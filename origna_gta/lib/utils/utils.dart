import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/screens/login_screen.dart';
import 'package:origna_gta/screens/privacy_policy_screen.dart';
import 'package:origna_gta/screens/terms_screen.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

export 'package:origna_gta/models/models.dart';

import 'package:url_launcher/url_launcher.dart';


// ============================================================================
// ERROR HANDLING UTILITIES
// ============================================================================

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

/// Maximum total keywords to generate (Firestore array limit consideration)
const int _maxKeywords = 100;

/// Maximum characters per word to generate prefixes for
const int _maxWordLength = 20;

final List<ProductCategories> productCategories = [
  ProductCategories(categoryId: 1, name: "Electronics", icon: Icons.devices),
  ProductCategories(categoryId: 2, name: "Computers", icon: Icons.computer),
  ProductCategories(categoryId: 3, name: "Gaming", icon: Icons.sports_esports),
  ProductCategories(categoryId: 4, name: "Home & Kitchen", icon: Icons.kitchen),
  ProductCategories(categoryId: 5, name: "Fashion", icon: Icons.shopping_bag),
  ProductCategories(
    categoryId: 6,
    name: "Shoes & Accessories",
    icon: Icons.backpack,
  ),
  ProductCategories(
    categoryId: 7,
    name: "Jewelry & Watches",
    icon: Icons.watch,
  ),
  ProductCategories(
    categoryId: 8,
    name: "Beauty & Personal Care",
    icon: Icons.spa,
  ),
  ProductCategories(
    categoryId: 9,
    name: "Health & Wellness",
    icon: Icons.favorite,
  ),
  ProductCategories(
    categoryId: 10,
    name: "Sports & Fitness",
    icon: Icons.fitness_center,
  ),
  ProductCategories(
    categoryId: 11,
    name: "Automotive",
    icon: Icons.directions_car,
  ),
  ProductCategories(
    categoryId: 12,
    name: "Tools & Hardware",
    icon: Icons.handyman,
  ),
  ProductCategories(
    categoryId: 13,
    name: "Office Supplies",
    icon: Icons.folder,
  ),
  ProductCategories(categoryId: 14, name: "Books", icon: Icons.book),
  ProductCategories(
    categoryId: 15,
    name: "Music & Instruments",
    icon: Icons.music_note,
  ),
  ProductCategories(categoryId: 16, name: "Toys & Games", icon: Icons.gamepad),
  ProductCategories(
    categoryId: 17,
    name: "Baby & Kids",
    icon: Icons.child_care,
  ),
  ProductCategories(categoryId: 18, name: "Pet Supplies", icon: Icons.pets),
  ProductCategories(
    categoryId: 19,
    name: "Groceries",
    icon: Icons.local_grocery_store,
  ),
  ProductCategories(
    categoryId: 20,
    name: "Art & Collectibles",
    icon: Icons.palette,
  ),
  ProductCategories(
    categoryId: 21,
    name: "Digital Products",
    icon: Icons.cloud,
  ),
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

Future<bool> addToCart({
  required String productId,
  required int quantity,
  required BuildContext context,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LoginScreen()));
    return false;
  }

  if (quantity <= 0) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid quantity'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  final cartItemRef = FirebaseFirestore.instance
      .collection(Collections.users)
      .doc(user.uid)
      .collection(Collections.cart)
      .doc(productId);

  try {
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(cartItemRef);

      if (snapshot.exists) {
        int currentQty = snapshot.data()?[Fields.quantity] ?? 0;
        transaction.update(cartItemRef, {
          Fields.quantity: currentQty + quantity,
        });
      } else {
        transaction.set(
          cartItemRef,
          CartModel(
            productId: productId,
            quantity: quantity,
            dateCreated: DateTime.now(),
          ).toMap(),
        );
      }
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e, stack) {
    AppError.log(e, stackTrace: stack, context: 'addToCart');
  }
  return true;
}

// Calculate detailed taxes based on selected province
Map<String, double> calculateDetailedTaxes(Address? address, double total) {
  if (address == null) return {};

  final province = address.state;
  final rates = provinceTaxRates[province] ?? {'GST': 0.05};

  Map<String, double> breakdown = {};
  rates.forEach((name, rate) {
    breakdown[name] = total * rate;
  });
  return breakdown;
}

