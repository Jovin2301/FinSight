import 'dart:io';
import 'dart:math' as math;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../utils/download_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_colors.dart';
import '../models/expense.dart';
import '../models/recurring_payment.dart';
import '../widgets/expense_card.dart';
import '../widgets/notification_bell.dart';
import 'add_expense_screen.dart';
import 'bill_scan_dialog.dart';
import 'receipt_scan_dialog.dart';
import 'dart:convert';

class TransactionsScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<RecurringPayment> recurringPayments;
  final Map<String, String> categoryIcons;
  final ValueChanged<Expense> onAddExpense;
  final ValueChanged<RecurringPayment> onAddRecurringPayment;
  final void Function(int index, RecurringPayment payment)
  onUpdateRecurringPayment;
  final ValueChanged<int> onDeleteRecurringPayment;
  final void Function(int index, Expense expense) onUpdateExpense;
  final ValueChanged<int> onDeleteExpense;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  const TransactionsScreen({
    super.key,
    required this.expenses,
    required this.recurringPayments,
    this.categoryIcons = const {},
    required this.onAddExpense,
    required this.onAddRecurringPayment,
    required this.onUpdateRecurringPayment,
    required this.onDeleteRecurringPayment,
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
  bool _showRecurringList = false;
  bool _showAllRecurring = false;
  bool _showAllExpenses = false;
  bool _isExporting = false;

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
    final payment = await showDialog<RecurringPayment>(
      context: context,
      builder: (_) => const BillScanDialog(),
    );

    if (payment != null) {
      widget.onAddRecurringPayment(payment);
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction?'),
        content: Text(
          'Remove "${widget.expenses[index].title}" from transactions?',
        ),
        actions: _deleteDialogActions(context),
      ),
    );

    if (shouldDelete == true) widget.onDeleteExpense(index);
  }

  Future<void> _openRecurringForm(int index) async {
    final payment = widget.recurringPayments[index];
    final nameController = TextEditingController(text: payment.name);
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(2),
    );
    final categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
    final frequencies = ['weekly', 'monthly', 'yearly'];
    String category = payment.category;
    String frequency = payment.frequency;
    DateTime startDate = payment.startDate;

    final updatedPayment = await showDialog<RecurringPayment>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Edit Recurring Payment'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _dialogLabel('Name'),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Netflix Subscription',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Amount'),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(hintText: '0.00'),
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Category'),
                      DropdownButtonFormField<String>(
                        initialValue: categories.contains(category)
                            ? category
                            : 'Bills',
                        items: categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Frequency'),
                      SegmentedButton<String>(
                        segments: frequencies
                            .map(
                              (item) => ButtonSegment(
                                value: item,
                                label: Text(
                                  item[0].toUpperCase() + item.substring(1),
                                ),
                              ),
                            )
                            .toList(),
                        selected: {frequency},
                        onSelectionChanged: (value) {
                          setDialogState(() => frequency = value.first);
                        },
                      ),
                      const SizedBox(height: 14),
                      _dialogLabel('Next billing date'),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2035),
                          );

                          if (picked != null) {
                            setDialogState(() {
                              startDate = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                              );
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.light,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(_dateLabel(startDate)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final amount = double.tryParse(amountController.text);
                    final name = nameController.text.trim();

                    if (name.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Check the recurring details.'),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      payment.copyWith(
                        name: name,
                        amount: amount,
                        category: category,
                        frequency: frequency,
                        startDate: startDate,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    amountController.dispose();

    if (updatedPayment != null) {
      widget.onUpdateRecurringPayment(index, updatedPayment);
    }
  }

  Future<void> _confirmDeleteRecurring(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Recurring Payment?'),
        content: Text(
          'Remove "${widget.recurringPayments[index].name}" from recurring payments?',
        ),
        actions: _deleteDialogActions(context),
      ),
    );

    if (shouldDelete == true) {
      widget.onDeleteRecurringPayment(index);
    }
  }

  List<Widget> _deleteDialogActions(BuildContext context) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.muted),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
        ),
        child: const Text('Cancel'),
      ),
      OutlinedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(const Color(0xFFFFF0F0)),
          foregroundColor: WidgetStateProperty.all(AppColors.red),
          overlayColor: WidgetStateProperty.all(
            AppColors.red.withValues(alpha: 0.08),
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: Color(0xFFFFD4D4)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        child: const Text('Delete'),
      ),
    ];
  }

  Widget _dialogLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
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

  String _dateLabel(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _categoryIcon(String category) {
    final icon = widget.categoryIcons[category];
    if (icon != null) return icon;

    if (category == 'Food') return '🍔';
    if (category == 'Transport') return '🚌';
    if (category == 'Shopping') return '🛍️';
    if (category == 'Bills') return '💡';
    return '💰';
  }

  List<DateTime> _recentMonths(DateTime now) {
    return List.generate(6, (index) {
      return DateTime(now.year, now.month - 5 + index);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _exportTransactions(List<MapEntry<int, Expense>> results) async {
    if (_isExporting) return;

    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to export.')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final rows = <List<dynamic>>[
        ['Date', 'Title', 'Category', 'Amount'],
        ...results.map((entry) {
          final expense = entry.value;
          return [
            _formatDate(expense.date),
            expense.title,
            expense.category,
            expense.amount.toStringAsFixed(2),
          ];
        }),
      ];

      final csvData = const ListToCsvConverter().convert(rows);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'transactions_$timestamp.csv';

      // Web: dart:io's Platform class doesn't exist in the browser, so it
      // must be checked (and skipped) before anything else touches it.
      if (kIsWeb) {
        downloadCsvWeb(csvData, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloaded: $fileName')),
          );
        }
        return;
      }

      // Desktop platforms (macOS/Windows/Linux) have a real Downloads
      // folder the app can write to directly.
      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        final downloadsDir = await getDownloadsDirectory();
        if (downloadsDir != null) {
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          final file = File('${downloadsDir.path}/$fileName');
          await file.writeAsString(csvData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Saved to Downloads: $fileName')),
            );
          }
          return;
        }
      }

      // Mobile (iOS/Android): write to a temp file and hand off to the
      // native share sheet so the user can save/send it themselves.
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(file.path)], text: 'Transactions export');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
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

  Widget _recurringPaymentsSection() {
    final paymentEntries = widget.recurringPayments.asMap().entries.toList();
    final shownPayments = _showAllRecurring
        ? paymentEntries
        : paymentEntries.take(2).toList();
    double monthlyTotal = 0;
    for (final payment in widget.recurringPayments) {
      monthlyTotal += _monthlyRecurringAmount(payment);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bills & Subscriptions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _openBillScan,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.main,
                side: const BorderSide(color: AppColors.border),
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add bill'),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${widget.recurringPayments.length} saved bills or subscriptions',
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (widget.recurringPayments.isEmpty)
          Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.event_repeat_outlined,
                      color: AppColors.main,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No bills or subscriptions saved yet.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  TextButton(
                    onPressed: _openBillScan,
                    child: const Text('Add bill'),
                  ),
                ],
              ),
            ),
          )
        else ...[
          _recurringSummaryCard(monthlyTotal),
          if (_showRecurringList) ...[
            const SizedBox(height: 12),
            ...shownPayments.map((entry) {
              return _recurringPaymentCard(entry.key, entry.value);
            }),
            if (widget.recurringPayments.length > 2)
              _showMoreButton(
                isExpanded: _showAllRecurring,
                showMoreText:
                    'View all ${widget.recurringPayments.length} recurring payments',
                onTap: () {
                  setState(() => _showAllRecurring = !_showAllRecurring);
                },
              ),
          ],
        ],
      ],
    );
  }

  double _monthlyRecurringAmount(RecurringPayment payment) {
    if (payment.frequency == 'weekly') return payment.amount * 4;
    if (payment.frequency == 'yearly') return payment.amount / 12;
    return payment.amount;
  }

  Widget _recurringSummaryCard(double monthlyTotal) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          setState(() => _showRecurringList = !_showRecurringList);
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_repeat_outlined,
                  color: AppColors.main,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bills and subscriptions',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'About \$${monthlyTotal.toStringAsFixed(2)} per month',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _showRecurringList ? 'Hide' : 'View',
                style: const TextStyle(
                  color: AppColors.main,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                _showRecurringList
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.main,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _showMoreButton({
    required bool isExpanded,
    required String showMoreText,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.main,
        padding: EdgeInsets.zero,
      ),
      icon: Icon(
        isExpanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.keyboard_arrow_down_rounded,
      ),
      label: Text(isExpanded ? 'Show less' : showMoreText),
    );
  }

  Widget _recurringPaymentCard(int index, RecurringPayment payment) {
    final percentText =
        payment.frequency[0].toUpperCase() +
        payment.frequency.substring(1).toLowerCase();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _openRecurringForm(index),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _categoryIcon(payment.category),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.category} • $percentText',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Next ${_dateLabel(payment.startDate)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-\$${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Delete recurring payment',
                  onPressed: () => _confirmDeleteRecurring(index),
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.red,
                    size: 21,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
    final shownResults = _showAllExpenses ? results : results.take(5).toList();

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
                const SizedBox(width: 8),
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
          _recurringPaymentsSection(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
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
              ),
              IconButton(
                tooltip: 'Export transactions',
                onPressed: _isExporting
                    ? null
                    : () => _exportTransactions(results),
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                color: AppColors.muted,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _scanMenuButton()),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: hasFilters ? AppColors.lightMint : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasFilters ? AppColors.main : AppColors.border,
                  ),
                ),
                child: IconButton(
                  tooltip: 'Filter transactions',
                  onPressed: () => _openFilters(categories, dateFilters),
                  icon: Badge(
                    isLabelVisible: hasFilters,
                    label: Text('$filterCount'),
                    child: const Icon(Icons.filter_alt_rounded),
                  ),
                  color: hasFilters ? AppColors.main : AppColors.muted,
                ),
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
            ...shownResults.map((entry) {
              final originalIndex = entry.key;
              final expense = entry.value;

              return ExpenseCard(
                expense: expense,
                categoryIcon: widget.categoryIcons[expense.category],
                onTap: () => _openForm(context, originalIndex),
                onDelete: () => _confirmDelete(context, originalIndex),
              );
            }),
          if (results.length > 5)
            _showMoreButton(
              isExpanded: _showAllExpenses,
              showMoreText: 'View all ${results.length} expenses',
              onTap: () {
                setState(() => _showAllExpenses = !_showAllExpenses);
              },
            ),
        ],
      ),
    );
  }

  Widget _scanMenuButton() {
    return InkWell(
      onTap: _openReceiptScan,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 18,
              color: AppColors.main,
            ),
            SizedBox(width: 7),
            Flexible(
              child: Text(
                'Scan receipt',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.main,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
