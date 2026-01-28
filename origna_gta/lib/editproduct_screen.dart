import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:origna_gta/productaddimages_screen.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/utils.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
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
  late String _selectedProvince;
  late double? _latitude;
  late double? _longitude;
  bool _isLoading = false;
  bool _isSoldOut = false;
  final List<ImageModel> _newImageModels = [];
  List<String> _existingImageUrls = [];
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
    _selectedProvince = p.sellerAddress.state.isNotEmpty ? p.sellerAddress.state : 'ON';
    _latitude = p.sellerAddress.latitude;
    _longitude = p.sellerAddress.longitude;
    _existingImageUrls = List.from(p.imageUrls);
    _isSoldOut = p.stockQuantity == 0;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter description' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.attach_money_outlined),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter price' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    enabled: !_isSoldOut,
                    decoration: InputDecoration(
                      labelText: 'Stock Quantity',
                      prefixIcon: const Icon(Icons.inventory_2_outlined),
                      suffixText: _isSoldOut ? 'Sold Out' : null,
                    ),
                    validator: (value) {
                      if (_isSoldOut) return null;
                      if (value == null || value.isEmpty) return 'Please enter stock quantity';
                      if (int.tryParse(value) == null || int.parse(value) < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Mark as Sold Out'),
                    subtitle: const Text('This will set stock to 0'),
                    value: _isSoldOut,
                    activeTrackColor: const Color(0xFFFF6B35),
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        _isSoldOut = value;
                        if (value) {
                          _stockController.text = '0';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    isDense: true,
                    items: productCategories
                        .map((cat) => DropdownMenuItem<String>(
                              value: cat.categoryId.toString(),
                              child: Text(cat.name),
                            ))
                        .toList(),
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
                    decoration: const InputDecoration(
                      labelText: 'Street Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      hintText: 'e.g., 123 Main St',
                    ),
                    onChanged: _onStreetChanged,
                    validator: (value) => value?.isEmpty ?? true ? 'Required for shipping calculation' : null,
                  ),
                  if (_showSuggestions && _addressSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
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
                            title: Text(formatted, style: const TextStyle(color: Colors.black87)),
                            onTap: () => _selectAddress(suggestion),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _apartmentController,
                    decoration: const InputDecoration(
                      labelText: 'Apartment, Suite, Unit (Optional)',
                      prefixIcon: Icon(Icons.apartment_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city_outlined),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProvince,
                    decoration: const InputDecoration(
                      labelText: 'Province',
                      prefixIcon: Icon(Icons.map_outlined),
                    ),
                    items: _provinceNames.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text('${entry.value} (${entry.key})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProvince = value!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Postal Code',
                      prefixIcon: Icon(Icons.pin_outlined),
                      hintText: 'A1A 1A1',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (value) {
                      if (value.length == 3 && !value.contains(' ')) {
                        _postalCodeController.text = '$value ';
                        _postalCodeController.selection =
                            TextSelection.fromPosition(TextPosition(offset: _postalCodeController.text.length));
                      }
                    },
                    validator: _validateCanadianPostalCode,
                  ),
                  const SizedBox(height: 20),
                  _buildExistingImages(),
                  const SizedBox(height: 12),
                  const Text('Add New Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ProductAddImages(imageModels: _newImageModels),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  Widget _buildExistingImages() {
    if (_existingImageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Current Images', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _existingImageUrls.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(_existingImageUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _existingImageUrls.removeAt(index);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  static const int maxImageSize = 5 * 1024 * 1024;
  static const int maxImages = 10;
  static const int maxDimension = 2048;

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final totalImages = _existingImageUrls.length + _newImageModels.length;
    if (totalImages == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please have at least one product image')),
      );
      return;
    }

    if (totalImages > maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum $maxImages images allowed')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productName = _nameController.text.trim();
      final keywords = generateSearchKeywords(productName);

      List<String> allImageUrls = List.from(_existingImageUrls);

      // Upload new images if any
      if (_newImageModels.isNotEmpty) {
        final uploadResults = await _uploadImagesInParallel(_newImageModels, widget.product.id);
        final successfulUrls = uploadResults.where((url) => url != null).cast<String>().toList();
        allImageUrls.addAll(successfulUrls);
      }

      // Update product
      await FirebaseFirestore.instance.collection('products').doc(widget.product.id).update({
        'name': productName,
        'searchKeywords': keywords,
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stockQuantity': _isSoldOut ? 0 : int.parse(_stockController.text.trim()),
        'categoryId': int.parse(_categoryController.text.trim()),
        'imageUrls': allImageUrls,
        'sellerAddress': {
          'street': _streetController.text.trim(),
          'apartment': _apartmentController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _selectedProvince,
          'postalCode': _postalCodeController.text.trim().toUpperCase(),
          'country': 'Canada',
          'latitude': _latitude,
          'longitude': _longitude,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Uint8List?> _validateAndCompressImage(Uint8List bytes) async {
    try {
      if (bytes.length > maxImageSize) {
        throw Exception('Image too large. Max size is ${maxImageSize ~/ (1024 * 1024)}MB');
      }

      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      img.Image resized = image;
      if (image.width > maxDimension || image.height > maxDimension) {
        resized = img.copyResize(
          image,
          width: image.width > image.height ? maxDimension : null,
          height: image.height > image.width ? maxDimension : null,
        );
      }

      final compressed = img.encodeJpg(resized, quality: 85);
      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Image validation error: $e');
      return null;
    }
  }

  Future<List<String?>> _uploadImagesInParallel(
    List<ImageModel> imageModels,
    String productId,
  ) async {
    final validationFutures = imageModels.map((model) async {
      final validated = await _validateAndCompressImage(model.bytes);
      return validated != null ? (model, validated) : null;
    });

    final validatedImages = (await Future.wait(validationFutures)).whereType<(ImageModel, Uint8List)>().toList();

    if (validatedImages.isEmpty) {
      throw Exception('No valid images to upload');
    }

    final uploadFutures = validatedImages.asMap().entries.map((entry) async {
      final index = entry.key;
      final (original, compressed) = entry.value;

      try {
        return await _uploadToCloudflareR2(compressed, productId, index + _existingImageUrls.length);
      } catch (e) {
        debugPrint('Failed to upload image $index: $e');
        return null;
      }
    });

    return await Future.wait(uploadFutures);
  }

  Future<String?> _uploadToCloudflareR2(
    Uint8List bytes,
    String productId,
    int index,
  ) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = "product_${productId}_${index}_$timestamp.jpg";
        final String filePath = "products/$fileName";

        final result =
            await FirebaseFunctions.instance.httpsCallable('get_r2_presigned_url').call({'fileName': fileName});

        String uploadUrl = result.data['uploadUrl'];

        final response = await http
            .put(
              Uri.parse(uploadUrl),
              body: bytes,
              headers: {"Content-Type": "image/jpeg"},
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final String permanentUrl = "${ConfigService().imageBaseUrl}/$filePath";
          debugPrint("Uploaded image $index successfully to R2!");
          return permanentUrl;
        } else {
          throw Exception('Upload failed with status ${response.statusCode}');
        }
      } catch (e) {
        attempt++;
        debugPrint('Upload attempt $attempt failed: $e');

        if (attempt >= maxRetries) {
          debugPrint('Max retries reached for image $index');
          return null;
        }

        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }

    return null;
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
      final response = await http.get(
        Uri.parse('https://api.geoapify.com/v1/geocode/autocomplete?text=$value&filter=countrycode:ca&apiKey=$apiKey'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _addressSuggestions = List<Map<String, dynamic>>.from(data['features'] ?? []);
          _showSuggestions = _addressSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('Error fetching address suggestions: $e');
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

  String? _validateCanadianPostalCode(String? value) {
    if (value == null || value.isEmpty) return 'Required';
    final postalCodeRegex = RegExp(r'^[A-Z]\d[A-Z] \d[A-Z]\d$');
    if (!postalCodeRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid format (e.g., A1A 1A1)';
    }
    return null;
  }
}
