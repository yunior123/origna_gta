import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/utils/constants.dart';

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

  Address({
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
  factory Address.empty() => Address(street: '', city: '', state: '', postalCode: '', country: 'Canada');

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      apartment: map['apartment'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      phoneNumber: map['phoneNumber'],
      isDefault: map['isDefault'] ?? false,
      label: map['label'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  // Helper for display with line breaks
  String get formattedAddress {
    final line1 = street;
    final line2 = apartment.isNotEmpty ? apartment : null;
    final line3 = '$city, $state $postalCode';
    final line4 = country;

    return [line1, line2, line3, line4].where((line) => line != null && line.isNotEmpty).join('\n');
  }

  // Helper method to get formatted full address
  String get fullAddress {
    final parts = <String>[street, if (apartment.isNotEmpty) apartment, city, state, postalCode, country];
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'apartment': apartment,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'phoneNumber': phoneNumber,
      'isDefault': isDefault,
      'label': label,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class AddressDetails {
  final String street;
  final String city;
  final String province;
  final String postalCode;
  final double latitude;
  final double longitude;

  AddressDetails({required this.street, required this.city, required this.province, required this.postalCode, required this.latitude, required this.longitude});
}

class CartItemDetailModel {
  final String productId;
  final String name;
  final String description;
  final double price;
  final List<String> imageUrls;
  final int quantity;
  final Timestamp dateCreated;
  final Address sellerAddress;
  final String sellerId;
  final String deliveryStatus;
  final String? trackingNumber;
  final bool confirmedByBuyer; // Buyer confirmed receipt of this item
  final double? weightKg;
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final bool isLocalDeliveryOnly;
  final bool isPerishable;
  final int estimatedShipDays;
  final List<SellerDeliveryOption> deliveryOptions;
  final int minimumOrderQuantity;
  final bool freeShipping;
  final bool isDigital;

  CartItemDetailModel({
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrls,
    required this.quantity,
    required this.dateCreated,
    required this.sellerAddress,
    required this.sellerId,
    required this.deliveryStatus,
    this.trackingNumber,
    this.confirmedByBuyer = false,
    this.weightKg,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.isLocalDeliveryOnly = false,
    this.isPerishable = false,
    this.estimatedShipDays = 3,
    this.deliveryOptions = const [],
    this.minimumOrderQuantity = 1,
    this.freeShipping = false,
    this.isDigital = false,
  });

  // Convert Firestore Map to CartItemDetailModel
  factory CartItemDetailModel.fromMap(Map<String, dynamic> map) {
    return CartItemDetailModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      dateCreated: (map['dateCreated'] as Timestamp?) ?? Timestamp.now(),
      sellerAddress: map['sellerAddress'] != null ? Address.fromMap(map['sellerAddress'] as Map<String, dynamic>) : Address.empty(),
      sellerId: map['sellerId'] ?? '',
      deliveryStatus: map['deliveryStatus'] ?? DeliveryStatus.pending.value,
      trackingNumber: map['trackingNumber'],
      confirmedByBuyer: map['confirmedByBuyer'] ?? false,
      weightKg: map['weightKg'] != null ? (map['weightKg'] as num).toDouble() : null,
      lengthCm: map['lengthCm'] != null ? (map['lengthCm'] as num).toDouble() : null,
      widthCm: map['widthCm'] != null ? (map['widthCm'] as num).toDouble() : null,
      heightCm: map['heightCm'] != null ? (map['heightCm'] as num).toDouble() : null,
      isLocalDeliveryOnly: map['isLocalDeliveryOnly'] ?? false,
      isPerishable: map['isPerishable'] ?? false,
      estimatedShipDays: map['estimatedShipDays'] ?? 3,
      deliveryOptions: map['deliveryOptions'] != null
          ? (map['deliveryOptions'] as List).map((o) => SellerDeliveryOption.fromMap(o as Map<String, dynamic>)).toList()
          : [],
      minimumOrderQuantity: (map['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
      freeShipping: map['freeShipping'] ?? false,
      isDigital: map['isDigital'] ?? false,
    );
  }

  // Convert model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'quantity': quantity,
      'dateCreated': dateCreated,
      'sellerAddress': sellerAddress.toMap(),
      'sellerId': sellerId,
      'deliveryStatus': deliveryStatus,
      'trackingNumber': trackingNumber,
      'confirmedByBuyer': confirmedByBuyer,
      'weightKg': weightKg,
      'lengthCm': lengthCm,
      'widthCm': widthCm,
      'heightCm': heightCm,
      'isLocalDeliveryOnly': isLocalDeliveryOnly,
      'isPerishable': isPerishable,
      'estimatedShipDays': estimatedShipDays,
      'deliveryOptions': deliveryOptions.map((o) => o.toMap()).toList(),
      'minimumOrderQuantity': minimumOrderQuantity,
      'freeShipping': freeShipping,
      'isDigital': isDigital,
    };
  }
}

class CartItemModel {
  final int quantity;
  final String productId;
  final Timestamp dateCreated;
  CartItemModel({required this.quantity, required this.productId, required this.dateCreated});
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      productId: map['productId'] ?? '',
      dateCreated: map['dateCreated'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'quantity': quantity, 'productId': productId, 'dateCreated': dateCreated};
  }
}

class CartModel {
  final String productId;
  final int quantity;
  final DateTime dateCreated;

  CartModel({required this.productId, this.quantity = 1, required this.dateCreated});

  factory CartModel.fromMap(Map<String, dynamic> map) {
    // Handle both Timestamp and null cases safely
    DateTime parsedDate;
    final rawDate = map['dateCreated'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    } else {
      parsedDate = DateTime.now();
    }

    return CartModel(productId: map['productId'] ?? '', quantity: (map['quantity'] as num?)?.toInt() ?? 1, dateCreated: parsedDate);
  }

  Map<String, dynamic> toMap() {
    return {'productId': productId, 'quantity': quantity, 'dateCreated': Timestamp.fromDate(dateCreated)};
  }
}

class FavoriteItem {
  final String productId;
  final DateTime dateFavorited;

  FavoriteItem({required this.productId, required this.dateFavorited});

  factory FavoriteItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteItem(productId: data['productId'] ?? doc.id, dateFavorited: (data['dateFavorited'] as Timestamp?)?.toDate() ?? DateTime.now());
  }

  Map<String, dynamic> toMap() {
    return {'productId': productId, 'dateFavorited': Timestamp.fromDate(dateFavorited)};
  }
}

class ImageModel {
  final String url;
  final Uint8List bytes;

  ImageModel({required this.url, required this.bytes});
}

class OrderModel {
  final String orderId;
  final String userId;
  final String customerId;
  final String customerEmail;
  final List<CartItemDetailModel> items;
  final double total;
  final Map<String, double> taxes;
  final double shippingCost;
  final double subtotal;
  final String status;
  final String paymentStatus;
  final Map<String, dynamic> deliveryInfo;
  final DateTime createdAt;
  final String currency;
  final int amount;
  final List<String> sellerIds;
  final String stripeSessionId;
  final String shippingApprovalStatus;
  final bool shippingApprovalRequired;
  final double actualShipping;
  final double pendingTotal;
  // Payout tracking fields
  final List<SellerPayout> sellerPayouts; // Per-seller payout breakdown
  final bool confirmedByClient; // Client confirmed receipt
  final DateTime? confirmedAt; // When order was confirmed by client
  final double platformFeeTotal; // Total platform fee for this order
  final String payoutStatus; // 'pending', 'processing', 'completed', 'partial'
  final Map<String, dynamic> ratings;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.items,
    required this.total,
    required this.status,
    required this.deliveryInfo,
    required this.createdAt,
    required this.customerId,
    required this.customerEmail,
    required this.taxes,
    required this.shippingCost,
    required this.subtotal,
    required this.amount,
    required this.currency,
    required this.sellerIds,
    required this.stripeSessionId,
    this.shippingApprovalStatus = 'not_required',
    this.shippingApprovalRequired = false,
    this.actualShipping = 0.0,
    this.pendingTotal = 0.0,
    String? paymentStatus,
    this.sellerPayouts = const [],
    this.confirmedByClient = false,
    this.confirmedAt,
    this.platformFeeTotal = 0.0,
    this.payoutStatus = 'pending',
    this.ratings = const {},
  }) : paymentStatus = paymentStatus ?? PaymentStatus.awaitingPayment.value;

  factory OrderModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert the list of items
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final items = itemsData.map((item) {
      final map = item as Map<String, dynamic>;
      return CartItemDetailModel(
        productId: map['productId'] ?? '',
        name: map['name'] ?? '',
        description: map["description"] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        imageUrls: List<String>.from(map['imageUrls'] ?? []),
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        dateCreated: (map['dateCreated'] as Timestamp?) ?? Timestamp.now(),
        sellerAddress: map['sellerAddress'] != null ? Address.fromMap(map['sellerAddress'] as Map<String, dynamic>) : Address.empty(),
        sellerId: map['sellerId'] ?? '',
        deliveryStatus: map['deliveryStatus'] ?? DeliveryStatus.pending.value,
        trackingNumber: map['trackingNumber'],
        confirmedByBuyer: map['confirmedByBuyer'] ?? false,
        isDigital: map['isDigital'] ?? false,
      );
    }).toList();

    // Parse seller payouts
    final payoutsData = data['sellerPayouts'] as List<dynamic>? ?? [];
    final sellerPayouts = payoutsData.map((p) => SellerPayout.fromMap(p as Map<String, dynamic>)).toList();

    final subtotal = (data['subtotal'] ?? 0).toDouble();
    final total = (data['total'] ?? 0).toDouble();
    final platformFeeTotal = (data['platformFeeTotal'] ?? (subtotal > 0 ? subtotal * 0.025 : total * 0.025)).toDouble();

    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
        ? createdAtRaw
        : DateTime.now();

    return OrderModel(
      orderId: data['orderId'] ?? doc.id,
      userId: data['userId'] ?? '',
      items: items,
      total: total,
      status: data['status'] ?? OrderStatus.pending.value,
      paymentStatus: data['paymentStatus'] ?? data['status'] ?? PaymentStatus.awaitingPayment.value,
      deliveryInfo: data['deliveryInfo'] ?? {},
      createdAt: createdAt,
      customerId: data['customerId'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      taxes: Map<String, double>.from(data['taxes'] ?? {}),
      shippingCost: (data['shippingCost'] ?? 0).toDouble(),
      subtotal: subtotal,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data["currency"] ?? '',
      sellerIds: List<String>.from(data["sellerIds"] ?? []),
      stripeSessionId: data["stripeSessionId"] ?? "",
      shippingApprovalStatus: data['shippingApprovalStatus'] ?? ShippingApprovalStatus.notRequired.value,
      shippingApprovalRequired: data['shippingApprovalRequired'] ?? false,
      actualShipping: (data['actualShipping'] ?? 0).toDouble(),
      pendingTotal: (data['pendingTotal'] ?? 0).toDouble(),
      sellerPayouts: sellerPayouts,
      confirmedByClient: data['confirmedByClient'] ?? false,
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      platformFeeTotal: platformFeeTotal,
      payoutStatus: data['payoutStatus'] ?? 'pending',
      ratings: Map<String, dynamic>.from(data['ratings'] ?? {}),
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> data) {
    // Convert the list of items
    final itemsData = data['items'] as List<dynamic>? ?? [];
    final items = itemsData.map((item) {
      final map = item as Map<String, dynamic>;
      return CartItemDetailModel(
        productId: map['productId'] ?? '',
        name: map['name'] ?? '',
        description: map["description"] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        imageUrls: List<String>.from(map['imageUrls'] ?? []),
        quantity: (map['quantity'] as num?)?.toInt() ?? 0,
        dateCreated: (map['dateCreated'] as Timestamp?) ?? Timestamp.now(),
        sellerAddress: map['sellerAddress'] != null ? Address.fromMap(map['sellerAddress'] as Map<String, dynamic>) : Address.empty(),
        sellerId: map['sellerId'] ?? '',
        deliveryStatus: map['deliveryStatus'] ?? DeliveryStatus.pending.value,
        trackingNumber: map['trackingNumber'],
        confirmedByBuyer: map['confirmedByBuyer'] ?? false,
        isDigital: map['isDigital'] ?? false,
      );
    }).toList();

    // Parse seller payouts
    final payoutsData = data['sellerPayouts'] as List<dynamic>? ?? [];
    final sellerPayouts = payoutsData.map((p) => SellerPayout.fromMap(p as Map<String, dynamic>)).toList();

    final subtotal = (data['subtotal'] ?? 0).toDouble();
    final total = (data['total'] ?? 0).toDouble();
    final platformFeeTotal = (data['platformFeeTotal'] ?? (subtotal > 0 ? subtotal * 0.025 : total * 0.025)).toDouble();

    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : createdAtRaw is DateTime
        ? createdAtRaw
        : DateTime.now();

    return OrderModel(
      orderId: data['orderId'] ?? '',
      userId: data['userId'] ?? '',
      items: items,
      total: total,
      status: data['status'] ?? OrderStatus.pending.value,
      paymentStatus: data['paymentStatus'] ?? data['status'] ?? PaymentStatus.awaitingPayment.value,
      deliveryInfo: Map<String, dynamic>.from(data['deliveryInfo'] ?? {}),
      createdAt: createdAt,
      customerId: data['customerId'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      taxes: Map<String, double>.from(data['taxes'] ?? {}),
      shippingCost: (data['shippingCost'] ?? 0).toDouble(),
      subtotal: subtotal,
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      currency: data['currency'] ?? 'cad',
      sellerIds: List<String>.from(data['sellerIds'] ?? []),
      stripeSessionId: data['stripeSessionId'] ?? '',
      shippingApprovalStatus: data['shippingApprovalStatus'] ?? ShippingApprovalStatus.notRequired.value,
      shippingApprovalRequired: data['shippingApprovalRequired'] ?? false,
      actualShipping: (data['actualShipping'] ?? 0).toDouble(),
      pendingTotal: (data['pendingTotal'] ?? 0).toDouble(),
      sellerPayouts: sellerPayouts,
      confirmedByClient: data['confirmedByClient'] ?? false,
      confirmedAt: (data['confirmedAt'] is Timestamp?) ? (data['confirmedAt'] as Timestamp?)?.toDate() : null,
      platformFeeTotal: platformFeeTotal,
      payoutStatus: data['payoutStatus'] ?? 'pending',
      ratings: Map<String, dynamic>.from(data['ratings'] ?? {}),
    );
  }

  /// Check if all delivered items have been confirmed by buyer
  bool get allItemsConfirmed {
    final deliveredItems = items.where((i) => i.deliveryStatus == DeliveryStatus.delivered.value);
    return deliveredItems.isNotEmpty && deliveredItems.every((i) => i.confirmedByBuyer);
  }

  /// Check if all sellers have been paid
  bool get allSellersPaid => sellerPayouts.isNotEmpty && sellerPayouts.every((p) => p.paid);

  // Convert OrderModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'status': status,
      'deliveryInfo': deliveryInfo,
      'createdAt': createdAt,
      'customerId': customerId,
      'customerEmail': customerEmail,
      'taxes': taxes,
      'shippingCost': shippingCost,
      'subtotal': subtotal,
      "currency": currency,
      "amount": amount,
      "sellerIds": sellerIds,
      'sellerPayouts': sellerPayouts.map((p) => p.toMap()).toList(),
      'shippingApprovalStatus': shippingApprovalStatus,
      'shippingApprovalRequired': shippingApprovalRequired,
      'actualShipping': actualShipping,
      'pendingTotal': pendingTotal,
      'confirmedByClient': confirmedByClient,
      if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
      'platformFeeTotal': platformFeeTotal,
      'payoutStatus': payoutStatus,
      'ratings': ratings,
    };
  }
}

