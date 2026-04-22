import 'package:web/web.dart' as web;

String? getStoredLocale() {
  return web.window.localStorage.getItem('ov_locale');
}

void setStoredLocale(String value) {
  web.window.localStorage.setItem('ov_locale', value);
}

String? getBrowserLanguage() {
  return web.window.navigator.language;
}

bool? getCookieConsentAccepted() {
  final value = web.window.localStorage.getItem('ov_cookie_consent');
  if (value == null) return null;
  return value == 'accepted';
}

void setCookieConsentAccepted(bool accepted) {
  web.window.localStorage.setItem(
    'ov_cookie_consent',
    accepted ? 'accepted' : 'declined',
  );
}

void openUrl(String url) {
  web.window.location.assign(url);
}
