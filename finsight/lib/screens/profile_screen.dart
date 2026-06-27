import 'package:finsight/screens/help_center.dart';
import 'package:finsight/screens/login_screen.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:finsight/screens/private_policy.dart';
import 'package:finsight/screens/term_service.dart';
import 'package:flutter/material.dart';
import '../widgets/profile_card.dart';
import './auth_provider.dart';
import 'package:provider/provider.dart';
import './edit_username_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import '../widgets/notification_bell.dart';

class ProfileScreen extends StatefulWidget {
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  const ProfileScreen({
    super.key,
    required this.unreadNotifications,
    required this.onNotificationsTap,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedCurrency = 'SGD';
  String _selectedBudgetCycle = 'Monthly';
  String _selectedIncomeType = 'Salaried';
  String _selectedAppNotification = 'Enabled';
  String _selectedTheme = 'Light';
  DateTime? _selectedBudgetCycleDate;
  bool _prefsLoaded = false;

  Future<void> _openLoginScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_prefsLoaded) {
      _prefsLoaded = true;
      _loadPreferences(); // ← call here instead of initState
    }
  }
  

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadPreferences() async {
    final authProvider = context.read<AuthProvider>();
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/user/getUserPreferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      print('Prefs status: ${response.statusCode}');
      print('Prefs body: ${response.body}');

      if (response.statusCode == 201) {
        final prefs = jsonDecode(response.body);
        
        setState(() {
          _selectedCurrency = prefs['prefCurrency'] ?? 'SGD';
          _selectedBudgetCycle = prefs['prefBudgetCycle'] ?? 'Monthly';
          _selectedIncomeType = prefs['prefIncomeType'] ?? 'Salaried';
          _selectedTheme = prefs['prefTheme'] ?? 'Light Mode';
          _selectedAppNotification = (prefs['prefNotification'] == true) ? 'Enabled' : 'Disabled';
         
          if (prefs['prefBudgetCycleDate'] != null) {
            final day = (prefs['prefBudgetCycleDate'] as num).toInt();
            final now = DateTime.now();
            _selectedBudgetCycleDate = DateTime(now.year, now.month, day);
          }
        });
      }
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences({
    String? currency,
    String? budgetCycle,
    String? incomeType,
    String? theme,
    String? notification,
    DateTime? budgetCycleDate,
  }) async {
    final authProvider = context.read<AuthProvider>();
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/user/updateUserPreferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          if (currency != null) 'currency': currency,           // → prefCurrency
          if (incomeType != null) 'incomeType': incomeType,     // → prefIncomeType
          if (budgetCycle != null) 'prefBudgetCycle': budgetCycle, // → prefBudgetCycle
          if (budgetCycleDate != null) 'budgetCycleDate': budgetCycleDate.day, // ← just the day number e.g. 15
          if (notification != null) 'notification': notification, // → prefNotification (converted to bool in backend)
          if (theme != null) 'prefTheme': theme,                // → prefTheme
        }),
      );

      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode != 201) throw Exception('Failed to save');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDatePicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBudgetCycleDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() => _selectedBudgetCycleDate = picked);
      _savePreferences(budgetCycleDate: picked);
    }
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
    final user = context.watch<AuthProvider>().user;
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: NotificationBell(
              unreadCount: widget.unreadNotifications,
              onTap: widget.onNotificationsTap,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // profile card
            ProfileCard(
              user: user,
              onUserUpdated: (user) => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditUserDetailsScreen())
              ),
            ),
            const SizedBox(height: 24),

            // Budget Preferences 
            _sectionTitle('Budget Preferences'),
            const SizedBox(height: 12),
            _settingsTile('Default Currency', 
              value: _selectedCurrency, 
              onTap: () {
                showCurrencyPicker(
                  context: context,
                  onSelect: (Currency currency) {
                    setState(() => _selectedCurrency = currency.code);
                    _savePreferences(currency: currency.code); 
                  },
                );
              }),
            _settingsTile('Income Type',
              value: _selectedIncomeType,
              onTap: () {
                _showPicker(
                  title: 'Select Preferred Income Type',
                  options: ['Salaried', 'Freelance', 'Hourly', 'Commission'],
                  selected: _selectedIncomeType,
                  onSelect: (val) {
                    setState(() => _selectedIncomeType = val);
                    _savePreferences(incomeType: val); 
                  },
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
                  onSelect: (val) {
                    setState(() => _selectedBudgetCycle = val);
                    _savePreferences(budgetCycle: val); 
                  }
                );
              },
            ),
            _settingsTile(
              'Budget Cycle Date',
              value: _selectedBudgetCycleDate != null
                  ? 'Day ${_selectedBudgetCycleDate!.day}'  // shows "Day 15"
                  : 'Not set',
              onTap: _showDatePicker,
            ),
            const SizedBox(height: 24),

            // ── App Settings ──
            _sectionTitle('App Settings'),
            const SizedBox(height: 12),
            _settingsTile('Notifications',
              value: _selectedAppNotification,
              onTap: () {
                _showPicker(
                  title: 'Select App Notification',
                  options: ['Enabled', 'Disabled'],
                  selected: _selectedAppNotification,
                  onSelect: (val) {
                    setState(() => _selectedAppNotification = val);
                    _savePreferences(notification: val); 
                  }
                );
              },
            ),
            _settingsTile('Appearance',
              value: _selectedTheme,
              onTap: () {
                _showPicker(
                  title: 'Select App Appearance',
                  options: ['Light Mode', 'Dark Mode'],
                  selected: _selectedTheme,
                  onSelect: (val) {
                    setState(() => _selectedTheme = val);
                    _savePreferences(theme: val); 
                  }
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Support ──
            _sectionTitle('Support'),
            const SizedBox(height: 12),
            _settingsTile('Help Center', 
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpCenterScreen())
              ),
            ),
            _settingsTile('Privacy Policy', 
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())
              ),
            ),
            _settingsTile('Terms of Service', 
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())
              ),
            ),
            const SizedBox(height: 32),

            // ── Sign Out Button ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
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
