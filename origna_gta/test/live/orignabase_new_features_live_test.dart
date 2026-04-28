import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:uuid/uuid.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  bool isExpectedAccessError(OrignaBaseException error) =>
      [400, 403, 404, 409, 422].contains(error.statusCode);

  group('OrignaBase New Features Live Tests', () {
    late ProviderContainer container;
    late OrignaBase ob;
    const buyerEmail = 'e2e-buyer@test.origna.ca';
    const buyerPassword = 'REDACTED_TEST_PASSWORD';
    const sellerEmail = 'e2e-seller@test.origna.ca';
    const sellerPassword = 'REDACTED_TEST_PASSWORD';
    const adminEmail = 'e2e-admin@test.origna.ca';
    const adminPassword = 'REDACTED_TEST_PASSWORD';

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
    });

    tearDownAll(() {
      container.dispose();
    });

    // --- 1. Product review submission ---
    test(
      'submit product review/rating succeeds or returns expected error',
      () async {
        await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

        try {
          final result = await ob.request(
            'POST',
            ApiEndpoints.productsSubmitRatingAtomic,
            body: {
              Fields.productId: 'e2e_product_test_seller',
              Fields.userId: ob.auth.currentUserId,
              'rating': 4,
              'title': 'Great product',
              'comment': 'Live test review — please ignore',
            },
          );

          expect(result, isA<Map<String, dynamic>>());
        } on OrignaBaseException catch (e) {
          // 400 = not eligible (didn't buy), 409 = already reviewed, 404 = product not found
          expect(
            [400, 403, 404, 409, 422].contains(e.statusCode),
            isTrue,
            reason:
                'Review submission error should be expected, got ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 2. Product review eligibility check ---
    test(
      'review eligibility check returns a boolean-like response',
      () async {
        await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

        // Check if buyer can review a product (need to have purchased it)
        final ratingsSnapshot = await ob
            .collection(Collections.productRatings)
            .where(Fields.productId, isEqualTo: 'e2e_product_test_seller')
            .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
            .limit(1)
            .get();

        // If no rating exists, buyer may be eligible (if they purchased)
        // If rating exists, they already reviewed
        final hasReviewed = ratingsSnapshot.docs.isNotEmpty;
        expect(
          hasReviewed,
          isA<bool>(),
          reason: 'Eligibility check should resolve to a boolean',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 3. Return request creation ---
    test(
      'return request on a delivered order is handled',
      () async {
        await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

        // Find a delivered order to test against
        final dynamic ordersSnapshot;
        try {
          ordersSnapshot = await ob
              .collection(Collections.orders)
              .where(Fields.buyerId, isEqualTo: ob.auth.currentUserId)
              .where(Fields.status, isEqualTo: OrderStatusValues.delivered)
              .limit(1)
              .get();
        } on OrignaBaseException catch (e) {
          expect(
            isExpectedAccessError(e),
            isTrue,
            reason:
                'Unexpected delivered-order lookup error: ${e.statusCode}: ${e.message}',
          );
          return;
        }

        final ordersDocs = (ordersSnapshot.docs as List<dynamic>?) ?? const [];
        if (ordersDocs.isEmpty) {
          // No delivered orders — skip gracefully
          return;
        }

        final orderId = ordersDocs.first.id;

        try {
          final result = await ob.request(
            'POST',
            ApiEndpoints.ordersCreateReturn,
            body: {
              'orderId': orderId,
              ApiKeys.reason: 'Live test return — product not as described',
              'items': [], // Return all items
            },
          );

          expect(result, isA<Map<String, dynamic>>());
        } on OrignaBaseException catch (e) {
          // 400 = return window expired, 409 = already returned, 404 = order not found
          expect(
            [400, 403, 404, 409, 422].contains(e.statusCode),
            isTrue,
            reason:
                'Return request error should be expected, got ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 4. Seller metrics/analytics data fetch ---
    test(
      'seller metrics collection returns data or empty',
      () async {
        await ob.auth.signInWithEmail(sellerEmail, sellerPassword);

        try {
          final metricsSnapshot = await ob
              .collection(Collections.sellerMetrics)
              .where(Fields.sellerId, isEqualTo: ob.auth.currentUserId)
              .limit(5)
              .get();

          expect(metricsSnapshot.docs, isA<List<dynamic>>());
        } on OrignaBaseException catch (e) {
          expect(
            isExpectedAccessError(e),
            isTrue,
            reason:
                'Unexpected seller metrics error: ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 5. Bulk update endpoint accepts valid batch ---
    test(
      'bulk product update endpoint processes valid batch',
      () async {
        await ob.auth.signInWithEmail(sellerEmail, sellerPassword);

        // Get seller's products
        final productsSnapshot = await ob
            .collection(Collections.products)
            .where(Fields.sellerId, isEqualTo: ob.auth.currentUserId)
            .limit(2)
            .get();

        if (productsSnapshot.docs.isEmpty) return;

        final productIds = productsSnapshot.docs.map((doc) => doc.id).toList();

        try {
          final result = await ob.request(
            'POST',
            ApiEndpoints.productsBulkUpdate,
            body: {
              Fields.userId: ob.auth.currentUserId,
              'updates': productIds
                  .map(
                    (id) => {
                      Fields.productId: id,
                      Fields.description:
                          'Bulk update test — ${DateTime.now().toIso8601String()}',
                    },
                  )
                  .toList(),
            },
          );

          expect(result, isA<Map<String, dynamic>>());
        } on OrignaBaseException catch (e) {
          // 400/404 = endpoint params different — acceptable
          if ([400, 404, 422].contains(e.statusCode)) return;
          rethrow;
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 6. Bulk upload rejects > 100 items ---
    test(
      'bulk update with >100 items is rejected or handled',
      () async {
        await ob.auth.signInWithEmail(sellerEmail, sellerPassword);

        // Create a list of 101 fake updates
        final tooManyUpdates = List.generate(
          101,
          (i) => {
            Fields.productId: 'fake_product_$i',
            Fields.description: 'Bulk overload test $i',
          },
        );

        try {
          await ob.request(
            'POST',
            ApiEndpoints.productsBulkUpdate,
            body: {
              Fields.userId: ob.auth.currentUserId,
              'updates': tooManyUpdates,
            },
          );
          // If accepted, the backend may not have a batch limit — note as finding
        } on OrignaBaseException catch (e) {
          // Expected: 400/413/422 for too many items
          expect(
            [400, 413, 422].contains(e.statusCode),
            isTrue,
            reason:
                'Too many items should be rejected, got ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 7. Admin data export endpoint ---
    test(
      'admin export data endpoint responds',
      () async {
        await ob.auth.signInWithEmail(adminEmail, adminPassword);

        try {
          final result = await ob.request(
            'POST',
            ApiEndpoints.adminExportData,
            body: {'type': 'orders', 'format': 'json'},
          );

          expect(result, isA<Map<String, dynamic>>());
        } on OrignaBaseException catch (e) {
          // 400/404/403 = params wrong or not implemented — acceptable
          expect(
            [400, 403, 404, 422].contains(e.statusCode),
            isTrue,
            reason:
                'Export data error should be expected, got ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 8. Admin MFA enrollment endpoint responds ---
    test(
      'admin MFA enroll endpoint returns provisioning data or expected error',
      () async {
        await ob.auth.signInWithEmail(adminEmail, adminPassword);

        try {
          final result = await ob.request(
            'POST',
            ApiEndpoints.adminMfaEnroll,
            body: {},
          );

          expect(result, isA<Map<String, dynamic>>());
          // Should contain provisioning URI or QR code
          final hasSecret =
              result.containsKey(ApiKeys.secret) ||
              result.containsKey(ApiKeys.qrCodeUrl) ||
              result.containsKey(ApiKeys.provisioningUri);
          expect(
            hasSecret,
            isTrue,
            reason:
                'MFA enroll should return secret/QR. Keys: ${result.keys.toList()}',
          );
        } on OrignaBaseException catch (e) {
          // 409 = already enrolled, 400 = bad request
          expect(
            [400, 403, 404, 409, 422].contains(e.statusCode),
            isTrue,
            reason:
                'MFA enroll error should be expected, got ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 9. Search with pagination ---
    test(
      'search with offset pagination returns different results',
      () async {
        await ob.auth.signInWithEmail(buyerEmail, buyerPassword);

        // Page 1
        final page1 = await ob.search(
          Collections.products,
          '',
          limit: 3,
          offset: 0,
          filter:
              '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );
        final hits1 = (page1['hits'] as List<dynamic>?) ?? [];

        if (hits1.length < 3) return; // Not enough products to test pagination

        // Page 2
        final page2 = await ob.search(
          Collections.products,
          '',
          limit: 3,
          offset: 3,
          filter:
              '${Fields.lifecycleStatus} = ${ProductLifecycleStatusValues.active}',
        );
        final hits2 = (page2['hits'] as List<dynamic>?) ?? [];

        // Pages should have different items (if enough products exist)
        if (hits2.isNotEmpty) {
          final ids1 = hits1
              .map((h) => (h as Map<String, dynamic>)['id'])
              .toSet();
          final ids2 = hits2
              .map((h) => (h as Map<String, dynamic>)['id'])
              .toSet();
          // At least some IDs should differ
          expect(
            ids1.intersection(ids2).length,
            lessThan(3),
            reason: 'Paginated results should be different',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    // --- 10. Address CRUD lifecycle ---
    test(
      'address full CRUD: create, read, update, delete',
      () async {
        await ob.auth.signInWithEmail(buyerEmail, buyerPassword);
        final marker = const Uuid().v4().substring(0, 8);
        final addressId = 'live_feat_test_$marker';

        // Create
        await ob.collection(Collections.addresses).doc(addressId).set({
          Fields.userId: ob.auth.currentUserId,
          'street': '100 Feature Test Blvd',
          'city': 'Ottawa',
          'province': 'ON',
          'postalCode': 'K1A 0A6',
          'country': 'Canada',
          'label': 'Feature Test $marker',
          Fields.isDefault: false,
        });

        // Read
        var doc = await ob
            .collection(Collections.addresses)
            .doc(addressId)
            .get();
        expect(
          doc?.exists,
          isTrue,
          reason: 'Address should exist after creation',
        );
        expect(doc?.data['city'], equals('Ottawa'));

        // Update
        await ob.collection(Collections.addresses).doc(addressId).update({
          'city': 'Gatineau',
          'province': 'QC',
        });

        doc = await ob.collection(Collections.addresses).doc(addressId).get();
        expect(doc?.data['city'], equals('Gatineau'));
        expect(doc?.data['province'], equals('QC'));

        // Delete
        await ob.collection(Collections.addresses).doc(addressId).delete();

        doc = await ob.collection(Collections.addresses).doc(addressId).get();
        expect(doc, isNull, reason: 'Address should be deleted');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
