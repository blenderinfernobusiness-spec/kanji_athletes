import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'sets_data.dart';
import 'set_preferences.dart';
import 'stroke_order_animator.dart';
import 'writing_practice_canvas.dart';
import 'view_set.dart';

class ItemDetailScreen extends StatefulWidget {
  final Item item;
  final bool isDarkMode;
  final List<dynamic>? allItems; // Can be List<Item> or mixed List<Map> from dictionary
  final int? currentIndex;
  final Function(bool) onThemeChanged;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.isDarkMode,
    this.allItems,
    this.currentIndex,
    required this.onThemeChanged,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> with TickerProviderStateMixin {
    void _showEditReadingsDialog() {
      final onYomiController = TextEditingController(text: _currentItem.onYomi);
      final kunYomiController = TextEditingController(text: _currentItem.kunYomi);
      final naNoriController = TextEditingController(text: _currentItem.naNori);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Edit Kanji Readings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: onYomiController,
                    decoration: const InputDecoration(labelText: "On'yomi (音読み)"),
                  ),
                  TextField(
                    controller: kunYomiController,
                    decoration: const InputDecoration(labelText: "Kun'yomi (訓読み)"),
                  ),
                  TextField(
                    controller: naNoriController,
                    decoration: const InputDecoration(labelText: "Nanori (名乗り)"),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _currentItem.onYomi = onYomiController.text;
                    _currentItem.kunYomi = kunYomiController.text;
                    _currentItem.naNori = naNoriController.text;
                  });
                  // Save to sets_data if needed (if item is part of a set, trigger persistence)
                  await SetPreferences.saveAllSets();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }
  late TabController _tabController;
  bool _isStrokeOrderReady = false;
  late Item _currentItem;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentItem = widget.item;
    _currentIndex = widget.currentIndex ?? 0;
    
    // Only load stroke order for non-Vocab items
    if (_currentItem.itemType != 'Vocab') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStrokeOrderData();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStrokeOrderData() async {
    final kanjiVGCode = _getKanjiVGCode();
    if (kanjiVGCode != null) {
      try {
        // Pre-cache the SVG file
        await DefaultCacheManager().getSingleFile(
          'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/$kanjiVGCode.svg',
        );
        if (mounted) {
          setState(() {
            _isStrokeOrderReady = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isStrokeOrderReady = true;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isStrokeOrderReady = true;
        });
      }
    }
  }

  String? _getKanjiVGCode() {
    if (_currentItem.kanjiVGCode != null) {
      return _currentItem.kanjiVGCode;
    }
    
    // For hiragana and katakana, generate code from Unicode
    if (_isKanaCharacter(_currentItem.japanese)) {
      final char = _currentItem.japanese;
      final code = char.codeUnitAt(0);
      if ((code >= 0x3040 && code <= 0x309F) || // Hiragana
          (code >= 0x30A0 && code <= 0x30FF)) { // Katakana
        return code.toRadixString(16).padLeft(5, '0');
      }
    }
    
    return null;
  }

  bool _isKanaCharacter(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 0x3040 && code <= 0x309F) || // Hiragana
           (code >= 0x30A0 && code <= 0x30FF);   // Katakana
  }

  Future<String> _loadCombinedSVG(List<String> kanjiVGCodes) async {
    final svgContents = <String>[];
    final missingCodes = <String>[];
    for (final code in kanjiVGCodes) {
      try {
        final file = await DefaultCacheManager().getSingleFile(
          'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/$code.svg',
        );
        final content = await file.readAsString();
        svgContents.add(content);
      } catch (e) {
        print('Error loading SVG for $code: $e');
        missingCodes.add(code);
      }
    }
    if (svgContents.isEmpty) {
      // Return a visible SVG with a message for missing stroke order
      return '''<svg xmlns="http://www.w3.org/2000/svg" width="200" height="109">
        <rect width="200" height="109" fill="#f8d7da"/>
        <text x="100" y="54" font-size="16" text-anchor="middle" fill="#721c24">No stroke order found</text>
      </svg>''';
    }
    
    // Combine SVGs horizontally
    final spacing = 10.0;
    final svgWidth = 109.0;
    final totalWidth = (svgWidth * svgContents.length) + (spacing * (svgContents.length - 1));
    
    final combinedSvg = StringBuffer();
    combinedSvg.write('<svg xmlns="http://www.w3.org/2000/svg" width="$totalWidth" height="109" viewBox="0 0 $totalWidth 109">');
    
    for (int i = 0; i < svgContents.length; i++) {
      final xOffset = i * (svgWidth + spacing);
      // Extract the path data from individual SVG
      final pathMatch = RegExp(r'<path[^>]*d="([^"]*)"[^>]*/>').allMatches(svgContents[i]);
      for (final match in pathMatch) {
        final pathData = match.group(1);
        combinedSvg.write('<g transform="translate($xOffset, 0)">');
        combinedSvg.write('<path d="$pathData" stroke="#000" stroke-width="3" fill="none"/>');
        combinedSvg.write('</g>');
      }
    }
    
    combinedSvg.write('</svg>');
    return combinedSvg.toString();
  }

  // Safely load SVG file contents as string for a single kanjiVG code.
  // Returns null if the file can't be retrieved or parsed.
  Future<String?> _loadSvgStringForCode(String kanjiVGCode) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(
        'https://raw.githubusercontent.com/KanjiVG/kanjivg/master/kanji/$kanjiVGCode.svg',
      );
      final content = await file.readAsString();
      return content;
    } catch (e) {
      // Ignore errors and return null so callers can show a friendly message
      return null;
    }
  }

  String _getPreviewText(dynamic item) {
    if (item is Map) {
      final actualItem = item['item'];
      return actualItem.japanese;
    } else if (item is Item) {
      return item.japanese;
    }
    return '';
  }

  void _navigateToPreviousItem() {
    if (widget.allItems == null || widget.allItems!.isEmpty) return;
    
    int newIndex;
    if (_currentIndex <= 0) {
      newIndex = widget.allItems!.length - 1;
    } else {
      newIndex = _currentIndex - 1;
    }
    
    _navigateToItem(newIndex);
  }

  void _navigateToNextItem() {
    if (widget.allItems == null || widget.allItems!.isEmpty) return;
    
    int newIndex;
    if (_currentIndex >= widget.allItems!.length - 1) {
      newIndex = 0;
    } else {
      newIndex = _currentIndex + 1;
    }
    
    _navigateToItem(newIndex);
  }

  void _navigateToItem(int newIndex) {
    final nextItem = widget.allItems![newIndex];
    Item actualItem;
    
    // Check if it's a dictionary entry (Map) or direct Item
    if (nextItem is Map) {
      actualItem = nextItem['item'];
    } else {
      actualItem = nextItem;
    }
    
    // Navigate to the same unified screen with the new item
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ItemDetailScreen(
          item: actualItem,
          isDarkMode: widget.isDarkMode,
          allItems: widget.allItems,
          currentIndex: newIndex,
          onThemeChanged: widget.onThemeChanged,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
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
                    widget.onThemeChanged(value);
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) {
                        setState(() {
                          localDarkMode = value;
                        });
                      }
                    });
                  },
                ),
              ],
            ),
            actions: [
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

  Future<void> _showEditDialog() async {
    print('DEBUG: _showEditDialog called');
    final japaneseController = TextEditingController(text: _currentItem.japanese);
    final translationController = TextEditingController(text: _currentItem.translation);
    final readingController = TextEditingController(text: _currentItem.reading);
    final tagsController = TextEditingController(
      text: _currentItem.tags.join(', ')
    );
    final notesController = TextEditingController(text: _currentItem.notes);
    String selectedType = _currentItem.itemType;
    String? errorMessage;
    
    // Find current set
    String? currentSetKey;
    for (var entry in setsData.entries) {
      if (entry.value.items.contains(_currentItem)) {
        currentSetKey = entry.key;
        break;
      }
    }
    String selectedSet = currentSetKey ?? (setsData.isNotEmpty ? setsData.keys.first : '');

    try {
      print('DEBUG: setsData length=${setsData.length} currentSetKey=$currentSetKey selectedSet=$selectedSet');
      print('DEBUG: about to call showDialog');
      await showDialog<void>(
        context: context,
        builder: (context) {
          print('DEBUG: showDialog.builder called');
          return StatefulBuilder(
            builder: (context, setDialogState) {
              print('DEBUG: statefulBuilder called');
              return AlertDialog(
              scrollable: true,
              backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Edit Item',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: math.min(MediaQuery.of(context).size.width * 0.9, 720),
                height: math.max(
                    200.0,
                    MediaQuery.of(context).size.height * 0.75 - MediaQuery.of(context).viewInsets.bottom),
                child: ListView(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 8),
                  shrinkWrap: true,
                  children: [
                    // Item Type dropdown
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Item Type',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF9A00FE)),
                        ),
                      ),
                      items: ['Kanji', 'Hiragana', 'Katakana', 'Vocab'].map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) setDialogState(() => selectedType = newValue);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Set selector dropdown (handle case where no sets exist)
                    if (setsData.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: setsData.containsKey(selectedSet) ? selectedSet : setsData.keys.first,
                        dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Set',
                          labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF9A00FE)),
                          ),
                        ),
                        items: setsData.keys.map((String setName) {
                          return DropdownMenuItem<String>(
                            value: setName,
                            child: Text(setName),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) setDialogState(() => selectedSet = newValue);
                        },
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No sets available',
                          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const SizedBox(height: 16),
                    TextField(
                      controller: japaneseController,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          String detectedType;
                          if (value.length > 1) {
                            detectedType = 'Vocab';
                          } else {
                            final firstChar = value.characters.first;
                            final code = firstChar.codeUnitAt(0);
                            if (code >= 0x3040 && code <= 0x309F) {
                              detectedType = 'Hiragana';
                            } else if (code >= 0x30A0 && code <= 0x30FF) {
                              detectedType = 'Katakana';
                            } else if (code >= 0x4E00 && code <= 0x9FFF) {
                              detectedType = 'Kanji';
                            } else {
                              detectedType = 'Kanji';
                            }
                          }

                          if (detectedType != selectedType) {
                            setDialogState(() {
                              selectedType = detectedType;
                              errorMessage = null;
                            });
                          }
                        }
                      },
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: selectedType == 'Vocab' ? 'Word' : (selectedType == 'Hiragana' ? 'Hiragana' : (selectedType == 'Katakana' ? 'Katakana' : 'Kanji')),
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF9A00FE)),
                        ),
                      ),
                    ),
                    // Show reading field if selectedType is 'Vocab'
                    if (selectedType == 'Vocab') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: readingController,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: 'Reading',
                          labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF9A00FE)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: translationController,
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Translation',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF9A00FE)),
                        ),
                      ),
                    ),
                    if (selectedType == 'Kanji') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(text: _currentItem.onYomi),
                        onChanged: (value) => _currentItem.onYomi = value,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "On'yomi (音読み)",
                          labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF9A00FE)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: _currentItem.kunYomi),
                        onChanged: (value) => _currentItem.kunYomi = value,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "Kun'yomi (訓読み)",
                          labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF9A00FE)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: _currentItem.naNori),
                        onChanged: (value) => _currentItem.naNori = value,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          labelText: "Nanori (名乗り)",
                          labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF9A00FE)),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Tags section
                    Text(
                      'Tags',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          // User tags
                          ...tagsController.text
                              .split(',')
                              .map((tag) => tag.trim())
                              .where((tag) => tag.isNotEmpty)
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9A00FE).withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: tagsController,
                      onChanged: (value) {
                        setDialogState(() {}); // Trigger rebuild to update tag badges
                      },
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Add tags separated by commas (e.g., beginner, JLPT N5)',
                        hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                        filled: true,
                        fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: widget.isDarkMode ? Colors.white30 : Colors.black26),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF9A00FE)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Delete Item Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              title: Text(
                                'Delete Item?',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                'Are you sure you want to delete "${_currentItem.japanese}"? This action cannot be undone.',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && mounted) {
                            // Find which set contains this item
                            String? setKey;
                            for (var entry in setsData.entries) {
                              if (entry.value.items.contains(_currentItem)) {
                                setKey = entry.key;
                                break;
                              }
                            }

                            if (setKey != null) {
                              setsData[setKey]!.items.remove(_currentItem);
                              await SetPreferences.saveSet(setKey, setsData[setKey]!);

                              if (mounted) {
                                Navigator.pop(context); // Close edit dialog
                                Navigator.pop(context); // Go back to set view
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Item deleted successfully'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.delete, size: 20),
                        label: const Text('Delete Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, left: 16, right: 16),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
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
                  onPressed: () async {
                    // Validate: can't save multi-character text as Kanji/Hiragana/Katakana
                    if (japaneseController.text.length > 1 && selectedType != 'Vocab') {
                      setDialogState(() {
                        errorMessage = 'Multiple characters must be saved as Vocab type';
                      });
                      return;
                    }

                    // Check if Japanese field changed (need to regenerate kanjiVGCode)
                    final japaneseChanged = _currentItem.japanese != japaneseController.text;

                    // Update the item
                    _currentItem.japanese = japaneseController.text;
                    _currentItem.translation = translationController.text;
                    _currentItem.itemType = selectedType;
                    _currentItem.notes = notesController.text;

                    // Parse user tags
                    final userTags = tagsController.text
                        .split(',')
                        .map((tag) => tag.trim())
                        .where((tag) => tag.isNotEmpty)
                        .toList();
                    // Remove duplicates
                    _currentItem.tags = userTags.toSet().toList();

                    // Update reading field based on type
                    if (selectedType == 'Vocab') {
                      _currentItem.reading = readingController.text;
                    } else {
                      _currentItem.reading = '';
                    }

                    // If Japanese changed, need to create new item with updated kanjiVGCode
                    if (japaneseChanged && japaneseController.text.isNotEmpty) {
                      // Generate new kanjiVGCode
                      final char = japaneseController.text.characters.first;
                      final codePoint = char.codeUnitAt(0);
                      final newKanjiVGCode = codePoint.toRadixString(16).padLeft(5, '0');

                      // Create new item with updated kanjiVGCode
                      final newItem = Item(
                        japanese: _currentItem.japanese,
                        translation: _currentItem.translation,
                        strokeOrder: _currentItem.strokeOrder,
                        kanjiVGCode: newKanjiVGCode,
                        itemType: _currentItem.itemType,
                        reading: _currentItem.reading,
                        tags: _currentItem.tags,
                        notes: _currentItem.notes,
                      );

                      // Find the set and replace the old item
                      for (var entry in setsData.entries) {
                        final items = entry.value.items;
                        final index = items.indexOf(_currentItem);
                        if (index != -1) {
                          items[index] = newItem;
                          _currentItem = newItem;
                          break;
                        }
                      }
                    }

                    // Handle set change
                    String? oldSetKey;
                    for (var entry in setsData.entries) {
                      if (entry.value.items.contains(_currentItem)) {
                        oldSetKey = entry.key;
                        break;
                      }
                    }

                    if (oldSetKey != selectedSet) {
                      // Remove from old set and add to new set
                      if (oldSetKey != null) {
                        setsData[oldSetKey]!.items.remove(_currentItem);
                        await SetPreferences.saveSet(oldSetKey, setsData[oldSetKey]!);
                      }
                      if (setsData.containsKey(selectedSet)) {
                        setsData[selectedSet]!.items.add(_currentItem);
                        await SetPreferences.saveSet(selectedSet, setsData[selectedSet]!);
                      }
                    } else {
                      // Save to current set if it exists
                      if (setsData.containsKey(selectedSet)) {
                        await SetPreferences.saveSet(selectedSet, setsData[selectedSet]!);
                      }
                    }

                    // Close dialog and rebuild
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
      );
      print('DEBUG: showDialog completed');
    } catch (e, st) {
      print('Exception opening edit dialog: $e\n$st');
      // Show a lightweight error dialog so app doesn't crash
      try {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: SingleChildScrollView(child: Text('Failed to open edit dialog:\n$e')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
            ],
          ),
        );
      } catch (_) {}
    } finally {
      japaneseController.dispose();
      translationController.dispose();
      readingController.dispose();
      tagsController.dispose();
      notesController.dispose();
    }
  }

  void _showNotesEditDialog() {
    final notesController = TextEditingController(text: _currentItem.notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Notes',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: notesController,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
          maxLines: 8,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Add personal notes about this item...',
            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
            filled: true,
            fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _currentItem.notes = notesController.text;
              });
              
              // Find the set containing this item and save it
              for (var entry in setsData.entries) {
                if (entry.value.items.contains(_currentItem)) {
                  await SetPreferences.saveSet(entry.key, entry.value);
                  break;
                }
              }
              
              if (mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A00FE),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      notesController.dispose();
    });
  }

  void _showPracticeWritingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Calculate scale based on screen size
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final scale = (screenWidth / 600).clamp(0.8, 1.5);
        
        // Get kanjiVG codes based on item type
        List<String>? kanjiVGCodes;
        if (_currentItem.itemType == 'Vocab') {
          // For vocab, collect all kanji VG codes
          final kanjiChars = _getKanjiCharacters(_currentItem.japanese);
          kanjiVGCodes = kanjiChars
              .map((kanji) => _getKanjiVGCodeFor(kanji))
              .where((code) => code != null)
              .cast<String>()
              .toList();
        } else {
          // For Kanji/Hiragana/Katakana, use single character code
          final code = _getKanjiVGCode();
          if (code != null) {
            kanjiVGCodes = [code];
          }
        }
        
        return Dialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.9,
              maxWidth: screenWidth * 0.9,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Practice Writing',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 24 * scale,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                            size: 24 * scale,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    WritingPracticeCanvas(
                      kanjiVGCodes: kanjiVGCodes,
                      isDarkMode: widget.isDarkMode,
                      kanji: _currentItem.japanese,
                      translation: _currentItem.translation,
                      scale: scale,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isVocab = _currentItem.itemType == 'Vocab';
    final isKana = _isKanaCharacter(_currentItem.japanese);
    
    String titleText;
    if (isVocab) {
      titleText = 'Vocabulary Details';
    } else if (isKana) {
      titleText = 'Kana Details';
    } else {
      titleText = 'Kanji Details';
    }
    
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          titleText,
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit button pressed'), duration: Duration(seconds: 1)),
              );
              print('DEBUG: edit button pressed');
              _showEditDialog();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Large item display with navigation arrows
            if (widget.allItems != null && widget.currentIndex != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Previous button
                  IconButton(
                    icon: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_ios, color: widget.isDarkMode ? Colors.white : Colors.black),
                        if (_currentIndex > 0)
                          Text(
                            _getPreviewText(widget.allItems![_currentIndex - 1]),
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          )
                        else
                          Text(
                            _getPreviewText(widget.allItems![widget.allItems!.length - 1]),
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                    onPressed: _navigateToPreviousItem,
                  ),
                  const SizedBox(width: 10),
                  // Large item display
                  Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9A00FE),
                      borderRadius: BorderRadius.circular(isVocab ? 12 : 16),
                    ),
                    child: Text(
                      _currentItem.japanese,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isVocab
                            ? (_currentItem.japanese.length > 4 ? 36 : (_currentItem.japanese.length > 3 ? 42 : 48))
                            : (_currentItem.japanese.length > 2 ? 80 : 120),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Next button
                  IconButton(
                    icon: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_forward_ios, color: widget.isDarkMode ? Colors.white : Colors.black),
                        if (_currentIndex < widget.allItems!.length - 1)
                          Text(
                            _getPreviewText(widget.allItems![_currentIndex + 1]),
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          )
                        else
                          Text(
                            _getPreviewText(widget.allItems![0]),
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontSize: 16,
                            ),
                          ),
                      ],
                    ),
                    onPressed: _navigateToNextItem,
                  ),
                ],
              )
            else
              // Large item display without navigation
              Container(
                width: 200,
                height: 200,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF9A00FE),
                  borderRadius: BorderRadius.circular(isVocab ? 12 : 16),
                ),
                child: Text(
                  _currentItem.japanese,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isVocab
                        ? (_currentItem.japanese.length > 4 ? 36 : (_currentItem.japanese.length > 3 ? 42 : 48))
                        : (_currentItem.japanese.length > 2 ? 80 : 120),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(height: 30),
            // Translation
            Text(
              'Translation',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: isVocab ? 14 : 16,
                fontWeight: isVocab ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _currentItem.translation,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontSize: isVocab ? 24 : 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            // Show reading field if itemType is 'Vocab'
            if (isVocab) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Reading',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentItem.reading,
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            // Show onyomi, kunyomi, nanori for Kanji items only
            if (!isVocab && _currentItem.itemType == 'Kanji') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((_currentItem.onYomi ?? '').isNotEmpty) ...[
                                Text(
                                  "On'yomi (音読み)",
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currentItem.onYomi,
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if ((_currentItem.kunYomi ?? '').isNotEmpty) ...[
                                Text(
                                  "Kun'yomi (訓読み)",
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currentItem.kunYomi,
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                const SizedBox(height: 12),
                              ],
                              if ((_currentItem.naNori ?? '').isNotEmpty) ...[
                                Text(
                                  "Nanori (名乗り)",
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _currentItem.naNori,
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: widget.isDarkMode ? Colors.white : Colors.black),
                              tooltip: 'Edit Readings',
                              onPressed: () => _showEditReadingsDialog(),
                            ),
                            IconButton(
                              icon: Icon(Icons.info_outline, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                              tooltip: 'Reading Types Info',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Kanji Reading Types'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text("Kun'yomi (訓読み): The 'Japanese reading', usually used for Kanji inside of words which contain just a single kanji, but not always.\n"),
                                        SizedBox(height: 10),
                                        Text("On'yomi (音読み): The 'Chinese reading', usually used for Kanji inside of words made up of multiple kanji, but not always.\n"),
                                        SizedBox(height: 10),
                                        Text("Nanori (名乗り): The 'Name reading', a special kanji reading used in Japanese personal names or place names."),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
            // ...existing code...

            const SizedBox(height: 40),
            // Stroke order section - show for all item types
            Text(
              'Stroke Order (Kakijun)',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                fontSize: 16,
              ),
            ),
              const SizedBox(height: 10),
              Builder(
                key: ValueKey(_currentItem.japanese), // Force rebuild when character changes
                builder: (context) {
                  // For vocab items, show combined stroke order for entire word
                  if (isVocab) {
                    final kanjiChars = _getKanjiCharacters(_currentItem.japanese);
                    final kanjiVGCodes = kanjiChars
                        .map((kanji) => _getKanjiVGCodeFor(kanji))
                        .where((code) => code != null)
                        .cast<String>()
                        .toList();
                    
                    if (kanjiVGCodes.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'No kanji characters in this word',
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    
                    // Show single renderer with entire word stroke order
                    return Column(
                      children: [
                        // Tab bar
                        Container(
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: const Color(0xFF9A00FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: widget.isDarkMode ? Colors.white70 : Colors.black87,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Animated'),
                              Tab(text: 'Numbered'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Tab content - single renderer for entire word
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Animated tab - use StrokeOrderAnimator with all kanji codes
                              Center(
                                child: StrokeOrderAnimator(
                                  kanjiVGCodes: kanjiVGCodes,
                                  isDarkMode: widget.isDarkMode,
                                ),
                              ),
                              // Numbered tab - load combined SVG
                              Center(
                                child: FutureBuilder(
                                  future: _loadCombinedSVG(kanjiVGCodes),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      return Container(
                                        width: 300,
                                        height: 300,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Stroke order not available',
                                          style: TextStyle(
                                            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      );
                                    }

                                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                      return Container(
                                        width: 300,
                                        height: 300,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: SvgPicture.string(
                                          snapshot.data!,
                                          colorFilter: widget.isDarkMode
                                              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                                              : null,
                                        ),
                                      );
                                    }

                                    return Container(
                                      width: 300,
                                      height: 300,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(
                                        color: Color(0xFF9A00FE),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  
                  // For non-vocab items, use the existing single character logic
                  final kanjiVGCode = _getKanjiVGCode();
                  
                  // Show loading placeholder until ready (but only if we expect stroke order)
                  if (!_isStrokeOrderReady && kanjiVGCode != null) {
                    return Container(
                      height: 450,
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: Color(0xFF9A00FE),
                      ),
                    );
                  }
                  
                  if (kanjiVGCode != null) {
                    return Column(
                      children: [
                        // Tab bar
                        Container(
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorSize: TabBarIndicatorSize.tab,
                            indicator: BoxDecoration(
                              color: const Color(0xFF9A00FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: widget.isDarkMode ? Colors.white70 : Colors.black87,
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Animated'),
                              Tab(text: 'Numbered'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Tab content
                        SizedBox(
                          height: 400,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Animated tab
                              Center(
                                child: StrokeOrderAnimator(
                                  kanjiVGCode: kanjiVGCode,
                                  isDarkMode: widget.isDarkMode,
                                ),
                              ),
                              // Numbered tab
                              Center(
                                child: FutureBuilder<String?>(
                                  future: _loadSvgStringForCode(kanjiVGCode),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError || (snapshot.connectionState == ConnectionState.done && snapshot.data == null)) {
                                      return Container(
                                        width: 300,
                                        height: 300,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Stroke order not available',
                                          style: TextStyle(
                                            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                          ),
                                        ),
                                      );
                                    }

                                    if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                      return Container(
                                        width: 300,
                                        height: 300,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: SvgPicture.string(
                                          snapshot.data!,
                                          colorFilter: widget.isDarkMode
                                              ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                                              : null,
                                        ),
                                      );
                                    }

                                    return Container(
                                      width: 300,
                                      height: 300,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(
                                        color: Color(0xFF9A00FE),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Stroke order not available for this character',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                },
              ),
              if (_getKanjiVGCode() != null)
                const SizedBox(height: 20),
              if (_currentItem.strokeOrder.isNotEmpty && !isVocab)
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 16,
                    ),
                    children: [
                      const TextSpan(text: 'Total number of strokes: '),
                      TextSpan(
                        text: _currentItem.strokeOrder,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 30),
            // Kanji/Kana section for Vocab items
            if (isVocab && _hasKanji(_currentItem.japanese)) ...[
              const SizedBox(height: 30),
              Text(
                'Kanji/Kana',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _getKanjiCharacters(_currentItem.japanese)
                    .map((kanjiChar) => _buildKanjiButton(kanjiChar))
                    .toList(),
              ),
              const SizedBox(height: 20),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    fontSize: 16,
                  ),
                  children: [
                    const TextSpan(text: 'Kanji/Kana characters: '),
                    TextSpan(
                      text: _getKanjiCharacters(_currentItem.japanese)
                          .where((kanji) => _getKanjiVGCodeFor(kanji) != null)
                          .length
                          .toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
            // Practice Writing button
            ElevatedButton.icon(
              onPressed: () {
                _showPracticeWritingDialog(context);
              },
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Practice Writing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 15),
            // Go to Set button
            ElevatedButton.icon(
              onPressed: () {
                // Find which set contains this item
                ItemSet? foundSet;
                for (var entry in setsData.entries) {
                  if (entry.value.items.contains(_currentItem)) {
                    foundSet = entry.value;
                    break;
                  }
                }
                
                if (foundSet != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewSetScreen(
                        itemSet: foundSet!,
                        isDarkMode: widget.isDarkMode,
                        onThemeChanged: widget.onThemeChanged,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.folder_open, size: 20),
              label: const Text('Go to Set'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            // Notes section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notes',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    _showNotesEditDialog();
                  },
                  color: const Color(0xFF9A00FE),
                  tooltip: 'Edit Notes',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentItem.notes.isEmpty ? 'No notes yet. Tap the edit icon to add notes.' : _currentItem.notes,
                style: TextStyle(
                  color: _currentItem.notes.isEmpty 
                      ? (widget.isDarkMode ? Colors.white38 : Colors.black38)
                      : (widget.isDarkMode ? Colors.white : Colors.black),
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // More info section
            Text(
              'More Info',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = isVocab
                            ? Uri.parse('https://www.kanshudo.com/searchw?q=${_currentItem.japanese}')
                            : Uri.parse('https://www.kanshudo.com/kanji/${_currentItem.japanese}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Kanshudo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 15),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final url = isVocab
                            ? Uri.parse('https://jisho.org/search/${_currentItem.japanese}')
                            : Uri.parse('https://jisho.org/search/${_currentItem.japanese}%23kanji');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Jisho.org'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: () async {
                    final url = isVocab
                        ? Uri.parse('https://tangorin.com/words?search=${_currentItem.japanese}')
                        : Uri.parse('https://tangorin.com/kanji/${_currentItem.japanese}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Tangorin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Kakijun (Stroke Order) sourced from KanjiVG',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              '© Ulrich Apel • CC BY-SA 3.0',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Check if a string contains kanji, hiragana, or katakana characters
  bool _hasKanji(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // Check if character is kanji, hiragana, or katakana
      if ((code >= 0x4E00 && code <= 0x9FFF) || // CJK Unified Ideographs
          (code >= 0x3400 && code <= 0x4DBF) || // CJK Extension A
          (code >= 0x3040 && code <= 0x309F) || // Hiragana
          (code >= 0x30A0 && code <= 0x30FF)) { // Katakana
        return true;
      }
    }
    return false;
  }

  // Extract kanji, hiragana, and katakana characters from a string
  List<String> _getKanjiCharacters(String text) {
    List<String> charList = [];
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final code = char.codeUnitAt(0);
      // Check if character is kanji, hiragana, or katakana
      if ((code >= 0x4E00 && code <= 0x9FFF) || // CJK Unified Ideographs
          (code >= 0x3400 && code <= 0x4DBF) || // CJK Extension A
          (code >= 0x3040 && code <= 0x309F) || // Hiragana
          (code >= 0x30A0 && code <= 0x30FF)) { // Katakana
        if (!charList.contains(char)) {
          charList.add(char);
        }
      }
    }
    return charList;
  }

  // Get kanjiVG code for a character (kanji, hiragana, or katakana)
  String? _getKanjiVGCodeFor(String char) {
    // First check practice sets for kanji
    for (var practiceSet in setsData.values) {
      for (var item in practiceSet.items) {
        if (item.japanese == char && item.kanjiVGCode != null) {
          return item.kanjiVGCode;
        }
      }
    }
    
    // If not found in practice sets, generate code for hiragana/katakana
    final code = char.codeUnitAt(0);
    if ((code >= 0x3040 && code <= 0x309F) || // Hiragana
        (code >= 0x30A0 && code <= 0x30FF)) { // Katakana
      return code.toRadixString(16).padLeft(5, '0');
    }
    
    return null;
  }

  // Build a clickable kanji button
  Widget _buildKanjiButton(String kanji) {
    // Find the Item in practice sets
    Item? kanjiItem;
    for (var practiceSet in setsData.values) {
      for (var item in practiceSet.items) {
        if (item.japanese == kanji) {
          kanjiItem = item;
          break;
        }
      }
      if (kanjiItem != null) break;
    }

    return GestureDetector(
      onTap: kanjiItem != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(
                    item: kanjiItem!,
                    isDarkMode: widget.isDarkMode,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: kanjiItem != null
              ? const Color(0xFF9A00FE)
              : (widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[300]),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          kanji,
          style: TextStyle(
            color: kanjiItem != null
                ? Colors.white
                : (widget.isDarkMode ? Colors.white38 : Colors.black38),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
