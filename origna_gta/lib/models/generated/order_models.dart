// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// Generated from Pydantic models - Single source of truth

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'base_models.dart';
import 'product_models.dart';

part 'order_models.freezed.dart';
part 'order_models.g.dart';

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
    required double total,
    required double subtotal,
    @Default(0.0) double shippingCost,
    required Taxes taxes,
    @Default(OrderStatus.pending) OrderStatus status,
    @Default(PaymentStatus.awaitingPayment) PaymentStatus paymentStatus,
    required Address deliveryInfo,
    required DateTime createdAt,
    @Default('cad') String currency,
    required int amount,
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

    // Parse items
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final items = itemsData.map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList();

    // Parse taxes (handle legacy Map format)
    final taxesData = data['taxes'];
    final taxes = taxesData is Map ? Taxes.fromMap(taxesData as Map<String, dynamic>) : const Taxes();

    // Parse seller payouts
    final payoutsData = data['sellerPayouts'] as List<dynamic>? ?? [];
    final payouts = payoutsData.map((p) => SellerPayout.fromMap(p as Map<String, dynamic>)).toList();

    // Parse ratings (handle legacy format)
    final ratingsData = data['ratings'];
    final ratings = ratingsData is List ? (ratingsData).map((r) => Ratings.fromJson(r as Map<String, dynamic>)).toList() : <Ratings>[];

    return Order(
      orderId: data['orderId'] ?? doc.id,
      userId: data['userId'] ?? '',
      customerId: data['customerId'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      items: items,
      total: (data['total'] ?? 0.0).toDouble(),
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0.0).toDouble(),
      taxes: taxes,
      status: OrderStatus.values.firstWhere((e) => e.name == data['status'], orElse: () => OrderStatus.pending),
      paymentStatus: PaymentStatus.values.firstWhere((e) => e.name == data['paymentStatus'], orElse: () => PaymentStatus.awaitingPayment),
      deliveryInfo: Address.fromJson(data['deliveryInfo'] as Map<String, dynamic>? ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currency: data['currency'] ?? 'cad',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      sellerIds: List<String>.from(data['sellerIds'] ?? []),
      stripeSessionId: data['stripeSessionId'] ?? '',
      shippingApprovalStatus: ShippingApprovalStatus.values.firstWhere(
        (e) => e.name == data['shippingApprovalStatus'],
        orElse: () => ShippingApprovalStatus.notRequired,
      ),
      shippingApprovalRequired: data['shippingApprovalRequired'] ?? false,
      actualShipping: (data['actualShipping'] ?? 0.0).toDouble(),
      pendingTotal: (data['pendingTotal'] ?? 0.0).toDouble(),
      sellerPayouts: payouts,
      confirmedByClient: data['confirmedByClient'] ?? false,
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      platformFeeTotal: (data['platformFeeTotal'] ?? 0.0).toDouble(),
      payoutStatus: data['payoutStatus'] ?? 'pending',
      ratings: ratings,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  const Order._();

  /// Calculate totals from items
  Order calculateTotals() {
    final newSubtotal = items.fold(0.0, (acc, item) => acc + item.subtotal);
    final newTotal = newSubtotal + shippingCost + taxes.total;
    return copyWith(subtotal: newSubtotal, total: newTotal);
  }
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
    required Address deliveryInfo,
    required String stripeSessionId,
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
    @Default(DeliveryStatus.pending) DeliveryStatus deliveryStatus,
    String? trackingNumber,
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
    String? sellerStripeAccountId,
    required double amount,
    required double platformFee,
    required double netAmount,
    @Default('pending') String status,
    DateTime? payoutDate,
    String? stripeTransferId,
    String? failureReason,
  }) = _SellerPayout;

  factory SellerPayout.fromJson(Map<String, dynamic> json) => _$SellerPayoutFromJson(json);

  factory SellerPayout.fromMap(Map<String, dynamic> map) => SellerPayout(
    sellerId: map['sellerId'] ?? '',
    sellerStripeAccountId: map['sellerStripeAccountId'],
    amount: (map['amount'] ?? 0.0).toDouble(),
    platformFee: (map['platformFee'] ?? 0.0).toDouble(),
    netAmount: (map['netAmount'] ?? 0.0).toDouble(),
    status: map['status'] ?? 'pending',
    payoutDate: map['payoutDate'] is Timestamp
        ? (map['payoutDate'] as Timestamp).toDate()
        : map['payoutDate'] is DateTime
        ? map['payoutDate']
        : null,
    stripeTransferId: map['stripeTransferId'],
    failureReason: map['failureReason'],
  );

  const SellerPayout._();

  Map<String, dynamic> toMap() => {
    'sellerId': sellerId,
    'sellerStripeAccountId': sellerStripeAccountId,
    'amount': amount,
    'platformFee': platformFee,
    'netAmount': netAmount,
    'status': status,
    'payoutDate': payoutDate,
    'stripeTransferId': stripeTransferId,
    'failureReason': failureReason,
  };
}

// ============================================================================
// TAXES
// ============================================================================

@freezed
class Taxes with _$Taxes {
  const factory Taxes({@Default(0.0) double gst, @Default(0.0) double pst, @Default(0.0) double hst, @Default(0.0) double qst}) = _Taxes;

  factory Taxes.fromJson(Map<String, dynamic> json) {
    // Support both lowercase (gst) and uppercase (GST) keys
    return Taxes(
      gst: (json['gst'] ?? json['GST'] ?? 0.0).toDouble(),
      pst: (json['pst'] ?? json['PST'] ?? 0.0).toDouble(),
      hst: (json['hst'] ?? json['HST'] ?? 0.0).toDouble(),
      qst: (json['qst'] ?? json['QST'] ?? 0.0).toDouble(),
    );
  }

  /// Create from legacy Map format
  factory Taxes.fromMap(Map<String, dynamic> map) =>
      Taxes(gst: (map['GST'] ?? 0.0).toDouble(), pst: (map['PST'] ?? 0.0).toDouble(), hst: (map['HST'] ?? 0.0).toDouble(), qst: (map['QST'] ?? 0.0).toDouble());

  const Taxes._();

  /// Calculate total tax amount
  double get total => gst + pst + hst + qst;

  /// Convert to JSON (support both formats)
  Map<String, dynamic> toJson() => {'GST': gst, 'PST': pst, 'HST': hst, 'QST': qst};

  /// Convert to legacy Map format for compatibility
  Map<String, double> toMap() => {'GST': gst, 'PST': pst, 'HST': hst, 'QST': qst};
}
