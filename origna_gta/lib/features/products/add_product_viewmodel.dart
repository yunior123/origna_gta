import 'package:cross_file/cross_file.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/nutrition_helper.dart';
import 'package:origna_gta/utils/utils.dart';

import 'add_product_state.dart';
import 'add_product_validation.dart';
import 'product_image_helpers.dart';
import 'variant_models.dart';

/// Riverpod provider for [AddProductViewModel].
///
/// Auto-disposed — fresh state per product creation session.
final addProductViewModelProvider =
    StateNotifierProvider.autoDispose<AddProductViewModel, AddProductState>((
      ref,
    ) {
      return AddProductViewModel(ref);
    });

/// Manages multi-step product creation: form validation, image upload, server submission.
///
/// ## Key Decisions
/// - Request ID guard ([_activeRequestId]) prevents stale submissions from overwriting
///   newer state if the user submits twice rapidly.
/// - Validation is extracted to [validateAddProductInputs] in `add_product_validation.dart`.
/// - Images are compressed client-side before upload to save bandwidth.
/// - Digital products force free shipping and skip address/delivery validation.
/// - Variant support: cartesian product of option values auto-generates variant entries.
/// - Warehouse stock: per-warehouse quantities validated server-side.
///
/// See also:
/// - [AddProductState] for the state shape
/// - [EditProductViewModel] for editing existing products
class AddProductViewModel extends StateNotifier<AddProductState> {
  final Ref _ref;
  String? _activeRequestId;

  AddProductViewModel(this._ref) : super(const AddProductState());

  /// Adds an [ImageModel] to the product image list.
  void addImage(ImageModel image) =>
      state = state.copyWith(imageModels: [...state.imageModels, image]);

  /// Toggles an allergen in the selected allergens list.
  ///
  /// Parameters:
  /// - [allergen]: allergen identifier (e.g., 'peanuts', 'gluten').
  void toggleAllergen(String allergen) {
    final current = List<String>.from(state.selectedAllergens);
    if (current.contains(allergen)) {
      current.remove(allergen);
    } else {
      current.add(allergen);
    }
    state = state.copyWith(selectedAllergens: current);
  }

  /// Toggles a "may contain" allergen in the precautionary allergens list.
  void toggleMayContainAllergen(String allergen) {
    final current = List<String>.from(state.selectedMayContainAllergens);
    if (current.contains(allergen)) {
      current.remove(allergen);
    } else {
      current.add(allergen);
    }
    state = state.copyWith(selectedMayContainAllergens: current);
  }

  /// Toggles a dietary badge (e.g., 'vegan', 'gluten-free') in the selected list.
  void toggleDietaryBadge(String badge) {
    final current = List<String>.from(state.selectedDietaryBadges);
    if (current.contains(badge)) {
      current.remove(badge);
    } else {
      current.add(badge);
    }
    state = state.copyWith(selectedDietaryBadges: current);
  }

  /// Sets ingredient lists in English and/or French.
  void setIngredients({String? en, String? fr}) {
    state = state.copyWith(ingredientsEn: en, ingredientsFr: fr);
  }

  /// Sets storage instructions in English and/or French.
  void setStorageInstructions({String? en, String? fr}) {
    state = state.copyWith(
      storageInstructionsEn: en,
      storageInstructionsFr: fr,
    );
  }

  /// Sets the best-before shelf life in days (perishable food products).
  void setBestBeforeDays(int? days) {
    state = state.copyWith(bestBeforeDays: days);
  }

