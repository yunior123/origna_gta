// coverage:ignore-file

abstract class LocationRepository {
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query);
}
