import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'screenshot_saver.dart' as saver;
import 'dart:ui' as ui;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'study_data.dart';
import 'writing_practice_canvas.dart';
import 'card_edit_dialog.dart';
import 'user_profile.dart';

// Animated stars widget for well done screen
class _AnimatedStars extends StatefulWidget {
  final int stars;
  const _AnimatedStars({required this.stars});

  @override
  State<_AnimatedStars> createState() => _AnimatedStarsState();
}

class _AnimatedStarsState extends State<_AnimatedStars> {
  int _shownStars = 0;

  @override
  void initState() {
    super.initState();
    _animateStars();
  }

  void _animateStars() async {
    for (int i = 1; i <= widget.stars; i++) {
      await Future.delayed(const Duration(milliseconds: 220));
      if (!mounted) return;
      setState(() {
        _shownStars = i;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: i < _shownStars
            ? Icon(Icons.star, key: ValueKey('star-$i'), color: const Color(0xFFFFC107), size: 36)
            : Icon(Icons.star_border, key: ValueKey('star-border-$i'), color: Colors.grey.withAlpha(128), size: 36),
      )),
    );
  }
}

// Writing game: shows the English meaning, the user draws the Japanese in
// the box, then self-marks against the revealed answer. Ported from the old
// standalone Arcade's writing mode to run against a Study deck's own cards
// instead of a Library ItemSet.
class WritingGameScreen extends StatefulWidget {
  final String title;
  final List<StudyCard> questions;
  final bool isDarkMode;

  const WritingGameScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.isDarkMode,
  });

  @override
  State<WritingGameScreen> createState() => _WritingGameScreenState();
}

class _WritingGameScreenState extends State<WritingGameScreen> {
  UserProfile? _userProfile;
  final GlobalKey _wellDoneKey = GlobalKey();
  bool _finished = false;
  final List<StudyCard> _correctAnswers = [];
  final List<StudyCard> _wrongAnswers = [];
  late ScrollController _correctScrollController;
  late ScrollController _wrongScrollController;
  late List<StudyCard> _questions;
  int _currentIndex = 0;
  int _canvasResetCounter = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  bool _marked = false;

