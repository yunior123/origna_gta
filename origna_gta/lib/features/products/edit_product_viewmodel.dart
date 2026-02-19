import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/utils.dart';

import 'edit_product_state.dart';

final editProductViewModelProvider = StateNotifierProvider.autoDispose.family<EditProductViewModel, EditProductState, models.Product>((ref, product) {
  return EditProductViewModel(ref, product);
});

class EditProductViewModel extends StateNotifier<EditProductState> {
  final Ref _ref;
  final models.Product _product;

  EditProductViewModel(this._ref, this._product)
    : super(
        EditProductState(
          isSoldOut: _product.stockQuantity == 0,
          isLocalDeliveryOnly: _product.isLocalDeliveryOnly,
          isPerishable: _product.isPerishable,
          isDigital: _product.isDigital,
          digitalType: _product.digitalType,
          macosDownloadUrl: _product.digitalBuilds?[DigitalPlatformValues.macos],
          windowsDownloadUrl: _product.digitalBuilds?[DigitalPlatformValues.windows],
          linuxDownloadUrl: _product.digitalBuilds?[DigitalPlatformValues.linux],
          bookSourceUrl: null, // server-side only, seller must re-enter
          deviceLimit: _product.deviceLimit,
          existingImageUrls: List.from(_product.imageUrls),
          selectedProvince: _product.sellerAddress.state.isNotEmpty ? _product.sellerAddress.state : ProvinceCodeValues.ontario,
          latitude: _product.sellerAddress.latitude,
          longitude: _product.sellerAddress.longitude,
          standardEnabled: _product.deliveryOptions.any((o) => o.type == DeliveryTypeValues.standard),
          expressEnabled: _product.deliveryOptions.any((o) => o.type == DeliveryTypeValues.express),
          sameDayEnabled: _product.deliveryOptions.any((o) => o.type == DeliveryTypeValues.sameDay),
          minimumOrderQuantity: _product.minimumOrderQuantity,
          freeShipping: _product.freeShipping,
        ),
      );

  ProductRepository get _repository => _ref.read(productRepositoryProvider);

  Future<void> onStreetChanged(String value) async {
    if (value.length < 3) {
      state = state.copyWith(showSuggestions: false, addressSuggestions: []);
      return;
    }
    try {
      final suggestions = await _repository.getAutocompleteSuggestions(value);
      state = state.copyWith(addressSuggestions: suggestions, showSuggestions: true);
    } catch (e) {
      AppError.log(e, context: 'EditProductViewModel.onStreetChanged');
    }
  }

  void removeExistingImage(int index) {
    final newList = List<String>.from(state.existingImageUrls)..removeAt(index);
    state = state.copyWith(existingImageUrls: newList);
  }

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

  void setExpressEnabled(bool value) => state = state.copyWith(expressEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);

  void setMinimumOrderQuantity(int value) => state = state.copyWith(minimumOrderQuantity: value);

  void setProvince(String province) => state = state.copyWith(selectedProvince: province);

  void setSameDayEnabled(bool value) => state = state.copyWith(sameDayEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);

  void setStandardEnabled(bool value) => state = state.copyWith(standardEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);

