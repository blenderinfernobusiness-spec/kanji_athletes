import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Checks a small, publicly-readable JSON file in Firebase Storage
// (public/app_version.json) for a newer release than the one currently
// installed, so users get an in-app prompt instead of having to notice a
// new download link somewhere and manually reinstall. Deliberately simple:
// this only ever *tells* the user an update exists and links them to it -
// it never downloads or installs anything itself (installing the real
// updater is a bigger project, and this alone already fixes "nobody knows
// an update exists").
//
// The file one entry per platform this is wired up for, e.g.:
// {
//   "android": {"latestVersion": "1.1.0", "minVersion": "1.0.0", "url": "https://.../app-release.apk", "notes": "..."},
//   "windows": {"latestVersion": "1.1.0", "minVersion": "1.0.0", "url": "https://.../KanjiAthletesSetup.exe", "notes": "..."}
// }
// minVersion is the oldest version still allowed to keep using the app
// without updating - anything older than that gets a non-dismissible
// prompt (for the rare release with a breaking data format change);
// anything between minVersion and latestVersion gets a dismissible one.
class UpdateInfo {
  final String latestVersion;
  final String minVersion;
  final String url;
  final String notes;
  final bool required;

  const UpdateInfo({
    required this.latestVersion,
    required this.minVersion,
    required this.url,
    required this.notes,
    required this.required,
  });
}

class UpdateCheckService {
  UpdateCheckService._();

  static const _networkTimeout = Duration(seconds: 10);
  static const _dismissedVersionKey = 'dismissedUpdateVersion';

  // Only Android and Windows are sideloaded (no app store handling updates
  // for them); web is always the latest build on reload, and iOS/macOS/
  // Linux aren't distributed this way, so there's nothing to check there.
  static String? get _platformKey {
    if (kIsWeb) return null;
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
    return null;
  }

  // Returns the update to show (if any), or null if the app is already
  // current, the platform isn't covered, or the check failed for any
  // reason - a broken version check should never block or nag a user who
  // can't reach the network.
  static Future<UpdateInfo?> check() async {
    final platformKey = _platformKey;
    if (platformKey == null) return null;
    try {
      final bytes = await FirebaseStorage.instance
          .ref('public/app_version.json')
          .getData(64 * 1024) // the file is a few hundred bytes; this is a generous cap
          .timeout(_networkTimeout);
      if (bytes == null) return null;
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final entry = json[platformKey] as Map<String, dynamic>?;
      if (entry == null) return null;

      final latest = entry['latestVersion'] as String? ?? '';
      final min = entry['minVersion'] as String? ?? '';
      final url = entry['url'] as String? ?? '';
      if (latest.isEmpty || url.isEmpty) return null;

      final installed = (await PackageInfo.fromPlatform()).version;
      if (_compareVersions(installed, latest) >= 0) return null; // already current or newer

      return UpdateInfo(
        latestVersion: latest,
        minVersion: min,
        url: url,
        notes: entry['notes'] as String? ?? '',
        required: min.isNotEmpty && _compareVersions(installed, min) < 0,
      );
    } catch (_) {
      return null; // offline, misconfigured file, etc. - fail silently
    }
  }

  // Remembers that the user dismissed a prompt for [version], so the same
  // (non-required) version doesn't keep nagging them every launch - a newer
  // published version still prompts again.
  static Future<void> dismiss(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedVersionKey, version);
  }

  static Future<bool> wasDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dismissedVersionKey) == version;
  }

  // Compares two "1.2.3"-style version strings, returning <0, 0, or >0 the
  // way a normal comparator does. Missing/non-numeric parts count as 0, and
  // a version string that doesn't parse at all is treated as equal rather
  // than throwing, so a typo in the published JSON can't accidentally force
  // every single user into a non-dismissible update prompt.
  static int _compareVersions(String a, String b) {
    List<int> parts(String v) =>
        v.split('.').map((p) => int.tryParse(p.trim()) ?? 0).toList();
    final pa = parts(a);
    final pb = parts(b);
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }
}
