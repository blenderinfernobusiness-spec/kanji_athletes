// The actual caption-extraction logic, factored out so the exact same code
// path is exercised by both the local test script (test_local.js, which
// launches a regular desktop Chromium since @sparticuz/chromium only ships
// a Linux binary) and the deployed service (index.js, which launches the
// Linux one via puppeteer-core) - not just similar code in two places.
"use strict";

// "1:23" or "12:34" or "1:02:34" -> milliseconds.
function parseTimestamp(ts) {
  const parts = ts.split(':').map((p) => parseInt(p, 10));
  let seconds = 0;
  for (const p of parts) seconds = seconds * 60 + p;
  return seconds * 1000;
}

async function dismissConsentIfPresent(page) {
  await page.evaluate(() => {
    const buttons = Array.from(document.querySelectorAll('button, tp-yt-paper-button'));
    const btn = buttons.find((b) => /^(Reject all|Accept all)$/i.test(b.textContent.trim()));
    if (btn) btn.click();
  });
}

async function openTranscriptPanel(page) {
  // The transcript button lives inside the expanded video description, not
  // under the "..." menu next to Like/Share (that one's just "Report").
  await page.evaluate(() => {
    const el = document.querySelector('tp-yt-paper-button#expand, #description-inline-expander #expand, #expand');
    if (el) el.click();
  });
  await new Promise((r) => setTimeout(r, 1200));

  return page.evaluate(() => {
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
  });
}

async function extractCues(page) {
  await page.waitForFunction(() => document.querySelector('transcript-segment-view-model'), { timeout: 15000 });
  await new Promise((r) => setTimeout(r, 500));
  const rows = await page.evaluate(() => {
    return Array.from(document.querySelectorAll('transcript-segment-view-model')).map((row) => {
      const tsEl = row.querySelector('[class*="Timestamp"]');
      const clone = row.cloneNode(true);
      clone.querySelectorAll('[class*="Timestamp"]').forEach((e) => e.remove());
      return { timestamp: tsEl ? tsEl.textContent.trim() : '', text: clone.textContent.trim() };
    });
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

// Runs the whole sequence against an already-navigated page (the caller
// owns browser/page lifecycle) and returns { available, cues }.
async function fetchCaptionsFromPage(page) {
  await new Promise((r) => setTimeout(r, 1500));
  await dismissConsentIfPresent(page);
  await new Promise((r) => setTimeout(r, 1000));

  const opened = await openTranscriptPanel(page);
  if (!opened) return { available: false, cues: [] };

  const cues = await extractCues(page);
  return { available: cues.length > 0, cues };
}

module.exports = { parseTimestamp, dismissConsentIfPresent, openTranscriptPanel, extractCues, fetchCaptionsFromPage };
