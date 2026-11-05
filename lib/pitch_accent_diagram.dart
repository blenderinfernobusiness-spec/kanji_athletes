import 'package:flutter/material.dart';
import 'app_colors.dart';

// Splits a reading into morae rather than characters - a small kana
// (ゃゅょぁぃぅぇぉ and their katakana forms) combines with the kana
// before it into one mora instead of getting its own dot, matching how
// pitch accent is actually counted (きょう is 2 morae, not 3).
List<String> moraeOf(String reading) {
  const smallKana = {
    'ゃ', 'ゅ', 'ょ', 'ぁ', 'ぃ', 'ぅ', 'ぇ', 'ぉ',
    'ャ', 'ュ', 'ョ', 'ァ', 'ィ', 'ゥ', 'ェ', 'ォ',
  };
  final morae = <String>[];
  for (final ch in reading.characters) {
    if (smallKana.contains(ch) && morae.isNotEmpty) {
      morae[morae.length - 1] = morae.last + ch;
    } else {
      morae.add(ch);
    }
  }
  return morae;
}

// The standard Tokyo pitch-accent rule, turning a mora count + accent
// number into a high/low sequence: accent 0 (heiban) starts low then
// stays high; accent 1 (atamadaka) is high only on the first mora; any
// other accent N is low, then high through mora N, then low again (the
// drop lands right after the Nth mora).
List<bool> highLowPattern(int moraCount, int accent) {
  if (moraCount <= 0) return const [];
  if (moraCount == 1) return [accent == 1];
  return List.generate(moraCount, (i) {
    if (accent == 0) return i > 0;
    if (accent == 1) return i == 0;
    return i > 0 && i < accent;
  });
}

// A small dots-and-line pitch chart for one word, in the same style as
// OJAD's own diagrams: a dot per mora, high moras drawn near the top and
// low moras near the bottom, joined by a line so the rise/drop reads at a
// glance, with the mora itself labelled underneath each dot. Renders
// nothing if there's no accent data or no reading to split into morae, so
// call sites can use it unconditionally wherever they have both.
class PitchAccentDiagram extends StatelessWidget {
  final String reading;
  final List<int> accents;
  final bool isDarkMode;
  const PitchAccentDiagram({super.key, required this.reading, required this.accents, required this.isDarkMode});

  static const double _cellWidth = 30;
  static const double _chartHeight = 34;

  @override
  Widget build(BuildContext context) {
    final morae = moraeOf(reading);
    if (morae.isEmpty || accents.isEmpty) return const SizedBox.shrink();
    final highs = highLowPattern(morae.length, accents.first);
    final width = _cellWidth * morae.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: _chartHeight,
          child: CustomPaint(
            painter: _PitchDotsPainter(
              highs: highs,
              dotColor: AppColors.accent,
              lineColor: AppColors.textMuted(isDarkMode),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            morae.length,
            (i) => SizedBox(
              width: _cellWidth,
              child: Text(
                morae[i],
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ),
        ),
        if (accents.length > 1) ...[
          const SizedBox(height: 2),
          Text(
            'also heard as [${accents.skip(1).join(', ')}]',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted(isDarkMode)),
          ),
        ],
      ],
    );
  }
}

class _PitchDotsPainter extends CustomPainter {
  final List<bool> highs;
  final Color dotColor;
  final Color lineColor;
  _PitchDotsPainter({required this.highs, required this.dotColor, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final n = highs.length;
    if (n == 0) return;
    final cellW = size.width / n;
    const topY = 6.0;
    final bottomY = size.height - 6.0;
    final points = List.generate(n, (i) => Offset(cellW * (i + 0.5), highs[i] ? topY : bottomY));

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2;
    for (var i = 0; i < n - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }
    final dotPaint = Paint()..color = dotColor;
    for (final p in points) {
      canvas.drawCircle(p, 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PitchDotsPainter oldDelegate) =>
      oldDelegate.highs != highs || oldDelegate.dotColor != dotColor || oldDelegate.lineColor != lineColor;
}
