library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

typedef BulkUploadContentHandler = void Function(String content);

Future<void> pickBulkUploadCsvFile(BulkUploadContentHandler onContent) async {
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = '.csv'
    ..click();

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.length == 0) {
      return;
    }

    final file = files.item(0);
    if (file == null) {
      return;
    }

    final reader = web.FileReader();
    reader.readAsText(file);
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result != null) {
        onContent((result as JSString).toDart);
      }
    });
  });
}

bool downloadBulkUploadCsvFile({
  required String filename,
  required String content,
}) {
  final bytes = utf8.encode(content);
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
  return true;
}
