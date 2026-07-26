import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const Color _tealDark = Color(0xFF2D7D7B);
  static const Color _bgColor = Color(0xFFEBF0F0);

  static const List<_TermsSection> _sections = [
    _TermsSection(
      number: '1',
      title: 'About FinSight',
      body:
          'FinSight is a personal finance tracking app built under NUS Orbital 2026. It is provided free of charge for personal and educational use.',
    ),
    _TermsSection(
      number: '2',
      title: 'Eligibility',
      body:
          'You must be at least 13 years old to use FinSight. By creating an account, you confirm you meet this requirement.',
    ),
    _TermsSection(
      number: '3',
      title: 'Your Account',
      bullets: [
        'You are responsible for keeping your login credentials confidential.',
        'You are responsible for all activity under your account.',
        'Notify us immediately if you suspect unauthorised access.',
      ],
    ),
    _TermsSection(
      number: '4',
      title: 'Acceptable Use',
      body: 'You must not:',
      bullets: [
        'Use the app for any unlawful purpose',
        'Attempt to reverse-engineer or tamper with the app',
        'Access other users\' accounts or data',
        'Use automated tools to scrape the service',
      ],
    ),
    _TermsSection(
      number: '5',
      title: 'Financial Disclaimer',
      isWarning: true,
      body:
          'FinSight is a tracking tool, not a financial advisor. Nothing in this app is financial, investment, or legal advice. Always consult a qualified professional before making financial decisions.',
    ),
    _TermsSection(
      number: '6',
      title: 'Limitation of Liability',
      body:
          'FinSight is provided "as is." We are not liable for data loss, decisions made from app insights, or disruptions to service. As a student project, enterprise-grade uptime is not guaranteed.',
    ),
    _TermsSection(
      number: '7',
      title: 'Governing Law',
      body:
          'These Terms are governed by the laws of Singapore. Disputes fall under the jurisdiction of Singapore courts.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _tealDark,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'Terms of Service',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.share_outlined,
                color: _tealDark,
                size: 18,
              ),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Notice banner ───────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E8),
              border: Border.all(color: const Color(0xFFF5C842), width: 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Text('📋', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'By using FinSight, you agree to these terms. Please read before continuing.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.brown[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meta info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 5),
                Text(
                  'Last updated June 2026',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(width: 12),
                Icon(Icons.school_rounded, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 5),
                Text(
                  'NUS Orbital 2026',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          // ── Scrollable sections ─────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              itemCount: _sections.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _TermsTile(section: _sections[i]),
            ),
          ),

          // ── Pinned accept footer ────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEBF0F0), width: 1),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              14,
              20,
              MediaQuery.of(context).padding.bottom + 14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'By tapping "I Understand", you confirm you have read and agreed to these Terms.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _tealDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'I Understand',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Terms tile ────────────────────────────────────────────────
class _TermsTile extends StatelessWidget {
  final _TermsSection section;
  const _TermsTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: section.isWarning
            ? Border.all(color: const Color(0xFFF9D0B8), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Number badge
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: section.isWarning
                      ? const Color(0xFFFDF0E0)
                      : const Color(0xFFE6F4F3),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    section.number,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: section.isWarning
                          ? const Color(0xFFE05C2A)
                          : const Color(0xFF2D7D7B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              if (section.isWarning)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFE05C2A),
                  size: 18,
                ),
            ],
          ),
          const SizedBox(height: 10),

          if (section.isWarning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF0E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                section.body!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7A3010),
                  height: 1.6,
                ),
              ),
            )
          else ...[
            if (section.body != null)
              Text(
                section.body!,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),
            if (section.bullets != null)
              ...section.bullets!.map(
                (b) => Padding(
                  padding: const EdgeInsets.only(top: 7),
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
          ],
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────
class _TermsSection {
  final String number;
  final String title;
  final String? body;
  final List<String>? bullets;
  final bool isWarning;

  const _TermsSection({
    required this.number,
    required this.title,
    this.body,
    this.bullets,
    this.isWarning = false,
  });
}
