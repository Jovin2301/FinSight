import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/main.dart';

void main() {
  testWidgets('FinSight app loads main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FinSightApp());

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Available to spend'), findsOneWidget);
  });
}
