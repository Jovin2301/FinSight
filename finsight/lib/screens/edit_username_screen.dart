import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../screens/auth_provider.dart';

class EditUsernameScreen extends StatefulWidget {
  final Map<String, dynamic>? user;
  const EditUsernameScreen({super.key, this.user});

  @override
  State<EditUsernameScreen> createState() => _EditUsernameScreenState();
}

class _EditUsernameScreenState extends State<EditUsernameScreen> {
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _userEmail = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      print('user in edit screen: $user'); // check what's here
      if (user != null) {
        _userName.text = user['username'] ?? '';
        _userEmail.text = user['email'] ?? '';
        setState(() {});
      }
    });
  }

  void _saveDetails() {
    final name = _userName.text.trim();
    final email = _userEmail.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // build updated map, keeping existing fields and overwriting the changed ones
    final updatedUser = {
      ...?widget.user,       // spread existing fields (userID, userMonthlyIncome, etc.)
      'userName': name,
      'userEmail': email,
    };

    Navigator.pop(context, updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit User Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 16),

              // ── Username ──
              const Text(
                'Username',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _userName,
                decoration: InputDecoration(
                  hintText: user?['userName'] ?? 'Enter username',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: const Icon(
                    Icons.person_2_rounded,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Email ──
              const Text(
                'Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _userEmail,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: user?['userEmail'] ?? 'Enter email',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: const Icon(
                    Icons.email_rounded,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}