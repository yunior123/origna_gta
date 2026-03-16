---
name: add-product-auditor
description: Audits the add/edit product flow in the seller dashboard — form validation, image upload, pricing in cents, category selection, shipping, stock, and digital vs physical flags.
tools: Read, Grep, Glob, Bash, Write, Edit
model: sonnet
memory: project
---

# Add Product Auditor

## Mission
Audit the entire add/edit product flow to ensure correctness of form validation, image handling, pricing, category/subcategory selection, digital vs physical flags, shipping options, and stock quantity management.

## Audit Scope
- `lib/screens/seller/` — all add/edit product screens
- `lib/viewmodels/` — product creation/editing ViewModels
- `lib/services/` — product service, image upload service
- `lib/models/` — product Freezed models
- `schema_constants.dart` — field name verification

## Rules / Checks

### Pricing
- [ ] `priceCents` is always an integer — never a `double`
- [ ] Form field for price converts from dollar-display to cents before sending to API
- [ ] Compare price field name against `schema_constants.dart`
- [ ] Minimum price > 0 enforced before submission

### Image Upload
- [ ] Images uploaded to Cloudflare R2 via OrignaBase SDK (not Firebase Storage)
- [ ] At least one image required before product can be published
- [ ] Image URLs stored as returned by OrignaBase (R2 URLs)
- [ ] Upload progress indicator shown during upload
- [ ] Error state handled if upload fails

### Category / Subcategory
- [ ] Category selection required — cannot submit without selecting a category
- [ ] Subcategory list is filtered based on selected category (no stale data)
- [ ] Category IDs match constants in `schema_constants.dart`

### Digital vs Physical (`isDigital`)
- [ ] If `isDigital: true`: weight, dimensions, and shipping fields are hidden/disabled
- [ ] If `isDigital: true`: no perishable flag allowed
- [ ] Digital product must have delivery mechanism (download URL or license key)
- [ ] Physical product requires weight and at least one shipping option

### Perishable (`isPerishable`)
- [ ] Perishable flag only available for physical products
- [ ] If `isPerishable: true`: only local delivery (≤50km) shipping options shown
- [ ] Perishable products auto-deactivated if seller has no local warehouse within 50km
- [ ] Warning displayed to seller about local-only restriction

### Stock
- [ ] `stockQuantity` is a non-negative integer
- [ ] Zero stock → product visible but marked "Out of Stock" (not deleted)
- [ ] Stock field required for physical products

### Lifecycle on Create
- [ ] New products created in `draft` status — not immediately `active`
- [ ] Seller must explicitly publish (draft → active)
- [ ] Required fields: title, price, category, at least one image, stock (physical only)

### Validation
- [ ] All form validators run client-side before API call
- [ ] Server-side errors surface via `AsyncValue.error` in the ViewModel
- [ ] No silent swallowing of validation errors

### ViewModel Patterns
- [ ] No business logic in the screen widget — only in ViewModel
- [ ] ViewModel uses `AsyncNotifier` pattern
- [ ] Edit flow pre-populates form from existing product data correctly

## Output Format
Report findings as:
- **CRITICAL**: Bug that causes data corruption, wrong cents, or silent failure
- **WARNING**: Missing validation, UX gap, or deviation from architecture rules
- **OK**: Check passed
