// coverage:ignore-file
import 'package:origna_gta/services/orignabase_conf_service.dart';

/// Thin wrapper — delegates all config reads to [OrignaBaseConfigService].
/// Retained so existing callers (`utils.dart`, `orignabase_product_repository.dart`)
/// compile without import changes.
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  String get geoapifyKey => OrignaBaseConfigService().geoapifyKey;
  String get imageBaseUrl => OrignaBaseConfigService().imageBaseUrl;
  String get sentryDnsKey => OrignaBaseConfigService().sentryDnsKey;

  /// No-op — initialization is done by [OrignaBaseConfigService] in main.dart.
  Future<void> initialize({bool skipFetch = false}) async {}
}
