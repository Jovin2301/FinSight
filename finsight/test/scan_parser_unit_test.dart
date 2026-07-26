import 'package:flutter_test/flutter_test.dart';
import 'package:finsight/utils/scan_text_parser.dart';

void main() {
  test('receipt parsing extracts merchant amount date and category', () {
    const receiptText = '''
FairPrice Finest
Receipt No 10291
Date 26/07/2026
TOTAL \$18.90
PayLah
''';

    final result = ScanTextParser.parseReceipt(receiptText);

    expect(result.merchant, 'FairPrice Finest');
    expect(result.amount, 18.90);
    expect(result.date, DateTime(2026, 7, 26));
    expect(result.category, 'Food');
  });

  test('bill parsing extracts recurring amount frequency and billing date', () {
    const billText = '''
Netflix Subscription
Billing Date 26/07/2026
Amount Due \$15.98
Monthly subscription
''';

    final result = ScanTextParser.parseBill(billText);

    expect(result.serviceName, 'Netflix Subscription');
    expect(result.amount, 15.98);
    expect(result.billingDate, DateTime(2026, 7, 26));
    expect(result.frequency, 'monthly');
  });
}
