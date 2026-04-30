import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/enum_extensions.dart';
import 'package:origna_gta/models/generated/base_models.dart'
    show OrderStatus, UserRole;
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/utils.dart';

// Re-export enums for backward compatibility
export 'package:origna_gta/models/generated/base_models.dart'
    show UserRole, PaymentStatus, ShippingApprovalStatus;

/// Lightweight document snapshot used by manual model factories.
class DocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;

  const DocumentSnapshot({required this.id, required Map<String, dynamic> data})
    : _data = data;

  Map<String, dynamic> data() => _data;
}

/// Safely parse a dynamic value (Timestamp, String, DateTime) to DateTime?
DateTime? _parseDateTime(dynamic value) {
  return parseDateTime(value);
}

/// Required DateTime fields fall back to "now" rather than crashing on stale data.
DateTime _parseDateTimeRequired(dynamic value) {
  return parseDateTimeRequired(value);
}

int? _parseOptionalInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is Map) {
    for (final key in const ['integerValue', 'doubleValue', 'stringValue']) {
      final nested = value[key];
      if (nested != null) return _parseOptionalInt(nested);
    }
    return null;
  }
  return int.tryParse(value.toString());
}

int _parseIntOrZero(dynamic value) => _parseOptionalInt(value) ?? 0;

/// Physical address model used for shipping, billing, and seller warehouse locations.
///
/// [state] is the Canadian province code (e.g., 'ON', 'QC', 'BC').
/// [postalCode] follows Canadian format: `A1A 1A1`.
/// [latitude]/[longitude] are optional geocoded coordinates used for
/// shipping distance calculations and local delivery checks.
class Address {
  final String street;
  final String apartment; // Unit, Suite, Apt #
  final String city;
  final String state; // or province
  final String postalCode; // ZIP code
  final String country;
  final String? phoneNumber; // Optional contact number for delivery
  final bool isDefault; // For multiple addresses
  final String? label; // "Home", "Work", "Other"
  final double? latitude; // For mapping/delivery
  final double? longitude;
  final String? addressId; // For Address Book subcollection

  Address({
    this.addressId,
    required this.street,
    this.apartment = '',
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phoneNumber,
    this.isDefault = false,
    this.label,
    this.latitude,
    this.longitude,
  });

  /// Create an empty address for fallback when data is missing
  factory Address.empty() => Address(
    street: '',
    city: '',
    state: '',
    postalCode: '',
    country: 'Canada',
  );

  factory Address.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Address(
      addressId: docId ?? map[Fields.addressId] as String?,
      street: (map[Fields.street] as String?) ?? '',
      apartment: (map[Fields.apartment] as String?) ?? '',
      city: (map[Fields.city] as String?) ?? '',
      state: (map[Fields.state] as String?) ?? '',
      postalCode: (map[Fields.postalCode] as String?) ?? '',
      country: (map[Fields.country] as String?) ?? '',
      phoneNumber: map[Fields.phoneNumber] as String?,
      isDefault: (map[Fields.isDefault] as bool?) ?? false,
      label: map[Fields.label] as String?,
      latitude: (map[Fields.latitude] as num?)?.toDouble(),
      longitude: (map[Fields.longitude] as num?)?.toDouble(),
    );
  }

  // Helper for display with line breaks
  String get formattedAddress {
    final line1 = street;
    final line2 = apartment.isNotEmpty ? apartment : null;
    final line3 = '$city, $state $postalCode';
    final line4 = country;

    return [
      line1,
      line2,
      line3,
      line4,
    ].where((line) => line != null && line.isNotEmpty).join('\n');
  }

  // Helper method to get formatted full address
  String get fullAddress {
    final parts = <String>[
      street,
      if (apartment.isNotEmpty) apartment,
      city,
      state,
      postalCode,
      country,
    ];
    return parts.join(', ');
  }

  Address copyWith({
    String? street,
    String? apartment,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phoneNumber,
    bool? isDefault,
    String? label,
    double? latitude,
    double? longitude,
    String? addressId,
  }) {
    return Address(
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isDefault: isDefault ?? this.isDefault,
      label: label ?? this.label,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressId: addressId ?? this.addressId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (addressId != null) Fields.addressId: addressId,
      Fields.street: street,
      Fields.apartment: apartment,
      Fields.city: city,
      Fields.state: state,
      Fields.postalCode: postalCode,
      Fields.country: country,
      Fields.phoneNumber: phoneNumber,
      Fields.isDefault: isDefault,
      Fields.label: label,
      Fields.latitude: latitude,
      Fields.longitude: longitude,
    };
  }
}

/// Geocoded address details returned from the autocomplete/geocode API.
///
/// Always includes [latitude] and [longitude] (unlike [Address] which has them optional).
class AddressDetails {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final double latitude;
  final double longitude;

  AddressDetails({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });
}

/// Enriched cart item with full product details, seller info, and shipping metadata.
///
/// Created by joining a [CartItemModel] (quantity, productId) with the product document.
/// [priceCents] is the authoritative price in integer cents — never use [price] for arithmetic.
/// [isDigital] items skip shipping; [isPerishable] items are limited to local delivery.
class CartItemDetailModel {
  final String productId;
  final String name;
  final String description;
  final double price;

  /// Price in integer cents — authoritative for arithmetic (never use [price] for sums).
  final int priceCents;
  final List<String> imageUrls;
  final int quantity;
  final DateTime createdAt;
  final Address sellerAddress;
  final String sellerId;
  final String sellerName;
  final String status;
  final String? trackingNumber;
  final bool confirmedByBuyer; // Buyer confirmed receipt of this item
  final String? madeInCountry; // F-277
  final double? weightKg;
  final String? weightUnit; // F-280
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final String? dimensionUnit; // F-280
  final bool isLocalDeliveryOnly;
  final bool isPerishable;
  final int estimatedShipDays;
  final List<SellerDeliveryOption> deliveryOptions;
  final int minimumOrderQuantity;
  final bool freeShipping;
  final bool isDigital;
  final bool isAgeRestricted;
  final String? buyerNote;
  final bool isSmallSupplier;
  final String? variantId;
  final String? variantTitle;
  final Map<String, String>? variantOptions;

