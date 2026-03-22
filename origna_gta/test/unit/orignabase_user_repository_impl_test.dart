import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orignabase/orignabase.dart';
import 'package:origna_gta/core/repositories/orignabase_user_repository.dart';
import 'package:origna_gta/core/repositories/user_repository.dart'
    show SellerAccountStatus;
import 'package:origna_gta/core/schema/schema_constants.dart'
    show ApiEndpoints, Collections, Fields, PolicyVersionValues, UserRoleValues;
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

  @override
  final String collection;

  _FakeDocument? documentValue;
  Map<String, dynamic>? lastSetData;
  Map<String, dynamic>? lastUpdateData;
  bool deleted = false;

  _FakeDocumentRef({
    this.id = 'doc_id',
    this.collection = 'test',
    _FakeDocument? doc,
  }) : documentValue = doc;

  @override
  Future<Document?> get() async => documentValue;

  @override
  Future<Document?> set(Map<String, dynamic> data) async {
    lastSetData = data;
    return documentValue ?? _FakeDocument(id, data, exists: true);
  }

  @override
  Future<Document?> update(Map<String, dynamic> data) async {
    lastUpdateData = data;
    return documentValue;
  }

  @override
  Future<void> delete() async {
    deleted = true;
  }
}

class _FakeCollectionRef extends Fake implements CollectionRef {
  final Map<String, _FakeDocumentRef> docsMap = {};
  List<Document> queryDocs = [];

  void setDoc(String id, _FakeDocumentRef ref) {
    docsMap[id] = ref;
  }

  @override
  DocumentRef doc(String id) {
    if (docsMap.containsKey(id)) return docsMap[id]!;
    final ref = _FakeDocumentRef(id: id);
    docsMap[id] = ref;
    return ref;
  }

  @override
  Future<QuerySnapshot> get() async => _FakeQuerySnapshot(queryDocs);

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
  Query startAfterId(String id) => this;
}

class _FakeQuerySnapshot extends Fake implements QuerySnapshot {
  @override
  final List<Document> docs;

  _FakeQuerySnapshot(this.docs);
}

class _FakeOrignaBase extends Fake implements OrignaBase {
  final _FakeAuth authValue = _FakeAuth();
  final _FakeCollectionRef usersCollection = _FakeCollectionRef();
  final _FakeCollectionRef addressesCollection = _FakeCollectionRef();
  final _FakeCollectionRef sellerProfilesCollection = _FakeCollectionRef();

  String? lastRequestMethod;
  String? lastRequestPath;
  Map<String, dynamic>? lastRequestBody;
  Map<String, dynamic> requestResponse = {'success': true};

  @override
  OrignaBaseAuth get auth => authValue;

  @override
  CollectionRef collection(String name) {
    if (name == Collections.users) return usersCollection;
    if (name == Collections.addresses) return addressesCollection;
    if (name == Collections.sellerProfiles) return sellerProfilesCollection;
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
  late OrignaBaseUserRepository repository;

  setUp(() {
    fakeOb = _FakeOrignaBase();
    fakeOb.authValue.currentUserIdValue = 'user_123';
    repository = OrignaBaseUserRepository(fakeOb);
  });

  group('OrignaBaseUserRepository - addBuyerAddress', () {
    test('creates address and returns ID', () async {
      final address = Address(
        street: '123 Main St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'Canada',
        isDefault: false,
      );

      final id = await repository.addBuyerAddress(address);

      expect(id, isNotEmpty);
      expect(fakeOb.addressesCollection.docsMap.containsKey(id), true);
      final docRef = fakeOb.addressesCollection.docsMap[id]!;
      expect(docRef.lastSetData?[Fields.userId], 'user_123');
      expect(docRef.lastSetData?['street'], '123 Main St');
      expect(docRef.lastSetData?['city'], 'Toronto');
    });

    test('sets isDefault and clears others', () async {
      final existingDoc = _FakeDocument('addr_other', {
        Fields.userId: 'user_123',
        Fields.isDefault: true,
      });
      fakeOb.addressesCollection.queryDocs = [existingDoc];
      fakeOb.addressesCollection.setDoc(
        'addr_other',
        _FakeDocumentRef(id: 'addr_other', doc: existingDoc),
      );

      final address = Address(
        street: '456 New St',
        city: 'Montreal',
        state: 'QC',
        postalCode: 'H1H 1H1',
        country: 'Canada',
        isDefault: true,
      );

      final id = await repository.addBuyerAddress(address);

      expect(id, isNotEmpty);
      final otherRef = fakeOb.addressesCollection.docsMap['addr_other'];
      expect(otherRef?.lastUpdateData?[Fields.isDefault], false);
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      final address = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'Canada',
      );

      expect(
        () => repository.addBuyerAddress(address),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when userId is empty', () {
      fakeOb.authValue.currentUserIdValue = '';

      final address = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'Canada',
      );

      expect(
        () => repository.addBuyerAddress(address),
        throwsA(isA<Exception>()),
      );
    });

    test('creates address with UUID and stores data', () async {
      final address = Address(
        street: '123 Main St',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M 1M1',
        country: 'Canada',
        isDefault: false,
      );

      final id = await repository.addBuyerAddress(address);

      expect(id, isNotEmpty);
    });
  });

