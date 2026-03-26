part of '../addproduct_screen.dart';

// ============================================================================
// DELIVERY CHILDREN — Delivery/shipping tier builders + package children
// ============================================================================

extension _AddProductDeliveryChildrenSection on _AddProductScreenState {
  List<Widget> _buildDeliveryChildren(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return [
      buildGlassToggle(
        key: const Key('addproduct_digital_toggle'),
        label: 'product.digital_product_label'.tr(),
        subtitle: 'product.no_shipping_needed'.tr(),
        icon: Icons.cloud_download_rounded,
        value: state.isDigital,
        onChanged: viewModel.toggleDigital,
        infoTitle: 'product.digital_info_title'.tr(),
        infoBody: 'product.digital_info_body'.tr(),
      ),
      if (state.isDigital)
        Padding(
          key: const Key('addproduct_digital_info_banner'),
          padding: const EdgeInsets.only(top: 8),
          child: buildInfoBanner(
            'product.digital_skip_shipping'.tr(),
            Icons.info_outline_rounded,
            DesignTokens.info,
          ),
        ),
      if (state.isDigital)
        buildDigitalProductSection(context, state, viewModel),
      if (!state.isDigital) ...[
        const SizedBox(height: 12),
        buildGlassToggle(
          key: const Key('addproduct_perishable_toggle'),
          label: 'product.perishable_item'.tr(),
          icon: Icons.thermostat_rounded,
          value: state.isPerishable,
          onChanged: viewModel.togglePerishable,
          infoTitle: 'product.perishable_info_title'.tr(),
          infoBody: 'product.perishable_info_body'.tr(),
        ),
        const SizedBox(height: 12),
        buildGlassToggle(
          key: const Key('addproduct_age_restricted_toggle'),
          label: 'product.age_restricted_item'.tr(),
          icon: Icons.no_adult_content_rounded,
          value: state.isAgeRestricted,
          onChanged: viewModel.toggleAgeRestricted,
          infoTitle: 'product.age_restricted_info_title'.tr(),
          infoBody: 'product.age_restricted_info_body'.tr(),
        ),
        const SizedBox(height: 16),
        buildDeliveryTierCard(
          key: const Key('addproduct_standard_delivery_card'),
          title: 'product.standard_delivery'.tr(),
          icon: Icons.local_shipping_outlined,
          isEnabled: state.standardEnabled,
          onChanged: viewModel.setStandardEnabled,
          color: DesignTokens.primary,
          infoTitle: 'product.standard_delivery'.tr(),
          infoBody: 'product.standard_delivery_info_body'.tr(),
          children: [
            Row(
              children: [
                Expanded(
                  child: buildGlassTextField(
                    controller: _standardDaysController,
                    label: 'product.days_label'.tr(),
                    hint: 'product.est_business_days_hint'.tr(),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: buildGlassTextField(
                    controller: _standardPriceController,
                    label: 'product.price_dollar'.tr(),
                    keyboardType: TextInputType.number,
                    hint: 'product.free_hint'.tr(),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (state.freeShipping)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: buildInfoBanner(
              'product.free_shipping_banner'.tr(),
              Icons.local_shipping_rounded,
              DesignTokens.success,
            ),
          ),
        if (!state.freeShipping) ...[
          const SizedBox(height: 10),
          buildDeliveryTierCard(
            key: const Key('addproduct_express_delivery_card'),
            title: 'product.express_delivery'.tr(),
            icon: Icons.bolt_rounded,
            isEnabled: state.expressEnabled,
            onChanged: viewModel.setExpressEnabled,
            color: DesignTokens.warning,
            infoTitle: 'product.express_delivery'.tr(),
            infoBody: 'product.express_delivery_info_body'.tr(),
            children: [
              Row(
                children: [
                  Expanded(
                    child: buildGlassTextField(
                      controller: _expressDaysController,
                      label: 'product.days_label'.tr(),
                      hint: 'product.est_business_days_hint'.tr(),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: buildGlassTextField(
                      controller: _expressPriceController,
                      label: 'product.price_dollar'.tr(),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          buildDeliveryTierCard(
            key: const Key('addproduct_same_day_delivery_card'),
            title: 'product.same_day_delivery'.tr(),
            icon: Icons.rocket_launch_rounded,
            isEnabled: state.sameDayEnabled,
            onChanged: viewModel.setSameDayEnabled,
            color: DesignTokens.success,
            infoTitle: 'product.same_day_delivery'.tr(),
            infoBody: 'product.same_day_delivery_info_body'.tr(),
            children: [
              buildGlassTextField(
                controller: _sameDayPriceController,
                label: 'product.price_dollar'.tr(),
                keyboardType: TextInputType.number,
              semanticsLabel: 'input-same-day-price',
              ),
            ],
          ),
          const SizedBox(height: 16),
          buildQuantityShippingDiscountsSection(viewModel, state),
        ],
      ],
    ];
  }

  List<Widget> _buildPackageChildren(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return [
      buildGlassToggle(
        key: const Key('addproduct_local_pickup_toggle'),
        label: 'product.local_pickup_only'.tr(),
        icon: Icons.store_rounded,
        value: state.isLocalDeliveryOnly,
        onChanged: viewModel.setLocalDeliveryOnly,
        infoTitle: 'product.local_pickup_only'.tr(),
        infoBody: 'product.local_pickup_info_body'.tr(),
      ),
      if (!state.isLocalDeliveryOnly) ...[
        const SizedBox(height: 16),
        buildGlassTextField(
          controller: _weightController,
          key: const Key('addproduct_weight_field'),
          label: 'product.weight'.tr(),
          icon: Icons.scale_rounded,
          keyboardType: TextInputType.number,
        semanticsLabel: 'input-weight',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildGlassTextField(
                controller: _lengthController,
                key: const Key('addproduct_length_field'),
                label: 'product.length_cm'.tr(),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                controller: _widthController,
                key: const Key('addproduct_width_field'),
                label: 'product.width_cm'.tr(),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                controller: _heightController,
                key: const Key('addproduct_height_field'),
                label: 'product.height_cm'.tr(),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        buildTappableInfoHint(
          'product.weight_dimensions_learn_more'.tr(),
          'product.weight_dimensions_info_title'.tr(),
          'product.weight_dimensions_info_body'.tr(),
        ),
      ],
      const SizedBox(height: 20),
      buildWarehouseSelector(context, state, viewModel),
    ];
  }
}
