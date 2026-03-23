import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/admin/orignabase_admin_repository.dart';
import 'package:origna_gta/utils/utils.dart';

// =============================================================================
// FAKE IMPLEMENTATIONS
// =============================================================================

class _FakeAuth extends Fake implements OrignaBaseAuth {
  String? currentUserIdValue;

  @override
  String? get currentUserId => currentUserIdValue;
}

class _FakeDocument extends Fake implements Document {
  @override
  final String id;

  @override
  final Map<String, dynamic> data;

  @override
  final bool exists;

  _FakeDocument(this.id, this.data, {this.exists = true});

  @override
  T? get<T>(String field) => data[field] as T?;

  @override
  dynamic operator [](String key) => data[key];

  @override
  bool containsKey(String key) => data.containsKey(key);
}

class _FakeDocumentRef extends Fake implements DocumentRef {
  @override
  final String id;

  _FakeDocument? documentValue;

  _FakeDocumentRef({this.id = 'doc_id', _FakeDocument? doc})
    : documentValue = doc;

  @override
  Future<Document?> get() async => documentValue;

  @override
  Future<Document?> update(Map<String, dynamic> data) async => documentValue;

  @override
  Future<void> delete() async {}
}

class _FakeCollectionRef extends Fake implements CollectionRef {
  final Map<String, _FakeDocumentRef> docsMap = {};

  void setDoc(String id, _FakeDocumentRef ref) {
    docsMap[id] = ref;
  }

  @override
  DocumentRef doc(String id) {
    if (docsMap.containsKey(id)) return docsMap[id]!;
    return _FakeDocumentRef(id: id);
  }

  @override
  Future<QuerySnapshot> get() async => _FakeQuerySnapshot([]);

  @override
  Query where(
    String field, {
    dynamic isEqualTo,
    dynamic isNotEqualTo,
    dynamic isGreaterThan,
    dynamic isGreaterThanOrEqualTo,
    dynamic isLessThan,
    dynamic isLessThanOrEqualTo,
    List<dynamic>? whereIn,
    dynamic contains,
    dynamic startsWith,
  }) => this;

  @override
  Query orderBy(String field, {bool descending = false}) => this;

  @override
  Query limit(int limit) => this;

  @override
  Query offset(int count) => this;

  @override
  Query startAfterId(String id) => this;

  void clear() => docsMap.clear();
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  @override
  final List<Document> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue = _FakeAuth();
  final _FakeCollectionRef usersCollection = _FakeCollectionRef();

  String? lastRequestMethod;
  String? lastRequestPath;
  Map<String, dynamic>? lastRequestBody;
  Map<String, dynamic> requestResponse = {'success': true};

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  CollectionRef collection(String name) {
    if (name == Collections.users) return usersCollection;
    return _FakeCollectionRef();
  }

  @override
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    lastRequestMethod = method;
    lastRequestPath = path;
    lastRequestBody = body;
    return requestResponse;
  }
}

