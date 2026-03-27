part of '../seller_warehouses_screen.dart';

// ---------------------------------------------------------------------------
// Add / Edit form bottom sheet
// ---------------------------------------------------------------------------

// --- Riverpod state for WarehouseFormSheet ---
final _warehouseFormTypeProvider = StateProvider.autoDispose<String>(
  (ref) => WarehouseTypeValues.warehouse,
);
final _warehouseFormDefaultProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
typedef _SaveFullCallback =
    Future<void> Function({
      required String label,
      required String type,
      required Map<String, dynamic> addressMap,
      required bool isDefault,
    });

typedef _SaveCallback =
    Future<void> Function({
      required String label,
      required String type,
      required String city,
      required String province,
      required String country,
      required bool isDefault,
    });

class _WarehouseFormSheet extends ConsumerStatefulWidget {
  final SellerWarehouse? existing;
  final _SaveCallback onSave;
  final _SaveFullCallback onSaveFull;

  const _WarehouseFormSheet({
    this.existing,
    required this.onSave,
    required this.onSaveFull,
  });

  @override
  ConsumerState<_WarehouseFormSheet> createState() =>
      _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends ConsumerState<_WarehouseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _countryCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?.label ?? '');
    _streetCtrl = TextEditingController(text: e?.address.street ?? '');
    _cityCtrl = TextEditingController(text: e?.address.city ?? '');
    _provinceCtrl = TextEditingController(text: e?.address.state ?? '');
    _postalCtrl = TextEditingController(text: e?.address.postalCode ?? '');
    _countryCtrl = TextEditingController(text: e?.address.country ?? 'Canada');
    // Initialize provider values from existing warehouse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_warehouseFormTypeProvider.notifier).state =
          e?.type ?? WarehouseTypeValues.warehouse;
      ref.read(_warehouseFormDefaultProvider.notifier).state =
          e?.isDefault ?? false;
    });
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedType = ref.read(_warehouseFormTypeProvider);
    final isDefault = ref.read(_warehouseFormDefaultProvider);

    final addressMap = {
      Fields.street: _streetCtrl.text.trim(),
      Fields.city: _cityCtrl.text.trim(),
      Fields.state: _provinceCtrl.text.trim().toUpperCase(),
      Fields.postalCode: _postalCtrl.text.trim().toUpperCase(),
      Fields.country: _countryCtrl.text.trim(),
    };

    await widget.onSaveFull(
      label: _labelCtrl.text,
      type: selectedType,
      addressMap: addressMap,
      isDefault: isDefault,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final selectedType = ref.watch(_warehouseFormTypeProvider);
    final isDefault = ref.watch(_warehouseFormDefaultProvider);
    final saving = ref.watch(
      warehousesViewModelProvider.select((s) => s.isLoading),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit
                    ? 'seller.edit_location'.tr()
                    : 'seller.add_shipping_location'.tr(),
                style: TextStyle(
                  color: isDark ? DesignTokens.white : DesignTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Location type selector
              Text(
                'seller.location_type'.tr(),
                style: TextStyle(
                  color: DesignTokens.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TypeChip(
                    label: 'seller.type_warehouse'.tr(),
                    icon: Icons.warehouse_outlined,
                    selected: selectedType == WarehouseTypeValues.warehouse,
                    onTap: () =>
                        ref.read(_warehouseFormTypeProvider.notifier).state =
                            WarehouseTypeValues.warehouse,
                  ),
                  _TypeChip(
                    label: 'seller.type_personal'.tr(),
                    icon: Icons.home_outlined,
                    selected: selectedType == WarehouseTypeValues.personal,
                    onTap: () =>
                        ref.read(_warehouseFormTypeProvider.notifier).state =
                            WarehouseTypeValues.personal,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Label
              _Field(
                controller: _labelCtrl,
                label: 'seller.location_name'.tr(),
                hint: selectedType == WarehouseTypeValues.warehouse
                    ? 'seller.location_name_hint_warehouse'.tr()
                    : 'seller.location_name_hint_home'.tr(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'seller.name_required'.tr()
                    : null,
              ),
              const SizedBox(height: 12),

              // Street
              _Field(
                controller: _streetCtrl,
                label: 'address.street'.tr(),
                hint: '123 Main St',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'address.street_required'.tr()
                    : null,
              ),
              const SizedBox(height: 12),

              // City + Province row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(
                      controller: _cityCtrl,
                      label: 'address.city'.tr(),
                      hint: 'seller.city_hint'.tr(),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'address.city_required'.tr()
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _Field(
                      controller: _provinceCtrl,
                      label: 'address.province'.tr(),
                      hint: 'ON',
                      maxLength: 2,
                      // FIX H-02: Validate against the 13 canonical CA province/territory codes.
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'common.required'.tr();
                        }
                        const validProvinces = {
                          'AB',
                          'BC',
                          'MB',
                          'NB',
                          'NL',
                          'NS',
                          'NT',
                          'NU',
                          'ON',
                          'PE',
                          'QC',
                          'SK',
                          'YT',
                        };
                        if (!validProvinces.contains(v.trim().toUpperCase())) {
                          return 'address.invalid_province'.tr();
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Postal + Country row
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _postalCtrl,
                      label: 'address.postal_code'.tr(),
                      hint: 'M5V 3A8',
                      maxLength: 7,
                      // FIX H-03: Validate Canadian postal code format (e.g. M5V 3A8 or M5V3A8).
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'common.required'.tr();
                        }
                        final upper = v.trim().toUpperCase();
                        final caPostal = RegExp(
                          r'^[A-Z]\d[A-Z][ -]?\d[A-Z]\d$',
                        );
                        if (!caPostal.hasMatch(upper)) {
                          return 'address.postal_format'.tr();
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(
                      controller: _countryCtrl,
                      label: 'address.country'.tr(),
                      hint: 'seller.country_hint'.tr(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Set as default toggle
              Row(
                children: [
                  Switch(
                    value: isDefault,
                    onChanged: (v) =>
                        ref.read(_warehouseFormDefaultProvider.notifier).state =
                            v,
                    activeThumbColor: DesignTokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'seller.set_default_shipping'.tr(),
                      style: TextStyle(
                        color: isDark
                            ? DesignTokens.white
                            : DesignTokens.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  label: 'btn-warehouse-save',
                  button: true,
                  child: ElevatedButton(
                    onPressed: saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primary,
                      foregroundColor: DesignTokens.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: saving
                        ? const ModernLoadingIndicator(size: 20)
                        : Text(
                            isEdit
                                ? 'common.save'.tr()
                                : 'seller.add_location'.tr(),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
