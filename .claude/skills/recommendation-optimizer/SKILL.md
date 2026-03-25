# Skill: Recommendation Optimizer

Optimize product recommendation quality for the OrignaGTA marketplace.

## Capabilities

### 1. Analyze Co-Purchase Data Coverage
- Query `product_recommendations` collection to identify which products have recommendations and which don't
- Report coverage percentage: products with co-purchase data vs total active products
- Identify "cold start" products (new, no order history) that need alternative recommendation strategies

### 2. Suggest Bundle Products for Sellers
- Analyze category-level co-purchase patterns to suggest bundles
- Identify complementary product categories (e.g., phone cases frequently bought with screen protectors)
- Generate seller-specific suggestions based on their product catalog
- Validate bundledProductIds arrays (max 5 per product)

### 3. Monitor Recommendation Hit Rate
- Track how often co-purchase recommendations are served vs category fallback
- Measure the `source` field distribution: `co_purchase` vs `seller_curated` vs `category`
- Alert when hit rate drops below threshold (indicates stale data or coverage gap)

### 4. Cold-Start Strategies for New Products
- New products with no order history get category-based recommendations
- Seller-curated bundles (`bundledProductIds`) provide immediate recommendations
- Products in the same subcategory with high `purchaseCount` serve as initial recs
- After sufficient orders accumulate (typically 7-14 days), co-purchase data takes over

### 5. Data Quality Checks
- Verify `computedAt` timestamps are recent (within 48 hours for daily cron)
- Check for orphaned recommendations (product deleted but recs remain)
- Validate recommendation scores are non-zero
- Ensure no self-referential recommendations (product recommending itself)

## Codebase References

| Component | File |
|-----------|------|
| Co-purchase cron job | `orignabase/crates/ob-handlers/src/cron/mod.rs` → `compute_co_purchase_recommendations` |
| REST endpoint | `orignabase/crates/ob-handlers/src/rest_api.rs` → `get_product_recommendations` |
| bundledProductIds validation | `orignabase/crates/ob-handlers/src/products/crud.rs` → `create_product_atomic`, `update_product` |
| Schema constants | `orignabase/crates/ob-handlers/src/shared/schema.rs` → `collections::PRODUCT_RECOMMENDATIONS` |
| EN translations | `origna_gta/assets/translations/en.json` → `recommendations.*` |
| FR translations | `origna_gta/assets/translations/fr.json` → `recommendations.*` |

## Usage

```
/recommendation-optimizer analyze-coverage
/recommendation-optimizer suggest-bundles --seller <seller_id>
/recommendation-optimizer check-freshness
/recommendation-optimizer cold-start-report
```

## Cron Schedule

The `compute_co_purchase_recommendations` job runs daily at 3 AM UTC (`0 3 * * *`).
It analyzes delivered orders from the last 90 days and stores the top 10 co-purchased products per product.
