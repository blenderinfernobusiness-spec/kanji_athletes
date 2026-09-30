import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screenshot_saver.dart' as saver;
import 'study_data.dart';
import 'study_settings.dart';
import 'user_profile.dart';

// The three JLPT vocabulary-section styles this app's card data can support:
// kanji reading, orthography (choosing the right kanji for a reading), and
// vocabulary meaning. Real JLPT booklets group questions into labelled
// sections like this rather than mixing question styles freely.
enum _Section { reading, writing, vocabulary }

// Section titles and instructions are shown in Japanese by default, matching
// a real test booklet, with an English fallback toggled via the settings cog.
String _sectionTitle(_Section s, bool japanese) {
  if (japanese) {
    switch (s) {
      case _Section.reading:
        return '問題１：漢字の読み方';
      case _Section.writing:
        return '問題２：表記';
      case _Section.vocabulary:
        return '問題３：語彙';
    }
  }
  switch (s) {
    case _Section.reading:
      return 'Section 1 · Kanji Reading';
    case _Section.writing:
      return 'Section 2 · Orthography';
    case _Section.vocabulary:
      return 'Section 3 · Vocabulary';
  }
}

String _sectionInstruction(_Section s, bool japanese) {
  if (japanese) {
    switch (s) {
      case _Section.reading:
        return '正しい読み方を選んでください。';
      case _Section.writing:
        return '正しい漢字を選んでください。';
      case _Section.vocabulary:
        return '正しい意味を選んでください。';
    }
  }
  switch (s) {
    case _Section.reading:
      return 'Choose the correct reading.';
    case _Section.writing:
      return 'Choose the correct word.';
    case _Section.vocabulary:
      return 'Choose the correct meaning.';
  }
}

class _Question {
  final StudyCard card;
  final _Section section;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  String? selected;

  _Question({
    required this.card,
    required this.section,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
  });
}

// A JLPT-style vocabulary test, sat like a real exam: questions are grouped
// into labelled sections (reading / orthography / vocabulary), there's a
// running countdown timer, and - crucially - no answer is graded until the
// whole thing is submitted. You can move freely between questions to review
// or change an answer beforehand, the same as filling in an answer sheet.
class JlptTestGameScreen extends StatefulWidget {
  final String title;
  final List<StudyCard> questions;
  final bool isDarkMode;

  const JlptTestGameScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.isDarkMode,
  });

  @override
  State<JlptTestGameScreen> createState() => _JlptTestGameScreenState();
}

class _JlptTestGameScreenState extends State<JlptTestGameScreen> {
  static const int _secondsPerQuestion = 25;

  final Random _random = Random();
  UserProfile? _userProfile;
  final GlobalKey _wellDoneKey = GlobalKey();

