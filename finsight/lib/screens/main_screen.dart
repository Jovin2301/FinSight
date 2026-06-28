import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../models/app_notification.dart';
import '../constants/app_colors.dart';
import './auth_provider.dart';
import './transactions_screen.dart';
import './profile_screen.dart';
import './wallet_screen.dart';
import './homeContent.dart';
import './goal_screen.dart';
import './notification_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const bool _previewBudgetPage = false;

  int _currentIndex = 0;
  bool _loadingBudgets = false;
  List<String> _budgetCategories = [];

  final List<Budget> _budgets = _previewBudgetPage
      ? [
          const Budget(
            id: '1',
            name: 'Food Budget',
            icon: '🍔',
            category: 'Food',
            limit: 300,
            frequency: 'monthly',
            spent: 86.50,
          ),
          const Budget(
            id: '2',
            name: 'Transport Budget',
            icon: '🚌',
            category: 'Transport',
            limit: 120,
            frequency: 'monthly',
            spent: 42.40,
          ),
          const Budget(
            id: '3',
            name: 'Shopping Budget',
            icon: '🛍️',
            category: 'Shopping',
            limit: 200,
            frequency: 'monthly',
            spent: 135.90,
          ),
        ]
      : [];

  final List<Goal> _goals = [
    const Goal(
      id: '1',
      title: 'Emergency Fund',
      targetAmount: 1000,
      savedAmount: 250,
    ),
    const Goal(
      id: '2',
      title: 'New Laptop',
      targetAmount: 2000,
      savedAmount: 600,
    ),
  ];

  List<AppNotification> _notifications = _previewBudgetPage
      ? [
          AppNotification(
            id: 'notification-1',
            type: 'budget',
            message: 'You have used 80% of your bills budget.',
            date: DateTime.now(),
            isRead: false,
          ),
          AppNotification(
            id: 'notification-2',
            type: 'goal',
            message: 'You are close to your saving goal.',
            date: DateTime.now().subtract(const Duration(days: 1)),
            isRead: true,
          ),
        ]
      : [];

  final List<Expense> _expenses = _previewBudgetPage
      ? [
          Expense(
            id: '1',
            title: 'Starbucks',
            category: 'Food',
            amount: 8.50,
            date: DateTime.now(),
          ),
          Expense(
            id: '2',
            title: 'Grab',
            category: 'Transport',
            amount: 12.40,
            date: DateTime.now(),
          ),
          Expense(
            id: '3',
            title: 'Shopee',
            category: 'Shopping',
            amount: 25.90,
            date: DateTime.now(),
          ),
        ]
      : [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBudgets();
      _loadTransactions();
    });
  }

  Map<String, String> _headers() {
    final token = context.read<AuthProvider>().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _loadBudgets() async {
    if (_previewBudgetPage) {
      _budgetCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
      return;
    }

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() => _loadingBudgets = true);

    try {
      final baseUrl = dotenv.env['BASE_URL'];
      final budgetResponse = await http.get(
        Uri.parse('$baseUrl/budget'),
        headers: _headers(),
      );
      final categoryResponse = await http.get(
        Uri.parse('$baseUrl/budget/categories'),
        headers: _headers(),
      );

      if (budgetResponse.statusCode == 200) {
        final data = jsonDecode(budgetResponse.body) as List;
        _budgets
          ..clear()
          ..addAll(data.map((item) => Budget.fromJson(item)));
      }

      if (categoryResponse.statusCode == 200) {
        final data = jsonDecode(categoryResponse.body) as List;
        _budgetCategories = data
            .map((item) => item['name'].toString())
            .toList();
      }

      await _loadNotifications();
    } catch (e) {
      _showMessage('Could not load budgets');
    }

    if (mounted) setState(() => _loadingBudgets = false);
  }

  Future<void> _loadNotifications() async {
    if (_previewBudgetPage) return;
    if (context.read<AuthProvider>().token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/notification'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (!mounted) return;
        setState(() {
          _notifications = data
              .map((item) => AppNotification.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      _showMessage('Could not load notifications');
    }
  }

  Future<void> _loadTransactions() async {
    if (_previewBudgetPage) return;
    if (context.read<AuthProvider>().token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/transaction'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (!mounted) return;
        setState(() {
          _expenses
            ..clear()
            ..addAll(data.map((item) => Expense.fromJson(item)));
        });
      } else {
        _showMessage('Could not load transactions');
      }
    } catch (e) {
      _showMessage('Could not connect to server');
    }
  }

  void _goToTransactions() => setState(() => _currentIndex = 1);

  void _goToBudgets() => setState(() => _currentIndex = 2);

  void _goToGoals() => setState(() => _currentIndex = 3);

  int get _unreadNotifications {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationScreen(
          notifications: _notifications,
          onMarkRead: _markNotificationRead,
          onMarkAllRead: _markAllNotificationsRead,
        ),
      ),
    );
  }

  Future<void> _markNotificationRead(String id) async {
    if (_previewBudgetPage) {
      setState(() {
        _notifications = _notifications.map((notification) {
          return notification.id == id
              ? notification.copyWith(isRead: true)
              : notification;
        }).toList();
      });
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/notification/$id/read'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _notifications = data
              .map((item) => AppNotification.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      _showMessage('Could not update notification');
    }
  }

  Future<void> _markAllNotificationsRead() async {
    if (_previewBudgetPage) {
      setState(() {
        _notifications = _notifications
            .map((notification) => notification.copyWith(isRead: true))
            .toList();
      });
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/notification/read-all'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _notifications = data
              .map((item) => AppNotification.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      _showMessage('Could not update notifications');
    }
  }

  Budget _withSpent(Budget budget, double spent) {
    return Budget(
      id: budget.id,
      name: budget.name,
      icon: budget.icon,
      category: budget.category,
      limit: budget.limit,
      description: budget.description,
      frequency: budget.frequency,
      startDate: budget.startDate,
      endDate: budget.endDate,
      spent: spent < 0 ? 0 : spent,
    );
  }

  void _changePreviewSpending(String category, double amount) {
    if (!_previewBudgetPage) return;

    final index = _budgets.indexWhere((budget) => budget.category == category);
    if (index == -1) return;

    final budget = _budgets[index];
    _budgets[index] = _withSpent(budget, budget.spent + amount);
  }

  void _addPreviewWarnings() {
    if (!_previewBudgetPage) return;

    for (final budget in _budgets) {
      if (budget.limit <= 0 || budget.spent / budget.limit < 0.8) continue;

      final message =
          'You have used 80% of your ${budget.category.toLowerCase()} budget.';
      final exists = _notifications.any(
        (notification) =>
            notification.type == 'budget' && notification.message == message,
      );

      if (!exists) {
        _notifications.insert(
          0,
          AppNotification(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            type: 'budget',
            message: message,
            date: DateTime.now(),
            isRead: false,
          ),
        );
      }
    }
  }

  void _addExpense(Expense expense) async {
    if (_previewBudgetPage) {
      setState(() {
        _expenses.add(expense);
        _changePreviewSpending(expense.category, expense.amount);
        _addPreviewWarnings();
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/transaction'),
        headers: _headers(),
        body: jsonEncode(expense.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as List;
        if (!mounted) return;
        setState(() {
          _expenses
            ..clear()
            ..addAll(data.map((item) => Expense.fromJson(item)));
        });
        await _loadBudgets();
      } else {
        _showMessage('Could not add transaction');
      }
    } catch (e) {
      _showMessage('Could not connect to server');
    }
  }

  void _updateExpense(int index, Expense expense) async {
    if (_previewBudgetPage) {
      setState(() {
        final oldExpense = _expenses[index];
        _changePreviewSpending(oldExpense.category, -oldExpense.amount);
        _expenses[index] = expense;
        _changePreviewSpending(expense.category, expense.amount);
        _addPreviewWarnings();
      });
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/transaction/${expense.id}'),
        headers: _headers(),
        body: jsonEncode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (!mounted) return;
        setState(() {
          _expenses
            ..clear()
            ..addAll(data.map((item) => Expense.fromJson(item)));
        });
        await _loadBudgets();
      } else {
        _showMessage('Could not update transaction');
      }
    } catch (e) {
      _showMessage('Could not connect to server');
    }
  }

  void _deleteExpense(int index) async {
    if (_previewBudgetPage) {
      setState(() {
        final expense = _expenses.removeAt(index);
        _changePreviewSpending(expense.category, -expense.amount);
      });
      return;
    }

    final expense = _expenses[index];

    try {
      final response = await http.delete(
        Uri.parse('${dotenv.env['BASE_URL']}/transaction/${expense.id}'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (!mounted) return;
        setState(() {
          _expenses
            ..clear()
            ..addAll(data.map((item) => Expense.fromJson(item)));
        });
        await _loadBudgets();
      } else {
        _showMessage('Could not delete transaction');
      }
    } catch (e) {
      _showMessage('Could not connect to server');
    }
  }

  void _addGoal(Goal goal) => setState(() => _goals.add(goal));

  void _updateGoal(int index, Goal goal) =>
      setState(() => _goals[index] = goal);

  void _deleteGoal(int index) => setState(() => _goals.removeAt(index));

  void _addBudget(Budget budget) async {
    if (_previewBudgetPage) {
      setState(() {
        _budgets.add(budget);
        _addPreviewWarnings();
      });
      return;
    }

    if (context.read<AuthProvider>().token == null) {
      _showMessage('Please login before saving budgets');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['BASE_URL']}/budget'),
        headers: _headers(),
        body: jsonEncode(budget.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _budgets
            ..clear()
            ..addAll(data.map((item) => Budget.fromJson(item)));
        });
        await _loadNotifications();
      } else {
        _showMessage('Could not add budget');
      }
    } catch (e) {
      _showMessage('Could not connect to server');
    }
  }

  void _updateBudget(int index, Budget budget) async {
    if (_previewBudgetPage) {
      setState(() {
        _budgets[index] = budget;
        _addPreviewWarnings();
      });
      return;
    }

    if (context.read<AuthProvider>().token == null) {
      _showMessage('Please login before updating budgets');
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['BASE_URL']}/budget/${budget.id}'),
        headers: _headers(),
        body: jsonEncode(budget.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _budgets
            ..clear()
            ..addAll(data.map((item) => Budget.fromJson(item)));
        });
        await _loadNotifications();
      } else {
        _showMessage('Could not update budget');
      }
    } catch (e) {
      _showMessage('Could not connect to server');
    }
  }

  void _deleteBudget(int index) async {
    if (_previewBudgetPage) {
      setState(() => _budgets.removeAt(index));
      return;
    }

    if (context.read<AuthProvider>().token == null) {
      _showMessage('Please login before deleting budgets');
      return;
    }

    final budget = _budgets[index];

    try {
      final response = await http.delete(
        Uri.parse('${dotenv.env['BASE_URL']}/budget/${budget.id}'),
        headers: _headers(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _budgets
            ..clear()
            ..addAll(data.map((item) => Budget.fromJson(item)));
        });
      } else {
        _showMessage('Could not delete budget');
      }
    } catch (e) {
      _showMessage('Could not connect to server');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // Home
      HomeContent(
        expenses: _expenses,
        budgets: _budgets,
        goals: _goals,
        onAddExpense: _addExpense,
        onViewTransactions: _goToTransactions,
        onViewBudgets: _goToBudgets,
        onViewGoals: _goToGoals,
        unreadNotifications: _unreadNotifications,
        onNotificationsTap: _openNotifications,
      ),
      // Transactions
      TransactionsScreen(
        expenses: _expenses,
        categoryIcons: {
          for (final budget in _budgets) budget.category: budget.icon,
        },
        onAddExpense: _addExpense,
        onUpdateExpense: _updateExpense,
        onDeleteExpense: _deleteExpense,
        unreadNotifications: _unreadNotifications,
        onNotificationsTap: _openNotifications,
      ),
      // Wallet
      WalletScreen(
        budgets: _budgets,
        categories: _budgetCategories,
        isLoading: _loadingBudgets,
        unreadNotifications: _unreadNotifications,
        onNotificationsTap: _openNotifications,
        onAddBudget: _addBudget,
        onUpdateBudget: _updateBudget,
        onDeleteBudget: _deleteBudget,
      ),
      GoalScreen(
      ),
      // Goals
      // Profile
      ProfileScreen(
        unreadNotifications: _unreadNotifications,
        onNotificationsTap: _openNotifications,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.main,
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'Budgets',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_rounded),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
