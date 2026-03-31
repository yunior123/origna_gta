import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/products/variant_models.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/utils.dart';

import 'edit_product_state.dart';
import 'product_image_helpers.dart';

/// Riverpod provider for [EditProductViewModel].
///
/// Family provider keyed by the [models.Product] being edited — each product
/// gets its own pre-filled state from the existing product data.
final editProductViewModelProvider = StateNotifierProvider.autoDispose
    .family<EditProductViewModel, EditProductState, models.Product>((
      ref,
      product,
    ) {
      return EditProductViewModel(ref, product);
    });

/// Manages product editing: loads existing data, validates changes, submits update.
///
/// ## Key Decisions
/// - Pre-fills all state from the existing [models.Product] in the constructor.
/// - Ownership guard: [updateProduct] verifies the current user owns the product before submitting.
/// - Digital products skip address/shipping validation; physical products require delivery options.
/// - Province codes are normalized ([_normalizeProvinceCode]) to handle legacy full-name values.
///
/// See also:
/// - [EditProductState] for the state shape
/// - [AddProductViewModel] for new product creation
class EditProductViewModel extends StateNotifier<EditProductState> {
  final Ref _ref;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  final models.Product _product;

  EditProductViewModel(this._ref, this._product)
    : super(
        EditProductState(
          isSoldOut: _product.stockQuantity == 0,
          isLocalDeliveryOnly: _product.isLocalDeliveryOnly,
          isPerishable: _product.isPerishable,
          isDigital: _product.isDigital,
          isAgeRestricted: _product.isAgeRestricted,
          digitalType: _product.digitalType,
          macosDownloadUrl:
              _product.digitalBuilds?[DigitalPlatformValues.macos],
          windowsDownloadUrl:
              _product.digitalBuilds?[DigitalPlatformValues.windows],
          linuxDownloadUrl:
              _product.digitalBuilds?[DigitalPlatformValues.linux],
          bookSourceUrl: null, // server-side only, seller must re-enter
          deviceLimit: _product.deviceLimit,
          existingImageUrls: List.from(_product.imageUrls),
          existingVideoUrl: _product.videoUrl,
          selectedProvince: _normalizeProvinceCode(
            _product.sellerAddress?.state,
          ),
          latitude: _product.sellerAddress?.latitude,
          longitude: _product.sellerAddress?.longitude,
          standardEnabled: _product.deliveryOptions.any(
            (o) => o.type == DeliveryTypeValues.standard,
          ),
          savedStandardEnabled: _product.deliveryOptions.any(
            (o) => o.type == DeliveryTypeValues.standard,
          ),
          expressEnabled: _product.deliveryOptions.any(
            (o) => o.type == DeliveryTypeValues.express,
          ),
          sameDayEnabled: _product.deliveryOptions.any(
            (o) => o.type == DeliveryTypeValues.sameDay,
          ),
          minimumOrderQuantity: _product.minimumOrderQuantity,
          freeShipping: _product.freeShipping,
          taxCode: _product.taxCode,
          // Variant/condition fields — parity with AddProductState
          hasVariants: _product.hasVariants,
          variantOptions: _product.variantOptions
              .map((v) => VariantOption.fromMap(v.toJson()))
              .toList(),
          variants: _product.variants
              .map((v) => ProductVariantEntry.fromMap(v.toJson()))
              .toList(),
          condition: _product.condition,
          // Warehouse fields
          selectedWarehouseIds: _product.warehouseIds ?? const [],
          warehouseStockMap: _product.warehouseStockMap ?? const {},
        ),
      );

