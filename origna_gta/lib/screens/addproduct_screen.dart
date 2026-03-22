import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/config/supplier_config.dart';
import 'package:origna_gta/core/routes.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/screens/productaddvideo_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import 'package:origna_gta/features/products/add_product_state.dart';
import 'package:origna_gta/features/products/add_product_viewmodel.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';

part 'parts/product_form_helper_widgets.dart';
part 'parts/addproduct_form_widgets.dart';
part 'parts/addproduct_basic_info_section.dart';
part 'parts/addproduct_delivery_section.dart';
part 'parts/addproduct_package_location_section.dart';
part 'parts/addproduct_supplier_section.dart';
part 'parts/addproduct_submit_section.dart';

/// Documentation for AddProductScreen
class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _compareAtPriceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _minOrderController = TextEditingController(text: '1');
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _taxCodeController = TextEditingController();

  // Bill 96: French translation controllers
  final _nameFController = TextEditingController();
  final _descriptionFController = TextEditingController();

  // Supplier Info Controllers
  final _costController = TextEditingController();
  final _supplierSkuController = TextEditingController();
  final _sellerSkuController = TextEditingController();
  final _supplierUrlController = TextEditingController();
  final _supplierShippingDaysController = TextEditingController(text: '7-15');
  final _supplierNotesController = TextEditingController();
  final _customSupplierNameController = TextEditingController();

  // Inventory Config
  final _lowStockThresholdController = TextEditingController(text: '5');

  final _standardDaysController = TextEditingController(text: '5');
  final _standardPriceController = TextEditingController(text: '0.00');
  final _expressDaysController = TextEditingController(text: '2');
  final _expressPriceController = TextEditingController(text: '9.99');
  final _sameDayPriceController = TextEditingController(text: '14.99');

  // Quantity-based shipping discount controllers
  final _shippingDiscount3Controller = TextEditingController();
  final _shippingDiscount5Controller = TextEditingController();
  final _additionalItemCostController = TextEditingController(text: '0.00');
  final _maxItemsPerShipmentController = TextEditingController(text: '0');

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  ProviderSubscription<AddProductState>? _addProductSubscription;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductViewModelProvider);
    final viewModel = ref.read(addProductViewModelProvider.notifier);

    final maxWidth = ResponsiveBreakpoints.getValue<double>(
      context: context,
      mobile: double.infinity,
      mobilePlus: 540,
      tablet: 640,
      desktop: 720,
    );

    return Scaffold(
      backgroundColor: DesignTokens.surface,
      body: Stack(
        children: [
          // Gradient header background
          _buildGradientHeader(),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(state),
                // Scrollable form
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Form(
                            key: _formKey,
                            autovalidateMode: state.hasAttemptedSubmit
                                ? AutovalidateMode.onUserInteraction
                                : AutovalidateMode.disabled,
                            child: _buildFormContent(state, viewModel),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

        // SECTION 5: Supplier & Inventory (collapsible)
        buildCollapsibleSection(
          key: const Key('addproduct_section_supplier'),
          index: 4,
          icon: Icons.business_center_rounded,
          title: 'product.supplier_inventory'.tr(),
          subtitle: 'product.cost_margins_stock'.tr(),
          children: _buildSupplierChildren(state, viewModel),
        ),
        const SizedBox(height: 28),

        buildSubmitButton(state, viewModel),
        const SizedBox(height: 20),
      ],
    );
  }

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
      ),
      const SizedBox(height: 12),
      buildGlassTextField(
        controller: _supplierUrlController,
        label: 'product.supplier_url'.tr(),
        icon: Icons.link_rounded,
        keyboardType: TextInputType.url,
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
          ),
        ],
      ],
    ];
  }

  @override
  void dispose() {
    _addProductSubscription?.close();
    _fadeController.dispose();
    _nameController.dispose();
    _nameFController.dispose();
    _descriptionController.dispose();
    _descriptionFController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _streetController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _stockController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _compareAtPriceController.dispose();
    _taxCodeController.dispose();
    _minOrderController.dispose();
    _standardDaysController.dispose();
    _standardPriceController.dispose();
    _expressDaysController.dispose();
    _expressPriceController.dispose();
    _sameDayPriceController.dispose();
    _costController.dispose();
    _supplierSkuController.dispose();
    _sellerSkuController.dispose();
    _supplierUrlController.dispose();
    _supplierShippingDaysController.dispose();
    _supplierNotesController.dispose();
    _customSupplierNameController.dispose();
    _lowStockThresholdController.dispose();
    _shippingDiscount3Controller.dispose();
    _shippingDiscount5Controller.dispose();
    _additionalItemCostController.dispose();
    _maxItemsPerShipmentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _addProductSubscription = ref.listenManual(addProductViewModelProvider, (
      previous,
      next,
    ) {
      if (!mounted || previous?.isSuccess == true) return;
      if (next.isSuccess) {
        _onSuccess();
      } else if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            key: const Key('addproduct_error_snackbar'),
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
    _shippingDiscount3Controller.addListener(_validateDiscountTiers);
    _shippingDiscount5Controller.addListener(_validateDiscountTiers);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // PROD-C1: reset text controllers when re-entering the screen after a previous success.
      final currentState = ref.read(addProductViewModelProvider);
      if (currentState.isSuccess) {
        _resetControllers();
      }
      ref.read(addProductViewModelProvider.notifier).resetIfSuccess();
    });
  }

  Widget _buildGradientHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 200,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.gradientStart,
              DesignTokens.gradientMiddle,
              DesignTokens.gradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              top: 40,
              left: -40,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AddProductState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            key: const Key('addproduct_back_button'),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'product.go_back'.tr(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: DesignTokens.textOnPrimary,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Text(
              key: const Key('addproduct_screen_title'),
              'product.new_product'.tr(),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: DesignTokens.textOnPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                final isActive = i <= state.activeStep;
                return Container(
                  width: isActive ? 18 : 8,
                  height: 8,
                  margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? DesignTokens.textOnPrimary
                        : Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  void _onSuccess() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('addproduct_success_snackbar'),
        content: Row(
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              color: DesignTokens.textOnPrimary,
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'product.under_review_title'.tr(),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'product.under_review_subtitle'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.textOnPrimary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor:
            DesignTokens.warning, // FIX [LOW] Was hardcoded Color(0xFFF59E0B)
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
      ),
    );
    Navigator.pop(context);
  }

  /// PROD-C1: Clears all text controllers so the form is blank when re-entering after a successful submit.
  void _resetControllers() {
    _nameController.clear();
    _nameFController.clear();
    _descriptionController.clear();
    _descriptionFController.clear();
    _priceController.clear();
    _compareAtPriceController.clear();
    _categoryController.clear();
    _streetController.clear();
    _apartmentController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _stockController.text = '1';
    _minOrderController.text = '1';
    _weightController.clear();
    _lengthController.clear();
    _widthController.clear();
    _heightController.clear();
    _taxCodeController.clear();
    _costController.clear();
    _supplierSkuController.clear();
    _sellerSkuController.clear();
    _supplierUrlController.clear();
    _supplierShippingDaysController.text = '7-15';
    _supplierNotesController.clear();
    _customSupplierNameController.clear();
    _lowStockThresholdController.text = '5';
    _standardDaysController.text = '5';
    _standardPriceController.text = '0.00';
    _expressDaysController.text = '2';
    _expressPriceController.text = '9.99';
    _sameDayPriceController.text = '14.99';
    _shippingDiscount3Controller.clear();
    _shippingDiscount5Controller.clear();
    _additionalItemCostController.text = '0.00';
    _maxItemsPerShipmentController.text = '0';
  }

  String? _validateCity(String? v) {
    if (v == null || v.trim().isEmpty) return 'common.required'.tr();
    if (v.trim().length < 2) return 'product.city_too_short'.tr();
    if (v.trim().length > 50) return 'product.city_too_long'.tr();
    return null;
  }

  void _validateDiscountTiers() {
    final d3 = double.tryParse(_shippingDiscount3Controller.text);
    final d5 = double.tryParse(_shippingDiscount5Controller.text);
    final hasError = d3 != null && d5 != null && d5 < d3;
    final state = ref.read(addProductViewModelProvider);
    if (hasError != state.discountTierError) {
      ref
          .read(addProductViewModelProvider.notifier)
          .setDiscountTierError(hasError);
    }
  }

  String? _validatePostalCode(String? v) {
    if (v == null || v.isEmpty) return 'common.required'.tr();
    final normalized = v.toUpperCase().replaceAll(' ', '').trim();
    final reg = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');
    if (!reg.hasMatch(normalized)) return 'product.invalid_postal'.tr();
    return null;
  }

  String? _validateStreet(String? v) {
    if (v == null || v.trim().isEmpty) return 'common.required'.tr();
    if (v.trim().length < 3) return 'product.street_too_short'.tr();
    if (v.trim().length > 100) return 'product.street_too_long'.tr();
    return null;
  }
}
