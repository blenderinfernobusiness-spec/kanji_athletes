# Kanji Athletes - YouTube Subtitles

Highlight Japanese text in YouTube's subtitles, look it up against your Kanji Athletes dictionary and decks, and add new words straight to a deck - synced with the same account as the app's Cloud Backup.

## Install (not on the Chrome Web Store - load it manually)

1. Unzip this folder somewhere permanent (don't delete it after installing - Chrome loads the extension from this folder every time).
2. Open Chrome and go to `chrome://extensions`.
3. Turn on **Developer mode** (top-right toggle).
4. Click **Load unpacked** and select this folder.
5. Pin the extension (puzzle-piece icon in Chrome's toolbar → pin "Kanji Athletes").

## How to use it

1. Click the extension icon and sign in with your Kanji Athletes account (same one as the app's Cloud Backup - create one there first if you haven't).
2. Click **Download my data**. Do this every time you want the extension to see decks/words you've added since the last download - it works from this local copy, not live from the cloud.
3. Open a YouTube video with Japanese subtitles turned on.
4. Click and drag across subtitle text to select it (the video auto-pauses so the caption doesn't change mid-drag - toggle this off in the popup's Settings if you don't want that).
5. A popup shows the reading/meaning if it's in your dictionary or decks, or lets you type one in if it isn't. Click **Add to deck**, pick an existing deck or create a new one.
6. When you're done, open the extension popup and click **Sync changes to cloud** to push everything you added back up. Your next "Download my data" in the app (or here) will include it.

## The bundled dictionary

`dictionary.json` ships with the extension itself, generated from the same dictionary the app uses (`tool/generate_dictionary_json.dart`) - so lookups work right after install, even before anyone signs in. "Download my data" layers your own decks and any dictionary words you've personalized (starred, re-translated, etc.) on top of it. If the dictionary itself changes (new words added, a translation fixed), re-run that script and re-zip/redistribute the extension - signing in doesn't update this bundled copy, only your own personal data.

## Known limitations (v1)

- Words added here don't get stroke-order data, so they won't show handwriting practice in the app's Writing game until edited there.
- Sync is manual and whole-file, same as the app's own Cloud Backup: if you add words here and also change decks in the app without syncing in between, whichever you sync last overwrites the other.
- Selection relies on YouTube's current caption HTML structure - if YouTube changes it, selection may stop working until this extension is updated.
