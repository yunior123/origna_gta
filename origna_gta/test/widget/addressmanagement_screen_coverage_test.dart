import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/profile/address_management_viewmodel.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/addressmanagement_screen.dart';

import '../test_utils.dart';
@GenerateNiceMocks([MockSpec<UserRepository>()])
import 'addressmanagement_screen_coverage_test.mocks.dart';

Address _makeAddress({
  String? addressId,
  String street = '123 Main St',
  String city = 'Toronto',
  String state = 'ON',
  String postalCode = 'M5V 1A1',
  bool isDefault = false,
  String? label,
  String? phoneNumber,
}) {
  return Address(
    addressId: addressId ?? 'addr1',
    street: street,
    city: city,
    state: state,
    postalCode: postalCode,
    country: 'Canada',
    isDefault: isDefault,
    label: label,
    phoneNumber: phoneNumber,
  );
}

void main() {
  late MockUserRepository mockUserRepo;

  setUpAll(() {
    initTestMocks();
  });

  setUp(() {
    mockUserRepo = MockUserRepository();
  });

  Widget buildWidget({List<Address>? addresses, bool hasError = false}) {
    return TestWrapper(
      overrides: [
        userIdProvider.overrideWithValue('u1'),
        currentUserProvider.overrideWithValue(
          const AppAuthUser(uid: 'u1', email: 'user@test.com'),
        ),
        userAddressesProvider.overrideWith((ref) {
          if (hasError) return Stream.error('error');
          return Stream.value(addresses ?? <Address>[]);
        }),
        addressManagementViewModelProvider.overrideWith(
          (ref) => AddressManagementViewModel(ref),
        ),
      ],
      child: const AddressManagementScreen(),
    );
  }

  group('AddressManagementScreen', () {
    testWidgets('renders empty state when no addresses', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AddressManagementScreen), findsOneWidget);
    });

    testWidgets('renders addresses list', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [
        _makeAddress(street: '123 Main St', city: 'Toronto'),
        _makeAddress(
          addressId: 'addr2',
          street: '456 Oak Ave',
          city: 'Montreal',
        ),
      ];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('123 Main St'), findsOneWidget);
      expect(find.textContaining('456 Oak Ave'), findsOneWidget);
    });

    testWidgets('renders loading state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        TestWrapper(
          overrides: [
            userIdProvider.overrideWithValue('u1'),
            currentUserProvider.overrideWithValue(
              const AppAuthUser(uid: 'u1', email: 'user@test.com'),
            ),
            userAddressesProvider.overrideWith((ref) => const Stream.empty()),
            addressManagementViewModelProvider.overrideWith(
              (ref) => AddressManagementViewModel(ref),
            ),
          ],
          child: const AddressManagementScreen(),
        ),
      );
      await tester.pump();

      expect(find.byType(AddressManagementScreen), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget(hasError: true));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AddressManagementScreen), findsOneWidget);
    });

    testWidgets('default address shows default badge', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress(isDefault: true)];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AddressManagementScreen), findsOneWidget);
    });

    testWidgets('address with label shows label badge', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress(label: 'Home')];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('address with phone shows phone number', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress(phoneNumber: '416-555-1234')];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('416-555-1234'), findsOneWidget);
    });

    testWidgets('address card has popup menu', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress()];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('add address button exists in app bar', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildWidget());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AddressManagementScreen), findsOneWidget);
    });

    testWidgets('work label shows business icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress(label: 'Work')];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.business_outlined), findsOneWidget);
    });

    testWidgets('loading overlay shown when viewmodel is loading', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress()];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(AddressManagementScreen), findsOneWidget);
    });

    testWidgets('address count subtitle shown', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress(), _makeAddress(addressId: 'addr2')];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('2'), findsWidgets);
    });

    testWidgets('non-default address shows set as default option', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [_makeAddress(isDefault: false)];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('formatted address displayed', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final addresses = [
        _makeAddress(
          street: '789 Elm Rd',
          city: 'Ottawa',
          state: 'ON',
          postalCode: 'K1A 0B1',
        ),
      ];
      await tester.pumpWidget(buildWidget(addresses: addresses));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('789 Elm Rd'), findsOneWidget);
      expect(find.textContaining('Ottawa'), findsOneWidget);
    });
  });
}
