/// Web implementation for clearing the OAuth callback fragment from the URL.
///
/// After a Google/Apple OAuth redirect, the URL contains a fragment or query
/// parameters from the auth callback. This library uses `window.history.replaceState`
/// via JS interop to clean the URL without triggering a page reload.
library;

import 'dart:js_interop';

/// Native JS binding to `window.history.replaceState`.
@JS('window.history.replaceState')
external void _replaceState(JSAny? data, JSString title, JSString url);

/// Clears the OAuth callback fragment/params from the browser URL.
///
/// Uses `history.replaceState` to rewrite the URL to [url] without reloading.
/// Called after processing the OAuth redirect callback.
void clearWebAuthCallbackFragment(String url) {
  _replaceState(null, ''.toJS, url.toJS);
}