/// Fallback shipping calculation when coordinates are unavailable.
/// Uses province-based flat rates.
double calculateFallbackShipping(
  List<CartItemDetailModel> items,
  String sellerProvince,
  String buyerProvince,
) {
  final totalItems = items.fold(0, (i, item) => i + item.quantity);
  double baseCost = 26.99;

  if (sellerProvince == buyerProvince) {
    baseCost = 12.99;
  } else if (_areAdjacentProvinces(sellerProvince, buyerProvince)) {
    baseCost = 18.99;
  } else if (_areSameRegion(sellerProvince, buyerProvince)) {
    baseCost = 22.99;
  }

  final additionalItemsCost =
      (totalItems - 1).clamp(0, 999) * (baseCost * 0.15);

  return baseCost + additionalItemsCost;
}

/// Calculate shipping cost based on distance, quantity, weight, and delivery speed.
/// Aligns with backend shipping_service.py for deterministic totals.
Future<double> calculateShippingCost(
  List<CartItemDetailModel> items,
  Address? buyerAddress, {
  DeliverySpeed chosenSpeed = DeliverySpeed.standard,
}) async {
  if (buyerAddress == null ||
      buyerAddress.latitude == null ||
      buyerAddress.longitude == null) {
    return 0.0;
  }

  double totalShipping = 0.0;
  final String apiKey = ConfigService().geoapifyKey;

  final Map<String, List<CartItemDetailModel>> itemsBySeller = {};
  for (var item in items) {
    itemsBySeller.putIfAbsent(item.sellerId, () => []).add(item);
  }

  for (var sellerItems in itemsBySeller.values) {
    final seller = sellerItems.first.sellerAddress;
    final sellerState = seller.state;
    final buyerState = buyerAddress.state;

    final chargeableItems = sellerItems.where((i) => !i.freeShipping).toList();
    if (chargeableItems.isEmpty) {
      continue;
    }

    final hasLocalRestriction = sellerItems.any(
      (i) => i.isLocalDeliveryOnly || i.isPerishable,
    );
    if (hasLocalRestriction && sellerState != buyerState) {
      totalShipping += 50.0;
    }

    final hasFixedPrice = _hasFixedPriceForSpeed(chargeableItems, chosenSpeed);
    if (hasFixedPrice.isEnabled) {
      totalShipping += hasFixedPrice.total;
      continue;
    }

    if (seller.latitude != null &&
        seller.longitude != null &&
        apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          "https://api.geoapify.com/v1/routematrix?apiKey=$apiKey",
        );
        final response = await http
            .post(
              url,
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "mode": "drive",
                "sources": [
                  {
                    "location": [seller.longitude, seller.latitude],
                  },
                ],
                "targets": [
                  {
                    "location": [buyerAddress.longitude, buyerAddress.latitude],
                  },
                ],
              }),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final distanceMeters =
              (data['sources_to_targets'] as List).first.first['distance']
                  as num? ??
              0;
          final distanceKm = distanceMeters / 1000.0;

          if (hasLocalRestriction && distanceKm > 100) {
            totalShipping += 75.0;
            continue;
          }

          totalShipping += _calculateTieredShipping(
            distanceKm,
            chargeableItems,
            chosenSpeed,
          );
          continue;
        }
      } catch (e, stack) {
        AppError.log(e, stackTrace: stack, context: 'calculateShippingCost');
      }
    }

    totalShipping += calculateFallbackShipping(
      chargeableItems,
      sellerState,
      buyerState,
    );
  }

  return totalShipping;
}

double calculateTieredShipping(
  double distanceKm,
  List<CartItemDetailModel> sellerItems,
  DeliverySpeed speed,
) {
  return _calculateTieredShipping(distanceKm, sellerItems, speed);
}

/// Helper to convert dynamic date/timestamp to Firestore Timestamp
Timestamp dynamicToTimestamp(dynamic value) {
  if (value is Timestamp) return value;
  if (value is DateTime) return Timestamp.fromDate(value);
  return Timestamp.now();
}

List<String> generateSearchKeywords(String name) {
  final cleanName = name.toLowerCase().trim();
  if (cleanName.isEmpty) return [''];

  final keywords = <String>{};
  final words = cleanName.split(RegExp(r'\s+'));

  for (final word in words) {
    final maxLen = word.length < _maxWordLength ? word.length : _maxWordLength;
    var temp = '';
    for (int i = 0; i < maxLen; i++) {
      temp += word[i];
      keywords.add(temp);
      if (keywords.length >= _maxKeywords) break;
    }
    if (keywords.length >= _maxKeywords) break;
  }

  keywords.add(cleanName);
  return keywords.toList();
}

Future<int> getCartItemCount(String userId) async {
  final query = FirebaseFirestore.instance
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.cart);

  final snapshot = await query.count().get();
  return snapshot.count ?? 0;
}

Stream<List<CartItemModel>> getCartStream(String userId) {
  return FirebaseFirestore.instance
      .collection(Collections.users)
      .doc(userId)
      .collection(Collections.cart)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => CartItemModel.fromMap(doc.data()))
            .toList();
      });
}

