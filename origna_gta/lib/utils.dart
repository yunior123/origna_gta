import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:origna_gta/constants.dart';
import 'package:origna_gta/login_screen.dart';
import 'package:origna_gta/services/conf_services.dart';

// Add these to your constants or helper section
const Map<String, Map<String, double>> provinceTaxRates = {
  'AB': {'GST': 0.05},
  'BC': {'GST': 0.05, 'PST': 0.07},
  'MB': {'GST': 0.05, 'PST': 0.07},
  'NB': {'HST': 0.15},
  'NL': {'HST': 0.15},
  'NS': {'HST': 0.15},
  'NT': {'GST': 0.05},
  'NU': {'GST': 0.05},
  'ON': {'HST': 0.13},
  'PE': {'HST': 0.15},
  'QC': {'GST': 0.05, 'QST': 0.09975},
  'SK': {'GST': 0.05, 'PST': 0.06},
  'YT': {'GST': 0.05},
};

final List<ProductCategories> productCategories = [
  ProductCategories(categoryId: 1, name: "Electronics", icon: Icons.devices),
  ProductCategories(categoryId: 2, name: "Computers", icon: Icons.computer),
  ProductCategories(categoryId: 3, name: "Gaming", icon: Icons.sports_esports),
  ProductCategories(categoryId: 4, name: "Home & Kitchen", icon: Icons.kitchen),
  ProductCategories(categoryId: 5, name: "Fashion", icon: Icons.shopping_bag),
  ProductCategories(categoryId: 6, name: "Shoes & Accessories", icon: Icons.backpack),
  ProductCategories(categoryId: 7, name: "Jewelry & Watches", icon: Icons.watch),
  ProductCategories(categoryId: 8, name: "Beauty & Personal Care", icon: Icons.spa),
  ProductCategories(categoryId: 9, name: "Health & Wellness", icon: Icons.favorite),
  ProductCategories(categoryId: 10, name: "Sports & Fitness", icon: Icons.fitness_center),
  ProductCategories(categoryId: 11, name: "Automotive", icon: Icons.directions_car),
  ProductCategories(categoryId: 12, name: "Tools & Hardware", icon: Icons.handyman),
  ProductCategories(categoryId: 13, name: "Office Supplies", icon: Icons.folder),
  ProductCategories(categoryId: 14, name: "Books", icon: Icons.book),
  ProductCategories(categoryId: 15, name: "Music & Instruments", icon: Icons.music_note),
  ProductCategories(categoryId: 16, name: "Toys & Games", icon: Icons.gamepad),
  ProductCategories(categoryId: 17, name: "Baby & Kids", icon: Icons.child_care),
  ProductCategories(categoryId: 18, name: "Pet Supplies", icon: Icons.pets),
  ProductCategories(categoryId: 19, name: "Groceries", icon: Icons.local_grocery_store),
  ProductCategories(categoryId: 20, name: "Art & Collectibles", icon: Icons.palette),
  ProductCategories(categoryId: 21, name: "Digital Products", icon: Icons.cloud),
];

// Provincial tax configuration
final taxConfig = {
  'AB': {'GST': 0.05},
  'BC': {'GST': 0.05, 'PST': 0.07},
  'MB': {'GST': 0.05, 'PST': 0.07},
  'NB': {'HST': 0.15},
  'NL': {'HST': 0.15},
  'NT': {'GST': 0.05},
  'NS': {'HST': 0.15},
  'NU': {'GST': 0.05},
  'ON': {'HST': 0.13},
  'PE': {'HST': 0.15},
  'QC': {'GST': 0.05, 'QST': 0.09975},
  'SK': {'GST': 0.05, 'PST': 0.06},
  'YT': {'GST': 0.05},
};

Future<bool> addToCart({required String productId, required int quantity, required BuildContext context}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    // Navigate to login screen
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoginScreen()));
    return false;
  }

  // Change: Access the cart as a sub-collection instead of a user document field
  final cartItemRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('cart').doc(productId);

  try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(cartItemRef);

      if (snapshot.exists) {
        // Increment quantity if item already exists
        int currentQty = snapshot.data()?['quantity'] ?? 0;
        transaction.update(cartItemRef, {'quantity': currentQty + quantity});
      } else {
        // Add new cart item document
        transaction.set(cartItemRef, CartModel(productId: productId, quantity: quantity, dateCreated: DateTime.now()).toMap());
      }
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart updated'), backgroundColor: Colors.green));
    }
  } catch (e) {
    debugPrint('Error updating cart: $e');
  }
  return true;
}

