import 'package:flutter/material.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Goal Screen', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Feature Coming Soon', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}