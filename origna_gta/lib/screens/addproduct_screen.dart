import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/config/supplier_config.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';

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
  final _sameDayRadiusController = TextEditingController(text: '50');

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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'New Product',
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
                                  index: 0,
                                  icon: Icons.shopping_bag_rounded,
                                  title: 'Product Details',
                                  subtitle: 'Name, description & pricing',
                                  children: [
                                    _buildGlassTextField(
                                      key: const Key('product_name_field'),
                                      controller: _nameController,
                                      label: 'Product Name',
                                      icon: Icons.sell_rounded,
                                      hint: 'Enter product name',
                                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildGlassTextField(
                                      key: const Key('product_description_field'),
                                      controller: _descriptionController,
                                      label: 'Description',
                                      icon: Icons.notes_rounded,
                                      hint: 'Describe your product...',
                                      maxLines: 3,
                                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildGlassTextField(
                                            key: const Key('product_price_field'),
                                            controller: _priceController,
                                            label: 'Price (CAD)',
                                            icon: Icons.attach_money_rounded,
                                            keyboardType: TextInputType.number,
                                            prefixText: '\$ ',
                                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGlassTextField(
                                            key: const Key('product_stock_field'),
                                            controller: _stockController,
                                            label: 'Stock',
                                            icon: Icons.inventory_2_rounded,
                                            keyboardType: TextInputType.number,
                                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
                                            label: 'Min Order Qty',
                                            icon: Icons.format_list_numbered_rounded,
                                            keyboardType: TextInputType.number,
                                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                            onChanged: (v) => viewModel.setMinimumOrderQuantity(int.tryParse(v) ?? 1),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGlassToggle(
                                            label: 'Free Shipping',
                                            icon: Icons.local_shipping_rounded,
                                            value: state.freeShipping,
                                            onChanged: viewModel.toggleFreeShipping,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildCategorySelector(viewModel),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(
                                      controller: _taxCodeController,
                                      label: 'Tax Code (optional)',
                                      icon: Icons.receipt_long_rounded,
                                      hint: 'txcd_########',
                                      validator: (v) => isValidTaxCode(v) ? null : 'Invalid tax code',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // SECTION 2: Product Images
                                _buildSectionCard(
                                  index: 1,
                                  icon: Icons.photo_library_rounded,
                                  title: 'Product Images',
                                  subtitle: 'Up to 5 photos',
                                  children: [
                                    ProductAddImages(imageModels: state.imageModels),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // SECTION 3: Delivery
                                _buildSectionCard(
                                  index: 2,
                                  icon: Icons.local_shipping_rounded,
                                  title: 'Delivery & Shipping',
                                  subtitle: 'Options, packaging & discounts',
                                  children: [
                                    _buildGlassToggle(
                                      label: 'Digital Product',
                                      subtitle: 'No shipping needed',
                                      icon: Icons.cloud_download_rounded,
                                      value: state.isDigital,
                                      onChanged: viewModel.toggleDigital,
                                    ),
                                    if (state.isDigital)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: _buildInfoBanner(
                                          'Digital products skip shipping and delivery options.',
                                          Icons.info_outline_rounded,
                                          DesignTokens.info,
                                        ),
                                      ),
                                    if (!state.isDigital) ...[
                                      const SizedBox(height: 12),
                                      _buildGlassToggle(
                                        label: 'Perishable Item',
                                        icon: Icons.thermostat_rounded,
                                        value: state.isPerishable,
                                        onChanged: viewModel.togglePerishable,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDeliveryTierCard(
                                        title: 'Standard Delivery',
                                        icon: Icons.local_shipping_outlined,
                                        isEnabled: state.standardEnabled,
                                        onChanged: viewModel.setStandardEnabled,
                                        color: DesignTokens.primary,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: _buildGlassTextField(controller: _standardDaysController, label: 'Days', keyboardType: TextInputType.number)),
                                              const SizedBox(width: 12),
                                              Expanded(child: _buildGlassTextField(controller: _standardPriceController, label: 'Price (\$)', keyboardType: TextInputType.number, hint: '0 = Free')),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _buildDeliveryTierCard(
                                        title: 'Express Delivery',
                                        icon: Icons.bolt_rounded,
                                        isEnabled: state.expressEnabled,
                                        onChanged: viewModel.setExpressEnabled,
                                        color: DesignTokens.warning,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: _buildGlassTextField(controller: _expressDaysController, label: 'Days', keyboardType: TextInputType.number)),
                                              const SizedBox(width: 12),
                                              Expanded(child: _buildGlassTextField(controller: _expressPriceController, label: 'Price (\$)', keyboardType: TextInputType.number)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _buildDeliveryTierCard(
                                        title: 'Same-Day Delivery',
                                        icon: Icons.rocket_launch_rounded,
                                        isEnabled: state.sameDayEnabled,
                                        onChanged: viewModel.setSameDayEnabled,
                                        color: DesignTokens.success,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(child: _buildGlassTextField(controller: _sameDayPriceController, label: 'Price (\$)', keyboardType: TextInputType.number)),
                                              const SizedBox(width: 12),
                                              Expanded(child: _buildGlassTextField(controller: _sameDayRadiusController, label: 'Radius (km)', keyboardType: TextInputType.number)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      _buildQuantityShippingDiscountsSection(viewModel, state),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // SECTION 4: Package & Location
                                if (!state.isDigital)
                                  _buildSectionCard(
                                    index: 3,
                                    icon: Icons.location_on_rounded,
                                    title: 'Package & Location',
                                    subtitle: 'Dimensions and pickup address',
                                    children: [
                                      _buildGlassToggle(
                                        label: 'Local Pickup Only',
                                        icon: Icons.store_rounded,
                                        value: state.isLocalDeliveryOnly,
                                        onChanged: viewModel.setLocalDeliveryOnly,
                                      ),
                                      if (!state.isLocalDeliveryOnly) ...[
                                        const SizedBox(height: 16),
                                        _buildGlassTextField(controller: _weightController, label: 'Weight (kg)', icon: Icons.scale_rounded, keyboardType: TextInputType.number),
                                        const SizedBox(height: 12),
                                        // Dimensions row
                                        Row(
                                          children: [
                                            Expanded(child: _buildGlassTextField(controller: _lengthController, label: 'L (cm)', keyboardType: TextInputType.number)),
                                            const SizedBox(width: 8),
                                            Expanded(child: _buildGlassTextField(controller: _widthController, label: 'W (cm)', keyboardType: TextInputType.number)),
                                            const SizedBox(width: 8),
                                            Expanded(child: _buildGlassTextField(controller: _heightController, label: 'H (cm)', keyboardType: TextInputType.number)),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                      // Location fields
                                      _buildSubSectionHeader('Pickup Address', Icons.pin_drop_rounded),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: _streetController,
                                        label: 'Street Address',
                                        icon: Icons.home_rounded,
                                        onChanged: viewModel.onStreetChanged,
                                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                      ),
                                      if (state.showSuggestions && state.addressSuggestions.isNotEmpty)
                                        _buildAddressSuggestions(state, viewModel),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: _cityController,
                                        label: 'City',
                                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildGlassDropdown(
                                              label: 'Province',
                                              value: state.selectedProvince,
                                              items: _provinceNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.key))).toList(),
                                              onChanged: (v) => viewModel.setProvince(v!),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildGlassTextField(
                                              controller: _postalCodeController,
                                              label: 'Postal Code',
                                              textCapitalization: TextCapitalization.characters,
                                              validator: _validatePostalCode,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                if (!state.isDigital) const SizedBox(height: 16),

                                // SECTION 5: Supplier & Inventory (Collapsible)
                                _buildCollapsibleSection(
                                  index: 4,
                                  icon: Icons.business_center_rounded,
                                  title: 'Supplier & Inventory',
                                  subtitle: 'Cost tracking, margins & stock settings',
                                  children: [
                                    _buildSubSectionHeader('Supplier Info', Icons.storefront_rounded),
                                    const SizedBox(height: 12),
                                    _buildGlassDropdown(
                                      label: 'Supplier Platform',
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
                                        label: 'Custom Supplier Name',
                                        icon: Icons.edit_rounded,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    _buildInfoBanner(
                                      'Track supplier cost below. Selling prices are always in CAD.',
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
                                            label: 'Supplier Cost',
                                            icon: Icons.payments_rounded,
                                            keyboardType: TextInputType.number,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGlassDropdown(
                                            label: 'Currency',
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
                                    _buildGlassTextField(controller: _supplierSkuController, label: 'Supplier SKU', icon: Icons.qr_code_2_rounded),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(controller: _supplierUrlController, label: 'Supplier URL', icon: Icons.link_rounded, keyboardType: TextInputType.url),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _buildGlassTextField(controller: _supplierShippingDaysController, label: 'Ship Days', icon: Icons.schedule_rounded)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildGlassToggle(
                                            label: 'Has Tracking',
                                            icon: Icons.gps_fixed_rounded,
                                            value: _hasTracking,
                                            onChanged: (v) => setState(() => _hasTracking = v),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildGlassTextField(controller: _supplierNotesController, label: 'Internal Notes', icon: Icons.sticky_note_2_rounded, maxLines: 2),
                                    const SizedBox(height: 24),
                                    _buildSubSectionHeader('Inventory Settings', Icons.warehouse_rounded),
                                    const SizedBox(height: 12),
                                    _buildGlassToggle(
                                      label: 'Manage Inventory',
                                      subtitle: 'Off for dropship products',
                                      icon: Icons.inventory_rounded,
                                      value: _inventoryManaged,
                                      onChanged: (v) => setState(() => _inventoryManaged = v),
                                    ),
                                    if (_inventoryManaged) ...[
                                      const SizedBox(height: 8),
                                      _buildGlassToggle(
                                        label: 'Track Quantity',
                                        subtitle: 'Off = unlimited stock',
                                        icon: Icons.numbers_rounded,
                                        value: _trackQuantity,
                                        onChanged: (v) => setState(() => _trackQuantity = v),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildGlassToggle(
                                        label: 'Allow Backorders',
                                        subtitle: 'Accept when out of stock',
                                        icon: Icons.replay_rounded,
                                        value: _allowBackorder,
                                        onChanged: (v) => setState(() => _allowBackorder = v),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: _lowStockThresholdController,
                                        label: 'Low Stock Alert',
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
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return TapRegion(
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
                        Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  // Section number badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _activeStep == index ? DesignTokens.primary : DesignTokens.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _activeStep == index ? Colors.white : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
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
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
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
            child: Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
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
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildGlassToggle({
    required String label,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
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
            Icon(icon, size: 20, color: value ? DesignTokens.primary : Colors.grey[500]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value ? DesignTokens.primary : Colors.grey[700])),
                  if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
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
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_rounded, size: 20),
        filled: true,
        fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
      ),
      items: productCategories.map((c) => DropdownMenuItem(
        value: c.categoryId.toString(),
        child: Row(
          children: [
            Icon(c.icon, size: 18, color: DesignTokens.primary),
            const SizedBox(width: 10),
            Text(c.name),
          ],
        ),
      )).toList(),
      onChanged: (v) => _categoryController.text = v ?? '',
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildDeliveryTierCard({
    required String title,
    required IconData icon,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required Color color,
    required List<Widget> children,
  }) {
    return AnimatedContainer(
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
                Icon(icon, size: 20, color: isEnabled ? color : Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isEnabled ? color : Colors.grey[500])),
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
              const Expanded(child: Text('Bulk Shipping Discounts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              Tooltip(
                message: 'Offer shipping discounts for bulk orders',
                child: Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Encourage larger orders with shipping savings', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const SizedBox(height: 16),
          _buildShippingDiscountTier(label: '3+ items', controller: _shippingDiscount3Controller, hint: '20'),
          const SizedBox(height: 8),
          _buildShippingDiscountTier(label: '5+ items', controller: _shippingDiscount5Controller, hint: '50'),
          const SizedBox(height: 8),
          _buildGlassToggle(
            label: '10+ items: Free Shipping',
            icon: Icons.celebration_rounded,
            value: state.freeShippingAt10Plus,
            onChanged: viewModel.setFreeShippingAt10Plus,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGlassTextField(controller: _additionalItemCostController, label: 'Cost/extra item', prefixText: '\$', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildGlassTextField(controller: _maxItemsPerShipmentController, label: 'Max per shipment', keyboardType: TextInputType.number, hint: '0 = unlimited')),
            ],
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
          child: Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              suffixText: '% off',
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
      child: Row(
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
                Text('Profit Margin', style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  '\$${profit.toStringAsFixed(2)} per unit',
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
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
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
              child: const Text('INT\'L', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DesignTokens.info)),
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

  Widget _buildSubmitButton(AddProductState state, AddProductViewModel viewModel) {
    return GestureDetector(
      onTapDown: state.isLoading ? null : (_) => HapticFeedback.mediumImpact(),
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        height: 56,
        decoration: BoxDecoration(
          gradient: state.isLoading ? null : DesignTokens.primaryGradient,
          color: state.isLoading ? Colors.grey[300] : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: state.isLoading
              ? []
              : [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: state.isLoading
                ? null
                : () {
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

                      InventoryConfig? inventoryConfig;
                      if (!_inventoryManaged || !_trackQuantity || _allowBackorder || (int.tryParse(_lowStockThresholdController.text) ?? 5) != 5) {
                        inventoryConfig = InventoryConfig(
                          managed: _inventoryManaged,
                          trackQuantity: _trackQuantity,
                          allowBackorder: _allowBackorder,
                          lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? 5,
                        );
                      }

                      viewModel.addProduct(
                        name: _nameController.text.trim(),
                        description: _descriptionController.text.trim(),
                        price: double.parse(_priceController.text.trim()),
                        stock: int.parse(_stockController.text.trim()),
                        categoryId: int.parse(_categoryController.text.trim()),
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
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Publish Product',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                        ),
                      ],
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

    final quantityDiscounts = <ShippingQuantityDiscount>[];

    final discount3 = double.tryParse(_shippingDiscount3Controller.text);
    if (discount3 != null && discount3 > 0) {
      quantityDiscounts.add(ShippingQuantityDiscount(
        minQuantity: 3,
        discountType: 'percent',
        discountValue: discount3,
        label: '${discount3.toStringAsFixed(0)}% off shipping for 3+ items',
      ));
    }

    final discount5 = double.tryParse(_shippingDiscount5Controller.text);
    if (discount5 != null && discount5 > 0) {
      quantityDiscounts.add(ShippingQuantityDiscount(
        minQuantity: 5,
        discountType: 'percent',
        discountValue: discount5,
        label: '${discount5.toStringAsFixed(0)}% off shipping for 5+ items',
      ));
    }

    if (state.freeShippingAt10Plus) {
      quantityDiscounts.add(const ShippingQuantityDiscount(minQuantity: 10, discountType: 'flat_rate', discountValue: 0, label: 'Free shipping for 10+ items'));
    }

    final additionalItemCost = double.tryParse(_additionalItemCostController.text) ?? 0.0;
    final maxItems = int.tryParse(_maxItemsPerShipmentController.text) ?? 0;

    return [
      if (state.standardEnabled)
        SellerDeliveryOption(
          type: 'standard',
          description: 'Standard Delivery',
          estimatedDays: int.tryParse(_standardDaysController.text) ?? 5,
          cost: double.tryParse(_standardPriceController.text) ?? 0.0,
          quantityDiscounts: quantityDiscounts,
          additionalItemCost: additionalItemCost,
          maxItemsPerShipment: maxItems,
        ),
      if (state.expressEnabled)
        SellerDeliveryOption(
          type: 'express',
          description: 'Express Delivery',
          estimatedDays: int.tryParse(_expressDaysController.text) ?? 2,
          cost: double.tryParse(_expressPriceController.text) ?? 9.99,
          quantityDiscounts: quantityDiscounts,
          additionalItemCost: additionalItemCost,
          maxItemsPerShipment: maxItems,
        ),
      if (state.sameDayEnabled)
        SellerDeliveryOption(
          type: 'same_day',
          description: 'Same Day Delivery',
          estimatedDays: 0,
          cost: double.tryParse(_sameDayPriceController.text) ?? 14.99,
        ),
    ];
  }

  void _onSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Product published successfully!', style: TextStyle(fontWeight: FontWeight.w600)),
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
    if (v == null || v.isEmpty) return 'Required';
    final reg = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');
    if (!reg.hasMatch(v.toUpperCase().trim())) return 'Invalid (A1A 1A1)';
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
    _sameDayRadiusController.dispose();
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
