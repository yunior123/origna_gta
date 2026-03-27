part of '../addproduct_screen.dart';

// ============================================================================
// DELIVERY SECTION — Delivery tiers, digital product, shipping discounts
// ============================================================================

extension _AddProductDeliverySection on _AddProductScreenState {
  Widget buildDeliveryTierCard({
    Key? key,
    required String title,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required Color color,
    required List<Widget> children,
    String? infoTitle,
    String? infoBody,
  }) {
    return AnimatedContainer(
      key: key,
      duration: DesignTokens.durationNormal,
      decoration: BoxDecoration(
        color: isEnabled
            ? color.withValues(alpha: 0.04)
            : DesignTokens.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? color.withValues(alpha: 0.3)
              : DesignTokens.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isEnabled ? color : DesignTokens.textDisabled,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? color : DesignTokens.textSecondary,
                    ),
                  ),
                ),
                if (infoTitle != null && infoBody != null)
                  Semantics(
                    button: true,
                    label: 'btn-add-product-delivery-info',
                    child: GestureDetector(
                      onTap: () => showInfoSheet(infoTitle, infoBody),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: isEnabled
                              ? color.withValues(alpha: 0.5)
                              : DesignTokens.textDisabled,
                        ),
                      ),
                    ),
                  ),
                Switch.adaptive(
                  value: isEnabled,
                  onChanged: onChanged,
                  activeThumbColor: color,
                ),
              ],
            ),
          ),
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  Widget buildDigitalProductSection(
    BuildContext context,
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DigitalTypeCard(
                key: const Key('addproduct_digital_type_software'),
                label: 'product.digital_type_software'.tr(),
                icon: Icons.computer_outlined,
                selected: state.digitalType == DigitalTypeValues.software,
                onTap: () =>
                    viewModel.setDigitalType(DigitalTypeValues.software),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DigitalTypeCard(
                key: const Key('addproduct_digital_type_book'),
                label: 'product.digital_type_book'.tr(),
                icon: Icons.menu_book_outlined,
                selected: state.digitalType == DigitalTypeValues.book,
                onTap: () => viewModel.setDigitalType(DigitalTypeValues.book),
              ),
            ),
          ],
        ),
        if (state.digitalType == DigitalTypeValues.software) ...[
          const SizedBox(height: 16),
          Text(
            'product.download_links'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: 4),
          buildUrlField(
            label: 'product.mac_os_label'.tr(),
            placeholder: 'product.macos_hint'.tr(),
            value: state.macosDownloadUrl,
            onChanged: viewModel.setMacosDownloadUrl,
          ),
          buildUrlField(
            label: 'product.windows_label'.tr(),
            placeholder: 'product.windows_hint'.tr(),
            value: state.windowsDownloadUrl,
            onChanged: viewModel.setWindowsDownloadUrl,
          ),
          buildUrlField(
            label: 'product.linux_label'.tr(),
            placeholder: 'product.linux_hint'.tr(),
            value: state.linuxDownloadUrl,
            onChanged: viewModel.setLinuxDownloadUrl,
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'input-add-product-device-limit',
            textField: true,
            child: TextFormField(
              initialValue: state.deviceLimit?.toString(),
              decoration: InputDecoration(
                labelText: 'product.device_limit_label'.tr(),
                hintText: 'product.device_limit_hint'.tr(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) =>
                  viewModel.setDeviceLimit(int.tryParse(v.trim())),
            ),
          ),
        ],
        if (state.digitalType == DigitalTypeValues.book) ...[
          const SizedBox(height: 16),
          Text(
            'product.book_download_url'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: DesignTokens.textPrimary),
          ),
          const SizedBox(height: 4),
          buildUrlField(
            label: 'product.download_source_url_label'.tr(),
            placeholder: 'product.book_download_hint'.tr(),
            value: state.bookSourceUrl,
            onChanged: viewModel.setBookSourceUrl,
          ),
        ],
      ],
    );
  }

  Widget buildQuantityShippingDiscountsSection(
    AddProductViewModel viewModel,
    AddProductState state,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.success.withValues(alpha: 0.04),
            DesignTokens.primary.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.success.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: DesignTokens.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer_rounded,
                  color: DesignTokens.success,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'product.bulk_shipping_discounts'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: 'btn-add-product-bulk-discount-info',
                child: GestureDetector(
                  onTap: () => showInfoSheet(
                    'product.bulk_shipping_discounts'.tr(),
                    'product.bulk_discount_info_body'.tr(),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: DesignTokens.textDisabled,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'product.encourage_larger_orders'.tr(),
            style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          buildShippingDiscountTier(
            label: 'product.three_plus_items'.tr(),
            controller: _shippingDiscount3Controller,
            hint: '20',
          ),
          const SizedBox(height: 8),
          buildShippingDiscountTier(
            label: 'product.five_plus_items'.tr(),
            controller: _shippingDiscount5Controller,
            hint: '50',
          ),
          if (state.discountTierError) ...[
            const SizedBox(height: 6),
            Text(
              'product.discount_validation'.tr(),
              style: TextStyle(color: DesignTokens.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: buildGlassTextField(
                  controller: _additionalItemCostController,
                  label: 'product.cost_extra_item'.tr(),
                  prefixText: '\$',
                  keyboardType: TextInputType.number,
                  semanticsLabel: 'input-additional-item-cost',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: buildGlassTextField(
                  controller: _maxItemsPerShipmentController,
                  label: 'product.max_per_shipment'.tr(),
                  keyboardType: TextInputType.number,
                  hint: 'product.unlimited_hint'.tr(),
                  semanticsLabel: 'input-max-items-per-shipment',
                ),
              ),
            ],
          ),
          buildTappableInfoHint(
            'product.multi_item_learn_more'.tr(),
            'product.multi_item_shipping_title'.tr(),
            'product.multi_item_shipping_body'.tr(),
          ),
        ],
      ),
    );
  }

  Widget buildShippingDiscountTier({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: DesignTokens.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            label: 'input-add-product-shipping-discount-$label',
            textField: true,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 13),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final val = double.tryParse(v);
                if (val == null || val < 0 || val > 100) {
                  return 'product.discount_range'.tr();
                }
                return null;
              },
              decoration: InputDecoration(
                hintText: hint,
                suffixText: 'product.percent_off'.tr(),
                isDense: true,
                filled: true,
                fillColor: DesignTokens.darkSurfaceVariant.withValues(
                  alpha: 0.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: DesignTokens.outline.withValues(alpha: 0.2),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: DesignTokens.success,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
