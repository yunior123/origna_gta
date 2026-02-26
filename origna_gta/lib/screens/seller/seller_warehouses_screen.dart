import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/features/seller/warehouses_viewmodel.dart';
import 'package:origna_gta/models/generated/base_models.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/widgets/modern_loading_indicator.dart';

/// Seller warehouse management screen.
/// Allows sellers to add, edit, and delete shipping locations (warehouses or personal addresses).
/// Accessible from seller profile settings.
class SellerWarehousesScreen extends ConsumerStatefulWidget {
  const SellerWarehousesScreen({super.key});

  static const routeName = '/seller/warehouses';

  @override
  ConsumerState<SellerWarehousesScreen> createState() => _SellerWarehousesScreenState();
}

class _SellerWarehousesScreenState extends ConsumerState<SellerWarehousesScreen> {
  @override
  void initState() {
    super.initState();
    // Listen to state changes for error/success feedback
    ref.listenManual(warehousesViewModelProvider, (prev, next) {
      if (!mounted) return;
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: DesignTokens.error),
        );
        ref.read(warehousesViewModelProvider.notifier).clearStatus();
      } else if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Warehouse saved').tr(), backgroundColor: DesignTokens.success),
        );
        ref.read(warehousesViewModelProvider.notifier).clearStatus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(sellerWarehousesStreamProvider);
    final vmState = ref.watch(warehousesViewModelProvider);

    return Scaffold(
      backgroundColor: DesignTokens.darkBackground,
      appBar: AppBar(
        backgroundColor: DesignTokens.darkBackground,
        title: const Text('Shipping Locations').tr(),
        foregroundColor: DesignTokens.textPrimary,
        actions: [
          if (vmState.isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: ModernLoadingIndicator(size: 20),
            ),
        ],
      ),
      body: warehousesAsync.when(
        loading: () => const Center(child: ModernLoadingIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load locations: $e',
              style: TextStyle(color: DesignTokens.error)),
        ),
        data: (warehouses) => _WarehousesList(
          warehouses: warehouses,
          isActionLoading: vmState.isLoading,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: DesignTokens.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add Location').tr(),
        onPressed: vmState.isLoading ? null : () => _showWarehouseForm(context),
      ),
    );
  }

  void _showWarehouseForm(BuildContext context, {SellerWarehouse? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _WarehouseFormSheet(
        existing: existing,
        onSave: ({
          required String label,
          required String type,
          required String city,
          required String province,
          required String country,
          required bool isDefault,
        }) async {
          // FIX L-01: This legacy callback is never invoked — the form always calls
          // onSaveFull with the complete address map.  Assert so any accidental
          // call surfaces immediately in tests rather than silently dropping a save.
          assert(false, 'onSave should never be called; use onSaveFull instead');
        },
        onSaveFull: ({
          required String label,
          required String type,
          required Map<String, dynamic> addressMap,
          required bool isDefault,
        }) async {
          final vm = ref.read(warehousesViewModelProvider.notifier);
          if (existing == null) {
            await vm.createWarehouse(
              label: label,
              type: type,
              address: _mapToAddress(addressMap),
              isDefault: isDefault,
            );
          } else {
            await vm.updateWarehouse(
              warehouseId: existing.warehouseId,
              label: label,
              type: type,
              address: _mapToAddress(addressMap),
              isDefault: isDefault,
            );
          }
        },
      ),
    );
  }

  /// Convert raw form map back to an Address object
  Address _mapToAddress(Map<String, dynamic> m) => Address(
    street: m[Fields.street] as String? ?? '',
    apartment: m[Fields.apartment] as String? ?? '',
    city: m[Fields.city] as String? ?? '',
    state: m[Fields.state] as String? ?? '',
    postalCode: m[Fields.postalCode] as String? ?? '',
    country: m[Fields.country] as String? ?? '',
    latitude: m[Fields.latitude] as double?,
    longitude: m[Fields.longitude] as double?,
    label: m[Fields.label] as String?,
  );
}

// ---------------------------------------------------------------------------
// Warehouses list
// ---------------------------------------------------------------------------

class _WarehousesList extends ConsumerWidget {
  final List<SellerWarehouse> warehouses;
  final bool isActionLoading;

