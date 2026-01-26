# Set your Stripe keys
firebase functions:config:set stripe.secret_key="STRIPE_SECRET_KEY_REDACTED"
firebase functions:config:set stripe.webhook_secret="STRIPE_WEBHOOK_SECRET_REDACTED"

# Deploy
firebase deploy --only functions
firebase emulators:start --only functions

# firebase functions:config:set stripe.secret_key="sk_live_..."
# firebase functions:config:set stripe.webhook_secret="whsec_..."
# ```


# 2. Configure Stripe Keys
# For Production:
# bashfirebase functions:config:set stripe.secret_key="sk_live_..."
# firebase functions:config:set stripe.webhook_secret="whsec_..."
# ```

# **For Local Testing:**
# Create `.env` file:
# ```
# STRIPE_SECRET_KEY=sk_test_...
# STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET_REDACTED...
# FUNCTIONS_EMULATOR=true
# 3. Deploy
# bashfirebase deploy --only functions
# 4. Configure Stripe Webhook
# In Stripe Dashboard → Webhooks, add endpoint:

# URL: https://YOUR-REGION-YOUR-PROJECT.cloudfunctions.net/stripe_webhook
# Events: checkout.session.completed, checkout.session.expired, payment_intent.succeeded, payment_intent.payment_failed

# Testing Locally
# bashfirebase emulators:start --only functions
# Use test cards from Stripe Testing:

# Success: 4242 4242 4242 4242
# Declined: 4000 0000 0000 0002


Basic Health Check
bashcurl http://127.0.0.1:5001/orignagta/us-central1/health_check
Create Customer
bashcurl -X POST http://127.0.0.1:5001/orignagta/us-central1/create_customer \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "name": "Test User"
  }'
Create Payment Intent
bashcurl -X POST http://127.0.0.1:5001/orignagta/us-central1/create_payment_intent \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 1000,
    "currency": "usd",
    "customer_id": "cus_xxxxx"
  }'
Get Payment Methods
bashcurl -X POST http://127.0.0.1:5001/orignagta/us-central1/get_payment_methods \
  -H "Content-Type: application/json" \
  -d '{
    "customer_id": "cus_xxxxx"
  }'
Confirm Payment
bashcurl -X POST http://127.0.0.1:5001/orignagta/us-central1/confirm_payment \
  -H "Content-Type: application/json" \
  -d '{
    "payment_intent_id": "pi_xxxxx"
  }'
Refund Payment
bashcurl -X POST http://127.0.0.1:5001/orignagta/us-central1/refund_payment \
  -H "Content-Type: application/json" \
  -d '{
    "payment_intent_id": "pi_xxxxx",
    "amount": 500
  }'
Stripe Webhook (simulate)
bashcurl -X POST http://127.0.0.1:5001/orignagta/us-central1/stripe_webhook \
  -H "Content-Type: application/json" \
  -H "Stripe-Signature: test_signature" \
  -d '{
    "type": "payment_intent.succeeded",
    "data": {
      "object": {
        "id": "pi_xxxxx"
      }
    }
  }'
Note: Replace cus_xxxxx and pi_xxxxx with actual IDs you get from creating customers and payment intents. Start with the health check, then create a customer, and use that customer ID for subsequent requests.