  CartItemDetailModel({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    int? priceCents,
    required this.imageUrls,
    required this.quantity,
    required this.createdAt,
    required this.sellerAddress,
    required this.sellerId,
    required this.sellerName,
    this.status = DeliveryStatusValues.pending,
    this.trackingNumber,
    this.confirmedByBuyer = false,
    this.madeInCountry,
    this.weightKg,
    this.weightUnit,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.dimensionUnit,
    this.isLocalDeliveryOnly = false,
    this.isPerishable = false,
    this.estimatedShipDays = 3,
    this.deliveryOptions = const [],
    this.minimumOrderQuantity = 1,
    this.freeShipping = false,
    this.isDigital = false,
    this.isAgeRestricted = false,
    this.buyerNote,
    this.isSmallSupplier = false,
    this.variantId,
    this.variantTitle,
    this.variantOptions,
  }) : priceCents = priceCents ?? (price * 100).round();

  // Convert a backend document map to CartItemDetailModel.
  factory CartItemDetailModel.fromMap(Map<String, dynamic> map) {
    return CartItemDetailModel(
      productId: (map[Fields.productId] as String?) ?? '',
      name: (map[Fields.name] as String?) ?? '',
      description: (map[Fields.description] as String?) ?? '',
      priceCents: map[Fields.priceCents] != null
          ? (map[Fields.priceCents] as num).toInt()
          : ((map[Fields.price] as num?) ?? 0).toInt() * 100,
      price: map[Fields.priceCents] != null
          ? (map[Fields.priceCents] as num).toDouble() / 100
          : (map[Fields.price] as num? ?? 0).toDouble(),
      imageUrls: List<String>.from(map[Fields.imageUrls] as Iterable? ?? []),
      quantity: (map[Fields.quantity] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTimeRequired(map[Fields.createdAt]),
      sellerAddress: map[Fields.sellerAddress] != null
          ? Address.fromMap(map[Fields.sellerAddress] as Map<String, dynamic>)
          : Address.empty(),
      sellerId: (map[Fields.sellerId] as String?) ?? '',
      sellerName: (map[Fields.sellerName] as String?) ?? '',
      status: (map[Fields.status] as String?) ?? DeliveryStatus.pending.value,
      trackingNumber: map[Fields.trackingNumber] as String?,
      confirmedByBuyer: (map[Fields.confirmedByBuyer] as bool?) ?? false,
      madeInCountry: map[Fields.madeInCountry] as String?,
      weightKg: map[Fields.weightKg] != null
          ? (map[Fields.weightKg] as num).toDouble()
          : null,
      weightUnit: map[Fields.weightUnit] as String?,
      lengthCm: map[Fields.lengthCm] != null
          ? (map[Fields.lengthCm] as num).toDouble()
          : null,
      widthCm: map[Fields.widthCm] != null
          ? (map[Fields.widthCm] as num).toDouble()
          : null,
      heightCm: map[Fields.heightCm] != null
          ? (map[Fields.heightCm] as num).toDouble()
          : null,
      dimensionUnit: map[Fields.dimensionUnit] as String?,
      isLocalDeliveryOnly: (map[Fields.isLocalDeliveryOnly] as bool?) ?? false,
      isPerishable: (map[Fields.isPerishable] as bool?) ?? false,
      estimatedShipDays: (map[Fields.estimatedShipDays] as num?)?.toInt() ?? 3,
      deliveryOptions: map[Fields.deliveryOptions] != null
          ? (map[Fields.deliveryOptions] as List<dynamic>)
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (o) =>
                      SellerDeliveryOption.fromMap(o.cast<String, dynamic>()),
                )
                .whereType<SellerDeliveryOption>()
                .toList()
          : [],
      minimumOrderQuantity:
          (map[Fields.minimumOrderQuantity] as num?)?.toInt() ?? 1,
      freeShipping: (map[Fields.freeShipping] as bool?) ?? false,
      isDigital: (map[Fields.isDigital] as bool?) ?? false,
      isAgeRestricted: (map[Fields.isAgeRestricted] as bool?) ?? false,
      buyerNote: map[Fields.buyerNote] as String?,
      isSmallSupplier: (map[Fields.isSmallSupplier] as bool?) ?? false,
      variantId: map[Fields.variantId] as String?,
      variantTitle: map[Fields.variantTitle] as String?,
      variantOptions: map[Fields.variantOptions] != null
          ? Map<String, String>.from(
              map[Fields.variantOptions] as Map<dynamic, dynamic>,
            )
          : null,
    );
  }

  // Convert model to a serializable map.
  Map<String, dynamic> toMap() {
    return {
      Fields.productId: productId,
      Fields.name: name,
      Fields.description: description,
      Fields.price: price,
      Fields.priceCents: priceCents,
      Fields.imageUrls: imageUrls,
      Fields.quantity: quantity,
      Fields.createdAt: createdAt,
      Fields.sellerAddress: sellerAddress.toMap(),
      Fields.sellerId: sellerId,
      Fields.sellerName: sellerName,
      Fields.status: status,
      Fields.trackingNumber: trackingNumber,
      Fields.confirmedByBuyer: confirmedByBuyer,
      if (madeInCountry != null) Fields.madeInCountry: madeInCountry,
      Fields.weightKg: weightKg,
      if (weightUnit != null) Fields.weightUnit: weightUnit,
      Fields.lengthCm: lengthCm,
      Fields.widthCm: widthCm,
      Fields.heightCm: heightCm,
      if (dimensionUnit != null) Fields.dimensionUnit: dimensionUnit,
      Fields.isLocalDeliveryOnly: isLocalDeliveryOnly,
      Fields.isPerishable: isPerishable,
      Fields.estimatedShipDays: estimatedShipDays,
      Fields.deliveryOptions: deliveryOptions.map((o) => o.toMap()).toList(),
      Fields.minimumOrderQuantity: minimumOrderQuantity,
      Fields.freeShipping: freeShipping,
      Fields.isDigital: isDigital,
      Fields.isAgeRestricted: isAgeRestricted,
      if (buyerNote != null) Fields.buyerNote: buyerNote,
      Fields.isSmallSupplier: isSmallSupplier,
      if (variantId != null) Fields.variantId: variantId,
      if (variantTitle != null) Fields.variantTitle: variantTitle,
      if (variantOptions != null) Fields.variantOptions: variantOptions,
    };
  }
}

/// Lightweight cart item from the `users/{uid}/cart` subcollection.
///
/// Contains only the product reference and quantity — enriched with product
/// details by [cartItemDetailProvider] to create [CartItemDetailModel].
/// [cartItemId] format: `productId` or `productId_variantId`.
class CartItemModel {
  final String cartItemId; // Auto-generated document ID
  final int quantity;
  final String productId;
  final DateTime createdAt;
  final String? productName;
  final String? productDescription;
  final List<String> imageUrls;
  final String? buyerNote;
  final int? priceSnapshot;
  final String? variantId;
  final String? variantTitle;
  final Map<String, String>? variantOptions;

