import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/app_logger.dart';

/// Service for fetching and caching remote configuration from OrignaBase.
///
/// Singleton that loads all config key-value pairs from OrignaBase's `/config`
/// endpoint on startup and caches them in memory. Supports `--dart-define`
/// overrides for local development and integration testing.
///
/// Config values include:
/// - Geoapify API key (geocoding/address autocomplete)
/// - Image base URL (Cloudflare R2 CDN)
/// - GlitchTip DSN (self-hosted error reporting)
/// - Google OAuth web client ID
class OrignaBaseConfigService {
  static final OrignaBaseConfigService _instance =
      OrignaBaseConfigService._internal();

  /// In-memory cache of config key-value pairs.
  final Map<String, String> _cache = {};

  /// The OrignaBase client instance, set during [initialize].
  OrignaBase? _ob;

  /// Returns the singleton [OrignaBaseConfigService] instance.
  factory OrignaBaseConfigService() => _instance;

  OrignaBaseConfigService._internal();

  /// The Geoapify API key for geocoding and address autocomplete.
  ///
  /// Prefers a `--dart-define` override (for dev/integration), falls back
  /// to the server-fetched value.
  String get geoapifyKey {
    // Allow integration/dev to override via --dart-define.
    const override = String.fromEnvironment(
      RemoteConfigKeys.geoapifyApiKey,
      defaultValue: '',
    );
    if (override.trim().isNotEmpty) return override.trim();
    return _cache[RemoteConfigKeys.geoapifyApiKey] ?? '';
  }

  /// Base URL for serving product images (e.g., `https://cdn.example.com/`).
  String get imageBaseUrl => _cache[RemoteConfigKeys.imageBaseUrl] ?? '';

  /// GlitchTip DSN for self-hosted error reporting and crash analytics.
  ///
  /// Supports `--dart-define=GLITCHTIP_DSN=...` for local verification and
  /// falls back to the legacy `sentry_dns` remote config key during migration.
  String get glitchtipDsn {
    const override = String.fromEnvironment('GLITCHTIP_DSN', defaultValue: '');
    if (override.trim().isNotEmpty) return override.trim();
    final value = _cache[RemoteConfigKeys.glitchtipDsn]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return _cache[RemoteConfigKeys.sentryDnsKey] ?? '';
  }

  /// Deprecated compatibility alias for callers not yet migrated.
  @Deprecated('Use glitchtipDsn.')
  String get sentryDnsKey => glitchtipDsn;

  /// Google OAuth web client ID for Sign-In with Google on web.
  String get googleWebClientId =>
      _cache[RemoteConfigKeys.googleWebClientId] ?? '';

  /// Initializes the config service with safe defaults, then fetches from server.
  ///
  /// Parameters:
  /// - [ob]: the OrignaBase client instance for API access.
  /// - [skipFetch]: if `true`, sets defaults but skips the server fetch
  ///   (useful for offline/testing scenarios).
  ///
  /// Errors during the fetch are caught and logged — the app starts with
  /// empty defaults rather than crashing.
  Future<void> initialize(OrignaBase ob, {bool skipFetch = false}) async {
    _ob = ob;

    // Set safe defaults.
    _cache[RemoteConfigKeys.geoapifyApiKey] = '';
    _cache[RemoteConfigKeys.imageBaseUrl] = '';
    _cache[RemoteConfigKeys.glitchtipDsn] = '';
    _cache[RemoteConfigKeys.sentryDnsKey] = '';
    _cache[RemoteConfigKeys.googleWebClientId] = '';
    if (skipFetch) return;

    try {
      final all = await _ob!.config.getAll();
      for (final entry in all.entries) {
        _cache[entry.key] = entry.value?.toString() ?? '';
      }
      AppLogger.i(
        'OrignaBaseConfig loaded: geoapify_api_key present=${geoapifyKey.trim().isNotEmpty}',
        tag: 'config',
      );
    } catch (_) {
      AppLogger.w(
        'OrignaBaseConfig fetch failed (geoapify_api_key may be empty)',
        tag: 'config',
      );
    }
  }

  /// Re-fetches a single config value from the server on demand.
  ///
  /// Parameters:
  /// - [key]: the config key to fetch (e.g., [RemoteConfigKeys.geoapifyApiKey]).
  ///
  /// Returns the fetched value, or the cached value (or empty string) if the
  /// fetch fails or the OrignaBase client is not yet initialized.
  Future<String> getString(String key) async {
    if (_ob == null) return _cache[key] ?? '';
    try {
      final value = await _ob!.config.getString(key);
      _cache[key] = value;
      return value;
    } catch (e) {
      AppLogger.w(
        'OrignaBaseConfigService: getString failed, returning cached',
        tag: 'config',
        error: e,
      );
      return _cache[key] ?? '';
    }
  }
}