int getCrossAxisCount(BuildContext context) {
  if (TargetPlatform.android == defaultTargetPlatform ||
      TargetPlatform.iOS == defaultTargetPlatform) {
    return 2;
  }
  final width = MediaQuery.of(context).size.width;

  if (kIsWeb) {
    if (width < 600) {
      return 2;
    } else if (width < 1024) {
      return 3;
    } else {
      return 4;
    }
  } else {
    return 2;
  }
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

bool hasValidAddress(Address? address) {
  if (address == null) return false;
  return address.street.trim().isNotEmpty &&
      address.city.trim().isNotEmpty &&
      address.state.trim().isNotEmpty &&
      address.postalCode.trim().isNotEmpty &&
      address.country.trim().isNotEmpty;
}

bool isValidTaxCode(String? taxCode) {
  if (taxCode == null || taxCode.trim().isEmpty) return true;
  final value = taxCode.trim();
  return RegExp(r'^txcd_\d{8}$').hasMatch(value);
}

AddressDetails parseAddressSuggestion(Map<String, dynamic> suggestion) {
  final props = suggestion['properties'] ?? {};

  final houseNumber = props['housenumber'];
  final streetName = props['street'];
  final addressLine1 = [
    ?houseNumber,
    ?streetName,
  ].join(' ');

  return AddressDetails(
    street: props['formatted'] ?? addressLine1,
    city: props['city'] ?? '',
    state: props['state_code'] ?? 'ON',
    postalCode: props['postcode'] ?? '',
    latitude: (suggestion['geometry']?['coordinates']?[1] ?? 0).toDouble(),
    longitude: (suggestion['geometry']?['coordinates']?[0] ?? 0).toDouble(),
  );
}

// Add this helper method
void showLoginPrompt(
  BuildContext context, {
  String text = 'You need to sign in to add items to your cart.',
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sign In Required'),
      content: Text(text),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
          ),
          child: const Text('Sign In'),
        ),
      ],
    ),
  );
}

/// Show a dialog prompting the user to verify their email before proceeding.
/// [onResend] optional callback to resend verification email.
/// Returns true if user dismissed, false if they tapped resend.
void showEmailVerificationDialog(
  BuildContext context, {
  VoidCallback? onResend,
}) {
  final user = FirebaseAuth.instance.currentUser;
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFFFF3E0),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mark_email_unread_outlined,
          color: Color(0xFFF57C00),
          size: 36,
        ),
      ),
      title: const Text(
        'Email Verification Required',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (user?.email != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                user!.email!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667EEA),
                ),
              ),
            ),
          Text(
            'Please verify your email address to use this feature:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '  1. Check your email inbox',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '  2. Look in spam/junk folder if not found',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '  3. Click the verification link',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  '  4. Return here and try again',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          if (onResend != null) ...[
            const SizedBox(height: 16),
            Text(
              "Didn't receive the email?",
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (onResend != null)
          TextButton.icon(
            onPressed: () {
              onResend();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification email sent! Check your inbox.'),
                  backgroundColor: Color(0xFF667EEA),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Resend Email'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF667EEA),
            ),
          ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text('Got It'),
        ),
      ],
    ),
  );
}

