import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InputResourcesScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const InputResourcesScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<InputResourcesScreen> createState() => _InputResourcesScreenState();
}

class _InputResourcesScreenState extends State<InputResourcesScreen> {
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
                  'assets/inputpage.png',
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
                if (_isHoveringButton1)
                  Image.asset(
                    'assets/inputbutton1.png',
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                if (_isHoveringButton2)
                  Image.asset(
                    'assets/inputbutton2.png',
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
                  top: 0,
                  left: 0,
                  right: 0,
                  height: MediaQuery.of(context).size.height / 4,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHoveringButton1 = true),
                    onExit: (_) => setState(() => _isHoveringButton1 = false),
                    child: GestureDetector(
                      onTap: () async {
                        final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541/classroom/0a6d30d0?md=cb38afd6918a46e7bac8ee409ec30366');
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
                    onEnter: (_) => setState(() => _isHoveringButton2 = true),
                    onExit: (_) => setState(() => _isHoveringButton2 = false),
                    child: GestureDetector(
                      onTap: () async {
                        final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541/classroom/0a6d30d0?md=06e8922f5eed43489f44f12021bb8f4d');
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
