import 'package:flutter/material.dart';
import 'grammar_data.dart';
import 'lesson_data.dart';
import 'lesson_viewer_screen.dart';
import 'spaced_repetition_standard.dart';
import 'study_data.dart';

const Color _accent = Color(0xFF9A00FE);

// Every circle on the path - lessons, the flashcard counters between them, and
// the remaining-cards counter at the end - shares this size.
const double _circleSize = 72;
const double _titleHeight = 40;
const double _nodeHeight = _circleSize + 6 + _titleHeight;
const double _gap = 96;
const List<double> _zigZag = [0, 84, 0, -84];

enum _NodeState { done, current, open, locked }

// A concept icon for each grammar point, shown instead of a lock so the path
// says what each lesson is about.
const Map<int, IconData> _grammarIcons = {
  1: Icons.record_voice_over_outlined,
  2: Icons.history,
  3: Icons.block,
  4: Icons.thumb_down_alt_outlined,
  5: Icons.hourglass_bottom,
  6: Icons.history_toggle_off,
  7: Icons.chat_outlined,
  8: Icons.restore,
  9: Icons.label_outline,
  10: Icons.person_outline,
  11: Icons.inventory_2_outlined,
  12: Icons.north_east,
  13: Icons.place_outlined,
  14: Icons.home_work_outlined,
  15: Icons.account_circle_outlined,
  16: Icons.link,
  17: Icons.add_circle_outline,
  18: Icons.help_outline,
  19: Icons.looks_one_outlined,
  20: Icons.looks_5_outlined,
  21: Icons.shuffle_outlined,
  22: Icons.build_outlined,
  23: Icons.pan_tool_outlined,
  24: Icons.do_not_disturb_alt_outlined,
  25: Icons.format_list_bulleted,
  26: Icons.play_circle_outline,
  27: Icons.pause_circle_outline,
  28: Icons.history_toggle_off,
  29: Icons.thumb_up_alt_outlined,
  30: Icons.check_circle_outline,
  31: Icons.question_mark,
  32: Icons.favorite_border,
  33: Icons.card_giftcard_outlined,
  34: Icons.groups_outlined,
  35: Icons.volunteer_activism_outlined,
  36: Icons.heart_broken_outlined,
  37: Icons.directions_walk,
  38: Icons.groups_2_outlined,
  39: Icons.question_answer_outlined,
  40: Icons.event_available_outlined,
  41: Icons.bolt_outlined,
  42: Icons.flash_on_outlined,
  43: Icons.format_color_fill_outlined,
  44: Icons.format_color_fill,
  45: Icons.photo_size_select_small_outlined,
  46: Icons.sync_alt,
  47: Icons.priority_high,
  48: Icons.looks_one,
  49: Icons.north_east,
  50: Icons.category_outlined,
  51: Icons.label_important_outline,
  52: Icons.explore_outlined,
  53: Icons.inventory_2_outlined,
  54: Icons.pets_outlined,
  55: Icons.schedule_outlined,
  56: Icons.timelapse_outlined,
  57: Icons.first_page,
  58: Icons.alt_route_outlined,
  59: Icons.last_page,
  60: Icons.repeat,
  61: Icons.hourglass_empty,
  62: Icons.hourglass_disabled_outlined,
  63: Icons.done_all,
  64: Icons.chat_bubble_outline,
  65: Icons.forum_outlined,
  66: Icons.thumb_up_off_alt_outlined,
  67: Icons.campaign_outlined,
  68: Icons.sentiment_satisfied_alt_outlined,
  69: Icons.swap_horiz,
  70: Icons.call_split,
  71: Icons.menu_book_outlined,
  72: Icons.article_outlined,
  73: Icons.low_priority,
  74: Icons.arrow_forward,
  75: Icons.redo,
  76: Icons.thumb_up_alt_outlined,
  77: Icons.compare_arrows,
  78: Icons.trending_up,
  79: Icons.emoji_events_outlined,
  80: Icons.favorite_outline,
  81: Icons.favorite_border,
  82: Icons.star_outline,
  83: Icons.star_half,
  84: Icons.help_center_outlined,
  85: Icons.settings_suggest_outlined,
  86: Icons.category_outlined,
  87: Icons.rule_outlined,
  88: Icons.back_hand_outlined,
  89: Icons.redeem_outlined,
  90: Icons.volunteer_activism_outlined,
  91: Icons.check_circle_outline,
  92: Icons.gavel_outlined,
  93: Icons.flash_on,
  94: Icons.rule,
  95: Icons.verified_outlined,
  96: Icons.not_interested,
  97: Icons.block_flipped,
  98: Icons.toggle_off_outlined,
  99: Icons.flag_outlined,
  100: Icons.event_note_outlined,
  101: Icons.playlist_add_check,
  102: Icons.list_alt_outlined,
  103: Icons.fork_right_outlined,
  104: Icons.sticky_note_2_outlined,
  105: Icons.history_toggle_off,
  106: Icons.filter_1_outlined,
  107: Icons.filter_alt_outlined,
};

