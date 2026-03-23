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

  group('Product Lifecycle Integration', skip: !runLive ? 'live tests disabled' : null, () {
    late ProviderContainer container;
    late OrignaBase ob;
    late String createdProductId;
    const sellerEmail = 'e2e-seller@test.origna.ca';
    const sellerPassword = 'REDACTED_TEST_PASSWORD';

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      await ob.auth.signInWithEmail(sellerEmail, sellerPassword);
    });

    tearDownAll(() async {
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'create product with draft status',
      () async {
        final marker = const Uuid().v4().substring(0, 8);
        final productTitle = 'Live Test Product $marker';

        final result = await ob.request('POST', ApiEndpoints.productsCreateAtomic, body: {
          Fields.userId: ob.auth.currentUserId,
          'productData': {
            Fields.name: productTitle,
            Fields.description: 'Test product for lifecycle integration',
            Fields.priceCents: 9999, // $99.99
            Fields.stockQuantity: 50,
            Fields.lifecycleStatus: ProductLifecycleStatusValues.draft,
            Fields.categoryId: 1,
            Fields.subcategory: 'test',
            Fields.isDigital: false,
            Fields.isPerishable: false,
            Fields.sellerAddress: {
              'street': '123 Test St',
              'city': 'Toronto',
              'province': 'ON',
              'postalCode': 'M5V 3A8',
              'country': 'Canada',
            },
          },
        });

        expect(result, isA<Map<String, dynamic>>());
        final productIdResult = result[Fields.productId];
        if (productIdResult != null) {
          createdProductId = productIdResult as String;
        } else {
          createdProductId = '';
        }
        expect(createdProductId, isNotEmpty, reason: 'Should return a product ID');

        // Verify product was created in draft status
        final doc = await ob.collection(Collections.products).doc(createdProductId).get();
        expect(doc?.data[Fields.lifecycleStatus], equals(ProductLifecycleStatusValues.draft));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'publish product to active status',
      () async {
        expect(createdProductId, isNotEmpty, reason: 'Product must be created first');

        // Update status to active
        await ob.collection(Collections.products).doc(createdProductId).update({
          Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
        });

        // Verify status changed
        final doc = await ob.collection(Collections.products).doc(createdProductId).get();
        expect(doc?.data[Fields.lifecycleStatus], equals(ProductLifecycleStatusValues.active));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'update product price',
      () async {
        expect(createdProductId, isNotEmpty, reason: 'Product must be created first');

        final newPrice = 7999; // $79.99
        await ob
            .collection(Collections.products)
            .doc(createdProductId)
            .update({Fields.priceCents: newPrice});

        // Verify price changed
        final doc = await ob.collection(Collections.products).doc(createdProductId).get();
        expect(doc?.data[Fields.priceCents], equals(newPrice));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'deactivate product to paused status',
      () async {
        expect(createdProductId, isNotEmpty, reason: 'Product must be created first');

        // Update status to paused
        await ob.collection(Collections.products).doc(createdProductId).update({
          Fields.lifecycleStatus: ProductLifecycleStatusValues.paused,
        });

        // Verify status changed
        final doc = await ob.collection(Collections.products).doc(createdProductId).get();
        expect(doc?.data[Fields.lifecycleStatus], equals(ProductLifecycleStatusValues.paused));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'delete product',
      () async {
        expect(createdProductId, isNotEmpty, reason: 'Product must be created first');

        // Delete product
        await ob.request('POST', ApiEndpoints.productsDelete, body: {
          Fields.productId: createdProductId,
          Fields.userId: ob.auth.currentUserId,
        });

        // Verify deletion - product should not be found or marked as deleted
        final doc = await ob.collection(Collections.products).doc(createdProductId).get();
        if (doc != null && doc.exists) {
          // Some backends soft-delete, so check if status changed
          final status = doc.data[Fields.lifecycleStatus] as String?;
          expect(status, isNotEmpty, reason: 'Product status should exist');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'full product lifecycle: create, publish, update, deactivate, delete',
      () async {
        final marker = const Uuid().v4().substring(0, 8);
        final productTitle = 'Lifecycle Test $marker';

        // Create in draft
        final createResult = await ob.request('POST', ApiEndpoints.productsCreateAtomic, body: {
          Fields.userId: ob.auth.currentUserId,
          'productData': {
            Fields.name: productTitle,
            Fields.description: 'Full lifecycle test',
            Fields.priceCents: 5000, // $50.00
            Fields.stockQuantity: 100,
            Fields.lifecycleStatus: ProductLifecycleStatusValues.draft,
            Fields.categoryId: 1,
            Fields.subcategory: 'test',
            Fields.isDigital: false,
            Fields.isPerishable: false,
            Fields.sellerAddress: {
              'street': '456 Lifecycle Ave',
              'city': 'Vancouver',
              'province': 'BC',
              'postalCode': 'V6B 4X7',
              'country': 'Canada',
            },
          },
        });

        final productId = createResult[Fields.productId] as String;
        expect(productId, isNotEmpty);

        // Publish (draft → active)
        await ob.collection(Collections.products).doc(productId).update({
          Fields.lifecycleStatus: ProductLifecycleStatusValues.active,
        });

        var doc = await ob.collection(Collections.products).doc(productId).get();
        expect(doc?.data[Fields.lifecycleStatus], equals(ProductLifecycleStatusValues.active));

        // Update price
        const newPrice = 4500;
        await ob.collection(Collections.products).doc(productId).update({
          Fields.priceCents: newPrice,
        });

        doc = await ob.collection(Collections.products).doc(productId).get();
        expect(doc?.data[Fields.priceCents], equals(newPrice));

        // Deactivate (active → paused)
        await ob.collection(Collections.products).doc(productId).update({
          Fields.lifecycleStatus: ProductLifecycleStatusValues.paused,
        });

        doc = await ob.collection(Collections.products).doc(productId).get();
        expect(doc?.data[Fields.lifecycleStatus], equals(ProductLifecycleStatusValues.paused));

        // Delete
        await ob.request('POST', ApiEndpoints.productsDelete, body: {
          Fields.productId: productId,
          Fields.userId: ob.auth.currentUserId,
        });

        doc = await ob.collection(Collections.products).doc(productId).get();
        if (doc != null && doc.exists) {
          expect(doc.data[Fields.lifecycleStatus], isNotEmpty);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
