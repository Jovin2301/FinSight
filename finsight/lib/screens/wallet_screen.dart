import 'package:flutter/material.dart';
import '../models/budget.dart';

class WalletScreen extends StatelessWidget {
  final List<Budget> budgets;

  const WalletScreen({super.key, required this.budgets});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Wallet Screen', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '${budgets.length} budgets added',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
