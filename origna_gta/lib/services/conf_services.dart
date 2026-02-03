import 'package:firebase_remote_config/firebase_remote_config.dart';

class ConfigService {
  // 1. Create a private static instance
  static final ConfigService _instance = ConfigService._internal();

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  // 2. Factory constructor returns the same instance every time
  factory ConfigService() {
    return _instance;
  }

  // 3. Private named constructor
  ConfigService._internal();

  String get algoliaAppId => _remoteConfig.getString('algolia_app_id');

  String get algoliaSearchApiKey => _remoteConfig.getString('algolia_search_api_key');
  // Getters for your keys
  String get geoapifyKey => _remoteConfig.getString('geoapify_api_key');

  // Inside ConfigService
  String get imageBaseUrl => _remoteConfig.getString('image_base_url');

  String get sentryDnsKey => _remoteConfig.getString('sentry_dns');
  Future<void> initialize({bool skipFetch = false}) async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: skipFetch ? const Duration(seconds: 1) : const Duration(seconds: 10),
        minimumFetchInterval: skipFetch ? Duration.zero : const Duration(hours: 1),
      ),
    );

    // Defaults should be safe: no placeholder keys that can hide misconfiguration.
    await _remoteConfig.setDefaults({'geoapify_api_key': '', 'image_base_url': '', 'sentry_dns': '', 'algolia_app_id': '', 'algolia_search_api_key': ''});

    if (skipFetch) {
      return;
    }

    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Remote Config fetch is best-effort. Defaults remain in place.
    }
  }
}
