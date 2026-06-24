import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../widgets/budget_card.dart';

class WalletScreen extends StatelessWidget {
  final List<Budget> budgets;
  final List<Expense> expenses;
  final ValueChanged<Budget> onAddBudget;
  final void Function(int index, Budget budget) onUpdateBudget;
  final ValueChanged<int> onDeleteBudget;

  const WalletScreen({
    super.key,
    required this.budgets,
    required this.expenses,
    required this.onAddBudget,
    required this.onUpdateBudget,
    required this.onDeleteBudget,
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

  Future<void> _openForm(BuildContext context, [int? index]) async {
    final budgetToEdit = index == null ? null : budgets[index];
    final categoryController = TextEditingController(
      text: budgetToEdit?.category ?? '',
    );
    final limitController = TextEditingController(
      text: budgetToEdit?.limit.toStringAsFixed(2) ?? '',
    );

    final budget = await showDialog<Budget>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(index == null ? 'New Budget' : 'Edit Budget')),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(hintText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: limitController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'Budget limit'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final category = categoryController.text.trim();
              final limit = double.tryParse(limitController.text.trim());

              if (category.isEmpty || limit == null || limit <= 0) return;

              Navigator.pop(
                context,
                Budget(
                  id:
                      budgetToEdit?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  category: category,
                  limit: limit,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    categoryController.dispose();
    limitController.dispose();

    if (budget == null) return;
    if (index == null) {
      onAddBudget(budget);
    } else {
      onUpdateBudget(index, budget);
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text('Remove the ${budgets[index].category} budget?'),
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

    if (shouldDelete == true) onDeleteBudget(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Wallet')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
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
                        return BudgetCard(
                          budget: budget,
                          spent: spent,
                          onTap: () => _openForm(context, index),
                          onDelete: () => _confirmDelete(context, index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
