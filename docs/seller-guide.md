# OrignaGTA Seller Onboarding Guide

Complete step-by-step guide for new sellers to set up their shop, list products, and start selling.

---

## Table of Contents

1. [Account Setup](#account-setup)
2. [Seller Registration](#seller-registration)
3. [Add Your First Product](#add-your-first-product)
4. [Manage Orders](#manage-orders)
5. [Payouts & Earnings](#payouts--earnings)
6. [Handle Returns](#handle-returns)
7. [View Analytics](#view-analytics)
8. [FAQ](#faq)

---

## Account Setup

### Step 1: Create an OrignaGTA Account

1. Go to **https://orignagta.ca** (or dev.orignagta.ca for testing)
2. Click **"Sign Up"**
3. Enter your email address
4. Create a strong password (minimum 8 characters)
5. Enter your display name
6. Check the **Cloudflare Turnstile** box (bot verification)
7. Click **"Create Account"**

You'll receive a verification email. Click the link to verify your email address.

### Step 2: Complete Your Profile

After signing in:

1. Click **"Profile"** in the top menu
2. Upload a profile picture (JPG or PNG, max 5MB)
3. Fill in your **Bio** (optional, 1–500 characters)
4. Add your **Phone Number** (E.164 format, e.g., +14165551234)
5. Click **"Save"**

### Step 3: Enable Two-Factor Authentication (MFA)

**Recommended for security:**

1. Go to **Account Settings** → **Security**
2. Click **"Enable Two-Factor Authentication"**
3. Scan the QR code with Google Authenticator or Authy
4. Enter the 6-digit code to verify
5. **Save your backup codes** (printed on screen) in a safe place
6. Click **"Confirm"**

---

## Seller Registration

### Step 1: Request Seller Access

1. Go to **Dashboard** → **Settings** → **Become a Seller**
2. Click **"Apply for Seller Account"**
3. Read the **Seller Terms of Service** and **Return Policy**
4. Check **"I agree to the terms"**
5. Click **"Continue"**

### Step 2: Stripe Connect Onboarding

To receive payouts, you must connect your bank account via Stripe.

1. You'll be redirected to **Stripe Connect** onboarding
2. Enter your **Business Information**:
   - Legal business name
   - Type (sole proprietor, LLC, corporation, partnership)
   - Tax ID (SSN or Business Number)
   - Physical address
3. Enter your **Bank Account Details**:
   - Account holder name
   - Routing number (institution number)
   - Account number
   - Account type (checking or savings)
4. Review and confirm
5. Stripe will verify your information (24–48 hours)

**Status**: After verification, you'll see "Account ready" in your seller dashboard.

### Step 3: Complete Your Store Profile

1. Go to **Dashboard** → **Store Settings**
2. Enter your **Business Name** (displayed to buyers)
3. Write a **Store Description** (1–500 chars):
   - E.g., "We specialize in refurbished electronics with 1-year warranty"
4. Set your **Return Policy**:
   - Default: "30-day money-back guarantee"
   - Can customize to match your business
5. Set your **Shipping Policy**:
   - E.g., "Free standard shipping on orders over $75"
6. Upload your **Store Logo** (JPG/PNG, max 5MB, recommended 256x256px)
7. Click **"Save"**

---

## Add Your First Product

### Step 1: Navigate to Products

1. Go to **Dashboard** → **Products**
2. Click **"+ Add New Product"** (blue button)

### Step 2: Enter Basic Information

**Title** (required, max 200 chars)
```
MacBook Pro 16" 2024 M4 Max
```

**Short Description** (required, 10–500 chars)
```
Latest generation MacBook Pro with M4 Max chip, 36GB unified memory, and 1TB SSD storage.
```

**Long Description** (optional, up to 5000 chars)
```
Detailed product information:

- CPU: Apple M4 Max chip (12-core)
- GPU: 20-core GPU
- RAM: 36GB unified memory
- Storage: 1TB SSD
- Display: 16" Liquid Retina XDR
- Battery: Up to 33 hours

Condition: Brand new, sealed box. Includes original packaging and accessories.

Warranty: Apple 1-year limited warranty + AppleCare+ available.
```

### Step 3: Set Price and Stock

**Price** (required)
```
$1,999.99 CAD
```
- Displayed in CAD
- Stored as integer cents (199999¢)
- Must be between $1.00 and $100,000.00

**Stock Quantity** (required)
```
5 units
```
- Set to 0 to mark out of stock (product remains visible)
- Stock is reserved when buyer checks out
- Stock is released if order is cancelled

### Step 4: Upload Images

1. Click **"+ Add Images"**
2. Select up to 5 images (JPG, PNG, GIF)
3. Images are displayed to buyers in gallery format
4. **First image is the thumbnail** (choose a clear, high-quality image)
5. Recommended resolution: 1200x1200px

**Image Best Practices**:
- Clear, well-lit photos
- Show product from multiple angles
- White or plain background
- File size: max 5MB per image

### Step 5: Categorize Product

**Primary Category** (required)
```
Electronics > Computers > Laptops
```

**Tags** (optional, max 10)
```
apple, laptop, m4, pro, refurbished
```

### Step 6: Product Details

**Product Type**:
- [ ] **Digital Product** (instant delivery, no shipping)
  - Check this if selling software, e-books, licenses, etc.
  - Buyers receive download link immediately after purchase
- [ ] **Perishable** (local delivery only, <50km)
  - Check if selling food, flowers, or other perishable items
  - Shipping restricted to local area
  - Seller notified urgently (24h expiry)

**Physical Properties** (if not digital):
- **Weight**: 2.1 kg
- **Dimensions**: Length 35.97cm, Width 24.8cm, Height 1.55cm
- Used to calculate shipping costs

**SKU** (optional)
```
SKU-MACBOOK-M4-2024
```
Your internal reference number.

### Step 7: Add Specifications (Optional)

Click **"+ Add Specifications"** to add product details:

```
Processor:        Apple M4 Max
RAM:              36GB unified memory
Storage:          1TB SSD
Display:          16" Liquid Retina XDR
Graphics:         20-core GPU
Battery:          Up to 33 hours
Operating System: macOS 14+
Warranty:         1 year
```

### Step 8: Publish Product

**Save as Draft** (only you can see):
```
Click "Save Draft"
```

**Publish to Store** (visible to all buyers):
```
Click "Publish"
```

Products are **active immediately** after publishing. You can edit at any time.

---

## Manage Orders

### View Orders

1. Go to **Dashboard** → **Orders**
2. Filter by status:
   - **Pending**: Payment processing (auto-confirmed in 5 days)
   - **Confirmed**: Payment received, ready to ship
   - **Shipped**: In transit to buyer
   - **Delivered**: Arrived at buyer
   - **Cancelled**: Refunded or cancelled

### Confirm Order Received

**Automatic**: Orders auto-confirm after 5 days of creation.

**Manual**:
1. Click the order
2. Click **"Confirm"**

Once confirmed, Stripe captures the payment and deposits it in your account.

### Ship Order

1. Click **"Mark as Shipped"**
2. Enter **Carrier** (UPS, FedEx, Canada Post, etc.)
3. Enter **Tracking Number**
4. Click **"Ship"**

The buyer will receive:
- Email notification with tracking link
- Updated order status in their account
- Estimated delivery date

### Process a Return

When a buyer requests a return:

1. Go to **Dashboard** → **Returns**
2. You'll see pending return requests
3. Click the return request to see photos and buyer comments

**Approve Return**:
1. Click **"Approve"**
2. Set refund amount (can be partial):
   ```
   Full refund: $1,999.99
   Partial (damaged corner): $1,799.99
   ```
3. Optionally add a message to buyer
4. Click **"Send Return Label"**

Buyer receives return shipping label. Once item arrives and is inspected:
- Refund is automatically processed to their card
- Takes 3–5 business days to appear

**Reject Return** (optional):
1. Click **"Reject"**
2. Provide reason:
   ```
   "Item works perfectly. No defect found."
   ```
3. Click **"Send"**

Buyer is notified and can appeal.

---

## Payouts & Earnings

### View Your Earnings

1. Go to **Dashboard** → **Earnings**
2. See:
   - **Total Earnings (This Month)**: $5,234.67
   - **Pending (Next Payout)**: $2,100.00
   - **Available Balance**: $3,134.67
   - **Lifetime Earnings**: $18,542.50

### Payout Schedule

**Default**: Payouts every 7 days (weekly)

**When Payouts Occur**:
- Order must be **Delivered** (buyer has received it)
- Funds are held for 7 days to allow returns
- After 7 days, funds are transferred to your bank account

**Payout Status**:
- **Pending**: Waiting for order to be delivered
- **In Progress**: Scheduled for next payout (Thursday)
- **Completed**: Transferred to your bank account

### Change Payout Schedule

1. Go to **Dashboard** → **Store Settings** → **Payouts**
2. Select frequency:
   - **Daily** (every weekday)
   - **Weekly** (every Thursday)
   - **Monthly** (end of month)
3. Click **"Update"**

### Verify Bank Account

If your bank account is not verified:

1. Go to **Store Settings** → **Bank Account**
2. Click **"Update Bank Account"**
3. You'll be redirected to Stripe to add/change your account
4. Stripe performs micro-deposits (2 small amounts sent to your account)
5. Verify the amounts in your bank statement
6. Enter the amounts to confirm

Once verified, payouts begin within 1–2 business days.

---

## View Analytics

1. Go to **Dashboard** → **Analytics**
2. See key metrics:

**Product Views**
```
MacBook Pro 16" - 342 views (↑ 23% from last month)
iPad Air - 156 views (↓ 12%)
```

**Sales**
```
Total Sales: 12 units
Total Revenue: $5,234.67
Average Order Value: $435.39
```

**Conversion Rate**
```
Views: 1,847
Sales: 12
Conversion: 0.65%
```

**Top Products**
```
1. MacBook Pro 16" (8 sales)
2. iPad Air (3 sales)
3. Apple Watch (1 sale)
```

**Traffic Source**
```
Search: 45%
Category browse: 30%
Direct: 15%
Referral: 10%
```

### Export Analytics

Click **"Export as CSV"** to download sales data for accounting.

---

## Best Practices for Sellers

### Pricing Strategy

1. **Research Competition**: Check similar products on OrignaGTA
2. **Factor in Costs**:
   - Cost of goods
   - Shipping (if you're covering it)
   - Platform fee (2.5%)
   - Packaging materials
   - Time and labor
3. **Competitive Pricing**: Set prices to compete while maintaining profit

**Example Calculation**:
```
Cost of product:        $800.00
Shipping cost:          $20.00
Packaging:              $5.00
Total cost:             $825.00

Desired profit:         $350.00
Selling price:          $1,175.00

Platform fee (2.5%):    $29.38
Your net:               $320.62 profit
```

### Product Descriptions

Write clear, honest descriptions:

1. **Condition**: New, like-new, refurbished, used
2. **Flaws**: Be transparent about damage or wear
3. **What's Included**: List all accessories and packaging
4. **Specifications**: Technical details buyers care about
5. **Photos**: Show item from multiple angles

**Example**:
```
Condition: Like-New (used for 2 months, light scratches on corner)

Includes:
- Original box and accessories
- Charging cable
- User manual

Minor wear: Small scratch on bottom corner (cosmetic, no impact on function)
```

### Shipping & Returns

1. **Ship Quickly**: Customers expect delivery within 3–5 days
2. **Use Tracking**: Always provide tracking number
3. **Generous Returns**: Builds trust and increases sales
4. **Be Professional**: Respond politely to return requests

### Customer Communication

1. **Respond Quickly**: Answer buyer messages within 24 hours
2. **Be Helpful**: Guide buyers through installation/setup if applicable
3. **Resolve Issues**: Handle complaints professionally to avoid disputes
4. **Ask for Reviews**: After delivery, politely ask buyers to leave feedback

---

## Troubleshooting

### "Stripe Verification Pending"

**Status**: Your Stripe account is under review.

**Solution**:
1. Go to **Store Settings** → **Bank Account**
2. Check Stripe Dashboard for any missing documents
3. Upload required documents (business license, ID, etc.)
4. Wait 24–48 hours for review

### "Payment Declined on Refund"

**Cause**: Buyer's card is expired or closed.

**Solution**:
1. Contact buyer directly (via Order Messages)
2. Ask them to update their payment method with their bank
3. Retry refund after 24 hours

### "Order Not Shipping"

**Standard Process**:
1. Confirm receipt (automatic or manual)
2. Pack item
3. Generate shipping label
4. Drop off at carrier
5. Update order with tracking number

Max 5 days from confirmation to shipping. Contact support if delayed: support@orignagta.ca

### "Return Rate Too High"

**Warning**: If >10% of orders are returned, your account may be flagged.

**Steps to Improve**:
1. Review return reasons (your dashboard shows these)
2. Improve product photos and descriptions
3. Inspect items before shipping
4. Upgrade packaging if items are fragile
5. Contact high-return buyers to understand issues

---

## FAQ

**Q: How long does it take for Stripe verification?**
A: Usually 24–48 hours. If longer, check your Stripe Dashboard for missing documents.

**Q: Can I sell outside Canada?**
A: Currently OrignaGTA only ships within Canada. International shipping coming soon.

**Q: What happens if a buyer never confirms delivery?**
A: Order auto-confirms after 30 days. Your payout is then released.

**Q: Can I edit my product after publishing?**
A: Yes. Click the product and click "Edit". Changes take effect immediately.

**Q: What if I made a pricing mistake?**
A: Edit the product and update the price. New price applies to new orders only. Existing orders use the old price.

**Q: How do I handle digital products?**
A: Check "Digital Product" when creating. After buyer pays, they receive a download link. No shipping required.

**Q: Can I see who viewed my products?**
A: Yes, in Analytics > Product Views. You'll see total views but not individual buyer names (privacy).

**Q: What's the platform fee?**
A: 2.5% of subtotal (not including tax or shipping). Deducted automatically when funds are transferred.

**Q: How do I contact support?**
A: Email support@orignagta.ca with your seller ID and issue details.

---

## Getting Help

- **Live Chat**: Click the chat icon in the bottom right (available 9am–6pm EST, Mon–Fri)
- **Email**: support@orignagta.ca
- **Knowledge Base**: https://help.orignagta.ca
- **Community Forum**: https://community.orignagta.ca (connect with other sellers)

---

## What's Next?

1. ✓ Create account and verify email
2. ✓ Complete seller onboarding (Stripe)
3. ✓ Set up store profile
4. ✓ Upload first product
5. ✓ Wait for first order!

**Bonus Tips**:
- Add 5–10 products to your store before marketing
- Ask friends/family to leave reviews (helps with visibility)
- Monitor Analytics weekly and optimize based on data
- Join the Community Forum to share tips with other sellers

---

**Last Updated**: March 18, 2026  
**Seller Program Version**: 1.0  
**Status**: Active

For detailed API documentation, see `/docs/api-reference.md`
