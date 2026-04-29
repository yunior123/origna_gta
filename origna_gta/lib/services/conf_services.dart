import 'package:origna_gta/services/orignabase_conf_service.dart';

/// Backward-compatible facade over [OrignaBaseConfigService].
///
/// Delegates all configuration reads to [OrignaBaseConfigService] so that
/// existing callers (e.g., `utils.dart`, `orignabase_product_repository.dart`)
/// continue to compile without import changes. This is a singleton.
///
/// Prefer using [OrignaBaseConfigService] directly in new code.
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();

  /// Returns the singleton [ConfigService] instance.
  factory ConfigService() => _instance;

  ConfigService._internal();

  /// The Geoapify API key used for geocoding and address autocomplete.
  String get geoapifyKey => OrignaBaseConfigService().geoapifyKey;

  /// Base URL for serving product images (e.g., Cloudflare R2 public URL).
  String get imageBaseUrl => OrignaBaseConfigService().imageBaseUrl;

  /// GlitchTip DSN key for self-hosted error reporting and crash analytics.
  String get glitchtipDsn => OrignaBaseConfigService().glitchtipDsn;

  /// Deprecated compatibility alias for callers not yet migrated.
  @Deprecated('Use glitchtipDsn.')
  String get sentryDnsKey => glitchtipDsn;

  /// Google OAuth web client ID for Sign-In with Google.
  String get googleWebClientId => OrignaBaseConfigService().googleWebClientId;

  /// No-op. Initialization is performed by [OrignaBaseConfigService] in main.dart.
  ///
  /// [skipFetch] is accepted for API compatibility but has no effect here.
  Future<void> initialize({bool skipFetch = false}) async {}
}
