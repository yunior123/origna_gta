part of '../editproduct_screen.dart';

// ============================================================================
// SUBMIT SECTION — Save handler, success callback
// ============================================================================

extension _EditProductSubmitSection on _EditProductScreenState {
  double? _parseSubmittedPrice() {
    final priceText = _priceController.text.trim();
    final parsedPrice = double.tryParse(priceText);
    if (parsedPrice != null) return parsedPrice;

    AppLogger.w(
      'Edit product submit aborted due to invalid price input: $priceText',
      tag: 'product',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('product.invalid_price'.tr()),
        backgroundColor: DesignTokens.error,
      ),
    );
    return null;
  }

  void handleSave(EditProductViewModel viewModel) {
    if (!_formKey.currentState!.validate()) return;

    final price = _parseSubmittedPrice();
    if (price == null) return;

    final state = ref.read(editProductViewModelProvider(widget.product));

    // Bug #6: Preserve existing quantityDiscounts/additionalItemCost/maxItemsPerShipment from product
    final existingStandard = widget.product.deliveryOptions
        .where((o) => o.type == 'standard')
        .firstOrNull;
    final existingExpress = widget.product.deliveryOptions
        .where((o) => o.type == 'express')
        .firstOrNull;
    final existingQuantityDiscounts =
        existingStandard?.quantityDiscounts ??
        existingExpress?.quantityDiscounts ??
        const <ShippingQuantityDiscount>[];
    final existingAdditionalItemCostCents =
        existingStandard?.additionalItemCostCents ??
        existingExpress?.additionalItemCostCents ??
        0;
    final existingMaxItems =
        existingStandard?.maxItemsPerShipment ??
        existingExpress?.maxItemsPerShipment ??
        0;

    List<SellerDeliveryOption> deliveryOptions;
    if (state.isDigital) {
      deliveryOptions = <SellerDeliveryOption>[];
    } else if (state.isLocalDeliveryOnly) {
      // Bug #2: Inject pickup option for local-only products
      deliveryOptions = [
        SellerDeliveryOption(
          type: 'pickup',
          description: 'product.local_pickup_only'.tr(),
          estimatedDays: 0,
          costCents: 0,
        ),
      ];
    } else {
      deliveryOptions = <SellerDeliveryOption>[
        if (state.standardEnabled)
          SellerDeliveryOption(
            type: 'standard',
            description: 'product.standard_delivery'.tr(),
            estimatedDays: int.tryParse(_standardDaysController.text) ?? 5,
            costCents:
                ((double.tryParse(_standardPriceController.text) ?? 0.0) * 100)
                    .round(),
            quantityDiscounts: existingQuantityDiscounts,
            additionalItemCostCents: existingAdditionalItemCostCents,
            maxItemsPerShipment: existingMaxItems,
          ),
        if (state.expressEnabled)
          SellerDeliveryOption(
            type: 'express',
            description: 'product.express_delivery'.tr(),
            estimatedDays: int.tryParse(_expressDaysController.text) ?? 2,
            costCents:
                ((double.tryParse(_expressPriceController.text) ?? 9.99) * 100)
                    .round(),
            quantityDiscounts: existingQuantityDiscounts,
            additionalItemCostCents: existingAdditionalItemCostCents,
            maxItemsPerShipment: existingMaxItems,
          ),
        if (state.sameDayEnabled)
          SellerDeliveryOption(
            type: 'same_day',
            description: 'product.same_day_delivery'.tr(),
            estimatedDays: 0,
            costCents:
                ((double.tryParse(_sameDayPriceController.text) ?? 14.99) * 100)
                    .round(),
          ),
      ];
    }

    final existingInventory =
        widget.product.inventory ?? const InventoryConfig();
    final updatedInventory = existingInventory.copyWith(
      lowStockThreshold: ref.read(_editProductLowStockAlertProvider)
          ? (int.tryParse(_lowStockThresholdController.text) ?? 5)
          : 0,
    );

    viewModel.updateProduct(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      nameF: _nameFController.text.trim().isEmpty
          ? null
          : _nameFController.text.trim(),
      descriptionF: _descriptionFController.text.trim().isEmpty
          ? null
          : _descriptionFController.text.trim(),
      price: price,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
      categoryId: int.tryParse(_categoryController.text.trim()) ?? 0,
      street: _streetController.text.trim(),
      apartment: _apartmentController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      weight: double.tryParse(_weightController.text),
      length: double.tryParse(_lengthController.text),
      width: double.tryParse(_widthController.text),
      height: double.tryParse(_heightController.text),
      shipDays: state.isDigital
          ? 0
          : int.tryParse(_shipDaysController.text) ?? 3,
      taxCode: _taxCodeController.text.trim(),
      deliveryOptions: deliveryOptions,
      inventory: updatedInventory,
      compareAtPrice: _compareAtPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_compareAtPriceController.text.trim()),
    );
  }

  void onUpdateSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('product.updated_success'.tr()),
        backgroundColor: DesignTokens.success,
      ),
    );
    Navigator.pop(context, true);
  }
}
