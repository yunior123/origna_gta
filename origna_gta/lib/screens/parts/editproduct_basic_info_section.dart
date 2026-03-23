part of '../editproduct_screen.dart';

extension _EditProductBasicInfo on _EditProductScreenState {
  Widget buildBasicInfoSection(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildApprovalStatusBanner(),
        _buildSectionTitle('product.basic_information'.tr()),
        TextFormField(
          key: const Key('product_edit_name_field'),
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'product.product_name'.tr(),
            prefixIcon: const Icon(Icons.shopping_bag_outlined),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'product.please_enter_name'.tr() : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('product_edit_description_field'),
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'product.description'.tr(),
            prefixIcon: const Icon(Icons.description_outlined),
          ),
          validator: (value) => value?.isEmpty ?? true
              ? 'product.please_enter_description'.tr()
              : null,
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('product.french_section_title'.tr()),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.canadaRed.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: DesignTokens.canadaRed.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: DesignTokens.canadaRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'product.french_section_subtitle'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: DesignTokens.canadaRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('product_edit_name_f_field'),
          controller: _nameFController,
          decoration: InputDecoration(
            labelText: 'product.name_french'.tr(),
            hintText: 'product.name_french_hint'.tr(),
            prefixIcon: const Icon(Icons.sell_rounded),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('product_edit_description_f_field'),
          controller: _descriptionFController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'product.description_french'.tr(),
            hintText: 'product.description_french_hint'.tr(),
            prefixIcon: const Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: const Key('product_edit_price_field'),
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'product.price'.tr(),
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                ),
                validator: (value) => value?.isEmpty ?? true
                    ? 'product.please_enter_price'.tr()
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                key: const Key('product_edit_stock_field'),
                controller: _stockController,
                keyboardType: TextInputType.number,
                enabled: !state.isSoldOut,
                decoration: InputDecoration(
                  labelText: 'product.stock'.tr(),
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                  suffixText: state.isSoldOut ? 'product.sold_out'.tr() : null,
                ),
                validator: (value) =>
                    !state.isSoldOut && (value == null || value.isEmpty)
                    ? 'product.enter_quantity'.tr()
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('product_edit_compare_at_price_field'),
          controller: _compareAtPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'product.compare_at_price'.tr(),
            prefixIcon: const Icon(Icons.local_offer_outlined),
            hintText: 'product.compare_at_price_hint'.tr(),
            helperText: 'product.compare_at_price_info_body'.tr(),
            helperMaxLines: 3,
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return null; // optional
            final cap = double.tryParse(v);
            if (cap == null) return 'product.invalid_price'.tr();
            final currentPrice =
                double.tryParse(_priceController.text.trim()) ?? 0;
            if (cap <= currentPrice) {
              return 'product.compare_at_price_must_be_higher'.tr();
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          key: const Key('product_edit_tax_code_field'),
          controller: _taxCodeController,
          decoration: InputDecoration(
            labelText: 'product.tax_code_label'.tr(),
            prefixIcon: const Icon(Icons.receipt_long_rounded),
            hintText: 'product.tax_code_hint'.tr(),
            helperText: 'product.stripe_tax_codes_body'.tr(),
          ),
          validator: (v) => v == null || v.isEmpty || isValidTaxCode(v)
              ? null
              : 'product.invalid_tax_code'.tr(),
        ),
        _buildTappableInfoHint(
          'product.tax_code_learn_more'.tr(),
          'product.stripe_tax_codes'.tr(),
          'product.stripe_tax_codes_body'.tr(),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: Text('product.mark_sold_out'.tr()),
          value: state.isSoldOut,
          activeTrackColor: DesignTokens.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) {
            viewModel.toggleSoldOut(v);
            if (v) _stockController.text = '0';
          },
        ),
        SwitchListTile(
          key: const Key('editproduct_low_stock_alert_toggle'),
          title: Text('product.low_stock_alert'.tr()),
          subtitle: Text('product.low_stock_alert_subtitle'.tr()),
          secondary: const Icon(Icons.notifications_active_rounded),
          value: ref.watch(_editProductLowStockAlertProvider),
          activeTrackColor: DesignTokens.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) =>
              ref.read(_editProductLowStockAlertProvider.notifier).state = v,
        ),
        if (ref.watch(_editProductLowStockAlertProvider)) ...[
          const SizedBox(height: 4),
          TextFormField(
            key: const Key('editproduct_low_stock_threshold_field'),
            controller: _lowStockThresholdController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'product.low_stock_threshold'.tr(),
              prefixIcon: const Icon(Icons.warning_amber_rounded),
            ),
          ),
          const SizedBox(height: 4),
        ],
        SwitchListTile(
          title: Text('product.digital_product'.tr()),
          subtitle: Text('product.digital_subtitle'.tr()),
          value: state.isDigital,
          activeTrackColor: DesignTokens.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: viewModel.toggleDigital,
        ),
        if (state.isDigital) ...[
          const SizedBox(height: 12),
          _buildEditDigitalSection(state, viewModel),
        ],
        DropdownButtonFormField<String>(
          key: const Key('product_edit_category_dropdown'),
          menuMaxHeight: ResponsiveBreakpoints.dropdownMaxHeight(context),
          initialValue: _categoryController.text.isNotEmpty
              ? _categoryController.text
              : null,
          decoration: InputDecoration(
            labelText: 'product.category'.tr(),
            prefixIcon: const Icon(Icons.category_outlined),
          ),
          items: productCategories
              .map(
                (c) => DropdownMenuItem(
                  value: c.categoryId.toString(),
                  child: Text(c.name.tr()),
                ),
              )
              .toList(),
          onChanged: (v) => _categoryController.text = v ?? '',
          validator: (v) => v == null ? 'product.select_category'.tr() : null,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
