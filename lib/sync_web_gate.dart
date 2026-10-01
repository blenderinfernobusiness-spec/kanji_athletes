import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

const Color _accent = Color(0xFF9A00FE);

// TEMPORARY: sync is known to be rough around the edges right now, and the
// web build is the one surface anyone (not just the developer) can reach -
// this is a deterrent to stop casual/public use of sync/backup/restore while
// that gets sorted out, not real security. A web page's own source/state is
// always inspectable, so anyone determined enough can bypass this; it only
// needs to stop someone from stumbling into a broken feature by accident.
// Desktop/Android builds (used only by the developer) are left untouched.
const String _syncGatePassword = 'thekanjiathleteboss';

// Remembered for the rest of this page load once entered correctly, so it
// only has to be typed once per session rather than before every sync tap.
bool _syncGateUnlocked = false;

Future<bool> confirmSyncAccessOnWeb(BuildContext context, bool isDarkMode) async {
  if (!kIsWeb || _syncGateUnlocked) return true;

  final controller = TextEditingController();
  final fg = isDarkMode ? Colors.white : Colors.black87;
  final bg = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;

  final submitted = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: bg,
      title: Text('Password required', style: TextStyle(color: fg)),
      content: TextField(
        controller: controller,
        obscureText: true,
        autofocus: true,
        style: TextStyle(color: fg),
        decoration: const InputDecoration(labelText: 'Password'),
        onSubmitted: (_) => Navigator.pop(ctx, true),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );

  if (submitted != true) return false;
  if (controller.text != _syncGatePassword) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incorrect password')));
    }
    return false;
  }
  _syncGateUnlocked = true;
  return true;
}