// =============================================================================
// TESTS
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeOrignaBase fakeOb;
  late OrignaBaseAdminRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    fakeOb.authValue.currentUserIdValue = 'admin_user_123';
    repository = OrignaBaseAdminRepository(fakeOb);
  });

  group('OrignaBaseAdminRepository - approveProduct', () {
    test('sends POST to adminApproveProduct endpoint', () async {
      await repository.approveProduct('prod_abc');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.adminApproveProduct);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_abc');
    });
  });

  group('OrignaBaseAdminRepository - deleteProduct', () {
    test('sends POST to productsDelete endpoint', () async {
      await repository.deleteProduct('prod_xyz');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.productsDelete);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_xyz');
    });
  });

  group('OrignaBaseAdminRepository - disableAdminMfa', () {
    test('sends POST to adminMfaDisable with code', () async {
      await repository.disableAdminMfa('654321');

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.adminMfaDisable);
      expect(fakeOb.lastRequestBody?[ApiKeys.code], '654321');
    });

    test('throws StateError when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.disableAdminMfa('123'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OrignaBaseAdminRepository - enableAdminMfa', () {
    test('sends POST to adminMfaEnroll and returns result', () async {
      fakeOb.requestResponse = {
        'success': true,
        'secret': 'JBSWY3DPEHPK3PXP',
        'qrCodeUrl': 'https://example.com/qr',
      };

      final result = await repository.enableAdminMfa();

      expect(fakeOb.lastRequestMethod, 'POST');
      expect(fakeOb.lastRequestPath, ApiEndpoints.adminMfaEnroll);
      expect(result['secret'], 'JBSWY3DPEHPK3PXP');
    });

    test('throws StateError when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = '';

      expect(() => repository.enableAdminMfa(), throwsA(isA<StateError>()));
    });
  });

  group('OrignaBaseAdminRepository - fetchUserById', () {
    test('returns UserModel when doc exists', () async {
      final doc = _FakeDocument('user_123', {
        Fields.email: 'user@example.com',
        Fields.name: 'Test User',
        Fields.roles: [UserRole.buyer],
      });
      fakeOb.usersCollection.setDoc('user_123', _FakeDocumentRef(doc: doc));

      final user = await repository.fetchUserById('user_123');

      expect(user, isNotNull);
      expect(user!.uid, 'user_123');
      expect(user.email, 'user@example.com');
    });

    test('returns null when doc does not exist', () async {
      fakeOb.usersCollection.setDoc(
        'missing',
        _FakeDocumentRef(doc: _FakeDocument('missing', {}, exists: false)),
      );

      final user = await repository.fetchUserById('missing');
      expect(user, isNull);
    });

    test('returns null when doc is null', () async {
      final user = await repository.fetchUserById('no_such_user');
      expect(user, isNull);
    });
  });

  group('OrignaBaseAdminRepository - getPaymentProviders', () {
    test('normalizes provider list into map', () async {
      fakeOb.requestResponse = {
        ApiKeys.success: true,
        ApiKeys.providers: [
          {
            Fields.name: 'stripe',
            ApiKeys.enabled: true,
            'webhookConfigured': true,
            'mode': 'live',
          },
          {
            Fields.name: 'paypal',
            ApiKeys.enabled: false,
            'webhookConfigured': false,
            'mode': 'test',
          },
        ],
      };

      final result = await repository.getPaymentProviders();

      expect(result[ApiKeys.success], true);
      final providers = result[ApiKeys.providers] as Map<String, dynamic>;
      expect(providers['stripe'][ApiKeys.enabled], true);
      expect(providers['stripe'][ApiKeys.configured], true);
      expect(providers['stripe'][ApiKeys.missingKeys], isEmpty);
      expect(providers['paypal'][ApiKeys.enabled], false);
      expect(providers['paypal'][ApiKeys.configured], false);
      expect(providers['paypal'][ApiKeys.missingKeys], contains('webhook'));
    });

    test('returns raw data when providers is not a list', () async {
      fakeOb.requestResponse = {ApiKeys.success: true, 'other': 'data'};

      final result = await repository.getPaymentProviders();
      expect(result['other'], 'data');
    });

    test('skips providers with empty name', () async {
      fakeOb.requestResponse = {
        ApiKeys.success: true,
        ApiKeys.providers: [
          {Fields.name: '', ApiKeys.enabled: true},
          {
            Fields.name: 'stripe',
            ApiKeys.enabled: true,
            'webhookConfigured': true,
            'mode': 'live',
          },
        ],
      };

      final result = await repository.getPaymentProviders();
      final providers = result[ApiKeys.providers] as Map<String, dynamic>;
      expect(providers.containsKey('stripe'), true);
      expect(providers.length, 1);
    });

    test('skips non-map items in list', () async {
      fakeOb.requestResponse = {
        ApiKeys.success: true,
        ApiKeys.providers: [
          'invalid_item',
          {
            Fields.name: 'stripe',
            ApiKeys.enabled: true,
            'webhookConfigured': false,
            'mode': 'test',
          },
        ],
      };

      final result = await repository.getPaymentProviders();
      final providers = result[ApiKeys.providers] as Map<String, dynamic>;
      expect(providers.length, 1);
    });

    test('throws StateError when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.getPaymentProviders(),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OrignaBaseAdminRepository - flagReview', () {
    test('sends flagged=true', () async {
      await repository.flagReview('rev_1', flagged: true);

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminFlagReview);
      expect(fakeOb.lastRequestBody?[Fields.reviewId], 'rev_1');
      expect(fakeOb.lastRequestBody?[Fields.flagged], true);
    });

    test('sends flagged=false', () async {
      await repository.flagReview('rev_2', flagged: false);
      expect(fakeOb.lastRequestBody?[Fields.flagged], false);
    });
  });

  group('OrignaBaseAdminRepository - refundOrder', () {
    test('sends default reason when not provided', () async {
      await repository.refundOrder('order_1');

      expect(fakeOb.lastRequestPath, ApiEndpoints.ordersRefundsItem);
      expect(fakeOb.lastRequestBody?[Fields.orderId], 'order_1');
      expect(fakeOb.lastRequestBody?[Fields.reason], 'Admin refund');
    });

    test('sends custom reason', () async {
      await repository.refundOrder('order_2', reason: 'Buyer complaint');
      expect(fakeOb.lastRequestBody?[Fields.reason], 'Buyer complaint');
    });
  });

  group('OrignaBaseAdminRepository - rejectProduct', () {
    test('sends POST to adminRejectProduct with reason', () async {
      await repository.rejectProduct('prod_1', 'Poor image quality');

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminRejectProduct);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
      expect(fakeOb.lastRequestBody?[Fields.reason], 'Poor image quality');
    });
  });

  group('OrignaBaseAdminRepository - setUserSuspended', () {
    test('sends suspend request when suspended=true', () async {
      await repository.setUserSuspended('user_1', true);

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminSuspendSeller);
      expect(fakeOb.lastRequestBody?[Fields.sellerId], 'user_1');
      expect(fakeOb.lastRequestBody?[ApiKeys.reason], 'Suspended by admin');
    });

    test('sends unsuspend request when suspended=false', () async {
      await repository.setUserSuspended('user_2', false);

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminUnsuspendSeller);
      expect(fakeOb.lastRequestBody?[Fields.sellerId], 'user_2');
      expect(fakeOb.lastRequestBody?[ApiKeys.reason], 'Unsuspended by admin');
    });
  });

  group('OrignaBaseAdminRepository - updatePaymentProvider', () {
    test('sends provider update request', () async {
      await repository.updatePaymentProvider('stripe', true);

      expect(fakeOb.lastRequestPath, ApiEndpoints.paymentsProvidersUpdate);
      expect(fakeOb.lastRequestBody?['providerName'], 'stripe');
      expect(fakeOb.lastRequestBody?[ApiKeys.enabled], true);
    });

    test('throws StateError when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repository.updatePaymentProvider('stripe', false),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OrignaBaseAdminRepository - updateProductStock', () {
    test('sends stock update', () async {
      await repository.updateProductStock('prod_1', 50);

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminUpdateStock);
      expect(fakeOb.lastRequestBody?[Fields.productId], 'prod_1');
      expect(fakeOb.lastRequestBody?[Fields.stockQuantity], 50);
    });
  });

  group('OrignaBaseAdminRepository - updateUserRoles', () {
    test('sends role update with add and remove', () async {
      await repository.updateUserRoles(
        'user_1',
        add: ['seller'],
        remove: ['buyer'],
        reason: 'Role promotion',
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminUpdateRoles);
      expect(fakeOb.lastRequestBody?[Fields.targetUserId], 'user_1');
      expect(fakeOb.lastRequestBody?[ApiKeys.add], ['seller']);
      expect(fakeOb.lastRequestBody?[ApiKeys.remove], ['buyer']);
      expect(fakeOb.lastRequestBody?[ApiKeys.reason], 'Role promotion');
    });

    test('uses default reason when not provided', () async {
      await repository.updateUserRoles('user_2', add: ['admin']);
      expect(fakeOb.lastRequestBody?[ApiKeys.reason], 'No reason provided');
    });

    test('uses empty lists when add and remove not provided', () async {
      await repository.updateUserRoles('user_3');

      expect(fakeOb.lastRequestBody?[ApiKeys.add], isEmpty);
      expect(fakeOb.lastRequestBody?[ApiKeys.remove], isEmpty);
    });
  });

  group('OrignaBaseAdminRepository - verifyAdminMfa', () {
    test('sends MFA verification and returns result', () async {
      fakeOb.requestResponse = {
        ApiKeys.success: true,
        ApiKeys.mfaVerified: true,
      };

      final result = await repository.verifyAdminMfa('123456');

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminMfaVerify);
      expect(fakeOb.lastRequestBody?[ApiKeys.code], '123456');
      expect(result[ApiKeys.success], true);
    });

    test('throws StateError when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.verifyAdminMfa('123'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('OrignaBaseAdminRepository - deleteReview', () {
    test('sends POST to adminDeleteReview', () async {
      await repository.deleteReview('rev_1');

      expect(fakeOb.lastRequestPath, ApiEndpoints.adminDeleteReview);
      expect(fakeOb.lastRequestBody?[Fields.reviewId], 'rev_1');
    });
  });

  group('OrignaBaseAdminRepository - watch stream helpers', () {
    test('watchOrders returns a stream', () {
      final stream = repository.watchOrders(status: OrderStatusValues.pending);
      expect(stream, isA<Stream<List<OrderModel>>>());
    });

    test('watchProducts returns a stream', () {
      final stream = repository.watchProducts(sellerId: 's1');
      expect(stream, isA<Stream<List<ProductModel>>>());
    });

    test('watchPendingReviewProducts returns a stream', () {
      final stream = repository.watchPendingReviewProducts();
      expect(stream, isA<Stream<List<ProductModel>>>());
    });

    test('watchReviews returns a stream', () {
      final stream = repository.watchReviews(flaggedOnly: true);
      expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
    });

    test('watchSellers returns a stream', () {
      final stream = repository.watchSellers();
      expect(stream, isA<Stream<List<UserModel>>>());
    });

    test('watchUsers returns a stream', () {
      final stream = repository.watchUsers();
      expect(stream, isA<Stream<List<UserModel>>>());
    });
  });
}
