import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'sets_data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'library.dart';
import 'study.dart';
import 'dictionary.dart';
import 'set_preferences.dart';
import 'user_profile.dart';
import 'stats_screen.dart';
import 'writing_practice_canvas.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'src/export_helper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'backup_data.dart';
import 'cloud_sync_page.dart';
import 'quick_sync_button.dart';
import 'main_mini.dart';
// Application entrypoint. A single build serves both the full app and
// "Kanji Athletes Mini" (a small always-on-top flashcard/listening
// companion window, see main_mini.dart) - launching with a --mini argument
// (e.g. a separate desktop shortcut pointed at this same .exe) boots the
// Mini UI instead, rather than maintaining a second Windows build/runner
// just to get what amounts to a second launchable icon.
Future<void> main(List<String> args) async {
  if (args.contains('--mini')) {
    await runMiniApp();
    return;
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Ensure any migrations and saved sets are loaded before the app starts
  await SetPreferences.checkMigration();
  await SetPreferences.loadAllSets();

  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: GemGridApp(),
  ));
}
// Custom hover icon button widget
class HoverIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDarkMode;

  const HoverIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.isDarkMode,
  });

  @override
  State<HoverIconButton> createState() => _HoverIconButtonState();
}

class _HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isHovering ? const Color(0xFF9A00FE) : Colors.transparent,
        ),
        child: IconButton(
          icon: Icon(
            widget.icon,
            color: _isHovering ? Colors.white : (widget.isDarkMode ? Colors.white54 : Colors.grey),
          ),
          onPressed: widget.onPressed,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          padding: const EdgeInsets.all(4),
        ),
      ),
    );
  }
  }

class GemGridApp extends StatefulWidget {
  const GemGridApp({super.key});

  @override
  State<GemGridApp> createState() => _GemGridAppState();
}

class _GemGridAppState extends State<GemGridApp> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  @override
  void reassemble() {
    // Called on hot reload — reload saved sets so runtime changes persist
    super.reassemble();
    SetPreferences.loadAllSets().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
    });
  }

  Future<void> _setThemePreference(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() {
      _isDarkMode = isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(onThemeChanged: _setThemePreference, isDarkMode: _isDarkMode),
    );
  }
}

class InventoryScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const InventoryScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Variables for the editable title
  // Variables for the drag-and-drop sequence
  bool _isBoxOpening = false;
  // --- OVERLAY STATE ---
  bool _isLocked = true;
  bool _showBoxUnlocked = false;
  final TextEditingController _keyController = TextEditingController();
  bool _isEditingTitle = false;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();


  // Call this to load everything from memory
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _titleController.text = prefs.getString('box_title') ?? "Your Name's Item Box";
      _isLocked = prefs.getBool('is_locked') ?? true;
      _showBoxUnlocked = prefs.getBool('show_box_unlocked') ?? false;
      
      String? gemString = prefs.getString('gem_data');
      if (gemString != null) {
        List<dynamic> decoded = jsonDecode(gemString);
        for (int i = 0; i < decoded.length; i++) {
          if (i < _gemData.length) _gemData[i] = decoded[i];
        }
      }
    });
  }

  // Call this whenever you change a variable you want to remember
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('box_title', _titleController.text);
    await prefs.setBool('is_locked', _isLocked);
    await prefs.setBool('show_box_unlocked', _showBoxUnlocked);
    await prefs.setString('gem_data', jsonEncode(_gemData));
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: "Your Name's Item Box");
    _titleFocusNode.addListener(_onTitleFocusChange);
    _loadData(); // Add this line here
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus && _isEditingTitle) {
      setState(() => _isEditingTitle = false);
      _saveData();
    }
  }

  @override
  void dispose() {
    _titleFocusNode.removeListener(_onTitleFocusChange);
    _titleController.dispose();
    _titleFocusNode.dispose();
    _keyController.dispose();
    _codeController.dispose();
    super.dispose();
  }
  // 1. Data initialization: 18 slots, all initially empty (false)
  final List<bool> _gemData = List.generate(18, (index) => false);

  // 2. The Code Mapping
  final Map<String, int> _gemCodes = {
    'A86': 0, 'A57': 1, 'A79': 2, 'A82': 3, 'A42': 4, 'A31': 5, // Amethysts
    'E17': 6, 'E43': 7, 'E21': 8, 'E29': 9, 'E91': 10, 'E87': 11, // Emeralds
    'S22': 12, 'S75': 13, 'S63': 14, 'S09': 15, 'S39': 16, 'S36': 17, // Sapphires
  };

  final TextEditingController _codeController = TextEditingController();
  UserProfile? _userProfile;

  void _unlockItemBox(String input) async {
    if (input.trim().toUpperCase() == "K22") {
      setState(() {
        _showBoxUnlocked = true;
      });
      await _saveData(); // <--- ADD THIS
      _keyController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Key Code"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _importKeyImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (result != null && result.files.single.name == "ItemBoxKeyK22.png") {
        setState(() {
          _showBoxUnlocked = true;
          _keyController.clear(); // Clear the key controller when the image is imported
        });
    } else if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Key Image"), backgroundColor: Colors.red),
      );
    }
  }
  
  // 3. Logic: Manual Code Entry
  void _unlockGemByCode() async {
    final String input = _codeController.text.trim().toUpperCase();

    if (_gemCodes.containsKey(input)) {
      final idx = _gemCodes[input]!;
      bool newlyUnlocked = false;
      setState(() {
        if (!_gemData[idx]) {
          _gemData[idx] = true;
          newlyUnlocked = true;
        }
      });

      if (newlyUnlocked) {
        // Award XP for unlocking a gem
        if (_userProfile == null) {
          _userProfile = await UserProfile.load();
        }
        if (_userProfile != null) {
          _userProfile!.addXp(150);
          await _userProfile!.save();
        }
      }

      await _saveData();
      _codeController.clear();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid Code"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleBoxUnlock() async {
    setState(() {
      _isBoxOpening = true; // Switches itembox.png to itemboxopen.png
    });

    // Wait for 1.2 seconds to show the open box state
    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() {
      _isLocked = false; // Fades out the overlay and shows gems
    });
    await _saveData(); // <--- ADD THIS
  }

  // 4. Logic: Multi-Import from PNG Filenames
  Future<void> _importFromImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (result != null) {
      int activatedCount = 0;

      setState(() {
        for (var file in result.files) {
          String fileName = file.name; // e.g., "amethyst1A86.png"
          
          // Logic: Extract 3 characters before the extension (.png)
          if (fileName.length >= 7) {
            String code = fileName.substring(fileName.length - 7, fileName.length - 4).toUpperCase();

            if (_gemCodes.containsKey(code)) {
              final idx = _gemCodes[code]!;
              if (!_gemData[idx]) {
                _gemData[idx] = true;
                activatedCount++;
              }
            }
          }
        }
      });

      if (activatedCount > 0) {
        // Award XP for newly unlocked gems
        if (_userProfile == null) {
          _userProfile = await UserProfile.load();
        }
        if (_userProfile != null) {
          _userProfile!.addXp(150 * activatedCount);
          await _userProfile!.save();
        }
      }

      await _saveData();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Unlocked $activatedCount gems from images!")),
      );
      // Notify user of XP earned for unlocking gems
      final int xpEarned = 150 * activatedCount;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You earned $xpEarned XP!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final int crossAxisCount = isLandscape ? 6 : 3;

    return Scaffold(
      appBar: AppBar(
        // 1. Home button on the far left
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.pop(context); // This takes you back to the Home Screen
          },
        ),
        title: _isEditingTitle
          ? TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              autofocus: true,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white : Colors.black87,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: "Enter title...",
                hintStyle: TextStyle(
                  color: widget.isDarkMode ? Colors.white54 : Colors.black45,
                ),
              ),
              onSubmitted: (value) async {
                setState(() => _isEditingTitle = false);
                await _saveData(); // <--- ADD THIS
              },
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingTitle = true;
                });
                _titleFocusNode.requestFocus();
              },
              child: Text(_titleController.text),
            ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // 2. Action buttons on the right (wrapped with Center for consistent vertical alignment)
        actions: [
          Center(child: syncAppBarAction(context, widget.isDarkMode)),
          Center(
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showAddMenu(context),
            ),
          ),
          Center(
            child: IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsMenu,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. The Background Image (Always visible)
          Positioned.fill(
            child: Image.asset('assets/felt.png', fit: BoxFit.cover),
          ),
          
          // 2. The Gem Grid (Only interactive/visible when NOT locked)
          if (!_isLocked)
            SafeArea(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: _gemData.length,
                itemBuilder: (context, index) {
                   // ... (Keep your existing grid builder logic here)
                   int slotNum = (index % 6) + 1;
                   String gemType = index < 6 ? 'amethyst' : (index < 12 ? 'emerald' : 'sapphire');
                   int gemNum = (index % 6) + 1;
                   return AnimatedSwitcher(
                     duration: const Duration(milliseconds: 300),
                     child: Image.asset(
                       _gemData[index] ? 'assets/$gemType$gemNum.png' : 'assets/gemslot$slotNum.png',
                       key: ValueKey('${_gemData[index]}_$index'),
                       fit: BoxFit.contain,
                     ),
                   );
                 },
              ),
            ),

          // 3. THE LOCK OVERLAY
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: _isLocked 
              ? Container(
                  key: const ValueKey("overlay"),
                  color: Colors.black.withValues(alpha: 0.85),
                  width: double.infinity,
                  height: double.infinity,
                  child: _showBoxUnlocked ? _buildUnlockedState() : _buildLockedState(),
                )
              : const SizedBox.shrink(), // Disappears when unlocked
          ),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the menu to move up when keyboard appears
      backgroundColor: const Color(0xFF2A2A2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: "Input code",
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _unlockGemByCode(), 
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: _unlockGemByCode,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Import from png"),
                  onPressed: _importFromImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9A00FE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // --- NEW DISCLAIMER TEXT ---
              const SizedBox(height: 8), // Small gap below the button
              const Text(
                "May not work if file name changes",
                style: TextStyle(
                  color: Colors.white54, // Dimmed color so it's not distracting
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              // ---------------------------

              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
    );
  }
  void _showSettingsMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Settings",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dark Mode",
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                ),
                Switch(
                  value: widget.isDarkMode,
                  onChanged: (value) {
                    widget.onThemeChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _showResetConfirmation();
                },
                child: const Text("Reset item box"),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: Text(
            "Are you absolutely sure?",
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
          ),
          content: Text(
            "You can import your items again later using the codes or item card images.",
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9A00FE),
                foregroundColor: Colors.white,
              ),
              onPressed: _resetInventory,
              child: const Text("Reset"),
            ),
          ],
        );
      },
    );
  }
  void _resetInventory() async {
    setState(() {
      // Sets all 18 slots back to false (empty)
      for (int i = 0; i < _gemData.length; i++) {
        _gemData[i] = false;
      }
    });
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gem_data', jsonEncode(_gemData));
    
    // Close the dialog and the menu
    Navigator.of(context).pop(); // Closes the "Are you sure" dialog
    Navigator.of(context).pop(); // Closes the Settings menu
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item box reset successfully")),
    );
  }
  // THE INITIAL MENU
  Widget _buildLockedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Your Item Box!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Image.asset('assets/itemboxkey.png', height: 100),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          child: Text(
            "Enter the item box key code to unlock or upload the item box key card!",
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 50),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keyController,
                  decoration: const InputDecoration(hintText: "Enter Code", filled: true, fillColor: Colors.white10),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
                onPressed: () => _unlockItemBox(_keyController.text),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _importKeyImage,
          icon: const Icon(Icons.upload_file),
          label: const Text("Upload Image"),
        ),
      ],
    );
  }

  Widget _buildUnlockedState() {
    return Stack(
      children: [
        // 1. Instructions at the top
        const Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: 60),
            child: Text(
              "Drag and hold the key onto the box",
              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white70),
            ),
          ),
        ),

        // 2. The Box (The Target)
        Center(
          child: DragTarget<String>(
            onWillAcceptWithDetails: (details) => details.data == "key",
            onAcceptWithDetails: (details) => _handleBoxUnlock(),
            builder: (context, candidateData, rejectedData) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  _isBoxOpening ? 'assets/itemboxopen.png' : 'assets/itembox.png',
                  key: ValueKey(_isBoxOpening),
                  width: 300,
                ),
              );
            },
          ),
        ),

        // 3. The Key (The Draggable)
        if (!_isBoxOpening)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60),
              child: Draggable<String>(
                data: "key",
                // What the user drags
                feedback: Image.asset('assets/itemboxkey.png', height: 100, opacity: const AlwaysStoppedAnimation(0.8)),
                // What stays behind while dragging (nothing)
                childWhenDragging: Opacity(opacity: 0.3, child: Image.asset('assets/itemboxkey.png', height: 100)),
                // The key in its normal state
                child: Image.asset('assets/itemboxkey.png', height: 100),
              ),
            ),
          ),
      ],
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  Item? _practiceKanji;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _pickRandomPracticeKanji();
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    setState(() {
      _userProfile = profile;
    });
  }

  // Picks a fresh random single-character kanji to display as a tracing
  // prompt on the home screen. Called on load and whenever the user
  // returns to the home screen from another screen.
  void _pickRandomPracticeKanji() {
    final pool = <Item>[];
    for (final set in setsData.values) {
      for (final item in set.items) {
        if (item.itemType == 'Kanji' && item.japanese.runes.length == 1) {
          pool.add(item);
        }
      }
    }
    if (pool.isEmpty) return;
    setState(() {
      _practiceKanji = pool[Random().nextInt(pool.length)];
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          "Settings",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Dark Mode",
                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                ),
                Switch(
                  value: widget.isDarkMode,
                  onChanged: (value) {
                    widget.onThemeChanged(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _exportData();
                },
                child: const Text("Export data"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9A00FE),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _importData();
                },
                child: const Text("Import data"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CloudSyncPage(isDarkMode: widget.isDarkMode)),
                  );
                },
                child: const Text("Cloud sync"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showCreditsDialog();
                },
                child: const Text("Credits & data sources"),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Close",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreditsDialog() {
    Widget source(String title, String detail) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: widget.isDarkMode ? Colors.white : Colors.black87)),
          Text(detail, style: TextStyle(fontSize: 13, color: widget.isDarkMode ? Colors.white70 : Colors.black54)),
        ],
      ),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text("Credits & Data Sources", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                source(
                  "JMdict / JMnedict",
                  "Japanese vocabulary, place name, and personal name dictionary data from the Electronic "
                      "Dictionary Research and Development Group (EDRDG) at Monash University, licensed CC BY-SA 4.0.",
                ),
                source(
                  "JLPT N1 word lists",
                  "Compiled by Jonathan Waller (tanos.co.uk) from past exam papers, licensed CC BY.",
                ),
                source(
                  "Tatoeba",
                  "Example sentences, each individually credited to its contributor where shown, licensed CC BY.",
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final jsonString = await buildExportJson();

      final safeTs = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('.', '');
      final fileName = 'kanji_athletes_export_$safeTs.json';
      if (kIsWeb) {
        await downloadString(fileName, jsonString);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloaded export as $fileName')));
      } else {
        // Primary: write to app documents (private)
        final dir = await getApplicationDocumentsDirectory();
        final file = File(path.join(dir.path, fileName));
        await file.writeAsString(jsonString);

        // Secondary: try to write a copy to a public Downloads folder so users can find it
        String? publicPath;
        try {
          // Common public download locations. Prefer Android external storage path.
          final candidates = [
            '/sdcard/Download',
            '/sdcard/Downloads',
            '${dir.path}/../..', // fallback attempt
          ];
          for (final p in candidates) {
            try {
              final testDir = Directory(p);
              if (!await testDir.exists()) continue;
              final outFile = File(path.join(p, fileName));
              await outFile.writeAsString(jsonString);
              publicPath = outFile.path;
              break;
            } catch (_) {
              // ignore candidate
            }
          }
        } catch (_) {
          // ignore
        }

        if (publicPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported data to $publicPath')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported data to ${file.path}')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text('Import data', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text('Importing will REPLACE your current study decks, reading texts, unlocked gems, and dictionary sets/items. Continue?', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9A00FE)), onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null) return; // user cancelled

      final picked = result.files.single;
      final String? filePath = !kIsWeb ? picked.path : null;
      String content;
      if (filePath == null) {
        // On web, FilePicker provides file bytes instead of a filesystem path.
        if (picked.bytes != null) {
          content = utf8.decode(picked.bytes!);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not read selected file')));
          return;
        }
      } else {
        final file = File(filePath);
        content = await file.readAsString();
      }
      await applyImportedJson(content);
      _userProfile = await UserProfile.load();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SafeArea(
            child: SingleChildScrollView(
              child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => StatsScreen(isDarkMode: widget.isDarkMode)),
                              );
                              _pickRandomPracticeKanji();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bar_chart, size: 32, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                const SizedBox(height: 2),
                                Text(
                                  "Stats",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 8, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          await precacheImage(const AssetImage('assets/sapphire6S36.png'), context);
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
                                      child: Image.asset('assets/sapphire6S36.png', fit: BoxFit.contain),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.download),
                                      label: const Text('Download'),
                                      onPressed: () async {
                                        try {
                                          final bd = await rootBundle.load('assets/sapphire6S36.png');
                                          final bytes = bd.buffer.asUint8List();
                                          final dir = await getApplicationDocumentsDirectory();
                                          final filePath = path.join(dir.path, 'sapphire6S36.png');
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
                                        final uri = Uri.parse('https://drive.google.com/file/d/1mjrRLl-mDckxOBhFuQBpGkTcJt1XuKnU/view?usp=sharing');
                                        try {
                                          if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                          }
                                        } catch (_) {
                                          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                            ),
                          );
                        },
                        child: Text(
                          "Welcome Home",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600 ? 22 : 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              _showSettingsDialog();
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.settings, size: 32, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                const SizedBox(height: 2),
                                Text(
                                  "Settings",
                                  style: TextStyle(fontSize: 8, color: widget.isDarkMode ? Colors.white : Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // XP/Level/Progress bar at the top
                  if (_userProfile != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Level ${_userProfile!.level}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'XP: ${_userProfile!.xp} / ${UserProfile.xpForLevel(_userProfile!.level)}',
                          style: TextStyle(fontSize: 18, color: widget.isDarkMode ? Colors.white : Colors.black),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                          tooltip: 'About XP & Levels',
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                                title: Text(
                                  "About XP & Levels",
                                  style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "You earn XP by completing tasks. Each level requires more XP than the last. Here are the XP requirements for each level range:",
                                        style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                                      ),
                                      const SizedBox(height: 16),
                                      Text("Level 1: 100 XP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                                      const SizedBox(height: 4),
                                      Text("Level 2: 150 XP", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      Text("Levels 3 - 5: 250 XP each", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      Text("Levels 6 - 10: 500 XP each", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      Text("Levels 11 - 25: 750 XP each", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      Text("Levels 26 - 49: 1000 XP each", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      Text("Levels 50 - 74: 1250 XP each", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      Text("Levels 75 - 99: 1500 XP each", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      Text("Level 100+: 1500 XP each", style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Keep completing tasks to level up!",
                                        style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                                ),
                                actionsPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                                actions: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: TextButton(
                                          onPressed: () async {
                                            await precacheImage(const AssetImage('assets/sapphire2S75.png'), context);
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
                                                        child: Image.asset('assets/sapphire2S75.png', fit: BoxFit.contain),
                                                      ),
                                                      const SizedBox(height: 16),
                                                      ElevatedButton.icon(
                                                        icon: const Icon(Icons.download),
                                                        label: const Text('Download'),
                                                        onPressed: () async {
                                                          try {
                                                            final bd = await rootBundle.load('assets/sapphire2S75.png');
                                                            final bytes = bd.buffer.asUint8List();
                                                            final dir = await getApplicationDocumentsDirectory();
                                                            final filePath = path.join(dir.path, 'sapphire2S75.png');
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
                                                          final uri = Uri.parse('https://drive.google.com/file/d/1dhJQWKENpIoMlLeseM6xusnhjbHyljRU/view?usp=sharing');
                                                          try {
                                                            if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                                            }
                                                          } catch (_) {
                                                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open link')));
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                actionsAlignment: MainAxisAlignment.center,
                                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                                              ),
                                            );
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.all(6),
                                            minimumSize: const Size(36, 36),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Text(
                                            '?',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                        child: TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          child: Text(
                                            "Close",
                                            style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
                      child: LinearProgressIndicator(
                        value: UserProfile.xpForLevel(_userProfile!.level) > 0 ? _userProfile!.xp / UserProfile.xpForLevel(_userProfile!.level) : 0.0,
                        minHeight: 12,
                        backgroundColor: widget.isDarkMode ? Colors.white12 : Colors.black12,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9A00FE)),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                // Dictionary section
                Padding(
                  padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Dictionary',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          // IntrinsicHeight + stretch makes all three buttons
                          // match the tallest one's height - without it, a
                          // subtle per-glyph font-metric difference between
                          // the Japanese labels (seen most on mobile/web)
                          // could make one button render taller than its
                          // siblings despite identical padding/text structure.
                          child: IntrinsicHeight(
                            child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          // Complete Dictionary button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DictionaryScreen(
                                        isDarkMode: widget.isDarkMode,
                                        onThemeChanged: widget.onThemeChanged,
                                      ),
                                    ),
                                  );
                                  _pickRandomPracticeKanji();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9A00FE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '辞書',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Complete\nDictionary',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Kanji Dictionary button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DictionaryScreen(
                                        isDarkMode: widget.isDarkMode,
                                        onThemeChanged: widget.onThemeChanged,
                                        initialFilters: {'Kanji'},
                                      ),
                                    ),
                                  );
                                  _pickRandomPracticeKanji();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9A00FE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '漢字',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Kanji\nDictionary',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Vocab Dictionary button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DictionaryScreen(
                                        isDarkMode: widget.isDarkMode,
                                        onThemeChanged: widget.onThemeChanged,
                                        initialFilters: {'Vocabulary'},
                                      ),
                                    ),
                                  );
                                  _pickRandomPracticeKanji();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9A00FE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '単語',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Vocab\nDictionary',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                        ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Practice: random kanji tracing box
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_practiceKanji != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Draw this kanji: ${_practiceKanji!.japanese}',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                              tooltip: 'New random kanji',
                              onPressed: _pickRandomPracticeKanji,
                            ),
                          ],
                        ),
                      if (_practiceKanji != null && _practiceKanji!.translation.isNotEmpty)
                        Text(
                          _practiceKanji!.translation,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                      if (_practiceKanji != null) const SizedBox(height: 12),
                      if (_practiceKanji != null)
                        WritingPracticeCanvas(
                          key: ValueKey(_practiceKanji!.japanese),
                          kanjiVGCodes: _practiceKanji!.kanjiVGCode != null ? [_practiceKanji!.kanjiVGCode!] : const [],
                          isDarkMode: widget.isDarkMode,
                          kanji: _practiceKanji!.japanese,
                          translation: _practiceKanji!.translation,
                          scale: 0.6,
                          hideAnswerText: true,
                          showHintByDefault: true,
                          compactStrokeControls: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),

              ],
            ),
          ),

          // Bottom Button Row with background barrier
          Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Spreads them out
                children: [
                // 1. Far Left: Library Button
                _buildHomeButton(
                  context,
                  image: 'assets/bookshelf.png',
                  label: "Library",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LibraryScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                    );
                    await _loadUserProfile();
                    _pickRandomPracticeKanji();
                  },
                ),

                // 2. Study Button
                _buildHomeButton(
                  context,
                  image: 'assets/bookopen.png',
                  label: "Study",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudyScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                    );
                    await _loadUserProfile();
                    _pickRandomPracticeKanji();
                  },
                ),

                // 3. Far Right: Item Box Button
                _buildHomeButton(
                  context,
                  image: 'assets/itembox.png',
                  label: "Item Box",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => InventoryScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                    );
                    await _loadUserProfile();
                    _pickRandomPracticeKanji();
                  },
                ),
              ],
            ),
            ),
        ],
      ),
    );
  }

  // HELPER METHOD: Keeps all buttons looking exactly the same
  Widget _buildHomeButton(BuildContext context, 
      {required String image, required String label, required VoidCallback onTap}) {
    return _HomeButton(
      image: image,
      label: label,
      onTap: onTap,
    );
  }
}

// Home button with hover effect
class _HomeButton extends StatefulWidget {
  final String image;
  final String label;
  final VoidCallback onTap;

  const _HomeButton({
    required this.image,
    required this.label,
    required this.onTap,
  });

  @override
  State<_HomeButton> createState() => _HomeButtonState();
}

class _HomeButtonState extends State<_HomeButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Get the current theme mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 100,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isHovering ? const Color(0xFF9A00FE) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(widget.image, height: 50, fit: BoxFit.contain),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isHovering ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
