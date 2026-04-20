import 'package:origna_gta/utils/preview_helpers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/responsive_layout.dart';
import 'package:origna_gta/utils/utils.dart';
import 'package:origna_gta/widgets/custom_app_bar.dart';
import 'package:origna_gta/widgets/modern_button.dart';

import 'package:origna_gta/features/profile/address_state.dart';
import 'package:origna_gta/features/profile/address_viewmodel.dart';
import 'package:flutter/widget_previews.dart';

// ─── Flutter Previews ────────────────────────────────────────────────────────

/// Form for adding or editing a shipping address with geocode autocomplete.
class AddEditAddressScreen extends ConsumerStatefulWidget {
  final Address? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  ProviderSubscription<AddressState>? _addressSubscription;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addressViewModelProvider);
    final viewModel = ref.read(addressViewModelProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: DesignTokens.backgroundGradient(isDark: isDark),
      ),
      child: Scaffold(
        appBar: AppBarFactory.simple(
          title: widget.address == null
              ? 'address.add_address'.tr()
              : 'address.edit_address'.tr(),
        ),
        backgroundColor: DesignTokens.transparent,
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
                    _buildSectionTitle(
                      'address.label'.tr(),
                      Icons.label_outlined,
                    ),
                    const SizedBox(height: DesignTokens.spacing12),
                    Wrap(
                      spacing: 10,
                      children:
                          [
                            AddressLabelValues.home,
                            AddressLabelValues.work,
                            AddressLabelValues.other,
                          ].map((label) {
                            final isSelected = state.selectedLabel == label;
                            final displayLabel =
                                label == AddressLabelValues.home
                                ? 'address.home'.tr()
                                : label == AddressLabelValues.work
                                ? 'address.work'.tr()
                                : 'address.other'.tr();
                            return Semantics(
                              button: true,
                              label:
                                  'chip-address-label-${label.toLowerCase()}',
                              selected: isSelected,
                              child: ChoiceChip(
                                label: Text(displayLabel),
                                selected: isSelected,
                                onSelected: (selected) =>
                                    viewModel.setLabel(label),
                                selectedColor: DesignTokens.primary,
                                backgroundColor: isDark
                                    ? DesignTokens.darkSurface
                                    : DesignTokens.white,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? DesignTokens.white
                                      : (isDark
                                            ? DesignTokens.white
                                            : DesignTokens.textPrimary),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radius12,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? DesignTokens.primary
                                        : (isDark
                                              ? DesignTokens.textPrimary
                                              : DesignTokens.outlineVariant),
                                  ),
                                ),
                                elevation: isSelected ? 2 : 0,
                                shadowColor: DesignTokens.primary.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            );
                          }).toList(),
                    ),

                    const SizedBox(height: DesignTokens.spacing24),

                    // Address Details Section
                    _buildSectionTitle(
                      'address.details'.tr(),
                      Icons.location_on_outlined,
                    ),
                    const SizedBox(height: DesignTokens.spacing12),

                    GlassContainer(
                      child: Column(
                        children: [
                          _buildTextField(
                            key: const Key('address_street_field'),
                            controller: _streetController,
                            label: 'address.street'.tr(),
                            icon: Icons.location_on_outlined,
                            onChanged: viewModel.onStreetChanged,
                            validator: (v) => v?.isEmpty ?? true
                                ? 'common.required'.tr()
                                : null,
                          ),
                          if (state.showSuggestions &&
                              state.addressSuggestions.isNotEmpty)
                            Container(
                              key: const Key('address_suggestions'),
                              margin: const EdgeInsets.only(top: 8, bottom: 8),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? DesignTokens.darkSurface
                                    : DesignTokens.white,
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius12,
                                ),
                                boxShadow: DesignTokens.shadowMd,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: state.addressSuggestions.length,
                                itemBuilder: (context, i) {
                                  final s = state.addressSuggestions[i];
                                  return ListTile(
                                    leading: Icon(
                                      Icons.location_on,
                                      color: DesignTokens.primary,
                                      size: 20,
                                    ),
                                    title: Text(
                                      (s['properties']?['formatted']
                                              as String?) ??
                                          '',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? DesignTokens.white
                                            : DesignTokens.textPrimary,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        DesignTokens.radius8,
                                      ),
                                    ),
                                    onTap: () {
                                      viewModel.selectAddress(s);
                                      final props =
                                          s['properties']
                                              as Map<String, dynamic>?;
                                      final street =
                                          (props?['street'] as String?)
                                              ?.trim() ??
                                          '';
                                      final houseNumber =
                                          (props?['housenumber'] as String?)
                                              ?.trim() ??
                                          (props?['house_number'] as String?)
                                              ?.trim() ??
                                          (props?['address_line1'] as String?)
                                              ?.trim() ??
                                          '';
                                      final formatted =
                                          (props?['formatted'] as String?)
                                              ?.trim() ??
                                          '';

                                      final fullStreet =
                                          (houseNumber.isNotEmpty &&
                                              street.isNotEmpty)
                                          ? '$houseNumber $street'
                                          : (street.isNotEmpty
                                                ? street
                                                : formatted);

                                      _streetController.text = fullStreet;
                                      _cityController.text =
                                          (s['properties']?['city']
                                              as String?) ??
                                          '';
                                      _postalCodeController.text =
                                          (s['properties']?['postcode']
                                              as String?) ??
                                          '';
                                    },
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            key: const Key('address_apartment_field'),
                            controller: _apartmentController,
                            label: 'address.apartment_optional'.tr(),
                            icon: Icons.apartment_outlined,
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            key: const Key('address_city_field'),
                            controller: _cityController,
                            label: 'address.city'.tr(),
                            icon: Icons.location_city_outlined,
                            validator: (v) => v?.isEmpty ?? true
                                ? 'common.required'.tr()
                                : null,
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          DropdownButtonFormField<String>(
                            key: ValueKey('country_${state.selectedCountry}'),
                            isExpanded: true,
                            menuMaxHeight:
                                ResponsiveBreakpoints.dropdownMaxHeight(
                                  context,
                                ),
                            initialValue: state.selectedCountry,
                            decoration: InputDecoration(
                              labelText: 'address.country'.tr(),
                              prefixIcon: Icon(
                                Icons.public,
                                color: DesignTokens.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius12,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? DesignTokens.textPrimary
                                      : DesignTokens.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius12,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? DesignTokens.textPrimary
                                      : DesignTokens.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius12,
                                ),
                                borderSide: const BorderSide(
                                  color: DesignTokens.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? DesignTokens.darkSurface
                                  : DesignTokens.white,
                            ),
                            items: [
                              DropdownMenuItem(
                                value: CountryValues.canada,
                                child: Text(CountryValues.canada),
                              ),
                              DropdownMenuItem(
                                value: CountryValues.cuba,
                                child: Text(
                                  '${CountryValues.cuba} (${CountryValues.cubaCode}) — ${'address.maritime_shipping'.tr()}',
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) viewModel.setCountry(v);
                            },
                          ),
                          if (state.selectedCountry == CountryValues.cuba)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: DesignTokens.spacing8,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(
                                  DesignTokens.spacing12,
                                ),
                                decoration: BoxDecoration(
                                  color: DesignTokens.tertiary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    DesignTokens.radius8,
                                  ),
                                  border: Border.all(
                                    color: DesignTokens.tertiary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: DesignTokens.tertiary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'address.cuba_maritime_notice'.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: DesignTokens.tertiary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: DesignTokens.spacing16),
                          DropdownButtonFormField<String>(
                            key: ValueKey(state.selectedProvince),
                            isExpanded: true,
                            menuMaxHeight:
                                ResponsiveBreakpoints.dropdownMaxHeight(
                                  context,
                                ),
                            initialValue: state.selectedProvince,
                            decoration: InputDecoration(
                              labelText: 'address.province'.tr(),
                              prefixIcon: Icon(
                                Icons.map_outlined,
                                color: DesignTokens.primary.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius12,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? DesignTokens.textPrimary
                                      : DesignTokens.outlineVariant,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius12,
                                ),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? DesignTokens.textPrimary
                                      : DesignTokens.outlineVariant,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  DesignTokens.radius12,
                                ),
                                borderSide: const BorderSide(
                                  color: DesignTokens.primary,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? DesignTokens.darkSurface
                                  : DesignTokens.white,
                            ),
                            items:
                                (state.selectedCountry == CountryValues.cuba
                                        ? ProvinceCodeValues.cubaProvinces
                                        : ProvinceCodeValues.all
                                              .where(
                                                (p) =>
                                                    p !=
                                                    ProvinceCodeValues.havana,
                                              )
                                              .toList())
                                    .map(
                                      (code) => DropdownMenuItem(
                                        value: code,
                                        child: Text(
                                          '${ProvinceCodeValues.names[code]} ($code)',
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) => viewModel.setProvince(v!),
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            key: const Key('address_postal_code_field'),
                            controller: _postalCodeController,
                            label: state.selectedCountry == CountryValues.cuba
                                ? 'address.postal_code_cuba'.tr()
                                : 'address.postal_code'.tr(),
                            icon: Icons.markunread_mailbox_outlined,
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'common.required'.tr();
                              }
                              final isCuba =
                                  state.selectedCountry == CountryValues.cuba;
                              if (!isCuba) {
                                final cleaned = v
                                    .replaceAll(' ', '')
                                    .toUpperCase();
                                if (!RegExp(
                                  r'^[A-Z]\d[A-Z]\d[A-Z]\d$',
                                ).hasMatch(cleaned)) {
                                  return 'address.valid_postal'.tr();
                                }
                              } else {
                                final cleaned = v
                                    .replaceAll(' ', '')
                                    .toUpperCase();
                                if (!RegExp(r'^\d{5}$').hasMatch(cleaned)) {
                                  return 'address.valid_postal_cuba'.tr();
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: DesignTokens.spacing16),
                          _buildTextField(
                            key: const Key('address_phone_field'),
                            controller: _phoneController,
                            label: 'address.phone'.tr(),
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'common.required'.tr();
                              }
                              final isCuba =
                                  state.selectedCountry == CountryValues.cuba;
                              final e164 = RegExp(r'^\+[1-9]\d{1,14}$');
                              final trimmed = v.trim();
                              if (!e164.hasMatch(trimmed)) {
                                return 'address.valid_phone'.tr();
                              }
                              if (!isCuba) {
                                final canadian = RegExp(r'^\+1\d{10}$');
                                if (trimmed.startsWith('+1') &&
                                    !canadian.hasMatch(trimmed)) {
                                  return 'address.valid_phone'.tr();
                                }
                              } else {
                                final cuban = RegExp(r'^\+53\d{8}$');
                                if (trimmed.startsWith('+53') &&
                                    !cuban.hasMatch(trimmed)) {
                                  return 'address.valid_phone_cuba'.tr();
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacing16),

                    // Set as default toggle
                    SwitchListTile(
                      value: state.isDefault,
                      onChanged: (v) => viewModel.setDefault(v),
                      title: Text(
                        'address.set_as_default'.tr(),
                        style: TextStyle(
                          color: isDark
                              ? DesignTokens.white
                              : DesignTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      activeThumbColor: DesignTokens.primary,
                      activeTrackColor: DesignTokens.primary.withValues(
                        alpha: 0.5,
                      ),
                      contentPadding: EdgeInsets.zero,
                      tileColor: DesignTokens.transparent,
                    ),

                    const SizedBox(height: DesignTokens.spacing24),

                    ModernButton(
                      key: const Key('btn_save_address'),
                      label: state.isLoading
                          ? 'address.saving'.tr()
                          : 'address.save_address'.tr(),
                      semanticsLabel: 'btn-save-address',
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

  @override
  void dispose() {
    _addressSubscription?.close();
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
    _addressSubscription = ref.listenManual(addressViewModelProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (next.isSuccess) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text('address.saved_success'.tr()),
            backgroundColor: DesignTokens.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
          ),
        );
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: DesignTokens.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radius12),
            ),
          ),
        );
      }
    });
    if (widget.address != null) {
      _streetController.text = widget.address!.street;
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode;
      _apartmentController.text = widget.address!.apartment;
      _phoneController.text = widget.address!.phoneNumber ?? '';
    }
    Future.microtask(
      () => ref
          .read(addressViewModelProvider.notifier)
          .setInitialData(widget.address),
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
              colors: [
                DesignTokens.primary.withValues(alpha: 0.15),
                DesignTokens.secondary.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radius8),
          ),
          child: Icon(icon, size: 18, color: DesignTokens.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'input-address-${label.toLowerCase().replaceAll(' ', '-')}',
      child: TextFormField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
        validator: validator,
        style: TextStyle(
          color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: DesignTokens.primary.withValues(alpha: 0.7))
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            borderSide: BorderSide(
              color: isDark
                  ? DesignTokens.textPrimary
                  : DesignTokens.outlineVariant,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            borderSide: BorderSide(
              color: isDark
                  ? DesignTokens.textPrimary
                  : DesignTokens.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radius12),
            borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
          ),
          filled: true,
          fillColor: isDark ? DesignTokens.darkSurface : DesignTokens.white,
        ),
      ),
    );
  }
}

// === Widget Previews ===

// ═══ Widget Previews ═══

class _PreviewAddressRef extends Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _PreviewAddressViewModel extends AddressViewModel {
  _PreviewAddressViewModel(AddressState previewState)
    : super(_PreviewAddressRef()) {
    state = previewState;
  }
}

final _previewEditableAddress = Address(
  addressId: 'preview-address-1',
  street: '123 Queen St W',
  apartment: 'Unit 804',
  city: 'Toronto',
  state: ProvinceCodeValues.ontario,
  postalCode: 'M5H 2M9',
  country: GeoValues.countryCanada,
  phoneNumber: '647-555-0132',
  label: AddressLabelValues.home,
  isDefault: true,
  latitude: 43.6529,
  longitude: -79.3849,
);

Widget _addEditAddress({Address? address, AddressState? state}) =>
    previewScopeLoggedIn(
      extraOverrides: [
        addressViewModelProvider.overrideWith(
          (ref) => _PreviewAddressViewModel(
            state ??
                AddressState(
                  selectedProvince: ProvinceCodeValues.ontario,
                  selectedLabel: AddressLabelValues.home,
                  latitude: 43.6529,
                  longitude: -79.3849,
                  addressId: address?.addressId,
                  isDefault: address?.isDefault ?? false,
                ),
          ),
        ),
      ],
      child: AddEditAddressScreen(address: address),
    );

// ── Core previews ───────────────────────────────────────────────────────────
@Preview(
  name: 'Manage Address Dark — Mobile',
  group: 'Screens',
  size: Size(390, 844),
)
Widget previewAddEditAddressScreenMobile() =>
    previewMobile(child: _addEditAddress(address: _previewEditableAddress));

@Preview(
  name: 'Manage Address Dark — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddEditAddressScreenDesktop() =>
    previewDesktop(child: _addEditAddress(address: _previewEditableAddress));

@Preview(
  name: 'Manage Address Light — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddEditAddressLightDesktop() => previewDesktop(
  theme: previewLightTheme,
  child: _addEditAddress(address: _previewEditableAddress),
);

@Preview(
  name: 'Add Address Empty — Desktop',
  group: 'Screens',
  size: Size(1280, 800),
)
Widget previewAddAddressEmptyDesktop() => previewDesktop(
  child: _addEditAddress(
    state: const AddressState(
      selectedProvince: ProvinceCodeValues.ontario,
      selectedLabel: AddressLabelValues.home,
    ),
  ),
);
