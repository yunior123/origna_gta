// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth
// ignore_for_file: non_abstract_class_inherits_abstract_member

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';
import 'product_models.dart';
import '../../core/schema/schema_constants.dart';

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

/// Safely convert to List String
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
    street: _safeString(map[Fields.street]),
    apartment: _safeString(map[Fields.apartment]),
    city: _safeString(map[Fields.city]),
    state: _safeString(map[Fields.state]),
    postalCode: _safeString(map[Fields.postalCode]),
    country: _safeString(map[Fields.country], BusinessRules.allowedShippingCountries.first),
    phoneNumber: map[Fields.phoneNumber] != null ? _safeString(map[Fields.phoneNumber]) : null,
    isDefault: _safeBool(map[Fields.isDefault]),
    label: map[Fields.label] != null ? _safeString(map[Fields.label]) : null,
    latitude: map[Fields.latitude] != null ? _safeDouble(map[Fields.latitude]) : null,
    longitude: map[Fields.longitude] != null ? _safeDouble(map[Fields.longitude]) : null,
  );
}

/// Parse an OrderItem from a Firestore map without relying on generated fromJson
OrderItem _parseOrderItem(dynamic raw) {
  final map = _safeMap(raw);
  return OrderItem(
    productId: _safeString(map[Fields.productId]),
    name: _safeString(map[Fields.name]),
    description: _safeString(map[Fields.description]),
    price: _safeDouble(map[Fields.price]),
    quantity: _safeInt(map[Fields.quantity], 1),
    imageUrls: _safeStringList(map[Fields.imageUrls]),
    sellerId: _safeString(map[Fields.sellerId]),
    sellerAddress: _safeAddress(map[Fields.sellerAddress]),
    status: _safeString(
      (map[Fields.status] == null || map[Fields.status].toString().isEmpty)
          ? map[Fields.deliveryStatus]
          : map[Fields.status],
      DeliveryStatusValues.pending,
    ),
    deliveryStatus: _parseDeliveryStatus(map[Fields.deliveryStatus]),
    trackingNumber: map[Fields.trackingNumber] != null ? _safeString(map[Fields.trackingNumber]) : null,
    carrier: map[Fields.carrier] != null ? _safeString(map[Fields.carrier]) : null,
    shippedAt: _parseDateTime(map[Fields.shippedAt]),
    deliveredAt: _parseDateTime(map[Fields.deliveredAt]),
    refundedAt: _parseDateTime(map[Fields.refundedAt]),
    refundReason: map[Fields.refundReason] != null ? _safeString(map[Fields.refundReason]) : null,
    refundAmountCents: map[Fields.refundAmountCents] != null ? _safeInt(map[Fields.refundAmountCents]) : null,
    refundId: map[Fields.refundId] != null ? _safeString(map[Fields.refundId]) : null,
    confirmedByBuyer: _safeBool(map[Fields.confirmedByBuyer] ?? map[Fields.buyerConfirmed]),
    weightKg: map[Fields.weightKg] != null ? _safeDouble(map[Fields.weightKg]) : null,
    lengthCm: map[Fields.lengthCm] != null ? _safeDouble(map[Fields.lengthCm]) : null,
    widthCm: map[Fields.widthCm] != null ? _safeDouble(map[Fields.widthCm]) : null,
    heightCm: map[Fields.heightCm] != null ? _safeDouble(map[Fields.heightCm]) : null,
    isLocalDeliveryOnly: _safeBool(map[Fields.isLocalDeliveryOnly] ?? map[Fields.localDeliveryOnly]),
    isPerishable: _safeBool(map[Fields.isPerishable] ?? map[Fields.perishable]),
    estimatedShipDays: _safeInt(map[Fields.estimatedShipDays] ?? map[Fields.supplierShippingDays], 3),
    minimumOrderQuantity: _safeInt(map[Fields.minimumOrderQuantity] ?? map[Fields.minOrderQuantity], 1),
    freeShipping: _safeBool(map[Fields.freeShipping]),
    isDigital: _safeBool(map[Fields.isDigital]),
    taxCode: map[Fields.taxCode] != null ? _safeString(map[Fields.taxCode]) : null,
  );
}

/// Parse DeliveryStatus from dynamic
DeliveryStatus _parseDeliveryStatus(dynamic raw) {
  final value = _safeString(raw, DeliveryStatusValues.pending);
  switch (value) {
    case DeliveryStatusValues.shipped:
      return DeliveryStatus.shipped;
    case DeliveryStatusValues.delivered:
      return DeliveryStatus.delivered;
    case DeliveryStatusValues.refunded:
      return DeliveryStatus.refunded;
    default:
      return DeliveryStatus.pending;
  }
}

