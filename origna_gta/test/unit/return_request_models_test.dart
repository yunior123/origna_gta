import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/models/generated/return_request_models.dart';

void main() {
  group('ReturnRequest Model - fromJson/toJson', () {
    final baseJson = {
      'returnId': 'ret_001',
      'orderId': 'ord_001',
      'orderItemId': 'item_001',
      'buyerId': 'buyer_001',
      'sellerId': 'seller_001',
      'productId': 'prod_001',
      'productName': 'Test Product',
      'quantity': 2,
      'returnStatus': 'requested',
      'returnReason': 'defective',
      'requestedAt': '2026-01-15T10:30:00.000Z',
      'updatedAt': '2026-01-16T12:00:00.000Z',
    };

    test('fromJson creates valid ReturnRequest', () {
      final request = ReturnRequest.fromJson(baseJson);

      expect(request.returnId, 'ret_001');
      expect(request.orderId, 'ord_001');
      expect(request.orderItemId, 'item_001');
      expect(request.buyerId, 'buyer_001');
      expect(request.sellerId, 'seller_001');
      expect(request.productId, 'prod_001');
      expect(request.productName, 'Test Product');
      expect(request.quantity, 2);
      expect(request.returnStatus, 'requested');
      expect(request.returnReason, 'defective');
      expect(request.requestedAt, DateTime.parse('2026-01-15T10:30:00.000Z'));
      expect(request.updatedAt, DateTime.parse('2026-01-16T12:00:00.000Z'));
    });

    test('toJson serializes all fields', () {
      final request = ReturnRequest.fromJson(baseJson);
      final json = request.toJson();

      expect(json['returnId'], 'ret_001');
      expect(json['orderId'], 'ord_001');
      expect(json['orderItemId'], 'item_001');
      expect(json['buyerId'], 'buyer_001');
      expect(json['sellerId'], 'seller_001');
      expect(json['productId'], 'prod_001');
      expect(json['productName'], 'Test Product');
      expect(json['quantity'], 2);
      expect(json['returnStatus'], 'requested');
      expect(json['returnReason'], 'defective');
      expect(json['requestedAt'], '2026-01-15T10:30:00.000Z');
    });

    test('fromJson handles optional fields', () {
      final json = {
        ...baseJson,
        'returnAdminNote': 'Admin approved',
        'returnTrackingNumber': 'TRACK123',
        'returnRefundAmountCents': 2500,
        'resolvedAt': '2026-01-20T08:00:00.000Z',
        'escalatedAt': '2026-01-18T14:00:00.000Z',
        'escalationReason': 'Buyer dispute',
      };

      final request = ReturnRequest.fromJson(json);

      expect(request.returnAdminNote, 'Admin approved');
      expect(request.returnTrackingNumber, 'TRACK123');
      expect(request.returnRefundAmountCents, 2500);
      expect(request.resolvedAt, DateTime.parse('2026-01-20T08:00:00.000Z'));
      expect(request.escalatedAt, DateTime.parse('2026-01-18T14:00:00.000Z'));
      expect(request.escalationReason, 'Buyer dispute');
    });

    test('fromJson handles null optional fields', () {
      final minimalJson = {
        'returnId': 'ret_002',
        'orderId': 'ord_002',
        'orderItemId': 'item_002',
        'buyerId': 'buyer_002',
        'sellerId': 'seller_002',
        'productId': 'prod_002',
        'productName': 'Another Product',
        'returnReason': 'wrong_item',
      };

      final request = ReturnRequest.fromJson(minimalJson);

      expect(request.returnAdminNote, isNull);
      expect(request.returnTrackingNumber, isNull);
      expect(request.returnRefundAmountCents, isNull);
      expect(request.requestedAt, isNull);
      expect(request.updatedAt, isNull);
      expect(request.resolvedAt, isNull);
      expect(request.escalatedAt, isNull);
      expect(request.escalationReason, isNull);
      expect(request.quantity, 1);
      expect(request.returnStatus, 'requested');
    });

    test('toJson roundtrip preserves data', () {
      final original = ReturnRequest.fromJson(baseJson);
      final json = original.toJson();
      final restored = ReturnRequest.fromJson(json);

      expect(restored.returnId, original.returnId);
      expect(restored.orderId, original.orderId);
      expect(restored.quantity, original.quantity);
      expect(restored.returnReason, original.returnReason);
    });

    test('toJson serializes optional fields as null when absent', () {
      final minimal = ReturnRequest.fromJson({
        'returnId': 'r1',
        'orderId': 'o1',
        'orderItemId': 'i1',
        'buyerId': 'b1',
        'sellerId': 's1',
        'productId': 'p1',
        'productName': 'P',
        'returnReason': 'other',
      });

      final json = minimal.toJson();
      expect(json['returnAdminNote'], isNull);
      expect(json['returnTrackingNumber'], isNull);
      expect(json['returnRefundAmountCents'], isNull);
      expect(json['requestedAt'], isNull);
      expect(json['resolvedAt'], isNull);
      expect(json['escalatedAt'], isNull);
      expect(json['escalationReason'], isNull);
    });
  });

  group('ReturnRequest Model - fromMap', () {
    test('fromMap parses cartItemId with fallback to orderItemId', () {
      final mapWithCartItemId = {
        'orderId': 'ord_003',
        'cartItemId': 'cart_123',
        'buyerId': 'buyer_003',
        'sellerId': 'seller_003',
        'productId': 'prod_003',
        'productName': 'Map Product',
        'returnReason': 'changed_mind',
      };

      final request = ReturnRequest.fromMap(mapWithCartItemId, 'ret_from_map');
      expect(request.returnId, 'ret_from_map');
      expect(request.orderItemId, 'cart_123');
    });

    test('fromMap falls back to orderItemId when cartItemId missing', () {
      final mapWithOrderItemId = {
        'orderId': 'ord_004',
        'orderItemId': 'oi_456',
        'buyerId': 'buyer_004',
        'sellerId': 'seller_004',
        'productId': 'prod_004',
        'productName': 'Fallback Product',
        'returnReason': 'not_as_described',
      };

      final request = ReturnRequest.fromMap(mapWithOrderItemId, 'ret_fallback');
      expect(request.orderItemId, 'oi_456');
    });

    test('fromMap uses defaults for missing fields', () {
      final emptyMap = <String, dynamic>{};

      final request = ReturnRequest.fromMap(emptyMap, 'ret_defaults');

      expect(request.returnId, 'ret_defaults');
      expect(request.orderId, '');
      expect(request.orderItemId, '');
      expect(request.buyerId, '');
      expect(request.sellerId, '');
      expect(request.productId, '');
      expect(request.productName, '');
      expect(request.quantity, 1);
      expect(request.returnStatus, 'requested');
      expect(request.returnReason, '');
    });

    test('fromMap parses numeric quantity as num', () {
      final map = {
        'orderId': 'ord_005',
        'orderItemId': 'item_005',
        'buyerId': 'buyer_005',
        'sellerId': 'seller_005',
        'productId': 'prod_005',
        'productName': 'Num Product',
        'returnReason': 'damaged_in_shipping',
        'quantity': 3,
        'returnRefundAmountCents': 5000,
      };

      final request = ReturnRequest.fromMap(map, 'ret_num');
      expect(request.quantity, 3);
      expect(request.returnRefundAmountCents, 5000);
    });

    test('fromMap parses DateTime from string', () {
      final map = {
        'orderId': 'ord_006',
        'orderItemId': 'item_006',
        'buyerId': 'buyer_006',
        'sellerId': 'seller_006',
        'productId': 'prod_006',
        'productName': 'Date Product',
        'returnReason': 'other',
        'requestedAt': '2026-02-01T10:00:00.000Z',
        'updatedAt': '2026-02-02T11:00:00.000Z',
        'resolvedAt': '2026-02-05T12:00:00.000Z',
        'escalatedAt': '2026-02-03T09:00:00.000Z',
      };

      final request = ReturnRequest.fromMap(map, 'ret_dates');
      expect(request.requestedAt, DateTime.parse('2026-02-01T10:00:00.000Z'));
      expect(request.updatedAt, DateTime.parse('2026-02-02T11:00:00.000Z'));
      expect(request.resolvedAt, DateTime.parse('2026-02-05T12:00:00.000Z'));
      expect(request.escalatedAt, DateTime.parse('2026-02-03T09:00:00.000Z'));
    });

    test('fromMap parses DateTime from int milliseconds', () {
      final dt = DateTime(2026, 3, 15, 10, 30);
      final map = {
        'orderId': 'ord_007',
        'orderItemId': 'item_007',
        'buyerId': 'buyer_007',
        'sellerId': 'seller_007',
        'productId': 'prod_007',
        'productName': 'Int Date Product',
        'returnReason': 'other',
        'requestedAt': dt.millisecondsSinceEpoch,
      };

      final request = ReturnRequest.fromMap(map, 'ret_int_date');
      expect(request.requestedAt, isNotNull);
      expect(request.requestedAt!.year, 2026);
      expect(request.requestedAt!.month, 3);
      expect(request.requestedAt!.day, 15);
    });

    test('fromMap parses DateTime from DateTime object', () {
      final dt = DateTime(2026, 4, 20, 14, 30);
      final map = {
        'orderId': 'ord_008',
        'orderItemId': 'item_008',
        'buyerId': 'buyer_008',
        'sellerId': 'seller_008',
        'productId': 'prod_008',
        'productName': 'DateTime Object Product',
        'returnReason': 'other',
        'requestedAt': dt,
      };

      final request = ReturnRequest.fromMap(map, 'ret_datetime');
      expect(request.requestedAt, dt);
    });

    test('fromMap handles all optional string fields', () {
      final map = {
        'orderId': 'ord_009',
        'orderItemId': 'item_009',
        'buyerId': 'buyer_009',
        'sellerId': 'seller_009',
        'productId': 'prod_009',
        'productName': 'Optional Fields Product',
        'returnReason': 'quality_issue',
        'returnAdminNote': 'Reviewed by manager',
        'returnTrackingNumber': 'TRK999',
        'escalationReason': 'No response from seller',
      };

      final request = ReturnRequest.fromMap(map, 'ret_optional');
      expect(request.returnAdminNote, 'Reviewed by manager');
      expect(request.returnTrackingNumber, 'TRK999');
      expect(request.escalationReason, 'No response from seller');
    });

    test('fromMap handles null values gracefully', () {
      final map = {
        'orderId': 'ord_010',
        'orderItemId': 'item_010',
        'buyerId': 'buyer_010',
        'sellerId': 'seller_010',
        'productId': 'prod_010',
        'productName': 'Null Values Product',
        'returnReason': 'other',
        'returnAdminNote': null,
        'returnTrackingNumber': null,
        'returnRefundAmountCents': null,
        'requestedAt': null,
      };

      final request = ReturnRequest.fromMap(map, 'ret_null');
      expect(request.returnAdminNote, isNull);
      expect(request.returnTrackingNumber, isNull);
      expect(request.returnRefundAmountCents, isNull);
      expect(request.requestedAt, isNull);
    });
  });

  group('ReturnRequest Model - copyWith', () {
    test('copyWith creates modified copy', () {
      final request = ReturnRequest.fromJson({
        'returnId': 'ret_copy',
        'orderId': 'ord_copy',
        'orderItemId': 'item_copy',
        'buyerId': 'buyer_copy',
        'sellerId': 'seller_copy',
        'productId': 'prod_copy',
        'productName': 'Copy Product',
        'returnReason': 'defective',
      });

      final modified = request.copyWith(
        returnStatus: 'approved',
        returnAdminNote: 'Approved by admin',
      );

      expect(modified.returnStatus, 'approved');
      expect(modified.returnAdminNote, 'Approved by admin');
      expect(modified.returnId, request.returnId);
      expect(modified.orderId, request.orderId);
    });

    test('copyWith preserves unchanged fields', () {
      final original = ReturnRequest(
        returnId: 'ret_preserve',
        orderId: 'ord_preserve',
        orderItemId: 'item_preserve',
        buyerId: 'buyer_preserve',
        sellerId: 'seller_preserve',
        productId: 'prod_preserve',
        productName: 'Preserve Product',
        quantity: 5,
        returnStatus: 'requested',
        returnReason: 'wrong_item',
        returnAdminNote: 'Original note',
        requestedAt: DateTime(2026, 1, 1),
      );

      final modified = original.copyWith(returnStatus: 'processing');

      expect(modified.returnId, original.returnId);
      expect(modified.orderId, original.orderId);
      expect(modified.orderItemId, original.orderItemId);
      expect(modified.buyerId, original.buyerId);
      expect(modified.sellerId, original.sellerId);
      expect(modified.productId, original.productId);
      expect(modified.productName, original.productName);
      expect(modified.quantity, original.quantity);
      expect(modified.returnReason, original.returnReason);
      expect(modified.returnAdminNote, original.returnAdminNote);
      expect(modified.requestedAt, original.requestedAt);
      expect(modified.returnStatus, 'processing');
    });

    test('copyWith can set previously null fields', () {
      final original = ReturnRequest(
        returnId: 'ret_set',
        orderId: 'ord_set',
        orderItemId: 'item_set',
        buyerId: 'buyer_set',
        sellerId: 'seller_set',
        productId: 'prod_set',
        productName: 'Set Product',
        returnReason: 'defective',
      );

      final modified = original.copyWith(
        returnAdminNote: 'New note',
        returnTrackingNumber: 'TRK123',
        returnRefundAmountCents: 5000,
        resolvedAt: DateTime(2026, 3, 1),
      );

      expect(modified.returnAdminNote, 'New note');
      expect(modified.returnTrackingNumber, 'TRK123');
      expect(modified.returnRefundAmountCents, 5000);
      expect(modified.resolvedAt, DateTime(2026, 3, 1));
    });

    test('copyWith can update quantity', () {
      final original = ReturnRequest(
        returnId: 'ret_qty',
        orderId: 'ord_qty',
        orderItemId: 'item_qty',
        buyerId: 'buyer_qty',
        sellerId: 'seller_qty',
        productId: 'prod_qty',
        productName: 'Qty Product',
        returnReason: 'defective',
        quantity: 1,
      );

      final modified = original.copyWith(quantity: 3);

      expect(modified.quantity, 3);
      expect(original.quantity, 1);
    });

    test('copyWith can clear optional fields to null', () {
      final original = ReturnRequest(
        returnId: 'ret_clear',
        orderId: 'ord_clear',
        orderItemId: 'item_clear',
        buyerId: 'buyer_clear',
        sellerId: 'seller_clear',
        productId: 'prod_clear',
        productName: 'Clear Product',
        returnReason: 'defective',
        returnAdminNote: 'To be cleared',
        returnTrackingNumber: 'TRK999',
      );

      final modified = original.copyWith(
        returnAdminNote: null,
        returnTrackingNumber: null,
      );

      expect(modified.returnAdminNote, isNull);
      expect(modified.returnTrackingNumber, isNull);
    });
  });

  group('ReturnRequest Model - Equality', () {
    test('equality works correctly', () {
      final a = ReturnRequest.fromJson({
        'returnId': 'ret_eq',
        'orderId': 'ord_eq',
        'orderItemId': 'item_eq',
        'buyerId': 'buyer_eq',
        'sellerId': 'seller_eq',
        'productId': 'prod_eq',
        'productName': 'Eq Product',
        'returnReason': 'defective',
      });
      final b = ReturnRequest.fromJson({
        'returnId': 'ret_eq',
        'orderId': 'ord_eq',
        'orderItemId': 'item_eq',
        'buyerId': 'buyer_eq',
        'sellerId': 'seller_eq',
        'productId': 'prod_eq',
        'productName': 'Eq Product',
        'returnReason': 'defective',
      });

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different returnIds are not equal', () {
      final a = ReturnRequest.fromJson({
        'returnId': 'ret_diff_a',
        'orderId': 'ord_same',
        'orderItemId': 'item_same',
        'buyerId': 'buyer_same',
        'sellerId': 'seller_same',
        'productId': 'prod_same',
        'productName': 'Same Product',
        'returnReason': 'defective',
      });
      final b = ReturnRequest.fromJson({
        'returnId': 'ret_diff_b',
        'orderId': 'ord_same',
        'orderItemId': 'item_same',
        'buyerId': 'buyer_same',
        'sellerId': 'seller_same',
        'productId': 'prod_same',
        'productName': 'Same Product',
        'returnReason': 'defective',
      });

      expect(a, isNot(equals(b)));
    });

    test('different quantities are not equal', () {
      final a = ReturnRequest(
        returnId: 'ret_qty_eq',
        orderId: 'ord_qty',
        orderItemId: 'item_qty',
        buyerId: 'buyer_qty',
        sellerId: 'seller_qty',
        productId: 'prod_qty',
        productName: 'Qty Product',
        returnReason: 'defective',
        quantity: 1,
      );
      final b = ReturnRequest(
        returnId: 'ret_qty_eq',
        orderId: 'ord_qty',
        orderItemId: 'item_qty',
        buyerId: 'buyer_qty',
        sellerId: 'seller_qty',
        productId: 'prod_qty',
        productName: 'Qty Product',
        returnReason: 'defective',
        quantity: 2,
      );

      expect(a, isNot(equals(b)));
    });

    test('different returnStatus are not equal', () {
      final a = ReturnRequest(
        returnId: 'ret_status',
        orderId: 'ord_status',
        orderItemId: 'item_status',
        buyerId: 'buyer_status',
        sellerId: 'seller_status',
        productId: 'prod_status',
        productName: 'Status Product',
        returnReason: 'defective',
        returnStatus: 'requested',
      );
      final b = ReturnRequest(
        returnId: 'ret_status',
        orderId: 'ord_status',
        orderItemId: 'item_status',
        buyerId: 'buyer_status',
        sellerId: 'seller_status',
        productId: 'prod_status',
        productName: 'Status Product',
        returnReason: 'defective',
        returnStatus: 'approved',
      );

      expect(a, isNot(equals(b)));
    });

    test('identical references are equal', () {
      final request = ReturnRequest(
        returnId: 'ret_identical',
        orderId: 'ord_identical',
        orderItemId: 'item_identical',
        buyerId: 'buyer_identical',
        sellerId: 'seller_identical',
        productId: 'prod_identical',
        productName: 'Identical Product',
        returnReason: 'defective',
      );

      expect(request, equals(request));
    });
  });

  group('ReturnRequest Model - toString', () {
    test('toString includes all fields', () {
      final request = ReturnRequest(
        returnId: 'ret_tostr',
        orderId: 'ord_tostr',
        orderItemId: 'item_tostr',
        buyerId: 'buyer_tostr',
        sellerId: 'seller_tostr',
        productId: 'prod_tostr',
        productName: 'ToString Product',
        quantity: 2,
        returnStatus: 'requested',
        returnReason: 'defective',
      );

      final str = request.toString();

      expect(str, contains('ReturnRequest'));
      expect(str, contains('ret_tostr'));
      expect(str, contains('ord_tostr'));
      expect(str, contains('buyer_tostr'));
      expect(str, contains('seller_tostr'));
      expect(str, contains('prod_tostr'));
      expect(str, contains('ToString Product'));
      expect(str, contains('defective'));
    });
  });

  group('ReturnRequest Model - Factory Constructors', () {
    test('factory constructor with all parameters', () {
      final request = ReturnRequest(
        returnId: 'ret_factory',
        orderId: 'ord_factory',
        orderItemId: 'item_factory',
        buyerId: 'buyer_factory',
        sellerId: 'seller_factory',
        productId: 'prod_factory',
        productName: 'Factory Product',
        quantity: 3,
        returnStatus: 'approved',
        returnReason: 'not_as_described',
        returnAdminNote: 'Approved',
        returnTrackingNumber: 'TRK456',
        returnRefundAmountCents: 7500,
        requestedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        resolvedAt: DateTime(2026, 1, 3),
        escalatedAt: DateTime(2026, 1, 2, 12),
        escalationReason: 'Disputed',
      );

      expect(request.returnId, 'ret_factory');
      expect(request.orderId, 'ord_factory');
      expect(request.orderItemId, 'item_factory');
      expect(request.buyerId, 'buyer_factory');
      expect(request.sellerId, 'seller_factory');
      expect(request.productId, 'prod_factory');
      expect(request.productName, 'Factory Product');
      expect(request.quantity, 3);
      expect(request.returnStatus, 'approved');
      expect(request.returnReason, 'not_as_described');
      expect(request.returnAdminNote, 'Approved');
      expect(request.returnTrackingNumber, 'TRK456');
      expect(request.returnRefundAmountCents, 7500);
      expect(request.requestedAt, DateTime(2026, 1, 1));
      expect(request.updatedAt, DateTime(2026, 1, 2));
      expect(request.resolvedAt, DateTime(2026, 1, 3));
      expect(request.escalatedAt, DateTime(2026, 1, 2, 12));
      expect(request.escalationReason, 'Disputed');
    });

    test('factory constructor with defaults', () {
      final request = ReturnRequest(
        returnId: 'ret_defaults',
        orderId: 'ord_defaults',
        orderItemId: 'item_defaults',
        buyerId: 'buyer_defaults',
        sellerId: 'seller_defaults',
        productId: 'prod_defaults',
        productName: 'Defaults Product',
        returnReason: 'other',
      );

      expect(request.quantity, 1);
      expect(request.returnStatus, 'requested');
      expect(request.returnAdminNote, isNull);
      expect(request.returnTrackingNumber, isNull);
      expect(request.returnRefundAmountCents, isNull);
      expect(request.requestedAt, isNull);
      expect(request.updatedAt, isNull);
      expect(request.resolvedAt, isNull);
      expect(request.escalatedAt, isNull);
      expect(request.escalationReason, isNull);
    });
  });

  group('ReturnRequest Model - Default Values', () {
    test('quantity defaults to 1', () {
      final request = ReturnRequest.fromJson({
        'returnId': 'r1',
        'orderId': 'o1',
        'orderItemId': 'i1',
        'buyerId': 'b1',
        'sellerId': 's1',
        'productId': 'p1',
        'productName': 'P',
        'returnReason': 'r',
      });

      expect(request.quantity, 1);
    });

    test('returnStatus defaults to requested', () {
      final request = ReturnRequest.fromJson({
        'returnId': 'r1',
        'orderId': 'o1',
        'orderItemId': 'i1',
        'buyerId': 'b1',
        'sellerId': 's1',
        'productId': 'p1',
        'productName': 'P',
        'returnReason': 'r',
      });

      expect(request.returnStatus, 'requested');
    });

    test('returnStatus can be set to other values', () {
      final request = ReturnRequest(
        returnId: 'r1',
        orderId: 'o1',
        orderItemId: 'i1',
        buyerId: 'b1',
        sellerId: 's1',
        productId: 'p1',
        productName: 'P',
        returnReason: 'r',
        returnStatus: 'approved',
      );

      expect(request.returnStatus, 'approved');
    });

    test('quantity can be set to other values', () {
      final request = ReturnRequest(
        returnId: 'r1',
        orderId: 'o1',
        orderItemId: 'i1',
        buyerId: 'b1',
        sellerId: 's1',
        productId: 'p1',
        productName: 'P',
        returnReason: 'r',
        quantity: 10,
      );

      expect(request.quantity, 10);
    });
  });
}
