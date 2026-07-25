import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color _tealDark = Color(0xFF2D7D7B);
  static const Color _bgColor = Color(0xFFEBF0F0);
  static const Color _cardColor = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Gradient header ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: _tealDark,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E5C5A), Color(0xFF4AADAA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 53, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Legal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Last updated June 2026 · FinSight Orbital 2026',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Info callout
                _InfoCallout(
                  icon: Icons.info_outline_rounded,
                  text:
                      'FinSight is a student project under NUS Orbital 2026. This policy explains how we handle your personal and financial data.',
                  color: _tealDark,
                  bgColor: const Color(0xFFE6F4F3),
                ),
                const SizedBox(height: 16),

                // Sections
                _PolicySection(
                  tag: 'What We Collect',
                  tagColor: _tealDark,
                  tagBg: const Color(0xFFE6F4F3),
                  icon: Icons.folder_open_rounded,
                  title: 'Account & Financial Data',
                  body:
                      'We collect your email and encrypted password when you register. Within the app, we store the income, expense, and budget entries you manually add.',
                  extra: _InfoCallout(
                    icon: Icons.account_balance_rounded,
                    text:
                        'FinSight does not connect to your bank or access any external financial accounts.',
                    color: _tealDark,
                    bgColor: const Color(0xFFE6F4F3),
                  ),
                ),
                const SizedBox(height: 12),

                _PolicySection(
                  tag: 'How We Use It',
                  tagColor: const Color(0xFF1A6B68),
                  tagBg: const Color(0xFFD0F0EE),
                  icon: Icons.settings_rounded,
                  title: 'Operating the App',
                  bullets: const [
                    'Provide and display your financial data',
                    'Send account emails (e.g. password resets)',
                    'Fix bugs and improve performance',
                    'Generate anonymised usage statistics',
                  ],
                ),
                const SizedBox(height: 12),

                _PolicySection(
                  tag: 'Security',
                  tagColor: const Color(0xFF1A6B68),
                  tagBg: const Color(0xFFD0F0EE),
                  icon: Icons.shield_rounded,
                  title: 'How We Protect Your Data',
                  body:
                      'All data in transit is encrypted with TLS. Data at rest is encrypted on our servers. Passwords are hashed — we can never see your plain password.',
                ),
                const SizedBox(height: 12),

                _PolicySection(
                  tag: 'Sharing',
                  tagColor: const Color(0xFF8B5000),
                  tagBg: const Color(0xFFFDF0E0),
                  icon: Icons.share_rounded,
                  title: 'We Don\'t Sell Your Data',
                  body:
                      'Your data is never sold or rented. It may be processed by cloud hosting providers under strict agreements, or disclosed if required by law.',
                ),
                const SizedBox(height: 12),

                _PolicySection(
                  tag: 'Your Rights',
                  tagColor: _tealDark,
                  tagBg: const Color(0xFFE6F4F3),
                  icon: Icons.person_rounded,
                  title: 'You\'re in Control',
                  bullets: const [
                    'Export your data anytime from Profile → Settings',
                    'Delete your account and all data permanently',
                    'Request a copy of any data we hold about you',
                    'Correct inaccurate information in your profile',
                  ],
                ),
                const SizedBox(height: 12),

                _PolicySection(
                  tag: 'Retention',
                  tagColor: const Color(0xFF8B5000),
                  tagBg: const Color(0xFFFDF0E0),
                  icon: Icons.timer_rounded,
                  title: 'Data Retention',
                  body:
                      'Your data is kept while your account is active. On deletion, all personal and financial data is permanently removed within 30 days.',
                ),

                const SizedBox(height: 24),

                // Contact
                _ContactBand(
                  title: 'Questions about your privacy?',
                  subtitle: 'We\'re happy to explain how your data is handled.',
                  buttonLabel: 'Contact Us',
                  onTap: () {},
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable widgets ─────────────────────────────────────────

class _PolicySection extends StatelessWidget {
  final String tag;
  final Color tagColor;
  final Color tagBg;
  final IconData icon;
  final String title;
  final String? body;
  final List<String>? bullets;
  final Widget? extra;

  const _PolicySection({
    required this.tag,
    required this.tagColor,
    required this.tagBg,
    required this.icon,
    required this.title,
    this.body,
    this.bullets,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2D7D7B), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (body != null)
            Text(
              body!,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                height: 1.6,
              ),
            ),
          if (bullets != null)
            ...bullets!.map(
              (b) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2D7D7B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (extra != null) ...[const SizedBox(height: 12), extra!],
        ],
      ),
    );
  }
}

class _InfoCallout extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color bgColor;

  const _InfoCallout({
    required this.icon,
    required this.text,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: color, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBand extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _ContactBand({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D7D7B), Color(0xFF4AADAA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: Color(0xFF2D7D7B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
