import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';
import '../constants/app_colors.dart';
import 'add_expense_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final List<Expense> _expenses = [
    Expense(
      id: '1',
      title: 'Starbucks',
      category: 'Food',
      amount: 8.50,
      date: DateTime.now(),
    ),
    Expense(
      id: '2',
      title: 'Grab',
      category: 'Transport',
      amount: 12.30,
      date: DateTime.now(),
    ),
    Expense(
      id: '3',
      title: 'Shopee',
      category: 'Shopping',
      amount: 25.90,
      date: DateTime.now(),
    ),
  ];

  void _addExpense(Expense expense) {
    setState(() {
      _expenses.add(expense);
    });
  }

  void _deleteExpense(int index) {
    setState(() {
      _expenses.removeAt(index);
    });
  }

  void _updateExpense(int index, Expense updatedExpense) {
    setState(() {
      _expenses[index] = updatedExpense;
    });
  }

  Future<void> _openEditExpenseScreen(int index) async {
    final updatedExpense = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(expense: _expenses[index]),
      ),
    );

    if (updatedExpense != null) {
      _updateExpense(index, updatedExpense);
    }
  }

  double get _totalSpent {
    double total = 0;
    for (final expense in _expenses) {
      total += expense.amount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.darkTeal,
                    AppColors.primaryTeal,
                    AppColors.accentMint,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Spent',
                    style: TextStyle(color: AppColors.lightMint, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_totalSpent.toStringAsFixed(2)}',
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

            // section title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Expenses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkText,
                  ),
                ),
                Text(
                  '${_expenses.length} items',
                  style: const TextStyle(color: AppColors.greyText),
                ),
              ],
            ),
            const SizedBox(height: 12),

            //expense list
            Expanded(
              child: _expenses.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions yet. \nTap + to add your first expense.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.greyText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final expense = _expenses[index];

                        return ExpenseCard(
                          expense: expense,
                          onTap: () => _openEditExpenseScreen(index),
                          onDelete: () => _deleteExpense(index),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),

      // add expense button
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () async {
          final newExpense = await Navigator.push<Expense>(
            context,
            MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
          );
          if (newExpense != null) {
            _addExpense(newExpense);
          }
        },
      ),
    );
  }
}
