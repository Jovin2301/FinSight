import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/goal.dart';
import '../widgets/goal_card.dart';

class GoalScreen extends StatelessWidget {
  final List<Goal> goals;
  final ValueChanged<Goal> onAddGoal;
  final void Function(int index, Goal goal) onUpdateGoal;
  final ValueChanged<int> onDeleteGoal;

  const GoalScreen({
    super.key,
    required this.goals,
    required this.onAddGoal,
    required this.onUpdateGoal,
    required this.onDeleteGoal,
  });

  Future<void> _openForm(BuildContext context, [int? index]) async {
    final goalToEdit = index == null ? null : goals[index];
    final titleController = TextEditingController(
      text: goalToEdit?.title ?? '',
    );
    final targetController = TextEditingController(
      text: goalToEdit?.targetAmount.toStringAsFixed(2) ?? '',
    );
    final savedController = TextEditingController(
      text: goalToEdit?.savedAmount.toStringAsFixed(2) ?? '',
    );

    final goal = await showDialog<Goal>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(index == null ? 'New Goal' : 'Edit Goal')),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'Goal name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'Target amount'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: savedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'Saved amount'),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final target = double.tryParse(targetController.text.trim());
              final saved = double.tryParse(savedController.text.trim()) ?? 0;

              if (title.isEmpty || target == null || target <= 0) return;

              Navigator.pop(
                context,
                Goal(
                  id:
                      goalToEdit?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  targetAmount: target,
                  savedAmount: saved,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    titleController.dispose();
    targetController.dispose();
    savedController.dispose();

    if (goal == null) return;
    if (index == null) {
      onAddGoal(goal);
    } else {
      onUpdateGoal(index, goal);
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: Text('Remove "${goals[index].title}" from your goals?'),
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

    if (shouldDelete == true) onDeleteGoal(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addGoal',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saving Goals',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${goals.length} goals',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: goals.isEmpty
                  ? const Center(
                      child: Text(
                        'No goals yet.\nTap + to add your first goal.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: goals.length,
                      itemBuilder: (_, index) => GoalCard(
                        goal: goals[index],
                        onTap: () => _openForm(context, index),
                        onDelete: () => _confirmDelete(context, index),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
