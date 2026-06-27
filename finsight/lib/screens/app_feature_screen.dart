import 'package:flutter/material.dart';
import '../widgets/help_center_widget.dart';

class AppFeaturesScreen extends StatelessWidget {
  const AppFeaturesScreen({super.key});

  static const List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.dashboard_rounded,
      'title': 'Dashboard',
      'body':
          'Your financial overview at a glance — net balance, recent transactions, spending by category, and savings progress.',
    },
    {
      'icon': Icons.receipt_long_rounded,
      'title': 'Transaction Tracker',
      'body':
          'Log income and expenses manually or via CSV import. Filter by date, category, or amount. Attach receipt photos.',
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Budget Manager',
      'body':
          'Set monthly spending limits per category. Get notified when you\'re approaching or exceed a budget.',
    },
    {
      'icon': Icons.savings_rounded,
      'title': 'Savings Goals',
      'body':
          'Create goals like "Emergency Fund" or "New Laptop." Track progress visually and log contributions anytime.',
    },
    {
      'icon': Icons.bar_chart_rounded,
      'title': 'Insights & Reports',
      'body':
          'Monthly summaries, spending trends, and category breakdowns shown as charts. Export reports as PDF or CSV.',
    },
    {
      'icon': Icons.notifications_rounded,
      'title': 'Smart Reminders',
      'body':
          'Set reminders for recurring bills or budget check-ins. Customise frequency and notification time.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: helpBgColor,
      appBar: const TopicAppBar(title: 'App Features'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          HelpCard(
            child: Row(
              children: [
                const IconBadge(icon: Icons.auto_awesome_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('App Features',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Text('Everything FinSight can do for your finances.',
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

          const SectionLabel(text: 'What\'s Inside FinSight'),
          ..._features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HelpCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                            color: tealLight,
                            borderRadius: BorderRadius.circular(12)),
                        child: Icon(f['icon'] as IconData,
                            color: tealDark, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['title'] as String,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A1A))),
                            const SizedBox(height: 4),
                            Text(f['body'] as String,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    height: 1.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 10),

          const SectionLabel(text: 'Budget vs Savings Goals'),
          HelpCard(
            child: Row(
              children: [
                Expanded(
                  child: _comparisonCol(
                    'Budget',
                    tealDark,
                    [
                      'Monthly spending cap',
                      'Per-category limits',
                      'Resets each month',
                      'Alerts when near limit',
                    ],
                  ),
                ),
                Container(
                    width: 1, height: 130, color: const Color(0xFFEBF0F0)),
                Expanded(
                  child: _comparisonCol(
                    'Savings Goal',
                    const Color(0xFF6B5CE7),
                    [
                      'Target amount to reach',
                      'No time pressure',
                      'Track contributions',
                      'Progress bar & milestones',
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const InfoBanner(
              text:
                  'New features are added regularly. Update the app to get the latest improvements.'),
        ],
      ),
    );
  }

  Widget _comparisonCol(String label, Color color, List<String> points) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8)),
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
          const SizedBox(height: 10),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                        child: Text(p,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}