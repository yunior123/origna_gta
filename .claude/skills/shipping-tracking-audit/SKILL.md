---
name: shipping-tracking-audit
description: "Deep audit of OrignaGTA shipping and tracking: cost calculation, free shipping threshold ($75 CAD), perishable 50km restriction, digital item zero cost, province-based rates, tracking number flow, delivery confirmation, multi-seller shipping, and international rates. Covers shipping_calc correctness, warehouse distance calculations, and high-value order approval. Use when asked to 'audit shipping', 'check tracking', 'review delivery', 'shipping audit', or similar."
---

# Shipping & Tracking Audit — OrignaGTA

Complete audit of shipping cost calculation, tracking number lifecycle, delivery confirmation, and all shipping business rules. Covers perishable restrictions, free shipping threshold, multi-seller orders, and international shipping.

## When To Use

- Before production deploy touching shipping or delivery code
- After modifying shipping cost calculation or rate tables
- When investigating incorrect shipping charges
- When reviewing perishable product delivery restrictions
- Pre-release audit of order fulfillment flow

## Files to Read

### Backend (Rust — OrignaBase)
```
orignabase/crates/ob-handlers/src/orders/shipping.rs      # 2,090 LOC — shipping status, tracking, delivery
orignabase/crates/ob-handlers/src/shipping_calc/mod.rs     # Cost calculation engine, rate tables, distance
orignabase/crates/ob-handlers/src/orders/status.rs         # Order state transitions (shipped, delivered)
orignabase/crates/ob-handlers/src/warehouses/mod.rs        # Warehouse CRUD, address, coordinates
orignabase/crates/ob-handlers/src/payments/checkout.rs     # Shipping cost included in checkout total
orignabase/crates/ob-handlers/src/products/crud.rs         # Product flags: isDigital, isPerishable, weight
```

### Flutter (Frontend)
```
origna_gta/lib/features/checkout/orignabase_checkout_provider.dart  # calculateShipping() call
origna_gta/lib/features/seller/orignabase_warehouses_viewmodel.dart # Warehouse management
origna_gta/lib/core/schema/schema_constants.dart                    # Field names, thresholds
```

---

## Audit Checkpoints

### 1. Shipping Cost Calculation

**Flow: Cart items -> group by seller -> per-seller shipping cost -> sum -> display**

**Check:**
- [ ] Shipping calculated per seller (not per order — multi-seller orders)
- [ ] Inputs: buyer postal code, seller warehouse postal code, total weight, item count
- [ ] Weight from product `weight` field (grams, integer)
- [ ] Cost returned in integer cents (never float)
- [ ] Calculation happens server-side (Flutter sends addresses, backend returns cost)
- [ ] Client-displayed cost matches server-calculated cost at checkout (price verification)
- [ ] Zero-weight items use minimum shipping weight (e.g., 100g)
- [ ] Shipping cost capped at reasonable maximum (prevent $999 shipping bugs)

**Grep for:** `shipping_cost`, `calculate_shipping`, `shippingCostCents`, `weight`, `postal_code`

### 2. Free Shipping Threshold

**Free standard shipping when subtotal >= $75 CAD (7500 cents).**

**Check:**
- [ ] Threshold: `7500` cents — matches `BusinessRules.freeShippingThresholdCents`
- [ ] Threshold applied per seller subtotal (not total order across sellers)
- [ ] Comparison: `subtotalCents >= 7500` (inclusive, not `>`)
- [ ] Free shipping applies to standard shipping only (not express/expedited)
- [ ] Free shipping banner shown on product pages and cart
- [ ] Cart shows "Add $X.XX more for free shipping" when close to threshold
- [ ] Perishable items excluded from free shipping (they have special delivery)
- [ ] Digital items don't count toward shipping threshold (they have no shipping)
- [ ] Discount/coupon applied BEFORE free shipping check (post-discount subtotal)

**Grep for:** `7500`, `free_shipping`, `freeShippingThreshold`, `FREE_SHIPPING`, `threshold`

### 3. Perishable Items — 50km Local Delivery

