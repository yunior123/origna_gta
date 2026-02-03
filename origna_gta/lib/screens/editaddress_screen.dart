import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import '../features/profile/address_viewmodel.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  final List<String> _canadianProvinces = ['AB', 'BC', 'MB', 'NB', 'NL', 'NT', 'NS', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT'];
  final Map<String, String> _provinceNames = {
    'AB': 'Alberta', 'BC': 'British Columbia', 'MB': 'Manitoba', 'NB': 'New Brunswick',
    'NL': 'Newfoundland and Labrador', 'NT': 'Northwest Territories', 'NS': 'Nova Scotia',
    'NU': 'Nunavut', 'ON': 'Ontario', 'PE': 'Prince Edward Island', 'QC': 'Quebec',
    'SK': 'Saskatchewan', 'YT': 'Yukon',
  };

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _streetController.text = widget.address!.street;
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode;
      _apartmentController.text = widget.address!.apartment;
      _phoneController.text = widget.address!.phoneNumber ?? '';
    }
    Future.microtask(() => ref.read(addressViewModelProvider.notifier).setInitialData(widget.address));
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
  Widget build(BuildContext context) {
    final state = ref.watch(addressViewModelProvider);
    final viewModel = ref.read(addressViewModelProvider.notifier);

    ref.listen(addressViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address saved'), backgroundColor: Colors.green));
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red));
      }
    });

    return Scaffold(
      appBar: AppBarFactory.simple(title: widget.address == null ? 'Add Address' : 'Edit Address'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Address Label', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Home', 'Work', 'Other'].map((label) {
                  return ChoiceChip(
                    label: Text(label),
                    selected: state.selectedLabel == label,
                    onSelected: (selected) => viewModel.setLabel(label),
                    selectedColor: const Color(0xFF667EEA),
                    labelStyle: TextStyle(color: state.selectedLabel == label ? Colors.white : Colors.black87),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street Address', prefixIcon: Icon(Icons.location_on_outlined)),
                onChanged: viewModel.onStreetChanged,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              if (state.showSuggestions && state.addressSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.addressSuggestions.length,
                    itemBuilder: (context, i) {
                      final s = state.addressSuggestions[i];
                      return ListTile(
                        leading: const Icon(Icons.location_on, color: Color(0xFF667EEA)),
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
              const SizedBox(height: 16),
              TextFormField(controller: _apartmentController, decoration: const InputDecoration(labelText: 'Apartment/Suite (Optional)')),
              const SizedBox(height: 16),
              TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'City'), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: state.selectedProvince,
                decoration: const InputDecoration(labelText: 'Province'),
                items: _canadianProvinces.map((code) => DropdownMenuItem(value: code, child: Text('${_provinceNames[code]} ($code)'))).toList(),
                onChanged: (v) => viewModel.setProvince(v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(labelText: 'Postal Code'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number'), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: state.isLoading ? null : () {
                    if (_formKey.currentState!.validate()) {
                      viewModel.saveAddress(
                        street: _streetController.text,
                        apartment: _apartmentController.text,
                        city: _cityController.text,
                        postalCode: _postalCodeController.text,
                        phoneNumber: _phoneController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white),
                  child: state.isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}