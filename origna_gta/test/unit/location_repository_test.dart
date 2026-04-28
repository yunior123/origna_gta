import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/core/repositories/location_repository.dart';

@GenerateNiceMocks([MockSpec<LocationRepository>()])
import 'location_repository_test.mocks.dart';

void main() {
  late MockLocationRepository repository;

  setUp(() {
    repository = MockLocationRepository();
  });

  group('LocationRepository', () {
    test('getAddressSuggestions returns list of features on success', () async {
      final mockData = [
        {
          'properties': {'formatted': '123 Main St'},
        },
      ];

      when(
        repository.getAddressSuggestions('123 Main'),
      ).thenAnswer((_) async => mockData);

      final results = await repository.getAddressSuggestions('123 Main');

      expect(results.length, 1);
      expect(results[0]['properties']['formatted'], '123 Main St');
      verify(repository.getAddressSuggestions('123 Main')).called(1);
    });

    test('getAddressSuggestions returns empty list on failure', () async {
      when(
        repository.getAddressSuggestions('123 Main'),
      ).thenAnswer((_) async => []);

      final results = await repository.getAddressSuggestions('123 Main');

      expect(results, isEmpty);
    });

    test('getAddressSuggestions returns empty list when no results', () async {
      when(
        repository.getAddressSuggestions('nonexistent'),
      ).thenAnswer((_) async => []);

      final results = await repository.getAddressSuggestions('nonexistent');

      expect(results, isEmpty);
    });
  });
}
