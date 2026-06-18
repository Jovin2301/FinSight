import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/goal.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GoalCard({super.key, required this.goal, this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount == 0
        ? 0.0
        : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '\$${goal.savedAmount.toStringAsFixed(2)} / \$${goal.targetAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.light,
                  color: AppColors.main,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
