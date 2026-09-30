import 'package:flutter/material.dart';
import 'study_data.dart';
import 'audio_service.dart';
import 'user_profile.dart';
import 'card_edit_dialog.dart';
import 'writing_practice_canvas.dart';

// XP awarded per correct answer, matching the arcade modes and the regular
// spaced repetition screen's per-item reward.
const int _xpPerCorrectAnswer = 10;

// A lightweight flashcard reviewer for practising a set of cards - e.g. past
// mistakes - without touching any card's real spaced-repetition progress.
// The cards it's given are throwaway copies, so grading here never writes
// back to a deck. Still respects each card's own answer mode (basic/draw/
// type), just like the real spaced repetition screen.
class IsolatedFlashcardStudyScreen extends StatefulWidget {
  final String title;
  final List<StudyCard> cards;
  final bool isDarkMode;

  const IsolatedFlashcardStudyScreen({
    super.key,
    required this.title,
    required this.cards,
    required this.isDarkMode,
  });

  @override
  State<IsolatedFlashcardStudyScreen> createState() => _IsolatedFlashcardStudyScreenState();
}

class _IsolatedFlashcardStudyScreenState extends State<IsolatedFlashcardStudyScreen> {
  int _index = 0;
  int _correctCount = 0;

  // Per-attempt state, reset whenever the current card changes.
  bool _showAnswer = false; // basic mode's reveal gate
  bool _typeMismatched = false; // type mode: typed answer didn't match
  bool _drawAnswerRevealed = false; // draw mode: stroke order has been shown
  bool _memoryTechniqueRevealed = false;
  int _drawResetCounter = 0;
  final TextEditingController _typeController = TextEditingController();

