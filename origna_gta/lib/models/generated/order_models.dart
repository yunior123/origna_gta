// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';
import 'product_models.dart';

part 'order_models.freezed.dart';
part 'order_models.g.dart';

/// Safely parse a dynamic value (Timestamp, String, DateTime) to DateTime?
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Safely convert any Firestore value to String (handles MiniFieldValue, int, etc.)
String _safeString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

/// Safely convert to double
double _safeDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely convert to int
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely convert to bool
bool _safeBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Safely convert to List of String
List<String> _safeStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) return value.map((e) => _safeString(e)).toList();
  return [];
}

/// Safely parse a Map from dynamic (handles Firestore internal types)
Map<String, dynamic> _safeMap(dynamic value) {
  if (value == null) return {};
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

/// Parse an Address from any dynamic Firestore value
Address _safeAddress(dynamic value) {
  final map = _safeMap(value);
  return Address(
    street: _safeString(map['street']),
    apartment: _safeString(map['apartment']),
    city: _safeString(map['city']),
    state: _safeString(map['state']),
    postalCode: _safeString(map['postalCode']),
    country: _safeString(map['country'], 'Canada'),
    phoneNumber: map['phoneNumber'] != null ? _safeString(map['phoneNumber']) : null,
    isDefault: _safeBool(map['isDefault']),
    label: map['label'] != null ? _safeString(map['label']) : null,
    latitude: map['latitude'] != null ? _safeDouble(map['latitude']) : null,
    longitude: map['longitude'] != null ? _safeDouble(map['longitude']) : null,
  );
}

/// Parse an OrderItem from a Firestore map without relying on generated fromJson
OrderItem _parseOrderItem(dynamic raw) {
  final map = _safeMap(raw);
  return OrderItem(
    productId: _safeString(map['productId']),
    name: _safeString(map['name']),
    description: _safeString(map['description']),
    price: _safeDouble(map['price']),
    quantity: _safeInt(map['quantity'], 1),
    imageUrls: _safeStringList(map['imageUrls']),
    sellerId: _safeString(map['sellerId']),
    sellerAddress: _safeAddress(map['sellerAddress']),
    status: _safeString(
      (map['status'] == null || map['status'].toString().isEmpty)
          ? map['deliveryStatus']
          : map['status'],
      'pending',
    ),
    deliveryStatus: _parseDeliveryStatus(map['deliveryStatus']),
    trackingNumber: map['trackingNumber'] != null ? _safeString(map['trackingNumber']) : null,
    carrier: map['carrier'] != null ? _safeString(map['carrier']) : null,
    shippedAt: _parseDateTime(map['shippedAt']),
    deliveredAt: _parseDateTime(map['deliveredAt']),
    refundedAt: _parseDateTime(map['refundedAt']),
    refundReason: map['refundReason'] != null ? _safeString(map['refundReason']) : null,
    refundAmountCents: map['refundAmountCents'] != null ? _safeInt(map['refundAmountCents']) : null,
    refundId: map['refundId'] != null ? _safeString(map['refundId']) : null,
    confirmedByBuyer: _safeBool(map['confirmedByBuyer'] ?? map['buyerConfirmed']),
    weightKg: map['weightKg'] != null ? _safeDouble(map['weightKg']) : null,
    lengthCm: map['lengthCm'] != null ? _safeDouble(map['lengthCm']) : null,
    widthCm: map['widthCm'] != null ? _safeDouble(map['widthCm']) : null,
    heightCm: map['heightCm'] != null ? _safeDouble(map['heightCm']) : null,
    isLocalDeliveryOnly: _safeBool(map['isLocalDeliveryOnly'] ?? map['localDeliveryOnly']),
    isPerishable: _safeBool(map['isPerishable'] ?? map['perishable']),
    estimatedShipDays: _safeInt(map['estimatedShipDays'] ?? map['supplierShippingDays'], 3),
    minimumOrderQuantity: _safeInt(map['minimumOrderQuantity'] ?? map['minOrderQuantity'], 1),
    freeShipping: _safeBool(map['freeShipping']),
    isDigital: _safeBool(map['isDigital']),
  );
}

/// Parse DeliveryStatus from dynamic
DeliveryStatus _parseDeliveryStatus(dynamic raw) {
  final value = _safeString(raw, 'pending');
  switch (value) {
    case 'shipped':
      return DeliveryStatus.shipped;
    case 'delivered':
      return DeliveryStatus.delivered;
    default:
      return DeliveryStatus.pending;
  }
}

/// Parse Ratings from a Firestore map without relying on generated fromJson
Ratings _parseRating(dynamic raw) {
  final map = _safeMap(raw);
  return Ratings(
    productId: _safeString(map['productId']),
    rating: _safeDouble(map['rating']),
    review: map['review'] != null ? _safeString(map['review']) : null,
    createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
  );
}

// ============================================================================
// ORDER
// ============================================================================

@Freezed(toJson: true, fromJson: true)
class Order with _$Order {
  const factory Order({
    required String orderId,
    required String userId,
    required String customerId,
    required String customerEmail,
    required List<OrderItem> items,
    // All money in integer cents
    required int totalAmountCents,
    required int subtotalCents,
    @Default(0) int shippingCostCents,
    @Default(0) int taxAmountCents,
    required Taxes taxes,
    @Default(OrderStatus.pending) OrderStatus orderStatus,
    @Default(PaymentStatus.awaitingPayment) PaymentStatus paymentStatus,
    required Address shippingAddress,
    required DateTime createdAt,
    @Default('cad') String currency,
    @Default([]) List<String> sellerIds,
    required String stripeSessionId,
    // Shipping approval
    @Default(ShippingApprovalStatus.notRequired) ShippingApprovalStatus shippingApprovalStatus,
    @Default(false) bool shippingApprovalRequired,
    @Default(0.0) double actualShipping,
    @Default(0.0) double pendingTotal,
    // Payout tracking
    @Default([]) List<SellerPayout> sellerPayouts,
    @Default(false) bool confirmedByClient,
    DateTime? confirmedAt,
    @Default(0.0) double platformFeeTotal,
    @Default('pending') String payoutStatus,
    // Ratings
    @Default([]) List<Ratings> ratings,
  }) = _Order;

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    OrderStatus parseOrderStatus(dynamic raw) {
      final value = raw?.toString();
      switch (value) {
        case 'pending':
          return OrderStatus.pending;
        case 'confirmed':
          return OrderStatus.confirmed;
        case 'processing':
          return OrderStatus.processing;
        case 'shipped':
          return OrderStatus.shipped;
        case 'in_transit':
          return OrderStatus.inTransit;
        case 'delivered':
          return OrderStatus.delivered;
        case 'cancelled':
          return OrderStatus.cancelled;
        case 'failed':
          return OrderStatus.failed;
        case 'expired':
          return OrderStatus.expired;
        case 'refunded':
          return OrderStatus.refunded;
        case 'partially_refunded':
          return OrderStatus.partiallyRefunded;
        default:
          return OrderStatus.pending;
      }
    }

    PaymentStatus parsePaymentStatus(dynamic raw) {
      final value = raw?.toString();
      switch (value) {
        case 'awaiting_payment':
          return PaymentStatus.awaitingPayment;
        case 'processing':
          return PaymentStatus.processing;
        case 'paid':
          return PaymentStatus.paid;
        case 'authorized':
          return PaymentStatus.authorized;
        case 'captured':
          return PaymentStatus.captured;
        case 'payment_failed':
          return PaymentStatus.paymentFailed;
        case 'refunded':
          return PaymentStatus.refunded;
        case 'session_expired':
          return PaymentStatus.sessionExpired;
        default:
          return PaymentStatus.awaitingPayment;
      }
    }

    ShippingApprovalStatus parseShippingApprovalStatus(dynamic raw) {
      final value = raw?.toString();
      switch (value) {
        case 'not_required':
          return ShippingApprovalStatus.notRequired;
        case 'pending':
          return ShippingApprovalStatus.pending;
        case 'approved':
          return ShippingApprovalStatus.approved;
        case 'rejected':
          return ShippingApprovalStatus.rejected;
        default:
          return ShippingApprovalStatus.notRequired;
      }
    }

    // Parse items — use safe parser, NOT generated fromJson (avoids hard casts)
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final items = itemsData.map(_parseOrderItem).toList();

    // Parse taxes
    final taxesData = data['taxes'];
    final taxes = taxesData is Map ? Taxes.fromMap(Map<String, dynamic>.from(taxesData)) : const Taxes();

    // Parse seller payouts — use safe parser
    final payoutsData = data['sellerPayouts'] as List<dynamic>? ?? [];
    final payouts = payoutsData.map((p) => SellerPayout.fromMap(_safeMap(p))).toList();

    // Parse ratings — use safe parser
    final ratingsData = data['ratings'];
    final ratings = ratingsData is List ? ratingsData.map(_parseRating).toList() : <Ratings>[];

    // Money — all cents
    final totalAmountCents = _safeInt(data['totalAmountCents']);
    final subtotalCents = _safeInt(data['subtotalCents']);
    final shippingCostCents = _safeInt(data['shippingCostCents']);
    final taxAmountCents = _safeInt(data['taxAmountCents']);

    // Address
    final rawAddress = _safeMap(data['shippingAddress']);

    return Order(
      orderId: _safeString(data['orderId'], doc.id),
      userId: _safeString(data['userId']),
      customerId: _safeString(data['customerId']),
      customerEmail: _safeString(data['customerEmail']),
      items: items,
      totalAmountCents: totalAmountCents,
      subtotalCents: subtotalCents,
      shippingCostCents: shippingCostCents,
      taxAmountCents: taxAmountCents,
      taxes: taxes,
      orderStatus: parseOrderStatus(data['orderStatus']),
      paymentStatus: parsePaymentStatus(data['paymentStatus']),
      shippingAddress: _safeAddress(rawAddress),
      createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
      currency: _safeString(data['currency'], 'cad'),
      sellerIds: _safeStringList(data['sellerIds']),
      stripeSessionId: _safeString(data['stripeSessionId']),
      shippingApprovalStatus: parseShippingApprovalStatus(data['shippingApprovalStatus']),
      shippingApprovalRequired: _safeBool(data['shippingApprovalRequired']),
      actualShipping: _safeDouble(data['actualShipping']),
      pendingTotal: _safeDouble(data['pendingTotal']),
      sellerPayouts: payouts,
      confirmedByClient: _safeBool(data['confirmedByClient']),
      confirmedAt: _parseDateTime(data['confirmedAt']),
      platformFeeTotal: _safeDouble(data['platformFeeTotal']),
      payoutStatus: _safeString(data['payoutStatus'], 'pending'),
      ratings: ratings,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  const Order._();

  /// Total in dollars (derived from cents)
  double get total => totalAmountCents / 100.0;

  /// Subtotal in dollars (derived from cents)
  double get subtotal => subtotalCents / 100.0;

  /// Shipping in dollars (derived from cents)
  double get shippingCost => shippingCostCents / 100.0;

  /// Tax in dollars (derived from cents)
  double get taxAmount => taxAmountCents / 100.0;
}

// ============================================================================
// ORDER CREATE
// ============================================================================

@freezed
class OrderCreate with _$OrderCreate {
  const factory OrderCreate({
    required String userId,
    required String customerId,
    required String customerEmail,
    required List<OrderItem> items,
    required Address shippingAddress,
    @Default(0.0) double shippingCost,
    @Default('cad') String currency,
    @Default(false) bool shippingApprovalRequired,
  }) = _OrderCreate;

  factory OrderCreate.fromJson(Map<String, dynamic> json) => _$OrderCreateFromJson(json);
}

// ============================================================================
// ORDER ITEM
// ============================================================================

@Freezed(toJson: true, fromJson: true)
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int quantity,
    required List<String> imageUrls,
    required String sellerId,
    required Address sellerAddress,
    // Per-item status tracking (NEW)
    @Default('pending') String status, // 'pending' | 'shipped' | 'delivered' | 'refunded'
    @Default(DeliveryStatus.pending) DeliveryStatus deliveryStatus, // DEPRECATED: backwards compatibility
    String? trackingNumber,
    String? carrier,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? refundedAt,
    String? refundReason,
    int? refundAmountCents,
    String? refundId,
    @Default(false) bool confirmedByBuyer,
    // Shipping metadata
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    @Default(false) bool isLocalDeliveryOnly,
    @Default(false) bool isPerishable,
    @Default(3) int estimatedShipDays,
    @Default([]) List<SellerDeliveryOption> deliveryOptions,
    @Default(1) int minimumOrderQuantity,
    @Default(false) bool freeShipping,
    @Default(false) bool isDigital,
  }) = _OrderItem;

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

  const OrderItem._();

  /// Calculate item subtotal
  double get subtotal => price * quantity;
}

