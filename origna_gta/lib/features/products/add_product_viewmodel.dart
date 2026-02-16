import 'package:easy_localization/easy_localization.dart';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/utils.dart';

import 'add_product_state.dart';

final addProductViewModelProvider =
    StateNotifierProvider.autoDispose<AddProductViewModel, AddProductState>((
      ref,
    ) {
      return AddProductViewModel(ref);
    });

class AddProductViewModel extends StateNotifier<AddProductState> {
  final Ref _ref;

  AddProductViewModel(this._ref) : super(AddProductState());

  void addImage(ImageModel image) =>
      state = state.copyWith(imageModels: [...state.imageModels, image]);
  Future<void> addProduct({
    required String name,
    required String description,
    required double price,
    required int stock,
    required int categoryId,
    required String street,
    required String apartment,
    required String city,
    required String postalCode,
    double? weight,
    double? length,
    double? width,
    double? height,
    String? taxCode,
    required List<models.SellerDeliveryOption> deliveryOptions,
    int? minimumOrderQuantity,
    bool? freeShipping,
    // Flat supplier fields (when supplier object is not used)
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    // Structured supplier info
    models.SupplierInfo? supplier,
    // Inventory configuration
    models.InventoryConfig? inventory,
    // Product status
    String? status,
  }) async {
    // Bug #27: Prevent double-submit
    if (state.isLoading) return;

    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'product.please_enter_name'.tr());
      return;
    }
    if (description.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'product.please_enter_description'.tr(),
      );
      return;
    }
    if (price <= 0) {
      state = state.copyWith(errorMessage: 'product.please_enter_price'.tr());
      return;
    }
    if (price > 100000) {
      state = state.copyWith(errorMessage: 'product.price_limit_exceeded'.tr());
      return;
    }
    if (stock < 0) {
      state = state.copyWith(errorMessage: 'product.stock_negative'.tr());
      return;
    }
    final minOrderQty = minimumOrderQuantity ?? state.minimumOrderQuantity;
    if (minOrderQty < 1) {
      state = state.copyWith(
        errorMessage: 'product.min_order_at_least_one'.tr(),
      );
      return;
    }
    if (categoryId <= 0) {
      state = state.copyWith(errorMessage: 'product.select_category'.tr());
      return;
    }
    // Bug #4: Skip address validation for digital products (no shipping needed)
    if (!state.isDigital) {
      if (street.trim().isEmpty ||
          city.trim().isEmpty ||
          postalCode.trim().isEmpty ||
          state.selectedProvince.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'product.address_required'.tr());
        return;
      }
      // FIX: Validate address field lengths to match Firestore Rules
      if (street.trim().length < 3) {
        state = state.copyWith(errorMessage: 'product.street_too_short'.tr());
        return;
      }
      if (street.trim().length > 100) {
        state = state.copyWith(errorMessage: 'product.street_too_long'.tr());
        return;
      }
      if (city.trim().length < 2) {
        state = state.copyWith(errorMessage: 'product.city_too_short'.tr());
        return;
      }
      if (city.trim().length > 50) {
        state = state.copyWith(errorMessage: 'product.city_too_long'.tr());
        return;
      }
      // FIX: Validate postal code format in ViewModel (not just Form UI)
      final normalizedPostal = postalCode.trim().toUpperCase().replaceAll(' ', '');
      final postalRegex = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');
      if (!postalRegex.hasMatch(normalizedPostal)) {
        state = state.copyWith(errorMessage: 'product.invalid_postal'.tr());
        return;
      }

      // SECURITY: Require address to be verified via Geoapify autocomplete
      // In dev/test mode, allow bypass for integration tests
      final isDevOrTest =
          const String.fromEnvironment('ENVIRONMENT', defaultValue: 'production') == 'dev' ||
          const bool.fromEnvironment('IS_TEST', defaultValue: false);
      if (!state.addressVerified && !isDevOrTest) {
        if (state.latitude == null || state.longitude == null) {
          state = state.copyWith(
            errorMessage: 'product.address_not_verified'.tr(),
          );
          return;
        }
      }
    }

    if (!isValidTaxCode(taxCode)) {
      state = state.copyWith(
        errorMessage: 'product.invalid_tax_code_format'.tr(),
      );
      return;
    }
    if ((weight ?? 0) < 0 ||
        (length ?? 0) < 0 ||
        (width ?? 0) < 0 ||
        (height ?? 0) < 0) {
      state = state.copyWith(errorMessage: 'product.dimensions_positive'.tr());
      return;
    }

    final isDevOrTestRun =
        const String.fromEnvironment(
              'ENVIRONMENT',
              defaultValue: 'production',
            ) ==
            'dev' ||
        const bool.fromEnvironment('IS_TEST', defaultValue: false);

    if (state.imageModels.isEmpty && !isDevOrTestRun) {
      state = state.copyWith(errorMessage: 'product.image_required'.tr());
      return;
    }

    // Bug #4: Physical products need at least one delivery tier (unless local-only)
    if (!state.isDigital && !state.isLocalDeliveryOnly) {
      if (!state.standardEnabled &&
          !state.expressEnabled &&
          !state.sameDayEnabled) {
        state = state.copyWith(
          errorMessage: 'product.delivery_tier_required'.tr(),
        );
        return;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final productRepository = _ref.read(productRepositoryProvider);

      final sanitizedDeliveryOptions = state.isDigital
          ? <models.SellerDeliveryOption>[]
          : deliveryOptions;

      final streetTrimmed = street.trim();
      final apartmentTrimmed = apartment.trim();
      final cityTrimmed = city.trim();
      final provinceTrimmed = state.selectedProvince.trim();
      final postalTrimmed = postalCode.trim().toUpperCase();

      // AUDIT FIX: Upload images FIRST to prevent orphan Firestore documents.
      // If image upload fails, no product document is created.
      // Generate a temporary product ID for the image path
      final tempProductId = _ref
          .read(productRepositoryProvider)
          .generateProductId();
      List<String> urls;

      if (state.imageModels.isEmpty && isDevOrTestRun) {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        urls = <String>['https://picsum.photos/seed/origna-$stamp/800/800'];
      } else {
        final compressedImages = await _compressImages(state.imageModels);
        if (compressedImages.isEmpty) {
          throw Exception(
            'Failed to compress images. Please try different images.',
          );
        }

        urls = await productRepository.uploadImages(
          compressedImages,
          tempProductId,
        );

        if (urls.isEmpty) {
          throw Exception(
            'Failed to upload images. Please check your connection and try again.',
          );
        }
      }

      final product = models.Product(
        productId: tempProductId,
        sellerId: _ref.read(userIdProvider)!,
        name: name,
        keywords: generateSearchKeywords(name),
        stockQuantity: stock,
        price: price,
        imageUrls: urls,
        sellerAddress: models.Address(
          street: streetTrimmed,
          apartment: apartmentTrimmed,
          city: cityTrimmed,
          state: provinceTrimmed,
          postalCode: postalTrimmed,
          country: CountryValues.canada,
          latitude: state.latitude,
          longitude: state.longitude,
        ),
        description: description,
        categoryId: categoryId,
        createdAt: DateTime.now(),
        rating: 0.0,
        isActive: true,
        weightKg: state.isDigital ? null : weight,
        lengthCm: state.isDigital ? null : length,
        widthCm: state.isDigital ? null : width,
        heightCm: state.isDigital ? null : height,
        isLocalDeliveryOnly: state.isDigital
            ? false
            : state.isLocalDeliveryOnly,
        estimatedShipDays: sanitizedDeliveryOptions.isNotEmpty
            ? sanitizedDeliveryOptions.first.estimatedDays
            : 0,
        taxCode: taxCode,
        deliveryOptions: sanitizedDeliveryOptions,
        isPerishable: state.isDigital ? false : state.isPerishable,
        isDigital: state.isDigital,
        minimumOrderQuantity: minOrderQty,
        freeShipping: freeShipping ?? state.freeShipping,
        cost: cost,
        supplierSku: supplierSku,
        supplierUrl: supplierUrl,
        supplier: supplier,
        inventory: inventory,
        status: status ?? ProductStatusValues.active,
      );

      await productRepository.addProductWithId(tempProductId, product);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'AddProductViewModel.addProduct',
      );
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e, 'product.add_product_failed'.tr()),
      );
    }
  }

  Future<void> onStreetChanged(String value) async {
    // Bug #16: Invalidate stale coordinates when user manually edits address
    clearCoordinates();
    if (value.length < 3) {
      state = state.copyWith(showSuggestions: false, addressSuggestions: []);
      return;
    }
    final suggestions = await _ref
        .read(locationRepositoryProvider)
        .getAddressSuggestions(value);
    state = state.copyWith(
      addressSuggestions: suggestions,
      showSuggestions: suggestions.isNotEmpty,
    );
  }

  void removeImage(int index) => state = state.copyWith(
    imageModels: List<ImageModel>.from(state.imageModels)..removeAt(index),
  );
  void selectAddress(Map<String, dynamic> suggestion) {
    final details = parseAddressSuggestion(suggestion);
    state = state.copyWith(
      selectedProvince: details.state,
      latitude: details.latitude,
      longitude: details.longitude,
      addressVerified: true,
      showSuggestions: false,
      addressSuggestions: [],
    );
  }

  void setExpressEnabled(bool value) => state = state.copyWith(
    expressEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );
  void setFreeShippingAt10Plus(bool? value) =>
      state = state.copyWith(freeShippingAt10Plus: value ?? false);
  void setLocalDeliveryOnly(bool value) => state = state.copyWith(
    isLocalDeliveryOnly: value,
    standardEnabled: value ? false : state.standardEnabled,
    expressEnabled: value ? false : state.expressEnabled,
    sameDayEnabled: value ? false : state.sameDayEnabled,
  );

  void setMinimumOrderQuantity(int value) =>
      state = state.copyWith(minimumOrderQuantity: value);

  void setProvince(String province) =>
      state = state.copyWith(selectedProvince: province);

  void setSameDayEnabled(bool value) => state = state.copyWith(
    sameDayEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );

  void setStandardEnabled(bool value) => state = state.copyWith(
    standardEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );

  void toggleDigital(bool value) => state = state.copyWith(
    isDigital: value,
    freeShipping: value ? true : state.freeShipping,
    isPerishable: value ? false : state.isPerishable,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
    standardEnabled: value
        ? false
        : true, // Re-enable standard when going back to physical
    expressEnabled: value ? false : state.expressEnabled,
    sameDayEnabled: value ? false : state.sameDayEnabled,
  );

  void toggleFreeShipping(bool value) {
    final effectiveValue = state.isDigital ? true : value;
    if (effectiveValue) {
      // Save current express/same-day state before disabling them
      state = state.copyWith(
        freeShipping: true,
        savedExpressEnabled: state.expressEnabled,
        savedSameDayEnabled: state.sameDayEnabled,
        expressEnabled: false,
        sameDayEnabled: false,
        freeShippingAt10Plus: false,
      );
    } else {
      // Restore previously saved express/same-day state
      state = state.copyWith(
        freeShipping: false,
        expressEnabled: state.savedExpressEnabled,
        sameDayEnabled: state.savedSameDayEnabled,
      );
    }
  }

  void togglePerishable(bool value) =>
      state = state.copyWith(isPerishable: value);

  /// Bug #16: Invalidate lat/lng when user manually edits address fields
  /// Also resets addressVerified — user must re-select from Geoapify
  void clearCoordinates() =>
      state = state.copyWith(latitude: null, longitude: null, addressVerified: false);

  /// Bug #1: Allow ProductAddImages widget to sync images back to ViewModel
  void updateImages(List<ImageModel> images) =>
      state = state.copyWith(imageModels: images);

  Future<List<Uint8List>> _compressImages(List<ImageModel> imageModels) async {
    final results = <Uint8List>[];
    for (var model in imageModels) {
      final compressed = await _validateAndCompressImage(model.bytes);
      if (compressed != null) results.add(compressed);
    }
    return results;
  }

  Future<Uint8List?> _validateAndCompressImage(Uint8List bytes) async {
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    img.Image resized = image;
    if (image.width > 2048 || image.height > 2048) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? 2048 : null,
        height: image.height > image.width ? 2048 : null,
      );
    }
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
