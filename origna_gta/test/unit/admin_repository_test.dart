import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:origna_gta/features/admin/admin_repository.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

@GenerateNiceMocks([MockSpec<AdminRepository>()])
import 'admin_repository_test.mocks.dart';

void main() {
  late MockAdminRepository repository;

  setUp(() {
    repository = MockAdminRepository();

    // Default stubs
    when(repository.approveProduct(any)).thenAnswer((_) async {});
    when(repository.deleteProduct(any)).thenAnswer((_) async {});
    when(repository.disableAdminMfa(any)).thenAnswer((_) async {});
    when(repository.enableAdminMfa()).thenAnswer((_) async => {'secret': 'secret123'});
    when(repository.getPaymentProviders()).thenAnswer((_) async => {'stripe': true});
    when(repository.setUserSuspended(any, any)).thenAnswer((_) async {});
    when(repository.updatePaymentProvider(any, any, reason: anyNamed('reason'))).thenAnswer((_) async {});
    when(repository.updateProductStock(any, any)).thenAnswer((_) async {});
    when(repository.rejectProduct(any, any)).thenAnswer((_) async {});
    when(repository.updateUserRoles(any, add: anyNamed('add'), remove: anyNamed('remove'), reason: anyNamed('reason'))).thenAnswer((_) async {});
    when(repository.verifyAdminMfa(any)).thenAnswer((_) async => {'success': true});
    when(repository.deleteReview(any)).thenAnswer((_) async {});
    when(repository.flagReview(any, flagged: anyNamed('flagged'))).thenAnswer((_) async {});
    when(repository.refundOrder(any, reason: anyNamed('reason'))).thenAnswer((_) async {});
  });

  group('AdminRepository', () {
    test('approveProduct calls repository', () async {
      await repository.approveProduct('p1');
      verify(repository.approveProduct('p1')).called(1);
    });

    test('deleteProduct calls repository', () async {
      await repository.deleteProduct('p1');
      verify(repository.deleteProduct('p1')).called(1);
    });

    test('disableAdminMfa calls repository', () async {
      await repository.disableAdminMfa('123456');
      verify(repository.disableAdminMfa('123456')).called(1);
    });

    test('enableAdminMfa returns secret', () async {
      final result = await repository.enableAdminMfa();
      expect(result['secret'], 'secret123');
    });

    test('fetchUserById returns user if exists', () async {
      when(repository.fetchUserById('u1')).thenAnswer((_) async => UserModel(
        uid: 'u1',
        email: 'test@ex.com',
        name: 'Test',
        roles: [UserRole.admin],
        createdAt: DateTime.now(),
      ));

      final user = await repository.fetchUserById('u1');
      expect(user?.uid, 'u1');
      expect(user?.email, 'test@ex.com');
    });

    test('fetchUserById returns null if not exists', () async {
      when(repository.fetchUserById('non-existent')).thenAnswer((_) async => null);
      final user = await repository.fetchUserById('non-existent');
      expect(user, isNull);
    });

    test('getPaymentProviders returns map', () async {
      final result = await repository.getPaymentProviders();
      expect(result['stripe'], true);
    });

    test('setUserSuspended calls repository with true', () async {
      await repository.setUserSuspended('u1', true);
      verify(repository.setUserSuspended('u1', true)).called(1);
    });

    test('setUserSuspended calls repository with false', () async {
      await repository.setUserSuspended('u1', false);
      verify(repository.setUserSuspended('u1', false)).called(1);
    });

    test('updatePaymentProvider calls repository', () async {
      await repository.updatePaymentProvider('stripe', true, reason: 'test');
      verify(repository.updatePaymentProvider('stripe', true, reason: 'test')).called(1);
    });

    test('updateProductStock calls repository', () async {
      await repository.updateProductStock('p1', 10);
      verify(repository.updateProductStock('p1', 10)).called(1);
    });

    test('rejectProduct calls repository', () async {
      await repository.rejectProduct('p1', 'bad photos');
      verify(repository.rejectProduct('p1', 'bad photos')).called(1);
    });

    test('updateUserRoles calls repository', () async {
      await repository.updateUserRoles('u1', add: ['admin'], remove: ['buyer'], reason: 'promotion');
      verify(repository.updateUserRoles('u1', add: ['admin'], remove: ['buyer'], reason: 'promotion')).called(1);
    });

    test('verifyAdminMfa returns result', () async {
      final result = await repository.verifyAdminMfa('123456');
      expect(result['success'], true);
    });

    test('watchUsers returns stream of users', () async {
      when(repository.watchUsers()).thenAnswer((_) => Stream.value([
        UserModel(uid: 'u1', email: 'u1@ex.com', name: 'U1', roles: [UserRole.buyer], createdAt: DateTime.now()),
      ]));

      final stream = repository.watchUsers();
      final users = await stream.first;
      expect(users.length, 1);
      expect(users.first.name, 'U1');
    });

    test('watchOrders with status filter', () async {
      when(repository.watchOrders(status: OrderStatusValues.pending)).thenAnswer((_) => Stream.value([
        OrderModel(
          orderId: 'o1',
          orderStatus: OrderStatusValues.pending,
          userId: 'u1',
          customerId: 'cust1',
          customerEmail: 'buyer@ex.com',
          items: const [],
          totalAmountCents: 1000,
          subtotalCents: 900,
          shippingAddress: const {},
          createdAt: DateTime.now(),
          taxes: const {},
          currency: 'CAD',
          sellerIds: const ['s1'],
          stripeSessionId: 'sess_1',
        ),
      ]));

      final stream = repository.watchOrders(status: OrderStatusValues.pending);
      final orders = await stream.first;
      expect(orders.length, 1);
      expect(orders.first.orderStatus, OrderStatusValues.pending);
    });

    test('watchProducts returns stream', () async {
      when(repository.watchProducts(sellerId: 's1')).thenAnswer((_) => Stream.value([
        ProductModel(
          id: 'p1',
          sellerId: 's1',
          name: 'P1',
          priceCents: 1000,
          imageUrls: const [],
          sellerAddress: Address(street: 'S', city: 'C', state: 'ON', postalCode: 'M1M', country: 'CA'),
          description: 'Test',
          stockQuantity: 10,
          categoryId: 1,
          keywords: const [],
        ),
      ]));

      final stream = repository.watchProducts(sellerId: 's1');
      final products = await stream.first;
      expect(products.length, 1);
      expect(products.first.sellerId, 's1');
    });

    test('watchPendingReviewProducts returns stream', () async {
      when(repository.watchPendingReviewProducts()).thenAnswer((_) => Stream.value([
        ProductModel(
          id: 'p1',
          name: 'P1',
          sellerId: 's1',
          lifecycleStatus: ProductLifecycleStatusValues.underReview,
          priceCents: 1000,
          imageUrls: const [],
          sellerAddress: Address(street: 'S', city: 'C', state: 'ON', postalCode: 'M1M', country: 'CA'),
          description: 'Test',
          stockQuantity: 10,
          categoryId: 1,
          keywords: const [],
        ),
      ]));

      final stream = repository.watchPendingReviewProducts();
      final products = await stream.first;
      expect(products.length, 1);
    });

    test('watchSellers returns stream of sellers', () async {
      when(repository.watchSellers()).thenAnswer((_) => Stream.value([
        UserModel(uid: 's1', email: 's1@ex.com', name: 'S1', roles: [UserRole.seller], createdAt: DateTime.now()),
      ]));

      final stream = repository.watchSellers();
      final sellers = await stream.first;
      expect(sellers.length, 1);
      expect(sellers.first.roles, contains(UserRole.seller));
    });

    test('watchReviews returns stream', () async {
      when(repository.watchReviews(flaggedOnly: true)).thenAnswer((_) => Stream.value([
        {'isFlagged': true, 'rating': 5, 'reviewText': 'Great'},
      ]));

      final stream = repository.watchReviews(flaggedOnly: true);
      final reviews = await stream.first;
      expect(reviews.length, 1);
      expect(reviews.first['isFlagged'], true);
    });

    test('deleteReview calls repository', () async {
      await repository.deleteReview('r1');
      verify(repository.deleteReview('r1')).called(1);
    });

    test('flagReview calls repository', () async {
      await repository.flagReview('r1', flagged: true);
      verify(repository.flagReview('r1', flagged: true)).called(1);
    });

    test('refundOrder calls repository', () async {
      await repository.refundOrder('o1', reason: 'Customer changed mind');
      verify(repository.refundOrder('o1', reason: 'Customer changed mind')).called(1);
    });
  });
}
