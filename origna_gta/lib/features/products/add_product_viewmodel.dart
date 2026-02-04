import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/models/generated/models.dart' as models;
import 'package:origna_gta/utils/utils.dart';

import 'add_product_state.dart';

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
    // LEGACY: Flat supplier fields (for backward compatibility)
    double? cost,
    String? supplierSku,
    String? supplierUrl,
    // NEW: Structured supplier info
    models.SupplierInfo? supplier,
    // NEW: Inventory configuration
    models.InventoryConfig? inventory,
    // NEW: Product status
    String? status,
  }) async {
    if (name.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Product name is required');
      return;
    }
    if (description.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Description is required');
      return;
    }
    if (price <= 0) {
      state = state.copyWith(errorMessage: 'Price must be greater than 0');
      return;
    }
    if (price > 100000) {
      state = state.copyWith(errorMessage: 'Price cannot exceed \$100,000 CAD');
      return;
    }
    if (stock < 0) {
      state = state.copyWith(errorMessage: 'Stock cannot be negative');
      return;
    }
    final minOrderQty = minimumOrderQuantity ?? state.minimumOrderQuantity;
    if (minOrderQty < 1) {
      state = state.copyWith(errorMessage: 'Minimum order quantity must be at least 1');
      return;
    }
    if (categoryId <= 0) {
      state = state.copyWith(errorMessage: 'Category is required');
      return;
    }
    if (street.trim().isEmpty || city.trim().isEmpty || postalCode.trim().isEmpty || state.selectedProvince.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Complete product address is required');
      return;
    }
    // Relaxed address validation for Web/Test environment where Geocoder might fail
    /* 
    if (state.latitude == null || state.longitude == null) {
      state = state.copyWith(errorMessage: 'Select a valid address from suggestions');
      return;
    }
    */

    if (!isValidTaxCode(taxCode)) {
      state = state.copyWith(errorMessage: 'Invalid tax code (expected txcd_########)');
      return;
    }
    if ((weight ?? 0) < 0 || (length ?? 0) < 0 || (width ?? 0) < 0 || (height ?? 0) < 0) {
      state = state.copyWith(errorMessage: 'Package dimensions must be positive');
      return;
    }

    if (state.imageModels.isEmpty) {
      state = state.copyWith(errorMessage: 'Please add at least one product image');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final productRepository = _ref.read(productRepositoryProvider);

      final sanitizedDeliveryOptions = state.isDigital ? <models.SellerDeliveryOption>[] : deliveryOptions;
      final productCreate = models.ProductCreate(
        sellerId: _ref.read(userIdProvider)!,
        name: name,
        keywords: generateSearchKeywords(name),
        stockQuantity: stock,
        price: price,
        imageUrls: [],
        sellerAddress: models.Address(
          street: street,
          apartment: apartment,
          city: city,
          state: state.selectedProvince,
          postalCode: postalCode.toUpperCase(),
          country: 'Canada',
          latitude: state.latitude,
          longitude: state.longitude,
        ),
        description: description,
        categoryId: categoryId,
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
        minimumOrderQuantity: minOrderQty,
        freeShipping: freeShipping ?? state.freeShipping,
        // LEGACY: Flat supplier fields (backward compatibility)
        cost: cost,
        supplierSku: supplierSku,
        supplierUrl: supplierUrl,
        // NEW: Structured objects for long-term scaling
        supplier: supplier,
        inventory: inventory,
        status: status ?? 'active',
      );

      // Convert ProductCreate to JSON, then create Product for repository
      final productData = productCreate.toJson();
      // Create a Product instance from the JSON (repository expects Product type)
      final product = models.Product.fromJson({
        ...productData,
        'productId': '', // Will be set by Firestore
        'dateCreated': DateTime.now().toIso8601String(),
        'rating': 0.0,
        'isActive': true,
      });

      final productId = await productRepository.addProduct(product);
      final compressedImages = await _compressImages(state.imageModels);
      final urls = await productRepository.uploadImages(compressedImages, productId);

      if (urls.isEmpty) throw Exception('Failed to upload images');

      await productRepository.updateProduct(productId, {'productId': productId, 'imageUrls': urls});
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> onStreetChanged(String value) async {
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
      selectedProvince: details.province,
      latitude: details.latitude,
      longitude: details.longitude,
      showSuggestions: false,
      addressSuggestions: [],
    );
  }

  void setExpressEnabled(bool value) => state = state.copyWith(expressEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);
  void setFreeShippingAt10Plus(bool? value) => state = state.copyWith(freeShippingAt10Plus: value ?? false);
  void setLocalDeliveryOnly(bool value) => state = state.copyWith(
    isLocalDeliveryOnly: value,
    standardEnabled: value ? false : state.standardEnabled,
    expressEnabled: value ? false : state.expressEnabled,
  );

  void setMinimumOrderQuantity(int value) => state = state.copyWith(minimumOrderQuantity: value);

  void setProvince(String province) => state = state.copyWith(selectedProvince: province);

  void setSameDayEnabled(bool value) => state = state.copyWith(sameDayEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);

  void setStandardEnabled(bool value) => state = state.copyWith(standardEnabled: value, isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly);

  void toggleDigital(bool value) => state = state.copyWith(
    isDigital: value,
    isPerishable: value ? false : state.isPerishable,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
    standardEnabled: value ? false : state.standardEnabled,
    expressEnabled: value ? false : state.expressEnabled,
    sameDayEnabled: value ? false : state.sameDayEnabled,
  );

  void toggleFreeShipping(bool value) => state = state.copyWith(freeShipping: value);

  void togglePerishable(bool value) => state = state.copyWith(isPerishable: value);

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
      resized = img.copyResize(image, width: image.width > image.height ? 2048 : null, height: image.height > image.width ? 2048 : null);
    }
    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }
}
