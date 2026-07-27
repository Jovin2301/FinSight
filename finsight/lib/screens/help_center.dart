import 'package:flutter/material.dart';
import 'account_topic_screen.dart';
import 'financial_topic_screen.dart';
import 'privacy_security_screen.dart';
import 'app_feature_screen.dart';
import 'trouble_shooting_screen.dart';
import 'contactUs_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const Color _tealDark = Color(0xFF2D7D7B);
  static const Color _bgColor = Color(0xFFEBF0F0);
  static const Color _cardColor = Color(0xFFFFFFFF);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<_FAQItem> _faqs = const [
    _FAQItem(
      question: 'How do I reset my password?',
      answer:
          'Ressetting of password is currently unavailable, so please remember your password!',
    ),
    _FAQItem(
      question: 'Does FinSight connect to my bank?',
      answer:
          'No. FinSight does not connect to any bank accounts. All financial data is entered manually by you.',
    ),
    _FAQItem(
      question: 'How do I set a monthly budget?',
      answer:
          'Tap the Wallet tab, then "+ New Budget". Choose a category, set your monthly limit, and save.',
    ),
    _FAQItem(
      question: 'What is the differences between saving goals and budget?',
      answer:
          'Saving goal accumulates money over time for a specific target without needing a reset, whereas a budget is a repeating plan that resets every period to manage your ongoing income and spending.',
    ),
    _FAQItem(
      question: 'How do I delete my account?',
      answer:
          'Go to Profile → Settings → Account → Delete Account. All your data will be permanently removed within 30 days.',
    ),
    _FAQItem(
      question: 'Why is my data not syncing?',
      answer:
          'Make sure you\'re connected to the internet. Pull down on the home screen to force a sync. If the issue persists, sign out and back in.',
    ),
  ];

  late final List<_TopicItem> _topics;

  @override
  void initState() {
    super.initState();
    _topics = [
      _TopicItem(
        icon: Icons.key_rounded,
        label: 'Account\n& Login',
        color: const Color(0xFF2D7D7B),
        screen: const AccountLoginScreen(),
      ),
      _TopicItem(
        icon: Icons.bar_chart_rounded,
        label: 'Financial\nData',
        color: const Color(0xFF2D7D7B),
        screen: const FinancialDataScreen(),
      ),
      _TopicItem(
        icon: Icons.lock_rounded,
        label: 'Privacy\n& Security',
        color: const Color(0xFF2D7D7B),
        screen: const PrivacySecurityScreen(),
      ),
      _TopicItem(
        icon: Icons.auto_awesome_rounded,
        label: 'App\nFeatures',
        color: const Color(0xFF2D7D7B),
        screen: const AppFeaturesScreen(),
      ),
      _TopicItem(
        icon: Icons.build_rounded,
        label: 'Trouble-\nshooting',
        color: const Color(0xFF2D7D7B),
        screen: const TroubleshootingScreen(),
      ),
      _TopicItem(
        icon: Icons.chat_bubble_rounded,
        label: 'Contact\nUs',
        color: const Color(0xFF2D7D7B),
        screen: const ContactUsScreen(),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? _faqs
        : _faqs
              .where(
                (f) =>
                    f.question.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    f.answer.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

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
              color: _cardColor,
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
          'Help Center',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search for help…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey[400],
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Browse Topics
          if (_searchQuery.isEmpty) ...[
            const Text(
              'Browse Topics',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: _topics.map((t) => _TopicCard(topic: t)).toList(),
            ),
            const SizedBox(height: 28),
          ],

          Row(
            children: [
              Text(
                _searchQuery.isEmpty ? 'Popular Questions' : 'Search Results',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              if (_searchQuery.isNotEmpty)
                Text(
                  '${filtered.length} found',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No results for "$_searchQuery"',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((f) => _FAQTile(item: f)),

          const SizedBox(height: 24),

          // Contact band
          Container(
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
                const Text(
                  'Still need help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Our team is happy to assist you.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Contact Us',
                      style: TextStyle(
                        color: Color(0xFF2D7D7B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final _TopicItem topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => topic.screen),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(topic.icon, color: const Color(0xFF2D7D7B), size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              topic.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQTile extends StatefulWidget {
  final _FAQItem item;
  const _FAQTile({required this.item});

  @override
  State<_FAQTile> createState() => _FAQTileState();
}

class _FAQTileState extends State<_FAQTile>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  late AnimationController _ctrl;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotate = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.item.question,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RotationTransition(
                    turns: _rotate,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF2D7D7B),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            if (_open)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFFF0F4F4), width: 1),
                  ),
                ),
                child: Text(
                  widget.item.answer,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.6,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FAQItem {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});
}

class _TopicItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget screen;
  const _TopicItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.screen,
  });
}
