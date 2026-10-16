import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trial_service.dart';
import 'unlock_dialog.dart';

const Color _accent = Color(0xFF9A00FE);

// The shared "days left / unlocked" status row shown above a trial-gated
// feature's content (Reading & Immersion, the Dictionary, ...) - yellow
// "X days left" with an unlock link while the trial's active or just
// expired, or green "PREMIUM USAGE ENABLED" with no link once unlocked.
// onChanged fires after a successful unlock so the caller can rebuild and
// show the real content/hide the locked placeholder.
class TrialStatusBanner extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onChanged;
  const TrialStatusBanner({super.key, required this.isDarkMode, required this.onChanged});

  Future<void> _unlock(BuildContext context) async {
    final unlocked = await showUnlockDialog(context, isDarkMode);
    if (unlocked) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = TrialService.isUnlockedSync;
    final daysLeft = TrialService.daysRemainingSync;
    final color = unlocked ? Colors.green : const Color(0xFFCCA300);
    final label = unlocked
        ? 'PREMIUM USAGE ENABLED'
        : daysLeft > 0
            ? '$daysLeft day${daysLeft == 1 ? '' : 's'} left in your free trial'
            : 'Your free trial has ended';
    return Container(
      width: double.infinity,
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          if (!unlocked)
            InkWell(
              onTap: () => _unlock(context),
              child: const Text(
                'Unlock full access here',
                style: TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13, decoration: TextDecoration.underline),
              ),
            ),
        ],
      ),
    );
  }
}

// The locked-state placeholder shown in place of a trial-gated feature's
// real content once the trial's run out and it hasn't been unlocked.
class TrialLockedBody extends StatelessWidget {
  final bool isDarkMode;
  final String featureName;
  final VoidCallback onChanged;
  const TrialLockedBody({super.key, required this.isDarkMode, required this.featureName, required this.onChanged});

  Future<void> _unlock(BuildContext context) async {
    final unlocked = await showUnlockDialog(context, isDarkMode, featureName: featureName);
    if (unlocked) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final fg = isDarkMode ? Colors.white : Colors.black87;
    final fgMuted = isDarkMode ? Colors.white70 : Colors.black54;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 48, color: fgMuted),
            const SizedBox(height: 16),
            Text(
              'Your 7-day free trial of $featureName has ended',
              textAlign: TextAlign.center,
              style: TextStyle(color: fg, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
              onPressed: () => _unlock(context),
              child: const Text('Unlock full access'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(kUpgradeUrl), mode: LaunchMode.externalApplication),
              child: const Text('Upgrade on Skool'),
            ),
          ],
        ),
      ),
    );
  }
}
