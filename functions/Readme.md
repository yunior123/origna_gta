# Set your Stripe keys
firebase functions:config:set stripe.secret_key="STRIPE_SECRET_KEY_REDACTED"
firebase functions:config:set stripe.webhook_secret="STRIPE_WEBHOOK_SECRET_REDACTED"
firebase functions:secrets:set MAILJET_API_KEY
firebase functions:secrets:set MAILJET_SECRET_KEY
firebase functions:secrets:set ALGOLIA_APP_ID
firebase functions:secrets:set ALGOLIA_SEARCH_API_KEY
firebase functions:secrets:set ALGOLIA_WRITE_API_KEY



firebase functions:delete stripe_webhook
# Deploy
firebase deploy --only functions
firebase emulators:start --only functions

firebase emulators:start --only functions --inspect-functions
firebase emulators:start --only functions --port 8081


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




# Stripe API Keys (Get from https://dashboard.stripe.com/test/apikeys)

# Firebase Service Account (Download from Firebase Console)
# Go to: Project Settings > Service Accounts > Generate New Private Key



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