  /// Updates a single nutrition field by name.
  ///
  /// Parameters:
  /// - [field]: field name matching [AddProductState] nutrition properties (e.g., 'caloriesKcal').
  /// - [value]: integer value in the field's native unit (mg, mcg, kcal).
  void updateNutritionField(String field, int? value) {
    state = switch (field) {
      'servingSizeAmount' => state.copyWith(servingSizeAmount: value),
      'servingsPerContainer' => state.copyWith(servingsPerContainer: value),
      'caloriesKcal' => state.copyWith(caloriesKcal: value),
      'totalFatMg' => state.copyWith(totalFatMg: value),
      'saturatedFatMg' => state.copyWith(saturatedFatMg: value),
      'transFatMg' => state.copyWith(transFatMg: value),
      'cholesterolMg' => state.copyWith(cholesterolMg: value),
      'sodiumMg' => state.copyWith(sodiumMg: value),
      'totalCarbohydrateMg' => state.copyWith(totalCarbohydrateMg: value),
      'fibreMg' => state.copyWith(fibreMg: value),
      'sugarsMg' => state.copyWith(sugarsMg: value),
      'proteinMg' => state.copyWith(proteinMg: value),
      'vitaminAMcg' => state.copyWith(vitaminAMcg: value),
      'vitaminCMg' => state.copyWith(vitaminCMg: value),
      'calciumMg' => state.copyWith(calciumMg: value),
      'ironMg' => state.copyWith(ironMg: value),
      _ => state,
    };
  }

  /// Sets the serving size unit (e.g., 'g', 'ml', 'piece').
  void setServingSizeUnit(String unit) {
    state = state.copyWith(servingSizeUnit: unit);
  }

  // === PRODUCT SPECS METHODS ===

  /// Sets the product brand name for specs.
  void setSpecBrand(String? brand) {
    state = state.copyWith(specBrand: brand);
  }

  /// Sets the product color for specs.
  void setSpecColor(String? color) {
    state = state.copyWith(specColor: color);
  }

  /// Sets the product material for specs.
  void setSpecMaterial(String? material) {
    state = state.copyWith(specMaterial: material);
  }

  /// Adds an empty spec entry (key-value pair) to the list.
  void addSpec() {
    final entries = List<Map<String, String>>.from(state.specEntries);
    entries.add({Fields.specKey: '', Fields.specValue: ''});
    state = state.copyWith(specEntries: entries);
  }

  /// Adds a spec entry with pre-filled values.
  ///
  /// Parameters:
  /// - [key]: spec label (e.g., 'Material').
  /// - [value]: spec value (e.g., 'Cotton').
  /// - [group]: optional grouping label.
  /// - [valueType]: value type hint ('text', 'number', 'url').
  /// - [unit]: optional unit label (e.g., 'cm').
  void addSpecWithValues(
    String key,
    String value, {
    String? group,
    String valueType = SpecValueTypeValues.text,
    String? unit,
  }) {
    final entries = List<Map<String, String>>.from(state.specEntries);
    final entry = <String, String>{
      Fields.specKey: key,
      Fields.specValue: value,
      Fields.specValueType: valueType,
    };
    if (group != null) entry[Fields.specGroup] = group;
    if (unit != null) entry[Fields.specUnit] = unit;
    entries.add(entry);
    state = state.copyWith(specEntries: entries);
  }

  /// Removes the spec entry at [index].
  void removeSpec(int index) {
    final entries = List<Map<String, String>>.from(state.specEntries);
    if (index >= 0 && index < entries.length) {
      entries.removeAt(index);
      state = state.copyWith(specEntries: entries);
    }
  }

  /// Updates the spec entry at [index] with a new [key] and [value].
  void updateSpec(int index, String key, String value) {
    final entries = List<Map<String, String>>.from(state.specEntries);
    if (index >= 0 && index < entries.length) {
      entries[index] = {
        ...entries[index],
        Fields.specKey: key,
        Fields.specValue: value,
      };
      state = state.copyWith(specEntries: entries);
    }
  }

