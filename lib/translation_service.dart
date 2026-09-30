import 'package:url_launcher/url_launcher.dart';

// This used to call MyMemory (mymemory.translated.net), a free machine-
// translation API, directly in-app. It's been removed: MyMemory's free tier
// is rate-limited (and its terms don't clearly cover heavy commercial use),
// with no fallback once it's exhausted or unreachable. Rather than wire up a
// paid provider right now, translation is handled externally for the time
// being - this just opens Google Translate in the browser with the text
// (and language pair) pre-filled.
Future<void> openGoogleTranslate(String text, {String from = 'ja', String to = 'en'}) async {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;
  final uri = Uri.parse(
    'https://translate.google.com/?sl=$from&tl=$to&text=${Uri.encodeComponent(trimmed)}&op=translate',
  );
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
