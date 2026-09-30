import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'lesson_data.dart';

// Fades + slides a child in on first build. Give it a fresh key (or let it
// mount fresh, e.g. inside a step that just became visible) to replay it.
class _FadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _FadeIn({required this.child, this.delay = Duration.zero});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _delayTimer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _controller.value,
        child: Transform.translate(offset: Offset(0, (1 - _controller.value) * 16), child: child),
      ),
      child: widget.child,
    );
  }
}

// A row of tappable options for a lesson question. Locks after the first
// tap, highlights the correct answer in green and (if wrong) the tapped one
// in red with a little shake, then reports back so the step can reveal.
class _ChoiceChips extends StatefulWidget {
  final List<String> options;
  final int correctIndex;
  final bool isDarkMode;
  final ValueChanged<bool> onAnswered; // true if correct

  const _ChoiceChips({
    required this.options,
    required this.correctIndex,
    required this.isDarkMode,
    required this.onAnswered,
  });

  @override
  State<_ChoiceChips> createState() => _ChoiceChipsState();
}

class _ChoiceChipsState extends State<_ChoiceChips> with SingleTickerProviderStateMixin {
  int? _selected;
  late final AnimationController _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  void _tap(int index) {
    if (_selected != null) return;
    setState(() => _selected = index);
    final correct = index == widget.correctIndex;
    if (!correct) _shake.forward(from: 0);
    widget.onAnswered(correct);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: List.generate(widget.options.length, (i) {
        Color bg;
        Color fg;
        Color border;
        if (_selected == null) {
          bg = isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05);
          fg = isDarkMode ? Colors.white : Colors.black87;
          border = isDarkMode ? Colors.white24 : Colors.black12;
        } else if (i == widget.correctIndex) {
          bg = Colors.green.withValues(alpha: 0.15);
          fg = Colors.green;
          border = Colors.green;
        } else if (i == _selected) {
          bg = Colors.red.withValues(alpha: 0.12);
          fg = Colors.red;
          border = Colors.red;
        } else {
          bg = isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03);
          fg = isDarkMode ? Colors.white38 : Colors.black38;
          border = Colors.transparent;
        }
        // Always the same widget shape (GestureDetector -> AnimatedBuilder ->
        // AnimatedContainer) regardless of state - only wrapping the tapped
        // chip in AnimatedBuilder *conditionally* would swap its widget type
        // at that exact tree position during the very tap that triggered it,
        // tearing down and rebuilding an element mid-gesture. That's what
        // was throwing "Looking up a deactivated widget's ancestor is
        // unsafe" when answering a question.
        return GestureDetector(
          onTap: () => _tap(i),
          child: AnimatedBuilder(
            animation: _shake,
            builder: (context, child) {
              final t = _shake.value;
              final dx = (i == _selected && t != 0 && t != 1) ? math.sin(t * math.pi * 6) * 6 * (1 - t) : 0.0;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 1.5),
              ),
              child: Text(widget.options[i], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: fg)),
            ),
          ),
        );
      }),
    );
  }
}

// One step of the lesson journey: shows the example, then (if there's a
// question) waits for an answer before revealing the payoff and its
// explanation - otherwise reveals immediately. Calls [onSettled] the moment
// the learner can move on, so the parent can enable "Continue".
class _StepView extends StatefulWidget {
  final LessonStep step;
  final bool isDarkMode;
  final bool initiallySettled;
  final VoidCallback onSettled;

  const _StepView({
    super.key,
    required this.step,
    required this.isDarkMode,
    required this.onSettled,
    this.initiallySettled = false,
  });

  @override
  State<_StepView> createState() => _StepViewState();
}

class _StepViewState extends State<_StepView> {
  // Frozen at mount time, deliberately never re-read from widget.
  // Answering a question re-triggers the parent's rebuild with
  // initiallySettled now true for this same step (it just got added to
  // _answeredSteps) - reading that live in build() would rip the just-tapped
  // choice chips out from under the user before they could see which one
  // was right. This snapshot is what "was this step already answered before
  // I appeared" actually means.
  late final bool _wasAlreadyAnswered = widget.initiallySettled;
  late bool _settled = _wasAlreadyAnswered || widget.step.question == null;

