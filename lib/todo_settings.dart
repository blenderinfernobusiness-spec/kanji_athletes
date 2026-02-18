import 'dart:io'; // Required for File()
import 'package:file_picker/file_picker.dart'; // Required for FilePicker
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// --- THE DATA MODEL ---
class TodoItem {
  String taskName;
  bool repeat;
  int repeatDays;
  int? repeatTimes; // null means infinite
  bool repeatForever;
  bool notify;
  TimeOfDay notificationTime;
  String notes;
  String? imagePath;
  List<String> links;
  List<String> variableNames; 
  List<String> variableLinks;
  String createdAt; // ISO date string (YYYY-MM-DD) - when this occurrence was created
  int occurrenceNumber; // which occurrence in the repeat cycle (1, 2, 3, ..., 90)
  String? completedDate; // null or ISO date (YYYY-MM-DD) when marked complete
  bool isCompleted;
  bool isDisplayed;
  String? nextDisplay; // ISO date (YYYY-MM-DD) when this task should next be shown
  String? overrideDate; // optional override date stored with the task

  TodoItem({
    required this.taskName,
    this.repeat = false,
    this.repeatDays = 1,
    this.repeatTimes,
    this.repeatForever = false,
    this.notify = false,
    this.notificationTime = const TimeOfDay(hour: 12, minute: 0),
    this.notes = "",
    this.imagePath,
    this.links = const [],
    this.variableNames = const [],
    this.variableLinks = const [],
    String? createdAt,
    this.occurrenceNumber = 1,
    this.completedDate,
    this.isCompleted = false,
    this.isDisplayed = true,
    this.nextDisplay,
    this.overrideDate,
  }) : createdAt = createdAt ?? _getTodayStamp();

  static String _getTodayStamp() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() => {
    'taskName': taskName,
    'repeat': repeat,
    'repeatDays': repeatDays,
    'repeatTimes': repeatTimes,
    'repeatForever': repeatForever,
    'notify': notify,
    'notifHour': notificationTime.hour,
    'notifMin': notificationTime.minute,
    'notes': notes,
    'imagePath': imagePath,
    'links': links,
    'variableNames': variableNames,
    'variableLinks': variableLinks,
    'createdAt': createdAt,
    'occurrenceNumber': occurrenceNumber,
    'completedDate': completedDate,
    'isCompleted': isCompleted,
    'isDisplayed': isDisplayed,
    'nextDisplay': nextDisplay,
    'overrideDate': overrideDate,
  };

  factory TodoItem.fromMap(Map<String, dynamic> map) => TodoItem(
    taskName: map['taskName'],
    repeat: map['repeat'],
    repeatDays: map['repeatDays'],
    repeatTimes: map['repeatTimes'],
    repeatForever: map['repeatForever'],
    notify: map['notify'],
    notificationTime: TimeOfDay(hour: map['notifHour'], minute: map['notifMin']),
    notes: map['notes'],
    imagePath: map['imagePath'],
    links: List<String>.from(map['links']),
    variableNames: List<String>.from(map['variableNames'] ?? []),
    variableLinks: List<String>.from(map['variableLinks'] ?? []),
    createdAt: map['createdAt'],
    occurrenceNumber: map['occurrenceNumber'] ?? 1,
    completedDate: map['completedDate'],
    nextDisplay: map['nextDisplay'],
    isCompleted: map['isCompleted'] as bool? ?? false,
    isDisplayed: map['isDisplayed'] as bool? ?? true,
    overrideDate: map['overrideDate'],
  );
}

class TodoSettingsMenu extends StatefulWidget {
  final bool isDarkMode;

  const TodoSettingsMenu({super.key, required this.isDarkMode});

  @override
  State<TodoSettingsMenu> createState() => _TodoSettingsMenuState();
}

class _TodoSettingsMenuState extends State<TodoSettingsMenu> {
  List<TodoItem> savedTasks = [];
  
