# START HERE: Phase 4 Implementation Roadmap

## Your Action Items (What To Do RIGHT NOW)

### THIS WEEK (Next 3-4 days)

#### 1. **Create Airwallex Account** (2 hours)
- [ ] Go to https://www.airwallex.com/business
- [ ] Sign up (use you@orignaventures.ca)
- [ ] Company: OrignaGta Inc, Country: Canada
- [ ] Verify email
- [ ] IMPORTANT: You'll need to upload documents for KYC approval (3-5 business days)

**Documents Needed:**
- Passport or Driver's License (your personal ID)
- Articles of Incorporation (company registration)
- Proof of Address (utility bill from last 3 months)
- Canadian bank account details for payout

See: **AIRWALLEX_KYC_SETUP_CHECKLIST.md** for detailed steps

#### 2. **Create ComplyAdvantage Account** (1 hour)
- [ ] Go to https://www.complyadvantage.com/signup
- [ ] Sign up for Business
- [ ] Company: OrignaGta Inc, Country: Canada
- [ ] Get API Key from dashboard

See: **AIRWALLEX_KYC_SETUP_CHECKLIST.md** for detailed steps

#### 3. **Implement Digital Products (No Shipping)** (3-4 hours)
**This is your easy win while waiting for Airwallex KYC approval!**

What it does: Let sellers mark products as "digital" (no shipping required)

Implementation steps:
1. Open `origna_gta/lib/models/product.dart`
   - Add field: `bool shippingRequired = true;` 
   
2. Open `origna_gta/lib/screens/add_product_screen.dart`
   - Add toggle: "Is this a digital product?"
   - When ON: Hide shipping fields
   - Pass `shippingRequired: false` to backend
   
3. Open `origna_gta/lib/screens/checkout_screen.dart`
   - Before showing shipping address section:
     ```dart
     if (product.shippingRequired) {
       // Show address fields
     } else {
       // Skip to payment
     }
     ```
   
4. Backend: `functions/main.py` - `create_checkout_session()`
   - Don't calculate shipping if `shippingRequired == false`
   - Set `shipping: { cost: 0, method: null }`

5. Test:
   - Create digital product
   - Verify shipping fields hidden in checkout
   - Process order without shipping section
   - Verify no shipping cost charged

---

### WEEK 2 (Days 5-10)

Once Airwallex KYC is approved:

