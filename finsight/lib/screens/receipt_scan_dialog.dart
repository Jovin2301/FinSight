import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';
import '../models/expense.dart';

class ReceiptScanDialog extends StatefulWidget {
  const ReceiptScanDialog({super.key});

  @override
  State<ReceiptScanDialog> createState() => _ReceiptScanDialogState();
}

class _ReceiptScanDialogState extends State<ReceiptScanDialog> {
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  final _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
  final _paymentMethods = ['Cash', 'Credit Card', 'Bank Transfer', 'EZ-Link'];

  Uint8List? _receiptImage;
  String _scanStatus = 'Pick a receipt first';
  String _category = 'Food';
  String _paymentMethod = 'Cash';
  DateTime _date = DateTime.now();

  bool get _canUseCamera {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _saveScannedReceipt() {
    final merchant = _merchant.text.trim();
    final amount = double.tryParse(_amount.text.trim());

    if (merchant.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check the scanned receipt details.')),
      );
      return;
    }

    Navigator.pop(
      context,
      Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: merchant,
        category: _category,
        amount: amount,
        date: _date,
        paymentMethod: _paymentMethod,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickReceiptImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedImage == null) return;

    final imageBytes = await pickedImage.readAsBytes();
    setState(() {
      _receiptImage = imageBytes;
      _paymentMethod = 'Cash';
      _scanStatus = _canUseCamera
          ? 'Reading receipt text...'
          : 'Reading receipt text from server...';
    });

    if (_canUseCamera) {
      await _readReceiptText(pickedImage.path);
    } else {
      await _readReceiptTextFromServer(imageBytes, pickedImage.name);
    }
  }

  Future<void> _readReceiptText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await textRecognizer.processImage(inputImage);
      final receiptText = result.text.trim();

      if (receiptText.isEmpty) {
        setState(() => _scanStatus = 'Could not read the receipt clearly');
        return;
      }

