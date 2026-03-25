part of '../addproduct_screen.dart';

// ============================================================================
// FOOD INFO SECTION — Ingredients, allergens, nutrition facts, storage
// ============================================================================

extension _AddProductFoodInfoSection on _AddProductScreenState {
  /// Build the food information section.
  /// Shown when categoryId == 19 (Groceries) or isPerishable == true.
  Widget buildFoodInfoSection(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return buildSectionCard(
      key: const Key('addproduct_section_food'),
      index: 5, // After supplier (index 4)
      icon: Icons.restaurant_menu_rounded,
      title: 'nutrition.section_title'.tr(),
      subtitle: 'nutrition.form_section_subtitle'.tr(),
      state: state,
      viewModel: viewModel,
      children: [
        // --- Ingredients EN ---
        buildGlassTextField(
          key: const Key('addproduct_ingredients_en'),
          controller: _ingredientsEnController,
          label: 'nutrition.ingredients_en_label'.tr(),
          icon: Icons.list_alt_rounded,
          hint: 'nutrition.ingredients_hint'.tr(),
          maxLines: 3,
          onChanged: (v) => viewModel.setIngredients(
            en: v.isEmpty ? null : v,
            fr: state.ingredientsFr,
          ),
        ),
        const SizedBox(height: 16),

        // --- Ingredients FR ---
        buildGlassTextField(
          key: const Key('addproduct_ingredients_fr'),
          controller: _ingredientsFrController,
          label: 'nutrition.ingredients_fr_label'.tr(),
          icon: Icons.list_alt_rounded,
          hint: 'nutrition.ingredients_hint'.tr(),
          maxLines: 3,
          onChanged: (v) => viewModel.setIngredients(
            en: state.ingredientsEn,
            fr: v.isEmpty ? null : v,
          ),
        ),
        const SizedBox(height: 20),

        // --- Allergens multi-select ---
        _buildChipSection(
          label: 'nutrition.allergens_label'.tr(),
          icon: Icons.warning_amber_rounded,
          values: AllergenValues.all,
          selected: state.selectedAllergens,
          onToggle: viewModel.toggleAllergen,
          translationPrefix: 'nutrition.allergen_',
        ),
        const SizedBox(height: 16),

        // --- May Contain multi-select ---
        _buildChipSection(
          label: 'nutrition.may_contain_label'.tr(),
          icon: Icons.help_outline_rounded,
          values: AllergenValues.all,
          selected: state.selectedMayContainAllergens,
          onToggle: viewModel.toggleMayContainAllergen,
          translationPrefix: 'nutrition.allergen_',
        ),
        const SizedBox(height: 16),

        // --- Dietary Badges multi-select ---
        _buildChipSection(
          label: 'nutrition.dietary_badges_label'.tr(),
          icon: Icons.eco_rounded,
          values: DietaryBadgeValues.all,
          selected: state.selectedDietaryBadges,
          onToggle: viewModel.toggleDietaryBadge,
          translationPrefix: 'nutrition.badge_',
        ),
        const SizedBox(height: 20),

        // --- Nutrition Facts (expandable) ---
        _buildNutritionFactsSubsection(state, viewModel),
        const SizedBox(height: 20),

        // --- Storage Instructions EN ---
        buildGlassTextField(
          key: const Key('addproduct_storage_en'),
          controller: _storageEnController,
          label: 'nutrition.form_storage_en'.tr(),
          icon: Icons.kitchen_rounded,
          hint: 'nutrition.form_storage_hint'.tr(),
          maxLines: 2,
          onChanged: (v) => viewModel.setStorageInstructions(
            en: v.isEmpty ? null : v,
            fr: state.storageInstructionsFr,
          ),
        ),
        const SizedBox(height: 16),

        // --- Storage Instructions FR ---
        buildGlassTextField(
          key: const Key('addproduct_storage_fr'),
          controller: _storageFrController,
          label: 'nutrition.form_storage_fr'.tr(),
          icon: Icons.kitchen_rounded,
          hint: 'nutrition.form_storage_hint'.tr(),
          maxLines: 2,
          onChanged: (v) => viewModel.setStorageInstructions(
            en: state.storageInstructionsEn,
            fr: v.isEmpty ? null : v,
          ),
        ),
        const SizedBox(height: 16),

        // --- Best Before Days ---
        buildGlassTextField(
          key: const Key('addproduct_best_before_days'),
          controller: _bestBeforeDaysController,
          label: 'nutrition.form_best_before_days'.tr(),
          icon: Icons.calendar_today_rounded,
          hint: 'nutrition.form_best_before_hint'.tr(),
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              viewModel.setBestBeforeDays(v.isEmpty ? null : int.tryParse(v)),
        ),
      ],
    );
  }

