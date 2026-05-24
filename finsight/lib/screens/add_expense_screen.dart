import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../constants/app_colors.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  bool get _isEditing => widget.expense != null;

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Others',
  ];

  @override
  void initState() {
    super.initState();

    final expense = widget.expense;
    if (expense != null) {
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toStringAsFixed(2);
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
    }
  }

  void _saveExpense() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text);

    if (title.isEmpty ||
        amount == null ||
        amount <= 0 ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid title, amount, and category.'),
        ),
      );
      return;
    }

    final newExpense = Expense(
      id: _isEditing
          ? widget.expense!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: _selectedCategory!,
      amount: amount,
      date: _selectedDate,
    );

    Navigator.pop(context, newExpense);
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Expense' : 'Add Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Expense Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Icon(
                    Icons.notes_outlined,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  hintText: 'Amount',
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Icon(
                    Icons.attach_money,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('Category'),
                decoration: const InputDecoration(
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  prefixIcon: Icon(
                    Icons.category_outlined,
                    color: AppColors.primaryTeal,
                    size: 22,
                  ),
                  prefixIconConstraints: BoxConstraints(
                    minWidth: 52,
                    minHeight: 52,
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.softBorder),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 52,
                        child: Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.calendar_today,
                            color: AppColors.primaryTeal,
                            size: 22,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Date: ${_formatDate(_selectedDate)}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(
                          Icons.chevron_right,
                          color: AppColors.greyText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _isEditing ? 'Update Expense' : 'Save Expense',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
