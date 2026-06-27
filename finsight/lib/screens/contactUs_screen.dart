import 'package:flutter/material.dart';
import '../widgets/help_center_widget.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchWebsite() async {
    final Uri url = Uri.parse('https://github.com/Jovin2301/FinSight.git');
    
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: helpBgColor,
      appBar: const TopicAppBar(title: 'Contact Us'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              border: Border.all(color: const Color(0xFFF5C842), width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('🎓', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'FinSight is a student project. We appreciate your patience and feedback — it genuinely helps us grow.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.brown[700], height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          HelpCard(
            child: Row(
              children: [
                const IconBadge(icon: Icons.chat_bubble_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contact Us',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Text(
                          'We\'re a small student team — we\'ll get back to you as soon as we can.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Get in Touch'),
          _contactCard(
            icon: Icons.email_rounded,
            title: 'Email Support',
            subtitle: 'Jovin: e1527037@u.nus.edu \n'
            'Zhi Hui: e1526364@u.nus.edu',
            tag: 'Replies within 1–2 working days',
            tagColor: tealDark,
            tagBg: tealLight,
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _contactCard(
            icon: Icons.bug_report_rounded,
            title: 'Report a Bug',
            subtitle: 'In-app: Settings → Send Feedback',
            tag: 'Helps us improve faster',
            tagColor: const Color(0xFF6B5CE7),
            tagBg: const Color(0xFFEFECFD),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _contactCard(
            icon: Icons.school_rounded,
            title: 'NUS Orbital Project',
            subtitle: 'github.com/finsight-orbital',
            tag: 'Open source',
            tagColor: const Color(0xFF1A1A1A),
            tagBg: const Color(0xFFF2F2F2),
            onTap: () => _launchWebsite(),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Before You Write to Us'),
          HelpCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Checking these first saves time for both of us:',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey[600], height: 1.5),
                ),
                const SizedBox(height: 12),
                const BulletTile(
                    text: 'Read through the relevant Help Centre topic above.'),
                const BulletTile(
                    text: 'Make sure your app is updated to the latest version.'),
                const BulletTile(
                    text: 'Try signing out and back in if it\'s a sync issue.'),
                const BulletTile(
                    text:
                        'Include your device model and OS version when emailing.'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Response Times'),
          HelpCard(
            child: Column(
              children: [
                _responseRow('General questions', 'Within 2 working days'),
                const Divider(height: 20),
                _responseRow('Bug reports', 'Triaged within 3 days'),
                const Divider(height: 20),
                _responseRow('Account issues', 'Priority — within 1 day'),
              ],
            ),
          ),
          const SizedBox(height: 20),

        ],
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required Color tagColor,
    required Color tagBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: HelpCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: tealLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: tealDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: tagBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(tag,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: tagColor)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _responseRow(String type, String time) {
    return Row(
      children: [
        Expanded(
          child: Text(type,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A1A))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: tealLight, borderRadius: BorderRadius.circular(8)),
          child: Text(time,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: tealDark)),
        ),
      ],
    );
  }
}