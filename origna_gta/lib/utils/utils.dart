import 'package:origna_gta/core/compat/timestamp.dart';
import 'package:orignabase/orignabase.dart'
    show OrignaBase, OrignaBaseException;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/errors/error_codes.dart';
import 'package:origna_gta/core/repositories/orignabase_auth_repository.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/models/models.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/app_logger.dart';
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/env_config.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

export 'package:origna_gta/models/models.dart';

// ============================================================================
// ERROR HANDLING UTILITIES
// ============================================================================

/// Canadian provincial/territorial tax rates for client-side estimation.
///
/// Keys are 2-letter province codes. Values map tax type to rate.
/// HST provinces have a single combined rate; others split GST + PST/QST.
/// NOTE: These are frontend estimates only — the backend uses Stripe Tax API.
const Map<String, Map<String, double>> provinceTaxRates = {
  'AB': {'GST': 0.05},
  'BC': {'GST': 0.05, 'PST': 0.07},
  'MB': {'GST': 0.05, 'PST': 0.07},
  'NB': {'HST': 0.15},
  'NL': {'HST': 0.15},
  'NS': {'HST': 0.14}, // Changed from 15% to 14% on April 1, 2025 (CRA)
  'NT': {'GST': 0.05},
  'NU': {'GST': 0.05},
  'ON': {'HST': 0.13},
  'PE': {'HST': 0.15},
  'QC': {'GST': 0.05, 'QST': 0.09975},
  'SK': {'GST': 0.05, 'PST': 0.06},
  'YT': {'GST': 0.05},
};

/// Maximum total keywords to generate for search prefixes.
const int _maxKeywords = 30;

/// Maximum characters per word to generate prefixes for
const int _maxWordLength = 20;

final List<ProductCategories> productCategories = [
  ProductCategories(
    categoryId: 1,
    name: "categories.electronics",
    icon: Icons.devices,
  ),
  ProductCategories(
    categoryId: 2,
    name: "categories.computers",
    icon: Icons.computer,
  ),
  ProductCategories(
    categoryId: 3,
    name: "categories.gaming",
    icon: Icons.sports_esports,
  ),
  ProductCategories(
    categoryId: 4,
    name: "categories.home_kitchen",
    icon: Icons.kitchen,
  ),
  ProductCategories(
    categoryId: 5,
    name: "categories.fashion",
    icon: Icons.shopping_bag,
  ),
  ProductCategories(
    categoryId: 6,
    name: "categories.shoes_accessories",
    icon: Icons.backpack,
  ),
  ProductCategories(
    categoryId: 7,
    name: "categories.jewelry_watches",
    icon: Icons.watch,
  ),
  ProductCategories(
    categoryId: 8,
    name: "categories.beauty_personal_care",
    icon: Icons.spa,
  ),
  ProductCategories(
    categoryId: 9,
    name: "categories.health_wellness",
    icon: Icons.favorite,
  ),
  ProductCategories(
    categoryId: 10,
    name: "categories.sports_fitness",
    icon: Icons.fitness_center,
  ),
  ProductCategories(
    categoryId: 11,
    name: "categories.automotive",
    icon: Icons.directions_car,
  ),
  ProductCategories(
    categoryId: 12,
    name: "categories.tools_hardware",
    icon: Icons.handyman,
  ),
  ProductCategories(
    categoryId: 13,
    name: "categories.office_supplies",
    icon: Icons.folder,
  ),
  ProductCategories(categoryId: 14, name: "categories.books", icon: Icons.book),
  ProductCategories(
    categoryId: 15,
    name: "categories.music_instruments",
    icon: Icons.music_note,
  ),
  ProductCategories(
    categoryId: 16,
    name: "categories.toys_games",
    icon: Icons.gamepad,
  ),
  ProductCategories(
    categoryId: 17,
    name: "categories.baby_kids",
    icon: Icons.child_care,
  ),
  ProductCategories(
    categoryId: 18,
    name: "categories.pet_supplies",
    icon: Icons.pets,
  ),
  ProductCategories(
    categoryId: 19,
    name: "categories.groceries",
    icon: Icons.local_grocery_store,
  ),
  ProductCategories(
    categoryId: 20,
    name: "categories.art_collectibles",
    icon: Icons.palette,
  ),
  ProductCategories(
    categoryId: 21,
    name: "categories.digital_products",
    icon: Icons.cloud,
  ),
];

