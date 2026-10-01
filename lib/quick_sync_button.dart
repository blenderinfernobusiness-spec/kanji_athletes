import 'package:flutter/material.dart';
import 'backup_data.dart';
import 'cloud_sync_service.dart';
import 'sync_web_gate.dart';

const Color _accent = Color(0xFF9A00FE);

// A quick "sync to cloud" shortcut for app bars throughout the app, so
// syncing doesn't require navigating all the way back to the home screen
// every time. This device's data (including anything you've deleted) always
// becomes the new cloud backup, but first pulls in anything genuinely new
// from elsewhere - like a word added via the Chrome extension - so that
// isn't lost either (see backup_data.dart's syncToCloud). The home screen's
// Cloud Backup screen (Export/Import -> Cloud sync) stays the only place for
// a full "Download from cloud" that deliberately discards this device's data
// in the other direction - that deserves the fuller context that screen
// gives, not a single quick tap from wherever you happen to be.
//
// Shows progress as the button itself turning into a small spinner (and
// disabling) rather than a separate modal dialog - a modal spinner dialog
// closed via a bare Navigator.pop is exactly the kind of thing a double-tap
// (easy to do when there's no immediate feedback) can get stuck: two taps
// stack two dialogs, and the first sync finishing only pops the top one,
// leaving the other on screen forever. A disabled button can't be
// double-tapped in the first place, and syncToCloud itself (see
// backup_data.dart) also now serializes concurrent calls as a second layer
// of protection, in case this button and another sync surface (the Mini
// app, say) get triggered at the same moment.
Widget syncAppBarAction(BuildContext context, bool isDarkMode) {
  return SyncAppBarAction(isDarkMode: isDarkMode);
}

class SyncAppBarAction extends StatefulWidget {
  final bool isDarkMode;
  const SyncAppBarAction({super.key, required this.isDarkMode});

  @override
  State<SyncAppBarAction> createState() => _SyncAppBarActionState();
}

class _SyncAppBarActionState extends State<SyncAppBarAction> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
        ),
      );
    }
    return IconButton(
      icon: const Icon(Icons.cloud_sync_outlined),
      tooltip: 'Sync with cloud',
      onPressed: () => _quickSync(context),
    );
  }

  Future<void> _quickSync(BuildContext context) async {
    if (CloudSyncService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sign in first - go to Export/Import > Cloud sync from the home screen.")),
      );
      return;
    }
    if (!await confirmSyncAccessOnWeb(context, widget.isDarkMode) || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text("Sync with cloud?", style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87)),
        content: Text(
          "Makes this device's data the new cloud backup - anything you've deleted here stays deleted. Cards or "
          "decks added elsewhere (like the Chrome extension) since your last sync are pulled in first, so they "
          "aren't lost.",
          style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87),
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

    setState(() => _busy = true);
    try {
      await syncToCloud();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Synced with cloud - restart the app to see everything")));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync failed: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
