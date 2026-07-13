import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
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

  Future<void> _openReceiptScan() async {
    final expense = await showDialog<Expense>(
      context: context,
      builder: (_) => const ReceiptScanDialog(),
    );

    if (expense != null) {
      widget.onAddExpense(expense);
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
                  OutlinedButton.icon(
                    onPressed: _openReceiptScan,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.main,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: const Text('Scan'),
                  ),
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
}

class ReceiptScanDialog extends StatefulWidget {
  const ReceiptScanDialog({super.key});

  @override
  State<ReceiptScanDialog> createState() => _ReceiptScanDialogState();
}

class _ReceiptScanDialogState extends State<ReceiptScanDialog> {
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  final _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
  final _paymentMethods = ['Cash', 'Credit Card', 'Bank Transfer', 'EZ-Link'];

  Uint8List? _receiptImage;
  String _scanStatus = 'Pick a receipt first';
  String _category = 'Food';
  String _paymentMethod = 'Cash';
  DateTime _date = DateTime.now();

  bool get _canUseCamera {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _saveScannedReceipt() {
    final merchant = _merchant.text.trim();
    final amount = double.tryParse(_amount.text.trim());

    if (merchant.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check the scanned receipt details.')),
      );
      return;
    }

    Navigator.pop(
      context,
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: merchant,
        category: _category,
        amount: amount,
        date: _date,
        paymentMethod: _paymentMethod,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedImage == null) return;

    final imageBytes = await pickedImage.readAsBytes();
    setState(() {
      _receiptImage = imageBytes;
      _paymentMethod = 'Cash';
      _scanStatus = _canUseCamera
          ? 'Reading receipt text...'
          : 'Reading receipt text from server...';
    });

    if (_canUseCamera) {
      await _readReceiptText(pickedImage.path);
    } else {
      await _readReceiptTextFromServer(imageBytes, pickedImage.name);
    }
  }

  Future<void> _readReceiptText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await textRecognizer.processImage(inputImage);
      final receiptText = result.text.trim();

      if (receiptText.isEmpty) {
        setState(() => _scanStatus = 'Could not read the receipt clearly');
        return;
      }

      debugPrint('Receipt OCR text:\n$receiptText');
      _fillFromReceiptText(receiptText);
      setState(() => _scanStatus = 'Receipt text extracted');
    } catch (error) {
      debugPrint('Mobile receipt scan error: $error');
      setState(() => _scanStatus = 'Could not read receipt. Try a clearer image.');
    } finally {
      await textRecognizer.close();
    }
  }

  Future<void> _readReceiptTextFromServer(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:3000';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/receipt/scan'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          imageBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        debugPrint('Desktop receipt scan failed: $body');
        setState(() => _scanStatus = 'Could not scan receipt. Try a clearer image.');
        return;
      }

      final receiptText = (jsonDecode(body)['text'] as String?)?.trim();

      if (receiptText == null || receiptText.isEmpty) {
        setState(() => _scanStatus = 'Could not read the receipt clearly');
        return;
      }

      debugPrint('Receipt OCR text:\n$receiptText');
      _fillFromReceiptText(receiptText);
      setState(() => _scanStatus = 'Receipt text extracted');
    } catch (error) {
      debugPrint('Desktop receipt scan error: $error');
      setState(() => _scanStatus = 'Start the server to scan receipts.');
    }
  }

  void _fillFromReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final amount = _findAmount(text);
    final date = _findDate(text);
    final merchant = _findMerchant(lines);
    final paymentMethod = _findPaymentMethod(text);
    debugPrint(
      'Receipt parsed: merchant=$merchant amount=$amount date=$date category=${_guessCategory(text)} payment=$paymentMethod',
    );

    setState(() {
      if (merchant != null) {
        _merchant.text = merchant;
      }
      if (amount != null) {
        _amount.text = amount.toStringAsFixed(2);
      }
      if (date != null) {
        _date = date;
      }
      _category = _guessCategory(text);
      _paymentMethod = paymentMethod;
    });
  }

  String? _findMerchant(List<String> lines) {
    final knownStores = [
      'fairprice',
      'ntuc',
      'cold storage',
      'sheng siong',
      'giant',
      'toast box',
      'starbucks',
      'mcdonald',
      'kfc',
      'subway',
      'watsons',
      'guardian',
      'uniqlo',
      'shopee',
      'lazada',
      'grab',
      'comfortdelgro',
    ];
    final ignoredWords = [
      'receipt',
      'invoice',
      'date',
      'time',
      'gst',
      'tax',
      'total',
      'amount',
      'cashier',
      'change',
      'payment',
      'visa',
      'mastercard',
      'subtotal',
      'balance',
      'approval',
      'terminal',
      'merchant id',
      'transaction',
      'uen',
      'tel',
      'address',
    ];

    for (final line in lines.take(10)) {
      final lowerLine = line.toLowerCase();
      final hasStoreName = knownStores.any(lowerLine.contains);

      if (hasStoreName) {
        return _cleanMerchantLine(line);
      }
    }

    for (final line in lines.take(10)) {
      final lowerLine = line.toLowerCase();
      final hasNumber = RegExp(r'\d').hasMatch(line);
      final hasAmount = RegExp(r'\d+\.\d{2}').hasMatch(line);
      final hasDate = RegExp(r'\d{1,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,4}')
          .hasMatch(line);
      final shouldIgnore = ignoredWords.any(lowerLine.contains);
      final tooShort = line.replaceAll(RegExp(r'[^A-Za-z]'), '').length < 3;

      if (!hasNumber && !hasAmount && !hasDate && !shouldIgnore && !tooShort) {
        return _cleanMerchantLine(line);
      }
    }

    return lines.isEmpty ? null : _cleanMerchantLine(lines.first);
  }

  String _cleanMerchantLine(String line) {
    return line
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[^A-Za-z]+'), '')
        .replaceAll(RegExp(r"[^A-Za-z0-9 &.'-]+$"), '')
        .trim();
  }

  double? _findAmount(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();
    final totalWords = [
      'grand total',
      'net total',
      'amount due',
      'total due',
      'total',
    ];
    final skipWords = ['subtotal', 'sub total', 'change', 'cash', 'balance'];

    for (final line in lines.reversed) {
      final lowerLine = line.toLowerCase();
      final isTotalLine = totalWords.any(lowerLine.contains);
      final shouldSkip = skipWords.any(lowerLine.contains);
      if (!isTotalLine || shouldSkip) continue;

      final lineAmount = _lastAmountInText(line);
      if (lineAmount != null) return lineAmount;
    }

    return _lastAmountInText(text);
  }

  double? _lastAmountInText(String text) {
    final matches = RegExp(r'(?:\$|sgd|s\$)?\s*(\d{1,4}(?:,\d{3})*\.\d{2})',
            caseSensitive: false)
        .allMatches(text)
        .toList();
    if (matches.isEmpty) return null;

    return double.tryParse(matches.last.group(1)!.replaceAll(',', ''));
  }

  DateTime? _findDate(String text) {
    final dayFirst = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})')
        .firstMatch(text);
    if (dayFirst != null) {
      final day = int.tryParse(dayFirst.group(1)!);
      final month = int.tryParse(dayFirst.group(2)!);
      final year = _normalYear(dayFirst.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    final yearFirst = RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})')
        .firstMatch(text);
    if (yearFirst != null) {
      final year = int.tryParse(yearFirst.group(1)!);
      final month = int.tryParse(yearFirst.group(2)!);
      final day = int.tryParse(yearFirst.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  int? _normalYear(String text) {
    final year = int.tryParse(text);
    if (year == null) return null;
    if (text.length == 2) return 2000 + year;

    return year;
  }

  String _guessCategory(String text) {
    final receiptText = text.toLowerCase();

    if (receiptText.contains('mrt') ||
        receiptText.contains('bus') ||
        receiptText.contains('grab') ||
        receiptText.contains('gojek') ||
        receiptText.contains('taxi') ||
        receiptText.contains('ez-link')) {
      return 'Transport';
    }
    if (receiptText.contains('uniqlo') ||
        receiptText.contains('lazada') ||
        receiptText.contains('watsons') ||
        receiptText.contains('shopee') ||
        receiptText.contains('shopping')) {
      return 'Shopping';
    }
    if (receiptText.contains('bill') ||
        receiptText.contains('singtel') ||
        receiptText.contains('starhub') ||
        receiptText.contains('sp services') ||
        receiptText.contains('utilities')) {
      return 'Bills';
    }
    if (receiptText.contains('fairprice') ||
        receiptText.contains('ntuc') ||
        receiptText.contains('food') ||
        receiptText.contains('restaurant') ||
        receiptText.contains('mcdonald') ||
        receiptText.contains('cafe')) {
      return 'Food';
    }

    return 'Others';
  }

  String _findPaymentMethod(String text) {
    final receiptText = text.toLowerCase();

    if (receiptText.contains('ez-link') || receiptText.contains('ezlink')) {
      return 'EZ-Link';
    }
    if (receiptText.contains('paynow') ||
        receiptText.contains('pay now') ||
        receiptText.contains('paylah') ||
        receiptText.contains('pay lah') ||
        receiptText.contains('dbs') ||
        receiptText.contains('uob') ||
        receiptText.contains('ocbc') ||
        receiptText.contains('posb') ||
        receiptText.contains('bank account') ||
        receiptText.contains('bank transfer') ||
        receiptText.contains('fund transfer') ||
        receiptText.contains('savings account') ||
        receiptText.contains('saving account') ||
        receiptText.contains('current account')) {
      return 'Bank Transfer';
    }
    if (receiptText.contains('visa') ||
        receiptText.contains('mastercard') ||
        receiptText.contains('master card') ||
        receiptText.contains('credit card') ||
        receiptText.contains('debit card') ||
        RegExp(r'\bcard\b').hasMatch(receiptText)) {
      return 'Credit Card';
    }
    if (receiptText.contains('cash tendered') ||
        receiptText.contains('cash paid') ||
        RegExp(r'\bcash\b').hasMatch(receiptText)) {
      return 'Cash';
    }

    return _paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: AppColors.main,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan Receipt'),
                SizedBox(height: 4),
                Text(
                  'Check the details before saving.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 430,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _receiptImage == null ? _emptyReceiptBox() : _receiptPreview(),
              const SizedBox(height: 12),
              _imageButtons(),
              const SizedBox(height: 22),
              _sectionTitle('Extracted Details'),
              const SizedBox(height: 16),
              _fieldLabel('Merchant'),
              const SizedBox(height: 8),
              TextField(
                controller: _merchant,
                decoration: _decoration('Merchant name', Icons.store_outlined),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Amount'),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('0.00', Icons.attach_money),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Possible category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _decoration(null, Icons.category_outlined),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Payment method'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: _decoration(null, Icons.payment_outlined),
                items: _paymentMethods
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.main),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${_date.day}/${_date.month}/${_date.year}',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
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
          onPressed: _saveScannedReceipt,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.main,
            minimumSize: const Size(150, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save Transaction'),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _imageButtons() {
    if (!_canUseCamera) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.main,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _pickReceiptImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.main,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _pickReceiptImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Camera'),
          ),
        ),
      ],
    );
  }

  Widget _emptyReceiptBox() {
    return InkWell(
      onTap: () => _pickReceiptImage(ImageSource.gallery),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.main.withAlpha(85), width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.main.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.upload_file_outlined,
                color: AppColors.main,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Upload receipt image',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose a clear photo so the details can be suggested.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            if (!_canUseCamera) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Browse Files',
                  style: TextStyle(
                    color: AppColors.main,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _receiptPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 190,
            color: AppColors.light,
            child: Image.memory(_receiptImage!, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(85),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(235),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.main,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _scanStatus,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String? hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.main),
    );
  }
}
