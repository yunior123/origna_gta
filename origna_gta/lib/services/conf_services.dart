import 'package:firebase_remote_config/firebase_remote_config.dart';

class ConfigService {
  // 1. Create a private static instance
  static final ConfigService _instance = ConfigService._internal();

  // 2. Factory constructor returns the same instance every time
  factory ConfigService() {
    return _instance;
  }

  // 3. Private named constructor
  ConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(fetchTimeout: const Duration(minutes: 1), minimumFetchInterval: const Duration(hours: 1)));

    await _remoteConfig.setDefaults({"geoapify_api_key": "YOUR_BACKUP_KEY"});

    await _remoteConfig.fetchAndActivate();
  }

  // Inside ConfigService
  String get imageBaseUrl => _remoteConfig.getString('image_base_url');
  // Getters for your keys
  String get geoapifyKey => _remoteConfig.getString('geoapify_api_key');

  String get sentryDnsKey => _remoteConfig.getString('sentry_dns');

  String get algoliaAppId => _remoteConfig.getString('algolia_app_id');
  String get algoliaSearchApiKey => _remoteConfig.getString('algolia_search_api_key');
}
