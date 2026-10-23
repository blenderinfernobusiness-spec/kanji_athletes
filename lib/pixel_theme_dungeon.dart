import 'pixel_sprites.dart';
import 'pixel_icons_base.dart';

// The "Dungeon" pixel-art theme - stone walls, torches and loot, built
// straight on the kit's own base material palette with no recolouring (the
// kit's own Dungeon theme entry has an empty material-override map, since
// it's the kit's original/reference look) and no decoration pass. Every
// icon below is one of the shared, theme-agnostic draw functions in
// pixel_icons_base.dart.
final PixelTheme kDungeonTheme = PixelTheme(
  id: 'dungeon',
  name: 'Dungeon',
  palette: kBasePalette,
  forcedDarkMode: true,
  icons: {
    'library': const SpriteIconDef(baseWidth: 32, draw: library),
    'study': const SpriteIconDef(baseWidth: 32, draw: study),
    'itembox': const SpriteIconDef(baseWidth: 32, draw: itembox),
    'dictComplete': const SpriteIconDef(baseWidth: 32, draw: dictComplete),
    'dictKanji': const SpriteIconDef(baseWidth: 32, draw: dictKanji),
    'dictVocab': const SpriteIconDef(baseWidth: 32, draw: dictVocab),
    'level': const SpriteIconDef(baseWidth: 32, draw: level),
    'gem': const SpriteIconDef(baseWidth: 32, draw: gem),
    'stats': const SpriteIconDef(baseWidth: 32, draw: stats),
    'settings': const SpriteIconDef(baseWidth: 32, draw: settings),
    'tabCards': const SpriteIconDef(baseWidth: 32, draw: tabCards),
    'tabReading': const SpriteIconDef(baseWidth: 32, draw: tabReading),
    'tabLessons': const SpriteIconDef(baseWidth: 32, draw: tabLessons),
    'addDeck': const SpriteIconDef(baseWidth: 32, draw: addDeck),
    'deckGrammar': const SpriteIconDef(baseWidth: 32, draw: deckGrammar),
    'deckKana': const SpriteIconDef(baseWidth: 32, draw: deckKana),
    'deckKanji': const SpriteIconDef(baseWidth: 32, draw: deckKanji),
    'deckMistakes': const SpriteIconDef(baseWidth: 32, draw: deckMistakes),
    'runeKana': const SpriteIconDef(baseWidth: 16, draw: runeKana),
    'bookVocab': const SpriteIconDef(baseWidth: 16, draw: bookVocab),
    'oreCoal': SpriteIconDef(baseWidth: 16, draw: oreDraw('ink')),
    'oreIron': SpriteIconDef(baseWidth: 16, draw: oreDraw('iron')),
    'oreGold': SpriteIconDef(baseWidth: 16, draw: oreDraw('gold')),
    'oreAmethyst': SpriteIconDef(baseWidth: 16, draw: oreDraw('amethyst')),
    'torch': const SpriteIconDef(baseWidth: 16, draw: torch),
    'quill': const SpriteIconDef(baseWidth: 16, draw: quill),
    'brush': const SpriteIconDef(baseWidth: 16, draw: brush),
    'bell': const SpriteIconDef(baseWidth: 32, draw: bell),
    'flag': const SpriteIconDef(baseWidth: 32, draw: flag),
    'undo': const SpriteIconDef(baseWidth: 16, draw: undo),
    'back': const SpriteIconDef(baseWidth: 16, draw: back),
    'frame': const SpriteIconDef(baseWidth: 24, draw: frame),
    'skull': const SpriteIconDef(baseWidth: 32, draw: skull),
    'shield': const SpriteIconDef(baseWidth: 32, draw: shield),
    'sword': const SpriteIconDef(baseWidth: 32, draw: sword),
    'crown': const SpriteIconDef(baseWidth: 32, draw: crown),
  },
);
