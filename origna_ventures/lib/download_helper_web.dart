import 'package:web/web.dart' as web;

Future<void> triggerDownload(String url) async {
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = '';
  web.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
