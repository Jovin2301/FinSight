import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/budget.dart';
import '../models/expense.dart';

class WalletScreen extends StatelessWidget {
  final List<Budget> budgets;
  final List<Expense> expenses;

  const WalletScreen({
    super.key,
    required this.budgets,
    required this.expenses,
  });

  double getSpent(String category) {
    double total = 0;
    for (final expense in expenses) {
      if (expense.category == category) {
        total += expense.amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Wallet')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Category Budgets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${budgets.length} items',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: budgets.isEmpty
                  ? const Center(
                      child: Text(
                        'No budgets yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: budgets.length,
                      itemBuilder: (_, index) {
                        final budget = budgets[index];
                        final spent = getSpent(budget.category);
                        return _BudgetCard(budget: budget, spent: spent);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;

  const _BudgetCard({required this.budget, required this.spent});

  @override
  Widget build(BuildContext context) {
    final left = budget.limit - spent;
    final progress = budget.limit == 0
        ? 0.0
        : (spent / budget.limit).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  budget.category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '\$${budget.limit.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.main,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '\$${spent.toStringAsFixed(2)} spent, \$${left.toStringAsFixed(2)} left',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppColors.light,
                color: left < 0 ? AppColors.red : AppColors.main,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