  /// Normalizes legacy province values like "Ontario" to canonical short codes.
  ///
  /// Returns `ON` when [rawProvince] is null, blank, or unknown so edit-product
  /// dropdowns always receive a valid selection.
  static String _normalizeProvinceCode(String? rawProvince) {
    final normalized = rawProvince?.trim();
    if (normalized == null || normalized.isEmpty) {
      return ProvinceCodeValues.ontario;
    }

    final upper = normalized.toUpperCase();
    if (ProvinceCodeValues.all.contains(upper)) {
      return upper;
    }

    for (final entry in ProvinceCodeValues.names.entries) {
      if (entry.value.toUpperCase() == upper) {
        return entry.key;
      }
    }

    return ProvinceCodeValues.ontario;
  }

  ProductRepository get _repository => _ref.read(productRepositoryProvider);

  /// Reads an image file and adds it to the new images list.
  ///
  /// Parameters:
  /// - [file]: the picked image file to add.
  Future<void> addImage(XFile file) async {
    final bytes = await file.readAsBytes();
    state = state.copyWith(
      newImages: [
        ...state.newImages,
        ImageModel(url: file.path, bytes: bytes),
      ],
    );
  }

  /// Replaces the entire new images list with [images].
  void updateNewImages(List<ImageModel> images) {
    state = state.copyWith(newImages: List<ImageModel>.from(images));
  }

  /// Triggers address autocomplete when street input changes.
  ///
  /// Parameters:
  /// - [value]: current street text; queries are skipped when < 3 characters.
  Future<void> onStreetChanged(String value) async {
    if (value.length < 3) {
      state = state.copyWith(showSuggestions: false, addressSuggestions: []);
      return;
    }
    try {
      final suggestions = await _repository.getAutocompleteSuggestions(value);
      state = state.copyWith(
        addressSuggestions: suggestions,
        showSuggestions: true,
      );
    } catch (e) {
      AppError.log(e, context: 'EditProductViewModel.onStreetChanged');
    }
  }

  /// Removes the existing image at [index] from the image list.
  void removeExistingImage(int index) {
    final newList = List<String>.from(state.existingImageUrls)..removeAt(index);
    state = state.copyWith(existingImageUrls: newList);
  }

  /// Removes the current video (both new upload and existing URL).
  void removeVideo() {
    state = state.copyWith(
      videoFile: null,
      videoDurationSeconds: null,
      existingVideoUrl: null,
    );
  }

  /// Populates state with province, lat/lng from a Geoapify suggestion.
  ///
  /// Parameters:
  /// - [suggestion]: raw feature map from Geoapify autocomplete API.
  void selectAddress(Map<String, dynamic> suggestion) {
    final details = parseAddressSuggestion(suggestion);
    state = state.copyWith(
      selectedProvince: details.state,
      latitude: details.latitude,
      longitude: details.longitude,
      showSuggestions: false,
      addressSuggestions: [],
    );
  }

  /// Sets the book source URL for digital book products.
  void setBookSourceUrl(String? url) =>
      state = state.copyWith(bookSourceUrl: url);

  /// Sets the device limit for digital software products.
  void setDeviceLimit(int? limit) => state = state.copyWith(deviceLimit: limit);

  /// Sets the digital product type (e.g., 'software', 'book').
  void setDigitalType(String? type) =>
      state = state.copyWith(digitalType: type);

  /// Move the image at [index] in existingImageUrls to position 0 (cover slot).
  void setExistingImageAsCover(int index) {
    final urls = List<String>.from(state.existingImageUrls);
    if (index <= 0 || index >= urls.length) return;
    final cover = urls.removeAt(index);
    urls.insert(0, cover);
    state = state.copyWith(existingImageUrls: urls);
  }

  /// Toggles express delivery; disables local-only when enabled.
  void setExpressEnabled(bool value) => state = state.copyWith(
    expressEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );

  /// Sets the Linux download URL for digital software products.
  void setLinuxDownloadUrl(String? url) =>
      state = state.copyWith(linuxDownloadUrl: url);

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

  /// Toggles standard delivery; disables local-only when enabled.
  void setStandardEnabled(bool value) => state = state.copyWith(
    standardEnabled: value,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
  );