// Calculate detailed taxes based on selected province
Map<String, double> calculateDetailedTaxes(Address? address, double total) {
  if (address == null) return {};

  final province = address.state; // Ensure Address model has stateCode
  final rates = provinceTaxRates[province] ?? {'GST': 0.05}; // Default to GST if unknown

  Map<String, double> breakdown = {};
  rates.forEach((name, rate) {
    breakdown[name] = total * rate;
  });
  return breakdown;
}

/// Calculate shipping cost based on distance and item quantity.
/// Uses a tiered pricing model that reflects real Canadian shipping costs:
/// - Local (0-50km): Base rate
/// - Regional (50-500km): Moderate rate
/// - Provincial (500-1500km): Higher rate
/// - National (1500km+): Uses flat rates similar to Canada Post
Future<double> calculateShippingCost(List<CartItemDetailModel> items, Address? buyerAddress) async {
  if (buyerAddress == null || buyerAddress.latitude == null || buyerAddress.longitude == null) {
    return 0.0;
  }

  double totalShipping = 0.0;
  final String apiKey = ConfigService().geoapifyKey;

  // Group items by seller to calculate shipping per seller
  final Map<String, List<CartItemDetailModel>> itemsBySeller = {};
  for (var item in items) {
    itemsBySeller.putIfAbsent(item.sellerId, () => []).add(item);
  }

  for (var sellerItems in itemsBySeller.values) {
    final seller = sellerItems.first.sellerAddress;
    if (seller.latitude == null || seller.longitude == null) {
      // Fallback: use flat rate if no coordinates
      totalShipping += _calculateFallbackShipping(sellerItems, seller.state, buyerAddress.state);
      continue;
    }

    final url = Uri.parse("https://api.geoapify.com/v1/routematrix?apiKey=$apiKey");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "mode": "drive",
          "sources": [{"location": [seller.longitude, seller.latitude]}],
          "targets": [{"location": [buyerAddress.longitude, buyerAddress.latitude]}],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final distanceKm = data['sources_to_targets'][0][0]['distance'] / 1000.0;

        // Calculate total items from this seller
        final totalItems = sellerItems.fold(0, (qty, item) => qty + item.quantity);

        // Calculate shipping using tiered model
        totalShipping += _calculateTieredShipping(distanceKm, totalItems);
      } else {
        // API failed, use fallback
        totalShipping += _calculateFallbackShipping(sellerItems, seller.state, buyerAddress.state);
      }
    } catch (e) {
      debugPrint('Error calculating shipping: $e');
      // Use fallback on error
      totalShipping += _calculateFallbackShipping(sellerItems, seller.state, buyerAddress.state);
    }
  }

  return totalShipping;
}

/// Tiered shipping calculation based on distance.
/// Reflects realistic Canadian shipping costs.
double _calculateTieredShipping(double distanceKm, int itemCount) {
  double baseCost;

  if (distanceKm <= 50) {
    // Local delivery (same city/area)
    baseCost = 5.99;
  } else if (distanceKm <= 150) {
    // Regional (nearby cities)
    baseCost = 8.99;
  } else if (distanceKm <= 500) {
    // Provincial (within province)
    baseCost = 12.99;
  } else if (distanceKm <= 1000) {
    // Inter-provincial (adjacent provinces)
    baseCost = 16.99;
  } else if (distanceKm <= 2000) {
    // Cross-country (e.g., ON to AB)
    baseCost = 22.99;
  } else if (distanceKm <= 4000) {
    // Coast to coast (e.g., BC to NS)
    baseCost = 28.99;
  } else {
    // Very far (e.g., northern territories)
    baseCost = 34.99;
  }

  // Additional items add incremental cost (simulating weight/volume)
  // First item is base, each additional adds 20% of base
  final additionalItemsCost = (itemCount - 1) * (baseCost * 0.2);

  // Cap additional cost at 50% of base for large orders
  final cappedAdditional = additionalItemsCost > (baseCost * 0.5)
      ? baseCost * 0.5
      : additionalItemsCost;

  return baseCost + cappedAdditional;
}

