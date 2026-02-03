import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/config/supplier_config.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

import '../../features/products/add_product_state.dart';
import '../../features/products/add_product_viewmodel.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
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

  // Supplier Info Controllers (New structured approach)
  final _costController = TextEditingController();
  final _supplierSkuController = TextEditingController();
  final _supplierUrlController = TextEditingController();
  final _supplierShippingDaysController = TextEditingController(text: '7-15');
  final _supplierNotesController = TextEditingController();
  final _customSupplierNameController = TextEditingController(); // For custom suppliers

  // Inventory Config
  final _lowStockThresholdController = TextEditingController(text: '5');

  final _standardDaysController = TextEditingController(text: '5');
  final _standardPriceController = TextEditingController(text: '0.00');
  final _expressDaysController = TextEditingController(text: '2');
  final _expressPriceController = TextEditingController(text: '9.99');
  final _sameDayPriceController = TextEditingController(text: '14.99');
  final _sameDayRadiusController = TextEditingController(text: '50');

  // Quantity-based shipping discount controllers
  final _shippingDiscount3Controller = TextEditingController(); // % off for 3+ items
  final _shippingDiscount5Controller = TextEditingController(); // % off for 5+ items
  final _additionalItemCostController = TextEditingController(text: '0.00');
  final _maxItemsPerShipmentController = TextEditingController(text: '0');

  // Supplier type selection
  String _selectedSupplierType = 'aliexpress';
  // Currency for SUPPLIER COST tracking only (selling price is always CAD)
  String _selectedSupplierCurrency = 'USD';
  bool _hasTracking = false;

  // Inventory config state
  bool _inventoryManaged = true;
  bool _trackQuantity = true;
  bool _allowBackorder = false;

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
  Widget build(BuildContext context) {
    final state = ref.watch(addProductViewModelProvider);
    final viewModel = ref.read(addProductViewModelProvider.notifier);

    ref.listen(addProductViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        _onSuccess();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Add Product'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (CAD)',
                            prefixIcon: Icon(Icons.attach_money_outlined),
                            helperText: 'Price in Canadian Dollars',
                            prefixText: '\$ ',
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Stock', prefixIcon: Icon(Icons.inventory_2_outlined)),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
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
                          decoration: const InputDecoration(labelText: 'Min Order Qty', prefixIcon: Icon(Icons.format_list_numbered)),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          onChanged: (v) => viewModel.setMinimumOrderQuantity(int.tryParse(v) ?? 1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Free Shipping'),
                          value: state.freeShipping,
                          activeThumbColor: const Color(0xFF667EEA),
                          onChanged: viewModel.toggleFreeShipping,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Digital Product (No Shipping)'),
                    subtitle: const Text('Hide shipping options and deliver digitally'),
                    value: state.isDigital,
                    activeThumbColor: const Color(0xFF667EEA),
                    onChanged: viewModel.toggleDigital,
                  ),
                  if (state.isDigital)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('Digital products skip shipping calculation and delivery options.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ),
                  const Text('Delivery Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (!state.isDigital) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Perishable Item'),
                      value: state.isPerishable,
                      activeThumbColor: const Color(0xFF667EEA),
                      onChanged: viewModel.togglePerishable,
                    ),
                    _buildDeliveryOptionCard(
                      title: 'Standard Delivery',
                      isEnabled: state.standardEnabled,
                      onChanged: viewModel.setStandardEnabled,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _standardDaysController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Days'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _standardPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Price (\$)', hintText: '0.00 = Free'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildDeliveryOptionCard(
                      title: 'Express Delivery',
                      isEnabled: state.expressEnabled,
                      onChanged: viewModel.setExpressEnabled,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _expressDaysController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Days'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _expressPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Price (\$)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    _buildDeliveryOptionCard(
                      title: 'Same-Day Delivery',
                      isEnabled: state.sameDayEnabled,
                      onChanged: viewModel.setSameDayEnabled,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _sameDayPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Price (\$)'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _sameDayRadiusController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Radius (km)'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Quantity-Based Shipping Discounts Section
                    const SizedBox(height: 16),
                    _buildQuantityShippingDiscountsSection(viewModel, state),
                  ],
                  const SizedBox(height: 20),
                  const Text('Package & Pickup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (!state.isDigital) ...[
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Local Pickup/Delivery Only'),
                      value: state.isLocalDeliveryOnly,
                      onChanged: viewModel.setLocalDeliveryOnly,
                    ),
                    if (!state.isLocalDeliveryOnly) ...[
                      TextFormField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.scale_outlined)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _lengthController,
                              decoration: const InputDecoration(labelText: 'L'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _widthController,
                              decoration: const InputDecoration(labelText: 'W'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(labelText: 'H'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                    items: productCategories.map((c) => DropdownMenuItem(value: c.categoryId.toString(), child: Text(c.name))).toList(),
                    onChanged: (v) => _categoryController.text = v ?? '',
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taxCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Tax Code (optional)',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                      helperText: 'Stripe Tax Code format: txcd_########',
                    ),
                    validator: (v) => isValidTaxCode(v) ? null : 'Invalid tax code',
                  ),
                  const SizedBox(height: 20),
                  // Supplier/Cost section (for marketplace sellers)
                  ExpansionTile(
                    title: const Text('Supplier Info (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('Track cost, margin & supplier source'),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Supplier Type Dropdown - DYNAMIC from config
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSupplierType,
                              decoration: const InputDecoration(labelText: 'Supplier Platform', prefixIcon: Icon(Icons.store_outlined)),
                              items: getSupplierDropdownItems(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedSupplierType = v ?? 'other';
                                  // Auto-set supplier cost currency based on supplier default
                                  final config = getSupplierConfig(v);
                                  if (config.supportedCurrencies.contains(_selectedSupplierCurrency) == false) {
                                    _selectedSupplierCurrency = config.defaultCurrency;
                                  }
                                });
                              },
                            ),
                            // Show supplier info
                            if (_selectedSupplierType.isNotEmpty) _buildSupplierInfoBadge(_selectedSupplierType),
                            const SizedBox(height: 12),
                            // Custom supplier name field (when 'custom' or 'other' selected)
                            if (getSupplierConfig(_selectedSupplierType).isCustom) ...[
                              TextFormField(
                                controller: _customSupplierNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Custom Supplier Name',
                                  prefixIcon: Icon(Icons.edit),
                                  helperText: 'Enter your supplier name',
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            // IMPORTANT: This is for SUPPLIER COST TRACKING only
                            // The SELLING PRICE above is always in CAD
                            Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Track your supplier cost below. All selling prices are in CAD.',
                                      style: TextStyle(fontSize: 12, color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Cost with Currency - For SUPPLIER COST tracking only
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _costController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Supplier Cost',
                                      prefixIcon: Icon(Icons.payments_outlined),
                                      helperText: 'What you pay supplier',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedSupplierCurrency,
                                    decoration: const InputDecoration(labelText: 'Cost Currency'),
                                    items: getSupplierConfig(
                                      _selectedSupplierType,
                                    ).supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                    onChanged: (v) => setState(() => _selectedSupplierCurrency = v ?? 'USD'),
                                  ),
                                ),
                              ],
                            ),
                            // Margin preview
                            if (_costController.text.isNotEmpty && _priceController.text.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  final cost = double.tryParse(_costController.text) ?? 0;
                                  final price = double.tryParse(_priceController.text) ?? 0;
                                  if (cost > 0 && price > 0) {
                                    final margin = ((price - cost) / price * 100);
                                    final profit = price - cost;
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: margin > 30 ? Colors.green.shade50 : (margin > 15 ? Colors.orange.shade50 : Colors.red.shade50),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: margin > 30 ? Colors.green : (margin > 15 ? Colors.orange : Colors.red)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                const Text('Margin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                                Text(
                                                  '${margin.toStringAsFixed(1)}%',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: margin > 30 ? Colors.green : (margin > 15 ? Colors.orange : Colors.red),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                const Text('Profit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                                Text('\$${profit.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _supplierSkuController,
                              decoration: const InputDecoration(
                                labelText: 'Supplier SKU',
                                prefixIcon: Icon(Icons.qr_code_outlined),
                                helperText: 'Product ID on supplier platform',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _supplierUrlController,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Supplier URL',
                                prefixIcon: Icon(Icons.link_outlined),
                                helperText: 'Link to supplier product page',
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _supplierShippingDaysController,
                                    decoration: const InputDecoration(
                                      labelText: 'Shipping Days',
                                      prefixIcon: Icon(Icons.local_shipping_outlined),
                                      helperText: 'e.g., 7-15',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Has Tracking'),
                                    value: _hasTracking,
                                    activeThumbColor: const Color(0xFF667EEA),
                                    onChanged: (v) => setState(() => _hasTracking = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _supplierNotesController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Internal Notes',
                                prefixIcon: Icon(Icons.note_outlined),
                                helperText: 'Private notes (not shown to buyers)',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Inventory Config section
                  ExpansionTile(
                    title: const Text('Inventory Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('Configure stock tracking behavior'),
                    initiallyExpanded: false,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Manage Inventory'),
                              subtitle: const Text('Turn off for dropship products'),
                              value: _inventoryManaged,
                              activeThumbColor: const Color(0xFF667EEA),
                              onChanged: (v) => setState(() => _inventoryManaged = v),
                            ),
                            if (_inventoryManaged) ...[
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Track Quantity'),
                                subtitle: const Text('Off = unlimited stock'),
                                value: _trackQuantity,
                                activeThumbColor: const Color(0xFF667EEA),
                                onChanged: (v) => setState(() => _trackQuantity = v),
                              ),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Allow Backorders'),
                                subtitle: const Text('Accept orders when out of stock'),
                                value: _allowBackorder,
                                activeThumbColor: const Color(0xFF667EEA),
                                onChanged: (v) => setState(() => _allowBackorder = v),
                              ),
                              TextFormField(
                                controller: _lowStockThresholdController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Low Stock Alert Threshold',
                                  prefixIcon: Icon(Icons.warning_amber_outlined),
                                  helperText: 'Get alerted when stock falls below this',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Product Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(labelText: 'Street Address', prefixIcon: Icon(Icons.location_on_outlined)),
                    onChanged: viewModel.onStreetChanged,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  if (state.showSuggestions && state.addressSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.addressSuggestions.length,
                        itemBuilder: (context, i) {
                          final s = state.addressSuggestions[i];
                          return ListTile(
                            title: Text(s['properties']?['formatted'] ?? ''),
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
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: state.selectedProvince,
                          decoration: const InputDecoration(labelText: 'Province'),
                          items: _provinceNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.key))).toList(),
                          onChanged: (v) => viewModel.setProvince(v!),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _postalCodeController,
                          decoration: const InputDecoration(labelText: 'Postal Code'),
                          textCapitalization: TextCapitalization.characters,
                          validator: _validatePostalCode,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ProductAddImages(imageModels: state.imageModels),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isLoading
                          ? null
                          : () {
                              if (_formKey.currentState!.validate()) {
                                // Build SupplierInfo if any supplier data entered
                                SupplierInfo? supplierInfo;
                                final hasCost = _costController.text.trim().isNotEmpty;
                                final hasSku = _supplierSkuController.text.trim().isNotEmpty;
                                final hasUrl = _supplierUrlController.text.trim().isNotEmpty;

                                if (hasCost || hasSku || hasUrl) {
                                  supplierInfo = SupplierInfo(
                                    type: _selectedSupplierType,
                                    cost: double.tryParse(_costController.text),
                                    currency: _selectedSupplierCurrency, // Supplier cost currency (not selling currency)
                                    supplierSku: hasSku ? _supplierSkuController.text.trim() : null,
                                    supplierUrl: hasUrl ? _supplierUrlController.text.trim() : null,
                                    shippingDays: _supplierShippingDaysController.text.trim().isEmpty ? null : _supplierShippingDaysController.text.trim(),
                                    hasTracking: _hasTracking,
                                    notes: _supplierNotesController.text.trim().isEmpty ? null : _supplierNotesController.text.trim(),
                                  );
                                }

                                // Build InventoryConfig if custom settings
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
                                  // Legacy flat fields (for backward compat)
                                  cost: double.tryParse(_costController.text),
                                  supplierSku: _supplierSkuController.text.trim().isEmpty ? null : _supplierSkuController.text.trim(),
                                  supplierUrl: _supplierUrlController.text.trim().isEmpty ? null : _supplierUrlController.text.trim(),
                                  // NEW: Structured objects
                                  supplier: supplierInfo,
                                  inventory: inventoryConfig,
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Add Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
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
    // Supplier/Cost tracking
    _costController.dispose();
    _supplierSkuController.dispose();
    _supplierUrlController.dispose();
    _supplierShippingDaysController.dispose();
    _supplierNotesController.dispose();
    _customSupplierNameController.dispose();
    // Inventory config
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  Widget _buildDeliveryOptionCard({required String title, required bool isEnabled, required ValueChanged<bool> onChanged, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isEnabled ? const Color(0xFF667EEA) : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(title: Text(title), value: isEnabled, onChanged: onChanged, activeThumbColor: const Color(0xFF667EEA)),
          if (isEnabled)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  List<SellerDeliveryOption> _buildDeliveryOptions(AddProductState state) {
    if (state.isDigital) return [];

    // Build quantity discounts from form inputs
    final quantityDiscounts = <ShippingQuantityDiscount>[];

    final discount3 = double.tryParse(_shippingDiscount3Controller.text);
    if (discount3 != null && discount3 > 0) {
      quantityDiscounts.add(
        ShippingQuantityDiscount(
          minQuantity: 3,
          discountType: 'percent',
          discountValue: discount3,
          label: '${discount3.toStringAsFixed(0)}% off shipping for 3+ items',
        ),
      );
    }

    final discount5 = double.tryParse(_shippingDiscount5Controller.text);
    if (discount5 != null && discount5 > 0) {
      quantityDiscounts.add(
        ShippingQuantityDiscount(
          minQuantity: 5,
          discountType: 'percent',
          discountValue: discount5,
          label: '${discount5.toStringAsFixed(0)}% off shipping for 5+ items',
        ),
      );
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
          // Same-day typically doesn't have bulk discounts
        ),
    ];
  }

  /// Build the quantity-based shipping discounts section
  Widget _buildQuantityShippingDiscountsSection(AddProductViewModel viewModel, AddProductState state) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                const Text('Quantity-Based Shipping Discounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Spacer(),
                Tooltip(
                  message: 'Offer shipping discounts when buyers order multiple items',
                  child: Icon(Icons.info_outline, size: 18, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Encourage bulk orders by offering shipping savings', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            // Discount Tier 1: 3+ items
            _buildShippingDiscountTier(label: '3+ items', controller: _shippingDiscount3Controller, hint: 'e.g., 20 (for 20% off)'),
            const SizedBox(height: 8),
            // Discount Tier 2: 5+ items
            _buildShippingDiscountTier(label: '5+ items', controller: _shippingDiscount5Controller, hint: 'e.g., 50 (for 50% off)'),
            const SizedBox(height: 8),
            // Discount Tier 3: 10+ items - Free Shipping
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('10+ items:', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ),
                Expanded(
                  flex: 3,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Free Shipping', style: TextStyle(fontSize: 13)),
                    value: state.freeShippingAt10Plus,
                    onChanged: viewModel.setFreeShippingAt10Plus,
                    activeThumbColor: Colors.green,
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Per-item additional cost
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _additionalItemCostController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Cost per extra item',
                      hintText: '0.00',
                      prefixText: '\$',
                      helperText: '0 = no extra cost per item',
                      helperStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _maxItemsPerShipmentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max items per shipment',
                      hintText: '0',
                      helperText: '0 = unlimited',
                      helperStyle: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDiscountTier({required String label, required TextEditingController controller, required String hint}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text('$label:', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
        ),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: '% off',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  /// Build supplier info badge showing delivery estimates and region
  Widget _buildSupplierInfoBadge(String supplierId) {
    final config = getSupplierConfig(supplierId);

    final deliveryRange = getSupplierDeliveryRange(supplierId);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(config.icon, size: 18, color: config.color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.displayName,
                  style: TextStyle(fontWeight: FontWeight.w600, color: config.color, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text('${config.region} • $deliveryRange • ${config.country}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          if (config.isInternational)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
              child: const Text(
                'INT\'L',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  void _onSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!'), backgroundColor: Colors.green));
    Navigator.pop(context);
  }

  String? _validatePostalCode(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final reg = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');
    if (!reg.hasMatch(v.toUpperCase().trim())) return 'Invalid (A1A 1A1)';
    return null;
  }
}