  @override
  void initState() {
    super.initState();
    _generateQuestions();
    _loadUserProfile();
    _correctScrollController = ScrollController();
    _wrongScrollController = ScrollController();
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
    });
  }

  void _generateQuestions() {
    _questions = List<StudyCard>.from(widget.questions)..shuffle();
    _currentIndex = 0;
    _showResult = false;
    _isCorrect = false;
    _marked = false;
  }

  @override
  void dispose() {
    _correctScrollController.dispose();
    _wrongScrollController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    setState(() {
      _showResult = true;
      _marked = false;
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _showResult = false;
      _isCorrect = false;
      _marked = false;
      _canvasResetCounter++;
    });
  }

  void _markAnswer(bool correct) {
    setState(() {
      _isCorrect = correct;
      _marked = true;
      if (_marked && _currentIndex < _questions.length) {
        if (correct) {
          _correctAnswers.add(_questions[_currentIndex]);
          if (_userProfile != null) {
            _userProfile!.addXp(10);
            _userProfile!.save();
          }
        } else {
          _wrongAnswers.add(_questions[_currentIndex]);
        }
      }
    });
    if (_currentIndex < _questions.length - 1) {
      Future.delayed(Duration(milliseconds: correct ? 500 : 1000), () {
        if (mounted && _marked && _currentIndex < _questions.length - 1) {
          _nextQuestion();
        }
      });
    }
  }

  void _toggleStar(StudyCard card) {
    setState(() => card.isStarred = !card.isStarred);
    updateCardInAllDecks(card.japanese, (c) => c.isStarred = card.isStarred);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex >= _questions.length - 1;
    final finished = _finished;
    final card = !finished ? _questions[_currentIndex] : null;
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Writing: ${widget.title}', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!finished)
            IconButton(
              icon: Icon(Icons.flag, color: widget.isDarkMode ? Colors.white : Colors.black),
              tooltip: 'Complete Session',
              onPressed: () {
                setState(() {
                  _finished = true;
                });
              },
            ),
        ],
      ),
      body: Center(
        child: finished
            ? _buildWellDoneScreen(context)
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Builder(builder: (context) {
                  final width = MediaQuery.of(context).size.width;
                  final bool isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
                  double uiScale = 1.0;
                  if (isAndroid) {
                    if (width < 360) {
                      uiScale = 0.78;
                    } else if (width < 420) {
                      uiScale = 0.86;
                    } else {
                      uiScale = 0.92;
                    }
                  }

                  return Transform.scale(
                    scale: uiScale,
                    alignment: Alignment.topCenter,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                    if (_userProfile != null)
                      Text('Level: ${_userProfile!.level}   XP: ${_userProfile!.xp}',
                        style: TextStyle(fontSize: 18, color: widget.isDarkMode ? Colors.amber : Colors.deepPurple)),
                    Text('Question ${_currentIndex + 1} of ${_questions.length}',
                      style: TextStyle(fontSize: 18, color: widget.isDarkMode ? Colors.white : Colors.black)),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / _questions.length,
                      backgroundColor: widget.isDarkMode ? Colors.white12 : Colors.black12,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9A00FE)),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 14),
                    if (card != null) ...[
                      Text(
                        card.english,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              card.isStarred ? Icons.star : Icons.star_border,
                              color: card.isStarred ? const Color(0xFFFFC107) : (widget.isDarkMode ? Colors.white : Colors.black),
                            ),
                            tooltip: card.isStarred ? 'Unstar card' : 'Star card',
                            onPressed: () => _toggleStar(card),
                          ),
                        ],
                      ),
                      if (_showResult) ...[
                        const SizedBox(height: 8),
                        Text(
                          card.japanese,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    if (card != null)
                      WritingPracticeCanvas(
                        key: ValueKey(_canvasResetCounter),
                        kanjiVGCodes: card.kanjiVGCodes,
                        isDarkMode: widget.isDarkMode,
                        kanji: card.japanese,
                        translation: card.english,
                        scale: (isAndroid ? (MediaQuery.of(context).size.width < 420 ? 0.86 : 0.92) : 1.0),
                        hideButtons: true,
                        hideCanvas: false,
                        showHintByDefault: false,
                        resetCounter: _canvasResetCounter,
                      ),
                    const SizedBox(height: 12),
                    if (card != null)
                      ElevatedButton.icon(
                        onPressed: () => showStrokeOrderDialogFor(context, card, widget.isDarkMode),
                        icon: const Icon(Icons.remove_red_eye, size: 20),
                        label: const Text('View Stroke Order'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A3A3A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (!_showResult)
                      ElevatedButton(
                        onPressed: _checkAnswer,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
                        child: const Text('Enter'),
                      )
                    else if (!_marked)
                      Column(
                        children: [
                          Text(
                            'Did you get it right?',
                            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _markAnswer(true),
                                icon: const Icon(Icons.check, color: Colors.white),
                                label: const Text('Right'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: () => _markAnswer(false),
                                icon: const Icon(Icons.close, color: Colors.white),
                                label: const Text('Wrong'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Check if your writing matches the answer above and mark yourself as correct or incorrect.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Icon(_isCorrect ? Icons.check_circle : Icons.cancel,
                              color: _isCorrect ? Colors.green : Colors.red, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            _isCorrect ? 'Correct' : 'Incorrect',
                            style: TextStyle(fontSize: 20, color: _isCorrect ? Colors.green : Colors.red),
                          ),
                          const SizedBox(height: 16),
                          if (!isLast && !_marked)
                            ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
                              child: const Text('Next'),
                            ),
                          if (isLast && _marked)
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _finished = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
                              child: const Text('Finish'),
                            ),
                        ],
                      ),
                        ],
                    ),
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildWellDoneScreen(BuildContext context) {
    final correct = _correctAnswers.length;
    int completedRounds = _finished ? (_correctAnswers.length + _wrongAnswers.length) : _questions.length;
    final percent = completedRounds > 0 ? (correct / completedRounds) * 100 : 0.0;
    int stars = 0;
    if (percent >= 100) {
      stars = 5;
    } else if (percent >= 80) {
      stars = 4;
    } else if (percent >= 60) {
      stars = 3;
    } else if (percent >= 40) {
      stars = 2;
    } else if (percent >= 20) {
      stars = 1;
    }
    int xp = _userProfile?.xp ?? 0;
    int level = _userProfile?.level ?? 0;
    int xpNeeded = UserProfile.xpForLevel(level);
    double progress = xpNeeded > 0 ? xp / xpNeeded : 0.0;
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
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black,
              ),
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
          Text('Well done!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 12),
          _AnimatedStars(stars: stars),
          const SizedBox(height: 6),
                    Text('Score: $correct / $completedRounds', style: TextStyle(fontSize: 22, color: widget.isDarkMode ? Colors.white : Colors.black)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final maxH = MediaQuery.of(context).size.height * 0.8;
                  final listHeight = (maxH - 160).clamp(120.0, maxH);
                  return Dialog(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxH, maxWidth: 800),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TabBar(
                                labelColor: const Color(0xFF9A00FE),
                                unselectedLabelColor: Colors.grey,
                                tabs: const [Tab(text: 'Correct'), Tab(text: 'Wrong')],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: listHeight,
                                child: TabBarView(
                                  children: [
                                    Scrollbar(
                                      controller: _correctScrollController,
                                      child: ListView.builder(
                                        controller: _correctScrollController,
                                        itemCount: _correctAnswers.length,
                                        itemBuilder: (context, i) {
                                          final card = _correctAnswers[i];
                                          return ListTile(
                                            title: Text(card.japanese, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text(card.english),
                                          );
                                        },
                                      ),
                                    ),
                                    Scrollbar(
                                      controller: _wrongScrollController,
                                      child: ListView.builder(
                                        controller: _wrongScrollController,
                                        itemCount: _wrongAnswers.length,
                                        itemBuilder: (context, i) {
                                          final card = _wrongAnswers[i];
                                          return ListTile(
                                            title: Text(card.japanese, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text(card.english),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
            child: const Text('View Details'),
          ),
          const SizedBox(height: 16),
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
                final today = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
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
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How Stars Work'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('★ 0 stars: < 20% correct'),
                      Text('★ 1 star: 20–39% correct'),
                      Text('★ 2 stars: 40–59% correct'),
                      Text('★ 3 stars: 60–79% correct'),
                      Text('★ 4 stars: 80–99% correct'),
                      Text('★ 5 stars: 100% correct'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Text(
                'How stars work',
                style: TextStyle(
                  color: Colors.grey.withAlpha(179),
                  fontSize: 14,
                  fontStyle: FontStyle.normal,
                  decoration: TextDecoration.none,
                ),
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
