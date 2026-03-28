import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart' show ApiEndpoints;

import 'location_repository.dart';

/// OrignaBase implementation of [LocationRepository].
///
/// Proxies address autocomplete requests through OrignaBase's geocoding
/// endpoint, which wraps the Geoapify provider. Fails soft on errors
/// (returns empty list) since address suggestions are non-critical UX.
class OrignaBaseLocationRepository implements LocationRepository {
  /// The OrignaBase client used for API requests.
  final OrignaBase _ob;

  /// Creates a location repository with the given OrignaBase [client].
  OrignaBaseLocationRepository(this._ob);

  /// Fetches address autocomplete suggestions from the geocoding endpoint.
  ///
  /// Parameters:
  /// - [query]: the partial address string to autocomplete.
  ///
  /// Returns up to 5 suggestion feature maps. Returns an empty list on
  /// any error (network, parsing, etc.) to avoid blocking the UI.
  @override
  Future<List<Map<String, dynamic>>> getAddressSuggestions(
      String query) async {
    try {
      final result = await _ob
          .request('POST', ApiEndpoints.addressesSuggestions, body: {
        'query': query,
        'limit': 5,
      });
      final data = Map<String, dynamic>.from(result as Map);
      final features = (data['features'] as List?) ?? [];
      return features.cast<Map<String, dynamic>>();
    } catch (e) {
      // Fail soft — address suggestions are non-critical.
      return [];
    }
  }
}
