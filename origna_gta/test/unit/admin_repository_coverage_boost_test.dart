import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/admin/orignabase_admin_repository.dart';

@GenerateNiceMocks([MockSpec<OrignaBase>(), MockSpec<OrignaBaseAuth>()])
import 'admin_repository_coverage_boost_test.mocks.dart';

void main() {
  late MockOrignaBase mockOb;
  late MockOrignaBaseAuth mockAuth;
  late OrignaBaseAdminRepository repo;

  setUp(() {
    mockOb = MockOrignaBase();
    mockAuth = MockOrignaBaseAuth();

    when(mockOb.auth).thenReturn(mockAuth);
    when(mockAuth.currentUserId).thenReturn('admin_123');

    repo = OrignaBaseAdminRepository(mockOb);
  });

  group('approveProduct', () {
    test('sends POST request', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.approveProduct('prod_1');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminApproveProduct,
          body: {Fields.productId: 'prod_1'},
        ),
      ).called(1);
    });
  });

  group('deleteProduct', () {
    test('sends POST request', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.deleteProduct('prod_1');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.productsDelete,
          body: {Fields.productId: 'prod_1'},
        ),
      ).called(1);
    });
  });

  group('MFA operations', () {
    test('enableAdminMfa sends POST and returns map', () async {
      when(mockOb.request(any, any, body: anyNamed('body'))).thenAnswer(
        (_) async => {'secret': 'totp_secret', 'qrUrl': 'https://...'},
      );

      final result = await repo.enableAdminMfa();
      expect(result, containsPair('secret', 'totp_secret'));
    });

    test('enableAdminMfa throws when not authenticated', () async {
      when(mockAuth.currentUserId).thenReturn(null);
      expect(() => repo.enableAdminMfa(), throwsA(isA<StateError>()));
    });

    test('disableAdminMfa sends POST', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.disableAdminMfa('123456');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminMfaDisable,
          body: {ApiKeys.code: '123456'},
        ),
      ).called(1);
    });

    test('verifyAdminMfa sends POST and returns map', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {'verified': true});

      final result = await repo.verifyAdminMfa('654321');
      expect(result, containsPair('verified', true));
    });
  });

  group('getPaymentProviders', () {
    test('normalizes list response', () async {
      when(mockOb.request(any, any, body: anyNamed('body'))).thenAnswer(
        (_) async => {
          ApiKeys.success: true,
          ApiKeys.providers: [
            {
              Fields.name: 'stripe',
              ApiKeys.enabled: true,
              'webhookConfigured': true,
              'mode': 'live',
            },
          ],
        },
      );

      final result = await repo.getPaymentProviders();
      expect(result[ApiKeys.success], isTrue);
      final providers = result[ApiKeys.providers] as Map<String, dynamic>;
      expect(providers.containsKey('stripe'), isTrue);
    });

    test('handles non-list providers', () async {
      when(mockOb.request(any, any, body: anyNamed('body'))).thenAnswer(
        (_) async => {ApiKeys.success: true, ApiKeys.providers: 'not-a-list'},
      );

      final result = await repo.getPaymentProviders();
      expect(result, isNotNull);
    });
  });

  group('flagReview', () {
    test('sends flag request', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.flagReview('review_1', flagged: true);

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminFlagReview,
          body: {Fields.reviewId: 'review_1', Fields.flagged: true},
        ),
      ).called(1);
    });
  });

  group('refundOrder', () {
    test('sends refund request with default reason', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.refundOrder('ord_1');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.ordersRefundsItem,
          body: {Fields.orderId: 'ord_1', Fields.reason: 'Admin refund'},
        ),
      ).called(1);
    });

    test('sends refund request with custom reason', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.refundOrder('ord_1', reason: 'Defective item');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.ordersRefundsItem,
          body: {Fields.orderId: 'ord_1', Fields.reason: 'Defective item'},
        ),
      ).called(1);
    });
  });

  group('rejectProduct', () {
    test('sends reject request', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.rejectProduct('prod_1', 'Inappropriate content');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminRejectProduct,
          body: {
            Fields.productId: 'prod_1',
            Fields.reason: 'Inappropriate content',
          },
        ),
      ).called(1);
    });
  });

  group('setUserSuspended', () {
    test('suspends user', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.setUserSuspended('user_1', true);

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminSuspendSeller,
          body: {
            Fields.sellerId: 'user_1',
            ApiKeys.reason: 'Suspended by admin',
          },
        ),
      ).called(1);
    });

    test('unsuspends user', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.setUserSuspended('user_1', false);

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminUnsuspendSeller,
          body: {
            Fields.sellerId: 'user_1',
            ApiKeys.reason: 'Unsuspended by admin',
          },
        ),
      ).called(1);
    });
  });

  group('updatePaymentProvider', () {
    test('sends update request', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.updatePaymentProvider('stripe', true);

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.paymentsProvidersUpdate,
          body: {'providerName': 'stripe', ApiKeys.enabled: true},
        ),
      ).called(1);
    });
  });

  group('updateProductStock', () {
    test('sends stock update', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.updateProductStock('prod_1', 50);

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminUpdateStock,
          body: {Fields.productId: 'prod_1', Fields.stockQuantity: 50},
        ),
      ).called(1);
    });
  });

  group('updateUserRoles', () {
    test('sends role update with defaults', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.updateUserRoles('user_1', add: ['seller']);

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminUpdateRoles,
          body: {
            Fields.targetUserId: 'user_1',
            ApiKeys.add: ['seller'],
            ApiKeys.remove: const <String>[],
            ApiKeys.reason: 'No reason provided',
          },
        ),
      ).called(1);
    });

    test('sends role update with custom reason', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.updateUserRoles('user_1', add: ['admin'], reason: 'Promoted');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminUpdateRoles,
          body: {
            Fields.targetUserId: 'user_1',
            ApiKeys.add: ['admin'],
            ApiKeys.remove: const <String>[],
            ApiKeys.reason: 'Promoted',
          },
        ),
      ).called(1);
    });
  });

  group('deleteReview', () {
    test('sends delete request', () async {
      when(
        mockOb.request(any, any, body: anyNamed('body')),
      ).thenAnswer((_) async => {});

      await repo.deleteReview('review_1');

      verify(
        mockOb.request(
          'POST',
          ApiEndpoints.adminDeleteReview,
          body: {Fields.reviewId: 'review_1'},
        ),
      ).called(1);
    });
  });
}
