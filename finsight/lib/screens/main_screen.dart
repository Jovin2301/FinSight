import 'package:flutter/material.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/goal.dart';
import '../constants/app_colors.dart';
import './transactions_screen.dart';
import './profile_screen.dart';
import './wallet_screen.dart';
import './homeContent.dart';
import './goal_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  double _budget = 500.00;

  final List<Budget> _budgets = [
    const Budget(id: '1', category: 'Food', limit: 200),
    const Budget(id: '2', category: 'Transport', limit: 120),
    const Budget(id: '3', category: 'Shopping', limit: 180),
  ];

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

  final List<Expense> _expenses = [
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
  ];

  void _goToTransactions() => setState(() => _currentIndex = 1);

  void _addGoal(Goal goal) => setState(() => _goals.add(goal));

  void _updateGoal(int index, Goal goal) =>
      setState(() => _goals[index] = goal);

  void _deleteGoal(int index) => setState(() => _goals.removeAt(index));

  void _addBudget(Budget budget) => setState(() => _budgets.add(budget));

  void _updateBudget(int index, Budget budget) =>
      setState(() => _budgets[index] = budget);

  void _deleteBudget(int index) => setState(() => _budgets.removeAt(index));

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      // Home
      HomeContent(
        expenses: _expenses,
        budgets: _budgets,
        goals: _goals,
        monthlyBudget: _budget,
        onAddExpense: (expense) => setState(() => _expenses.add(expense)),
        onBudgetChanged: (budget) => setState(() => _budget = budget),
        onViewTransactions: _goToTransactions,
      ),
      // Transactions
      TransactionsScreen(
        expenses: _expenses,
        onAddExpense: (expense) => setState(() => _expenses.add(expense)),
        onUpdateExpense: (index, expense) =>
            setState(() => _expenses[index] = expense),
        onDeleteExpense: (index) => setState(() => _expenses.removeAt(index)),
      ),
      // Wallet
      WalletScreen(
        budgets: _budgets,
        expenses: _expenses,
        onAddBudget: _addBudget,
        onUpdateBudget: _updateBudget,
        onDeleteBudget: _deleteBudget,
      ),
      GoalScreen(
      ),
      // Goals
      // Profile
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
              label: 'Wallet',
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
