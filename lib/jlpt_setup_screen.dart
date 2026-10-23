import 'package:flutter/material.dart';
import 'study_data.dart';
import 'study_settings.dart';
import 'jlpt_test_game.dart';
import 'app_colors.dart';
import 'app_theme.dart';

// Shown before a JLPT Test starts: lets the user set the test's Japanese
// instructions / instant feedback / timer options (persisted like the rest
// of Study's settings) before jumping into the actual test.
class JlptSetupScreen extends StatefulWidget {
  final String title;
  final List<StudyCard> questions;
  final bool isDarkMode;

  const JlptSetupScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.isDarkMode,
  });

  @override
  State<JlptSetupScreen> createState() => _JlptSetupScreenState();
}

class _JlptSetupScreenState extends State<JlptSetupScreen> {
  StudySettings _settings = StudySettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await loadStudySettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loaded = true;
    });
  }

  void _applyChange(void Function() change) {
    setState(change);
    saveStudySettings(_settings);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Scaffold(
      backgroundColor: AppColors.pageBg(isDarkMode),
      appBar: AppBar(
        backgroundColor: AppColors.pageBg(isDarkMode),
        title: Text('JLPT Test: ${widget.title}', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: !_loaded
            ? Center(child: CircularProgressIndicator(color: AppColors.accent))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Test Settings",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.text(isDarkMode)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${widget.questions.length} card${widget.questions.length == 1 ? '' : 's'} selected",
                      style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Japanese instructions", style: TextStyle(color: AppColors.text(isDarkMode))),
                      subtitle: Text(
                        "Standard for a real test. Turn off to show section titles and instructions in English instead.",
                        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45),
                      ),
                      value: _settings.jlptInstructionsInJapanese,
                      activeColor: AppColors.accent,
                      onChanged: (v) => _applyChange(() => _settings.jlptInstructionsInJapanese = v),
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Instant feedback", style: TextStyle(color: AppColors.text(isDarkMode))),
                      subtitle: Text(
                        "Off by default, like a real test - nothing is graded until you submit. Turn on to see right/wrong as you answer, like practice.",
                        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45),
                      ),
                      value: _settings.jlptInstantFeedback,
                      activeColor: AppColors.accent,
                      onChanged: (v) => _applyChange(() => _settings.jlptInstantFeedback = v),
                    ),
                    const Divider(height: 32),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Timer", style: TextStyle(color: AppColors.text(isDarkMode))),
                      subtitle: Text(
                        "Counts down and auto-submits the test when it runs out. Turn off to take as long as you like.",
                        style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45),
                      ),
                      value: _settings.jlptTimerEnabled,
                      activeColor: AppColors.accent,
                      onChanged: (v) => _applyChange(() => _settings.jlptTimerEnabled = v),
                    ),
                    const Divider(height: 32),
                    Text("Text size", style: TextStyle(color: AppColors.text(isDarkMode))),
                    Text(
                      "Scales the question and answer text during the test. Persists across the app.",
                      style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45),
                    ),
                    Row(
                      children: [
                        Text("A", style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : Colors.black45)),
                        Expanded(
                          child: Slider(
                            value: _settings.jlptTextScale,
                            min: 0.8,
                            max: 1.6,
                            divisions: 8,
                            activeColor: AppColors.accent,
                            label: '${(_settings.jlptTextScale * 100).round()}%',
                            onChanged: (v) => _applyChange(() => _settings.jlptTextScale = v),
                          ),
                        ),
                        Text("A", style: TextStyle(fontSize: 22, color: isDarkMode ? Colors.white54 : Colors.black45)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: pixelShape() ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => JlptTestGameScreen(
                                title: widget.title,
                                questions: widget.questions,
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          );
                        },
                        child: const Text("Start Test", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
