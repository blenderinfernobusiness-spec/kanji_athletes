import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'backup_data.dart';
import 'cloud_sync_page.dart' show CloudSignInForm;
import 'cloud_sync_service.dart';
import 'firebase_options.dart';
import 'listening_player.dart';
import 'study_data.dart';
import 'writing_practice_canvas.dart';

const Color _accent = Color(0xFF9A00FE);
const Color _bg = Color(0xFF1C1C1C);
const Color _panel = Color(0xFF2A2A2A);

// Kanji Athletes Mini: a small always-on-top companion window for practicing
// flashcards or Reading & Listening while working, without the full app's
// navigation around it. It's the same account as the main app and the
// Chrome extension - signing in pulls the latest cloud backup via the same
// merge-sync used everywhere else (see backup_data.dart's syncToCloud),
// rather than keeping any data of its own.
Future<void> runMiniApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(380, 640),
    minimumSize: Size(300, 440),
    center: true,
    backgroundColor: _bg,
    title: 'Kanji Athletes Mini',
    titleBarStyle: TitleBarStyle.normal,
  );
  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setAlwaysOnTop(true); // pinned on top by default
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MiniApp());
}

class MiniApp extends StatelessWidget {
  const MiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(primary: _accent, secondary: _accent),
      ),
      home: const MiniHomeScreen(),
    );
  }
}

// Slim top bar shown on every Mini screen: back button (optional), title,
// the always-on-top pin toggle, and whatever trailing actions a screen wants
// (sync, sign out). Kept separate from an AppBar so it stays compact and
// consistent whether or not a screen needs a Scaffold app bar otherwise.
class MiniTopBar extends StatefulWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const MiniTopBar({super.key, required this.title, this.onBack, this.actions = const []});

  @override
  State<MiniTopBar> createState() => _MiniTopBarState();
}

class _MiniTopBarState extends State<MiniTopBar> {
  bool _pinned = true; // matches the always-on-top set at window creation