  @override
  void initState() {
    super.initState();
    if (_settled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSettled());
    }
  }

  void _onAnswered(bool correct) {
    setState(() => _settled = true);
    widget.onSettled();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final step = widget.step;
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step.kickerPlain != null)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${step.kickerPlain} ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black),
                ),
                if (step.kickerHighlight != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: kLessonPurple,
                    child: Text(step.kickerHighlight!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
              ],
            ),
          if (step.kickerPlain != null) const SizedBox(height: 20),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _FadeIn(child: step.before(isDarkMode)),
                    if (step.question != null && !_wasAlreadyAnswered) ...[
                      const SizedBox(height: 24),
                      _FadeIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          children: [
                            Text(
                              step.question!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                            const SizedBox(height: 14),
                            _ChoiceChips(
                              options: step.options!,
                              correctIndex: step.correctIndex!,
                              isDarkMode: isDarkMode,
                              onAnswered: _onAnswered,
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_settled) ...[
                      const SizedBox(height: 24),
                      if (step.after != null) _FadeIn(child: step.after!(isDarkMode)),
                      if (step.explanation != null) ...[
                        const SizedBox(height: 14),
                        _FadeIn(
                          delay: const Duration(milliseconds: 120),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (isDarkMode ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              step.explanation!,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, height: 1.4, color: isDarkMode ? Colors.white70 : Colors.black54),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The interactive lesson journey: a title card with a "Let's go!" button,
// then each LessonStep in turn (with its think-first question, when it has
// one), then a "Complete Lesson" card. Pressing Complete Lesson pops the
// route with `true`, which callers use to mark the lesson done and, when
// shown at the start of a Spaced Repetition session, to proceed into it.
// Closing with the X instead pops with `false`.
class LessonViewerScreen extends StatefulWidget {
  final Lesson lesson;
  final bool isDarkMode;

  const LessonViewerScreen({
    super.key,
    required this.lesson,
    required this.isDarkMode,
  });

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

enum _Phase { intro, steps, activity, closing }

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  _Phase _phase = _Phase.intro;
  int _stepIndex = 0;
  bool _currentStepSettled = false;
  final Set<int> _answeredSteps = {};

  bool get _hasActivity => widget.lesson.activityBuilder != null;

  double get _progress {
    final totalUnits = widget.lesson.steps.length + (_hasActivity ? 1 : 0) + 2; // intro + steps + activity? + closing
    double doneUnits;
    switch (_phase) {
      case _Phase.intro:
        doneUnits = 0.0;
        break;
      case _Phase.steps:
        doneUnits = (1 + _stepIndex).toDouble();
        break;
      case _Phase.activity:
        doneUnits = (1 + widget.lesson.steps.length).toDouble();
        break;
      case _Phase.closing:
        doneUnits = totalUnits.toDouble();
        break;
    }
    return (doneUnits / totalUnits).clamp(0.0, 1.0);
  }

  // Every one of these is triggered by tapping a button that can end up
  // structurally removed (an `if (...)` branch flipping false) by the very
  // setState it causes - e.g. the Continue button disappears the instant a
  // non-final step advances, since _currentStepSettled resets to false. Doing
  // that removal synchronously, mid-tap, is what threw "Looking up a
  // deactivated widget's ancestor is unsafe" (the tapped button's own ripple
  // was still resolving against a Material ancestor that had just been torn
  // out). Deferring the state change to the next frame - Flutter's own
  // recommended fix for this race - lets the tap finish first.
  void _deferred(VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) action();
    });
  }

  // A lesson with a custom activity and no ordinary steps skips the step
  // phase entirely - it's the only phase that ever renders for that lesson.
  void _start() => _deferred(() => setState(() {
    _phase = widget.lesson.steps.isEmpty && _hasActivity ? _Phase.activity : _Phase.steps;
  }));

  void _continue() => _deferred(() {
    if (_stepIndex >= widget.lesson.steps.length - 1) {
      setState(() => _phase = _hasActivity ? _Phase.activity : _Phase.closing);
      return;
    }
    setState(() {
      _stepIndex++;
      _currentStepSettled = false;
    });
  });

  // Called by the activity widget itself once the learner's done with it -
  // there's no shared "Continue" button for this phase since the activity
  // occupies the whole body.
  void _finishActivity() => _deferred(() => setState(() => _phase = _Phase.closing));

  void _back() => _deferred(() {
    if (_phase == _Phase.closing) {
      setState(() => _phase = _hasActivity ? _Phase.activity : _Phase.steps);
      return;
    }
    if (_phase == _Phase.activity) {
      setState(() {
        if (widget.lesson.steps.isEmpty) {
          _phase = _Phase.intro;
        } else {
          _phase = _Phase.steps;
          _stepIndex = widget.lesson.steps.length - 1;
          _currentStepSettled = true; // a previously-visited step is already answered
        }
      });
      return;
    }
    if (_stepIndex == 0) {
      setState(() => _phase = _Phase.intro);
      return;
    }
    setState(() {
      _stepIndex--;
      _currentStepSettled = true; // a previously-visited step is already answered
    });
  });

  Widget _buildIntro(bool isDarkMode) {
    return Container(
      key: const ValueKey('intro'),
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FadeIn(child: Text('漢字', style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black))),
            const SizedBox(height: 12),
            _FadeIn(
              delay: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                color: kLessonPurple,
                child: Text(widget.lesson.title.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
            _FadeIn(
              delay: const Duration(milliseconds: 300),
              child: Text(
                widget.lesson.introSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 20),
            _FadeIn(
              delay: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kLessonPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tips_and_updates, color: kLessonPurple, size: 20),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "You don't need to have watched anything beforehand - and don't worry about getting the "
                        "questions wrong. Guessing (even wrong!) is part of how you learn.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _FadeIn(
              delay: const Duration(milliseconds: 560),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kLessonPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _start,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Let's go!", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosing(bool isDarkMode) {
    return Container(
      key: const ValueKey('closing'),
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FadeIn(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                child: const Icon(Icons.celebration, size: 56, color: kLessonPurple),
              ),
            ),
            const SizedBox(height: 20),
            _FadeIn(
              delay: const Duration(milliseconds: 150),
              child: Text(
                // An end-of-day lesson's own `day` is just a unique
                // bookkeeping number (so it doesn't collide with another
                // lesson sharing the same endOfDay), not the day that's
                // actually about to start - that's endOfDay + 1.
                "You're ready for Day ${widget.lesson.endOfDay != null ? widget.lesson.endOfDay! + 1 : widget.lesson.day}!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            _FadeIn(
              delay: const Duration(milliseconds: 250),
              child: Text(
                "You can find this lesson - and any future ones - anytime in Study → Lessons.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 28),
            _FadeIn(
              delay: const Duration(milliseconds: 380),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kLessonPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Complete Lesson', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final showBackButton = !(_phase == _Phase.intro);
    final showContinueButton = _phase == _Phase.steps && _currentStepSettled;

    Widget body;
    Object switchKey;
    switch (_phase) {
      case _Phase.intro:
        body = _buildIntro(isDarkMode);
        switchKey = 'intro';
        break;
      case _Phase.steps:
        body = _StepView(
          key: ValueKey('step-$_stepIndex'),
          step: widget.lesson.steps[_stepIndex],
          isDarkMode: isDarkMode,
          initiallySettled: _answeredSteps.contains(_stepIndex),
          onSettled: () {
            _answeredSteps.add(_stepIndex);
            if (!_currentStepSettled) setState(() => _currentStepSettled = true);
          },
        );
        switchKey = 'step-$_stepIndex';
        break;
      case _Phase.activity:
        body = widget.lesson.activityBuilder!(context, isDarkMode, _finishActivity);
        switchKey = 'activity';
        break;
      case _Phase.closing:
        body = _buildClosing(isDarkMode);
        switchKey = 'closing';
        break;
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  // Always the same IconButton (never swapped for another
                  // widget) - just disabled on the intro card. Removing a
                  // button from the tree as a direct result of tapping it
                  // (while its own ripple is still playing) is what was
                  // throwing "Looking up a deactivated widget's ancestor is
                  // unsafe" when going back from step 1 to the intro.
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: showBackButton ? (isDarkMode ? Colors.white70 : Colors.black54) : Colors.transparent,
                    ),
                    onPressed: showBackButton ? _back : null,
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: _progress),
                      duration: const Duration(milliseconds: 350),
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: isDarkMode ? Colors.white12 : Colors.black12,
                          color: kLessonPurple,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDarkMode ? Colors.white70 : Colors.black54),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(switchKey), child: body),
              ),
            ),
            if (showContinueButton)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _FadeIn(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kLessonPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _continue,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _stepIndex >= widget.lesson.steps.length - 1 ? 'Finish' : 'Continue',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