// Provincial tax configuration — single source of truth
// Used by checkout_screen.dart _buildTaxBreakdown() and getTaxRate()
// NOTE: These are FRONTEND ESTIMATES only. The backend uses Stripe Tax API
// for the authoritative calculation (which includes shipping in the tax base).
final taxConfig = provinceTaxRates;

/// Calculates per-tax-type breakdown for display (e.g., GST: $2.50, QST: $4.99).
///
/// [total] is in dollars. Returns empty map if address is null.
/// Uses the province from [address.state] to look up applicable rates.
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
/// Returns a Map of sellerId to shipping cost.
Future<Map<String, double>> calculateShippingCost(
  List<CartItemDetailModel> items,
  Address? buyerAddress, {
  DeliverySpeed chosenSpeed = DeliverySpeed.standard,
  OrignaBase? ob,
}) async {
  if (buyerAddress == null ||
      buyerAddress.latitude == null ||
      buyerAddress.longitude == null) {
    return {};
  }

  final Map<String, double> sellerCosts = {};

  final Map<String, List<CartItemDetailModel>> itemsBySeller = {};
  for (var item in items) {
    itemsBySeller.putIfAbsent(item.sellerId, () => []).add(item);
  }

  for (var entry in itemsBySeller.entries) {
    final sellerId = entry.key;
    final sellerItems = entry.value;
    double sellerTotal = 0.0;

    final seller = sellerItems.first.sellerAddress;
    final sellerState = seller.state;
    final buyerState = buyerAddress.state;

    final chargeableItems = sellerItems.where((i) => !i.freeShipping).toList();
    if (chargeableItems.isEmpty) {
      sellerCosts[sellerId] = 0.0;
      continue;
    }

    final hasLocalRestriction = sellerItems.any(
      (i) => i.isLocalDeliveryOnly || i.isPerishable,
    );
    if (hasLocalRestriction && sellerState != buyerState) {
      sellerTotal += 50.0;
    }

    final hasFixedPrice = _hasFixedPriceForSpeed(chargeableItems, chosenSpeed);
    if (hasFixedPrice.isEnabled) {
      sellerTotal += hasFixedPrice.total;
      sellerCosts[sellerId] = sellerTotal;
      continue;
    }

    if (seller.latitude != null && seller.longitude != null && ob != null) {
      try {
        // Proxy route matrix through OrignaBase — API key stays server-side.
        final response = await ob.request(
          'POST',
          ApiEndpoints.geocodeRouteMatrix,
          body: {
            'sources': [
              {
                'location': [seller.longitude, seller.latitude],
              },
            ],
            'targets': [
              {
                'location': [buyerAddress.longitude, buyerAddress.latitude],
              },
            ],
          },
        );

        final sourcesToTargets = response['sources_to_targets'];
        if (sourcesToTargets is List && sourcesToTargets.isNotEmpty) {
          final firstRow = sourcesToTargets.first;
          final firstCell = firstRow is List && firstRow.isNotEmpty
              ? firstRow.first
              : firstRow;
          final distanceMeters =
              (firstCell is Map ? firstCell['distance'] as num? : null) ?? 0;
          final distanceKm = distanceMeters / 1000.0;

          if (hasLocalRestriction && distanceKm > 100) {
            sellerTotal += 75.0;
            sellerCosts[sellerId] = sellerTotal;
            continue;
          }

          sellerTotal += _calculateTieredShipping(
            distanceKm,
            chargeableItems,
            chosenSpeed,
          );
          sellerCosts[sellerId] = sellerTotal;
          continue;
        }
      } catch (e, stack) {
        AppError.log(e, stackTrace: stack, context: 'calculateShippingCost');
      }
    }

    sellerTotal += calculateFallbackShipping(
      chargeableItems,
      sellerState,
      buyerState,
    );
    sellerCosts[sellerId] = sellerTotal;
  }

  return sellerCosts;
}

