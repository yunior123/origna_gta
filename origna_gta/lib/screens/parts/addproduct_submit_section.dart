part of '../addproduct_screen.dart';

// ============================================================================
// SUBMIT SECTION — Submit button, delivery options builder, variant builder
// ============================================================================

extension _AddProductSubmitSection on _AddProductScreenState {
  List<SellerDeliveryOption> buildDeliveryOptions(AddProductState state) {
    if (state.isDigital) return [];

    if (state.isLocalDeliveryOnly) {
      return [
        SellerDeliveryOption(
          type: DeliveryTypeValues.pickup,
          description: 'product.local_pickup_only'.tr(),
          estimatedDays: 0,
          costCents: 0,
        ),
      ];
    }

    final quantityDiscounts = <ShippingQuantityDiscount>[];

    final discount3 = double.tryParse(_shippingDiscount3Controller.text);
    if (discount3 != null && discount3 > 0) {
      quantityDiscounts.add(
        ShippingQuantityDiscount(
          minQuantity: 3,
          discountType: DiscountTypeValues.percent,
          discountValue: discount3,
          label: 'product.shipping_discount_label'.tr(
            namedArgs: {'percent': discount3.toStringAsFixed(0), 'qty': '3'},
          ),
        ),
      );
    }

    final discount5 = double.tryParse(_shippingDiscount5Controller.text);
    if (discount5 != null && discount5 > 0) {
      quantityDiscounts.add(
        ShippingQuantityDiscount(
          minQuantity: 5,
          discountType: DiscountTypeValues.percent,
          discountValue: discount5,
          label: 'product.shipping_discount_label'.tr(
            namedArgs: {'percent': discount5.toStringAsFixed(0), 'qty': '5'},
          ),
        ),
      );
    }

    final additionalItemCostCents =
        parseMoneyToCents(_additionalItemCostController.text) ?? 0;
    final maxItems = int.tryParse(_maxItemsPerShipmentController.text) ?? 0;

    return [
      if (state.standardEnabled)
        SellerDeliveryOption(
          type: DeliveryTypeValues.standard,
          description: 'product.standard_delivery'.tr(),
          estimatedDays: int.tryParse(_standardDaysController.text) ?? 5,
          costCents: parseMoneyToCents(_standardPriceController.text) ?? 0,
          quantityDiscounts: quantityDiscounts,
          additionalItemCostCents: additionalItemCostCents,
          maxItemsPerShipment: maxItems,
        ),
      if (state.expressEnabled)
        SellerDeliveryOption(
          type: DeliveryTypeValues.express,
          description: 'product.express_delivery'.tr(),
          estimatedDays: int.tryParse(_expressDaysController.text) ?? 2,
          costCents: parseMoneyToCents(_expressPriceController.text) ?? 999,
          quantityDiscounts: quantityDiscounts,
          additionalItemCostCents: additionalItemCostCents,
          maxItemsPerShipment: maxItems,
        ),
      if (state.sameDayEnabled)
        SellerDeliveryOption(
          type: DeliveryTypeValues.sameDay,
          description: 'product.same_day_delivery'.tr(),
          estimatedDays: 0,
          costCents: parseMoneyToCents(_sameDayPriceController.text) ?? 1499,
          quantityDiscounts: quantityDiscounts,
          additionalItemCostCents: additionalItemCostCents,
          maxItemsPerShipment: maxItems,
        ),
    ];
  }

