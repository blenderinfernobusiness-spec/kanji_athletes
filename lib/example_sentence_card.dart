import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_colors.dart';
import 'tatoeba_service.dart';

Future<void> _openSentenceSource(String? url) async {
  if (url == null) return;
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// A compact "example sentences" block for a word: each Tatoeba sentence
// with its translation and its own per-sentence attribution (Tatoeba's
// CC BY license requires crediting each sentence's individual author, not
// just Tatoeba as a whole - see tatoeba_service.dart). This is the plain,
// non-interactive sibling of VocabIntroScreen's _sentenceCard - used
// wherever sentences show up outside that full intro screen (flashcard
// reveals, the dictionary word page), where tap-to-look-up word spans
// would be more than the space/context calls for.
class ExampleSentencesSection extends StatelessWidget {
  final List<TatoebaSentence> sentences;
  final bool isDarkMode;
  final void Function(String text)? onSpeak;

  const ExampleSentencesSection({
    super.key,
    required this.sentences,
    required this.isDarkMode,
    this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    if (sentences.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final sentence in sentences) _sentenceCard(sentence)],
    );
  }

  Widget _sentenceCard(TatoebaSentence sentence) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg(isDarkMode),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  sentence.text,
                  style: TextStyle(fontSize: 16, color: AppColors.text(isDarkMode)),
                ),
              ),
              if (onSpeak != null)
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 18),
                  color: AppColors.accent,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => onSpeak!(sentence.text),
                ),
            ],
          ),
          if (sentence.translation != null && sentence.translation!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              sentence.translation!,
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textMuted(isDarkMode)),
            ),
          ],
          const SizedBox(height: 4),
          InkWell(
            onTap: sentence.sentenceUrl == null ? null : () => _openSentenceSource(sentence.sentenceUrl),
            child: Text(
              sentence.username != null ? 'Sentence by ${sentence.username} · ${sentence.license ?? 'Tatoeba'}' : 'via Tatoeba',
              style: TextStyle(
                fontSize: 10,
                color: isDarkMode ? Colors.white38 : Colors.black38,
                decoration: sentence.sentenceUrl != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
