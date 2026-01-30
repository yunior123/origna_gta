import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/productaddimages_screen.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

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
  final _stockController = TextEditingController(text: '1'); // Default to 1
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _shipDaysController = TextEditingController(text: '3');
  final _taxCodeController = TextEditingController(); // Optional
  bool _isLocalDeliveryOnly = false;
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
                  // --- STOCK QUANTITY FIELD ---
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock Quantity', prefixIcon: Icon(Icons.inventory_2_outlined)),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter stock quantity';
                      if (int.tryParse(value) == null || int.parse(value) < 0) return 'Enter a valid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- SHIPPING INFO SECTION ---
                  const Text('Shipping Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: const Text(
                      'Optional: Add dimensions for accurate shipping rates. Required for items shipped nationally.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Local delivery toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Local Delivery Only'),
                    subtitle: const Text('For food/perishables - same day local delivery'),
                    value: _isLocalDeliveryOnly,
                    activeTrackColor: const Color(0xFFFF6B35),
                    onChanged: (value) => setState(() => _isLocalDeliveryOnly = value),
                  ),
                  if (!_isLocalDeliveryOnly) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.scale_outlined), hintText: 'e.g., 0.5'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _shipDaysController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Ship Days', prefixIcon: Icon(Icons.schedule_outlined), hintText: '1-7'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Dimensions (cm)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lengthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Length'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _widthController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Width'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Height'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
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
                  TextFormField(
                    controller: _taxCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Stripe Tax Code (Optional)',
                      prefixIcon: Icon(Icons.receipt_long_outlined),
                      hintText: 'e.g., txcd_10000000',
                      helperText: 'Leave blank to use default category tax settings',
                    ),
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
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
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
    _stockController.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _shipDaysController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }

  // Constants for image validation
  static const int maxImageSize = 10 * 1024 * 1024; // 5MB
  static const int maxImages = 10;
  static const List<String> allowedFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxDimension = 2560; // Max width/height

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate images
    if (_imageModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one product image')));
      return;
    }

    if (_imageModels.length > maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maximum $maxImages images allowed')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final productName = _nameController.text.trim();
      final keywords = generateSearchKeywords(productName);

      final product = ProductModel(
        id: '',
        sellerId: FirebaseAuth.instance.currentUser!.uid,
        name: productName,
        searchKeywords: keywords,
        stockQuantity: int.parse(_stockController.text.trim()),
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
        // Shipping dimensions
        weightKg: _weightController.text.isNotEmpty ? double.tryParse(_weightController.text) : null,
        lengthCm: _lengthController.text.isNotEmpty ? double.tryParse(_lengthController.text) : null,
        widthCm: _widthController.text.isNotEmpty ? double.tryParse(_widthController.text) : null,
        heightCm: _heightController.text.isNotEmpty ? double.tryParse(_heightController.text) : null,
        isLocalDeliveryOnly: _isLocalDeliveryOnly,
        estimatedShipDays: int.tryParse(_shipDaysController.text) ?? 3,
        taxCode: _taxCodeController.text.trim().isNotEmpty ? _taxCodeController.text.trim() : null,
      );

      final productRef = await FirebaseFirestore.instance.collection('products').add(product.toMap());
      final productId = productRef.id;

      // 🔥 FIX: Upload images in parallel with validation
      final uploadResults = await _uploadImagesInParallel(_imageModels, productId);

      final successfulUrls = uploadResults.where((url) => url != null).cast<String>().toList();

      if (successfulUrls.isEmpty) {
        throw Exception('Failed to upload any images');
      }

      // Update product with uploaded image URLs
      await FirebaseFirestore.instance.collection('products').doc(productId).update({'id': productId, 'imageUrls': successfulUrls});

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Product added with ${successfulUrls.length} images'), backgroundColor: Colors.green));
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

  /// Validate and compress image before upload
  Future<Uint8List?> _validateAndCompressImage(Uint8List bytes) async {
    try {
      // Check file size
      if (bytes.length > maxImageSize) {
        throw Exception('Image too large. Max size is ${maxImageSize ~/ (1024 * 1024)}MB');
      }

      // Decode image
      final image = img.decodeImage(bytes);
      if (image == null) {
        throw Exception('Invalid image format');
      }

      // Resize if too large (maintains aspect ratio)
      img.Image resized = image;
      if (image.width > maxDimension || image.height > maxDimension) {
        resized = img.copyResize(image, width: image.width > image.height ? maxDimension : null, height: image.height > image.width ? maxDimension : null);
      }

      // Compress to JPEG with 85% quality
      final compressed = img.encodeJpg(resized, quality: 85);

      return Uint8List.fromList(compressed);
    } catch (e) {
      debugPrint('Image validation error: $e');
      return null;
    }
  }

  /// Upload multiple images in parallel for better performance
  Future<List<String?>> _uploadImagesInParallel(List<ImageModel> imageModels, String productId) async {
    // Validate format and compress all images first
    final validationFutures = imageModels.map((model) async {

      final validated = await _validateAndCompressImage(model.bytes);
      return validated != null ? (model, validated) : null;
    });

    final validatedImages = (await Future.wait(validationFutures)).whereType<(ImageModel, Uint8List)>().toList();

    if (validatedImages.isEmpty) {
      // TODO in this case, seller should not be able to add product, fix
      //       Rejected image with format: blob:http://localhost:63119/0ad21da6-9787-4c1c-9588-db67f94e935a
      // Rejected image with format: blob:http://localhost:63119/32ce5677-01b6-4211-a850-eb2c23809020
      throw Exception('No valid images to upload');
    }

    // Upload all images in parallel
    final uploadFutures = validatedImages.asMap().entries.map((entry) async {
      final index = entry.key;
      final (original, compressed) = entry.value;

      try {
        return await _uploadToCloudflareR2(compressed, productId, index);
      } catch (e) {
        debugPrint('Failed to upload image $index: $e');
        return null;
      }
    });

    return await Future.wait(uploadFutures);
  }

  /// Upload single image to Cloudflare R2 with retry logic
  Future<String?> _uploadToCloudflareR2(Uint8List bytes, String productId, int index) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = "product_${productId}_${index}_$timestamp.jpg";
        final String filePath = "products/$fileName";

        final functions = FirebaseFunctions.instance;
        if (kDebugMode) {
          functions.useFunctionsEmulator('127.0.0.1', 8081);
        }
        // Get presigned URL from Cloud Function
        final result = await functions.httpsCallable('get_r2_presigned_url').call({'fileName': fileName});

        String uploadUrl = result.data['uploadUrl'];

        // Upload with timeout
        final response = await http.put(Uri.parse(uploadUrl), 
        body: bytes, 
        
        
        ).timeout(const Duration(seconds: 30));

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

        // Exponential backoff
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
      final response = await http.get(Uri.parse('https://api.geoapify.com/v1/geocode/autocomplete?text=$value&filter=countrycode:ca&apiKey=$apiKey'));
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

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}


