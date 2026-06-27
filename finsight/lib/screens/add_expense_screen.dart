import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  final _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
  final _paymentMethods = ['Cash', 'Credit Card', 'Bank Transfer', 'EZ-Link'];

  String? _category;
  String _paymentMethod = 'Cash';
  DateTime _date = DateTime.now();

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    if (expense == null) return;

    _title.text = expense.title;
    _amount.text = expense.amount.toStringAsFixed(2);
    _category = expense.category;
    _date = expense.date;
    _paymentMethod = expense.paymentMethod;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    final amount = double.tryParse(_amount.text);

    if (title.isEmpty || amount == null || amount <= 0 || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields correctly.')),
      );
      return;
    }

    Navigator.pop(
      context,
      Expense(
        id: _isEdit
            ? widget.expense!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        category: _category!,
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

    if (picked != null) setState(() => _date = picked);
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
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_isEdit ? 'Edit Expense' : 'Add Expense'),
          const SizedBox(height: 4),
          Text(
            _isEdit
                ? 'Update your transaction details.'
                : 'Record a new expense.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Title'),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                decoration: _decoration(
                  'e.g. Lunch at food court',
                  Icons.notes_outlined,
                ),
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
              _fieldLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                hint: const Text('Select a category'),
                decoration: _decoration(null, Icons.category_outlined),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
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
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.main,
            minimumSize: const Size(140, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(_isEdit ? 'Save Changes' : 'Add Expense'),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }

  InputDecoration _decoration(String? hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.main),
    );
  }
}
