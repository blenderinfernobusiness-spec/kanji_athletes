// Exercises the exact same extractor.js logic the deployed service uses,
// just with a regular desktop-Chromium launch instead of
// puppeteer-core + @sparticuz/chromium (which only ships a Linux binary,
// so it can't run on this Windows machine). Not part of the deployed
// service - a pre-deploy sanity check only.
const puppeteer = require('puppeteer');
const { fetchCaptionsFromPage } = require('./extractor');

const videoId = process.argv[2] || 'FaBDuqSdveY';

(async () => {
  let browser;
  try {
    browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
    await page.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
    );
    await page.setViewport({ width: 1280, height: 1000 });
    console.log(`Navigating to video ${videoId}...`);
    await page.goto(`https://www.youtube.com/watch?v=${videoId}`, { waitUntil: 'networkidle2', timeout: 30000 });

    const { available, cues } = await fetchCaptionsFromPage(page);
    console.log(`available=${available} cues=${cues.length}`);
    for (const c of cues.slice(0, 5)) console.log(' ', c.startMs, c.durationMs, JSON.stringify(c.text));
    console.log('...');
    for (const c of cues.slice(-3)) console.log(' ', c.startMs, c.durationMs, JSON.stringify(c.text));
  } catch (e) {
    console.error('FAILED:', e);
    process.exitCode = 1;
  } finally {
    if (browser) await browser.close();
  }
})();
