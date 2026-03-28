import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// Service for generating secure, time-limited download sessions for digital products.
///
/// Supports two product types:
/// - **Books**: single download URL per license key.
/// - **Software**: download URL per license key + platform combination.
///
/// All download URLs are presigned and expire after a server-defined TTL.
/// The service requires a valid [OrignaBase] client instance for authentication.
class OrignaBaseDigitalService {
  /// The OrignaBase client used for API requests.
  final OrignaBase _ob;

  /// Creates a digital download service with the given OrignaBase [client].
  const OrignaBaseDigitalService(this._ob);

  /// Generates a secure download session for a digital book.
  ///
  /// Parameters:
  /// - [licenseKey]: the purchase/license key issued at checkout.
  ///
  /// Returns a map containing `downloadUrl` (presigned, time-limited).
  ///
  /// Throws if the license key is invalid, expired, or the download limit
  /// has been reached.
  Future<Map<String, dynamic>> generateBookDownloadSession(
      String licenseKey) async {
    final result =
        await _ob.request('POST', ApiEndpoints.digitalDownloadBook, body: {
      Fields.licenseKey: licenseKey,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// Generates a secure download session for a software product on a specific platform.
  ///
  /// Parameters:
  /// - [licenseKey]: the purchase/license key issued at checkout.
  /// - [platform]: the target platform (e.g., 'macos', 'windows', 'linux').
  ///
  /// Returns a map containing `downloadUrl` (presigned, time-limited).
  ///
  /// Throws if the license key is invalid, the platform is not available for
  /// the product, or the download limit has been reached.
  Future<Map<String, dynamic>> generateSoftwareDownloadSession(
      String licenseKey, String platform) async {
    final result =
        await _ob.request('POST', ApiEndpoints.digitalDownloadSoftware, body: {
      Fields.licenseKey: licenseKey,
      Fields.platform: platform,
    });
    return Map<String, dynamic>.from(result as Map);
  }
}
