part of '../addproduct_screen.dart';

// ============================================================================
// BASIC INFO SECTION — Category, subcategory, condition selectors
// ============================================================================

extension _AddProductBasicInfoSection on _AddProductScreenState {
  Widget buildCategorySelector(
    AddProductViewModel viewModel,
    AddProductState state,
  ) {
    return DropdownButtonFormField<String>(
      key: const Key('addproduct_category_selector'),
      menuMaxHeight: ResponsiveBreakpoints.dropdownMaxHeight(context),
      initialValue: state.selectedCategoryId,
      decoration: InputDecoration(
        labelText: 'product.category'.tr(),
        prefixIcon: const Icon(Icons.category_rounded, size: 20),
        filled: true,
        fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: DesignTokens.outline.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: DesignTokens.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
      ),
      items: productCategories
          .map(
            (c) => DropdownMenuItem(
              key: Key('category_item_${c.name}'),
              value: c.categoryId.toString(),
              child: Semantics(
                label: 'category-option-${c.categoryId}',
                child: Row(
                  children: [
                    Icon(c.icon, size: 18, color: DesignTokens.primary),
                    const SizedBox(width: 10),
                    Text(c.name.tr()),
                  ],
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (v) {
        viewModel.setCategoryId(v);
        _categoryController.text = v ?? '';
      },
      validator: (v) => v == null ? 'common.required'.tr() : null,
    );
  }

  Widget buildSubcategorySelector(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    final catId = int.tryParse(_categoryController.text) ?? 0;
    final subcategories = SubcategoryConstants.forCategoryId(catId);
    if (subcategories.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String>(
      key: Key('addproduct_subcategory_$catId'),
      menuMaxHeight: ResponsiveBreakpoints.dropdownMaxHeight(context),
      initialValue: state.selectedSubcategory,
      decoration: InputDecoration(
        labelText: 'product.subcategory_optional'.tr(),
        prefixIcon: const Icon(
          Icons.subdirectory_arrow_right_rounded,
          size: 20,
        ),
        filled: true,
        fillColor: DesignTokens.surfaceVariant.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: DesignTokens.outline.withValues(alpha: 0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: DesignTokens.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: DesignTokens.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
      ),
      hint: Text(
        'product.select_subcategory'.tr(),
        style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13),
      ),
      items: subcategories
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: const TextStyle(fontSize: 14)),
            ),
          )
          .toList(),
      onChanged: viewModel.setSubcategory,
    );
  }

  Widget buildConditionSelector(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    const conditions = [
      (ProductConditionValues.newCondition, 'product.condition_new'),
      (ProductConditionValues.likeNew, 'product.condition_like_new'),
      (ProductConditionValues.good, 'product.condition_good'),
      (ProductConditionValues.fair, 'product.condition_fair'),
      (ProductConditionValues.forParts, 'product.condition_for_parts'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.grade_rounded,
              size: 16,
              color: DesignTokens.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              'product.product_condition'.tr(),
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'common.optional'.tr(),
              style: TextStyle(color: DesignTokens.textDisabled, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: conditions.map(((String, String) entry) {
            final (value, labelKey) = entry;
            final selected = state.condition == value;
            return ChoiceChip(
              label: Text(
                labelKey.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? DesignTokens.white : DesignTokens.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: selected,
              onSelected: (_) =>
                  viewModel.setCondition(selected ? null : value),
              selectedColor: DesignTokens.primary,
              backgroundColor: DesignTokens.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selected
                      ? DesignTokens.primary
                      : DesignTokens.outline.withValues(alpha: 0.3),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildFrenchTranslationSection() {
    return AnimatedContainer(
      key: const Key('addproduct_section_french'),
      duration: DesignTokens.durationNormal,
      decoration: BoxDecoration(
        color: DesignTokens.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.outlineVariant),
        boxShadow: DesignTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DesignTokens.paypalNavy, DesignTokens.error],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.translate_rounded,
                    color: DesignTokens.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'product.french_section_title'.tr(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: DesignTokens.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'product.french_section_subtitle'.tr(),
                        style: TextStyle(
                          fontSize: 13,
                          color: DesignTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: DesignTokens.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: DesignTokens.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Loi 96',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: DesignTokens.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 24, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildGlassTextField(
                  key: const Key('product_name_f_field'),
                  controller: _nameFController,
                  label: 'product.name_french'.tr(),
                  icon: Icons.sell_rounded,
                  hint: 'product.name_french_hint'.tr(),
                ),
                const SizedBox(height: 16),
                buildGlassTextField(
                  key: const Key('product_description_f_field'),
                  controller: _descriptionFController,
                  label: 'product.description_french'.tr(),
                  icon: Icons.notes_rounded,
                  hint: 'product.description_french_hint'.tr(),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
