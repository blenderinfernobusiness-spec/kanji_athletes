import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dictionary.dart';

class RevisionResourcesScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const RevisionResourcesScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<RevisionResourcesScreen> createState() => _RevisionResourcesScreenState();
}

class _RevisionResourcesScreenState extends State<RevisionResourcesScreen> {
  bool _isHoveringExit = false;
  bool _isHoveringButton1 = false;
  bool _isHoveringButton2 = false;
  bool _isHoveringButton3 = false;

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
                  'assets/revisionpage.png',
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
                if (_isHoveringButton1)
                  Image.asset(
                    'assets/revisionbutton1.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                if (_isHoveringButton2)
                  Image.asset(
                    'assets/revisionbutton2.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                if (_isHoveringButton3)
                  Image.asset(
                    'assets/revisionbutton3.png',
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
                        final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541/classroom/0a6d30d0?md=40417735d66c4ffbb2367e57938a01f9');
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
                        final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541/classroom/0a6d30d0?md=40417735d66c4ffbb2367e57938a01f9');
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
                  top: MediaQuery.of(context).size.height / 2,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height / 4,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringButton3 = true),
                    onExit: (_) => setState(() => _isHoveringButton3 = false),
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
