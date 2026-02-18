import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'sets_data.dart';
import 'item_detail.dart';
import 'set_preferences.dart';

class ViewSetScreen extends StatefulWidget {
  final ItemSet itemSet;
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const ViewSetScreen({
    super.key,
    required this.itemSet,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<ViewSetScreen> createState() => _ViewSetScreenState();
}

class _ViewSetScreenState extends State<ViewSetScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Item> _filteredItems = [];
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  // Pagination
  final int _itemsPerPage = 100;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.itemSet.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _tagsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showEditDialog() {
    _nameController.text = widget.itemSet.name;
    _tagsController.text = widget.itemSet.tags.join(', ');
    bool displayInDictionary = widget.itemSet.displayInDictionary;
    String selectedSetType = widget.itemSet.setType;
    bool displayInWritingArcade = widget.itemSet.displayInWritingArcade;
    bool displayInReadingArcade = widget.itemSet.displayInReadingArcade;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit $selectedSetType Set',
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
                  controller: _nameController,
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
                const SizedBox(height: 20),
                Text(
                  'Tags (comma-separated)',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Permanent Set Type tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9A00FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedSetType,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.lock,
                              size: 12,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                      // User-added tags
                      ...(_tagsController.text.isNotEmpty
                          ? _tagsController.text
                              .split(',')
                              .map((tag) => tag.trim())
                              .where((tag) => tag.isNotEmpty)
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9A00FE),
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
                              .toList()
                          : []),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsController,
                  onChanged: (value) {
                    setDialogState(() {}); // Trigger rebuild to update tag badges
                  },
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: 'e.g., beginner, daily, conversation',
                    hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    filled: true,
                    fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Set Type',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSetType,
                      isExpanded: true,
                      dropdownColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                      style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                      items: ['Kana', 'Kanji', 'Vocab', 'Uncategorised']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
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
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Display in Dictionary',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Switch(
                      value: displayInDictionary,
                      onChanged: (value) {
                        setDialogState(() {
                          displayInDictionary = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Display in Arcade',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable in Writing',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Switch(
                      value: displayInWritingArcade,
                      onChanged: (value) {
                        setDialogState(() {
                          displayInWritingArcade = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable in Reading',
                      style: TextStyle(
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Switch(
                      value: displayInReadingArcade,
                      onChanged: (value) {
                        setDialogState(() {
                          displayInReadingArcade = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Note: If you hide it from everywhere you can find it by enabling "Show hidden" in the dictionary view sets page.',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white54 : Colors.black45,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),
                // Delete Set Button
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
                            'Delete Set?',
                            style: TextStyle(
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete "${widget.itemSet.name}"? This action cannot be undone.',
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
                        // Find the key for this set and delete it
                        String? setKey;
                        try {
                          setKey = setsData.entries
                              .firstWhere((entry) => entry.value == widget.itemSet,
                                  orElse: () => MapEntry('', widget.itemSet))
                              .key;
                        } catch (e) {
                          // If not found by reference, try by name
                          setKey = setsData.entries
                              .firstWhere((entry) => entry.value.name == widget.itemSet.name,
                                  orElse: () => MapEntry('', widget.itemSet))
                              .key;
                        }
                        
                        if (setKey.isNotEmpty) {
                          setsData.remove(setKey);
                          await SetPreferences.deleteSet(setKey);
                          
                          if (mounted) {
                            Navigator.pop(context); // Close edit dialog
                            Navigator.pop(context); // Go back to previous screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Set deleted successfully'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                    icon: const Icon(Icons.delete, size: 20),
                    label: const Text('Delete Set'),
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
                  widget.itemSet.name = _nameController.text;
                  // Parse user tags and always include setType
                  final userTags = _tagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();
                  // Ensure setType is included and remove duplicates
                  final allTags = {selectedSetType, ...userTags}.toList();
                  widget.itemSet.tags = allTags;
                  widget.itemSet.displayInDictionary = displayInDictionary;
                  widget.itemSet.setType = selectedSetType;
                  widget.itemSet.displayInWritingArcade = displayInWritingArcade;
                  widget.itemSet.displayInReadingArcade = displayInReadingArcade;
                });
                
                // Find the key for this set and save to preferences
                final setKey = setsData.entries
                    .firstWhere((entry) => entry.value == widget.itemSet)
                    .key;
                await SetPreferences.saveSet(setKey, widget.itemSet);
                
                Navigator.pop(context);
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
    );
  }

  void _showAddItemOptionsDialog() {
    String textFileImportType = 'Kanji (or kana)';
    String selectedPreset = 'Hiragana';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add Items',
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
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddItemDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Single Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Import from Preset',
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
                      setDialogState(() {
                        selectedPreset = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (completeDefaultPresets.containsKey(selectedPreset)) {
                      final presetItems = List<Item>.from(completeDefaultPresets[selectedPreset]!.items);
                      
                      setState(() {
                        for (var item in presetItems) {
                          widget.itemSet.items.add(Item(
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
                        _filteredItems = widget.itemSet.items;
                      });
                      
                      // Save changes to preferences
                      final setKey = setsData.entries
                          .firstWhere((entry) => entry.value == widget.itemSet)
                          .key;
                      await SetPreferences.saveSet(setKey, widget.itemSet);
                      
                      Navigator.pop(context);
                      
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
                      FilePickerResult? result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['txt'],
                      );

                      if (result != null && result.files.single.path != null) {
                        final file = File(result.files.single.path!);
                        final content = await file.readAsString();
                        
                        final lines = content.split('\n')
                            .map((line) => line.trim())
                            .where((line) => line.isNotEmpty)
                            .toList();
                        
                        int importedCount = 0;
                        
                        if (textFileImportType == 'Kanji (or kana)') {
                          for (int i = 0; i < lines.length - 1; i += 2) {
                            final japanese = lines[i];
                            final english = lines[i + 1];
                            
                            String itemType = 'Kanji';
                            if (japanese.isNotEmpty) {
                              final firstChar = japanese.runes.first;
                              if (firstChar >= 0x3040 && firstChar <= 0x309F) {
                                itemType = 'Hiragana';
                              } else if (firstChar >= 0x30A0 && firstChar <= 0x30FF) {
                                itemType = 'Katakana';
                              }
                            }
                            
                            String kanjiVGCode = '';
                            if (itemType == 'Kanji' && japanese.length == 1) {
                              kanjiVGCode = 'kanji_${japanese.codeUnitAt(0).toRadixString(16).padLeft(5, '0')}';
                            }
                            
                            setState(() {
                              widget.itemSet.items.add(Item(
                                japanese: japanese,
                                translation: english,
                                strokeOrder: '',
                                itemType: itemType,
                                kanjiVGCode: kanjiVGCode,
                                notes: '',
                                reading: '',
                                tags: [],
                              ));
                              _filteredItems = widget.itemSet.items;
                            });
                            importedCount++;
                          }
                        } else {
                          for (int i = 0; i < lines.length - 2; i += 3) {
                            final japanese = lines[i];
                            final reading = lines[i + 1];
                            final english = lines[i + 2];
                            
                            setState(() {
                              widget.itemSet.items.add(Item(
                                japanese: japanese,
                                translation: english,
                                strokeOrder: '',
                                itemType: 'Vocab',
                                kanjiVGCode: '',
                                notes: '',
                                reading: reading,
                                tags: [],
                              ));
                              _filteredItems = widget.itemSet.items;
                            });
                            importedCount++;
                          }
                        }
                        
                        // Save changes to preferences
                        final setKey = setsData.entries
                            .firstWhere((entry) => entry.value == widget.itemSet)
                            .key;
                        await SetPreferences.saveSet(setKey, widget.itemSet);
                        
                        Navigator.pop(context);
                        
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
                            setDialogState(() {
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
                            setDialogState(() {
                              textFileImportType = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
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

  void _showAddItemDialog() {
    final japaneseController = TextEditingController();
    final translationController = TextEditingController();
    final readingController = TextEditingController();
    final onYomiController = TextEditingController();
    final kunYomiController = TextEditingController();
    final naNoriController = TextEditingController();
    final tagsController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = widget.itemSet.setType == 'Vocab' ? 'Vocab' : 'Kanji';
    String? errorMessage;
    
    // Find current set key for default selection
    String? currentSetKey;
    for (var entry in setsData.entries) {
      if (entry.value == widget.itemSet) {
        currentSetKey = entry.key;
        break;
      }
    }
    String selectedSet = currentSetKey ?? setsData.keys.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Add New Item',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item Type dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
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
                    if (newValue != null) {
                      setDialogState(() {
                        selectedType = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Set selector dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedSet,
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
                    if (newValue != null) {
                      setDialogState(() {
                        selectedSet = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: japaneseController,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      // Auto-detect type based on first character
                      String detectedType;
                      
                      // Force Vocab for multiple characters
                      if (value.length > 1) {
                        detectedType = 'Vocab';
                      } else {
                        final firstChar = value.characters.first;
                        final code = firstChar.codeUnitAt(0);
                        
                        if (code >= 0x3040 && code <= 0x309F) {
                          // Hiragana
                          detectedType = 'Hiragana';
                        } else if (code >= 0x30A0 && code <= 0x30FF) {
                          // Katakana
                          detectedType = 'Katakana';
                        } else if (code >= 0x4E00 && code <= 0x9FFF) {
                          // Kanji range
                          detectedType = 'Kanji';
                        } else {
                          detectedType = 'Kanji';
                        }
                      }
                      
                      if (detectedType != selectedType) {
                        setDialogState(() {
                          selectedType = detectedType;
                          errorMessage = null; // Clear error on valid input
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
                // Show On'yomi, Kun'yomi, Nanori fields if selectedType is 'Kanji'
                if (selectedType == 'Kanji') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: onYomiController,
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
                    controller: kunYomiController,
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
                    controller: naNoriController,
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
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
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
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
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
                
                // Generate kanjiVGCode for the character
                String? kanjiVGCode;
                if (japaneseController.text.isNotEmpty) {
                  final char = japaneseController.text.characters.first;
                  final codePoint = char.codeUnitAt(0);
                  kanjiVGCode = codePoint.toRadixString(16).padLeft(5, '0');
                }
                
                // Create new item
                final newItem = Item(
                  japanese: japaneseController.text,
                  translation: translationController.text,
                  reading: readingController.text,
                  itemType: selectedType,
                  kanjiVGCode: kanjiVGCode,
                  tags: tagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList(),
                  notes: notesController.text,
                  onYomi: selectedType == 'Kanji' ? onYomiController.text : null,
                  kunYomi: selectedType == 'Kanji' ? kunYomiController.text : null,
                  naNori: selectedType == 'Kanji' ? naNoriController.text : null,
                );
                
                // Add to selected set
                setsData[selectedSet]!.items.add(newItem);
                await SetPreferences.saveSet(selectedSet, setsData[selectedSet]!);
                
                // Refresh UI if adding to current set
                if (selectedSet == currentSetKey) {
                  setState(() {
                    _filteredItems = widget.itemSet.items;
                  });
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Item added to $selectedSet'),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ).then((_) {
      japaneseController.dispose();
      translationController.dispose();
      readingController.dispose();
      tagsController.dispose();
      notesController.dispose();
    });
  }

  void _filterItems(String query) {
    setState(() {
      // Reset to first page whenever filters/search change
      _currentPage = 1;
      if (query.isEmpty) {
        _filteredItems = widget.itemSet.items;
      } else {
        _filteredItems = widget.itemSet.items.where((item) {
          final wordMatch = item.japanese.toLowerCase().contains(query.toLowerCase());
          final readingMatch = item.reading.toLowerCase().contains(query.toLowerCase());
          final translationMatch = item.translation.toLowerCase().contains(query.toLowerCase());
          return wordMatch || readingMatch || translationMatch;
        }).toList();
      }
    });
  }

  void _deleteSelectedItems() async {
    setState(() {
      final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final index in sortedIndices) {
        widget.itemSet.items.removeAt(index);
      }
      _selectedIndices.clear();
      _filteredItems = widget.itemSet.items;
      _isSelectionMode = false;
    });
    
    // Save changes to preferences
    final setKey = setsData.entries
        .firstWhere((entry) => entry.value == widget.itemSet)
        .key;
    await SetPreferences.saveSet(setKey, widget.itemSet);
  }

  void _duplicateSelectedItems() async {
    setState(() {
      final sortedIndices = _selectedIndices.toList()..sort();
      final itemsToDuplicate = sortedIndices
          .map((index) {
            final original = widget.itemSet.items[index];
            // Create a new Item object (copy) instead of reusing the reference
            return Item(
              japanese: original.japanese,
              reading: original.reading,
              translation: original.translation,
              strokeOrder: original.strokeOrder,
              kanjiVGCode: original.kanjiVGCode,
              itemType: original.itemType,
              tags: List<String>.from(original.tags),
            );
          })
          .toList();
      
      // Find the highest index (bottom selected item)
      final maxIndex = sortedIndices.last;
      final newSelectedIndices = <int>{};
      
      // Insert all duplicates right after the bottom selected item
      for (int i = 0; i < itemsToDuplicate.length; i++) {
        widget.itemSet.items.insert(maxIndex + 1 + i, itemsToDuplicate[i]);
        newSelectedIndices.add(maxIndex + 1 + i);
      }
      
      // Select the duplicates instead of the originals
      _selectedIndices.clear();
      _selectedIndices.addAll(newSelectedIndices);
      _filteredItems = widget.itemSet.items;
    });
    
    // Save changes to preferences
    final setKey = setsData.entries
        .firstWhere((entry) => entry.value == widget.itemSet)
        .key;
    await SetPreferences.saveSet(setKey, widget.itemSet);
  }

  void _showChangeSetDialog() {
    final availableSets = setsData.entries
        .where((entry) => entry.value != widget.itemSet)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Move to Set',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSets.length,
            itemBuilder: (context, index) {
              final entry = availableSets[index];
              return ListTile(
                title: Text(
                  entry.value.name,
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _moveItemsToSet(entry.value);
                },
              );
            },
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
        ],
      ),
    );
  }

  void _moveItemsToSet(ItemSet targetSet) async {
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    final itemsToMove = sortedIndices
        .map((index) => widget.itemSet.items[index])
        .toList();
    
    setState(() {
      // Add items to target set, avoiding duplicates
      for (final item in itemsToMove) {
        // Check if item already exists in target set
        final exists = targetSet.items.any((existing) => 
            existing.japanese == item.japanese && 
            existing.reading == item.reading &&
            existing.translation == item.translation);
        if (!exists) {
          targetSet.items.add(item);
        }
      }
      
      // Remove items from source set
      for (final index in sortedIndices) {
        widget.itemSet.items.removeAt(index);
      }
      
      _selectedIndices.clear();
      _filteredItems = widget.itemSet.items;
      _isSelectionMode = false;
    });

    // Save both source and target sets to preferences
    final sourceKey = setsData.entries
        .firstWhere((entry) => entry.value == widget.itemSet)
        .key;
    final targetKey = setsData.entries
        .firstWhere((entry) => entry.value == targetSet)
        .key;
    await SetPreferences.saveSet(sourceKey, widget.itemSet);
    await SetPreferences.saveSet(targetKey, targetSet);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Moved ${itemsToMove.length} item(s) to ${targetSet.name}'),
        backgroundColor: const Color(0xFF9A00FE),
      ),
    );
  }

  void _moveToTop() async {
    setState(() {
      final sortedIndices = _selectedIndices.toList()..sort();
      final itemsToMove = sortedIndices
          .map((index) => widget.itemSet.items[index])
          .toList();
      
      // Remove items from their current positions (in reverse order)
      for (int i = sortedIndices.length - 1; i >= 0; i--) {
        widget.itemSet.items.removeAt(sortedIndices[i]);
      }
      
      // Insert items at the top
      widget.itemSet.items.insertAll(0, itemsToMove);
      
      // Update selected indices to reflect new positions
      _selectedIndices.clear();
      for (int i = 0; i < itemsToMove.length; i++) {
        _selectedIndices.add(i);
      }
      
      _filteredItems = widget.itemSet.items;
    });
    
    // Jump to top instantly
    _scrollController.jumpTo(0);
    
    // Save changes to preferences
    final setKey = setsData.entries
        .firstWhere((entry) => entry.value == widget.itemSet)
        .key;
    await SetPreferences.saveSet(setKey, widget.itemSet);
  }

  void _moveToBottom() async {
    setState(() {
      final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      final itemsToMove = sortedIndices
          .reversed
          .map((index) => widget.itemSet.items[index])
          .toList();
      
      // Remove items from their current positions
      for (final index in sortedIndices) {
        widget.itemSet.items.removeAt(index);
      }
      
      // Add items to the bottom
      final startIndex = widget.itemSet.items.length;
      widget.itemSet.items.addAll(itemsToMove);
      
      // Update selected indices to reflect new positions
      _selectedIndices.clear();
      for (int i = 0; i < itemsToMove.length; i++) {
        _selectedIndices.add(startIndex + i);
      }
      
      _filteredItems = widget.itemSet.items;
    });
    
    // Jump to bottom instantly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
    
    // Save changes to preferences
    final setKey = setsData.entries
        .firstWhere((entry) => entry.value == widget.itemSet)
        .key;
    await SetPreferences.saveSet(setKey, widget.itemSet);
  }

  void _selectInRow() {
    if (_selectedIndices.length < 2) return;
    
    setState(() {
      final sortedIndices = _selectedIndices.toList()..sort();
      final minIndex = sortedIndices.first;
      final maxIndex = sortedIndices.last;
      
      // Select all items between min and max
      for (int i = minIndex; i <= maxIndex; i++) {
        _selectedIndices.add(i);
      }
    });
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(widget.itemSet.name, style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: () => _showAddItemOptionsDialog(),
          ),
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.checklist,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSelectionMode = !_isSelectionMode;
                _selectedIndices.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.edit, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: () => _showEditDialog(),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: widget.itemSet.items.isEmpty
          ? Center(
              child: Text(
                'No items in this set yet',
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 18,
                ),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                                fontSize: 18,
                              ),
                              children: [
                                const TextSpan(text: 'This set has '),
                                TextSpan(
                                  text: '${widget.itemSet.items.length}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const TextSpan(text: ' items'),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () {
                                  _scrollController.jumpTo(0);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward,
                                    size: 20,
                                    color: widget.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Icon(
                                    Icons.arrow_downward,
                                    size: 20,
                                    color: widget.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _searchController,
                        onChanged: _filterItems,
                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black),
                        decoration: InputDecoration(
                          hintText: 'Search word, reading, or translation...',
                          hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white54 : Colors.black54),
                          prefixIcon: Icon(Icons.search, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                                  onPressed: () {
                                    _searchController.clear();
                                    _filterItems('');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      // Select All button when in selection mode
                      if (_isSelectionMode) ...[
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    if (_selectedIndices.length == widget.itemSet.items.length) {
                                      // If all are selected, deselect all
                                      _selectedIndices.clear();
                                    } else {
                                      // Select all items
                                      _selectedIndices.clear();
                                      for (int i = 0; i < widget.itemSet.items.length; i++) {
                                        _selectedIndices.add(i);
                                      }
                                    }
                                  });
                                },
                                icon: Icon(
                                  _selectedIndices.length == widget.itemSet.items.length
                                      ? Icons.deselect
                                      : Icons.select_all,
                                  size: 20,
                                ),
                                label: Text(
                                  _selectedIndices.length == widget.itemSet.items.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF9A00FE),
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
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final int totalItems = _filteredItems.length;
                      int totalPages = (totalItems + _itemsPerPage - 1) ~/ _itemsPerPage;
                      if (totalPages < 1) totalPages = 1;
                      final startIndex = (_currentPage - 1) * _itemsPerPage;
                      final currentPageItems = _filteredItems.skip(startIndex).take(_itemsPerPage).toList();

                      return Column(
                        children: [
                          Expanded(
                            child: currentPageItems.isEmpty
                                ? Center(
                                    child: Text(
                                      'No items match your search',
                                      style: TextStyle(
                                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: currentPageItems.length,
                                    itemBuilder: (context, index) {
                                      final item = currentPageItems[index];
                                      final originalIndex = widget.itemSet.items.indexOf(item);
                                      final isSelected = _selectedIndices.contains(originalIndex);

                                      return Card(
                                        color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                                        margin: const EdgeInsets.only(bottom: 10),
                                        child: GestureDetector(
                                          onDoubleTap: () {
                                            setState(() {
                                              if (!_isSelectionMode) {
                                                _isSelectionMode = true;
                                                _selectedIndices.add(originalIndex);
                                              } else {
                                                _isSelectionMode = false;
                                                _selectedIndices.clear();
                                              }
                                            });
                                          },
                                          child: ListTile(
                                            onTap: () {
                                              if (_isSelectionMode) {
                                                setState(() {
                                                  if (isSelected) {
                                                    _selectedIndices.remove(originalIndex);
                                                  } else {
                                                    _selectedIndices.add(originalIndex);
                                                  }
                                                });
                                              } else {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ItemDetailScreen(
                                                      item: item,
                                                      isDarkMode: widget.isDarkMode,
                                                      allItems: widget.itemSet.items,
                                                      currentIndex: originalIndex,
                                                      onThemeChanged: widget.onThemeChanged,
                                                    ),
                                                  ),
                                                ).then((_) {
                                                  setState(() {});
                                                });
                                              }
                                            },
                                            leading: _isSelectionMode
                                                ? Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Checkbox(
                                                        value: isSelected,
                                                        onChanged: (bool? value) {
                                                          setState(() {
                                                            if (value == true) {
                                                              _selectedIndices.add(originalIndex);
                                                            } else {
                                                              _selectedIndices.remove(originalIndex);
                                                            }
                                                          });
                                                        },
                                                        activeColor: const Color(0xFF9A00FE),
                                                      ),
                                                      Container(
                                                        width: 50,
                                                        height: 50,
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
                                                    ],
                                                  )
                                                : (item.itemType != 'Vocab'
                                                    ? Container(
                                                        width: 50,
                                                        height: 50,
                                                        alignment: Alignment.center,
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFF9A00FE),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          item.japanese,
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 24,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      )
                                                    : null),
                                            title: item.itemType != 'Vocab'
                                                ? Text(
                                                    item.translation,
                                                    style: TextStyle(
                                                      color: widget.isDarkMode ? Colors.white : Colors.black,
                                                      fontSize: 16,
                                                    ),
                                                  )
                                                : Text(
                                                    item.japanese,
                                                    style: TextStyle(
                                                      color: widget.isDarkMode ? Colors.white : Colors.black,
                                                      fontSize: 20,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                            subtitle: item.itemType == 'Vocab'
                                                ? Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      const SizedBox(height: 5),
                                                      Text(
                                                        item.reading,
                                                        style: TextStyle(
                                                          color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 3),
                                                      Text(
                                                        item.translation,
                                                        style: TextStyle(
                                                          color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                : null,
                                            trailing: IconButton(
                                              icon: Icon(
                                                item.isStarred ? Icons.star : Icons.star_border,
                                                color: item.isStarred ? Colors.amber : Colors.grey,
                                              ),
                                              tooltip: item.isStarred ? 'Unstar' : 'Star',
                                              onPressed: () {
                                                setState(() {
                                                  item.isStarred = !item.isStarred;
                                                });
                                                final setKey = setsData.entries.firstWhere((entry) => entry.value == widget.itemSet).key;
                                                SetPreferences.saveSet(setKey, widget.itemSet);
                                              },
                                            ),
                                          ),
                                        ),
                                      );
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
                                          if (_scrollController.hasClients) _scrollController.jumpTo(0);
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
                                          if (_scrollController.hasClients) _scrollController.jumpTo(0);
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _isSelectionMode && _selectedIndices.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text(
                              'Delete Items',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: Text(
                              'Are you sure you want to delete ${_selectedIndices.length} item(s)?',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
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
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteSelectedItems();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete, size: 20),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _duplicateSelectedItems,
                      icon: const Icon(Icons.copy, size: 20),
                      label: const Text('Duplicate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showChangeSetDialog,
                      icon: const Icon(Icons.move_to_inbox, size: 20),
                      label: const Text('Move'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _moveToTop,
                      icon: const Icon(Icons.vertical_align_top, size: 20),
                      label: const Text('Move to Top'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _moveToBottom,
                      icon: const Icon(Icons.vertical_align_bottom, size: 20),
                      label: const Text('Move to Bottom'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9A00FE),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedIndices.length < 2 ? null : _selectInRow,
                  icon: const Icon(Icons.view_agenda, size: 20),
                  label: const Text('Select in Row'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
            )
          : null,
    );
  }
}