  /// Sets the product video file and its duration.
  ///
  /// Parameters:
  /// - [file]: the video file to upload.
  /// - [durationSeconds]: video length in seconds (validated against [BusinessRules.maxVideoDurationSeconds]).
  void setVideo(XFile file, int durationSeconds) {
    state = state.copyWith(
      videoFile: file,
      videoDurationSeconds: durationSeconds,
      existingVideoUrl: null,
    );
  }

  /// Sets the Windows download URL for digital software products.
  void setWindowsDownloadUrl(String? url) =>
      state = state.copyWith(windowsDownloadUrl: url);

  /// Toggles age restriction flag for the product.
  void toggleAgeRestricted(bool value) =>
      state = state.copyWith(isAgeRestricted: value);

  /// Toggles digital product mode — clears delivery options and forces free shipping on.
  ///
  /// When enabling: saves standard delivery state, disables all delivery tiers.
  /// When disabling: restores previously saved standard delivery state.
  void toggleDigital(bool value) => state = state.copyWith(
    isDigital: value,
    freeShipping: value ? true : state.freeShipping,
    isPerishable: value ? false : state.isPerishable,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
    // Save current standardEnabled before disabling, restore from saved state
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

  /// Toggles free shipping for the product.
  void toggleFreeShipping(bool value) =>
      state = state.copyWith(freeShipping: value);

  /// Toggles local-only delivery; disables standard/express/same-day when enabled.
  void toggleLocalDelivery(bool value) =>
      state = state.copyWith(isLocalDeliveryOnly: value);

  /// Toggles perishable flag — forces local-only delivery when enabled.
  void togglePerishable(bool value) {
    if (value) {
      state = state.copyWith(isPerishable: true, isLocalDeliveryOnly: true);
    } else {
      state = state.copyWith(isPerishable: false);
    }
  }

  /// Toggles the sold-out flag — sets stock to 0 when enabled.
  void toggleSoldOut(bool value) => state = state.copyWith(isSoldOut: value);

  /// Validates all inputs and submits the product update to the server.
  ///
  /// Parameters:
  /// - [name], [description], [price], [stock], [categoryId]: required product fields.
  /// - [street], [apartment], [city], [postalCode]: product address (physical only).
  /// - [weight], [length], [width], [height]: optional package dimensions.
  /// - [taxCode]: optional tax code.
  /// - [shipDays]: estimated shipping days.
  /// - [deliveryOptions]: seller delivery options.
  /// - [inventory]: optional inventory configuration.
  /// - [compareAtPrice]: original/crossed-out price for discount display (must be > price).
  /// - [nameF], [descriptionF]: French translations (Bill 96).
  ///
  /// Ownership guard: verifies current user owns the product.
  /// Uploads new images and video before updating the product document.
  ///
  /// Gotchas:
  /// - Digital products skip address and delivery option validation.
  /// - Physical products require at least one delivery tier (unless local-only).
  Future<void> updateProduct({
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
    required int shipDays,
    required List<models.SellerDeliveryOption> deliveryOptions,
    models.InventoryConfig? inventory,

    /// Original/crossed-out price for discount display (null = no sale, must be > price)
    double? compareAtPrice,
    // Bill 96: French translation fields
    String? nameF,
    String? descriptionF,
  }) async {
    // Guard: prevent double-submit
    if (state.isLoading) return;

    // Input boundary: convert dollars to cents immediately
    final priceCents = (price * 100).round();

    // CRITICAL: Ownership guard — prevent editing another seller's product
    final currentUid = _ref.read(userIdProvider);
    if (currentUid == null || currentUid != _product.sellerId) {
      state = state.copyWith(
        errorMessage: 'Unauthorized: you do not own this product',
      );
      return;
    }

    final normalizedTaxCode = (taxCode == null || taxCode.trim().isEmpty)
        ? null
        : taxCode.trim();

    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Product name is required');
      return;
    }
    if (description.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Description is required');
      return;
    }
    if (price <= 0.99) {
      state = state.copyWith(errorMessage: 'product.please_enter_price'.tr());
      return;
    }
    if (price > 100000) {
      state = state.copyWith(errorMessage: 'product.price_limit_exceeded'.tr());
      return;
    }
    if (compareAtPrice != null && compareAtPrice - price < 0.50) {
      state = state.copyWith(
        errorMessage: 'product.compare_at_price_must_be_higher'.tr(),
      );
      return;
    }
    if (stock < 0) {
      state = state.copyWith(errorMessage: 'Stock cannot be negative');
      return;
    }
    if (categoryId <= 0) {
      state = state.copyWith(errorMessage: 'Category is required');
      return;
    }
    // Address validation only for physical products
    if (!state.isDigital) {
      if (street.trim().isEmpty ||
          city.trim().isEmpty ||
          postalCode.trim().isEmpty ||
          state.selectedProvince.trim().isEmpty) {
        state = state.copyWith(
          errorMessage: 'Complete product address is required',
        );
        return;
      }
      if (state.latitude == null || state.longitude == null) {
        state = state.copyWith(
          errorMessage: 'Select a valid address from suggestions',
        );
        return;
      }
    }
    if ((weight ?? 0) < 0 ||
        (length ?? 0) < 0 ||
        (width ?? 0) < 0 ||
        (height ?? 0) < 0) {
      state = state.copyWith(
        errorMessage: 'Package dimensions must be positive',
      );
      return;
    }

    // Bug #4: Physical products need at least one delivery tier (unless local-only)
    if (!state.isDigital && !state.isLocalDeliveryOnly) {
      if (!state.standardEnabled &&
          !state.expressEnabled &&
          !state.sameDayEnabled) {
        state = state.copyWith(
          errorMessage:
              'Enable at least one delivery option for physical products',
        );
        return;
      }
    }

    // Digital product validation
    if (state.isDigital) {
      if (state.digitalType == null) {
        state = state.copyWith(errorMessage: 'Select a digital product type');
        return;
      }
      if (state.digitalType == DigitalTypeValues.software) {
        final urls = [
          state.macosDownloadUrl,
          state.windowsDownloadUrl,
          state.linuxDownloadUrl,
        ];
        if (urls.every((u) => u == null || u.isEmpty)) {
          state = state.copyWith(
            errorMessage: 'Add at least one platform download URL',
          );
          return;
        }
        if (urls
            .whereType<String>()
            .where((u) => u.isNotEmpty)
            .any((u) => !u.startsWith('https://'))) {
          state = state.copyWith(
            errorMessage: 'Download URLs must start with https://',
          );
          return;
        }
      } else if (state.digitalType == DigitalTypeValues.book) {
        final url = state.bookSourceUrl?.trim();
        if (url != null && url.isNotEmpty) {
          if (url.length > 500) {
            state = state.copyWith(errorMessage: 'product.url_too_long'.tr());
            return;
          }
          if (!url.startsWith('https://')) {
            state = state.copyWith(
              errorMessage: 'product.book_url_https_required'.tr(),
            );
            return;
          }
        }
      }
    }

    final totalImages = state.existingImageUrls.length + state.newImages.length;
    if (totalImages == 0) {
      state = state.copyWith(
        errorMessage: 'Please have at least one product image',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      isSuccess: false,
    );

    try {
      if (state.videoFile != null) {
        if ((state.videoDurationSeconds ?? 0) >
            BusinessRules.maxVideoDurationSeconds) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'product.video_too_long'.tr(),
          );
          return;
        }
        // P1-21: Check file size via File.length() to avoid loading entire video into RAM.
        // Falls back to readAsBytes().length for in-memory XFiles (e.g. in tests).
        final videoFile = File(state.videoFile!.path);
        final videoLength = await videoFile.exists()
            ? await videoFile.length()
            : (await state.videoFile!.readAsBytes()).length;
        if (videoLength > BusinessRules.maxVideoBytes) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'product.video_too_large'.tr(),
          );
          return;
        }
      }

      final keywords = generateSearchKeywords(name);
      List<String> allImageUrls = List.from(state.existingImageUrls);

      if (state.newImages.isNotEmpty) {
        final processedImages = await compressProductImages(state.newImages);
        final successfulUrls = await _repository.uploadImages(
          processedImages,
          _product.productId,
        );
        // P1-22: Block save if any image upload failed
        if (successfulUrls.length < processedImages.length) {
          final failed = processedImages.length - successfulUrls.length;
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'product.image_upload_failed'.tr(
              namedArgs: {'count': failed.toString()},
            ),
          );
          return;
        }
        allImageUrls.addAll(successfulUrls);
      }

      String? uploadedVideoUrl;
      // If a new video is selected, already validated above, now upload
      if (state.videoFile != null) {
        uploadedVideoUrl = await _repository.uploadProductVideo(
          state.videoFile!,
          _product.sellerId,
        );
      } else if (state.existingVideoUrl != null) {
        uploadedVideoUrl = state.existingVideoUrl;
      }
      final sanitizedDeliveryOptions = state.isDigital
          ? <models.SellerDeliveryOption>[]
          : deliveryOptions;
      final updatedProduct = _product.copyWith(
        name: name,
        nameF: nameF?.trim().isEmpty == true ? null : nameF?.trim(),
        description: description,
        descriptionF: descriptionF?.trim().isEmpty == true
            ? null
            : descriptionF?.trim(),
        priceCents: priceCents,
        stockQuantity: state.isSoldOut ? 0 : stock,
        categoryId: categoryId,
        imageUrls: allImageUrls,
        keywords: keywords,
        sellerAddress: models.Address(
          street: street,
          apartment: apartment,
          city: city,
          state: state.selectedProvince,
          postalCode: postalCode.toUpperCase(),
          // Preserve original country from product; fall back to Canada if not set
          country: _product.sellerAddress?.country.isNotEmpty == true
              ? _product.sellerAddress!.country
              : CountryValues.canada,
          latitude: state.latitude,
          longitude: state.longitude,
        ),
        weightKg: state.isDigital ? null : weight,
        lengthCm: state.isDigital ? null : length,
        widthCm: state.isDigital ? null : width,
        heightCm: state.isDigital ? null : height,
        isLocalDeliveryOnly: state.isDigital
            ? false
            : state.isLocalDeliveryOnly,
        estimatedShipDays: state.isDigital ? 0 : shipDays,
        isPerishable: state.isDigital ? false : state.isPerishable,
        isAgeRestricted: state.isDigital ? false : state.isAgeRestricted,
        deliveryOptions: sanitizedDeliveryOptions,
        isDigital: state.isDigital,
        digitalType: state.isDigital ? state.digitalType : null,
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
        minimumOrderQuantity: state.minimumOrderQuantity,
        freeShipping: state.freeShipping,
        taxCode: normalizedTaxCode,
        inventory: inventory ?? _product.inventory,
        compareAtPriceCents: compareAtPrice != null
            ? (compareAtPrice * 100).round()
            : null,
      );

      // Build update map and add bookSourceUrl only if seller re-entered it
      final updateMap = updatedProduct.toJson();
      if (state.isDigital &&
          state.digitalType == DigitalTypeValues.book &&
          state.bookSourceUrl?.isNotEmpty == true) {
        updateMap[Fields.bookSourceUrl] = state.bookSourceUrl!;
      }

      if (uploadedVideoUrl != null) {
        updateMap[Fields.videoUrl] = uploadedVideoUrl;
      } else {
        // If neither videoFile nor existingVideoUrl is set, clear the stored videoUrl.
        updateMap[Fields.videoUrl] = null;
      }

      await _repository.updateProduct(_product.productId, updateMap);
      if (_disposed) return;
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: AppError.getMessage(e),
      );
    }
  }
}
