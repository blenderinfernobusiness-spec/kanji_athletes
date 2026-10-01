# Kanji memory-technique images

Drop one image per kanji here, named by that kanji's KanjiVG code (its
Unicode codepoint as 5-digit lowercase hex - the same code already used for
stroke order, computed by `_kanjiVGCodeFor` in `lib/kanji_challenge_data.dart`),
e.g. `706b.webp` for 火.

Keep them as **WebP**, since it gives noticeably smaller files than PNG/JPEG
at the same visual quality - these are bundled straight into the app, so
their total size adds directly to every install and update. A resize/convert
pass (e.g. via `cwebp` or ImageMagick) down to roughly 500-600px on the long
edge at ~80% quality is normally enough for a small illustration like these
without visibly hurting quality - there's no need for anything larger since
they only ever display at a few hundred pixels wide in the app itself.

Once an image is here, point a `ChallengeKanji` entry in
`lib/kanji_challenge_data.dart` at it via its `imageAsset` field, e.g.:

```dart
ChallengeKanji(
  japanese: '火',
  english: 'Fire',
  memoryNotes: ['...'],
  imageAsset: 'assets/kanji_memory/706b.webp',
),
```