class ProductCategories {
  final int categoryId;
  final String name;
  final IconData icon;

  ProductCategories({required this.categoryId, required this.name, required this.icon});
}

class ProductModel {
  final String id;
  final String name;
  final double price;
  final List<String> imageUrls;
  final Address sellerAddress;
  final String description;
  final String sellerId;
  final int stockQuantity;
  final int categoryId;
  final double rating;
  final int ratingCount;
  final Timestamp? dateCreated;
  final List<String> searchKeywords;
  // Shipping dimensions (optional - for better shipping calculation)
  final double? weightKg; // Weight in kilograms
  final double? lengthCm; // Length in centimeters
  final double? widthCm; // Width in centimeters
  final double? heightCm; // Height in centimeters
  final bool isLocalDeliveryOnly; // Restrict to buyers within 50km for same-day/next-day delivery
  final int estimatedShipDays; // Seller's estimated shipping time in days (legacy, use deliveryOptions)
  final String? taxCode; // Optional Stripe Tax Code (e.g. txcd_10000000)
  // Seller-defined delivery options (standard, express, same-day with custom times/prices)
  final List<SellerDeliveryOption> deliveryOptions;
  final bool isPerishable; // Food, flowers, etc. - affects same-day delivery logic
  final int minimumOrderQuantity;
  final bool freeShipping;
  final bool isActive;
  final Timestamp? deletedAt;
  final bool isDigital; // True if product is digital (no shipping required)

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrls,
    required this.sellerAddress,
    required this.description,
    required this.stockQuantity,
    required this.categoryId,
    required this.sellerId,
    required List<String> keywords,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.dateCreated,
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
    this.isActive = true,
    this.deletedAt,
    this.isDigital = false,
  }) : deliveryOptions = deliveryOptions ?? SellerDeliveryOption.defaultOptions(),
       searchKeywords = keywords;

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    assert(doc.data() != null, 'Product document data is null');
    final data = doc.data() as Map<String, dynamic>;

    assert(data.containsKey('name'), 'Product missing "name"');
    assert(data.containsKey('price'), 'Product missing "price"');
    assert(data.containsKey('categoryId'), 'Product missing "categoryId"');

    return ProductModel.fromMap({...data, 'productId': doc.id});
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    // Parse delivery options from Firestore
    List<SellerDeliveryOption>? parsedDeliveryOptions;
    if (map['deliveryOptions'] != null && map['deliveryOptions'] is List) {
      parsedDeliveryOptions = (map['deliveryOptions'] as List).map((o) => SellerDeliveryOption.fromMap(o as Map<String, dynamic>)).toList();
    }

    return ProductModel(
      id: map['productId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      price: _parseDouble(map['price']),
      imageUrls: _parseStringList(map['imageUrls']),
      sellerAddress: _parseAddress(map['sellerAddress']),
      description: map['description']?.toString() ?? '',
      categoryId: _parseInt(map['categoryId']),
      rating: _parseDouble(map['rating']),
      ratingCount: _parseInt(map['ratingCount']),
      dateCreated: map['dateCreated'] as Timestamp?,
      sellerId: map['sellerId']?.toString() ?? '',
      keywords: _parseStringList(map['keywords']),
      stockQuantity: _parseInt(map['stockQuantity']),
      isDigital: map['isDigital'] as bool? ?? false,
      weightKg: map['weightKg'] != null ? _parseDouble(map['weightKg']) : null,
      lengthCm: map['lengthCm'] != null ? _parseDouble(map['lengthCm']) : null,
      widthCm: map['widthCm'] != null ? _parseDouble(map['widthCm']) : null,
      heightCm: map['heightCm'] != null ? _parseDouble(map['heightCm']) : null,
      isLocalDeliveryOnly: map['isLocalDeliveryOnly'] ?? false,
      estimatedShipDays: _parseInt(map['estimatedShipDays']),
      taxCode: map['taxCode']?.toString(),
      deliveryOptions: parsedDeliveryOptions,
      isPerishable: map['isPerishable'] ?? false,
      minimumOrderQuantity: _parseIntOr(map['minimumOrderQuantity'], defaultValue: 1),
      freeShipping: map['freeShipping'] ?? false,
      isActive: map['isActive'] ?? true,
      deletedAt: map['deletedAt'] as Timestamp?,
    );
  }

  /// Get enabled delivery options only
  List<SellerDeliveryOption> get enabledDeliveryOptions => deliveryOptions.where((o) => o.isEnabled).toList();

  /// Get delivery option by speed
  SellerDeliveryOption? getDeliveryOption(DeliverySpeed speed) => deliveryOptions.where((o) => o.speed == speed && o.isEnabled).firstOrNull;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'sellerId': sellerId,
      'imageUrls': imageUrls,
      'sellerAddress': sellerAddress.toMap(),
      'description': description,
      'stockQuantity': stockQuantity,
      'categoryId': categoryId,
      'rating': rating,
      'ratingCount': ratingCount,
      'dateCreated': dateCreated,
      'keywords': searchKeywords,
      if (weightKg != null) 'weightKg': weightKg,
      if (lengthCm != null) 'lengthCm': lengthCm,
      if (widthCm != null) 'widthCm': widthCm,
      if (heightCm != null) 'heightCm': heightCm,
      'isLocalDeliveryOnly': isLocalDeliveryOnly,
      'estimatedShipDays': estimatedShipDays,
      if (taxCode != null) 'taxCode': taxCode,
      'deliveryOptions': deliveryOptions.map((o) => o.toMap()).toList(),
      'isPerishable': isPerishable,
      'minimumOrderQuantity': minimumOrderQuantity,
      'freeShipping': freeShipping,
      'isActive': isActive,
      'isDigital': isDigital,
      if (deletedAt != null) 'deletedAt': deletedAt,
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

