// coverage:ignore-file
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

/// OrignaBase digital download service.
/// for book and software download session generation.
class OrignaBaseDigitalService {
  final OrignaBase _ob;

  const OrignaBaseDigitalService(this._ob);

  /// Generate a secure book download session.
  /// Returns a map containing [ApiKeys.downloadUrl].
  Future<Map<String, dynamic>> generateBookDownloadSession(
      String licenseKey) async {
    final result =
        await _ob.request('POST', ApiEndpoints.digitalDownloadBook, body: {
      Fields.licenseKey: licenseKey,
    });
    return Map<String, dynamic>.from(result as Map);
  }

  /// Generate a secure software download session for a given platform.
  /// Returns a map containing [ApiKeys.downloadUrl].
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