  CartItemModel({
    required this.cartItemId,
    required this.quantity,
    required this.productId,
    required this.createdAt,
    this.productName,
    this.productDescription,
    this.imageUrls = const [],
    this.buyerNote,
    this.priceSnapshot,
    this.variantId,
    this.variantTitle,
    this.variantOptions,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CartItemModel(
      cartItemId: docId ?? (map[Fields.cartItemId] as String? ?? ''),
      quantity: _parseIntOrZero(map[Fields.quantity]),
      productId: (map[Fields.productId] as String?) ?? '',
      createdAt: _parseDateTimeRequired(map[Fields.createdAt]),
      productName:
          map[Fields.name] as String? ?? map[Fields.productName] as String?,
      productDescription: map[Fields.description] as String?,
      imageUrls: List<String>.from(map[Fields.imageUrls] as Iterable? ?? []),
      buyerNote: map[Fields.buyerNote] as String?,
      priceSnapshot:
          _parseOptionalInt(map[Fields.priceSnapshot]) ??
          _parseOptionalInt(map[Fields.priceCents]),
      variantId: map[Fields.variantId] as String?,
      variantTitle: map[Fields.variantTitle] as String?,
      variantOptions: map[Fields.variantOptions] != null
          ? Map<String, String>.from(
              map[Fields.variantOptions] as Map<dynamic, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      Fields.quantity: quantity,
      Fields.productId: productId,
      Fields.createdAt: createdAt,
    };
    if (productName != null) map[Fields.name] = productName;
    if (productDescription != null) {
      map[Fields.description] = productDescription;
    }
    if (imageUrls.isNotEmpty) map[Fields.imageUrls] = imageUrls;
    if (buyerNote != null) map[Fields.buyerNote] = buyerNote;
    if (priceSnapshot != null) map[Fields.priceSnapshot] = priceSnapshot;
    if (variantId != null) map[Fields.variantId] = variantId;
    if (variantTitle != null) map[Fields.variantTitle] = variantTitle;
    if (variantOptions != null) map[Fields.variantOptions] = variantOptions;
    return map;
  }
}

/// Cart item data model for writes to the `cart` subcollection.
///
/// [priceSnapshot] captures the product price in cents at time of addition,
/// enabling price-drift detection at checkout.
class CartModel {
  final String cartItemId; // Auto-generated document ID
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final String? variantId;
  final String? variantTitle;
  final Map<String, String>? variantOptions;
  final String? variantSku;
  final int? priceSnapshot; // Price in cents at time of cart addition
  final String? productName;
  final String? productDescription;
  final List<String> imageUrls;

  CartModel({
    this.cartItemId = '',
    required this.productId,
    this.quantity = 1,
    required this.createdAt,
    this.variantId,
    this.variantTitle,
    this.variantOptions,
    this.variantSku,
    this.priceSnapshot,
    this.productName,
    this.productDescription,
    this.imageUrls = const [],
  });

  factory CartModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return CartModel(
      cartItemId: docId ?? (map[Fields.cartItemId] as String? ?? ''),
      productId: (map[Fields.productId] as String?) ?? '',
      quantity: (map[Fields.quantity] as num?)?.toInt() ?? 1,
      createdAt: _parseDateTimeRequired(map[Fields.createdAt]),
      variantId: map[Fields.variantId] as String?,
      variantTitle: map[Fields.variantTitle] as String?,
      variantOptions: map[Fields.variantOptions] != null
          ? Map<String, String>.from(
              map[Fields.variantOptions] as Map<dynamic, dynamic>,
            )
          : null,
      variantSku: map[Fields.variantSku] as String?,
      priceSnapshot: (map[Fields.priceSnapshot] as num?)?.toInt(),
      productName: map[Fields.name] as String?,
      productDescription: map[Fields.description] as String?,
      imageUrls: List<String>.from(map[Fields.imageUrls] as Iterable? ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      Fields.productId: productId,
      Fields.quantity: quantity,
      Fields.createdAt: createdAt,
    };
    if (productName != null) map[Fields.name] = productName;
    if (productDescription != null) {
      map[Fields.description] = productDescription;
    }
    if (imageUrls.isNotEmpty) map[Fields.imageUrls] = imageUrls;
    if (variantId != null) map[Fields.variantId] = variantId;
    if (variantTitle != null) map[Fields.variantTitle] = variantTitle;
    if (variantOptions != null) map[Fields.variantOptions] = variantOptions;
    if (variantSku != null) map[Fields.variantSku] = variantSku;
    if (priceSnapshot != null) map[Fields.priceSnapshot] = priceSnapshot;
    return map;
  }
}

/// Record of a user's favorited product with timestamp for sort ordering.
class FavoriteItem {
  final String productId;
  final DateTime dateFavorited;

  FavoriteItem({required this.productId, required this.dateFavorited});

  factory FavoriteItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();
    return FavoriteItem(
      productId: (data[Fields.productId] as String?) ?? doc.id,
      dateFavorited:
          _parseDateTime(data[Fields.dateFavorited]) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {Fields.productId: productId, Fields.dateFavorited: dateFavorited};
  }
}

/// Pair of image URL and raw bytes, used during product image upload flow.
class ImageModel {
  final String url;
  final Uint8List bytes;

  ImageModel({required this.url, required this.bytes});
}

/// Full order record with items, monetary totals, and lifecycle state.
///
/// All monetary fields use integer cents: [totalAmountCents], [subtotalCents],
/// [shippingCostCents], [taxAmountCents], [platformFeeTotalCents].
/// [sellerIds] supports multi-seller orders (one checkout, multiple sellers).
/// [items] is a snapshot at creation time — never modified after payment.
class OrderModel {
  final String orderId;
  final String userId;
  final String customerId;
  final String customerEmail;
  final List<CartItemDetailModel> items;
  // Money stored as cents, exposed as dollars
  final int totalAmountCents;
  final int subtotalCents;
  final int shippingCostCents;
  final int taxAmountCents;
  final Map<String, double> taxes;
  final String orderStatus;
  final String paymentStatus;
  final Map<String, dynamic> shippingAddress;
  final DateTime createdAt;
  final String currency;
  final List<String> sellerIds;
  final String stripeSessionId;
  final String shippingApprovalStatus;
  final bool shippingApprovalRequired;
  final int actualShippingCents;
  final int pendingTotalCents;
  // Payout tracking fields
  final List<SellerPayout> sellerPayouts;
  final bool confirmedByClient;
  final DateTime? confirmedAt;
  final int platformFeeTotalCents;
  final String payoutStatus;
  final Map<String, dynamic> ratings;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.totalAmountCents,
    required this.subtotalCents,
    this.shippingCostCents = 0,
    this.taxAmountCents = 0,
    required this.orderStatus,
    required this.shippingAddress,
    required this.createdAt,
    required this.customerId,
    required this.customerEmail,
    required this.taxes,
    required this.currency,
    required this.sellerIds,
    required this.stripeSessionId,
    this.shippingApprovalStatus = ShippingApprovalStatusValues.notRequired,
    this.shippingApprovalRequired = false,
    this.actualShippingCents = 0,
    this.pendingTotalCents = 0,
    String? paymentStatus,
    this.sellerPayouts = const [],
    this.confirmedByClient = false,
    this.confirmedAt,
    this.platformFeeTotalCents = 0,
    this.payoutStatus = PayoutStatusValues.pending,
    this.ratings = const {},
  }) : paymentStatus = paymentStatus ?? PaymentStatus.awaitingPayment.value;