double calculateTieredShipping(
  double distanceKm,
  List<CartItemDetailModel> sellerItems,
  DeliverySpeed speed,
) {
  return _calculateTieredShipping(distanceKm, sellerItems, speed);
}

/// Check if current user's email is verified. Returns true if verified or in emulator mode.
/// Shows dialog and returns false if not verified.
Future<bool> checkEmailVerifiedOrPrompt(
  BuildContext context,
  WidgetRef ref,
) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return false;

  // BOOT-H1: emulator bypass is intentional for local dev only.
  // Restricted to kDebugMode to ensure it cannot fire in release builds.
  // Logs a warning so behavior divergence is visible during development.
  if (EnvConfig().isEmulator && kDebugMode) {
    AppLogger.w(
      'BOOT-H1: email verification bypassed in emulator mode',
      tag: 'auth',
    );
    return true;
  }

  try {
    final verified = await ref.read(authRepositoryProvider).isEmailVerified();
    if (verified) return true;
  } catch (e) {
    AppLogger.w(
      'checkEmailVerifiedOrPrompt: verification check failed: $e',
      tag: 'auth',
    );
    if (EnvConfig().isEmulator) return true;
  }

  if (context.mounted) {
    showEmailVerificationDialog(
      context,
      email: user.email,
      onResend: () async {
        try {
          await ref.read(authRepositoryProvider).sendEmailVerification();
        } catch (_) {}
      },
    );
  }
  return false;
}

/// Robustly parse a dynamic value (Timestamp, String, DateTime, int) to DateTime?
/// Handles both seconds and milliseconds for integer input.
DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    // Heuristic: if the value is in a range that looks like seconds for
    // recent/near-future dates (2010-2100), treat it as seconds.
    // 1262304000 is 2010-01-01. 4102444800 is 2100-01-01.
    if (value >= 1262304000 && value <= 4102444800) {
      return DateTime.fromMillisecondsSinceEpoch(value * 1000);
    }
    // Otherwise assume milliseconds (common in Dart/JS)
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  try {
    // Handle legacy or third-party timestamp-like objects
    final converted = (value as dynamic).toDate();
    if (converted is DateTime) return converted;
  } catch (_) {
    // Ignore objects that do not expose a toDate() method returning DateTime
  }
  return null;
}

/// Helper to convert dynamic date/timestamp to DateTime. Returns [fallback] (default: now) if null.
DateTime parseDateTimeRequired(dynamic value, [DateTime? fallback]) {
  return parseDateTime(value) ?? fallback ?? DateTime.now();
}

/// Helper to convert dynamic date/timestamp to DateTime
DateTime dynamicToDateTime(dynamic value) {
  return parseDateTimeRequired(value);
}

/// Convert a dynamic date/timestamp value to DateTime.
/// Kept for backward compatibility with tests that called the old Timestamp version.
DateTime dynamicToTimestamp(dynamic value) {
  return parseDateTimeRequired(value);
}

/// Generates prefix search keywords for a product name.
///
/// Example: "Blue Shoes" -> ["b", "bl", "blu", "blue", "s", "sh", ..., "blue shoes"].
/// Limited to [_maxKeywords] entries and [_maxWordLength] chars per word.
List<String> generateSearchKeywords(String name) {
  final cleanName = name.toLowerCase().trim();
  if (cleanName.isEmpty) return [''];

  final keywords = <String>{};
  final words = cleanName.split(RegExp(r'\s+'));
  final prefixLimit = _maxKeywords > 1 ? _maxKeywords - 1 : 0;

  for (final word in words) {
    final maxLen = word.length < _maxWordLength ? word.length : _maxWordLength;
    var temp = '';
    for (int i = 0; i < maxLen; i++) {
      temp += word[i];
      keywords.add(temp);
      if (keywords.length >= prefixLimit) break;
    }
    if (keywords.length >= prefixLimit) break;
  }

  keywords.add(cleanName);
  return keywords.take(_maxKeywords).toList();
}

