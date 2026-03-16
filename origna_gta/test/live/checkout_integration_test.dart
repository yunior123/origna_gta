import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  group('Checkout Integration', skip: !runLive ? 'live tests disabled' : null, () {
    late ProviderContainer container;
    late OrignaBase ob;
    const buyerEmail = 'yuniorrodriguezo460@gmail.com';
    const buyerPassword = 'REDACTED_TEST_PASSWORD';

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      await ob.auth.signInWithEmail(buyerEmail, buyerPassword);
    });

    tearDownAll(() async {
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'checkout returns valid session URL',
      () async {
        // Add product to cart
        final cartRef = ob.collection(Collections.cart);
        await cartRef.add({
          Fields.userId: ob.auth.currentUserId,
          Fields.productId: 'e2e_product_test_seller',
          Fields.quantity: 1,
          Fields.price: 2999, // $29.99 in cents
        });

        // Get cart details
        final cartSnapshot = await cartRef
            .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
            .get();
        expect(cartSnapshot.docs, isNotEmpty, reason: 'Cart should have items');

        // Get checkout address
        final addressSnapshot = await ob
            .collection(Collections.addresses)
            .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
            .get();
        expect(addressSnapshot.docs, isNotEmpty, reason: 'Should have an address');

        final addressDoc = addressSnapshot.docs.first;
        final addressData = addressDoc.data;

        // Call checkout endpoint
        final result = await ob.request('POST', ApiEndpoints.checkoutSession, body: {
          Fields.items: [
            {
              Fields.productId: 'e2e_product_test_seller',
              Fields.name: 'Test Product',
              Fields.price: 2999,
              Fields.quantity: 1,
              Fields.sellerId: 'admin_seller',
              Fields.imageUrls: [],
              Fields.isDigital: false,
            }
          ],
          ApiKeys.subtotalCents: 2999,
          Fields.shippingAddress: addressData,
          Fields.deliverySpeed: 'standard',
          Fields.deliveryInstructions: '',
        });

        final checkoutUrl = result[ApiKeys.checkoutUrl] as String?;
        expect(checkoutUrl, isNotNull, reason: 'Should return a checkout URL');
        expect(
          checkoutUrl!.startsWith('https://checkout.stripe.com'),
          isTrue,
          reason: 'Checkout URL should point to Stripe',
        );

        // Clean up cart
        for (final doc in cartSnapshot.docs) {
          await ob.collection(Collections.cart).doc(doc.id).delete();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'checkout with empty cart returns error',
      () async {
        // Verify cart is empty
        final cartSnapshot = await ob
            .collection(Collections.cart)
            .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
            .get();

        // Clear any items
        for (final doc in cartSnapshot.docs) {
          await ob.collection(Collections.cart).doc(doc.id).delete();
        }

        // Get an address
        final addressSnapshot = await ob
            .collection(Collections.addresses)
            .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
            .get();
        final addressDoc = addressSnapshot.docs.first;
        final addressData = addressDoc.data;

        // Attempt checkout with empty items
        try {
          await ob.request('POST', ApiEndpoints.checkoutSession, body: {
            Fields.items: [],
            ApiKeys.subtotalCents: 0,
            Fields.shippingAddress: addressData,
            Fields.deliverySpeed: 'standard',
          });
          fail('Should have thrown an error for empty cart');
        } on OrignaBaseException catch (e) {
          expect(e.message, isNotEmpty, reason: 'Should have an error message');
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'checkout with invalid address returns error',
      () async {
        // Add product to cart
        final cartRef = ob.collection(Collections.cart);
        await cartRef.add({
          Fields.userId: ob.auth.currentUserId,
          Fields.productId: 'e2e_product_test_seller',
          Fields.quantity: 1,
          Fields.price: 2999,
        });

        // Invalid address
        final invalidAddress = {
          'street': '',
          'city': '',
          'province': '',
          'postalCode': '',
          'country': '',
        };

        try {
          await ob.request('POST', ApiEndpoints.checkoutSession, body: {
            Fields.items: [
              {
                Fields.productId: 'e2e_product_test_seller',
                Fields.name: 'Test Product',
                Fields.price: 2999,
                Fields.quantity: 1,
                Fields.sellerId: 'admin_seller',
                Fields.imageUrls: [],
                Fields.isDigital: false,
              }
            ],
            ApiKeys.subtotalCents: 2999,
            Fields.shippingAddress: invalidAddress,
            Fields.deliverySpeed: 'standard',
          });
          fail('Should have thrown an error for invalid address');
        } on OrignaBaseException catch (e) {
          expect(e.message, isNotEmpty, reason: 'Should have an error message');
        }

        // Clean up cart
        final cartSnapshot = await cartRef
            .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
            .get();
        for (final doc in cartSnapshot.docs) {
          await ob.collection(Collections.cart).doc(doc.id).delete();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
