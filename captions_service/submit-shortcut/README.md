# Captions-submitting iPhone Shortcut

Not an App Store app - a regular iPhone Shortcut, shared as a link or file,
built once in the Shortcuts app. It reads a YouTube video's official
Japanese transcript directly out of the user's own Safari tab (so it's
subject to YouTube's normal rules for a real visitor, not a cloud server's),
and sends the result to `captions_service`'s cache. One successful run from
any iPhone makes that video load instantly for every later web viewer.

**Not yet tested on a real device** - built and reasoned through, but I
(Claude) have no iPhone or Mac to try it on myself.

## Building the Shortcut

1. Open the **Shortcuts** app → **+** (new shortcut).
2. Add the action **Run JavaScript on Web Page** (search for it in the
   action picker).
3. Tap into its script box, delete the placeholder, and paste in the full
   contents of [`extract-and-submit.js`](extract-and-submit.js) from this
   folder. Then replace `REPLACE_WITH_THE_REAL_SUBMIT_KEY` with the actual
   key (ask Claude for it, or find it in the Cloud Run service's env vars -
   `gcloud run services describe captions-service --region us-central1`).
   It's deliberately left out of this file since the file itself is public.
4. Rename the shortcut (tap its name at the top) to something like
   "Submit JP Captions".
5. Optional but recommended: tap the shortcut's settings (the **(i)** icon
   on its card in the Shortcuts list) → **Show in Share Sheet** → on, so it
   shows up when sharing from the YouTube app/Safari, not just from inside
   Shortcuts.

## Using it

1. Open the YouTube video (in Safari, or the YouTube app's "Open in Safari"
   / share-to-Shortcuts path - it needs to be a real Safari tab, not an
   in-app browser).
2. Make sure the video actually has Japanese captions available (check the
   CC button).
3. Run the shortcut (from the Shortcuts app, or the Share Sheet while
   viewing the video).
4. It'll show a short result message: either that it saved N caption
   lines, that this video was already cached by someone else, or what went
   wrong (no transcript button found, no captions, etc).

It only takes a few seconds and doesn't change anything about how the video
plays - it's just reading the transcript panel in the background.

## If this needs to change later

- The script's `SUBMIT_URL` / `SUBMIT_KEY` constants match the key the
  Cloud Run service was deployed with (`gcloud run deploy ... --set-env-vars
  SUBMIT_KEY=...` - see `../README.md`). If that key ever gets rotated, the
  pasted script in every existing Shortcut needs to be updated to match, or
  submissions will get a 401.
- The actual extraction logic (finding the transcript button, parsing
  timestamps, etc) is the same as what `captions_service` used to do
  server-side with Puppeteer before the yt-dlp rewrite - see the git history
  of `captions_service/extractor.js` if YouTube's page structure changes
  and this needs updating.
