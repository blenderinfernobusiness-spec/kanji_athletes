import 'package:flutter/material.dart';
import 'sets_data.dart';
import 'study_data.dart';
import 'card_edit_dialog.dart';

class DeckDetailScreen extends StatefulWidget {
  final StudyDeck deck;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final VoidCallback onChanged;
  // Raw actions (no confirmation of their own) - this screen shows its own
  // "are you sure" dialog before calling either, since they mutate the deck
  // list owned by the Study screen rather than this deck in place.
  final Future<void> Function() onDelete;
  final Future<void> Function() onDuplicate;

  const DeckDetailScreen({
    super.key,
    required this.deck,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onChanged,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  State<DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends State<DeckDetailScreen> {
  bool _selectionMode = false;
  final Set<StudyCard> _selected = {};

  void _startSelection(StudyCard card) {
    setState(() {
      _selectionMode = true;
      _selected.add(card);
    });
  }

  void _toggleSelection(StudyCard card) {
    setState(() {
      if (_selected.contains(card)) {
        _selected.remove(card);
        if (_selected.isEmpty) _selectionMode = false;
      } else {
        _selected.add(card);
      }
    });
  }

  // Deferred to after the current frame: this is called from a button that
  // lives inside the app bar this state change removes/rebuilds, so calling
  // setState synchronously here hits "widget tree was locked" (unlike the
  // dialog-routed bulk actions below, which have a route boundary first).
  void _exitSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectionMode = false;
        _selected.clear();
      });
    });
  }

  void _showDeckSettingsDialog() {
    final isChallengeDeck = widget.deck.challengeStartDate != null;
    final controller = TextEditingController(text: widget.deck.newCardsPerDay.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Deck Settings",
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...isChallengeDeck
                ? [
                    Text(
                      "New cards per day",
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "This is a day-by-day challenge deck, so new kanji unlock automatically on their own schedule instead of a fixed daily number.",
                      style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                    ),
                  ]
                : [
                    Text(
                      "New cards per day",
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Limits how many never-studied cards Spaced Repetition introduces in a single day.",
                      style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.build, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              title: Text(
                "Manage Deck",
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Rename, duplicate, reset progress, or delete",
                style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black45),
              ),
              onTap: () {
                Navigator.pop(context);
                _showManageDeckMenu();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isChallengeDeck ? "Close" : "Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          if (!isChallengeDeck)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value < 0) return;
                setState(() => widget.deck.newCardsPerDay = value);
                widget.onChanged();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
        ],
      ),
    );
  }

  void _showManageDeckMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.deck.name,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Rename"),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDeckDialog();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text("Duplicate"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDuplicateDeck();
                },
              ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text("Reset Progress"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmResetDeckProgress();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text("Delete Deck", style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteDeck();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRenameDeckDialog() {
    final controller = TextEditingController(text: widget.deck.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Rename Deck", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: "Deck name",
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              setState(() => widget.deck.name = name);
              widget.onChanged();
              Navigator.pop(dialogContext);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _confirmDuplicateDeck() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Duplicate Deck?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          'This will create a copy of "${widget.deck.name}", including all its cards and progress.',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await widget.onDuplicate();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deck duplicated')),
              );
            },
            child: const Text("Duplicate"),
          ),
        ],
      ),
    );
  }

  void _confirmResetDeckProgress() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Reset Progress?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          'This marks every card in "${widget.deck.name}" as new again${widget.deck.challengeStartDate != null ? " and restarts its challenge schedule from day 1" : ""}. This cannot be undone.',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => resetDeckProgress(widget.deck));
              widget.onChanged();
              Navigator.pop(dialogContext);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDeck() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Deck?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          'This will permanently delete "${widget.deck.name}" and all ${widget.deck.cards.length} card${widget.deck.cards.length == 1 ? '' : 's'} in it. This cannot be undone.',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await widget.onDelete();
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected() {
    final count = _selected.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete $count card${count == 1 ? '' : 's'}?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          "This cannot be undone.",
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                widget.deck.cards.removeWhere((c) => _selected.contains(c));
                _selectionMode = false;
                _selected.clear();
              });
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // Same deferred-setState reasoning as _exitSelection above: this button
  // lives in the app bar that this state change rebuilds.
  void _duplicateSelected() {
    final copies = _selected
        .map((c) => StudyCard(
              japanese: c.japanese,
              hiragana: c.hiragana,
              romaji: c.romaji,
              english: c.english,
              kanjiVGCodes: List<String>.from(c.kanjiVGCodes),
              englishFirst: c.englishFirst,
              answerMode: c.answerMode,
              cardType: c.cardType,
            ))
        .toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        widget.deck.cards.addAll(copies);
        _selectionMode = false;
        _selected.clear();
      });
      widget.onChanged();
    });
  }

  void _confirmResetProgressSelected() {
    final count = _selected.length;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Reset progress for $count card${count == 1 ? '' : 's'}?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          "Their spaced repetition progress will go back to new. This cannot be undone.",
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A00FE),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                for (final c in _selected) {
                  resetCardProgress(c);
                }
                _selectionMode = false;
                _selected.clear();
              });
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _showAnswerModeOverrideDialog() {
    String mode = 'basic';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Set Answer Mode",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: SizedBox(
            width: 280,
            child: answerModeField(
              value: mode,
              isDarkMode: widget.isDarkMode,
              onChanged: (value) {
                if (value != null) setDialogState(() => mode = value);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  for (final c in _selected) {
                    c.answerMode = mode;
                  }
                  _selectionMode = false;
                  _selected.clear();
                });
                widget.onChanged();
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardTypeOverrideDialog() {
    String type = 'Vocab';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Set Card Type",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: SizedBox(
            width: 280,
            child: cardTypeField(
              value: type,
              isDarkMode: widget.isDarkMode,
              onChanged: (value) {
                if (value != null) setDialogState(() => type = value);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  for (final c in _selected) {
                    c.cardType = type;
                  }
                  _selectionMode = false;
                  _selected.clear();
                });
                widget.onChanged();
                Navigator.pop(context);
              },
              child: const Text("Apply"),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
      filled: true,
      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Fills in the card fields from a chosen dictionary entry. Kana entries
  // store their romaji in `translation`, so the mapping differs by type.
  // Returns the card type ('Kanji'/'Kana'/'Vocab') implied by the entry.
  String _applyDictionaryItem(
    Item item, {
    required TextEditingController japaneseController,
    required TextEditingController hiraganaController,
    required TextEditingController romajiController,
    required TextEditingController englishController,
  }) {
    japaneseController.text = item.japanese;
    if (item.itemType == 'Hiragana' || item.itemType == 'Katakana') {
      hiraganaController.text = item.japanese;
      romajiController.text = item.translation;
      englishController.text = '';
      return 'Kana';
    } else if (item.itemType == 'Vocab') {
      hiraganaController.text = item.reading;
      englishController.text = item.translation;
      return 'Vocab';
    } else {
      hiraganaController.text = item.kunYomi.isNotEmpty ? item.kunYomi : item.onYomi;
      englishController.text = item.translation;
      return 'Kanji';
    }
  }

  void _showAddCardDialog() {
    final japaneseController = TextEditingController();
    final hiraganaController = TextEditingController();
    final romajiController = TextEditingController();
    final englishController = TextEditingController();
    final memoryTechniqueController = TextEditingController();
    List<Item> searchResults = [];
    String answerMode = 'basic';
    String cardType = 'Vocab';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Add Card",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
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
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: _fieldDecoration("Japanese"),
                onChanged: (value) {
                  setDialogState(() {
                    searchResults = searchDictionaryItems(value);
                  });
                },
              ),
              Visibility(
                visible: searchResults.isNotEmpty,
                maintainState: true,
                child: Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 160),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final item = searchResults[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.japanese,
                          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        ),
                        subtitle: Text(
                          item.translation,
                          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9A00FE).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.itemType,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9A00FE),
                            ),
                          ),
                        ),
                        onTap: () {
                          final impliedType = _applyDictionaryItem(
                            item,
                            japaneseController: japaneseController,
                            hiraganaController: hiraganaController,
                            romajiController: romajiController,
                            englishController: englishController,
                          );
                          FocusScope.of(context).unfocus();
                          setDialogState(() {
                            searchResults = [];
                            cardType = impliedType;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hiraganaController,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: _fieldDecoration("Japanese (hiragana)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: romajiController,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: _fieldDecoration("Romaji (optional)"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: englishController,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: _fieldDecoration("English"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: memoryTechniqueController,
                maxLines: 3,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: _fieldDecoration("Memory technique (optional)"),
              ),
              const SizedBox(height: 12),
              answerModeField(
                value: answerMode,
                isDarkMode: widget.isDarkMode,
                onChanged: (value) {
                  if (value != null) setDialogState(() => answerMode = value);
                },
              ),
              const SizedBox(height: 12),
              cardTypeField(
                value: cardType,
                isDarkMode: widget.isDarkMode,
                onChanged: (value) {
                  if (value != null) setDialogState(() => cardType = value);
                },
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
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
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

              final card = StudyCard(
                japanese: japanese,
                hiragana: hiragana,
                romaji: romajiController.text.trim(),
                english: english,
                kanjiVGCodes: findKanjiVGCodesForWord(japanese),
                answerMode: answerMode,
                memoryTechnique: memoryTechniqueController.text.trim(),
                cardType: cardType,
              );

              setState(() {
                widget.deck.cards.add(card);
              });
              widget.onChanged();
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: _selectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel selection',
                onPressed: _exitSelection,
              ),
              title: Text('${_selected.length} selected'),
              backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Duplicate',
                  onPressed: _duplicateSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  tooltip: 'Set answer mode',
                  onPressed: _showAnswerModeOverrideDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.category_outlined),
                  tooltip: 'Set card type',
                  onPressed: _showCardTypeOverrideDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  tooltip: 'Reset progress',
                  onPressed: _confirmResetProgressSelected,
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete',
                  onPressed: _confirmDeleteSelected,
                ),
              ],
            )
          : AppBar(
              title: Text(widget.deck.name),
              backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Deck settings',
                  onPressed: _showDeckSettingsDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddCardDialog,
                ),
              ],
            ),
      body: widget.deck.cards.isEmpty
          ? Center(
              child: Text(
                "No cards yet.\nTap + to add one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
            )
          : widget.deck.challengeStartDate != null
              ? _buildGroupedByDayList()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: widget.deck.cards.length,
                  itemBuilder: (context, index) => _buildCardTile(widget.deck.cards[index]),
                ),
    );
  }

  // Day-scheduled challenge decks (e.g. the 90 Day Kanji Challenge) group
  // their cards under a "Day N" header per the card's own challengeDay,
  // rather than one flat list - cards without a day (shouldn't normally
  // happen for these decks) land under "Unassigned".
  Widget _buildGroupedByDayList() {
    final groups = <int, List<StudyCard>>{};
    for (final card in widget.deck.cards) {
      groups.putIfAbsent(card.challengeDay ?? 0, () => []).add(card);
    }
    final days = groups.keys.toList()..sort();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              day == 0 ? 'Unassigned' : 'Day $day',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9A00FE)),
            ),
          ),
          for (final card in groups[day]!) _buildCardTile(card),
        ],
      ],
    );
  }

  Widget _buildCardTile(StudyCard card) {
    final isSelected = _selected.contains(card);
    return Card(
      color: isSelected
          ? const Color(0xFF9A00FE).withValues(alpha: 0.15)
          : widget.isDarkMode
              ? const Color(0xFF2A2A2A)
              : Colors.grey[100],
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: _selectionMode ? () => _toggleSelection(card) : null,
        onLongPress: () => _selectionMode ? _toggleSelection(card) : _startSelection(card),
        leading: _selectionMode
            ? Checkbox(
                value: isSelected,
                activeColor: const Color(0xFF9A00FE),
                onChanged: (_) => _toggleSelection(card),
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              card.japanese,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF9A00FE).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                card.cardType,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9A00FE)),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                card.hiragana,
                if (card.romaji.isNotEmpty) card.romaji,
                card.english,
              ].join(' · '),
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              '${dueLabel(card)} · Progress: ${card.progress}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF9A00FE),
              ),
            ),
          ],
        ),
        trailing: _selectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    tooltip: 'Edit card',
                    onPressed: () => showEditCardDialog(
                      context,
                      card,
                      widget.isDarkMode,
                      () {
                        setState(() {});
                        widget.onChanged();
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.gesture,
                      color: card.kanjiVGCodes.isNotEmpty
                          ? const Color(0xFF9A00FE)
                          : Colors.grey,
                    ),
                    tooltip: 'View stroke order',
                    onPressed: () => showStrokeOrderDialogFor(context, card, widget.isDarkMode),
                  ),
                ],
              ),
      ),
    );
  }
}
