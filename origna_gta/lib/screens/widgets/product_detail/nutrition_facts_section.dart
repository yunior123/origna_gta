import 'package:flutter/material.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/design_tokens.dart';
import 'package:origna_gta/utils/nutrition_helper.dart';
import 'package:origna_gta/widgets/modern_card.dart';

// ============================================================================
// NUTRITION COLORS — Domain-specific, NOT in DesignTokens
// ============================================================================

class _NutritionColors {
  static Color fopBackground = DesignTokens.error.withValues(alpha: 0.12);
  static Color fopBorder = DesignTokens.error.withValues(alpha: 0.3);
  static Color allergenConfirmedBg = DesignTokens.error.withValues(alpha: 0.15);
  static Color allergenConfirmedFg = DesignTokens.error;
  static Color allergenMayContainBg = DesignTokens.warning.withValues(
    alpha: 0.15,
  );
  static Color allergenMayContainFg = DesignTokens.warning;
  static Color dietaryPositiveBg = DesignTokens.success.withValues(alpha: 0.12);
  static Color dietaryPositiveFg = DesignTokens.success;
  static Color thickDivider = Colors.white.withValues(alpha: 0.3);
  static Color thinDivider = Colors.white.withValues(alpha: 0.08);
  static Color subNutrientText = Colors.white.withValues(alpha: 0.7);
  static Color footnoteText = Colors.white.withValues(alpha: 0.55);
}

// ============================================================================
// ALLERGEN ICON MAPPING
// ============================================================================

IconData _allergenIcon(String allergen) {
  return switch (allergen) {
    AllergenValues.peanuts || AllergenValues.treeNuts => Icons.eco,
    AllergenValues.milk => Icons.water_drop,
    AllergenValues.eggs => Icons.egg_outlined,
    AllergenValues.wheat => Icons.grass,
    AllergenValues.soy => Icons.spa,
    AllergenValues.fish => Icons.set_meal,
    AllergenValues.crustaceans => Icons.pest_control,
    AllergenValues.sesame => Icons.grain,
    AllergenValues.mustard => Icons.local_fire_department,
    AllergenValues.sulphites => Icons.science,
    _ => Icons.warning_amber_rounded,
  };
}

String _allergenDisplayName(String allergen) {
  return switch (allergen) {
    AllergenValues.eggs => 'Eggs',
    AllergenValues.milk => 'Milk',
    AllergenValues.mustard => 'Mustard',
    AllergenValues.peanuts => 'Peanuts',
    AllergenValues.crustaceans => 'Crustaceans',
    AllergenValues.fish => 'Fish',
    AllergenValues.sesame => 'Sesame',
    AllergenValues.soy => 'Soy',
    AllergenValues.sulphites => 'Sulphites',
    AllergenValues.treeNuts => 'Tree Nuts',
    AllergenValues.wheat => 'Wheat',
    _ => allergen,
  };
}

String _dietaryBadgeDisplayName(String badge) {
  return switch (badge) {
    DietaryBadgeValues.organic => 'Organic',
    DietaryBadgeValues.vegan => 'Vegan',
    DietaryBadgeValues.vegetarian => 'Vegetarian',
    DietaryBadgeValues.halal => 'Halal',
    DietaryBadgeValues.kosher => 'Kosher',
    DietaryBadgeValues.glutenFree => 'Gluten-Free',
    DietaryBadgeValues.nonGmo => 'Non-GMO',
    DietaryBadgeValues.dairyFree => 'Dairy-Free',
    DietaryBadgeValues.nutFree => 'Nut-Free',
    DietaryBadgeValues.sugarFree => 'Sugar-Free',
    _ => badge,
  };
}

// ============================================================================
// NUTRITION FACTS SECTION — Main widget
// ============================================================================

/// Displays food nutrition info as collapsible accordion sections.
///
/// Only renders if product has [NutritionFacts] or [FoodMetadata].
/// Layout: FOP Banner → Ingredients Card → Nutrition Facts Card → Storage Card.
class NutritionFactsSection extends StatelessWidget {
  final Product product;
  const NutritionFactsSection({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final nf = product.nutritionFacts;
    final fm = product.foodMetadata;

    if (!NutritionHelper.hasAnyFoodData(nf, fm)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FOP Warning Banner (above all cards)
        if (fm != null &&
            nf != null &&
            (fm.fopHighSodium || fm.fopHighSugars || fm.fopHighSaturatedFat))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FopWarningBanner(foodMetadata: fm),
          ),

        // Section 1: Ingredients + Allergens + Dietary Badges
        if (fm != null &&
            (fm.ingredientsEn != null ||
                fm.allergens.isNotEmpty ||
                fm.dietaryBadges.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _IngredientsCard(foodMetadata: fm),
          ),

        // Section 2: Nutrition Facts Table
        if (nf != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NutritionFactsCard(nutritionFacts: nf),
          ),

        // Section 3: Storage & Handling
        if (fm != null &&
            (fm.storageInstructionsEn != null || fm.bestBeforeDays != null))
          _StorageCard(foodMetadata: fm),
      ],
    );
  }
}

