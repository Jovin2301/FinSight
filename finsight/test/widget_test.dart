import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:finsight/main.dart';
import 'package:finsight/screens/auth_provider.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
      API_URL=https://placeholder
    ''',
    );
  });

  testWidgets('FinSight app loads main navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const FinSightApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Available to spend'), findsOneWidget);
  });
}
