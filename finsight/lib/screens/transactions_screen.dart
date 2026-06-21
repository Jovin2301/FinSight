import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';
import 'add_expense_screen.dart';

class TransactionsScreen extends StatelessWidget {
  final List<Expense> expenses;
  final ValueChanged<Expense> onAddExpense;
  final void Function(int index, Expense expense) onUpdateExpense;
  final ValueChanged<int> onDeleteExpense;

  const TransactionsScreen({
    super.key,
    required this.expenses,
    required this.onAddExpense,
    required this.onUpdateExpense,
    required this.onDeleteExpense,
  });

  double get total => expenses.fold(0, (sum, e) => sum + e.amount);

  Future<void> _openForm(BuildContext context, [int? index]) async {
    final expense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddExpenseScreen(expense: index == null ? null : expenses[index]),
      ),
    );

    if (expense == null) return;
    index == null ? onAddExpense(expense) : onUpdateExpense(index, expense);
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text('Remove "${expenses[index].title}" from transactions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) onDeleteExpense(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
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
                    'Total Spent',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Expenses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${expenses.length} items',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: expenses.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions yet.\nTap + to add your first expense.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (_, index) => ExpenseCard(
                        expense: expenses[index],
                        onTap: () => _openForm(context, index),
                        onDelete: () => _confirmDelete(context, index),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
