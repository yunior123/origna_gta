part of '../addproduct_screen.dart';

// ============================================================================
// FORM CONTENT — Main form layout orchestration
// ============================================================================

extension _AddProductFormContentSection on _AddProductScreenState {
  Widget _buildFormContent(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SECTION 1: Basic Info
        buildSectionCard(
          key: const Key('addproduct_section_basic'),
          index: 0,
          icon: Icons.shopping_bag_rounded,
          title: 'product.product_details'.tr(),
          subtitle: 'product.name_desc_pricing'.tr(),
          state: state,
          viewModel: viewModel,
          children: [
            buildGlassTextField(
              key: const Key('product_name_field'),
              controller: _nameController,
              label: 'product.product_name'.tr(),
              icon: Icons.sell_rounded,
              hint: 'product.enter_product_name'.tr(),
              validator: (v) =>
                  v?.isEmpty ?? true ? 'common.required'.tr() : null,
              semanticsLabel: 'input-name',
            ),
            const SizedBox(height: 16),
            buildGlassTextField(
              key: const Key('product_description_field'),
              controller: _descriptionController,
              label: 'product.description'.tr(),
              icon: Icons.notes_rounded,
              hint: 'product.describe_product'.tr(),
              maxLines: 3,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'common.required'.tr() : null,
              semanticsLabel: 'input-description',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: buildGlassTextField(
                    key: const Key('product_price_field'),
                    controller: _priceController,
                    label: 'product.price_cad'.tr(),
                    icon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    prefixText: '\$ ',
                    suffixText: 'CAD',
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'common.required'.tr() : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildGlassTextField(
                    key: const Key('product_stock_field'),
                    controller: _stockController,
                    label: 'product.stock'.tr(),
                    icon: Icons.inventory_2_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'common.required'.tr() : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            buildGlassTextField(
              key: const Key('product_compare_at_price_field'),
              controller: _compareAtPriceController,
              label: 'product.compare_at_price'.tr(),
              icon: Icons.local_offer_rounded,
              hint: 'product.compare_at_price_hint'.tr(),
              keyboardType: TextInputType.number,
              prefixText: '\$ ',
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final cap = double.tryParse(v);
                if (cap == null) return 'product.invalid_price'.tr();
                final currentPrice =
                    double.tryParse(_priceController.text.trim()) ?? 0;
                if (cap - currentPrice < 0.50) {
                  return 'product.compare_at_price_must_be_higher'.tr();
                }
                return null;
              },
              semanticsLabel: 'input-compare-at-price',
            ),
            buildTappableInfoHint(
              'product.compare_at_price_learn_more'.tr(),
              'product.compare_at_price'.tr(),
              'product.compare_at_price_info_body'.tr(),
            ),
            const SizedBox(height: 16),
            buildGlassTextField(
              controller: _minOrderController,
              label: 'product.min_order_qty'.tr(),
              icon: Icons.format_list_numbered_rounded,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'common.required'.tr() : null,
              onChanged: (v) =>
                  viewModel.setMinimumOrderQuantity(int.tryParse(v) ?? 1),
              semanticsLabel: 'input-min-order',
            ),
            if (!state.isDigital) ...[
              const SizedBox(height: 12),
              buildGlassToggle(
                key: const Key('addproduct_free_shipping_toggle'),
                label: 'product.free_shipping'.tr(),
                icon: Icons.local_shipping_rounded,
                value: state.freeShipping,
                onChanged: viewModel.toggleFreeShipping,
                infoTitle: 'product.free_shipping'.tr(),
                infoBody: 'product.free_shipping_info_body'.tr(),
              ),
            ],
            const SizedBox(height: 16),
            buildCategorySelector(viewModel, state),
            const SizedBox(height: 12),
            buildSubcategorySelector(state, viewModel),
            const SizedBox(height: 12),
            buildGlassTextField(
              controller: _taxCodeController,
              label: 'product.tax_code_label'.tr(),
              icon: Icons.receipt_long_rounded,
              hint: 'product.tax_code_hint'.tr(),
              validator: (v) =>
                  isValidTaxCode(v) ? null : 'product.invalid_tax_code'.tr(),
              semanticsLabel: 'input-tax-code',
            ),
            buildTappableInfoHint(
              'product.tax_code_learn_more'.tr(),
              'product.stripe_tax_codes'.tr(),
              'product.stripe_tax_codes_body'.tr(),
            ),
            const SizedBox(height: 16),
            buildGlassTextField(
              key: const Key('addproduct_seller_sku_field'),
              controller: _sellerSkuController,
              label: 'product.sku_optional'.tr(),
              icon: Icons.qr_code_rounded,
              hint: 'product.sku_hint'.tr(),
              errorText: state.skuError,
              onChanged: (v) {
                if (state.skuError != null) viewModel.clearSkuError();
                viewModel.setSellerSku(v);
              },
              semanticsLabel: 'input-seller-sku',
            ),
            buildTappableInfoHint(
              'product.sku_what_is'.tr(),
              'product.sku'.tr(),
              'product.sku_info_body'.tr(),
            ),
            if (!state.isDigital) ...[
              const SizedBox(height: 16),
              buildConditionSelector(state, viewModel),
            ],
          ],
        ),
        const SizedBox(height: 16),

        buildFrenchTranslationSection(),
        const SizedBox(height: 16),

        buildVariantBuilderSection(state, viewModel),
        if (state.hasVariants) const SizedBox(height: 16),

        // SECTION 2: Media
        buildSectionCard(
          key: const Key('addproduct_section_media'),
          index: 1,
          icon: Icons.perm_media_rounded,
          title: 'product.product_media'.tr(),
          subtitle: 'product.photos_and_video'.tr(),
          state: state,
          viewModel: viewModel,
          children: [
            ProductAddImages(
              imageModels: state.imageModels,
              onImagesChanged: viewModel.updateImages,
            ),
            const SizedBox(height: 24),
            ProductAddVideo(
              videoFile: state.videoFile,
              onVideoAdded: viewModel.setVideo,
              onVideoRemoved: viewModel.removeVideo,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // SECTION 3: Delivery & Shipping
        buildSectionCard(
          key: const Key('addproduct_section_delivery'),
          index: 2,
          icon: Icons.local_shipping_rounded,
          title: 'product.delivery_shipping'.tr(),
          subtitle: 'product.shipping_options'.tr(),
          state: state,
          viewModel: viewModel,
          children: _buildDeliveryChildren(state, viewModel),
        ),
        const SizedBox(height: 16),

        // SECTION 4: Package & Location (physical only)
        if (!state.isDigital)
          buildSectionCard(
            key: const Key('addproduct_section_package'),
            index: 3,
            icon: Icons.location_on_rounded,
            title: 'product.package_location'.tr(),
            subtitle: 'product.dimensions_pickup'.tr(),
            state: state,
            viewModel: viewModel,
            children: _buildPackageChildren(state, viewModel),
          ),
        if (!state.isDigital) const SizedBox(height: 16),

        // SECTION 5: Food Information (conditional: Groceries or perishable)
        if (state.selectedCategoryId == '19' || state.isPerishable)
          buildFoodInfoSection(state, viewModel),
        if (state.selectedCategoryId == '19' || state.isPerishable)
          const SizedBox(height: 16),

        // SECTION 5.5: Product Specifications (all non-food categories)
        if (state.selectedCategoryId != null &&
            state.selectedCategoryId != '19' &&
            !state.isPerishable)
          buildSpecsSection(state, viewModel),
        if (state.selectedCategoryId != null &&
            state.selectedCategoryId != '19' &&
            !state.isPerishable)
          const SizedBox(height: 16),

        const SizedBox(height: 28),

        buildSubmitButton(state, viewModel),
        const SizedBox(height: 20),
      ],
    );
  }
}
