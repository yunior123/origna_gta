import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/app_logger.dart';

/// OrignaBase config service.
/// Fetches config key-value pairs from OrignaBase's /config endpoint.
class OrignaBaseConfigService {
  static final OrignaBaseConfigService _instance =
      OrignaBaseConfigService._internal();

  final Map<String, String> _cache = {};
  OrignaBase? _ob;

  factory OrignaBaseConfigService() => _instance;

  OrignaBaseConfigService._internal();

  String get geoapifyKey {
    // Allow integration/dev to override via --dart-define.
    const override = String.fromEnvironment(
      RemoteConfigKeys.geoapifyApiKey,
      defaultValue: '',
    );
    if (override.trim().isNotEmpty) return override.trim();
    return _cache[RemoteConfigKeys.geoapifyApiKey] ?? '';
  }

  String get imageBaseUrl =>
      _cache[RemoteConfigKeys.imageBaseUrl] ?? '';

  String get sentryDnsKey =>
      _cache[RemoteConfigKeys.sentryDnsKey] ?? '';

  String get googleWebClientId =>
      _cache[RemoteConfigKeys.googleWebClientId] ?? '';

  /// Initialize with defaults, then fetch from OrignaBase server.
  Future<void> initialize(OrignaBase ob, {bool skipFetch = false}) async {
    _ob = ob;

    // Set safe defaults.
    _cache[RemoteConfigKeys.geoapifyApiKey] = '';
    _cache[RemoteConfigKeys.imageBaseUrl] = '';
    _cache[RemoteConfigKeys.sentryDnsKey] = '';
    _cache[RemoteConfigKeys.googleWebClientId] = '';
    if (skipFetch) return;

    try {
      final all = await _ob!.config.getAll();
      for (final entry in all.entries) {
        _cache[entry.key] = entry.value?.toString() ?? '';
      }
      AppLogger.i(
          'OrignaBaseConfig loaded: geoapify_api_key present=${geoapifyKey.trim().isNotEmpty}', tag: 'config');
    } catch (_) {
      AppLogger.w(
          'OrignaBaseConfig fetch failed (geoapify_api_key may be empty)', tag: 'config');
    }
  }

  /// Re-fetch a single config value on demand.
  Future<String> getString(String key) async {
    if (_ob == null) return _cache[key] ?? '';
    try {
      final value = await _ob!.config.getString(key);
      _cache[key] = value;
      return value;
    } catch (_) {
      return _cache[key] ?? '';
    }
  }
}
