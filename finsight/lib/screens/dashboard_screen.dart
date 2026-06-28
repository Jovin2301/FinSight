import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  final List<Expense> expenses;
  final double monthlyBudget;
  final ValueChanged<Expense> onAddExpense;
  final ValueChanged<double> onBudgetChanged;
  final VoidCallback onViewTransactions;

  const DashboardScreen({
    super.key,
    required this.expenses,
    required this.monthlyBudget,
    required this.onAddExpense,
    required this.onBudgetChanged,
    required this.onViewTransactions,
  });

  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Future<void> _addExpense(BuildContext context) async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (_) => const AddExpenseScreen(),
    );
    if (expense != null) onAddExpense(expense);
  }

  Future<void> _editBudget(BuildContext context) async {
    final controller = TextEditingController(
      text: monthlyBudget.toStringAsFixed(2),
    );

    final budget = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Adjust Budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'Monthly budget'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value != null && value > 0) Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (budget != null) onBudgetChanged(budget);
  }

  @override
  Widget build(BuildContext context) {
    final recent = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final remaining = monthlyBudget - totalSpent;
    final progress = (totalSpent / monthlyBudget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Home')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Good morning',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              const Text(
                'Your money at a glance',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 18),
              _budgetCard(remaining, progress),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _quickButton(
                      Icons.add,
                      'Add Expense',
                      () => _addExpense(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickButton(
                      Icons.receipt_long_outlined,
                      'Transactions',
                      onViewTransactions,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _title('Recent Expenses', 'View all', onViewTransactions),
              _panel(
                recent.isEmpty
                    ? _empty('No recent expenses yet.')
                    : Column(
                        children: recent.take(3).map(_expenseTile).toList(),
                      ),
              ),
              const SizedBox(height: 24),
              _title('Spending Over Time'),
              _panel(_timeChart()),
              const SizedBox(height: 24),
              _title('Category Breakdown'),
              _panel(
                categoryTotals.isEmpty
                    ? _empty('No spending data yet.')
                    : Column(
                        children: categoryTotals.entries.map((entry) {
                          return _categoryTile(entry.key, entry.value);
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
              _title('Budget Overview', 'Edit', () => _editBudget(context)),
              _panel(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\$${totalSpent.toStringAsFixed(2)} / \$${monthlyBudget.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.main,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _bar(progress),
                    const SizedBox(height: 8),
                    Text(
                      '\$${remaining.toStringAsFixed(2)} left',
                      style: TextStyle(
                        color: remaining < 0 ? AppColors.red : AppColors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _budgetCard(double remaining, double progress) {
    final overBudget = remaining < 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.dark, AppColors.main, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available to spend',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${remaining.abs().toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            overBudget
                ? 'Over budget by \$${remaining.abs().toStringAsFixed(2)}'
                : '\$${totalSpent.toStringAsFixed(2)} spent of \$${monthlyBudget.toStringAsFixed(2)} budget',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _bar(progress, background: Colors.white24, color: Colors.white),
        ],
      ),
    );
  }

  Widget _quickButton(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.main),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _title(String text, [String? action, VoidCallback? onTap]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        if (action != null) TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }

  Widget _panel(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _expenseTile(Expense e) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.light,
        child: Icon(_iconFor(e.category), color: AppColors.main),
      ),
      title: Text(e.title),
      subtitle: Text(
        '${e.category} • ${e.date.day}/${e.date.month}/${e.date.year}',
      ),
      trailing: Text(
        '-\$${e.amount.toStringAsFixed(2)}',
        style: const TextStyle(
          color: AppColors.red,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _categoryTile(String category, double amount) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.light,
        child: Icon(_iconFor(category), color: AppColors.main),
      ),
      title: Text(category),
      subtitle: _bar(totalSpent == 0 ? 0 : amount / totalSpent),
      trailing: Text(
        '\$${amount.toStringAsFixed(2)}',
        style: const TextStyle(
          color: AppColors.main,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _timeChart() {
    if (expenses.isEmpty) return _empty('No spending data yet.');

    final totals = <DateTime, double>{};
    for (final e in expenses) {
      final date = DateTime(e.date.year, e.date.month, e.date.day);
      totals[date] = (totals[date] ?? 0) + e.amount;
    }

    final rows = totals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final highest = totals.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: rows.map((entry) {
          final barHeight = 80 * (entry.value / highest);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '\$${entry.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.main,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.key.day}/${entry.key.month}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _bar(
    double value, {
    Color background = AppColors.light,
    Color color = AppColors.main,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: background,
        color: color,
      ),
    );
  }

  Widget _empty(String text) {
    return Text(text, style: const TextStyle(color: AppColors.muted));
  }

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
