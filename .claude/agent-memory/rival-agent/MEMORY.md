# Rival Agent Memory

## Last Analysis: 2026-02-21

### P0 Schema Gaps Found
1. Cart has no variantId -- variant products cannot be properly added to cart (doc ID = productId only)
2. Order has no statusHistory -- no audit trail of status transitions

### P1 Schema Gaps Found
- OrderItem schema drift: JSON uses "deliveryStatus" (3 values), Python uses "status" (4 values)
- No return request sub-states (return_requested, return_approved, return_shipped, return_received)
- No brand field on products (top filter facet on every marketplace)
- No slug field for SEO URLs
- No trackingUrl on OrderItem (only trackingNumber + carrier)
- Notifications subcollection undefined in schema despite Collections.NOTIFICATIONS existing
- No review moderation status (pending/published/flagged/removed)
- No inventory reservation tracking (reservedQuantity)

### Scalability Risks Found
- coupons.usedByUids array can exceed 1MB at scale (100K+ users per coupon)
- product_ratings.helpfulVoterIds same problem (50K+ voters)

### What OrignaGTA Does Well (confirmed)
- Immutable order item snapshots
- Multi-warehouse with denormalized stock
- CASL/PIPEDA/Quebec Law 25 compliance fields
- Per-seller commission rate
- Seller metrics collection
- Product Q&A collection
- Dispute tracking with preDisputeStatus
- Digital product support with license keys

### Competitor Patterns Reference
- See detailed analysis in conversation (not persisted -- too large)
- Key competitors consulted: Amazon, Shopify, eBay, Etsy, Walmart, Temu, Mercado Libre, Flipkart, AliExpress
