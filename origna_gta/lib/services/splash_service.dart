// Conditional import to handle Web vs Mobile
import 'package:origna_gta/services/splash_manager_stub.dart' if (dart.library.js) 'package:origna_gta/services/splash_manager_web.dart';

class SplashService {
  /// Removes the web splash screen manually.
  /// This should be called when the app is fully initialized (e.g. after Auth check).
  static void removeSplash() {
    SplashManager().removeSplash();
  }
}
