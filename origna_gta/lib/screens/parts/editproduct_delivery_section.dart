part of '../editproduct_screen.dart';

// ============================================================================
// DELIVERY SECTION — Delivery options, digital product editing
// ============================================================================

extension _EditProductDeliverySection on _EditProductScreenState {
  Widget _buildDeliveryOptions(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: isDark ? DesignTokens.darkCard : DesignTokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildDeliveryTile(
              'product.standard_delivery'.tr(),
              state.standardEnabled,
              (v) => viewModel.setStandardEnabled(v),
              _standardDaysController,
              _standardPriceController,
              'product.days_label'.tr(),
            ),
            _buildDeliveryTile(
              'product.express_delivery'.tr(),
              state.expressEnabled,
              (v) => viewModel.setExpressEnabled(v),
              _expressDaysController,
              _expressPriceController,
              'product.days_label'.tr(),
            ),
            _buildDeliveryTile(
              'product.same_day_delivery'.tr(),
              state.sameDayEnabled,
              (v) => viewModel.setSameDayEnabled(v),
              null,
              _sameDayPriceController,
              'product.price_dollar'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTile(
    String title,
    bool enabled,
    Function(bool) onToggle,
    TextEditingController? daysController,
    TextEditingController priceController,
    String unitLabel, {
    TextEditingController? extraController,
  }) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          value: enabled,
          onChanged: onToggle,
          activeThumbColor: DesignTokens.primary,
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (daysController != null)
                  Expanded(
                    child: Semantics(
                      label: 'input-edit-product-delivery-days',
                      child: TextFormField(
                        controller: daysController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: unitLabel,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                if (extraController != null)
                  Expanded(
                    child: Semantics(
                      label: 'input-edit-product-delivery-extra',
                      child: TextFormField(
                        controller: extraController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: unitLabel,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    label: 'input-edit-product-delivery-price',
                    child: TextFormField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'product.price_dollar'.tr(),
                        isDense: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEditDigitalSection(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    return Column(
      key: const Key('editproduct_digital_section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _EditDigitalTypeChip(
                key: const Key('editproduct_digital_type_software'),
                label: 'product.digital_type_software'.tr(),
                icon: Icons.computer_outlined,
                selected: state.digitalType == DigitalTypeValues.software,
                onTap: () =>
                    viewModel.setDigitalType(DigitalTypeValues.software),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _EditDigitalTypeChip(
                key: const Key('editproduct_digital_type_book'),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? DesignTokens.white
                  : DesignTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          _editUrlField(
            key: const Key('editproduct_macos_url'),
            label: 'product.mac_os_label'.tr(),
            controller: _macosUrlController,
            onChanged: (v) =>
                viewModel.setMacosDownloadUrl(v.isEmpty ? null : v),
          ),
          _editUrlField(
            key: const Key('editproduct_windows_url'),
            label: 'product.windows_label'.tr(),
            controller: _windowsUrlController,
            onChanged: (v) =>
                viewModel.setWindowsDownloadUrl(v.isEmpty ? null : v),
          ),
          _editUrlField(
            key: const Key('editproduct_linux_url'),
            label: 'product.linux_label'.tr(),
            controller: _linuxUrlController,
            onChanged: (v) =>
                viewModel.setLinuxDownloadUrl(v.isEmpty ? null : v),
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'input-edit-product-device-limit',
            child: TextFormField(
              key: const Key('editproduct_device_limit'),
              controller: _deviceLimitController,
              decoration: InputDecoration(
                labelText: 'product.device_limit_label'.tr(),
                hintText: 'product.device_limit_hint'.tr(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => viewModel.setDeviceLimit(int.tryParse(v)),
            ),
          ),
        ],
        if (state.digitalType == DigitalTypeValues.book) ...[
          const SizedBox(height: 16),
          Text(
            'product.reenter_download_url_update'.tr(),
            style: const TextStyle(fontSize: 12, color: DesignTokens.warning),
          ),
          const SizedBox(height: 6),
          _editUrlField(
            key: const Key('editproduct_book_url'),
            label: 'product.book_download_url'.tr(),
            controller: _bookUrlController,
            onChanged: (v) => viewModel.setBookSourceUrl(v.isEmpty ? null : v),
          ),
        ],
      ],
    );
  }
}
