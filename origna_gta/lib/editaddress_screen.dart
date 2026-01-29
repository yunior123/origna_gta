import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:origna_gta/utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedProvince = 'ON';
  String? _selectedLabel = 'Home';
  bool _isLoading = false;

  List<Map<String, dynamic>> _addressSuggestions = [];
  bool _showSuggestions = false;
  double? _latitude;
  double? _longitude;
  final List<String> _canadianProvinces = ['AB', 'BC', 'MB', 'NB', 'NL', 'NT', 'NS', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT'];

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
      appBar: AppBar(title: Text(widget.address == null ? 'Add Address' : 'Edit Address')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Canada-only notice
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shipping is currently available within Canada only.',
                        style: TextStyle(color: Colors.blue, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Text('Address Label', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Home', 'Work', 'Other'].map((label) {
                  return ChoiceChip(
                    label: Text(label),
                    selected: _selectedLabel == label,
                    onSelected: (selected) {
                      setState(() => _selectedLabel = selected ? label : null);
                    },
                    selectedColor: const Color(0xFFFF6B35),
                    labelStyle: TextStyle(color: _selectedLabel == label ? Colors.white : Colors.black87),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street Address', prefixIcon: Icon(Icons.location_on_outlined), hintText: 'e.g., 123 Main St'),
                onChanged: _onStreetChanged,
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                        title: Text(formatted ?? 'no suggestion', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        onTap: () => _selectAddress1(suggestion),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apartmentController,
                decoration: const InputDecoration(
                  labelText: 'Apartment, Suite, Unit (Optional)',
                  prefixIcon: Icon(Icons.apartment_outlined),
                  hintText: 'e.g., Apt 4B',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined)),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedProvince,
                decoration: const InputDecoration(labelText: 'Province', prefixIcon: Icon(Icons.map_outlined)),
                items: _canadianProvinces.map((code) {
                  return DropdownMenuItem(value: code, child: Text('${_provinceNames[code]} ($code)'));
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedProvince = value!);
                },
              ),

              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined), hintText: '(416) 555-0123'),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _streetController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.address != null) {
      final p = widget.address!.state.trim();

      if (_canadianProvinces.contains(p)) {
        _selectedProvince = p;
      } else {
        _selectedProvince = null; // 👈 critical
      }

      _streetController.text = widget.address!.street ;
      _cityController.text = widget.address!.city ;
      _postalCodeController.text = widget.address!.postalCode ;
      _apartmentController.text = widget.address!.apartment ;
    } else {
      _selectedProvince = 'ON'; // default for new address
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
      print('Error fetching address suggestions: $e');
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final address = Address(
        street: _streetController.text.trim(),
        apartment: _apartmentController.text.trim(),
        city: _cityController.text.trim(),
        state: _selectedProvince!,
        postalCode: _postalCodeController.text.trim().toUpperCase(),
        country: 'Canada',
        phoneNumber: _phoneController.text.trim(),
        label: _selectedLabel,
        isDefault: true,
        latitude: _latitude,
        longitude: _longitude,
      );

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'address': address.toMap()});

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectAddress1(Map<String, dynamic> suggestion) {
    final details = parseAddressSuggestion(suggestion);

    setState(() {
      _streetController.text = details.street;
      _cityController.text = details.city ;
      _selectedProvince = details.province ;
      _postalCodeController.text = details.postalCode ;
      _latitude = details.latitude;
      _longitude = details.longitude;
      _showSuggestions = false;
      _addressSuggestions.clear();
    });
  }

  String? _validateCanadianPostalCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';

    final cleaned = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();

    final postalCodeRegex = RegExp(r'^[A-Z]\d[A-Z]\d[A-Z]\d$');

    if (!postalCodeRegex.hasMatch(cleaned)) {
      return 'Invalid format (e.g., A1A 1A1)';
    }

    return null;
  }
}

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}