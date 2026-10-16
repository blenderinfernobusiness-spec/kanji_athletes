import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'study_data.dart';
import 'reading_text_screen.dart';
import 'beta_tag.dart';
import 'immersion_tab.dart';
import 'trial_service.dart';
import 'unlock_dialog.dart';

// The Study screen's "Reading & Immersion" tab: a sub-tab for the existing
// Reading list (unchanged, see ReadingTabView below) and a sub-tab for
// Immersion (recommended channels + the "watch a video" box, see
// immersion_tab.dart). Nested inside its own DefaultTabController since the
// outer Study screen's TabController already has 3 tabs of its own.
//
// Both sub-tabs are free for the first 7 days (see trial_service.dart) -
// a status banner shows the days left (or, once unlocked, a permanent
// confirmation), and once the trial runs out their content is replaced by a
// locked placeholder until the code is entered.
class ReadingAndImmersionTabView extends StatefulWidget {
  final bool isDarkMode;
  const ReadingAndImmersionTabView({super.key, required this.isDarkMode});

  @override
  State<ReadingAndImmersionTabView> createState() => _ReadingAndImmersionTabViewState();
}

class _ReadingAndImmersionTabViewState extends State<ReadingAndImmersionTabView> {
  Future<void> _unlock() async {
    final unlocked = await showUnlockDialog(context, widget.isDarkMode, featureName: 'Reading & Immersion');
    if (unlocked && mounted) setState(() {});
  }

  Widget _statusBanner() {
    final unlocked = TrialService.isUnlockedSync;
    final daysLeft = TrialService.daysRemainingSync;
    final color = unlocked ? Colors.green : const Color(0xFFCCA300);
    final label = unlocked
        ? 'PREMIUM USAGE ENABLED'
        : daysLeft > 0
            ? '$daysLeft day${daysLeft == 1 ? '' : 's'} left in your free trial'
            : 'Your free trial has ended';
    return Container(
      width: double.infinity,
      color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          if (!unlocked)
            InkWell(
              onTap: _unlock,
              child: const Text(
                'Unlock full access here',
                style: TextStyle(color: Color(0xFF9A00FE), fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }

  Widget _lockedBody() {
    final fg = widget.isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = widget.isDarkMode ? Colors.white70 : Colors.black54;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 48, color: fgMuted),
            const SizedBox(height: 16),
            Text(
              'Your 7-day free trial of Reading & Immersion has ended',
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
              onPressed: _unlock,
              child: const Text('Unlock full access'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(kUpgradeUrl), mode: LaunchMode.externalApplication),
              child: const Text('Upgrade on Skool'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = !TrialService.hasTrialAccessSync;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
            child: TabBar(
              indicatorColor: const Color(0xFF9A00FE),
              labelColor: const Color(0xFF9A00FE),
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
          _statusBanner(),
          Expanded(
            child: locked
                ? _lockedBody()
                : TabBarView(
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
