import 'package:flutter/material.dart';
import '../widgets/help_center_widget.dart';

class AccountLoginScreen extends StatelessWidget {
  const AccountLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: helpBgColor,
      appBar: const TopicAppBar(title: 'Account & Login'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // Header card
          HelpCard(
            child: Row(
              children: [
                const IconBadge(icon: Icons.key_rounded),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Account & Login',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 4),
                      Text(
                          'Manage your profile, password, and login methods.',
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

          const SectionLabel(text: 'Reset Your Password'),
          const StepTile(
              step: 1,
              title: 'Go to Login screen',
              body: 'Tap "Forgot Password?" below the sign-in button.'),
          const SizedBox(height: 10),
          const StepTile(
              step: 2,
              title: 'Enter your email',
              body: 'We\'ll send a 6-digit OTP to your registered email address.'),
          const SizedBox(height: 10),
          const StepTile(
              step: 3,
              title: 'Verify OTP',
              body: 'Enter the code within 10 minutes — it expires after that.'),
          const SizedBox(height: 10),
          const StepTile(
              step: 4,
              title: 'Set new password',
              body: 'Choose a password with at least 8 characters, mixing letters and numbers.'),
          const SizedBox(height: 20),

          const SectionLabel(text: 'Common Questions'),
          const FaqItem(
            question: 'How do I change my email address?',
            answer:
                'Go to Profile → Settings → Account Details. Tap "Edit Email," enter your new address, and confirm via OTP sent to the new email.',
          ),
          const SizedBox(height: 10),
          const FaqItem(
            question: 'Can I log in with Google or Apple?',
            answer:
                'Yes! On the login screen tap "Continue with Google" or "Continue with Apple." Your account will be linked automatically on first use.',
          ),
          const SizedBox(height: 10),
          const FaqItem(
            question: 'What if I didn\'t receive the OTP?',
            answer:
                'Check your spam/junk folder first. If it\'s still missing, wait 60 seconds and tap "Resend Code." Make sure the email you entered is correct.',
          ),
          const SizedBox(height: 10),
          const FaqItem(
            question: 'How do I update my display name or avatar?',
            answer:
                'Open Profile → tap the pencil icon next to your name or photo. Changes are saved instantly.',
          ),
          const SizedBox(height: 20),

          const WarningBanner(
              text:
                  'Never share your password or OTP with anyone, including FinSight support.'),
        ],
      ),
    );
  }
}