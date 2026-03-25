import 'package:flutter_test/flutter_test.dart';
import 'package:origna_gta/core/schema/schema_constants.dart';
import 'package:origna_gta/models/generated/product_models.dart';
import 'package:origna_gta/utils/nutrition_helper.dart';

void main() {
  group('NutritionFacts model', () {
    test('serialization roundtrip', () {
      const nf = NutritionFacts(
        servingSizeAmount: 55,
        servingSizeUnit: ServingSizeUnitValues.g,
        servingsPerContainer: 8,
        caloriesKcal: 230,
        totalFatMg: 12000,
        saturatedFatMg: 3000,
        transFatMg: 0,
        cholesterolMg: 0,
        sodiumMg: 160,
        totalCarbohydrateMg: 37000,
        fibreMg: 4000,
        sugarsMg: 12000,
        proteinMg: 3000,
        vitaminAMcg: 100,
        vitaminCMg: 10,
        calciumMg: 260,
        ironMg: 8,
      );

      final json = nf.toJson();
      final restored = NutritionFacts.fromJson(json);

      expect(restored.servingSizeAmount, 55);
      expect(restored.servingSizeUnit, ServingSizeUnitValues.g);
      expect(restored.servingsPerContainer, 8);
      expect(restored.caloriesKcal, 230);
      expect(restored.totalFatMg, 12000);
      expect(restored.saturatedFatMg, 3000);
      expect(restored.transFatMg, 0);
      expect(restored.cholesterolMg, 0);
      expect(restored.sodiumMg, 160);
      expect(restored.totalCarbohydrateMg, 37000);
      expect(restored.fibreMg, 4000);
      expect(restored.sugarsMg, 12000);
      expect(restored.proteinMg, 3000);
      expect(restored.vitaminAMcg, 100);
      expect(restored.vitaminCMg, 10);
      expect(restored.calciumMg, 260);
      expect(restored.ironMg, 8);
    });

    test('optional fields default to null', () {
      const nf = NutritionFacts(
        servingSizeAmount: 30,
        servingSizeUnit: ServingSizeUnitValues.g,
        caloriesKcal: 100,
        totalFatMg: 5000,
        saturatedFatMg: 1000,
        transFatMg: 0,
        cholesterolMg: 0,
        sodiumMg: 50,
        totalCarbohydrateMg: 15000,
        fibreMg: 2000,
        sugarsMg: 8000,
        proteinMg: 2000,
        vitaminAMcg: 0,
        vitaminCMg: 0,
        calciumMg: 0,
        ironMg: 0,
      );

      expect(nf.servingsPerContainer, isNull);
      expect(nf.addedSugarsMg, isNull);
      expect(nf.potassiumMg, isNull);
      expect(nf.vitaminDMcg, isNull);
    });

    test('all-zero nutrition values serialize correctly', () {
      const nf = NutritionFacts(
        servingSizeAmount: 100,
        servingSizeUnit: ServingSizeUnitValues.mL,
        caloriesKcal: 0,
        totalFatMg: 0,
        saturatedFatMg: 0,
        transFatMg: 0,
        cholesterolMg: 0,
        sodiumMg: 0,
        totalCarbohydrateMg: 0,
        fibreMg: 0,
        sugarsMg: 0,
        proteinMg: 0,
        vitaminAMcg: 0,
        vitaminCMg: 0,
        calciumMg: 0,
        ironMg: 0,
      );

      final json = nf.toJson();
      final restored = NutritionFacts.fromJson(json);
      expect(restored.caloriesKcal, 0);
      expect(restored.totalFatMg, 0);
    });
  });

  group('FoodMetadata model', () {
    test('serialization roundtrip', () {
      const fm = FoodMetadata(
        ingredientsEn: 'Whole grain oats, sugar, corn starch',
        ingredientsFr: 'Flocons d\'avoine, sucre, fécule de maïs',
        allergens: [AllergenValues.wheat, AllergenValues.milk],
        mayContainAllergens: [AllergenValues.soy],
        storageInstructionsEn: 'Store in a cool, dry place',
        storageInstructionsFr: 'Conserver dans un endroit frais et sec',
        bestBeforeDays: 365,
        dietaryBadges: [DietaryBadgeValues.organic, DietaryBadgeValues.vegan],
        fopHighSodium: false,
        fopHighSugars: true,
        fopHighSaturatedFat: false,
      );

      final json = fm.toJson();
      final restored = FoodMetadata.fromJson(json);

      expect(restored.ingredientsEn, 'Whole grain oats, sugar, corn starch');
      expect(restored.ingredientsFr, contains('Flocons'));
      expect(restored.allergens, [AllergenValues.wheat, AllergenValues.milk]);
      expect(restored.mayContainAllergens, [AllergenValues.soy]);
      expect(restored.bestBeforeDays, 365);
      expect(restored.dietaryBadges, contains(DietaryBadgeValues.organic));
      expect(restored.fopHighSugars, isTrue);
      expect(restored.fopHighSodium, isFalse);
      expect(restored.fopHighSaturatedFat, isFalse);
    });

    test('defaults for empty food metadata', () {
      const fm = FoodMetadata();

      expect(fm.ingredientsEn, isNull);
      expect(fm.ingredientsFr, isNull);
      expect(fm.allergens, isEmpty);
      expect(fm.mayContainAllergens, isEmpty);
      expect(fm.storageInstructionsEn, isNull);
      expect(fm.storageInstructionsFr, isNull);
      expect(fm.bestBeforeDays, isNull);
      expect(fm.dietaryBadges, isEmpty);
      expect(fm.fopHighSodium, isFalse);
      expect(fm.fopHighSugars, isFalse);
      expect(fm.fopHighSaturatedFat, isFalse);
    });
  });

  group('Product with nutrition data', () {
    test('Product with nutritionFacts and foodMetadata deserializes', () {
      final json = {
        'productId': 'products:food1',
        'name': 'Organic Oatmeal',
        'priceCents': 599,
        'description': 'Hearty organic oatmeal',
        'imageUrls': <String>['https://example.com/oat.jpg'],
        'sellerId': 'users:seller1',
        'categoryId': CategoryIds.groceries,
        'stockQuantity': 100,
        'createdAt': '2026-03-25T00:00:00.000Z',
        'isPerishable': false,
        'nutritionFacts': {
          'servingSizeAmount': 40,
          'servingSizeUnit': 'g',
          'caloriesKcal': 150,
          'totalFatMg': 3000,
          'saturatedFatMg': 500,
          'transFatMg': 0,
          'cholesterolMg': 0,
          'sodiumMg': 0,
          'totalCarbohydrateMg': 27000,
          'fibreMg': 4000,
          'sugarsMg': 1000,
          'proteinMg': 5000,
          'vitaminAMcg': 0,
          'vitaminCMg': 0,
          'calciumMg': 20,
          'ironMg': 2,
        },
        'foodMetadata': {
          'ingredientsEn': 'Whole grain rolled oats',
          'allergens': ['wheat'],
          'dietaryBadges': ['organic', 'vegan'],
        },
      };

      final product = Product.fromJson(json);
      expect(product.nutritionFacts, isNotNull);
      expect(product.nutritionFacts!.caloriesKcal, 150);
      expect(product.nutritionFacts!.totalFatMg, 3000);
      expect(product.foodMetadata, isNotNull);
      expect(product.foodMetadata!.ingredientsEn, 'Whole grain rolled oats');
      expect(product.foodMetadata!.allergens, ['wheat']);
      expect(product.foodMetadata!.dietaryBadges, contains('organic'));
    });

    test('Product without nutrition data has null fields', () {
      final json = {
        'productId': 'products:elec1',
        'name': 'USB Cable',
        'priceCents': 999,
        'description': 'USB-C cable',
        'imageUrls': <String>[],
        'sellerId': 'users:seller1',
        'categoryId': 1,
        'stockQuantity': 50,
        'createdAt': '2026-03-25T00:00:00.000Z',
      };

      final product = Product.fromJson(json);
      expect(product.nutritionFacts, isNull);
      expect(product.foodMetadata, isNull);
    });
  });

  group('NutritionHelper', () {
    group('computeFopWarnings', () {
      test('high sodium triggers warning', () {
        const nf = NutritionFacts(
          servingSizeAmount: 100,
          servingSizeUnit: ServingSizeUnitValues.g,
          caloriesKcal: 200,
          totalFatMg: 5000,
          saturatedFatMg: 1000,
          transFatMg: 0,
          cholesterolMg: 0,
          sodiumMg: 400, // >= 345 threshold
          totalCarbohydrateMg: 20000,
          fibreMg: 2000,
          sugarsMg: 5000,
          proteinMg: 8000,
          vitaminAMcg: 0,
          vitaminCMg: 0,
          calciumMg: 0,
          ironMg: 0,
        );

        final warnings = NutritionHelper.computeFopWarnings(nf);
        expect(warnings.sodium, isTrue);
        expect(warnings.sugars, isFalse);
        expect(warnings.saturatedFat, isFalse);
      });

      test('high sugars triggers warning', () {
        const nf = NutritionFacts(
          servingSizeAmount: 60,
          servingSizeUnit: ServingSizeUnitValues.mL,
          caloriesKcal: 210,
          totalFatMg: 0,
          saturatedFatMg: 0,
          transFatMg: 0,
          cholesterolMg: 0,
          sodiumMg: 0,
          totalCarbohydrateMg: 54000,
          fibreMg: 0,
          sugarsMg: 54000, // 54g = 54000mg >= 15000 threshold
          proteinMg: 0,
          vitaminAMcg: 0,
          vitaminCMg: 0,
          calciumMg: 0,
          ironMg: 0,
        );

        final warnings = NutritionHelper.computeFopWarnings(nf);
        expect(warnings.sugars, isTrue);
        expect(warnings.sodium, isFalse);
        expect(warnings.saturatedFat, isFalse);
      });

      test('high saturated fat triggers warning', () {
        const nf = NutritionFacts(
          servingSizeAmount: 32,
          servingSizeUnit: ServingSizeUnitValues.g,
          caloriesKcal: 190,
          totalFatMg: 16000,
          saturatedFatMg: 3500, // >= 3000 threshold
          transFatMg: 0,
          cholesterolMg: 0,
          sodiumMg: 0,
          totalCarbohydrateMg: 7000,
          fibreMg: 3000,
          sugarsMg: 3000,
          proteinMg: 7000,
          vitaminAMcg: 0,
          vitaminCMg: 0,
          calciumMg: 0,
          ironMg: 0,
        );

        final warnings = NutritionHelper.computeFopWarnings(nf);
        expect(warnings.saturatedFat, isTrue);
        expect(warnings.sodium, isFalse);
        expect(warnings.sugars, isFalse);
      });

      test('all below thresholds returns all false', () {
        const nf = NutritionFacts(
          servingSizeAmount: 100,
          servingSizeUnit: ServingSizeUnitValues.g,
          caloriesKcal: 50,
          totalFatMg: 1000,
          saturatedFatMg: 500,
          transFatMg: 0,
          cholesterolMg: 0,
          sodiumMg: 100,
          totalCarbohydrateMg: 10000,
          fibreMg: 3000,
          sugarsMg: 2000,
          proteinMg: 2000,
          vitaminAMcg: 0,
          vitaminCMg: 0,
          calciumMg: 0,
          ironMg: 0,
        );

        final warnings = NutritionHelper.computeFopWarnings(nf);
        expect(warnings.sodium, isFalse);
        expect(warnings.sugars, isFalse);
        expect(warnings.saturatedFat, isFalse);
      });

      test('all three exceed thresholds simultaneously', () {
        const nf = NutritionFacts(
          servingSizeAmount: 100,
          servingSizeUnit: ServingSizeUnitValues.g,
          caloriesKcal: 500,
          totalFatMg: 30000,
          saturatedFatMg: 10000,
          transFatMg: 500,
          cholesterolMg: 50,
          sodiumMg: 800,
          totalCarbohydrateMg: 50000,
          fibreMg: 1000,
          sugarsMg: 30000,
          proteinMg: 5000,
          vitaminAMcg: 0,
          vitaminCMg: 0,
          calciumMg: 0,
          ironMg: 0,
        );

        final warnings = NutritionHelper.computeFopWarnings(nf);
        expect(warnings.sodium, isTrue);
        expect(warnings.sugars, isTrue);
        expect(warnings.saturatedFat, isTrue);
      });
    });

    group('percentDailyValue', () {
      test('sodium 300mg → 13% DV', () {
        final dv = NutritionHelper.percentDailyValue(
          300,
          HealthCanadaDailyValues.sodiumMg,
        );
        expect(dv, 13); // (300 / 2300 * 100).round() = 13
      });

      test('fat 12g (12000mg) → 16% DV', () {
        final dv = NutritionHelper.percentDailyValue(
          12000,
          HealthCanadaDailyValues.totalFatMg,
        );
        expect(dv, 16); // (12000 / 75000 * 100).round() = 16
      });

      test('calcium 260mg → 20% DV', () {
        final dv = NutritionHelper.percentDailyValue(
          260,
          HealthCanadaDailyValues.calciumMg,
        );
        expect(dv, 20); // (260 / 1300 * 100).round() = 20
      });

      test('zero nutrient → 0% DV', () {
        final dv = NutritionHelper.percentDailyValue(
          0,
          HealthCanadaDailyValues.sodiumMg,
        );
        expect(dv, 0);
      });
    });

    group('formatNutrientDisplay', () {
      test('15000mg → "15 g"', () {
        expect(NutritionHelper.formatNutrientMg(15000), '15 g');
      });

      test('300mg → "300 mg"', () {
        expect(NutritionHelper.formatNutrientMg(300), '300 mg');
      });

      test('500mg → "500 mg"', () {
        expect(NutritionHelper.formatNutrientMg(500), '500 mg');
      });

      test('0mg → "0 g"', () {
        expect(NutritionHelper.formatNutrientMg(0), '0 g');
      });

      test('100mcg vitamin A', () {
        expect(NutritionHelper.formatNutrientMcg(100), '100 mcg');
      });
    });
  });

  group('AllergenValues', () {
    test('all contains 11 Canadian priority allergens', () {
      expect(AllergenValues.all, hasLength(11));
      expect(AllergenValues.all, contains(AllergenValues.eggs));
      expect(AllergenValues.all, contains(AllergenValues.milk));
      expect(AllergenValues.all, contains(AllergenValues.mustard));
      expect(AllergenValues.all, contains(AllergenValues.peanuts));
      expect(AllergenValues.all, contains(AllergenValues.crustaceans));
      expect(AllergenValues.all, contains(AllergenValues.fish));
      expect(AllergenValues.all, contains(AllergenValues.sesame));
      expect(AllergenValues.all, contains(AllergenValues.soy));
      expect(AllergenValues.all, contains(AllergenValues.sulphites));
      expect(AllergenValues.all, contains(AllergenValues.treeNuts));
      expect(AllergenValues.all, contains(AllergenValues.wheat));
    });
  });

  group('DietaryBadgeValues', () {
    test('all contains 10 badges', () {
      expect(DietaryBadgeValues.all, hasLength(10));
    });
  });

  group('FopThresholds', () {
    test('threshold values match Health Canada 15% DV', () {
      // Saturated fat: 15% of 20g = 3g = 3000mg
      expect(FopThresholds.saturatedFatMgPerServing, 3000);
      // Sugars: 15% of 100g = 15g = 15000mg
      expect(FopThresholds.sugarsMgPerServing, 15000);
      // Sodium: 15% of 2300mg = 345mg
      expect(FopThresholds.sodiumMgPerServing, 345);
    });
  });

  group('HealthCanadaDailyValues', () {
    test('daily values match Health Canada reference', () {
      expect(HealthCanadaDailyValues.totalFatMg, 75000);
      expect(HealthCanadaDailyValues.saturatedPlusTransFatMg, 20000);
      expect(HealthCanadaDailyValues.sodiumMg, 2300);
      expect(HealthCanadaDailyValues.fibreMg, 28000);
      expect(HealthCanadaDailyValues.sugarsMg, 100000);
      expect(HealthCanadaDailyValues.vitaminAMcg, 900);
      expect(HealthCanadaDailyValues.vitaminCMg, 90);
      expect(HealthCanadaDailyValues.calciumMg, 1300);
      expect(HealthCanadaDailyValues.ironMg, 18);
      expect(HealthCanadaDailyValues.potassiumMg, 3400);
      expect(HealthCanadaDailyValues.vitaminDMcg, 20);
    });
  });
}
