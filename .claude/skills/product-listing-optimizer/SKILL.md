# Product Listing Optimizer

Reviews product listings for completeness, scores quality, suggests SEO improvements, and cross-checks specs against description for consistency.

## Activation

When a seller wants to improve their product listing, check listing quality, or optimize for search visibility.

## Codebase References

- Product models: `origna_gta/lib/models/generated/product_models.dart`
- Schema constants: `origna_gta/lib/core/schema/schema_constants.dart`
- Add product VM: `origna_gta/lib/features/products/add_product_viewmodel.dart`
- Meilisearch searchable fields: title, name, description, keywords, subcategory
- Meilisearch filterable fields: lifecycleStatus, categoryId, subcategory, priceCents, sellerId, isPerishable
- Translations: `origna_gta/assets/translations/{en,fr}.json` (`specs` block)
- Seed examples: `e2e/lib/seed-dev.ts`

## Quality Score Calculation

Score a listing out of 100 points:

| Criterion | Points | Details |
|-----------|--------|---------|
| Title quality | 15 | 20-80 chars, includes brand + key feature, no ALL CAPS |
| Description length | 15 | 150+ chars = full points, <50 = 0 |
| Images | 20 | 5+ images = full points, 1 = 4pts, 0 = 0 |
| Specs filled % | 20 | (filled / category template total) * 20 |
| Price set | 5 | Non-zero price in cents |
| Category + subcategory | 5 | Both set |
| Shipping info | 5 | Weight, dimensions, ship-from country |
| Keywords/tags | 5 | At least 3 keywords |
| Compliance fields | 10 | All required regulatory fields for category |

### Rating Bands
- 90-100: Excellent — ready for trending/featured
- 70-89: Good — publishable, minor improvements suggested
- 50-69: Fair — missing key elements, fix before publishing
- <50: Poor — incomplete listing, needs significant work

## SEO Suggestions

1. **Title**: Include brand name, primary feature, size/variant if applicable. Keep under 80 chars.
2. **Description**: Lead with key benefits. Include material, use case, dimensions. Minimum 150 chars, ideal 300-500.
3. **Keywords**: Extract from description + specs. Include synonyms (e.g., "laptop" + "notebook"). Add Canadian-specific terms where relevant.
4. **Subcategory**: Must match Meilisearch filterable values exactly.
5. **Specs**: Fill all category template fields — Meilisearch indexes these for faceted search.

## Consistency Cross-Check

Verify these fields match between description and specs:
- Brand mentioned in description matches `specs.brand`
- Color mentioned in description matches `specs.color`
- Material mentioned in description matches `specs.material`
- Dimensions in description match spec values
- "Made in X" in description matches `specs.madeIn`
- Price tier matches product positioning (luxury description + low price = flag)

Flag inconsistencies as warnings with specific field references.

## Workflow

1. Read the product listing (all fields)
2. Calculate quality score with breakdown
3. List missing specs for the category template
4. Check compliance fields for the category
5. Run consistency cross-check (description vs specs)
6. Generate actionable improvement suggestions, ordered by impact
7. If score < 70, flag as "needs work before publishing"

## Output Format

```
## Listing Quality Report: [Product Title]

**Score: XX/100** (Rating Band)

### Breakdown
- Title: X/15
- Description: X/15
- Images: X/20
- Specs: X/20
- Price: X/5
- Category: X/5
- Shipping: X/5
- Keywords: X/5
- Compliance: X/10

### Missing Specs
- [list of unfilled category template fields]

### Compliance Issues
- [any regulatory fields missing]

### Consistency Warnings
- [description vs spec mismatches]

### Top 3 Improvements
1. [highest impact suggestion]
2. [second highest]
3. [third highest]
```
