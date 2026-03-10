// coverage:ignore-file
import 'package:orignabase/orignabase.dart';

import 'location_repository.dart';

/// OrignaBase location repository.
class OrignaBaseLocationRepository implements LocationRepository {
  final OrignaBase _ob;

  OrignaBaseLocationRepository(this._ob);

  @override
  Future<List<Map<String, dynamic>>> getAddressSuggestions(
      String query) async {
    try {
      final result = await _ob
          .request('POST', '/api/addresses/suggestions', body: {
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
