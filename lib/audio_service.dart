import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:android_intent_plus/android_intent.dart';

// Text-to-speech via the device's own OS speech engine (flutter_tts), rather
// than an unofficial Google Translate endpoint - that endpoint isn't a
// published API, so it wasn't safe to rely on for a commercial app (no
// uptime guarantee, and Google's terms prohibit automated querying of their
// services without permission). flutter_tts makes no network calls at all,
// so there's no such exposure.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final FlutterTts _tts = FlutterTts();

  bool readAloudEnabled = true;

  // Lets a caller await actual speech completion (see speak()'s
  // waitForCompletion param) via flutter_tts's event-based completion
  // handler, rather than its awaitSpeakCompletion flag. That flag makes
  // stop() unconditionally complete a "speakResult" native-side, including
  // when one was never set (e.g. the very first speak() call in the app's
  // lifetime, since speak() always calls stop() first) - a null pointer on
  // Windows that crashes the whole app. The event handler has no such
  // failure mode and is supported everywhere this app runs.
  Completer<void>? _speechCompleter;
  bool _handlersRegistered = false;
  void _ensureCompletionHandlers() {
    if (_handlersRegistered) return;
    _handlersRegistered = true;
    void resolvePending() {
      _speechCompleter?.complete();
      _speechCompleter = null;
    }
    _tts.setCompletionHandler(resolvePending);
    _tts.setCancelHandler(resolvePending);
    _tts.setErrorHandler((_) => resolvePending());
  }

  static const _localeMap = {
    'Japanese': 'ja-JP',
    'English': 'en-US',
  };

  static const _localePrefix = {
    'Japanese': 'ja',
    'English': 'en',
  };

  List<Map<String, dynamic>>? _voicesCache;

  // Browsers (web's speechSynthesis) load their voice list asynchronously -
  // querying it right after page load can come back empty before the
  // browser's own voice-loading finishes. Only caching a non-empty result
  // means an early empty query just gets retried next time instead of
  // locking "no voices" in for the rest of the session.
  Future<List<Map<String, dynamic>>> _allVoices() async {
    if (_voicesCache != null && _voicesCache!.isNotEmpty) return _voicesCache!;
    try {
      final raw = await _tts.getVoices;
      final list = (raw as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();
      if (list.isNotEmpty) _voicesCache = list;
      return list;
    } catch (_) {
      // getVoices isn't implemented on every platform - callers fall back to
      // setLanguage-only behaviour when this comes back empty.
      return _voicesCache ?? [];
    }
  }

  // Every installed voice whose locale matches [language] (e.g. "Japanese"
  // -> every "ja*" voice) - for a voice-picker UI, and to answer "is a voice
  // for this language installed at all".
  Future<List<Map<String, dynamic>>> voicesForLanguage(String language) async {
    final prefix = _localePrefix[language] ?? '';
    final voices = await _allVoices();
    return voices.where((v) => (v['locale'] ?? '').toString().toLowerCase().startsWith(prefix)).toList();
  }

  Future<Map<String, dynamic>?> _resolveVoice(String language, String? preferredName) async {
    final matches = await voicesForLanguage(language);
    if (matches.isEmpty) return null;
    if (preferredName != null) {
      for (final v in matches) {
        if (v['name'] == preferredName) return v;
      }
    }
    return matches.first;
  }

  // flutter_tts's speech-rate scale isn't consistent across platforms (unlike
  // a simple playback-speed multiplier), so a 0.5x-2.0x UI value has to be
  // mapped differently per platform. Android takes the multiplier directly;
  // iOS/macOS center on 0.5 as "normal"; Windows centers on 0 as "normal".
  double _platformRate(double multiplier) {
    if (kIsWeb) return multiplier.clamp(0.1, 10.0);
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return (0.5 * multiplier).clamp(0.0, 1.0);
      case TargetPlatform.windows:
        return ((multiplier - 1.0) * 10).clamp(-10.0, 10.0);
      default:
        return multiplier.clamp(0.0, 2.0);
    }
  }

  // Speaks [text] in [language] ("English" or "Japanese"), optionally with a
  // specific installed voice (by name, from voicesForLanguage). Pass
  // waitForCompletion: true (e.g. for a sequential player like listening
  // mode) to have the returned future resolve only once the speech actually
  // finishes, instead of just once it starts.
  //
  // Picks a voice explicitly via setVoice rather than relying solely on
  // setLanguage: flutter_tts's Windows implementation has a bug where
  // setLanguage reports success even when no voice matches the requested
  // language, silently leaving whatever voice was already selected (so
  // Japanese text gets read with an English voice instead of failing). Using
  // setVoice avoids that, and lets a caller know via the return value when
  // no voice for the language is installed at all, instead of mispronouncing
  // it - true if it actually spoke, false if no matching voice exists.
  Future<bool> speak(String text, String language, {double rate = 1.0, String? voiceName, bool waitForCompletion = false}) async {
    if (!readAloudEnabled || text.trim().isEmpty) return false;
    final voice = await _resolveVoice(language, voiceName);
    if (voice == null) return false;

    await _tts.stop();
    try {
      await _tts.setVoice({
        'name': voice['name'].toString(),
        'locale': voice['locale'].toString(),
      });
    } catch (_) {
      await _tts.setLanguage(_localeMap[language] ?? 'ja-JP');
    }
    await _tts.setSpeechRate(_platformRate(rate));

    if (waitForCompletion) {
      _ensureCompletionHandlers();
      final completer = Completer<void>();
      _speechCompleter = completer;
      await _tts.speak(text);
      // A safety net in case a platform's completion event never fires for
      // some reason - without it, a stuck event would hang the player
      // forever instead of just skipping ahead eventually.
      await completer.future.timeout(const Duration(seconds: 20), onTimeout: () {});
    } else {
      await _tts.speak(text);
    }
    return true;
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  // Android only: jumps straight to the OS's "download this voice data" flow
  // for the missing TTS language, instead of making the user hunt through
  // Settings themselves. A no-op (returns false) on every other platform,
  // where there's no equivalent one-tap system flow to trigger.
  Future<bool> canOfferVoiceInstall() async =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> openInstallVoiceData() async {
    if (!await canOfferVoiceInstall()) return;
    try {
      const intent = AndroidIntent(action: 'android.speech.tts.engine.INSTALL_TTS_DATA');
      await intent.launch();
    } catch (_) {
      // Best-effort - some OEM ROMs or TTS engines don't implement this
      // action, and there's no good fallback except telling the user.
    }
  }
}

