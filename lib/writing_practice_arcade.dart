
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'sets_data.dart';
import 'set_preferences.dart';
import 'writing_practice_canvas.dart';
import 'item_detail.dart';
import 'user_profile.dart';

// Animated stars widget for well done screen
class _AnimatedStars extends StatefulWidget {
  final int stars;
  const _AnimatedStars({super.key, required this.stars});

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
            : Icon(Icons.star_border, key: ValueKey('star-border-$i'), color: Colors.grey.withOpacity(0.5), size: 36),
      )),
    );
  }
}


class WritingPracticeArcadeScreen extends StatefulWidget {
  final ItemSet itemSet;
  final int numberOfRounds;
  final bool roundForEveryItem;
  final bool roundForEveryStarred;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const WritingPracticeArcadeScreen({
    super.key,
    required this.itemSet,
    required this.numberOfRounds,
    required this.roundForEveryItem,
    required this.roundForEveryStarred,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<WritingPracticeArcadeScreen> createState() => _WritingPracticeArcadeScreenState();
}

class _WritingPracticeArcadeScreenState extends State<WritingPracticeArcadeScreen> {
        UserProfile? _userProfile;
  final GlobalKey _wellDoneKey = GlobalKey();
      bool _finished = false;
    final List<Item> _correctAnswers = [];
    final List<Item> _wrongAnswers = [];
      late ScrollController _correctScrollController;
      late ScrollController _wrongScrollController;
  late List<Item> _questions;
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
          // Only auto-advance if still marked and still on this question
          _nextQuestion();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentIndex >= _questions.length - 1;
    final finished = _finished;
    final item = !finished ? _questions[_currentIndex] : null;
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Writing Practice Arcade', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
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
                        item.translation,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
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
                              // Persist change to the set that contains this item
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
                          item.japanese,
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                    const SizedBox(height: 32),
                    // Drawing box for writing answer
                    if (item != null)
                      WritingPracticeCanvas(
                        key: ValueKey(_canvasResetCounter),
                        kanjiVGCodes: item.kanjiVGCode != null ? [item.kanjiVGCode!] : [],
                        isDarkMode: widget.isDarkMode,
                        kanji: item.japanese,
                        translation: item.translation,
                        scale: (Platform.isAndroid ? (MediaQuery.of(context).size.width < 420 ? 0.86 : 0.92) : 1.0),
                        hideButtons: true,
                        hideCanvas: false,
                        showHintByDefault: false,
                        resetCounter: _canvasResetCounter,
                      ),
                    const SizedBox(height: 12),
                    if (item != null)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailScreen(
                                item: item,
                                isDarkMode: widget.isDarkMode,
                                onThemeChanged: widget.onThemeChanged,
                              ),
                            ),
                          );
                        },
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
                          Text(
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
    final total = _questions.length;
    final correct = _correctAnswers.length;
    // Show score out of rounds completed if finished early
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
          // XP/Level display at the very top
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
          // Animated star rating row
          _AnimatedStars(stars: stars),
          const SizedBox(height: 6),
          // Removed top score display
                    Text('Score: $correct / $completedRounds', style: TextStyle(fontSize: 22, color: widget.isDarkMode ? Colors.white : Colors.black)),
                    // Only count completed answers when finished early
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
          const SizedBox(height: 12),
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
                  color: Colors.grey.withOpacity(0.7),
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
