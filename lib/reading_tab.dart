import 'package:flutter/material.dart';
import 'study_data.dart';
import 'reading_text_screen.dart';
import 'immersion_tab.dart';

// The Study screen's "Reading & Immersion" tab: a sub-tab for the existing
// Reading list (unchanged, see ReadingTabView below) and a sub-tab for
// Immersion (recommended channels + the "watch a video" box, see
// immersion_tab.dart). Nested inside its own DefaultTabController since the
// outer Study screen's TabController already has 3 tabs of its own.
class ReadingAndImmersionTabView extends StatelessWidget {
  final bool isDarkMode;
  const ReadingAndImmersionTabView({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            child: TabBar(
              indicatorColor: const Color(0xFF9A00FE),
              labelColor: const Color(0xFF9A00FE),
              unselectedLabelColor: isDarkMode ? Colors.white54 : Colors.black45,
              tabs: const [
                Tab(text: "Reading"),
                Tab(text: "Immersion"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                ReadingTabView(isDarkMode: isDarkMode),
                ImmersionTabView(isDarkMode: isDarkMode),
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
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Import Text",
          style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
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
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Delete Text?", style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
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
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF9A00FE)))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                              color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[100],
                              child: ListTile(
                                title: Text(
                                  text.title,
                                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  '${text.content.length} characters',
                                  style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
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