  UserProfile? _userProfile;
  int _xpEarned = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _typeController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await UserProfile.load();
    if (!mounted) return;
    setState(() => _userProfile = profile);
  }

  String _japaneseText(StudyCard card) => card.hiragana.isNotEmpty ? card.hiragana : card.japanese;

  // Falls back to basic if a draw-mode card has no stroke data.
  String _effectiveMode(StudyCard card) =>
      (card.answerMode == 'draw' && card.kanjiVGCodes.isEmpty) ? 'basic' : card.answerMode;

  void _resetAttemptState() {
    _showAnswer = false;
    _typeMismatched = false;
    _drawAnswerRevealed = false;
    _memoryTechniqueRevealed = false;
    _typeController.clear();
    _drawResetCounter++;
  }

  void _showAnswerNow() => setState(() => _showAnswer = true);

  void _revealDrawAnswer(StudyCard card, bool isDarkMode) {
    setState(() => _drawAnswerRevealed = true);
  }

  bool _isTypedAnswerCorrect(StudyCard card, String typed) {
    final t = typed.trim().toLowerCase();
    if (t.isEmpty) return false;
    if (card.englishFirst) {
      return t == card.hiragana.trim().toLowerCase() || t == card.japanese.trim().toLowerCase();
    }
    return t == card.english.trim().toLowerCase();
  }

  void _submitTypedAnswer() {
    final card = widget.cards[_index];
    if (_isTypedAnswerCorrect(card, _typeController.text)) {
      _answer(true);
    } else {
      setState(() => _typeMismatched = true);
    }
  }

  void _answer(bool correct) {
    if (correct) {
      _xpEarned += _xpPerCorrectAnswer;
      _userProfile?.addXp(_xpPerCorrectAnswer);
      _userProfile?.save();
    }
    setState(() {
      if (correct) _correctCount++;
      _index++;
      _resetAttemptState();
    });
  }

  Widget _audioButton(String text, String language) {
    return IconButton(
      icon: const Icon(Icons.volume_up),
      color: const Color(0xFF9A00FE),
      tooltip: 'Play audio',
      onPressed: () async {
        final ok = await AudioService().speak(text, language);
        if (!ok && mounted) {
          showMissingVoiceSnackBar(context, widget.isDarkMode, language);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: widget.cards.isEmpty
            ? _buildMessage(isDarkMode, "No mistakes in this range - nice work!")
            : _index >= widget.cards.length
                ? _buildMessage(
                    isDarkMode,
                    "Done!\n$_correctCount / ${widget.cards.length} correct.\n+$_xpEarned XP earned",
                  )
                : _buildCard(isDarkMode),
      ),
    );
  }

  Widget _buildMessage(bool isDarkMode, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradingButtons() {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _answer(false),
              child: const Text("Incorrect", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _answer(true),
              child: const Text("Correct", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _memoryTechniqueSection(StudyCard card, bool isDarkMode) {
    if (card.memoryTechnique.isEmpty) return const SizedBox.shrink();
    if (!_memoryTechniqueRevealed) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextButton.icon(
          onPressed: () => setState(() => _memoryTechniqueRevealed = true),
          icon: const Icon(Icons.psychology, color: Color(0xFF9A00FE)),
          label: const Text("Memory Technique", style: TextStyle(color: Color(0xFF9A00FE))),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          card.memoryTechnique,
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _revealBlock(StudyCard card, bool isDarkMode, bool frontIsEnglish) {
    return Column(
      children: [
        if (frontIsEnglish)
          Text(
            card.japanese,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        Text(
          card.hiragana,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: isDarkMode ? Colors.white70 : Colors.black87),
        ),
        if (card.romaji.isNotEmpty)
          Text(
            card.romaji,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white54 : Colors.black54),
          ),
        if (!frontIsEnglish) ...[
          const SizedBox(height: 12),
          Text(
            card.english,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
        _audioButton(
          frontIsEnglish ? _japaneseText(card) : card.english,
          frontIsEnglish ? 'Japanese' : 'English',
        ),
        _memoryTechniqueSection(card, isDarkMode),
      ],
    );
  }

  Widget _buildCard(bool isDarkMode) {
    final card = widget.cards[_index];
    final frontIsEnglish = card.englishFirst;
    final mode = _effectiveMode(card);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Card ${_index + 1} of ${widget.cards.length}',
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 24),
          Text(
            frontIsEnglish ? card.english : card.japanese,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: frontIsEnglish ? 32 : 48,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          _audioButton(
            frontIsEnglish ? card.english : _japaneseText(card),
            frontIsEnglish ? 'English' : 'Japanese',
          ),
          const SizedBox(height: 16),

          if (mode == 'basic' && _showAnswer) ...[
            _revealBlock(card, isDarkMode, frontIsEnglish),
            const SizedBox(height: 24),
          ],

          if (mode == 'draw') ...[
            WritingPracticeCanvas(
              key: ValueKey('draw-$_index-$_drawResetCounter'),
              kanjiVGCodes: card.kanjiVGCodes,
              isDarkMode: isDarkMode,
              kanji: card.japanese,
              translation: card.english,
              hideButtons: true,
              showAnswerOverride: _drawAnswerRevealed,
              resetCounter: _drawResetCounter,
              scale: (MediaQuery.of(context).size.width / 600).clamp(0.6, 1.2) * 0.8,
            ),
            const SizedBox(height: 16),
            if (!_drawAnswerRevealed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _revealDrawAnswer(card, isDarkMode),
                  child: const Text("Show Answer", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              )
            else
              TextButton.icon(
                onPressed: () => showStrokeOrderDialogFor(context, card, isDarkMode),
                icon: const Icon(Icons.gesture, color: Color(0xFF9A00FE)),
                label: const Text("View stroke order again", style: TextStyle(color: Color(0xFF9A00FE))),
              ),
            if (_drawAnswerRevealed) _memoryTechniqueSection(card, isDarkMode),
            const SizedBox(height: 16),
          ],

          if (mode == 'type' && !_typeMismatched) ...[
            TextField(
              controller: _typeController,
              textAlign: TextAlign.center,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 18),
              decoration: InputDecoration(
                hintText: frontIsEnglish ? 'Type the Japanese' : 'Type the English',
                hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _submitTypedAnswer(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _submitTypedAnswer,
                child: const Text("Submit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (mode == 'type' && _typeMismatched) ...[
            _revealBlock(card, isDarkMode, frontIsEnglish),
            const SizedBox(height: 24),
          ],

          if (mode == 'basic' && !_showAnswer)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _showAnswerNow,
                child: const Text("Show Answer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          else if ((mode == 'basic' && _showAnswer) ||
              (mode == 'draw' && _drawAnswerRevealed) ||
              (mode == 'type' && _typeMismatched))
            _gradingButtons(),
        ],
      ),
    );
  }
}
