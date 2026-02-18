import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sets_data.dart';
import 'view_set.dart';
import 'set_preferences.dart';
import 'view_all_sets.dart';
import 'writing_practice_arcade.dart';

class WritingPracticeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const WritingPracticeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<WritingPracticeScreen> createState() => _WritingPracticeScreenState();
}

class _WritingPracticeScreenState extends State<WritingPracticeScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedSetKeys = {};

  List<MapEntry<String, ItemSet>> get allSets {
    List<MapEntry<String, ItemSet>> sets = [];
    
    // Add all sets that should display in writing arcade
    for (var entry in setsData.entries) {
      if (entry.value.displayInWritingArcade) {
        sets.add(entry);
      }
    }
    
    return sets;
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

  void _showPlayDialog(BuildContext context, ItemSet set) {
    int numberOfRounds = 20;
    bool roundForEveryItem = false;
    bool roundForEveryStarred = false;
    bool showNoStarredWarning = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Start Practice', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Number of Rounds', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              TextField(
                enabled: !roundForEveryItem && !roundForEveryStarred,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
                controller: TextEditingController(text: numberOfRounds.toString()),
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) setState(() => numberOfRounds = parsed);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('Round for every item', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                value: roundForEveryItem,
                onChanged: (val) {
                  setState(() {
                    roundForEveryItem = val;
                    if (val) roundForEveryStarred = false;
                  });
                },
                activeThumbColor: const Color(0xFF9A00FE),
              ),
              SwitchListTile(
                title: Text('Round for every starred item', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                value: roundForEveryStarred,
                onChanged: (val) {
                  setState(() {
                    roundForEveryStarred = val;
                    if (val) roundForEveryItem = false;
                    if (val) {
                      final starredCount = set.items.where((item) => item.isStarred).length;
                      showNoStarredWarning = starredCount == 0;
                    } else {
                      showNoStarredWarning = false;
                    }
                  });
                },
                activeThumbColor: const Color(0xFF9A00FE),
              ),
              if (showNoStarredWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'No starred items in set',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
            ),
            ElevatedButton(
              onPressed: showNoStarredWarning
                  ? null
                  : () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WritingPracticeArcadeScreen(
                            itemSet: set,
                            numberOfRounds: numberOfRounds,
                            roundForEveryItem: roundForEveryItem,
                            roundForEveryStarred: roundForEveryStarred,
                            isDarkMode: widget.isDarkMode,
                            onThemeChanged: widget.onThemeChanged,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE), foregroundColor: Colors.white),
              child: const Text('Start'),
            ),
          ],
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
        title: Text('Writing Practice', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: widget.isDarkMode ? Colors.white : Colors.black),
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
                setState(() {});
              });
            },
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Practice Set',
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            // Select All button when in selection mode
            if (_isSelectionMode) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    if (_selectedSetKeys.length == allSets.length) {
                      _selectedSetKeys.clear();
                    } else {
                      _selectedSetKeys.clear();
                      for (var entry in allSets) {
                        _selectedSetKeys.add(entry.key);
                      }
                    }
                  });
                },
                icon: Icon(
                  _selectedSetKeys.length == allSets.length
                      ? Icons.deselect
                      : Icons.select_all,
                  size: 20,
                ),
                label: Text(
                  _selectedSetKeys.length == allSets.length
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
            Expanded(
              child: ListView.builder(
                itemCount: allSets.length + 1, // +1 for footer
                itemBuilder: (context, index) {
                  // Show footer at the end
                  if (index == allSets.length) {
                    return Padding(
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
                    );
                  }
                  
                  final entry = allSets[index];
                  final set = entry.value;
                  final setKey = entry.key;
                  final displayName = set.name;
                  final isSelected = _selectedSetKeys.contains(setKey);
                  
                  return Card(
                    color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey[200],
                    margin: const EdgeInsets.only(bottom: 15),
                    child: GestureDetector(
                      onDoubleTap: () {
                        setState(() {
                          if (!_isSelectionMode) {
                            _isSelectionMode = true;
                            _selectedSetKeys.add(setKey);
                          } else {
                            _isSelectionMode = false;
                            _selectedSetKeys.clear();
                          }
                        });
                      },
                      child: ListTile(
                        leading: _isSelectionMode
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedSetKeys.add(setKey);
                                    } else {
                                      _selectedSetKeys.remove(setKey);
                                    }
                                  });
                                },
                                fillColor: WidgetStateProperty.resolveWith<Color>(
                                  (Set<WidgetState> states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return const Color(0xFF9A00FE);
                                    }
                                    return widget.isDarkMode
                                        ? Colors.grey[700]!
                                        : Colors.grey[400]!;
                                  },
                                ),
                              )
                            : null,
                        title: Text(
                          displayName,
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white : Colors.black,
                            fontSize: 18,
                          ),
                        ),
                        trailing: _isSelectionMode
                            ? null
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
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
                                        setState(() {});
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9A00FE),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Icon(Icons.remove_red_eye),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      _showPlayDialog(context, set);
                                    }, // Play button now shows dialog with set
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF9A00FE),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Icon(Icons.play_arrow),
                                  ),
                                ],
                              ),
                        onTap: _isSelectionMode
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedSetKeys.remove(setKey);
                                  } else {
                                    _selectedSetKeys.add(setKey);
                                  }
                                });
                              }
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

  // Duplicate selected sets
  Future<void> _duplicateSelectedSets() async {
    final selectedCount = _selectedSetKeys.length;
    
    for (String setKey in _selectedSetKeys) {
      final originalSet = setsData[setKey];
      if (originalSet == null) continue;

      String newSetName = '${originalSet.name} (Copy)';
      int copyNumber = 1;
      while (setsData.containsKey(newSetName)) {
        copyNumber++;
        newSetName = '${originalSet.name} (Copy $copyNumber)';
      }

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

      final newSet = ItemSet(
        name: newSetName,
        items: copiedItems,
        setType: originalSet.setType,
        displayInDictionary: originalSet.displayInDictionary,
        tags: List<String>.from(originalSet.tags),
        displayInWritingArcade: originalSet.displayInWritingArcade,
        displayInReadingArcade: originalSet.displayInReadingArcade,
      );

      setsData[newSetName] = newSet;
      await SetPreferences.saveSet(newSetName, newSet);
    }

    setState(() {
      _isSelectionMode = false;
      _selectedSetKeys.clear();
    });

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

    for (String setKey in _selectedSetKeys) {
      setsData.remove(setKey);
      await SetPreferences.deleteSet(setKey);
    }

    setState(() {
      _isSelectionMode = false;
      _selectedSetKeys.clear();
    });

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