// ============================================================================
// RATINGS
// ============================================================================

@freezed
class Ratings with _$Ratings {
  const factory Ratings({required String productId, required double rating, String? review, required DateTime createdAt}) = _Ratings;

  factory Ratings.fromJson(Map<String, dynamic> json) => _$RatingsFromJson(json);
}

// ============================================================================
// SELLER PAYOUT
// ============================================================================

@freezed
class SellerPayout with _$SellerPayout {
  const factory SellerPayout({
    required String sellerId,
    String? stripeAccountId,
    required int amountCents,
    required int platformFeeCents,
    required int netAmountCents,
    @Default('pending') String status,
    DateTime? payoutDate,
    String? stripeTransferId,
    String? failureReason,
  }) = _SellerPayout;

  factory SellerPayout.fromJson(Map<String, dynamic> json) => _$SellerPayoutFromJson(json);

  factory SellerPayout.fromMap(Map<String, dynamic> map) {
    return SellerPayout(
      sellerId: _safeString(map['sellerId']),
      stripeAccountId: map['stripeAccountId'] != null ? _safeString(map['stripeAccountId']) : null,
      amountCents: _safeInt(map['amountCents']),
      platformFeeCents: _safeInt(map['platformFeeCents']),
      netAmountCents: _safeInt(map['netAmountCents']),
      status: _safeString(map['status'], 'pending'),
      payoutDate: _parseDateTime(map['payoutDate']),
      stripeTransferId: map['stripeTransferId'] != null ? _safeString(map['stripeTransferId']) : null,
      failureReason: map['failureReason'] != null ? _safeString(map['failureReason']) : null,
    );
  }

