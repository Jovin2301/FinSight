import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';
import '../widgets/notification_bell.dart';
import 'add_expense_screen.dart';

class TransactionsScreen extends StatefulWidget {
  final List<Expense> expenses;
  final Map<String, String> categoryIcons;
  final ValueChanged<Expense> onAddExpense;
  final void Function(int index, Expense expense) onUpdateExpense;
  final ValueChanged<int> onDeleteExpense;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  const TransactionsScreen({
    super.key,
    required this.expenses,
    this.categoryIcons = const {},
    required this.onAddExpense,
    required this.onUpdateExpense,
    required this.onDeleteExpense,
    required this.unreadNotifications,
    required this.onNotificationsTap,
  });

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<String> _selectedCategories = [];
  String _selectedDate = 'All';

  Future<void> _openForm(BuildContext context, [int? index]) async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (_) => AddExpenseScreen(
        expense: index == null ? null : widget.expenses[index],
      ),
    );

    if (expense == null) return;
    index == null
        ? widget.onAddExpense(expense)
        : widget.onUpdateExpense(index, expense);
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
          'Remove "${widget.expenses[index].title}" from transactions?',
        ),
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

    if (shouldDelete == true) widget.onDeleteExpense(index);
  }

  void _openFilters(List<String> categories, List<String> dateFilters) {
    List<String> tempCategories = _selectedCategories
        .where((category) => categories.contains(category))
        .toList();
    String tempDate = _selectedDate;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Transactions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  categories.isEmpty
                      ? const Text(
                          'No categories yet',
                          style: TextStyle(color: AppColors.muted),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((category) {
                            return FilterChip(
                              label: Text(category),
                              selected: tempCategories.contains(category),
                              selectedColor: AppColors.lightMint,
                              checkmarkColor: AppColors.main,
                              onSelected: (value) {
                                sheetSetState(() {
                                  if (value) {
                                    tempCategories.add(category);
                                  } else {
                                    tempCategories.remove(category);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 18),
                  const Text(
                    'Date',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dateFilters.map((date) {
                      return ChoiceChip(
                        label: Text(date),
                        selected: tempDate == date,
                        selectedColor: AppColors.lightMint,
                        checkmarkColor: AppColors.main,
                        onSelected: (_) {
                          sheetSetState(() => tempDate = date);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategories = [];
                              _selectedDate = 'All';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategories = tempCategories;
                              _selectedDate = tempDate;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = <String>[];
    for (final expense in widget.expenses) {
      if (!categories.contains(expense.category)) {
        categories.add(expense.category);
      }
    }

    final shownSelectedCategories = _selectedCategories
        .where((category) => categories.contains(category))
        .toList();

    final dateFilters = ['All', 'Today', 'This Month'];
    final results = <MapEntry<int, Expense>>[];
    final now = DateTime.now();

    for (final entry in widget.expenses.asMap().entries) {
      final expense = entry.value;

      final categoryOk =
          shownSelectedCategories.isEmpty ||
          shownSelectedCategories.contains(expense.category);

      bool dateOk = true;
      if (_selectedDate == 'Today') {
        dateOk =
            expense.date.year == now.year &&
            expense.date.month == now.month &&
            expense.date.day == now.day;
      } else if (_selectedDate == 'This Month') {
        dateOk =
            expense.date.year == now.year && expense.date.month == now.month;
      }

      if (categoryOk && dateOk) {
        results.add(entry);
      }
    }

    results.sort((a, b) => b.value.date.compareTo(a.value.date));

    double total = 0;
    for (final entry in results) {
      total += entry.value.amount;
    }

    final hasFilters =
        shownSelectedCategories.isNotEmpty || _selectedDate != 'All';
    final filterCount =
        shownSelectedCategories.length + (_selectedDate == 'All' ? 0 : 1);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: NotificationBell(
              unreadCount: widget.unreadNotifications,
              onTap: widget.onNotificationsTap,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addTrans',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${results.length} items',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _openFilters(categories, dateFilters),
                  icon: Badge(
                    isLabelVisible: hasFilters,
                    label: Text('$filterCount'),
                    child: const Icon(Icons.filter_alt_rounded),
                  ),
                  color: hasFilters ? AppColors.main : AppColors.muted,
                ),
              ],
            ),
            if (hasFilters) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...shownSelectedCategories.map((category) {
                      return Chip(
                        label: Text(category),
                        onDeleted: () {
                          setState(() {
                            _selectedCategories.remove(category);
                          });
                        },
                      );
                    }),
                    if (_selectedDate != 'All')
                      Chip(
                        label: Text(_selectedDate),
                        onDeleted: () {
                          setState(() => _selectedDate = 'All');
                        },
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: widget.expenses.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions yet.\nTap + to add your first expense.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : results.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions match the selected filters.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, index) {
                        final originalIndex = results[index].key;
                        final expense = results[index].value;

                        return ExpenseCard(
                          expense: expense,
                          onTap: () => _openForm(context, originalIndex),
                          onDelete: () =>
                              _confirmDelete(context, originalIndex),
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
