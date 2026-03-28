/// Non-web stub for clearing the OAuth callback fragment.
///
/// On mobile/desktop platforms, there is no browser URL to clean up,
/// so this is a no-op. Paired with `web_auth_redirect_web.dart` via
/// conditional imports.
library;

/// No-op on non-web platforms.
void clearWebAuthCallbackFragment(String url) {}
