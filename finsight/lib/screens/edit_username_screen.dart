import 'package:flutter/material.dart';
import '../models/user.dart';
import '../constants/app_colors.dart';
import './profile_screen.dart';

class EditUsernameScreen extends StatefulWidget {
  final User? user;
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

    final user = widget.user;
    if (user != null) {
      _userName.text = user.userName;
      _userEmail.text = user.userEmail;
    }
  }

  void _saveDetails() {
    final user = widget.user;
    final name = _userName.text.trim();
    final email = _userEmail.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (user == null) return;

    final updatedUser = User(
      userID: user.userID,
      userName: name,
      userEmail: email,
      userMonthlyIncome: user.userMonthlyIncome,
      lastLogin: user.lastLogin,
      authMethod: user.authMethod,
      password: user.password,
    );

    Navigator.pop(context, updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit User Details',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              TextField(
                controller: _userName,
                decoration: const InputDecoration(
                  hintText: 'username',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Icon(
                    Icons.person_2_rounded,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _userEmail,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  hintText: 'User Email',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Icon(
                    Icons.email_rounded,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                ),
              ),
              const SizedBox(height: 14),
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

                )
              )
            ],
          ),
        ),
      )
    );
  }
}