#### 4. **Complete Airwallex Setup** (2-3 hours)
- [ ] Verify bank account (they'll send micro-deposits)
- [ ] Get API credentials (Client ID, Secret, API Key)
- [ ] Setup webhook URL: `https://us-central1-origna-gta.cloudfunctions.net/airwallex_webhook`
- [ ] Test with sandbox API keys first

#### 5. **Implement Auth Flows Audit** (4-5 hours)
Go through EVERY auth flow and test:
- [ ] Sign up → email verification → can use app
- [ ] Forgot password → reset email → new password works
- [ ] Sign in → works with correct password
- [ ] Sign out → clears session properly
- [ ] Session timeout → after 30 min inactivity
- [ ] Rate limiting → 5 failed attempts = 15 min lockout

Create test file: `origna_gta/integration_test/auth_flows_test.dart`

#### 6. **Implement Seller Approval Gates** (2-3 hours)
Make it so sellers must be approved before they can add products:

Frontend changes:
1. `origna_gta/lib/features/seller/add_product_screen.dart`
   ```dart
   if (seller.status != 'approved') {
     showDialog("Your account must be approved to add products");
     return;
   }
   ```

2. `origna_gta/lib/screens/seller_dashboard_screen.dart`
   - Check same status before showing dashboard

Database changes:
1. `firestore.rules` - Add rule:
   ```javascript
   allow create: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.sellerStatus == 'approved';
   ```

2. Admin panel: Add "Approve/Reject Seller" button
   - Updates: `users/[sellerId]/sellerStatus` to "approved" or "rejected"

---

### WEEK 3 (Days 11-15)

#### 7. **Integrate ComplyAdvantage KYC** (4-5 hours)
After seller submits registration form:
1. Call ComplyAdvantage API: `POST /v1/searches`
2. Get fraud score + sanctions check
3. Save result to Firestore
4. Auto-approve if low risk, flag for manual review if high risk

Implementation:
- New file: `functions/kyc_service.py`
- New function: `kyc_verify_seller` in `functions/main.py`
- Tests: `functions/tests/test_kyc_integration.py`

#### 8. **Integrate Airwallex Payment Processing** (6-7 hours)
Make it so sellers can choose Stripe OR Airwallex for payments

Implementation:
- New file: `functions/airwallex_service.py`
- New functions:
  - `airwallex_create_customer` (onboard seller)
  - `airwallex_process_payment` (authorize payment)
  - `airwallex_capture_payment` (capture after shipping)
  - `airwallex_webhook` (handle payment events)
  
- Update: `functions/main.py`
  - Modify `create_checkout_session()` to route to Stripe or Airwallex
  - Modify `capture_payment()` to work with both providers

#### 9. **Update Frontend for Airwallex** (3-4 hours)
- Add payment method selection during seller registration
- Update checkout to support both Stripe and Airwallex payment forms
- Show seller payout status in dashboard

---

### WEEK 4 (Days 16-20)

#### 10. **Admin MFA (2FA)** (2-3 hours)
Secure admin accounts with Google Authenticator codes

Implementation:
- New file: `functions/mfa_service.py` (TOTP generation)
- New endpoints: `enable_mfa`, `disable_mfa`, `verify_mfa_login`
- Frontend: Admin settings screen → "Enable 2FA"

#### 11. **Full E2E Testing** (4-5 hours)
Test complete flows:
- [ ] Buy digital product (no shipping)
- [ ] Buy physical product (with Stripe)
- [ ] Buy physical product (with Airwallex, China seller)
- [ ] Seller registration → KYC approval
- [ ] Seller creates product → needs approval before visible
- [ ] Admin approves seller → seller can now sell

#### 12. **Pre-Release Audit** (3-4 hours)
- [ ] Security review (password validation, API keys, etc)
- [ ] Performance testing (load test with 100 concurrent users)
- [ ] Accessibility audit (can users with screen readers use it?)
- [ ] Mobile testing (test on real phones, not just simulator)

---

## Timeline Summary

| Week | Focus | Days | Status |
|------|-------|------|--------|
| 1 | Setup (Airwallex/KYC account), Digital Products | 3-4 | 🔜 NEXT |
| 2 | Auth audit, Seller gates, Complete Airwallex setup | 5-6 | TBD |
| 3 | KYC integration, Airwallex payment processing | 8-10 | TBD |
| 4 | Admin MFA, E2E testing, Pre-release audit | 9-12 | TBD |
| **Total** | **Full Phase 4** | **25-32 days** | ✅ Estimated |

---

## Key Resources

**Documentation Files Created:**
1. **PHASE_4_IMPLEMENTATION_GUIDE.md** - Detailed technical guide for all features
2. **AIRWALLEX_KYC_SETUP_CHECKLIST.md** - Step-by-step account setup checklist
3. This file - Quick action items roadmap

**Code Examples Location:**
- See **PHASE_4_IMPLEMENTATION_GUIDE.md** for:
  - Python code for Airwallex integration
  - Dart code for UI components
  - Backend function implementations
  - Database schemas

---

## Questions?

If you get stuck:

1. **For Airwallex setup**: Refer to **AIRWALLEX_KYC_SETUP_CHECKLIST.md**
2. **For coding help**: Refer to **PHASE_4_IMPLEMENTATION_GUIDE.md** - has full code examples
3. **For questions**: Just ask me! I can help debug or explain concepts.

---

## READY TO START?

**Recommended First Action:**
1. ✅ Create Airwallex account (do this TODAY)
2. ✅ Create ComplyAdvantage account (do this TODAY)
3. ✅ Implement digital products while waiting for KYC approval (do this tomorrow)

Let me know when you're ready, and I can help with:
- Creating the digital products feature
- Explaining any code in detail
- Debugging issues as they come up
- Testing the features

**Let's go! 🚀**
