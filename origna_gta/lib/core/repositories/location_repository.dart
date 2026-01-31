import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:origna_gta/services/conf_services.dart';

abstract class LocationRepository {
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query);
}

class GeoapifyLocationRepository implements LocationRepository {
  @override
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    final String apiKey = ConfigService().geoapifyKey;
    final response = await http.get(
      Uri.parse('https://api.geoapify.com/v1/geocode/autocomplete?text=$query&filter=countrycode:ca&apiKey=$apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['features'] ?? []);
    }
    return [];
  }
}
