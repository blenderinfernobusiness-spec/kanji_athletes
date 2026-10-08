import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'backup_data.dart';
import 'cloud_sync_service.dart';

const Color _accent = Color(0xFF9A00FE);

// Cloud backup/restore - email/password sign-in (see CloudSyncService's doc
// comment for why not Google Sign-In), then a single backup file per
// account shared by a phone, a desktop, and the Chrome extension alike.
// "Sync" makes this device's data the new cloud backup - deletions stick -
// but first pulls in anything genuinely new from elsewhere (see
// backup_data.dart's syncToCloud) so a word added via the extension isn't
// lost. "Download from cloud" below is the one true replace in the other
// direction, and "Hard Override Upload" skips even the pull-forward step for
// when you want this device's data to win outright. Fully optional - the
// app works entirely offline without ever visiting this screen.
class CloudSyncPage extends StatefulWidget {
  final bool isDarkMode;
  const CloudSyncPage({super.key, required this.isDarkMode});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  bool _busy = false;

  // Set right after a successful sign-in (not account creation - a brand
  // new account has no cloud backup to choose between yet) so the very next
  // build of the signed-in view can prompt for upload vs download once, up
  // front, rather than leaving a user to find Sync/Download themselves among
  // the signed-in view's other buttons.
  bool _pendingSyncPrompt = false;

