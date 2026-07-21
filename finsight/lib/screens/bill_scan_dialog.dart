import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../constants/app_colors.dart';

class BillScanDialog extends StatefulWidget {
  const BillScanDialog({super.key});

  @override
  State<BillScanDialog> createState() => _BillScanDialogState();
}

class _BillScanDialogState extends State<BillScanDialog> {
  final _serviceName = TextEditingController();
  final _amount = TextEditingController();
  final _categories = ['Food', 'Transport', 'Shopping', 'Bills', 'Others'];
  final _frequencies = ['weekly', 'monthly', 'yearly'];
  final _paymentMethods = ['Cash', 'Credit Card', 'Bank Transfer', 'EZ-Link'];

  Uint8List? _billImage;
  String _category = 'Bills';
  String _frequency = 'monthly';
  String _paymentMethod = 'Credit Card';
  String _scanStatus = 'Upload a bill first';
  DateTime _billingDate = DateTime.now();

  bool get _canUseCamera {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  @override
  void dispose() {
    _serviceName.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickBillImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedImage == null) return;

    final imageBytes = await pickedImage.readAsBytes();
    setState(() {
      _billImage = imageBytes;
      _scanStatus = _canUseCamera
          ? 'Reading bill text...'
          : 'Reading bill text from server...';
    });

    if (_canUseCamera) {
      await _readBillText(pickedImage.path);
    } else {
      await _readBillTextFromServer(imageBytes, pickedImage.name);
    }
  }

