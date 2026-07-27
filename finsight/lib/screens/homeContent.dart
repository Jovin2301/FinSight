import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/app_colors.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import 'add_expense_screen.dart';
import 'package:provider/provider.dart';
import './auth_provider.dart';
import '../widgets/budget_card.dart';
import '../widgets/expense_card.dart';
import '../widgets/notification_bell.dart';

class HomeContent extends StatelessWidget {
  final List<Expense> expenses;
  final List<Budget> budgets;
  final List<Goal> goals;
  final ValueChanged<Expense> onAddExpense;
  final VoidCallback onViewTransactions;
  final VoidCallback onViewBudgets;
  final VoidCallback onViewGoals;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  const HomeContent({
    super.key,
    required this.expenses,
    required this.budgets,
    required this.goals,
    required this.onAddExpense,
    required this.onViewTransactions,
    required this.onViewBudgets,
    required this.onViewGoals,
    required this.unreadNotifications,
    required this.onNotificationsTap,
  });

  List<Expense> get monthlyExpenses {
    final now = DateTime.now();
    return expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
  }

  double get totalSpent =>
      monthlyExpenses.fold(0, (sum, expense) => sum + expense.amount);
  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final expense in monthlyExpenses) {
      totals[expense.category] =
          (totals[expense.category] ?? 0) + expense.amount;
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
    final expense = await showDialog<Expense>(
      context: context,
      builder: (_) => const AddExpenseScreen(),
    );
    if (expense != null) onAddExpense(expense);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final username = (user?['username'] ?? 'User').toString();
    final initial = username.trim().isEmpty
        ? 'U'
        : username.trim()[0].toUpperCase();
    final monthName = _monthName(DateTime.now().month);
    final recent = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 82,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.main,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: NotificationBell(
              unreadCount: unreadNotifications,
              onTap: onNotificationsTap,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.payments_outlined,
                        color: AppColors.main,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$monthName spending',
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${totalSpent.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${monthlyExpenses.length} items',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.category_outlined,
                      color: AppColors.main,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Top category',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                    const Spacer(),
                    Text(
                      topCategory,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
            children: [
              Expanded(
                child: _actionButton(
                  Icons.add_rounded,
                  'Add Expense',
                  () => _addExpense(context),
                  backgroundColor: const Color(0xFFDDF3F1),
                  iconColor: AppColors.main,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _actionButton(
                  Icons.receipt_long_rounded,
                  'Transactions',
                  onViewTransactions,
                  backgroundColor: const Color(0xFFEAF2FF),
                  iconColor: const Color(0xFF4B78B8),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _actionButton(
                  Icons.account_balance_wallet_outlined,
                  'Budgets',
                  onViewBudgets,
                  backgroundColor: AppColors.light,
                  iconColor: AppColors.main,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _actionButton(
                  Icons.savings_outlined,
                  'Goals',
                  onViewGoals,
                  backgroundColor: const Color(0xFFFFF4D8),
                  iconColor: const Color(0xFFB7791F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

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
          const SizedBox(height: 10),
          recent.isEmpty
              ? _emptyCard('No recent expenses yet.')
              : Column(
                  children: recent
                      .take(3)
                      .map(
                        (expense) => ExpenseCard(
                          expense: expense,
                          categoryIcon: _budgetIconFor(expense.category),
                          onTap: onViewTransactions,
                        ),
                      )
                      .toList(),
                ),
          const SizedBox(height: 10),

          // ── Budgets ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Budgets',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(onPressed: onViewBudgets, child: const Text('Manage')),
            ],
          ),
          const SizedBox(height: 10),
          _budgetsCard(),
          const SizedBox(height: 14),

          // ── Category Breakdown ──
          const Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: _categoryBreakdownChart(),
          ),
          const SizedBox(height: 24),

          // ── Goals ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
              TextButton(onPressed: onViewGoals, child: const Text('View all')),
            ],
          ),
          const SizedBox(height: 10),
          _goalsCard(),
        ],
      ),
    );
  }

  Widget _goalsCard() {
    if (goals.isEmpty) return _emptyCard('No goals added yet.');

    return Column(
      children: goals.take(2).map((goal) {
        final progress = goal.targetAmount == 0
            ? 0.0
            : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: onViewGoals,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4D8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('🎯', style: TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${goal.savedAmount.toStringAsFixed(0)} / \$${goal.targetAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% saved',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _bar(progress),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _budgetsCard() {
    if (budgets.isEmpty) return _emptyCard('No budgets yet.');

    final shownBudgets = budgets.take(2).toList();

    return Column(
      children: shownBudgets.map((budget) {
        return BudgetCard(
          budget: budget,
          spent: budget.spent,
          onTap: onViewBudgets,
          compact: true,
        );
      }).toList(),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  static Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: iconColor, size: 25),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String? _budgetIconFor(String category) {
    for (final budget in budgets) {
      if (budget.category.toLowerCase() == category.toLowerCase()) {
        return budget.icon;
      }
    }
    return null;
  }

  Widget _categoryBreakdownChart() {
    if (sortedCategoryTotals.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No spending this month',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    const colors = [
      AppColors.main,
      Color(0xFFEF8A78),
      Color(0xFFF2B84B),
      Color(0xFF5B8DEF),
      Color(0xFF8C7BC8),
    ];
    final entries = sortedCategoryTotals;

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 38,
              sectionsSpace: 3,
              sections: List.generate(entries.length, (index) {
                final percentage = entries[index].value / totalSpent * 100;
                return PieChartSectionData(
                  value: entries[index].value,
                  color: colors[index % colors.length],
                  radius: 46,
                  title: percentage >= 8
                      ? '${percentage.toStringAsFixed(0)}%'
                      : '',
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: List.generate(entries.length, (index) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  entries[index].key,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            );
          }),
        ),
      ],
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

  static Widget _emptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(text, style: const TextStyle(color: AppColors.muted)),
    );
  }
}

// ignore_for_file: file_names
