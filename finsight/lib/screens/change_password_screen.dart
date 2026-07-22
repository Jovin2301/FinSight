import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import './auth_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

// ── Live requirement checklist row ─────────────────────────────
class _RequirementRow extends StatelessWidget {
  final String label;
  final bool met;

  const _RequirementRow({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    final color = met ? const Color(0xFF2D7D7B) : Colors.red[400];
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final _formKey = GlobalKey<FormState>();

  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;
  bool isSaving = false;

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    newController.addListener(_updatePasswordChecks);
    currentController.addListener(_onFieldChanged);
    confirmController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  void _updatePasswordChecks() {
    final value = newController.text;
    setState(() {
      _hasMinLength = value.length >= 8;
      _hasUppercase = value.contains(RegExp(r'[A-Z]'));
      _hasNumber = value.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;+=~`]'));
    });
  }

  bool get _allRequirementsMet =>
      _hasMinLength && _hasUppercase && _hasNumber && _hasSpecialChar;

  bool get _canSubmit =>
      currentController.text.isNotEmpty &&
      _allRequirementsMet &&
      confirmController.text == newController.text &&
      confirmController.text.isNotEmpty;

  @override
  void dispose() {
    newController.removeListener(_updatePasswordChecks);
    currentController.removeListener(_onFieldChanged);
    confirmController.removeListener(_onFieldChanged);
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;

      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/user/changeUserPassword'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'userid': user?['id'],
          'currentPassword': currentController.text,
          'password': newController.text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
          ),
        );
        Navigator.pop(context);
      } else {
        String message = 'Could not change password';
        try {
          final data = jsonDecode(response.body);
          if (data is Map && data['error'] != null) {
            message = data['error'].toString();
          }
        } catch (_) {
          // response body wasn't JSON; fall back to the default message
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not connect to server')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Change Password"),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Form(

            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                const Text(
                  "Keep your account secure by creating a strong password.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 35),

                TextFormField(
                  controller: currentController,
                  obscureText: hideCurrent,
                  decoration: InputDecoration(
                    labelText: "Current Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideCurrent
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          hideCurrent = !hideCurrent;
                        });
                      },
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty
                          ? "Enter current password"
                          : null,
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: newController,
                  obscureText: hideNew,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideNew
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          hideNew = !hideNew;
                        });
                      },
                    ),
                  ),
                  validator: (value) {

                    if (value == null || value.isEmpty) {
                      return "Enter a new password";
                    }
                    if (!_allRequirementsMet) {
                      return "Password does not meet all requirements";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: confirmController,
                  obscureText: hideConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          hideConfirm = !hideConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {

                    if (value != newController.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Password must contain:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _RequirementRow(
                        label: "At least 8 characters",
                        met: _hasMinLength,
                      ),
                      const SizedBox(height: 8),
                      _RequirementRow(
                        label: "One uppercase letter",
                        met: _hasUppercase,
                      ),
                      const SizedBox(height: 8),
                      _RequirementRow(
                        label: "One number",
                        met: _hasNumber,
                      ),
                      const SizedBox(height: 8),
                      _RequirementRow(
                        label: "One special character",
                        met: _hasSpecialChar,
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: (isSaving || !_canSubmit) ? null : changePassword,
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Change Password",
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}