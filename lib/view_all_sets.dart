import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'sets_data.dart';
import 'view_set.dart';
import 'set_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ViewAllSetsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ViewAllSetsScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ViewAllSetsScreen> createState() => _ViewAllSetsScreenState();
}

class _ViewAllSetsScreenState extends State<ViewAllSetsScreen> {
  bool _showHiddenSets = false;
  bool _isSelectionMode = false;
  final Set<String> _selectedSetKeys = {};

  // Reset setsData to the original defaults and clear saved user sets.
  Future<void> _resetToDefaultSets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('set_') || key.startsWith('practice_set_') || key.startsWith('vocab_set_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      print('Error clearing saved sets: $e');
    }

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
                        'This will remove all your custom sets and restore the app to the default sets. This cannot be undone. Continue?\n\n(You may need to restart the app for changes to take full effect.)',
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
                      setState(() {});
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

  void _showImportOptionsDialog(BuildContext parentContext, List<Item> tempItems, StateSetter setDialogState) {
    String selectedPreset = 'Hiragana';
    String textFileImportType = 'Kanji (or kana)';
    
    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setImportDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Import Items',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Text(
                'Choose from Preset',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedPreset,
                dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  'Hiragana',
                  'Katakana', 
                  'Essential Radicals',
                  'JLPT N5 Kanji',
                  'JLPT N4 Kanji',
                  'JLPT N3 Kanji',
                  'JLPT N2 Kanji'
                ].map((String preset) {
                  return DropdownMenuItem<String>(
                    value: preset,
                    child: Text(preset),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setImportDialogState(() {
                      selectedPreset = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Import items from the default preset
                  if (completeDefaultPresets.containsKey(selectedPreset)) {
                    final presetItems = completeDefaultPresets[selectedPreset]!.items;
                    
                    // Add all items from preset to tempItems
                    for (var item in presetItems) {
                      tempItems.add(Item(
                        japanese: item.japanese,
                        translation: item.translation,
                        strokeOrder: item.strokeOrder,
                        itemType: item.itemType,
                        kanjiVGCode: item.kanjiVGCode,
                        notes: item.notes,
                        reading: item.reading,
                        tags: item.tags,
                      ));
                    }
                    
                    // Close this dialog
                    Navigator.pop(dialogContext);
                    
                    // Update parent dialog
                    Future.microtask(() {
                      setDialogState(() {});
                    });
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Imported ${presetItems.length} items from $selectedPreset'),
                        backgroundColor: const Color(0xFF9A00FE),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Import Preset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    // Pick a text file
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['txt'],
                    );

                    if (result != null && result.files.single.path != null) {
                      final file = File(result.files.single.path!);
                      final content = await file.readAsString();
                      
                      // Split content by lines and remove empty lines
                      final lines = content.split('\n')
                          .map((line) => line.trim())
                          .where((line) => line.isNotEmpty)
                          .toList();
                      
                      int importedCount = 0;
                      
                      if (textFileImportType == 'Kanji (or kana)') {
                        // Kanji format: Japanese\nEnglish (2 lines per item)
                        for (int i = 0; i < lines.length - 1; i += 2) {
                          final japanese = lines[i];
                          final english = lines[i + 1];
                          
                          // Auto-detect item type
                          String itemType = 'Kanji';
                          if (japanese.isNotEmpty) {
                            final firstChar = japanese.runes.first;
                            if (firstChar >= 0x3040 && firstChar <= 0x309F) {
                              itemType = 'Hiragana';
                            } else if (firstChar >= 0x30A0 && firstChar <= 0x30FF) {
                              itemType = 'Katakana';
                            }
                          }
                          
                          // Generate KanjiVG code if it's a single kanji character
                          String kanjiVGCode = '';
                          if (itemType == 'Kanji' && japanese.length == 1) {
                            kanjiVGCode = japanese.codeUnitAt(0).toRadixString(16).padLeft(5, '0');
                          }
                          
                          tempItems.add(Item(
                            japanese: japanese,
                            translation: english,
                            strokeOrder: '',
                            itemType: itemType,
                            kanjiVGCode: kanjiVGCode,
                            notes: '',
                            reading: '',
                            onYomi: '',
                            kunYomi: '',
                            naNori: '',
                            tags: [],
                          ));
                          importedCount++;
                        }
                      } else {
                        // Vocab format: Japanese\nReading\nEnglish (3 lines per item)
                        for (int i = 0; i < lines.length - 2; i += 3) {
                          final japanese = lines[i];
                          final reading = lines[i + 1];
                          final english = lines[i + 2];
                          
                          tempItems.add(Item(
                            japanese: japanese,
                            translation: english,
                            strokeOrder: '',
                            itemType: 'Vocab',
                            kanjiVGCode: '',
                            notes: '',
                            reading: reading,
                            onYomi: '',
                            kunYomi: '',
                            naNori: '',
                            tags: [],
                          ));
                          importedCount++;
                        }
                      }
                      
                      // Close this dialog
                      Navigator.pop(dialogContext);
                      
                      // Update parent dialog
                      Future.microtask(() {
                        setDialogState(() {});
                      });
                      
                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Imported $importedCount items from text file'),
                          backgroundColor: const Color(0xFF9A00FE),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error importing file: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.file_upload),
                label: const Text('Import from Text File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[300],
                  foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Kanji (or kana)',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      value: 'Kanji (or kana)',
                      groupValue: textFileImportType,
                      activeColor: const Color(0xFF9A00FE),
                      onChanged: (String? value) {
                        if (value != null) {
                          setImportDialogState(() {
                            textFileImportType = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Vocab',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                          fontSize: 14,
                        ),
                      ),
                      value: 'Vocab',
                      groupValue: textFileImportType,
                      activeColor: const Color(0xFF9A00FE),
                      onChanged: (String? value) {
                        if (value != null) {
                          setImportDialogState(() {
                            textFileImportType = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  title: Text(
                    'How to use',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  iconColor: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  collapsedIconColor: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  children: [
                    // For Kanji Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'For Kanji',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Text File Format:',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            child: Text(
                              'Japanese\nEnglish',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.all(8),
                              title: Text(
                                'Example',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              iconColor: widget.isDarkMode ? Colors.white : Colors.black,
                              collapsedIconColor: widget.isDarkMode ? Colors.white : Colors.black,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 300),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                                      ),
                                    ),
                                    child: Text(
                                      '水\nWater\n火\nFire\n人\nPerson',
                                      style: TextStyle(
                                        color: widget.isDarkMode ? Colors.white : Colors.black,
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Each item should follow this pattern:\n• First line: Japanese text\n• Second line: English translation\n• Blank line between items (optional)',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '⚠️ Don\'t forget to check the Kanji option for text file import',
                            style: TextStyle(
                              color: const Color(0xFF9A00FE),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // For Vocab Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'For Vocab',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Text File Format:',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                              ),
                            ),
                            child: Text(
                              'Japanese\nReading\nEnglish',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              childrenPadding: const EdgeInsets.all(8),
                              title: Text(
                                'Example',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              iconColor: widget.isDarkMode ? Colors.white : Colors.black,
                              collapsedIconColor: widget.isDarkMode ? Colors.white : Colors.black,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 300),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                                      ),
                                    ),
                                    child: Text(
                                      '学校\nがっこう\nSchool\n水\nみず\nWater\n確認\nかくにん\nConfirmation',
                                      style: TextStyle(
                                        color: widget.isDarkMode ? Colors.white : Colors.black,
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Each item should follow this pattern:\n• First line: Japanese text\n• Second line: Reading (hiragana)\n• Third line: English translation\n• Blank line between items (optional)',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '⚠️ Don\'t forget to check the Vocab option for text file import',
                            style: TextStyle(
                              color: const Color(0xFF9A00FE),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: null,
                  child: Text(
                    'more import options',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                      decoration: TextDecoration.underline,
                      decorationColor: widget.isDarkMode ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ),
            ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Close',
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemInNewSetDialog(BuildContext parentContext, List<Item> tempItems, int itemIndex, StateSetter setDialogState) {
    final item = tempItems[itemIndex];
    final japaneseController = TextEditingController(text: item.japanese);
    final englishController = TextEditingController(text: item.translation);
    final readingController = TextEditingController(text: item.reading);
    final onYomiController = TextEditingController(text: (item.onYomi == null) ? '' : item.onYomi);
    final kunYomiController = TextEditingController(text: (item.kunYomi == null) ? '' : item.kunYomi);
    final naNoriController = TextEditingController(text: (item.naNori == null) ? '' : item.naNori);
    final notesController = TextEditingController(text: item.notes);
    final tagsController = TextEditingController(text: item.tags.join(', '));
    String selectedType = item.itemType;
    String errorMessage = '';

    // Auto-detect item type from Japanese input
    String detectItemType(String text) {
      if (text.isEmpty) return selectedType;
      
      final firstChar = text.runes.first;
      
      // Hiragana range: 0x3040 - 0x309F
      if (firstChar >= 0x3040 && firstChar <= 0x309F) {
        return 'Hiragana';
      }
      // Katakana range: 0x30A0 - 0x30FF
      else if (firstChar >= 0x30A0 && firstChar <= 0x30FF) {
        return 'Katakana';
      }
      // Kanji range: 0x4E00 - 0x9FFF
      else if (firstChar >= 0x4E00 && firstChar <= 0x9FFF) {
        if (text.length == 1) {
          return 'Kanji';
        } else {
          return 'Vocab';
        }
      }
      return selectedType;
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setItemDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Item',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Japanese',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: japaneseController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (text) {
                    setItemDialogState(() {
                      selectedType = detectItemType(text);
                      errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'English',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: englishController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (selectedType == 'Vocab') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Reading (optional)',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: readingController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'e.g., がっこう',
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                if (selectedType == 'Kanji') ...[
                  const SizedBox(height: 16),
                  Text(
                    "On'yomi (音読み)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: onYomiController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., ショウ",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kun'yomi (訓読み)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: kunYomiController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., か.く",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Nanori (名乗り)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: naNoriController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., あきら",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                if (selectedType == 'Kanji') ...[
                  const SizedBox(height: 16),
                  Text(
                    "On'yomi (音読み)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: ''),
                    onChanged: (value) => readingController.text = value,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., ショウ",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kun'yomi (訓読み)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: ''),
                    onChanged: (value) {/* store kunYomi if needed */},
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., か.く",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Nanori (名乗り)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: ''),
                    onChanged: (value) {/* store nanori if needed */},
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., あきら",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Type',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Kanji', 'Vocab', 'Hiragana', 'Katakana'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setItemDialogState(() {
                        selectedType = newValue;
                        errorMessage = '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Tags (comma-separated, optional)',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'e.g., beginner, common',
                    hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notes (optional)',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (japaneseController.text.trim().isEmpty || englishController.text.trim().isEmpty) {
                  setItemDialogState(() {
                    errorMessage = 'Please fill in both Japanese and English fields';
                  });
                  return;
                }

                // Validate multi-character items
                if (japaneseController.text.trim().length > 1 && selectedType != 'Vocab') {
                  setItemDialogState(() {
                    errorMessage = 'Multi-character items must be of type "Vocab"';
                  });
                  return;
                }

                // Generate kanjiVGCode for the item
                String? kanjiVGCode;
                if (selectedType == 'Kanji' || selectedType == 'Vocab') {
                  final text = japaneseController.text.trim();
                  final codes = <String>[];
                  for (int i = 0; i < text.length; i++) {
                    final codePoint = text.codeUnitAt(i);
                    codes.add(codePoint.toRadixString(16).padLeft(5, '0'));
                  }
                  kanjiVGCode = codes.join(',');
                }

                // Parse tags
                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                final updatedItem = Item(
                  japanese: japaneseController.text.trim(),
                  translation: englishController.text.trim(),
                  strokeOrder: item.strokeOrder,
                  itemType: selectedType,
                  kanjiVGCode: kanjiVGCode,
                  notes: notesController.text.trim(),
                  reading: readingController.text.trim(),
                  onYomi: onYomiController.text.trim(),
                  kunYomi: kunYomiController.text.trim(),
                  naNori: naNoriController.text.trim(),
                  tags: tags,
                );

                // Update the item in the list
                tempItems[itemIndex] = updatedItem;
                
                // Close this dialog
                Navigator.pop(dialogContext);
                
                // Trigger parent dialog rebuild after this frame
                Future.microtask(() {
                  setDialogState(() {});
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) {
      japaneseController.dispose();
      englishController.dispose();
      notesController.dispose();
      tagsController.dispose();
    });
  }

  void _showAddItemToNewSetDialog(BuildContext parentContext, List<Item> tempItems, StateSetter setDialogState) {
    final japaneseController = TextEditingController();
    final englishController = TextEditingController();
    final readingController = TextEditingController();
    final onYomiController = TextEditingController(text: '');
    final kunYomiController = TextEditingController(text: '');
    final naNoriController = TextEditingController(text: '');
    final notesController = TextEditingController();
    final tagsController = TextEditingController();
    String selectedType = 'Kanji';
    String errorMessage = '';

    // Auto-detect item type from Japanese input
    String detectItemType(String text) {
      if (text.isEmpty) return selectedType;
      
      final firstChar = text.runes.first;
      
      // Hiragana range: 0x3040 - 0x309F
      if (firstChar >= 0x3040 && firstChar <= 0x309F) {
        return 'Hiragana';
      }
      // Katakana range: 0x30A0 - 0x30FF
      else if (firstChar >= 0x30A0 && firstChar <= 0x30FF) {
        return 'Katakana';
      }
      // Kanji range: 0x4E00 - 0x9FFF
      else if (firstChar >= 0x4E00 && firstChar <= 0x9FFF) {
        if (text.length == 1) {
          return 'Kanji';
        } else {
          return 'Vocab';
        }
      }
      return selectedType;
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setItemDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Item',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Japanese',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: japaneseController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (text) {
                    setItemDialogState(() {
                      selectedType = detectItemType(text);
                      errorMessage = '';
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'English',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: englishController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                if (selectedType == 'Vocab') ...[
                  const SizedBox(height: 16),
                  Text(
                    'Reading (optional)',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: readingController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'e.g., がっこう',
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                if (selectedType == 'Kanji') ...[
                  const SizedBox(height: 16),
                  Text(
                    "On'yomi (音読み)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: onYomiController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., ショウ",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kun'yomi (訓読み)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: kunYomiController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., か.く",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Nanori (名乗り)",
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: naNoriController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "e.g., あきら",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Type',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Kanji', 'Vocab', 'Hiragana', 'Katakana'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setItemDialogState(() {
                        selectedType = newValue;
                        errorMessage = '';
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Tags (comma-separated, optional)',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'e.g., beginner, common',
                    hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Notes (optional)',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (japaneseController.text.trim().isEmpty || englishController.text.trim().isEmpty) {
                  setItemDialogState(() {
                    errorMessage = 'Please fill in both Japanese and English fields';
                  });
                  return;
                }

                // Validate multi-character items
                if (japaneseController.text.trim().length > 1 && selectedType != 'Vocab') {
                  setItemDialogState(() {
                    errorMessage = 'Multi-character items must be of type "Vocab"';
                  });
                  return;
                }

                // Generate kanjiVGCode for the item
                String? kanjiVGCode;
                if (selectedType == 'Kanji' || selectedType == 'Vocab') {
                  final text = japaneseController.text.trim();
                  final codes = <String>[];
                  for (int i = 0; i < text.length; i++) {
                    final codePoint = text.codeUnitAt(i);
                    codes.add(codePoint.toRadixString(16).padLeft(5, '0'));
                  }
                  kanjiVGCode = codes.join(',');
                }

                // Parse tags
                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                final newItem = Item(
                  japanese: japaneseController.text.trim(),
                  translation: englishController.text.trim(),
                  strokeOrder: '',
                  itemType: selectedType,
                  kanjiVGCode: kanjiVGCode,
                  notes: notesController.text.trim(),
                  reading: readingController.text.trim(),
                  onYomi: onYomiController.text.trim(),
                  kunYomi: kunYomiController.text.trim(),
                  naNori: naNoriController.text.trim(),
                  tags: tags,
                );

                // Add to list (it's passed by reference)
                tempItems.add(newItem);
                
                // Close this dialog
                Navigator.pop(dialogContext);
                
                // Trigger parent dialog rebuild after this frame
                Future.microtask(() {
                  setDialogState(() {});
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ).then((_) {
      japaneseController.dispose();
      englishController.dispose();
      notesController.dispose();
      tagsController.dispose();
    });
  }

  void _showAddSetDialog() {
    final nameController = TextEditingController();
    final tagsController = TextEditingController();
    final itemTagsController = TextEditingController();
    String selectedSetType = 'Kanji';
    bool displayInDictionary = true;
    bool displayInWritingArcade = true;
    bool displayInReadingArcade = true;
    bool addTagsToItems = false;
    List<Item> tempItems = []; // Items to be added to the new set

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Create New Set',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Name',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Enter set name',
                    hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set Type',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedSetType,
                  dropdownColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: ['Kanji', 'Vocab', 'Hiragana', 'Katakana', 'Uncategorised'].map((String type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setDialogState(() {
                        selectedSetType = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Tags (comma-separated)',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: tagsController,
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'e.g., beginner, JLPT N5',
                    hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(
                    'Display in Dictionary',
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  ),
                  value: displayInDictionary,
                  onChanged: (value) {
                    setDialogState(() {
                      displayInDictionary = value ?? true;
                    });
                  },
                  activeColor: const Color(0xFF9A00FE),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text(
                    'Display in Writing Arcade',
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  ),
                  value: displayInWritingArcade,
                  onChanged: (value) {
                    setDialogState(() {
                      displayInWritingArcade = value ?? true;
                    });
                  },
                  activeColor: const Color(0xFF9A00FE),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Text(
                    'Display in Reading Arcade',
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  ),
                  value: displayInReadingArcade,
                  onChanged: (value) {
                    setDialogState(() {
                      displayInReadingArcade = value ?? true;
                    });
                  },
                  activeColor: const Color(0xFF9A00FE),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Text(
                    'Add tags to items',
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  ),
                  value: addTagsToItems,
                  onChanged: (value) {
                    setDialogState(() {
                      addTagsToItems = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF9A00FE),
                  contentPadding: EdgeInsets.zero,
                ),
                if (addTagsToItems) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: itemTagsController,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Tags to add to all items (comma-separated)',
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                      filled: true,
                      fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Import button
                OutlinedButton.icon(
                  onPressed: () {
                    _showImportOptionsDialog(context, tempItems, setDialogState);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Import'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF9A00FE),
                    side: const BorderSide(color: Color(0xFF9A00FE)),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 16),
                // Display added items count and simple list
                if (tempItems.isNotEmpty) ...[
                  Text(
                    'Items in Set (${tempItems.length})',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...tempItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                _showEditItemInNewSetDialog(context, tempItems, index, setDialogState);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      item.japanese,
                                      style: TextStyle(
                                        color: widget.isDarkMode ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.translation,
                                        style: TextStyle(
                                          color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setDialogState(() {
                                tempItems.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
                // Add Items button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showAddItemToNewSetDialog(context, tempItems, setDialogState);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Items'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9A00FE),
                      side: const BorderSide(color: Color(0xFF9A00FE)),
                    ),
                  ),
                ),
              ],
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a set name'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                // Parse tags
                final userTags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();
                
                // Ensure setType is included in tags
                final allTags = {selectedSetType, ...userTags}.toList();

                // Parse item tags if checkbox is enabled
                if (addTagsToItems && itemTagsController.text.trim().isNotEmpty) {
                  final itemTags = itemTagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();
                  
                  // Add tags to all items in tempItems
                  for (int i = 0; i < tempItems.length; i++) {
                    final item = tempItems[i];
                    final updatedTags = {...item.tags, ...itemTags}.toList();
                    tempItems[i] = Item(
                      japanese: item.japanese,
                      translation: item.translation,
                      strokeOrder: item.strokeOrder,
                      itemType: item.itemType,
                      kanjiVGCode: item.kanjiVGCode,
                      notes: item.notes,
                      reading: item.reading,
                      tags: updatedTags,
                    );
                  }
                }

                // Create new set
                final newSet = ItemSet(
                  name: nameController.text.trim(),
                  items: tempItems, // Include the items added during creation
                  tags: allTags,
                  displayInDictionary: displayInDictionary,
                  setType: selectedSetType,
                  displayInWritingArcade: displayInWritingArcade,
                  displayInReadingArcade: displayInReadingArcade,
                );

                // Generate unique key for the set
                String setKey = nameController.text.trim().replaceAll(' ', '_');
                int counter = 1;
                while (setsData.containsKey(setKey)) {
                  setKey = '${nameController.text.trim().replaceAll(' ', '_')}_$counter';
                  counter++;
                }

                // Add to setsData and save
                setsData[setKey] = newSet;
                await SetPreferences.saveSet(setKey, newSet);

                setState(() {}); // Refresh the UI

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Set "${newSet.name}" created successfully'),
                      backgroundColor: const Color(0xFF9A00FE),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameController.dispose();
      tagsController.dispose();
      itemTagsController.dispose();
    });
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
          'All Practice Sets',
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: _showAddSetDialog,
          ),
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.checklist,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedSetKeys.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Row(
            children: [
              Checkbox(
                value: _showHiddenSets,
                onChanged: (value) {
                  setState(() {
                    _showHiddenSets = value ?? false;
                  });
                },
                activeColor: const Color(0xFF9A00FE),
              ),
              Text(
                'View hidden sets',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Select All button when in selection mode
          if (_isSelectionMode) ...[
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  if (_selectedSetKeys.length == _getVisibleSetKeys().length) {
                    // If all are selected, deselect all
                    _selectedSetKeys.clear();
                  } else {
                    // Select all visible sets
                    _selectedSetKeys.clear();
                    _selectedSetKeys.addAll(_getVisibleSetKeys());
                  }
                });
              },
              icon: Icon(
                _selectedSetKeys.length == _getVisibleSetKeys().length
                    ? Icons.deselect
                    : Icons.select_all,
                size: 20,
              ),
              label: Text(
                _selectedSetKeys.length == _getVisibleSetKeys().length
                    ? 'Deselect All'
                    : 'Select All',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          ..._buildSectionsBySetType(),
          // Footer with Kanshudo attribution
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 10),
            child: Column(
              children: [
                Text(
                  'Pre-made JLPT sets referenced from kanshudo.com',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse('https://www.kanshudo.com/collections/jlpt_kanji');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'JLPT Kanji',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse('https://www.kanshudo.com/collections/wikipedia_jlpt?vw');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'JLPT Vocab',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final url = Uri.parse('https://www.kanshudo.com/component_details/standard_radicals');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                        minimumSize: Size.zero,
                      ),
                      child: const Text(
                        'Components',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isSelectionMode && _selectedSetKeys.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _duplicateSelectedSets,
                      icon: const Icon(Icons.content_copy, size: 20),
                      label: Text('Duplicate (${_selectedSetKeys.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _deleteSelectedSets,
                      icon: const Icon(Icons.delete, size: 20),
                      label: Text('Delete (${_selectedSetKeys.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  List<Widget> _buildSectionsBySetType() {
    List<Widget> widgets = [];
    
    // Define the order of sections
    final sectionOrder = ['Kana', 'Kanji', 'Vocab', 'Uncategorised'];
    
    for (String setType in sectionOrder) {
      // Collect all sets of this type
      List<MapEntry<String, ItemSet>> setsOfType = [];
      
      // Add sets of this type (only once!)
      for (var entry in setsData.entries) {
        if (entry.value.setType == setType) {
          // Filter based on displayInDictionary and showHiddenSets
          if (_showHiddenSets || entry.value.displayInDictionary) {
            setsOfType.add(entry);
          }
        }
      }
      
      // Only show section if there are sets of this type
      if (setsOfType.isNotEmpty) {
        // Add section header
        widgets.add(
          Text(
            setType,
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 15));
        
        // Add all sets in this section
        for (var entry in setsOfType) {
          final isHidden = !entry.value.displayInDictionary;
          widgets.add(_buildSetCard(
            entry.key,
            set: entry.value,
            isHidden: isHidden,
          ));
        }
        
        // Add spacing after section
        widgets.add(const SizedBox(height: 30));
      }
    }
    
    return widgets;
  }

  Widget _buildSetCard(String setName, {required ItemSet set, required bool isHidden}) {
    final isSelected = _selectedSetKeys.contains(setName);
    
    return Card(
      color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
      margin: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onDoubleTap: () {
          setState(() {
            if (!_isSelectionMode) {
              _isSelectionMode = true;
              _selectedSetKeys.add(setName);
            } else {
              _isSelectionMode = false;
              _selectedSetKeys.clear();
            }
          });
        },
        child: ListTile(
          onTap: () {
            if (_isSelectionMode) {
              setState(() {
                if (isSelected) {
                  _selectedSetKeys.remove(setName);
                } else {
                  _selectedSetKeys.add(setName);
                }
              });
              return;
            }
          // Navigate to unified set view
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewSetScreen(
                itemSet: set,
                isDarkMode: widget.isDarkMode,
                onThemeChanged: widget.onThemeChanged,
              ),
            ),
          ).then((_) {
            // Refresh the list when returning
            setState(() {});
          });
        },
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedSetKeys.add(setName);
                    } else {
                      _selectedSetKeys.remove(setName);
                    }
                  });
                },
                activeColor: const Color(0xFF9A00FE),
              )
            : null,
        title: Text(
          set.name,
          style: TextStyle(
            color: isHidden 
                ? (widget.isDarkMode ? Colors.white54 : Colors.black45)
                : (widget.isDarkMode ? Colors.white : Colors.black),
            fontSize: 18,
            fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHidden) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hidden',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.arrow_forward_ios,
              color: widget.isDarkMode ? Colors.white60 : Colors.black54,
              size: 18,
            ),
          ],
        ),
        ),
      ),
    );
  }

  // Get all visible set keys based on current filter
  List<String> _getVisibleSetKeys() {
    List<String> visibleKeys = [];
    for (var entry in setsData.entries) {
      if (_showHiddenSets || entry.value.displayInDictionary) {
        visibleKeys.add(entry.key);
      }
    }
    return visibleKeys;
  }

  // Duplicate selected sets
  Future<void> _duplicateSelectedSets() async {
    final selectedCount = _selectedSetKeys.length;
    
    for (String setKey in _selectedSetKeys) {
      final originalSet = setsData[setKey];
      if (originalSet == null) continue;

      // Find a unique name for the duplicate
      String newSetName = '${originalSet.name} (Copy)';
      int copyNumber = 1;
      while (setsData.containsKey(newSetName)) {
        copyNumber++;
        newSetName = '${originalSet.name} (Copy $copyNumber)';
      }

      // Create a deep copy of the items list
      final copiedItems = originalSet.items.map((item) {
        return Item(
          japanese: item.japanese,
          translation: item.translation,
          itemType: item.itemType,
          strokeOrder: item.strokeOrder,
          kanjiVGCode: item.kanjiVGCode,
          reading: item.reading,
          tags: List<String>.from(item.tags),
        );
      }).toList();

      // Create new set with all properties copied
      final newSet = ItemSet(
        name: newSetName,
        items: copiedItems,
        setType: originalSet.setType,
        displayInDictionary: originalSet.displayInDictionary,
        tags: List<String>.from(originalSet.tags),
        displayInWritingArcade: originalSet.displayInWritingArcade,
        displayInReadingArcade: originalSet.displayInReadingArcade,
      );

      // Add to setsData and save
      setsData[newSetName] = newSet;
      await SetPreferences.saveSet(newSetName, newSet);
    }

    // Exit selection mode and refresh
    setState(() {
      _isSelectionMode = false;
      _selectedSetKeys.clear();
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Duplicated $selectedCount set(s)'),
          backgroundColor: const Color(0xFF9A00FE),
        ),
      );
    }
  }

  // Delete selected sets
  Future<void> _deleteSelectedSets() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Sets?',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedSetKeys.length} set(s)? This action cannot be undone.',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Delete each selected set
    for (String setKey in _selectedSetKeys) {
      setsData.remove(setKey);
      await SetPreferences.deleteSet(setKey);
    }

    // Exit selection mode and refresh
    setState(() {
      _isSelectionMode = false;
      _selectedSetKeys.clear();
    });

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sets deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


