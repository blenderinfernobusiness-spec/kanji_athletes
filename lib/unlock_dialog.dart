import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trial_service.dart';
import 'app_colors.dart';
import 'app_theme.dart';

Color get _accent => AppColors.accent;

// The one dialog every locked feature funnels into - explains why it's
// locked, links out to Skool to upgrade, and has a field to enter the code
// directly. Returns true if a valid code was entered (so the caller can
// proceed with whatever was blocked), false/null otherwise.
Future<bool> showUnlockDialog(BuildContext context, bool isDarkMode, {String? featureName}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _UnlockDialog(isDarkMode: isDarkMode, featureName: featureName),
  );
  return result ?? false;
}

class _UnlockDialog extends StatefulWidget {
  final bool isDarkMode;
  final String? featureName;
  const _UnlockDialog({required this.isDarkMode, this.featureName});

  @override
  State<_UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends State<_UnlockDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _controller.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await TrialService.tryUnlock(code);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = "That code isn't right";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.text(widget.isDarkMode);
    final fgMuted = AppColors.textMuted(widget.isDarkMode);
    final fieldFill = widget.isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[200];
    return AlertDialog(
      backgroundColor: AppColors.cardBg(widget.isDarkMode),
      shape: pixelShape() ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Unlock full access', style: TextStyle(fontWeight: FontWeight.bold, color: fg)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.featureName != null
                  ? '${widget.featureName} needs full access to unlock.'
                  : 'This needs full access to unlock.',
              style: TextStyle(color: fgMuted),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => launchUrl(Uri.parse(kUpgradeUrl), mode: LaunchMode.externalApplication),
              child: Text(
                'Upgrade on Skool to get the code',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w600, decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(color: fg),
              decoration: InputDecoration(
                hintText: 'Enter code',
                hintStyle: TextStyle(color: fgMuted),
                filled: true,
                fillColor: fieldFill,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _busy ? null : _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: fgMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Unlock'),
        ),
      ],
    );
  }
}