  factory OrderModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();

    // Convert the list of items
    final itemsData = data[Fields.items] as List<dynamic>? ?? [];
    final items = itemsData.map<CartItemDetailModel>((item) {
      final map = item as Map<String, dynamic>;
      return CartItemDetailModel(
        productId: (map[Fields.productId] as String?) ?? '',
        name: (map[Fields.name] as String?) ?? '',
        description: (map[Fields.description] as String?) ?? '',
        price: ((map[Fields.price] as num?) ?? 0).toDouble(),
        imageUrls: List<String>.from(map[Fields.imageUrls] as Iterable? ?? []),
        quantity: (map[Fields.quantity] as num?)?.toInt() ?? 0,
        createdAt: _parseDateTimeRequired(map[Fields.createdAt]),
        sellerAddress: map[Fields.sellerAddress] != null
            ? Address.fromMap(map[Fields.sellerAddress] as Map<String, dynamic>)
            : Address.empty(),
        sellerId: (map[Fields.sellerId] as String?) ?? '',
        sellerName: (map[Fields.sellerName] as String?) ?? '',
        status: (map[Fields.status] as String?) ?? DeliveryStatus.pending.value,
        trackingNumber: map[Fields.trackingNumber] as String?,
        confirmedByBuyer: (map[Fields.confirmedByBuyer] as bool?) ?? false,
        isDigital: (map[Fields.isDigital] as bool?) ?? false,
        isAgeRestricted: (map[Fields.isAgeRestricted] as bool?) ?? false,
      );
    }).toList();

    // Parse seller payouts (safe cast — skip malformed entries)
    final payoutsData = data[Fields.sellerPayouts] as List<dynamic>? ?? [];
    final sellerPayouts = payoutsData
        .whereType<Map<String, dynamic>>()
        .map((p) => SellerPayout.fromMap(p))
        .toList();

    // Money — all cents
    final totalAmountCents =
        (data[Fields.totalAmountCents] as num?)?.toInt() ?? 0;
    final subtotalCents = (data[Fields.subtotalCents] as num?)?.toInt() ?? 0;
    final shippingCostCents =
        (data[Fields.shippingCostCents] as num?)?.toInt() ?? 0;
    final taxAmountCents = (data[Fields.taxAmountCents] as num?)?.toInt() ?? 0;
    final platformFeeTotalCents =
        (data[Fields.platformFeeTotalCents] as num?)?.toInt() ?? 0;

    final createdAt = _parseDateTimeRequired(data[Fields.createdAt]);

