part of '../addproduct_screen.dart';

// ============================================================================
// HELPER WIDGETS — Extracted from addproduct_screen.dart for readability
// ============================================================================

class _AddVariantOptionButton extends StatelessWidget {
  final List<String> existingNames;
  final void Function(String name, List<String> values) onAdd;

  const _AddVariantOptionButton({required this.existingNames, required this.onAdd});

  Map<String, List<String>> get _presets => {
    'product.preset_size'.tr(): 'product.preset_size_values'.tr().split(', '),
    'product.preset_color'.tr(): 'product.preset_color_values'.tr().split(', '),
    'product.preset_material'.tr(): 'product.preset_material_values'.tr().split(', '),
  };

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('addproduct_add_variant_option_button'),
      onPressed: () => _showAddDialog(context),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: Text('product.add_variant_option_btn'.tr()),
      style: OutlinedButton.styleFrom(
        foregroundColor: DesignTokens.secondary,
        side: BorderSide(color: DesignTokens.secondary.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final available = _presets.keys.where((k) => !existingNames.contains(k)).toList();
    final nameCtrl = TextEditingController();
    final valuesCtrl = TextEditingController();
    String? selectedPreset;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('product.add_variant_option'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (available.isNotEmpty) ...[
                Text('product.quick_add'.tr(), style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: available.map((preset) {
                    final isSelected = selectedPreset == preset;
                    return ChoiceChip(
                      label: Text(preset),
                      selected: isSelected,
                      onSelected: (v) {
                        setDialogState(() {
                          selectedPreset = v ? preset : null;
                          if (v) {
                            nameCtrl.text = preset;
                            valuesCtrl.text = _presets[preset]!.join(', ');
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const Divider(height: 20),
              ],
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'product.option_name'.tr(), hintText: 'product.eg_size'.tr()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: valuesCtrl,
                decoration: InputDecoration(labelText: 'product.option_values_hint'.tr(), hintText: 'product.eg_size_values'.tr()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr())),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final values = valuesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
                if (name.isNotEmpty && values.isNotEmpty) {
                  onAdd(name, values);
                }
                Navigator.pop(ctx);
              },
              child: Text('common.add'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DigitalTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DigitalTypeCard({super.key, required this.label, required this.icon, required this.selected, required this.onTap});

  // FIX [HIGH] Design-system violation: replaced Theme.of(context).colorScheme with DesignTokens.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: DesignTokens.durationFast,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? DesignTokens.primary.withValues(alpha: 0.08) : DesignTokens.surfaceVariant.withValues(alpha: 0.5),
            border: Border.all(color: selected ? DesignTokens.primary : DesignTokens.outline.withValues(alpha: 0.3), width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? [BoxShadow(color: DesignTokens.primary.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? DesignTokens.primary : DesignTokens.textSecondary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                  color: selected ? DesignTokens.primary : DesignTokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariantOptionCard extends StatelessWidget {
  final String name;
  final List<String> values;
  final VoidCallback onRemove;
  final void Function(String name, List<String> values) onUpdate;

  const _VariantOptionCard({super.key, required this.name, required this.values, required this.onRemove, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.label_rounded, size: 16, color: DesignTokens.secondary),
              const SizedBox(width: 6),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showEditDialog(context),
                child: Icon(Icons.edit_rounded, size: 16, color: DesignTokens.primary),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 16, color: DesignTokens.error),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: values
                .map(
                  (v) => Chip(
                    label: Text(v, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: DesignTokens.surface,
                    side: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: name);
    final valuesCtrl = TextEditingController(text: values.join(', '));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('product.edit_option'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: 'product.option_name'.tr()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: valuesCtrl,
              decoration: InputDecoration(labelText: 'product.option_values_hint'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('common.cancel'.tr())),
          FilledButton(
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newValues = valuesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              if (newName.isNotEmpty && newValues.isNotEmpty) {
                onUpdate(newName, newValues);
              }
              Navigator.pop(ctx);
            },
            child: Text('common.save'.tr()),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      valuesCtrl.dispose();
    });
  }
}

class _VariantRow extends StatelessWidget {
  final Map<String, String> optionValues;
  final double? price;
  final int stockQuantity;
  final String? sku;
  final void Function(double?) onPriceChanged;
  final void Function(int) onStockChanged;
  final void Function(String?) onSkuChanged;

  const _VariantRow({
    super.key,
    required this.optionValues,
    required this.price,
    required this.stockQuantity,
    required this.sku,
    required this.onPriceChanged,
    required this.onStockChanged,
    required this.onSkuChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = optionValues.values.join(' / ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: DesignTokens.darkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DesignTokens.outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: DesignTokens.secondary.withValues(alpha: 0.6), shape: BoxShape.circle),
              ),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: DesignTokens.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: price?.toStringAsFixed(2),
                  decoration: _variantFieldDecoration('product.price_dollar'.tr(), prefixText: '\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  onChanged: (v) => onPriceChanged(double.tryParse(v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: stockQuantity.toString(),
                  decoration: _variantFieldDecoration('product.stock'.tr()),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  onChanged: (v) => onStockChanged(int.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: sku,
                  decoration: _variantFieldDecoration('product.sku'.tr()),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  onChanged: (v) => onSkuChanged(v.trim().isEmpty ? null : v.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Shared compact glass decoration for variant fields.
  static InputDecoration _variantFieldDecoration(String label, {String? prefixText}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      isDense: true,
      filled: true,
      fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: DesignTokens.outline.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: DesignTokens.error),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      labelStyle: const TextStyle(color: DesignTokens.textSecondary, fontSize: 11),
    );
  }
}
