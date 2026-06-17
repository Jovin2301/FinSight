import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/budget.dart';

class BudgetCard extends StatelessWidget {
  final Budget budget;
  final double spent;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BudgetCard({
    super.key,
    required this.budget,
    required this.spent,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final left = budget.limit - spent;
    final progress = budget.limit == 0
        ? 0.0
        : (spent / budget.limit).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 14, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      budget.category,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  Text(
                    '\$${budget.limit.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.main,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '\$${spent.toStringAsFixed(2)} spent, \$${left.toStringAsFixed(2)} left',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: AppColors.light,
                    color: left < 0 ? AppColors.red : AppColors.main,
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