  /// Validates all inputs, compresses images, and creates the product via [createProductAtomic].
  ///
  /// Handles physical/digital products, warehouse stock, and variant configurations.
  /// Updates [AddProductState.isLoading] during the operation and sets [isSuccess] on completion.
  /// Errors are written to [AddProductState.errorMessage] rather than thrown.
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
    int? costCents,
    String? supplierSku,
    String? supplierUrl,
    // Structured supplier info
    models.SupplierInfo? supplier,
    // Inventory configuration
    models.InventoryConfig? inventory,
    // Subcategory (N-11)
    String? subcategory,
    // PROD-C2: true when the seller has warehouses registered — enforces warehouse selection
    bool sellerHasWarehouses = false,
    // Bill 96: French translation fields
    String? nameF,
    String? descriptionF,
  }) async {
    // Bug #27: Prevent double-submit with request ID guard
    final requestId = DateTime.now().microsecondsSinceEpoch.toString();
    _activeRequestId = requestId;

    // Input boundary: convert dollars to cents immediately
    final priceCents = (price * 100).round();

    final config = _ref.read(envConfigProvider);
    final isDevOrTestRun = config.isDev || config.isEmulator;

    final minOrderQty = minimumOrderQuantity ?? state.minimumOrderQuantity;

    // Validate all inputs — extracted to add_product_validation.dart
    final validationError = validateAddProductInputs(
      name: name,
      description: description,
      price: price,
      compareAtPrice: compareAtPrice,
      stock: stock,
      categoryId: categoryId,
      street: street,
      city: city,
      postalCode: postalCode,
      weight: weight,
      length: length,
      width: width,
      height: height,
      taxCode: taxCode,
      minimumOrderQuantity: minOrderQty,
      state: state,
      isDevOrTestRun: isDevOrTestRun,
      sellerHasWarehouses: sellerHasWarehouses,
    );
    if (validationError != null) {
      state = state.copyWith(errorMessage: validationError);
      return;
    }

    if (state.videoFile != null) {
      final size = await state.videoFile!.length();
      if (size > BusinessRules.maxVideoBytes) {
        state = state.copyWith(errorMessage: 'product.video_too_large'.tr());
        return;
      }
      final duration = state.videoDurationSeconds ?? 0;
      if (duration > BusinessRules.maxVideoDurationSeconds) {
        state = state.copyWith(errorMessage: 'product.video_too_long'.tr());
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

      // Atomic: compress images then delegate both upload + database write to backend.
      // On any failure the backend cleans up R2 automatically — no orphan images.
      List<Uint8List> compressedImages = [];
      List<String>? testImageUrls;

      if (state.imageModels.isEmpty && isDevOrTestRun) {
        final stamp = DateTime.now().millisecondsSinceEpoch;
        testImageUrls = ['https://picsum.photos/seed/origna-$stamp/800/800'];
      } else {
        compressedImages = await compressProductImages(state.imageModels);
        if (_activeRequestId != requestId) return;
        if (compressedImages.isEmpty) {
          throw Exception(
            'Failed to compress images. Please try different images.',
          );
        }
      }

      final useWarehouses = state.selectedWarehouseIds.isNotEmpty;
      if (useWarehouses) {
        if (state.warehouseStockMap.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'product.warehouse_stock_required'.tr(),
          );
          return;
        }
        final allHaveStock = state.selectedWarehouseIds.every(
          (id) => state.warehouseStockMap.containsKey(id),
        );
        if (!allHaveStock) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'product.warehouse_stock_all_required'.tr(),
          );
          return;
        }
        final totalStock = state.warehouseStockMap.values.fold(
          0,
          (a, b) => a + b,
        );
        if (totalStock == 0) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'product.warehouse_total_stock_zero'.tr(),
          );
          return;
        }
        // F-82: Reject negative per-warehouse stock
        if (state.warehouseStockMap.values.any((qty) => qty < 0)) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'product.warehouse_stock_negative'.tr(),
          );
          return;
        }
      }
      // F-53: When hasVariants, derive effective stock from variant quantities sum.
      // When using warehouses, stock = sum of all warehouseStockMap values.
      final effectiveStock = state.hasVariants
          ? state.variants.fold(0, (int sum, v) => sum + (v.stockQuantity))
          : useWarehouses
          ? state.warehouseStockMap.values.fold(0, (a, b) => a + b)
          : stock;

      final uid = _ref.read(userIdProvider);
      if (uid == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'errors.auth_expired'.tr(),
        );
        return;
      }

      // Assemble nutrition data if any food fields are filled
      models.NutritionFacts? nutritionFacts;
      if (state.servingSizeAmount != null && state.caloriesKcal != null) {
        nutritionFacts = models.NutritionFacts(
          servingSizeAmount: state.servingSizeAmount!,
          servingSizeUnit: state.servingSizeUnit,
          servingsPerContainer: state.servingsPerContainer,
          caloriesKcal: state.caloriesKcal!,
          totalFatMg: state.totalFatMg ?? 0,
          saturatedFatMg: state.saturatedFatMg ?? 0,
          transFatMg: state.transFatMg ?? 0,
          cholesterolMg: state.cholesterolMg ?? 0,
          sodiumMg: state.sodiumMg ?? 0,
          totalCarbohydrateMg: state.totalCarbohydrateMg ?? 0,
          fibreMg: state.fibreMg ?? 0,
          sugarsMg: state.sugarsMg ?? 0,
          proteinMg: state.proteinMg ?? 0,
          vitaminAMcg: state.vitaminAMcg ?? 0,
          vitaminCMg: state.vitaminCMg ?? 0,
          calciumMg: state.calciumMg ?? 0,
          ironMg: state.ironMg ?? 0,
        );
      }

      models.FoodMetadata? foodMetadata;
      if (state.ingredientsEn != null ||
          state.selectedAllergens.isNotEmpty ||
          state.selectedDietaryBadges.isNotEmpty ||
          state.storageInstructionsEn != null) {
        final fopWarnings = nutritionFacts != null
            ? NutritionHelper.computeFopWarnings(nutritionFacts)
            : (sodium: false, sugars: false, saturatedFat: false);
        foodMetadata = models.FoodMetadata(
          ingredientsEn: state.ingredientsEn,
          ingredientsFr: state.ingredientsFr,
          allergens: state.selectedAllergens,
          mayContainAllergens: state.selectedMayContainAllergens,
          storageInstructionsEn: state.storageInstructionsEn,
          storageInstructionsFr: state.storageInstructionsFr,
          bestBeforeDays: state.bestBeforeDays,
          dietaryBadges: state.selectedDietaryBadges,
          fopHighSodium: fopWarnings.sodium,
          fopHighSugars: fopWarnings.sugars,
          fopHighSaturatedFat: fopWarnings.saturatedFat,
        );
      }

      // Build the product model — imageUrls and productId are set server-side
      var product = models.Product(
        productId: '',
        sellerId: uid,
        name: name,
        nameF: nameF?.trim().isEmpty == true ? null : nameF?.trim(),
        keywords: generateSearchKeywords(name),
        stockQuantity: effectiveStock,
        priceCents: priceCents,
        compareAtPriceCents: compareAtPrice != null
            ? (compareAtPrice * 100).round()
            : null,
        imageUrls: const [],
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
        descriptionF: descriptionF?.trim().isEmpty == true
            ? null
            : descriptionF?.trim(),
        categoryId: categoryId,
        createdAt: DateTime.now(),
        rating: 0.0,
        // PROD-C3: lifecycleStatus omitted — defaults to 'draft' in model; backend sets 'under_review' on creation.
        weightKg: state.isDigital ? null : weight,
        lengthCm: state.isDigital ? null : length,
        widthCm: state.isDigital ? null : width,
        heightCm: state.isDigital ? null : height,
        isLocalDeliveryOnly: state.isDigital
            ? false
            : state.isLocalDeliveryOnly,
        estimatedShipDays: () {
          // Use the 'standard' option's estimatedDays as the canonical shipping time.
          // Fall back to first available, then 0 if none exist.
          if (sanitizedDeliveryOptions.isEmpty) return 0;
          final standard = sanitizedDeliveryOptions
              .where((o) => o.type == DeliveryTypeValues.standard)
              .firstOrNull;
          return standard?.estimatedDays ??
              sanitizedDeliveryOptions.first.estimatedDays;
        }(),
        taxCode: taxCode,
        deliveryOptions: sanitizedDeliveryOptions,
        isPerishable: state.isDigital ? false : state.isPerishable,
        isDigital: state.isDigital,
        isAgeRestricted: state.isAgeRestricted,
        digitalType: state.isDigital && state.digitalType != null
            ? state.digitalType
            : null,
        digitalBuilds:
            state.isDigital && state.digitalType == DigitalTypeValues.software
            ? {
                if (state.macosDownloadUrl?.isNotEmpty == true)
                  DigitalPlatformValues.macos: state.macosDownloadUrl!,
                if (state.windowsDownloadUrl?.isNotEmpty == true)
                  DigitalPlatformValues.windows: state.windowsDownloadUrl!,
                if (state.linuxDownloadUrl?.isNotEmpty == true)
                  DigitalPlatformValues.linux: state.linuxDownloadUrl!,
              }
            : null,
        deviceLimit: state.isDigital ? state.deviceLimit : null,
        minimumOrderQuantity: minOrderQty,
        freeShipping: freeShipping ?? state.freeShipping,
        costCents: costCents,
        supplierSku: supplierSku,
        supplierUrl: supplierUrl,
        supplier: supplier,
        inventory: inventory,
        sellerSku: state.sellerSku,
        subcategory: subcategory,
        warehouseIds: useWarehouses ? state.selectedWarehouseIds : null,
        warehouseStockMap: useWarehouses ? state.warehouseStockMap : null,
        hasVariants: state.hasVariants,
        variants: state.hasVariants
            ? state.variants
                  .map((v) => models.ProductVariant.fromJson(v.toMap()))
                  .toList()
            : const [],
        variantOptions: state.hasVariants
            ? state.variantOptions
                  .map((o) => models.VariantOption.fromJson(o.toMap()))
                  .toList()
            : const [],
        condition: state.isDigital ? null : state.condition,
        nutritionFacts: nutritionFacts,
        foodMetadata: foodMetadata,
        videoUrl: null, // Will be set after upload
      );

      // PROD-C4: Show dedicated uploading state so submit button reflects video upload progress.
      String? uploadedVideoUrl;
      if (state.videoFile != null) {
        state = state.copyWith(isUploadingVideo: true);
        try {
          uploadedVideoUrl = await productRepository.uploadProductVideo(
            state.videoFile!,
            uid,
          );
          if (_activeRequestId != requestId) return;
          product = product.copyWith(videoUrl: uploadedVideoUrl);
        } finally {
          state = state.copyWith(isUploadingVideo: false);
        }
      }

      await productRepository.createProductAtomic(
        product,
        compressedImages,
        testImageUrls: testImageUrls,
        // Pass bookSourceUrl for digital book products — excluded from Dart Product model
        // (buyer-protected: never read back by client) but required by Python backend
        // to store the download URL server-side.
        bookSourceUrl:
            (state.isDigital && state.digitalType == DigitalTypeValues.book)
            ? state.bookSourceUrl
            : null,
      );
      if (_activeRequestId != requestId) return;
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'AddProductViewModel.addProduct',
      );
      final msg = AppError.getMessage(e, 'product.add_product_failed'.tr());

      // PROD-H2: Detect SKU already exists error from backend
      if (msg.toLowerCase().contains('sku') &&
          (msg.toLowerCase().contains('exists') ||
              msg.toLowerCase().contains('déjà'))) {
        state = state.copyWith(
          isLoading: false,
          skuError: 'product.sku_already_exists'.tr(),
          errorMessage: null,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: msg);
      }
    }
  }

  /// Adds a new variant option axis and regenerates all variant combinations.
  ///
  /// [name] The option axis label (e.g., "Color"). [values] The selectable values (e.g., ["Red", "Blue"]).
  /// Existing variant price/stock/sku data is preserved where option values match.
  void addVariantOption(String name, List<String> values) {
    final options = List<VariantOption>.from(state.variantOptions);
    options.add(VariantOption(name: name, values: values));
    state = state.copyWith(variantOptions: options);
    _regenerateVariants();
  }

  /// Bug #16: Invalidate lat/lng when user manually edits address fields
  /// Also resets addressVerified — user must re-select from Geoapify
  void clearCoordinates() => state = state.copyWith(
    latitude: null,
    longitude: null,
    addressVerified: false,
  );

  /// Clear error message to allow re-triggering SnackBar on next error
  void clearError() =>
      state = state.copyWith(errorMessage: null, skuError: null);

  /// PROD-H2: Clear SKU-specific error
  void clearSkuError() => state = state.copyWith(skuError: null);

  /// Handles street input changes — triggers Geoapify address autocomplete.
  ///
  /// [value] The current street input string. Coordinates are invalidated on every
  /// keystroke to prevent stale geolocation data from a prior suggestion (Bug #16).
  Future<void> onStreetChanged(String value) async {
    // Bug #16: Invalidate stale coordinates when user manually edits address
    clearCoordinates();
    if (value.length < 3) {
      state = state.copyWith(showSuggestions: false, addressSuggestions: []);
      return;
    }
    try {
      final suggestions = await _ref
          .read(locationRepositoryProvider)
          .getAddressSuggestions(value);
      state = state.copyWith(
        addressSuggestions: suggestions,
        showSuggestions: suggestions.isNotEmpty,
      );
    } catch (e, st) {
      AppError.log(
        e,
        stackTrace: st,
        context: 'AddProductViewModel.onStreetChanged',
      );
      state = state.copyWith(
        addressSuggestions: [],
        showSuggestions: false,
        errorMessage: 'product.location_error'.tr(),
      );
    }
  }

  /// Removes the image at [index] from the product image list.
  void removeImage(int index) => state = state.copyWith(
    imageModels: List<ImageModel>.from(state.imageModels)..removeAt(index),
  );

  /// Removes the variant option at [index] and regenerates variant combinations.
  void removeVariantOption(int index) {
    final options = List<VariantOption>.from(state.variantOptions);
    options.removeAt(index);
    state = state.copyWith(variantOptions: options);
    _regenerateVariants();
  }

  /// Removes the current video file from state.
  void removeVideo() =>
      state = state.copyWith(videoFile: null, videoDurationSeconds: null);

  /// F-58: Reset form state when re-entering the screen after a previous success.
  /// Call from screen's initState if state.isSuccess == true.
  void resetIfSuccess() {
    if (state.isSuccess) {
      state = const AddProductState();
    }
  }

  /// Populates state with the parsed province, latitude, and longitude from a Geoapify suggestion.
  ///
  /// [suggestion] Raw feature map from the Geoapify autocomplete API response.
  /// Sets [addressVerified] to true, which unblocks product form submission.
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

  /// Sets the multi-step form active step index.
  void setActiveStep(int step) => state = state.copyWith(activeStep: step);

  /// Toggles whether backorders are allowed for this product.
  void setAllowBackorder(bool value) =>
      state = state.copyWith(allowBackorder: value);

  /// Sets the book source URL for digital book products.
  void setBookSourceUrl(String? url) =>
      state = state.copyWith(bookSourceUrl: url);

  /// Sets the selected category and clears any previously selected subcategory.
  void setCategoryId(String? id) =>
      state = state.copyWith(selectedCategoryId: id, selectedSubcategory: null);

  /// Sets the product condition (e.g., 'new', 'used', 'refurbished').
  void setCondition(String? condition) =>
      state = state.copyWith(condition: condition);

  /// Sets the device limit for digital software products.
  void setDeviceLimit(int? limit) => state = state.copyWith(deviceLimit: limit);

  /// Sets the digital product type (e.g., 'software', 'book').
  void setDigitalType(String? type) =>
      state = state.copyWith(digitalType: type);

  /// Sets whether a discount tier validation error should be shown.
  void setDiscountTierError(bool value) =>
      state = state.copyWith(discountTierError: value);

  /// Toggles express delivery; disables local-only when enabled.
  void setExpressEnabled(bool value) => state = state.copyWith(
    expressEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );

  /// Sets whether the user has attempted to submit (triggers validation display).
  void setHasAttemptedSubmit(bool value) =>
      state = state.copyWith(hasAttemptedSubmit: value);

  /// Toggles tracking number availability for the product.
  void setHasTracking(bool value) => state = state.copyWith(hasTracking: value);

  /// Toggles inventory management for the product.
  void setInventoryManaged(bool value) =>
      state = state.copyWith(inventoryManaged: value);

  /// Sets the Linux download URL for digital software products.
  void setLinuxDownloadUrl(String? url) =>
      state = state.copyWith(linuxDownloadUrl: url);

  /// Toggles local-only delivery; disables standard/express/same-day when enabled.
  void setLocalDeliveryOnly(bool value) => state = state.copyWith(
    isLocalDeliveryOnly: value,
    standardEnabled: value ? false : state.standardEnabled,
    expressEnabled: value ? false : state.expressEnabled,
    sameDayEnabled: value ? false : state.sameDayEnabled,
  );

  /// Toggles low-stock alert for inventory management.
  void setLowStockAlertEnabled(bool value) =>
      state = state.copyWith(lowStockAlertEnabled: value);

  /// Sets the macOS download URL for digital software products.
  void setMacosDownloadUrl(String? url) =>
      state = state.copyWith(macosDownloadUrl: url);

  /// Sets the minimum order quantity for this product.
  void setMinimumOrderQuantity(int value) =>
      state = state.copyWith(minimumOrderQuantity: value);

  /// Sets the province code for the product address.
  void setProvince(String province) =>
      state = state.copyWith(selectedProvince: province);

  /// Toggles same-day delivery; disables local-only when enabled.
  void setSameDayEnabled(bool value) => state = state.copyWith(
    sameDayEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );

  /// Sets the seller SKU, trimming whitespace and treating empty as null.
  void setSellerSku(String? sku) => state = state.copyWith(
    sellerSku: sku?.trim().isEmpty == true ? null : sku?.trim(),
  );

  /// Toggles standard delivery; disables local-only when enabled.
  void setStandardEnabled(bool value) => state = state.copyWith(
    standardEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );

  /// Sets the selected subcategory for the product.
  void setSubcategory(String? sub) =>
      state = state.copyWith(selectedSubcategory: sub);

  /// Sets the supplier currency code.
  void setSupplierCurrency(String currency) =>
      state = state.copyWith(selectedSupplierCurrency: currency);

  /// Sets the supplier type (e.g., 'dropship', 'wholesale').
  void setSupplierType(String type) =>
      state = state.copyWith(selectedSupplierType: type);

  /// Toggles quantity tracking for inventory.
  void setTrackQuantity(bool value) =>
      state = state.copyWith(trackQuantity: value);

  /// Sets the product video file and its duration in seconds.
  void setVideo(XFile? file, int? durationSeconds) => state = state.copyWith(
    videoFile: file,
    videoDurationSeconds: durationSeconds,
  );

  /// Sets stock quantity for a specific warehouse.
  ///
  /// Parameters:
  /// - [warehouseId]: the warehouse identifier.
  /// - [qty]: stock quantity at that warehouse.
  void setWarehouseStock(String warehouseId, int qty) {
    final stockMap = Map<String, int>.from(state.warehouseStockMap);
    stockMap[warehouseId] = qty;
    state = state.copyWith(warehouseStockMap: stockMap);
  }

  /// Sets the Windows download URL for digital software products.
  void setWindowsDownloadUrl(String? url) =>
      state = state.copyWith(windowsDownloadUrl: url);

  /// Toggles age restriction flag for the product.
  void toggleAgeRestricted(bool value) =>
      state = state.copyWith(isAgeRestricted: value);

  /// Toggles digital product mode, resetting delivery and perishable fields accordingly.
  ///
  /// [value] When true, delivery options are cleared and free shipping is forced on.
  /// The current standard-delivery state is saved so it can be restored if digital mode is disabled.
  void toggleDigital(bool value) => state = state.copyWith(
    isDigital: value,
    freeShipping: value ? true : state.freeShipping,
    isPerishable: value ? false : state.isPerishable,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
    // Save standard delivery state when enabling digital; restore when disabling
    savedStandardEnabled: value
        ? state.standardEnabled
        : state.savedStandardEnabled,
    standardEnabled: value ? false : state.savedStandardEnabled,
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

  /// Enables or disables free shipping, saving and restoring express/same-day state.
  ///
  /// [value] When true, express and same-day options are disabled (free = standard-only).
  /// When false, previously saved express/same-day selections are restored.
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
        // freeShippingAt10Plus: false,
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

  /// Enables or disables variant mode, clearing all options and variants when disabled.
  ///
  /// [value] When false, [variantOptions] and [variants] are reset to empty lists.
  void toggleHasVariants(bool value) {
    if (value) {
      state = state.copyWith(hasVariants: true);
    } else {
      state = state.copyWith(
        hasVariants: false,
        variantOptions: [],
        variants: [],
      );
    }
  }

  /// Toggles perishable flag — forces local-only delivery when enabled.
  void togglePerishable(bool value) {
    if (value) {
      state = state.copyWith(isPerishable: true, isLocalDeliveryOnly: true);
    } else {
      state = state.copyWith(isPerishable: false);
    }
  }

  /// Toggles warehouse selection — adds or removes [warehouseId] and its stock entry.
  void toggleWarehouseSelection(String warehouseId) {
    final current = List<String>.from(state.selectedWarehouseIds);
    if (current.contains(warehouseId)) {
      current.remove(warehouseId);
      // Remove stock entry too
      final stockMap = Map<String, int>.from(state.warehouseStockMap)
        ..remove(warehouseId);
      state = state.copyWith(
        selectedWarehouseIds: current,
        warehouseStockMap: stockMap,
      );
    } else {
      current.add(warehouseId);
      state = state.copyWith(selectedWarehouseIds: current);
    }
  }

  /// Syncs the full image list back to the ViewModel (Bug #1 fix).
  void updateImages(List<ImageModel> images) =>
      state = state.copyWith(imageModels: images);

  /// Updates the variant option at [index] with new [name] and [values], then regenerates variants.
  void updateVariantOption(int index, String name, List<String> values) {
    final options = List<VariantOption>.from(state.variantOptions);
    options[index] = VariantOption(name: name, values: values);
    state = state.copyWith(variantOptions: options);
    _regenerateVariants();
  }

  /// Updates the price (in dollars, converted to cents) for the variant at [index].
  void updateVariantPrice(int index, double? price) {
    final variants = List<ProductVariantEntry>.from(state.variants);
    final priceCents = price != null ? (price * 100).round() : null;
    variants[index] = variants[index].copyWith(priceCents: priceCents);
    state = state.copyWith(variants: variants);
  }

  /// Updates the SKU for the variant at [index].
  void updateVariantSku(int index, String? sku) {
    final variants = List<ProductVariantEntry>.from(state.variants);
    variants[index] = variants[index].copyWith(sku: sku);
    state = state.copyWith(variants: variants);
  }

  /// Updates the stock quantity for the variant at [index].
  void updateVariantStock(int index, int stockQuantity) {
    final variants = List<ProductVariantEntry>.from(state.variants);
    variants[index] = variants[index].copyWith(stockQuantity: stockQuantity);
    state = state.copyWith(variants: variants);
  }

  /// Auto-generates all variant combinations from variantOptions (cartesian product).
  ///
  /// Preserves price/stock/sku from existing variants where optionValues match.
  /// Called internally by [addVariantOption], [removeVariantOption], and [updateVariantOption].
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
      final key = v.optionValues.entries
          .map((e) => '${e.key}=${e.value}')
          .join('|');
      existingByKey[key] = v;
    }

    final newVariants = combos.map((combo) {
      final key = combo.entries.map((e) => '${e.key}=${e.value}').join('|');
      final existing = existingByKey[key];
      return ProductVariantEntry(
        optionValues: combo,
        priceCents: existing?.priceCents,
        stockQuantity: existing?.stockQuantity ?? 0,
        sku: existing?.sku,
        isActive: existing?.isActive ?? true,
      );
    }).toList();

    state = state.copyWith(variants: newVariants);
  }
}
