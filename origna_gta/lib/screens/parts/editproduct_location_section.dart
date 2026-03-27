part of '../editproduct_screen.dart';

extension _EditProductLocation on _EditProductScreenState {
  /// Returns the persisted province only when it still exists in the dropdown.
  ///
  /// Flutter's dropdown asserts if the selected value doesn't match exactly
  /// one menu item. Legacy products can contain stale province codes, so those
  /// must be treated as unselected.
  String? _selectedProvinceValue(EditProductState state) {
    return _EditProductScreenState._provinceNames.containsKey(
          state.selectedProvince,
        )
        ? state.selectedProvince
        : null;
  }

  Widget buildLocationSection(
    EditProductState state,
    EditProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('product.product_location'.tr()),
        Semantics(
          label: 'input-edit-product-street-address',
          child: TextFormField(
            controller: _streetController,
            decoration: InputDecoration(
              labelText: 'product.street_address'.tr(),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
            onChanged: viewModel.onStreetChanged,
            validator: (v) =>
                v?.isEmpty ?? true ? 'common.required'.tr() : null,
          ),
        ),
        if (state.showSuggestions && state.addressSuggestions.isNotEmpty)
          _buildAddressSuggestions(state, viewModel),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Semantics(
                label: 'input-edit-product-city',
                child: TextFormField(
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'product.city'.tr(),
                    prefixIcon: const Icon(Icons.location_city_outlined),
                  ),
                  validator: (v) =>
                      v?.isEmpty ?? true ? 'common.required'.tr() : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                menuMaxHeight: ResponsiveBreakpoints.dropdownMaxHeight(context),
                initialValue: _selectedProvinceValue(state),
                decoration: InputDecoration(labelText: 'product.province'.tr()),
                items: _EditProductScreenState._provinceNames.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.key)),
                    )
                    .toList(),
                onChanged: (v) => viewModel.setProvince(v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          label: 'input-edit-product-postal-code',
          child: TextFormField(
            controller: _postalCodeController,
            decoration: InputDecoration(
              labelText: 'product.postal_code'.tr(),
              prefixIcon: const Icon(Icons.pin_outlined),
            ),
            validator: _validatePostalCode,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
