import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/product_models.dart';

/// Helper for Health Canada nutrition calculations.
///
/// All computations use integer arithmetic (mg/mcg) to avoid float precision issues.
/// Display formatting converts to grams only at the presentation layer.
class NutritionHelper {
  NutritionHelper._();

  /// Compute Health Canada Front-of-Package warnings from nutrition facts.
  ///
  /// Returns a record of booleans indicating whether each nutrient exceeds
  /// the 15% DV per serving threshold (Health Canada FOP, enforced Jan 2026).
  static ({bool sodium, bool sugars, bool saturatedFat}) computeFopWarnings(
    NutritionFacts nf,
  ) {
    return (
      sodium: nf.sodiumMg >= FopThresholds.sodiumMgPerServing,
      sugars: nf.sugarsMg >= FopThresholds.sugarsMgPerServing,
      saturatedFat: nf.saturatedFatMg >= FopThresholds.saturatedFatMgPerServing,
    );
  }

  /// Calculate % Daily Value for a nutrient.
  ///
  /// Both [nutrientAmount] and [dailyValue] must be in the same unit (mg or mcg).
  /// Returns rounded integer percentage.
  static int percentDailyValue(int nutrientAmount, int dailyValue) {
    if (dailyValue <= 0) return 0;
    return (nutrientAmount / dailyValue * 100).round();
  }

  /// Format a nutrient amount in mg for display.
  ///
  /// - >= 1000mg → shows as grams (e.g., 15000 → "15 g")
  /// - < 1000mg → shows as mg (e.g., 300 → "300 mg")
  /// - 0 → "0 g"
  static String formatNutrientMg(int mg) {
    if (mg == 0) return '0 g';
    if (mg >= 1000) {
      final grams = mg / 1000;
      // Show integer if whole number, one decimal otherwise
      if (grams == grams.roundToDouble()) {
        return '${grams.toInt()} g';
      }
      return '${grams.toStringAsFixed(1)} g';
    }
    return '$mg mg';
  }

  /// Format a nutrient amount in mcg for display.
  static String formatNutrientMcg(int mcg) {
    return '$mcg mcg';
  }

  /// Get the list of active FOP warning labels for display.
  ///
  /// Returns bilingual labels like "Saturated Fat / Gras saturés".
  static List<String> getFopWarningLabels(FoodMetadata fm) {
    final labels = <String>[];
    if (fm.fopHighSaturatedFat) labels.add('Saturated Fat');
    if (fm.fopHighSugars) labels.add('Sugars');
    if (fm.fopHighSodium) labels.add('Sodium');
    return labels;
  }

  /// Check if a product has any food-related data to display.
  static bool hasAnyFoodData(NutritionFacts? nf, FoodMetadata? fm) {
    if (nf != null) return true;
    if (fm == null) return false;
    return fm.ingredientsEn != null ||
        fm.allergens.isNotEmpty ||
        fm.dietaryBadges.isNotEmpty ||
        fm.storageInstructionsEn != null;
  }
}