  Future<void> _togglePin() async {
    final next = !_pinned;
    await windowManager.setAlwaysOnTop(next);
    setState(() => _pinned = next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _panel,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          if (widget.onBack != null)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: widget.onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...widget.actions,
          IconButton(
            icon: Icon(
              _pinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _pinned ? _accent : Colors.white54,
              size: 18,
            ),
            tooltip: _pinned ? 'Always on top (on)' : 'Always on top (off)',
            onPressed: _togglePin,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

class MiniHomeScreen extends StatefulWidget {
  const MiniHomeScreen({super.key});

  @override
  State<MiniHomeScreen> createState() => _MiniHomeScreenState();
}

class _MiniHomeScreenState extends State<MiniHomeScreen> {
  bool _busy = false;
  bool _syncedThisSession = false;
  String? _statusMessage;

  Future<void> _syncNow({bool silent = false}) async {
    setState(() {
      _busy = true;
      if (!silent) _statusMessage = 'Syncing…';
    });
    try {
      await syncToCloud();
      setState(() {
        _syncedThisSession = true;
        _statusMessage = 'Synced';
      });
    } catch (e) {
      setState(() => _statusMessage = 'Sync failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          StreamBuilder<User?>(
            stream: CloudSyncService.authStateChanges,
            builder: (context, snapshot) {
              final user = snapshot.data;
              return MiniTopBar(
                title: 'Kanji Athletes Mini',
                actions: user == null
                    ? const []
                    : [
                        if (_busy)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.sync, color: Colors.white54, size: 18),
                            tooltip: 'Sync now',
                            onPressed: () => _syncNow(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white54, size: 18),
                          tooltip: 'Sign out',
                          onPressed: () async {
                            await CloudSyncService.signOut();
                            setState(() => _syncedThisSession = false);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        ),
                      ],
              );
            },
          ),
          Expanded(
            child: StreamBuilder<User?>(
              stream: CloudSyncService.authStateChanges,
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user == null) {
                  return SingleChildScrollView(child: CloudSignInForm(isDarkMode: true, busy: _busy, onBusyChanged: (b) => setState(() => _busy = b)));
                }
                if (!_syncedThisSession) {
                  if (!_busy) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _syncNow(silent: true));
                  }
                  return const Center(child: CircularProgressIndicator(color: _accent));
                }
                return MiniModePicker(statusMessage: _statusMessage);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MiniModePicker extends StatelessWidget {
  final String? statusMessage;
  const MiniModePicker({super.key, this.statusMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (statusMessage != null) ...[
            Text(statusMessage!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(height: 16),
          ],
          _ModeButton(
            icon: Icons.style_outlined,
            label: 'Flashcards',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MiniDeckPicker(mode: MiniMode.flashcards)),
            ),
          ),
          const SizedBox(height: 16),
          _ModeButton(
            icon: Icons.headphones_outlined,
            label: 'Reading & Listening',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MiniDeckPicker(mode: MiniMode.listening)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ModeButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 90,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _panel,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: _accent, size: 28),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

enum MiniMode { flashcards, listening }

class MiniDeckPicker extends StatefulWidget {
  final MiniMode mode;
  const MiniDeckPicker({super.key, required this.mode});

  @override
  State<MiniDeckPicker> createState() => _MiniDeckPickerState();
}

class _MiniDeckPickerState extends State<MiniDeckPicker> {
  List<StudyDeck> _decks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final decks = await loadStudyDecks();
    if (!mounted) return;
    setState(() {
      _decks = decks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          MiniTopBar(title: 'Choose a deck', onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _accent))
                : _decks.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No decks yet - add some in the app or sync first.',
                            style: TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _decks.length,
                        itemBuilder: (context, index) {
                          final deck = _decks[index];
                          final dueCount = deck.cards.where(isCardDue).length;
                          return ListTile(
                            title: Text(deck.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              '${deck.cards.length} card(s) - $dueCount due',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right, color: Colors.white38),
                            onTap: () {
                              if (widget.mode == MiniMode.flashcards) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MiniFlashcardsScreen(deck: deck, allDecks: _decks),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ListeningPlayerScreen(
                                      title: deck.name,
                                      cards: deck.cards,
                                      isDarkMode: true,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class MiniFlashcardsScreen extends StatefulWidget {
  final StudyDeck deck;
  final List<StudyDeck> allDecks;
  const MiniFlashcardsScreen({super.key, required this.deck, required this.allDecks});

  @override
  State<MiniFlashcardsScreen> createState() => _MiniFlashcardsScreenState();
}

class _MiniFlashcardsScreenState extends State<MiniFlashcardsScreen> {
  List<StudyCard> _queue = [];
  int _index = 0;
  bool _showAnswer = false; // basic mode's reveal gate
  bool _drawAnswerRevealed = false; // draw mode's reveal gate
  int _drawResetCounter = 0; // bumped to clear the drawing canvas between cards
  int _correctCount = 0;
  int _reviewedCount = 0;

  // Same fallback as the main app's study screen: a draw-mode card with no
  // stroke data to draw against can't actually be drawn, so it's shown as a
  // basic flip card instead.
  String _effectiveMode(StudyCard card) =>
      (card.answerMode == 'draw' && card.kanjiVGCodes.isEmpty) ? 'basic' : card.answerMode;

  @override
  void initState() {
    super.initState();
    _buildQueue();
  }

  // Mirrors spaced_repetition_standard.dart's queue logic (due reviews, plus
  // new cards capped by the deck's own pacing) without the full app's lesson
  // intros/tutorials - this is meant for quick practice, not first exposure
  // to brand-new material.
  void _buildQueue() {
    final deck = widget.deck;
    final due = deck.cards.where(isCardDue).toList();
    final reviews = due.where((c) => c.nextReviewDate != null).toList();
    final newCards = due.where((c) => c.nextReviewDate == null).toList();

    List<StudyCard> newCardsForSession;
    if (deck.challengeStartDate != null) {
      final start = DateTime.parse(deck.challengeStartDate!);
      final currentDay = DateTime.now().difference(start).inDays + 1;
      newCardsForSession = newCards.where((c) => (c.challengeDay ?? 1) <= currentDay).toList();
    } else {
      final today = todayStamp();
      if (deck.newCardsIntroducedDate != today) {
        deck.newCardsIntroducedDate = today;
        deck.newCardsIntroducedToday = 0;
      }
      final newAllowed = (deck.newCardsPerDay - deck.newCardsIntroducedToday).clamp(0, newCards.length);
      newCardsForSession = newCards.take(newAllowed).toList();
    }
    _queue = [...reviews, ...newCardsForSession];
  }

  Future<void> _grade(bool correct) async {
    final card = _queue[_index];
    final wasNew = card.nextReviewDate == null;
    recordReview(card, correct); // mutates the same StudyCard instance held in widget.deck.cards
    if (wasNew) widget.deck.newCardsIntroducedToday += 1;

    await saveStudyDecks(widget.allDecks);

    setState(() {
      _reviewedCount++;
      if (correct) _correctCount++;
      _showAnswer = false;
      _drawAnswerRevealed = false;
      _drawResetCounter++;
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final done = _index >= _queue.length;
    return Scaffold(
      body: Column(
        children: [
          MiniTopBar(title: widget.deck.name, onBack: () => Navigator.of(context).pop()),
          Expanded(
            child: done ? _buildDoneView() : _buildCardView(_queue[_index]),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: _accent, size: 40),
            const SizedBox(height: 12),
            Text(
              _reviewedCount == 0
                  ? 'Nothing due in this deck right now.'
                  : 'All done - $_correctCount/$_reviewedCount correct.',
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView(StudyCard card) {
    final mode = _effectiveMode(card);
    final answerRevealed = mode == 'draw' ? _drawAnswerRevealed : _showAnswer;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('${_index + 1} / ${_queue.length}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 12),
          Expanded(
            child: mode == 'draw' ? _buildDrawCard(card) : _buildBasicCard(card),
          ),
          const SizedBox(height: 16),
          if (!answerRevealed)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
                onPressed: () => setState(() {
                  if (mode == 'draw') {
                    _drawAnswerRevealed = true;
                  } else {
                    _showAnswer = true;
                  }
                }),
                child: const Text('Show Answer'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB00020), foregroundColor: Colors.white),
                    onPressed: () => _grade(false),
                    child: const Text('Incorrect'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32), foregroundColor: Colors.white),
                    onPressed: () => _grade(true),
                    child: const Text('Correct'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Matches the main app's basic-mode colouring (plain white/black text,
  // purple reserved for buttons) rather than tinting the revealed answer.
  Widget _buildBasicCard(StudyCard card) {
    final prompt = card.englishFirst ? card.english : card.japanese;
    final answer = card.englishFirst ? card.japanese : card.english;
    final reading = card.hiragana.isNotEmpty && card.hiragana != card.japanese ? card.hiragana : null;

    return GestureDetector(
      onTap: () => setState(() => _showAnswer = true),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prompt,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (_showAnswer) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: Colors.white24),
                  ),
                  if (reading != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(reading, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    ),
                  Text(
                    answer,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Text('Tap to reveal', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawCard(StudyCard card) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 420).clamp(0.45, 1.0);
        return SingleChildScrollView(
          child: Column(
            children: [
              Text(
                card.englishFirst ? card.english : card.japanese,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              WritingPracticeCanvas(
                key: ValueKey('draw-$_index-$_drawResetCounter'),
                kanjiVGCodes: card.kanjiVGCodes,
                isDarkMode: true,
                kanji: card.japanese,
                translation: card.english,
                hideButtons: true,
                compactStrokeControls: true,
                showAnswerOverride: _drawAnswerRevealed,
                resetCounter: _drawResetCounter,
                scale: scale,
              ),
            ],
          ),
        );
      },
    );
  }
}
