import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screenshot_saver.dart' as saver;
import 'study_data.dart';
import 'user_profile.dart';

// One tile on the board: either a card's Japanese or its English side. Two
// tiles sharing the same card are a pair.
class _Tile {
  final StudyCard card;
  final String text;
  _Tile(this.card, this.text);
}

// Quizlet-style match game: every card contributes a Japanese tile and an
// English tile, shuffled together on a board. Tap two tiles - a match
// removes both and awards XP, a mismatch briefly flashes red. To keep the
// whole board on screen without scrolling, the selected cards are split into
// rounds of at most _maxPairsPerRound pairs; finishing a round's board loads
// the next one, and the game as a whole finishes (stopping the clock) once
// every round is done.
class MatchGameScreen extends StatefulWidget {
  final String title;
  final List<StudyCard> questions;
  final bool isDarkMode;

  const MatchGameScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.isDarkMode,
  });

  @override
  State<MatchGameScreen> createState() => _MatchGameScreenState();
}

class _MatchGameScreenState extends State<MatchGameScreen> {
  static const int _maxPairsPerRound = 6;

  UserProfile? _userProfile;
  final GlobalKey _wellDoneKey = GlobalKey();
  late List<List<StudyCard>> _rounds;
  int _roundIndex = 0;
  late List<_Tile> _tiles;
  _Tile? _selectedTile;
  Set<_Tile> _wrongTiles = {};
  Set<_Tile> _correctTiles = {};
  bool _locked = false;
  int _wrongAttempts = 0;
  int _totalPairs = 0;
  int _matchedTotal = 0;
  bool _finished = false;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _totalPairs = widget.questions.length;
    final shuffled = List<StudyCard>.from(widget.questions)..shuffle();
    _rounds = [
      for (int i = 0; i < shuffled.length; i += _maxPairsPerRound)
        shuffled.sublist(i, (i + _maxPairsPerRound).clamp(0, shuffled.length)),
    ];
    _loadRound(0);
    _loadUserProfile();
    _stopwatch.start();
    _tickTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  void _loadRound(int index) {
    _roundIndex = index;
    final round = _rounds[index];
    _tiles = [
      for (final card in round) ...[
        _Tile(card, card.japanese),
        _Tile(card, card.english),
      ],
    ]..shuffle();
    _correctTiles = {};
    _wrongTiles = {};
    _selectedTile = null;
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    if (!mounted) return;
    setState(() {
      _userProfile = profile;
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final tenths = (d.inMilliseconds % 1000) ~/ 100;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
  }

  void _onTileTap(_Tile tile) {
    if (_locked || tile == _selectedTile || _correctTiles.contains(tile)) return;

    final first = _selectedTile;
    if (first == null) {
      setState(() => _selectedTile = tile);
      return;
    }

    if (first.card == tile.card) {
      setState(() {
        _correctTiles = {..._correctTiles, first, tile};
        _selectedTile = null;
        _matchedTotal++;
      });
      if (_userProfile != null) {
        _userProfile!.addXp(10);
        _userProfile!.save();
      }
      // Matched tiles stay put (faded, with a checkmark) rather than being
      // removed - that keeps the tile count constant for the round, so the
      // grid never resizes/reflows mid-round.
      if (_correctTiles.length == _tiles.length) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          if (_roundIndex + 1 < _rounds.length) {
            setState(() => _loadRound(_roundIndex + 1));
          } else {
            _finish();
          }
        });
      }
    } else {
      setState(() {
        _wrongTiles = {first, tile};
        _locked = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          _wrongTiles = {};
          _selectedTile = null;
          _wrongAttempts++;
          _locked = false;
        });
      });
    }
  }

  void _finish() {
    _stopwatch.stop();
    _tickTimer?.cancel();
    setState(() => _finished = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Match: ${widget.title}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatElapsed(_stopwatch.elapsed),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Matched $_matchedTotal / $_totalPairs',
                    style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                  if (_rounds.length > 1)
                    Text(
                      'Round ${_roundIndex + 1} / ${_rounds.length}',
                      style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45),
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final count = _tiles.length;
                int crossAxisCount = constraints.maxWidth < 500 ? 2 : (constraints.maxWidth < 800 ? 3 : 4);
                if (count > 0 && count < crossAxisCount) crossAxisCount = count;
                const spacing = 10.0;
                final rows = count == 0 ? 1 : (count / crossAxisCount).ceil();
                final tileWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
                final tileHeight = (constraints.maxHeight - spacing * (rows - 1)) / rows;
                final aspectRatio = (tileWidth / tileHeight).clamp(0.6, 3.0);
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                  ),
                  itemCount: count,
                  itemBuilder: (context, index) {
                    final tile = _tiles[index];
                    final isSelected = tile == _selectedTile;
                    final isWrong = _wrongTiles.contains(tile);
                    final isMatched = _correctTiles.contains(tile);
                    final Color bg = isMatched
                        ? Colors.green.withValues(alpha: 0.15)
                        : isWrong
                            ? Colors.red.withValues(alpha: 0.3)
                            : isSelected
                                ? const Color(0xFF9A00FE).withValues(alpha: 0.35)
                                : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200]!);
                    final Color border = isMatched
                        ? Colors.transparent
                        : isWrong
                            ? Colors.red
                            : (isSelected ? const Color(0xFF9A00FE) : Colors.transparent);
                    // Matched tiles stay in place (never removed) so the
                    // tile count - and therefore the grid's computed layout
                    // - never changes mid-round; they just settle into a
                    // faded, checkmarked resting state via the same widget
                    // shape (kept under the same key throughout) so the
                    // fade/crossfade actually animates instead of jump-cutting.
                    return GestureDetector(
                      key: ValueKey(tile),
                      onTap: () => _onTileTap(tile),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: isMatched ? 0.45 : 1.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border, width: 2),
                          ),
                          padding: const EdgeInsets.all(8),
                          alignment: Alignment.center,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: isMatched
                                ? const Icon(
                                    Icons.check,
                                    key: ValueKey('check'),
                                    size: 32,
                                    color: Colors.green,
                                  )
                                : FittedBox(
                                    key: const ValueKey('text'),
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      tile.text,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWellDoneScreen(BuildContext context) {
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
                Text(
                  'Well done!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  'Time: ${_formatElapsed(_stopwatch.elapsed)}',
                  style: TextStyle(fontSize: 24, color: widget.isDarkMode ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 6),
                Text(
                  '$_totalPairs pairs · $_wrongAttempts wrong attempt${_wrongAttempts == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 16, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
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
