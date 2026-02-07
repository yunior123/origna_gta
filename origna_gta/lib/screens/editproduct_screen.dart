import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/screens/productaddimages_screen.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';

import '../../features/products/edit_product_state.dart';
import '../../features/products/edit_product_viewmodel.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _streetController;
  late final TextEditingController _apartmentController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _stockController;
  late final TextEditingController _weightController;
  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final TextEditingController _shipDaysController;
  late final TextEditingController _minOrderController;

  // Delivery controllers
  late final TextEditingController _standardDaysController;
  late final TextEditingController _standardPriceController;
  late final TextEditingController _expressDaysController;
  late final TextEditingController _expressPriceController;
  late final TextEditingController _sameDayPriceController;
  late final TextEditingController _sameDayRadiusController;

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
    final state = ref.watch(editProductViewModelProvider(widget.product));
    final viewModel = ref.read(editProductViewModelProvider(widget.product).notifier);

    // Listen for success or error
    ref.listen(editProductViewModelProvider(widget.product), (previous, next) {
      if (next.isSuccess) {
        _onUpdateSuccess();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBarFactory.simple(title: 'Edit Product'),
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
                  _buildSectionTitle('Basic Information'),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Product Name', prefixIcon: Icon(Icons.shopping_bag_outlined)),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money_outlined)),
                          validator: (value) => value?.isEmpty ?? true ? 'Please enter price' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          enabled: !state.isSoldOut,
                          decoration: InputDecoration(
                            labelText: 'Stock',
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            suffixText: state.isSoldOut ? 'Sold Out' : null,
                          ),
                          validator: (value) => !state.isSoldOut && (value == null || value.isEmpty) ? 'Enter quantity' : null,
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    title: const Text('Mark as Sold Out'),
                    value: state.isSoldOut,
                    activeTrackColor: const Color(0xFF667EEA),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (v) {
                      viewModel.toggleSoldOut(v);
                      if (v) _stockController.text = '0';
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Digital Product (No Shipping)'),
                    subtitle: const Text('Hide shipping options and deliver digitally'),
                    value: state.isDigital,
                    activeTrackColor: const Color(0xFF667EEA),
                    contentPadding: EdgeInsets.zero,
                    onChanged: viewModel.toggleDigital,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                    decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                    items: productCategories.map((c) => DropdownMenuItem(value: c.categoryId.toString(), child: Text(c.name))).toList(),
                    onChanged: (v) => setState(() => _categoryController.text = v ?? ''),
                    validator: (v) => v == null ? 'Select category' : null,
                  ),
                  const SizedBox(height: 24),

                  if (!state.isDigital) ...[
                    _buildSectionTitle('Shipping & Delivery'),
                    SwitchListTile(
                      title: const Text('Local Delivery Only'),
                      subtitle: const Text('Restrict to buyers within 50km'),
                      value: state.isLocalDeliveryOnly,
                      activeTrackColor: const Color(0xFF667EEA),
                      contentPadding: EdgeInsets.zero,
                      onChanged: viewModel.toggleLocalDelivery,
                    ),
                    SwitchListTile(
                      title: const Text('Perishable Item'),
                      subtitle: const Text('Food, flowers, etc. (Requires same-day)'),
                      value: state.isPerishable,
                      activeTrackColor: const Color(0xFF667EEA),
                      contentPadding: EdgeInsets.zero,
                      onChanged: viewModel.togglePerishable,
                    ),
                    if (!state.isLocalDeliveryOnly) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.scale_outlined)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _shipDaysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Ship Days', prefixIcon: Icon(Icons.schedule_outlined)),
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
                              decoration: const InputDecoration(labelText: 'L (cm)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _widthController,
                              decoration: const InputDecoration(labelText: 'W (cm)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(labelText: 'H (cm)'),
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
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                              onChanged: (v) => viewModel.setMinimumOrderQuantity(int.tryParse(v) ?? 1),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Free Shipping'),
                              value: state.freeShipping,
                              activeTrackColor: const Color(0xFF667EEA),
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

                  _buildSectionTitle('Product Location'),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(labelText: 'Street Address', prefixIcon: Icon(Icons.location_on_outlined)),
                    onChanged: viewModel.onStreetChanged,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  if (state.showSuggestions && state.addressSuggestions.isNotEmpty) _buildAddressSuggestions(state, viewModel),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: state.selectedProvince,
                          decoration: const InputDecoration(labelText: 'Province'),
                          items: _provinceNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.key))).toList(),
                          onChanged: (v) => viewModel.setProvince(v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(labelText: 'Postal Code', prefixIcon: Icon(Icons.pin_outlined)),
                    validator: _validatePostalCode,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Images'),
                  _buildImageGrid(state, viewModel),
                  const SizedBox(height: 12),
                  ProductAddImages(imageModels: state.newImages),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : () => _handleSave(viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
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
    _shipDaysController.dispose();
    _minOrderController.dispose();
    _standardDaysController.dispose();
    _standardPriceController.dispose();
    _expressDaysController.dispose();
    _expressPriceController.dispose();
    _sameDayPriceController.dispose();
    _sameDayRadiusController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _descriptionController = TextEditingController(text: p.description);
    _priceController = TextEditingController(text: p.price.toString());
    _categoryController = TextEditingController(text: p.categoryId.toString());
    _streetController = TextEditingController(text: p.sellerAddress.street);
    _apartmentController = TextEditingController(text: p.sellerAddress.apartment);
    _cityController = TextEditingController(text: p.sellerAddress.city);
    _postalCodeController = TextEditingController(text: p.sellerAddress.postalCode);
    _stockController = TextEditingController(text: p.stockQuantity.toString());
    _weightController = TextEditingController(text: p.weightKg?.toString() ?? '');
    _lengthController = TextEditingController(text: p.lengthCm?.toString() ?? '');
    _widthController = TextEditingController(text: p.widthCm?.toString() ?? '');
    _heightController = TextEditingController(text: p.heightCm?.toString() ?? '');
    _shipDaysController = TextEditingController(text: p.estimatedShipDays.toString());
    _minOrderController = TextEditingController(text: p.minimumOrderQuantity.toString());

    // Initialize delivery options
    final standardOpt = _findOption(
      p.deliveryOptions,
      'standard',
      const SellerDeliveryOption(type: 'standard', description: 'Standard Delivery', cost: 0.0, estimatedDays: 5),
    );
    final expressOpt = _findOption(
      p.deliveryOptions,
      'express',
      const SellerDeliveryOption(type: 'express', description: 'Express Delivery', cost: 9.99, estimatedDays: 2),
    );
    final sameDayOpt = _findOption(
      p.deliveryOptions,
      'same_day',
      const SellerDeliveryOption(type: 'same_day', description: 'Same Day Delivery', cost: 14.99, estimatedDays: 0),
    );

    _standardDaysController = TextEditingController(text: standardOpt.estimatedDays.toString());
    _standardPriceController = TextEditingController(text: standardOpt.cost.toStringAsFixed(2));
    _expressDaysController = TextEditingController(text: expressOpt.estimatedDays.toString());
    _expressPriceController = TextEditingController(text: expressOpt.cost.toStringAsFixed(2));
    _sameDayPriceController = TextEditingController(text: sameDayOpt.cost.toStringAsFixed(2));
    _sameDayRadiusController = TextEditingController(text: '50');
  }

  Widget _buildAddressSuggestions(EditProductState state, EditProductViewModel viewModel) {
    return Card(
      child: Column(
        children: state.addressSuggestions.map((s) {
          final props = s['properties'] ?? {};
          return ListTile(
            title: Text(props['formatted'] ?? ''),
            onTap: () {
              viewModel.selectAddress(s);
              _streetController.text = props['street'] ?? props['formatted'] ?? '';
              _cityController.text = props['city'] ?? '';
              _postalCodeController.text = props['postcode'] ?? '';
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeliveryOptions(EditProductState state, EditProductViewModel viewModel) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildDeliveryTile(
              'Standard Delivery',
              state.standardEnabled,
              (v) => viewModel.setStandardEnabled(v),
              _standardDaysController,
              _standardPriceController,
              'Days',
            ),
            _buildDeliveryTile(
              'Express Delivery',
              state.expressEnabled,
              (v) => viewModel.setExpressEnabled(v),
              _expressDaysController,
              _expressPriceController,
              'Days',
            ),
            _buildDeliveryTile(
              'Same Day Delivery',
              state.sameDayEnabled,
              (v) => viewModel.setSameDayEnabled(v),
              null,
              _sameDayPriceController,
              'Price (\$)',
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          value: enabled,
          onChanged: onToggle,
          activeThumbColor: const Color(0xFF667EEA),
        ),
        if (enabled)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (daysController != null)
                  Expanded(
                    child: TextFormField(
                      controller: daysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: unitLabel, isDense: true),
                    ),
                  ),
                if (extraController != null)
                  Expanded(
                    child: TextFormField(
                      controller: extraController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: unitLabel, isDense: true),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price (\$)', isDense: true),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildImageGrid(EditProductState state, EditProductViewModel viewModel) {
    if (state.existingImageUrls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.existingImageUrls.length,
        itemBuilder: (context, index) => Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(image: NetworkImage(state.existingImageUrls[index]), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 0,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => viewModel.removeExistingImage(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF667EEA)),
      ),
    );
  }

  SellerDeliveryOption _findOption(List<SellerDeliveryOption> options, String type, SellerDeliveryOption fallback) {
    return options.firstWhere((o) => o.type == type, orElse: () => fallback);
  }

  void _handleSave(EditProductViewModel viewModel) {
    if (!_formKey.currentState!.validate()) return;

    final state = ref.read(editProductViewModelProvider(widget.product));

    // Bug #6: Preserve existing quantityDiscounts/additionalItemCost/maxItemsPerShipment from product
    final existingStandard = widget.product.deliveryOptions.where((o) => o.type == 'standard').firstOrNull;
    final existingExpress = widget.product.deliveryOptions.where((o) => o.type == 'express').firstOrNull;
    final existingQuantityDiscounts = existingStandard?.quantityDiscounts ?? existingExpress?.quantityDiscounts ?? const [];
    final existingAdditionalItemCost = existingStandard?.additionalItemCost ?? existingExpress?.additionalItemCost ?? 0.0;
    final existingMaxItems = existingStandard?.maxItemsPerShipment ?? existingExpress?.maxItemsPerShipment ?? 0;

    List<SellerDeliveryOption> deliveryOptions;
    if (state.isDigital) {
      deliveryOptions = <SellerDeliveryOption>[];
    } else if (state.isLocalDeliveryOnly) {
      // Bug #2: Inject pickup option for local-only products
      deliveryOptions = [
        const SellerDeliveryOption(
          type: 'pickup',
          description: 'Local Pickup',
          estimatedDays: 0,
          cost: 0.0,
        ),
      ];
    } else {
      deliveryOptions = <SellerDeliveryOption>[
        if (state.standardEnabled)
          SellerDeliveryOption(
            type: 'standard',
            description: 'Standard Delivery',
            estimatedDays: int.tryParse(_standardDaysController.text) ?? 5,
            cost: double.tryParse(_standardPriceController.text) ?? 0.0,
            quantityDiscounts: existingQuantityDiscounts,
            additionalItemCost: existingAdditionalItemCost,
            maxItemsPerShipment: existingMaxItems,
          ),
        if (state.expressEnabled)
          SellerDeliveryOption(
            type: 'express',
            description: 'Express Delivery',
            estimatedDays: int.tryParse(_expressDaysController.text) ?? 2,
            cost: double.tryParse(_expressPriceController.text) ?? 9.99,
            quantityDiscounts: existingQuantityDiscounts,
            additionalItemCost: existingAdditionalItemCost,
            maxItemsPerShipment: existingMaxItems,
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

    viewModel.updateProduct(
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
      shipDays: state.isDigital ? 0 : int.tryParse(_shipDaysController.text) ?? 3,
      deliveryOptions: deliveryOptions,
    );
  }

  void _onUpdateSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green));
    Navigator.pop(context, true);
  }

  String? _validatePostalCode(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final reg = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');
    if (!reg.hasMatch(v.toUpperCase().trim())) return 'Invalid (A1A 1A1)';
    return null;
  }
}
