import 'package:flutter/material.dart';
import '../widgets/help_center_widget.dart';

class TroubleshootingScreen extends StatelessWidget {
  const TroubleshootingScreen({super.key});

  static const List<Map<String, String>> _issues = [
    {
      'q': 'Why is my data not syncing?',
      'a':
          'Check your internet connection first. Then go to Settings → Sync → tap "Sync Now." If the issue persists, sign out and sign back in to force a full sync.',
    },
    {
      'q': 'The app keeps crashing — what should I do?',
      'a':
          'Force-close the app and reopen it. If it still crashes, update to the latest version on the App Store or Google Play. As a last resort, reinstall the app — your cloud data will be restored on login.',
    },
    {
      'q': 'Charts are not loading correctly.',
      'a':
          'Pull down on the screen to refresh. If the charts remain broken, clear the app cache (Settings → Storage → Clear Cache on Android; reinstall on iOS) and relaunch.',
    },
    {
      'q': 'I accidentally deleted a transaction.',
      'a':
          'Unfortunately, deleted transactions cannot be recovered. To avoid this in future, you can enable the deletion confirmation prompt in Settings → Preferences.',
    },
    {
      'q': 'Notifications aren\'t working.',
      'a':
          'Ensure FinSight has notification permissions in your phone\'s Settings app. Then check Settings → Reminders in FinSight to confirm your reminders are enabled.',
    },
    {
      'q': 'The app is running slowly.',
      'a':
          'Close other background apps to free up memory. If slowness continues, try clearing the app cache or updating to the latest version.',
    },
    {
      'q': 'CSV import failed.',
      'a':
          'Ensure your CSV has the columns: Date, Description, Amount, Category. Dates must be in DD/MM/YYYY format and amounts must be plain numbers without currency symbols.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: helpBgColor,
      appBar: const TopicAppBar(title: 'Troubleshooting'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          HelpCard(
            child: Row(
              children: [
                const IconBadge(icon: Icons.build_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Troubleshooting',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fix common issues quickly with these solutions.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Quick Fixes'),
          HelpCard(
            child: Column(
              children: [
                _quickFix(
                  Icons.refresh_rounded,
                  'Force refresh',
                  'Pull down on any screen to sync the latest data.',
                ),
                const Divider(height: 20),
                _quickFix(
                  Icons.system_update_rounded,
                  'Update the app',
                  'Most bugs are fixed in the latest version.',
                ),
                const Divider(height: 20),
                _quickFix(
                  Icons.logout_rounded,
                  'Sign out & back in',
                  'Resolves most account and sync-related issues.',
                ),
                const Divider(height: 20),
                _quickFix(
                  Icons.delete_sweep_rounded,
                  'Clear app cache',
                  'Fixes display glitches and slow performance.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Common Issues'),
          ...List.generate(
            _issues.length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < _issues.length - 1 ? 10 : 0),
              child: FaqItem(
                question: _issues[i]['q']!,
                answer: _issues[i]['a']!,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const WarningBanner(
            text:
                'Still stuck? Tap "Contact Us" from the Help Centre to reach our support team.',
          ),
        ],
      ),
    );
  }

  Widget _quickFix(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: tealLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: tealDark, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