/// Returns the product grid column count based on platform and screen width.
///
/// Mobile: 2, Tablet: 3, Desktop: 4. Native Android/iOS always returns 2.
int getCrossAxisCount(BuildContext context) {
  if (TargetPlatform.android == defaultTargetPlatform ||
      TargetPlatform.iOS == defaultTargetPlatform) {
    return 2;
  }
  final width = MediaQuery.sizeOf(context).width;

  if (kIsWeb) {
    if (width < ResponsiveBreakpoints.tablet) {
      return 2;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return 3;
    } else {
      return 4;
    }
  } else {
    return 2;
  }
}

/// Returns the combined tax rate for a Canadian province. Defaults to 13% (Ontario HST).
///
/// Example: getTaxRate('QC') -> 0.14975 (5% GST + 9.975% QST).
double getTaxRate(String province) {
  // Derive combined rate from the canonical provinceTaxRates map
  final rates = provinceTaxRates[province];
  if (rates == null) return 0.13; // Default: Ontario HST
  // Round to 5 decimals to avoid IEEE 754 floating-point artifacts while preserving QC's 14.975%
  final total = rates.values.fold(0.0, (acc, rate) => acc + rate);
  return double.parse(total.toStringAsFixed(5));
}

bool hasValidAddress(Address? address) {
  if (address == null) return false;
  final stateCode = address.state.trim().toUpperCase();
  return address.street.trim().isNotEmpty &&
      address.city.trim().isNotEmpty &&
      stateCode.isNotEmpty &&
      ProvinceCodeValues.all.contains(stateCode) &&
      address.postalCode.trim().isNotEmpty &&
      address.country.trim().isNotEmpty;
}

bool isValidTaxCode(String? taxCode) {
  if (taxCode == null || taxCode.trim().isEmpty) return true;
  final value = taxCode.trim();
  return RegExp(r'^txcd_\d{8}$').hasMatch(value);
}

/// Opens Privacy Policy page in-app on all platforms.
void openPrivacyPolicy(BuildContext context) {
  Navigator.pushNamed(context, AppRoutes.privacyPolicy);
}

/// Opens Terms of Service page in-app on all platforms.
void openTermsOfService(BuildContext context) {
  Navigator.pushNamed(context, AppRoutes.termsOfService);
}

int? parseMoneyToCents(String? input) {
  if (input == null || input.trim().isEmpty) return null;
  final clean = input.trim();
  final parts = clean.split('.');
  int dollars = int.tryParse(parts[0]) ?? 0;
  int cents = 0;
  if (parts.length > 1) {
    final centsStr = parts[1].padRight(2, '0').substring(0, 2);
    cents = int.tryParse(centsStr) ?? 0;
  }
  return (dollars * 100) + cents;
}

AddressDetails parseAddressSuggestion(Map<String, dynamic> suggestion) {
  final props = suggestion['properties'] ?? {};

  final houseNumber = props['housenumber'];
  final streetName = props['street'];
  final addressLine1 = [?houseNumber, ?streetName].join(' ');

  return AddressDetails(
    street: (props['formatted'] as String?) ?? addressLine1,
    city: (props['city'] as String?) ?? '',
    state: (props['state_code'] as String?) ?? 'ON',
    postalCode: (props['postcode'] as String?) ?? '',
    latitude: ((suggestion['geometry']?['coordinates']?[1] as num?) ?? 0)
        .toDouble(),
    longitude: ((suggestion['geometry']?['coordinates']?[0] as num?) ?? 0)
        .toDouble(),
  );
}

