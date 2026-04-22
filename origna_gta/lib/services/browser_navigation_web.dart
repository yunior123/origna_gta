import 'package:web/web.dart' as web;

bool get supportsBrowserNavigation => true;

void navigateToPath(String path) {
  web.window.location.assign(path);
}
