import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class OtherResourcesScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const OtherResourcesScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<OtherResourcesScreen> createState() => _OtherResourcesScreenState();
}

class _OtherResourcesScreenState extends State<OtherResourcesScreen> {
  bool _isHoveringExit = false;
  bool _isHoveringButton1 = false;

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
                  'assets/otherpage.png',
                  fit: BoxFit.contain,
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                ),
                if (_isHoveringButton1)
                  Image.asset(
                    'assets/otherbutton1.png',
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
                        final Uri url = Uri.parse('https://www.skool.com/kanji-athletes-5541/classroom/0a6d30d0?md=b2af6f4d62724fd9a3d05f49440c8fb8');
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
