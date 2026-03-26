part of '../addproduct_screen.dart';

// ============================================================================
// SUPPLIER CHILDREN — Supplier info + inventory settings builders
// ============================================================================

extension _AddProductSupplierChildrenSection on _AddProductScreenState {
  List<Widget> _buildSupplierChildren(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return [
      buildSubSectionHeader(
        'product.supplier_info'.tr(),
        Icons.storefront_rounded,
      ),
      const SizedBox(height: 12),
      buildGlassDropdown(
        label: 'product.supplier_platform'.tr(),
        value: state.selectedSupplierType,
        items: getSupplierDropdownItems(),
        onChanged: (v) {
          final type = v ?? SupplierTypeValues.other;
          viewModel.setSupplierType(type);
          final config = getSupplierConfig(type);
          if (!config.supportedCurrencies.contains(
            state.selectedSupplierCurrency,
          )) {
            viewModel.setSupplierCurrency(config.defaultCurrency);
          }
          final range = getSupplierDeliveryRange(type);
          _standardDaysController.text = range.minDays.toString();
          _expressDaysController.text = (range.minDays ~/ 2)
              .clamp(1, range.minDays)
              .toString();
        },
      ),
      if (state.selectedSupplierType.isNotEmpty)
        buildSupplierInfoBadge(state.selectedSupplierType),
      if (getSupplierConfig(state.selectedSupplierType).isCustom) ...[
        const SizedBox(height: 12),
        buildGlassTextField(
          controller: _customSupplierNameController,
          label: 'product.custom_supplier_name'.tr(),
          icon: Icons.edit_rounded,
        semanticsLabel: 'input-custom-supplier-name',
        ),
      ],
      const SizedBox(height: 12),
      buildInfoBanner(
        'product.supplier_cost_banner'.tr(),
        Icons.info_outline_rounded,
        DesignTokens.info,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            flex: 2,
            child: buildGlassTextField(
              controller: _costController,
              label: 'product.supplier_cost'.tr(),
              icon: Icons.payments_rounded,
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: buildGlassDropdown(
              label: 'product.currency_label'.tr(),
              value: state.selectedSupplierCurrency,
              items: getSupplierConfig(state.selectedSupplierType)
                  .supportedCurrencies
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => viewModel.setSupplierCurrency(
                v ?? SupplierCurrencyValues.usd,
              ),
            ),
          ),
        ],
      ),
      if (_costController.text.isNotEmpty && _priceController.text.isNotEmpty)
        buildMarginPreview(state),
      const SizedBox(height: 12),
      buildGlassTextField(
        controller: _supplierSkuController,
        label: 'product.supplier_sku'.tr(),
        icon: Icons.qr_code_2_rounded,
      semanticsLabel: 'input-supplier-sku',
      ),
      const SizedBox(height: 12),
      buildGlassTextField(
        controller: _supplierUrlController,
        label: 'product.supplier_url'.tr(),
        icon: Icons.link_rounded,
        keyboardType: TextInputType.url,
      semanticsLabel: 'input-supplier-url',
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: buildGlassTextField(
              controller: _supplierShippingDaysController,
              label: 'product.ship_days'.tr(),
              icon: Icons.schedule_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: buildGlassToggle(
              label: 'product.has_tracking'.tr(),
              icon: Icons.gps_fixed_rounded,
              value: state.hasTracking,
              onChanged: viewModel.setHasTracking,
              infoTitle: 'product.supplier_tracking_title'.tr(),
              infoBody: 'product.supplier_tracking_body'.tr(),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      buildGlassTextField(
        controller: _supplierNotesController,
        label: 'product.internal_notes'.tr(),
        icon: Icons.sticky_note_2_rounded,
        maxLines: 2,
      semanticsLabel: 'input-supplier-notes',
      ),
      const SizedBox(height: 24),
      buildSubSectionHeader(
        'product.inventory_settings'.tr(),
        Icons.warehouse_rounded,
      ),
      const SizedBox(height: 12),
      buildGlassToggle(
        key: const Key('addproduct_inventory_toggle'),
        label: 'product.manage_inventory'.tr(),
        subtitle: 'product.manage_inventory_subtitle'.tr(),
        icon: Icons.inventory_rounded,
        value: state.inventoryManaged,
        onChanged: viewModel.setInventoryManaged,
        infoTitle: 'product.inventory_management_title'.tr(),
        infoBody: 'product.inventory_management_body'.tr(),
      ),
      if (state.inventoryManaged) ...[
        const SizedBox(height: 8),
        buildGlassToggle(
          label: 'product.stock_quantity'.tr(),
          subtitle: 'product.track_quantity_subtitle'.tr(),
          icon: Icons.numbers_rounded,
          value: state.trackQuantity,
          onChanged: viewModel.setTrackQuantity,
          infoTitle: 'product.stock_quantity'.tr(),
          infoBody: 'product.track_quantity_info_body'.tr(),
        ),
        const SizedBox(height: 8),
        buildGlassToggle(
          label: 'product.allow_backorders'.tr(),
          subtitle: 'product.allow_backorders_subtitle'.tr(),
          icon: Icons.replay_rounded,
          value: state.allowBackorder,
          onChanged: viewModel.setAllowBackorder,
          infoTitle: 'product.allow_backorders'.tr(),
          infoBody: 'product.allow_backorders_info_body'.tr(),
        ),
        const SizedBox(height: 8),
        buildGlassToggle(
          key: const Key('addproduct_low_stock_alert_toggle'),
          label: 'product.low_stock_alert'.tr(),
          subtitle: 'product.low_stock_alert_subtitle'.tr(),
          icon: Icons.notifications_active_rounded,
          value: state.lowStockAlertEnabled,
          onChanged: viewModel.setLowStockAlertEnabled,
        ),
        if (state.lowStockAlertEnabled) ...[
          const SizedBox(height: 8),
          buildGlassTextField(
            controller: _lowStockThresholdController,
            label: 'product.low_stock_threshold'.tr(),
            icon: Icons.warning_amber_rounded,
            keyboardType: TextInputType.number,
          semanticsLabel: 'input-low-stock-threshold',
          ),
        ],
      ],
    ];
  }
}
