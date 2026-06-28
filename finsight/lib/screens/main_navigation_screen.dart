import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _tab = 0;
  double _budget = 500.00;

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

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        expenses: _expenses,
        monthlyBudget: _budget,
        onAddExpense: (expense) => setState(() => _expenses.add(expense)),
        onBudgetChanged: (budget) => setState(() => _budget = budget),
        onViewTransactions: () => setState(() => _tab = 1),
      ),
      TransactionsScreen(
        expenses: _expenses,
        onAddExpense: (expense) => setState(() => _expenses.add(expense)),
        onUpdateExpense: (index, expense) {
          setState(() => _expenses[index] = expense);
        },
        onDeleteExpense: (index) => setState(() => _expenses.removeAt(index)),
        unreadNotifications: 0,
        onNotificationsTap: () {},
      ),
    ];

    return Scaffold(
      body: screens[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (index) => setState(() => _tab = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
        ],
      ),
    );
  }
}
