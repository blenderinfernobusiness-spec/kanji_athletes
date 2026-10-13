// Fetches a YouTube video's official Japanese subtitles using yt-dlp - an
// actively-maintained, purpose-built tool for exactly this, with a large
// community keeping it working as YouTube's own internals change. This
// replaced an earlier approach that drove a real headless browser (reading
// YouTube's own "Show Transcript" panel): that worked for most videos, but
// failed outright for some, with YouTube's player itself reporting the
// caption track as explicitly "not servable" in that automated context.
// yt-dlp succeeded on every video that approach failed on, instantly - a
// different, more specialized tool handling YouTube's requirements more
// completely than a hand-rolled browser-automation script reasonably could.
//
// Every unique video is only ever fetched from YouTube once - the result is
// cached in Firestore, and every later request (from any viewer, forever)
// is served straight from that cache.
const express = require('express');
const { spawn } = require('child_process');
const fs = require('fs/promises');
const os = require('os');
const path = require('path');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

initializeApp();
const db = getFirestore();

const app = express();

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

// Runs yt-dlp to fetch just the Japanese subtitle track (no video/audio
// download at all) as a json3 file, in a fresh temp directory per request
// so concurrent requests for different videos can never collide.
async function fetchSubtitlesJson3(videoId) {
  const workDir = await fs.mkdtemp(path.join(os.tmpdir(), 'yt-'));
  const outputTemplate = path.join(workDir, 'sub.%(ext)s');
  await new Promise((resolve, reject) => {
    const proc = spawn('yt-dlp', [
      '--write-subs',
      '--write-auto-subs',
      '--sub-langs',
      'ja',
      '--skip-download',
      '--sub-format',
      'json3',
      '-o',
      outputTemplate,
      `https://www.youtube.com/watch?v=${videoId}`,
    ]);
    let stderr = '';
    proc.stderr.on('data', (d) => (stderr += d));
    proc.on('close', (code) => {
      if (code === 0) resolve();
      else reject(new Error(`yt-dlp exited ${code}: ${stderr.slice(-500)}`));
    });
    proc.on('error', reject);
  });

  const files = await fs.readdir(workDir);
  const subFile = files.find((f) => f.endsWith('.json3'));
  if (!subFile) {
    await fs.rm(workDir, { recursive: true, force: true });
    return null; // no Japanese subtitles available for this video
  }
  const raw = await fs.readFile(path.join(workDir, subFile), 'utf-8');
  await fs.rm(workDir, { recursive: true, force: true });
  return JSON.parse(raw);
}

function parseCues(json3) {
  const events = json3.events || [];
  return events
    .filter((e) => Array.isArray(e.segs))
    .map((e) => ({
      text: e.segs.map((s) => s.utf8 || '').join(''),
      startMs: e.tStartMs ?? 0,
      durationMs: e.dDurationMs ?? 0,
    }))
    .filter((c) => c.text.trim().length > 0);
}

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
    console.error('Cache read failed', e);
  }

  try {
    const json3 = await fetchSubtitlesJson3(videoId);
    const cues = json3 ? parseCues(json3) : [];
    const result = { videoId, available: cues.length > 0, cues, cachedAt: Date.now() };
    await docRef.set(result);
    res.json(result);
  } catch (e) {
    console.error('Subtitle fetch failed', e);
    res.status(502).json({ error: 'Could not fetch captions for this video' });
  }
});

const port = process.env.PORT || 8080;
app.listen(port, () => console.log(`captions-service listening on ${port}`));