// A path of this deck's lessons, Duolingo-style. Tap a lesson to open it (and
// complete it if it isn't yet). Tap a flashcard circle to study those cards.
class StudyProgressScreen extends StatefulWidget {
  final StudyDeck deck;
  final bool isDarkMode;
  final VoidCallback? onChanged;

  const StudyProgressScreen({super.key, required this.deck, required this.isDarkMode, this.onChanged});

  @override
  State<StudyProgressScreen> createState() => _StudyProgressScreenState();
}

class _StudyProgressScreenState extends State<StudyProgressScreen> {
  StudyDeck get deck => widget.deck;
  bool get isDarkMode => widget.isDarkMode;

  // Where a lesson sits on the path. An end-of-day lesson comes after that
  // day's cards; its own day number may be a bookkeeping value (e.g. the
  // Introduce Yourself lesson is day 91 but ends day 1), so endOfDay wins.
  double _position(Lesson l) => l.endOfDay != null ? l.endOfDay! + 0.5 : l.day.toDouble();

  // The day number this lesson is recorded under (see completedLessonDays).
  int _slotDay(Lesson l) => l.endOfDay ?? l.day;

  List<Lesson> _trackLessons() {
    final trackId = deck.lessonSetId;
    if (trackId == null) return const [];
    return [...lessons, ...grammarLessons].where((l) => l.trackId == trackId).toList()
      ..sort((a, b) => _position(a).compareTo(_position(b)));
  }

  // Cards introduced from lesson i up to the next lesson - the cards that
  // sit between those two lessons on the path.
  List<StudyCard> _betweenCards(List<Lesson> trackLessons, int i) {
    final from = _position(trackLessons[i]);
    final to = _position(trackLessons[i + 1]);
    return deck.cards.where((c) {
      final day = c.challengeDay;
      if (day == null) return false;
      // A card sits a quarter of a day into its own day, so the lessons either
      // side of a day land cleanly before and after its cards.
      final at = day + 0.25;
      return at > from && at < to;
    }).toList();
  }

  _NodeState _stateFor(int day, int currentDay, Set<int> done) {
    if (done.contains(day)) return _NodeState.done;
    if (day == currentDay) return _NodeState.current;
    if (day < currentDay) return _NodeState.open;
    return _NodeState.locked;
  }

