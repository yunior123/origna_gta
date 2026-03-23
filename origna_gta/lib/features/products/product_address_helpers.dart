import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/utils/utils.dart';

/// Shared address autocomplete logic for Add/Edit product ViewModels.
///
/// Both ViewModels need: autocomplete suggestions on street input,
/// province/lat/lng extraction on suggestion selection, and coordinate
/// invalidation on manual edits.

/// Fetches address suggestions from Geoapify for a street input.
///
/// Returns empty list if [value] is shorter than 3 chars or on error.
/// Caller should update their state with the results.
Future<List<Map<String, dynamic>>> fetchAddressSuggestions(
  Ref ref,
  String value,
) async {
  if (value.length < 3) return [];
  try {
    return await ref
        .read(locationRepositoryProvider)
        .getAddressSuggestions(value);
  } catch (e, st) {
    AppError.log(e, stackTrace: st, context: 'fetchAddressSuggestions');
    return [];
  }
}

/// Parses a Geoapify suggestion into province, latitude, longitude.
///
/// Returns a record with (state, latitude, longitude) extracted from
/// the raw suggestion map. Uses [parseAddressSuggestion] from utils.
({String state, double? latitude, double? longitude}) extractAddressDetails(
  Map<String, dynamic> suggestion,
) {
  final details = parseAddressSuggestion(suggestion);
  return (
    state: details.state,
    latitude: details.latitude,
    longitude: details.longitude,
  );
}
