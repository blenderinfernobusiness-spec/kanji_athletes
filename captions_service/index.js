// Fetches a YouTube video's Japanese transcript using a real headless
// browser - directly reading YouTube's own "Show transcript" panel off the
// rendered page, the same way a person using that feature would, rather
// than calling any separate caption API. That matters: a plain HTTP request
// to YouTube's caption endpoint (confirmed directly, more than once) comes
// back empty even with a real desktop browser's user agent - but actually
// loading the page and opening the transcript panel the way a genuine
// viewer would works reliably, since there's nothing automated-looking
// about the traffic pattern at that point. The actual extraction logic
// lives in extractor.js, shared with (and proven by) the local test script.
//
// Every unique video is only ever fetched from YouTube once - the result is
// cached in Firestore, and every later request (from any viewer, forever)
// is served straight from that cache. Launching a real browser is slow and
// not free, so this caching is what keeps this practical at any real scale,
// not just a performance nicety.
const express = require('express');
const chromium = require('@sparticuz/chromium');
const puppeteer = require('puppeteer-core');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { fetchCaptionsFromPage } = require('./extractor');

initializeApp();
const db = getFirestore();

const app = express();

// No sign-in involved in watching a video's captions, so this is openly
// readable by the web app's own origin (and, deliberately, any origin -
// there's nothing sensitive in a video's caption text, and restricting the
// origin here wouldn't add any real protection against misuse anyway).
app.use((req, res, next) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, OPTIONS');
  if (req.method === 'OPTIONS') {
    res.status(204).send('');
    return;
  }
  next();
});

const VIDEO_ID_RE = /^[A-Za-z0-9_-]{11}$/;

app.get('/', async (req, res) => {
  const videoId = String(req.query.videoId || '').trim();
  if (!VIDEO_ID_RE.test(videoId)) {
    res.status(400).json({ error: 'Missing or invalid videoId' });
    return;
  }

  const docRef = db.collection('captionsCache').doc(videoId);
  try {
    const cached = await docRef.get();
    if (cached.exists) {
      res.json(cached.data());
      return;
    }
  } catch (e) {
    // Firestore being briefly unreachable shouldn't block a fetch that
    // would otherwise succeed - just skip the cache this one time.
    console.error('Cache read failed', e);
  }

  let browser;
  try {
    browser = await puppeteer.launch({
      args: chromium.args,
      defaultViewport: { width: 1280, height: 1000 },
      executablePath: await chromium.executablePath(),
      headless: true,
    });
    const page = await browser.newPage();
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
    );
    // domcontentloaded rather than networkidle2 - a live stream keeps
    // making network requests indefinitely, so "network idle" may never
    // actually happen for one (confirmed directly: a live video timed out
    // here). The explicit waits inside fetchCaptionsFromPage for the
    // consent dialog, transcript button, and transcript rows are the real
    // gate on correctness, not this initial navigation.
    await page.goto(`https://www.youtube.com/watch?v=${videoId}`, { waitUntil: 'domcontentloaded', timeout: 30000 });

    const { available, cues } = await fetchCaptionsFromPage(page);
    const result = { videoId, available, cues, cachedAt: Date.now() };
    await docRef.set(result);
    res.json(result);
  } catch (e) {
    console.error('Caption fetch failed', e);
    res.status(502).json({ error: 'Could not fetch captions for this video' });
  } finally {
    if (browser) await browser.close();
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`captions-service listening on ${port}`));