/// Parse Ratings from a Firestore map without relying on generated fromJson
Ratings _parseRating(dynamic raw) {
  final map = _safeMap(raw);
  return Ratings(
    productId: _safeString(map[Fields.productId]),
    rating: _safeDouble(map[Fields.rating]),
    review: map[Fields.review] != null ? _safeString(map[Fields.review]) : null,
    createdAt: _parseDateTime(map[Fields.createdAt]) ?? DateTime.now(),
  );
}

// ============================================================================
// ORDER
// ============================================================================

@Freezed(toJson: true, fromJson: true)
abstract class Order with _$Order {
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
    @Default(BusinessRules.defaultCurrency) String currency,
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
    @Default(PayoutStatusValues.pending) String payoutStatus,
    // Ratings
    @Default([]) List<Ratings> ratings,
    // === AUDIT FIX: 18 missing fields synced from Python/Firestore ===
    // Payment capture tracking
    String? stripePaymentIntentId,
    @Default(0) int captureAttempts,
    DateTime? capturedAt,
    DateTime? expiresAt,
    @Default(false) bool autoConfirmed,
    @Default(false) bool autoCaptured,
    // Refund tracking
    @Default(0.0) double refundAmount,
    DateTime? refundedAt,
    // Cancellation tracking
    @Default(false) bool stockRestored,
    String? cancelledBy,
    DateTime? cancelledAt,
    String? cancellationReason,
    // Shipping approval
    DateTime? respondedAt,
    double? actualCost,
    // Admin review
    @Default(false) bool requiresManualReview,
    String? manualReviewReason,
    @Default([]) List<String> payoutErrors,
    // Timestamp
    DateTime? updatedAt,
    // Tax fields (new)
    @Default([]) List<Map<String, dynamic>> itemTaxes,
    @Default(false) bool taxExempt,
    Map<String, dynamic>? taxExemption,
    // Delivery instructions from buyer
    String? deliveryInstructions,
  }) = _Order;

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    OrderStatus parseOrderStatus(dynamic raw) {
      final value = raw?.toString();
      switch (value) {
        case OrderStatusValues.pending:
          return OrderStatus.pending;
        case OrderStatusValues.confirmed:
          return OrderStatus.confirmed;
        case OrderStatusValues.processing:
          return OrderStatus.processing;
        case OrderStatusValues.shipped:
          return OrderStatus.shipped;
        case OrderStatusValues.inTransit:
          return OrderStatus.inTransit;
        case OrderStatusValues.delivered:
          return OrderStatus.delivered;
        case OrderStatusValues.cancelled:
          return OrderStatus.cancelled;
        case OrderStatusValues.failed:
          return OrderStatus.failed;
        case OrderStatusValues.expired:
          return OrderStatus.expired;
        case OrderStatusValues.refunded:
          return OrderStatus.refunded;
        case OrderStatusValues.partiallyRefunded:
          return OrderStatus.partiallyRefunded;
        default:
          return OrderStatus.pending;
      }
    }

    PaymentStatus parsePaymentStatus(dynamic raw) {
      final value = raw?.toString();
      switch (value) {
        case PaymentStatusValues.awaitingPayment:
          return PaymentStatus.awaitingPayment;
        case PaymentStatusValues.processing:
          return PaymentStatus.processing;
        case PaymentStatusValues.paid:
          return PaymentStatus.paid;
        case PaymentStatusValues.authorized:
          return PaymentStatus.authorized;
        case PaymentStatusValues.captured:
          return PaymentStatus.captured;
        case PaymentStatusValues.paymentFailed:
          return PaymentStatus.paymentFailed;
        case PaymentStatusValues.refunded:
          return PaymentStatus.refunded;
        case PaymentStatusValues.sessionExpired:
          return PaymentStatus.sessionExpired;
        case PaymentStatusValues.cancelled:
          return PaymentStatus.cancelled;
        case PaymentStatusValues.authorizationExpired:
          return PaymentStatus.authorizationExpired;
        default:
          return PaymentStatus.awaitingPayment;
      }
    }

    ShippingApprovalStatus parseShippingApprovalStatus(dynamic raw) {
      final value = raw?.toString();
      switch (value) {
        case ShippingApprovalStatusValues.notRequired:
          return ShippingApprovalStatus.notRequired;
        case ShippingApprovalStatusValues.pending:
          return ShippingApprovalStatus.pending;
        case ShippingApprovalStatusValues.approved:
          return ShippingApprovalStatus.approved;
        case ShippingApprovalStatusValues.rejected:
          return ShippingApprovalStatus.rejected;
        default:
          return ShippingApprovalStatus.notRequired;
      }
    }

    // Parse items — use safe parser, NOT generated fromJson (avoids hard casts)
    final itemsData = data[Fields.items] as List<dynamic>? ?? [];
    final items = itemsData.map(_parseOrderItem).toList();

    // Parse taxes
    final taxesData = data[Fields.taxes];
    final taxes = taxesData is Map ? Taxes.fromMap(Map<String, dynamic>.from(taxesData)) : const Taxes();

    // Parse seller payouts — use safe parser
    final payoutsData = data[Fields.sellerPayouts] as List<dynamic>? ?? [];
    final payouts = payoutsData.map((p) => SellerPayout.fromMap(_safeMap(p))).toList();

    // Parse ratings — use safe parser
    final ratingsData = data[Fields.ratings];
    final ratings = ratingsData is List ? ratingsData.map(_parseRating).toList() : <Ratings>[];

    // Money — all cents
    final totalAmountCents = _safeInt(data[Fields.totalAmountCents]);
    final subtotalCents = _safeInt(data[Fields.subtotalCents]);
    final shippingCostCents = _safeInt(data[Fields.shippingCostCents]);
    final taxAmountCents = _safeInt(data[Fields.taxAmountCents]);

    // Address
    final rawAddress = _safeMap(data[Fields.shippingAddress]);

    return Order(
      orderId: _safeString(data[Fields.orderId], doc.id),
      userId: _safeString(data[Fields.userId]),
      customerId: _safeString(data[Fields.customerId]),
      customerEmail: _safeString(data[Fields.customerEmail]),
      items: items,
      totalAmountCents: totalAmountCents,
      subtotalCents: subtotalCents,
      shippingCostCents: shippingCostCents,
      taxAmountCents: taxAmountCents,
      taxes: taxes,
      orderStatus: parseOrderStatus(data[Fields.orderStatus]),
      paymentStatus: parsePaymentStatus(data[Fields.paymentStatus]),
      shippingAddress: _safeAddress(rawAddress),
      createdAt: _parseDateTime(data[Fields.createdAt]) ?? DateTime.now(),
      currency: _safeString(data[Fields.currency], BusinessRules.defaultCurrency),
      sellerIds: _safeStringList(data[Fields.sellerIds]),
      stripeSessionId: _safeString(data[Fields.stripeSessionId]),
      shippingApprovalStatus: parseShippingApprovalStatus(data[Fields.shippingApprovalStatus]),
      shippingApprovalRequired: _safeBool(data[Fields.shippingApprovalRequired]),
      actualShipping: _safeDouble(data[Fields.actualShipping]),
      pendingTotal: _safeDouble(data[Fields.pendingTotal]),
      sellerPayouts: payouts,
      confirmedByClient: _safeBool(data[Fields.confirmedByClient]),
      confirmedAt: _parseDateTime(data[Fields.confirmedAt]),
      platformFeeTotal: _safeDouble(data[Fields.platformFeeTotal]),
      payoutStatus: _safeString(data[Fields.payoutStatus], PayoutStatusValues.pending),
      ratings: ratings,
      // === AUDIT FIX: Parse 18 missing fields ===
      stripePaymentIntentId: data[Fields.stripePaymentIntentId] != null ? _safeString(data[Fields.stripePaymentIntentId]) : null,
      captureAttempts: _safeInt(data[Fields.captureAttempts]),
      capturedAt: _parseDateTime(data[Fields.capturedAt]),
      expiresAt: _parseDateTime(data[Fields.expiresAt]),
      autoConfirmed: _safeBool(data[Fields.autoConfirmed]),
      autoCaptured: _safeBool(data[Fields.autoCaptured]),
      refundAmount: _safeDouble(data[Fields.refundAmount]),
      refundedAt: _parseDateTime(data[Fields.refundedAt]),
      stockRestored: _safeBool(data[Fields.stockRestored]),
      cancelledBy: data[Fields.cancelledBy] != null ? _safeString(data[Fields.cancelledBy]) : null,
      cancelledAt: _parseDateTime(data[Fields.cancelledAt]),
      cancellationReason: data[Fields.cancellationReason] != null ? _safeString(data[Fields.cancellationReason]) : null,
      respondedAt: _parseDateTime(data[Fields.respondedAt]),
      actualCost: data[Fields.actualCost] != null ? _safeDouble(data[Fields.actualCost]) : null,
      requiresManualReview: _safeBool(data[Fields.requiresManualReview]),
      manualReviewReason: data[Fields.manualReviewReason] != null ? _safeString(data[Fields.manualReviewReason]) : null,
      payoutErrors: _safeStringList(data[Fields.payoutErrors]),
      updatedAt: _parseDateTime(data[Fields.updatedAt]),
      // Parse tax fields
      itemTaxes: (data[Fields.itemTaxes] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      taxExempt: _safeBool(data[Fields.taxExempt]),
      taxExemption: data[Fields.taxExemption] != null ? _safeMap(data[Fields.taxExemption]) : null,
      // Delivery instructions from buyer
      deliveryInstructions: data[Fields.deliveryInstructions] != null ? _safeString(data[Fields.deliveryInstructions]) : null,
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
abstract class OrderCreate with _$OrderCreate {
  const factory OrderCreate({
    required String userId,
    required String customerId,
    required String customerEmail,
    required List<OrderItem> items,
    required Address shippingAddress,
    @Default(0.0) double shippingCost,
    @Default(BusinessRules.defaultCurrency) String currency,
    @Default(false) bool shippingApprovalRequired,
  }) = _OrderCreate;

  factory OrderCreate.fromJson(Map<String, dynamic> json) => _$OrderCreateFromJson(json);
}

// ============================================================================
// ORDER ITEM
// ============================================================================

@Freezed(toJson: true, fromJson: true)
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required String productId,
    required String name,
    required String description,
    required double price,
    required int quantity,
    required List<String> imageUrls,
    required String sellerId,
    required Address sellerAddress,
    // Per-item status tracking
    @Default(DeliveryStatusValues.pending) String status, // 'pending' | 'shipped' | 'delivered' | 'refunded'
    @Default(DeliveryStatus.pending) DeliveryStatus deliveryStatus, // Parallel enum field for type-safe access
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
    // Tax field (new)
    String? taxCode,
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
abstract class Ratings with _$Ratings {
  const factory Ratings({required String productId, required double rating, String? review, required DateTime createdAt}) = _Ratings;

  factory Ratings.fromJson(Map<String, dynamic> json) => _$RatingsFromJson(json);
}

// ============================================================================
// SELLER PAYOUT
// ============================================================================

@freezed
abstract class SellerPayout with _$SellerPayout {
  const factory SellerPayout({
    required String sellerId,
    String? stripeAccountId,
    required int amountCents,
    required int platformFeeCents,
    required int netAmountCents,
    @Default(PayoutStatusValues.pending) String status,
    DateTime? payoutDate,
    String? stripeTransferId,
    String? failureReason,
  }) = _SellerPayout;

  factory SellerPayout.fromJson(Map<String, dynamic> json) => _$SellerPayoutFromJson(json);

  factory SellerPayout.fromMap(Map<String, dynamic> map) {
    return SellerPayout(
      sellerId: _safeString(map[Fields.sellerId]),
      stripeAccountId: map[Fields.stripeAccountId] != null ? _safeString(map[Fields.stripeAccountId]) : null,
      amountCents: _safeInt(map[Fields.amountCents]),
      platformFeeCents: _safeInt(map[Fields.platformFeeCents]),
      netAmountCents: _safeInt(map[Fields.netAmountCents]),
      status: _safeString(map[Fields.status], PayoutStatusValues.pending),
      payoutDate: _parseDateTime(map[Fields.payoutDate]),
      stripeTransferId: map[Fields.stripeTransferId] != null ? _safeString(map[Fields.stripeTransferId]) : null,
      failureReason: map[Fields.failureReason] != null ? _safeString(map[Fields.failureReason]) : null,
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
abstract class Taxes with _$Taxes {
  const factory Taxes({@Default(0.0) double gst, @Default(0.0) double pst, @Default(0.0) double hst, @Default(0.0) double qst}) = _Taxes;

  factory Taxes.fromJson(Map<String, dynamic> json) {
    return Taxes(
      gst: (json[Fields.gst] ?? json[Fields.GST] ?? 0.0).toDouble(),
      pst: (json[Fields.pst] ?? json[Fields.PST] ?? 0.0).toDouble(),
      hst: (json[Fields.hst] ?? json[Fields.HST] ?? 0.0).toDouble(),
      qst: (json[Fields.qst] ?? json[Fields.QST] ?? 0.0).toDouble(),
    );
  }

  factory Taxes.fromMap(Map<String, dynamic> map) =>
      Taxes(gst: (map[Fields.GST] ?? 0.0).toDouble(), pst: (map[Fields.PST] ?? 0.0).toDouble(), hst: (map[Fields.HST] ?? 0.0).toDouble(), qst: (map[Fields.QST] ?? 0.0).toDouble());

  const Taxes._();

  /// Calculate total tax amount
  double get total => gst + pst + hst + qst;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {Fields.GST: gst, Fields.PST: pst, Fields.HST: hst, Fields.QST: qst};

  /// Convert to Map
  Map<String, double> toMap() => {Fields.GST: gst, Fields.PST: pst, Fields.HST: hst, Fields.QST: qst};
}
