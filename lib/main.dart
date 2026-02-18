import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'sets_data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'todo_settings.dart';
import 'library.dart';
import 'arcade.dart';
import 'dictionary.dart';
import 'set_preferences.dart';
import 'user_profile.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
// Application entrypoint
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
    UserProfile? _userProfile;
  List<TodoItem> todoItems = [];
  Map<int, bool> completedStatus = {};
  Timer? _midnightTimer;
  int? expandedIndex; // Track which item is expanded

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTasks();
    _loadUserProfile();
    scheduleMidnightTimer();
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfile.load();
    setState(() {
      _userProfile = profile;
    });
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void scheduleMidnightTimer() {
    // Cancel any existing timer
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final duration = nextMidnight.difference(now);
    _midnightTimer = Timer(duration, () async {
      await _loadTasks();
      // Reschedule for the following midnight
      scheduleMidnightTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('saved_todo_tasks');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      // Compute today's stamps and track whether anything changed; these
      // variables live outside setState so they can be used after it.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final String todayStamp = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final String? lastLoadedStamp = prefs.getString('todo_last_load_date');
      bool changed = false;
        setState(() {
        todoItems = decodedData.map((item) => TodoItem.fromMap(item)).toList();
        // Clear and reinitialize completion status
        completedStatus.clear();
        for (int i = 0; i < todoItems.length; i++) {
          // prefer explicit flag
          completedStatus[i] = todoItems[i].isCompleted;

          // If the task was completed on an earlier day, mark it no longer displayed
          final cd = todoItems[i].completedDate;
          if (cd != null && cd.isNotEmpty) {
            try {
              final parts = cd.split('-');
              if (parts.length >= 3) {
                final y = int.parse(parts[0]);
                final m = int.parse(parts[1]);
                final d = int.parse(parts[2]);
                final completedDay = DateTime(y, m, d);
                        if (completedDay.isBefore(today)) {
                          // Increment occurrence number when completion was from a prior day
                          todoItems[i].occurrenceNumber = (todoItems[i].occurrenceNumber ?? 0) + 1;
                          changed = true;

                          // Compute nextDisplay depending on repeat settings
                          String? computedNextStamp;
                          if (todoItems[i].repeat) {
                            final int daysToAdd = todoItems[i].repeatDays;
                            final DateTime nextDate = completedDay.add(Duration(days: daysToAdd));
                            computedNextStamp = '${nextDate.year.toString().padLeft(4, '0')}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}';

                            if (todoItems[i].repeatForever) {
                              // always schedule nextDisplay
                            } else if (todoItems[i].repeatTimes != null) {
                              // Only schedule next display if we haven't exceeded repeatTimes
                              if (todoItems[i].occurrenceNumber > todoItems[i].repeatTimes!) {
                                computedNextStamp = null;
                              }
                            }
                          } else {
                            computedNextStamp = null;
                          }

                            // Set nextDisplay if changed
                          if (todoItems[i].nextDisplay != computedNextStamp) {
                            todoItems[i].nextDisplay = computedNextStamp;
                            changed = true;
                          }

                          // If nextDisplay equals today, make it visible again; otherwise hide
                          if (computedNextStamp != null && computedNextStamp == todayStamp) {
                            if (!todoItems[i].isDisplayed) {
                              todoItems[i].isDisplayed = true;
                              changed = true;
                            }
                          } else {
                            if (todoItems[i].isDisplayed) {
                              todoItems[i].isDisplayed = false;
                              changed = true;
                            }
                          }

                          // Clear completedDate after scheduling so this won't trigger repeatedly
                          if (todoItems[i].completedDate != null) {
                            todoItems[i].completedDate = null;
                            changed = true;
                          }
                        }
              }
            } catch (_) {
              // ignore parse errors
            }
          }

          // Regardless of completedDate, evaluate `nextDisplay` daily and update visibility
          // Only re-show when nextDisplay equals today; otherwise leave isDisplayed unchanged
          final nd = todoItems[i].nextDisplay;
          if (nd != null && nd.isNotEmpty) {
            if (nd == todayStamp) {
              if (!todoItems[i].isDisplayed) {
                todoItems[i].isDisplayed = true;
                changed = true;
              }
            }
          }
        
          // Midnight override handling: if the item is currently marked completed
          // and has an overrideDate, set nextDisplay to the override (or today
          // if the override is earlier than today), then clear overrideDate.
          if (todoItems[i].isCompleted && todoItems[i].overrideDate != null && todoItems[i].overrideDate!.isNotEmpty) {
            try {
              final parts = todoItems[i].overrideDate!.split('-');
              if (parts.length >= 3) {
                final y = int.parse(parts[0]);
                final m = int.parse(parts[1]);
                final d = int.parse(parts[2]);
                final overrideDt = DateTime(y, m, d);
                if (overrideDt.isBefore(today)) {
                  // If override is before today, schedule for today
                  todoItems[i].nextDisplay = todayStamp;
                } else {
                  // Preserve the override date
                  todoItems[i].nextDisplay = '${overrideDt.year.toString().padLeft(4, '0')}-${overrideDt.month.toString().padLeft(2, '0')}-${overrideDt.day.toString().padLeft(2, '0')}';
                }
                todoItems[i].overrideDate = null;
                changed = true;
              }
            } catch (_) {
              // ignore malformed overrideDate
              todoItems[i].overrideDate = null;
              changed = true;
            }
          }
        }
        // If the stored last-load date is not today, clear per-day completion flags.
        if (lastLoadedStamp != todayStamp) {
          for (int i = 0; i < todoItems.length; i++) {
            if (todoItems[i].isCompleted) {
              todoItems[i].isCompleted = false;
              completedStatus[i] = false;
              changed = true;
            }
            if (todoItems[i].completedDate != null && todoItems[i].completedDate!.isNotEmpty) {
              todoItems[i].completedDate = null;
              changed = true;
            }
          }
        }

        // Persist changes if any task changed (actual write moved outside setState)
      });

      if (changed) {
        await prefs.setString('saved_todo_tasks', jsonEncode(todoItems.map((t) => t.toMap()).toList()));
      }

      // Remember the date we last processed tasks so we only clear daily flags once
      await prefs.setString('todo_last_load_date', todayStamp);
    } else {
      // First run: create a welcome preset so the user sees the 90 day challenge
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final String todayStamp = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final welcome = TodoItem(
        taskName: "Welcome to the 90 day challenge!",
        repeat: false,
        notify: true,
        notificationTime: const TimeOfDay(hour: 17, minute: 0),
        notes: "Welcome! Start your 90 day challenge here!",
        links: [
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ffc5a70ba2a240a89ecee1596ebbf5fd",
        ],
        imagePath: "90dayvids.png",
      );

      final videos = TodoItem(
        taskName: "90 day challenge videos",
        repeat: true,
        repeatDays: 1,
        repeatTimes: 90,
        notify: true,
        notificationTime: const TimeOfDay(hour: 17, minute: 0),
        notes: "Complete today's 90 day challenge video on Skool!",
        imagePath: "90dayvids.png",
        links: [
          "https://kleki.com",
        ],
        variableNames: List.generate(90, (i) => "Day ${i + 1}"),
        variableLinks: [
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=dc1983fa0c594c8b8d310bf1a75bf5de",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8f9c48f08cda415d82996e69efda1d0f",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e1e8d589c06540fd99a3a50db3738fd6",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ebeffbebd01e4116a21e6b5b2ea8ef0d",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=169f3d8f669a48b1a1e5b1e4168ca95f",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e366d0cef7b74dad826aa138d26014f8",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d12d2c1144134d8ba6aef234670721f9",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=2eb52014c0dd47c292e0fc1bb19dbab2",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d296c2c6cdf74eb9baa530a96fbfd77d",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cc20f1ed176540d9829c0d32c69c487c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ebc375fcadbf4a99a627a3cdaeb33d64",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=12cfb35150894154bf2c79a07aeb0cb2",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1e0f8601ae4a4d5eb592bdb2ed53480c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=fb88e7b017494fa4b34c53d2a5695912",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=4fad74c917d14d139452fac87909021a",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=c33e514710c345b68b9a5335ad67c002",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f8b4f6a3a32148569159a3a8673b76e3",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=7329a371b75d404eb98d012c0a6d9998",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=005ab8026bcb46288ee35d1af4da18b0",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=076f5b962a554e35bcbe6fe0fd1ca7ce",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d039a5eb9c1d462ba0111fa29b8b748c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=bee1546fe2ba4a9697fb9e476820b601",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8774d680b93643ec82bee40ff68e9395",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=05510bfc251c4aa9b8b98ee2bc19f385",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a3ca1aa3c47e4e779b38a64146effdf7",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=3c6acd5f9f3e4b00829813c6171e5d5d",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1ddd5d6d2ee947ba9aa2b5f51da5b30d",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cd869470a2f8405897f2ee57184e7dc0",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cd996fbe538e4c9f9eec446b27d658aa",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d0321fbd0579459a8e058e5105c79fb1",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=abb2cf072e9f4505b4c8f02da7dac4e1",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=960cae4e500f4938ae16b284e64c2598",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=aa92a28b368e452ba35fca28fe1b7b49",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f2e0b670b27248ac9873ada7e0bc3381",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=58f78c0f51614607ad6ce1b1c43b000c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=925f7f128ac04889900fb5f789603505",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a8d6f249eb264010a7cfefde723db273",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1025455823074d97b09156b829ab1da3",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=fc625bc7d2b94ec6bfdd4a513a07d346",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a950189af7af4416a57329d7bc378ab8",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=58690cccbfb74145921393ff50032f85",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=00d3f6645ec943d2b173a11574748b95",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1dad046bd8d14dad95bbafaf751e6fe9",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f7250f3c26d0446ab7849800e517ae27",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=9158b2e9181f42f4b42f9f313b69f280",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=986fa414d9074a2ca8167e395dfb05a4",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=a481bc086c3e4ed195368c2ff78b15ec",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1767c09be4634da48bf4d85cbc38144a",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=155e6773aff84cbf95ec098da3b3e643",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=b5b9cf86be1d433686b8f82146f2d4cf",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8c0c76fc1ad14b0ba5b476305634a3c9",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=738a6396790243748b43be21ef0550df",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8a282e2eb6b84dd3836e12ced645bb9d",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ed37b00fb5194808a0720b7820c670e3",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=02277fbba2574c31beadb1274a0fa477",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=71109e36452b4065a476f5bc96e671b2",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=38a33e7ab72148a8a4d5bcaf8703697e",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=0d9664b5a37d48eeb64f06c4166e2190",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1d22ac4463c94c23a91f1f4770e3fb4a",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cb8934da44914c95bb5c400c38d3b7c9",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=99c39a3354d047e3ad4720a3356867ea",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=caff3853f86d47148825334de63ba48a",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=9973795f3c0d43afb942d397b8f8e583",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=deceb753e62a4fe0b20b68077fd35a7c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d75810999cb344cc8d4984990314a086",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=0574496278aa4206922e5a2cadb7158c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=70fcd1d6765f47c5823764fffe0faa39",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e3b9fdf842f345a98cc0cc06e92e6299",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=8d340493ebef4779887d14b205ea2fbe",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=29148a6d776644438198b392bc2fa3fd",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=07982128b1af406e8c8fb6d682d29421",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=19619fbcee144a60bfb515b3b8317c11",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=e8a06520029b4d2fa22ecf2ea54a0af9",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=f40803ca76f2417ea872f182073fb6de",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=2e43336e1ba14f7e97d7bc4f0498a5b5",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=4d2389a5e30947f6be210d6fe3d15006",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=03a8e7f26125423286f3b5391f21746d",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d6dbe119be624f73b89cc562182cdff4",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=6ed52c9cb20b42df902a8df8dceabc0c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=cdd10084c01547ada31e8dda8ceb4760",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d8ca2c02609b413b9c2b2683235b0b5c",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=1eebc6772cd14746a06e6a6e72364ed1",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=3bf0a215a8d640f9845c474227b81097",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=d89b5e7d7c1b4b99bae44048b398cd51",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=833c8381e9d24539a285b14ca575f3e2",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ce37e66682a64f4183529a25750843dd",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=6d25c22ef8664ce4a6512914de1b580d",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=fb844b9b834c443ca59e33b45a355fab",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=34bd2cd9c7764757ae74842789dc001b",
          "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=5cb1c7a7722e4342b7928ea084ddb738",
        ],
      );

      final flashcards = TodoItem(
        taskName: "90 day challenge flashcards",
        repeat: true,
        repeatDays: 1,
        repeatTimes: 90,
        notify: true,
        notificationTime: const TimeOfDay(hour: 17, minute: 0),
        notes: "Complete your flashcards!",
        imagePath: "90daycards.png",
        links: [
          "https://knowt.com/flashcards/d9956ac8-f910-4ffe-a8a9-3c2cf12d2cd7",
          "https://knowt.com/flashcards/baa1ecd8-337d-4aa9-9114-2cea181ca8a9",
          "https://knowt.com/flashcards/1aba42b9-b53f-4290-a465-2b443aa0ebcf?isNew=false",
          "https://knowt.com/flashcards/17b371d9-09e9-450e-a55e-84bba3ce5352"
        ],
        variableNames: List.generate(90, (i) => "Day ${i + 1}"),
      );

      setState(() {
        todoItems = [welcome, videos, flashcards];
        completedStatus.clear();
      });

      // Persist the initial welcome and 90-day preset items and today's load date
      await prefs.setString('saved_todo_tasks', jsonEncode(todoItems.map((t) => t.toMap()).toList()));
      await prefs.setString('todo_last_load_date', todayStamp);
    }
  }

  Future<void> _toggleTaskCompletion(int index) async {
    final today = DateTime.now();
    final todayStamp = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    setState(() {
      completedStatus[index] = !(completedStatus[index] ?? false);
      // Update the TodoItem's completedDate
      if (completedStatus[index]!) {
        todoItems[index].completedDate = todayStamp;
        todoItems[index].isCompleted = true;
      } else {
        todoItems[index].completedDate = null;
        todoItems[index].isCompleted = false;
      }
    });

    // Update user XP: +50 for completion, -50 for un-completion
    if (_userProfile == null) {
      _userProfile = await UserProfile.load();
    }
    if (_userProfile != null) {
      if (completedStatus[index] == true) {
        _userProfile!.addXp(50);
      } else {
        _userProfile!.removeXp(50);
      }
      await _userProfile!.save();
      setState(() {});
    }

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(todoItems.map((item) => item.toMap()).toList());
    await prefs.setString('saved_todo_tasks', encodedData);
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

  Future<void> _exportData() async {
    try {
      await SetPreferences.loadAllSets();
      final prefs = await SharedPreferences.getInstance();

      final user = await UserProfile.load();
      final String? todoString = prefs.getString('saved_todo_tasks');
      final dynamic todoData = todoString != null ? jsonDecode(todoString) : [];
      final String? gemString = prefs.getString('gem_data');
      final dynamic gemData = gemString != null ? jsonDecode(gemString) : [];

      final Map<String, dynamic> setsMap = {};
      for (var entry in setsData.entries) {
        final key = entry.key;
        final set = entry.value;
        setsMap[key] = {
          'name': set.name,
          'tags': set.tags,
          'displayInDictionary': set.displayInDictionary,
          'setType': set.setType,
          'displayInWritingArcade': set.displayInWritingArcade,
          'displayInReadingArcade': set.displayInReadingArcade,
          'items': set.items.map((item) => {
                'japanese': item.japanese,
                'translation': item.translation,
                'reading': item.reading,
                'strokeOrder': item.strokeOrder,
                'kanjiVGCode': item.kanjiVGCode,
                'itemType': item.itemType,
                'onYomi': item.onYomi,
                'kunYomi': item.kunYomi,
                'naNori': item.naNori,
                'tags': item.tags,
                'notes': item.notes,
                'isStarred': item.isStarred,
              }).toList(),
        };
      }

      final export = {
        'exportedAt': DateTime.now().toIso8601String(),
        'userProfile': {'xp': user.xp, 'level': user.level},
        'todoTasks': todoData,
        'gems': gemData,
        'sets': setsMap,
      };

      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(export);

      final dir = await getApplicationDocumentsDirectory();
      final safeTs = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('.', '');
      final fileName = 'kanji_athletes_export_$safeTs.json';
      final file = File(path.join(dir.path, fileName));
      await file.writeAsString(jsonString);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported data to ${file.path}')));
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
        content: Text('Importing will REPLACE your current saved to-do tasks, unlocked gems, and dictionary sets/items. Continue?', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
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
      final data = jsonDecode(content) as Map<String, dynamic>;

      final prefs = await SharedPreferences.getInstance();

      // User profile
      if (data.containsKey('userProfile')) {
        try {
          final up = data['userProfile'] as Map<String, dynamic>;
          await prefs.setInt('user_xp', (up['xp'] as num?)?.toInt() ?? 0);
          await prefs.setInt('user_level', (up['level'] as num?)?.toInt() ?? 0);
          _userProfile = await UserProfile.load();
        } catch (_) {}
      }

      // To-do tasks
      if (data.containsKey('todoTasks')) {
        await prefs.setString('saved_todo_tasks', jsonEncode(data['todoTasks']));
        await _loadTasks();
      }

      // Gems
      if (data.containsKey('gems')) {
        await prefs.setString('gem_data', jsonEncode(data['gems']));
      }

      // Replace saved sets: remove existing saved set keys
      final keys = prefs.getKeys().toList();
      for (var key in keys) {
        if (key.startsWith('set_') || key.startsWith('practice_set_') || key.startsWith('vocab_set_')) {
          await prefs.remove(key);
        }
      }

      // Sets (dictionary data)
      if (data.containsKey('sets')) {
        final sets = data['sets'] as Map<String, dynamic>;
        for (var entry in sets.entries) {
          final setKey = entry.key;
          try {
            final s = entry.value as Map<String, dynamic>;
            final items = <Item>[];
            if (s.containsKey('items')) {
              for (var it in (s['items'] as List<dynamic>)) {
                try {
                  items.add(Item(
                    japanese: it['japanese'] as String? ?? '',
                    translation: it['translation'] as String? ?? '',
                    strokeOrder: it['strokeOrder'] as String? ?? '',
                    kanjiVGCode: it['kanjiVGCode'] as String?,
                    reading: it['reading'] as String? ?? '',
                    itemType: it['itemType'] as String? ?? 'Kanji',
                    onYomi: it['onYomi'] as String? ?? '',
                    kunYomi: it['kunYomi'] as String? ?? '',
                    naNori: it['naNori'] as String? ?? '',
                    tags: (it['tags'] as List<dynamic>?)?.cast<String>() ?? [],
                    notes: it['notes'] as String? ?? '',
                    isStarred: it['isStarred'] as bool? ?? false,
                  ));
                } catch (_) {}
              }
            }

            final newSet = ItemSet(
              name: s['name'] as String? ?? setKey,
              items: items,
              setType: s['setType'] as String? ?? 'Uncategorised',
              displayInDictionary: s['displayInDictionary'] as bool? ?? true,
              tags: (s['tags'] as List<dynamic>?)?.cast<String>() ?? [],
              displayInWritingArcade: s['displayInWritingArcade'] as bool? ?? false,
              displayInReadingArcade: s['displayInReadingArcade'] as bool? ?? false,
            );

            setsData[setKey] = newSet;
            await SetPreferences.saveSet(setKey, newSet);
          } catch (_) {}
        }
      }

      // Reload saved sets into memory
      await SetPreferences.loadAllSets();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import successful')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  void _editTask(int index) {
    final task = todoItems[index];
    String? editImagePath = task.imagePath;
    TextEditingController editName = TextEditingController(text: task.taskName);
    TextEditingController editNotes = TextEditingController(text: task.notes);
    TextEditingController editDays = TextEditingController(text: task.repeatDays.toString());
    TextEditingController editTimes = TextEditingController(text: task.repeatTimes?.toString() ?? "");
    
    List<TextEditingController> editLinks = task.links.isEmpty 
        ? [TextEditingController()] 
        : task.links.map((link) => TextEditingController(text: link)).toList();

    bool editRepeat = task.repeat;
    bool editForever = task.repeatForever;
    bool editNotify = task.notify;
    TimeOfDay editTime = task.notificationTime;
    bool editResetOccurrence = false;
    String? editPickedNextDisplay;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[100],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit To Do Item",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  Text(
                    "Task Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: editName,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Task Name",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Checkbox(value: editRepeat, onChanged: (val) => setModalState(() => editRepeat = val!)),
                      Text("Repeat", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: editDays,
                              enabled: editRepeat,
                              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Days",
                                hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Days (e.g 1 = everyday)',
                              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: editTimes,
                              enabled: editRepeat && !editForever,
                              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Times",
                                hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Times (e.g 1 = show once)',
                              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(value: editForever, onChanged: editRepeat ? (val) => setModalState(() => editForever = val!) : null),
                      Text("∞", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87)),
                    ],
                  ),

                  Row(
                    children: [
                      Checkbox(value: editNotify, onChanged: (val) => setModalState(() => editNotify = val!)),
                      Text("Notify", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87)),
                      if (editNotify) TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(context: context, initialTime: editTime);
                          if (picked != null) setModalState(() => editTime = picked);
                        },
                        child: Text(editTime.format(context)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Repeat Occurrence",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: editResetOccurrence ? '1' : '${task.occurrenceNumber}',
                                  style: TextStyle(color: editResetOccurrence ? Colors.red : (widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                ),
                                TextSpan(
                                  text: '/${task.repeatTimes ?? '∞'}',
                                  style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => setModalState(() => editResetOccurrence = !editResetOccurrence),
                        child: Text(editResetOccurrence ? 'Will Reset' : 'Reset', style: TextStyle(color: editResetOccurrence ? Colors.redAccent : (widget.isDarkMode ? Colors.white70 : Colors.black87))),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Notes",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: editNotes,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: "Notes",
                      hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "Next display date",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Builder(
                        builder: (context) {
                          String displayText = 'None';
                          final today = DateTime.now();
                          final todayDay = DateTime(today.year, today.month, today.day);
                          if (task.overrideDate != null && task.overrideDate!.isNotEmpty) {
                            displayText = task.overrideDate!;
                          } else if (task.isDisplayed) {
                            final next = todayDay.add(Duration(days: task.repeatDays));
                            displayText = '${next.year.toString().padLeft(4, '0')}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
                          } else {
                            if (!task.repeat) {
                              displayText = 'None';
                            } else {
                              final nd = task.nextDisplay;
                              if (nd != null && nd.isNotEmpty) {
                                try {
                                  final parts = nd.split('-');
                                  if (parts.length >= 3) {
                                    final y = int.parse(parts[0]);
                                    final m = int.parse(parts[1]);
                                    final d = int.parse(parts[2]);
                                    final ndDate = DateTime(y, m, d);
                                    if (!ndDate.isBefore(todayDay)) {
                                      displayText = nd;
                                    }
                                  }
                                } catch (_) {
                                  displayText = 'None';
                                }
                              }
                            }
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayText,
                                    style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                                  ),
                                  const SizedBox(width: 8),
                                  if (task.isDisplayed) ...[
                                    if (!task.isCompleted)
                                      Text(
                                        '(If you complete it today)',
                                        style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Currently displaying',
                                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Show Set Next Display date button when repeat is enabled and there are remaining repeats
                              if (editRepeat)
                                Builder(builder: (ctx) {
                                  final currentOcc = editResetOccurrence ? 1 : task.occurrenceNumber;
                                  final parsedTimes = editForever ? null : (int.tryParse(editTimes.text) ?? task.repeatTimes);
                                  final showPicker = parsedTimes == null || (parsedTimes > (currentOcc ?? 0));
                                  if (!showPicker) return const SizedBox.shrink();
                                  return Row(children: [
                                    ElevatedButton(
                                      onPressed: () async {
                                        final now = DateTime.now();
                                        final picked = await showDatePicker(
                                          context: ctx,
                                          initialDate: now,
                                          firstDate: now,
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            editPickedNextDisplay = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                                          });
                                        }
                                      },
                                      child: Text(editPickedNextDisplay == null ? 'Set Next Display date' : 'Change Next Display'),
                                    ),
                                    const SizedBox(width: 8),
                                    if (editPickedNextDisplay != null) Text(editPickedNextDisplay!, style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                                  ]);
                                }),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Task Image",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  StatefulBuilder(
                    builder: (context, setImageState) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (editImagePath != null && editImagePath!.isNotEmpty) ...[
                            Row(
                              children: [
                                Container(
                                  width: 60, height: 60,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white24),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: editImagePath!.startsWith('data:')
                                        ? Image.memory(base64Decode(editImagePath!.split(',').last), fit: BoxFit.cover)
                                        : (editImagePath!.contains('/') || editImagePath!.contains('\\')
                                            ? Image.file(File(editImagePath!), fit: BoxFit.cover)
                                            : Image.asset('assets/$editImagePath', fit: BoxFit.cover)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                TextButton(
                                  onPressed: () => setImageState(() => editImagePath = null),
                                  child: const Text("Remove Image", style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          ] else ...[
                            ElevatedButton.icon(
                              onPressed: () async {
                                String? newPath = await _pickImageFromComputer();
                                if (newPath != null) {
                                  setImageState(() => editImagePath = newPath);
                                }
                              },
                              icon: const Icon(Icons.upload),
                              label: const Text("Choose Image from Computer"),
                            ),
                          ],
                        ],
                      );
                    }
                  ),

                  const SizedBox(height: 20),
                  Text(
                    "Links",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...editLinks.asMap().entries.map((entry) => Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: entry.value,
                          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                          decoration: InputDecoration(
                            hintText: "URL",
                            hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                          ),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setModalState(() => editLinks.removeAt(entry.key))),
                    ],
                  )),
                  TextButton.icon(onPressed: () => setModalState(() => editLinks.add(TextEditingController())), icon: const Icon(Icons.add), label: const Text("Add Link")),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context), 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9A00FE),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Cancel")
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9A00FE),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          setState(() {
                            final updated = TodoItem(
                              taskName: editName.text,
                              repeat: editRepeat,
                              repeatDays: int.tryParse(editDays.text) ?? 1,
                              repeatTimes: editForever ? null : int.tryParse(editTimes.text),
                              repeatForever: editForever,
                              notify: editNotify,
                              notificationTime: editTime,
                              notes: editNotes.text,
                              imagePath: editImagePath,
                              links: editLinks.map((c) => c.text).where((t) => t.isNotEmpty).toList(),
                              variableNames: task.variableNames,
                              variableLinks: task.variableLinks,
                              createdAt: task.createdAt,
                              occurrenceNumber: editResetOccurrence ? 1 : task.occurrenceNumber,
                              completedDate: task.completedDate,
                              isCompleted: task.isCompleted,
                              isDisplayed: task.isDisplayed,
                              nextDisplay: task.nextDisplay,
                            );

                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final String todayStamp = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                            if (updated.repeat) {
                              final bool withinTimes = (updated.repeatTimes == null) || (updated.occurrenceNumber <= (updated.repeatTimes ?? 0));
                              final bool nextIsDue = (updated.nextDisplay == null) || (updated.nextDisplay!.compareTo(todayStamp) <= 0);
                              if (withinTimes && nextIsDue) {
                                updated.isDisplayed = true;
                              } else if (!withinTimes) {
                                // Hide if occurrence exceeds repeatTimes
                                updated.isDisplayed = false;
                              }
                            }

                            // If a next display date was picked via the picker, apply it to both nextDisplay and overrideDate
                            if (editPickedNextDisplay != null) {
                              updated.nextDisplay = editPickedNextDisplay;
                              updated.overrideDate = editPickedNextDisplay;
                            }

                            todoItems[index] = updated;
                          });
                          // Save to SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          final String encodedData = jsonEncode(todoItems.map((item) => item.toMap()).toList());
                          await prefs.setString('saved_todo_tasks', encodedData);
                          Navigator.pop(context);
                        }, 
                        child: const Text("Save Changes")
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int index, String taskName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          "Delete Task?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          "Are you sure you want to delete '$taskName'?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9A00FE),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                todoItems.removeAt(index);
                completedStatus.remove(index);
              });
              // Save to SharedPreferences
              final prefs = await SharedPreferences.getInstance();
              final String encodedData = jsonEncode(todoItems.map((item) => item.toMap()).toList());
              await prefs.setString('saved_todo_tasks', encodedData);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<String?> _pickImageFromComputer() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg'],
    );

      if (result != null) {
        final picked = result.files.single;
        if (!kIsWeb && picked.path != null) return picked.path;
        if (picked.bytes != null) {
          final mime = (picked.extension ?? '').toLowerCase() == 'png' ? 'image/png' : 'image/jpeg';
          final b64 = base64Encode(picked.bytes!);
          return 'data:$mime;base64,$b64';
        }
      }
      return null;
  }

  // Collapsed view - shows task name, notes preview, and action buttons
  Widget _buildCollapsedView(TodoItem task, int index, bool isCompleted) {
    return Row(
      children: [
        // Circle Checkbox
        GestureDetector(
          onTap: () => _toggleTaskCompletion(index),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted ? Colors.green : (widget.isDarkMode ? Colors.white54 : Colors.grey),
                width: 2,
              ),
              color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
            ),
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.green)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        
        // Task Text and Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task Name (with variable prefix if present for this occurrence)
              Text(
                (() {
                  String prefix = '';
                  if (task.variableNames.isNotEmpty) {
                    final idx = (task.occurrenceNumber ?? 1) - 1;
                    if (idx >= 0 && idx < task.variableNames.length) {
                      final vn = task.variableNames[idx];
                      if (vn != null && vn.isNotEmpty) prefix = '$vn ';
                    }
                  }
                  return '$prefix${task.taskName}';
                })(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? (widget.isDarkMode ? Colors.white54 : Colors.grey)
                      : (widget.isDarkMode ? Colors.white : Colors.black87),
                  decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              // Notes (1 line only)
              if (task.notes.isNotEmpty)
                Text(
                  task.notes,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted
                        ? (widget.isDarkMode ? Colors.white38 : Colors.grey[600])
                        : (widget.isDarkMode ? Colors.white60 : Colors.grey[700]),
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // Repeat info
              if (task.repeat)
                Text(
                  'Repeat: ${task.repeatTimes != null ? '${task.occurrenceNumber}/${task.repeatTimes}' : '∞'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted
                        ? (widget.isDarkMode ? Colors.white38 : Colors.grey[600])
                        : (widget.isDarkMode ? Colors.white60 : Colors.grey[700]),
                  ),
                ),
            ],
          ),
        ),
        // Expand Button
        GestureDetector(
          onTap: () {
            setState(() {
              expandedIndex = index;
            });
          },
          child: HoverIconButton(
            icon: Icons.expand_more,
            onPressed: () {
              setState(() {
                expandedIndex = index;
              });
            },
            isDarkMode: widget.isDarkMode,
          ),
        ),
        // Edit Button
        GestureDetector(
          onTap: () => _editTask(index),
          child: HoverIconButton(
            icon: Icons.edit,
            onPressed: () => _editTask(index),
            isDarkMode: widget.isDarkMode,
          ),
        ),
        // Delete Button
        GestureDetector(
          onTap: () => _showDeleteConfirmation(index, task.taskName),
          child: HoverIconButton(
            icon: Icons.delete_outline,
            onPressed: () => _showDeleteConfirmation(index, task.taskName),
            isDarkMode: widget.isDarkMode,
          ),
        ),
      ],
    );
  }

  // Expanded view - shows full task details
  Widget _buildExpandedView(TodoItem task, int index, bool isCompleted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Task Name with Checkbox and Action Buttons
        GestureDetector(
          onTap: () {
            setState(() {
              expandedIndex = null;
            });
          },
          child: Row(
            children: [
              // Circle Checkbox
              GestureDetector(
                onTap: () => _toggleTaskCompletion(index),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted ? Colors.green : (widget.isDarkMode ? Colors.white54 : Colors.grey),
                      width: 2,
                    ),
                    color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.green)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (() {
                    String prefix = '';
                    if (task.variableNames.isNotEmpty) {
                      final idx = (task.occurrenceNumber ?? 1) - 1;
                      if (idx >= 0 && idx < task.variableNames.length) {
                        final vn = task.variableNames[idx];
                        if (vn != null && vn.isNotEmpty) prefix = '$vn ';
                      }
                    }
                    return '$prefix${task.taskName}';
                  })(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? (widget.isDarkMode ? Colors.white54 : Colors.grey)
                        : (widget.isDarkMode ? Colors.white : Colors.black87),
                    decoration: isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                  ),
                ),
              ),
              // Collapse Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    expandedIndex = null;
                  });
                },
                child: HoverIconButton(
                  icon: Icons.expand_less,
                  onPressed: () {
                    setState(() {
                      expandedIndex = null;
                    });
                  },
                  isDarkMode: widget.isDarkMode,
                ),
              ),
              // Edit Button
              GestureDetector(
                onTap: () => _editTask(index),
                child: HoverIconButton(
                  icon: Icons.edit,
                  onPressed: () => _editTask(index),
                  isDarkMode: widget.isDarkMode,
                ),
              ),
              // Delete Button
              GestureDetector(
                onTap: () => _showDeleteConfirmation(index, task.taskName),
                child: HoverIconButton(
                  icon: Icons.delete_outline,
                  onPressed: () => _showDeleteConfirmation(index, task.taskName),
                  isDarkMode: widget.isDarkMode,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Task Image
        if (task.imagePath != null && task.imagePath!.isNotEmpty) ...[
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: widget.isDarkMode ? Colors.white12 : Colors.grey[300]!),
            ),
              child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: task.imagePath!.startsWith('data:')
                  ? Image.memory(
                      base64Decode(task.imagePath!.split(',').last),
                      fit: BoxFit.contain,
                      width: double.infinity,
                    )
                  : (task.imagePath!.contains('/') || task.imagePath!.contains('\\')
                      ? Image.file(
                          File(task.imagePath!),
                          fit: BoxFit.contain,
                          width: double.infinity,
                        )
                      : Image.asset(
                          'assets/${task.imagePath}',
                          fit: BoxFit.contain,
                          width: double.infinity,
                        )),
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Task Notes
        if (task.notes.isNotEmpty) ...[
          Text(
            task.notes,
            style: TextStyle(
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Task Links (include variableLinks for the current occurrence at the top)
        Builder(builder: (context) {
          final int idx = (task.occurrenceNumber ?? 1) - 1;
          final List<String> linksToShow = [];
          if (task.variableLinks.isNotEmpty && idx >= 0 && idx < task.variableLinks.length) {
            final v = task.variableLinks[idx];
            if (v != null && v.isNotEmpty) linksToShow.add(v);
          }
          linksToShow.addAll(task.links);
          if (linksToShow.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Links:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              ...linksToShow.map((link) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: () async {
                    String linkUrl = link;
                    if (!linkUrl.startsWith('http://') && !linkUrl.startsWith('https://')) {
                      linkUrl = 'https://$linkUrl';
                    }
                    final Uri url = Uri.parse(linkUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Text(
                    link,
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.blue[300] : Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              )).toList(),
              const SizedBox(height: 16),
            ],
          );
        }),
        
        // Repeat info
        if (task.repeat)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Repeat: ${task.repeatTimes != null ? '${task.occurrenceNumber}/${task.repeatTimes}' : '∞'}',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDarkMode ? Colors.white60 : Colors.grey[700],
              ),
            ),
          ),
        
        // Complete Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.grey : const Color(0xFF9A00FE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _toggleTaskCompletion(index),
            child: Text(isCompleted ? 'Mark Incomplete' : 'Complete'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Compute visible todo indexes (only tasks with isDisplayed == true)
    final visibleIndexes = <int>[];
    for (int i = 0; i < todoItems.length; i++) {
      if (todoItems[i].isDisplayed) visibleIndexes.add(i);
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main content with todo list
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(),
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
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          // Complete Dictionary button
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DictionaryScreen(
                                        isDarkMode: widget.isDarkMode,
                                        onThemeChanged: widget.onThemeChanged,
                                      ),
                                    ),
                                  );
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DictionaryScreen(
                                        isDarkMode: widget.isDarkMode,
                                        onThemeChanged: widget.onThemeChanged,
                                        initialFilters: {'Kanji'},
                                      ),
                                    ),
                                  );
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
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DictionaryScreen(
                                        isDarkMode: widget.isDarkMode,
                                        onThemeChanged: widget.onThemeChanged,
                                        initialFilters: {'Vocabulary'},
                                      ),
                                    ),
                                  );
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
                    ],
                  ),
                ),
                
                // To-do list header
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                  child: Text(
                    'To-do list',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // To-Do List Display (only show tasks where `isDisplayed` is true)
                if (visibleIndexes.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: visibleIndexes.length,
                        itemBuilder: (context, vi) {
                          final index = visibleIndexes[vi]; // original index in todoItems
                          final task = todoItems[index];
                          final isCompleted = completedStatus[index] ?? false;
                          final isExpanded = expandedIndex == index;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 500),
                                child: GestureDetector(
                                  onTap: isExpanded ? null : () {
                                    setState(() {
                                      expandedIndex = index;
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: widget.isDarkMode ? const Color(0xFF242424) : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: widget.isDarkMode ? Colors.white12 : Colors.grey[300]!),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                    child: isExpanded
                                        ? _buildExpandedView(task, index, isCompleted)
                                        : _buildCollapsedView(task, index, isCompleted),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // To-Do List Settings Button (Left Side)
          Positioned(
            // Use the top system padding so the button aligns correctly on Android
            top: MediaQuery.of(context).padding.top + 8,
            left: 20,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TodoSettingsMenu(isDarkMode: widget.isDarkMode)),
                ).then((_) => _loadTasks());
              },
              child: Column(
                children: [
                  Icon(Icons.checklist, size: 32, color: widget.isDarkMode ? Colors.white : Colors.black87),
                  const SizedBox(height: 2),
                  Text(
                    "To do list",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8, color: widget.isDarkMode ? Colors.white : Colors.black87),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Button Row with background barrier
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
                // 1. Far Left: Arcade Button
                _buildHomeButton(
                  context,
                  image: 'assets/game.png',
                  label: "Arcade",
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ArcadeScreen(isDarkMode: widget.isDarkMode, onThemeChanged: widget.onThemeChanged)),
                    );
                    await _loadUserProfile();
                  },
                ),

                // 2. Middle: Library Button
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
                  },
                ),
              ],
            ),
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



