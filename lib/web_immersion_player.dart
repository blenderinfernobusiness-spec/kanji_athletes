import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'immersion_word_lookup.dart';
import 'ruby_text.dart';
import 'study_data.dart';
import 'study_settings.dart';

const Color _accent = Color(0xFF9A00FE);

// TODO: replace with the deployed captions_service Cloud Run URL once it's
// live (see captions_service/README.md for the deploy command). Until then
// every lookup fails closed - this screen still plays the video, it just
// can't show captions.
const String kCaptionsServiceUrl = 'https://CHANGE-ME.run.app';

class _CaptionCue {
  final String text;
  final Duration start;
  final Duration end;
  final List<SentenceToken> tokens;
  _CaptionCue({required this.text, required this.start, required this.end, required this.tokens});
}

// The web equivalent of video_subtitle_panel_screen.dart's native WebView
// version: since a web page can't read captions out of an embedded YouTube
// iframe itself (no site can read into another site's embedded content,
// browsers block it by design), playback uses YouTube's own official
// embeddable player instead, and captions come from captions_service - a
// small server that fetches them once per video using a real browser (so it
// isn't blocked the way a plain request is) and caches the result, so every
// later viewer of that same video gets them instantly.
class WebImmersionPlayerScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final bool isDarkMode;
  const WebImmersionPlayerScreen({super.key, required this.videoId, required this.title, required this.isDarkMode});

  @override
  State<WebImmersionPlayerScreen> createState() => _WebImmersionPlayerScreenState();
}

class _WebImmersionPlayerScreenState extends State<WebImmersionPlayerScreen> {
  late final YoutubePlayerController _controller;
  final _scrollController = ScrollController();

  Map<String, HighlightEntry> _highlightIndex = {};
  StudySettings _settings = StudySettings();
  List<_CaptionCue> _cues = [];
  bool _loadingCaptions = true;
  String? _captionsError;
  int _activeCueIndex = -1;
  Timer? _positionTimer;

  Color get _fg => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _fgMuted => widget.isDarkMode ? Colors.white60 : Colors.black54;
  Color get _bg => widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true),
    );
    _loadLookupData();
    _loadCaptions();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 400), (_) => _syncActiveCue());
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    _controller.close();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadLookupData() async {
    final decks = await loadStudyDecks();
    final allCards = decks.expand((d) => d.cards).toList();
    final settings = await loadStudySettings();
    if (!mounted) return;
    setState(() {
      _highlightIndex = buildHighlightIndex(allCards);
      _settings = settings;
    });
  }

  Future<void> _loadCaptions() async {
    try {
      final uri = Uri.parse(kCaptionsServiceUrl).replace(queryParameters: {'videoId': widget.videoId});
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        setState(() {
          _loadingCaptions = false;
          _captionsError = 'Captions aren\'t available for this video right now.';
        });
        return;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final available = data['available'] as bool? ?? false;
      final rawCues = (data['cues'] as List<dynamic>? ?? []);
      if (!available || rawCues.isEmpty) {
        setState(() {
          _loadingCaptions = false;
          _captionsError = 'This video doesn\'t have Japanese captions.';
        });
        return;
      }
      final cues = rawCues.map((c) {
        final map = c as Map<String, dynamic>;
        final text = map['text'] as String? ?? '';
        final start = Duration(milliseconds: (map['startMs'] as num? ?? 0).toInt());
        final duration = Duration(milliseconds: (map['durationMs'] as num? ?? 0).toInt());
        return _CaptionCue(text: text, start: start, end: start + duration, tokens: tokenizeSentence(text, _highlightIndex));
      }).toList();
      if (!mounted) return;
      setState(() {
        _cues = cues;
        _loadingCaptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingCaptions = false;
        _captionsError = 'Couldn\'t load captions - check your connection and try again.';
      });
    }
  }

  Future<void> _syncActiveCue() async {
    if (_cues.isEmpty || !mounted) return;
    final state = await _controller.playerState;
    if (state != PlayerState.playing) return;
    final position = await _controller.currentTime;
    final current = Duration(milliseconds: (position * 1000).round());
    var index = -1;
    for (var i = 0; i < _cues.length; i++) {
      if (current >= _cues[i].start && current < _cues[i].end) {
        index = i;
        break;
      }
    }
    if (index != _activeCueIndex && mounted) {
      setState(() => _activeCueIndex = index);
      if (index >= 0) {
        _scrollController.animateTo(
          (index * 56.0).clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onTapToken(SentenceToken token) {
    if (token.entry != null) {
      showImmersionKnownWord(
        context,
        entry: token.entry!,
        isDarkMode: widget.isDarkMode,
        settings: _settings,
        highlightIndex: _highlightIndex,
      );
    } else if (token.text.trim().isNotEmpty) {
      showImmersionUnknownText(context, text: token.text, isDarkMode: widget.isDarkMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(controller: _controller),
          ),
          Expanded(child: _buildCaptionArea()),
        ],
      ),
    );
  }

  Widget _buildCaptionArea() {
    if (_loadingCaptions) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }
    if (_captionsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_captionsError!, textAlign: TextAlign.center, style: TextStyle(color: _fgMuted)),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _cues.length,
      itemBuilder: (context, index) {
        final cue = _cues[index];
        final active = index == _activeCueIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? _accent.withValues(alpha: widget.isDarkMode ? 0.18 : 0.08) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final token in cue.tokens)
                GestureDetector(
                  onTap: () => _onTapToken(token),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: rubyWord(
                      text: token.text,
                      reading: token.entry?.reading ?? '',
                      fontSize: 18,
                      textColor: token.entry != null ? _accent : _fg,
                      rubyColor: _fgMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
