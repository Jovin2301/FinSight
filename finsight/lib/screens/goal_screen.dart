import 'package:flutter/material.dart';
import '../models/goal.dart';

class GoalScreen extends StatelessWidget {
  final List<Goal> goals;

  const GoalScreen({super.key, required this.goals});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Goal Screen', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '${goals.length} goals added',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
