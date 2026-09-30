import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String _studySettingsPrefsKey = 'study_settings';

class StudySettings {
  bool enableRomaji;
  bool autoReadEnglish;
  bool autoReadJapanese;
  double englishSpeed;
  double japaneseSpeed;
  // Installed TTS voice name to use for each language (null = device default).
  String? englishVoiceName;
  String? japaneseVoiceName;
  // Listening mode: whether finishing a sentence (and its translation)
  // automatically moves on to the next one, or pauses and waits for a
  // manual skip.
  bool listeningAutoAdvance;
  // Listening mode: read out each already-in-deck word (and its meaning)
  // found in a sentence before playing the sentence itself, capped to once
  // every 3 sentences per word so it doesn't get repetitive.
  bool readKnownWordsFirst;
  // JLPT Test game: whether section titles/instructions are shown in
  // Japanese (the standard, matching a real test booklet) or English.
  bool jlptInstructionsInJapanese;
  // JLPT Test game: whether picking an option immediately reveals right/wrong
  // (a practice-style aid) - off by default, matching a real test where
  // nothing is graded until you submit.
  bool jlptInstantFeedback;
  // JLPT Test game: whether a countdown timer runs and auto-submits at zero.
  bool jlptTimerEnabled;
  // JLPT Test game: text scale multiplier for question/option text, so
  // players can size it up or down. Persists like the rest of these settings.
  double jlptTextScale;
  // Study > Reading: text scale multiplier for imported passage text.
  double readingTextScale;
  // Study > Reading: shows the whole passage at once (split into sentences
  // by line breaks) rather than one sentence per screen.
  bool readingWholeTextView;

  StudySettings({
    this.enableRomaji = true,
    this.autoReadEnglish = false,
    this.autoReadJapanese = false,
    this.englishSpeed = 1.05,
    this.japaneseSpeed = 1.05,
    this.englishVoiceName,
    this.japaneseVoiceName,
    this.listeningAutoAdvance = true,
    this.readKnownWordsFirst = true,
    this.jlptInstructionsInJapanese = true,
    this.jlptInstantFeedback = false,
    this.jlptTimerEnabled = true,
    this.jlptTextScale = 1.0,
    this.readingTextScale = 1.0,
    this.readingWholeTextView = false,
  });

  Map<String, dynamic> toMap() => {
    'enableRomaji': enableRomaji,
    'autoReadEnglish': autoReadEnglish,
    'autoReadJapanese': autoReadJapanese,
    'englishSpeed': englishSpeed,
    'japaneseSpeed': japaneseSpeed,
    'englishVoiceName': englishVoiceName,
    'japaneseVoiceName': japaneseVoiceName,
    'listeningAutoAdvance': listeningAutoAdvance,
    'readKnownWordsFirst': readKnownWordsFirst,
    'jlptInstructionsInJapanese': jlptInstructionsInJapanese,
    'jlptInstantFeedback': jlptInstantFeedback,
    'jlptTimerEnabled': jlptTimerEnabled,
    'jlptTextScale': jlptTextScale,
    'readingTextScale': readingTextScale,
    'readingWholeTextView': readingWholeTextView,
  };

  factory StudySettings.fromMap(Map<String, dynamic> map) => StudySettings(
    enableRomaji: map['enableRomaji'] ?? true,
    autoReadEnglish: map['autoReadEnglish'] ?? false,
    autoReadJapanese: map['autoReadJapanese'] ?? false,
    englishSpeed: (map['englishSpeed'] ?? 1.05).toDouble(),
    japaneseSpeed: (map['japaneseSpeed'] ?? 1.05).toDouble(),
    englishVoiceName: map['englishVoiceName'],
    japaneseVoiceName: map['japaneseVoiceName'],
    listeningAutoAdvance: map['listeningAutoAdvance'] ?? true,
    readKnownWordsFirst: map['readKnownWordsFirst'] ?? true,
    jlptInstructionsInJapanese: map['jlptInstructionsInJapanese'] ?? true,
    jlptInstantFeedback: map['jlptInstantFeedback'] ?? false,
    jlptTimerEnabled: map['jlptTimerEnabled'] ?? true,
    jlptTextScale: (map['jlptTextScale'] ?? 1.0).toDouble(),
    readingTextScale: (map['readingTextScale'] ?? 1.0).toDouble(),
    readingWholeTextView: map['readingWholeTextView'] ?? false,
  );
}

Future<StudySettings> loadStudySettings() async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = prefs.getString(_studySettingsPrefsKey);
  if (encoded == null) return StudySettings();
  return StudySettings.fromMap(Map<String, dynamic>.from(jsonDecode(encoded)));
}

Future<void> saveStudySettings(StudySettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_studySettingsPrefsKey, jsonEncode(settings.toMap()));
}