/// Show a dialog prompting the user to verify their email before proceeding.
/// [onResend] optional callback to resend verification email.
/// Returns true if user dismissed, false if they tapped resend.
void showEmailVerificationDialog(
  BuildContext context, {
  String? email,
  VoidCallback? onResend,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: DesignTokens.warningSubtle,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.mark_email_unread_outlined,
          color: DesignTokens.warningIcon,
          size: 36,
        ),
      ),
      title: Text(
        'email_verification.title'.tr(),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (email != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                email,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.primary,
                ),
              ),
            ),
          Text(
            'email_verification.instruction_title'.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: DesignTokens.textSecondary,
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
                  '  1. ${'email_verification.step1'.tr()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '  2. ${'email_verification.step2'.tr()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '  3. ${'email_verification.step3'.tr()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '  4. ${'email_verification.step4'.tr()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: DesignTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onResend != null) ...[
            const SizedBox(height: 16),
            Text(
              "email_verification.did_not_receive".tr(),
              style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary),
            ),
          ],
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (onResend != null)
          Semantics(
            button: true,
            label: 'btn-dialog-resend-email',
            child: TextButton.icon(
              onPressed: () {
                onResend();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('email_verification.sent_success'.tr()),
                    backgroundColor: DesignTokens.primary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.send, size: 16),
              label: Text('email_verification.resend_button'.tr()),
              style: TextButton.styleFrom(
                foregroundColor: DesignTokens.primary,
              ),
            ),
          ),
        Semantics(
          button: true,
          label: 'btn-dialog-got-it',
          child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: DesignTokens.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Text('common.got_it'.tr()),
          ),
        ),
      ],
    ),
  );
}

/// Displays a modal dialog prompting the user to sign in.
///
/// [text] is a translation key for the dialog body (defaults to cart sign-in prompt).
/// Tapping "Sign in" navigates to the login screen; tapping "Cancel" dismisses.
void showLoginPrompt(
  BuildContext context, {
  String text = 'auth.sign_in_cart_required',
}) {
  // Capture the ROOT navigator from the CALLER's context before showing dialog.
  // rootNavigator: true is required in Flutter Web to update the browser URL.
  // Without it, a nested navigator (e.g., inside a tab) handles the push
  // and the browser URL is never updated, breaking deep-linking and E2E tests.
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('auth.sign_in_required'.tr()),
      content: Text(text.tr()),
      actions: [
        Semantics(
          button: true,
          label: 'btn-dialog-cancel',
          child: TextButton(
            key: const Key('login_dialog_cancel_button'),
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('common.cancel'.tr()),
          ),
        ),
        Semantics(
          button: true,
          label: 'btn-dialog-sign-in',
          child: ElevatedButton(
            key: const Key('login_dialog_sign_in_button'),
            onPressed: () {
              Navigator.pop(dialogContext);
              navigator.pushNamed(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primary,
              foregroundColor: DesignTokens.white,
            ),
            child: Text('auth.sign_in'.tr()),
          ),
        ),
      ],
    ),
  );
}

