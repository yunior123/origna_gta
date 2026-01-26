import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloudflare_r2_uploader/cloudflare_r2_uploader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/productaddimages_screen.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  String _selectedProvince = 'ON';
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  final List<ImageModel> _imageModels = [];
  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _showSuggestions = false;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
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
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    minLines: 2,
                    decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price', prefixIcon: Icon(Icons.attach_money_outlined)),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter price' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                    decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined)),
                    isDense: true,
                    items: productCategories.map((cat) => DropdownMenuItem<String>(value: cat.categoryId.toString(), child: Text(cat.name))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryController.text = value ?? '';
                      });
                    },
                    validator: (value) => (value == null || value.isEmpty) ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text('Product Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(labelText: 'Street Address', prefixIcon: Icon(Icons.location_on_outlined), hintText: 'e.g., 123 Main St'),
                    onChanged: _onStreetChanged,
                    validator: (value) => value?.isEmpty ?? true ? 'Required for shipping calculation' : null,
                  ),
                  if (_showSuggestions && _addressSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _addressSuggestions.length,
                        itemBuilder: (context, index) {
                          final suggestion = _addressSuggestions[index];
                          final formatted = suggestion['properties']?['formatted'] ?? 'no suggestion';

                          return ListTile(
                            leading: const Icon(Icons.location_on, color: Color(0xFFFF6B35)),
                            title: Text(
                              formatted ?? 'No suggestion',
                              style: const TextStyle(color: Colors.black87), // FIX: Added text color
                            ),
                            onTap: () => _selectAddress(suggestion),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apartmentController,
                    decoration: const InputDecoration(labelText: 'Apartment, Suite, Unit (Optional)', prefixIcon: Icon(Icons.apartment_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProvince,
                    decoration: const InputDecoration(labelText: 'Province', prefixIcon: Icon(Icons.map_outlined)),
                    items: _provinceNames.entries.map((entry) {
                      return DropdownMenuItem(value: entry.key, child: Text('${entry.value} (${entry.key})'));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProvince = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(labelText: 'Postal Code', prefixIcon: Icon(Icons.pin_outlined), hintText: 'A1A 1A1'),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      if (value.length == 3 && !value.contains(' ')) {
                        _postalCodeController.text = '$value ';
                        _postalCodeController.selection = TextSelection.fromPosition(TextPosition(offset: _postalCodeController.text.length));
                      }
                    },
                    validator: _validateCanadianPostalCode,
                  ),
                  const SizedBox(height: 20),
                  ProductAddImages(imageModels: _imageModels),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addProduct,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
    super.dispose();
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final product = ProductModel(
        id: '',
        sellerId: FirebaseAuth.instance.currentUser!.uid,
        name: _nameController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        imageUrls: <String>[],
        sellerAddress: Address(
          street: _streetController.text.trim(),
          apartment: _apartmentController.text.trim(),
          city: _cityController.text.trim(),
          state: _selectedProvince,
          postalCode: _postalCodeController.text.trim().toUpperCase(),
          country: 'Canada',
          latitude: _latitude,
          longitude: _longitude,
        ),
        description: _descriptionController.text.trim(),
        categoryId: int.parse(_categoryController.text.trim()),
        dateCreated: Timestamp.now(),
      );
      final productIdMap = await FirebaseFirestore.instance.collection('products').add(product.toMap());
      final productId = productIdMap.id;
      for (var m in _imageModels) {
        final downloadUrl = await _uploadToCloudflareR2(m.bytes, m.url);
        if (downloadUrl != null) {
          await FirebaseFirestore.instance.collection('products').doc(productId).update({
            "id": productId,
            'imageUrls': FieldValue.arrayUnion([downloadUrl]),
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStreetChanged(String value) async {
    if (value.length < 3) {
      setState(() {
        _showSuggestions = false;
        _addressSuggestions = [];
      });
      return;
    }
    try {
      final String apiKey = ConfigService().geoapifyKey;
      final response = await http.get(Uri.parse('https://api.geoapify.com/v1/geocode/autocomplete?text=$value&filter=countrycode:ca&apiKey=$apiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _addressSuggestions = List<Map<String, dynamic>>.from(data['features'] ?? []);
          _showSuggestions = _addressSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error fetching address suggestions: $e');
    }
  }

  void _selectAddress(Map<String, dynamic> suggestion) {
    final details = parseAddressSuggestion(suggestion);

    setState(() {
      _streetController.text = details.street;
      _cityController.text = details.city;
      _selectedProvince = details.province;
      _postalCodeController.text = details.postalCode;
      _latitude = details.latitude;
      _longitude = details.longitude;

      _showSuggestions = false;
      _addressSuggestions = [];
    });
  }

  Future<String?> _uploadToCloudflareR2(Uint8List bytes, path) async {
    try {
      final fileName = "product_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final String filePath = "products/$fileName";

      final result = await FirebaseFunctions.instance.httpsCallable('get_r2_presigned_url').call({'fileName': fileName});

      String uploadUrl = result.data['uploadUrl'];

      final response = await http.put(
        Uri.parse(uploadUrl),
        body: bytes, // The image bytes from your image picker
        headers: {"Content-Type": "image/jpeg"},
      );

      final String permanentUrl = "${ConfigService().imageBaseUrl}/$filePath";

      if (response.statusCode == 200) {
        print("Uploaded successfully to R2!");
        return permanentUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading to Cloudflare R2: $e');
      return null;
    }
  }

  String? _validateCanadianPostalCode(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final postalCodeRegex = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');
    if (!postalCodeRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid format (e.g., A1A 1A1)';
    }
    return null;
  }
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}
