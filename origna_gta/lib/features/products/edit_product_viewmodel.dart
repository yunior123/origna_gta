import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:origna_gta/utils/constants.dart';
import 'package:origna_gta/core/providers.dart';
import 'package:origna_gta/core/repositories/product_repository.dart';
import 'package:origna_gta/utils/utils.dart';

import 'edit_product_state.dart';

final editProductViewModelProvider = StateNotifierProvider.autoDispose.family<EditProductViewModel, EditProductState, ProductModel>((ref, product) {
  return EditProductViewModel(ref, product);
});

class EditProductViewModel extends StateNotifier<EditProductState> {
  final Ref _ref;
  final ProductModel _product;

  EditProductViewModel(this._ref, this._product)
    : super(
        EditProductState(
          isSoldOut: _product.stockQuantity == 0,
          isLocalDeliveryOnly: _product.isLocalDeliveryOnly,
          isPerishable: _product.isPerishable,
          existingImageUrls: List.from(_product.imageUrls),
          selectedProvince: _product.sellerAddress.state.isNotEmpty ? _product.sellerAddress.state : 'ON',
          latitude: _product.sellerAddress.latitude,
          longitude: _product.sellerAddress.longitude,
          standardEnabled: _product.getDeliveryOption(DeliverySpeed.standard)?.isEnabled ?? true,
          expressEnabled: _product.getDeliveryOption(DeliverySpeed.express)?.isEnabled ?? false,
          sameDayEnabled: _product.getDeliveryOption(DeliverySpeed.sameDay)?.isEnabled ?? false,
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
      selectedProvince: details.province,
      latitude: details.latitude,
      longitude: details.longitude,
      showSuggestions: false,
      addressSuggestions: [],
    );
  }

  void setDeliveryEnabled(DeliverySpeed speed, bool value) {
    if (speed == DeliverySpeed.standard) state = state.copyWith(standardEnabled: value);
    if (speed == DeliverySpeed.express) state = state.copyWith(expressEnabled: value);
    if (speed == DeliverySpeed.sameDay) state = state.copyWith(sameDayEnabled: value);
  }

  void setProvince(String province) => state = state.copyWith(selectedProvince: province);

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
    required List<SellerDeliveryOption> deliveryOptions,
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
    if (stock < 0) {
      state = state.copyWith(errorMessage: 'Stock cannot be negative');
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
    if (state.latitude == null || state.longitude == null) {
      state = state.copyWith(errorMessage: 'Select a valid address from suggestions');
      return;
    }
    if ((weight ?? 0) < 0 || (length ?? 0) < 0 || (width ?? 0) < 0 || (height ?? 0) < 0) {
      state = state.copyWith(errorMessage: 'Package dimensions must be positive');
      return;
    }

    final totalImages = state.existingImageUrls.length + state.newImages.length;
    if (totalImages == 0) {
      state = state.copyWith(errorMessage: 'Please have at least one product image');
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final keywords = generateSearchKeywords(name);
      List<String> allImageUrls = List.from(state.existingImageUrls);

      if (state.newImages.isNotEmpty) {
        final processedImages = await _processImages(state.newImages);
        final successfulUrls = await _repository.uploadImages(processedImages, _product.id);
        allImageUrls.addAll(successfulUrls);
      }

      final updatedProduct = _product.copyWith(
        name: name,
        description: description,
        price: price,
        stockQuantity: state.isSoldOut ? 0 : stock,
        categoryId: categoryId,
        imageUrls: allImageUrls,
        searchKeywords: keywords,
        sellerAddress: Address(
          street: street,
          apartment: apartment,
          city: city,
          state: state.selectedProvince,
          postalCode: postalCode.toUpperCase(),
          country: 'Canada',
          latitude: state.latitude,
          longitude: state.longitude,
        ),
        weightKg: weight,
        lengthCm: length,
        widthCm: width,
        heightCm: height,
        isLocalDeliveryOnly: state.isLocalDeliveryOnly,
        estimatedShipDays: shipDays,
        isPerishable: state.isPerishable,
        deliveryOptions: deliveryOptions,
      );

      await _repository.updateProduct(_product.id, updatedProduct.toMap());
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

extension ProductModelCopyWith on ProductModel {
  ProductModel copyWith({
    String? name,
    double? price,
    List<String>? imageUrls,
    Address? sellerAddress,
    String? description,
    int? stockQuantity,
    int? categoryId,
    List<String>? searchKeywords,
    double? weightKg,
    double? lengthCm,
    double? widthCm,
    double? heightCm,
    bool? isLocalDeliveryOnly,
    int? estimatedShipDays,
    List<SellerDeliveryOption>? deliveryOptions,
    bool? isPerishable,
  }) {
    return ProductModel(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      description: description ?? this.description,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      categoryId: categoryId ?? this.categoryId,
      sellerId: sellerId,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      rating: rating,
      ratingCount: ratingCount,
      dateCreated: dateCreated,
      weightKg: weightKg ?? this.weightKg,
      lengthCm: lengthCm ?? this.lengthCm,
      widthCm: widthCm ?? this.widthCm,
      heightCm: heightCm ?? this.heightCm,
      isLocalDeliveryOnly: isLocalDeliveryOnly ?? this.isLocalDeliveryOnly,
      estimatedShipDays: estimatedShipDays ?? this.estimatedShipDays,
      deliveryOptions: deliveryOptions ?? this.deliveryOptions,
      isPerishable: isPerishable ?? this.isPerishable,
    );
  }
}
