import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../constants/app_colors.dart';
import '../constants/category_icons.dart';
import '../models/budget.dart';
import '../widgets/budget_card.dart';
import '../widgets/notification_bell.dart';

class WalletScreen extends StatelessWidget {
  final List<Budget> budgets;
  final List<String> categories;
  final bool isLoading;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;
  final ValueChanged<Budget> onAddBudget;
  final void Function(int index, Budget budget) onUpdateBudget;
  final ValueChanged<int> onDeleteBudget;

  const WalletScreen({
    super.key,
    required this.budgets,
    required this.categories,
    required this.isLoading,
    required this.unreadNotifications,
    required this.onNotificationsTap,
    required this.onAddBudget,
    required this.onUpdateBudget,
    required this.onDeleteBudget,
  });

  DateTime _startDateFor(String frequency) {
    final now = DateTime.now();
    if (frequency == 'weekly') {
      return DateTime(now.year, now.month, now.day - now.weekday + 1);
    }
    if (frequency == 'yearly') {
      return DateTime(now.year, 1, 1);
    }
    return DateTime(now.year, now.month, 1);
  }

  DateTime _endDateFor(String frequency) {
    final start = _startDateFor(frequency);
    if (frequency == 'weekly') return start.add(const Duration(days: 6));
    if (frequency == 'yearly') return DateTime(start.year, 12, 31);
    return DateTime(start.year, start.month + 1, 0);
  }

  void _openEmojiPicker(BuildContext context, ValueChanged<String> onSelected) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return SizedBox(
          height: 320,
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              onSelected(emoji.emoji);
              Navigator.pop(context);
            },
            config: const Config(
              height: 300,
              emojiViewConfig: EmojiViewConfig(columns: 7),
              bottomActionBarConfig: BottomActionBarConfig(
                showBackspaceButton: false,
              ),
            ),
          ),
        );
      },
    );
  }

  void _changeIcon(BuildContext context, int index) {
    final oldBudget = budgets[index];

    _openEmojiPicker(context, (emoji) {
      onUpdateBudget(
        index,
        Budget(
          id: oldBudget.id,
          name: oldBudget.name,
          icon: emoji,
          category: oldBudget.category,
          limit: oldBudget.limit,
          description: oldBudget.description,
          frequency: oldBudget.frequency,
          startDate: oldBudget.startDate,
          endDate: oldBudget.endDate,
          spent: oldBudget.spent,
        ),
      );
    });
  }

  Future<void> _openForm(BuildContext context, [int? index]) async {
    final budgetToEdit = index == null ? null : budgets[index];
    final allCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
    String selectedCategory = budgetToEdit?.category ?? allCategories.first;
    String selectedFrequency = budgetToEdit?.frequency ?? 'monthly';
    String? limitError;
    final limitController = TextEditingController(
      text: budgetToEdit?.limit.toStringAsFixed(2) ?? '',
    );
    final descController = TextEditingController(
      text: budgetToEdit?.description ?? '',
    );

    final budget = await showDialog<Budget>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(index == null ? 'New Budget' : 'Edit Budget'),
                  const SizedBox(height: 4),
                  Text(
                    index == null
                        ? 'Set a spending limit for a category.'
                        : 'Update your budget details.',
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: const InputDecoration(
                          hintText: 'Select a category',
                        ),
                        items: allCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedCategory = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Budget limit',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: limitController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) {
                          if (limitError != null) {
                            setDialogState(() => limitError = null);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: '\$ ',
                          errorText: limitError,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Frequency',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(
                              value: 'weekly',
                              label: Text('Weekly'),
                            ),
                            ButtonSegment(
                              value: 'monthly',
                              label: Text('Monthly'),
                            ),
                            ButtonSegment(
                              value: 'yearly',
                              label: Text('Yearly'),
                            ),
                          ],
                          selected: {selectedFrequency},
                          onSelectionChanged: (selected) {
                            setDialogState(
                              () => selectedFrequency = selected.first,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Notes (optional)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Add a short note',
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
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.main,
                    minimumSize: const Size(140, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final limit = double.tryParse(limitController.text.trim());

                    if (limit == null || limit <= 0) {
                      setDialogState(
                        () => limitError = 'Enter a valid budget amount',
                      );
                      return;
                    }

                    Navigator.pop(
                      context,
                      Budget(
                        id:
                            budgetToEdit?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: selectedCategory,
                        icon:
                            budgetToEdit?.icon ??
                            categoryEmoji(selectedCategory),
                        category: selectedCategory,
                        limit: limit,
                        description: descController.text.trim(),
                        frequency: selectedFrequency,
                        startDate: _startDateFor(selectedFrequency),
                        endDate: _endDateFor(selectedFrequency),
                        spent: budgetToEdit?.spent ?? 0,
                      ),
                    );
                  },
                  child: Text(index == null ? 'Create Budget' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    limitController.dispose();
    descController.dispose();

    if (budget == null) return;
    if (index == null) {
      onAddBudget(budget);
    } else {
      onUpdateBudget(index, budget);
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text('Remove the ${budgets[index].category} budget?'),
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

    if (shouldDelete == true) onDeleteBudget(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: NotificationBell(
              unreadCount: unreadNotifications,
              onTap: onNotificationsTap,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addwallet',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.light,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌱 Spend with purpose today, so you have more choices tomorrow.',
                    style: TextStyle(
                      color: AppColors.text,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Category Budgets',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${budgets.length} items',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : budgets.isEmpty
                  ? const Center(
                      child: Text(
                        'No budgets yet.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView.builder(
                      itemCount: budgets.length,
                      itemBuilder: (_, index) {
                        final budget = budgets[index];
                        return BudgetCard(
                          budget: budget,
                          spent: budget.spent,
                          onIconTap: () => _changeIcon(context, index),
                          onTap: () => _openForm(context, index),
                          onDelete: () => _confirmDelete(context, index),
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
