// Pasted into an iPhone Shortcut's "Run JavaScript on Web Page" action, run
// against a YouTube watch page in the user's own Safari tab. This exists
// because captions_service's own server-side fetch (index.js, via yt-dlp)
// gets bot-challenged by YouTube on every request - Cloud Run's IP range is
// recognised as data-center infrastructure, not a residential client. A
// real device's own browser never has that problem, so this does the same
// transcript-panel extraction a real viewer would, then submits the result
// to the same cache every web viewer reads from. One successful run from
// any iPhone permanently speeds up that video for everyone else.
//
// See README.md in this folder for how to turn this into an actual Shortcut.
(async () => {
  // "1:23" / "12:34" / "1:02:34" -> milliseconds.
  function parseTimestamp(ts) {
    const parts = ts.split(':').map((p) => parseInt(p, 10));
    let seconds = 0;
    for (const p of parts) seconds = seconds * 60 + p;
    return seconds * 1000;
  }

  function dismissConsentIfPresent() {
    const buttons = Array.from(document.querySelectorAll('button, tp-yt-paper-button'));
    const btn = buttons.find((b) => /^(Reject all|Accept all)$/i.test(b.textContent.trim()));
    if (btn) btn.click();
  }

  function expandDescription() {
    const el = document.querySelector('tp-yt-paper-button#expand, #description-inline-expander #expand, #expand');
    if (el) el.click();
  }

  // The transcript button lives inside the expanded description, not under
  // the "..." menu next to Like/Share (that one's just "Report").
  function openTranscriptPanel() {
    const all = Array.from(document.querySelectorAll('button, tp-yt-paper-button'));
    const btn = all.find(
      (b) => /transcript/i.test(b.textContent || '') || /transcript/i.test(b.getAttribute('aria-label') || ''),
    );
    if (btn) {
      btn.scrollIntoView({ block: 'center' });
      btn.click();
      return true;
    }
    return false;
  }

  function wait(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  function waitForSegments(timeoutMs) {
    return new Promise((resolve, reject) => {
      const start = Date.now();
      const check = () => {
        if (document.querySelector('transcript-segment-view-model')) {
          resolve();
          return;
        }
        if (Date.now() - start > timeoutMs) {
          reject(new Error('Timed out waiting for the transcript panel to load'));
          return;
        }
        setTimeout(check, 300);
      };
      check();
    });
  }

  function extractCues() {
    const rows = Array.from(document.querySelectorAll('transcript-segment-view-model')).map((row) => {
      const tsEl = row.querySelector('[class*="Timestamp"]');
      const clone = row.cloneNode(true);
      clone.querySelectorAll('[class*="Timestamp"]').forEach((e) => e.remove());
      return { timestamp: tsEl ? tsEl.textContent.trim() : '', text: clone.textContent.trim() };
    });
    const cues = [];
    for (let i = 0; i < rows.length; i++) {
      const { timestamp, text } = rows[i];
      if (!timestamp || !text) continue;
      const startMs = parseTimestamp(timestamp);
      const nextStartMs = i + 1 < rows.length && rows[i + 1].timestamp ? parseTimestamp(rows[i + 1].timestamp) : startMs + 5000;
      cues.push({ text, startMs, durationMs: Math.max(0, nextStartMs - startMs) });
    }
    return cues;
  }

  function getVideoId() {
    try {
      const url = new URL(location.href);
      if (url.hostname.includes('youtu.be')) return url.pathname.split('/').filter(Boolean)[0] || null;
      return url.searchParams.get('v');
    } catch (e) {
      return null;
    }
  }

  // SUBMIT_KEY is deliberately NOT filled in here - this file is public
  // (it's in a public repo), and the key only works as abuse prevention if
  // it isn't visible to anyone who finds this file. Replace the
  // placeholder below with the real value before pasting this into the
  // Shortcut - see submit-shortcut/README.md step 3.
  const SUBMIT_URL = 'https://captions-service-275785368511.us-central1.run.app/submit';
  const SUBMIT_KEY = 'REPLACE_WITH_THE_REAL_SUBMIT_KEY';

  try {
    const videoId = getVideoId();
    if (!videoId) {
      completion('Could not find a video id on this page - make sure you ran this from a YouTube watch page.');
      return;
    }

    await wait(1500);
    dismissConsentIfPresent();
    await wait(800);
    expandDescription();
    await wait(800);
    const opened = openTranscriptPanel();
    if (!opened) {
      completion('Could not find the "Show transcript" button - this video may not have captions.');
      return;
    }

    await waitForSegments(15000);
    await wait(500);
    const cues = extractCues();
    if (cues.length === 0) {
      completion('The transcript panel opened but no caption lines were found.');
      return;
    }

    const resp = await fetch(SUBMIT_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'X-Submit-Key': SUBMIT_KEY },
      body: JSON.stringify({ videoId, cues }),
    });
    const data = await resp.json().catch(() => ({}));
    if (!resp.ok) {
      completion('Server rejected the captions: ' + (data.error || resp.status));
      return;
    }
    if (data.status === 'already-cached') {
      completion('Someone already submitted captions for this video - nothing to do.');
      return;
    }
    completion('Saved ' + (data.cueCount || cues.length) + ' caption lines. This video will now load instantly for every web user.');
  } catch (e) {
    completion('Something went wrong: ' + (e && e.message ? e.message : String(e)));
  }
})();
