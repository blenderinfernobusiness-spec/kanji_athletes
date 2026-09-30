import 'dart:async';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screenshot_saver.dart' as saver;
import 'study_data.dart';
import 'user_profile.dart';

const List<Color> _balloonColors = [
  Color(0xFFEF5350),
  Color(0xFF42A5F5),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
  Color(0xFFAB47BC),
  Color(0xFFFF7043),
];

class _Balloon {
  final StudyCard card;
  final bool isCorrect;
  bool popped = false;
  _Balloon({required this.card, required this.isCorrect});
}

// Falling-balloons recognition game, in the spirit of the meteor/balloon
// mini-games in apps like "Japanese Games: Infinite": each round shows an
// English prompt, and a handful of balloons carrying Japanese words fall
// down the screen - tap the one that matches before it reaches the bottom.
// Tapping a wrong balloon just pops it (the round keeps going); missing the
// correct balloon entirely (it reaches the bottom untapped) ends the round
// as a miss. Falls a little faster each round for a gentle difficulty ramp.
class BalloonGameScreen extends StatefulWidget {
  final String title;
  final List<StudyCard> questions;
  final bool isDarkMode;

  const BalloonGameScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.isDarkMode,
  });

  @override
  State<BalloonGameScreen> createState() => _BalloonGameScreenState();
}

class _BalloonGameScreenState extends State<BalloonGameScreen> with TickerProviderStateMixin {
  UserProfile? _userProfile;
  final GlobalKey _wellDoneKey = GlobalKey();
  final Random _random = Random();

  late List<StudyCard> _queue;
  int _roundIndex = 0;
  int _correctCount = 0;
  int _missedCount = 0;
  bool _finished = false;
  bool _roundEnding = false;
  bool _roundMistake = false; // a wrong balloon was tapped this round - even
  // if the correct one is found afterwards, the round still counts as wrong.

  List<_Balloon> _balloons = [];
  List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    _queue = List<StudyCard>.from(widget.questions)..shuffle();
    _loadUserProfile();
    if (_queue.isEmpty) {
      _finished = true;
    } else {
      _startRound();
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
    });
  }

  void _disposeControllers() {
    for (final c in _controllers) {
      c.dispose();
    }
    _controllers = [];
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _startRound() {
    _disposeControllers();
    _roundEnding = false;
    _roundMistake = false;

    final target = _queue[_roundIndex];
    final pool = List<StudyCard>.from(_queue)..remove(target);
    pool.shuffle(_random);
    final distractors = pool.take(min(3, pool.length)).toList();
    final roundCards = [target, ...distractors]..shuffle(_random);

    final durationMs = (7000 - _roundIndex * 150).clamp(3200, 7000);
    final duration = Duration(milliseconds: durationMs);

    _balloons = [for (final c in roundCards) _Balloon(card: c, isCorrect: c == target)];
    _controllers = [for (final _ in _balloons) AnimationController(vsync: this, duration: duration)];

    for (int i = 0; i < _controllers.length; i++) {
      final balloon = _balloons[i];
      _controllers[i].addStatusListener((status) {
        if (status == AnimationStatus.completed && !balloon.popped && !_roundEnding && balloon.isCorrect) {
          _endRound(correct: false);
        }
      });
      _controllers[i].forward();
    }
    setState(() {});
  }

  void _onBalloonTap(int index) {
    final balloon = _balloons[index];
    if (balloon.popped || _roundEnding) return;
    _controllers[index].stop();
    if (balloon.isCorrect) {
      setState(() => balloon.popped = true);
      _roundEnding = true;
      _endRound(correct: !_roundMistake);
    } else {
      setState(() {
        balloon.popped = true;
        _roundMistake = true;
      });
    }
  }

  void _endRound({required bool correct}) {
    for (final c in _controllers) {
      c.stop();
    }
    if (correct) {
      _correctCount++;
      if (_userProfile != null) {
        _userProfile!.addXp(10);
        _userProfile!.save();
      }
    } else {
      _missedCount++;
    }
    setState(() {});
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      _roundIndex++;
      if (_roundIndex >= _queue.length) {
        setState(() => _finished = true);
      } else {
        _startRound();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Balloons: ${widget.title}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: _finished ? _buildWellDoneScreen(context) : _buildBoard(context),
      ),
    );
  }

  Widget _buildBoard(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final target = _queue[_roundIndex];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            children: [
              Text(
                'Round ${_roundIndex + 1} / ${_queue.length}',
                style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.black45),
              ),
              const SizedBox(height: 6),
              Text(
                'Find: ${target.english}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    for (int i = 0; i < _balloons.length; i++)
                      _buildBalloon(i, constraints.maxWidth, constraints.maxHeight),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalloon(int index, double areaWidth, double areaHeight) {
    const balloonSize = 92.0;
    final laneWidth = areaWidth / _balloons.length;
    final left = (index * laneWidth + (laneWidth - balloonSize) / 2).clamp(0.0, areaWidth - balloonSize);
    final balloon = _balloons[index];

    return AnimatedBuilder(
      animation: _controllers[index],
      builder: (context, child) {
        final top = _controllers[index].value * (areaHeight - balloonSize);
        return Positioned(
          left: left,
          top: top,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: balloon.popped ? 0.0 : 1.0,
            child: GestureDetector(
              onTap: () => _onBalloonTap(index),
              child: Container(
                width: balloonSize,
                height: balloonSize,
                decoration: BoxDecoration(
                  color: _balloonColors[index % _balloonColors.length],
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    balloon.card.japanese,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWellDoneScreen(BuildContext context) {
    int xp = _userProfile?.xp ?? 0;
    int level = _userProfile?.level ?? 0;
    int xpNeeded = UserProfile.xpForLevel(level);
    double progress = xpNeeded > 0 ? xp / xpNeeded : 0.0;
    final total = _correctCount + _missedCount;
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
                Text(
                  'Well done!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Score: $_correctCount / $total',
                  style: TextStyle(fontSize: 24, color: widget.isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 24),
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