/// Check if current user's email is verified. Returns true if verified or in emulator mode.
/// Shows dialog and returns false if not verified.
Future<bool> checkEmailVerifiedOrPrompt(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;

  // Emulator bypass
  if (EnvConfig().isEmulator) {
    return true;
  }

  await user.reload();
  final freshUser = FirebaseAuth.instance.currentUser;
  if (freshUser != null && freshUser.emailVerified) {
    return true;
  }

  if (context.mounted) {
    showEmailVerificationDialog(
      context,
      onResend: () async {
        try {
          await freshUser?.sendEmailVerification();
        } catch (_) {}
      },
    );
  }
  return false;
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

double _calculateTieredShipping(
  double distanceKm,
  List<CartItemDetailModel> sellerItems,
  DeliverySpeed speed,
) {
  double baseCost = 26.99;

  if (distanceKm <= 15) {
    baseCost = 1.99;
  } else if (distanceKm <= 50) {
    baseCost = 4.99;
  } else if (distanceKm <= 150) {
    baseCost = 9.99;
  } else if (distanceKm <= 500) {
    baseCost = 14.99;
  } else if (distanceKm <= 1200) {
    baseCost = 18.99;
  } else if (distanceKm <= 2500) {
    baseCost = 22.99;
  }

  double weightSurcharge = 0;
  int totalItems = 0;
  for (final item in sellerItems) {
    final qty = item.quantity;
    totalItems += qty;

    final actualWeight = item.weightKg ?? 0.5;
    final length = item.lengthCm ?? 10;
    final width = item.widthCm ?? 10;
    final height = item.heightCm ?? 10;
    final volWeight = (length * width * height) / 5000.0;
    final effectiveWeight = actualWeight > volWeight ? actualWeight : volWeight;

    if (effectiveWeight > 2.0) {
      weightSurcharge += (effectiveWeight - 2.0) * 1.5 * qty;
    }
  }

  final subtotal =
      baseCost +
      weightSurcharge +
      ((totalItems - 1).clamp(0, 999) * (baseCost * 0.15));

  double multiplier = 1.0;
  if (speed == DeliverySpeed.express) {
    if (distanceKm <= 15) {
      multiplier = 4.0;
    } else if (distanceKm <= 50) {
      multiplier = 1.6;
    } else if (distanceKm <= 150) {
      multiplier = 1.5;
    } else {
      multiplier = 1.6;
    }
  } else if (speed == DeliverySpeed.sameDay) {
    if (distanceKm <= 15) {
      multiplier = 4.5;
    } else if (distanceKm <= 50) {
      multiplier = 1.8;
    } else if (distanceKm <= 150) {
      multiplier = 1.8;
    } else {
      multiplier = 2.5;
    }
  }

  return subtotal * multiplier;
}

_FixedPriceResult _hasFixedPriceForSpeed(
  List<CartItemDetailModel> items,
  DeliverySpeed speed,
) {
  double total = 0;
  for (final item in items) {
    final matches = item.deliveryOptions.where((o) => o.type == speed.value);
    if (matches.isEmpty) {
      return const _FixedPriceResult(isEnabled: false, total: 0);
    }

    final option = matches.first;
    final cost = option.calculateCostForQuantity(item.quantity);
    // Keep legacy behavior: only treat as fixed-price shipping when cost is positive.
    // `freeShipping` is handled separately via the product flag.
    if (cost.isNaN || cost.isInfinite || cost <= 0) {
      return const _FixedPriceResult(isEnabled: false, total: 0);
    }

    total += cost;
  }

  return _FixedPriceResult(isEnabled: true, total: total);
}

/// Centralized error handler - logs to console and Sentry
/// Use this for all caught errors to ensure visibility
class AppError {
  /// Extract user-friendly message from error
  static String getMessage(dynamic error) {
    if (error is FirebaseException) {
      return error.message ?? 'An error occurred';
    }
    if (error is Exception) {
      final message = error.toString();
      // Remove "Exception: " prefix if present
      if (message.startsWith('Exception: ')) {
        return message.substring(11);
      }
      return message;
    }
    return error?.toString() ?? 'An unexpected error occurred';
  }

  /// Log error with optional user message
  /// - Logs to debugPrint in development
  /// - Sends to Sentry in production
  static void log(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? extras,
  }) {
    final contextPrefix = context != null ? '[$context] ' : '';
    debugPrint('$contextPrefix$error');
    if (stackTrace != null) {
      debugPrint('$stackTrace');
    }

    // Send to Sentry (non-blocking)
    Sentry.captureException(
      error,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (context != null) {
          scope.setTag('context', context);
        }
        if (extras != null) {
          scope.setContexts('extras', extras);
        }
      },
    );
  }

  /// Show error to user via SnackBar and log it
  static void show(
    BuildContext context,
    String userMessage, {
    dynamic error,
    StackTrace? stackTrace,
    String? logContext,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Log the error
    if (error != null) {
      log(error, stackTrace: stackTrace, context: logContext);
    }

    // Show user-friendly message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: Colors.red,
        duration: duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class _FixedPriceResult {
  final bool isEnabled;
  final double total;

  const _FixedPriceResult({required this.isEnabled, required this.total});
}

// ============================================================================
// LEGAL PAGE NAVIGATION - OAuth Compliance
// ============================================================================

Future<void> _launchPath(String path) async {
  // Ensure you use https://
  final Uri url = Uri.parse('https://orignagta.ca$path');
  
  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Could not launch $url');
  }
}
/// Opens Privacy Policy page
/// On web: navigates to /privacy-policy URL (required for OAuth verification)
/// On mobile: shows in-app screen
void openPrivacyPolicy(BuildContext context) {
  if (kIsWeb) {
    // Navigate to actual URL for OAuth compliance
    _launchPath('/privacy-policy');
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }
}

/// Opens Terms of Service page
/// On web: navigates to /terms-of-service URL (required for OAuth verification)
/// On mobile: shows in-app screen
void openTermsOfService(BuildContext context) {
  if (kIsWeb) {
    // Navigate to actual URL for OAuth compliance
    _launchPath('/terms-of-service');
   
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  }
}