  // Custom Tab Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _daysController = TextEditingController(text: "1");
  final TextEditingController _timesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<TextEditingController> _linkControllers = [TextEditingController()];
  String? _imagePath;
  bool _repeatChecked = false;
  bool _repeatForever = false;
  bool _notifyChecked = false;
  TimeOfDay _notifTime = const TimeOfDay(hour: 12, minute: 0);

 

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString('saved_todo_tasks');
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      setState(() {
        savedTasks = decodedData.map((item) => TodoItem.fromMap(item)).toList();
      });
    }
  }

  Future<void> _saveTasksToMemory() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(savedTasks.map((item) => item.toMap()).toList());
    await prefs.setString('saved_todo_tasks', encodedData);
  }

  // --- PRE-SETS DATA ---
  final List<TodoItem> presets = [
    TodoItem(
      taskName: "90 day challenge videos",
      repeat: true, repeatDays: 1, repeatTimes: 90,
      notify: true, notificationTime: const TimeOfDay(hour: 17, minute: 0),
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
    ),
    TodoItem(
      taskName: "90 day challenge flashcards",
      repeat: true, repeatDays: 1, repeatTimes: 90,
      notify: true, notificationTime: const TimeOfDay(hour: 17, minute: 0),
      notes: "Complete your flashcards!",
      imagePath: "90daycards.png",
      links: [
        "https://knowt.com/flashcards/d9956ac8-f910-4ffe-a8a9-3c2cf12d2cd7",
        "https://knowt.com/flashcards/baa1ecd8-337d-4aa9-9114-2cea181ca8a9",
        "https://knowt.com/flashcards/1aba42b9-b53f-4290-a465-2b443aa0ebcf?isNew=false",
        "https://knowt.com/flashcards/17b371d9-09e9-450e-a55e-84bba3ce5352"
      ],
      variableNames: List.generate(90, (i) => "Day ${i + 1}"),
    ),
    TodoItem(
      taskName: "Learn new words",
      repeat: true, repeatDays: 1, repeatForever: true,
      notify: true, notificationTime: const TimeOfDay(hour: 17, minute: 0),
      notes: "Learn some new words!",
    ),
    TodoItem(
      taskName: "Listen to a Japanese Podcast",
      repeat: true, repeatDays: 1, repeatForever: true,
      notify: true, notificationTime: const TimeOfDay(hour: 17, minute: 0),
      notes: "Put on your favourite podcast on in the background while cooking, doing chores, running or working!",
    ),
    TodoItem(
      taskName: "Get ready for bed",
      repeat: true, repeatDays: 1, repeatForever: true,
      notify: true, notificationTime: const TimeOfDay(hour: 21, minute: 0),
      notes: "Feel free to put on a japanese podcast or some relaxing music and get ready for a great day tomorrow!",
    ),
    TodoItem(
      taskName: "Welcome to the 90 day challenge!",
      repeat: false,
      notify: true,
      notificationTime: const TimeOfDay(hour: 17, minute: 0),
      notes: "Welcome! Start your 90 day challenge here!",
      links: [
        "https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ffc5a70ba2a240a89ecee1596ebbf5fd",
      ],
      imagePath: "90dayvids.png",
    ),
  ];

  void _addPresetTask(TodoItem preset) {
    setState(() {
      savedTasks.add(preset);
    });
    _saveTasksToMemory();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added ${preset.taskName}")));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("To do list settings"),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton(
                onPressed: () async {
                  await precacheImage(const AssetImage('assets/sapphire4S09.png'), context);
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
                              child: Image.asset('assets/sapphire4S09.png', fit: BoxFit.contain),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                              onPressed: () async {
                                try {
                                  final bd = await rootBundle.load('assets/sapphire4S09.png');
                                  final bytes = bd.buffer.asUint8List();
                                  final dir = await getApplicationDocumentsDirectory();
                                  final filePath = p.join(dir.path, 'sapphire4S09.png');
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
                                final uri = Uri.parse('https://drive.google.com/file/d/1JVd-9lKOAsZ4lxQd57X8c_2tk66BfVhF/view?usp=sharing');
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
                                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.white70),
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
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Column(
              children: [
                // VIEW LIST BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _viewTodoList(),
                      icon: const Icon(Icons.list),
                      label: const Text("View your to do list items"),
                    ),
                  ),
                ),
                const TabBar(
                  tabs: [Tab(text: "Pre-sets"), Tab(text: "Custom")],
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildPresetsTab(),
            _buildCustomTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: presets.length,
      itemBuilder: (context, index) {
        final item = presets[index];
        return Card(
          color: widget.isDarkMode ? Colors.white10 : Colors.grey[200],
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
              item.taskName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: widget.isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Text(
              item.notes,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.isDarkMode ? Colors.white60 : Colors.grey[700],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green, size: 30),
              onPressed: () => _addPresetTask(item),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Task Name"),
            onEditingComplete: () => FocusScope.of(context).unfocus(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(value: _repeatChecked, onChanged: (val) => setState(() => _repeatChecked = val!)),
              const Text("Repeat"),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _daysController,
                      enabled: _repeatChecked,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "Days"),
                    ),
                    const SizedBox(height: 6),
                    Text('Days (e.g 1 = everyday)', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _timesController,
                      enabled: _repeatChecked && !_repeatForever,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: "Times"),
                    ),
                    const SizedBox(height: 6),
                    Text('Times (e.g 1 = show once)', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87, fontSize: 12)),
                  ],
                ),
              ),
              Checkbox(value: _repeatForever, onChanged: _repeatChecked ? (val) => setState(() => _repeatForever = val!) : null),
              const Text("∞"),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Checkbox(value: _notifyChecked, onChanged: (val) => setState(() => _notifyChecked = val!)),
              const Text("Notify"),
              const SizedBox(width: 20),
              if (_notifyChecked)
                ElevatedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(context: context, initialTime: _notifTime);
                    if (picked != null) setState(() => _notifTime = picked);
                  },
                  child: Text(_notifTime.format(context)),
                ),
            ],
          ),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: "Notes")),
          const SizedBox(height: 10),
          
          Row(
            children: [
              // The Upload Button
              ElevatedButton.icon(
                onPressed: () async {
                  String? path = await _pickImageFromComputer();
                  if (path != null) {
                    final persisted = await _persistPickedImage(path);
                    setState(() {
                      _imagePath = persisted;
                    });
                  }
                },
                icon: const Icon(Icons.upload),
                label: const Text("Upload Image"),
              ),
              const SizedBox(width: 15),
              
              // The Preview Box
              if (_imagePath != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                    // Small 'x' to clear the image
                    GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                )
              else
                const Text("No image", style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),

          ..._linkControllers.map((controller) => TextField(controller: controller, decoration: const InputDecoration(labelText: "Link"))),
          IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _linkControllers.add(TextEditingController()))),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  final newTask = TodoItem(
                    taskName: _nameController.text,
                    repeat: _repeatChecked,
                    repeatDays: int.tryParse(_daysController.text) ?? 1,
                    repeatTimes: _repeatForever ? null : int.tryParse(_timesController.text),
                    repeatForever: _repeatForever,
                    notify: _notifyChecked,
                    notificationTime: _notifTime,
                    notes: _notesController.text,
                    imagePath: _imagePath, // <--- ADD THIS LINE
                    links: _linkControllers.map((c) => c.text).toList(),
                  );
                  // Inside the Save button's onPressed:
                  setState(() {
                    savedTasks.add(newTask);
                    _imagePath = null; // Clear the preview for the next task
                  });
                  _saveTasksToMemory();
                  _nameController.clear();
                  _notesController.clear();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task Saved!")));
                },
                child: const Text("Save"),
              ),
              ElevatedButton(
                onPressed: () => _showCancelWarning(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                child: const Text("Cancel"),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showCancelWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("You will lose the edits you've made to this item."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Continue Editing")),
          ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Confirm")),
        ],
      ),
    );
  }

  void _viewTodoList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodoListView(
          tasks: savedTasks,
          onUpdate: _saveTasksToMemory,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }
}

