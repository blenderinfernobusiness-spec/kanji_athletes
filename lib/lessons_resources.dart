import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonsResourcesScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const LessonsResourcesScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<LessonsResourcesScreen> createState() => _LessonsResourcesScreenState();
}

class _LessonsResourcesScreenState extends State<LessonsResourcesScreen> {
  bool _isHoveringExit = false;
  bool _isHoveringButton1 = false;
  bool _isHoveringButton2 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/lessonspage.png',
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
                if (_isHoveringButton1)
                  Image.asset(
                    'assets/lessonsbutton1.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                if (_isHoveringButton1)
                  Image.asset(
                    'assets/lessonskanjiscreen.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                if (_isHoveringButton2)
                  Image.asset(
                    'assets/lessonsbutton2.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                if (_isHoveringButton2)
                  Image.asset(
                    'assets/lessonsvocabscreen.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                if (_isHoveringExit)
                  Image.asset(
                    'assets/bookshelfexit.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                Positioned(
                  top: 15,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height / 4,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringButton1 = true),
                    onExit: (_) => setState(() => _isHoveringButton1 = false),
                    child: GestureDetector(
                      onTap: () async {
                        final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541/classroom/3e9d2af4?md=ffc5a70ba2a240a89ecee1596ebbf5fd');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).size.height / 4 + 10,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height / 4 - 20,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringButton2 = true),
                    onExit: (_) => setState(() => _isHoveringButton2 = false),
                    child: GestureDetector(
                      onTap: () async {
                        final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541/classroom/9959aae4?md=27d24c272a834551aa218225ca1c6ed1');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height / 4,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringExit = true),
                    onExit: (_) => setState(() => _isHoveringExit = false),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