      debugPrint('Receipt OCR text:\n$receiptText');
      _fillFromReceiptText(receiptText);
      setState(() => _scanStatus = 'Receipt text extracted');
    } catch (error) {
      debugPrint('Mobile receipt scan error: $error');
      setState(() => _scanStatus = 'Could not read receipt. Try a clearer image.');
    } finally {
      await textRecognizer.close();
    }
  }

  Future<void> _readReceiptTextFromServer(
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      final baseUrl = dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:3000';
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/receipt/scan'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'receipt',
          imageBytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        debugPrint('Desktop receipt scan failed: $body');
        setState(() => _scanStatus = 'Could not scan receipt. Try a clearer image.');
        return;
      }

      final receiptText = (jsonDecode(body)['text'] as String?)?.trim();

      if (receiptText == null || receiptText.isEmpty) {
        setState(() => _scanStatus = 'Could not read the receipt clearly');
        return;
      }

      debugPrint('Receipt OCR text:\n$receiptText');
      _fillFromReceiptText(receiptText);
      setState(() => _scanStatus = 'Receipt text extracted');
    } catch (error) {
      debugPrint('Desktop receipt scan error: $error');
      setState(() => _scanStatus = 'Start the server to scan receipts.');
    }
  }

  void _fillFromReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final amount = _findAmount(text);
    final date = _findDate(text);
    final merchant = _findMerchant(lines);
    final paymentMethod = _findPaymentMethod(text);
    debugPrint(
      'Receipt parsed: merchant=$merchant amount=$amount date=$date category=${_guessCategory(text)} payment=$paymentMethod',
    );

    setState(() {
      if (merchant != null) {
        _merchant.text = merchant;
      }
      if (amount != null) {
        _amount.text = amount.toStringAsFixed(2);
      }
      if (date != null) {
        _date = date;
      }
      _category = _guessCategory(text);
      _paymentMethod = paymentMethod;
    });
  }

  String? _findMerchant(List<String> lines) {
    final knownStores = [
      'fairprice',
      'ntuc',
      'cold storage',
      'sheng siong',
      'giant',
      'toast box',
      'starbucks',
      'mcdonald',
      'kfc',
      'subway',
      'watsons',
      'guardian',
      'uniqlo',
      'shopee',
      'lazada',
      'grab',
      'comfortdelgro',
    ];
    final ignoredWords = [
      'receipt',
      'invoice',
      'date',
      'time',
      'gst',
      'tax',
      'total',
      'amount',
      'cashier',
      'change',
      'payment',
      'visa',
      'mastercard',
      'subtotal',
      'balance',
      'approval',
      'terminal',
      'merchant id',
      'transaction',
      'uen',
      'tel',
      'address',
    ];

    for (final line in lines.take(10)) {
      final lowerLine = line.toLowerCase();
      final hasStoreName = knownStores.any(lowerLine.contains);

      if (hasStoreName) {
        return _cleanMerchantLine(line);
      }
    }

    for (final line in lines.take(10)) {
      final lowerLine = line.toLowerCase();
      final hasNumber = RegExp(r'\d').hasMatch(line);
      final hasAmount = RegExp(r'\d+\.\d{2}').hasMatch(line);
      final hasDate = RegExp(r'\d{1,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,4}')
          .hasMatch(line);
      final shouldIgnore = ignoredWords.any(lowerLine.contains);
      final tooShort = line.replaceAll(RegExp(r'[^A-Za-z]'), '').length < 3;

      if (!hasNumber && !hasAmount && !hasDate && !shouldIgnore && !tooShort) {
        return _cleanMerchantLine(line);
      }
    }

    return lines.isEmpty ? null : _cleanMerchantLine(lines.first);
  }

  String _cleanMerchantLine(String line) {
    return line
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[^A-Za-z]+'), '')
        .replaceAll(RegExp(r"[^A-Za-z0-9 &.'-]+$"), '')
        .trim();
  }

  double? _findAmount(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();
    final totalWords = [
      'grand total',
      'net total',
      'amount due',
      'total due',
      'total',
    ];
    final skipWords = ['subtotal', 'sub total', 'change', 'cash', 'balance'];

    for (final line in lines.reversed) {
      final lowerLine = line.toLowerCase();
      final isTotalLine = totalWords.any(lowerLine.contains);
      final shouldSkip = skipWords.any(lowerLine.contains);
      if (!isTotalLine || shouldSkip) continue;

      final lineAmount = _lastAmountInText(line);
      if (lineAmount != null) return lineAmount;
    }

    return _lastAmountInText(text);
  }

  double? _lastAmountInText(String text) {
    final matches = RegExp(r'(?:\$|sgd|s\$)?\s*(\d{1,4}(?:,\d{3})*\.\d{2})',
            caseSensitive: false)
        .allMatches(text)
        .toList();
    if (matches.isEmpty) return null;

    return double.tryParse(matches.last.group(1)!.replaceAll(',', ''));
  }

  DateTime? _findDate(String text) {
    final dayFirst = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})')
        .firstMatch(text);
    if (dayFirst != null) {
      final day = int.tryParse(dayFirst.group(1)!);
      final month = int.tryParse(dayFirst.group(2)!);
      final year = _normalYear(dayFirst.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    final yearFirst = RegExp(r'(\d{4})[\/\-\.](\d{1,2})[\/\-\.](\d{1,2})')
        .firstMatch(text);
    if (yearFirst != null) {
      final year = int.tryParse(yearFirst.group(1)!);
      final month = int.tryParse(yearFirst.group(2)!);
      final day = int.tryParse(yearFirst.group(3)!);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  int? _normalYear(String text) {
    final year = int.tryParse(text);
    if (year == null) return null;
    if (text.length == 2) return 2000 + year;

    return year;
  }

  String _guessCategory(String text) {
    final receiptText = text.toLowerCase();

    if (receiptText.contains('mrt') ||
        receiptText.contains('bus') ||
        receiptText.contains('grab') ||
        receiptText.contains('gojek') ||
        receiptText.contains('taxi') ||
        receiptText.contains('ez-link')) {
      return 'Transport';
    }
    if (receiptText.contains('uniqlo') ||
        receiptText.contains('lazada') ||
        receiptText.contains('watsons') ||
        receiptText.contains('shopee') ||
        receiptText.contains('shopping')) {
      return 'Shopping';
    }
    if (receiptText.contains('bill') ||
        receiptText.contains('singtel') ||
        receiptText.contains('starhub') ||
        receiptText.contains('sp services') ||
        receiptText.contains('utilities')) {
      return 'Bills';
    }
    if (receiptText.contains('fairprice') ||
        receiptText.contains('ntuc') ||
        receiptText.contains('food') ||
        receiptText.contains('restaurant') ||
        receiptText.contains('mcdonald') ||
        receiptText.contains('cafe')) {
      return 'Food';
    }

    return 'Others';
  }

  String _findPaymentMethod(String text) {
    final receiptText = text.toLowerCase();

    if (receiptText.contains('ez-link') || receiptText.contains('ezlink')) {
      return 'EZ-Link';
    }
    if (receiptText.contains('paynow') ||
        receiptText.contains('pay now') ||
        receiptText.contains('paylah') ||
        receiptText.contains('pay lah') ||
        receiptText.contains('dbs') ||
        receiptText.contains('uob') ||
        receiptText.contains('ocbc') ||
        receiptText.contains('posb') ||
        receiptText.contains('bank account') ||
        receiptText.contains('bank transfer') ||
        receiptText.contains('fund transfer') ||
        receiptText.contains('savings account') ||
        receiptText.contains('saving account') ||
        receiptText.contains('current account')) {
      return 'Bank Transfer';
    }
    if (receiptText.contains('visa') ||
        receiptText.contains('mastercard') ||
        receiptText.contains('master card') ||
        receiptText.contains('credit card') ||
        receiptText.contains('debit card') ||
        RegExp(r'\bcard\b').hasMatch(receiptText)) {
      return 'Credit Card';
    }
    if (receiptText.contains('cash tendered') ||
        receiptText.contains('cash paid') ||
        RegExp(r'\bcash\b').hasMatch(receiptText)) {
      return 'Cash';
    }

    return _paymentMethod;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 6),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.light,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: AppColors.main,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan Receipt'),
                SizedBox(height: 4),
                Text(
                  'Check the details before saving.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 430,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _receiptImage == null ? _emptyReceiptBox() : _receiptPreview(),
              const SizedBox(height: 12),
              _imageButtons(),
              const SizedBox(height: 22),
              _sectionTitle('Extracted Details'),
              const SizedBox(height: 16),
              _fieldLabel('Merchant'),
              const SizedBox(height: 8),
              TextField(
                controller: _merchant,
                decoration: _decoration('Merchant name', Icons.store_outlined),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Amount'),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('0.00', Icons.attach_money),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Possible category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _decoration(null, Icons.category_outlined),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Payment method'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: _decoration(null, Icons.payment_outlined),
                items: _paymentMethods
                    .map(
                      (method) =>
                          DropdownMenuItem(value: method, child: Text(method)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _paymentMethod = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.light,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.main),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          '${_date.day}/${_date.month}/${_date.year}',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveScannedReceipt,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.main,
            minimumSize: const Size(150, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save Transaction'),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
  }

  Widget _sectionTitle(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _imageButtons() {
    if (!_canUseCamera) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.main,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _pickReceiptImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.main,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => _pickReceiptImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Camera'),
          ),
        ),
      ],
    );
  }

  Widget _emptyReceiptBox() {
    return InkWell(
      onTap: () => _pickReceiptImage(ImageSource.gallery),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.light,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.main.withAlpha(85), width: 1.4),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.main.withAlpha(20),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.upload_file_outlined,
                color: AppColors.main,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Upload receipt image',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Choose a clear photo so the details can be suggested.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            if (!_canUseCamera) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Browse Files',
                  style: TextStyle(
                    color: AppColors.main,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _receiptPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 190,
            color: AppColors.light,
            child: Image.memory(_receiptImage!, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withAlpha(85),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(235),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.main,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _scanStatus,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String? hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.main),
    );
  }
}