/// Fallback shipping calculation when coordinates are unavailable.
/// Uses province-based flat rates.
double _calculateFallbackShipping(List<CartItemDetailModel> items, String sellerProvince, String buyerProvince) {
  final totalItems = items.fold(0, (i, item) => i + item.quantity);
  double baseCost;

  if (sellerProvince == buyerProvince) {
    // Same province
    baseCost = 12.99;
  } else if (_areAdjacentProvinces(sellerProvince, buyerProvince)) {
    // Adjacent provinces
    baseCost = 18.99;
  } else if (_areSameRegion(sellerProvince, buyerProvince)) {
    // Same region (East, Central, West, North)
    baseCost = 24.99;
  } else {
    // Cross-country
    baseCost = 29.99;
  }

  // Additional items cost
  final additionalCost = (totalItems - 1) * (baseCost * 0.2);
  final cappedAdditional = additionalCost > (baseCost * 0.5) ? baseCost * 0.5 : additionalCost;

  return baseCost + cappedAdditional;
}

/// Check if two provinces are adjacent
bool _areAdjacentProvinces(String p1, String p2) {
  const adjacency = {
    'BC': ['AB', 'YT', 'NT'],
    'AB': ['BC', 'SK', 'NT'],
    'SK': ['AB', 'MB', 'NT', 'NU'],
    'MB': ['SK', 'ON', 'NU'],
    'ON': ['MB', 'QC'],
    'QC': ['ON', 'NB', 'NL'],
    'NB': ['QC', 'NS', 'PE'],
    'NS': ['NB', 'PE'],
    'PE': ['NB', 'NS'],
    'NL': ['QC'],
    'YT': ['BC', 'NT'],
    'NT': ['BC', 'AB', 'SK', 'YT', 'NU'],
    'NU': ['SK', 'MB', 'NT'],
  };

  return adjacency[p1]?.contains(p2) ?? false;
}

/// Check if two provinces are in the same region
bool _areSameRegion(String p1, String p2) {
  const regions = {
    'West': ['BC', 'AB'],
    'Prairies': ['SK', 'MB'],
    'Central': ['ON', 'QC'],
    'Atlantic': ['NB', 'NS', 'PE', 'NL'],
    'North': ['YT', 'NT', 'NU'],
  };

  for (var region in regions.values) {
    if (region.contains(p1) && region.contains(p2)) {
      return true;
    }
  }
  return false;
}

List<String> generateSearchKeywords(String name) {
  List<String> keywords = [];
  String cleanName = name.toLowerCase().trim();

  // Split the name into individual words (e.g., "Nike Shoe" -> ["nike", "shoe"])
  List<String> words = cleanName.split(' ');

  for (String word in words) {
    String temp = "";
    for (int i = 0; i < word.length; i++) {
      temp += word[i];
      keywords.add(temp);
    }
  }

  // Also add the full name as one string for exact full-name matches
  keywords.add(cleanName);

  return keywords.toSet().toList(); // Remove duplicates
}

Future<int> getCartItemCount(String userId) async {
  final query = FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');

  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<CartItemModel>> getCartStream(String userId) {
  return FirebaseFirestore.instance.collection('users').doc(userId).collection('cart').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => CartItemModel.fromMap(doc.data())).toList();
  });
}

double getTaxRate(String province) {
  const taxRates = {
    'AB': 0.05,
    'BC': 0.12,
    'MB': 0.12,
    'NB': 0.15,
    'NL': 0.15,
    'NT': 0.05,
    'NS': 0.15,
    'NU': 0.05,
    'ON': 0.13,
    'PE': 0.15,
    'QC': 0.14975,
    'SK': 0.11,
    'YT': 0.05,
  };
  return taxRates[province] ?? 0.13;
}