/// Validates a video file based on size and duration business rules.
VideoValidationError validateVideoFile({
  required int sizeInBytes,
  required int durationInSeconds,
}) {
  if (sizeInBytes > BusinessRules.maxVideoBytes) {
    return VideoValidationError.tooLarge;
  }
  if (durationInSeconds > BusinessRules.maxVideoDurationSeconds) {
    return VideoValidationError.tooLong;
  }
  return VideoValidationError.none;
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
    // Only treat as fixed-price shipping when cost is positive.
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
  /// Extract user-friendly message from error.
  ///
  /// For [OrignaBaseException], returns the backend message (safe — our
  /// backend already sanitises messages before raising HttpsError), but filters
  /// out any raw database exceptions that might have leaked.
  /// For auth/storage/backend exceptions, returns a safe generic message when
  /// the raw message may leak internals.
  /// For everything else, returns [fallback] to avoid leaking internals.
  ///
  /// If [code] is provided it is appended to the message so users can quote it
  /// when contacting support: e.g. "Card declined [ORIGNA-PAY-001]".
  /// When [code] is omitted the method attempts to infer one automatically via
  /// [_inferCode].
  static String getMessage(dynamic error, [String? fallback, String? code]) {
    final defaultFallback = 'errors.generic_error'.tr();
    final actualFallback = fallback ?? defaultFallback;

    String rawMsg;

    if (error is OrignaBaseException) {
      final msg = error.message;
      // Filter out leaked backend errors
      if (msg.contains('FailedPrecondition') ||
          msg.contains('The query requires an index')) {
        rawMsg = 'errors.service_unavailable'.tr();
      } else {
        rawMsg = msg.isNotEmpty ? msg : actualFallback;
      }
    } else if (error is OrignaBaseAuthException ||
        error is OrignaBaseException) {
      rawMsg = 'errors.service_unavailable'.tr();
    } else {
      // NEVER expose raw e.toString() — it can contain stack traces,
      // type names and server internals.
      rawMsg = actualFallback;
    }

    // If the backend already embedded a code (e.g. "Order not found [ORIGNA-ORD-001]")
    // do not append a second one.
    if (rawMsg.contains('[ORIGNA-')) {
      return rawMsg;
    }

    final displayCode = code ?? _inferCode(error);
    if (displayCode != null) {
      return '$rawMsg [$displayCode]';
    }
    return rawMsg;
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
    AppLogger.e('$contextPrefix$error', error: error, stackTrace: stackTrace);

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

  /// Show error to user via SnackBar and log it.
  ///
  /// If [userMessage] contains an embedded `[ORIGNA-*]` code the code is
  /// extracted and rendered as a small monospace subtitle so users can quote
  /// it when contacting support@orignagta.ca.
  static void show(
    BuildContext context,
    String userMessage, {
    dynamic error,
    StackTrace? stackTrace,
    String? logContext,
    Duration duration = const Duration(seconds: 5),
  }) {
    // Log the error
    if (error != null) {
      log(error, stackTrace: stackTrace, context: logContext);
    }

    // Extract embedded error code, e.g. "Card declined [ORIGNA-PAY-001]"
    final codeMatch = RegExp(r'\[ORIGNA-[A-Z]+-\d+\]').firstMatch(userMessage);
    final String? displayCode = codeMatch?.group(0);
    final String mainText = displayCode != null
        ? userMessage.replaceFirst(displayCode, '').trimRight()
        : userMessage;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: DesignTokens.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        content: displayCode != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mainText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$displayCode · support@orignagta.ca',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                      color: DesignTokens.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              )
            : Text(userMessage),
        action: SnackBarAction(
          label: 'common.dismiss'.tr(),
          textColor: DesignTokens.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  /// Infer an ORIGNA error code from a known auth/backend error code or
  /// from the exception type.  Returns null when no mapping exists.
  static String? _inferCode(dynamic error) {
    if (error is OrignaBaseException) {
      // Backend already appends ORIGNA-* codes in the message body;
      // no client-side inference needed — avoid double-coding.
      return null;
    }
    if (error is OrignaBaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => ErrorCodes.authEmailInUse,
        'wrong-password' => ErrorCodes.authWrongPassword,
        'user-not-found' => ErrorCodes.authUserNotFound,
        'weak-password' => ErrorCodes.authWeakPassword,
        'too-many-requests' => ErrorCodes.authTooManyRequests,
        'session-cookie-expired' ||
        'user-token-expired' => ErrorCodes.authSessionExpired,
        'invalid-credential' ||
        'invalid-email' => ErrorCodes.authInvalidCredential,
        'user-disabled' => ErrorCodes.authAccountDisabled,
        'mfa-required' => ErrorCodes.authMfaRequired,
        'network-request-failed' => ErrorCodes.sysNetworkError,
        _ => ErrorCodes.sysUnknown,
      };
    }
    // CircuitBreakerOpenException — service temporarily degraded
    if (error.runtimeType.toString() == 'CircuitBreakerOpenException') {
      return ErrorCodes.sysServiceDegraded;
    }
    // PremiumRequiredException — feature gate
    if (error.runtimeType.toString() == 'PremiumRequiredException') {
      return ErrorCodes.premFeatureGated;
    }
    // Dart TimeoutException
    if (error.runtimeType.toString() == 'TimeoutException') {
      return ErrorCodes.sysTimeout;
    }
    return null;
  }
}

/// Enum for video validation errors
enum VideoValidationError { none, tooLarge, tooLong, invalidFormat }

class _FixedPriceResult {
  final bool isEnabled;
  final double total;

  const _FixedPriceResult({required this.isEnabled, required this.total});
}