  void toggleDigital(bool value) => state = state.copyWith(
    isDigital: value,
    freeShipping: value ? true : state.freeShipping,
    isPerishable: value ? false : state.isPerishable,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
    standardEnabled: value ? false : _product.deliveryOptions.any((o) => o.type == DeliveryTypeValues.standard),
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

  void setDigitalType(String? type) => state = state.copyWith(digitalType: type);
  void setMacosDownloadUrl(String? url) => state = state.copyWith(macosDownloadUrl: url);
  void setWindowsDownloadUrl(String? url) => state = state.copyWith(windowsDownloadUrl: url);
  void setLinuxDownloadUrl(String? url) => state = state.copyWith(linuxDownloadUrl: url);
  void setBookSourceUrl(String? url) => state = state.copyWith(bookSourceUrl: url);
  void setDeviceLimit(int? limit) => state = state.copyWith(deviceLimit: limit);

  void toggleFreeShipping(bool value) => state = state.copyWith(freeShipping: value);

  void toggleLocalDelivery(bool value) => state = state.copyWith(isLocalDeliveryOnly: value);

  void togglePerishable(bool value) => state = state.copyWith(isPerishable: value);

  void toggleSoldOut(bool value) => state = state.copyWith(isSoldOut: value);

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
    required int shipDays,
    required List<models.SellerDeliveryOption> deliveryOptions,
  }) async {
    // Guard: prevent double-submit
    if (state.isLoading) return;

    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Product name is required');
      return;
    }
    if (description.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Description is required');
      return;
    }
    if (price <= 0) {
      state = state.copyWith(errorMessage: 'product.please_enter_price'.tr());
      return;
    }
    if (price > 100000) {
      state = state.copyWith(errorMessage: 'Price cannot exceed \$100,000');
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
      if (street.trim().isEmpty || city.trim().isEmpty || postalCode.trim().isEmpty || state.selectedProvince.trim().isEmpty) {
        state = state.copyWith(errorMessage: 'Complete product address is required');
        return;
      }
      if (state.latitude == null || state.longitude == null) {
        state = state.copyWith(errorMessage: 'Select a valid address from suggestions');
        return;
      }
    }
    if ((weight ?? 0) < 0 || (length ?? 0) < 0 || (width ?? 0) < 0 || (height ?? 0) < 0) {
      state = state.copyWith(errorMessage: 'Package dimensions must be positive');
      return;
    }

    // Bug #4: Physical products need at least one delivery tier (unless local-only)
    if (!state.isDigital && !state.isLocalDeliveryOnly) {
      if (!state.standardEnabled && !state.expressEnabled && !state.sameDayEnabled) {
        state = state.copyWith(errorMessage: 'Enable at least one delivery option for physical products');
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
        final urls = [state.macosDownloadUrl, state.windowsDownloadUrl, state.linuxDownloadUrl];
        if (urls.every((u) => u == null || u.isEmpty)) {
          state = state.copyWith(errorMessage: 'Add at least one platform download URL');
          return;
        }
        if (urls.whereType<String>().where((u) => u.isNotEmpty).any((u) => !u.startsWith('https://'))) {
          state = state.copyWith(errorMessage: 'Download URLs must start with https://');
          return;
        }
      } else if (state.digitalType == DigitalTypeValues.book) {
        if (state.bookSourceUrl != null && state.bookSourceUrl!.isNotEmpty && !state.bookSourceUrl!.startsWith('https://')) {
          state = state.copyWith(errorMessage: 'Book URL must start with https://');
          return;
        }
      }
    }

    final totalImages = state.existingImageUrls.length + state.newImages.length;
    if (totalImages == 0) {
      state = state.copyWith(errorMessage: 'Please have at least one product image');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);

    try {
      final keywords = generateSearchKeywords(name);
      List<String> allImageUrls = List.from(state.existingImageUrls);

      if (state.newImages.isNotEmpty) {
        final processedImages = await _processImages(state.newImages);
        final successfulUrls = await _repository.uploadImages(processedImages, _product.productId);
        allImageUrls.addAll(successfulUrls);
      }

      final sanitizedDeliveryOptions = state.isDigital ? <models.SellerDeliveryOption>[] : deliveryOptions;
      final updatedProduct = _product.copyWith(
        name: name,
        description: description,
        price: price,
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
          country: CountryValues.canada, // Default for now — sellers can be from any country, UI supports CA addresses
          latitude: state.latitude,
          longitude: state.longitude,
        ),
        weightKg: state.isDigital ? null : weight,
        lengthCm: state.isDigital ? null : length,
        widthCm: state.isDigital ? null : width,
        heightCm: state.isDigital ? null : height,
        isLocalDeliveryOnly: state.isDigital ? false : state.isLocalDeliveryOnly,
        estimatedShipDays: state.isDigital ? 0 : shipDays,
        isPerishable: state.isDigital ? false : state.isPerishable,
        deliveryOptions: sanitizedDeliveryOptions,
        isDigital: state.isDigital,
        digitalType: state.isDigital ? state.digitalType : null,
        digitalBuilds: state.isDigital && state.digitalType == DigitalTypeValues.software
            ? {
                if (state.macosDownloadUrl?.isNotEmpty == true) DigitalPlatformValues.macos: state.macosDownloadUrl!,
                if (state.windowsDownloadUrl?.isNotEmpty == true) DigitalPlatformValues.windows: state.windowsDownloadUrl!,
                if (state.linuxDownloadUrl?.isNotEmpty == true) DigitalPlatformValues.linux: state.linuxDownloadUrl!,
              }
            : null,
        deviceLimit: state.isDigital ? state.deviceLimit : null,
        minimumOrderQuantity: state.minimumOrderQuantity,
        freeShipping: state.freeShipping,
      );

      // Build update map and add bookSourceUrl only if seller re-entered it
      // Note: bookSourceUrl is server-side only — not in Fields constants by design
      final updateMap = updatedProduct.toJson();
      if (state.isDigital && state.digitalType == DigitalTypeValues.book && state.bookSourceUrl?.isNotEmpty == true) {
        updateMap['bookSourceUrl'] = state.bookSourceUrl!;
      }

      await _repository.updateProduct(_product.productId, updateMap);
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: AppError.getMessage(e));
    }
  }

  Future<List<Uint8List>> _processImages(List<ImageModel> imageModels) async {
    final processed = <Uint8List>[];
    for (var model in imageModels) {
      final validated = await _validateAndCompressImage(model.bytes);
      if (validated != null) processed.add(validated);
    }
    return processed;
  }

  Future<Uint8List?> _validateAndCompressImage(Uint8List bytes) async {
    const int maxImageSize = 5 * 1024 * 1024;
    const int maxDimension = 2048;

    if (bytes.length > maxImageSize) return null;

    final image = img.decodeImage(bytes);
    if (image == null) return null;

    img.Image resized = image;
    if (image.width > maxDimension || image.height > maxDimension) {
      resized = img.copyResize(image, width: image.width > image.height ? maxDimension : null, height: image.height > image.width ? maxDimension : null);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
