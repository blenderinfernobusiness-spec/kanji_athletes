import 'package:flutter/material.dart';
import 'backup_data.dart';
import 'cloud_sync_service.dart';

const Color _accent = Color(0xFF9A00FE);

// A quick "sync to cloud" shortcut for app bars throughout the app, so
// syncing doesn't require navigating all the way back to the home screen
// every time. Deliberately not a full restore: it merges this device's
// changes with whatever's already on the cloud (see backup_data.dart's
// syncToCloud) rather than replacing it outright, so it's safe to use freely
// even if another device or the Chrome extension has synced since. The home
// screen's Cloud Backup screen (Export/Import -> Cloud sync) stays the only
// place for a full "Download from cloud" that deliberately discards this
// device's data - that deserves the fuller context that screen gives, not a
// single quick tap from wherever you happen to be.
Widget syncAppBarAction(BuildContext context, bool isDarkMode) {
  return IconButton(
    icon: const Icon(Icons.cloud_sync_outlined),
    tooltip: 'Sync with cloud',
    onPressed: () => _quickSync(context, isDarkMode),
  );
}

Future<void> _quickSync(BuildContext context, bool isDarkMode) async {
  if (CloudSyncService.currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sign in first - go to Export/Import > Cloud sync from the home screen.")),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      title: Text("Sync with cloud?", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
      content: Text(
        "Combines what's on this device with your cloud backup - new or changed decks and cards from either "
        "side are kept. For a full replace instead, use Cloud sync from the home screen's Export/Import menu.",
        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text("Cancel")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text("Sync", style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: _accent)),
  );

  try {
    await syncToCloud();
    if (!context.mounted) return;
    Navigator.pop(context); // close the loading indicator
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Synced with cloud - restart the app to see everything")));
  } catch (e) {
    if (!context.mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync failed: $e")));
  }
}
