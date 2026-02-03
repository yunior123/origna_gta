// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class SplashManager {
  void removeSplash() {
    if (js.context.hasProperty('removeSplashFromWeb')) {
      js.context.callMethod('removeSplashFromWeb');
    } else {
      // Fallback if the function isn't found (e.g. index.html mismatch)
      // We try to remove the element by ID manually just in case
      try {
        final splash = js.context['document'].callMethod('getElementById', ['splash']);
        if (splash != null) {
          splash.callMethod('remove');
        }
      } catch (_) {
        // Ignore errors
      }
    }
  }
}