    return OrderModel(
      orderId: (data[Fields.orderId] as String?) ?? doc.id,
      userId: (data[Fields.userId] as String?) ?? '',
      items: items,
      totalAmountCents: totalAmountCents,
      subtotalCents: subtotalCents,
      shippingCostCents: shippingCostCents,
      taxAmountCents: taxAmountCents,
      orderStatus:
          (data[Fields.orderStatus] as String?) ?? OrderStatus.pending.value,
      paymentStatus:
          (data[Fields.paymentStatus] as String?) ??
          PaymentStatus.awaitingPayment.value,
      shippingAddress: Map<String, dynamic>.from(
        data[Fields.shippingAddress] as Map? ?? {},
      ),
      createdAt: createdAt,
      customerId: (data[Fields.customerId] as String?) ?? '',
      customerEmail: (data[Fields.customerEmail] as String?) ?? '',
      taxes: Map<String, double>.from(data[Fields.taxes] as Map? ?? {}),
      currency:
          (data[Fields.currency] as String?) ?? BusinessRules.defaultCurrency,
      sellerIds: List<String>.from(data[Fields.sellerIds] as Iterable? ?? []),
      stripeSessionId: (data[Fields.stripeSessionId] as String?) ?? '',
      shippingApprovalStatus:
          (data[Fields.shippingApprovalStatus] as String?) ??
          ShippingApprovalStatus.notRequired.value,
      shippingApprovalRequired:
          (data[Fields.shippingApprovalRequired] as bool?) ?? false,
      actualShippingCents:
          (data[Fields.actualShippingCents] as num?)?.toInt() ?? 0,
      pendingTotalCents: (data[Fields.pendingTotalCents] as num?)?.toInt() ?? 0,
      sellerPayouts: sellerPayouts,
      confirmedByClient: (data[Fields.confirmedByClient] as bool?) ?? false,
      confirmedAt: _parseDateTime(data[Fields.confirmedAt]),
      platformFeeTotalCents: platformFeeTotalCents,
      payoutStatus:
          (data[Fields.payoutStatus] as String?) ?? PayoutStatusValues.pending,
      ratings: Map<String, dynamic>.from(data[Fields.ratings] as Map? ?? {}),
    );
  }
  factory OrderModel.fromMap(Map<String, dynamic> data) {
    // Convert the list of items
    final itemsData = data[Fields.items] as List<dynamic>? ?? [];
    final items = itemsData.map<CartItemDetailModel>((item) {
      final map = item as Map<String, dynamic>;
      return CartItemDetailModel(
        productId: (map[Fields.productId] as String?) ?? '',
        name: (map[Fields.name] as String?) ?? '',
        description: (map[Fields.description] as String?) ?? '',
        price: ((map[Fields.price] as num?) ?? 0).toDouble(),
        imageUrls: List<String>.from(map[Fields.imageUrls] as Iterable? ?? []),
        quantity: (map[Fields.quantity] as num?)?.toInt() ?? 0,
        createdAt: _parseDateTimeRequired(map[Fields.createdAt]),
        sellerAddress: map[Fields.sellerAddress] != null
            ? Address.fromMap(map[Fields.sellerAddress] as Map<String, dynamic>)
            : Address.empty(),
        sellerId: (map[Fields.sellerId] as String?) ?? '',
        sellerName: (map[Fields.sellerName] as String?) ?? '',
        status: (map[Fields.status] as String?) ?? DeliveryStatus.pending.value,
        trackingNumber: map[Fields.trackingNumber] as String?,
        confirmedByBuyer: (map[Fields.confirmedByBuyer] as bool?) ?? false,
        isDigital: (map[Fields.isDigital] as bool?) ?? false,
        isAgeRestricted: (map[Fields.isAgeRestricted] as bool?) ?? false,
      );
    }).toList();

    // Parse seller payouts (safe cast — skip malformed entries)
    final payoutsData = data[Fields.sellerPayouts] as List<dynamic>? ?? [];
    final sellerPayouts = payoutsData
        .whereType<Map<String, dynamic>>()
        .map((p) => SellerPayout.fromMap(p))
        .toList();

    // Money — all cents
    final totalAmountCents =
        (data[Fields.totalAmountCents] as num?)?.toInt() ?? 0;
    final subtotalCents = (data[Fields.subtotalCents] as num?)?.toInt() ?? 0;
    final shippingCostCents =
        (data[Fields.shippingCostCents] as num?)?.toInt() ?? 0;
    final taxAmountCents = (data[Fields.taxAmountCents] as num?)?.toInt() ?? 0;
    final platformFeeTotalCents =
        (data[Fields.platformFeeTotalCents] as num?)?.toInt() ?? 0;

    final createdAt = _parseDateTimeRequired(data[Fields.createdAt]);

    return OrderModel(
      orderId: (data[Fields.orderId] as String?) ?? '',
      userId: (data[Fields.userId] as String?) ?? '',
      items: items,
      totalAmountCents: totalAmountCents,
      subtotalCents: subtotalCents,
      shippingCostCents: shippingCostCents,
      taxAmountCents: taxAmountCents,
      orderStatus:
          (data[Fields.orderStatus] as String?) ?? OrderStatusValues.pending,
      paymentStatus:
          (data[Fields.paymentStatus] as String?) ??
          PaymentStatusValues.awaitingPayment,
      shippingAddress: Map<String, dynamic>.from(
        data[Fields.shippingAddress] as Map? ?? {},
      ),
      createdAt: createdAt,
      customerId: (data[Fields.customerId] as String?) ?? '',
      customerEmail: (data[Fields.customerEmail] as String?) ?? '',
      taxes: Map<String, double>.from(data[Fields.taxes] as Map? ?? {}),
      currency:
          (data[Fields.currency] as String?) ?? BusinessRules.defaultCurrency,
      sellerIds: List<String>.from(data[Fields.sellerIds] as Iterable? ?? []),
      stripeSessionId: (data[Fields.stripeSessionId] as String?) ?? '',
      shippingApprovalStatus:
          (data[Fields.shippingApprovalStatus] as String?) ??
          ShippingApprovalStatus.notRequired.value,
      shippingApprovalRequired:
          (data[Fields.shippingApprovalRequired] as bool?) ?? false,
      actualShippingCents:
          (data[Fields.actualShippingCents] as num?)?.toInt() ?? 0,
      pendingTotalCents: (data[Fields.pendingTotalCents] as num?)?.toInt() ?? 0,
      sellerPayouts: sellerPayouts,
      confirmedByClient: (data[Fields.confirmedByClient] as bool?) ?? false,
      confirmedAt: _parseDateTime(data[Fields.confirmedAt]),
      platformFeeTotalCents: platformFeeTotalCents,
      payoutStatus:
          (data[Fields.payoutStatus] as String?) ?? PayoutStatusValues.pending,
      ratings: Map<String, dynamic>.from(data[Fields.ratings] as Map? ?? {}),
    );
  }

  /// Check if all delivered items have been confirmed by buyer
  bool get allItemsConfirmed {
    final deliveredItems = items.where(
      (i) => i.status == DeliveryStatus.delivered.value,
    );
    return deliveredItems.isNotEmpty &&
        deliveredItems.every((i) => i.confirmedByBuyer);
  }

  /// Check if all sellers have been paid
  bool get allSellersPaid =>
      sellerPayouts.isNotEmpty && sellerPayouts.every((p) => p.paid);

  double get shippingCost => shippingCostCents / 100.0;

  double get subtotal => subtotalCents / 100.0;

  double get taxAmount => taxAmountCents / 100.0;

  // Dollar getters derived from cents
  double get total => totalAmountCents / 100.0;

  // Convert OrderModel to a serializable map.
  Map<String, dynamic> toMap() {
    return {
      Fields.userId: userId,
      Fields.items: items.map((item) => item.toMap()).toList(),
      Fields.totalAmountCents: totalAmountCents,
      Fields.subtotalCents: subtotalCents,
      Fields.shippingCostCents: shippingCostCents,
      Fields.taxAmountCents: taxAmountCents,
      Fields.orderStatus: orderStatus,
      Fields.shippingAddress: shippingAddress,
      Fields.createdAt: createdAt,
      Fields.customerId: customerId,
      Fields.customerEmail: customerEmail,
      Fields.taxes: taxes,
      Fields.currency: currency,
      Fields.sellerIds: sellerIds,
      Fields.sellerPayouts: sellerPayouts.map((p) => p.toMap()).toList(),
      Fields.shippingApprovalStatus: shippingApprovalStatus,
      Fields.shippingApprovalRequired: shippingApprovalRequired,
      Fields.actualShippingCents: actualShippingCents,
      Fields.pendingTotalCents: pendingTotalCents,
      Fields.confirmedByClient: confirmedByClient,
      if (confirmedAt != null) Fields.confirmedAt: (confirmedAt!),
      Fields.platformFeeTotalCents: platformFeeTotalCents,
      Fields.payoutStatus: payoutStatus,
      Fields.ratings: ratings,
    };
  }
}

/// Product category definition with display name (localization key) and icon.
class ProductCategories {
  final int categoryId;
  final String name;
  final IconData icon;

  ProductCategories({
    required this.categoryId,
    required this.name,
    required this.icon,
  });
}

