import 'package:flutter/material.dart';
import 'sets_data.dart';
import 'item_detail.dart';
import 'view_all_sets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'set_preferences.dart';

class DictionaryScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final Set<String>? initialFilters;

  const DictionaryScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    this.initialFilters,
  });

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _allItems = [];
  List<dynamic> _filteredItems = [];
  bool _showHidden = false;
  int _currentIndex = -1;
  // Pagination
  final int _itemsPerPage = 100;
  int _currentPage = 1;
  Set<String> _activeFilters = {'Kanji', 'Hiragana', 'Katakana', 'Vocabulary'}; // All active by default
  final Set<String> _selectedTags = {}; // Selected tags for filtering
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Set initial filters if provided, otherwise default to all types
    if (widget.initialFilters != null) {
      _activeFilters = widget.initialFilters!;
    }
    _loadAllItems();
    // Use debounced listener for search
    _searchController.addListener(_onSearchChanged);
    // Apply initial filters after loading
    _filterItems();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Start new timer
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _filterItems();
    });
  }

  void _loadAllItems() {
    _allItems = [];
    
    // Add all items from sets with displayInDictionary enabled
    for (var itemSet in setsData.values) {
      if (_showHidden || itemSet.displayInDictionary) {
        for (var item in itemSet.items) {
          // Determine type based on item's itemType
          String displayType = item.itemType == 'Vocab' ? 'Vocabulary' : item.itemType;
          _allItems.add({
            'type': displayType,
            'item': item,
            'isHidden': !itemSet.displayInDictionary,
          });
        }
      }
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      // Reset to first page whenever filters/search change
      _currentPage = 1;
      if (query.isEmpty) {
        _filteredItems = _allItems.where((entry) {
          if (!_activeFilters.contains(entry['type'])) return false;
          
          // Apply tag filter if any tags are selected
          if (_selectedTags.isNotEmpty) {
            final item = entry['item'];
            return item.tags.any((tag) => _selectedTags.contains(tag));
          }
          return true;
        }).toList();
      } else {
        _filteredItems = _allItems.where((entry) {
          if (!_activeFilters.contains(entry['type'])) return false;
          
          final type = entry['type'];
          final item = entry['item'];
          
          // Apply tag filter if any tags are selected
          if (_selectedTags.isNotEmpty) {
            if (!item.tags.any((tag) => _selectedTags.contains(tag))) return false;
          }
          
          if (type == 'Vocabulary') {
            return item.japanese.toLowerCase().contains(query) ||
                   item.reading.toLowerCase().contains(query) ||
                   item.translation.toLowerCase().contains(query);
          } else {
            // Hiragana, Katakana, or Kanji
            return item.japanese.toLowerCase().contains(query) ||
                   item.translation.toLowerCase().contains(query);
          }
        }).toList();
      }
      
      // Reset current index if it's out of bounds
      if (_currentIndex >= _filteredItems.length) {
        _currentIndex = -1;
      }
    });
  }

  Widget _buildFilterButton(String type) {
    final isActive = _activeFilters.contains(type);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onDoubleTap: () {
            setState(() {
              // Double tap: make only this filter active
              _activeFilters = {type};
              _filterItems();
            });
          },
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                if (isActive) {
                  _activeFilters.remove(type);
                } else {
                  _activeFilters.add(type);
                }
                _filterItems();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? const Color(0xFF9A00FE) : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              type == 'Vocabulary' ? 'Vocab' : type,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Set<String> _getAllTags() {
    final allTags = <String>{};
    for (var entry in _allItems) {
      final item = entry['item'];
      allTags.addAll(item.tags);
    }
    return allTags;
  }

  void _showTagFilterDialog() {
    final allTags = _getAllTags().toList()..sort();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Filter by Tags',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.5,
            child: allTags.isEmpty
                ? Text(
                    'No tags found. Add tags to items to filter by them.',
                    style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                  )
                : ListView(
                    children: allTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return CheckboxListTile(
                        title: Text(
                          tag,
                          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        ),
                        value: isSelected,
                        activeColor: const Color(0xFF9A00FE),
                        onChanged: (value) {
                          setDialogState(() {
                            if (value == true) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            if (_selectedTags.isNotEmpty)
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    _selectedTags.clear();
                  });
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterItems();
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Reset setsData to the original defaults and clear saved user sets.
  Future<void> _resetToDefaultSets() async {
    // Clear persisted sets in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('set_') || key.startsWith('practice_set_') || key.startsWith('vocab_set_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // ignore prefs errors
      print('Error clearing saved sets: $e');
    }

    // Repopulate setsData from defaultPresets (deep copy)
    setsData.clear();
    defaultPresets.forEach((key, preset) {
      final items = preset.items.map((it) => Item(
            japanese: it.japanese,
            translation: it.translation,
            strokeOrder: it.strokeOrder,
            kanjiVGCode: it.kanjiVGCode,
            itemType: it.itemType,
            reading: it.reading,
            onYomi: it.onYomi,
            kunYomi: it.kunYomi,
            naNori: it.naNori,
            tags: List<String>.from(it.tags),
            notes: it.notes,
            isStarred: it.isStarred,
          )).toList();

      setsData[key] = ItemSet(
        name: preset.name,
        items: items,
        tags: List<String>.from(preset.tags),
        displayInDictionary: preset.displayInDictionary,
        setType: preset.setType,
        displayInWritingArcade: preset.displayInWritingArcade,
        displayInReadingArcade: preset.displayInReadingArcade,
      );
    });

    // Persist defaults to preferences
    try {
      await SetPreferences.saveAllSets();
    } catch (e) {
      print('Error saving default sets: $e');
    }
  }

  void _showSettingsMenu() {
    bool localDarkMode = widget.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: AlertDialog(
            backgroundColor: localDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: localDarkMode ? Colors.white : Colors.black87,
              ),
              child: const Text("Settings"),
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(color: localDarkMode ? Colors.white : Colors.black87),
                  child: const Text("Dark Mode"),
                ),
                Switch(
                  value: localDarkMode,
                  onChanged: (value) {
                    setState(() {
                      localDarkMode = value;
                    });
                    widget.onThemeChanged(value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Confirm reset
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: localDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      title: Text(
                        'Reset Dictionary',
                        style: TextStyle(color: localDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'This will remove all your custom sets and restore the app to the default sets. This cannot be undone. Continue? \n\n(You may need to restart the app for changes to take full effect.)',
                        style: TextStyle(color: localDarkMode ? Colors.white70 : Colors.black87),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    Navigator.pop(context); // close settings dialog
                    await _resetToDefaultSets();
                    if (mounted) {
                      setState(() {
                        _loadAllItems();
                        _filterItems();
                      });
                    }
                  }
                },
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(color: localDarkMode ? Colors.white70 : Colors.redAccent),
                  child: const Text('Reset Dictionary'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(color: localDarkMode ? Colors.white70 : Colors.black87),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Dictionary',
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        actions: [
                  if (_showHidden)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextButton(
                        onPressed: () async {
                          await precacheImage(const AssetImage('assets/sapphire3S63.png'), context);
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Colors.transparent,
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                                      child: Image.asset('assets/sapphire3S63.png', fit: BoxFit.contain),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.download),
                                      label: const Text('Download'),
                                      onPressed: () async {
                                        try {
                                          final bd = await rootBundle.load('assets/sapphire3S63.png');
                                          final bytes = bd.buffer.asUint8List();
                                          final dir = await getApplicationDocumentsDirectory();
                                          final filePath = p.join(dir.path, 'sapphire3S63.png');
                                          final f = File(filePath);
                                          await f.writeAsBytes(bytes);
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $filePath')));
                                        } catch (e) {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed')));
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.link),
                                      label: const Text('Download link'),
                                      onPressed: () async {
                                        final uri = Uri.parse('https://drive.google.com/file/d/1icXrArw6T4rUEssAMpfbzOndko4uhDnl/view?usp=sharing');
                                        try {
                                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                          }
                                        } catch (_) {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                      child: Text(
                                        'Download link if download fails',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                            ),
                          );
                        },
                        style: TextButton.styleFrom(padding: const EdgeInsets.all(6), minimumSize: const Size(36, 36), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                        child: Text('?', style: TextStyle(fontSize: 18, color: widget.isDarkMode ? Colors.white54 : Colors.black54)),
                      ),
                    ),
          IconButton(
            icon: Icon(Icons.settings, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Show Hidden checkbox
            Row(
              children: [
                Checkbox(
                  value: _showHidden,
                  onChanged: (value) {
                    setState(() {
                      _showHidden = value ?? false;
                      _loadAllItems();
                      _filterItems();
                    });
                  },
                  activeColor: const Color(0xFF9A00FE),
                ),
                Text(
                  'Show hidden items',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // View Sets button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewAllSetsScreen(
                      isDarkMode: widget.isDarkMode,
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                ).then((_) {
                  setState(() {
                    _loadAllItems();
                    _filterItems();
                  });
                });
              },
              icon: const Icon(Icons.folder_open, size: 20),
              label: const Text('View Sets'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            // Search bar
            TextField(
              controller: _searchController,
              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search for a word...',
                hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                prefixIcon: Icon(Icons.search, color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                filled: true,
                fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 15),
            // Filter instruction text
            Text(
              'Double tap/click a filter to isolate!',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
            // Filter buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton('Kanji'),
                _buildFilterButton('Hiragana'),
                _buildFilterButton('Katakana'),
                _buildFilterButton('Vocabulary'),
              ],
            ),
            const SizedBox(height: 10),
            // Filter by tags button
            ElevatedButton.icon(
              onPressed: _showTagFilterDialog,
              icon: Icon(_selectedTags.isEmpty ? Icons.filter_list : Icons.filter_alt, size: 20),
              label: Text(_selectedTags.isEmpty ? 'Filter by Tags' : 'Filter by Tags (${_selectedTags.length})'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _selectedTags.isEmpty ? const Color(0xFF9A00FE) : const Color(0xFF7700CC),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            // Results count with navigation arrows
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_filteredItems.length} items',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _scrollToTop,
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _scrollToBottom,
                        child: Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Results list with pagination
            Builder(
              builder: (context) {
                // Compute pagination values inside a builder so local variables
                // can be declared within the widget tree.
                final int totalItems = _filteredItems.length;
                int totalPages = (totalItems + _itemsPerPage - 1) ~/ _itemsPerPage;
                if (totalPages < 1) totalPages = 1;
                final startIndex = (_currentPage - 1) * _itemsPerPage;
                final currentPageItems = _filteredItems.skip(startIndex).take(_itemsPerPage).toList();

                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: currentPageItems.length,
                          itemBuilder: (context, index) {
                            final entry = currentPageItems[index];
                            final type = entry['type'];
                            final item = entry['item'];
                            final isHidden = entry['isHidden'] ?? false;

                        if (type == 'Vocabulary') {
                          return Card(
                            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  final actualIndex = startIndex + index;
                                  _currentIndex = actualIndex;
                                });

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailScreen(
                                      item: item,
                                      isDarkMode: widget.isDarkMode,
                                      onThemeChanged: widget.onThemeChanged,
                                      allItems: _filteredItems,
                                      currentIndex: _currentIndex,
                                    ),
                                  ),
                                ).then((_) {
                                  _loadAllItems();
                                  _filterItems();
                                });
                              },
                              title: Text(
                                item.japanese,
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item.reading} - ${item.translation}',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isHidden) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Hidden',
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Vocab',
                                      style: TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          final isKana = type == 'Hiragana' || type == 'Katakana';
                          return Card(
                            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  _currentIndex = index;
                                });

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailScreen(
                                      item: item,
                                      isDarkMode: widget.isDarkMode,
                                      onThemeChanged: widget.onThemeChanged,
                                      allItems: _filteredItems,
                                      currentIndex: index,
                                    ),
                                  ),
                                ).then((_) {
                                  _loadAllItems();
                                  _filterItems();
                                });
                              },
                              leading: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF9A00FE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.japanese,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.translation,
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isHidden) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Hidden',
                                        style: TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isKana ? Colors.green : Colors.orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type,
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                          },
                        ),
                      ),

                      // Pagination controls
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 1
                                  ? () {
                                      setState(() {
                                        _currentPage = (_currentPage - 1).clamp(1, totalPages);
                                      });
                                      _scrollToTop();
                                    }
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Page $_currentPage of $totalPages',
                              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < totalPages
                                  ? () {
                                      setState(() {
                                        _currentPage = (_currentPage + 1).clamp(1, totalPages);
                                      });
                                      _scrollToTop();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),

                      // Search buttons at bottom (only show when search is active)
                      if (_searchController.text.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                            border: Border(
                              top: BorderSide(
                                color: widget.isDarkMode ? Colors.white12 : Colors.grey[400]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 8, bottom: 8),
                                child: Text(
                                  'Search in external dictionaries:',
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final query = Uri.encodeComponent(_searchController.text);
                                        final url = Uri.parse('https://jisho.org/search/$query');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF9A00FE),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('Search in Jisho', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final query = Uri.encodeComponent(_searchController.text);
                                        final url = Uri.parse('https://www.kanshudo.com/search?q=$query');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF9A00FE),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('Search in Kanshudo', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final query = Uri.encodeComponent(_searchController.text);
                                        final url = Uri.parse('https://tangorin.com/words?search=$query');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF9A00FE),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: const Text('Search in Tangorin', style: TextStyle(fontSize: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
