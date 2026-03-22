import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_location_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>()])
import 'orignabase_location_repository_test.mocks.dart';

void main() {
  late MockOrignaBase mockOb;
  late OrignaBaseLocationRepository repository;

  setUp(() {
    mockOb = MockOrignaBase();
    repository = OrignaBaseLocationRepository(mockOb);
  });

  group('OrignaBaseLocationRepository', () {
    test('getAddressSuggestions returns features on success', () async {
      final mockResponse = {
        'features': [
          {
            'properties': {'formatted': '123 Main St, Montreal'},
          },
          {
            'properties': {'formatted': '456 Oak Ave, Toronto'},
          },
        ],
      };

      when(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => mockResponse);

      final results = await repository.getAddressSuggestions('123 Main');

      expect(results.length, 2);
      expect(results[0]['properties']['formatted'], '123 Main St, Montreal');
      expect(results[1]['properties']['formatted'], '456 Oak Ave, Toronto');
    });

    test(
      'getAddressSuggestions returns empty list when features is null',
      () async {
        when(
          mockOb.request(
            'POST',
            ApiEndpoints.addressesSuggestions,
            body: anyNamed('body'),
          ),
        ).thenAnswer((_) async => {});

        final results = await repository.getAddressSuggestions('query');

        expect(results, isEmpty);
      },
    );

    test('getAddressSuggestions returns empty list on exception', () async {
      when(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: anyNamed('body'),
        ),
      ).thenThrow(Exception('Network error'));

      final results = await repository.getAddressSuggestions('query');

      expect(results, isEmpty);
    });

    test('getAddressSuggestions passes query in body', () async {
      when(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'features': []});

      await repository.getAddressSuggestions('Montreal');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: argThat(
            allOf([
              containsPair('query', 'Montreal'),
              containsPair('limit', 5),
            ]),
            named: 'body',
          ),
        ),
      ).called(1);
    });

    test('getAddressSuggestions handles empty query', () async {
      when(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'features': []});

      final results = await repository.getAddressSuggestions('');

      expect(results, isEmpty);
    });

    test('getAddressSuggestions handles features as non-list', () async {
      when(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'features': 'not a list'});

      final results = await repository.getAddressSuggestions('query');

      expect(results, isEmpty);
    });

    test('getAddressSuggestions handles missing features key', () async {
      when(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: anyNamed('body'),
        ),
      ).thenAnswer((_) async => {'other': 'data'});

      final results = await repository.getAddressSuggestions('query');

      expect(results, isEmpty);
    });

    test('getAddressSuggestions casts features to Map', () async {
      when(
        mockOb.request(
          'POST',
          ApiEndpoints.addressesSuggestions,
          body: anyNamed('body'),
        ),
      ).thenAnswer(
        (_) async => {
          'features': [
            <String, dynamic>{
              'properties': {'formatted': '123 St'},
            },
          ],
        },
      );

      final results = await repository.getAddressSuggestions('query');

      expect(results, isA<List<Map<String, dynamic>>>());
    });
  });
}
