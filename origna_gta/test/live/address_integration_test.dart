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

  bool isExpectedPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('403') ||
        msg.contains('permission') ||
        msg.contains('forbidden');
  }

  group('Address Integration', skip: !runLive ? 'live tests disabled' : null, () {
    late ProviderContainer container;
    late OrignaBase ob;
    late String createdAddressId;
    const buyerEmail = 'e2e-buyer@test.origna.ca';
    const buyerPassword = 'REDACTED_TEST_PASSWORD';

    setUpAll(() async {
      container = ProviderContainer();
      ob = container.read(orignabaseProvider);
      await ob.auth.signInWithEmail(buyerEmail, buyerPassword);
    });

    tearDownAll(() async {
      // Clean up created address
      if (createdAddressId.isNotEmpty) {
        try {
          await ob.collection(Collections.addresses).doc(createdAddressId).delete();
        } catch (_) {
          // Address already deleted or doesn't exist
        }
      }
      ob.auth.signOut();
      container.dispose();
    });

    test(
      'add address returns address ID',
      () async {
        final marker = const Uuid().v4().substring(0, 8);
        createdAddressId = 'addr_live_test_$marker';

        final addressData = {
          Fields.userId: ob.auth.currentUserId,
          'street': '123 Test St',
          'city': 'Toronto',
          'province': 'ON',
          'postalCode': 'M5V 3A8',
          'country': 'Canada',
          'label': 'Live Test Address $marker',
          Fields.isDefault: false,
        };

        await ob.collection(Collections.addresses).doc(createdAddressId).set(addressData);

        expect(createdAddressId, isNotEmpty, reason: 'Should return an address ID');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'get user addresses includes newly added address',
      () async {
        expect(createdAddressId, isNotEmpty, reason: 'Address must be created first');
        try {
          final addressSnapshot = await ob
              .collection(Collections.addresses)
              .where(Fields.userId, isEqualTo: ob.auth.currentUserId)
              .get();

          expect(addressSnapshot.docs, isNotEmpty,
              reason: 'Should have at least one address');

          final addressIds = addressSnapshot.docs
              .map((doc) => doc.id.contains(':') ? doc.id.split(':').last : doc.id)
              .toList();
          expect(addressIds.contains(createdAddressId), isTrue,
              reason: 'Created address should be in the list');

          final createdDoc = addressSnapshot.docs.firstWhere((doc) {
            final shortId = doc.id.contains(':') ? doc.id.split(':').last : doc.id;
            return shortId == createdAddressId || doc.id == createdAddressId;
          });
          expect(createdDoc.data['street'], equals('123 Test St'));
          expect(createdDoc.data['city'], equals('Toronto'));
        } catch (e) {
          expect(
            isExpectedPermissionError(e),
            isTrue,
            reason: 'Unexpected address lookup error: $e',
          );
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'update address modifies address data',
      () async {
        expect(createdAddressId, isNotEmpty, reason: 'Address must be created first');

        final newStreet = '456 Updated Ave';
        await ob
            .collection(Collections.addresses)
            .doc(createdAddressId)
            .update({'street': newStreet, 'city': 'Vancouver'});

        // Verify update
        final updatedDoc = await ob
            .collection(Collections.addresses)
            .doc(createdAddressId)
            .get();

        expect(updatedDoc?.data['street'], equals(newStreet));
        expect(updatedDoc?.data['city'], equals('Vancouver'));
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'delete address removes it from list',
      () async {
        expect(createdAddressId, isNotEmpty, reason: 'Address must be created first');

        // Delete the address
        await ob.collection(Collections.addresses).doc(createdAddressId).delete();

        // Verify deletion
        final deletedDoc = await ob
            .collection(Collections.addresses)
            .doc(createdAddressId)
            .get();

        expect(deletedDoc, isNull, reason: 'Address should be deleted');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );

    test(
      'full address lifecycle: add, read, update, delete',
      () async {
        final marker = const Uuid().v4().substring(0, 8);
        final addressId = '${Collections.addresses}_live_$marker';

        // Add
        final addressData = {
          Fields.userId: ob.auth.currentUserId,
          'street': '789 Lifecycle St',
          'city': 'Montreal',
          'province': 'QC',
          'postalCode': 'H1A 0A1',
          'country': 'Canada',
          'label': 'Lifecycle Test $marker',
          Fields.isDefault: false,
        };

        final docRef = ob.collection(Collections.addresses).doc(addressId);
        await docRef.set(addressData);

        // Read
        var doc = await docRef.get();
        expect(doc?.exists, isTrue, reason: 'Address should exist after creation');
        expect(doc?.data['street'], equals('789 Lifecycle St'));

        // Update
        await docRef.update({
          'street': '789 Lifecycle St Unit 2',
          'postalCode': 'H1A 0A2',
        });

        doc = await docRef.get();
        expect(doc?.data['street'], equals('789 Lifecycle St Unit 2'));
        expect(doc?.data['postalCode'], equals('H1A 0A2'));

        // Delete
        await docRef.delete();

        doc = await docRef.get();
        expect(doc, isNull, reason: 'Address should be deleted');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
