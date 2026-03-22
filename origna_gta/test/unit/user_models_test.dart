import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/generated/user_models.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  group('User Model - Serialization', () {
    final baseJson = {
      'uid': 'user_001',
      'email': 'test@example.com',
      'name': 'Test User',
      'roles': ['buyer'],
      'createdAt': '2024-01-15T10:30:00.000Z',
    };

    test('fromJson creates valid User with minimal fields', () {
      final user = User.fromJson(baseJson);

      expect(user.uid, 'user_001');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.roles, [UserRole.buyer]);
      expect(user.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
    });

    test('fromJson creates valid User with all fields', () {
      final json = {
        ...baseJson,
        'address': {
          'street': '123 Main St',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M5V 1A1',
          'country': 'Canada',
        },
        'customerId': 'cus_abc123',
        'lastCheckoutSession': 'cs_test_123',
        'lastOrderId': 'ord_123',
        'lastCheckoutTimestamp': '2024-02-20T14:00:00.000Z',
        'isSeller': true,
        'suspended': false,
        'suspendedAt': null,
        'updatedAt': '2024-03-01T09:00:00.000Z',
        'paymentProvider': 'stripe',
        'unsuspendedAt': null,
        'suspendedBy': null,
        'suspensionReason': null,
        'taxExemption': {'type': 'business', 'id': 'TX123'},
        'mfaEnabled': true,
        'mfaEnrolledAt': '2024-01-20T08:00:00.000Z',
        'lastMfaVerify': '2024-03-15T12:00:00.000Z',
        'emailConsent': true,
        'marketingOptIn': true,
        'consentTimestamp': '2024-01-15T10:30:00.000Z',
        'consentMethod': 'signup',
        'privacyAcceptedAt': '2024-01-15T10:30:00.000Z',
        'termsAcceptedAt': '2024-01-15T10:30:00.000Z',
        'privacyPolicyVersion': '2.0',
        'termsVersion': '2.0',
        'preferredLanguage': 'en',
        'unsubscribedAt': null,
        'dataProcessingConsent': true,
        'isPremium': true,
        'premiumSince': '2024-02-01T00:00:00.000Z',
        'premiumExpiresAt': '2025-02-01T00:00:00.000Z',
        'stripeSubscriptionId': 'sub_xyz789',
        'notifyNewProducts': true,
        'notifyTrending': true,
        'pushEnabled': true,
        'fcmToken': 'fcm_token_abc123',
        'fcmTokenUpdatedAt': '2024-03-10T10:00:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.uid, 'user_001');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.roles, [UserRole.buyer]);
      expect(user.address?.street, '123 Main St');
      expect(user.address?.city, 'Toronto');
      expect(user.customerId, 'cus_abc123');
      expect(user.lastCheckoutSession, 'cs_test_123');
      expect(user.lastOrderId, 'ord_123');
      expect(
        user.lastCheckoutTimestamp,
        DateTime.parse('2024-02-20T14:00:00.000Z'),
      );
      expect(user.isSeller, true);
      expect(user.suspended, false);
      expect(user.suspendedAt, isNull);
      expect(user.updatedAt, DateTime.parse('2024-03-01T09:00:00.000Z'));
      expect(user.paymentProvider, 'stripe');
      expect(user.mfaEnabled, true);
      expect(user.mfaEnrolledAt, DateTime.parse('2024-01-20T08:00:00.000Z'));
      expect(user.lastMfaVerify, DateTime.parse('2024-03-15T12:00:00.000Z'));
      expect(user.emailConsent, true);
      expect(user.marketingOptIn, true);
      expect(user.consentTimestamp, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(user.consentMethod, 'signup');
      expect(
        user.privacyAcceptedAt,
        DateTime.parse('2024-01-15T10:30:00.000Z'),
      );
      expect(user.termsAcceptedAt, DateTime.parse('2024-01-15T10:30:00.000Z'));
      expect(user.privacyPolicyVersion, '2.0');
      expect(user.termsVersion, '2.0');
      expect(user.preferredLanguage, 'en');
      expect(user.dataProcessingConsent, true);
      expect(user.isPremium, true);
      expect(user.premiumSince, DateTime.parse('2024-02-01T00:00:00.000Z'));
      expect(user.premiumExpiresAt, DateTime.parse('2025-02-01T00:00:00.000Z'));
      expect(user.stripeSubscriptionId, 'sub_xyz789');
      expect(user.notifyNewProducts, true);
      expect(user.notifyTrending, true);
      expect(user.pushEnabled, true);
      expect(user.fcmToken, 'fcm_token_abc123');
      expect(
        user.fcmTokenUpdatedAt,
        DateTime.parse('2024-03-10T10:00:00.000Z'),
      );
      expect(user.taxExemption, {'type': 'business', 'id': 'TX123'});
    });

    test('toJson serializes all fields correctly', () {
      final user = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test User',
        roles: [UserRole.buyer, UserRole.seller],
        createdAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        address: Address(
          street: '123 Main St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V 1A1',
          country: 'Canada',
        ),
        customerId: 'cus_abc123',
        lastCheckoutSession: 'cs_test_123',
        lastOrderId: 'ord_123',
        lastCheckoutTimestamp: DateTime.parse('2024-02-20T14:00:00.000Z'),
        isSeller: true,
        suspended: true,
        suspendedAt: DateTime.parse('2024-03-01T09:00:00.000Z'),
        updatedAt: DateTime.parse('2024-03-02T09:00:00.000Z'),
        paymentProvider: 'stripe',
        unsuspendedAt: DateTime.parse('2024-04-01T09:00:00.000Z'),
        suspendedBy: 'admin_001',
        suspensionReason: 'Policy violation',
        taxExemption: {'type': 'business'},
        mfaEnabled: true,
        mfaEnrolledAt: DateTime.parse('2024-01-20T08:00:00.000Z'),
        lastMfaVerify: DateTime.parse('2024-03-15T12:00:00.000Z'),
        emailConsent: true,
        marketingOptIn: true,
        consentTimestamp: DateTime.parse('2024-01-15T10:30:00.000Z'),
        consentMethod: 'signup',
        privacyAcceptedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        termsAcceptedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
        privacyPolicyVersion: '2.0',
        termsVersion: '2.0',
        preferredLanguage: 'fr',
        unsubscribedAt: DateTime.parse('2024-06-01T00:00:00.000Z'),
        dataProcessingConsent: true,
        isPremium: true,
        premiumSince: DateTime.parse('2024-02-01T00:00:00.000Z'),
        premiumExpiresAt: DateTime.parse('2025-02-01T00:00:00.000Z'),
        stripeSubscriptionId: 'sub_xyz789',
        notifyNewProducts: true,
        notifyTrending: false,
        pushEnabled: true,
        fcmToken: 'fcm_token_abc123',
        fcmTokenUpdatedAt: DateTime.parse('2024-03-10T10:00:00.000Z'),
      );

      final json = user.toJson();

      expect(json['uid'], 'user_001');
      expect(json['email'], 'test@example.com');
      expect(json['name'], 'Test User');
      expect(json['roles'], ['buyer', 'seller']);
      expect(json['createdAt'], '2024-01-15T10:30:00.000Z');
      expect(json['address'], isNotNull);
      expect(json['customerId'], 'cus_abc123');
      expect(json['lastCheckoutSession'], 'cs_test_123');
      expect(json['lastOrderId'], 'ord_123');
      expect(json['lastCheckoutTimestamp'], '2024-02-20T14:00:00.000Z');
      expect(json['isSeller'], true);
      expect(json['suspended'], true);
      expect(json['suspendedAt'], '2024-03-01T09:00:00.000Z');
      expect(json['updatedAt'], '2024-03-02T09:00:00.000Z');
      expect(json['paymentProvider'], 'stripe');
      expect(json['unsuspendedAt'], '2024-04-01T09:00:00.000Z');
      expect(json['suspendedBy'], 'admin_001');
      expect(json['suspensionReason'], 'Policy violation');
      expect(json['taxExemption'], {'type': 'business'});
      expect(json['mfaEnabled'], true);
      expect(json['mfaEnrolledAt'], '2024-01-20T08:00:00.000Z');
      expect(json['lastMfaVerify'], '2024-03-15T12:00:00.000Z');
      expect(json['emailConsent'], true);
      expect(json['marketingOptIn'], true);
      expect(json['consentTimestamp'], '2024-01-15T10:30:00.000Z');
      expect(json['consentMethod'], 'signup');
      expect(json['privacyAcceptedAt'], '2024-01-15T10:30:00.000Z');
      expect(json['termsAcceptedAt'], '2024-01-15T10:30:00.000Z');
      expect(json['privacyPolicyVersion'], '2.0');
      expect(json['termsVersion'], '2.0');
      expect(json['preferredLanguage'], 'fr');
      expect(json['unsubscribedAt'], '2024-06-01T00:00:00.000Z');
      expect(json['dataProcessingConsent'], true);
      expect(json['isPremium'], true);
      expect(json['premiumSince'], '2024-02-01T00:00:00.000Z');
      expect(json['premiumExpiresAt'], '2025-02-01T00:00:00.000Z');
      expect(json['stripeSubscriptionId'], 'sub_xyz789');
      expect(json['notifyNewProducts'], true);
      expect(json['notifyTrending'], false);
      expect(json['pushEnabled'], true);
      expect(json['fcmToken'], 'fcm_token_abc123');
      expect(json['fcmTokenUpdatedAt'], '2024-03-10T10:00:00.000Z');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'uid': 'user_002',
        'email': 'minimal@example.com',
        'name': 'Minimal User',
        'roles': ['buyer'],
        'createdAt': '2024-01-15T10:30:00.000Z',
      };

      final user = User.fromJson(json);

      expect(user.address, isNull);
      expect(user.customerId, isNull);
      expect(user.lastCheckoutSession, isNull);
      expect(user.lastOrderId, isNull);
      expect(user.lastCheckoutTimestamp, isNull);
      expect(user.isSeller, false);
      expect(user.suspended, false);
      expect(user.suspendedAt, isNull);
      expect(user.updatedAt, isNull);
      expect(user.paymentProvider, isNull);
      expect(user.unsuspendedAt, isNull);
      expect(user.suspendedBy, isNull);
      expect(user.suspensionReason, isNull);
      expect(user.taxExemption, isNull);
      expect(user.mfaEnabled, false);
      expect(user.mfaEnrolledAt, isNull);
      expect(user.lastMfaVerify, isNull);
      expect(user.emailConsent, true);
      expect(user.marketingOptIn, false);
      expect(user.consentTimestamp, isNull);
      expect(user.consentMethod, isNull);
      expect(user.privacyAcceptedAt, isNull);
      expect(user.termsAcceptedAt, isNull);
      expect(user.privacyPolicyVersion, isNull);
      expect(user.termsVersion, isNull);
      expect(user.preferredLanguage, 'en');
      expect(user.unsubscribedAt, isNull);
      expect(user.dataProcessingConsent, false);
      expect(user.isPremium, false);
      expect(user.premiumSince, isNull);
      expect(user.premiumExpiresAt, isNull);
      expect(user.stripeSubscriptionId, isNull);
      expect(user.notifyNewProducts, false);
      expect(user.notifyTrending, false);
      expect(user.pushEnabled, true);
      expect(user.fcmToken, isNull);
      expect(user.fcmTokenUpdatedAt, isNull);
    });

    test('toJson roundtrip preserves data', () {
      final json = {
        'uid': 'user_rt',
        'email': 'roundtrip@example.com',
        'name': 'Roundtrip User',
        'roles': ['seller'],
        'createdAt': '2024-05-15T10:30:00.000Z',
        'address': {
          'street': '456 Oak Ave',
          'apartment': '',
          'city': 'Vancouver',
          'state': 'BC',
          'postalCode': 'V6B 1A1',
          'country': 'Canada',
        },
        'customerId': 'cus_rt',
        'mfaEnabled': true,
        'isPremium': true,
        'premiumSince': '2024-06-01T00:00:00.000Z',
      };

      final original = User.fromJson(json);
      final restored = User.fromJson(original.toJson());

      expect(restored.uid, original.uid);
      expect(restored.email, original.email);
      expect(restored.name, original.name);
      expect(restored.roles, original.roles);
      expect(restored.createdAt, original.createdAt);
      expect(restored.address?.street, original.address?.street);
      expect(restored.address?.city, original.address?.city);
      expect(restored.customerId, original.customerId);
      expect(restored.mfaEnabled, original.mfaEnabled);
      expect(restored.isPremium, original.isPremium);
      expect(restored.premiumSince, original.premiumSince);
    });
  });

  group('User Model - fromMap', () {
    test('fromMap creates User from database map', () {
      final map = {
        Fields.uid: 'user_map',
        Fields.email: 'map@example.com',
        Fields.name: 'Map User',
        Fields.roles: ['buyer', 'seller'],
        Fields.createdAt: DateTime(2024, 3, 15),
        Fields.customerId: 'cus_map',
        Fields.suspended: true,
        Fields.suspendedAt: DateTime(2024, 4, 1),
        Fields.mfaEnabled: true,
        Fields.isPremium: true,
      };

      final user = User.fromMap(map, 'doc_001');

      expect(user.uid, 'user_map');
      expect(user.email, 'map@example.com');
      expect(user.name, 'Map User');
      expect(user.roles, [UserRole.buyer, UserRole.seller]);
      expect(user.customerId, 'cus_map');
      expect(user.suspended, true);
      expect(user.mfaEnabled, true);
      expect(user.isPremium, true);
    });

    test('fromMap uses docId when uid missing', () {
      final map = {
        Fields.email: 'nouid@example.com',
        Fields.name: 'No Uid',
        Fields.roles: ['buyer'],
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final user = User.fromMap(map, 'doc_fallback');

      expect(user.uid, 'doc_fallback');
    });

    test('fromMap parses roles from strings', () {
      final map = {
        Fields.roles: ['admin', 'seller', 'buyer'],
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final user = User.fromMap(map, 'u1');

      expect(user.roles, [UserRole.admin, UserRole.seller, UserRole.buyer]);
    });

    test('fromMap handles invalid role strings', () {
      final map = {
        Fields.roles: ['invalid_role', 'buyer'],
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final user = User.fromMap(map, 'u1');

      expect(user.roles.length, 2);
      expect(user.roles, contains(UserRole.buyer));
    });

    test('fromMap defaults roles to buyer when missing', () {
      final map = {Fields.createdAt: DateTime(2024, 1, 1)};

      final user = User.fromMap(map, 'u1');

      expect(user.roles, [UserRole.buyer]);
    });

    test('fromMap parses DateTime from various formats', () {
      final stringDateMap = {Fields.createdAt: '2024-03-15T10:30:00.000Z'};
      final intDateMap = {
        Fields.createdAt: DateTime(2024, 3, 15).millisecondsSinceEpoch,
      };
      final dateTimeMap = {Fields.createdAt: DateTime(2024, 3, 15)};

      final stringUser = User.fromMap(stringDateMap, 'u1');
      final intUser = User.fromMap(intDateMap, 'u2');
      final dateTimeUser = User.fromMap(dateTimeMap, 'u3');

      expect(stringUser.createdAt.year, 2024);
      expect(intUser.createdAt.year, 2024);
      expect(dateTimeUser.createdAt.year, 2024);
    });

    test('fromMap parses Address from nested map', () {
      final map = {
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.address: {
          Fields.street: '789 Pine St',
          Fields.city: 'Montreal',
          Fields.state: 'QC',
          Fields.postalCode: 'H2X 1Y4',
          Fields.country: 'Canada',
        },
      };

      final user = User.fromMap(map, 'u1');

      expect(user.address, isNotNull);
      expect(user.address?.street, '789 Pine St');
      expect(user.address?.city, 'Montreal');
      expect(user.address?.state, 'QC');
      expect(user.address?.postalCode, 'H2X 1Y4');
    });

    test('fromMap sets isSeller from roles', () {
      final sellerMap = {
        Fields.roles: ['seller'],
        Fields.createdAt: DateTime(2024, 1, 1),
      };
      final buyerMap = {
        Fields.roles: ['buyer'],
        Fields.createdAt: DateTime(2024, 1, 1),
      };

      final seller = User.fromMap(sellerMap, 's1');
      final buyer = User.fromMap(buyerMap, 'b1');

      expect(seller.isSeller, true);
      expect(buyer.isSeller, false);
    });

    test('fromMap parses all consent fields', () {
      final map = {
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.emailConsent: false,
        Fields.marketingOptIn: true,
        Fields.consentTimestamp: DateTime(2024, 2, 1),
        Fields.consentMethod: 'checkbox',
        Fields.privacyAcceptedAt: DateTime(2024, 1, 15),
        Fields.termsAcceptedAt: DateTime(2024, 1, 15),
        Fields.privacyPolicyVersion: '3.0',
        Fields.termsVersion: '3.0',
        Fields.preferredLanguage: 'fr',
        Fields.dataProcessingConsent: true,
      };

      final user = User.fromMap(map, 'u1');

      expect(user.emailConsent, false);
      expect(user.marketingOptIn, true);
      expect(user.consentTimestamp, DateTime(2024, 2, 1));
      expect(user.consentMethod, 'checkbox');
      expect(user.privacyAcceptedAt, DateTime(2024, 1, 15));
      expect(user.termsAcceptedAt, DateTime(2024, 1, 15));
      expect(user.privacyPolicyVersion, '3.0');
      expect(user.termsVersion, '3.0');
      expect(user.preferredLanguage, 'fr');
      expect(user.dataProcessingConsent, true);
    });

    test('fromMap parses premium subscription fields', () {
      final map = {
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.isPremium: true,
        Fields.premiumSince: DateTime(2024, 5, 1),
        Fields.premiumExpiresAt: DateTime(2025, 5, 1),
        Fields.stripeSubscriptionId: 'sub_premium',
        Fields.notifyNewProducts: true,
        Fields.notifyTrending: true,
      };

      final user = User.fromMap(map, 'u1');

      expect(user.isPremium, true);
      expect(user.premiumSince, DateTime(2024, 5, 1));
      expect(user.premiumExpiresAt, DateTime(2025, 5, 1));
      expect(user.stripeSubscriptionId, 'sub_premium');
      expect(user.notifyNewProducts, true);
      expect(user.notifyTrending, true);
    });

    test('fromMap parses FCM fields', () {
      final map = {
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.fcmToken: 'fcm_abc123',
        Fields.fcmTokenUpdatedAt: DateTime(2024, 6, 1),
        Fields.pushEnabled: false,
      };

      final user = User.fromMap(map, 'u1');

      expect(user.fcmToken, 'fcm_abc123');
      expect(user.fcmTokenUpdatedAt, DateTime(2024, 6, 1));
      expect(user.pushEnabled, false);
    });

    test('fromMap parses taxExemption map', () {
      final map = {
        Fields.createdAt: DateTime(2024, 1, 1),
        Fields.taxExemption: {'type': 'GST', 'number': '12345'},
      };

      final user = User.fromMap(map, 'u1');

      expect(user.taxExemption, isNotNull);
      expect(user.taxExemption?['type'], 'GST');
      expect(user.taxExemption?['number'], '12345');
    });
  });

  group('User Model - copyWith', () {
    test('copyWith creates new instance with updated fields', () {
      final original = User(
        uid: 'user_001',
        email: 'original@example.com',
        name: 'Original Name',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        name: 'Updated Name',
        email: 'updated@example.com',
      );

      expect(updated.uid, 'user_001');
      expect(updated.name, 'Updated Name');
      expect(updated.email, 'updated@example.com');
      expect(original.name, 'Original Name');
    });

    test('copyWith preserves unchanged fields', () {
      final original = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test User',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        customerId: 'cus_123',
        isPremium: true,
      );

      final updated = original.copyWith(name: 'New Name');

      expect(updated.uid, original.uid);
      expect(updated.email, original.email);
      expect(updated.roles, original.roles);
      expect(updated.createdAt, original.createdAt);
      expect(updated.customerId, original.customerId);
      expect(updated.isPremium, original.isPremium);
    });

    test('copyWith can update nested Address', () {
      final original = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
        address: Address(
          street: '123 Old St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V',
          country: 'Canada',
        ),
      );

      final updated = original.copyWith(
        address: Address(
          street: '456 New St',
          city: 'Vancouver',
          state: 'BC',
          postalCode: 'V6B',
          country: 'Canada',
        ),
      );

      expect(updated.address?.street, '456 New St');
      expect(updated.address?.city, 'Vancouver');
      expect(original.address?.street, '123 Old St');
    });

    test('copyWith can set address to null', () {
      final original = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
        address: Address(
          street: '123 St',
          city: 'Toronto',
          state: 'ON',
          postalCode: 'M5V',
          country: 'Canada',
        ),
      );

      final updated = original.copyWith(address: null);

      expect(updated.address, isNull);
    });

    test('copyWith updates premium fields', () {
      final original = User(
        uid: 'u1',
        email: 'e@e.com',
        name: 'User',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        isPremium: true,
        premiumSince: DateTime(2024, 6, 1),
        stripeSubscriptionId: 'sub_new',
      );

      expect(updated.isPremium, true);
      expect(updated.premiumSince, DateTime(2024, 6, 1));
      expect(updated.stripeSubscriptionId, 'sub_new');
    });

    test('copyWith updates consent fields', () {
      final original = User(
        uid: 'u1',
        email: 'e@e.com',
        name: 'User',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        marketingOptIn: true,
        consentTimestamp: DateTime(2024, 7, 1),
        preferredLanguage: 'fr',
      );

      expect(updated.marketingOptIn, true);
      expect(updated.consentTimestamp, DateTime(2024, 7, 1));
      expect(updated.preferredLanguage, 'fr');
    });
  });

  group('User Model - Equality', () {
    test('equal users have same hashCode', () {
      final user1 = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test User',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      final user2 = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test User',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 15, 10, 30),
      );

      expect(user1, equals(user2));
      expect(user1.hashCode, equals(user2.hashCode));
    });

    test('different users are not equal', () {
      final user1 = User(
        uid: 'user_001',
        email: 'test1@example.com',
        name: 'Test User',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      final user2 = User(
        uid: 'user_002',
        email: 'test2@example.com',
        name: 'Test User',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user1, isNot(equals(user2)));
    });

    test('users with different roles are not equal', () {
      final user1 = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      final user2 = User(
        uid: 'user_001',
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(user1, isNot(equals(user2)));
    });
  });

  group('User Model - Getters', () {
    test('canSell returns true for admin', () {
      final admin = User(
        uid: 'admin_001',
        email: 'admin@example.com',
        name: 'Admin',
        roles: [UserRole.admin],
        createdAt: DateTime(2024, 1, 1),
        isSeller: true,
      );

      expect(admin.canSell, true);
    });

    test('canSell returns true for seller not suspended', () {
      final seller = User(
        uid: 'seller_001',
        email: 'seller@example.com',
        name: 'Seller',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        suspended: false,
        isSeller: true,
      );

      expect(seller.canSell, true);
    });

    test('canSell returns false for suspended seller', () {
      final suspended = User(
        uid: 'seller_002',
        email: 'suspended@example.com',
        name: 'Suspended',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
        suspended: true,
      );

      expect(suspended.canSell, false);
    });

    test('canSell returns false for buyer', () {
      final buyer = User(
        uid: 'buyer_001',
        email: 'buyer@example.com',
        name: 'Buyer',
        roles: [UserRole.buyer],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(buyer.canSell, false);
    });

    test('isAdmin returns true for admin role', () {
      final admin = User(
        uid: 'admin_001',
        email: 'admin@example.com',
        name: 'Admin',
        roles: [UserRole.admin],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(admin.isAdmin, true);
    });

    test('isAdmin returns false for non-admin', () {
      final seller = User(
        uid: 'seller_001',
        email: 'seller@example.com',
        name: 'Seller',
        roles: [UserRole.seller],
        createdAt: DateTime(2024, 1, 1),
      );

      expect(seller.isAdmin, false);
    });
  });

  group('UserCreate Model', () {
    test('fromJson creates valid UserCreate', () {
      final json = {
        'email': 'newuser@example.com',
        'name': 'New User',
        'roles': ['buyer'],
      };

      final userCreate = UserCreate.fromJson(json);

      expect(userCreate.email, 'newuser@example.com');
      expect(userCreate.name, 'New User');
      expect(userCreate.roles, [UserRole.buyer]);
    });

    test('fromJson defaults roles to buyer', () {
      final json = {'email': 'minimal@example.com', 'name': 'Minimal'};

      final userCreate = UserCreate.fromJson(json);

      expect(userCreate.roles, [UserRole.buyer]);
    });

    test('toJson serializes correctly', () {
      final userCreate = UserCreate(
        email: 'create@example.com',
        name: 'Create User',
        roles: [UserRole.seller],
      );

      final json = userCreate.toJson();

      expect(json['email'], 'create@example.com');
      expect(json['name'], 'Create User');
      expect(json['roles'], ['seller']);
    });

    test('fromJson with address', () {
      final json = {
        'email': 'withaddress@example.com',
        'name': 'With Address',
        'address': {
          'street': '123 St',
          'city': 'Toronto',
          'state': 'ON',
          'postalCode': 'M5V',
          'country': 'Canada',
        },
      };

      final userCreate = UserCreate.fromJson(json);

      expect(userCreate.address, isNotNull);
      expect(userCreate.address?.street, '123 St');
      expect(userCreate.address?.city, 'Toronto');
    });

    test('copyWith creates modified copy', () {
      final original = UserCreate(
        email: 'original@example.com',
        name: 'Original',
        roles: [UserRole.buyer],
      );

      final updated = original.copyWith(name: 'Updated');

      expect(updated.email, 'original@example.com');
      expect(updated.name, 'Updated');
      expect(original.name, 'Original');
    });

    test('equality works correctly', () {
      final a = UserCreate(
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.buyer],
      );
      final b = UserCreate(
        email: 'test@example.com',
        name: 'Test',
        roles: [UserRole.buyer],
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
