import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import 'add_expense_screen.dart';
import 'package:provider/provider.dart';
import './auth_provider.dart';

class HomeContent extends StatelessWidget {
  final List<Expense> expenses;
  final List<Budget> budgets;
  final List<Goal> goals;
  final double monthlyBudget;
  final ValueChanged<Expense> onAddExpense;
  final ValueChanged<double> onBudgetChanged;
  final VoidCallback onViewTransactions;

  const HomeContent({
    super.key,
    required this.expenses,
    required this.budgets,
    required this.goals,
    required this.monthlyBudget,
    required this.onAddExpense,
    required this.onBudgetChanged,
    required this.onViewTransactions,
  });

  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);
  double get totalSaved => goals.fold(0, (sum, goal) => sum + goal.savedAmount);
  double get totalGoalTarget =>
      goals.fold(0, (sum, goal) => sum + goal.targetAmount);
  double get budgetUsedPercent =>
      monthlyBudget == 0 ? 0 : (totalSpent / monthlyBudget) * 100;

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  String get topCategory {
    if (categoryTotals.isEmpty) return 'None';

    return sortedCategoryTotals.first.key;
  }

  List<MapEntry<String, double>> get sortedCategoryTotals {
    final entries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
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
    final isOverBudget = remaining < 0;
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
                gradient: LinearGradient(
                  colors: isOverBudget
                      ? const [Color(0xFFB85C68), Color(0xFFF28B82)]
                      : const [
                          AppColors.dark,
                          AppColors.main,
                          AppColors.accent,
                        ],
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
                    isOverBudget ? 'Over budget by' : 'Available to spend',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
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
                  const SizedBox(height: 8),
                  Text(
                    isOverBudget
                        ? 'Over budget this month'
                        : 'Within budget this month',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _balanceStat(
                          'Monthly Budget',
                          '\$${monthlyBudget.toStringAsFixed(2)}',
                          Icons.account_balance_wallet_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _balanceStat(
                          'Spent',
                          '\$${totalSpent.toStringAsFixed(2)}',
                          Icons.receipt_long_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Budget progress',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '${budgetUsedPercent.toStringAsFixed(0)}% used',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _bar(
                    progress,
                    background: Colors.white24,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _monthSummary(),
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
              children: [
                Expanded(
                  child: _actionButton(
                    Icons.add_rounded,
                    'Add Expense',
                    () => _addExpense(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    Icons.receipt_long_rounded,
                    'Transactions',
                    onViewTransactions,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    Icons.account_balance_wallet_outlined,
                    'Edit Budget',
                    () => _editBudget(context),
                  ),
                ),
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
                    children: recent
                        .take(3)
                        .map(
                          (e) => _transactionTile(
                            _iconFor(e.category),
                            e.title,
                            '${e.category} • ${e.date.day}/${e.date.month}/${e.date.year}',
                            '-\$${e.amount.toStringAsFixed(2)}',
                            false,
                          ),
                        )
                        .toList(),
                  ),
            const SizedBox(height: 24),

            // ── Budgets ──
            const Text(
              'Budgets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            _budgetsCard(),
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
                      children: sortedCategoryTotals.map((entry) {
                        return _categoryTile(entry.key, entry.value);
                      }).toList(),
                    ),
            ),
            const SizedBox(height: 24),

            // ── Goals ──
            const Text(
              'Goals',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 12),
            _goalsCard(),
            const SizedBox(height: 24),

            // ── Daily Spending ──
            const Text(
              'Daily Spending',
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
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _monthSummary() {
    final remaining = monthlyBudget - totalSpent;
    final remainingText = remaining < 0
        ? 'Over by \$${remaining.abs().toStringAsFixed(2)}'
        : '\$${remaining.toStringAsFixed(2)}';

    return Container(
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
          const Text(
            'This Month',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 10) / 2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _summaryTile(
                    Icons.payments_outlined,
                    'Total spent',
                    '\$${totalSpent.toStringAsFixed(2)}',
                    tileWidth,
                  ),
                  _summaryTile(
                    Icons.account_balance_wallet_outlined,
                    'Budget left',
                    remainingText,
                    tileWidth,
                    valueColor: remaining < 0 ? AppColors.red : AppColors.text,
                  ),
                  _summaryTile(
                    Icons.percent_rounded,
                    'Budget used',
                    '${budgetUsedPercent.toStringAsFixed(0)}%',
                    tileWidth,
                  ),
                  _summaryTile(
                    Icons.category_outlined,
                    'Top category',
                    topCategory,
                    tileWidth,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(
    IconData icon,
    String label,
    String value,
    double width, {
    Color valueColor = AppColors.text,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.main, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalsCard() {
    if (goals.isEmpty) return _emptyCard('No goals added yet.');

    return Container(
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
            '\$${totalSaved.toStringAsFixed(2)} saved',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${goals.length} goals · \$${totalGoalTarget.toStringAsFixed(2)} target',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Column(
            children: goals.take(2).map((goal) {
              final goalProgress = goal.targetAmount == 0
                  ? 0.0
                  : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);

              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${goal.savedAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _bar(goalProgress),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _budgetsCard() {
    if (budgets.isEmpty) return _emptyCard('No category budgets yet.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: budgets.take(3).map((budget) {
          final spent = categoryTotals[budget.category] ?? 0;
          final progress = budget.limit == 0
              ? 0.0
              : (spent / budget.limit).clamp(0.0, 1.0);
          final overBudget = spent > budget.limit;
          final overAmount = spent - budget.limit;
          final isLast = budget == budgets.take(3).last;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      budget.category,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      overBudget
                          ? 'Over by \$${overAmount.toStringAsFixed(0)}'
                          : '\$${spent.toStringAsFixed(0)} / \$${budget.limit.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: overBudget ? AppColors.red : AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _bar(
                  progress,
                  color: progress >= 1 ? AppColors.red : AppColors.main,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
          SizedBox(
            width: 80,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _transactionTile(
    IconData icon,
    String title,
    String subtitle,
    String amount,
    bool isIncome,
  ) {
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
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
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
    final percent = totalSpent == 0 ? 0 : (amount / totalSpent) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                '\$${amount.toStringAsFixed(2)} · ${percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _bar(totalSpent == 0 ? 0 : amount / totalSpent),
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
          final barHeight = (80 * (entry.value / highest)).clamp(10.0, 80.0);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '\$${entry.value.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.main,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 24,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.key.day}/${entry.key.month}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
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