//TODO Upload attempt 1 failed: ClientException: Failed to fetch, uri=https://9b027cd3919483d27f0abeb2090ac626.r2.cloudflarestorage.com/orignagta/products/product_oPBYStxEuBrRi0t9vYhP_0_1769768978790.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=aa9380c4880881c0c93977ee9c01f24a%2F20260130%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20260130T102939Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=1a349400f6c1295f899c81db4838f842efe02654ea7d2cdd8b1ec9e0e7725a6c
// Upload attempt 2 failed: ClientException: Failed to fetch, uri=https://9b027cd3919483d27f0abeb2090ac626.r2.cloudflarestorage.com/orignagta/products/product_oPBYStxEuBrRi0t9vYhP_0_1769768981463.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=aa9380c4880881c0c93977ee9c01f24a%2F20260130%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20260130T102941Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=1b3eb9f6c6811ee845e4c552ff85998f4f79c2a2bd996637f12d50a884f95846
// Upload attempt 3 failed: ClientException: Failed to fetch, uri=https://9b027cd3919483d27f0abeb2090ac626.r2.cloudflarestorage.com/orignagta/products/product_oPBYStxEuBrRi0t9vYhP_0_1769768985550.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=aa9380c4880881c0c93977ee9c01f24a%2F20260130%2Fauto%2Fs3%2Faws4_request&X-Amz-Date=20260130T102945Z&X-Amz-Expires=3600&X-Amz-SignedHeaders=host&X-Amz-Signature=4ee995468595b68688ed63d5cd244eb4cb6a20f0a5d5105ff59b53dc1acd12cf
// Max retries reached for image 0
// 1. Use a server-side upload proxy (recommended)
// Instead of uploading directly from Flutter Web to R2:
// Send image bytes from Flutter Web to your Firebase Function.
// Firebase Function uploads to R2 using boto3 (server-side, no CORS issues).
// Return the permanent URL to the client.
// This is bulletproof and works for all platforms.
// Example Flutter Web:
// final request = http.MultipartRequest(
//   'POST',
//   Uri.parse('https://your-cloud-function/uploadImage'),
// );
// request.files.add(
//   http.MultipartFile.fromBytes('file', imageBytes, filename: 'product.jpg'),
// );
// final response = await request.send();
// Server-side function: uploads to R2 normally (no CORS, no preflight).