  late List<_Question> _questions;
  int _index = 0;
  int _correctCount = 0;
  bool _finished = false;
  int _secondsRemaining = 0;
  Timer? _timer;
  StudySettings _settings = StudySettings();

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions(widget.questions);
    _loadUserProfile();
    _loadSettings();
    if (_questions.isEmpty) {
      _finished = true;
    } else {
      _secondsRemaining = _questions.length * _secondsPerQuestion;
    }
  }

  Future<void> _loadSettings() async {
    final settings = await loadStudySettings();
    if (!mounted) return;
    setState(() => _settings = settings);
    _startTimerIfNeeded();
  }

  // Starts the countdown if the timer setting is on, there's a test to sit,
  // and it isn't already ticking (so toggling the setting mid-test - or the
  // settings load resolving after initState - doesn't spawn a second timer).
  void _startTimerIfNeeded() {
    if (!_settings.jlptTimerEnabled || _finished || _questions.isEmpty || _timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Test Settings", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Japanese instructions",
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  "Standard for a real test. Turn off to show section titles and instructions in English instead.",
                  style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                ),
                value: _settings.jlptInstructionsInJapanese,
                activeColor: const Color(0xFF9A00FE),
                onChanged: (v) {
                  setDialogState(() => _settings.jlptInstructionsInJapanese = v);
                  setState(() {});
                  saveStudySettings(_settings);
                },
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Instant feedback",
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  "Off by default, like a real test. Turn on to see right/wrong as you answer.",
                  style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                ),
                value: _settings.jlptInstantFeedback,
                activeColor: const Color(0xFF9A00FE),
                onChanged: (v) {
                  setDialogState(() => _settings.jlptInstantFeedback = v);
                  setState(() {});
                  saveStudySettings(_settings);
                },
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  "Timer",
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                ),
                subtitle: Text(
                  "Counts down and auto-submits when it runs out. Turn off to take as long as you like.",
                  style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                ),
                value: _settings.jlptTimerEnabled,
                activeColor: const Color(0xFF9A00FE),
                onChanged: (v) {
                  setDialogState(() => _settings.jlptTimerEnabled = v);
                  setState(() {
                    if (v) {
                      _startTimerIfNeeded();
                    } else {
                      _stopTimer();
                    }
                  });
                  saveStudySettings(_settings);
                },
              ),
              const Divider(),
              Text(
                "Text size",
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
              ),
              Row(
                children: [
                  Text("A", style: TextStyle(fontSize: 14, color: widget.isDarkMode ? Colors.white54 : Colors.black45)),
                  Expanded(
                    child: Slider(
                      value: _settings.jlptTextScale,
                      min: 0.8,
                      max: 1.6,
                      divisions: 8,
                      activeColor: const Color(0xFF9A00FE),
                      label: '${(_settings.jlptTextScale * 100).round()}%',
                      onChanged: (v) {
                        setDialogState(() => _settings.jlptTextScale = v);
                        setState(() {});
                        saveStudySettings(_settings);
                      },
                    ),
                  ),
                  Text("A", style: TextStyle(fontSize: 22, color: widget.isDarkMode ? Colors.white54 : Colors.black45)),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  void _tick() {
    if (!mounted) return;
    if (_secondsRemaining <= 1) {
      setState(() => _secondsRemaining = 0);
      _submitTest();
    } else {
      setState(() => _secondsRemaining--);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    if (!mounted) return;
    setState(() => _userProfile = profile);
  }

  List<_Question> _buildQuestions(List<StudyCard> cards) {
    final kanaEligible = (List<StudyCard>.from(cards)..shuffle(_random))
        .where((c) => c.hiragana.trim().isNotEmpty && c.hiragana.trim() != c.japanese.trim())
        .toList();
    final half = (kanaEligible.length / 2).ceil();
    final readingCards = kanaEligible.take(half).toList();
    final writingCards = kanaEligible.skip(half).toList();
    final vocabCards = (List<StudyCard>.from(cards)..shuffle(_random))
        .where((c) => c.english.trim().isNotEmpty)
        .toList();

    final questions = <_Question>[];
    for (final c in readingCards) {
      questions.add(_makeQuestion(
        card: c,
        section: _Section.reading,
        prompt: c.japanese,
        correct: c.hiragana,
        pool: cards,
        field: (x) => x.hiragana,
      ));
    }
    for (final c in writingCards) {
      questions.add(_makeQuestion(
        card: c,
        section: _Section.writing,
        prompt: c.hiragana,
        correct: c.japanese,
        pool: cards,
        field: (x) => x.japanese,
      ));
    }
    for (final c in vocabCards) {
      questions.add(_makeQuestion(
        card: c,
        section: _Section.vocabulary,
        prompt: c.japanese,
        correct: c.english,
        pool: cards,
        field: (x) => x.english,
      ));
    }
    return questions;
  }

  _Question _makeQuestion({
    required StudyCard card,
    required _Section section,
    required String prompt,
    required String correct,
    required List<StudyCard> pool,
    required String Function(StudyCard) field,
  }) {
    final distractors = <String>[];
    final shuffledPool = List<StudyCard>.from(pool)..shuffle(_random);
    for (final other in shuffledPool) {
      if (other == card) continue;
      final value = field(other);
      if (value.trim().isNotEmpty && value != correct && !distractors.contains(value)) {
        distractors.add(value);
      }
      if (distractors.length >= 3) break;
    }
    final options = [correct, ...distractors]..shuffle(_random);
    return _Question(card: card, section: section, prompt: prompt, options: options, correctAnswer: correct);
  }

  void _selectAnswer(String option) {
    setState(() => _questions[_index].selected = option);
  }

  void _goNext() {
    if (_index + 1 < _questions.length) setState(() => _index++);
  }

  void _goPrev() {
    if (_index > 0) setState(() => _index--);
  }

  void _confirmSubmit() {
    final unanswered = _questions.where((q) => q.selected == null).length;
    if (unanswered == 0) {
      _submitTest();
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Submit Test?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          "You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}. Submit anyway?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Keep Going", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(dialogContext);
              _submitTest();
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _submitTest() {
    _stopTimer();
    var correct = 0;
    for (final q in _questions) {
      if (q.selected != null && q.selected == q.correctAnswer) correct++;
    }
    _correctCount = correct;
    if (_userProfile != null && correct > 0) {
      _userProfile!.addXp(correct * 10);
      _userProfile!.save();
    }
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('JLPT Test: ${widget.title}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_finished && _questions.isNotEmpty) ...[
            if (_settings.jlptTimerEnabled)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    _formatTime(_secondsRemaining),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining <= 30 ? Colors.redAccent : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.check_circle_outline),
              tooltip: 'Submit test',
              onPressed: _confirmSubmit,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Test settings',
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_settings.jlptTextScale)),
        child: SafeArea(
          child: _finished
              ? _buildResultsScreen(context)
              : _questions.isEmpty
                  ? Center(
                      child: Text(
                        "Not enough card data to build a test.",
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    )
                  : _buildQuestion(isDarkMode),
        ),
      ),
    );
  }

  Widget _buildQuestion(bool isDarkMode) {
    final question = _questions[_index];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / _questions.length,
                    backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                    color: const Color(0xFF9A00FE),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_index + 1} / ${_questions.length}',
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _sectionTitle(question.section, _settings.jlptInstructionsInJapanese),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF9A00FE)),
          ),
          const SizedBox(height: 4),
          Text(
            _sectionInstruction(question.section, _settings.jlptInstructionsInJapanese),
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.black45),
          ),
          const SizedBox(height: 16),
          Text(
            question.prompt,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 32),
          ...question.options.map((option) {
            final isSelected = option == question.selected;
            final showFeedback = _settings.jlptInstantFeedback && question.selected != null;
            final isCorrectOption = option == question.correctAnswer;
            Color? backgroundColor;
            Color borderColor = Colors.transparent;
            if (showFeedback && isCorrectOption) {
              backgroundColor = Colors.green.withValues(alpha: 0.2);
              borderColor = Colors.green;
            } else if (showFeedback && isSelected) {
              backgroundColor = Colors.redAccent.withValues(alpha: 0.2);
              borderColor = Colors.redAccent;
            } else if (isSelected) {
              backgroundColor = const Color(0xFF9A00FE).withValues(alpha: 0.2);
              borderColor = const Color(0xFF9A00FE);
            } else {
              backgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100];
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    side: BorderSide(color: borderColor, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _selectAnswer(option),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _index == 0 ? null : _goPrev,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text("Previous"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _index + 1 >= _questions.length ? _confirmSubmit : _goNext,
                  child: Text(_index + 1 >= _questions.length ? "Submit Test" : "Next"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnswerReview(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final maxH = MediaQuery.of(dialogContext).size.height * 0.8;
        return Dialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH, maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Answer Review",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _questions.length,
                      itemBuilder: (context, i) {
                        final q = _questions[i];
                        final correct = q.selected == q.correctAnswer;
                        return ListTile(
                          leading: Icon(
                            q.selected == null ? Icons.remove_circle_outline : (correct ? Icons.check_circle : Icons.cancel),
                            color: q.selected == null ? Colors.grey : (correct ? Colors.green : Colors.redAccent),
                          ),
                          title: Text(
                            q.prompt,
                            style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
                          ),
                          subtitle: Text(
                            q.selected == null
                                ? 'Not answered · Correct: ${q.correctAnswer}'
                                : correct
                                    ? 'Correct: ${q.correctAnswer}'
                                    : 'You answered: ${q.selected} · Correct: ${q.correctAnswer}',
                            style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsScreen(BuildContext context) {
    final total = _questions.length;
    final percent = total > 0 ? (_correctCount / total) * 100 : 0.0;
    final passed = percent >= 60;
    int xp = _userProfile?.xp ?? 0;
    int level = _userProfile?.level ?? 0;
    int xpNeeded = UserProfile.xpForLevel(level);
    double progress = xpNeeded > 0 ? xp / xpNeeded : 0.0;

    final bySection = <_Section, List<_Question>>{};
    for (final q in _questions) {
      bySection.putIfAbsent(q.section, () => []).add(q);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: RepaintBoundary(
          key: _wellDoneKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_userProfile != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Level $level',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                  ),
                  Text('XP: $xp / $xpNeeded', style: TextStyle(fontSize: 18, color: widget.isDarkMode ? Colors.white : Colors.black)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: widget.isDarkMode ? Colors.white12 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9A00FE)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Icon(Icons.emoji_events, color: Color(0xFF9A00FE), size: 64),
                const SizedBox(height: 16),
                Text(
                  'Test Complete!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16),
                if (total > 0) ...[
                  Text(
                    'Score: $_correctCount / $total (${percent.toStringAsFixed(0)}%)',
                    style: TextStyle(fontSize: 22, color: widget.isDarkMode ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: (passed ? Colors.green : Colors.redAccent).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      passed ? "Passing score (60%+)" : "Below passing (60%+)",
                      style: TextStyle(fontWeight: FontWeight.bold, color: passed ? Colors.green : Colors.redAccent),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Section Breakdown",
                          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 8),
                        for (final section in _Section.values)
                          if (bySection[section] != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_sectionTitle(section, _settings.jlptInstructionsInJapanese), style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
                                  Text(
                                    '${bySection[section]!.where((q) => q.selected == q.correctAnswer).length} / ${bySection[section]!.length}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => _showAnswerReview(context),
                    child: const Text("View Answer Review", style: TextStyle(color: Color(0xFF9A00FE))),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                  child: const Text('Finish'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final boundary = _wellDoneKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                      if (boundary == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not capture screenshot')));
                        return;
                      }
                      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
                      final int w = image.width;
                      final int h = image.height;
                      final ui.PictureRecorder recorder = ui.PictureRecorder();
                      final ui.Canvas canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
                      canvas.drawRect(
                        ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
                        ui.Paint()..color = widget.isDarkMode ? const ui.Color(0xFF2A2A2A) : const ui.Color(0xFFFFFFFF),
                      );
                      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
                      final ui.Image composed = await recorder.endRecording().toImage(w, h);
                      final ByteData? byteData = await composed.toByteData(format: ui.ImageByteFormat.png);
                      if (byteData == null) return;
                      final bytes = byteData.buffer.asUint8List();
                      final filename = 'kanji_skool_${DateTime.now().millisecondsSinceEpoch}.png';
                      final savedPath = await saver.savePng(bytes, filename);
                      if (!mounted) return;
                      if (savedPath != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved screenshot to $savedPath')));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloaded screenshot')));
                      }
                      final prefs = await SharedPreferences.getInstance();
                      final now = DateTime.now();
                      final today = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                      final last = prefs.getString('skool_share_last_date') ?? '';
                      if (last != today) {
                        _userProfile ??= await UserProfile.load();
                        if (_userProfile != null) {
                          _userProfile!.addXp(50);
                          await _userProfile!.save();
                          await prefs.setString('skool_share_last_date', today);
                          if (!mounted) return;
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You earned 50 XP for sharing today!')));
                        }
                      }
                      final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541');
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B), foregroundColor: Colors.white),
                  child: const Text('Share in skool!'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
