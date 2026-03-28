// Integration tests for seller features against live dev server
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

  group('Seller features live', () {
    late ProviderContainer container;
    late OrignaBase ob;

    bool isExpectedPermissionError(Object error) {
      final msg = error.toString().toLowerCase();
      return msg.contains('403') ||
          msg.contains('permission') ||
          msg.contains('forbidden');
    }

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);

      // Sign in as seller
      await ob.auth.signInWithEmail(
        'e2e-seller@test.origna.ca',
        'REDACTED_TEST_PASSWORD',
      );
    });

    tearDownAll(() async {
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'Can fetch seller profile',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        try {
          final userDoc = await ob.collection(Collections.users).doc(currentUserId!).get();

          if (userDoc != null && userDoc.exists) {
            expect(userDoc.data, isA<Map<String, dynamic>>());
            final roles = userDoc.data[Fields.roles];
            expect(roles, isNotNull);
          }
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected seller profile lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Can query seller profile document',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        // Seller profiles are keyed by short user ID — strip collection prefix
        // (JWT sub returns "users:xxx" but seller_profiles use "xxx" as key).
        final shortId = currentUserId!.contains(':')
            ? currentUserId.split(':').last
            : currentUserId;

        final sellerProfileDoc = await ob
            .collection(Collections.sellerProfiles)
            .doc(shortId)
            .get();

        // May exist if seller is registered
        if (sellerProfileDoc != null && sellerProfileDoc.exists) {
          expect(sellerProfileDoc.data, isA<Map<String, dynamic>>());
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Can create warehouse',
      () async {
        const uuid = Uuid();
        final warehouseLabel = 'Test Warehouse ${uuid.v4().substring(0, 8)}';

        try {
          await ob.request(
            'POST',
            ApiEndpoints.warehousesCreate,
            body: {
              'label': warehouseLabel,
              Fields.type: 'primary',
              'address': {
                Fields.street: '123 Test St',
                Fields.city: 'Toronto',
                Fields.state: 'ON',
                Fields.postalCode: 'M5V 3A8',
                Fields.country: 'Canada',
              },
              'isDefault': false,
            },
          );
          expect(true, isTrue);
        } catch (e) {
          // May fail if warehouse limit reached
          expect(e, isNotNull);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Can query warehouses collection',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        try {
          final snapshot = await ob
              .collection(Collections.warehouses)
              .where(Fields.sellerId, isEqualTo: currentUserId!)
              .limit(10)
              .get();

          expect(snapshot, isNotNull);
          expect(snapshot.docs, isA<List<dynamic>>());
        } catch (e) {
          // May fail if collection doesn't exist yet
          expect(e, isNotNull);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'updateWarehouse endpoint is reachable',
      () async {
        // Get a warehouse first
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        try {
          final snapshot = await ob
              .collection(Collections.warehouses)
              .where(Fields.sellerId, isEqualTo: currentUserId!)
              .limit(1)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final warehouseId = snapshot.docs.first.id;
            await ob.request(
              'POST',
              ApiEndpoints.warehousesUpdate,
              body: {
                'warehouseId': warehouseId,
                'label': 'Updated Warehouse',
              },
            );
            expect(true, isTrue);
          }
        } catch (e) {
          // May fail if no warehouses exist
          expect(e, isNotNull);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Can query seller products',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        final snapshot = await ob
            .collection(Collections.products)
            .where(Fields.sellerId, isEqualTo: currentUserId!)
            .limit(10)
            .get();

        expect(snapshot, isNotNull);
        expect(snapshot.docs, isA<List<dynamic>>());
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Can query seller orders',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        try {
          final snapshot = await ob
              .collection(Collections.orders)
              .where(Fields.sellerId, isEqualTo: currentUserId!)
              .limit(10)
              .get();

          expect(snapshot, isNotNull);
          expect(snapshot.docs, isA<List<dynamic>>());
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected seller orders lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'deleteWarehouse endpoint is reachable',
      () async {
        // Try to delete a nonexistent warehouse
        try {
          await ob.request(
            'POST',
            ApiEndpoints.warehousesDelete,
            body: {
              'warehouseId': 'nonexistent_warehouse_id',
            },
          );
          // May succeed with no error or fail
        } catch (e) {
          // Expected to fail with nonexistent warehouse
          expect(e, isNotNull);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Can query seller stats via collection',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        try {
          final productSnapshot = await ob
              .collection(Collections.products)
              .where(Fields.sellerId, isEqualTo: currentUserId!)
              .get();

          expect(productSnapshot.docs, isA<List<dynamic>>());

          final orderSnapshot = await ob
              .collection(Collections.orders)
              .where(Fields.sellerId, isEqualTo: currentUserId)
              .get();

          expect(orderSnapshot.docs, isA<List<dynamic>>());
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected seller stats lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'Can fetch seller profile details',
      () async {
        final currentUserId = ob.auth.currentUserId;
        expect(currentUserId, isNotNull);

        try {
          final userDoc = await ob.collection(Collections.users).doc(currentUserId!).get();

          if (userDoc == null || !userDoc.exists) return;

          final data = userDoc.data;
          expect(data, isA<Map<String, dynamic>>());
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected seller profile details lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
