import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import './auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../widgets/notification_bell.dart';

class GoalScreen extends StatefulWidget {
  final int unreadNotifications;
  final VoidCallback onNotificationsTap;

  const GoalScreen({
    super.key,
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

  static const Color _tealDark  = Color(0xFF2D7D7B);
  static const Color _tealLight = Color(0xFF4AADAA);
  static const Color _bgColor   = Color(0xFFEBF0F0);
  static const Color _inkDark   = Color(0xFF1A2D3D);

  double get _totalSaved  => goals.fold(0, (s, g) => s + g.savedAmount);
  double get _totalTarget => goals.fold(0, (s, g) => s + g.targetAmount);
  double get _overallPct  =>
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

  Future<void> _openForm(BuildContext context, [int? index]) async {
    final goalToEdit = index == null ? null : goals[index];
    final titleController =
        TextEditingController(text: goalToEdit?.title ?? '');
    final targetController = TextEditingController(
        text: goalToEdit?.targetAmount.toStringAsFixed(2) ?? '');
    final savedController = TextEditingController(
        text: goalToEdit?.savedAmount.toStringAsFixed(2) ?? '');

    final goal = await showModalBottomSheet<Goal>(
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

    if (goal == null) return;
    if (index == null) {
      onAddGoal(goal);
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
        _showSnack(data?['error'] ?? 'Failed to add goal 2(${response.statusCode})');
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
      print('goal: $goal');
      print('goalid: $goalId');

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
        print(updated);
        setState(() {
          _goals[index] = updated != null
              ? Map<String, dynamic>.from(updated)
              : goal;
        });

        _showSnack('Goal updated successfully');
      } else {
        final data = _tryDecode(response.body);
        _showSnack(data?['error'] ?? 'Failed to update goal 3(${response.statusCode})');
      }
    } catch (e) {
      _showSnack('Could not connect to server');
    }
  }

  Future<void> _confirmDelete(BuildContext context, int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Goal?',
            style: TextStyle(fontWeight: FontWeight.w700, color: _inkDark)),
        content: Text(
          'Remove "${goals[index].title}" from your goals? This cannot be undone.',
          style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child:
                const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (shouldDelete == true) onDeleteGoal(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        title: const Text(
          'Goals',
          style: TextStyle(
              color: _inkDark, fontSize: 18, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
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
      floatingActionButton: GestureDetector(
        onTap: () => _openForm(context),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_tealDark, _tealLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _tealDark.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
      body: goals.isEmpty ? _buildEmpty() : _buildList(context),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4F3),
              borderRadius: BorderRadius.circular(24),
            ),
            child:
                const Icon(Icons.flag_rounded, color: _tealDark, size: 40),
          ),
          const SizedBox(height: 20),
          const Text('No goals yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _inkDark)),
          const SizedBox(height: 8),
          Text('Tap + to set your first saving goal',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
      children: [
        // ── Teal summary card ──────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E5C5A), Color(0xFF4AADAA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _tealDark.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Overall Progress',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${goals.length} goal${goals.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '\$${_totalSaved.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w700),
              ),
              Text(
                'saved of \$${_totalTarget.toStringAsFixed(2)}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: _overallPct,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Budget progress',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12)),
                  Text(
                    '${(_overallPct * 100).toStringAsFixed(0)}% saved',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Section header ────────────────────────────────
        Row(
          children: [
            const Text(
              'Saving Goals',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _inkDark),
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${goals.length} goal${goals.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tealDark),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Goal cards ────────────────────────────────────
        ...goals.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalCard(
                  goal: e.value,
                  onTap: () => _openForm(context, e.key),
                  onDelete: () => _confirmDelete(context, e.key),
                ),
              ),
            ),
      ],
    );
  }
}

// ── Goal card ─────────────────────────────────────────────────
class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onDelete,
  });

  static const Color _tealDark = Color(0xFF2D7D7B);
  static const Color _inkDark  = Color(0xFF1A2D3D);

  double get _pct =>
      goal.targetAmount == 0
          ? 0
          : (goal.savedAmount / goal.targetAmount).clamp(0.0, 1.0);

  String get _emoji {
    if (_pct >= 1.0) return '🎉';
    if (_pct >= 0.75) return '🔥';
    if (_pct >= 0.5) return '💪';
    return '🎯';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title row ──────────────────────────────────
            Row(
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    goal.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _inkDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pct >= 1.0
                        ? const Color(0xFFD0F0EE)
                        : const Color(0xFFE6F4F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${(_pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _pct >= 1.0
                            ? const Color(0xFF1A6B68)
                            : _tealDark),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red, size: 17),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Amount row ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Saved',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text(
                      '\$${goal.savedAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _tealDark),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Target',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[500])),
                    const SizedBox(height: 2),
                    Text(
                      '\$${goal.targetAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _inkDark),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Progress bar ───────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _pct,
                minHeight: 8,
                backgroundColor: const Color(0xFFE6F4F3),
                valueColor: AlwaysStoppedAnimation<Color>(
                    _pct >= 1.0 ? const Color(0xFF1A6B68) : _tealDark),
              ),
            ),

            // ── Goal reached banner ────────────────────────
            if (_pct >= 1.0) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD0F0EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    '🎉 Goal reached!',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A6B68)),
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

// ── Bottom sheet form ─────────────────────────────────────────
class _GoalFormSheet extends StatelessWidget {
  final bool isEdit;
  final TextEditingController titleController;
  final TextEditingController targetController;
  final TextEditingController savedController;
  final Goal? goalToEdit;

  const _GoalFormSheet({
    required this.isEdit,
    required this.titleController,
    required this.targetController,
    required this.savedController,
    this.goalToEdit,
  });

  static const Color _tealDark = Color(0xFF2D7D7B);
  static const Color _inkDark  = Color(0xFF1A2D3D);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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

          // Sheet header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4F3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: _tealDark, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                isEdit ? 'Edit Goal' : 'New Goal',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _inkDark),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Color(0xFF1A2D3D), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _SheetField(
            label: 'Goal Name',
            controller: titleController,
            hint: 'e.g. Emergency Fund',
            icon: Icons.edit_rounded,
          ),
          const SizedBox(height: 14),
          _SheetField(
            label: 'Target Amount (\$)',
            controller: targetController,
            hint: '0.00',
            icon: Icons.flag_outlined,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 14),
          _SheetField(
            label: 'Amount Already Saved (\$)',
            controller: savedController,
            hint: '0.00',
            icon: Icons.savings_rounded,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 28),

          // Save button
          GestureDetector(
            onTap: () {
              final title = titleController.text.trim();
              final target = double.tryParse(targetController.text.trim());
              final saved =
                  double.tryParse(savedController.text.trim()) ?? 0;
              if (title.isEmpty || target == null || target <= 0) return;
              Navigator.pop(
                context,
                Goal(
                  id: goalToEdit?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  title: title,
                  targetAmount: target,
                  savedAmount: saved,
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D7D7B), Color(0xFF4AADAA)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: _tealDark.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  isEdit ? 'Save Changes' : 'Add Goal',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
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
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFEBF0F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A2D3D)),
            decoration: InputDecoration(
              prefixIcon:
                  Icon(icon, color: const Color(0xFF2D7D7B), size: 20),
              hintText: hint,
              hintStyle:
                  TextStyle(color: Colors.grey[400], fontSize: 15),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
