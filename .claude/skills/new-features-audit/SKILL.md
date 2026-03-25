---
name: new-features-audit
description: "Audit of 3 newly built OrignaGTA features: (A) Food Nutrition with Health Canada FOP thresholds, (B) Product Specs with 20 category templates, (C) Recommendations engine with co-purchase cron and FBT widget. Checks data validation, threshold correctness, Meilisearch sync, UI rendering, and edge cases. Use when asked to 'audit new features', 'check nutrition', 'review specs', 'audit recommendations', or similar."
---

# New Features Audit — OrignaGTA

Audit of 3 features built this session: Food Nutrition (Health Canada compliant), Product Specs (typed values with templates), and Recommendations (co-purchase engine with FBT widget). Each section covers validation, correctness, edge cases, and cross-stack consistency.

## When To Use

- After implementing or modifying nutrition, specs, or recommendation code
- Before production deploy of any of these 3 features
- When reviewing Health Canada compliance for food products
- When investigating recommendation quality or spec template issues

---

## A. Food Nutrition

### Files to Read

```
orignabase/crates/ob-handlers/src/shared/nutrition.rs                           # Backend validation, FOP thresholds
origna_gta/lib/utils/nutrition_helper.dart                                       # Frontend FOP calculation, %DV
origna_gta/lib/screens/widgets/product_detail/nutrition_facts_section.dart       # NFt label rendering
origna_gta/lib/models/generated/product_models.dart                              # NutritionFacts + FoodMetadata freezed models
origna_gta/lib/models/generated/product_models.freezed.dart                      # Generated code
origna_gta/lib/models/generated/product_models.g.dart                            # JSON serialization
```

### Audit Checkpoints

#### A1. NutritionFacts Model (19 nutrient fields)

**All values stored as integers in their natural unit (mg, mcg, kcal, g as mg).**

**Check:**
- [ ] 19 fields present: calories (kcal), totalFat, saturatedFat, transFat, cholesterol, sodium, totalCarbohydrate, dietaryFiber, totalSugars, addedSugars, protein, vitaminA, vitaminC, vitaminD, calcium, iron, potassium, phosphorus, magnesium
- [ ] All fields are integer (not double/float) in Dart model AND Rust struct
- [ ] Units consistent: mg for most, mcg for vitamin A/D, kcal for calories
- [ ] Freezed model has `@Default(0)` or nullable for optional nutrients
- [ ] JSON keys match between Dart (`product_models.g.dart`) and Rust (`nutrition.rs`)
- [ ] No field name mismatch (e.g., `totalFatMg` in Dart vs `total_fat_mg` in Rust — serde rename?)

**Grep for:** `NutritionFacts`, `saturatedFat`, `addedSugars`, `totalCarbohydrate`, `vitaminD`

#### A2. FoodMetadata Model

**Ingredients, allergens, dietary badges, FOP warnings.**

**Check:**
- [ ] `ingredientsEn` and `ingredientsFr` — bilingual (Canada requirement)
- [ ] 11 Canadian priority allergens listed: eggs, milk, mustard, peanuts, crustaceans/shellfish, fish, sesame, soy, sulphites, tree nuts, wheat/triticale
- [ ] Allergens stored as `List<String>` enum values (not free text)
- [ ] Dietary badges: vegan, vegetarian, glutenFree, organic, kosher, halal (or subset)
- [ ] FOP (Front-of-Package) warning flags: highSaturatedFat, highSugars, highSodium
- [ ] FOP warnings computed from NutritionFacts, not manually set

#### A3. FOP Threshold Correctness (Health Canada)

**Front-of-Package nutrition symbol thresholds per serving.**

| Nutrient | Threshold | Unit |
|----------|-----------|------|
| Saturated fat | >= 3000 | mg per serving |
| Sugars | >= 15000 | mg per serving |
| Sodium | >= 345 | mg per serving |

