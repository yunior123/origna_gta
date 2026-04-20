library;

typedef BulkUploadContentHandler = void Function(String content);

Future<void> pickBulkUploadCsvFile(BulkUploadContentHandler onContent) async {}

bool downloadBulkUploadCsvFile({
  required String filename,
  required String content,
}) {
  return false;
}
