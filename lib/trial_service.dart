import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Free-trial gating - a single code (kUnlockCode) unlocks everything
// permanently; until then, a 7-day clock starting from the very first time
// the app was ever opened on this install gives full access to everything,
// premade decks included. Once the trial runs out without the code being
// entered, every deck (premade or custom) stops introducing new cards -
// existing progress stays fully revisable - and Games, viewing previous
// Lessons, Reading, Immersion, Listening, and the Dictionary lock outright.
// This is a separate lock from study.dart's _adminUnlockAllLessons (that
// one's for previewing not-yet-released content; this one's the free-trial
// paywall).
const String kUnlockCode = '11118KANJI';
const String kUpgradeUrl =
    'https://www.skool.com/kanji-athletes-5541/classroom/4bc7f780?md=6b0c57bde79046d78e36ae77eb39b8ea';
const int kTrialDays = 7;

class TrialService {
  TrialService._();

  static const _trialStartKey = 'trial_start_date';
  static const _unlockedKey = 'full_access_unlocked';

  // Kept in memory after the first async load (ensureTrialStarted, called
  // once at startup) so day-gating logic that can't await - like building a
  // Spaced Repetition queue - still has a current answer. Only two things
  // ever change it after startup: entering a valid code, and time passing
  // (which daysRemainingSync re-derives live from the cached start date, not
  // from a stale cached day-count).
  static DateTime? _cachedTrialStart;
  static bool _cachedUnlocked = false;

  // Call once at app startup, before anything reads trial state - records
  // "now" as the trial's start the very first time this runs on a given
  // install (including an existing install updating to the version that
  // first introduced this, which gets a fresh 7 days rather than being
  // locked out immediately), then loads both values into the sync cache.
  static Future<void> ensureTrialStarted() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_trialStartKey)) {
      await prefs.setString(_trialStartKey, DateTime.now().toIso8601String());
    }
    _cachedTrialStart = DateTime.parse(prefs.getString(_trialStartKey)!);
    _cachedUnlocked = prefs.getBool(_unlockedKey) ?? false;
  }

  static int get daysRemainingSync {
    final start = _cachedTrialStart;
    if (start == null) return kTrialDays;
    final elapsedDays = DateTime.now().difference(start).inHours ~/ 24;
    final remaining = kTrialDays - elapsedDays;
    return remaining < 0 ? 0 : remaining;
  }

  static bool get isUnlockedSync => _cachedUnlocked;
  static bool get isTrialActiveSync => daysRemainingSync > 0;

  // Kana Course, 90 Day Kanji Challenge, Reading, and Immersion all check
  // this - unlocked by either the code or still being inside the 7-day trial.
  static bool get hasTrialAccessSync => isUnlockedSync || isTrialActiveSync;

  // The moment the trial ends (or ended) - used to freeze a day-scheduled
  // deck's new-card schedule at whatever day it had reached right when the
  // trial ran out, rather than it continuing to silently introduce new days'
  // cards for free. See study_data.dart's buildSpacedRepetitionQueue.
  static DateTime get trialEndDate => (_cachedTrialStart ?? DateTime.now()).add(const Duration(days: kTrialDays));

  // Checks the exact code (case-insensitive, trimmed) and, if it matches,
  // unlocks everything immediately (updating the sync cache right away) and
  // best-effort saves the flag to this account's cloud storage, if signed
  // in, so a reinstall or a new device on the same account doesn't need the
  // code re-entered. Returns whether the code was valid.
  static Future<bool> tryUnlock(String code) async {
    if (code.trim().toUpperCase() != kUnlockCode) return false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_unlockedKey, true);
    _cachedUnlocked = true;
    await _saveToCloud();
    return true;
  }

  static Future<void> _saveToCloud() async {
    // The whole body (including the FirebaseAuth.instance getter itself,
    // which throws synchronously if Firebase hasn't been initialized - e.g.
    // a widget test pumping this without Firebase.initializeApp() first) is
    // best-effort: the local unlock already took effect regardless of
    // whether this device is online, signed in, or even has Firebase set up.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
        'fullAccessUnlocked': true,
        'unlockedAt': DateTime.now().toIso8601String(),
      })));
      await FirebaseStorage.instance
          .ref('backups/${user.uid}/unlock_status.json')
          .putData(bytes, SettableMetadata(contentType: 'application/json'))
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  // Pulls this account's cloud unlock flag down to this device - call right
  // after a successful sign-in (and optionally at startup if already signed
  // in from a previous session), so a returning user on a new device or
  // reinstall doesn't have to re-enter the code.
  static Future<void> syncFromCloud() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || _cachedUnlocked) return; // already unlocked locally - nothing to pull
      final bytes = await FirebaseStorage.instance
          .ref('backups/${user.uid}/unlock_status.json')
          .getData(4096)
          .timeout(const Duration(seconds: 15));
      if (bytes == null) return;
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      if (json['fullAccessUnlocked'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_unlockedKey, true);
        _cachedUnlocked = true;
      }
    } catch (_) {
      // Offline, no file yet (never unlocked on any device), etc. - the
      // local trial clock still applies either way.
    }
  }
}
