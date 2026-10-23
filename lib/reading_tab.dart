import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'study_data.dart';
import 'reading_text_screen.dart';
import 'beta_tag.dart';
import 'immersion_tab.dart';
import 'app_colors.dart';
import 'app_theme.dart';

// The Study screen's "Reading & Immersion" tab. On every platform but web,
// a sub-tab for the existing Reading list (unchanged, see ReadingTabView
// below) and a sub-tab for Immersion (recommended channels + the "watch a
// video" box, see immersion_tab.dart), nested inside its own
// DefaultTabController since the outer Study screen's TabController already
// has 3 tabs of its own. Immersion needs a real embedded browser that a web
// page can't open inside itself (see immersion_tab.dart's own web-unavailable
// dialog for channels/browsing), so on web this is just Reading on its own,
// no tab bar needed for a single tab.
//
class ReadingAndImmersionTabView extends StatefulWidget {
  final bool isDarkMode;
  const ReadingAndImmersionTabView({super.key, required this.isDarkMode});

  @override
  State<ReadingAndImmersionTabView> createState() => _ReadingAndImmersionTabViewState();
}

class _ReadingAndImmersionTabViewState extends State<ReadingAndImmersionTabView> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return ReadingTabView(isDarkMode: widget.isDarkMode);
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: AppColors.pageBg(widget.isDarkMode),
            child: TabBar(
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: widget.isDarkMode ? Colors.white54 : Colors.black45,
              tabs: [
                const Tab(text: "Reading"),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Immersion"),
                      if (isImmersionBeta) ...[const SizedBox(width: 6), const BetaTag()],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ReadingTabView(isDarkMode: widget.isDarkMode),
                ImmersionTabView(isDarkMode: widget.isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// The "Reading" sub-tab: a list of imported text passages, each opened in
// ReadingTextScreen for word-highlighted reading, plus a button to import a
// new one by pasting text straight in.
class ReadingTabView extends StatefulWidget {
  final bool isDarkMode;

  const ReadingTabView({super.key, required this.isDarkMode});

  @override
  State<ReadingTabView> createState() => _ReadingTabViewState();
}

class _ReadingTabViewState extends State<ReadingTabView> {
  final List<ReadingText> _texts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final texts = await loadReadingTexts();
    if (!mounted) return;
    setState(() {
      _texts
        ..clear()
        ..addAll(texts);
      _isLoading = false;
    });
  }

  Future<void> _save() => saveReadingTexts(_texts);

  String _autoTitle(String content) {
    final firstLine = content.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => content).trim();
    return firstLine.length > 30 ? '${firstLine.substring(0, 30)}...' : firstLine;
  }

  void _showImportDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg(widget.isDarkMode),
        shape: pixelShape() ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Import Text",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(widget.isDarkMode)),
        ),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Title (optional)",
                    hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 10,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: "Paste Japanese text here",
                    hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            onPressed: () {
              final content = contentController.text.trim();
              if (content.isEmpty) return;
              final title = titleController.text.trim().isEmpty ? _autoTitle(content) : titleController.text.trim();
              final text = ReadingText(id: DateTime.now().millisecondsSinceEpoch.toString(), title: title, content: content);
              setState(() => _texts.insert(0, text));
              _save();
              Navigator.pop(context);
            },
            child: const Text("Import"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ReadingText text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg(widget.isDarkMode),
        shape: pixelShape() ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Text?", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text(widget.isDarkMode))),
        content: Text(
          'This will permanently delete "${text.title}". This cannot be undone.',
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              setState(() => _texts.remove(text));
              _save();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: pixelShape() ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _showImportDialog,
                      icon: const Icon(Icons.add),
                      label: const Text("Import text", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Expanded(
                  child: _texts.isEmpty
                      ? Center(
                          child: Text(
                            "No reading texts yet.\nImport some Japanese text to get started.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black45),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _texts.length,
                          itemBuilder: (context, index) {
                            final text = _texts[index];
                            return Card(
                              color: AppColors.cardBg(widget.isDarkMode),
                              child: ListTile(
                                title: Text(
                                  text.title,
                                  style: TextStyle(color: AppColors.text(widget.isDarkMode)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${text.content.length} characters',
                                  style: TextStyle(color: AppColors.textMuted(widget.isDarkMode)),
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReadingTextScreen(readingText: text, isDarkMode: widget.isDarkMode),
                                  ),
                                ),
                                onLongPress: () => _confirmDelete(text),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
