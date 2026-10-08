import 'package:flutter/material.dart';

// One piece of a word, with the reading shown above it ('' for none).
class RubySegment {
  final String text;
  final String ruby;

  const RubySegment(this.text, this.ruby);
}

bool isKanjiChar(String ch) {
  final rune = ch.runes.first;
  return (rune >= 0x4E00 && rune <= 0x9FFF) || (rune >= 0x3400 && rune <= 0x4DBF);
}

// A run of the word's kanji, or of its kana.
class _WordBlock {
  String text;
  final bool kanji;

  _WordBlock(this.text, this.kanji);
}

// Splits a word into kanji blocks and kana blocks, and gives each kanji block
// its part of the reading. The reading of a kanji block is found by matching
// the kana blocks around it, so the reading only goes over the kanji. The kana
// (okurigana, like the った in 降った, or the の in 私の趣味) get no reading:
// 降った with ふった shows ふ over 降 and nothing over った.
//
// A reading that lists several choices (ふる, おりる) is ambiguous for this
// word, and a reading that doesn't line up with the word's kana is wrong for
// it. In both cases nothing is shown rather than a wrong reading.
List<RubySegment> rubySegmentsFor(String word, String reading) {
  // Dictionary readings mark the okurigana boundary with a dot (あつ.い).
  final cleaned = reading.replaceAll(RegExp(r'[\s.\-]'), '');
  if (word.isEmpty) return const [];
  if (cleaned.isEmpty || reading.contains(',') || !word.runes.any((r) => isKanjiChar(String.fromCharCode(r)))) {
    return [RubySegment(word, '')];
  }
  final blocks = <_WordBlock>[];
  for (final ch in word.split('')) {
    final kanji = isKanjiChar(ch);
    if (blocks.isNotEmpty && blocks.last.kanji == kanji) {
      blocks.last.text += ch;
    } else {
      blocks.add(_WordBlock(ch, kanji));
    }
  }
  final segments = <RubySegment>[];
  var cursor = 0;
  for (var i = 0; i < blocks.length; i++) {
    final block = blocks[i];
    if (block.kanji) {
      // The kanji's reading runs up to where the next kana block appears.
      var end = cleaned.length;
      if (i + 1 < blocks.length) {
        // A kana block at the very end of the word lines up with the end of the
        // reading, so search from there (かわいい: the い at the end, not the one in かわ).
        final next = blocks[i + 1].text;
        end = i + 2 == blocks.length ? cleaned.lastIndexOf(next) : cleaned.indexOf(next, cursor);
        if (end < cursor) return [RubySegment(word, '')];
      }
      segments.add(RubySegment(block.text, cleaned.substring(cursor, end)));
      cursor = end;
    } else {
      if (!cleaned.startsWith(block.text, cursor)) return [RubySegment(word, '')];
      segments.add(RubySegment(block.text, ''));
      cursor += block.text.length;
    }
  }
  return cursor == cleaned.length ? segments : [RubySegment(word, '')];
}

// A word with its reading placed over the kanji (see rubySegmentsFor).
// Set showRuby to false to draw the word without any readings.
Widget rubyWord({
  required String text,
  required String reading,
  required double fontSize,
  required Color textColor,
  required Color rubyColor,
  FontWeight fontWeight = FontWeight.w500,
  bool showRuby = true,
  double rubyScale = 0.45,
}) {
  final textStyle = TextStyle(fontSize: fontSize, color: textColor, fontWeight: fontWeight);
  if (!showRuby) return Text(text, style: textStyle);
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      for (final segment in rubySegmentsFor(text, reading))
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              segment.ruby.isEmpty ? ' ' : segment.ruby,
              style: TextStyle(fontSize: fontSize * rubyScale, color: rubyColor),
            ),
            Text(segment.text, style: textStyle),
          ],
        ),
    ],
  );
}