  group('OrignaBaseUserRepository - deleteBuyerAddress', () {
    test('deletes address when owned by user', () async {
      final doc = _FakeDocument('addr_1', {Fields.userId: 'user_123'});
      final docRef = _FakeDocumentRef(id: 'addr_1', doc: doc);
      fakeOb.addressesCollection.setDoc('addr_1', docRef);

      await repository.deleteBuyerAddress('addr_1');

      expect(docRef.deleted, true);
    });

    test('throws when address not found', () {
      expect(
        () => repository.deleteBuyerAddress('nonexistent'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when address belongs to different user', () {
      final doc = _FakeDocument('addr_1', {Fields.userId: 'other_user'});
      fakeOb.addressesCollection.setDoc('addr_1', _FakeDocumentRef(doc: doc));

      expect(
        () => repository.deleteBuyerAddress('addr_1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when doc does not exist', () {
      final doc = _FakeDocument('addr_1', {}, exists: false);
      fakeOb.addressesCollection.setDoc('addr_1', _FakeDocumentRef(doc: doc));

      expect(
        () => repository.deleteBuyerAddress('addr_1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.deleteBuyerAddress('addr_1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseUserRepository - getSellerAccountStatus', () {
    test('returns status for seller with charges enabled', () async {
      final userDoc = _FakeDocument('user_123', {
        Fields.roles: [UserRole.seller],
      });
      final spDoc = _FakeDocument('user_123', {
        Fields.chargesEnabled: true,
        Fields.payoutsEnabled: true,
        Fields.onboardingCompleted: true,
        Fields.pendingRequirements: [],
      });

      fakeOb.usersCollection.setDoc('user_123', _FakeDocumentRef(doc: userDoc));
      fakeOb.sellerProfilesCollection.setDoc(
        'user_123',
        _FakeDocumentRef(doc: spDoc),
      );

      final status = await repository.getSellerAccountStatus('user_123');

      expect(status.isSeller, true);
      expect(status.chargesEnabled, true);
      expect(status.detailsSubmitted, true);
      expect(status.hasPendingRequirements, false);
      expect(status.isComplete, true);
    });

    test('returns non-seller status', () async {
      final userDoc = _FakeDocument('user_123', {
        Fields.roles: [UserRole.buyer],
      });

      fakeOb.usersCollection.setDoc('user_123', _FakeDocumentRef(doc: userDoc));

      final status = await repository.getSellerAccountStatus('user_123');

      expect(status.isSeller, false);
      expect(status.chargesEnabled, false);
    });

    test('handles missing seller profile', () async {
      final userDoc = _FakeDocument('user_123', {
        Fields.roles: [UserRole.seller],
      });

      fakeOb.usersCollection.setDoc('user_123', _FakeDocumentRef(doc: userDoc));

      final status = await repository.getSellerAccountStatus('user_123');

      expect(status.isSeller, true);
      expect(status.chargesEnabled, false);
    });

    test('handles pending requirements', () async {
      final userDoc = _FakeDocument('user_123', {
        Fields.roles: [UserRole.seller],
      });
      final spDoc = _FakeDocument('user_123', {
        Fields.chargesEnabled: false,
        Fields.payoutsEnabled: false,
        Fields.pendingRequirements: [
          'external_account',
          'individual.verification.document',
        ],
      });

      fakeOb.usersCollection.setDoc('user_123', _FakeDocumentRef(doc: userDoc));
      fakeOb.sellerProfilesCollection.setDoc(
        'user_123',
        _FakeDocumentRef(doc: spDoc),
      );

      final status = await repository.getSellerAccountStatus('user_123');

      expect(status.hasPendingRequirements, true);
      expect(status.pendingRequirements.length, 2);
      expect(status.isIncomplete, true);
      expect(status.needsIdentityDocuments, true);
    });

    test('admin user is treated as seller', () async {
      final userDoc = _FakeDocument('user_123', {
        Fields.roles: [UserRole.admin],
      });
      final spDoc = _FakeDocument('user_123', {
        Fields.chargesEnabled: true,
        Fields.payoutsEnabled: true,
        Fields.pendingRequirements: [],
      });

      fakeOb.usersCollection.setDoc('user_123', _FakeDocumentRef(doc: userDoc));
      fakeOb.sellerProfilesCollection.setDoc(
        'user_123',
        _FakeDocumentRef(doc: spDoc),
      );

      final status = await repository.getSellerAccountStatus('user_123');
      expect(status.isSeller, true);
    });
  });

  group('OrignaBaseUserRepository - getUserProfile', () {
    test('returns UserModel on success', () async {
      fakeOb.requestResponse = {
        'success': true,
        Fields.uid: 'user_123',
        Fields.email: 'user@example.com',
        Fields.name: 'Test User',
        Fields.roles: [UserRole.buyer],
      };

      final profile = await repository.getUserProfile('user_123');

      expect(profile, isNotNull);
      expect(profile!.uid, 'user_123');
      expect(profile.email, 'user@example.com');
    });

    test('returns null on failure', () async {
      fakeOb.requestResponse = {'success': false};

      final profile = await repository.getUserProfile('user_123');
      expect(profile, isNull);
    });

    test('parses address from response', () async {
      fakeOb.requestResponse = {
        'success': true,
        Fields.email: 'user@example.com',
        Fields.address: {
          'street': '123 Main',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M1M',
          'country': 'Canada',
        },
      };

      final profile = await repository.getUserProfile('user_123');

      expect(profile, isNotNull);
      expect(profile!.address, isNotNull);
    });

    test('adds userId to address', () async {
      fakeOb.requestResponse = {
        'success': true,
        Fields.email: 'user@example.com',
        Fields.address: {
          'street': '123 Main',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M1M',
          'country': 'Canada',
        },
      };

      final profile = await repository.getUserProfile('user_123');

      expect(profile!.address, isNotNull);
    });

    test('adds uid from userId when missing', () async {
      fakeOb.requestResponse = {
        'success': true,
        Fields.email: 'user@example.com',
      };

      final profile = await repository.getUserProfile('user_123');

      expect(profile!.uid, 'user_123');
    });
  });

  group('OrignaBaseUserRepository - recordTermsAcceptance', () {
    test('sends terms acceptance', () async {
      fakeOb.requestResponse = {'success': true};

      await repository.recordTermsAcceptance();

      expect(fakeOb.lastRequestPath, ApiEndpoints.usersProfileUpdate);
      expect(fakeOb.lastRequestBody?[Fields.userId], 'user_123');
      expect(fakeOb.lastRequestBody?[Fields.termsAcceptedAt], true);
      expect(
        fakeOb.lastRequestBody?[Fields.termsVersion],
        PolicyVersionValues.defaultVersion,
      );
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      expect(
        () => repository.recordTermsAcceptance(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when API returns failure', () async {
      fakeOb.requestResponse = {'success': false, 'error': 'Some error'};

      expect(
        () => repository.recordTermsAcceptance(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseUserRepository - setDefaultBuyerAddress', () {
    test('sets default and clears others', () async {
      final doc = _FakeDocument('addr_1', {Fields.userId: 'user_123'});
      final docRef = _FakeDocumentRef(id: 'addr_1', doc: doc);
      fakeOb.addressesCollection.setDoc('addr_1', docRef);

      await repository.setDefaultBuyerAddress('addr_1');

      expect(docRef.lastUpdateData?[Fields.isDefault], true);
    });

    test('throws when address not found', () {
      expect(
        () => repository.setDefaultBuyerAddress('nonexistent'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when address belongs to different user', () {
      final doc = _FakeDocument('addr_1', {Fields.userId: 'other_user'});
      fakeOb.addressesCollection.setDoc('addr_1', _FakeDocumentRef(doc: doc));

      expect(
        () => repository.setDefaultBuyerAddress('addr_1'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = '';

      expect(
        () => repository.setDefaultBuyerAddress('addr_1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseUserRepository - updateBuyerAddress', () {
    test('updates address when owned by user', () async {
      final doc = _FakeDocument('addr_1', {Fields.userId: 'user_123'});
      final docRef = _FakeDocumentRef(id: 'addr_1', doc: doc);
      fakeOb.addressesCollection.setDoc('addr_1', docRef);

      final address = Address(
        street: '789 Updated St',
        city: 'Vancouver',
        state: 'BC',
        postalCode: 'V6B 1A1',
        country: 'Canada',
        isDefault: false,
      );

      await repository.updateBuyerAddress('addr_1', address);

      expect(docRef.lastUpdateData, isNotNull);
      expect(docRef.lastUpdateData?['street'], '789 Updated St');
      expect(docRef.lastUpdateData?['city'], 'Vancouver');
    });

    test('sets default and clears others when isDefault=true', () async {
      final doc = _FakeDocument('addr_1', {Fields.userId: 'user_123'});
      final docRef = _FakeDocumentRef(id: 'addr_1', doc: doc);
      fakeOb.addressesCollection.setDoc('addr_1', docRef);
      fakeOb.addressesCollection.queryDocs = [doc];

      final address = Address(
        street: '789 Updated St',
        city: 'Vancouver',
        state: 'BC',
        postalCode: 'V6B 1A1',
        country: 'Canada',
        isDefault: true,
      );

      await repository.updateBuyerAddress('addr_1', address);

      expect(docRef.lastUpdateData?['isDefault'], true);
    });

    test('throws when address not found', () {
      final address = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M',
        country: 'Canada',
      );

      expect(
        () => repository.updateBuyerAddress('nonexistent', address),
        throwsA(isA<Exception>()),
      );
    });

    test('throws when not authenticated', () {
      fakeOb.authValue.currentUserIdValue = null;

      final address = Address(
        street: '123 Main',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M1M',
        country: 'Canada',
      );

      expect(
        () => repository.updateBuyerAddress('addr_1', address),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseUserRepository - updateNotificationPreferences', () {
    test('updates new products preference', () async {
      fakeOb.requestResponse = {'success': true};

      await repository.updateNotificationPreferences(
        'user_123',
        notifyNewProducts: true,
      );

      expect(fakeOb.lastRequestPath, ApiEndpoints.usersNotificationPreferences);
      expect(fakeOb.lastRequestBody?[Fields.userId], 'user_123');
      expect(fakeOb.lastRequestBody?[Fields.notifyNewProducts], true);
    });

    test('updates trending preference', () async {
      fakeOb.requestResponse = {'success': true};

      await repository.updateNotificationPreferences(
        'user_123',
        notifyTrending: false,
      );

      expect(fakeOb.lastRequestBody?[Fields.notifyTrending], false);
    });

    test('updates both preferences', () async {
      fakeOb.requestResponse = {'success': true};

      await repository.updateNotificationPreferences(
        'user_123',
        notifyNewProducts: true,
        notifyTrending: false,
      );

      expect(fakeOb.lastRequestBody?[Fields.notifyNewProducts], true);
      expect(fakeOb.lastRequestBody?[Fields.notifyTrending], false);
    });

    test('returns early when no preferences to update', () async {
      await repository.updateNotificationPreferences('user_123');

      expect(fakeOb.lastRequestPath, isNull);
    });

    test('throws when API returns failure', () async {
      fakeOb.requestResponse = {'success': false, 'error': 'Permission denied'};

      expect(
        () => repository.updateNotificationPreferences(
          'user_123',
          notifyNewProducts: true,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseUserRepository - updatePreferredLanguage', () {
    test('sends language update', () async {
      fakeOb.requestResponse = {'success': true};

      await repository.updatePreferredLanguage('user_123', 'fr');

      expect(fakeOb.lastRequestPath, ApiEndpoints.usersProfileUpdate);
      expect(fakeOb.lastRequestBody?[Fields.userId], 'user_123');
      expect(fakeOb.lastRequestBody?[Fields.preferredLanguage], 'fr');
    });

    test('throws when API returns failure', () async {
      fakeOb.requestResponse = {'success': false, 'error': 'Invalid language'};

      expect(
        () => repository.updatePreferredLanguage('user_123', 'invalid'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('OrignaBaseUserRepository - watchAddresses', () {
    test('returns a stream of addresses', () {
      final stream = repository.watchAddresses('user_123');
      expect(stream, isA<Stream<List<Address>>>());
    });
  });

  group('OrignaBaseUserRepository - watchSellerAccountStatus', () {
    test('returns a stream of SellerAccountStatus', () {
      final stream = repository.watchSellerAccountStatus('user_123');
      expect(stream, isA<Stream<SellerAccountStatus>>());
    });
  });

  group('SellerAccountStatus', () {
    test('isComplete when seller and charges enabled', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: true,
        detailsSubmitted: true,
      );
      expect(status.isComplete, true);
      expect(status.isIncomplete, false);
    });

    test('isIncomplete when charges not enabled', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        detailsSubmitted: false,
      );
      expect(status.isIncomplete, true);
      expect(status.isComplete, false);
    });

    test('isPendingVerification when submitted but no charges', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        detailsSubmitted: true,
      );
      expect(status.isPendingVerification, true);
    });

    test('needsIdentityDocuments detects verification requirements', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        pendingRequirements: ['individual.verification.document'],
      );
      expect(status.needsIdentityDocuments, true);
    });

    test('needsIdentityDocuments false for non-verification requirements', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        pendingRequirements: ['external_account'],
      );
      expect(status.needsIdentityDocuments, false);
    });

    test('pendingRequirementsDescription formats requirements', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        pendingRequirements: ['external_account', 'tos_acceptance'],
      );
      expect(status.pendingRequirementsDescription, contains('Bank account'));
      expect(
        status.pendingRequirementsDescription,
        contains('Terms of Service'),
      );
    });

    test(
      'pendingRequirementsDescription returns empty for no requirements',
      () {
        const status = SellerAccountStatus(
          isSeller: true,
          chargesEnabled: false,
        );
        expect(status.pendingRequirementsDescription, '');
      },
    );

    test('pendingRequirementsDescription formats identity doc', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        pendingRequirements: ['verification.document'],
      );
      expect(
        status.pendingRequirementsDescription,
        contains('Identity document'),
      );
    });

    test('pendingRequirementsDescription formats SIN', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        pendingRequirements: ['individual.id_number'],
      );
      expect(
        status.pendingRequirementsDescription,
        contains('Social Insurance Number'),
      );
    });

    test('pendingRequirementsDescription formats business info', () {
      const status = SellerAccountStatus(
        isSeller: true,
        chargesEnabled: false,
        pendingRequirements: ['business_profile'],
      );
      expect(
        status.pendingRequirementsDescription,
        contains('Business information'),
      );
    });
  });
}
