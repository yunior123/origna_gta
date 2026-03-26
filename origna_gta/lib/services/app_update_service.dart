import 'package:package_info_plus/package_info_plus.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AppUpdateService {
  /// Check if app update is required.
  /// Returns null if no update needed, or the minimum version string if update required.
  static Future<String?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g., "1.1.0"
      
      // Fetch minimum version from OrignaBase config
      final url = '${EnvConfig().orignabaseUrl}/config/min_app_version';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) return null;
      
      final data = jsonDecode(response.body);
      final minVersion = data['value'] as String?;
      if (minVersion == null) return null;
      
      if (_isVersionLower(currentVersion, minVersion)) {
        AppLogger.w('App update required: current=$currentVersion, min=$minVersion');
        return minVersion;
      }
      return null;
    } catch (e) {
      AppLogger.w('Version check failed: $e');
      return null; // Don't block app on network errors
    }
  }
  
  /// Compare semantic versions. Returns true if current < minimum.
  static bool _isVersionLower(String current, String minimum) {
    final currentParts = current.split('.').map(int.tryParse).toList();
    final minParts = minimum.split('.').map(int.tryParse).toList();
    
    for (var i = 0; i < 3; i++) {
      final c = i < currentParts.length ? (currentParts[i] ?? 0) : 0;
      final m = i < minParts.length ? (minParts[i] ?? 0) : 0;
      if (c < m) return true;
      if (c > m) return false;
    }
    return false;
  }
}
