import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'update_check_service.dart';

const Color _accent = Color(0xFF9A00FE);

// Shows the "a new version is available" prompt. Non-dismissible (no "Not
// now", no tap-outside-to-close) when [info.required] is true - used only
// for the rare release with a breaking data format change, where staying
// on the old version risks the exact sync collision this whole feature
// exists to prevent.
Future<void> showUpdateDialog(BuildContext context, UpdateInfo info, bool isDarkMode) {
  return showDialog(
    context: context,
    barrierDismissible: !info.required,
    builder: (context) => PopScope(
      canPop: !info.required,
      child: AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          info.required ? 'Update required' : 'Update available',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${info.latestVersion} is out.',
              style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
            ),
            if (info.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                info.notes,
                style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Download the new version and reinstall it over this one.',
              style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 13),
            ),
            if (info.required) ...[
              const SizedBox(height: 12),
              Text(
                "This version is too old to keep using safely. Please update before continuing.",
                style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
            ],
          ],
        ),
        actions: [
          if (!info.required)
            TextButton(
              onPressed: () async {
                await UpdateCheckService.dismiss(info.latestVersion);
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('Not now', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            onPressed: () => launchUrl(Uri.parse(info.url), mode: LaunchMode.externalApplication),
            child: const Text('Download & reinstall'),
          ),
        ],
      ),
    ),
  );
}
