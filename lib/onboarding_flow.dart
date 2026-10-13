import 'package:flutter/material.dart';
import 'cloud_sync_page.dart';

const Color _accent = Color(0xFF9A00FE);

// Shown once, before HomeScreen, to a brand new install that isn't signed
// in yet (see main.dart's _StartupGate for when that is). Signing in just
// finishes onboarding straight to the home screen, like a returning user;
// creating a new account instead continues to further slides introducing
// the app - not built yet, so for now account creation also finishes
// onboarding. When those slides exist, change _finish in the `onAccountCreated`
// callback below to advance _step instead.
class OnboardingFlow extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onFinished;
  const OnboardingFlow({super.key, required this.isDarkMode, required this.onFinished});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case 0:
        return _WelcomeSlide(isDarkMode: widget.isDarkMode, onContinue: () => setState(() => _step = 1));
      default:
        return _AuthSlide(
          isDarkMode: widget.isDarkMode,
          onBack: () => setState(() => _step = 0),
          onSignedIn: widget.onFinished,
          onAccountCreated: widget.onFinished,
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
                  const Text('辞書', style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: _accent)),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to Kanji Athletes',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: fg),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
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

class _AuthSlide extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onBack;
  final VoidCallback onSignedIn;
  final VoidCallback onAccountCreated;
  const _AuthSlide({
    required this.isDarkMode,
    required this.onBack,
    required this.onSignedIn,
    required this.onAccountCreated,
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
          ],
        ),
      ),
    );
  }
}
