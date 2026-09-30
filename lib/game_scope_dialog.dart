import 'package:flutter/material.dart';
import 'study_data.dart';

// Lets the user pick which cards a Writing/Reading game session should play
// through: the whole set, or a chosen number picked randomly, by newest
// added, or by lowest study progress (cards they get wrong often). Returns
// the resolved list of cards to play, or null if cancelled.
Future<List<StudyCard>?> showGameScopeDialog(
  BuildContext context, {
  required List<StudyCard> cards,
  required bool isDarkMode,
}) {
  return showDialog<List<StudyCard>>(
    context: context,
    builder: (context) => _GameScopeDialog(cards: cards, isDarkMode: isDarkMode),
  );
}

class _GameScopeDialog extends StatefulWidget {
  final List<StudyCard> cards;
  final bool isDarkMode;

  const _GameScopeDialog({required this.cards, required this.isDarkMode});

  @override
  State<_GameScopeDialog> createState() => _GameScopeDialogState();
}

enum _PickStrategy { random, newest, lowestProgress }

class _GameScopeDialogState extends State<_GameScopeDialog> {
  bool _wholeDeck = true;
  _PickStrategy _strategy = _PickStrategy.random;
  late final TextEditingController _countController;

  @override
  void initState() {
    super.initState();
    final defaultCount = widget.cards.length < 20 ? widget.cards.length : 20;
    _countController = TextEditingController(text: defaultCount.toString());
  }

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  List<StudyCard> _resolve() {
    if (_wholeDeck) return List<StudyCard>.from(widget.cards);

    final total = widget.cards.length;
    var count = int.tryParse(_countController.text.trim()) ?? total;
    count = count.clamp(1, total);

    switch (_strategy) {
      case _PickStrategy.random:
        final shuffled = List<StudyCard>.from(widget.cards)..shuffle();
        return shuffled.take(count).toList();
      case _PickStrategy.newest:
        return widget.cards.sublist(total - count);
      case _PickStrategy.lowestProgress:
        final sorted = List<StudyCard>.from(widget.cards)
          ..sort((a, b) => a.progress.compareTo(b.progress));
        return sorted.take(count).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subColor = isDarkMode ? Colors.white70 : Colors.black54;
    final isEmpty = widget.cards.isEmpty;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text("Choose Cards", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      content: SizedBox(
        width: 300,
        child: isEmpty
            ? Text("No cards to play.", style: TextStyle(color: subColor))
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Whole deck (${widget.cards.length} cards)', style: TextStyle(color: textColor)),
                      value: true,
                      groupValue: _wholeDeck,
                      activeColor: const Color(0xFF9A00FE),
                      onChanged: (v) => setState(() => _wholeDeck = true),
                    ),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Set number of cards', style: TextStyle(color: textColor)),
                      value: false,
                      groupValue: _wholeDeck,
                      activeColor: const Color(0xFF9A00FE),
                      onChanged: (v) => setState(() => _wholeDeck = false),
                    ),
                    if (!_wholeDeck) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                        child: TextField(
                          controller: _countController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Number of cards',
                            labelStyle: TextStyle(color: subColor),
                            filled: true,
                            fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      RadioListTile<_PickStrategy>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Random', style: TextStyle(color: textColor)),
                        value: _PickStrategy.random,
                        groupValue: _strategy,
                        activeColor: const Color(0xFF9A00FE),
                        onChanged: (v) => setState(() => _strategy = v!),
                      ),
                      RadioListTile<_PickStrategy>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Newest added', style: TextStyle(color: textColor)),
                        value: _PickStrategy.newest,
                        groupValue: _strategy,
                        activeColor: const Color(0xFF9A00FE),
                        onChanged: (v) => setState(() => _strategy = v!),
                      ),
                      RadioListTile<_PickStrategy>(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Lowest progress', style: TextStyle(color: textColor)),
                        subtitle: Text('Cards you get wrong often', style: TextStyle(color: subColor, fontSize: 12)),
                        value: _PickStrategy.lowestProgress,
                        groupValue: _strategy,
                        activeColor: const Color(0xFF9A00FE),
                        onChanged: (v) => setState(() => _strategy = v!),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: subColor)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
          onPressed: isEmpty ? null : () => Navigator.pop(context, _resolve()),
          child: const Text("Start"),
        ),
      ],
    );
  }
}
