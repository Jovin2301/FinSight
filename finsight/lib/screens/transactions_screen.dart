import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/expense.dart';
import '../widgets/expense_card.dart';
import '../widgets/notification_bell.dart';
import 'add_expense_screen.dart';
import 'bill_scan_dialog.dart';
import 'receipt_scan_dialog.dart';

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

  Future<void> _openReceiptScan() async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (_) => const ReceiptScanDialog(),
    );

    if (expense != null) {
      widget.onAddExpense(expense);
    }
  }

  Future<void> _openBillScan() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const BillScanDialog(),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bill scan details confirmed. Database save next.'),
        ),
      );
    }
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

  String _monthLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[date.month - 1];
  }

  List<DateTime> _recentMonths(DateTime now) {
    return List.generate(6, (index) {
      return DateTime(now.year, now.month - 5 + index);
    });
  }

  Widget _chartContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _monthlySpendingChart(DateTime now) {
    final months = _recentMonths(now);
    final totals = <double>[];

    for (final month in months) {
      double total = 0;
      for (final expense in widget.expenses) {
        if (expense.date.year == month.year &&
            expense.date.month == month.month) {
          total += expense.amount;
        }
      }
      totals.add(total);
    }

    final highest = totals.fold<double>(0, math.max);
    if (highest == 0) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No monthly spending yet',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          maxY: highest * 1.2,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= months.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _monthLabel(months[index]),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '\$${rod.toY.toStringAsFixed(2)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(totals.length, (index) {
            final isCurrentMonth = index == totals.length - 1;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: totals[index],
                  width: 20,
                  color: isCurrentMonth ? AppColors.main : AppColors.accent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _categorySpendingChart(DateTime now) {
    final totals = <String, double>{};
    for (final expense in widget.expenses) {
      if (expense.date.year == now.year && expense.date.month == now.month) {
        totals[expense.category] =
            (totals[expense.category] ?? 0) + expense.amount;
      }
    }

    if (totals.isEmpty) {
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
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.value);

    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 38,
              sectionsSpace: 3,
              sections: List.generate(entries.length, (index) {
                final percentage = entries[index].value / total * 100;
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
        tooltip: 'Add transaction',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
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
            child: Row(
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
                        hasFilters ? 'Filtered Spending' : 'Total Spent',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${results.length} items',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final chartWidth = wide
                  ? (constraints.maxWidth - 14) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  SizedBox(
                    width: chartWidth,
                    child: _chartContainer(
                      title: 'Monthly Spending',
                      subtitle: 'Last 6 months',
                      child: _monthlySpendingChart(now),
                    ),
                  ),
                  SizedBox(
                    width: chartWidth,
                    child: _chartContainer(
                      title: 'Spending by Category',
                      subtitle: '${_monthLabel(now)} ${now.year}',
                      child: _categorySpendingChart(now),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Expenses',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${results.length} items',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              Row(
                children: [
                  _scanMenuButton(),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Filter transactions',
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
            ],
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...shownSelectedCategories.map((category) {
                  return Chip(
                    label: Text(category),
                    onDeleted: () {
                      setState(() => _selectedCategories.remove(category));
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
          ],
          const SizedBox(height: 12),
          if (widget.expenses.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No transactions yet.\nTap + to add your first expense.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else if (results.isEmpty)
            const SizedBox(
              height: 160,
              child: Center(
                child: Text(
                  'No transactions match the selected filters.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            )
          else
            ...results.map((entry) {
              final originalIndex = entry.key;
              final expense = entry.value;

              return ExpenseCard(
                expense: expense,
                categoryIcon: widget.categoryIcons[expense.category],
                onTap: () => _openForm(context, originalIndex),
                onDelete: () => _confirmDelete(context, originalIndex),
              );
            }),
        ],
      ),
    );
  }

  Widget _scanMenuButton() {
    return PopupMenuButton<String>(
      tooltip: 'Scan',
      onSelected: (value) {
        if (value == 'receipt') {
          _openReceiptScan();
        } else if (value == 'bill') {
          _openBillScan();
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'receipt',
          child: Row(
            children: [
              Icon(Icons.document_scanner_outlined, color: AppColors.main),
              SizedBox(width: 10),
              Text('Scan Receipt'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'bill',
          child: Row(
            children: [
              Icon(Icons.event_repeat_outlined, color: AppColors.main),
              SizedBox(width: 10),
              Text('Scan Bill'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.document_scanner_outlined, size: 18, color: AppColors.main),
            SizedBox(width: 7),
            Text(
              'Scan',
              style: TextStyle(
                color: AppColors.main,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.main),
          ],
        ),
      ),
    );
  }
}
