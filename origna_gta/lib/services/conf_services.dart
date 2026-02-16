import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

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

  String get algoliaAppId => _remoteConfig.getString(RemoteConfigKeys.algoliaAppId);

  String get algoliaSearchApiKey => _remoteConfig.getString(RemoteConfigKeys.algoliaSearchApiKey);
  // Getters for your keys
  String get geoapifyKey => _remoteConfig.getString(RemoteConfigKeys.geoapifyApiKey);

  // Inside ConfigService
  String get imageBaseUrl => _remoteConfig.getString(RemoteConfigKeys.imageBaseUrl);

  String get sentryDnsKey => _remoteConfig.getString(RemoteConfigKeys.sentryDnsKey);
  Future<void> initialize({bool skipFetch = false}) async {
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: skipFetch ? const Duration(seconds: 1) : const Duration(seconds: 10),
        minimumFetchInterval: Duration.zero, // FORCE REFRESH FOR DEBUGGING
      ),
    );

    // Defaults should be safe: no placeholder keys that can hide misconfiguration.
    await _remoteConfig.setDefaults({
      RemoteConfigKeys.geoapifyApiKey: '',
      RemoteConfigKeys.imageBaseUrl: '',
      RemoteConfigKeys.sentryDnsKey: '',
      RemoteConfigKeys.algoliaAppId: '',
      RemoteConfigKeys.algoliaSearchApiKey: '',
    });

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
