import 'package:flutter/material.dart';
import 'card_edit_dialog.dart';
import 'stroke_order_animator.dart';
import 'study_data.dart';

const Color _accent = Color(0xFF9A00FE);

// Full context for one flashcard: the word or kanji itself, its reading and
// meaning, how each kanji in it reads, its stroke order, the memory technique
// and picture, and how the card is going in study. Opened by tapping a card
// in a deck.
class CardContextScreen extends StatefulWidget {
  final StudyCard card;
  final bool isDarkMode;
  final Map<String, HighlightEntry> highlightIndex;
  final VoidCallback onChanged;

  const CardContextScreen({
    super.key,
    required this.card,
    required this.isDarkMode,
    required this.highlightIndex,
    required this.onChanged,
  });

  @override
  State<CardContextScreen> createState() => _CardContextScreenState();
}

class _CardContextScreenState extends State<CardContextScreen> {
  Color get _fg => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _fgMuted => widget.isDarkMode ? Colors.white60 : Colors.black54;
  Color get _cardBg => widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!;

  Widget _section(String title, Widget child) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, textAlign: TextAlign.center, style: TextStyle(color: _fgMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final kanji = extractKanjiOnly(card.japanese);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Card'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit card',
            onPressed: () => showEditCardDialog(context, card, widget.isDarkMode, () {
              setState(() {});
              widget.onChanged();
            }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  card.japanese,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _fg, fontSize: 48, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.cardType,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accent),
                  ),
                ),
                if (card.hiragana.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(card.hiragana, textAlign: TextAlign.center, style: TextStyle(color: _fgMuted, fontSize: 18)),
                  ),
                if (card.romaji.isNotEmpty)
                  Text(card.romaji, textAlign: TextAlign.center, style: TextStyle(color: _fgMuted, fontSize: 14)),
                const SizedBox(height: 12),
                Text(
                  card.english.isEmpty ? 'No meaning yet' : card.english,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _fg, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (kanji.isNotEmpty)
                  _section(
                    'KANJI IN THIS CARD',
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final k in kanji)
                          Container(
                            width: 90,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: [
                                Text(k, style: TextStyle(color: _fg, fontSize: 28, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                  widget.highlightIndex[k]?.meaning ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: _fgMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                if (kanji.isNotEmpty)
                  _section(
                    'STROKE ORDER',
                    card.kanjiVGCodes.isEmpty
                        ? OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: _accent, side: const BorderSide(color: _accent)),
                            icon: const Icon(Icons.gesture),
                            label: const Text('Load stroke order'),
                            onPressed: () {
                              card.kanjiVGCodes = findKanjiVGCodesForWord(card.japanese);
                              setState(() {});
                              widget.onChanged();
                            },
                          )
                        : Container(
                            width: 320,
                            height: 420,
                            decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
                            child: StrokeOrderAnimator(kanjiVGCodes: card.kanjiVGCodes, isDarkMode: widget.isDarkMode),
                          ),
                  ),
                _section(
                  'MEMORY TECHNIQUE',
                  card.memoryTechnique.isEmpty && card.memoryImageAsset == null
                      ? Text('None yet - tap edit to add one.', textAlign: TextAlign.center, style: TextStyle(color: _fgMuted))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (card.memoryTechnique.isNotEmpty)
                              Text(card.memoryTechnique, textAlign: TextAlign.center, style: TextStyle(color: _fg, fontSize: 15)),
                            if (card.memoryImageAsset != null) ...[
                              if (card.memoryTechnique.isNotEmpty) const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(card.memoryImageAsset!, fit: BoxFit.contain),
                              ),
                            ],
                          ],
                        ),
                ),
                _section(
                  'STUDY',
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(dueLabel(card), textAlign: TextAlign.center, style: TextStyle(color: _fg, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Progress: ${card.progress}%', textAlign: TextAlign.center, style: TextStyle(color: _fgMuted)),
                        Text('Correct in a row: ${card.repetitions}', textAlign: TextAlign.center, style: TextStyle(color: _fgMuted)),
                        Text('Current interval: ${card.intervalDays} day(s)', textAlign: TextAlign.center, style: TextStyle(color: _fgMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
