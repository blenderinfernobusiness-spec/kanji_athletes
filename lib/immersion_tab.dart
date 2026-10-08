import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'beta_tag.dart';
import 'video_subtitle_panel_screen.dart';

const Color _accent = Color(0xFF9A00FE);

// Immersion needs a real embedded browser to read YouTube's caption track
// live (see video_subtitle_panel_screen.dart) - something no web page can do
// to another site's embedded content, by browser design, so there's no web
// version of this screen. These are where to get one instead.
const String _androidDownloadUrl = 'https://drive.google.com/file/d/1mm57-tEzo3Ov752sFYJBNUEm03LsNIz2/view';
const String _windowsDownloadUrl = 'https://drive.google.com/file/d/1Vg-b6I7zILQHjJxme38etXWxm4SuOcNL/view';
const String _chromeExtensionUrl = 'https://drive.google.com/file/d/12yO5-Ppb0sgp_c7OBpGt3TNSbxNvJnD8/view';

class _ImmersionChannel {
  final String name;
  final String description;
  final String url;
  const _ImmersionChannel({required this.name, required this.description, required this.url});
}

// Hand-picked, not pulled from anywhere live - add more here as they come up.
const List<_ImmersionChannel> _recommendedChannels = [
  _ImmersionChannel(
    name: 'Speak Japanese Naturally',
    description: 'Comprehensible-input style immersion content.',
    url: 'https://www.youtube.com/@SpeakJapaneseNaturally',
  ),
];

// The Study screen's "Immersion" sub-tab (see reading_tab.dart's
// ReadingAndImmersionTabView): a short list of recommended Japanese
// immersion channels, plus a "Watch a video" box for pasting any YouTube
// link to watch with clickable subtitles.
class ImmersionTabView extends StatefulWidget {
  final bool isDarkMode;
  const ImmersionTabView({super.key, required this.isDarkMode});

  @override
  State<ImmersionTabView> createState() => _ImmersionTabViewState();
}

class _ImmersionTabViewState extends State<ImmersionTabView> {
  final _urlController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Color get _fg => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _fgMuted => widget.isDarkMode ? Colors.white60 : Colors.black54;
  Color get _cardBg => widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100]!;

  void _openInApp(String url, String title) {
    if (kIsWeb) {
      _showWebUnavailableDialog();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoSubtitlePanelScreen(initialUrl: url, title: title, isDarkMode: widget.isDarkMode),
      ),
    );
  }

  void _showWebUnavailableDialog() {
    final fg = _fg;
    final fgMuted = _fgMuted;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text('Immersion isn\'t available on web', style: TextStyle(color: fg)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Watching a video with clickable subtitles needs a real browser window, which a web page can\'t open inside itself.',
              style: TextStyle(color: fgMuted, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Use one of these instead:',
              style: TextStyle(color: fgMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            _WebUnavailableLink(label: 'Android app', url: _androidDownloadUrl, fg: fg),
            _WebUnavailableLink(label: 'Windows app', url: _windowsDownloadUrl, fg: fg),
            _WebUnavailableLink(label: 'Chrome extension', url: _chromeExtensionUrl, fg: fg),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: fgMuted)),
          ),
        ],
      ),
    );
  }

  // hl (interface language) + gl (region) are the same parameters YouTube's
  // own language/region setting sets - pushes recommendations, trending, and
  // the UI itself towards Japanese YouTube rather than whatever the device's
  // own locale would otherwise show. YouTube remembers this via a cookie for
  // the rest of the browsing session, so it carries over to pages navigated
  // to from here too, not just the first one loaded.
  String _withJapaneseLocale(String url) {
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: {...uri.queryParameters, 'hl': 'ja', 'gl': 'JP'}).toString();
  }

  void _openChannel(_ImmersionChannel channel) => _openInApp(_withJapaneseLocale(channel.url), channel.name);

  void _browseYouTube() => _openInApp(_withJapaneseLocale('https://www.youtube.com'), 'YouTube');

  void _watchVideo() {
    final input = _urlController.text.trim();
    final videoId = _extractYouTubeId(input);
    if (videoId == null) {
      setState(() => _error = "That doesn't look like a YouTube video link.");
      return;
    }
    setState(() => _error = null);
    _openInApp('https://www.youtube.com/watch?v=$videoId', 'YouTube');
  }

  // Pulls the 11-character video id out of the common URL shapes:
  // youtube.com/watch?v=ID, youtu.be/ID, youtube.com/shorts/ID, with or
  // without extra query params (timestamps, playlist, etc).
  String? _extractYouTubeId(String input) {
    if (input.isEmpty) return null;
    Uri? uri = Uri.tryParse(input);
    if (uri == null) return null;
    if (uri.host.contains('youtu.be')) {
      final segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.first : null;
    }
    if (uri.host.contains('youtube.com')) {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'shorts' && uri.pathSegments.length > 1) {
        return uri.pathSegments[1];
      }
      return uri.queryParameters['v'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (isImmersionBeta) ...[
            Row(
              children: [
                const BetaTag(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Immersion is still rough around the edges on Android - browsing and watching work, but may be fiddly.',
                    style: TextStyle(color: _fgMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _browseYouTube,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Browse YouTube', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          Text('Recommended channels', style: TextStyle(color: _fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Japanese immersion content worth watching once you can follow along a little. Opens inside the app.',
            style: TextStyle(color: _fgMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final channel in _recommendedChannels)
            Card(
              color: _cardBg,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.ondemand_video, color: _accent),
                title: Text(channel.name, style: TextStyle(color: _fg, fontWeight: FontWeight.w600)),
                subtitle: Text(channel.description, style: TextStyle(color: _fgMuted)),
                trailing: Icon(Icons.chevron_right, color: _fgMuted),
                onTap: () => _openChannel(channel),
              ),
            ),
          const SizedBox(height: 28),
          Text('Watch a video', style: TextStyle(color: _fg, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'Paste a YouTube link to a video with Japanese subtitles.',
            style: TextStyle(color: _fgMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _urlController,
            style: TextStyle(color: _fg),
            decoration: InputDecoration(
              hintText: 'https://www.youtube.com/watch?v=...',
              hintStyle: TextStyle(color: _fgMuted),
              filled: true,
              fillColor: _cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _watchVideo(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _watchVideo,
              child: const Text('Watch', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebUnavailableLink extends StatelessWidget {
  final String label;
  final String url;
  final Color fg;
  const _WebUnavailableLink({required this.label, required this.url, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, color: _accent, size: 16),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