**Perishable products (`isPerishable: true`) can only ship within 50km of seller warehouse.**

**Check:**
- [ ] Distance calculated: seller warehouse coordinates -> buyer address coordinates
- [ ] Distance calculation: Haversine formula or equivalent geodesic distance
- [ ] Maximum distance: 50km (not 50 miles)
- [ ] Check happens at cart/checkout time (before payment, not after)
- [ ] Clear error message: "This perishable item can only be delivered within 50km"
- [ ] Cross-province shipping blocked for perishable (even if within 50km across border)
- [ ] Seller warehouse must have valid coordinates for perishable products
- [ ] Product creation: if `isPerishable: true`, warehouse coordinates required
- [ ] Mixed cart: perishable + non-perishable items handled separately
- [ ] Perishable shipping rate: flat local delivery fee (not weight-based)

**Grep for:** `perishable`, `isPerishable`, `50`, `distance`, `haversine`, `local_delivery`, `cross_province`

### 4. Digital Items — Zero Shipping

**Digital products (`isDigital: true`) have no shipping cost and no physical delivery.**

**Check:**
- [ ] `isDigital: true` -> shipping cost = 0 cents
- [ ] No shipping address required for digital-only orders
- [ ] No weight field required for digital products
- [ ] No tracking number for digital orders
- [ ] Digital order skips `shipped` state (goes `confirmed` -> `delivered` on download/access)
- [ ] Mixed cart: digital + physical items -> shipping only for physical items
- [ ] Digital delivery: download link or access key sent via email/notification
- [ ] Digital delivery link has expiry (e.g., 7 days)

**Grep for:** `isDigital`, `digital`, `zero_shipping`, `no_shipping`, `download_link`

### 5. Province-Based Tax & Shipping Rates

**Canadian provinces have different tax rates and shipping zones.**

**Check:**
- [ ] Province extracted from buyer shipping address
- [ ] Tax calculation uses correct provincial rate (GST + PST/HST varies by province)
- [ ] Shipping zones defined: local (same province), domestic (different province), remote (territories)
- [ ] Remote zones (YT, NT, NU) have higher shipping rates
- [ ] Quebec: special consumer protection rules (verify compliance if applicable)
- [ ] Province codes: 2-letter standard (ON, QC, BC, AB, etc.)
- [ ] No hardcoded province-specific logic in Flutter (all server-side)
- [ ] Tax calculated server-side, not client-side (authoritative)

**Grep for:** `province`, `tax_rate`, `GST`, `HST`, `PST`, `shipping_zone`, `remote`, `territory`

### 6. Tracking Number Flow

**Seller adds tracking -> buyer sees tracking -> auto-status updates.**

**Check:**
- [ ] Seller marks order as `shipped` with: tracking number, carrier name
- [ ] Tracking number validated: alphanumeric, reasonable length (5-50 chars)
- [ ] Carrier name from predefined list (Canada Post, UPS, FedEx, Purolator, etc.)
- [ ] Custom carrier option available (for local couriers)
- [ ] Tracking number stored on order record
- [ ] Buyer notification includes tracking number and carrier
- [ ] Tracking URL generated: carrier-specific URL pattern with tracking number
- [ ] Buyer can click tracking URL to see status on carrier's website
- [ ] Multiple tracking numbers per order supported (partial shipments)
- [ ] Tracking number not modifiable after delivery confirmed

**Grep for:** `tracking_number`, `carrier`, `shipped`, `Canada Post`, `UPS`, `FedEx`, `Purolator`, `tracking_url`

### 7. Delivery Confirmation

**Buyer confirms delivery or auto-timeout triggers delivery.**

**Check:**
- [ ] Buyer can manually confirm delivery from order detail screen
- [ ] Auto-delivery timeout: X days after `shipped` (e.g., 14 days domestic, 30 days international)
- [ ] Timeout implemented as cron job (not checked on each request)
- [ ] Cron runs daily, checks `shipped` orders past timeout window
- [ ] On delivery (manual or auto): order status -> `delivered`
- [ ] On delivery: seller payout scheduled (or triggered)
- [ ] Buyer notified of auto-delivery before it happens (e.g., "Confirm delivery or it will auto-confirm in 3 days")
- [ ] Buyer can dispute delivery before auto-confirmation
- [ ] `deliveredAt` timestamp recorded for return window calculation (30 days from delivery)

