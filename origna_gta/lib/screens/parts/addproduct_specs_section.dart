part of '../addproduct_screen.dart';

// ============================================================================
// SPECS SECTION — Category-aware product specifications form
// ============================================================================

extension _AddProductSpecsSection on _AddProductScreenState {
  /// Build the product specifications section.
  /// Shown when a non-food category is selected (all except cat 19).
  Widget buildSpecsSection(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    final categoryId = int.tryParse(state.selectedCategoryId ?? '') ?? 0;
    final config = getSpecsForCategory(categoryId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputTextColor = isDark
        ? DesignTokens.white
        : DesignTokens.textPrimary;

    return buildSectionCard(
      key: const Key('addproduct_section_specs'),
      index: 5,
      icon: Icons.list_alt_rounded,
      title: 'specs.section_title'.tr(),
      subtitle: 'specs.form_subtitle'.tr(),
      state: state,
      viewModel: viewModel,
      children: [
        // Brand field
        buildGlassTextField(
          key: const Key('spec_brand_field'),
          controller: _specBrandController,
          label: 'specs.brand'.tr(),
          icon: Icons.branding_watermark_rounded,
          hint: 'Samsung, Apple, Nike...',
          onChanged: viewModel.setSpecBrand,
          semanticsLabel: 'input-spec-brand',
        ),
        const SizedBox(height: 12),

        // Color field
        buildGlassTextField(
          key: const Key('spec_color_field'),
          controller: _specColorController,
          label: 'specs.color_label'.tr(),
          icon: Icons.palette_rounded,
          hint: 'Black, White, Navy...',
          onChanged: viewModel.setSpecColor,
          semanticsLabel: 'input-spec-color',
        ),
        const SizedBox(height: 12),

        // Material field
        buildGlassTextField(
          key: const Key('spec_material_field'),
          controller: _specMaterialController,
          label: 'specs.material_label'.tr(),
          icon: Icons.texture_rounded,
          hint: 'Aluminum, Cotton, Leather...',
          onChanged: viewModel.setSpecMaterial,
          semanticsLabel: 'input-spec-material',
        ),
        const SizedBox(height: 20),

        // Category-specific template specs
        if (config != null) ...[
          Text(
            config.categoryName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: inputTextColor,
            ),
          ),
          const SizedBox(height: 12),
          ...config.templates
              .where(
                (t) =>
                    t.key != SpecKeyValues.brand &&
                    t.key != SpecKeyValues.color &&
                    t.key != SpecKeyValues.material,
              )
              .map(
                (template) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSpecTemplateField(
                    template: template,
                    state: state,
                    viewModel: viewModel,
                  ),
                ),
              ),
        ],

        // Custom specs (dynamic add/remove)
        if (state.specEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...state.specEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final spec = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: 'input-add-product-spec-key-$index',
                      child: TextFormField(
                        initialValue: spec[Fields.specKey],
                        decoration: InputDecoration(
                          labelText: 'Key',
                          labelStyle: TextStyle(
                            color: DesignTokens.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.label_outline,
                            size: 18,
                            color: DesignTokens.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DesignTokens.outline.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                        style: TextStyle(color: inputTextColor, fontSize: 14),
                        onChanged: (v) => viewModel.updateSpec(
                          index,
                          v,
                          spec[Fields.specValue] ?? '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Tooltip(
                      message: 'input-add-product-spec-value-$index',
                      child: TextFormField(
                        initialValue: spec[Fields.specValue],
                        decoration: InputDecoration(
                          labelText: 'Value',
                          labelStyle: TextStyle(
                            color: DesignTokens.textSecondary,
                          ),
                          prefixIcon: Icon(
                            Icons.text_fields,
                            size: 18,
                            color: DesignTokens.primary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: DesignTokens.outline.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        ),
                        style: TextStyle(color: inputTextColor, fontSize: 14),
                        onChanged: (v) => viewModel.updateSpec(
                          index,
                          spec[Fields.specKey] ?? '',
                          v,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: DesignTokens.error,
                      size: 20,
                    ),
                    onPressed: () => viewModel.removeSpec(index),
                    tooltip: 'btn-add-product-remove-spec-$index',
                  ),
                ],
              ),
            );
          }),
        ],

        // Add custom spec button
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
            label: 'btn-add-product-add-custom-spec',
            child: TextButton.icon(
              onPressed: viewModel.addSpec,
              icon: Icon(
                Icons.add_rounded,
                size: 18,
                color: DesignTokens.primary,
              ),
              label: Text(
                'specs.add_custom'.tr(),
                style: TextStyle(
                  color: DesignTokens.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecTemplateField({
    required SpecTemplate template,
    required AddProductState state,
    required AddProductViewModel viewModel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputTextColor = isDark
        ? DesignTokens.white
        : DesignTokens.textPrimary;

    // Find existing value in specEntries for this template key
    final existingIndex = state.specEntries.indexWhere(
      (e) => e[Fields.specKey] == template.key,
    );

    if (template.valueType == SpecValueTypeValues.boolean) {
      final currentValue = existingIndex >= 0
          ? state.specEntries[existingIndex]['value'] == 'true'
          : false;
      return buildGlassToggle(
        key: Key('spec_${template.key}_toggle'),
        label: template.labelEn,
        icon: Icons.check_circle_outline,
        value: currentValue,
        onChanged: (v) {
          if (existingIndex >= 0) {
            viewModel.updateSpec(existingIndex, template.key, v.toString());
          } else {
            viewModel.addSpecWithValues(
              template.key,
              v.toString(),
              group: template.group,
              valueType: template.valueType,
              unit: template.unit,
            );
          }
        },
      );
    }

    if (template.options != null && template.options!.isNotEmpty) {
      // Dropdown for predefined options.
      // Use a UniqueKey to force rebuild when state clears — avoids Flutter's
      // "initialValue must match one of items" assertion on stale dropdowns.
      final rawValue = existingIndex >= 0
          ? state.specEntries[existingIndex]['value']
          : null;
      final safeValue = rawValue != null && template.options!.contains(rawValue)
          ? rawValue
          : null;
      return DropdownButtonFormField<String>(
        key: ValueKey('spec_${template.key}_$safeValue'),
        initialValue: safeValue,
        decoration: InputDecoration(
          labelText: template.labelEn,
          labelStyle: TextStyle(color: DesignTokens.textSecondary),
          prefixIcon: Icon(
            Icons.arrow_drop_down_circle_outlined,
            color: DesignTokens.primary,
            size: 20,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: DesignTokens.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
        dropdownColor: DesignTokens.darkCard,
        style: TextStyle(color: inputTextColor, fontSize: 14),
        items: template.options!
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            if (existingIndex >= 0) {
              viewModel.updateSpec(existingIndex, template.key, v);
            } else {
              viewModel.addSpecWithValues(
                template.key,
                v,
                group: template.group,
                valueType: template.valueType,
                unit: template.unit,
              );
            }
          }
        },
      );
    }

    // Text/number input
    return Tooltip(
      message: 'input-add-product-spec-${template.key}',
      child: TextFormField(
        key: Key('spec_${template.key}_field'),
        initialValue: existingIndex >= 0
            ? state.specEntries[existingIndex]['value']
            : null,
        decoration: InputDecoration(
          labelText: template.labelEn,
          labelStyle: TextStyle(color: DesignTokens.textSecondary),
          hintText: template.unit != null ? 'e.g., 16 ${template.unit}' : null,
          suffixText: template.unit,
          prefixIcon: Icon(
            template.valueType == SpecValueTypeValues.number
                ? Icons.numbers_rounded
                : Icons.text_fields,
            size: 18,
            color: DesignTokens.primary,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: DesignTokens.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
        style: TextStyle(color: inputTextColor, fontSize: 14),
        keyboardType: template.valueType == SpecValueTypeValues.number
            ? TextInputType.number
            : TextInputType.text,
        onChanged: (v) {
          if (v.isEmpty && existingIndex >= 0) {
            viewModel.removeSpec(existingIndex);
          } else if (v.isNotEmpty) {
            if (existingIndex >= 0) {
              viewModel.updateSpec(existingIndex, template.key, v);
            } else {
              viewModel.addSpecWithValues(
                template.key,
                v,
                group: template.group,
                valueType: template.valueType,
                unit: template.unit,
              );
            }
          }
        },
        validator: template.isRequired
            ? (v) => v?.isEmpty ?? true ? 'common.required'.tr() : null
            : null,
      ),
    );
  }
}