/// Model for tracking seller payouts per order
class SellerPayout {
  final String sellerId;
  final String? stripeAccountId;
  final double gross; // Total amount before platform fee
  final double platformFee; // Platform fee amount
  final double net; // Amount seller receives
  final bool paid; // Has the seller been paid
  final String? transferId; // Stripe transfer ID
  final DateTime? paidAt; // When the seller was paid

  SellerPayout({
    required this.sellerId,
    this.stripeAccountId,
    required this.gross,
    required this.platformFee,
    required this.net,
    this.paid = false,
    this.transferId,
    this.paidAt,
  });

  factory SellerPayout.fromMap(Map<String, dynamic> map) {
    return SellerPayout(
      sellerId: map['sellerId'] ?? '',
      stripeAccountId: map['stripeAccountId'],
      gross: (map['gross'] ?? 0).toDouble(),
      platformFee: (map['platformFee'] ?? 0).toDouble(),
      net: (map['net'] ?? 0).toDouble(),
      paid: map['paid'] ?? false,
      transferId: map['transferId'],
      paidAt: (map['paidAt'] as Timestamp?)?.toDate(),
    );
  }

  SellerPayout copyWith({
    String? sellerId,
    String? stripeAccountId,
    double? gross,
    double? platformFee,
    double? net,
    bool? paid,
    String? transferId,
    DateTime? paidAt,
  }) {
    return SellerPayout(
      sellerId: sellerId ?? this.sellerId,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      gross: gross ?? this.gross,
      platformFee: platformFee ?? this.platformFee,
      net: net ?? this.net,
      paid: paid ?? this.paid,
      transferId: transferId ?? this.transferId,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'stripeAccountId': stripeAccountId,
      'gross': gross,
      'platformFee': platformFee,
      'net': net,
      'paid': paid,
      'transferId': transferId,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    };
  }
}

