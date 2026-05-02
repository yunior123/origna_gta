import 'package:easy_localization/easy_localization.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/utils.dart' show isValidTaxCode;

import 'add_product_state.dart';

/// Extracted validation logic for [AddProductViewModel].
///
/// Returns an error message string if validation fails, or null if all checks pass.
/// Keeps the ViewModel focused on state transitions and API calls.
String? validateAddProductInputs({
  required String name,
  required String description,
  required int priceCents,
  int? compareAtPriceCents,
  required int stock,
  required int categoryId,
  required String street,
  required String city,
  required String postalCode,
  double? weight,
  double? length,
  double? width,
  double? height,
  String? taxCode,
  int minimumOrderQuantity = 1,
  required AddProductState state,
  required bool isDevOrTestRun,
  required bool sellerHasWarehouses,
}) {
  if (name.trim().isEmpty) return 'product.please_enter_name'.tr();
  if (name.trim().length > 120) return 'product.name_too_long'.tr();
  if (description.trim().isEmpty) {
    return 'product.please_enter_description'.tr();
  }
  if (description.trim().length < 10) {
    return 'product.description_too_short'.tr();
  }
  if (description.trim().length > 4000) {
    return 'product.description_too_long'.tr();
  }
  if (priceCents <= 99) return 'product.please_enter_price'.tr();
  if (priceCents > 10000000) return 'product.price_limit_exceeded'.tr();
  if (compareAtPriceCents != null && compareAtPriceCents - priceCents < 50) {
    return 'product.compare_at_price_must_be_higher'.tr();
  }
  if (stock < 0) return 'product.stock_negative'.tr();
  if (minimumOrderQuantity < 1) return 'product.min_order_at_least_one'.tr();
  if (categoryId <= 0) return 'product.select_category'.tr();

  // PROD-C2: If seller has warehouses, they must select at least one.
  if (!state.isDigital &&
      sellerHasWarehouses &&
      state.selectedWarehouseIds.isEmpty) {
    return 'product.warehouse_selection_required'.tr();
  }

  // Address validation for physical products without warehouses
  if (!state.isDigital && state.selectedWarehouseIds.isEmpty) {
    if (street.trim().isEmpty ||
        city.trim().isEmpty ||
        postalCode.trim().isEmpty ||
        state.selectedProvince.trim().isEmpty) {
      return 'product.address_required'.tr();
    }
    if (street.trim().length < 3) return 'product.street_too_short'.tr();
    if (street.trim().length > 100) return 'product.street_too_long'.tr();
    if (city.trim().length < 2) return 'product.city_too_short'.tr();
    if (city.trim().length > 50) return 'product.city_too_long'.tr();

    final normalizedPostal = postalCode.trim().toUpperCase().replaceAll(
      ' ',
      '',
    );
    final postalRegex = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');
    if (!postalRegex.hasMatch(normalizedPostal)) {
      return 'product.invalid_postal'.tr();
    }

    // SECURITY: Require address to be verified via Geoapify autocomplete
    if (!state.addressVerified && !isDevOrTestRun) {
      if (state.latitude == null || state.longitude == null) {
        return 'product.address_not_verified'.tr();
      }
    }
  }

  if (!isValidTaxCode(taxCode)) return 'product.invalid_tax_code_format'.tr();
  if ((weight ?? 0) < 0 ||
      (length ?? 0) < 0 ||
      (width ?? 0) < 0 ||
      (height ?? 0) < 0) {
    return 'product.dimensions_positive'.tr();
  }

  if (state.imageModels.isEmpty && !isDevOrTestRun) {
    return 'product.image_required'.tr();
  }

  // Physical products need at least one delivery tier (unless local-only)
  if (!state.isDigital && !state.isLocalDeliveryOnly) {
    if (!state.standardEnabled &&
        !state.expressEnabled &&
        !state.sameDayEnabled) {
      return 'product.delivery_tier_required'.tr();
    }
  }

  // Digital product validation
  if (state.isDigital) {
    final digitalError = _validateDigitalProduct(state);
    if (digitalError != null) return digitalError;
  }

  // Variant validation
  if (state.hasVariants) {
    if (state.variantOptions.isEmpty) return 'product.variants_required'.tr();
    final invalidVariants = state.variants.where(
      (v) => v.priceCents == null || v.priceCents! < 99,
    );
    if (invalidVariants.isNotEmpty) {
      return 'product.variant_price_required'.tr();
    }
  }

  return null; // All checks passed
}

String? _validateDigitalProduct(AddProductState state) {
  if (state.digitalType == null) return 'product.digital_type_required'.tr();

  if (state.digitalType == DigitalTypeValues.software) {
    final urls = [
      state.macosDownloadUrl,
      state.windowsDownloadUrl,
      state.linuxDownloadUrl,
    ];
    if (urls.every((u) => u == null || u.trim().isEmpty)) {
      return 'product.digital_platform_url_required'.tr();
    }
    final nonEmptyUrls = urls.whereType<String>().where(
      (u) => u.trim().isNotEmpty,
    );
    if (nonEmptyUrls.any((u) => !u.startsWith('https://'))) {
      return 'product.digital_url_https_required'.tr();
    }
  } else if (state.digitalType == DigitalTypeValues.book) {
    final url = state.bookSourceUrl?.trim();
    if (url == null || url.isEmpty) return 'product.book_url_required'.tr();
    if (url.length > 500) return 'product.url_too_long'.tr();
    if (!url.startsWith('https://')) {
      return 'product.book_url_https_required'.tr();
    }
  }

  return null;
}
