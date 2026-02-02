# Airwallex & KYC Setup Quickstart Checklist

## AIRWALLEX ACCOUNT SETUP (30-45 MINUTES)

### Pre-Setup
- [ ] Have company legal name ready: "OrignaGta Inc" or similar
- [ ] Have Canadian business address
- [ ] Have business email (you@orignaventures.ca)
- [ ] Have government-issued ID (passport or driver's license)
- [ ] Have company registration documents (Articles of Incorporation)
- [ ] Have proof of address (utility bill from last 3 months)

### Account Creation
- [ ] Go to https://www.airwallex.com/business
- [ ] Click "Sign Up"
- [ ] Select "I want to receive payments from customers"
- [ ] Fill Company Info:
  - [ ] Business Name: OrignaGta Inc
  - [ ] Country: Canada
  - [ ] Industry: E-commerce / Marketplace
  - [ ] Estimated monthly volume: $50,000-$100,000
- [ ] Create password (min 8 chars, 1 number, 1 special char)
- [ ] Accept Terms & Conditions
- [ ] Verify email (check spam folder!)

### Business Verification (KYC)
**This takes 3-5 business days. Do this immediately.**

- [ ] Log into Airwallex Dashboard
- [ ] Navigate to Settings → Verification
- [ ] Upload Documents:
  - [ ] **Director/Owner ID**: Passport or Driver's License (clear front + back)
  - [ ] **Business Registration**: Articles of Incorporation or Certificate
  - [ ] **Proof of Address**: Utility bill, lease agreement, or bank statement (last 3 months, must show company name + address)
- [ ] Fill Business Details:
  - [ ] Business registration number / ID
  - [ ] Business address (must match proof of address)
  - [ ] Director/owner name (must match ID)
  - [ ] Tax ID (Canada: GST/HST number if applicable)
- [ ] Submit for review
- [ ] **Status**: Check every 24 hours. You should see approval within 3-5 business days.
- [ ] **Emails to watch for**: "Verification Complete" or "Additional Information Needed"

### Bank Account Verification
**After business verification approved**

- [ ] Settings → Bank Accounts
- [ ] Add Bank Account:
  - [ ] Account holder name
  - [ ] Bank name
  - [ ] Account number
  - [ ] Transit number (Canadian bank routing)
  - [ ] SWIFT code (if required)
- [ ] Airwallex sends 2 micro-deposits (small amounts like $0.01 + $0.02)
- [ ] Wait 2-3 business days for deposits to arrive
- [ ] Log into Canadian bank account online
- [ ] Note down the 2 amounts Airwallex sent
- [ ] Airwallex Dashboard → Bank Accounts → Verify
- [ ] Enter the 2 amounts
- [ ] **Status**: Bank account verified ✓

### API Credentials & Webhook Setup

#### Get API Keys
- [ ] Airwallex Dashboard → Developers → API Keys
- [ ] Create API Key:
  - [ ] Name: "OrignaGta Production"
  - [ ] Type: "Full Access" (you need all permissions)
  - [ ] Copy: **Client ID** (keep safe!)
  - [ ] Copy: **Client Secret** (NEVER share or commit to git!)
  - [ ] Copy: **API Key** (also keep safe)
- [ ] Store in environment variables:
  ```
  AIRWALLEX_CLIENT_ID=xxxxxx
  AIRWALLEX_CLIENT_SECRET=xxxxxx
  AIRWALLEX_API_KEY=xxxxxx
  ```

#### Setup Webhook Endpoint
- [ ] Developers → Webhooks
- [ ] Add Endpoint:
  - [ ] URL: `https://us-central1-origna-gta.cloudfunctions.net/airwallex_webhook`
  - [ ] Events to subscribe:
    - [ ] `payment.succeeded`
    - [ ] `payment.failed`
    - [ ] `payment.cancelled`
    - [ ] `payment.authorization_expired`
    - [ ] `payout.completed`
    - [ ] `payout.failed`
- [ ] Save
- [ ] Test: Dashboard → Webhooks → Send Test Event
- [ ] Verify: Your endpoint returns 200 OK

### Currency & Payout Settings
- [ ] Settings → Currency Preferences:
  - [ ] Primary: CAD (Canadian Dollars)
  - [ ] Secondary: USD (optional fallback)
- [ ] Settings → Payout Settings:
  - [ ] Schedule: Daily (sellers paid same day)
  - [ ] Minimum payout: $20 CAD
  - [ ] Method: Direct to bank account
- [ ] Settings → Platform Settings:
  - [ ] Enable "Connected Accounts" (for sellers)
  - [ ] Platform fee: 2.5% (you keep this)
  - [ ] Currency: CAD

### Testing (CRITICAL - DO THIS FIRST!)

#### Switch to Sandbox Mode
- [ ] Top-left corner → Switch to "Sandbox"
- [ ] All test transactions here are FAKE (no real money moves)

#### Test Payment Flow
- [ ] Use test credit card: **4111 1111 1111 1111**
  - [ ] Expiry: 12/25
  - [ ] CVV: 123
  - [ ] Name: Any name
- [ ] Follow payment flow in your app
- [ ] **Expected**: Payment shows as "succeeded" in Airwallex dashboard
- [ ] Dashboard → Transactions → See test payment
- [ ] **Verify**: Payment shows $0.00 amount (test only)

#### Test Webhook
- [ ] Developers → Webhooks
- [ ] Click your endpoint
- [ ] "Send Test Event"
- [ ] Check your cloud function logs:
  ```
  Firebase Console → Functions → airwallex_webhook → Logs
  ```
- [ ] **Expected**: Log shows webhook received & processed

#### Test Payout Flow (Sellers)
- [ ] Dashboard → Payouts
- [ ] "Send Payout" (test mode)
- [ ] Select test seller account
- [ ] Amount: $100 CAD
- [ ] **Expected**: Payout shows "pending" then "completed"

### Go Live

#### Switch to Production
- [ ] **BACKUP**: Save all sandbox test IDs for reference
- [ ] Top-left corner → Switch to "Production"
- [ ] **CRITICAL**: Delete/disable test API keys from code
- [ ] **CRITICAL**: Use ONLY production API keys

#### Production API Keys
- [ ] Copy new Production API Keys from dashboard
- [ ] Update environment variables (don't commit!)
- [ ] Test with $1 real payment from test card (may decline)
- [ ] Test with small real purchase ($5) if needed

#### Production Verification
- [ ] Airwallex Dashboard → Transactions
- [ ] See real payments coming in (might take 5-10 min to show)
- [ ] Check webhook logs in Firebase
- [ ] Verify seller got payout in bank account (next business day)

---

## KYC API DECISION: COMPLYADVANTAGE ✓

### Why ComplyAdvantage?
- ✓ Best for Canada marketplace
- ✓ Fast (< 1 sec API response)
- ✓ Affordable ($0.50-2.00 per check)
- ✓ Sanctions screening built-in
- ✓ Easy integration (REST API)
- ✓ Good dashboard for review

### Setup Steps

#### 1. Create Account
- [ ] Go to https://www.complyadvantage.com/signup
- [ ] Sign up as "Business"
- [ ] Company: OrignaGta Inc
- [ ] Country: Canada
- [ ] Use: you@orignaventures.ca
- [ ] Password: Strong (min 12 chars)
- [ ] Verify email

#### 2. Get API Credentials
- [ ] Dashboard → API → API Keys
- [ ] Create API Key:
  - [ ] Name: "OrignaGta KYC"
  - [ ] Type: "KYC Screening"
- [ ] Copy: **API Key**
- [ ] Store in environment:
  ```
  COMPLY_ADVANTAGE_API_KEY=xxxxxx
  ```

#### 3. Configure Settings
- [ ] Settings → Rules & Alerts:
  - [ ] Enable: "PEP Screening" (politically exposed persons)
  - [ ] Enable: "Sanctions List Screening"
  - [ ] Risk threshold: HIGH (only reject obvious fraud)
  - [ ] Automatic rejection: OFF (manual review)
- [ ] Settings → Integration:
  - [ ] Enable: Webhooks
  - [ ] Webhook URL: `https://us-central1-origna-gta.cloudfunctions.net/kyc_webhook`

#### 4. Pricing & Limits
- [ ] Billing → Plan
  - [ ] Choose: "Pay-per-check" (no monthly fee)
  - [ ] Per check cost: ~$1-2 CAD
  - [ ] Monthly estimate: $50-100 (depends on sellers)
- [ ] Limits:
  - [ ] Set daily limit: 1000 checks (plenty for marketplace)

#### 5. Testing
- [ ] API → Documentation
- [ ] Test with API Key in sandbox
- [ ] Sample request:
  ```python
  # See PHASE_4_IMPLEMENTATION_GUIDE.md for full code
  curl -X POST https://api.complyadvantage.com/v1/searches \
    -d '{
      "search_term": "John Smith",
      "country_codes": ["CA"]
    }'
  ```
- [ ] Expected response: Fraud risk score + PEP/sanctions status

---

## ENVIRONMENT VARIABLES CHECKLIST

### Add to Firebase Functions `.env` file
```
# Airwallex
AIRWALLEX_CLIENT_ID=your_client_id
AIRWALLEX_CLIENT_SECRET=your_client_secret
AIRWALLEX_API_KEY=your_api_key

# ComplyAdvantage KYC
COMPLY_ADVANTAGE_API_KEY=your_kyc_api_key

# Stripe (existing, keep)
STRIPE_SECRET_KEY=STRIPE_SECRET_KEY_REDACTED
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx

# Firebase (existing, keep)
FIREBASE_PROJECT_ID=origna-gta
FIREBASE_DATABASE_URL=https://origna-gta.firebaseio.com

# Email
SENDGRID_API_KEY=SG.xxxxx
```

### Add to Flutter `.env` file
```
# Airwallex (publishable/public only)
AIRWALLEX_CLIENT_ID=your_client_id

# Stripe (existing)
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxx

# Firebase (existing)
FIREBASE_PROJECT_ID=origna-gta
```

**CRITICAL**: Never commit `.env` files! Add to `.gitignore`

---

## NEXT STEPS (IN ORDER)

### Week 1: Setup & Core Features
1. **Complete Airwallex account setup** (following checklist above)
2. **Get ComplyAdvantage API key** (following checklist above)
3. **Implement Digital Products** (easy, quick win)
4. **Implement Auth Audits** (comprehensive testing)

### Week 2: Backend Integration
5. **Implement ComplyAdvantage KYC** backend
6. **Implement Airwallex payment service** (Python)
7. **Implement seller approval gates** (frontend + backend)

### Week 3: Frontend & Testing
8. **Implement Airwallex checkout** (Flutter UI)
9. **Implement KYC status UI** (seller experience)
10. **Full E2E testing** (all flows)

---

## SUPPORT & RESOURCES

### Airwallex
- Dashboard: https://dashboard.airwallex.com
- API Docs: https://doc.airwallex.com
- Support: support@airwallex.com
- Phone: +1 (888) AIRWALLEX

### ComplyAdvantage
- Dashboard: https://dashboard.complyadvantage.com
- API Docs: https://docs.complyadvantage.com
- Support: support@complyadvantage.com

### Questions?
- Refer to PHASE_4_IMPLEMENTATION_GUIDE.md for full code examples
- Check Firebase Cloud Functions logs for errors
- Use Sentry for error tracking (P1.7)
