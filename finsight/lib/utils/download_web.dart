import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

void downloadCsvWeb(String csvData, String fileName) {
  final bytes = utf8.encode(csvData);
  final blobParts = [bytes.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: 'text/csv'));
  final url = web.URL.createObjectURL(blob);

  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName
    ..style.display = 'none';

  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}