/// Lightweight product model used for form-to-API conversions in add/edit flows.
///
/// [priceCents] is the authoritative price in integer cents.
/// [lifecycleStatus] follows: draft -> active -> inactive -> deleted.
/// [isDigital] products skip shipping; [isPerishable] enforces local delivery only.
class ProductModel {
  final String id;
  final String name;
  final int priceCents;
  final List<String> imageUrls;
  final Address sellerAddress;
  final String description;
  final String sellerId;
  final int stockQuantity;
  final int categoryId;
  final double rating;
  final int ratingCount;
  final DateTime? createdAt;
  final List<String> searchKeywords;
  final double? weightKg;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final bool isLocalDeliveryOnly;
  final int estimatedShipDays;
  final String? taxCode;
  final List<SellerDeliveryOption> deliveryOptions;
  final bool isPerishable;
  final int minimumOrderQuantity;
  final bool freeShipping;
  final DateTime? deletedAt;
  final bool isDigital;
  final bool isAgeRestricted;
  final String? digitalType;
  final Map<String, String>? digitalBuilds;
  final String? approvalRejectionReason;
  final String lifecycleStatus;

  ProductModel({
    required this.id,
    required this.name,
    required this.priceCents,
    required this.imageUrls,
    required this.sellerAddress,
    required this.description,
    required this.stockQuantity,
    required this.categoryId,
    required this.sellerId,
    required List<String> keywords,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.createdAt,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.isLocalDeliveryOnly = false,
    this.estimatedShipDays = 3,
    this.taxCode,
    List<SellerDeliveryOption>? deliveryOptions,
    this.isPerishable = false,
    this.minimumOrderQuantity = 1,
    this.freeShipping = false,
    this.deletedAt,
    this.isDigital = false,
    this.isAgeRestricted = false,
    this.digitalType,
    this.digitalBuilds,
    this.approvalRejectionReason,
    this.lifecycleStatus = ProductLifecycleStatusValues.draft,
  }) : deliveryOptions =
           deliveryOptions ?? SellerDeliveryOption.defaultOptions(),
       searchKeywords = keywords;

  double get price => priceCents / 100.0;

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data();

    assert(data.containsKey(Fields.name), 'Product missing "name"');
    assert(data.containsKey(Fields.price), 'Product missing "price"');
    assert(data.containsKey(Fields.categoryId), 'Product missing "categoryId"');

    return ProductModel.fromMap({...data, Fields.productId: doc.id});
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    // Parse delivery options from stored data.
    List<SellerDeliveryOption>? parsedDeliveryOptions;
    if (map[Fields.deliveryOptions] != null &&
        map[Fields.deliveryOptions] is List) {
      parsedDeliveryOptions = (map[Fields.deliveryOptions] as List)
          .whereType<Map<dynamic, dynamic>>()
          .map((o) => SellerDeliveryOption.fromMap(o.cast<String, dynamic>()))
          .whereType<SellerDeliveryOption>()
          .toList();
    }

    return ProductModel(
      id: map[Fields.productId]?.toString() ?? '',
      name: map[Fields.name]?.toString() ?? '',
      priceCents: map[Fields.priceCents] != null
          ? _parseInt(map[Fields.priceCents])
          : (_parseDouble(map[Fields.price]) * 100).round(),
      imageUrls: _parseStringList(map[Fields.imageUrls]),
      sellerAddress: _parseAddress(map[Fields.sellerAddress]),
      description: map[Fields.description]?.toString() ?? '',
      categoryId: _parseInt(map[Fields.categoryId]),
      rating: _parseDouble(map[Fields.rating]),
      ratingCount: _parseInt(map[Fields.ratingCount]),
      createdAt: _parseDateTime(map[Fields.createdAt]),
      sellerId: map[Fields.sellerId]?.toString() ?? '',
      keywords: _parseStringList(map[Fields.keywords]),
      stockQuantity: _parseInt(map[Fields.stockQuantity]),
      isDigital: map[Fields.isDigital] as bool? ?? false,
      isAgeRestricted: map[Fields.isAgeRestricted] as bool? ?? false,
      digitalType: map[Fields.digitalType]?.toString(),
      digitalBuilds: map[Fields.digitalBuilds] != null
          ? Map<String, String>.from(map[Fields.digitalBuilds] as Map)
          : null,
      approvalRejectionReason: map[Fields.approvalRejectionReason]?.toString(),
      lifecycleStatus:
          map[Fields.lifecycleStatus]?.toString() ??
          ProductLifecycleStatusValues.draft,
      weightKg: map[Fields.weightKg] != null
          ? _parseDouble(map[Fields.weightKg])
          : null,
      lengthCm: map[Fields.lengthCm] != null
          ? _parseDouble(map[Fields.lengthCm])
          : null,
      widthCm: map[Fields.widthCm] != null
          ? _parseDouble(map[Fields.widthCm])
          : null,
      heightCm: map[Fields.heightCm] != null
          ? _parseDouble(map[Fields.heightCm])
          : null,
      isLocalDeliveryOnly: (map[Fields.isLocalDeliveryOnly] as bool?) ?? false,
      estimatedShipDays: _parseInt(map[Fields.estimatedShipDays]),
      taxCode: map[Fields.taxCode]?.toString(),
      deliveryOptions: parsedDeliveryOptions,
      isPerishable: (map[Fields.isPerishable] as bool?) ?? false,
      minimumOrderQuantity: _parseIntOr(
        map[Fields.minimumOrderQuantity],
        defaultValue: 1,
      ),
      freeShipping: (map[Fields.freeShipping] as bool?) ?? false,
      deletedAt: _parseDateTime(map[Fields.deletedAt]),
    );
  }

  /// Get enabled delivery options only
  List<SellerDeliveryOption> get enabledDeliveryOptions => deliveryOptions;

  /// Get delivery option by speed
  SellerDeliveryOption? getDeliveryOption(DeliverySpeed speed) =>
      deliveryOptions.where((o) => o.type == speed.value).firstOrNull;

  Map<String, dynamic> toMap() {
    return {
      Fields.productId: id,
      Fields.name: name,
      Fields.price: price,
      Fields.sellerId: sellerId,
      Fields.imageUrls: imageUrls,
      Fields.sellerAddress: sellerAddress.toMap(),
      Fields.description: description,
      Fields.stockQuantity: stockQuantity,
      Fields.categoryId: categoryId,
      Fields.rating: rating,
      Fields.ratingCount: ratingCount,
      Fields.createdAt: createdAt,
      Fields.keywords: searchKeywords,
      if (weightKg != null) Fields.weightKg: weightKg,
      if (lengthCm != null) Fields.lengthCm: lengthCm,
      if (widthCm != null) Fields.widthCm: widthCm,
      if (heightCm != null) Fields.heightCm: heightCm,
      Fields.isLocalDeliveryOnly: isLocalDeliveryOnly,
      Fields.estimatedShipDays: estimatedShipDays,
      if (taxCode != null) Fields.taxCode: taxCode,
      Fields.deliveryOptions: deliveryOptions.map((o) => o.toMap()).toList(),
      Fields.isPerishable: isPerishable,
      Fields.minimumOrderQuantity: minimumOrderQuantity,
      Fields.freeShipping: freeShipping,
      Fields.isDigital: isDigital,
      Fields.isAgeRestricted: isAgeRestricted,
      Fields.lifecycleStatus: lifecycleStatus,
      if (deletedAt != null) Fields.deletedAt: deletedAt,
    };
  }

  static Address _parseAddress(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Address.fromMap(value);
    }
    return Address.fromMap({});
  }

  // Helper methods for parsing
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  static int _parseIntOr(dynamic value, {required int defaultValue}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }
}