  Widget buildSubmitButton(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return Semantics(
      button: true,
      label: 'btn-publish-product',
      child: GestureDetector(
        // PROD-C4: also disable during video upload
        onTapDown: (state.isLoading || state.isUploadingVideo)
            ? null
            : (_) => HapticFeedback.mediumImpact(),
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          height: 56,
          decoration: BoxDecoration(
            gradient: (state.isLoading || state.isUploadingVideo)
                ? null
                : DesignTokens.primaryGradient,
            color: (state.isLoading || state.isUploadingVideo)
                ? DesignTokens.outline
                : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: (state.isLoading || state.isUploadingVideo)
                ? []
                : [
                    BoxShadow(
                      color: DesignTokens.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('addproduct_submit_button'),
              borderRadius: BorderRadius.circular(16),
              onTap: (state.isLoading || state.isUploadingVideo)
                  ? null
                  : () => _handleSubmit(state, viewModel),
              child: Center(
                // PROD-C4: show spinner for both full loading and video upload phase
                child: (state.isLoading || state.isUploadingVideo)
                    ? const ModernLoadingIndicator(
                        size: 24,
                        strokeWidth: 2.5,
                        color: DesignTokens.textOnPrimary,
                        centered: false,
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.rocket_launch_rounded,
                            color: DesignTokens.textOnPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'product.publish_product'.tr(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DesignTokens.textOnPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit(AddProductState state, AddProductViewModel viewModel) {
    if (!state.hasAttemptedSubmit) {
      viewModel.setHasAttemptedSubmit(true);
    }
    if (state.discountTierError) return;
    viewModel.clearError();
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('addproduct_error_snackbar'),
          content: Text('product.fix_errors_before_submit'.tr()),
          backgroundColor: DesignTokens.error,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final taxCode = _taxCodeController.text.trim();
    final normalizedTaxCode = taxCode.isEmpty ? null : taxCode;

    SupplierInfo? supplierInfo;
    final hasCost = _costController.text.trim().isNotEmpty;
    final hasSku = _supplierSkuController.text.trim().isNotEmpty;
    final hasUrl = _supplierUrlController.text.trim().isNotEmpty;

    if (hasCost || hasSku || hasUrl) {
      supplierInfo = SupplierInfo(
        type: state.selectedSupplierType,
        costCents: parseMoneyToCents(_costController.text),
        currency: state.selectedSupplierCurrency,
        supplierSku: hasSku ? _supplierSkuController.text.trim() : null,
        supplierUrl: hasUrl ? _supplierUrlController.text.trim() : null,
        shippingDays: _supplierShippingDaysController.text.trim().isEmpty
            ? null
            : _supplierShippingDaysController.text.trim(),
        hasTracking: state.hasTracking,
        notes: _supplierNotesController.text.trim().isEmpty
            ? null
            : _supplierNotesController.text.trim(),
      );
    }

    final inventoryConfig = InventoryConfig(
      managed: state.inventoryManaged,
      trackQuantity: state.trackQuantity,
      allowBackorder: state.allowBackorder,
      lowStockThreshold: state.lowStockAlertEnabled
          ? (int.tryParse(_lowStockThresholdController.text) ?? 5)
          : 0,
    );

    viewModel.addProduct(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      nameF: _nameFController.text.trim().isEmpty
          ? null
          : _nameFController.text.trim(),
      descriptionF: _descriptionFController.text.trim().isEmpty
          ? null
          : _descriptionFController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
      compareAtPrice: _compareAtPriceController.text.trim().isEmpty
          ? null
          : double.tryParse(_compareAtPriceController.text.trim()),
      stock: state.selectedWarehouseIds.isEmpty
          ? (int.tryParse(_stockController.text.trim()) ?? 0)
          : 0,
      categoryId: int.tryParse(_categoryController.text.trim()) ?? 0,
      subcategory: state.selectedSubcategory,
      street: _streetController.text.trim(),
      apartment: _apartmentController.text.trim(),
      city: _cityController.text.trim(),
      postalCode: _postalCodeController.text.trim(),
      weight: double.tryParse(_weightController.text),
      length: double.tryParse(_lengthController.text),
      width: double.tryParse(_widthController.text),
      height: double.tryParse(_heightController.text),
      taxCode: normalizedTaxCode,
      deliveryOptions: buildDeliveryOptions(state),
      minimumOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
      freeShipping: state.freeShipping,
      costCents: parseMoneyToCents(_costController.text),
      supplierSku: _supplierSkuController.text.trim().isEmpty
          ? null
          : _supplierSkuController.text.trim(),
      supplierUrl: _supplierUrlController.text.trim().isEmpty
          ? null
          : _supplierUrlController.text.trim(),
      supplier: supplierInfo,
      inventory: inventoryConfig,
      // PROD-C2: inform viewmodel whether seller has warehouses registered
      sellerHasWarehouses:
          ref.read(sellerWarehousesStreamProvider).valueOrNull?.isNotEmpty ==
          true,
    );
  }

  Widget buildVariantBuilderSection(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return buildCollapsibleSection(
      key: const Key('addproduct_section_variants'),
      index: 5,
      icon: Icons.style_rounded,
      title: 'product.variant_builder'.tr(),
      subtitle: 'product.variant_builder_desc'.tr(),
      children: [
        buildGlassToggle(
          key: const Key('addproduct_has_variants_toggle'),
          label: 'product.has_variants'.tr(),
          subtitle: 'product.has_variants_desc'.tr(),
          icon: Icons.tune_rounded,
          value: state.hasVariants,
          onChanged: viewModel.toggleHasVariants,
          semanticsLabel: 'toggle-has-variants',
        ),
        if (state.hasVariants) ...[
          const SizedBox(height: 16),
          ...List.generate(state.variantOptions.length, (i) {
            final opt = state.variantOptions[i];
            return _VariantOptionCard(
              key: Key('variant_option_$i'),
              name: opt.name,
              values: opt.values,
              onRemove: () => viewModel.removeVariantOption(i),
              onUpdate: (newName, newValues) =>
                  viewModel.updateVariantOption(i, newName, newValues),
            );
          }),
          const SizedBox(height: 8),
          if (state.variantOptions.length < 3)
            _AddVariantOptionButton(
              existingNames: state.variantOptions.map((o) => o.name).toList(),
              onAdd: viewModel.addVariantOption,
            ),
          if (state.variants.isNotEmpty) ...[
            const SizedBox(height: 20),
            buildSubSectionHeader(
              'product.variant_combinations'.tr(
                namedArgs: {'count': state.variants.length.toString()},
              ),
              Icons.grid_view_rounded,
            ),
            const SizedBox(height: 8),
            buildInfoBanner(
              'product.variant_combinations_info'.tr(),
              Icons.info_outline_rounded,
              DesignTokens.info,
            ),
            const SizedBox(height: 8),
            ...List.generate(state.variants.length, (i) {
              final variant = state.variants[i];
              return _VariantRow(
                key: Key('variant_row_$i'),
                optionValues: variant.optionValues,
                price: variant.priceDollars,
                stockQuantity: variant.stockQuantity,
                sku: variant.sku,
                onPriceChanged: (v) => viewModel.updateVariantPrice(i, v),
                onStockChanged: (v) => viewModel.updateVariantStock(i, v),
                onSkuChanged: (v) => viewModel.updateVariantSku(i, v),
              );
            }),
          ],
        ],
      ],
    );
  }
}
