# Food Expert Skill

Use when sellers need help filling food product nutrition data, validating Health Canada compliance, looking up nutrition info, or checking allergen declarations. Triggers on: "food nutrition help", "fill nutrition facts", "check food compliance", "allergen check", "nutrition lookup", "food label help", "CFIA compliance", "FOP check".

## What This Skill Does

Helps sellers create regulation-compliant food product listings for the Canadian marketplace by:

1. **Validating Health Canada compliance** for the 13 mandatory nutrients in the Nutrition Facts Table
2. **Checking allergen declarations** against Canada's 11 priority allergen categories
3. **Computing FOP warnings** (Front-of-Package "High In" symbols, enforced Jan 2026)
4. **Suggesting missing bilingual fields** (EN/FR requirement under CFIA / Bill 96)
5. **Looking up nutrition data** from Open Food Facts by product name or barcode
6. **Verifying ingredient order** (descending by weight, as required by CFIA)

## Health Canada Mandatory Nutrients (13)

Per serving, in this exact order:
1. Calories (kcal)
2. Fat / Lipides (g)
3. Saturated fat / Gras saturés (g) + Trans fat / Gras trans (g)
4. Cholesterol / Cholestérol (mg)
5. Sodium (mg)
6. Carbohydrate / Glucides (g)
7. Fibre / Fibres (g)
8. Sugars / Sucres (g)
9. Protein / Protéines (g)
10. Vitamin A / Vitamine A (mcg RAE)
11. Vitamin C / Vitamine C (mg)
12. Calcium (mg)
13. Iron / Fer (mg)

Optional but recommended: Potassium, Vitamin D, Added Sugars.

## Canada's 11 Priority Allergens

Must be declared if present: Eggs, Milk, Mustard, Peanuts, Crustaceans, Fish, Sesame, Soy, Sulphites, Tree Nuts, Wheat (and other gluten sources).

"May contain" (precautionary) statements are separate from confirmed allergens.

## FOP "High In" Thresholds (15% DV per serving)

| Nutrient | Threshold | Warning |
|----------|-----------|---------|
| Saturated fat | >= 3.0 g (3000 mg) | High in Saturated Fat |
| Sugars | >= 15.0 g (15000 mg) | High in Sugars |
| Sodium | >= 345 mg | High in Sodium |

## Daily Values for %DV Calculation

| Nutrient | DV |
|----------|----|
| Fat | 75 g |
| Sat + Trans (combined) | 20 g |
| Cholesterol | 300 mg |
| Sodium | 2300 mg |
| Fibre | 28 g |
| Sugars | 100 g |
| Vitamin A | 900 mcg |
| Vitamin C | 90 mg |
| Calcium | 1300 mg |
| Iron | 18 mg |
| Potassium | 3400 mg |
| Vitamin D | 20 mcg |

Note: Carbohydrate, Protein, Trans fat have no %DV in the standard NFT.

## Workflow

1. Read the product's current `nutritionFacts` and `foodMetadata` fields
2. Check which mandatory nutrients are missing or zero
3. Verify allergens are from the allowed set (`AllergenValues.all` in `schema_constants.dart`)
4. Compute FOP warnings using `NutritionHelper.computeFopWarnings()`
5. Check for missing French translations (ingredientsFr, storageInstructionsFr)
6. If product name matches a known food, look up nutrition on Open Food Facts API: `https://world.openfoodfacts.org/api/v2/search?search_terms={name}&fields=nutriments,allergens_tags,ingredients_text`
7. Report compliance status and suggest fixes

## Codebase References

| What | File |
|------|------|
| Dart schema constants | `origna_gta/lib/core/schema/schema_constants.dart` (AllergenValues, DietaryBadgeValues, FopThresholds, HealthCanadaDailyValues) |
| Dart models | `origna_gta/lib/models/generated/product_models.dart` (NutritionFacts, FoodMetadata) |
| Nutrition helper | `origna_gta/lib/utils/nutrition_helper.dart` (computeFopWarnings, percentDailyValue, formatNutrientMg) |
| Rust structs | `orignabase/crates/ob-handlers/src/shared/nutrition.rs` |
| Rust schema | `orignabase/crates/ob-handlers/src/shared/schema.rs` (allergen_values, dietary_badge_values, fop_thresholds) |
| Display widget | `origna_gta/lib/screens/widgets/product_detail/nutrition_facts_section.dart` |
| Form section | `origna_gta/lib/screens/parts/addproduct_food_info_section.dart` |
| Translations | `origna_gta/assets/translations/en.json` and `fr.json` (nutrition.* keys) |

## Compliance Checklist

- [ ] All 13 mandatory nutrients filled (non-zero serving size + calories)
- [ ] Serving size unit is "g" or "mL"
- [ ] All allergens from allowed set (11 Canadian priority categories)
- [ ] Ingredients listed in descending order of weight
- [ ] French translation provided for ingredients
- [ ] French translation provided for storage instructions
- [ ] FOP warnings auto-computed (not manually set)
- [ ] Dietary badges from allowed set (10 values)
- [ ] Best-before days set for perishable products
- [ ] Storage instructions provided for perishable products