/// Model for tracking seller payouts per order (cents-based)
class SellerPayout {
  final String sellerId;
  final String? stripeAccountId;
  final int amountCents;
  final int platformFeeCents;
  final int netAmountCents;
  final String status; // 'pending', 'completed', 'failed'
  final String? stripeTransferId;
  final DateTime? payoutDate;
  final String? failureReason;

  SellerPayout({
    required this.sellerId,
    this.stripeAccountId,
    required this.amountCents,
    required this.platformFeeCents,
    required this.netAmountCents,
    this.status = PayoutStatusValues.pending,
    this.stripeTransferId,
    this.payoutDate,
    this.failureReason,
  });

  factory SellerPayout.fromMap(Map<String, dynamic> map) {
    return SellerPayout(
      sellerId: (map[Fields.sellerId] as String?) ?? '',
      stripeAccountId: map[Fields.stripeAccountId] as String?,
      amountCents: (map[Fields.amountCents] as num?)?.toInt() ?? 0,
      platformFeeCents: (map[Fields.platformFeeCents] as num?)?.toInt() ?? 0,
      netAmountCents: (map[Fields.netAmountCents] as num?)?.toInt() ?? 0,
      status: (map[Fields.status] as String?) ?? PayoutStatusValues.pending,
      stripeTransferId: map[Fields.stripeTransferId] as String?,
      payoutDate: _parseDateTime(map[Fields.payoutDate]),
      failureReason: map[Fields.failureReason] as String?,
    );
  }
  // Dollar getters
  double get amount => amountCents / 100.0;
  double get netAmount => netAmountCents / 100.0;
  bool get paid => status == PayoutStatusValues.completed;

  double get platformFee => platformFeeCents / 100.0;

  Map<String, dynamic> toMap() {
    return {
      Fields.sellerId: sellerId,
      Fields.stripeAccountId: stripeAccountId,
      Fields.amountCents: amountCents,
      Fields.platformFeeCents: platformFeeCents,
      Fields.netAmountCents: netAmountCents,
      Fields.status: status,
      Fields.stripeTransferId: stripeTransferId,
      if (payoutDate != null) Fields.payoutDate: (payoutDate!),
      Fields.failureReason: failureReason,
    };
  }
}

