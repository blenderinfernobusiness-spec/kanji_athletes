# captions_service

Fetches a YouTube video's official Japanese subtitles for the web app's
Immersion "Watch a video" feature, using `yt-dlp` (an actively-maintained,
purpose-built tool for exactly this). Every unique video is only ever
fetched from YouTube once - the result is cached in Firestore
(`captionsCache` collection), and every later request for that same video,
from anyone, is served straight from the cache.

**Known limitation:** every request from this service's own Cloud Run IP
gets YouTube's "Sign in to confirm you're not a bot" challenge - that IP
range is recognised as data-center infrastructure, not a residential
client, regardless of how the request is made (this was also true of an
earlier Puppeteer-based version). Because of this, the web app currently
locks "Watch a video" back to an "Immersion isn't available on web" message
(see `lib/immersion_tab.dart`) rather than hanging on every new video
before failing. The `GET /` endpoint below still works for anything already
in the cache; see `submit-shortcut/` for how new videos get added to it
without that server-side fetch.

## Deploying (one-time setup, then one command per update)

This needs to run under **your** Google account - deploying to your project
needs your own permissions, not mine. From this folder:

```
gcloud auth login
gcloud config set project kanji-athletes
gcloud run deploy captions-service --source . --region us-central1 --allow-unauthenticated --memory 512Mi --cpu 1 --timeout 60 --set-env-vars SUBMIT_KEY=<the key pasted into the Shortcut>
```

The first command opens a browser window to sign in - do that once. The
`deploy` command builds the container in the cloud (no Docker needed on
your machine) and prints a URL like
`https://captions-service-xxxxxxxxxx-uc.a.run.app` when it's done, usually
a few minutes. Cloud Run carries existing env vars over on later deploys
that omit `--set-env-vars`, so `SUBMIT_KEY` only needs to be passed again
when actually rotating it - but if `/submit` ever starts returning 401 for
everyone, check that the env var is still set (`gcloud run services
describe captions-service --region us-central1` lists it).

## Endpoints

- `GET /?videoId=<11-char id>` - returns `{ videoId, available, cues,
  cachedAt }` from cache if present; otherwise tries `yt-dlp` live (which,
  per the limitation above, currently always fails with a bot challenge)
  and caches whatever it gets (including a `available: false` miss, so a
  genuinely caption-less video isn't retried forever).
- `POST /submit` - used by the iPhone Shortcut in `submit-shortcut/` to add
  a video a real device already extracted. Requires header
  `X-Submit-Key: <SUBMIT_KEY>`; body `{ videoId, cues: [{ text, startMs,
  durationMs }] }`. Won't overwrite an existing cache entry that already
  has cues (first successful submission wins, to stop repeated submissions
  from thrashing the same entry).

## Testing locally

`yt-dlp` needs to be on PATH (`pip install yt-dlp` into a venv, then add
its `Scripts`/`bin` folder to PATH for the session). Then:

```
npm install
node index.js
```

and hit `http://localhost:8080/?videoId=<id>` or POST to
`http://localhost:8080/submit` with `X-Submit-Key` set to whatever
`SUBMIT_KEY` env var the local process was started with.
