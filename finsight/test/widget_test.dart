import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:finsight/main.dart';

void main() {
  setUpAll(() async {
    // Load dotenv with test values so widgets reading dotenv.env[...] don't throw
    dotenv.testLoad(
      fileInput: '''
API_URL=https://placeholder
''',
    );
  });

  testWidgets('FinSight app loads main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const FinSightApp());

    // Let splash screen navigation complete
    await tester.pumpAndSettle();

    // TODO: if splash routes to login when unauthenticated,
    // this will fail here — see note below
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Available to spend'), findsOneWidget);
  });
}
