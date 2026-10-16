import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kanji_athletes/trial_service.dart';

void main() {
  test('a fresh install gets the full 7 days, unlocked false', () async {
    SharedPreferences.setMockInitialValues({});
    await TrialService.ensureTrialStarted();
    expect(TrialService.daysRemainingSync, 7);
    expect(TrialService.isTrialActiveSync, isTrue);
    expect(TrialService.isUnlockedSync, isFalse);
    expect(TrialService.hasTrialAccessSync, isTrue);
  });

  test('an existing install with no trial_start_date gets a fresh start, not locked out', () async {
    // Same as a fresh install from this service's point of view - no prior
    // key means "first time this code has ever run on this install",
    // whether that's a brand new user or an existing one updating to the
    // version that introduced trials.
    SharedPreferences.setMockInitialValues({});
    await TrialService.ensureTrialStarted();
    expect(TrialService.hasTrialAccessSync, isTrue);
  });

  test('trial expires after 7 days and locks access without the code', () async {
    final longAgo = DateTime.now().subtract(const Duration(days: 10)).toIso8601String();
    SharedPreferences.setMockInitialValues({'trial_start_date': longAgo});
    await TrialService.ensureTrialStarted();
    expect(TrialService.daysRemainingSync, 0);
    expect(TrialService.isTrialActiveSync, isFalse);
    expect(TrialService.hasTrialAccessSync, isFalse);
  });

  test('a wrong code does not unlock anything', () async {
    SharedPreferences.setMockInitialValues({});
    await TrialService.ensureTrialStarted();
    final ok = await TrialService.tryUnlock('WRONGCODE');
    expect(ok, isFalse);
    expect(TrialService.isUnlockedSync, isFalse);
  });

  test('the real code unlocks regardless of case or surrounding whitespace', () async {
    SharedPreferences.setMockInitialValues({'trial_start_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String()});
    await TrialService.ensureTrialStarted();
    expect(TrialService.hasTrialAccessSync, isFalse, reason: 'sanity check - trial should be expired before unlocking');
    final ok = await TrialService.tryUnlock('  11118kanji  ');
    expect(ok, isTrue);
    expect(TrialService.isUnlockedSync, isTrue);
    expect(TrialService.hasTrialAccessSync, isTrue, reason: 'unlocked should grant access even with the trial expired');
  });

  test('isTrialGatedTrackId only matches the Kana Course and 90 Day Challenge', () {
    expect(isTrialGatedTrackId('hiragana_challenge'), isTrue);
    expect(isTrialGatedTrackId('kanji_challenge'), isTrue);
    expect(isTrialGatedTrackId('grammar'), isFalse);
    expect(isTrialGatedTrackId('essential_vocab'), isFalse);
    expect(isTrialGatedTrackId(null), isFalse);
  });
}
