class ReceiptScanResult {
  final String merchant;
  final double amount;
  final DateTime? date;
  final String category;

  const ReceiptScanResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
  });
}

class BillScanResult {
  final String serviceName;
  final double amount;
  final DateTime? billingDate;
  final String frequency;

  const BillScanResult({
    required this.serviceName,
    required this.amount,
    required this.billingDate,
    required this.frequency,
  });
}

class ScanTextParser {
  static ReceiptScanResult parseReceipt(String text) {
    final lines = _cleanLines(text);
    return ReceiptScanResult(
      merchant: _firstUsefulLine(lines),
      amount: _findAmount(text),
      date: _findDate(text),
      category: _guessReceiptCategory(text),
    );
  }

  static BillScanResult parseBill(String text) {
    final lines = _cleanLines(text);
    return BillScanResult(
      serviceName: _firstUsefulLine(lines),
      amount: _findAmount(text),
      billingDate: _findDate(text),
      frequency: _guessFrequency(text),
    );
  }

  static List<String> _cleanLines(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static String _firstUsefulLine(List<String> lines) {
    const skipWords = [
      'receipt',
      'invoice',
      'total',
      'amount',
      'date',
      'gst',
      'subtotal',
      'payment',
    ];

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      final hasMoney = RegExp(r'\d+\.\d{2}').hasMatch(line);
      final shouldSkip = skipWords.any(lowerLine.contains);
      if (!hasMoney && !shouldSkip) return line;
    }

    return lines.isEmpty ? '' : lines.first;
  }

  static double _findAmount(String text) {
    final amountLines = text.split('\n').where((line) {
      final lowerLine = line.toLowerCase();
      return lowerLine.contains('total') ||
          lowerLine.contains('amount due') ||
          lowerLine.contains('bill amount') ||
          lowerLine.contains('amount payable');
    });

    for (final line in amountLines) {
      final amount = _lastAmount(line);
      if (amount != null) return amount;
    }

    return _lastAmount(text) ?? 0;
  }

  static double? _lastAmount(String text) {
    final matches = RegExp(
      r'\$?\s?(\d{1,5}(?:,\d{3})*\.\d{2})',
    ).allMatches(text).toList();
    if (matches.isEmpty) return null;
    return double.tryParse(matches.last.group(1)!.replaceAll(',', ''));
  }

  static DateTime? _findDate(String text) {
    final dateMatch = RegExp(
      r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b',
    ).firstMatch(text);

    if (dateMatch == null) return null;

    final day = int.tryParse(dateMatch.group(1)!);
    final month = int.tryParse(dateMatch.group(2)!);
    var year = int.tryParse(dateMatch.group(3)!);

    if (day == null || month == null || year == null) return null;
    if (year < 100) year += 2000;

    return DateTime(year, month, day);
  }

  static String _guessReceiptCategory(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('mrt') ||
        lowerText.contains('bus') ||
        lowerText.contains('grab') ||
        lowerText.contains('ez-link')) {
      return 'Transport';
    }
    if (lowerText.contains('netflix') ||
        lowerText.contains('singtel') ||
        lowerText.contains('starhub') ||
        lowerText.contains('utilities')) {
      return 'Bills';
    }
    if (lowerText.contains('shopee') ||
        lowerText.contains('uniqlo') ||
        lowerText.contains('shopping')) {
      return 'Shopping';
    }
    return 'Food';
  }

  static String _guessFrequency(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('yearly') ||
        lowerText.contains('annual') ||
        lowerText.contains('per year')) {
      return 'yearly';
    }
    if (lowerText.contains('weekly') || lowerText.contains('per week')) {
      return 'weekly';
    }
    return 'monthly';
  }
}
