import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'listening_player.dart' show WordPopupCard, DeckPickerDialog;
import 'study_data.dart';
import 'study_settings.dart';

const Color _accent = Color(0xFF9A00FE);

// Word lookup used by every immersion video screen, so a tapped word behaves
// the same whether it came from the overlay player or the subtitle panel.

void showImmersionKnownWord(
  BuildContext context, {
  required HighlightEntry entry,
  required bool isDarkMode,
  required StudySettings settings,
  required Map<String, HighlightEntry> highlightIndex,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.all(16),
      child: WordPopupCard(
        entry: entry,
        isDarkMode: isDarkMode,
        width: double.infinity,
        settings: settings,
        highlightIndex: highlightIndex,
        onClose: () => Navigator.pop(sheetContext),
        onAddToDeck: (toAdd) {
          Navigator.pop(sheetContext);
          addImmersionEntryToDeck(context, entry: toAdd, isDarkMode: isDarkMode);
        },
        onEditMemoryTechnique: () {
          Navigator.pop(sheetContext);
          editImmersionMemoryTechnique(context, entry: entry, isDarkMode: isDarkMode);
        },
        onOpenKanji: (kEntry) {
          Navigator.pop(sheetContext);
          showImmersionKnownWord(
            context,
            entry: kEntry,
            isDarkMode: isDarkMode,
            settings: settings,
            highlightIndex: highlightIndex,
          );
        },
      ),
    ),
  );
}

void showImmersionUnknownText(BuildContext context, {required String text, required bool isDarkMode}) {
  final meaningController = TextEditingController();
  showModalBottomSheet(
    context: context,
    backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            "Not in your dictionary/decks",
            style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              final url = 'https://translate.google.com/?sl=ja&tl=en&text=${Uri.encodeComponent(text)}&op=translate';
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            icon: const Icon(Icons.translate, color: _accent),
            label: const Text("Open in Google Translate", style: TextStyle(color: _accent)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: meaningController,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: "English meaning (optional, for adding to a deck)",
              hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(sheetContext);
                await addImmersionRawTextToDeck(
                  context,
                  text: text,
                  meaning: meaningController.text.trim(),
                  isDarkMode: isDarkMode,
                );
              },
              child: const Text("Add to deck"),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> addImmersionEntryToDeck(
  BuildContext context, {
  required HighlightEntry entry,
  required bool isDarkMode,
}) async {
  final decks = await loadStudyDecks();
  if (!context.mounted) return;
  final chosen = await showDialog<StudyDeck>(
    context: context,
    builder: (context) => DeckPickerDialog(decks: decks, isDarkMode: isDarkMode),
  );
  if (chosen == null || !context.mounted) return;

  final card = StudyCard(
    japanese: entry.japanese,
    hiragana: entry.reading,
    english: entry.meaning,
    kanjiVGCodes: findKanjiVGCodesForWord(entry.japanese),
  );
  chosen.cards.add(card);
  await saveStudyDecks(decks);
  if (!context.mounted) return;
  entry.isDeckWord = true;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${entry.japanese}" to ${chosen.name}')));
}

Future<void> addImmersionRawTextToDeck(
  BuildContext context, {
  required String text,
  required String meaning,
  required bool isDarkMode,
}) async {
  final decks = await loadStudyDecks();
  if (!context.mounted) return;
  final chosen = await showDialog<StudyDeck>(
    context: context,
    builder: (context) => DeckPickerDialog(decks: decks, isDarkMode: isDarkMode),
  );
  if (chosen == null || !context.mounted) return;

  final card = StudyCard(japanese: text, hiragana: '', english: meaning);
  chosen.cards.add(card);
  await saveStudyDecks(decks);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "$text" to ${chosen.name}')));
}

Future<void> editImmersionMemoryTechnique(
  BuildContext context, {
  required HighlightEntry entry,
  required bool isDarkMode,
}) async {
  final controller = TextEditingController(text: entry.memoryTechnique);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        entry.memoryTechnique.isEmpty ? "Add Memory Technique" : "Edit Memory Technique",
        style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: 4,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "e.g. a mnemonic or memory aid",
          hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
          filled: true,
          fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text("Save"),
        ),
      ],
    ),
  );
  if (result == null || !context.mounted) return;

  final technique = result.trim();
  entry.memoryTechnique = technique;
  entry.card?.memoryTechnique = technique;

  final decks = await loadStudyDecks();
  var changed = false;
  for (final deck in decks) {
    for (final card in deck.cards) {
      if (card.japanese.trim() == entry.japanese) {
        card.memoryTechnique = technique;
        changed = true;
      }
    }
  }
  if (changed) await saveStudyDecks(decks);
}
