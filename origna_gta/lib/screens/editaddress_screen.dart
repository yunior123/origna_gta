import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen(addressViewModelProvider, (previous, next) {
      if (next.isSuccess) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Address saved successfully'),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius12)),
          ),
        );
      }
    });

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[900]!, Colors.grey[800]!]
              : [const Color(0xFFF0F2FF), Colors.white],
        ),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(title: widget.address == null ? 'Add Address' : 'Edit Address'),
        backgroundColor: Colors.transparent,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spacing20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Address Label Section
                    _buildSectionTitle('Address Label', Icons.label_outlined),
                    const SizedBox(height: DesignTokens.spacing12),
                    Wrap(
                      spacing: 10,
                      children: ['Home', 'Work', 'Other'].map((label) {
                        final isSelected = state.selectedLabel == label;
                        return Semantics(
                          button: true,
                          label: 'chip-address-label-${label.toLowerCase()}',
                          selected: isSelected,
                          child: ChoiceChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) => viewModel.setLabel(label),
                          selectedColor: DesignTokens.primary,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.grey[700]),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(DesignTokens.radius12),
                            side: BorderSide(
                              color: isSelected ? DesignTokens.primary : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                            ),
                          ),
                          elevation: isSelected ? 2 : 0,
                          shadowColor: DesignTokens.primary.withValues(alpha: 0.3),
                        ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: DesignTokens.spacing24),

                    // Address Details Section
                    _buildSectionTitle('Address Details', Icons.location_on_outlined),
                    const SizedBox(height: DesignTokens.spacing12),

                    GlassContainer(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _streetController,
                            label: 'Street Address',
                            icon: Icons.location_on_outlined,
                            onChanged: viewModel.onStreetChanged,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          if (state.showSuggestions && state.addressSuggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8, bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[800] : Colors.white,
                                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                boxShadow: DesignTokens.shadowMd,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.addressSuggestions.length,
                                itemBuilder: (context, i) {
                                  final s = state.addressSuggestions[i];
                                  return ListTile(
                                    leading: Icon(Icons.location_on, color: DesignTokens.primary, size: 20),
                                    title: Text(
                                      s['properties']?['formatted'] ?? '',
                                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.grey[800]),
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radius8)),
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
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            controller: _apartmentController,
                            label: 'Apartment/Suite (Optional)',
                            icon: Icons.apartment_outlined,
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            controller: _cityController,
                            label: 'City',
                            icon: Icons.location_city_outlined,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          DropdownButtonFormField<String>(
                            key: ValueKey(state.selectedProvince),
                            initialValue: state.selectedProvince,
                            decoration: InputDecoration(
                              labelText: 'Province',
                              prefixIcon: Icon(Icons.map_outlined, color: DesignTokens.primary.withValues(alpha: 0.7)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                                borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
                              ),
                              filled: true,
                              fillColor: isDark ? Colors.grey[850] : Colors.white,
                            ),
                            items: _canadianProvinces.map((code) => DropdownMenuItem(value: code, child: Text('${_provinceNames[code]} ($code)'))).toList(),
                            onChanged: (v) => viewModel.setProvince(v!),
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            controller: _postalCodeController,
                            label: 'Postal Code',
                            icon: Icons.markunread_mailbox_outlined,
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Phone Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacing32),

                    Semantics(
                      button: true,
                      label: 'btn-save-address',
                      child: ModernButton(
                      label: state.isLoading ? 'Saving...' : 'Save Address',
                      icon: Icons.save_outlined,
                      isLoading: state.isLoading,
                      onPressed: state.isLoading
                          ? null
                          : () {
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
                    ),
                    ),

                    const SizedBox(height: DesignTokens.spacing32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [DesignTokens.primary.withValues(alpha: 0.15), DesignTokens.secondary.withValues(alpha: 0.15)],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Icon(icon, size: 18, color: DesignTokens.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.grey[900]),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      validator: validator,
      style: TextStyle(color: isDark ? Colors.white : Colors.grey[900]),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: DesignTokens.primary.withValues(alpha: 0.7)) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radius12),
          borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
      ),
    );
  }
}