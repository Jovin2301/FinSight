import 'package:flutter/material.dart';
import '../widgets/help_center_widget.dart';

class FinancialDataScreen extends StatelessWidget {
  const FinancialDataScreen({super.key});

  static const List<Map<String, String>> _faq = [
    {
      'q': 'How do I add a transaction manually?',
      'a':
          'Tap the "+" button on the Home or Transactions tab. Fill in the amount, category, date, and optional note, then tap Save.',
    },
    {
      'q': 'Can I import transactions from a CSV?',
      'a':
          'Yes. Go to Transactions → Import → Upload CSV. FinSight accepts exports from most Singapore banks. Map the columns and confirm.',
    },
    {
      'q': 'How do I edit or delete a transaction?',
      'a':
          'Long-press any transaction to reveal Edit and Delete options. Deleted transactions cannot be recovered, so please confirm carefully.',
    },
    {
      'q': 'What categories are available?',
      'a':
          'Default categories include Food, Transport, Shopping, Entertainment, Health, and Utilities. You can create custom categories under Settings → Categories.',
    },
    {
      'q': 'Can I attach receipts to transactions?',
      'a':
          'Yes — tap any transaction, then tap the camera icon to attach a photo from your gallery or take one directly.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: helpBgColor,
      appBar: const TopicAppBar(title: 'Financial Data'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          HelpCard(
            child: Row(
              children: [
                const IconBadge(icon: Icons.bar_chart_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Financial Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track, import, and manage your income and expenses.',
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

          const SectionLabel(text: 'Adding Transactions'),
          const StepTile(
            step: 1,
            title: 'Tap the + button',
            body:
                'Found at the bottom centre of the Home or Transactions screen.',
          ),
          const SizedBox(height: 10),
          const StepTile(
            step: 2,
            title: 'Choose type',
            body: 'Select Expense, Income, or Transfer between your accounts.',
          ),
          const SizedBox(height: 10),
          const StepTile(
            step: 3,
            title: 'Fill in details',
            body:
                'Enter amount, pick a category, set the date, and add an optional note or receipt photo.',
          ),
          const SizedBox(height: 10),
          const StepTile(
            step: 4,
            title: 'Save',
            body:
                'The transaction appears instantly in your timeline and updates your balance.',
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Supported Data Types'),
          HelpCard(
            child: Column(
              children: [
                _dataRow(
                  Icons.arrow_downward_rounded,
                  'Expenses',
                  'Money going out — bills, purchases, subscriptions',
                ),
                const Divider(height: 20),
                _dataRow(
                  Icons.arrow_upward_rounded,
                  'Income',
                  'Salary, allowance, freelance, gifts',
                ),
                const Divider(height: 20),
                _dataRow(
                  Icons.swap_horiz_rounded,
                  'Transfers',
                  'Between your own accounts — won\'t affect net balance',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Common Questions'),
          ...List.generate(
            _faq.length,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < _faq.length - 1 ? 10 : 0),
              child: FaqItem(question: _faq[i]['q']!, answer: _faq[i]['a']!),
            ),
          ),
          const SizedBox(height: 20),

          const InfoBanner(
            text:
                'FinSight stores all data locally and in your secure cloud account. We never sell your financial data.',
          ),
        ],
      ),
    );
  }

  Widget _dataRow(IconData icon, String title, String subtitle) {
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