class TodoListView extends StatefulWidget {
  final List<TodoItem> tasks;
  final VoidCallback onUpdate;
  final bool isDarkMode;
  
  const TodoListView({
    super.key,
    required this.tasks,
    required this.onUpdate,
    required this.isDarkMode,
  });

  @override
  State<TodoListView> createState() => _TodoListViewState();
}

class _TodoListViewState extends State<TodoListView> {
  Set<int> selectedIndices = {};
  bool isMultiSelect = false;

  // This opens your computer's file explorer to pick an image
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage To Dos"),
        actions: [
          if (isMultiSelect) ...[
            IconButton(icon: const Icon(Icons.copy), onPressed: _duplicateSelected),
            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteSelected),
          ],
          IconButton(
            icon: Icon(isMultiSelect ? Icons.close : Icons.select_all),
            onPressed: () => setState(() {
              isMultiSelect = !isMultiSelect;
              selectedIndices.clear();
            }),
          )
        ],
      ),
      body: widget.tasks.isEmpty 
        ? Center(
            child: Text(
              "No items yet!",
              style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
            ),
          )
        : ListView.builder(
            itemCount: widget.tasks.length,
            itemBuilder: (context, index) {
              final task = widget.tasks[index];
              return Card(
                color: widget.isDarkMode ? const Color(0xFF242424) : Colors.grey[200],
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: isMultiSelect 
                    ? Checkbox(
                        value: selectedIndices.contains(index),
                        onChanged: (val) => setState(() => val! ? selectedIndices.add(index) : selectedIndices.remove(index)),
                      ) 
                    : Icon(Icons.drag_handle, color: widget.isDarkMode ? Colors.white24 : Colors.grey),
                  title: Text(
                    task.taskName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  subtitle: Text(
                    task.notes,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.grey[700]),
                  ),
                  // THE NEW EDIT AND DELETE BUTTONS
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
                        onPressed: () => _editTask(index),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: widget.isDarkMode ? Colors.white54 : Colors.grey),
                        onPressed: () => _confirmSingleDelete(index),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  onLongPress: () => setState(() => isMultiSelect = true),
                ),
              );
            },
          ),
    );
  }

  // LOGIC FOR DELETING ONE ITEM
  void _confirmSingleDelete(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          "Delete Task?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          "Are you sure you want to delete '${widget.tasks[index].taskName}'?",
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
            onPressed: () {
              setState(() => widget.tasks.removeAt(index));
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // LOGIC FOR EDITING (Simple placeholder for now)
 // LOGIC FOR EDITING
  void _editTask(int index) {
    final task = widget.tasks[index];
    String? editImagePath = task.imagePath; // Create a local copy for editing
    // Temporary controllers for the edit menu
    TextEditingController editName = TextEditingController(text: task.taskName);
    TextEditingController editNotes = TextEditingController(text: task.notes);
    TextEditingController editDays = TextEditingController(text: task.repeatDays.toString());
    TextEditingController editTimes = TextEditingController(text: task.repeatTimes?.toString() ?? "");
    
    // Handle multiple links
    List<TextEditingController> editLinks = task.links.isEmpty 
        ? [TextEditingController()] 
        : task.links.map((link) => TextEditingController(text: link)).toList();

    // Handle Variable Names/Links
    List<TextEditingController> editVarNames = task.variableNames.map((v) => TextEditingController(text: v)).toList();
    List<TextEditingController> editVarLinks = task.variableLinks.map((v) => TextEditingController(text: v)).toList();

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

                  // --- IMAGE SECTION ---
                  const SizedBox(height: 20),
                  Text(
                    "Task Image",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Inside the Edit Modal -> Task Image Section
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
                                    child: editImagePath!.contains('/') || editImagePath!.contains('\\')
                                        ? Image.file(File(editImagePath!), fit: BoxFit.cover)
                                        : Image.asset('assets/$editImagePath', fit: BoxFit.cover),
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
                                  final persisted = await _persistPickedImage(newPath);
                                  setImageState(() => editImagePath = persisted);
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

                  const Divider(color: Colors.white24, height: 40),
                  
                  // --- VARIABLE SECTION ---
                  Text(
                    "Variable Names & Links",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    "These allow the to do list item to have a unique name and link each day.",
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  if (editVarNames.isEmpty) Text(
                    "No variables present.",
                    style: TextStyle(color: widget.isDarkMode ? Colors.white24 : Colors.black38),
                  ),
                  
                  ...editVarNames.asMap().entries.map((entry) {
                    int i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: editVarNames[i],
                              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Name (e.g. Day ${i+1})",
                                hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: editVarLinks.length > i ? editVarLinks[i] : TextEditingController(),
                              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                hintText: "Link",
                                hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white38 : Colors.black38),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent), 
                            onPressed: () => setModalState(() {
                              editVarNames.removeAt(i);
                              if (editVarLinks.length > i) editVarLinks.removeAt(i);
                            })
                          ),
                        ],
                      ),
                    );
                  }),

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
                        onPressed: () {
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
                              variableNames: editVarNames.map((c) => c.text).toList(),
                              variableLinks: editVarLinks.map((c) => c.text).toList(),
                              createdAt: task.createdAt,
                              occurrenceNumber: editResetOccurrence ? 1 : task.occurrenceNumber,
                              completedDate: task.completedDate,
                              isCompleted: task.isCompleted,
                              isDisplayed: task.isDisplayed,
                              nextDisplay: editPickedNextDisplay ?? task.nextDisplay,
                              overrideDate: editPickedNextDisplay ?? task.overrideDate,
                            );

                            final String todayStamp = TodoItem._getTodayStamp();
                            if (updated.repeat) {
                              final bool withinTimes = (updated.repeatTimes == null) || (updated.occurrenceNumber <= (updated.repeatTimes ?? 0));
                              final bool nextIsDue = (updated.nextDisplay == null) || (updated.nextDisplay!.compareTo(todayStamp) <= 0);
                              if (withinTimes && nextIsDue) {
                                updated.isDisplayed = true;
                              } else if (!withinTimes) {
                                // If we've exceeded the allowed repeatTimes, ensure it is hidden
                                updated.isDisplayed = false;
                              }
                            }

                            widget.tasks[index] = updated;
                          });
                          widget.onUpdate();
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

  void _duplicateSelected() {
    setState(() {
      final toAdd = selectedIndices.map((i) => widget.tasks[i]).toList();
      widget.tasks.addAll(toAdd);
      selectedIndices.clear();
      isMultiSelect = false;
    });
    widget.onUpdate();
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          "Delete Multiple?",
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Text(
          "Delete ${selectedIndices.length} selected items?",
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
            onPressed: () {
              setState(() {
                final sortedIndices = selectedIndices.toList()..sort((a, b) => b.compareTo(a));
                for (var i in sortedIndices) { widget.tasks.removeAt(i); }
                selectedIndices.clear();
                isMultiSelect = false;
              });
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text("Delete All"),
          ),
        ],
      ),
    );
  }
}

Future<String?> _pickImageFromComputer() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'png', 'jpeg'],
  );

  if (result != null && result.files.single.path != null) {
    return result.files.single.path;
  }
  return null;
}

// Persist a picked image into the app's documents directory and return the
// persistent path. If copying fails, returns the original path.
Future<String> _persistPickedImage(String pickedPath) async {
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(pickedPath);
    String destPath = p.join(appDir.path, fileName);

    // Avoid overwriting existing files by appending a timestamp when needed
    if (await File(destPath).exists()) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      destPath = p.join(appDir.path, '\$ts_\$fileName');
    }

    final source = File(pickedPath);
    if (await source.exists()) {
      final copied = await source.copy(destPath);
      return copied.path;
    }
  } catch (e) {
    // ignore and fall back to original path
    // ignore: avoid_print
    print('Error persisting picked image: $e');
  }
  return pickedPath;
}