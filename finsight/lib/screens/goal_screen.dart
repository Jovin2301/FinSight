import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/notification_bell.dart';
import '../models/goal.dart';
import '../constants/app_colors.dart';

class GoalScreen extends StatefulWidget {
  final List<Goal> goals;
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  const GoalScreen({
    super.key,
    required this.goals,
    required this.unreadNotifications,
    required this.onNotificationsTap,
  });

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

double parseAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

class _GoalScreenState extends State<GoalScreen> {
  List<Map<String, dynamic>> _goals = [];
  bool isLoading = true;

  double get _totalSaved =>
      _goals.fold(0.0, (double s, g) => s + parseAmount(g['goalCurrentAmt']));

  double get _totalTarget =>
      _goals.fold(0.0, (double s, g) => s + parseAmount(g['goalTargetAmt']));

  double get _overallPct =>
      _totalTarget == 0 ? 0 : (_totalSaved / _totalTarget).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGoals();
    });
  }

  // ── READ
  Future<void> _loadGoals() async {
    setState(() => isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/user/getSavingGoal'),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          _goals = data
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      } else {
        _showSnack('Failed to load goals (${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Could not connect to server');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ── CREATE / EDIT entry point
  Future<void> _openForm(BuildContext context, [int? index]) async {
    final Map<String, dynamic>? goalToEdit = index == null
        ? null
        : Map<String, dynamic>.from(_goals[index]);

    final titleController = TextEditingController(
      text: goalToEdit?['goalName']?.toString() ?? '',
    );

    final targetController = TextEditingController(
      text: goalToEdit == null
          ? ''
          : parseAmount(goalToEdit['goalTargetAmt']).toStringAsFixed(2),
    );

    final savedController = TextEditingController(
      text: goalToEdit == null
          ? ''
          : parseAmount(goalToEdit['goalCurrentAmt']).toStringAsFixed(2),
    );

    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalFormSheet(
        isEdit: index != null,
        titleController: titleController,
        targetController: targetController,
        savedController: savedController,
        goalToEdit: goalToEdit,
      ),
    );

    titleController.dispose();
    targetController.dispose();
    savedController.dispose();

    if (result == null) return; // user cancelled

    if (index == null) {
      await _createGoal(result);
    } else {
      await _updateGoal(result, index);
    }
  }

  // ── CREATE
  Future<void> _createGoal(Map<String, dynamic> goal) async {
    try {
      final auth = context.read<AuthProvider>();

      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/user/createSavingGoal'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(goal),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final created = jsonDecode(response.body);

        setState(() {
          _goals.add(Map<String, dynamic>.from(created as Map));
        });

        _showSnack('Goal added successfully');
      } else {
        final data = _tryDecode(response.body);
        _showSnack(
          data?['error'] ?? 'Failed to add goal (${response.statusCode})',
        );
      }
    } catch (e) {
      _showSnack('Could not connect to server');
    }
  }

  // ── UPDATE
  Future<void> _updateGoal(Map<String, dynamic> goalList, int index) async {
    try {
      final auth = context.read<AuthProvider>();
      final goalId = _goals[index]['goalID'];
      final goal = {..._goals[index], ...goalList};

      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/user/updateSavingGoal/$goalId'),
        headers: {
          'Authorization': 'Bearer ${auth.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(goal),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final updated = _tryDecode(response.body);
        setState(() {
          _goals[index] = updated != null
              ? Map<String, dynamic>.from(updated)
              : goal;
        });

        _showSnack('Goal updated successfully');
      } else {
        final data = _tryDecode(response.body);
        _showSnack(
          data?['error'] ?? 'Failed to update goal (${response.statusCode})',
        );
      }
    } catch (e) {
      _showSnack('Could not connect to server');
    }
  }

  // ── DELETE
  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Goal?',
          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
        ),
        content: Text(
          'Remove "${_goals[index]['goalName']}" from your goals? This cannot be undone.',
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      final auth = context.read<AuthProvider>();
      final goalId = _goals[index]['goalID'];

      final response = await http.delete(
        Uri.parse('${dotenv.env['BASE_URL']}/user/deleteSavingGoals/$goalId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _goals.removeAt(index);
        });
        _showSnack('Goal deleted successfully');
      } else {
        final data = _tryDecode(response.body);
        _showSnack(data?['error'] ?? 'Failed to delete goal');
      }
    } catch (e) {
      _showSnack('Could not connect to server');
    }
  }

  // ── helpers
  Map<String, dynamic>? _tryDecode(String body) {
    try {
      return Map<String, dynamic>.from(jsonDecode(body) as Map);
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Goals'),
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
        heroTag: 'addgoal',
        onPressed: () => _openForm(context),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: RefreshIndicator(
          color: AppColors.main,
          onRefresh: _loadGoals,
          child: Column(
            children: [
              // ── Tip box, matching the Budgets screen style
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _goals.isEmpty
                          ? '🎯 Set a goal and start saving toward it today.'
                          : '🎯 \$${_totalSaved.toStringAsFixed(2)} saved of '
                                '\$${_totalTarget.toStringAsFixed(2)} '
                                '(${(_overallPct * 100).toStringAsFixed(0)}%) across all goals.',
                      style: const TextStyle(
                        color: AppColors.text,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Section header, matching "Category Budgets" style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Saving Goals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${_goals.length} item${_goals.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── List
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _goals.isEmpty
                    ? _buildEmpty()
                    : ListView.builder(
                        itemCount: _goals.length,
                        itemBuilder: (_, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GoalCard(
                              goal: Map<String, dynamic>.from(_goals[index]),
                              onTap: () => _openForm(context, index),
                              onDelete: () => _confirmDelete(context, index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      // ListView (not Center) so RefreshIndicator's pull-to-refresh works
      // even when there are no goals yet.
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        const Center(
          child: Text(
            'No goals yet.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

// ── Goal card, restyled to match BudgetCard's visual language
class GoalCard extends StatelessWidget {
  final Map<String, dynamic> goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    required this.onDelete,
  });

  double get _pct {
    final target = parseAmount(goal['goalTargetAmt']);
    final current = parseAmount(goal['goalCurrentAmt']);
    if (target == 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }

  String _month(int m) => const [
    '',
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
  ][m];

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day} ${_month(dt.month)} ${dt.year}';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  int? _daysLeft(DateTime? dt) {
    if (dt == null) return null;
    return dt.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final title = goal['goalName']?.toString() ?? '';
    final status = goalStatusFromString(goal['goalStatus']?.toString());
    final iconEmoji = goal['goalIcon']?.toString() ?? '🎯';
    final dueDate = _parseDate(goal['goalDueDate']);
    final days = _daysLeft(dueDate);

    final current = parseAmount(goal['goalCurrentAmt']);
    final target = parseAmount(goal['goalTargetAmt']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      iconEmoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dueDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          days == null
                              ? _formatDate(dueDate)
                              : days < 0
                              ? 'Overdue · ${_formatDate(dueDate)}'
                              : days == 0
                              ? 'Due today'
                              : '$days days left · ${_formatDate(dueDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: days != null && days < 0
                                ? Colors.red[400]
                                : AppColors.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(_pct * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppColors.main,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _StatusPill(status: status),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                Text(
                  'Target',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${current.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.main,
                  ),
                ),
                Text(
                  '\$${target.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _pct,
                minHeight: 8,
                backgroundColor: AppColors.light,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.main),
              ),
            ),
            if (_pct >= 1.0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    '🎉 Goal reached!',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.main,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Status pill widget
class _StatusPill extends StatelessWidget {
  final GoalStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 11, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet form ────────────────────────────────────────────
class _GoalFormSheet extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? goalToEdit;
  final TextEditingController titleController;
  final TextEditingController targetController;
  final TextEditingController savedController;

  const _GoalFormSheet({
    required this.isEdit,
    required this.goalToEdit,
    required this.titleController,
    required this.targetController,
    required this.savedController,
  });

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  late DateTime? _dueDate;
  late GoalStatus _status;
  late String _selectedEmoji;
  bool _showIconPicker = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final goal = widget.goalToEdit;

    _dueDate = _parseDate(goal?['goalDueDate']);
    _status = goalStatusFromString(goal?['goalStatus']?.toString());
    _selectedEmoji = goal?['goalIcon']?.toString() ?? '🎯';
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
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
    return '${dt.day} ${months[dt.month]} ${dt.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.main,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: AppColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _clearDate() => setState(() => _dueDate = null);

  void _submit() {
    final title = widget.titleController.text.trim();
    final target = double.tryParse(widget.targetController.text.trim());
    final saved = double.tryParse(widget.savedController.text.trim()) ?? 0;

    if (title.isEmpty) {
      setState(() => _errorText = 'Please enter a goal name');
      return;
    }
    if (target == null || target <= 0) {
      setState(() => _errorText = 'Please enter a valid target amount');
      return;
    }
    if (saved < 0) {
      setState(() => _errorText = 'Saved amount cannot be negative');
      return;
    }

    Navigator.pop(context, {
      if (widget.goalToEdit?['goalID'] != null)
        'goalID': widget.goalToEdit!['goalID'],
      'goalName': title,
      'goalTargetAmt': target,
      'goalCurrentAmt': saved,
      'goalDueDate': _dueDate?.toIso8601String(),
      'goalStatus': goalStatusToDbString(_status),
      'iconEmoji': _selectedEmoji,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: AppColors.main,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.isEdit ? 'Edit Goal' : 'New Goal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.text,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionLabel(label: 'Goal Icon'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showIconPicker = !_showIconPicker),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          _selectedEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      kGoalIcons.firstWhere(
                            (i) => i['emoji'] == _selectedEmoji,
                            orElse: () => {'label': 'Custom'},
                          )['label']
                          as String,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const Spacer(),
                    AnimatedRotation(
                      turns: _showIconPicker ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.main,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.light,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: GridView.count(
                  crossAxisCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: kGoalIcons.map((item) {
                    final emoji = item['emoji'] as String;
                    final isSelected = emoji == _selectedEmoji;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedEmoji = emoji;
                        _showIconPicker = false;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.main
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 20)),
                            const SizedBox(height: 2),
                            Text(
                              item['label'] as String,
                              style: TextStyle(
                                fontSize: 9,
                                color: isSelected
                                    ? AppColors.main
                                    : AppColors.muted,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              crossFadeState: _showIconPicker
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            const SizedBox(height: 14),
            _SheetField(
              label: 'Goal Name',
              controller: widget.titleController,
              hint: 'e.g. Emergency Fund',
              icon: Icons.edit_rounded,
            ),
            const SizedBox(height: 14),
            _SheetField(
              label: 'Target Amount (\$)',
              controller: widget.targetController,
              hint: '0.00',
              icon: Icons.flag_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 14),
            _SheetField(
              label: 'Amount Already Saved (\$)',
              controller: widget.savedController,
              hint: '0.00',
              icon: Icons.savings_rounded,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: 'Due Date'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.light,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppColors.main,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _dueDate != null
                                ? _formatDate(_dueDate!)
                                : 'Set a due date',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _dueDate != null
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_dueDate != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _clearDate,
                    child: Container(
                      width: 46,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
            const _SectionLabel(label: 'Status'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GoalStatus.values.map((s) {
                final isSelected = s == _status;
                return GestureDetector(
                  onTap: () => setState(() => _status = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? s.bg : AppColors.light,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? s.color : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          s.icon,
                          size: 13,
                          color: isSelected ? s.color : AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          s.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? s.color : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.main,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  widget.isEdit ? 'Save Changes' : 'Add Goal',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    );
  }
}

// ── Sheet input field ─────────────────────────────────────────
class _SheetField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _SheetField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.light,
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.main, size: 20),
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Status enum ─────────────────────────────────────────────────
enum GoalStatus { onTrack, atRisk, paused, completed }

GoalStatus goalStatusFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'atrisk':
    case 'at_risk':
      return GoalStatus.atRisk;
    case 'paused':
      return GoalStatus.paused;
    case 'completed':
      return GoalStatus.completed;
    case 'ontrack':
    case 'on_track':
    default:
      return GoalStatus.onTrack;
  }
}

String goalStatusToDbString(GoalStatus status) {
  switch (status) {
    case GoalStatus.onTrack:
      return 'onTrack';
    case GoalStatus.atRisk:
      return 'atRisk';
    case GoalStatus.paused:
      return 'paused';
    case GoalStatus.completed:
      return 'completed';
  }
}

extension GoalStatusExt on GoalStatus {
  String get label {
    switch (this) {
      case GoalStatus.onTrack:
        return 'On Track';
      case GoalStatus.atRisk:
        return 'At Risk';
      case GoalStatus.paused:
        return 'Paused';
      case GoalStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case GoalStatus.onTrack:
        return AppColors.main;
      case GoalStatus.atRisk:
        return const Color(0xFFE07B39);
      case GoalStatus.paused:
        return AppColors.muted;
      case GoalStatus.completed:
        return AppColors.main;
    }
  }

  Color get bg {
    switch (this) {
      case GoalStatus.onTrack:
        return AppColors.light;
      case GoalStatus.atRisk:
        return const Color(0xFFFFF0E8);
      case GoalStatus.paused:
        return const Color(0xFFF0F1F4);
      case GoalStatus.completed:
        return AppColors.light;
    }
  }

  IconData get icon {
    switch (this) {
      case GoalStatus.onTrack:
        return Icons.trending_up_rounded;
      case GoalStatus.atRisk:
        return Icons.warning_amber_rounded;
      case GoalStatus.paused:
        return Icons.pause_circle_outline_rounded;
      case GoalStatus.completed:
        return Icons.check_circle_outline_rounded;
    }
  }
}

// ── Icon options ──────────────────────────────────────────────
const List<Map<String, dynamic>> kGoalIcons = [
  {'emoji': '🎯', 'label': 'Target'},
  {'emoji': '✈️', 'label': 'Travel'},
  {'emoji': '🏠', 'label': 'Home'},
  {'emoji': '🚗', 'label': 'Car'},
  {'emoji': '📱', 'label': 'Tech'},
  {'emoji': '🎓', 'label': 'Education'},
  {'emoji': '💍', 'label': 'Ring'},
  {'emoji': '🏋️', 'label': 'Fitness'},
  {'emoji': '🎮', 'label': 'Gaming'},
  {'emoji': '🛳️', 'label': 'Vacation'},
  {'emoji': '💼', 'label': 'Business'},
  {'emoji': '🏥', 'label': 'Health'},
  {'emoji': '📷', 'label': 'Camera'},
  {'emoji': '🎸', 'label': 'Music'},
  {'emoji': '🌱', 'label': 'Growth'},
  {'emoji': '💎', 'label': 'Luxury'},
  {'emoji': '🐾', 'label': 'Pets'},
  {'emoji': '🍼', 'label': 'Baby'},
  {'emoji': '🎉', 'label': 'Celebration'},
  {'emoji': '🔑', 'label': 'Keys'},
];