/// Authenticated user's profile combining OrignaBase auth state and `users` document.
///
/// [roles] determines access: buyer (default), seller (after Stripe onboarding), admin.
/// [isPremium] and [premiumExpiresAt] track subscription status.
/// [termsVersion] tracks the last Terms of Service version accepted (CASL/PIPEDA compliance).
/// Stripe Connect fields ([stripeAccountId], [payoutsEnabled], [chargesEnabled]) are
/// mastered in `seller_profiles` — UserModel only stores cached values.
class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<UserRole> roles;
  final Address? address;
  final DateTime createdAt;
  final String? customerId;
  final String? lastCheckoutSession;
  final String? lastOrderId;
  final DateTime? lastCheckoutTimestamp;
  final String? stripeAccountId;
  final bool payoutsEnabled;
  final bool chargesEnabled;
  final bool onboardingCompleted;
  final bool suspended;
  final DateTime? suspendedAt;
  final String paymentProvider;
  final bool verified;
  final String? verificationStatus;
  final String? platform;
  final String? country;
  final String? businessName;
  final int payoutHoldDays;
  final List<String> pendingRequirements;
  final bool isPremium;
  final DateTime? premiumSince;
  final DateTime? premiumExpiresAt;
  final String? stripeSubscriptionId;
  final bool notifyNewProducts;
  final bool notifyTrending;
  final bool mfaEnabled;
  final String? termsVersion;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.roles,
    this.address,
    required this.createdAt,
    this.customerId,
    this.lastCheckoutSession,
    this.lastOrderId,
    this.lastCheckoutTimestamp,
    this.stripeAccountId,
    this.payoutsEnabled = false,
    this.chargesEnabled = false,
    this.onboardingCompleted = false,
    this.suspended = false,
    this.suspendedAt,
    this.paymentProvider = PaymentProviderValues.stripe,
    this.verified = false,
    this.verificationStatus,
    this.platform,
    this.country,
    this.businessName,
    this.payoutHoldDays = 7,
    this.pendingRequirements = const [],
    this.isPremium = false,
    this.premiumSince,
    this.premiumExpiresAt,
    this.stripeSubscriptionId,
    this.notifyNewProducts = false,
    this.notifyTrending = false,
    this.mfaEnabled = false,
    this.termsVersion,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Convert string roles to UserRole enum (handles both String and UserRole inputs)
    final rawRoles = map[Fields.roles] is Iterable
        ? (map[Fields.roles] as Iterable).toList()
        : <dynamic>[];
    final roles = rawRoles.map((r) {
      if (r is UserRole) return r;
      final s = r.toString();
      switch (s) {
        case UserRoleValues.admin:
          return UserRole.admin;
        case UserRoleValues.seller:
          return UserRole.seller;
        case UserRoleValues.buyer:
        default:
          return UserRole.buyer;
      }
    }).toList();

    return UserModel(
      uid: map[Fields.uid]?.toString() ?? '',
      email: map[Fields.email]?.toString() ?? '',
      name: map[Fields.name]?.toString() ?? '',
      roles: roles,
      address: map[Fields.address] != null
          ? Address.fromMap(map[Fields.address] as Map<String, dynamic>)
          : null,
      createdAt: _parseDateTime(map[Fields.createdAt]) ?? DateTime.now(),
      customerId: map[Fields.customerId] as String?,
      lastCheckoutSession: map[Fields.lastCheckoutSession] as String?,
      lastOrderId: map[Fields.lastOrderId] as String?,
      lastCheckoutTimestamp: _parseDateTime(map[Fields.lastCheckoutTimestamp]),
      // C-6: These fields are now exclusively mastered in seller_profiles/{uid}
      stripeAccountId: null,
      payoutsEnabled: false,
      chargesEnabled: false,
      onboardingCompleted: false,
      suspended: (map[Fields.suspended] as bool?) ?? false,
      suspendedAt: _parseDateTime(map[Fields.suspendedAt]),
      paymentProvider:
          (map[Fields.paymentProvider] as String?) ??
          PaymentProviderValues.stripe,
      // Seller-specific fields
      verified: (map[Fields.verified] as bool?) ?? false,
      verificationStatus: map[Fields.verificationStatus] as String?,
      platform: map[Fields.platform] as String?,
      country: map[Fields.country] as String?,
      businessName: map[Fields.businessName] as String?,
      payoutHoldDays: (map[Fields.payoutHoldDays] as num?)?.toInt() ?? 7,
      pendingRequirements: List<String>.from(
        map[Fields.pendingRequirements] as Iterable? ?? const [],
      ),
      isPremium: (map[Fields.isPremium] as bool?) ?? false,
      premiumSince: _parseDateTime(map[Fields.premiumSince]),
      premiumExpiresAt: _parseDateTime(map[Fields.premiumExpiresAt]),
      stripeSubscriptionId: map[Fields.stripeSubscriptionId] as String?,
      notifyNewProducts: (map[Fields.notifyNewProducts] as bool?) ?? false,
      notifyTrending: (map[Fields.notifyTrending] as bool?) ?? false,
      mfaEnabled: (map[Fields.mfaEnabled] as bool?) ?? false,
      termsVersion: map[Fields.termsVersion] as String?,
    );
  }

  /// Check if user is a seller or admin with payouts enabled
  bool get canReceivePayouts =>
      (roles.contains(UserRole.seller) || roles.contains(UserRole.admin)) &&
      payoutsEnabled &&
      onboardingCompleted;

  /// Check if user can sell products (seller/admin + onboarding + payouts/charges enabled)
  bool get canSell =>
      (roles.contains(UserRole.seller) || roles.contains(UserRole.admin)) &&
      onboardingCompleted &&
      chargesEnabled &&
      payoutsEnabled &&
      !suspended;

  /// Check if user has pending Stripe requirements to complete
  bool get hasPendingRequirements => pendingRequirements.isNotEmpty;

  // copyWith method for updating specific fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    List<UserRole>? roles,
    Address? address,
    DateTime? createdAt,
    String? customerId,
    String? lastCheckoutSession,
    String? lastOrderId,
    DateTime? lastCheckoutTimestamp,
    String? stripeAccountId,
    bool? payoutsEnabled,
    bool? chargesEnabled,
    bool? onboardingCompleted,
    bool? suspended,
    DateTime? suspendedAt,
    String? paymentProvider,
    bool? verified,
    String? verificationStatus,
    String? platform,
    String? country,
    String? businessName,
    int? payoutHoldDays,
    List<String>? pendingRequirements,
    bool? isPremium,
    DateTime? premiumSince,
    DateTime? premiumExpiresAt,
    String? stripeSubscriptionId,
    bool? notifyNewProducts,
    bool? notifyTrending,
    bool? mfaEnabled,
    String? termsVersion,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      roles: roles ?? this.roles,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      customerId: customerId ?? this.customerId,
      lastCheckoutSession: lastCheckoutSession ?? this.lastCheckoutSession,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      lastCheckoutTimestamp:
          lastCheckoutTimestamp ?? this.lastCheckoutTimestamp,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      payoutsEnabled: payoutsEnabled ?? this.payoutsEnabled,
      chargesEnabled: chargesEnabled ?? this.chargesEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      suspended: suspended ?? this.suspended,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      verified: verified ?? this.verified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      platform: platform ?? this.platform,
      country: country ?? this.country,
      businessName: businessName ?? this.businessName,
      payoutHoldDays: payoutHoldDays ?? this.payoutHoldDays,
      pendingRequirements: pendingRequirements ?? this.pendingRequirements,
      isPremium: isPremium ?? this.isPremium,
      premiumSince: premiumSince ?? this.premiumSince,
      premiumExpiresAt: premiumExpiresAt ?? this.premiumExpiresAt,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      notifyNewProducts: notifyNewProducts ?? this.notifyNewProducts,
      notifyTrending: notifyTrending ?? this.notifyTrending,
      mfaEnabled: mfaEnabled ?? this.mfaEnabled,
      termsVersion: termsVersion ?? this.termsVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Fields.uid: uid,
      Fields.email: email,
      Fields.name: name,
      Fields.roles: roles.map((r) => r.name).toList(),
      Fields.address: address?.toMap(),
      Fields.createdAt: (createdAt),
      Fields.customerId: customerId,
      if (lastCheckoutSession != null)
        Fields.lastCheckoutSession: lastCheckoutSession,
      if (lastOrderId != null) Fields.lastOrderId: lastOrderId,
      if (lastCheckoutTimestamp != null)
        Fields.lastCheckoutTimestamp: (lastCheckoutTimestamp!),
      if (stripeAccountId != null) Fields.stripeAccountId: stripeAccountId,
      Fields.payoutsEnabled: payoutsEnabled,
      Fields.chargesEnabled: chargesEnabled,
      Fields.onboardingCompleted: onboardingCompleted,
      Fields.suspended: suspended,
      if (suspendedAt != null) Fields.suspendedAt: (suspendedAt!),
      Fields.paymentProvider: paymentProvider,
      // Seller-specific fields
      Fields.verified: verified,
      if (verificationStatus != null)
        Fields.verificationStatus: verificationStatus,
      if (platform != null) Fields.platform: platform,
      if (country != null) Fields.country: country,
      if (businessName != null) Fields.businessName: businessName,
      Fields.payoutHoldDays: payoutHoldDays,
      if (pendingRequirements.isNotEmpty)
        Fields.pendingRequirements: pendingRequirements,
      Fields.mfaEnabled: mfaEnabled,
    };
  }
}

// === Widget Previews ===
