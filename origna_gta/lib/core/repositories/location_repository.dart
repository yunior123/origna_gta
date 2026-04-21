/// Contract for location/address operations.
///
/// Implementations: [OrignaBaseLocationRepository] (production).
///
/// Provides address autocomplete suggestions for shipping address input.
abstract class LocationRepository {
  /// Returns address autocomplete suggestions for the given [query].
  ///
  /// Parameters:
  /// - [query]: the partial address string to autocomplete.
  ///
  /// Returns a list of feature maps from the geocoding provider, each
  /// containing properties like `name`, `address`, `lat`, `lon`.
  /// Returns an empty list on failure (non-critical, fails soft).
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query);
}
