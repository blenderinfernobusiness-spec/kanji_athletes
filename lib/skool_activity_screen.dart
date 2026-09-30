import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

const _kPurple = Color(0xFF9A00FE);
const _kSkoolUrl = 'https://www.skool.com/kanji-athletes-5541';

// One fill-in-the-blank line in a SkoolActivityScreen - the learner types
// any word/phrase they know into the blank, and it's stitched into
// [before] + word + [after] to build their final line (either side can be
// left empty for a prompt that's just a single free-form blank).
class SkoolPrompt {
  final String before;
  final String after;
  final String hint;
  const SkoolPrompt({this.before = '', this.after = '', required this.hint});
}

// A reusable "fill in the blanks, then copy & share to Skool" activity used
// at the end of several Hiragana Challenge lesson days (see lesson_data.dart's
// Lesson.activityBuilder) - each lesson supplies its own title, instructions,
// and prompts, but the mechanic and the Skool hookup are shared so every one
// of these activities looks and works the same way.
class SkoolActivityScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onDone;
  final String kicker;
  final String title;
  final String instructions;
  final List<SkoolPrompt> prompts;
  final String resultsHeading;
  final String shareInstructions;

  const SkoolActivityScreen({
    super.key,
    required this.isDarkMode,
    required this.onDone,
    required this.kicker,
    required this.title,
    required this.instructions,
    required this.prompts,
    this.resultsHeading = 'Nice work!',
    this.shareInstructions = "The button above copies what you wrote and opens Skool for you - just create a new "
        "post, give it a simple title, then paste it in and share for feedback. Everyone's just starting out too, "
        "so there's no need to be shy!",
  });

  @override
  State<SkoolActivityScreen> createState() => _SkoolActivityScreenState();
}

class _SkoolActivityScreenState extends State<SkoolActivityScreen> {
  late final List<TextEditingController> _controllers = List.generate(widget.prompts.length, (_) => TextEditingController());
  bool _showResults = false;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _lineFor(int i) {
    final word = _controllers[i].text.trim();
    final filled = word.isEmpty ? '＿＿＿' : word;
    return '${widget.prompts[i].before}$filled${widget.prompts[i].after}';
  }

  String get _allLines => List.generate(widget.prompts.length, _lineFor).join('\n');

  Future<void> _copyAndShare() async {
    await Clipboard.setData(ClipboardData(text: _allLines));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied! Opening Skool so you can paste it into a post...')),
    );
    final uri = Uri.parse(_kSkoolUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _promptCard(bool isDarkMode, int i) {
    final prompt = widget.prompts[i];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${prompt.before}＿＿＿${prompt.after}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 2),
          Text(prompt.hint, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black45)),
          const SizedBox(height: 10),
          TextField(
            controller: _controllers[i],
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: "Your word (romaji, hiragana, or kanji)",
              hintStyle: TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38),
              filled: true,
              fillColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputForm(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.kicker,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _kPurple, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 12),
          Text(
            widget.instructions,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black54),
          ),
          const SizedBox(height: 28),
          for (var i = 0; i < widget.prompts.length; i++) ...[
            _promptCard(isDarkMode, i),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () => setState(() => _showResults = true),
            child: const Text("Build It", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.celebration, size: 48, color: _kPurple),
          const SizedBox(height: 16),
          Text(
            widget.resultsHeading,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.prompts.length; i++) ...[
                  Text(
                    _lineFor(i),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  if (i < widget.prompts.length - 1) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _copyAndShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.ios_share),
            label: const Text("Copy & Share to Skool", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kPurple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: _kPurple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Share for feedback!",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.shareInstructions,
                  style: TextStyle(fontSize: 13, height: 1.4, color: isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: widget.onDone,
            child: const Text("Done", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: _showResults ? _buildResults(isDarkMode) : _buildInputForm(isDarkMode),
    );
  }
}