**Check:**
- [ ] Backend (`nutrition.rs`): thresholds match exactly: 3000, 15000, 345
- [ ] Frontend (`nutrition_helper.dart`): thresholds match exactly: 3000, 15000, 345
- [ ] Comparison is `>=` (not `>`) — threshold value itself triggers warning
- [ ] Serving size is required when nutrition facts present (no division by zero)
- [ ] FOP calculated per serving (not per 100g or per package)
- [ ] Both backend and frontend agree on FOP result for same input
- [ ] FOP symbol displayed on product card and product detail page

**Grep for:** `3000`, `15000`, `345`, `fop`, `front_of_package`, `threshold`, `serving`

#### A4. Health Canada Daily Values (%DV)

**%DV displayed on nutrition label must use correct daily values.**

**Check:**
- [ ] Daily values reference table exists in code (not hardcoded per nutrient inline)
- [ ] DV for key nutrients (verify against Health Canada Table of Daily Values):
  - Fat: 75g
  - Saturated fat: 20g
  - Cholesterol: 300mg
  - Sodium: 2300mg
  - Carbohydrate: 275g
  - Fiber: 28g
  - Added sugars: 50g
  - Protein: 50g
  - Vitamin A: 900mcg
  - Vitamin C: 90mg
  - Calcium: 1300mg
  - Iron: 18mg
  - Potassium: 4700mg
- [ ] %DV formula: `(nutrient_amount / daily_value) * 100`, rounded to nearest integer
- [ ] %DV displayed with `%` suffix on nutrition label UI
- [ ] No %DV shown for: calories, trans fat, total sugars (Health Canada rule)

**Grep for:** `daily_value`, `percent_dv`, `%DV`, `DAILY_VALUES`, `2300`, `275`

#### A5. Validation

**Check:**
- [ ] All nutrient values: non-negative (>= 0)
- [ ] Maximum value: 999999 (prevent absurd entries)
- [ ] Serving size: required string, non-empty
- [ ] Servings per container: positive integer
- [ ] Backend validates ALL fields (not just frontend)
- [ ] Invalid values return clear error messages with field name
- [ ] Allergen values validated against allowed enum list

---

## B. Product Specs

### Files to Read

```
orignabase/crates/ob-handlers/src/shared/specs.rs                               # Backend validation, spec types
origna_gta/lib/utils/spec_templates.dart                                         # 20 category templates, 160+ keys
origna_gta/lib/screens/widgets/product_detail/product_specs_section.dart         # Spec display UI
origna_gta/lib/models/generated/product_models.dart                              # ProductSpec/ProductSpecs models
```

### Audit Checkpoints

#### B1. ProductSpec / ProductSpecs Models

**Typed specification values: text, number, boolean.**

**Check:**
- [ ] `ProductSpec` has: `key` (String), `value` (dynamic/union), `type` (enum: text/number/boolean)
- [ ] `ProductSpecs` is a list/collection of `ProductSpec`
- [ ] Type enforcement: `number` type stores numeric value, `boolean` stores true/false
- [ ] Serialization roundtrip: Dart -> JSON -> Rust -> SurrealDB -> Rust -> JSON -> Dart (no data loss)
- [ ] Key is case-sensitive or normalized (pick one, be consistent)
- [ ] Freezed model correctly handles the union/dynamic value type

**Grep for:** `ProductSpec`, `ProductSpecs`, `spec_type`, `SpecType`, `text`, `number`, `boolean`

#### B2. Category Templates (20 categories, 160+ keys)

**Each product category has predefined spec keys.**