  Widget _buildChipSection({
    required String label,
    required IconData icon,
    required List<String> values,
    required List<String> selected,
    required void Function(String) onToggle,
    required String translationPrefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: DesignTokens.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: DesignTokens.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: values.map((value) {
            final isSelected = selected.contains(value);
            return FilterChip(
              key: Key('food_chip_${label.hashCode}_$value'),
              label: Text(
                '$translationPrefix$value'.tr(),
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? DesignTokens.white
                      : DesignTokens.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onToggle(value),
              selectedColor: DesignTokens.primary,
              backgroundColor: DesignTokens.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
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

  Widget _buildNutritionFactsSubsection(
    AddProductState state,
    AddProductViewModel viewModel,
  ) {
    return ExpansionTile(
      key: const Key('addproduct_nutrition_expansion'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(top: 8),
      leading: Icon(
        Icons.fact_check_rounded,
        size: 18,
        color: DesignTokens.textSecondary,
      ),
      title: Text(
        'nutrition.nutrition_facts_expand'.tr(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: DesignTokens.textPrimary,
        ),
      ),
      children: [
        // Serving size row
        Row(
          children: [
            Expanded(
              flex: 2,
              child: buildGlassTextField(
                key: const Key('addproduct_serving_size_amount'),
                controller: _servingSizeAmountController,
                label: 'nutrition.form_serving_size_amount'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) => viewModel.updateNutritionField(
                  'servingSizeAmount',
                  int.tryParse(v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                key: const Key('addproduct_serving_size_unit'),
                initialValue: state.servingSizeUnit,
                decoration: InputDecoration(
                  labelText: 'nutrition.form_serving_size_unit'.tr(),
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
                    borderSide: const BorderSide(
                      color: DesignTokens.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  labelStyle: TextStyle(
                    color: DesignTokens.textSecondary,
                    fontSize: 13,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'g', child: Text('g')),
                  DropdownMenuItem(value: 'mL', child: Text('mL')),
                ],
                onChanged: (v) {
                  if (v != null) viewModel.setServingSizeUnit(v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Servings per container
        buildGlassTextField(
          key: const Key('addproduct_servings_per_container'),
          controller: _servingsPerContainerController,
          label: 'nutrition.servings_per_container'.tr(),
          keyboardType: TextInputType.number,
          onChanged: (v) => viewModel.updateNutritionField(
            'servingsPerContainer',
            int.tryParse(v),
          ),
        ),
        const SizedBox(height: 12),

        // Calories
        buildGlassTextField(
          key: const Key('addproduct_calories'),
          controller: _caloriesController,
          label: 'nutrition.form_calories'.tr(),
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              viewModel.updateNutritionField('caloriesKcal', int.tryParse(v)),
        ),
        const SizedBox(height: 12),

        // Fat row: total + saturated
        Row(
          children: [
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_total_fat'),
                controller: _totalFatController,
                label: 'nutrition.form_total_fat'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    viewModel.updateNutritionField('totalFatMg', _gramToMg(v)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_saturated_fat'),
                controller: _saturatedFatController,
                label: 'nutrition.form_saturated_fat'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) => viewModel.updateNutritionField(
                  'saturatedFatMg',
                  _gramToMg(v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Trans fat + cholesterol
        Row(
          children: [
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_trans_fat'),
                controller: _transFatController,
                label: 'nutrition.form_trans_fat'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    viewModel.updateNutritionField('transFatMg', _gramToMg(v)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_cholesterol'),
                controller: _cholesterolController,
                label: 'nutrition.form_cholesterol'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) => viewModel.updateNutritionField(
                  'cholesterolMg',
                  int.tryParse(v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sodium
        buildGlassTextField(
          key: const Key('addproduct_sodium'),
          controller: _sodiumController,
          label: 'nutrition.form_sodium'.tr(),
          keyboardType: TextInputType.number,
          onChanged: (v) =>
              viewModel.updateNutritionField('sodiumMg', int.tryParse(v)),
        ),
        const SizedBox(height: 12),

        // Carbs + fibre
        Row(
          children: [
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_total_carb'),
                controller: _totalCarbController,
                label: 'nutrition.form_total_carbohydrate'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) => viewModel.updateNutritionField(
                  'totalCarbohydrateMg',
                  _gramToMg(v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_fibre'),
                controller: _fibreController,
                label: 'nutrition.form_dietary_fibre'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    viewModel.updateNutritionField('fibreMg', _gramToMg(v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sugars + protein
        Row(
          children: [
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_sugars'),
                controller: _sugarsController,
                label: 'nutrition.form_sugars'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    viewModel.updateNutritionField('sugarsMg', _gramToMg(v)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_protein'),
                controller: _proteinController,
                label: 'nutrition.form_protein'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    viewModel.updateNutritionField('proteinMg', _gramToMg(v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Vitamins + minerals
        Row(
          children: [
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_vitamin_a'),
                controller: _vitaminAController,
                label: 'nutrition.form_vitamin_a'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) => viewModel.updateNutritionField(
                  'vitaminAMcg',
                  int.tryParse(v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_vitamin_c'),
                controller: _vitaminCController,
                label: 'nutrition.form_vitamin_c'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) => viewModel.updateNutritionField(
                  'vitaminCMg',
                  int.tryParse(v),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_calcium'),
                controller: _calciumController,
                label: 'nutrition.form_calcium'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) => viewModel.updateNutritionField(
                  'calciumMg',
                  int.tryParse(v),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: buildGlassTextField(
                key: const Key('addproduct_iron'),
                controller: _ironController,
                label: 'nutrition.form_iron'.tr(),
                keyboardType: TextInputType.number,
                onChanged: (v) =>
                    viewModel.updateNutritionField('ironMg', int.tryParse(v)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Convert gram string input to milligrams for the model.
  int? _gramToMg(String value) {
    final grams = double.tryParse(value);
    if (grams == null) return null;
    return (grams * 1000).round();
  }
}
