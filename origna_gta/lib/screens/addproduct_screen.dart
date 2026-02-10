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
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Go back',
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
                                        // FIX: Hide free shipping toggle for digital products (forced true anyway)
                                        if (!state.isDigital)
                                          Expanded(
                                            child: _buildGlassToggle(
                                              label: 'Free Shipping',
                                              icon: Icons.local_shipping_rounded,
                                              value: state.freeShipping,
                                              onChanged: viewModel.toggleFreeShipping,
                                              infoTitle: 'Free Shipping',
                                              infoBody: 'When enabled, the buyer pays \$0 for shipping — you absorb the cost.\n\nThis is great for increasing conversions, especially for lightweight or high-margin products.\n\nTip: You can also offer free shipping only for bulk orders (10+ items) in the Delivery section below.',
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
                                    _buildTappableInfoHint(
                                      'What is a tax code? Tap to learn more',
                                      'Stripe Tax Codes',
                                      'Tax codes tell Stripe which tax rate to apply at checkout.\n\nFormat: txcd_ followed by 8 digits (e.g. txcd_99999999).\n\nCommon codes:\n• txcd_99999999 — General tangible goods\n• txcd_10000000 — General services\n• txcd_10201000 — Software as a Service (SaaS)\n• txcd_35010000 — Clothing & apparel\n\nLeave empty to use Stripe\'s default tax behavior. Find the full list at stripe.com/docs/tax/tax-codes.',
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
                                    ProductAddImages(imageModels: state.imageModels, onImagesChanged: viewModel.updateImages),
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
                                      infoTitle: 'Digital Products',
                                      infoBody: 'Enable this for products delivered electronically — e-books, software, digital art, courses, etc.\n\nWhat happens:\n• Shipping is automatically set to free\n• Delivery tiers and package dimensions are hidden\n• No physical address is needed from the buyer\n\nThe buyer will receive the product through your delivery method (email, download link, etc.).',
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
                                        infoTitle: 'Perishable Items',
                                        infoBody: 'Mark products that are temperature-sensitive or have a short shelf life — food, flowers, cosmetics, etc.\n\nWhat this does:\n• Flags the product for priority handling\n• Buyers are informed about special shipping conditions\n• Express or Same-Day delivery is recommended\n\nTip: Consider enabling Same-Day Delivery below for perishable items to ensure freshness.',
                                      ),
                                      const SizedBox(height: 16),
                                      _buildDeliveryTierCard(
                                        title: 'Standard Delivery',
                                        icon: Icons.local_shipping_outlined,
                                        isEnabled: state.standardEnabled,
                                        onChanged: viewModel.setStandardEnabled,
                                        color: DesignTokens.primary,
                                        infoTitle: 'Standard Delivery',
                                        infoBody: 'The base shipping option for your product.\n\nPricing:\n• Set Price to \$0 for free standard shipping\n• Or set your own flat rate (e.g. \$5.99)\n• If left at \$0 and Free Shipping is off, distance-based rates apply\n\nDays: Estimated business days for delivery (shown to buyers).\n\nAt least one delivery tier must be enabled for physical products.',
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
                                      // When free shipping is ON, Express/Same-Day/Bulk discounts are hidden
                                      // because the backend makes ALL tiers $0 anyway
                                      if (state.freeShipping)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 12),
                                          child: _buildInfoBanner(
                                            'Free shipping is enabled — Express and Same-Day tiers are hidden. Standard delivery will be offered at no cost to the buyer.',
                                            Icons.local_shipping_rounded,
                                            DesignTokens.success,
                                          ),
                                        ),
                                      if (!state.freeShipping) ...[
                                        const SizedBox(height: 10),
                                        _buildDeliveryTierCard(
                                          title: 'Express Delivery',
                                          icon: Icons.bolt_rounded,
                                          isEnabled: state.expressEnabled,
                                          onChanged: viewModel.setExpressEnabled,
                                          color: DesignTokens.warning,
                                          infoTitle: 'Express Delivery',
                                          infoBody: 'Offer faster shipping at a premium price.\n\nDefault surcharge: \$9.99 on top of standard shipping.\n\nWhen a buyer selects Express at checkout:\n• Your price here is the base rate shown\n• An additional express surcharge is applied automatically\n• You keep the shipping revenue minus platform fees\n\nTypical express timeframe: 1-2 business days.',
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
                                          infoTitle: 'Same-Day Delivery',
                                          infoBody: 'Offer same-day delivery for local buyers.\n\nDefault surcharge: \$14.99 on top of base shipping.\n\nHow it works:\n• Only available for buyers within your delivery area\n• Orders must be placed before your cutoff time\n• Best for perishable items, gifts, or urgent needs\n\nIdeal for food, flowers, and time-sensitive products.',
                                          children: [
                                            _buildGlassTextField(controller: _sameDayPriceController, label: 'Price (\$)', keyboardType: TextInputType.number),
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
                                        infoTitle: 'Local Pickup Only',
                                        infoBody: 'Enable this if the product can only be picked up in person — no shipping.\n\nWhat happens:\n• Shipping cost is \$0 for the buyer\n• Package weight and dimensions fields are hidden\n• A "pickup" delivery option is automatically created\n• The buyer sees your address as the pickup location\n\nPerfect for: furniture, large items, fresh food, or any product you don\'t want to ship.',
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
                                        _buildTappableInfoHint(
                                          'How weight & dimensions affect shipping cost',
                                          'Package Weight & Dimensions',
                                          'Accurate weight and dimensions help calculate fair shipping rates.\n\nHow pricing works:\n• Carriers use the greater of actual weight vs dimensional weight\n• Dimensional weight = (L × W × H) ÷ 5000 (in cm/kg)\n• Example: A box 40×30×20 cm = 4.8 kg dimensional\n\nIf your product is light but bulky, you may pay more than expected. Enter accurate dimensions to avoid surprises.\n\nTip: Measure the packaged product, not just the product itself.',
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
                                      // FIX: Add apartment field UI (was declared but not rendered)
                                      _buildGlassTextField(
                                        controller: _apartmentController,
                                        label: 'Apartment / Unit (Optional)',
                                        icon: Icons.apartment_rounded,
                                        hint: 'e.g., Suite 100, Unit 5B',
                                      ),
                                      const SizedBox(height: 12),
                                      _buildGlassTextField(
                                        controller: _cityController,
                                        label: 'City',
                                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                                        onChanged: (_) => viewModel.clearCoordinates(),
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
                                              onChanged: (_) => viewModel.clearCoordinates(),
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
                                            infoTitle: 'Supplier Tracking',
                                            infoBody: 'Does your supplier provide tracking numbers?\n\nWhen enabled:\n• You can enter tracking numbers for each order\n• Buyers receive shipping updates automatically\n• Helps reduce "where is my order?" inquiries\n\nMost suppliers (AliExpress, Amazon, etc.) provide tracking. Smaller local suppliers may not.',
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
                                      infoTitle: 'Inventory Management',
                                      infoBody: 'Controls whether stock levels are tracked for this product.\n\nON (recommended for most):\n• Stock decreases automatically on each sale\n• Low stock alerts notify you when to restock\n• Product is hidden when stock reaches 0\n\nOFF (for dropship products):\n• Stock is never tracked — unlimited availability\n• Your supplier fulfills orders directly\n\nTip: Turn OFF if using AliExpress or similar dropship suppliers.',
                                    ),
                                    if (_inventoryManaged) ...[
                                      const SizedBox(height: 8),
                                      _buildGlassToggle(
                                        label: 'Track Quantity',
                                        subtitle: 'Off = unlimited stock',
                                        icon: Icons.numbers_rounded,
                                        value: _trackQuantity,
                                        onChanged: (v) => setState(() => _trackQuantity = v),
                                        infoTitle: 'Track Quantity',
                                        infoBody: 'When ON, stock counts down with each sale and the product becomes unavailable at 0.\n\nWhen OFF, the product always shows as "in stock" regardless of orders. Useful for made-to-order or digital-like physical products.\n\nNote: Only applies when Manage Inventory is also ON.',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildGlassToggle(
                                        label: 'Allow Backorders',
                                        subtitle: 'Accept when out of stock',
                                        icon: Icons.replay_rounded,
                                        value: _allowBackorder,
                                        onChanged: (v) => setState(() => _allowBackorder = v),
                                        infoTitle: 'Allow Backorders',
                                        infoBody: 'When enabled, buyers can still place orders even when stock is 0.\n\nThis is useful if:\n• You can restock quickly from your supplier\n• You accept pre-orders\n• You manufacture on demand\n\nThe buyer will NOT be warned — update your product description if fulfillment may be delayed.',
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
    String? infoTitle,
    String? infoBody,
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
    String? infoTitle,
    String? infoBody,
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
                if (infoTitle != null && infoBody != null)
                  GestureDetector(
                    onTap: () => _showInfoSheet(infoTitle, infoBody),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.info_outline_rounded, size: 16, color: isEnabled ? color.withValues(alpha: 0.5) : Colors.grey[400]),
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
              const Expanded(child: Text('Bulk Shipping Discounts', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
              GestureDetector(
                onTap: () => _showInfoSheet(
                  'Bulk Shipping Discounts',
                  'Encourage bigger orders by offering progressive shipping discounts.\n\nHow tiers work:\n• 3+ items: A percentage off shipping (e.g. 20% off)\n• 5+ items: A bigger percentage (e.g. 50% off)\n• 10+ items: Free shipping entirely\n\nAdditional item cost: Extra shipping per item beyond the first (e.g. \$1.50/item for heavier products).\n\nMax per shipment: Limit items per package. Set to 0 for unlimited. If a buyer orders more, multiple shipments are created automatically.',
                ),
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
            infoTitle: 'Bulk Free Shipping',
            infoBody: 'When enabled, buyers who order 10 or more units get completely free shipping.\n\nThis is a powerful incentive for wholesale and repeat customers. Stacks with your 3+ and 5+ discount tiers.\n\nNote: At least one delivery tier (Standard, Express, or Same-Day) must be enabled for this to take effect.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildGlassTextField(controller: _additionalItemCostController, label: 'Cost/extra item', prefixText: '\$', keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: _buildGlassTextField(controller: _maxItemsPerShipmentController, label: 'Max per shipment', keyboardType: TextInputType.number, hint: '0 = unlimited')),
            ],
          ),
          _buildTappableInfoHint(
            'What do these multi-item fields mean?',
            'Multi-Item Shipping',
            'Cost per extra item: Additional shipping charge for each item beyond the first (e.g. \$1.50). Set to \$0 if no extra cost.\n\nMax per shipment: Maximum items that fit in one package. Set to 0 for unlimited. If a buyer orders more, multiple shipments are created automatically.\n\nExample: Max 5/shipment + \$1.50/extra → 7 items = 2 shipments, first at base + 4×\$1.50, second at base + 1×\$1.50.',
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
            validator: (v) {
              if (v == null || v.isEmpty) return null; // optional field
              final val = double.tryParse(v);
              if (val == null || val < 0 || val > 100) return '0-100%';
              return null;
            },
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
          if (_selectedSupplierCurrency != 'CAD')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '\u26a0 Supplier cost in $_selectedSupplierCurrency \u2014 margin is approximate until converted to CAD.',
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
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
                    child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(body, style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6)),
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
            Expanded(child: Text(shortText, style: TextStyle(fontSize: 11, color: Colors.grey[500]))),
            Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey[400]),
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
                    // FIX: Validate discount tiers before form validation
                    final discount3 = double.tryParse(_shippingDiscount3Controller.text);
                    final discount5 = double.tryParse(_shippingDiscount5Controller.text);
                    if (discount3 != null && discount5 != null && discount5 < discount3) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('5+ items discount must be ≥ 3+ items discount'),
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
    ),
    );
  }

  // ─── DATA BUILDERS ────────────────────────────────────────────────────

  List<SellerDeliveryOption> _buildDeliveryOptions(AddProductState state) {
    if (state.isDigital) return [];

    // Bug #2: Local-only products need a pickup delivery option
    if (state.isLocalDeliveryOnly) {
      return [
        const SellerDeliveryOption(
          type: 'pickup',
          description: 'Local Pickup',
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
          quantityDiscounts: quantityDiscounts,
          additionalItemCost: additionalItemCost,
          maxItemsPerShipment: maxItems,
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
    final normalized = v.toUpperCase().replaceAll(' ', '').trim();
    final reg = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');
    if (!reg.hasMatch(normalized)) return 'Invalid (A1A 1A1)';
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