**Check:**
- [ ] 20 category templates defined (verify count)
- [ ] Templates indexed by `categoryId` (not category name — name changes, ID doesn't)
- [ ] Each template has: list of spec keys with display name, type, and optional unit
- [ ] Common keys shared across categories (e.g., "Brand", "Color", "Material")
- [ ] Category-specific keys present (e.g., "Screen Size" for Electronics, "Fabric" for Clothing)
- [ ] Template keys are suggestions, not mandatory (seller can skip or add custom)
- [ ] Custom spec keys allowed (seller not limited to template)
- [ ] Template data lives in Flutter only (not in backend — it's a UI hint)
- [ ] EN and FR display names for spec keys (bilingual)

**Grep for:** `spec_template`, `category_template`, `predefined`, `Electronics`, `Clothing`

#### B3. Validation

**Check:**
- [ ] Max 50 specs per product (prevent abuse)
- [ ] Key length: 1-64 characters
- [ ] Value length: 1-500 characters (for text type)
- [ ] Number value: valid numeric range (not NaN, not Infinity)
- [ ] Boolean value: only true/false (not "yes"/"no" strings)
- [ ] Duplicate keys rejected (same key twice in one product)
- [ ] Backend validates all constraints (not just frontend)
- [ ] Empty specs list is valid (specs are optional)

**Grep for:** `max_specs`, `50`, `64`, `500`, `duplicate`, `validate_specs`

#### B4. Meilisearch Integration

**Brand, color, material as filterable attributes in search.**

**Check:**
- [ ] `brand`, `color`, `material` extracted from specs and indexed as top-level Meilisearch fields
- [ ] Filterable attributes config includes: `brand`, `color`, `material`
- [ ] Spec values synced to Meilisearch on product create/update
- [ ] Spec deletion removes values from Meilisearch document
- [ ] Search filters work: `brand = "Nike"`, `color = "Red"`
- [ ] Spec values are strings in Meilisearch (not typed)

**Grep for:** `brand`, `color`, `material`, `filterable`, `meilisearch`, `search_sync`

---

## C. Recommendations

### Files to Read

```
orignabase/crates/ob-handlers/src/cron/mod.rs        # Co-purchase cron: daily 3AM, 90-day window
orignabase/crates/ob-handlers/src/rest_api.rs        # /products/{id}/recommendations endpoint
origna_gta/lib/screens/widgets/product_detail/fbt_section.dart  # "Frequently Bought Together" UI widget
orignabase/crates/ob-handlers/src/products/crud.rs   # bundledProductIds field on product
```

### Audit Checkpoints

#### C1. Co-Purchase Cron Job

**Daily 3AM: analyze delivered orders from 90 days, build co-occurrence matrix.**

**Check:**
- [ ] Cron runs at 3AM (server timezone — verify which timezone)
- [ ] Only analyzes orders with `status: delivered` (not pending/cancelled)
- [ ] 90-day rolling window (not all-time — stale data degrades quality)
- [ ] Co-occurrence: for each product pair (A, B) in same order, increment count
- [ ] Matrix stored in dedicated collection/table (not computed on-the-fly per request)
- [ ] Old matrix data replaced atomically (not incrementally — avoids stale accumulation)
- [ ] Cron is idempotent (running twice in same day produces same result)
- [ ] Performance: pagination over orders (not `SELECT *` on 90 days of orders)
- [ ] Self-recommendations excluded (product A doesn't recommend itself)
- [ ] Inactive/deleted products excluded from recommendations

**Grep for:** `cron`, `co_purchase`, `co_occurrence`, `matrix`, `delivered`, `90`, `3AM`, `schedule`

#### C2. Recommendations Endpoint

**`GET /products/{id}/recommendations` — 3-tier fallback.**

| Tier | Source | When Used |
|------|--------|-----------|
| 1 | `bundledProductIds` (seller-curated) | If seller set manual bundles |
| 2 | Co-purchase matrix | If co-purchase data exists for this product |
| 3 | Same-category popular products | Fallback when no purchase data |

**Check:**
- [ ] Tier 1 checked first: `bundledProductIds` on product record
- [ ] Tier 2 checked second: co-occurrence matrix lookup
- [ ] Tier 3 fallback: same `categoryId`, sorted by popularity/sales
- [ ] Response: list of product summaries (id, name, image, price)
- [ ] Max recommendations: 5-10 (configurable or hardcoded)
- [ ] Only `active` products returned (not draft/inactive/deleted)
- [ ] Products with `stockQuantity: 0` excluded (or flagged as out-of-stock)
- [ ] Response cached with reasonable TTL (recommendations don't change per-request)
- [ ] Rate limit: standard API rate limit applies
- [ ] Invalid product ID returns 404 (not empty recommendations)

**Grep for:** `recommendations`, `bundledProductIds`, `co_purchase`, `fallback`, `same_category`

#### C3. FBT Widget (Frequently Bought Together)

**Flutter widget: checkboxes + combined price + "Add all to Cart".**

**Check:**
- [ ] Widget fetches recommendations on product detail page load
- [ ] Each recommendation shown with: image, name, price, checkbox
- [ ] Current product included in combined price (main product + selected recommendations)
- [ ] Combined price calculated in integer cents (not float)
- [ ] "Add all to Cart" adds ONLY checked items (not all recommendations)
- [ ] Unchecking main product is not allowed (it's the anchor)
- [ ] Loading state shown while fetching recommendations
- [ ] Error state: silently hide FBT section (don't break product page)
- [ ] Empty state: don't show FBT section if 0 recommendations
- [ ] Out-of-stock items in recommendations: show but disabled/greyed out
- [ ] "Add all to Cart" respects stock quantities

**Grep for:** `FbtSection`, `frequently_bought`, `combined_price`, `add_all`, `checkbox`

#### C4. bundledProductIds (Seller-Curated)

**Seller manually sets up to 5 product bundles.**

**Check:**
- [ ] Max 5 `bundledProductIds` per product
- [ ] IDs validated: must be real product IDs owned by same seller
- [ ] Self-reference prevented (product can't bundle itself)
- [ ] Circular reference check: A bundles B, B bundles A (allowed — it's not a dependency)
- [ ] Deleted bundled product: gracefully handled (skip, don't error)
- [ ] Inactive bundled product: excluded from recommendations response
- [ ] UI for seller to add/remove bundled products exists
- [ ] IDs stored as SurrealDB record IDs (`products:xxx`)

**Grep for:** `bundledProductIds`, `max_bundles`, `5`, `seller_curated`, `manual_bundle`

---

## Cross-Cutting Checks

### Data Consistency (Backend <-> Frontend)
- [ ] NutritionFacts field names match between Dart freezed and Rust serde
- [ ] ProductSpec serialization roundtrips correctly
- [ ] Recommendation response shape matches Dart model expectations
- [ ] FOP thresholds identical in `nutrition.rs` and `nutrition_helper.dart`

### Meilisearch Sync
- [ ] Nutrition data: NOT indexed in Meilisearch (not searchable)
- [ ] Specs (brand, color, material): synced as filterable attributes
- [ ] Recommendations: NOT in Meilisearch (separate endpoint)
- [ ] Product update triggers Meilisearch re-sync for spec changes

### i18n (EN/FR)
- [ ] Nutrient names displayed in user's language
- [ ] Allergen names in both languages
- [ ] Spec key display names bilingual
- [ ] Recommendation section header bilingual

---

## Severity Guide

| Severity | Criteria | Example |
|----------|----------|---------|
| **P0 Critical** | Health Canada compliance violation or data corruption | Wrong FOP threshold; nutrition values stored as float; negative calories accepted |
| **P1 High** | Feature broken or data inconsistency | Spec validation bypassed; recommendations return deleted products; FBT price wrong |
| **P2 Medium** | Edge case not handled or UX issue | No fallback tier 3; allergen not in enum; spec duplicate allowed |
| **P3 Low** | Minor polish | Missing FR translation for spec key; FBT loading skeleton absent |

## Output Format

For each finding:
```
## [P0/P1/P2/P3] — Title
- **File**: path/to/file:line
- **Issue**: What's wrong
- **Impact**: What could happen
- **Fix**: Specific code change needed
```
