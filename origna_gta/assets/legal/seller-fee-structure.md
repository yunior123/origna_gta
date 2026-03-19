# Seller Fee Structure and Payout Policy

**Effective Date:** March 18, 2026  
**Jurisdiction:** Canada  
**Currency:** Canadian Dollars (CAD)

---

## 1. Overview

This document outlines all fees charged to sellers on the OrignaGTA marketplace, how payouts are calculated, and when sellers receive their earnings.

**Key Principle:** OrignaGTA charges sellers **transparently** with a single platform fee; all other costs (payment processing, shipping, taxes) are either built into the platform model or passed through at cost.

---

## 2. Platform Commission Fee

### 2.1 Commission Rate

OrignaGTA charges a **5% platform commission** on the **subtotal** (product price only, before tax and shipping) of each successful order.

**Formula:**
```
Platform Commission = (Product Price) × 5%
```

**Example 1:**
- Product Price: $100.00 CAD
- Tax (13% HST): $13.00
- Shipping (seller's cost): $8.50
- Order Total: $121.50

**Commission Calculation:**
- Subtotal (product only): $100.00
- Platform Fee (5% of $100): **$5.00**
- Seller Nets: $100.00 – $5.00 = **$95.00** (before Stripe fees)

**Example 2 (Multi-Item Order):**
- Product 1: $50.00
- Product 2: $30.00
- Subtotal: $80.00
- Platform Fee (5% of $80): **$4.00**
- Seller Nets: $80.00 – $4.00 = **$76.00** (before Stripe fees)

### 2.2 What Is Included in the 5% Fee

The 5% platform fee covers:

- Marketplace hosting, infrastructure, and uptime
- Payment processing coordination (Stripe integration)
- Buyer and seller support
- Fraud detection and chargeback handling
- Search and product discovery features
- Messaging and dispute resolution platform
- Seller onboarding and account management
- Compliance and legal infrastructure (PIPEDA, CASL, Bill 96)

### 2.3 When Commission Is Charged

The platform commission is deducted when:

1. **Order is placed** and payment is authorized by Stripe
2. **Order reaches "shipped" status** (seller ships the item)
3. **Refund is issued** (commission is refunded to seller proportionally)

**Example with Refund:**
- Original Order: $100 (Commission: $5)
- Buyer requests return
- Return approved and refunded: $100
- Seller receives: Original commission $5 is **refunded** → Seller retains $0 commission on refunded order

---

## 3. Stripe Payment Processing Fees

### 3.1 Stripe Fee Structure

**OrignaGTA absorbs Stripe payment processing fees on behalf of sellers.** Sellers do not see or pay Stripe fees separately.

Stripe's standard rates are:
- **Credit Cards:** 2.9% + $0.30 CAD per transaction
- **Digital Wallets:** 2.9% + $0.30 CAD per transaction
- **Bank Transfers:** Variable (typically 1% + $0.50 CAD)

**Example:**
- Product Price: $100.00
- Stripe processing fee: (2.9% of $100) + $0.30 = $3.20
- **OrignaGTA absorbs:** $3.20
- Seller nets: $100.00 – $5.00 (platform) = $95.00 (after platform fee, before shipping)

### 3.2 Why OrignaGTA Absorbs Stripe Fees

By absorbing Stripe fees, OrignaGTA:

1. **Simplifies seller accounting** — one clear 5% fee, not multiple deductions
2. **Improves seller competitiveness** — sellers don't need to mark up prices to cover payment fees
3. **Maintains platform economics** — OrignaGTA's 5% fee covers all operating costs including payment processing

---

## 4. Tax Handling

### 4.1 Sales Tax Collection and Remittance

**OrignaGTA collects sales tax** on behalf of sellers:

- **GST (Goods and Services Tax):** 5% (applies nationwide)
- **HST (Harmonized Sales Tax):** 13% or 15% (ON, NS, NB, NL, PE, SK)
- **PST (Provincial Sales Tax):** BC, MB, AB, QC (varies by province)

**Process:**
1. OrignaGTA calculates tax based on buyer's postal code and product type
2. Tax is added to the order total at checkout
3. Tax is collected from the buyer via Stripe
4. OrignaGTA remits collected tax to Canada Revenue Agency (CRA) monthly
5. **Seller never handles tax remittance directly**

**Seller Clarity:**
- Sellers see **subtotal (product price only)** and **total with tax** on their dashboard
- The 5% platform commission is calculated on subtotal only (excluding tax)
- Sellers do not owe tax on the platform fee itself

### 4.2 Exemptions and Special Cases

- **Digital Products:** May be exempt from PST (varies by province)
- **Alcohol and Tobacco:** Subject to special excise taxes (seller responsible for classification)
- **Controlled Goods:** Cannabis (provincial markup rules apply)

Sellers selling these items must classify products correctly during listing. OrignaGTA provides guidance and can reject listings that are incorrectly classified.

---

## 5. Shipping Cost Handling

### 5.1 Shipping Is Seller-Set

Each seller sets its own shipping costs based on:

- Seller's location and buyer's location
- Package weight and dimensions
- Shipping method (standard, expedited, express)
- Carrier used (Canada Post, UPS, FedEx, regional)

**Shipping Does Not Count Toward Platform Commission:**

```
Platform Commission = Product Price × 5%
(Shipping is separate and does not affect commission calculation)
```

### 5.2 Shipping Cost Examples

**Example 1: Standard Shipping**
- Product Price: $50
- Shipping Cost (seller sets): $5
- Order Subtotal (for commission): $50
- Platform Commission (5% of $50): $2.50
- Tax (13% HST on $50 product): $6.50
- Buyer Pays Total: $50 + $5 (shipping) + $6.50 (tax) = $61.50
- Seller Receives: $50 – $2.50 (commission) = $47.50 (product net) + shipping revenue

**Example 2: Free Shipping (Threshold)**
- Product Price: $100 (≥$75 threshold)
- Shipping Cost (seller offers free): $0
- Order Subtotal: $100
- Platform Commission (5% of $100): $5.00
- Tax (13% HST on $100): $13.00
- Buyer Pays Total: $100 + $0 (free shipping) + $13 (tax) = $113
- Seller Receives: $100 – $5 (commission) = $95.00 (product net)

---

## 6. Payout Schedule and Processing

### 6.1 Payout Trigger

Sellers receive payouts **after an order reaches "delivered" status**:

1. **Order confirmed:** Payment captured from buyer
2. **Order shipped:** Seller ships item, provides tracking
3. **Order delivered:** Buyer receives item or 7 days pass (auto-delivery)
4. **Payout processed:** Within 2–5 business days of delivery confirmation

### 6.2 Payout Timing

| Stage | Timeline |
|-------|----------|
| **Order Placed** | Immediate (payment captured) |
| **Order Shipped** | Day 1–3 (seller's processing time) |
| **Order Delivered** | Day 4–14 (carrier delivery time) |
| **Payout Processed** | Day 15–19 (2–5 business days after delivery) |
| **Funds in Seller's Bank Account** | Day 18–24 (additional 3–5 business days for bank transfer) |

**Example Timeline:**
- Monday: Buyer places order (payment captured immediately)
- Tuesday–Wednesday: Seller ships
- Friday: Buyer receives
- Friday–Tuesday: OrignaGTA processes payout to Stripe Connect
- Tuesday–Friday: Funds arrive in seller's bank account

### 6.3 Payout Method: Stripe Connect

OrignaGTA uses **Stripe Connect** to handle seller payouts. This means:

- Sellers receive payouts directly to their bank account
- No intermediary service or additional fees
- Sellers maintain Stripe Connect account linked to their OrignaGTA seller profile
- Payout frequency: **Daily** (payouts are batched daily and processed overnight)

**Seller Setup:**
- During seller onboarding, seller creates or links a Stripe Connect account
- Stripe Connect requires business information, banking details, and tax ID
- OrignaGTA does not see seller banking details (handled directly by Stripe)

### 6.4 Stripe Connect Fees (Seller Responsibility)

Sellers using Stripe Connect for payouts may incur:

| Fee Type | Rate | Who Pays |
|----------|------|----------|
| **Transfer Fee** | $0.00 CAD | OrignaGTA (included in 5% commission) |
| **Instant Payout** | Varies | Seller (optional; not recommended) |
| **Chargeback/Dispute** | $15 CAD per chargeback | Seller |

**OrignaGTA Covers:** Standard payout fees are included in the 5% platform commission.

---

## 7. Seller Costs and Net Revenue Breakdown

### 7.1 Complete Revenue Example

**Scenario:** Seller lists a $100 CAD product, ships to Ontario buyer.

| Item | Amount | Notes |
|------|--------|-------|
| **Buyer Sees:** | | |
| Product Price | $100.00 | |
| HST (13%) | $13.00 | Collected for CRA remittance |
| Shipping (optional) | $0.00 | Free shipping (≥$75 threshold) |
| **Buyer Total** | **$113.00** | |
| | | |
| **Seller Receives:** | | |
| Gross Product Sale | $100.00 | Before deductions |
| Platform Commission (5%) | -$5.00 | |
| Stripe Processing Fee | -$2.90 | OrignaGTA absorbs |
| (Paid from platform commission) | | |
| **Net Product Revenue** | **$92.10** | |
| | | |
| **Seller Shipping:** | | |
| Shipping Revenue (seller sets) | $0.00 | Free shipping offered |
| Shipping Cost (actual carrier) | -$8.50 | Seller's cost |
| **Net Shipping** | **-$8.50** | Seller loses $8.50 |
| | | |
| **Final Seller Net** | **$83.60** | After all fees and shipping |
| | | |
| **Seller Payout (via Stripe)** | **$83.60** | No additional fees |

### 7.2 Seller Profitability Strategy

For sellers to remain profitable:

1. **Price Products Appropriately:** Account for shipping costs when setting price
   - **Strategy 1:** Build shipping cost into product price ($108 product → $8 shipping margin)
   - **Strategy 2:** Offer free shipping only on high-margin products
   - **Strategy 3:** Use regional shipping rates (cheaper for nearby zones)

2. **Negotiate Carrier Rates:** Sellers with high volume can negotiate lower carrier rates

3. **Optimize Fulfillment:** Use local warehouses to reduce shipping distances and costs

4. **Use Expedited Shipping Sparingly:** Standard shipping is cheaper; offer expedited as premium option

---

## 8. No Additional Fees

OrignaGTA does **not** charge:

- ✓ **Monthly subscription fee** — No flat fee per month
- ✓ **Listing fee** — Products can be listed unlimited times
- ✓ **Activation fee** — Account creation is free
- ✓ **Feature fee** — No extra cost to use seller tools
- ✓ **Withdrawal fee** — Stripe Connect transfers are free
- ✓ **Chargeback dispute fee** (normally) — Covered in platform commission
- ✓ **Support fee** — Seller support is included

---

## 9. Premium Seller Subscription (Future)

**Coming Soon:** OrignaGTA plans to offer a voluntary premium seller subscription with enhanced features:

- **Estimated Price:** $9.99 CAD/month (starting)
- **Benefits (TBD):**
  - Sponsored product listings (priority search results)
  - Enhanced seller badge (verified seller icon)
  - Advanced analytics dashboard
  - Priority customer support
  - Early access to new seller tools

**Important:** Premium subscription is **optional**. All sellers can succeed with the base 5% commission model.

---

## 10. Refunds and Chargeback Policy

### 10.1 Refund Processing

When a buyer requests a refund:

1. **Seller approves return request** (within 48 hours)
2. **Buyer ships item back**
3. **Seller receives return** (within 7–14 days)
4. **Seller inspects and approves refund** (within 5 business days)
5. **Refund issued to buyer** via Stripe
6. **Platform commission refunded to seller**

**Example:**
- Original Sale: $100 (Commission: $5)
- Refund Issued: $100
- Seller Commission Refunded: $5
- Seller Net Impact: $0 (no commission on refunded order)

### 10.2 Chargeback and Dispute Protection

If a buyer initiates a chargeback with their bank:

1. **Stripe investigates** the chargeback claim
2. **Evidence submitted:** Seller provides tracking, communication, and order details
3. **Outcome:**
   - **Chargeback lost:** Seller's account is debited $100 + $15 chargeback fee
   - **Chargeback won:** Seller retains the $100; no fee

**Seller Protections:**
- High-quality tracking and signatures reduce chargeback risk
- Clear messaging with buyers reduces disputes
- Sellers with <1% chargeback rate get chargeback fee waived (Stripe benefit)

---

## 11. Account Suspension and Fee Disputes

### 11.1 Suspension for Non-Compliance

OrignaGTA may suspend seller accounts for:

- Selling prohibited items
- Fraudulent listings or refund requests
- Payment method issues (declined cards)
- Excessive chargebacks (>1% of orders)
- Violating Terms of Service

**Payout Impact:** Suspended sellers do not receive payouts for new orders. Existing completed orders are still paid out.

### 11.2 Fee Dispute Process

If a seller disputes a commission charge or payout:

1. **Contact Support:** Email seller@orignagta.ca with order ID and details
2. **Investigation:** OrignaGTA reviews transaction and fee calculation (3–5 business days)
3. **Resolution:**
   - If error found: Fee is refunded or adjusted
   - If no error: Explanation provided; seller can appeal to legal@orignagta.ca

---

## 12. Transparency and Reporting

### 12.1 Seller Dashboard Reporting

Sellers have real-time access to:

- **Sales Dashboard:** Revenue, number of orders, top products
- **Commission Report:** Total platform fees paid this month/year
- **Payout History:** All completed payouts with dates and amounts
- **Tax Summary:** Tax collected on seller's behalf (for seller's records)
- **Chargeback Report:** Any chargebacks and their status

**Report Example:**
```
March 2026 Seller Summary
========================
Total Sales (Subtotal):        $5,200.00
Platform Commission (5%):       -$260.00
Orders Shipped:                 52
Average Order Value:            $100.00
Payout Processed:               $5,000+ (varies by delivery)
```

### 12.2 Tax Documentation

OrignaGTA provides **monthly T5A equivalent statements** (for Canadian tax purposes):

- Total gross sales
- Platform commission paid
- Tax collected on seller's behalf
- Payout amounts

Sellers use these statements for their own tax filing (GST/HST returns, income tax).

---

## 13. Contact and Disputes

For questions about fees, payouts, or commissions:

**OrignaGTA Seller Support**
- **Email:** seller@orignagta.ca
- **Response Time:** Within 24 hours
- **Escalation:** legal@orignagta.ca for disputes

**Stripe Connect Support** (for payout-specific issues)
- **Link:** https://support.stripe.com
- **Account:** Seller's Stripe Connect account

---

## 14. Changes to Fee Structure

OrignaGTA reserves the right to modify the fee structure with **60 days' notice** to affected sellers. Changes will not apply retroactively to existing orders.

**Email notification** is sent to all sellers at least 60 days before any fee change. Sellers can contact support@orignagta.ca to discuss impact on their business.

---

**Last Updated:** March 18, 2026

**Disclaimer:** This policy is a template. Before implementation, consult with a qualified Canadian accountant and lawyer to ensure compliance with CRA regulations, GST/HST filing requirements, and provincial business law. This policy does not constitute tax or financial advice.
