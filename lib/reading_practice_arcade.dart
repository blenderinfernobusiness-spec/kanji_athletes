import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'sets_data.dart';
import 'user_profile.dart';
import 'set_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingPracticeArcadeScreen extends StatefulWidget {
  final ItemSet itemSet;
  final int numberOfRounds;
  final bool roundForEveryItem;
  final bool roundForEveryStarred;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ReadingPracticeArcadeScreen({
    super.key,
    required this.itemSet,
    required this.numberOfRounds,
    required this.roundForEveryItem,
    required this.roundForEveryStarred,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ReadingPracticeArcadeScreen> createState() => _ReadingPracticeArcadeScreenState();
}

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
          : Icon(
            Icons.star_border,
            key: ValueKey('star-border-$i'),
            color: Color.fromRGBO(128, 128, 128, 0.5),
            size: 36,
            ),
      )),
    );
  }
  
}

class _ReadingPracticeArcadeScreenState extends State<ReadingPracticeArcadeScreen> {
  UserProfile? _userProfile;
  final GlobalKey _wellDoneKey = GlobalKey();
  bool _finished = false;
  final List<Item> _correctAnswers = [];
  final List<Item> _wrongAnswers = [];
  late ScrollController _correctScrollController;
  late ScrollController _wrongScrollController;
  late List<Item> _questions;
  int _currentIndex = 0;
  bool _showResult = false;
  bool? _isCorrect = false;
  final TextEditingController _answerController = TextEditingController();

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
    setState(() {
      _userProfile = profile;
    });
  }

  void _generateQuestions() {
    List<Item> items = widget.itemSet.items;
    if (widget.roundForEveryStarred) {
      items = items.where((item) => item.isStarred).toList();
    }
    if (widget.roundForEveryItem) {
      _questions = List<Item>.from(items)..shuffle();
    } else {
      _questions = List<Item>.from(items)..shuffle();
      if (_questions.length > widget.numberOfRounds) {
        _questions = _questions.sublist(0, widget.numberOfRounds);
      }
    }
    _currentIndex = 0;
    _showResult = false;
    _isCorrect = false;
    _answerController.clear();
  }

  void _checkAnswer() {
    setState(() {
      _showResult = true;
      final item = _questions[_currentIndex];
      final userInput = _answerController.text.trim().toLowerCase();
      String correctAnswer = '';
      if (item.itemType.toLowerCase() == 'kanji') {
        // For Kanji, user always marks correct/incorrect manually
        _isCorrect = null;
        // Optionally, you could check if userInput matches any reading and suggest, but do not auto-mark
      } else if (item.itemType.toLowerCase() == 'hiragana' || item.itemType.toLowerCase() == 'katakana') {
        correctAnswer = item.translation.trim().toLowerCase();
        if (userInput.isNotEmpty && userInput == correctAnswer) {
          _isCorrect = true;
          _correctAnswers.add(item);
          if (_userProfile != null) {
            _userProfile!.addXp(10);
            _userProfile!.save();
          }
          // auto-advance after correct
          _advanceAfterDelay();
        } else {
          _isCorrect = null;
        }
      } else if (item.itemType.toLowerCase() == 'vocab') {
        correctAnswer = item.reading.trim().toLowerCase();
        if (userInput.isNotEmpty && userInput == correctAnswer) {
          _isCorrect = true;
          _correctAnswers.add(item);
          if (_userProfile != null) {
            _userProfile!.addXp(10);
            _userProfile!.save();
          }
        } else {
          _isCorrect = null;
        }
      } else {
        correctAnswer = item.reading.trim().toLowerCase();
        if (correctAnswer.isEmpty) {
          correctAnswer = item.translation.trim().toLowerCase();
        }
        if (userInput.isNotEmpty && userInput == correctAnswer) {
          _isCorrect = true;
          _correctAnswers.add(item);
          if (_userProfile != null) {
            _userProfile!.addXp(10);
            _userProfile!.save();
          }
          // auto-advance after correct
          _advanceAfterDelay();
        } else {
          _isCorrect = null;
        }
      }
    });
  }

  void _advanceAfterDelay() {
    // Short delay so the user sees the feedback, then auto-advance or finish
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final isLast = _currentIndex >= _questions.length - 1;
      setState(() {
        if (isLast) {
          _finished = true;
        } else {
          _currentIndex++;
          _showResult = false;
          _isCorrect = false;
          _answerController.clear();
        }
      });
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentIndex++;
      _showResult = false;
      _isCorrect = false;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex >= _questions.length - 1;
    final finished = _finished;
    final item = !finished ? _questions[_currentIndex] : null;
    String promptText = '';
    if (item != null) {
      // Always prompt with Japanese field
      promptText = item.japanese;
    }
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Reading Practice Arcade', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
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
                  // Compute Android-specific UI scale so elements fit smaller screens
                  final width = MediaQuery.of(context).size.width;
                  double uiScale = 1.0;
                  try {
                    if (Platform.isAndroid) {
                      if (width < 360) uiScale = 0.78;
                      else if (width < 420) uiScale = 0.86;
                      else uiScale = 0.92;
                    }
                  } catch (_) {
                    uiScale = 1.0;
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A00FE)),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 14),
                    if (item != null) ...[
                      Text(
                        promptText,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(
                              item.isStarred ? Icons.star : Icons.star_border,
                              color: item.isStarred ? const Color(0xFFFFC107) : (widget.isDarkMode ? Colors.white : Colors.black),
                            ),
                            tooltip: item.isStarred ? 'Unstar item' : 'Star item',
                            onPressed: () async {
                              setState(() {
                                item.isStarred = !item.isStarred;
                              });
                              String? setKey;
                              for (var entry in setsData.entries) {
                                if (entry.value.items.contains(item)) {
                                  setKey = entry.key;
                                  break;
                                }
                              }
                              if (setKey != null) {
                                await SetPreferences.saveSet(setKey, setsData[setKey]!);
                              }
                            },
                          ),
                        ],
                      ),
                      if (_showResult) ...[
                        const SizedBox(height: 8),
                        Text(
                          // Show correct answer(s) based on item type
                          () {
                            if (item.itemType.toLowerCase() == 'kanji') {
                              return 'Onyomi: ${item.onYomi}\nKunyomi: ${item.kunYomi}\nNanori: ${item.naNori}';
                            } else if (item.itemType.toLowerCase() == 'hiragana' || item.itemType.toLowerCase() == 'katakana') {
                              return 'Correct answer: ${item.translation}';
                            } else if (item.itemType.toLowerCase() == 'vocab') {
                              return 'Correct answer: ${item.reading}';
                            } else {
                              return 'Correct answer: ${item.reading.isNotEmpty ? item.reading : item.translation}';
                            }
                          }(),
                          style: TextStyle(fontSize: 18, color: _isCorrect == true ? Colors.green : Colors.red),
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    if (item != null)
                      TextField(
                        controller: _answerController,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontSize: 22),
                        decoration: InputDecoration(
                          labelText: 'Type the reading',
                          labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                          filled: true,
                          fillColor: widget.isDarkMode ? const Color(0xFF222222) : Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => !_showResult ? _checkAnswer() : null,
                        enabled: !_finished,
                      ),
                    const SizedBox(height: 24),
                    if (!_showResult)
                      ElevatedButton(
                        onPressed: _checkAnswer,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
                        child: const Text('Enter'),
                      )
                    else if (_isCorrect == true)
                      const SizedBox.shrink()
                    else if (_isCorrect == null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Mark Correct'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isCorrect = true;
                                _correctAnswers.add(_questions[_currentIndex]);
                                if (_userProfile != null) {
                                  _userProfile!.addXp(10);
                                  _userProfile!.save();
                                }
                              });
                              _advanceAfterDelay();
                            },
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Mark Incorrect'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            onPressed: () {
                              setState(() {
                                _isCorrect = false;
                                _wrongAnswers.add(_questions[_currentIndex]);
                              });
                              _advanceAfterDelay();
                            },
                          ),
                        ],
                      )
                    else if (_isCorrect == false)
                      const SizedBox.shrink(),
                      ],
                    ),
                  );
                }),
              ),
      ),
    );
  }

  Widget _buildWellDoneScreen(BuildContext context) {
    final total = _questions.length;
    final correct = _correctAnswers.length;
    int completedRounds = _finished ? (_correctAnswers.length + _wrongAnswers.length) : total;
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
    return RepaintBoundary(
      key: _wellDoneKey,
      child: SizedBox(
      height: 500,
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
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9A00FE)),
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
                                    // Correct list
                                    Scrollbar(
                                      controller: _correctScrollController,
                                      child: ListView.builder(
                                        controller: _correctScrollController,
                                        itemCount: _correctAnswers.length,
                                        itemBuilder: (context, i) {
                                          final item = _correctAnswers[i];
                                          return ListTile(
                                            title: Text(item.japanese, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text(item.translation),
                                          );
                                        },
                                      ),
                                    ),
                                    // Wrong list
                                    Scrollbar(
                                      controller: _wrongScrollController,
                                      child: ListView.builder(
                                        controller: _wrongScrollController,
                                        itemCount: _wrongAnswers.length,
                                        itemBuilder: (context, i) {
                                          final item = _wrongAnswers[i];
                                          return ListTile(
                                            title: Text(item.japanese, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            subtitle: Text(item.translation),
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
            onPressed: () async {
              try {
                final boundary = _wellDoneKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
                if (boundary == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not capture screenshot')));
                  return;
                }
                final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
                // Composite onto a white background to avoid transparent PNGs
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
                final dir = await getApplicationDocumentsDirectory();
                final filePath = path.join(dir.path, 'kanji_skool_${DateTime.now().millisecondsSinceEpoch}.png');
                final file = File(filePath);
                await file.writeAsBytes(bytes);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved screenshot to ${file.path}')));
                // Award daily share XP once per day
                final prefs = await SharedPreferences.getInstance();
                final now = DateTime.now();
                final today = '${now.year.toString().padLeft(4,'0')}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
                final last = prefs.getString('skool_share_last_date') ?? '';
                if (last != today) {
                  if (_userProfile == null) {
                    _userProfile = await UserProfile.load();
                  }
                  if (_userProfile != null) {
                    _userProfile!.addXp(50);
                    await _userProfile!.save();
                    await prefs.setString('skool_share_last_date', today);
                    if (mounted) setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You earned 50 XP for sharing today!')));
                  }
                }
                final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Share failed: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A86B), foregroundColor: Colors.white),
            child: const Text('Share in skool!'),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How Stars Work'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
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
                  color: Color.fromRGBO(128, 128, 128, 0.7),
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
  );
  }
  @override
  void dispose() {
    _correctScrollController.dispose();
    _wrongScrollController.dispose();
    _answerController.dispose();
    super.dispose();
  }
}
