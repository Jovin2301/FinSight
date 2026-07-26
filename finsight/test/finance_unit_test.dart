import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/models/budget.dart';
import 'package:finsight/models/expense.dart';
import 'package:finsight/models/goal.dart';
import 'package:finsight/models/recurring_payment.dart';
import 'package:finsight/screens/goal_screen.dart';

void main() {
  test('budget model reads database json correctly', () {
    final budget = Budget.fromJson({
      'id': 'budget-1',
      'name': 'Food Budget',
      'icon': '🍔',
      'category': 'Food',
      'limit': '300.00',
      'description': 'Monthly food spending',
      'frequency': 'monthly',
      'spent': '86.50',
    });

    expect(budget.id, 'budget-1');
    expect(budget.name, 'Food Budget');
    expect(budget.category, 'Food');
    expect(budget.limit, 300.00);
    expect(budget.spent, 86.50);
    expect(budget.frequency, 'monthly');
  });

  test('budget progress calculation returns correct percentage', () {
    const budget = Budget(
      id: 'budget-2',
      category: 'Transport',
      limit: 120,
      spent: 96,
    );

    expect(budget.progress, 0.8);
  });

  test('remaining budget calculation returns correct amount', () {
    const budget = Budget(
      id: 'budget-1',
      category: 'Food',
      limit: 300,
      spent: 86.50,
    );

    expect(budget.remainingAmount, 213.50);
  });

  test('active budget check only returns active budgets', () {
    final today = DateTime(2026, 7, 26);
    final budgets = [
      Budget(
        id: 'active-budget',
        category: 'Food',
        limit: 300,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
      ),
      Budget(
        id: 'old-budget',
        category: 'Transport',
        limit: 120,
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 30),
      ),
    ];

    final activeBudgets = budgets.where((budget) => budget.isActiveOn(today));

    expect(activeBudgets.map((budget) => budget.id), ['active-budget']);
  });

  test('transaction model conversion reads database json correctly', () {
    final expense = Expense.fromJson({
      'id': 'transaction-1',
      'title': 'Lunch',
      'category': 'Food',
      'amount': '8.50',
      'date': '2026-07-26',
      'paymentMethod': 'PayLah',
    });

    expect(expense.id, 'transaction-1');
    expect(expense.title, 'Lunch');
    expect(expense.category, 'Food');
    expect(expense.amount, 8.50);
    expect(expense.paymentMethod, 'PayLah');
  });

  test('saving goal progress calculation returns correct percentage', () {
    const goal = Goal(
      id: 'goal-1',
      title: 'Emergency Fund',
      targetAmount: 1000,
      savedAmount: 250,
      status: GoalStatus.onTrack,
    );

    expect(goal.progress, 0.25);
  });

  test('recurring payment model conversion reads bill json correctly', () {
    final recurringPayment = RecurringPayment.fromJson({
      'id': 'recurring-1',
      'name': 'Netflix Subscription',
      'category': 'Bills',
      'amount': '15.98',
      'frequency': 'monthly',
      'startDate': '2026-07-26',
      'status': 'active',
    });

    expect(recurringPayment.name, 'Netflix Subscription');
    expect(recurringPayment.category, 'Bills');
    expect(recurringPayment.amount, 15.98);
    expect(recurringPayment.frequency, 'monthly');
  });
}
