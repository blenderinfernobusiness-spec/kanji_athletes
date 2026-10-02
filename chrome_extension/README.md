# Kanji Athletes - YouTube Subtitles

Highlight Japanese text in YouTube's subtitles, look it up against your Kanji Athletes dictionary and decks, and add new words straight to a deck - synced with the same account as the app's Cloud Backup. Also works as a page-wide Japanese reader on any website (see "Screen reading mode" below).

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

## Screen reading mode

Turn on **Highlight Japanese text on web pages** in the extension popup to get the same purple highlighting and click/drag-to-look-up behavior as the YouTube subtitles, but on any website's own text - articles, forum posts, manga sites, anything. It's off by default; once enabled it works on every page until you turn it off again. Recognized words are drawn as an overlay (via the browser's Custom Highlight API) rather than edited into the page itself, so it can't break the page's own scripts - but that also means the "outline box" highlight style isn't available here, only colored text.

## The bundled dictionary

`dictionary.json` ships with the extension itself, generated from the same dictionary the app uses (`tool/generate_dictionary_json.dart`) - so lookups work right after install, even before anyone signs in. "Download my data" layers your own decks and any dictionary words you've personalized (starred, re-translated, etc.) on top of it. If the dictionary itself changes (new words added, a translation fixed), re-run that script and re-zip/redistribute the extension - signing in doesn't update this bundled copy, only your own personal data.

## Known limitations (v1)

- Words added here don't get stroke-order data, so they won't show handwriting practice in the app's Writing game until edited there.
- Syncing merges rather than overwrites: clicking **Sync changes to cloud** pulls the latest cloud data first and adds just the words you added here on top of it, so studying in the app on another device in the meantime won't get wiped out. The one case this can't resolve automatically is editing or deleting the *same* existing card in the app and here at the same time - whichever syncs last wins for that specific card, same tradeoff Anki accepts for its own sync.
- Deletions don't propagate backwards: the extension works from whatever you last downloaded, so if you deleted a deck in the app (or on another device) more recently than that, it can still show up here and even get recreated if you add a word to it. If you've deleted anything recently, hit **Download my data** again first.
- Selection relies on YouTube's current caption HTML structure - if YouTube changes it, selection may stop working until this extension is updated.
- Screen reading mode re-scans the page after it changes, which can be a little slow to catch up on very dynamic, fast-updating pages (e.g. live feeds) - it settles within about half a second of the page going quiet.