  Future<void> _openLesson(Lesson lesson) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LessonViewerScreen(lesson: lesson, isDarkMode: isDarkMode),
      ),
    );
    if (completed != true || !mounted) return;
    final slot = _slotDay(lesson);
    if (!deck.completedLessonDays.contains(slot)) deck.completedLessonDays.add(slot);
    widget.onChanged?.call();
    setState(() {});
  }

  // The next lesson in line can be started early; later ones aren't open yet.
  Future<void> _startNextDay(Lesson lesson) async {
    final start = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Start Day ${_slotDay(lesson)} now?'),
        content: Text('Day ${_slotDay(lesson)} is not due yet - you can start it early if you like.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Not now')),
          ElevatedButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Start now')),
        ],
      ),
    );
    if (start == true && mounted) await _openLesson(lesson);
  }

  Future<void> _openCards() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpacedRepetitionStandardScreen(
          deck: deck,
          isDarkMode: isDarkMode,
          onChanged: widget.onChanged ?? () {},
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final trackLessons = _trackLessons();
    final currentDay = lessonDayFor(deck);
    final done = deck.completedLessonDays.toSet();
    final muted = isDarkMode ? Colors.white60 : Colors.black54;
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final background = Theme.of(context).scaffoldBackgroundColor;

    final allCards = deck.cards;
    final completedCards = allCards.where((c) => c.repetitions > 0).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Study progress')),
      body: trackLessons.isEmpty
          ? Center(child: Text('This deck has no lessons yet.', style: TextStyle(color: muted)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  Text(deck.name, textAlign: TextAlign.center, style: TextStyle(color: fg, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '$completedCards of ${allCards.length} cards completed',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _path(trackLessons, currentDay, done, fg, muted, background),
                ],
              ),
            ),
    );
  }

  Widget _path(
    List<Lesson> trackLessons,
    int currentDay,
    Set<int> done,
    Color fg,
    Color muted,
    Color background,
  ) {
    final count = trackLessons.length;
    final slot = _nodeHeight + _gap;
    final showCards = deck.lessonSetId != kGrammarTrackId;

    // The Grammar track is further broken into named sections (see
    // grammarSections) - a header shown above the first node of each new
    // section, pushing every node from there on down by its height.
    const sectionHeaderHeight = 56.0;
    final headerBeforeIndex = <int, String>{};
    if (isGrammar) {
      String? prevSection;
      for (var i = 0; i < count; i++) {
        final section = grammarSectionForDay(_slotDay(trackLessons[i]))?.title;
        if (section != null && section != prevSection) headerBeforeIndex[i] = section;
        prevSection = section;
      }
    }
    final extraOffset = List<double>.filled(count, 0);
    var acc = 0.0;
    for (var i = 0; i < count; i++) {
      if (headerBeforeIndex.containsKey(i)) acc += sectionHeaderHeight;
      extraOffset[i] = acc;
    }
    double extraOffsetAt(int i) => i < count ? extraOffset[i] : (count > 0 ? extraOffset[count - 1] : 0);

    final height = count * slot + (showCards ? _circleSize : 0) + (count > 0 ? extraOffset[count - 1] : 0);
    final states = [for (final l in trackLessons) _stateFor(_slotDay(l), currentDay, done)];
    final firstLocked = states.indexWhere((st) => st == _NodeState.locked);
    final between = [for (var i = 0; i < count - 1; i++) _betweenCards(trackLessons, i)];
    final representedCards = between.expand((list) => list).toSet();
    final remainingCards = deck.cards.where((c) => !representedCards.contains(c)).toList();
    final remainingDone = remainingCards.where((c) => c.repetitions > 0).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double centerX(int i) => width / 2 + _zigZag[i % _zigZag.length];
        double circleCenterY(int i) => i * slot + _circleSize / 2 + extraOffsetAt(i);
        final endIndex = count;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _PathPainter(
                    points: [for (var i = 0; i <= endIndex; i++) Offset(centerX(i), circleCenterY(i))],
                    color: isDarkMode ? Colors.white24 : Colors.black26,
                  ),
                ),
              ),
              for (final entry in headerBeforeIndex.entries)
                Positioned(
                  left: 0,
                  right: 0,
                  top: entry.key * slot + extraOffsetAt(entry.key) - sectionHeaderHeight,
                  height: sectionHeaderHeight,
                  child: Center(
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: fg, fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              for (var i = 0; i < count; i++)
                Positioned(
                  left: centerX(i) - 100,
                  top: i * slot + extraOffsetAt(i),
                  width: 200,
                  child: _lessonNode(
                    trackLessons[i],
                    states[i],
                    fg,
                    muted,
                    background,
                    isNextLocked: i == firstLocked,
                  ),
                ),
              for (var i = 0; i < count - 1; i++)
                if (showCards && between[i].isNotEmpty)
                  Positioned(
                    left: (centerX(i) + centerX(i + 1)) / 2 - _circleSize / 2,
                    top: (circleCenterY(i) + circleCenterY(i + 1)) / 2 - _circleSize / 2,
                    width: _circleSize,
                    height: _circleSize,
                    child: _cardCounter(
                      completed: between[i].where((c) => c.repetitions > 0).length,
                      total: between[i].length,
                      muted: muted,
                      background: background,
                      label: _countLabel(
                        between[i].where((c) => c.repetitions > 0).length,
                        between[i].length,
                      ),
                    ),
                  ),
              if (showCards && count > 0)
                Positioned(
                  left: centerX(endIndex) - _circleSize / 2,
                  top: circleCenterY(endIndex) - _circleSize / 2,
                  width: _circleSize,
                  height: _circleSize,
                  child: _cardCounter(
                    completed: remainingDone,
                    total: remainingCards.length,
                    muted: muted,
                    background: background,
                    label: '${remainingCards.length} left',
                    tooltip: '${remainingCards.length} cards not on the path yet',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  bool get isGrammar => deck.lessonSetId == kGrammarTrackId;

  String _countLabel(int completed, int total) => total == 0 ? '–' : '$completed/$total';

  Widget _lessonNode(
    Lesson lesson,
    _NodeState state,
    Color fg,
    Color muted,
    Color background, {
    required bool isNextLocked,
  }) {
    final filled = state == _NodeState.done || state == _NodeState.current;
    final circleColor = filled ? _accent : (isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[300]!);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (state != _NodeState.locked) {
          _openLesson(lesson);
        } else if (isGrammar || isNextLocked) {
          _startNextDay(lesson);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Not unlocked yet')),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: _circleSize,
            height: _circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: circleColor,
              border: state == _NodeState.current ? Border.all(color: _accent, width: 4) : null,
            ),
            child: Center(
              child: state == _NodeState.done
                  ? const Icon(Icons.check, color: Colors.white, size: 32)
                  : state == _NodeState.locked
                      ? Icon(
                          isGrammar ? (_grammarIcons[_slotDay(lesson)] ?? Icons.lock) : Icons.lock,
                          color: muted,
                        )
                      : Text(
                          '${_slotDay(lesson)}',
                          style: TextStyle(
                            color: filled ? Colors.white : fg,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 6),
          // Background behind the title so a line passing behind it stays readable.
          Container(
            color: background,
            height: _titleHeight,
            alignment: Alignment.topCenter,
            child: Text(
              lesson.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: state == _NodeState.locked ? muted : fg, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // A circle with a flashcard icon, a ring showing how much of [total] is done,
  // and a short label inside the circle. Tapping it studies those cards.
  Widget _cardCounter({
    required int completed,
    required int total,
    required Color muted,
    required Color background,
    required String label,
    String? tooltip,
  }) {
    final fraction = total == 0 ? 0.0 : completed / total;
    return Tooltip(
      message: tooltip ?? '$completed of $total cards completed',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openCards,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(shape: BoxShape.circle, color: background),
            ),
            SizedBox(
              width: _circleSize - 4,
              height: _circleSize - 4,
              child: CircularProgressIndicator(
                value: fraction,
                strokeWidth: 4,
                color: _accent,
                backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.style, color: _accent, size: 22),
                Text(label, style: TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Lines between consecutive circles, drawn centre to centre behind the nodes.
class _PathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;

  _PathPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.points != points || old.color != color;
}
