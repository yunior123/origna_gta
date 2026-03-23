part of '../editproduct_screen.dart';

extension _EditProductShipping on _EditProductScreenState {
  Widget buildShippingSection(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('product.shipping_delivery'.tr()),
        SwitchListTile(
          title: Text('product.local_delivery_only'.tr()),
          subtitle: Text('product.restrict_50km'.tr()),
          value: state.isLocalDeliveryOnly,
          activeTrackColor: DesignTokens.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: viewModel.toggleLocalDelivery,
        ),
        SwitchListTile(
          title: Text('product.perishable_item'.tr()),
          subtitle: Text('product.perishable_subtitle'.tr()),
          value: state.isPerishable,
          activeTrackColor: DesignTokens.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: viewModel.togglePerishable,
        ),
        SwitchListTile(
          key: const Key('editproduct_age_restricted_toggle'),
          title: Text('product.age_restricted_item'.tr()),
          value: state.isAgeRestricted,
          activeTrackColor: DesignTokens.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: viewModel.toggleAgeRestricted,
        ),
        if (!state.isLocalDeliveryOnly) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'product.weight'.tr(),
                    prefixIcon: const Icon(Icons.scale_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _shipDaysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'product.ship_days'.tr(),
                    prefixIcon: const Icon(Icons.schedule_outlined),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lengthController,
                  decoration: InputDecoration(
                    labelText: 'product.length_cm'.tr(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _widthController,
                  decoration: InputDecoration(
                    labelText: 'product.width_cm'.tr(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _heightController,
                  decoration: InputDecoration(
                    labelText: 'product.height_cm'.tr(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _minOrderController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'product.min_order_qty'.tr(),
                    prefixIcon: const Icon(Icons.format_list_numbered),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'common.required'.tr() : null,
                  onChanged: (v) =>
                      viewModel.setMinimumOrderQuantity(int.tryParse(v) ?? 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('product.free_shipping'.tr()),
                  value: state.freeShipping,
                  activeTrackColor: DesignTokens.primary,
                  onChanged: viewModel.toggleFreeShipping,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        _buildDeliveryOptions(state, viewModel),
        const SizedBox(height: 24),
      ],
    );
  }
}