  Future<void> _readBillText(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await textRecognizer.processImage(inputImage);
      final billText = result.text.trim();

      if (billText.isEmpty) {
        setState(() => _scanStatus = 'Could not read the bill clearly');
        return;
      }

      debugPrint('Bill OCR text:\n$billText');
      _fillFromBillText(billText);
      setState(() => _scanStatus = 'Bill text extracted');
    } catch (error) {
      debugPrint('Mobile bill scan error: $error');
      setState(() => _scanStatus = 'Could not read bill. Try a clearer image.');
    } finally {
      await textRecognizer.close();
    }
  }

  Future<void> _readBillTextFromServer(
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
        debugPrint('Desktop bill scan failed: $body');
        setState(() => _scanStatus = 'Could not scan bill. Try a clearer image.');
        return;
      }

      final billText = (jsonDecode(body)['text'] as String?)?.trim();

      if (billText == null || billText.isEmpty) {
        setState(() => _scanStatus = 'Could not read the bill clearly');
        return;
      }

      debugPrint('Bill OCR text:\n$billText');
      _fillFromBillText(billText);
      setState(() => _scanStatus = 'Bill text extracted');
    } catch (error) {
      debugPrint('Desktop bill scan error: $error');
      setState(() => _scanStatus = 'Start the server to scan bills.');
    }
  }

  void _fillFromBillText(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final serviceName = _findServiceName(lines);
    final amount = _findBillAmount(text);
    final date = _findBillDate(text);
    final frequency = _guessFrequency(text);
    final paymentMethod = _findBillPaymentMethod(text);
    final category = _guessBillCategory(text);

    debugPrint(
      'Bill parsed: service=$serviceName amount=$amount date=$date '
      'frequency=$frequency category=$category payment=$paymentMethod',
    );

    setState(() {
      if (serviceName != null) {
        _serviceName.text = serviceName;
      }
      if (amount != null) {
        _amount.text = amount.toStringAsFixed(2);
      }
      if (date != null) {
        _billingDate = date;
      }
      _frequency = frequency;
      _category = category;
      _paymentMethod = paymentMethod;
    });
  }

  String? _findServiceName(List<String> lines) {
    final knownServices = [
      'netflix',
      'spotify',
      'disney',
      'youtube',
      'google',
      'apple',
      'icloud',
      'singtel',
      'starhub',
      'm1',
      'sp services',
      'aws',
      'microsoft',
      'adobe',
      'gym',
    ];
    final ignoredWords = [
      'invoice',
      'bill',
      'receipt',
      'date',
      'due',
      'amount',
      'total',
      'payment',
      'account',
      'statement',
      'transaction',
    ];

    for (final line in lines.take(12)) {
      final lowerLine = line.toLowerCase();
      if (knownServices.any(lowerLine.contains)) {
        return _cleanBillLine(line);
      }
    }

    for (final line in lines.take(8)) {
      final lowerLine = line.toLowerCase();
      final hasAmount = RegExp(r'\d+\.\d{2}').hasMatch(line);
      final hasDate = RegExp(r'\d{1,4}[\/\-\.]\d{1,2}[\/\-\.]\d{1,4}')
          .hasMatch(line);
      final shouldIgnore = ignoredWords.any(lowerLine.contains);
      final enoughLetters = line.replaceAll(RegExp(r'[^A-Za-z]'), '').length >= 3;

      if (!hasAmount && !hasDate && !shouldIgnore && enoughLetters) {
        return _cleanBillLine(line);
      }
    }

    return lines.isEmpty ? null : _cleanBillLine(lines.first);
  }

  String _cleanBillLine(String line) {
    return line
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[^A-Za-z]+'), '')
        .replaceAll(RegExp(r"[^A-Za-z0-9 &.'-]+$"), '')
        .trim();
  }

  double? _findBillAmount(String text) {
    final lines = text.split('\n').map((line) => line.trim()).toList();
    final amountWords = [
      'amount due',
      'total due',
      'bill amount',
      'monthly charge',
      'subscription fee',
      'grand total',
      'total',
    ];
    final skipWords = ['previous balance', 'outstanding', 'subtotal'];

    for (final line in lines.reversed) {
      final lowerLine = line.toLowerCase();
      final isAmountLine = amountWords.any(lowerLine.contains);
      final shouldSkip = skipWords.any(lowerLine.contains);
      if (!isAmountLine || shouldSkip) continue;

      final amount = _lastBillAmountInText(line);
      if (amount != null) return amount;
    }

    return _lastBillAmountInText(text);
  }

  double? _lastBillAmountInText(String text) {
    final matches = RegExp(r'(?:\$|sgd|s\$)?\s*(\d{1,4}(?:,\d{3})*\.\d{2})',
            caseSensitive: false)
        .allMatches(text)
        .toList();
    if (matches.isEmpty) return null;

    return double.tryParse(matches.last.group(1)!.replaceAll(',', ''));
  }

  DateTime? _findBillDate(String text) {
    final lines = text.split('\n');
    final dateWords = [
      'due date',
      'billing date',
      'payment date',
      'next payment',
      'payment due',
      'bill date',
    ];

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (!dateWords.any(lowerLine.contains)) continue;

      final date = _dateFromText(line);
      if (date != null) return date;
    }

    return _dateFromText(text);
  }

  DateTime? _dateFromText(String text) {
    final dayFirst = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})')
        .firstMatch(text);
    if (dayFirst != null) {
      final day = int.tryParse(dayFirst.group(1)!);
      final month = int.tryParse(dayFirst.group(2)!);
      final year = _normalBillYear(dayFirst.group(3)!);
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

  int? _normalBillYear(String text) {
    final year = int.tryParse(text);
    if (year == null) return null;
    if (text.length == 2) return 2000 + year;

    return year;
  }

  String _guessFrequency(String text) {
    final billText = text.toLowerCase();

    if (billText.contains('annual') ||
        billText.contains('yearly') ||
        billText.contains('per year') ||
        billText.contains('/year')) {
      return 'yearly';
    }
    if (billText.contains('weekly') ||
        billText.contains('per week') ||
        billText.contains('/week')) {
      return 'weekly';
    }

    return 'monthly';
  }

  String _guessBillCategory(String text) {
    final billText = text.toLowerCase();

    if (billText.contains('netflix') ||
        billText.contains('spotify') ||
        billText.contains('disney') ||
        billText.contains('youtube')) {
      return 'Others';
    }
    if (billText.contains('singtel') ||
        billText.contains('starhub') ||
        billText.contains('m1') ||
        billText.contains('sp services') ||
        billText.contains('utilities') ||
        billText.contains('electricity') ||
        billText.contains('water')) {
      return 'Bills';
    }
    if (billText.contains('grab') || billText.contains('ez-link')) {
      return 'Transport';
    }

    return 'Bills';
  }

  String _findBillPaymentMethod(String text) {
    final billText = text.toLowerCase();

    if (billText.contains('ez-link') || billText.contains('ezlink')) {
      return 'EZ-Link';
    }
    if (billText.contains('paynow') ||
        billText.contains('paylah') ||
        billText.contains('dbs') ||
        billText.contains('uob') ||
        billText.contains('ocbc') ||
        billText.contains('posb') ||
        billText.contains('bank account') ||
        billText.contains('giro')) {
      return 'Bank Transfer';
    }
    if (billText.contains('visa') ||
        billText.contains('mastercard') ||
        billText.contains('credit card') ||
        billText.contains('debit card') ||
        RegExp(r'\bcard\b').hasMatch(billText)) {
      return 'Credit Card';
    }
    if (RegExp(r'\bcash\b').hasMatch(billText)) {
      return 'Cash';
    }

    return _paymentMethod;
  }

  Future<void> _pickBillingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _billingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (picked != null) {
      setState(() {
        _billingDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _saveBillScan() {
    final serviceName = _serviceName.text.trim();
    final amount = double.tryParse(_amount.text.trim());

    if (serviceName.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check the bill details first.')),
      );
      return;
    }

    Navigator.pop(context, true);
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
            child: const Icon(Icons.event_repeat_outlined, color: AppColors.main),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scan Bill'),
                SizedBox(height: 4),
                Text(
                  'Check recurring payment details before saving.',
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
              _billImage == null ? _emptyBillBox() : _billPreview(),
              const SizedBox(height: 12),
              _imageButtons(),
              const SizedBox(height: 22),
              _sectionTitle('Recurring Details'),
              const SizedBox(height: 16),
              _fieldLabel('Service name'),
              const SizedBox(height: 8),
              TextField(
                controller: _serviceName,
                decoration: _decoration(
                  'e.g. Netflix Subscription',
                  Icons.subscriptions_outlined,
                ),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Payment amount'),
              const SizedBox(height: 8),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _decoration('0.00', Icons.attach_money),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Category'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: _decoration(null, Icons.category_outlined),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Frequency'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: _frequencies
                    .map(
                      (freq) => ButtonSegment(
                        value: freq,
                        label: Text(freq[0].toUpperCase() + freq.substring(1)),
                      ),
                    )
                    .toList(),
                selected: {_frequency},
                onSelectionChanged: (value) {
                  setState(() => _frequency = value.first);
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Payment method'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _paymentMethod,
                decoration: _decoration(null, Icons.payment_outlined),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _paymentMethod = value);
                },
              ),
              const SizedBox(height: 16),
              _fieldLabel('Billing date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickBillingDate,
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
                          '${_billingDate.day}/${_billingDate.month}/${_billingDate.year}',
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
          onPressed: _saveBillScan,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.main,
            minimumSize: const Size(150, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Confirm Bill'),
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
    if (!_canUseCamera) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: _uploadButtonStyle(),
            onPressed: () => _pickBillImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            style: _uploadButtonStyle(),
            onPressed: () => _pickBillImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Camera'),
          ),
        ),
      ],
    );
  }

  ButtonStyle _uploadButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.main,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  Widget _emptyBillBox() {
    return InkWell(
      onTap: () => _pickBillImage(ImageSource.gallery),
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
              'Upload bill or subscription',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'The app will suggest recurring payment details to check.',
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

  Widget _billPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 190,
            color: AppColors.light,
            child: Image.memory(_billImage!, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(85)],
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
