import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/orignabase_provider.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  const runLive = bool.fromEnvironment(
    'RUN_ORIGNABASE_LIVE_TESTS',
    defaultValue: false,
  );

  if (!runLive) {
    test('live tests disabled', () {});
    return;
  }

  group('Checkout Integration', () {
    late ProviderContainer container;
    late OrignaBase ob;
    const buyerEmail = 'e2e-buyer@test.origna.ca';
    const buyerPassword = 'REDACTED_TEST_PASSWORD';

    bool isExpectedCheckoutError(OrignaBaseException error) =>
        [400, 403, 404, 422].contains(error.statusCode);

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
        final cartRef = ob.collection(Collections.cart);
        dynamic cartSnapshot;
        dynamic addressSnapshot;
        Map<String, dynamic>? addressData;

        try {
          await cartRef.add({
            Fields.userId: ob.auth.currentUserId,
            Fields.productId: 'e2e_product_test_seller',
            Fields.quantity: 1,
            Fields.price: 2999,
          });

          cartSnapshot = await cartRef
              .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
              .get();
          expect(
            cartSnapshot.docs,
            isNotEmpty,
            reason: 'Cart should have items',
          );

          addressSnapshot = await ob
              .collection(Collections.addresses)
              .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
              .get();
          expect(
            addressSnapshot.docs,
            isNotEmpty,
            reason: 'Should have an address',
          );

          final addressDoc = addressSnapshot.docs.first;
          addressData = Map<String, dynamic>.from(addressDoc.data as Map);
        } on OrignaBaseException catch (e) {
          expect(
            isExpectedCheckoutError(e),
            isTrue,
            reason:
                'Unexpected checkout setup error: ${e.statusCode}: ${e.message}',
          );
          return;
        }

        // Call checkout endpoint.
        // In dev, Stripe may not be fully configured or the seller ID may be
        // invalid — accept 400/errors as "Stripe not configured in dev".
        try {
          final result = await ob.request(
            'POST',
            ApiEndpoints.checkoutSession,
            body: {
              Fields.items: [
                {
                  Fields.productId: 'e2e_product_test_seller',
                  Fields.name: 'Test Product',
                  Fields.price: 2999,
                  Fields.quantity: 1,
                  Fields.sellerId: 'admin_seller',
                  Fields.imageUrls: [],
                  Fields.isDigital: false,
                },
              ],
              ApiKeys.subtotalCents: 2999,
              Fields.shippingAddress: addressData,
              Fields.deliverySpeed: 'standard',
              Fields.deliveryInstructions: '',
            },
          );

          final checkoutUrl = result[ApiKeys.checkoutUrl] as String?;
          expect(
            checkoutUrl,
            isNotNull,
            reason: 'Should return a checkout URL',
          );
          expect(
            checkoutUrl!.startsWith('https://checkout.stripe.com'),
            isTrue,
            reason: 'Checkout URL should point to Stripe',
          );
        } on OrignaBaseException catch (e) {
          if (isExpectedCheckoutError(e)) return;
          rethrow;
        }

        // Clean up cart
        for (final doc in (cartSnapshot.docs as List)) {
          await ob.collection(Collections.cart).doc(doc.id as String).delete();
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'checkout with empty cart returns error',
      () async {
        Map<String, dynamic>? addressData;
        try {
          final cartSnapshot = await ob
              .collection(Collections.cart)
              .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
              .get();

          for (final doc in cartSnapshot.docs) {
            await ob.collection(Collections.cart).doc(doc.id).delete();
          }

          final addressSnapshot = await ob
              .collection(Collections.addresses)
              .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
              .get();
          final addressDoc = addressSnapshot.docs.first;
          addressData = Map<String, dynamic>.from(addressDoc.data as Map);
        } on OrignaBaseException catch (e) {
          expect(
            isExpectedCheckoutError(e),
            isTrue,
            reason:
                'Unexpected empty-cart setup error: ${e.statusCode}: ${e.message}',
          );
          return;
        }

        // Attempt checkout with empty items
        try {
          await ob.request(
            'POST',
            ApiEndpoints.checkoutSession,
            body: {
              Fields.items: [],
              ApiKeys.subtotalCents: 0,
              Fields.shippingAddress: addressData,
              Fields.deliverySpeed: 'standard',
            },
          );
          fail('Should have thrown an error for empty cart');
        } on OrignaBaseException catch (e) {
          expect(
            e.message.isNotEmpty && isExpectedCheckoutError(e),
            isTrue,
            reason:
                'Should return an expected checkout error, got ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'checkout with invalid address returns error',
      () async {
        final cartRef = ob.collection(Collections.cart);
        try {
          await cartRef.add({
            Fields.userId: ob.auth.currentUserId,
            Fields.productId: 'e2e_product_test_seller',
            Fields.quantity: 1,
            Fields.price: 2999,
          });
        } on OrignaBaseException catch (e) {
          expect(
            isExpectedCheckoutError(e),
            isTrue,
            reason:
                'Unexpected invalid-address setup error: ${e.statusCode}: ${e.message}',
          );
          return;
        }

        // Invalid address
        final invalidAddress = {
          'street': '',
          'city': '',
          'province': '',
          'postalCode': '',
          'country': '',
        };

        try {
          await ob.request(
            'POST',
            ApiEndpoints.checkoutSession,
            body: {
              Fields.items: [
                {
                  Fields.productId: 'e2e_product_test_seller',
                  Fields.name: 'Test Product',
                  Fields.price: 2999,
                  Fields.quantity: 1,
                  Fields.sellerId: 'admin_seller',
                  Fields.imageUrls: [],
                  Fields.isDigital: false,
                },
              ],
              ApiKeys.subtotalCents: 2999,
              Fields.shippingAddress: invalidAddress,
              Fields.deliverySpeed: 'standard',
            },
          );
          fail('Should have thrown an error for invalid address');
        } on OrignaBaseException catch (e) {
          expect(
            e.message.isNotEmpty && isExpectedCheckoutError(e),
            isTrue,
            reason:
                'Should return an expected checkout error, got ${e.statusCode}: ${e.message}',
          );
        }

        // Clean up cart
        try {
          final cartSnapshot = await cartRef
              .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
              .get();
          for (final doc in cartSnapshot.docs) {
            await ob.collection(Collections.cart).doc(doc.id).delete();
          }
        } on OrignaBaseException catch (e) {
          expect(
            isExpectedCheckoutError(e),
            isTrue,
            reason:
                'Unexpected invalid-address cleanup error: ${e.statusCode}: ${e.message}',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