AddressDetails parseAddressSuggestion(Map<String, dynamic> suggestion) {
  final props = suggestion['properties'] ?? {};

  final houseNumber = props['housenumber'];
  final streetName = props['street'];
  final addressLine1 = [if (houseNumber != null) houseNumber, if (streetName != null) streetName].join(' ');

  return AddressDetails(
    street: props['formatted'] ?? addressLine1,
    city: props['city'] ?? '',
    province: props['state_code'] ?? 'ON',
    postalCode: props['postcode'] ?? '',
    latitude: (suggestion['geometry']?['coordinates']?[1] ?? 0).toDouble(),
    longitude: (suggestion['geometry']?['coordinates']?[0] ?? 0).toDouble(),
  );
}

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
  });

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
    };
  }

  // Convert Firestore Map to CartItemDetailModel
  factory CartItemDetailModel.fromMap(Map<String, dynamic> map) {
    return CartItemDetailModel(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      quantity: map['quantity'] ?? 0,
      dateCreated: (map['dateCreated'] as Timestamp?) ?? Timestamp.now(),
      sellerAddress: Address.fromMap(map['sellerAddress'] as Map<String, dynamic>),
      sellerId: map['sellerId'] ?? '',
      deliveryStatus: map['deliveryStatus'] ?? DeliveryStatus.pending.value,
      trackingNumber: map['trackingNumber'],
      confirmedByBuyer: map['confirmedByBuyer'] ?? false,
    );
  }
}

int getCrossAxisCount(BuildContext context) {
  if (TargetPlatform.android == defaultTargetPlatform || TargetPlatform.iOS == defaultTargetPlatform) {
    return 2;
  }
  final width = MediaQuery.of(context).size.width;

  if (kIsWeb) {
    if (width < 600) {
      return 2; // Mobile browser
    } else if (width < 1024) {
      return 3; // Tablet / small desktop
    } else {
      return 4; // Desktop
    }
  } else {
    return 2; // Mobile app
  }
}

class CartItemModel {
  final int quantity;
  final String productId;
  final Timestamp dateCreated;
  CartItemModel({required this.quantity, required this.productId, required this.dateCreated});
  factory CartItemModel.fromMap(Map<String, dynamic> map) {
    return CartItemModel(quantity: map['quantity'] ?? 0, productId: map['productId'] ?? '', dateCreated: map['dateCreated'] ?? Timestamp.now());
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
    return CartModel(productId: map['productId'] ?? '', quantity: map['quantity'] ?? 1, dateCreated: (map['dateCreated'] as Timestamp).toDate());
  }

