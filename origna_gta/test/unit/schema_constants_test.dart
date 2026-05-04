import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';

void main() {
  group('SchemaRegistry', () {
    test('getTimestampField returns createdAt for known collections', () {
      expect(
        SchemaRegistry.getTimestampField(Collections.users),
        Fields.createdAt,
      );
      expect(
        SchemaRegistry.getTimestampField(Collections.products),
        Fields.dateCreated,
      );
      expect(
        SchemaRegistry.getTimestampField(Collections.orders),
        Fields.createdAt,
      );
      expect(
        SchemaRegistry.getTimestampField(Collections.payouts),
        Fields.createdAt,
      );
      expect(
        SchemaRegistry.getTimestampField(Collections.cart),
        Fields.dateCreated,
      );
    });

    test(
      'getTimestampField returns createdAt default for unknown collection',
      () {
        expect(
          SchemaRegistry.getTimestampField('unknown_collection'),
          Fields.createdAt,
        );
      },
    );
  });

  group('SubcategoryConstants', () {
    test('forCategoryId returns subcategories for valid IDs', () {
      final electronics = SubcategoryConstants.forCategoryId(1);
      expect(electronics, isNotEmpty);
      expect(electronics, contains('Smartphones'));
      expect(electronics, contains('Laptops'));

      final gaming = SubcategoryConstants.forCategoryId(3);
      expect(gaming, contains('Consoles'));
      expect(gaming, contains('Video Games'));

      final books = SubcategoryConstants.forCategoryId(14);
      expect(books, contains('Fiction'));
      expect(books, contains('Non-Fiction'));
    });

    test('forCategoryId returns empty list for invalid ID', () {
      expect(SubcategoryConstants.forCategoryId(999), isEmpty);
      expect(SubcategoryConstants.forCategoryId(0), isEmpty);
      expect(SubcategoryConstants.forCategoryId(-1), isEmpty);
    });
  });

  group('BusinessRules constants', () {
    test('has expected values', () {
      expect(BusinessRules.platformFeePercent, 2.5);
      expect(BusinessRules.returnWindowDays, 30);
      expect(BusinessRules.defaultCurrency, 'cad');
      expect(BusinessRules.freeShippingThresholdCents, 7500);
      expect(BusinessRules.minCheckoutTotalCents, 100);
      expect(BusinessRules.maxCouponDiscountRatio, 0.95);
      expect(BusinessRules.premiumSubscriptionPriceCents, 786);
    });

    test('taxRates has all provinces', () {
      expect(BusinessRules.taxRates, contains('AB'));
      expect(BusinessRules.taxRates['NS']!['HST'], 14.0);
      expect(BusinessRules.taxRates['QC']!['GST'], 5.0);
      expect(BusinessRules.taxRates['QC']!['QST'], 9.975);
    });
  });

  group('Enum value classes', () {
    test('DeliveryStatusValues has all values', () {
      expect(DeliveryStatusValues.pending, 'pending');
      expect(DeliveryStatusValues.shipped, 'shipped');
      expect(DeliveryStatusValues.delivered, 'delivered');
      expect(DeliveryStatusValues.refunded, 'refunded');
      expect(DeliveryStatusValues.all.length, 4);
    });

    test('OrderStatusValues has valid transitions', () {
      expect(
        OrderStatusValues.validTransitions[OrderStatusValues.pending],
        contains(OrderStatusValues.confirmed),
      );
      expect(
        OrderStatusValues.validTransitions[OrderStatusValues.delivered],
        contains(OrderStatusValues.disputed),
      );
      expect(
        OrderStatusValues.validTransitions[OrderStatusValues.cancelled],
        isEmpty,
      );
    });

    test('OrderStatusValues terminal states', () {
      expect(
        OrderStatusValues.terminalStates,
        contains(OrderStatusValues.cancelled),
      );
      expect(
        OrderStatusValues.terminalStates,
        contains(OrderStatusValues.refunded),
      );
    });

    test('PaymentStatusValues has all values', () {
      expect(PaymentStatusValues.all, contains('awaiting_payment'));
      expect(PaymentStatusValues.all, contains('captured'));
      expect(PaymentStatusValues.all, contains('voided'));
    });

    test('CarrierValues has all carriers', () {
      expect(CarrierValues.all, contains('ups'));
      expect(CarrierValues.all, contains('fedex'));
      expect(CarrierValues.all, contains('canada_post'));
      expect(CarrierValues.all.length, 8);
    });

    test('UserRoleValues has all roles', () {
      expect(UserRoleValues.all, contains('admin'));
      expect(UserRoleValues.all, contains('seller'));
      expect(UserRoleValues.all, contains('buyer'));
    });

    test('ProvinceCodeValues has all provinces', () {
      expect(ProvinceCodeValues.canadaProvinces.length, 13);
      expect(ProvinceCodeValues.all.length, 13);
      expect(ProvinceCodeValues.names[ProvinceCodeValues.ontario], 'Ontario');
      expect(ProvinceCodeValues.names[ProvinceCodeValues.quebec], 'Quebec');
    });

    test('NotificationTypes has all types', () {
      expect(NotificationTypes.all, contains('order_status'));
      expect(NotificationTypes.all, contains('return_request'));
      expect(NotificationTypes.all, contains('back_in_stock'));
    });

    test('ReturnStatusValues has all statuses', () {
      expect(ReturnStatusValues.requested, 'requested');
      expect(ReturnStatusValues.approved, 'approved');
      expect(ReturnStatusValues.refunded, 'refunded');
      expect(ReturnStatusValues.escalated, 'escalated');
    });

    test('DigitalTypeValues has correct values', () {
      expect(DigitalTypeValues.all, contains('software'));
      expect(DigitalTypeValues.all, contains('book'));
    });

    test('SubscriptionStatusValues premium active set', () {
      expect(SubscriptionStatusValues.premiumActive, contains('active'));
      expect(SubscriptionStatusValues.premiumActive, contains('trialing'));
    });

    test('SupplierTypeValues international set', () {
      expect(SupplierTypeValues.international, contains('aliexpress'));
      expect(SupplierTypeValues.international, contains('temu'));
      expect(SupplierTypeValues.international, isNot(contains('local')));
    });
  });

  group('Collections constants', () {
    test('has expected collection names', () {
      expect(Collections.users, 'users');
      expect(Collections.products, 'products');
      expect(Collections.orders, 'orders');
      expect(Collections.returnRequests, 'return_requests');
      expect(Collections.chats, 'chats');
      expect(Collections.coupons, 'coupons');
    });
  });

  group('ApiEndpoints constants', () {
    test('has expected endpoint paths', () {
      expect(ApiEndpoints.connectCreateAccount, '/api/connect/create-account');
      expect(ApiEndpoints.connectAccountLink, '/api/connect/account-link');
      expect(ApiEndpoints.ordersCreateReturn, '/api/orders/returns/create');
      expect(ApiEndpoints.checkoutSession, '/api/checkout/session');
      expect(ApiEndpoints.adminMfaVerify, '/api/admin/mfa/verify');
    });
  });

  group('Fields constants', () {
    test('has expected field names', () {
      expect(Fields.createdAt, 'createdAt');
      expect(Fields.orderId, 'orderId');
      expect(Fields.productId, 'productId');
      expect(Fields.subtotalCents, 'subtotalCents');
      expect(Fields.returnId, 'returnId');
      expect(Fields.returnReason, 'returnReason');
    });
  });

  group('EmailConfig constants', () {
    test('has CASL compliance fields', () {
      expect(EmailConfig.supportEmail, contains('@'));
      expect(EmailConfig.physicalAddress, isNotEmpty);
      expect(EmailConfig.gstHstNumber, isNotEmpty);
      expect(EmailConfig.unsubscribeUrl, startsWith('https://'));
    });
  });

  group('ExternalUrls constants', () {
    test('has correct URLs', () {
      expect(ExternalUrls.stripeDashboard, contains('stripe.com'));
      expect(ExternalUrls.geoapifyBase, contains('geoapify.com'));
    });
  });

  group('DeepLinkParams constants', () {
    test('has expected param keys', () {
      expect(DeepLinkParams.mode, 'mode');
      expect(DeepLinkParams.oobCode, 'oobCode');
      expect(DeepLinkParams.sessionId, 'session_id');
      expect(DeepLinkParams.modeResetPassword, 'resetPassword');
    });
  });
}
