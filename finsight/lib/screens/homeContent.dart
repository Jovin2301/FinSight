import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';
import 'package:provider/provider.dart';
import './auth_provider.dart';

class HomeContent extends StatelessWidget {
  final List<Expense> expenses;
  final double monthlyBudget;
  final ValueChanged<Expense> onAddExpense;
  final ValueChanged<double> onBudgetChanged;
  final VoidCallback onViewTransactions;

  const HomeContent({
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
    final expense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
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
    final user = context.watch<AuthProvider>().user;
    final recent = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final remaining = monthlyBudget - totalSpent;
    final progress = monthlyBudget > 0
        ? (totalSpent / monthlyBudget).clamp(0.0, 1.0)
        : 0.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header ──
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.light,
                  child: Text(
                    'V',
                    style: TextStyle(
                      color: AppColors.main,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning 👋',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                      Text(
                        '${user?['username'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                _headerIcon(Icons.search_rounded, () {}),
                const SizedBox(width: 8),
                _headerIcon(Icons.notifications_outlined, () {}),
              ],
            ),
            const SizedBox(height: 24),

            // ── Balance Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.dark, AppColors.main, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.main.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${remaining.abs().toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _balanceStat('Income', '\$${monthlyBudget.toStringAsFixed(2)}',
                          Icons.arrow_downward_rounded),
                      const SizedBox(width: 32),
                      _balanceStat('Expenses', '\$${totalSpent.toStringAsFixed(2)}',
                          Icons.arrow_upward_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bar(progress, background: Colors.white24, color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick Actions ──
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _actionButton(Icons.add_rounded, 'Add', () => _addExpense(context)),
                _actionButton(Icons.receipt_long_rounded, 'Transactions', onViewTransactions),
                _actionButton(Icons.account_balance_wallet_outlined, 'Budget', () => _editBudget(context)),
                _actionButton(Icons.more_horiz_rounded, 'More', () {}),
              ],
            ),
            const SizedBox(height: 24),

            // ── Recent Expenses ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                TextButton(
                  onPressed: onViewTransactions,
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            recent.isEmpty
                ? _emptyCard('No recent expenses yet.')
                : Column(
                    children: recent.take(3).map((e) => _transactionTile(
                      _iconFor(e.category),
                      e.title,
                      '${e.category} • ${e.date.day}/${e.date.month}/${e.date.year}',
                      '-\$${e.amount.toStringAsFixed(2)}',
                      false,
                    )).toList(),
                  ),
            const SizedBox(height: 24),

            // ── Spending Over Time ──
            const Text(
              'Spending Over Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: _timeChart(),
            ),
            const SizedBox(height: 24),

            // ── Category Breakdown ──
            const Text(
              'Category Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: categoryTotals.isEmpty
                  ? _empty('No spending data yet.')
                  : Column(
                      children: categoryTotals.entries.map((entry) {
                        return _categoryTile(entry.key, entry.value);
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // ── Budget Overview ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Budget Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                TextButton(
                  onPressed: () => _editBudget(context),
                  child: const Text('Edit'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '\$${totalSpent.toStringAsFixed(2)} / \$${monthlyBudget.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.main,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _bar(progress),
                  const SizedBox(height: 10),
                  Text(
                    remaining < 0
                        ? 'Over budget by \$${remaining.abs().toStringAsFixed(2)}'
                        : '\$${remaining.toStringAsFixed(2)} left',
                    style: TextStyle(
                      color: remaining < 0 ? AppColors.red : AppColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  static Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.text, size: 22),
      ),
    );
  }

  static Widget _balanceStat(String label, String amount, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 12)),
            Text(amount,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ],
        ),
      ],
    );
  }

  static Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.main, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  static Widget _transactionTile(
      IconData icon, String title, String subtitle, String amount, bool isIncome) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.main),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isIncome ? AppColors.main : AppColors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryTile(String category, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconFor(category), color: AppColors.main, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                _bar(totalSpent == 0 ? 0 : amount / totalSpent),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.main,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
          final barHeight = (80 * (entry.value / highest)).clamp(10.0, 80.0); // reduced from 120 to 80

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min, // added
              children: [
                Text(
                  '\$${entry.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.main,
                    fontSize: 10, // reduced from 11
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // added
                ),
                const SizedBox(height: 4), // reduced from 6
                Container(
                  width: 28,
                  height: barHeight,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.dark, AppColors.accent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6), // reduced from 8
                Text(
                  '${entry.key.day}/${entry.key.month}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10, // reduced from 11
                  ),
                  overflow: TextOverflow.ellipsis, // added
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _bar(
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

  static Widget _empty(String text) {
    return Text(text, style: const TextStyle(color: AppColors.muted));
  }

  static Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
    );
  }

  static IconData _iconFor(String category) {
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