**Grep for:** `delivered`, `auto_deliver`, `delivery_timeout`, `confirm_delivery`, `deliveredAt`, `payout`

### 8. Multi-Seller Shipping

**One checkout with multiple sellers creates separate shipments per seller.**

**Check:**
- [ ] Cart items grouped by `sellerId` before shipping calculation
- [ ] Shipping cost calculated independently per seller group
- [ ] Each seller group becomes a separate order record
- [ ] Each order has its own tracking number (independent fulfillment)
- [ ] Each order has its own delivery status (independent state machine)
- [ ] Buyer sees per-seller shipping cost breakdown at checkout
- [ ] Total shipping = sum of per-seller shipping costs
- [ ] Free shipping threshold applied per seller (not per total order)
- [ ] Seller only sees their own order items (not other sellers')

**Grep for:** `sellerId`, `group_by_seller`, `per_seller`, `multi_seller`, `split_order`

### 9. International Shipping

**Base rates from supplier type for cross-border orders.**

**Check:**
- [ ] International shipping detected: buyer country != seller country (or buyer country != CA)
- [ ] International rates higher than domestic
- [ ] Customs declaration fields: item description, value, HS code (if applicable)
- [ ] International orders may have longer delivery timeout (30+ days)
- [ ] Perishable items: international shipping BLOCKED
- [ ] Currency: all amounts in CAD regardless of buyer location
- [ ] International tracking: carrier must support cross-border tracking
- [ ] Seller can opt out of international shipping per product
- [ ] Duties/taxes: clearly communicated as buyer's responsibility (DDU)

**Grep for:** `international`, `country`, `customs`, `cross_border`, `DDU`, `duties`

### 10. Shipping Approval for High-Value Orders

**Orders above a certain value may require additional shipping approval.**

**Check:**
- [ ] High-value threshold defined (if exists)
- [ ] Approval workflow: admin or automated risk check
- [ ] Insurance required for high-value shipments
- [ ] Signature required on delivery for high-value orders
- [ ] High-value orders: explicit logging of shipping decisions
- [ ] If no approval workflow exists: document as P3 (future feature)

**Grep for:** `high_value`, `approval`, `insurance`, `signature_required`, `shipping_approval`

### 11. Warehouse Management

**Seller warehouses: address, coordinates, shipping origin.**

**Check:**
- [ ] Warehouse has: name, address (street, city, province, postal code, country), coordinates (lat/lng)
- [ ] Coordinates auto-populated from postal code (geocoding) or manually entered
- [ ] Seller can have multiple warehouses
- [ ] Default warehouse set for shipping origin
- [ ] Warehouse used for: distance calculation (perishable), shipping cost, ship-from address
- [ ] Warehouse address validated (Canadian postal code format: `A1A 1A1`)
- [ ] Deleted warehouse: orders referencing it keep snapshot (not broken reference)

**Grep for:** `warehouse`, `coordinates`, `lat`, `lng`, `geocode`, `postal_code`, `default_warehouse`

---

## Severity Guide

| Severity | Criteria | Example |
|----------|----------|---------|
| **P0 Critical** | Incorrect charge or delivery violation | Shipping cost calculated as float; perishable shipped 200km; free shipping at $74.99 |
| **P1 High** | Missing validation or broken flow | No tracking number validation; auto-delivery never fires; digital item charged shipping |
| **P2 Medium** | Edge case or UX gap | No "add $X for free shipping" banner; carrier list incomplete; no multi-tracking |
| **P3 Low** | Minor polish or future feature | High-value approval not implemented; international HS codes missing |

## Output Format

For each finding:
```
## [P0/P1/P2/P3] — Title
- **File**: path/to/file.rs:line
- **Issue**: What's wrong
- **Impact**: What could happen (wrong charge, failed delivery, compliance violation)
- **Fix**: Specific code change needed
```
