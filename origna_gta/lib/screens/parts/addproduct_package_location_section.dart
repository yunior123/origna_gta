part of '../addproduct_screen.dart';

// ============================================================================
// PACKAGE & LOCATION SECTION — Warehouse selector, address fields, suggestions
// ============================================================================

extension _AddProductPackageLocationSection on _AddProductScreenState {
  Widget buildAddressSuggestions(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return Container(
      key: const Key('addproduct_address_suggestions'),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: DesignTokens.darkCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: DesignTokens.shadowLg,
        border: Border.all(color: DesignTokens.outline.withValues(alpha: 0.2)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: state.addressSuggestions.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: DesignTokens.outlineVariant),
          itemBuilder: (context, i) {
            final s = state.addressSuggestions[i];
            return ListTile(
              dense: true,
              leading: Icon(
                Icons.location_on_rounded,
                size: 18,
                color: DesignTokens.primary,
              ),
              title: Text(
                (s['properties']?['formatted'] as String?) ?? '',
                style: const TextStyle(fontSize: 13),
              ),
              onTap: () {
                viewModel.selectAddress(s);
                final props = s['properties'] as Map<String, dynamic>?;
                final street = (props?['street'] as String?)?.trim() ?? '';
                final houseNumber =
                    (props?['housenumber'] as String?)?.trim() ??
                    (props?['house_number'] as String?)?.trim() ??
                    (props?['address_line1'] as String?)?.trim() ??
                    '';
                final formatted =
                    (props?['formatted'] as String?)?.trim() ?? '';

                final fullStreet = (houseNumber.isNotEmpty && street.isNotEmpty)
                    ? '$houseNumber $street'
                    : (street.isNotEmpty ? street : formatted);

                _streetController.text = fullStreet;
                _cityController.text =
                    (s['properties']?['city'] as String?) ?? '';
                _postalCodeController.text =
                    (s['properties']?['postcode'] as String?) ?? '';
              },
            );
          },
        ),
      ),
    );
  }

  Widget buildWarehouseSelector(
    BuildContext context,
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    final warehousesAsync = ref.watch(sellerWarehousesStreamProvider);

    return warehousesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: ModernLoadingIndicator()),
      ),
      error: (e, _) => buildInfoBanner(
        'product.warehouse_load_error'.tr(namedArgs: {'error': e.toString()}),
        Icons.error_outline_rounded,
        DesignTokens.error,
      ),
      data: (warehouses) {
        if (warehouses.isEmpty) {
          return _buildEmptyWarehouseSection(state, viewModel);
        }
        return _buildWarehouseList(warehouses, state, viewModel);
      },
    );
  }

  Widget _buildEmptyWarehouseSection(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSubSectionHeader(
          'product.ships_from'.tr(),
          Icons.pin_drop_rounded,
        ),
        const SizedBox(height: 8),
        buildInfoBanner(
          'product.warehouse_no_locations_hint'.tr(),
          Icons.info_outline_rounded,
          DesignTokens.info,
        ),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: 'btn-add-product-manage-warehouses',
          child: OutlinedButton.icon(
            key: const Key('addproduct_manage_warehouses_button'),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.sellerWarehouses),
            icon: const Icon(Icons.add_location_alt_rounded, size: 18),
            label: Text('product.warehouse_add_button'.tr()),
            style: OutlinedButton.styleFrom(
              foregroundColor: DesignTokens.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        buildSubSectionHeader(
          'product.warehouse_manual_address'.tr(),
          Icons.edit_location_alt_rounded,
        ),
        const SizedBox(height: 8),
        if (state.addressVerified)
          buildInfoBanner(
            'product.address_verified'.tr(),
            Icons.verified_rounded,
            DesignTokens.success,
          )
        else if (_streetController.text.trim().isNotEmpty &&
            !state.addressVerified)
          buildInfoBanner(
            'product.address_select_from_suggestions'.tr(),
            Icons.warning_amber_rounded,
            DesignTokens.warning,
          ),
        const SizedBox(height: 12),
        buildGlassTextField(
          key: const Key('addproduct_street_field'),
          controller: _streetController,
          label: 'product.street_address'.tr(),
          icon: Icons.home_rounded,
          onChanged: viewModel.onStreetChanged,
          validator: _validateStreet,
          hint: 'product.street_hint'.tr(),
          semanticsLabel: 'input-street',
        ),
        if (state.showSuggestions && state.addressSuggestions.isNotEmpty)
          buildAddressSuggestions(state, viewModel),
        const SizedBox(height: 12),
        buildGlassTextField(
          controller: _apartmentController,
          label: 'product.apartment_unit'.tr(),
          icon: Icons.apartment_rounded,
          hint: 'product.apartment_hint'.tr(),
          semanticsLabel: 'input-apartment',
        ),
        const SizedBox(height: 12),
        buildGlassTextField(
          key: const Key('addproduct_city_field'),
          controller: _cityController,
          label: 'product.city'.tr(),
          validator: _validateCity,
          readOnly: state.addressVerified,
          onChanged: state.addressVerified
              ? null
              : (_) => viewModel.clearCoordinates(),
          semanticsLabel: 'input-city',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: buildGlassDropdown(
                key: const Key('addproduct_province_dropdown'),
                label: 'product.province'.tr(),
                value: state.selectedProvince,
                items: ProvinceCodeValues.names.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.key)),
                    )
                    .toList(),
                onChanged: state.addressVerified
                    ? null
                    : (v) => viewModel.setProvince(v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_postal_code_field'),
                controller: _postalCodeController,
                label: 'product.postal_code'.tr(),
                textCapitalization: TextCapitalization.characters,
                validator: _validatePostalCode,
                readOnly: state.addressVerified,
                onChanged: state.addressVerified
                    ? null
                    : (_) => viewModel.clearCoordinates(),
                    semanticsLabel: 'input-postal-code',
              ),
            ),
          ],
        ),
        if (state.addressVerified) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              button: true,
              label: 'btn-add-product-clear-address',
              child: TextButton.icon(
                key: const Key('addproduct_clear_address_button'),
                onPressed: () {
                  _streetController.clear();
                  _cityController.clear();
                  _postalCodeController.clear();
                  viewModel.clearCoordinates();
                },
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: Text(
                  'product.clear_address'.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWarehouseList(
    List<SellerWarehouse> warehouses,
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            buildSubSectionHeader(
              'product.ships_from'.tr(),
              Icons.warehouse_rounded,
            ),
            const Spacer(),
            Semantics(
              button: true,
              label: 'btn-add-product-manage-warehouses-list',
              child: TextButton.icon(
                key: const Key('addproduct_manage_warehouses_button'),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.sellerWarehouses),
                icon: const Icon(Icons.settings_rounded, size: 14),
                label: Text(
                  'product.warehouse_manage'.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: DesignTokens.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Tooltip(
                message: 'product.warehouse_ships_from_tooltip'.tr(),
                triggerMode: TooltipTriggerMode.tap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: DesignTokens.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'product.warehouse_select_hint'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...warehouses.map((warehouse) {
          final isSelected = state.selectedWarehouseIds.contains(
            warehouse.warehouseId,
          );
          final stockQty = state.warehouseStockMap[warehouse.warehouseId] ?? 0;
          final typeIcon = warehouse.type == WarehouseTypeValues.warehouse
              ? Icons.warehouse_rounded
              : Icons.home_work_rounded;
          return Padding(
            key: Key('addproduct_warehouse_${warehouse.warehouseId}'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? DesignTokens.primary.withValues(alpha: 0.08)
                    : DesignTokens.surfaceVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radius12),
                border: Border.all(
                  color: isSelected
                      ? DesignTokens.primary
                      : DesignTokens.outline,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    key: Key(
                      'addproduct_warehouse_checkbox_${warehouse.warehouseId}',
                    ),
                    value: isSelected,
                    onChanged: (_) => viewModel.toggleWarehouseSelection(
                      warehouse.warehouseId,
                    ),
                    title: Row(
                      children: [
                        Icon(typeIcon, size: 16, color: DesignTokens.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            warehouse.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (warehouse.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: DesignTokens.primary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'product.warehouse_default_label'.tr(),
                              style: TextStyle(
                                fontSize: 10,
                                color: DesignTokens.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${warehouse.address.city}, ${warehouse.address.state} · ${warehouse.address.postalCode}',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textSecondary,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.trailing,
                    checkColor: DesignTokens.white,
                    fillColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? DesignTokens.primary
                          : null,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radius12,
                      ),
                    ),
                  ),
                  if (isSelected) ...[
                    Divider(height: 1, color: DesignTokens.outline),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_rounded,
                            size: 16,
                            color: DesignTokens.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'product.warehouse_stock_at_location'.tr(),
                            style: TextStyle(
                              fontSize: 13,
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: Semantics(
                              label:
                                  'input-add-product-warehouse-stock-${warehouse.warehouseId}',
                              textField: true,
                              child: TextFormField(
                                key: Key(
                                  'addproduct_warehouse_stock_${warehouse.warehouseId}',
                                ),
                                initialValue: stockQty > 0
                                    ? stockQty.toString()
                                    : '',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  hintText: '0',
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: (v) => viewModel.setWarehouseStock(
                                  warehouse.warehouseId,
                                  int.tryParse(v) ?? 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'product.warehouse_units'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              color: DesignTokens.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        if (state.selectedWarehouseIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'product.warehouse_select_required'.tr(),
              style: TextStyle(fontSize: 12, color: DesignTokens.error),
            ),
          ),
        if (state.selectedWarehouseIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_rounded,
                  size: 14,
                  color: DesignTokens.success,
                ),
                const SizedBox(width: 6),
                Text(
                  state.selectedWarehouseIds.length > 1
                      ? 'product.warehouse_total_stock_plural'.tr(
                          namedArgs: {
                            'total': state.warehouseStockMap.values
                                .fold(0, (a, b) => a + b)
                                .toString(),
                            'count': state.selectedWarehouseIds.length
                                .toString(),
                          },
                        )
                      : 'product.warehouse_total_stock'.tr(
                          namedArgs: {
                            'total': state.warehouseStockMap.values
                                .fold(0, (a, b) => a + b)
                                .toString(),
                            'count': state.selectedWarehouseIds.length
                                .toString(),
                          },
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    color: DesignTokens.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
