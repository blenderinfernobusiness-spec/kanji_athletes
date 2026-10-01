import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'backup_data.dart';
import 'cloud_sync_service.dart';

const Color _accent = Color(0xFF9A00FE);

// Cloud backup/restore - email/password sign-in (see CloudSyncService's doc
// comment for why not Google Sign-In), then a single backup file per
// account shared by a phone, a desktop, and the Chrome extension alike.
// "Sync" merges with whatever's already on the cloud (see backup_data.dart's
// syncToCloud) rather than blindly overwriting it; only the explicit
// "Download from cloud" below is a true replace, since that's the one action
// that's supposed to discard what's on this device. Fully optional - the
// app works entirely offline without ever visiting this screen.
class CloudSyncPage extends StatefulWidget {
  final bool isDarkMode;
  const CloudSyncPage({super.key, required this.isDarkMode});

  @override
  State<CloudSyncPage> createState() => _CloudSyncPageState();
}

class _CloudSyncPageState extends State<CloudSyncPage> {
  bool _busy = false;

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
    );
  }

  Widget _buildSignedInView(User user) {
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
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Upload to cloud'),
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
  const CloudSignInForm({super.key, required this.isDarkMode, required this.busy, required this.onBusyChanged});

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
