import 'package:flutter/material.dart';
import 'study_data.dart';
import 'stroke_order_animator.dart';

InputDecoration _fieldDecoration(bool isDarkMode, String hint) => InputDecoration(
  hintText: hint,
  hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
  filled: true,
  fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
);

const Map<String, String> answerModeLabels = {
  'basic': 'Basic (reveal and mark yourself)',
  'draw': 'Draw (write it, with stroke hints)',
  'type': 'Type (auto-marked on exact match)',
};

// Shared answer-mode picker for the Add/Edit card dialogs.
Widget answerModeField({
  required String value,
  required bool isDarkMode,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    initialValue: value,
    dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    decoration: _fieldDecoration(isDarkMode, "Answer mode"),
    items: answerModeLabels.entries
        .map((entry) => DropdownMenuItem<String>(value: entry.key, child: Text(entry.value)))
        .toList(),
    onChanged: onChanged,
  );
}

const List<String> cardTypeOptions = ['Kanji', 'Kana', 'Vocab'];

// Shared card-type picker (Kanji/Kana/Vocab) for the Add/Edit card dialogs
// and the deck's bulk-edit menu.
Widget cardTypeField({
  required String value,
  required bool isDarkMode,
  required ValueChanged<String?> onChanged,
}) {
  return DropdownButtonFormField<String>(
    initialValue: cardTypeOptions.contains(value) ? value : 'Vocab',
    dropdownColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
    decoration: _fieldDecoration(isDarkMode, "Card type"),
    items: cardTypeOptions.map((type) => DropdownMenuItem<String>(value: type, child: Text(type))).toList(),
    onChanged: onChanged,
  );
}

void _confirmResetProgress(
  BuildContext context,
  StudyCard card,
  bool isDarkMode,
  VoidCallback onUpdate,
  void Function(void Function()) setDialogState,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Reset Progress?",
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
      ),
      content: Text(
        "This card's spaced repetition progress will go back to new. This cannot be undone.",
        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Cancel",
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9A00FE),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            resetCardProgress(card);
            onUpdate();
            setDialogState(() {});
            Navigator.pop(context);
          },
          child: const Text("Reset"),
        ),
      ],
    ),
  );
}

// Shared "edit card" dialog used both from the deck's card list and from a
// spaced repetition session, so a card can be fixed up mid-study.
void showEditCardDialog(BuildContext context, StudyCard card, bool isDarkMode, VoidCallback onUpdate) {
  final japaneseController = TextEditingController(text: card.japanese);
  final hiraganaController = TextEditingController(text: card.hiragana);
  final romajiController = TextEditingController(text: card.romaji);
  final englishController = TextEditingController(text: card.english);
  final memoryTechniqueController = TextEditingController(text: card.memoryTechnique);
  bool englishFirst = card.englishFirst;
  String answerMode = card.answerMode;
  String cardType = card.cardType;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit Card",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: SizedBox(
          width: 280,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: japaneseController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: _fieldDecoration(isDarkMode, "Japanese"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: hiraganaController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: _fieldDecoration(isDarkMode, "Japanese (hiragana)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: romajiController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: _fieldDecoration(isDarkMode, "Romaji (optional)"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: englishController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: _fieldDecoration(isDarkMode, "English"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: memoryTechniqueController,
                  maxLines: 3,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  decoration: _fieldDecoration(isDarkMode, "Memory technique (optional)"),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        englishFirst ? "Prompt with English first" : "Prompt with Japanese first",
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      ),
                    ),
                    Switch(
                      value: englishFirst,
                      activeThumbColor: const Color(0xFF9A00FE),
                      onChanged: (value) => setDialogState(() => englishFirst = value),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                answerModeField(
                  value: answerMode,
                  isDarkMode: isDarkMode,
                  onChanged: (value) {
                    if (value != null) setDialogState(() => answerMode = value);
                  },
                ),
                const SizedBox(height: 12),
                cardTypeField(
                  value: cardType,
                  isDarkMode: isDarkMode,
                  onChanged: (value) {
                    if (value != null) setDialogState(() => cardType = value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Study progress: ${card.progress}%",
                      style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                    ),
                    TextButton(
                      onPressed: () => _confirmResetProgress(context, card, isDarkMode, onUpdate, setDialogState),
                      child: const Text("Reset Progress"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A00FE),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final japanese = japaneseController.text.trim();
              final hiragana = hiraganaController.text.trim();
              final english = englishController.text.trim();
              if (japanese.isEmpty || hiragana.isEmpty || english.isEmpty) return;

              card.japanese = japanese;
              card.hiragana = hiragana;
              card.romaji = romajiController.text.trim();
              card.english = english;
              card.englishFirst = englishFirst;
              card.answerMode = answerMode;
              card.cardType = cardType;
              card.memoryTechnique = memoryTechniqueController.text.trim();
              card.kanjiVGCodes = findKanjiVGCodesForWord(japanese);
              onUpdate();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    ),
  );
}

// Shared "view stroke order" pop-up used from the deck's card list and from
// a spaced repetition session.
void showStrokeOrderDialogFor(BuildContext context, StudyCard card, bool isDarkMode) {
  showStrokeOrderDialog(context, card.kanjiVGCodes, isDarkMode);
}

// Lower-level version taking raw KanjiVG codes directly, for callers (e.g.
// reading/listening word lookups) that don't have a full StudyCard on hand.
void showStrokeOrderDialog(BuildContext context, List<String> kanjiVGCodes, bool isDarkMode) {
  if (kanjiVGCodes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No stroke order data found for this word')),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: StrokeOrderAnimator(
        kanjiVGCodes: kanjiVGCodes,
        isDarkMode: isDarkMode,
      ),
    ),
  );
}
