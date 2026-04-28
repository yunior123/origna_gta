import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/models/models.dart';

@GenerateNiceMocks([MockSpec<UserRepository>()])
import 'user_repository_test.mocks.dart';

void main() {
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
  });

  group('UserRepository Comprehensive Tests', () {
    test('getUserProfile returns user model', () async {
      when(mockRepository.getUserProfile('u1')).thenAnswer(
        (_) async => UserModel(
          uid: 'u1',
          email: 'u1@e.com',
          name: 'U1',
          roles: [UserRole.buyer],
          createdAt: DateTime.now(),
        ),
      );

      final profile = await mockRepository.getUserProfile('u1');
      expect(profile, isNotNull);
      expect(profile!.uid, 'u1');
    });

    test('addBuyerAddress calls repository', () async {
      when(mockRepository.addBuyerAddress(any)).thenAnswer((_) async => 'a1');

      final address = Address(
        street: 'S',
        city: 'C',
        state: 'P',
        postalCode: 'Z',
        country: 'CA',
      );
      final addressId = await mockRepository.addBuyerAddress(address);

      expect(addressId, 'a1');
      verify(mockRepository.addBuyerAddress(any)).called(1);
    });

    test('updatePreferredLanguage calls repository', () async {
      await mockRepository.updatePreferredLanguage('u1', 'fr');
      verify(mockRepository.updatePreferredLanguage('u1', 'fr')).called(1);
    });

    test('watchAddresses returns list', () async {
      when(mockRepository.watchAddresses('u1')).thenAnswer(
        (_) => Stream.value([
          Address(
            street: 'S1',
            city: 'C',
            state: 'ON',
            postalCode: 'M1M',
            country: 'CA',
          ),
        ]),
      );

      final stream = mockRepository.watchAddresses('u1');
      final list = await stream.first;
      expect(list.length, 1);
      expect(list.first.street, 'S1');
    });
  });
}