class UserModel {
  final String uid;
  final String email;
  final String name;
  final List<String> roles;
  final Address? address; // Changed to Address object
  final DateTime createdAt;
  final String? customerId; // Stripe customer ID
  final String? lastCheckoutSession;
  final String? lastOrderId;
  final DateTime? lastCheckoutTimestamp;
  // Stripe Connect fields for sellers
  final String? stripeAccountId; // Stripe Connect account ID
  final bool payoutsEnabled; // Can receive payouts
  final bool chargesEnabled; // Can accept charges
  final bool onboardingCompleted; // Completed Stripe onboarding
  final bool suspended;
  final DateTime? suspendedAt;
  final String paymentProvider; // stripe | airwallex
  final String? airwallexAccountId;
  final String? airwallexCustomerId;
  final String? airwallexStatus;
  // Seller-specific fields
  final double commissionRate; // Per-seller commission rate (default 0.025 = 2.5%)
  final bool verified; // Manual verification by admin
  final String? verificationStatus; // pending, approved, rejected
  final String? platform; // alibaba, dhgate, direct
  final String? country; // Seller's country (CN, CA, etc.)
  final String? businessName; // Company name for business sellers
  final int payoutHoldDays; // Custom hold period before payout (default 7)
  final List<String> pendingRequirements; // Stripe requirements still needed

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.roles,
    this.address, // Made optional since not all users may have an address
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
    this.paymentProvider = 'stripe',
    this.airwallexAccountId,
    this.airwallexCustomerId,
    this.airwallexStatus,
    this.commissionRate = 0.025, // Default 2.5%
    this.verified = false,
    this.verificationStatus,
    this.platform,
    this.country,
    this.businessName,
    this.payoutHoldDays = 7,
    this.pendingRequirements = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      roles: List<String>.from(map['roles'] ?? const []),
      address: map['address'] != null ? Address.fromMap(map['address'] as Map<String, dynamic>) : null,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customerId: map['customerId'] as String?,
      lastCheckoutSession: map['lastCheckoutSession'] as String?,
      lastOrderId: map['lastOrderId'] as String?,
      lastCheckoutTimestamp: (map['lastCheckoutTimestamp'] as Timestamp?)?.toDate(),
      stripeAccountId: map['stripeAccountId'] as String?,
      payoutsEnabled: map['payoutsEnabled'] ?? false,
      chargesEnabled: map['chargesEnabled'] ?? false,
      onboardingCompleted: map['onboardingCompleted'] ?? map['stripeOnboardingComplete'] ?? false,
      suspended: map['suspended'] ?? false,
      suspendedAt: (map['suspendedAt'] as Timestamp?)?.toDate(),
      paymentProvider: map['paymentProvider'] ?? 'stripe',
      airwallexAccountId: map['airwallexAccountId'] as String?,
      airwallexCustomerId: map['airwallexCustomerId'] as String?,
      airwallexStatus: map['airwallexStatus'] as String?,
      // Seller-specific fields
      commissionRate: (map['commissionRate'] as num?)?.toDouble() ?? 0.025,
      verified: map['verified'] ?? false,
      verificationStatus: map['verificationStatus'] as String?,
      platform: map['platform'] as String?,
      country: map['country'] as String?,
      businessName: map['businessName'] as String?,
      payoutHoldDays: map['payoutHoldDays'] ?? 7,
      pendingRequirements: List<String>.from(map['pendingRequirements'] ?? const []),
    );
  }

  /// Check if user is a seller or admin with payouts enabled
  bool get canReceivePayouts => (roles.contains(UserRoles.seller) || roles.contains(UserRoles.admin)) && payoutsEnabled && onboardingCompleted;

  /// Check if user can sell products (seller/admin + onboarding + payouts/charges enabled)
  bool get canSell =>
      (roles.contains(UserRoles.seller) || roles.contains(UserRoles.admin)) && onboardingCompleted && chargesEnabled && payoutsEnabled && !suspended;

  /// Check if user has pending Stripe requirements to complete
  bool get hasPendingRequirements => pendingRequirements.isNotEmpty;

  // copyWith method for updating specific fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    List<String>? roles,
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
    String? airwallexAccountId,
    String? airwallexCustomerId,
    String? airwallexStatus,
    double? commissionRate,
    bool? verified,
    String? verificationStatus,
    String? platform,
    String? country,
    String? businessName,
    int? payoutHoldDays,
    List<String>? pendingRequirements,
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
      lastCheckoutTimestamp: lastCheckoutTimestamp ?? this.lastCheckoutTimestamp,
      stripeAccountId: stripeAccountId ?? this.stripeAccountId,
      payoutsEnabled: payoutsEnabled ?? this.payoutsEnabled,
      chargesEnabled: chargesEnabled ?? this.chargesEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      suspended: suspended ?? this.suspended,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      paymentProvider: paymentProvider ?? this.paymentProvider,
      airwallexAccountId: airwallexAccountId ?? this.airwallexAccountId,
      airwallexCustomerId: airwallexCustomerId ?? this.airwallexCustomerId,
      airwallexStatus: airwallexStatus ?? this.airwallexStatus,
      commissionRate: commissionRate ?? this.commissionRate,
      verified: verified ?? this.verified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      platform: platform ?? this.platform,
      country: country ?? this.country,
      businessName: businessName ?? this.businessName,
      payoutHoldDays: payoutHoldDays ?? this.payoutHoldDays,
      pendingRequirements: pendingRequirements ?? this.pendingRequirements,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'roles': roles,
      'address': address?.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'customerId': customerId,
      if (lastCheckoutSession != null) 'lastCheckoutSession': lastCheckoutSession,
      if (lastOrderId != null) 'lastOrderId': lastOrderId,
      if (lastCheckoutTimestamp != null) 'lastCheckoutTimestamp': Timestamp.fromDate(lastCheckoutTimestamp!),
      if (stripeAccountId != null) 'stripeAccountId': stripeAccountId,
      'payoutsEnabled': payoutsEnabled,
      'chargesEnabled': chargesEnabled,
      'onboardingCompleted': onboardingCompleted,
      'suspended': suspended,
      if (suspendedAt != null) 'suspendedAt': Timestamp.fromDate(suspendedAt!),
      'paymentProvider': paymentProvider,
      if (airwallexAccountId != null) 'airwallexAccountId': airwallexAccountId,
      if (airwallexCustomerId != null) 'airwallexCustomerId': airwallexCustomerId,
      if (airwallexStatus != null) 'airwallexStatus': airwallexStatus,
      // Seller-specific fields
      'commissionRate': commissionRate,
      'verified': verified,
      if (verificationStatus != null) 'verificationStatus': verificationStatus,
      if (platform != null) 'platform': platform,
      if (country != null) 'country': country,
      if (businessName != null) 'businessName': businessName,
      'payoutHoldDays': payoutHoldDays,
      if (pendingRequirements.isNotEmpty) 'pendingRequirements': pendingRequirements,
    };
  }

  // Helper method to get cart subcollection reference
  static CollectionReference getCartCollection(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
  }

  // Helper method to get favorites subcollection reference
  static CollectionReference getFavoritesCollection(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');
  }
}
