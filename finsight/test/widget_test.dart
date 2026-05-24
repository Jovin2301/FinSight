import 'package:flutter_test/flutter_test.dart';

import 'package:finsight/main.dart';

void main() {
  testWidgets('FinSight app loads transactions screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FinSightApp());

    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Total Spent'), findsOneWidget);
    expect(find.text('Recent Expenses'), findsOneWidget);
  });
}
