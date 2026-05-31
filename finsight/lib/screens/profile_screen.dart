import 'package:finsight/screens/login_screen.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/profile_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedCurrency = 'SGD';
  String _selectedBudgetCycle = 'Monthly';
  String _selectedIncomeType = 'Salaried';

  final List<User> _userDetail = [
    User(
      userID: 1,
      userName: 'vinjo',
      userEmail: 'jovinwong@gmail.com',
      userMonthlyIncome: 8000,
      lastLogin: DateTime.now(),
      authMethod: 'Email',
      password: '123jovin',
    ),
  ];

  void _updateUserDetail(User updatedUser, int index) {
    setState(() {
      _userDetail[index] = updatedUser;
    });
  }

  Future<void> _openLoginScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void _showPicker({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 16),
              ...options.map((option) => ListTile(
                title: Text(option),
                trailing: selected == option
                    ? const Icon(Icons.check_circle, color: Color(0xFF00897B))
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  onSelect(option);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return 
    Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00897B), Color(0xFF4DB6AC)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E2D),
        elevation: 0,
        toolbarHeight: 70,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // profile card
            ProfileCard(
              user: _userDetail[0],
              onUserUpdated: (updatedUser) => _updateUserDetail(updatedUser, 0),
            ),
            const SizedBox(height: 24),

            // Budget Preferences 
            _sectionTitle('Budget Preferences'),
            const SizedBox(height: 12),
            _settingsTile('Default Currency', value: _selectedCurrency, onTap: () {
              showCurrencyPicker(
                  context: context,
                  onSelect: (Currency currency) {
                    setState(() {
                      _selectedCurrency = currency.code;
                    });
                  },
                );
              }),
            _settingsTile('Income Type',
              value: _selectedIncomeType,
              onTap: () {
                _showPicker(
                  title: 'Select Preferred Budget Cycle',
                  options: ['Salaried', 'Freelance', 'Hourly', 'Commission'],
                  selected: _selectedIncomeType,
                  onSelect: (val) => setState(() => _selectedIncomeType = val),
                );
              },
            ),
            _settingsTile('Budget Cycle',
              value: _selectedBudgetCycle,
              onTap: () {
                _showPicker(
                  title: 'Select Preferred Budget Cycle',
                  options: ['Bi-Monthly', 'Monthly', 'Weekly', 'Daily'],
                  selected: _selectedBudgetCycle,
                  onSelect: (val) => setState(() => _selectedBudgetCycle = val),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── App Settings ──
            _sectionTitle('App Settings'),
            const SizedBox(height: 12),
            _settingsTile('Notifications',
              value: 'Enabled',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature not available yet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            _settingsTile('Appearance',
              value: 'Light Mode',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature not available yet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Support ──
            _sectionTitle('Support'),
            const SizedBox(height: 12),
            _settingsTile('Help Center', 
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature not available yet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            ),
            _settingsTile('Privacy Policy', 
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature not available yet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            ),
            _settingsTile('Terms of Service', 
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Feature not available yet'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            ),
            const SizedBox(height: 32),

            // ── Sign Out Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => _openLoginScreen(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E1E2D),
      ),
    );
  }

  static Widget _settingsTile(String label, {String? value, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F6FA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1E1E2D),
                ),
              ),
              const Spacer(),
              if (value != null)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}