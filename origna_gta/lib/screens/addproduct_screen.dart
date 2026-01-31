import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/constants.dart';
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
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _taxCodeController = TextEditingController();

  final _standardDaysController = TextEditingController(text: '5');
  final _standardPriceController = TextEditingController(text: '0.00');
  final _expressDaysController = TextEditingController(text: '2');
  final _expressPriceController = TextEditingController(text: '9.99');
  final _sameDayPriceController = TextEditingController(text: '14.99');
  final _sameDayRadiusController = TextEditingController(text: '50');

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
                          decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money_outlined)),
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
                  const SizedBox(height: 20),
                  const Text('Delivery Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Perishable Item'),
                    value: state.isPerishable,
                    activeThumbColor: const Color(0xFFFF6B35),
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
                  const SizedBox(height: 20),
                  const Text('Package & Pickup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
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
    _standardDaysController.dispose();
    _standardPriceController.dispose();
    _expressDaysController.dispose();
    _expressPriceController.dispose();
    _sameDayPriceController.dispose();
    _sameDayRadiusController.dispose();
    super.dispose();
  }

  Widget _buildDeliveryOptionCard({required String title, required bool isEnabled, required ValueChanged<bool> onChanged, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border.all(color: isEnabled ? const Color(0xFFFF6B35) : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(title: Text(title), value: isEnabled, onChanged: onChanged, activeThumbColor: const Color(0xFFFF6B35)),
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
    return [
      SellerDeliveryOption(
        speed: DeliverySpeed.standard,
        isEnabled: state.standardEnabled,
        estimatedDays: int.tryParse(_standardDaysController.text) ?? 5,
        price: double.tryParse(_standardPriceController.text) ?? 0.0,
      ),
      SellerDeliveryOption(
        speed: DeliverySpeed.express,
        isEnabled: state.expressEnabled,
        estimatedDays: int.tryParse(_expressDaysController.text) ?? 2,
        price: double.tryParse(_expressPriceController.text) ?? 9.99,
      ),
      SellerDeliveryOption(
        speed: DeliverySpeed.sameDay,
        isEnabled: state.sameDayEnabled,
        estimatedDays: 0,
        price: double.tryParse(_sameDayPriceController.text) ?? 14.99,
        maxRadiusKm: int.tryParse(_sameDayRadiusController.text) ?? 50,
      ),
    ];
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
