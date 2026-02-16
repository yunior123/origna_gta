import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/config/supplier_config.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

import '../../features/products/add_product_state.dart';
import '../../features/products/add_product_viewmodel.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
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

  // Supplier Info Controllers
  final _costController = TextEditingController();
  final _supplierSkuController = TextEditingController();
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

  // State
  String _selectedSupplierType = 'aliexpress';
  String _selectedSupplierCurrency = 'USD';
  bool _hasTracking = false;
  bool _inventoryManaged = true;
  bool _trackQuantity = true;
  bool _allowBackorder = false;

  // Active section for stepper
  int _activeStep = 0;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final Map<String, String> _provinceNames = {
    'AB': 'Alberta',
    'BC': 'British Columbia',
    'MB': 'Manitoba',
    'NB': 'New Brunswick',
    'NL': 'Newfoundland and Labrador',
    'NT': 'Northwest Territories',
    'NS': 'Nova Scotia',
    'NU': 'Nunavut',
    'ON': 'Ontario',
    'PE': 'Prince Edward Island',
    'QC': 'Quebec',
    'SK': 'Saskatchewan',
    'YT': 'Yukon',
  };

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductViewModelProvider);
    final viewModel = ref.read(addProductViewModelProvider.notifier);

    ref.listen(addProductViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        _onSuccess();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: DesignTokens.error));
      }
    });

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
          Positioned(
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
                  // Decorative circles
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
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom top bar
                Padding(
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
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          key: const Key('addproduct_screen_title'),
                          'product.new_product'.tr(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      // Step indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final isActive = i <= _activeStep;
                            return Container(
                              width: isActive ? 18 : 8,
                              height: 8,
                              margin: EdgeInsets.only(left: i > 0 ? 4 : 0),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable form
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // SECTION 1: Basic Info
                                _buildSectionCard(
                                  key: const Key('addproduct_section_basic'),
                                  index: 0,
                                  icon: Icons.shopping_bag_rounded,
                                  title: 'product.product_details'.tr(),
                                  subtitle: 'product.name_desc_pricing'.tr(),
                                  children: [
                                    _buildGlassTextField(
                                      key: const Key('product_name_field'),
                                      controller: _nameController,
                                      label: 'product.product_name'.tr(),
                                      icon: Icons.sell_rounded,
                                      hint: 'product.enter_product_name'.tr(),
                                      validator: (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildGlassTextField(
                                      key: const Key('product_description_field'),
                                      controller: _descriptionController,
                                      label: 'product.description'.tr(),
                                      icon: Icons.notes_rounded,
                                      hint: 'product.describe_product'.tr(),
                                      maxLines: 3,
                                      validator: (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildGlassTextField(
                                            key: const Key('product_price_field'),
                                            controller: _priceController,
                                            label: 'product.price_cad'.tr(),
                                            icon: Icons.attach_money_rounded,
                                            keyboardType: TextInputType.number,
                                            prefixText: '\$ ',
                                            validator: (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGlassTextField(
                                            key: const Key('product_stock_field'),
                                            controller: _stockController,
                                            label: 'product.stock'.tr(),
                                            icon: Icons.inventory_2_rounded,
                                            keyboardType: TextInputType.number,
                                            validator: (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildGlassTextField(
                                            controller: _minOrderController,
                                            label: 'product.min_order_qty'.tr(),
                                            icon: Icons.format_list_numbered_rounded,
                                            keyboardType: TextInputType.number,
                                            validator: (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null,
                                            onChanged: (v) => viewModel.setMinimumOrderQuantity(int.tryParse(v) ?? 1),
                                          ),
                                        ),
                                        // FIX: Hide free shipping toggle for digital products (forced true anyway)
                                        if (!state.isDigital)
                                          Expanded(
                                            child: _buildGlassToggle(
                                              key: const Key('addproduct_free_shipping_toggle'),
                                              label: 'product.free_shipping'.tr(),
                                              icon: Icons.local_shipping_rounded,
                                              value: state.freeShipping,
                                              onChanged: viewModel.toggleFreeShipping,
                                              infoTitle: 'product.free_shipping'.tr(),
                                              infoBody: 'product.free_shipping_info_body'.tr(),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildCategorySelector(viewModel),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(
                                      controller: _taxCodeController,
                                      label: 'product.tax_code_label'.tr(),
                                      icon: Icons.receipt_long_rounded,
                                      hint: 'product.tax_code_hint'.tr(),
                                      validator: (v) => isValidTaxCode(v) ? null : 'product.invalid_tax_code'.tr(),
                                    ),
                                    _buildTappableInfoHint(
                                      'product.tax_code_learn_more'.tr(),
                                      'product.stripe_tax_codes'.tr(),
                                      'product.stripe_tax_codes_body'.tr(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // SECTION 2: Product Images
                                _buildSectionCard(
                                  key: const Key('addproduct_section_images'),
                                  index: 1,
                                  icon: Icons.photo_library_rounded,
                                  title: 'product.product_images'.tr(),
                                  subtitle: 'product.up_to_5_photos'.tr(),
                                  children: [
                                    ProductAddImages(imageModels: state.imageModels, onImagesChanged: viewModel.updateImages),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // SECTION 3: Delivery
                                _buildSectionCard(
                                  key: const Key('addproduct_section_delivery'),
                                  index: 2,
                                  icon: Icons.local_shipping_rounded,
                                  title: 'product.delivery_shipping'.tr(),
                                  subtitle: 'product.shipping_options'.tr(),
                                  children: [
                                    _buildGlassToggle(
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
                                        child: _buildInfoBanner(
                                          'product.digital_skip_shipping'.tr(),
                                          Icons.info_outline_rounded,
                                          DesignTokens.info,
                                        ),
                                      ),
                                    if (!state.isDigital) ...[
                                      const SizedBox(height: 12),
                                      _buildGlassToggle(
                                        key: const Key('addproduct_perishable_toggle'),
                                        label: 'product.perishable_item'.tr(),
                                        icon: Icons.thermostat_rounded,
                                        value: state.isPerishable,
                                        onChanged: viewModel.togglePerishable,
                                        infoTitle: 'product.perishable_info_title'.tr(),
                                        infoBody: 'product.perishable_info_body'.tr(),
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDeliveryTierCard(
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
                                              Expanded(child: _buildGlassTextField(controller: _standardDaysController, label: 'product.days_label'.tr(), keyboardType: TextInputType.number)),
                                              const SizedBox(width: 12),
                                              Expanded(child: _buildGlassTextField(controller: _standardPriceController, label: 'product.price_dollar'.tr(), keyboardType: TextInputType.number, hint: 'product.free_hint'.tr())),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // When free shipping is ON, Express/Same-Day/Bulk discounts are hidden
                                      // because the backend makes ALL tiers $0 anyway
                                      if (state.freeShipping)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: _buildInfoBanner(
                                            'product.free_shipping_banner'.tr(),
                                            Icons.local_shipping_rounded,
                                            DesignTokens.success,
                                          ),
                                        ),
                                      if (!state.freeShipping) ...[
                                        const SizedBox(height: 10),
                                        _buildDeliveryTierCard(
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
                                                Expanded(child: _buildGlassTextField(controller: _expressDaysController, label: 'product.days_label'.tr(), keyboardType: TextInputType.number)),
                                                const SizedBox(width: 12),
                                                Expanded(child: _buildGlassTextField(controller: _expressPriceController, label: 'product.price_dollar'.tr(), keyboardType: TextInputType.number)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        _buildDeliveryTierCard(
                                          key: const Key('addproduct_same_day_delivery_card'),
                                          title: 'product.same_day_delivery'.tr(),
                                          icon: Icons.rocket_launch_rounded,
                                          isEnabled: state.sameDayEnabled,
                                          onChanged: viewModel.setSameDayEnabled,
                                          color: DesignTokens.success,
                                          infoTitle: 'product.same_day_delivery'.tr(),
                                          infoBody: 'product.same_day_delivery_info_body'.tr(),
                                          children: [
                                            _buildGlassTextField(controller: _sameDayPriceController, label: 'product.price_dollar'.tr(), keyboardType: TextInputType.number),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        _buildQuantityShippingDiscountsSection(viewModel, state),
                                      ],
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // SECTION 4: Package & Location
                                if (!state.isDigital)
                                  _buildSectionCard(
                                    key: const Key('addproduct_section_package'),
                                    index: 3,
                                    icon: Icons.location_on_rounded,
                                    title: 'product.package_location'.tr(),
                                    subtitle: 'product.dimensions_pickup'.tr(),
                                    children: [
                                      _buildGlassToggle(
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
                                        _buildGlassTextField(controller: _weightController, key: const Key('addproduct_weight_field'), label: 'product.weight'.tr(), icon: Icons.scale_rounded, keyboardType: TextInputType.number),
                                        const SizedBox(height: 12),
                                        // Dimensions row
                                        Row(
                                          children: [
                                            Expanded(child: _buildGlassTextField(controller: _lengthController, key: const Key('addproduct_length_field'), label: 'product.length_cm'.tr(), keyboardType: TextInputType.number)),
                                            const SizedBox(width: 8),
                                            Expanded(child: _buildGlassTextField(controller: _widthController, key: const Key('addproduct_width_field'), label: 'product.width_cm'.tr(), keyboardType: TextInputType.number)),
                                            const SizedBox(width: 8),
                                            Expanded(child: _buildGlassTextField(controller: _heightController, key: const Key('addproduct_height_field'), label: 'product.height_cm'.tr(), keyboardType: TextInputType.number)),
                                          ],
                                        ),
                                        _buildTappableInfoHint(
                                          'product.weight_dimensions_learn_more'.tr(),
                                          'product.weight_dimensions_info_title'.tr(),
                                          'product.weight_dimensions_info_body'.tr(),
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                      // Location fields
                                      _buildSubSectionHeader('product.pickup_address'.tr(), Icons.pin_drop_rounded),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        key: const Key('addproduct_street_field'),
                                        controller: _streetController,
                                        label: 'product.street_address'.tr(),
                                        icon: Icons.home_rounded,
                                        onChanged: viewModel.onStreetChanged,
                                        validator: (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null,
                                      ),
                                      if (state.showSuggestions && state.addressSuggestions.isNotEmpty)
                                        _buildAddressSuggestions(state, viewModel),
                                      const SizedBox(height: 12),
                                      // FIX: Add apartment field UI (was declared but not rendered)
                                      _buildGlassTextField(
                                        controller: _apartmentController,
                                        label: 'product.apartment_unit'.tr(),
                                        icon: Icons.apartment_rounded,
                                        hint: 'product.apartment_hint'.tr(),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        key: const Key('addproduct_city_field'),
                                        controller: _cityController,
                                        label: 'product.city'.tr(),
                                        validator: (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null,
                                        onChanged: (_) => viewModel.clearCoordinates(),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildGlassDropdown(
                                              key: const Key('addproduct_province_dropdown'),
                                              label: 'product.province'.tr(),
                                              value: state.selectedProvince,
                                              items: _provinceNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.key))).toList(),
                                              onChanged: (v) => viewModel.setProvince(v!),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildGlassTextField(
                                              key: const Key('addproduct_postal_code_field'),
                                              controller: _postalCodeController,
                                              label: 'product.postal_code'.tr(),
                                              textCapitalization: TextCapitalization.characters,
                                              validator: _validatePostalCode,
                                              onChanged: (_) => viewModel.clearCoordinates(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                if (!state.isDigital) const SizedBox(height: 16),

                                _buildCollapsibleSection(
                                  key: const Key('addproduct_section_supplier'),
                                  index: 4,
                                  icon: Icons.business_center_rounded,
                                  title: 'product.supplier_inventory'.tr(),
                                  subtitle: 'product.cost_margins_stock'.tr(),
                                  children: [
                                    _buildSubSectionHeader('product.supplier_info'.tr(), Icons.storefront_rounded),
                                    const SizedBox(height: 12),
                                    _buildGlassDropdown(
                                      label: 'product.supplier_platform'.tr(),
                                      value: _selectedSupplierType,
                                      items: getSupplierDropdownItems(),
                                      onChanged: (v) {
                                        setState(() {
                                          _selectedSupplierType = v ?? 'other';
                                          final config = getSupplierConfig(v);
                                          if (!config.supportedCurrencies.contains(_selectedSupplierCurrency)) {
                                            _selectedSupplierCurrency = config.defaultCurrency;
                                          }
                                        });
                                      },
                                    ),
                                    if (_selectedSupplierType.isNotEmpty) _buildSupplierInfoBadge(_selectedSupplierType),
                                    if (getSupplierConfig(_selectedSupplierType).isCustom) ...[
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: _customSupplierNameController,
                                        label: 'product.custom_supplier_name'.tr(),
                                        icon: Icons.edit_rounded,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    _buildInfoBanner(
                                      'product.supplier_cost_banner'.tr(),
                                      Icons.info_outline_rounded,
                                      DesignTokens.info,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: _buildGlassTextField(
                                            controller: _costController,
                                            label: 'product.supplier_cost'.tr(),
                                            icon: Icons.payments_rounded,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGlassDropdown(
                                            label: 'product.currency_label'.tr(),
                                            value: _selectedSupplierCurrency,
                                            items: getSupplierConfig(_selectedSupplierType).supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                            onChanged: (v) => setState(() => _selectedSupplierCurrency = v ?? 'USD'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Margin preview
                                    if (_costController.text.isNotEmpty && _priceController.text.isNotEmpty) _buildMarginPreview(),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(controller: _supplierSkuController, label: 'product.supplier_sku'.tr(), icon: Icons.qr_code_2_rounded),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(controller: _supplierUrlController, label: 'product.supplier_url'.tr(), icon: Icons.link_rounded, keyboardType: TextInputType.url),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildGlassTextField(controller: _supplierShippingDaysController, label: 'product.ship_days'.tr(), icon: Icons.schedule_rounded)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGlassToggle(
                                            label: 'product.has_tracking'.tr(),
                                            icon: Icons.gps_fixed_rounded,
                                            value: _hasTracking,
                                            onChanged: (v) => setState(() => _hasTracking = v),
                                            infoTitle: 'product.supplier_tracking_title'.tr(),
                                            infoBody: 'product.supplier_tracking_body'.tr(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(controller: _supplierNotesController, label: 'product.internal_notes'.tr(), icon: Icons.sticky_note_2_rounded, maxLines: 2),
                                    const SizedBox(height: 24),
                                    _buildSubSectionHeader('product.inventory_settings'.tr(), Icons.warehouse_rounded),
                                    const SizedBox(height: 12),
                                    _buildGlassToggle(
                                      key: const Key('addproduct_inventory_toggle'),
                                      label: 'product.manage_inventory'.tr(),
                                      subtitle: 'product.manage_inventory_subtitle'.tr(),
                                      icon: Icons.inventory_rounded,
                                      value: _inventoryManaged,
                                      onChanged: (v) => setState(() => _inventoryManaged = v),
                                      infoTitle: 'product.inventory_management_title'.tr(),
                                      infoBody: 'product.inventory_management_body'.tr(),
                                    ),
                                    if (_inventoryManaged) ...[
                                      const SizedBox(height: 8),
                                      _buildGlassToggle(
                                        label: 'product.stock_quantity'.tr(),
                                        subtitle: 'product.track_quantity_subtitle'.tr(),
                                        icon: Icons.numbers_rounded,
                                        value: _trackQuantity,
                                        onChanged: (v) => setState(() => _trackQuantity = v),
                                        infoTitle: 'product.stock_quantity'.tr(),
                                        infoBody: 'product.track_quantity_info_body'.tr(),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildGlassToggle(
                                        label: 'product.allow_backorders'.tr(),
                                        subtitle: 'product.allow_backorders_subtitle'.tr(),
                                        icon: Icons.replay_rounded,
                                        value: _allowBackorder,
                                        onChanged: (v) => setState(() => _allowBackorder = v),
                                        infoTitle: 'product.allow_backorders'.tr(),
                                        infoBody: 'product.allow_backorders_info_body'.tr(),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: _lowStockThresholdController,
                                        label: 'product.low_stock_alert'.tr(),
                                        icon: Icons.warning_amber_rounded,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 28),

                                // Submit Button
                                _buildSubmitButton(state, viewModel),
                                const SizedBox(height: 20),
                              ],
                            ),
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

  // ─── SECTION BUILDERS ─────────────────────────────────────────────────

  Widget _buildSectionCard({
    Key? key,
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return TapRegion(
      key: key,
      onTapInside: (_) {
        if (_activeStep != index) setState(() => _activeStep = index);
      },
      child: AnimatedContainer(
        duration: DesignTokens.durationNormal,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _activeStep == index ? DesignTokens.primary.withValues(alpha: 0.3) : DesignTokens.outlineVariant,
            width: _activeStep == index ? 1.5 : 1,
          ),
          boxShadow: _activeStep == index ? [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))] : DesignTokens.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: DesignTokens.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: DesignTokens.darkSurface, letterSpacing: -0.3)),
                        const SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
                      ],
                    ),
                  ),
                  // Active indicator icon
                  if (_activeStep == index)
                    Icon(Icons.edit_rounded, size: 18, color: DesignTokens.primary),
                ],
              ),
            ),
            const Divider(height: 24, indent: 20, endIndent: 20),
            // Section content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection({
    Key? key,
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
      key: key,
      duration: DesignTokens.durationNormal,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.outlineVariant),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [DesignTokens.secondary, DesignTokens.primary]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: DesignTokens.darkSurface, letterSpacing: -0.3)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle, style: TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
          ),
          children: children,
        ),
      ),
    );
  }

  // ─── FIELD BUILDERS ───────────────────────────────────────────────────

  Widget _buildGlassTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? hint,
    String? prefixText,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: prefixText,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        filled: true,
        fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: DesignTokens.error)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
        hintStyle: TextStyle(color: DesignTokens.textDisabled, fontSize: 13),
      ),
    );
  }

  Widget _buildGlassDropdown({
    Key? key,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      key: key,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildGlassToggle({
    Key? key,
    required String label,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? infoTitle,
    String? infoBody,
  }) {
    return GestureDetector(
      key: key,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? DesignTokens.primary.withValues(alpha: 0.06) : DesignTokens.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: value ? DesignTokens.primary.withValues(alpha: 0.3) : DesignTokens.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: value ? DesignTokens.primary : DesignTokens.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value ? DesignTokens.primary : DesignTokens.textPrimary)),
                  if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            if (infoTitle != null && infoBody != null)
              GestureDetector(
                onTap: () => _showInfoSheet(infoTitle, infoBody),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.info_outline_rounded, size: 16, color: DesignTokens.info.withValues(alpha: 0.5)),
                ),
              ),
            SizedBox(
              height: 28,
              child: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: DesignTokens.primary,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SPECIALIZED WIDGETS ──────────────────────────────────────────────

  Widget _buildCategorySelector(AddProductViewModel viewModel) {
    return DropdownButtonFormField<String>(
      key: const Key('addproduct_category_selector'),
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_rounded, size: 20),
        filled: true,
        fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
      ),
      items: productCategories.map((c) => DropdownMenuItem(
        key: Key('category_item_${c.name}'),
        value: c.categoryId.toString(),
        child: Row(
          children: [
            Icon(c.icon, size: 18, color: DesignTokens.primary),
            const SizedBox(width: 10),
            Text(c.name.tr()),
          ],
        ),
      )).toList(),
      onChanged: (v) => _categoryController.text = v ?? '',
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildDeliveryTierCard({
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
        color: isEnabled ? color.withValues(alpha: 0.04) : DesignTokens.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEnabled ? color.withValues(alpha: 0.3) : DesignTokens.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
            child: Row(
              children: [
                Icon(icon, size: 20, color: isEnabled ? color : DesignTokens.textDisabled),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isEnabled ? color : DesignTokens.textSecondary)),
                ),
                if (infoTitle != null && infoBody != null)
                  GestureDetector(
                    onTap: () => _showInfoSheet(infoTitle, infoBody),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.info_outline_rounded, size: 16, color: isEnabled ? color.withValues(alpha: 0.5) : DesignTokens.textDisabled),
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
          if (isEnabled) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Column(children: children)),
        ],
      ),
    );
  }

  Widget _buildQuantityShippingDiscountsSection(AddProductViewModel viewModel, AddProductState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [DesignTokens.success.withValues(alpha: 0.04), DesignTokens.primary.withValues(alpha: 0.04)],
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
                decoration: BoxDecoration(color: DesignTokens.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.local_offer_rounded, color: DesignTokens.success, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text('product.bulk_shipping_discounts'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              GestureDetector(
                onTap: () => _showInfoSheet(
                  'product.bulk_shipping_discounts'.tr(),
                  'product.bulk_discount_info_body'.tr(),
                ),
                child: Icon(Icons.info_outline_rounded, size: 18, color: DesignTokens.textDisabled),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('product.encourage_larger_orders'.tr(), style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          _buildShippingDiscountTier(label: 'product.three_plus_items'.tr(), controller: _shippingDiscount3Controller, hint: '20'),
          const SizedBox(height: 8),
          _buildShippingDiscountTier(label: 'product.five_plus_items'.tr(), controller: _shippingDiscount5Controller, hint: '50'),
          const SizedBox(height: 8),
          _buildGlassToggle(
            label: 'product.ten_plus_free'.tr(),
            icon: Icons.celebration_rounded,
            value: state.freeShippingAt10Plus,
            onChanged: viewModel.setFreeShippingAt10Plus,
            infoTitle: 'product.bulk_free_shipping_title'.tr(),
            infoBody: 'product.bulk_free_shipping_body'.tr(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGlassTextField(controller: _additionalItemCostController, label: 'product.cost_extra_item'.tr(), prefixText: '\$', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildGlassTextField(controller: _maxItemsPerShipmentController, label: 'product.max_per_shipment'.tr(), keyboardType: TextInputType.number, hint: 'product.unlimited_hint'.tr())),
            ],
          ),
          _buildTappableInfoHint(
            'product.multi_item_learn_more'.tr(),
            'product.multi_item_shipping_title'.tr(),
            'product.multi_item_shipping_body'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingDiscountTier({required String label, required TextEditingController controller, required String hint}) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: TextStyle(color: DesignTokens.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            validator: (v) {
              if (v == null || v.isEmpty) return null; // optional field
              final val = double.tryParse(v);
              if (val == null || val < 0 || val > 100) return 'product.discount_range'.tr();
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              suffixText: 'product.percent_off'.tr(),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.2))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: DesignTokens.success, width: 1.5)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarginPreview() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    if (cost <= 0 || price <= 0) return const SizedBox.shrink();

    final margin = ((price - cost) / price * 100);
    final profit = price - cost;
    final isGood = margin > 30;
    final isOk = margin > 15;
    final color = isGood ? DesignTokens.success : (isOk ? DesignTokens.warning : DesignTokens.error);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Margin circle
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)]),
                ),
                child: Center(
                  child: Text(
                    '${margin.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('product.profit_margin'.tr(), style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(
                      'product.per_unit'.tr(namedArgs: {'amount': profit.toStringAsFixed(2)}),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
                    ),
                  ],
                ),
              ),
              Icon(
                isGood ? Icons.trending_up_rounded : (isOk ? Icons.trending_flat_rounded : Icons.trending_down_rounded),
                color: color,
                size: 28,
              ),
            ],
          ),
          if (_selectedSupplierCurrency != 'CAD')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'product.margin_warning'.tr(namedArgs: {'currency': _selectedSupplierCurrency}),
                style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSupplierInfoBadge(String supplierId) {
    final config = getSupplierConfig(supplierId);
    final deliveryRange = getSupplierDeliveryRange(supplierId);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: config.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(config.icon, size: 18, color: config.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.displayName, style: TextStyle(fontWeight: FontWeight.w700, color: config.color, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  '${config.region} · ${deliveryRange.minDays}-${deliveryRange.maxDays} days · ${config.country}',
                  style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary),
                ),
              ],
            ),
          ),
          if (config.isInternational)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [DesignTokens.info.withValues(alpha: 0.15), DesignTokens.info.withValues(alpha: 0.05)]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('product.intl_label'.tr(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DesignTokens.info)),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressSuggestions(AddProductState state, AddProductViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: DesignTokens.shadowLg,
        border: Border.all(color: DesignTokens.outline.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: state.addressSuggestions.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: DesignTokens.outlineVariant),
          itemBuilder: (context, i) {
            final s = state.addressSuggestions[i];
            return ListTile(
              dense: true,
              leading: Icon(Icons.location_on_rounded, size: 18, color: DesignTokens.primary),
              title: Text(s['properties']?['formatted'] ?? '', style: const TextStyle(fontSize: 13)),
              onTap: () {
                viewModel.selectAddress(s);
                _streetController.text = s['properties']?['street'] ?? '';
                _cityController.text = s['properties']?['city'] ?? '';
                _postalCodeController.text = s['properties']?['postcode'] ?? '';
              },
            );
          },
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────

  Widget _buildSubSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: DesignTokens.secondary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DesignTokens.darkSurface)),
      ],
    );
  }

  Widget _buildInfoBanner(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  void _showInfoSheet(String title, String body) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DesignTokens.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lightbulb_rounded, color: DesignTokens.info, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: DesignTokens.darkSurface)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: DesignTokens.surfaceVariant, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 16, color: DesignTokens.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(body, style: TextStyle(fontSize: 14, color: DesignTokens.textPrimary, height: 1.6)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTappableInfoHint(String shortText, String title, String body) {
    return GestureDetector(
      onTap: () => _showInfoSheet(title, body),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: DesignTokens.info.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Expanded(child: Text(shortText, style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary))),
            Icon(Icons.chevron_right_rounded, size: 14, color: DesignTokens.textDisabled),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AddProductState state, AddProductViewModel viewModel) {
    return Semantics(
      button: true,
      label: 'btn-publish-product',
      child: GestureDetector(
      onTapDown: state.isLoading ? null : (_) => HapticFeedback.mediumImpact(),
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        height: 56,
        decoration: BoxDecoration(
          gradient: state.isLoading ? null : DesignTokens.primaryGradient,
          color: state.isLoading ? DesignTokens.outline : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: state.isLoading
              ? []
              : [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('addproduct_submit_button'),
            borderRadius: BorderRadius.circular(16),
            onTap: state.isLoading
                ? null
                : () {
                    // FIX: Validate discount tiers before form validation
                    final discount3 = double.tryParse(_shippingDiscount3Controller.text);
                    final discount5 = double.tryParse(_shippingDiscount5Controller.text);
                    if (discount3 != null && discount5 != null && discount5 < discount3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('product.discount_validation'.tr()),
                          backgroundColor: DesignTokens.error,
                        ),
                      );
                      return;
                    }
                    if (_formKey.currentState!.validate()) {
                      SupplierInfo? supplierInfo;
                      final hasCost = _costController.text.trim().isNotEmpty;
                      final hasSku = _supplierSkuController.text.trim().isNotEmpty;
                      final hasUrl = _supplierUrlController.text.trim().isNotEmpty;

                      if (hasCost || hasSku || hasUrl) {
                        supplierInfo = SupplierInfo(
                          type: _selectedSupplierType,
                          cost: double.tryParse(_costController.text),
                          currency: _selectedSupplierCurrency,
                          supplierSku: hasSku ? _supplierSkuController.text.trim() : null,
                          supplierUrl: hasUrl ? _supplierUrlController.text.trim() : null,
                          shippingDays: _supplierShippingDaysController.text.trim().isEmpty ? null : _supplierShippingDaysController.text.trim(),
                          hasTracking: _hasTracking,
                          notes: _supplierNotesController.text.trim().isEmpty ? null : _supplierNotesController.text.trim(),
                        );
                      }

                      // FIX: Always create inventory config to persist settings
                      final inventoryConfig = InventoryConfig(
                        managed: _inventoryManaged,
                        trackQuantity: _trackQuantity,
                        allowBackorder: _allowBackorder,
                        lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? 5,
                      );

                      viewModel.addProduct(
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        price: double.tryParse(_priceController.text.trim()) ?? 0,
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
                        taxCode: _taxCodeController.text.trim(),
                        deliveryOptions: _buildDeliveryOptions(state),
                        minimumOrderQuantity: int.tryParse(_minOrderController.text) ?? 1,
                        freeShipping: state.freeShipping,
                        cost: double.tryParse(_costController.text),
                        supplierSku: _supplierSkuController.text.trim().isEmpty ? null : _supplierSkuController.text.trim(),
                        supplierUrl: _supplierUrlController.text.trim().isEmpty ? null : _supplierUrlController.text.trim(),
                        supplier: supplierInfo,
                        inventory: inventoryConfig,
                      );
                    }
                  },
            child: Center(
              child: state.isLoading
                  ? const ModernLoadingIndicator(size: 24, strokeWidth: 2.5, color: Colors.white, centered: false)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'product.publish_product'.tr(),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
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

  // ─── DATA BUILDERS ────────────────────────────────────────────────────

  List<SellerDeliveryOption> _buildDeliveryOptions(AddProductState state) {
    if (state.isDigital) return [];

    // Bug #2: Local-only products need a pickup delivery option
    if (state.isLocalDeliveryOnly) {
      return [
        SellerDeliveryOption(
          type: 'pickup',
          description: 'product.local_pickup_only'.tr(),
          estimatedDays: 0,
          cost: 0.0,
        ),
      ];
    }

    final quantityDiscounts = <ShippingQuantityDiscount>[];

    final discount3 = double.tryParse(_shippingDiscount3Controller.text);
    if (discount3 != null && discount3 > 0) {
      quantityDiscounts.add(ShippingQuantityDiscount(
        minQuantity: 3,
        discountType: 'percent',
        discountValue: discount3,
        label: 'product.shipping_discount_label'.tr(namedArgs: {'percent': discount3.toStringAsFixed(0), 'qty': '3'}),
      ));
    }

    final discount5 = double.tryParse(_shippingDiscount5Controller.text);
    if (discount5 != null && discount5 > 0) {
      quantityDiscounts.add(ShippingQuantityDiscount(
        minQuantity: 5,
        discountType: 'percent',
        discountValue: discount5,
        label: 'product.shipping_discount_label'.tr(namedArgs: {'percent': discount5.toStringAsFixed(0), 'qty': '5'}),
      ));
    }

    if (state.freeShippingAt10Plus) {
      quantityDiscounts.add(ShippingQuantityDiscount(minQuantity: 10, discountType: 'flat_rate', discountValue: 0, label: 'product.free_shipping_10_plus_label'.tr()));
    }

    final additionalItemCost = double.tryParse(_additionalItemCostController.text) ?? 0.0;
    final maxItems = int.tryParse(_maxItemsPerShipmentController.text) ?? 0;

    return [
      if (state.standardEnabled)
        SellerDeliveryOption(
          type: 'standard',
          description: 'product.standard_delivery'.tr(),
          estimatedDays: int.tryParse(_standardDaysController.text) ?? 5,
          cost: double.tryParse(_standardPriceController.text) ?? 0.0,
          quantityDiscounts: quantityDiscounts,
          additionalItemCost: additionalItemCost,
          maxItemsPerShipment: maxItems,
        ),
      if (state.expressEnabled)
        SellerDeliveryOption(
          type: 'express',
          description: 'product.express_delivery'.tr(),
          estimatedDays: int.tryParse(_expressDaysController.text) ?? 2,
          cost: double.tryParse(_expressPriceController.text) ?? 9.99,
          quantityDiscounts: quantityDiscounts,
          additionalItemCost: additionalItemCost,
          maxItemsPerShipment: maxItems,
        ),
      if (state.sameDayEnabled)
        SellerDeliveryOption(
          type: 'same_day',
          description: 'product.same_day_delivery'.tr(),
          estimatedDays: 0,
          cost: double.tryParse(_sameDayPriceController.text) ?? 14.99,
          quantityDiscounts: quantityDiscounts,
          additionalItemCost: additionalItemCost,
          maxItemsPerShipment: maxItems,
        ),
    ];
  }

  void _onSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('addproduct_success_snackbar'),
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('product.published_success'.tr(), style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: DesignTokens.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    Navigator.pop(context);
  }

  String? _validatePostalCode(String? v) {
    if (v == null || v.isEmpty) return 'common.required'.tr();
    final normalized = v.toUpperCase().replaceAll(' ', '').trim();
    final reg = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');
    if (!reg.hasMatch(normalized)) return 'product.invalid_postal'.tr();
    return null;
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
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
    _taxCodeController.dispose();
    _minOrderController.dispose();
    _standardDaysController.dispose();
    _standardPriceController.dispose();
    _expressDaysController.dispose();
    _expressPriceController.dispose();
    _sameDayPriceController.dispose();
    _costController.dispose();
    _supplierSkuController.dispose();
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
}
