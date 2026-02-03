import 'package:web/web.dart' as web;

class SplashManager {
  void removeSplash() {
    // Fast + bulletproof: remove known splash elements by id/class.
    // (If index.html also exposes removeSplashFromWeb(), it's fine to leave it;
    // this keeps the Dart side independent of JS interop APIs.)
    try {
      web.document.getElementById('splash')?.remove();
      web.document.getElementById('splash-branding')?.remove();
      web.document.getElementById('splash-loader')?.remove();

      final rings = web.document.querySelectorAll('.energy-ring');
      for (var i = 0; i < rings.length; i++) {
        final node = rings.item(i);
        node?.parentNode?.removeChild(node);
      }

      final extras = web.document.querySelectorAll('.orbit-container, .commerce-overlay, .product-card-hint');
      for (var i = 0; i < extras.length; i++) {
        final node = extras.item(i);
        node?.parentNode?.removeChild(node);
      }
      for (final id in const ['grid-3d', 'shapes-3d', 'stars-canvas', 'particles']) {
        web.document.getElementById(id)?.remove();
      }
    } catch (_) {
      // ignore
    }
  }
}
