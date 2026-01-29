# Set your Stripe keys
firebase functions:config:set stripe.secret_key="STRIPE_SECRET_KEY_REDACTED"
firebase functions:config:set stripe.webhook_secret="STRIPE_WEBHOOK_SECRET_REDACTED"
firebase functions:secrets:set MAILJET_API_KEY
firebase functions:secrets:set MAILJET_SECRET_KEY



firebase functions:delete stripe_webhook
# Deploy
firebase deploy --only functions
firebase emulators:start --only functions

# ###################################
firebase functions:delete on_order_updated
firebase deploy --only functions:on_order_updated

firebase functions:delete stripe_webhook 
firebase deploy --only functions:stripe_webhook

firebase functions:delete create_checkout_session 
firebase deploy --only functions:create_checkout_session

firebase functions:delete get_r2_presigned_url 
firebase deploy --only functions:get_r2_presigned_url


firebase functions:delete --all

firebase functions:secrets:set GEOAPIFY_API_KEY
pip3 install -r requirements.txt
source venv/bin/activate 

pip freeze > requirements.txt

firebase functions:config:get

firebase functions:secrets:list

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




# Stripe API Keys (Get from https://dashboard.stripe.com/test/apikeys)
STRIPE_SECRET_KEY=REDACTED_SECRET
STRIPE_WEBHOOK_SECRET=REDACTED_SECRET

# Firebase Service Account (Download from Firebase Console)
# Go to: Project Settings > Service Accounts > Generate New Private Key
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json


FUNCTIONS_EMULATOR=true

R2_ACCOUNT_ID = 9b027cd3919483d27f0abeb2090ac626
R2_ACCESS_KEY = aa9380c4880881c0c93977ee9c01f24a
R2_SECRET_KEY = REDACTED_SECRET

R2_ACCOUNT_ID_NEW = 9b027cd3919483d27f0abeb2090ac626
R2_ACCESS_KEY_NEW = aa9380c4880881c0c93977ee9c01f24a
R2_SECRET_KEY_NEW = REDACTED_SECRET


MAILJET_API_KEY = MAILJET_CREDENTIAL_REDACTED
MAILJET_SECRET_KEY = MAILJET_CREDENTIAL_REDACTED


https://us-central1-orignagta.cloudfunctions.net/stripe_webhook

✔  Deploy complete!

https://stripe-webhook-wwnxr2xxoq-uc.a.run.app


# Local test
firebase emulators:start --only functions

# Deploy only what changed
firebase deploy --only functions:get_r2_presigned_url





# Deploy corrected backend
firebase deploy --only functions:create_checkout_session,functions:stripe_webhook

# Test with Stripe CLI
stripe trigger checkout.session.completed
stripe trigger payment_intent.succeeded

# Check logs
firebase functions:log --only stripe_webhook