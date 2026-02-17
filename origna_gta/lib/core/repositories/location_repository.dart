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
    if (apiKey.trim().isEmpty) {
      // Fail soft, but make it visible in logs.
      // (If this prints, set Remote Config geoapify_api_key, or pass --dart-define=geoapify_api_key=...)
      // ignore: avoid_print
      print('⚠️ Geoapify disabled: geoapify_api_key is empty');
      return [];
    }

    final uri = Uri.https(
      'api.geoapify.com',
      '/v1/geocode/autocomplete',
      <String, String>{
        'text': query,
        'filter': 'countrycode:ca',
        'apiKey': apiKey,
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['features'] ?? []);
    }

    // ignore: avoid_print
    print('⚠️ Geoapify autocomplete HTTP ${response.statusCode}');
    return [];
  }
}
