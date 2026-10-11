# captions_service

Fetches a YouTube video's Japanese transcript for the web app's Immersion
"Watch a video" feature, using a real headless browser to read YouTube's own
"Show transcript" panel - a plain HTTP request to YouTube's caption API is
blocked (confirmed directly), but actually loading the page and opening the
transcript panel, the way a genuine viewer would, works reliably.

Every unique video is only ever fetched from YouTube once - the result is
cached in Firestore (`captionsCache` collection), and every later request
for that same video, from anyone, is served straight from the cache.

## Deploying (one-time setup, then one command per update)

This needs to run under **your** Google account - deploying to your project
needs your own permissions, not mine. From this folder:

```
gcloud auth login
gcloud config set project kanji-athletes
gcloud run deploy captions-service --source . --region us-central1 --allow-unauthenticated --memory 1Gi --timeout 60
```

The first command opens a browser window to sign in - do that once. The
`deploy` command builds the container in the cloud (no Docker needed on your
machine) and prints a URL like
`https://captions-service-xxxxxxxxxx-uc.a.run.app` when it's done, usually a
few minutes.

**Give me that URL once you have it** - it needs to be pasted into
`lib/web_immersion_player.dart`'s `kCaptionsServiceUrl` constant before the
web app can actually use it.

To ship a future code change to this service, just re-run the same
`gcloud run deploy` command from this folder - no other setup needed after
the first time.

## Testing locally before deploying

`@sparticuz/chromium` (the production dependency) only ships a Linux
binary, so it can't run on Windows. `test_local.js` exercises the exact same
extraction logic (`extractor.js`, shared with `index.js`) using a regular
desktop Puppeteer install instead, purely for local sanity-checking:

```
npm install
npm install --no-save puppeteer
node test_local.js <videoId>
```