  Map<String, dynamic> toMap() {
    return {'productId': productId, 'quantity': quantity, 'dateCreated': Timestamp.fromDate(dateCreated)};
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
  final Map<String, dynamic> deliveryInfo;
  final DateTime createdAt;
  final String currency;
  final int amount;
  final List<String> sellerIds;
  final String stripeSessionId;
  // Payout tracking fields
  final List<SellerPayout> sellerPayouts; // Per-seller payout breakdown
  final bool confirmedByClient; // Client confirmed receipt
  final DateTime? confirmedAt; // When order was confirmed by client
  final double platformFeeTotal; // Total platform fee for this order
  final String payoutStatus; // 'pending', 'processing', 'completed', 'partial'

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
    this.sellerPayouts = const [],
    this.confirmedByClient = false,
    this.confirmedAt,
    this.platformFeeTotal = 0.0,
    this.payoutStatus = 'pending',
  });

  /// Check if all delivered items have been confirmed by buyer
  bool get allItemsConfirmed {
    final deliveredItems = items.where((i) => i.deliveryStatus == DeliveryStatus.delivered.value);
    return deliveredItems.isNotEmpty && deliveredItems.every((i) => i.confirmedByBuyer);
  }

  /// Check if all sellers have been paid
  bool get allSellersPaid => sellerPayouts.isNotEmpty && sellerPayouts.every((p) => p.paid);

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
        quantity: map['quantity'] ?? 0,
        dateCreated: map['dateCreated'] as Timestamp,
        sellerAddress: Address.fromMap(map['sellerAddress'] as Map<String, dynamic>),
        sellerId: map['sellerId'] ?? '',
        deliveryStatus: map['deliveryStatus'] ?? DeliveryStatus.pending.value,
        trackingNumber: map['trackingNumber'],
        confirmedByBuyer: map['confirmedByBuyer'] ?? false,
      );
    }).toList();

    // Parse seller payouts
    final payoutsData = data['sellerPayouts'] as List<dynamic>? ?? [];
    final sellerPayouts = payoutsData.map((p) => SellerPayout.fromMap(p as Map<String, dynamic>)).toList();

    return OrderModel(
      orderId: doc.id,
      userId: data['userId'] ?? '',
      items: items,
      total: (data['total'] ?? 0).toDouble(),
      status: data['status'] ?? OrderStatus.pending.value,
      deliveryInfo: data['deliveryInfo'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      customerId: data['customerId'] ?? '',
      customerEmail: data['customerEmail'] ?? '',
      taxes: Map<String, double>.from(data['taxes'] ?? {}),
      shippingCost: (data['shippingCost'] ?? 0).toDouble(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      amount: (data['amount'] ?? 0),
      currency: data["currency"] ?? '',
      sellerIds: List<String>.from(data["sellerIds"] ?? []),
      stripeSessionId: data["stripeSessionId"] ?? "",
      sellerPayouts: sellerPayouts,
      confirmedByClient: data['confirmedByClient'] ?? false,
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      platformFeeTotal: (data['platformFeeTotal'] ?? 0).toDouble(),
      payoutStatus: data['payoutStatus'] ?? 'pending',
    );
  }

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
      'confirmedByClient': confirmedByClient,
      if (confirmedAt != null) 'confirmedAt': Timestamp.fromDate(confirmedAt!),
      'platformFeeTotal': platformFeeTotal,
      'payoutStatus': payoutStatus,
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
  final bool isLocalDeliveryOnly; // For food/perishables - same day local delivery
  final int estimatedShipDays; // Seller's estimated shipping time in days
  final String? taxCode; // Optional Stripe Tax Code (e.g. txcd_10000000)

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
    required this.searchKeywords,
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
  });

  factory ProductModel.fromDocument(DocumentSnapshot doc) {
    assert(doc.data() != null, 'Product document data is null');
    final data = doc.data() as Map<String, dynamic>;

    assert(data.containsKey('name'), 'Product missing "name"');
    assert(data.containsKey('price'), 'Product missing "price"');
    assert(data.containsKey('categoryId'), 'Product missing "categoryId"');

    return ProductModel.fromMap({...data, 'id': doc.id});
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id']?.toString() ?? '',
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
      searchKeywords: _parseStringList(map['searchKeywords']),
      stockQuantity: _parseInt(map['stockQuantity']),
      weightKg: map['weightKg'] != null ? _parseDouble(map['weightKg']) : null,
      lengthCm: map['lengthCm'] != null ? _parseDouble(map['lengthCm']) : null,
      widthCm: map['widthCm'] != null ? _parseDouble(map['widthCm']) : null,
      heightCm: map['heightCm'] != null ? _parseDouble(map['heightCm']) : null,
      isLocalDeliveryOnly: map['isLocalDeliveryOnly'] ?? false,
      estimatedShipDays: _parseInt(map['estimatedShipDays']),
      taxCode: map['taxCode']?.toString(),
    );
  }

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
      'searchKeywords': searchKeywords,
      if (weightKg != null) 'weightKg': weightKg,
      if (lengthCm != null) 'lengthCm': lengthCm,
      if (widthCm != null) 'widthCm': widthCm,
      if (heightCm != null) 'heightCm': heightCm,
      'isLocalDeliveryOnly': isLocalDeliveryOnly,
      'estimatedShipDays': estimatedShipDays,
      if (taxCode != null) 'taxCode': taxCode,
    };
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

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static Address _parseAddress(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Address.fromMap(value);
    }
    return Address.fromMap({});
  }
}

// Model for favorite items in subcollection
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
      onboardingCompleted: map['onboardingCompleted'] ?? false,
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
    };
  }

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
    );
  }

  /// Check if user is a seller or admin with payouts enabled
  bool get canReceivePayouts =>
      (roles.contains(UserRoles.seller) || roles.contains(UserRoles.admin)) &&
      payoutsEnabled &&
      onboardingCompleted;

  // Helper method to get favorites subcollection reference
  static CollectionReference getFavoritesCollection(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites');
  }

  // Helper method to get cart subcollection reference
  static CollectionReference getCartCollection(String userId) {
    return FirebaseFirestore.instance.collection('users').doc(userId).collection('cart');
  }
}

// Add this helper method
void showLoginPrompt(BuildContext context, {String text = 'You need to sign in to add items to your cart.'}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign In Required'),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen()));
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
          child: const Text('Sign In'),
        ),
      ],
    ),
  );
}