// Shared "no voice for this language" feedback for every audio button in the
// app - on Android it offers a one-tap fix via the OS's voice-download flow;
// on Windows (where there's no such shortcut, just a buried Settings path)
// it offers a step-by-step help dialog instead; elsewhere it's just an
// informative message.
Future<void> showMissingVoiceSnackBar(BuildContext context, bool isDarkMode, String language) async {
  final canInstall = await AudioService().canOfferVoiceInstall();
  if (!context.mounted) return;
  final isWindows = !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('No $language voice installed on this device.'),
      action: canInstall
          ? SnackBarAction(label: 'Install', onPressed: () => AudioService().openInstallVoiceData())
          : isWindows
              ? SnackBarAction(
                  label: 'Help',
                  onPressed: () => showWindowsVoiceSetupHelp(context, isDarkMode, language),
                )
              : null,
    ),
  );
}

Widget _setupStep(int number, String text, bool isDarkMode) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: const Color(0xFF9A00FE),
          child: Text(
            '$number',
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87)),
        ),
      ],
    ),
  );
}

// Step-by-step guide for installing a TTS voice on Windows, since there's no
// one-tap system flow there like Android's - reachable from the "Help"
// action on the missing-voice snackbar.
Future<void> showWindowsVoiceSetupHelp(BuildContext context, bool isDarkMode, String language) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        "Set Up $language Voice on Windows",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _setupStep(1, 'Open Windows Settings (press Win + I).', isDarkMode),
              _setupStep(2, 'Go to Time & Language > Language & region.', isDarkMode),
              _setupStep(
                3,
                'Under "Preferred languages", click "Add a language" and search for $language (e.g. 日本語 for Japanese).',
                isDarkMode,
              ),
              _setupStep(4, 'Select it and install the language pack.', isDarkMode),
              _setupStep(5, 'Click the newly added language, then "Language options".', isDarkMode),
              _setupStep(6, 'Under "Speech", click "Download" next to Text-to-speech.', isDarkMode),
              _setupStep(7, 'Once it finishes downloading, restart this app.', isDarkMode),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9A00FE),
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text("Got it"),
        ),
      ],
    ),
  );
}