  Color get _bg => widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _fg => widget.isDarkMode ? Colors.white : Colors.black87;
  Color get _fgMuted => widget.isDarkMode ? Colors.white70 : Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Cloud Backup')),
      body: StreamBuilder<User?>(
        stream: CloudSyncService.authStateChanges,
        builder: (context, snapshot) {
          final user = snapshot.data;
          if (user == null) return _buildSignInForm();
          return _buildSignedInView(user);
        },
      ),
    );
  }

  Widget _buildSignInForm() {
    return CloudSignInForm(
      isDarkMode: widget.isDarkMode,
      busy: _busy,
      onBusyChanged: (v) => setState(() => _busy = v),
      onSignedIn: () => _pendingSyncPrompt = true,
    );
  }

  Widget _buildSignedInView(User user) {
    if (_pendingSyncPrompt) {
      _pendingSyncPrompt = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showUploadOrDownloadPrompt();
      });
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: _bg,
          child: ListTile(
            leading: const Icon(Icons.account_circle, color: _accent),
            title: Text(user.email ?? 'Signed in', style: TextStyle(color: _fg)),
            trailing: TextButton(
              onPressed: _busy ? null : () => CloudSyncService.signOut(),
              child: const Text('Sign out'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<DateTime?>(
          future: CloudSyncService.lastBackupTime(),
          builder: (context, snap) {
            final text = snap.connectionState != ConnectionState.done
                ? 'Checking last backup…'
                : (snap.data == null ? 'No backup uploaded yet' : 'Last backup: ${_formatDateTime(snap.data!)}');
            return Text(text, style: TextStyle(color: _fgMuted, fontSize: 13));
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _busy ? null : _backupNow,
          icon: const Icon(Icons.sync),
          label: const Text('Sync'),
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _restoreFromCloud,
          icon: Icon(Icons.cloud_download_outlined, color: _fg),
          label: Text('Download from cloud', style: TextStyle(color: _fg)),
        ),
        const SizedBox(height: 8),
        Text(
          'Downloading replaces your study decks, reading texts, unlocked gems, and dictionary sets/items on this device with whatever was last uploaded — anything added here since your last upload will be lost.',
          style: TextStyle(color: _fgMuted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Only use the options below if Sync isn\'t resolving things correctly on its own.',
          style: TextStyle(color: _fgMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _forceUpload,
          icon: const Icon(Icons.warning_amber, color: Colors.orangeAccent),
          label: const Text('Hard Override Upload', style: TextStyle(color: Colors.orangeAccent)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.orangeAccent)),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _deleteAccount,
          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
          label: const Text('Delete Account & Learning Progress', style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator(color: _accent)),
        ],
      ],
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text('Delete account?', style: TextStyle(color: _fg)),
        content: Text(
          'Are you sure? This will permanently delete your account and your cloud backup — your Japanese study scores stored here cannot be recovered. This does not touch anything already saved on this device.',
          style: TextStyle(color: _fgMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await CloudSyncService.deleteAccount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('For security, please sign out, sign back in, and try deleting your account again.'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: ${e.message ?? e.code}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Shown once, right after signing in (not account creation). Upload
  // reuses the same smart-merge Sync already below (never destructive -
  // pulls in anything new from the cloud first); Download reuses the same
  // "Download from cloud" action, including its own confirmation, since
  // that one does overwrite this device's data.
  Future<void> _showUploadOrDownloadPrompt() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text('Upload or download?', style: TextStyle(color: _fg)),
        content: Text(
          "If this is a new device and you already have progress saved to this account, press Download to bring "
          "it here. Otherwise, press Upload to sync what's on this device to the cloud.",
          style: TextStyle(color: _fgMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text('Maybe later', style: TextStyle(color: _fgMuted)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop('download'),
            child: const Text('Download'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop('upload'),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice == 'upload') {
      await _backupNow();
    } else {
      await _restoreFromCloud();
    }
  }

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    try {
      await syncToCloud();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Synced with cloud — restart the app to see everything')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Bypasses merging entirely and replaces the cloud backup with exactly
  // what's on this device - the old pre-merge upload behaviour, kept as an
  // explicit escape hatch for when a merge isn't resolving things correctly
  // and you just want this device's data to become the source of truth.
  Future<void> _forceUpload() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text('Override cloud backup?', style: TextStyle(color: _fg)),
        content: Text(
          "This replaces your entire cloud backup with what's on this device, discarding anything from another "
          "device or the Chrome extension that hasn't already been synced here. Only use this to recover from a "
          "sync problem - otherwise use Sync above, which merges instead of overwriting.",
          style: TextStyle(color: _fgMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Override', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final content = await buildExportJson();
      await CloudSyncService.uploadBackup(content);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Cloud backup overridden with this device's data")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Override failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromCloud() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text('Download from cloud?', style: TextStyle(color: _fg)),
        content: Text(
          'This replaces your study decks, reading texts, unlocked gems, and dictionary sets/items on this device with the last cloud backup. This cannot be undone.',
          style: TextStyle(color: _fgMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Download', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      final content = await CloudSyncService.downloadBackup();
      if (content == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No backup found for this account')));
        return;
      }
      await applyImportedJson(content);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore complete — restart the app to see everything')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDateTime(DateTime d) {
    final local = d.toLocal();
    return '${local.year}-${_twoDigits(local.month)}-${_twoDigits(local.day)} ${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }
}

class CloudSignInForm extends StatefulWidget {
  final bool isDarkMode;
  final bool busy;
  final void Function(bool) onBusyChanged;
  // Called right after a successful sign-in (not account creation - a brand
  // new account has nothing to choose between yet). Optional and unused by
  // Kanji Athletes Mini, which already auto-syncs silently on sign-in by
  // design (see main_mini.dart) rather than prompting.
  final VoidCallback? onSignedIn;
  const CloudSignInForm({
    super.key,
    required this.isDarkMode,
    required this.busy,
    required this.onBusyChanged,
    this.onSignedIn,
  });

  @override
  State<CloudSignInForm> createState() => CloudSignInFormState();
}

class CloudSignInFormState extends State<CloudSignInForm> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isCreatingAccount = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter an email and password');
      return;
    }
    widget.onBusyChanged(true);
    setState(() => _error = null);
    try {
      if (_isCreatingAccount) {
        await CloudSyncService.signUp(email: email, password: password);
      } else {
        await CloudSyncService.signIn(email: email, password: password);
        widget.onSignedIn?.call();
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      widget.onBusyChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = widget.isDarkMode ? Colors.white54 : Colors.black54;
    final fieldFill = widget.isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFEDEDED);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isCreatingAccount ? 'Create an account' : 'Sign in',
            style: TextStyle(color: fg, fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'The same account on every device keeps them synced to one backup.',
            style: TextStyle(color: fgMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We only collect your email address to save your learning progress and let you log back in. Your data is securely handled by Google Firebase infrastructure and will never be shared or sold.',
            style: TextStyle(color: fgMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: fg),
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: fgMuted),
              filled: true,
              fillColor: fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: true,
            style: TextStyle(color: fg),
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: TextStyle(color: fgMuted),
              filled: true,
              fillColor: fieldFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: widget.busy ? null : _submit,
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: widget.busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isCreatingAccount ? 'Create account' : 'Sign in'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.busy ? null : () => setState(() => _isCreatingAccount = !_isCreatingAccount),
            child: Text(
              _isCreatingAccount ? 'Already have an account? Sign in' : "Don't have an account? Create one",
              style: TextStyle(color: fgMuted),
            ),
          ),
        ],
      ),
    );
  }
}
