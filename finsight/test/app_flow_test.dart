import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/models/budget.dart';
import 'package:finsight/screens/login_screen.dart';
import 'package:finsight/widgets/budget_card.dart';

void main() {
  testWidgets('login flow shows validation message for empty form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please fill in all fields'), findsOneWidget);
  });

  testWidgets('budget card system flow shows progress and handles delete tap', (
    WidgetTester tester,
  ) async {
    var deleteTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetCard(
            budget: const Budget(
              id: 'budget-1',
              category: 'Food',
              icon: '🍔',
              limit: 300,
              frequency: 'monthly',
            ),
            spent: 240,
            onDelete: () => deleteTapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('\$240.00'), findsOneWidget);
    expect(find.text('\$300.00'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pump();

    expect(deleteTapped, true);
  });
}
