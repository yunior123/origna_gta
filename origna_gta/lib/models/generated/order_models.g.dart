// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
  orderId: json['orderId'] as String,
  userId: json['userId'] as String,
  customerId: json['customerId'] as String,
  customerEmail: json['customerEmail'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  total: (json['total'] as num).toDouble(),
  subtotal: (json['subtotal'] as num).toDouble(),
  shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
  taxes: Taxes.fromJson(json['taxes'] as Map<String, dynamic>),
  status:
      $enumDecodeNullable(_$OrderStatusEnumMap, json['status']) ??
      OrderStatus.pending,
  paymentStatus:
      $enumDecodeNullable(_$PaymentStatusEnumMap, json['paymentStatus']) ??
      PaymentStatus.awaitingPayment,
  deliveryInfo: Address.fromJson(json['deliveryInfo'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
  currency: json['currency'] as String? ?? 'cad',
  amount: (json['amount'] as num).toInt(),
  sellerIds:
      (json['sellerIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  stripeSessionId: json['stripeSessionId'] as String,
  shippingApprovalStatus:
      $enumDecodeNullable(
        _$ShippingApprovalStatusEnumMap,
        json['shippingApprovalStatus'],
      ) ??
      ShippingApprovalStatus.notRequired,
  shippingApprovalRequired: json['shippingApprovalRequired'] as bool? ?? false,
  actualShipping: (json['actualShipping'] as num?)?.toDouble() ?? 0.0,
  pendingTotal: (json['pendingTotal'] as num?)?.toDouble() ?? 0.0,
  sellerPayouts:
      (json['sellerPayouts'] as List<dynamic>?)
          ?.map((e) => SellerPayout.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  confirmedByClient: json['confirmedByClient'] as bool? ?? false,
  confirmedAt: json['confirmedAt'] == null
      ? null
      : DateTime.parse(json['confirmedAt'] as String),
  platformFeeTotal: (json['platformFeeTotal'] as num?)?.toDouble() ?? 0.0,
  payoutStatus: json['payoutStatus'] as String? ?? 'pending',
  ratings:
      (json['ratings'] as List<dynamic>?)
          ?.map((e) => Ratings.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'userId': instance.userId,
      'customerId': instance.customerId,
      'customerEmail': instance.customerEmail,
      'items': instance.items,
      'total': instance.total,
      'subtotal': instance.subtotal,
      'shippingCost': instance.shippingCost,
      'taxes': instance.taxes,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'paymentStatus': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'deliveryInfo': instance.deliveryInfo,
      'createdAt': instance.createdAt.toIso8601String(),
      'currency': instance.currency,
      'amount': instance.amount,
      'sellerIds': instance.sellerIds,
      'stripeSessionId': instance.stripeSessionId,
      'shippingApprovalStatus':
          _$ShippingApprovalStatusEnumMap[instance.shippingApprovalStatus]!,
      'shippingApprovalRequired': instance.shippingApprovalRequired,
      'actualShipping': instance.actualShipping,
      'pendingTotal': instance.pendingTotal,
      'sellerPayouts': instance.sellerPayouts,
      'confirmedByClient': instance.confirmedByClient,
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
      'platformFeeTotal': instance.platformFeeTotal,
      'payoutStatus': instance.payoutStatus,
      'ratings': instance.ratings,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'pending',
  OrderStatus.confirmed: 'confirmed',
  OrderStatus.shipped: 'shipped',
  OrderStatus.delivered: 'delivered',
  OrderStatus.cancelled: 'cancelled',
  OrderStatus.refunded: 'refunded',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.awaitingPayment: 'awaiting_payment',
  PaymentStatus.paymentReceived: 'payment_received',
  PaymentStatus.paymentFailed: 'payment_failed',
  PaymentStatus.refunded: 'refunded',
  PaymentStatus.partiallyRefunded: 'partially_refunded',
};

const _$ShippingApprovalStatusEnumMap = {
  ShippingApprovalStatus.notRequired: 'not_required',
  ShippingApprovalStatus.pending: 'pending',
  ShippingApprovalStatus.approved: 'approved',
  ShippingApprovalStatus.rejected: 'rejected',
};

_$OrderCreateImpl _$$OrderCreateImplFromJson(
  Map<String, dynamic> json,
) => _$OrderCreateImpl(
  userId: json['userId'] as String,
  customerId: json['customerId'] as String,
  customerEmail: json['customerEmail'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  deliveryInfo: Address.fromJson(json['deliveryInfo'] as Map<String, dynamic>),
  stripeSessionId: json['stripeSessionId'] as String,
  shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
  currency: json['currency'] as String? ?? 'cad',
  shippingApprovalRequired: json['shippingApprovalRequired'] as bool? ?? false,
);

Map<String, dynamic> _$$OrderCreateImplToJson(_$OrderCreateImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'customerId': instance.customerId,
      'customerEmail': instance.customerEmail,
      'items': instance.items,
      'deliveryInfo': instance.deliveryInfo,
      'stripeSessionId': instance.stripeSessionId,
      'shippingCost': instance.shippingCost,
      'currency': instance.currency,
      'shippingApprovalRequired': instance.shippingApprovalRequired,
    };

_$OrderItemImpl _$$OrderItemImplFromJson(
  Map<String, dynamic> json,
) => _$OrderItemImpl(
  productId: json['productId'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  price: (json['price'] as num).toDouble(),
  quantity: (json['quantity'] as num).toInt(),
  imageUrls: (json['imageUrls'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sellerId: json['sellerId'] as String,
  sellerAddress: Address.fromJson(
    json['sellerAddress'] as Map<String, dynamic>,
  ),
  deliveryStatus:
      $enumDecodeNullable(_$DeliveryStatusEnumMap, json['deliveryStatus']) ??
      DeliveryStatus.pending,
  trackingNumber: json['trackingNumber'] as String?,
  confirmedByBuyer: json['confirmedByBuyer'] as bool? ?? false,
  weightKg: (json['weightKg'] as num?)?.toDouble(),
  lengthCm: (json['lengthCm'] as num?)?.toDouble(),
  widthCm: (json['widthCm'] as num?)?.toDouble(),
  heightCm: (json['heightCm'] as num?)?.toDouble(),
  isLocalDeliveryOnly: json['isLocalDeliveryOnly'] as bool? ?? false,
  isPerishable: json['isPerishable'] as bool? ?? false,
  estimatedShipDays: (json['estimatedShipDays'] as num?)?.toInt() ?? 3,
  deliveryOptions:
      (json['deliveryOptions'] as List<dynamic>?)
          ?.map((e) => SellerDeliveryOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  minimumOrderQuantity: (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
  freeShipping: json['freeShipping'] as bool? ?? false,
);

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'quantity': instance.quantity,
      'imageUrls': instance.imageUrls,
      'sellerId': instance.sellerId,
      'sellerAddress': instance.sellerAddress,
      'deliveryStatus': _$DeliveryStatusEnumMap[instance.deliveryStatus]!,
      'trackingNumber': instance.trackingNumber,
      'confirmedByBuyer': instance.confirmedByBuyer,
      'weightKg': instance.weightKg,
      'lengthCm': instance.lengthCm,
      'widthCm': instance.widthCm,
      'heightCm': instance.heightCm,
      'isLocalDeliveryOnly': instance.isLocalDeliveryOnly,
      'isPerishable': instance.isPerishable,
      'estimatedShipDays': instance.estimatedShipDays,
      'deliveryOptions': instance.deliveryOptions,
      'minimumOrderQuantity': instance.minimumOrderQuantity,
      'freeShipping': instance.freeShipping,
    };

const _$DeliveryStatusEnumMap = {
  DeliveryStatus.pending: 'pending',
  DeliveryStatus.processing: 'processing',
  DeliveryStatus.shipped: 'shipped',
  DeliveryStatus.delivered: 'delivered',
  DeliveryStatus.cancelled: 'cancelled',
  DeliveryStatus.returned: 'returned',
};

_$RatingsImpl _$$RatingsImplFromJson(Map<String, dynamic> json) =>
    _$RatingsImpl(
      productId: json['productId'] as String,
      rating: (json['rating'] as num).toDouble(),
      review: json['review'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$RatingsImplToJson(_$RatingsImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'rating': instance.rating,
      'review': instance.review,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$SellerPayoutImpl _$$SellerPayoutImplFromJson(Map<String, dynamic> json) =>
    _$SellerPayoutImpl(
      sellerId: json['sellerId'] as String,
      sellerStripeAccountId: json['sellerStripeAccountId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      platformFee: (json['platformFee'] as num).toDouble(),
      netAmount: (json['netAmount'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      payoutDate: json['payoutDate'] == null
          ? null
          : DateTime.parse(json['payoutDate'] as String),
      stripeTransferId: json['stripeTransferId'] as String?,
      failureReason: json['failureReason'] as String?,
    );

Map<String, dynamic> _$$SellerPayoutImplToJson(_$SellerPayoutImpl instance) =>
    <String, dynamic>{
      'sellerId': instance.sellerId,
      'sellerStripeAccountId': instance.sellerStripeAccountId,
      'amount': instance.amount,
      'platformFee': instance.platformFee,
      'netAmount': instance.netAmount,
      'status': instance.status,
      'payoutDate': instance.payoutDate?.toIso8601String(),
      'stripeTransferId': instance.stripeTransferId,
      'failureReason': instance.failureReason,
    };
