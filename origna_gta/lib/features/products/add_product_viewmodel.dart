import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/utils.dart';

import 'add_product_state.dart';
import 'variant_models.dart';

/// Top-level isolate function for image compression — runs in a separate thread.
Uint8List? _compressImageAddIsolate(Uint8List bytes) {
  const int maxDimension = 2048;
  final image = img.decodeImage(bytes);
  if (image == null) return null;
  img.Image resized = image;
  if (image.width > maxDimension || image.height > maxDimension) {
    resized = img.copyResize(image, width: image.width > image.height ? maxDimension : null, height: image.height > image.width ? maxDimension : null);
  }
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

final addProductViewModelProvider = StateNotifierProvider.autoDispose<AddProductViewModel, AddProductState>((ref) {
  return AddProductViewModel(ref);
});

class AddProductViewModel extends StateNotifier<AddProductState> {
  final Ref _ref;

  AddProductViewModel(this._ref) : super(AddProductState());

  void addImage(ImageModel image) => state = state.copyWith(imageModels: [...state.imageModels, image]);

  Future<void> addProduct({
    required String name,
    required String description,
    required double price,

    /// Original/crossed-out price for discount display (null = no sale, must be > price)
    double? compareAtPrice,
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
    // Subcategory (N-11)
    String? subcategory,
  }) async {
    // Bug #27: Prevent double-submit
    if (state.isLoading) return;

    final isDevOrTestRun =
        const String.fromEnvironment('ENVIRONMENT', defaultValue: 'production') == 'dev' ||
        const bool.fromEnvironment('IS_TEST', defaultValue: false);

    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'product.please_enter_name'.tr());
      return;
    }
    if (description.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'product.please_enter_description'.tr());
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
    if (compareAtPrice != null && compareAtPrice <= price) {
      state = state.copyWith(errorMessage: 'product.compare_at_price_must_be_higher'.tr());
      return;
    }
    if (stock < 0) {
      state = state.copyWith(errorMessage: 'product.stock_negative'.tr());
      return;
    }
    final minOrderQty = minimumOrderQuantity ?? state.minimumOrderQuantity;
    if (minOrderQty < 1) {
      state = state.copyWith(errorMessage: 'product.min_order_at_least_one'.tr());
      return;
    }
    if (categoryId <= 0) {
      state = state.copyWith(errorMessage: 'product.select_category'.tr());
      return;
    }
    // Bug #4: Skip address validation for digital products (no shipping needed)
    if (!state.isDigital) {
      if (street.trim().isEmpty || city.trim().isEmpty || postalCode.trim().isEmpty || state.selectedProvince.trim().isEmpty) {
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
      if (!state.addressVerified && !isDevOrTestRun) {
        if (state.latitude == null || state.longitude == null) {
          state = state.copyWith(errorMessage: 'product.address_not_verified'.tr());
          return;
        }
      }
    }

    if (!isValidTaxCode(taxCode)) {
      state = state.copyWith(errorMessage: 'product.invalid_tax_code_format'.tr());
      return;
    }
    if ((weight ?? 0) < 0 || (length ?? 0) < 0 || (width ?? 0) < 0 || (height ?? 0) < 0) {
      state = state.copyWith(errorMessage: 'product.dimensions_positive'.tr());
      return;
    }

    if (state.imageModels.isEmpty && !isDevOrTestRun) {
      state = state.copyWith(errorMessage: 'product.image_required'.tr());
      return;
    }

    // Bug #4: Physical products need at least one delivery tier (unless local-only)
    if (!state.isDigital && !state.isLocalDeliveryOnly) {
      if (!state.standardEnabled && !state.expressEnabled && !state.sameDayEnabled) {
        state = state.copyWith(errorMessage: 'product.delivery_tier_required'.tr());
        return;
      }
    }

    // Digital product validation
    if (state.isDigital) {
      if (state.digitalType == null) {
        state = state.copyWith(errorMessage: 'product.digital_type_required'.tr());
        return;
      }
      if (state.digitalType == DigitalTypeValues.software) {
        final urls = [state.macosDownloadUrl, state.windowsDownloadUrl, state.linuxDownloadUrl];
        if (urls.every((u) => u == null || u.trim().isEmpty)) {
          state = state.copyWith(errorMessage: 'product.digital_platform_url_required'.tr());
          return;
        }
        final nonEmptyUrls = urls.whereType<String>().where((u) => u.trim().isNotEmpty);
        if (nonEmptyUrls.any((u) => !u.startsWith('https://'))) {
          state = state.copyWith(errorMessage: 'product.digital_url_https_required'.tr());
          return;
        }
      } else if (state.digitalType == DigitalTypeValues.book) {
        if (state.bookSourceUrl == null || state.bookSourceUrl!.trim().isEmpty) {
          state = state.copyWith(errorMessage: 'product.book_url_required'.tr());
          return;
        }
        if (!state.bookSourceUrl!.startsWith('https://')) {
          state = state.copyWith(errorMessage: 'product.book_url_https_required'.tr());
          return;
        }
      }
    }

    // Variant validation: all variants must have a price > 0
    if (state.hasVariants) {
      if (state.variantOptions.isEmpty) {
        state = state.copyWith(errorMessage: 'product.variants_required'.tr());
        return;
      }
      final invalidVariants = state.variants.where((v) {
        return v.price == null || v.price! <= 0;
      });
      if (invalidVariants.isNotEmpty) {
        state = state.copyWith(errorMessage: 'product.variant_price_required'.tr());
        return;
      }
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final productRepository = _ref.read(productRepositoryProvider);

      final sanitizedDeliveryOptions = state.isDigital ? <models.SellerDeliveryOption>[] : deliveryOptions;

      final streetTrimmed = street.trim();
      final apartmentTrimmed = apartment.trim();
      final cityTrimmed = city.trim();
      final provinceTrimmed = state.selectedProvince.trim();
      final postalTrimmed = postalCode.trim().toUpperCase();

      // AUDIT FIX: Upload images FIRST to prevent orphan Firestore documents.
      // If image upload fails, no product document is created.
      // Generate a temporary product ID for the image path
      final tempProductId = _ref.read(productRepositoryProvider).generateProductId();
      List<String> urls;

      if (state.imageModels.isEmpty && isDevOrTestRun) {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        urls = <String>['https://picsum.photos/seed/origna-$stamp/800/800'];
      } else {
        final compressedImages = await _compressImages(state.imageModels);
        if (compressedImages.isEmpty) {
          throw Exception('Failed to compress images. Please try different images.');
        }

        urls = await productRepository.uploadImages(compressedImages, tempProductId);

        if (urls.isEmpty) {
          throw Exception('Failed to upload images. Please check your connection and try again.');
        }
      }

      final useWarehouses = state.selectedWarehouseIds.isNotEmpty;
      if (useWarehouses && state.warehouseStockMap.isEmpty) {
        state = state.copyWith(isLoading: false, errorMessage: 'product.warehouse_stock_required'.tr());
        return;
      }
      // When using warehouses, stock = sum of all warehouseStockMap values
      final effectiveStock = useWarehouses ? state.warehouseStockMap.values.fold(0, (a, b) => a + b) : stock;

      final product = models.Product(
        productId: tempProductId,
        sellerId: _ref.read(userIdProvider)!,
        name: name,
        keywords: generateSearchKeywords(name),
        stockQuantity: effectiveStock,
        price: price,
        compareAtPrice: compareAtPrice,
        imageUrls: urls,
        sellerAddress: useWarehouses
            ? null
            : models.Address(
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
        lifecycleStatus: ProductLifecycleStatusValues.draft,
        weightKg: state.isDigital ? null : weight,
        lengthCm: state.isDigital ? null : length,
        widthCm: state.isDigital ? null : width,
        heightCm: state.isDigital ? null : height,
        isLocalDeliveryOnly: state.isDigital ? false : state.isLocalDeliveryOnly,
        estimatedShipDays: sanitizedDeliveryOptions.isNotEmpty ? sanitizedDeliveryOptions.first.estimatedDays : 0,
        taxCode: taxCode,
        deliveryOptions: sanitizedDeliveryOptions,
        isPerishable: state.isDigital ? false : state.isPerishable,
        isDigital: state.isDigital,
        digitalType: state.isDigital && state.digitalType != null ? state.digitalType : null,
        digitalBuilds: state.isDigital && state.digitalType == DigitalTypeValues.software
            ? {
                if (state.macosDownloadUrl?.isNotEmpty == true) DigitalPlatformValues.macos: state.macosDownloadUrl!,
                if (state.windowsDownloadUrl?.isNotEmpty == true) DigitalPlatformValues.windows: state.windowsDownloadUrl!,
                if (state.linuxDownloadUrl?.isNotEmpty == true) DigitalPlatformValues.linux: state.linuxDownloadUrl!,
              }
            : null,
        deviceLimit: state.isDigital ? state.deviceLimit : null,
        minimumOrderQuantity: minOrderQty,
        freeShipping: freeShipping ?? state.freeShipping,
        cost: cost,
        supplierSku: supplierSku,
        supplierUrl: supplierUrl,
        supplier: supplier,
        inventory: inventory,
        sellerSku: state.sellerSku,
        subcategory: subcategory,
        warehouseIds: useWarehouses ? state.selectedWarehouseIds : null,
        hasVariants: state.hasVariants,
        variants: state.hasVariants ? state.variants.map((v) => v.toMap()).toList() : const [],
        variantOptions: state.hasVariants ? state.variantOptions.map((o) => o.toMap()).toList() : const [],
      );

      await productRepository.addProductWithId(tempProductId, product);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppError.log(e, stackTrace: st, context: 'AddProductViewModel.addProduct');
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e, 'product.add_product_failed'.tr()));
    }
  }

  /// Bug #16: Invalidate lat/lng when user manually edits address fields
  /// Also resets addressVerified — user must re-select from Geoapify
  void clearCoordinates() => state = state.copyWith(latitude: null, longitude: null, addressVerified: false);

  /// Clear error message to allow re-triggering SnackBar on next error
  void clearError() => state = state.copyWith(errorMessage: null);

  Future<void> onStreetChanged(String value) async {
    // Bug #16: Invalidate stale coordinates when user manually edits address
    clearCoordinates();
    if (value.length < 3) {
      state = state.copyWith(showSuggestions: false, addressSuggestions: []);
      return;
    }
    final suggestions = await _ref.read(locationRepositoryProvider).getAddressSuggestions(value);
    state = state.copyWith(addressSuggestions: suggestions, showSuggestions: suggestions.isNotEmpty);
  }

  void removeImage(int index) => state = state.copyWith(imageModels: List<ImageModel>.from(state.imageModels)..removeAt(index));

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

  void setBookSourceUrl(String? url) => state = state.copyWith(bookSourceUrl: url);
  void setDeviceLimit(int? limit) => state = state.copyWith(deviceLimit: limit);

  void setDigitalType(String? type) => state = state.copyWith(digitalType: type);

  void setExpressEnabled(bool value) => state = state.copyWith(expressEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);

  void setFreeShippingAt10Plus(bool? value) => state = state.copyWith(freeShippingAt10Plus: value ?? false);

  void setLinuxDownloadUrl(String? url) => state = state.copyWith(linuxDownloadUrl: url);

  void setLocalDeliveryOnly(bool value) => state = state.copyWith(
    isLocalDeliveryOnly: value,
    standardEnabled: value ? false : state.standardEnabled,
    expressEnabled: value ? false : state.expressEnabled,
    sameDayEnabled: value ? false : state.sameDayEnabled,
  );

  void setMacosDownloadUrl(String? url) => state = state.copyWith(macosDownloadUrl: url);
  void setMinimumOrderQuantity(int value) => state = state.copyWith(minimumOrderQuantity: value);
  void setProvince(String province) => state = state.copyWith(selectedProvince: province);
  void setSameDayEnabled(bool value) => state = state.copyWith(sameDayEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);
  void setSellerSku(String? sku) => state = state.copyWith(sellerSku: sku?.trim().isEmpty == true ? null : sku?.trim());
  void setStandardEnabled(bool value) => state = state.copyWith(standardEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);

  void setWarehouseStock(String warehouseId, int qty) {
    final stockMap = Map<String, int>.from(state.warehouseStockMap);
    stockMap[warehouseId] = qty;
    state = state.copyWith(warehouseStockMap: stockMap);
  }

  void setWindowsDownloadUrl(String? url) => state = state.copyWith(windowsDownloadUrl: url);

  void toggleDigital(bool value) => state = state.copyWith(
    isDigital: value,
    freeShipping: value ? true : state.freeShipping,
    isPerishable: value ? false : state.isPerishable,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
    standardEnabled: value ? false : state.standardEnabled, // Restore previous value when going back to physical
    expressEnabled: value ? false : state.expressEnabled,
    sameDayEnabled: value ? false : state.sameDayEnabled,
    // Clear digital sub-fields when turning off
    digitalType: value ? state.digitalType : null,
    macosDownloadUrl: value ? state.macosDownloadUrl : null,
    windowsDownloadUrl: value ? state.windowsDownloadUrl : null,
    linuxDownloadUrl: value ? state.linuxDownloadUrl : null,
    bookSourceUrl: value ? state.bookSourceUrl : null,
    deviceLimit: value ? state.deviceLimit : null,
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
      state = state.copyWith(freeShipping: false, expressEnabled: state.savedExpressEnabled, sameDayEnabled: state.savedSameDayEnabled);
    }
  }

  void toggleHasVariants(bool value) {
    if (value) {
      state = state.copyWith(hasVariants: true);
    } else {
      state = state.copyWith(hasVariants: false, variantOptions: [], variants: []);
    }
  }

  void addVariantOption(String name, List<String> values) {
    final options = List<VariantOption>.from(state.variantOptions);
    options.add(VariantOption(name: name, values: values));
    state = state.copyWith(variantOptions: options);
    _regenerateVariants();
  }

  void removeVariantOption(int index) {
    final options = List<VariantOption>.from(state.variantOptions);
    options.removeAt(index);
    state = state.copyWith(variantOptions: options);
    _regenerateVariants();
  }

  void updateVariantOption(int index, String name, List<String> values) {
    final options = List<VariantOption>.from(state.variantOptions);
    options[index] = VariantOption(name: name, values: values);
    state = state.copyWith(variantOptions: options);
    _regenerateVariants();
  }

  void updateVariantPrice(int index, double? price) {
    final variants = List<ProductVariantEntry>.from(state.variants);
    variants[index] = variants[index].copyWith(price: price);
    state = state.copyWith(variants: variants);
  }

  void updateVariantStock(int index, int stockQuantity) {
    final variants = List<ProductVariantEntry>.from(state.variants);
    variants[index] = variants[index].copyWith(stockQuantity: stockQuantity);
    state = state.copyWith(variants: variants);
  }

  void updateVariantSku(int index, String? sku) {
    final variants = List<ProductVariantEntry>.from(state.variants);
    variants[index] = variants[index].copyWith(sku: sku);
    state = state.copyWith(variants: variants);
  }

  /// Auto-generates all variant combinations from variantOptions.
  /// Preserves price/stock/sku from existing variants where optionValues match.
  void _regenerateVariants() {
    final options = state.variantOptions;
    if (options.isEmpty) {
      state = state.copyWith(variants: []);
      return;
    }
    // Generate cartesian product of all option values
    List<Map<String, String>> combos = [{}];
    for (final opt in options) {
      final newCombos = <Map<String, String>>[];
      for (final combo in combos) {
        for (final val in opt.values) {
          newCombos.add({...combo, opt.name: val});
        }
      }
      combos = newCombos;
    }

    // Map existing variants by their optionValues for preservation
    final existingByKey = <String, ProductVariantEntry>{};
    for (final v in state.variants) {
      final key = v.optionValues.entries.map((e) => '${e.key}=${e.value}').join('|');
      existingByKey[key] = v;
    }

    final newVariants = combos.map((combo) {
      final key = combo.entries.map((e) => '${e.key}=${e.value}').join('|');
      final existing = existingByKey[key];
      return ProductVariantEntry(
        optionValues: combo,
        price: existing?.price,
        stockQuantity: existing?.stockQuantity ?? 0,
        sku: existing?.sku,
        isActive: existing?.isActive ?? true,
      );
    }).toList();

    state = state.copyWith(variants: newVariants);
  }

  void togglePerishable(bool value) => state = state.copyWith(isPerishable: value);

  void toggleWarehouseSelection(String warehouseId) {
    final current = List<String>.from(state.selectedWarehouseIds);
    if (current.contains(warehouseId)) {
      current.remove(warehouseId);
      // Remove stock entry too
      final stockMap = Map<String, int>.from(state.warehouseStockMap)..remove(warehouseId);
      state = state.copyWith(selectedWarehouseIds: current, warehouseStockMap: stockMap);
    } else {
      current.add(warehouseId);
      state = state.copyWith(selectedWarehouseIds: current);
    }
  }

  /// Bug #1: Allow ProductAddImages widget to sync images back to ViewModel
  void updateImages(List<ImageModel> images) => state = state.copyWith(imageModels: images);

  Future<List<Uint8List>> _compressImages(List<ImageModel> imageModels) async {
    final results = <Uint8List>[];
    for (var model in imageModels) {
      final compressed = await _validateAndCompressImage(model.bytes);
      if (compressed != null) results.add(compressed);
    }
    return results;
  }

  Future<Uint8List?> _validateAndCompressImage(Uint8List bytes) async {
    const int maxImageSize = 10 * 1024 * 1024; // 10MB — matches backend limit
    if (bytes.length > maxImageSize) {
      throw Exception('product.image_too_large'.tr());
    }
    return compute(_compressImageAddIsolate, bytes);
  }
}