// ============================================================================
// FOP WARNING BANNER
// ============================================================================

class _FopWarningBanner extends StatelessWidget {
  final FoodMetadata foodMetadata;
  const _FopWarningBanner({required this.foodMetadata});

  @override
  Widget build(BuildContext context) {
    final labels = NutritionHelper.getFopWarningLabels(foodMetadata);
    if (labels.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'Health Canada warning: High in ${labels.join(', ')}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _NutritionColors.fopBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _NutritionColors.fopBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FopHexagonIcon(size: 20, color: DesignTokens.error),
                const SizedBox(width: 8),
                Text(
                  'Health Canada Warning',
                  style: TextStyle(
                    color: DesignTokens.error,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: labels
                  .map(
                    (label) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: DesignTokens.error.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FopHexagonIcon(size: 14, color: DesignTokens.white),
                          const SizedBox(width: 4),
                          Text(
                            'High in $label',
                            style: const TextStyle(
                              color: DesignTokens.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// FOP HEXAGON ICON — CustomPainter
// ============================================================================

class _FopHexagonIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _FopHexagonIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _HexagonPainter(color: color)),
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  _HexagonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) =>
      color != oldDelegate.color;
}

// ============================================================================
// INGREDIENTS CARD
// ============================================================================

class _IngredientsCard extends StatelessWidget {
  final FoodMetadata foodMetadata;
  const _IngredientsCard({required this.foodMetadata});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(
            Icons.list_alt_rounded,
            size: 20,
            color: DesignTokens.primary,
          ),
          title: const Text(
            'Ingredients',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DesignTokens.white,
            ),
          ),
          iconColor: DesignTokens.textSecondary,
          collapsedIconColor: DesignTokens.textSecondary,
          children: [
            // Ingredients text
            if (foodMetadata.ingredientsEn != null) ...[
              Semantics(
                label: 'Ingredients: ${foodMetadata.ingredientsEn}',
                child: Text(
                  foodMetadata.ingredientsEn!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
              ),
              if (foodMetadata.ingredientsFr != null) ...[
                const SizedBox(height: 8),
                Text(
                  foodMetadata.ingredientsFr!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _NutritionColors.subNutrientText,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],

            // Allergen badges
            if (foodMetadata.allergens.isNotEmpty ||
                foodMetadata.mayContainAllergens.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...foodMetadata.allergens.map(
                    (a) => _AllergenBadge(allergen: a, isConfirmed: true),
                  ),
                  ...foodMetadata.mayContainAllergens.map(
                    (a) => _AllergenBadge(allergen: a, isConfirmed: false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Dietary badges
            if (foodMetadata.dietaryBadges.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: foodMetadata.dietaryBadges
                    .map((b) => _DietaryBadge(badge: b))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ALLERGEN BADGE
// ============================================================================

class _AllergenBadge extends StatelessWidget {
  final String allergen;
  final bool isConfirmed;
  const _AllergenBadge({required this.allergen, required this.isConfirmed});

  @override
  Widget build(BuildContext context) {
    final bg = isConfirmed
        ? _NutritionColors.allergenConfirmedBg
        : _NutritionColors.allergenMayContainBg;
    final fg = isConfirmed
        ? _NutritionColors.allergenConfirmedFg
        : _NutritionColors.allergenMayContainFg;
    final label = isConfirmed
        ? 'Contains ${_allergenDisplayName(allergen)}'
        : 'May contain ${_allergenDisplayName(allergen)}';

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_allergenIcon(allergen), size: 14, color: fg),
            const SizedBox(width: 4),
            Text(
              isConfirmed
                  ? _allergenDisplayName(allergen)
                  : 'May: ${_allergenDisplayName(allergen)}',
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DIETARY BADGE
// ============================================================================

class _DietaryBadge extends StatelessWidget {
  final String badge;
  const _DietaryBadge({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${_dietaryBadgeDisplayName(badge)} certified',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _NutritionColors.dietaryPositiveBg,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: _NutritionColors.dietaryPositiveFg,
            ),
            const SizedBox(width: 4),
            Text(
              _dietaryBadgeDisplayName(badge),
              style: TextStyle(
                color: _NutritionColors.dietaryPositiveFg,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NUTRITION FACTS CARD — Health Canada table format
// ============================================================================

class _NutritionFactsCard extends StatelessWidget {
  final NutritionFacts nutritionFacts;
  const _NutritionFactsCard({required this.nutritionFacts});

  @override
  Widget build(BuildContext context) {
    final nf = nutritionFacts;

    return ModernCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(
            Icons.analytics_outlined,
            size: 20,
            color: DesignTokens.primary,
          ),
          title: const Text(
            'Nutrition Facts',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DesignTokens.white,
            ),
          ),
          trailing: Text(
            '${nf.servingSizeAmount} ${nf.servingSizeUnit}',
            style: TextStyle(
              fontSize: 13,
              color: _NutritionColors.subNutrientText,
            ),
          ),
          iconColor: DesignTokens.textSecondary,
          collapsedIconColor: DesignTokens.textSecondary,
          children: [
            // Header
            Semantics(
              label:
                  'Nutrition Facts, serving size ${nf.servingSizeAmount} ${nf.servingSizeUnit}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nutrition Facts / Valeur nutritive',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: DesignTokens.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Per ${nf.servingSizeAmount} ${nf.servingSizeUnit}${nf.servingsPerContainer != null ? ' (${nf.servingsPerContainer} servings)' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _NutritionColors.subNutrientText,
                    ),
                  ),
                ],
              ),
            ),

            // Thick divider
            _ThickDivider(),
            // Calories row (large)
            Semantics(
              label: '${nf.caloriesKcal} calories per serving',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calories / Calories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.white,
                      ),
                    ),
                    Text(
                      '${nf.caloriesKcal}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _ThickDivider(),

            // % DV header
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 2),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '% Daily Value*',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _NutritionColors.subNutrientText,
                  ),
                ),
              ),
            ),
            _ThinDivider(),

            // Nutrient rows — official Health Canada order
            _NutrientRow(
              name: 'Fat / Lipides',
              amount: NutritionHelper.formatNutrientMg(nf.totalFatMg),
              dv: NutritionHelper.percentDailyValue(
                nf.totalFatMg,
                HealthCanadaDailyValues.totalFatMg,
              ),
              isBold: true,
            ),
            _NutrientRow(
              name: 'Saturated / saturés',
              amount: NutritionHelper.formatNutrientMg(nf.saturatedFatMg),
              dv: NutritionHelper.percentDailyValue(
                nf.saturatedFatMg + nf.transFatMg,
                HealthCanadaDailyValues.saturatedPlusTransFatMg,
              ),
              isIndented: true,
            ),
            _NutrientRow(
              name: '+ Trans / trans',
              amount: NutritionHelper.formatNutrientMg(nf.transFatMg),
              isIndented: true,
            ),
            _ThinDivider(),
            _NutrientRow(
              name: 'Cholesterol / Cholestérol',
              amount: NutritionHelper.formatNutrientMg(nf.cholesterolMg),
              isBold: true,
            ),
            _ThinDivider(),
            _NutrientRow(
              name: 'Sodium',
              amount: NutritionHelper.formatNutrientMg(nf.sodiumMg),
              dv: NutritionHelper.percentDailyValue(
                nf.sodiumMg,
                HealthCanadaDailyValues.sodiumMg,
              ),
              isBold: true,
            ),
            _ThinDivider(),
            _NutrientRow(
              name: 'Carbohydrate / Glucides',
              amount: NutritionHelper.formatNutrientMg(nf.totalCarbohydrateMg),
              isBold: true,
            ),
            _NutrientRow(
              name: 'Fibre / Fibres',
              amount: NutritionHelper.formatNutrientMg(nf.fibreMg),
              dv: NutritionHelper.percentDailyValue(
                nf.fibreMg,
                HealthCanadaDailyValues.fibreMg,
              ),
              isIndented: true,
            ),
            _NutrientRow(
              name: 'Sugars / Sucres',
              amount: NutritionHelper.formatNutrientMg(nf.sugarsMg),
              dv: NutritionHelper.percentDailyValue(
                nf.sugarsMg,
                HealthCanadaDailyValues.sugarsMg,
              ),
              isIndented: true,
            ),
            _ThinDivider(),
            _NutrientRow(
              name: 'Protein / Protéines',
              amount: NutritionHelper.formatNutrientMg(nf.proteinMg),
              isBold: true,
            ),
            _ThickDivider(),

            // Vitamins & minerals (compact row)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (nf.potassiumMg != null)
                    _MineralCompact(
                      name: 'Potassium',
                      amount: NutritionHelper.formatNutrientMg(nf.potassiumMg!),
                      dv: NutritionHelper.percentDailyValue(
                        nf.potassiumMg!,
                        HealthCanadaDailyValues.potassiumMg,
                      ),
                    ),
                  _MineralCompact(
                    name: 'Calcium',
                    amount: NutritionHelper.formatNutrientMg(nf.calciumMg),
                    dv: NutritionHelper.percentDailyValue(
                      nf.calciumMg,
                      HealthCanadaDailyValues.calciumMg,
                    ),
                  ),
                  _MineralCompact(
                    name: 'Iron / Fer',
                    amount: NutritionHelper.formatNutrientMg(nf.ironMg),
                    dv: NutritionHelper.percentDailyValue(
                      nf.ironMg,
                      HealthCanadaDailyValues.ironMg,
                    ),
                  ),
                  _MineralCompact(
                    name: 'Vit A',
                    amount: NutritionHelper.formatNutrientMcg(nf.vitaminAMcg),
                    dv: NutritionHelper.percentDailyValue(
                      nf.vitaminAMcg,
                      HealthCanadaDailyValues.vitaminAMcg,
                    ),
                  ),
                  _MineralCompact(
                    name: 'Vit C',
                    amount: NutritionHelper.formatNutrientMg(nf.vitaminCMg),
                    dv: NutritionHelper.percentDailyValue(
                      nf.vitaminCMg,
                      HealthCanadaDailyValues.vitaminCMg,
                    ),
                  ),
                  if (nf.vitaminDMcg != null)
                    _MineralCompact(
                      name: 'Vit D',
                      amount: NutritionHelper.formatNutrientMcg(
                        nf.vitaminDMcg!,
                      ),
                      dv: NutritionHelper.percentDailyValue(
                        nf.vitaminDMcg!,
                        HealthCanadaDailyValues.vitaminDMcg,
                      ),
                    ),
                ],
              ),
            ),
            _ThinDivider(),

            // Footnote
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '*5% or less is a little, 15% or more is a lot\n*5% ou moins c\'est peu, 15% ou plus c\'est beaucoup',
                style: TextStyle(
                  fontSize: 11,
                  color: _NutritionColors.footnoteText,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// NUTRIENT ROW
// ============================================================================

class _NutrientRow extends StatelessWidget {
  final String name;
  final String amount;
  final int? dv;
  final bool isBold;
  final bool isIndented;

  const _NutrientRow({
    required this.name,
    required this.amount,
    this.dv,
    this.isBold = false,
    this.isIndented = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name: $amount${dv != null ? ', $dv% daily value' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            if (isIndented) const SizedBox(width: 16),
            Expanded(
              child: Text(
                '$name $amount',
                style: TextStyle(
                  color: isIndented
                      ? _NutritionColors.subNutrientText
                      : DesignTokens.white,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ),
            if (dv != null)
              Text(
                '$dv%',
                style: TextStyle(
                  color: DesignTokens.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MINERAL COMPACT ROW
// ============================================================================

class _MineralCompact extends StatelessWidget {
  final String name;
  final String amount;
  final int dv;
  const _MineralCompact({
    required this.name,
    required this.amount,
    required this.dv,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$name: $amount, $dv% daily value',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$name $amount ',
              style: const TextStyle(fontSize: 13, color: DesignTokens.white),
            ),
            TextSpan(
              text: '$dv%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: DesignTokens.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// STORAGE CARD
// ============================================================================

class _StorageCard extends StatelessWidget {
  final FoodMetadata foodMetadata;
  const _StorageCard({required this.foodMetadata});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          leading: Icon(
            Icons.kitchen_outlined,
            size: 20,
            color: DesignTokens.primary,
          ),
          title: const Text(
            'Storage & Handling',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: DesignTokens.white,
            ),
          ),
          iconColor: DesignTokens.textSecondary,
          collapsedIconColor: DesignTokens.textSecondary,
          children: [
            if (foodMetadata.storageInstructionsEn != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.thermostat_outlined,
                    size: 16,
                    color: DesignTokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      foodMetadata.storageInstructionsEn!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (foodMetadata.storageInstructionsFr != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    foodMetadata.storageInstructionsFr!,
                    style: TextStyle(
                      fontSize: 12,
                      color: _NutritionColors.subNutrientText,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
            if (foodMetadata.bestBeforeDays != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: DesignTokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Best before: ${foodMetadata.bestBeforeDays} days from production',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// DIVIDERS
// ============================================================================

class _ThickDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 2,
        color: _NutritionColors.thickDivider,
        margin: const EdgeInsets.symmetric(vertical: 2),
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        height: 1,
        color: _NutritionColors.thinDivider,
        margin: const EdgeInsets.symmetric(vertical: 1),
      ),
    );
  }
}