  const _WarehousesList({required this.warehouses, required this.isActionLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (warehouses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warehouse_outlined, size: 64, color: DesignTokens.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No shipping locations yet',
                style: TextStyle(color: DesignTokens.textSecondary, fontSize: 16),
              ).tr(),
              const SizedBox(height: 8),
              Text(
                'Add a warehouse or personal address to start listing products with multi-location shipping.',
                textAlign: TextAlign.center,
                style: TextStyle(color: DesignTokens.textTertiary, fontSize: 13),
              ).tr(),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: warehouses.length,
      itemBuilder: (context, i) {
        final wh = warehouses[i];
        return _WarehouseCard(
          warehouse: wh,
          isActionLoading: isActionLoading,
          onEdit: () => context
              .findAncestorStateOfType<_SellerWarehousesScreenState>()
              ?._showWarehouseForm(context, existing: wh),
          onDelete: () async {
            final confirmed = await _confirmDelete(context, wh.label);
            if (confirmed == true) {
              await ref.read(warehousesViewModelProvider.notifier).deleteWarehouse(wh.warehouseId);
            }
          },
          onSetDefault: () => ref.read(warehousesViewModelProvider.notifier).updateWarehouse(
            warehouseId: wh.warehouseId,
            isDefault: true,
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, String label) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.darkSurface,
        title: const Text('Delete location?').tr(),
        content: Text('Remove "$label"? Product references to this location will be cleaned up automatically.').tr(),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel').tr(),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.error),
            child: const Text('Delete').tr(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Warehouse card
// ---------------------------------------------------------------------------

class _WarehouseCard extends StatelessWidget {
  final SellerWarehouse warehouse;
  final bool isActionLoading;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _WarehouseCard({
    required this.warehouse,
    required this.isActionLoading,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: DesignTokens.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: warehouse.isDefault
            ? BorderSide(color: DesignTokens.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Color.fromRGBO(102, 126, 234, 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                warehouse.isWarehouse ? Icons.warehouse_outlined : Icons.home_outlined,
                color: DesignTokens.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          warehouse.label,
                          style: TextStyle(
                            color: DesignTokens.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (warehouse.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(102, 126, 234, 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              color: DesignTokens.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ).tr(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    warehouse.typeLabel,
                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 12),
                  ).tr(),
                  const SizedBox(height: 2),
                  Text(
                    warehouse.cityProvince,
                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
                  ),
                  Text(
                    warehouse.address.country,
                    style: TextStyle(color: DesignTokens.textTertiary, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              tooltip: 'Warehouse options',
              color: DesignTokens.darkSurface,
              iconColor: DesignTokens.textSecondary,
              itemBuilder: (_) => [
                if (!warehouse.isDefault)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(children: [
                      const Icon(Icons.star_outline, size: 18),
                      const SizedBox(width: 8),
                      const Text('Set as default').tr(),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    const Icon(Icons.edit_outlined, size: 18),
                    const SizedBox(width: 8),
                    const Text('Edit').tr(),
                  ]),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline, size: 18, color: DesignTokens.error),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: DesignTokens.error)).tr(),
                  ]),
                ),
              ],
              onSelected: (value) {
                if (isActionLoading) return;
                switch (value) {
                  case 'default': onSetDefault(); break;
                  case 'edit': onEdit(); break;
                  case 'delete': onDelete(); break;
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add / Edit form bottom sheet
// ---------------------------------------------------------------------------

typedef _SaveFullCallback = Future<void> Function({
  required String label,
  required String type,
  required Map<String, dynamic> addressMap,
  required bool isDefault,
});

typedef _SaveCallback = Future<void> Function({
  required String label,
  required String type,
  required String city,
  required String province,
  required String country,
  required bool isDefault,
});

class _WarehouseFormSheet extends StatefulWidget {
  final SellerWarehouse? existing;
  final _SaveCallback onSave;
  final _SaveFullCallback onSaveFull;

  const _WarehouseFormSheet({
    this.existing,
    required this.onSave,
    required this.onSaveFull,
  });

  @override
  State<_WarehouseFormSheet> createState() => _WarehouseFormSheetState();
}

class _WarehouseFormSheetState extends State<_WarehouseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _countryCtrl;

  late String _selectedType;
  late bool _isDefault;
  bool _saving = false;

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
    _selectedType = e?.type ?? WarehouseTypeValues.warehouse;
    _isDefault = e?.isDefault ?? false;
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
    setState(() => _saving = true);

    final addressMap = {
      Fields.street: _streetCtrl.text.trim(),
      Fields.city: _cityCtrl.text.trim(),
      Fields.state: _provinceCtrl.text.trim().toUpperCase(),
      Fields.postalCode: _postalCtrl.text.trim().toUpperCase(),
      Fields.country: _countryCtrl.text.trim(),
    };

    try {
      await widget.onSaveFull(
        label: _labelCtrl.text,
        type: _selectedType,
        addressMap: addressMap,
        isDefault: _isDefault,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: DesignTokens.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Location' : 'Add Shipping Location',
                style: TextStyle(
                  color: DesignTokens.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ).tr(),
              const SizedBox(height: 20),

              // Location type selector
              Text('Location Type', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)).tr(),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeChip(
                    label: 'Warehouse',
                    icon: Icons.warehouse_outlined,
                    selected: _selectedType == WarehouseTypeValues.warehouse,
                    onTap: () => setState(() => _selectedType = WarehouseTypeValues.warehouse),
                  ),
                  const SizedBox(width: 8),
                  _TypeChip(
                    label: 'Personal / Home',
                    icon: Icons.home_outlined,
                    selected: _selectedType == WarehouseTypeValues.personal,
                    onTap: () => setState(() => _selectedType = WarehouseTypeValues.personal),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Label
              _Field(
                controller: _labelCtrl,
                label: 'Location Name',
                hint: _selectedType == WarehouseTypeValues.warehouse
                    ? 'e.g. Toronto Warehouse'
                    : 'e.g. Home Office',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),

              // Street
              _Field(
                controller: _streetCtrl,
                label: 'Street Address',
                hint: '123 Main St',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Street is required' : null,
              ),
              const SizedBox(height: 12),

              // City + Province row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _Field(
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'Toronto',
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'City required' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _Field(
                      controller: _provinceCtrl,
                      label: 'Province',
                      hint: 'ON',
                      maxLength: 2,
                      // FIX H-02: Validate against the 13 canonical CA province/territory codes.
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        const validProvinces = {
                          'AB', 'BC', 'MB', 'NB', 'NL', 'NS',
                          'NT', 'NU', 'ON', 'PE', 'QC', 'SK', 'YT',
                        };
                        if (!validProvinces.contains(v.trim().toUpperCase())) {
                          return 'Invalid province code';
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
                      label: 'Postal Code',
                      hint: 'M5V 3A8',
                      maxLength: 7,
                      // FIX H-03: Validate Canadian postal code format (e.g. M5V 3A8 or M5V3A8).
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        final upper = v.trim().toUpperCase();
                        final caPostal = RegExp(r'^[A-Z]\d[A-Z][ -]?\d[A-Z]\d$');
                        if (!caPostal.hasMatch(upper)) return 'Format: A1A 1A1';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Field(
                      controller: _countryCtrl,
                      label: 'Country',
                      hint: 'Canada',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Set as default toggle
              Row(
                children: [
                  Switch(
                    value: _isDefault,
                    onChanged: (v) => setState(() => _isDefault = v),
                    activeThumbColor: DesignTokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set as default shipping location',
                      style: TextStyle(color: DesignTokens.textPrimary, fontSize: 14),
                    ).tr(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const ModernLoadingIndicator(size: 20)
                      : Text(isEdit ? 'Save Changes' : 'Add Location').tr(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Color.fromRGBO(102, 126, 234, 0.15) : DesignTokens.darkSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? DesignTokens.primary : DesignTokens.darkOutline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16,
                color: selected ? DesignTokens.primary : DesignTokens.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? DesignTokens.primary : DesignTokens.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ).tr(),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final int? maxLength;

  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLength: maxLength,
      style: TextStyle(color: DesignTokens.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label.tr(),
        hintText: hint,
        labelStyle: TextStyle(color: DesignTokens.textSecondary),
        hintStyle: TextStyle(color: DesignTokens.textTertiary),
        filled: true,
        fillColor: DesignTokens.darkBackground,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DesignTokens.darkOutline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DesignTokens.darkOutline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: DesignTokens.primary, width: 1.5),
        ),
      ),
    );
  }
}