  const SellerPayout._();

  /// Amount in dollars
  double get amount => amountCents / 100.0;

  /// Platform fee in dollars
  double get platformFee => platformFeeCents / 100.0;

  /// Net amount in dollars
  double get netAmount => netAmountCents / 100.0;
}

// ============================================================================
// TAXES
// ============================================================================

@freezed
class Taxes with _$Taxes {
  const factory Taxes({@Default(0.0) double gst, @Default(0.0) double pst, @Default(0.0) double hst, @Default(0.0) double qst}) = _Taxes;

  factory Taxes.fromJson(Map<String, dynamic> json) {
    return Taxes(
      gst: (json['gst'] ?? json['GST'] ?? 0.0).toDouble(),
      pst: (json['pst'] ?? json['PST'] ?? 0.0).toDouble(),
      hst: (json['hst'] ?? json['HST'] ?? 0.0).toDouble(),
      qst: (json['qst'] ?? json['QST'] ?? 0.0).toDouble(),
    );
  }

  factory Taxes.fromMap(Map<String, dynamic> map) =>
      Taxes(gst: (map['GST'] ?? 0.0).toDouble(), pst: (map['PST'] ?? 0.0).toDouble(), hst: (map['HST'] ?? 0.0).toDouble(), qst: (map['QST'] ?? 0.0).toDouble());

  const Taxes._();

  /// Calculate total tax amount
  double get total => gst + pst + hst + qst;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {'GST': gst, 'PST': pst, 'HST': hst, 'QST': qst};

  /// Convert to Map
  Map<String, double> toMap() => {'GST': gst, 'PST': pst, 'HST': hst, 'QST': qst};
}
