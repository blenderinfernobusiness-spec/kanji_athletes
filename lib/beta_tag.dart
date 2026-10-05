import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Immersion (the in-app YouTube player) is noticeably rougher on Android
// than on Windows/web - see immersion_tab.dart's and video_immersion_player
// .dart's own notes - so it's flagged as beta there rather than on every
// platform.
bool get isImmersionBeta => !kIsWeb && Platform.isAndroid;

class BetaTag extends StatelessWidget {
  const BetaTag({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: const Color(0xFF9A00FE), borderRadius: BorderRadius.circular(4)),
      child: const Text('BETA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
