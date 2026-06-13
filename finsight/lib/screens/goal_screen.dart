import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/goal.dart';
import '../widgets/goal_card.dart';

class GoalScreen extends StatelessWidget {
  final List<Goal> goals;

  const GoalScreen({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Goals',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Track your saving progress',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            ...goals.map((goal) => GoalCard(goal: goal)),
          ],
        ),
      ),
    );
  }
}
