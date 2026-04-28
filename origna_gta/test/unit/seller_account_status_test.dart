import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/user_repository.dart';
import 'package:origna_gta/features/seller/seller_account_status_viewmodel.dart';

class _FakeUserRepo implements UserRepository {
  SellerAccountStatus? nextStatus;
  Object? nextError;

  @override
  Stream<SellerAccountStatus> watchSellerAccountStatus(String uid) {
    if (nextError != null) return Stream.error(nextError!);
    return Stream.value(
      nextStatus ??
          SellerAccountStatus(
            isSeller: true,
            chargesEnabled: true,
            detailsSubmitted: true,
            hasPendingRequirements: false,
            pendingRequirements: [],
          ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _FakeOb implements OrignaBase {
  Map<String, dynamic> nextResponse = {};
  Object? nextError;

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    if (nextError != null) throw nextError!;
    return nextResponse;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  late _FakeUserRepo fakeRepo;
  late _FakeOb fakeOb;

  setUp(() {
    fakeRepo = _FakeUserRepo();
    fakeOb = _FakeOb();
  });

  group('sellerAccountStatusProvider', () {
    test('emits error when userId is null', () async {
      final c = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(fakeRepo),
          obUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(c.dispose);
      await expectLater(
        c.read(sellerAccountStatusProvider.future),
        throwsA(isA<Exception>()),
      );
    });

    test('emits status when userId is set', () async {
      final c = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(fakeRepo),
          obUserIdProvider.overrideWithValue('user_1'),
        ],
      );
      addTearDown(c.dispose);
      final result = await c.read(sellerAccountStatusProvider.future);
      expect(result.isSeller, isTrue);
      expect(result.chargesEnabled, isTrue);
    });
  });

  group('refreshSellerStatusProvider', () {
    test('throws when userId is null', () {
      final c = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(fakeOb),
          obUserIdProvider.overrideWithValue(null),
        ],
      );
      addTearDown(c.dispose);
      expect(
        () => c.read(refreshSellerStatusProvider(null).future),
        throwsA(isA<Exception>()),
      );
    });

    test('parses Stripe response correctly', () async {
      fakeOb.nextResponse = {
        'chargesEnabled': true,
        'payoutsEnabled': true,
        'detailsSubmitted': true,
        'requirementsCurrentlyDue': <dynamic>[],
      };
      final c = ProviderContainer(
        overrides: [
          orignabaseProvider.overrideWithValue(fakeOb),
          obUserIdProvider.overrideWithValue('user_1'),
        ],
      );
      addTearDown(c.dispose);
      final result = await c.read(refreshSellerStatusProvider(null).future);
      expect(result.chargesEnabled, isTrue);
      expect(result.hasPendingRequirements, isFalse);
    });
  });
}
