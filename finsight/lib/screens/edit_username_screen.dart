import 'package:finsight/screens/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditUserDetailsScreen extends StatefulWidget {
  const EditUserDetailsScreen({super.key});

  @override
  State<EditUserDetailsScreen> createState() => _EditUserDetailsScreenState();
}

class _EditUserDetailsScreenState extends State<EditUserDetailsScreen> {
  static const Color _tealDark = Color(0xFF2D7D7B);
  static const Color _bgColor = Color(0xFFEBF0F0);
  static const Color _inkDark = Color(0xFF1A2D3D);

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  bool _changesMade = false;

  @override
  void initState() {
    super.initState();
    _usernameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();

  //   if (_usernameController.text.isEmpty &&
  //       _emailController.text.isEmpty) {
  //     final user = context.read<AuthProvider>().user;

  //     _usernameController.text = user?['username'] ?? '';
  //     _emailController.text = user?['email'] ?? '';
  //   }
  // }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final user = context.read<AuthProvider>().user;

    // Remove the isEmpty guard — always sync with latest user data
    // But temporarily remove the listener to avoid triggering _onChanged
    _usernameController.removeListener(_onChanged);
    _emailController.removeListener(_onChanged);

    _usernameController.text = user?['username'] ?? '';
    _emailController.text = user?['email'] ?? '';

    _usernameController.addListener(_onChanged);
    _emailController.addListener(_onChanged);

    setState(() => _changesMade = false);
  }

  void _onChanged() => setState(() => _changesMade = true);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.user;
      print(user);

      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/user/updateUserDetail'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
        body: jsonEncode({
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'userid': user?['id']
        }),
      );

      print('code ${response.statusCode}');
      print('body ${response.body}');

      if (response.statusCode == 201) {
        final updatedUser = jsonDecode(response.body);
        
        // Update local provider
        authProvider.updateUser({
          'username': updatedUser?['userName'],
          'email': updatedUser?['userEmail']
        });
        print('Updated user keys: ${updatedUser.keys}');

        setState(() {
          _changesMade = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
          ),
        );
      } else {
        throw Exception('Failed to update profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final username = user?['username'] ?? '';
    final userEmail = user?['email'] ?? '';
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _tealDark, size: 18),
          ),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _inkDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_changesMade)
            GestureDetector(
              onTap: () {
                _usernameController.text = username;
                _emailController.text = userEmail;
                setState(() => _changesMade = false);
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Reset',
                  style: TextStyle(
                      color: Colors.deepOrangeAccent[500],
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 4),

            // ── Avatar section ──────────────────────────────
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D7D7B), Color(0xFF4AADAA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _tealDark.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _bgColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: _tealDark, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                username,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _inkDark,
                ),
              ),
            ),
            Center(
              child: Text(
                userEmail,
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),

            const SizedBox(height: 28),

            // ── Personal Info card ──────────────────────────
            _SectionCard(
              label: 'Personal Information',
              children: [
                _FieldItem(
                  label: 'Username',
                  controller: _usernameController,
                  icon: Icons.person_rounded,
                  hint: 'Enter your username',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                ),
                const _Divider(),
                _FieldItem(
                  label: 'Email Address',
                  controller: _emailController,
                  icon: Icons.email_rounded,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                )
              ],
            ),

            const SizedBox(height: 14),

            // ── Save button ─────────────────────────────────
            AnimatedOpacity(
              opacity: _changesMade ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: _changesMade && !_isSaving ? _save : null,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _changesMade
                        ? const LinearGradient(
                            colors: [Color(0xFF2D7D7B), Color(0xFF4AADAA)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: _changesMade ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: _changesMade
                        ? [
                            BoxShadow(
                              color: _tealDark.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Security card ───────────────────────────────
            _SectionCard(
              label: 'Security',
              children: [
                _ActionRow(
                  icon: Icons.lock_rounded,
                  label: 'Change Password',
                  onTap: () {},
                ),
                const _Divider(),
                _ActionRow(
                  icon: Icons.shield_rounded,
                  label: 'Two-Factor Authentication',
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4F3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Off',
                      style: TextStyle(
                          fontSize: 11,
                          color: _tealDark,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 14),

          ],
        ),
      ),
    );
  }

}

// ── Section card wrapper ──────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _SectionCard({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey[500],
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Editable field row ────────────────────────────────────────
class _FieldItem extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FieldItem({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2D7D7B), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  validator: validator,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2D3D),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle:
                        TextStyle(color: Colors.grey[400], fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.edit_rounded, color: Colors.grey[300], size: 16),
        ],
      ),
    );
  }
}

// ── Tappable action row ───────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? textColor;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    this.textColor,
    this.iconColor,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF2D7D7B)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: iconColor ?? const Color(0xFF2D7D7B), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? const Color(0xFF1A2D3D),
                ),
              ),
            ),
            trailing ??
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[300], size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Hairline divider ──────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, thickness: 1, color: Color(0xFFF0F4F4), indent: 64);
  }
}