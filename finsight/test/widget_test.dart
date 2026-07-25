import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:finsight/screens/auth_provider.dart';
import 'package:finsight/screens/main_screen.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
        BASE_URL=https://placeholder
      ''',
    );
  });

  testWidgets('MainScreen shows all bottom navigation tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: const MaterialApp(home: MainScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Transactions'), findsWidgets);
    expect(find.text('Budgets'), findsWidgets);
    expect(find.text('Goals'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });
}
