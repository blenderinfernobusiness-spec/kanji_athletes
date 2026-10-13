import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'cloud_sync_page.dart';

const Color _accent = Color(0xFF9A00FE);

// Shown once, before HomeScreen, to a brand new install that isn't signed
// in yet (see main.dart's _StartupGate for when that is). Signing in just
// finishes onboarding straight to the home screen, like a returning user;
// creating a new account instead continues to a self-reported experience
// level question, saved for later personalization (e.g. steering a brand
// new learner towards the kana course first).
class OnboardingFlow extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onFinished;
  // Shows a "Skip" button on the sign-in/create-account slide, bypassing
  // auth entirely - only set by main.dart's testing-only "Try tutorial"
  // button, so real first-time users always go through sign-in/sign-up.
  // Remove along with that button once onboarding is finished.
  final bool testMode;
  const OnboardingFlow({super.key, required this.isDarkMode, required this.onFinished, this.testMode = false});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;

  // 'brand_new' or 'knows_kana' - not acted on anywhere yet, just saved for
  // when something downstream wants to personalize off it.
  Future<void> _finishWithLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('onboarding_japanese_level', level);
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return _WelcomeSlide(isDarkMode: widget.isDarkMode, onContinue: () => setState(() => _step = 1));
      case 1:
        return _AuthSlide(
          isDarkMode: widget.isDarkMode,
          onBack: () => setState(() => _step = 0),
          onSignedIn: widget.onFinished,
          onAccountCreated: () => setState(() => _step = 2),
          onSkip: widget.testMode ? widget.onFinished : null,
        );
      default:
        return _ExperienceSlide(
          isDarkMode: widget.isDarkMode,
          onBack: () => setState(() => _step = 1),
          onChoice: _finishWithLevel,
        );
    }
  }
}

class _WelcomeSlide extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onContinue;
  const _WelcomeSlide({required this.isDarkMode, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Same bold-kanji-over-a-purple-banner treatment as the
                  // lesson category art (assets/lessonskanjiscreen.png etc)
                  // - built as text/a Container rather than another baked
                  // image, so it reflows for any string and still contrasts
                  // in dark mode (where a baked-black-text image wouldn't).
                  Text(
                    '漢字',
                    style: TextStyle(fontSize: 72, fontWeight: FontWeight.w900, color: fg, height: 1),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    color: _accent,
                    child: const Text(
                      'WELCOME!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ready to start learning Japanese?',
                    style: TextStyle(fontSize: 16, color: fgMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: onContinue,
                      child: const Text("Let's go", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceSlide extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onBack;
  final void Function(String level) onChoice;
  const _ExperienceSlide({required this.isDarkMode, required this.onBack, required this.onChoice});

  @override
  State<_ExperienceSlide> createState() => _ExperienceSlideState();
}

class _ExperienceSlideState extends State<_ExperienceSlide> {
  bool _showKanaInfo = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = widget.isDarkMode ? Colors.white70 : Colors.black54;
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'How much Japanese do you know?',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: fg),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      _ChoiceCard(
                        label: 'Brand new, still learning kana (hiragana and katakana)',
                        isDarkMode: widget.isDarkMode,
                        onTap: () => widget.onChoice('brand_new'),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showKanaInfo = !_showKanaInfo),
                          icon: Icon(_showKanaInfo ? Icons.expand_less : Icons.expand_more, size: 18, color: fgMuted),
                          label: Text('What is kana?', style: TextStyle(color: fgMuted, fontSize: 13)),
                        ),
                      ),
                      if (_showKanaInfo)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
                          child: Text(
                            "Kana are Japanese's two phonetic alphabets - hiragana (ひらがな) for native words and "
                            "grammar, and katakana (カタカナ) mostly for foreign loanwords. Together they're the "
                            "foundation everything else, including kanji, builds on.",
                            style: TextStyle(color: fgMuted, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _ChoiceCard(
                        label: 'I know kana already!',
                        isDarkMode: widget.isDarkMode,
                        onTap: () => widget.onChoice('knows_kana'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: fgMuted),
                onPressed: widget.onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final String label;
  final bool isDarkMode;
  final VoidCallback onTap;
  const _ChoiceCard({required this.label, required this.isDarkMode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final cardBg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!;
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _accent.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _AuthSlide extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onBack;
  final VoidCallback onSignedIn;
  final VoidCallback onAccountCreated;
  // Non-null only in OnboardingFlow's testMode - see its doc comment.
  final VoidCallback? onSkip;
  const _AuthSlide({
    required this.isDarkMode,
    required this.onBack,
    required this.onSignedIn,
    required this.onAccountCreated,
    this.onSkip,
  });

  @override
  State<_AuthSlide> createState() => _AuthSlideState();
}

class _AuthSlideState extends State<_AuthSlide> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  child: CloudSignInForm(
                    isDarkMode: widget.isDarkMode,
                    busy: _busy,
                    onBusyChanged: (v) => setState(() => _busy = v),
                    onSignedIn: widget.onSignedIn,
                    onAccountCreated: widget.onAccountCreated,
                    initiallyCreatingAccount: true,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                onPressed: _busy ? null : widget.onBack,
              ),
            ),
            if (widget.onSkip != null)
              Positioned(
                top: 4,
                right: 4,
                child: TextButton(
                  onPressed: _busy ? null : widget.onSkip,
                  child: Text('Skip', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
