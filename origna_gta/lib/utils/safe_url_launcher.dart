import 'package:origna_gta/utils/app_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Allowed domains for external URL launching.
/// URLs with schemes like `mailto:` are always allowed.
const _allowedDomains = [
  // OrignaGTA
  'orignagta.ca',
  'www.orignagta.ca',
  'dev.orignagta.ca',
  'staging.orignagta.ca',
  'api.orignagta.ca',
  'api.dev.orignagta.ca',
  'api.staging.orignagta.ca',
  // Payments
  'stripe.com',
  'dashboard.stripe.com',
  'connect.stripe.com',
  'checkout.stripe.com',
  // Auth / OAuth
  'google.com',
  'accounts.google.com',
  // Shipping carriers (tracking URLs)
  'canadapost-postescanada.ca',
  'fedex.com',
  'ups.com',
  'purolator.com',
  'dhl.com',
  // Cloudflare R2 (download URLs)
  'r2.cloudflarestorage.com',
];

/// Returns true if the [uri] is safe to launch (domain is in allowlist or
/// scheme is mailto/tel).
bool isAllowedUrl(Uri uri) {
  // Always allow mailto and tel schemes
  if (uri.scheme == 'mailto' || uri.scheme == 'tel') return true;

  // Only allow http/https
  if (uri.scheme != 'http' && uri.scheme != 'https') return false;

  final host = uri.host.toLowerCase();
  return _allowedDomains.any((domain) => host == domain || host.endsWith('.$domain'));
}

/// Launch a URL only if its domain is in the allowlist.
/// Returns true if the URL was launched, false if blocked or launch failed.
///
/// [webOnlyWindowName] is passed through to [launchUrl] for web platform
/// (e.g. '_self' for same-tab navigation).
Future<bool> safeLaunchUrl(
  Uri uri, {
  LaunchMode mode = LaunchMode.platformDefault,
  String? webOnlyWindowName,
}) async {
  if (!isAllowedUrl(uri)) {
    AppLogger.w('Blocked launch of untrusted URL: $uri', tag: 'SafeUrlLauncher');
    return false;
  }
  return launchUrl(uri, mode: mode, webOnlyWindowName: webOnlyWindowName ?? '');
}
