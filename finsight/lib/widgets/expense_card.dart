import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../constants/app_colors.dart';

class ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryTeal.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // left category icon
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.lightMint,
          child: Icon(
            _getCategoryIcon(expense.category),
            color: AppColors.primaryTeal,
            size: 22,
          ),
        ),

        // expense title
        title: Text(
          expense.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText,
          ),
        ),

        // category and date
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${expense.category} • ${_formatDate(expense.date)}',
            style: const TextStyle(color: AppColors.greyText, fontSize: 13),
          ),
        ),

        // right side: amount and delete button
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '-\$${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.expenseRed,
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.greyText,
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'bills':
        return Icons.receipt_long;
      default:
        return Icons.wallet;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
