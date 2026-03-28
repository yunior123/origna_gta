import 'package:package_info_plus/package_info_plus.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for checking whether the app needs to be updated.
///
/// Compares the current app version (from `PackageInfo`) against the minimum
/// required version stored in OrignaBase's server config. Used to enforce
/// mandatory updates when breaking API changes are deployed.
///
/// All methods are static — this is a stateless utility service.
class AppUpdateService {
  /// Checks if the app needs to be updated to meet the server's minimum version.
  ///
  /// Compares the current app version against the `min_app_version` config
  /// value fetched from OrignaBase.
  ///
  /// Returns:
  /// - `null` if no update is needed or the check fails (fails open).
  /// - The minimum required version string (e.g., `"1.2.0"`) if an update
  ///   is required.
  ///
  /// Error handling:
  /// - Network errors and timeouts (5s) are caught and return `null` to avoid
  ///   blocking app startup on transient connectivity issues.
  /// - Non-200 HTTP responses also return `null`.
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
  
  /// Compares two semantic version strings (major.minor.patch).
  ///
  /// Returns `true` if [current] is strictly lower than [minimum].
  /// Missing segments default to 0. Non-numeric segments are treated as 0.
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
