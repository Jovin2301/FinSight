import 'package:flutter/material.dart';
import '../widgets/help_center_widget.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: helpBgColor,
      appBar: const TopicAppBar(title: 'Privacy & Security'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          HelpCard(
            child: Row(
              children: [
                const IconBadge(icon: Icons.lock_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Privacy & Security',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'How we protect your data and what you control.',
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

          const SectionLabel(text: 'How We Protect Your Data'),
          HelpCard(
            child: Column(
              children: [
                _securityRow(
                  Icons.enhanced_encryption_rounded,
                  'End-to-end encryption',
                  'All data is encrypted and secured.',
                ),
                const Divider(height: 20),
                _securityRow(
                  Icons.visibility_off_rounded,
                  'No data selling',
                  'FinSight never sells or shares your financial data with third parties.',
                ),
                const Divider(height: 20),
                _securityRow(
                  Icons.cloud_done_rounded,
                  'Secure cloud backup',
                  'Your data is backed up to a secure server — only you can access it.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Your Privacy Controls'),
          HelpCard(
            child: Column(
              children: [
                _controlRow(
                  'Export my data',
                  'Settings → Privacy → Export Data (CSV or JSON)',
                ),
                const Divider(height: 16),
                _controlRow(
                  'Delete my account',
                  'Settings → Privacy → Delete Account — permanently removes all data',
                ),
                const Divider(height: 16),
                _controlRow(
                  'Revoke permissions',
                  'Settings → Permissions — manage camera, notifications, and more',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Common Questions'),
          const FaqItem(
            question: 'Is my banking data stored on your servers?',
            answer:
                'FinSight does not connect directly to banks. Any data you enter is encrypted and stored securely. We have no access to your actual bank accounts.',
          ),
          const SizedBox(height: 10),

          const FaqItem(
            question: 'What happens to my data if I delete the app?',
            answer:
                'Your cloud backup is retained for 30 days after uninstalling, in case you reinstall. After that it is permanently deleted. To delete immediately, use Settings → Privacy → Delete Account first.',
          ),
          const SizedBox(height: 20),

          const InfoBanner(
            text:
                'FinSight is compliant with Singapore\'s Personal Data Protection Act (PDPA).',
          ),
        ],
      ),
    );
  }

  Widget _securityRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 3),
              Text(
                subtitle,
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
    );
  }

  Widget _controlRow(String action, String location) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                action,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFFCCCCCC),
          size: 20,
        ),
      ],
    );
  }
}
