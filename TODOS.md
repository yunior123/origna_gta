


## External Manual Backlog (Future)

Console Firebase — Supprimer l'ancien app iOS com.example.orignaGta, ajouter la nouvelle avec ca.orignagta.app, re-télécharger GoogleService-Info.plist (il manquera le REVERSED_CLIENT_ID pour Google Sign-In)
Apple Developer Portal — Créer l'App ID ca.orignagta.app, activer les capabilities Push Notifications et Associated Domains
APNs — Créer une clé APNs (ou certificat) et l'uploader dans Firebase Console → Project Settings → Cloud Messaging → Apple app
Déployer le AASA — Le fichier apple-app-site-association est dans web/.well-known/ — il sera servi automatiquement si le site est hosté avec Firebase Hosting (ajouter un rewrite dans firebase.json si nécessaire avec Content-Type: application/json)
Google Sign-In — Après régénération du GoogleService-Info.plist, ajouter le REVERSED_CLIENT_ID comme URL scheme supplémentaire dans Info.plist


Voici les 3 entitlements à activer dans le Apple Developer Portal (Identifiers → ca.orignagta.app → Capabilities) :

Capability	Entitlement	Pourquoi
Push Notifications	aps-environment	Firebase Cloud Messaging / notifications de commandes
Associated Domains	com.apple.developer.associated-domains	Universal Links pour les retours Stripe (/payment-success, /seller-return, etc.)
Sign in with Apple	com.apple.developer.applesignin	Obligatoire — Apple rejette les apps qui offrent Google Sign-In sans aussi offrir Sign in with Apple (App Store Review Guideline 4.8)
Étapes dans le portail Apple :
Identifiers → Create/Edit App ID ca.orignagta.app
Cocher : ✅ Push Notifications, ✅ Associated Domains, ✅ Sign in with Apple
Keys → Créer une clé APNs → l'uploader dans Firebase Console (Project Settings → Cloud Messaging)
Profiles → Générer un Provisioning Profile de développement et de distribution avec ces capabilities
Changer aps-environment de development à production avant la soumission App Store
Note importante : Puisque vous offrez Google Sign-In, vous devrez aussi implémenter Sign in with Apple dans l'app Flutter (package sign_in_with_apple) avant de soumettre sur l'App Store — c'est une exigence Apple.

Ce qui nécessite l'Apple Developer Program ($99/an) :
Feature	Pourquoi
Push Notifications	Capability aps-environment
Universal Links (retour auto depuis Stripe)	Capability Associated Domains
Sign in with Apple	Capability + obligatoire pour l'App Store si tu offres Google Sign-In
App Store submission	Distribution via TestFlight ou App Store


cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta && sed -i '' '/CODE_SIGN_ENTITLEMENTS = Runner\/Runner.entitlements;/d' ios/Runner.xcodeproj/project.pbxproj
Les 3 références CODE_SIGN_ENTITLEMENTS sont supprimées. Tu peux maintenant relancer flutter run. Le fichier Runner.entitlements reste dans le repo pour plus tard quand tu auras le Apple Developer Program — il suffira de réajouter les lignes dans le pbxproj.
For future manual setup:
0. google mcp integration
1. mcp for api
2. web mcp
3. docs for 1 and 2




10.**Cloud Scheduler frequency** — Cron jobs should run at the minimum effective frequency (e.g. every 5 minutes, not every minute) to reduce invocations while still meeting timing requirements.


11. mcp for store


# Add Product — Full Code Audit
**Files audited:** `Product.json`, `add_product_state.dart`, `add_product_viewmodel.dart`, `addproduct_screen.dart`, `product_repository.dart`, `supplier_config.dart`, `schema_constants.dart`

---


22. playwright ai agents integration


33. create a system similar to this to track schema, it should also include subcollection, collection organization, do it collection by collection when it comes to db to have a clear understanding

## 5. Cross-Stack Field Verification ✅

| Field         | Dart (Fields.*)  | Python (Fields.*) | Firestore Value  | Status |
|---------------|-----------------|-------------------|-----------------|--------|
| questionText  | questionText     | QUESTION_TEXT     | 'question'      | ✅ Match |
| answerText    | answerText       | ANSWER_TEXT       | 'answer'        | ✅ Match |
| askerId       | askerId          | ASKER_ID          | 'askerId'       | ✅ Match |
| isAnswered    | isAnswered       | IS_ANSWERED       | 'isAnswered'    | ✅ Match |
| sellerId      | sellerId         | SELLER_ID         | 'sellerId'      | ✅ Match |
| productId     | productId        | PRODUCT_ID        | 'productId'     | ✅ Match |
| questionId    | questionId       | QUESTION_ID       | 'questionId'    | ✅ Match |
| upvotes       | upvotes          | UPVOTES           | 'upvotes'       | ✅ Match |



- **[F-175]** Missing variant-specific images (High return rate risk).

- **[F-43]** No UCP machine-readable discovery (Agentic commerce gap).

### [F-47] AI-Assisted Listing
Implement "Magic Upload": generate product name, description, and categories from a single image.
- **Priority:** P1 (Seller experience).

### [F-44] AI-Dispute Mediation
Use RAG-based LLMs to auto-resolve 70% of buyer/seller disputes without admin intervention.
- **Priority:** P1 (Scalability).

- **[F-43]** No UCP machine-readable discovery (Agentic commerce gap).
- **Decision [F-43]**: UCP (Universal Commerce Protocol) implementation needs detailed specification for the machine-readable endpoint.


- **[F-239] Photo Moderation:** No automated safety check (Google Vision) for review photos.

 I will examine e2e/playwright.config.dev.ts to determine whether it targets a remote environment or requires local
  emulators.

╭───────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  ReadFile e2e/playwright.config.dev.ts                                                                          │
│                                                                                                                   │
╰───────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ I will read scripts/deploy_rules.sh to understand its deployment target and ensure it doesn't inadvertently deploy to
  an unintended environment.

╭───────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  ReadFile scripts/deploy_rules.sh                                                                               │
│                                                                                                                   │
╰───────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ I will read scripts/install_git_hooks.sh to see how the git hooks are configured and which scripts they are intended to
  trigger.

╭───────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  ReadFile scripts/install_git_hooks.sh                                                                          │
│                                                                                                                   │
╰───────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
✦ I will check the Firebase login status to ensure I have the necessary permissions to execute the deployment steps in
  the pre-push hook.

╭───────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ ✓  Shell firebase projects:list [current working directory /Users/yuniorrodriguezosorio/Documents/GitHub/origna_… │
│                                                                                                                   │
│ ├───────────────────────┼─────────────────────────┼────────────────┼─────────────────────────┤                    │
│ │ origna-ventures       │ origna-ventures         │ 651976388489   │ [Not specified]         │                    │
│ ├───────────────────────┼─────────────────────────┼────────────────┼─────────────────────────┤                    │
│ │ OrignaGTA             │ orignagta               │ 935641055788   │ [Not specified]         │                    │
│ ├───────────────────────┼─────────────────────────┼────────────────┼─────────────────────────┤                    │
│ │ OrignaGTA Dev         │ orignagta-dev (current) │ 245187519087   │ [Not specified]         │                    │
│ ├───────────────────────┼─────────────────────────┼────────────────┼─────────────────────────┤                    │
│ │ OrignaGTA Staging     │ orignagta-staging       │ 440582189942   │ [Not specified]         │                    │
│ ├───────────────────────┼─────────────────────────┼────────────────┼─────────────────────────┤                    │
│ │ OrignaL               │ orignal-interactive     │ 41434084644    │ [Not specified]         │                    │
│ ├───────────────────────┼─────────────────────────┼────────────────┼─────────────────────────┤                    │
│ │ ucidevs               │ ucidevs-3947e           │ 411288328981   │ northamerica-northeast1 │  




-Claude cookbook github

why were these removed, how are disputes handled in the code

    # Dispute handlers
    "process_charge_refunded",
    "process_dispute_created",
    "process_dispute_closed",
    "process_dispute_updated",
    "process_dispute_funds_reinstated",






    digital-product-e2e.spec.ts
B. Digital-Only Checkout › B.2 Buy digital software product → license key created on order itemchromium
2.5m
digital-product-e2e.spec.ts:123
B. Digital-Only Checkout › B.3 Buy digital book product → book license created with bookSourceUrlchromium
2.6m
digital-product-e2e.spec.ts:158
C. Mixed Cart — Digital + Physical › C.2 Mixed cart checkout creates order with both digital and physical itemschromium
1.0m
digital-product-e2e.spec.ts:210
D. License Activation & Book Download › D.1 Activate software license on a new device → approved with downloadUrlschromium
975ms
digital-product-e2e.spec.ts:321
D. License Activation & Book Download › D.2 Re-activating same device is idempotent (no duplicate activation entry)chromium
4.0s
digital-product-e2e.spec.ts:337
D. License Activation & Book Download › D.3 Generate book download session → single-use downloadUrl returnedchromium
147ms
digital-product-e2e.spec.ts:355
E. Security & Access Control › E.4 Book download session token is single-use (second use of same token fails)chromium
153ms
digital-product-e2e.spec.ts:474
G. Software Download Session › G.1 generate_software_download_session → downloadUrl with /sdl?t= tokenchromium
0ms
digital-product-e2e.spec.ts:610
G. Software Download Session › G.2 software download token is single-use (second use returns 410)chromium
0ms
digital-product-e2e.spec.ts:623
G. Software Download Session › G.5 generate_software_download_session on a book license is rejectedchromium
0ms
digital-product-e2e.spec.ts:661
H. License Management — Deactivate, Verify, Device Limit, Revoke › H.1 deactivate_license removes device — remaining activations decrementedchromium
487ms
digital-product-e2e.spec.ts:777
H. License Management — Deactivate, Verify, Device Limit, Revoke › H.2 After deactivation, same device can be re-activated (slot freed)chromium
518ms
digital-product-e2e.spec.ts:796
H. License Management — Deactivate, Verify, Device Limit, Revoke › H.6 verify_license re-activates idempotently — no duplicate in activations arraychromium
715ms
digital-product-e2e.spec.ts:836
I. Digital Business Rules › I.2 License is revoked when order is refunded (revoke_digital_licenses_for_order)chromium
540ms
digital-product-e2e.spec.ts:922
stock-notif.spec.ts
1. UI — Notify Me Button on OOS Product › 1.1 OOS product shows notify section (not add-to-cart)chromium
56.9s
stock-notif.spec.ts:97
1. UI — Notify Me Button on OOS Product › 1.2 Notify Me button is visible and labelled correctly when not subscribedchromium
53.6s
stock-notif.spec.ts:113
1. UI — Notify Me Button on OOS Product › 1.3 Tapping Notify Me subscribes and toggles to cancel statechromium
56.6s
stock-notif.spec.ts:131
1. UI — Notify Me Button on OOS Product › 1.4 Tapping the button a second time unsubscribes (toggle)chromium
577ms
stock-notif.spec.ts:163
1. UI — Notify Me Button on OOS Product › 1.5 Guest user tapping Notify Me sees login promptchromium
22.9s
stock-notif.spec.ts:191
1. UI — Notify Me Button on OOS Product › 1.6 In-stock product shows Add to Cart (not Notify Me)chromium
52.0s
stock-notif.spec.ts:211
1. UI — Notify Me Button on OOS Product › 1.7 Own product (seller) shows "Your Product" message not Notify Mechromium
34.4s
stock-notif.spec.ts:225
2. UI — Stock Restored Removes Notify Me › 2.1 OOS product shows Notify Me, then after stock restored shows Add to Cartchromium
49.2s
stock-notif.spec.ts:289
3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.1 Subscribe to OOS product returns subscribed:truechromium
146ms
stock-notif.spec.ts:344
3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.2 Duplicate subscribe is idempotent (no error, no duplicate doc)chromium
184ms
stock-notif.spec.ts:353
3. API — subscribe_stock_notification / unsubscribe_stock_notification › 3.5 Subscribe without variantKey (product-level) workschromium
145ms
stock-notif.spec.ts:402
4. Security — Adversarial Scenarios › 4.1 Buyer cannot unsubscribe another user's notificationchromium
112ms
stock-notif.spec.ts:490
multi-seller-orders.spec.ts
Multi-Seller Orders › Cart with multiple items creates single orderchromium
2.4m
multi-seller-orders.spec.ts:43
Multi-Seller Orders › Multi-seller cart creates order with correct itemschromium
2.5m
multi-seller-orders.spec.ts:53
Multi-Seller Orders › Multi-country + Multi-seller cart creates orderchromium
2.9m
multi-seller-orders.spec.ts:65
Multi-Seller Orders › Per-item status tracking works for multi-item orderchromium
9.0s
multi-seller-orders.spec.ts:87
Multi-Seller Orders › Wrong seller cannot update another seller itemschromium
2.5m
multi-seller-orders.spec.ts:114
Multi-Seller Orders › Seller cannot update order-level status for multi-seller orderchromium
3.0m
multi-seller-orders.spec.ts:136
new-coverage-e2e.spec.ts
1. Stock Notification Subscribe/Unsubscribe › 1.1 Subscribe to out-of-stock notificationchromium
373ms
new-coverage-e2e.spec.ts:53
1. Stock Notification Subscribe/Unsubscribe › 1.2 Duplicate subscribe is idempotentchromium
181ms
new-coverage-e2e.spec.ts:68
2. Digital Product Purchase → License Generation › 2.1 Purchasing a digital product creates a license after capturechromium
3.0m
new-coverage-e2e.spec.ts:119
4. Multi-Seller Cart → Per-Seller Payout Verification › 4.1 Multi-seller cart creates order with items from both sellerschromium
2.9m
new-coverage-e2e.spec.ts:229
4. Multi-Seller Cart → Per-Seller Payout Verification › 4.2 Each seller item has independent status trackingchromium
3.0m
new-coverage-e2e.spec.ts:251
4. Multi-Seller Cart → Per-Seller Payout Verification › 4.3 Payout amounts are computed per-seller after capturechromium
3.0m
new-coverage-e2e.spec.ts:271
order-lifecycle.spec.ts
Order Lifecycle › Order created after payment has confirmed statuschromium
2.4m
order-lifecycle.spec.ts:31
Order Lifecycle › Seller can transition confirmed → processingchromium
2.4m
order-lifecycle.spec.ts:41
Order Lifecycle › Seller can transition processing → shipped with trackingchromium
2.9m
order-lifecycle.spec.ts:56
Order Lifecycle › Invalid transition confirmed → delivered is rejectedchromium
2.9m
order-lifecycle.spec.ts:79
Order Lifecycle › Buyer cannot update order status (only seller/admin can)chromium
2.4m
order-lifecycle.spec.ts:93
order-notifications.spec.ts
Order Notifications › Buyer receives notification when individual items are shippedchromium
2.5m
order-notifications.spec.ts:44
Order Notifications › Buyer receives notification when individual items are deliveredchromium
2.4m
order-notifications.spec.ts:79
Order Notifications › Local pickup order receives "Ready for Pickup" notificationchromium
740ms
order-notifications.spec.ts:109
Order Notifications › Seller receives notification when a new order is placedchromium
2.4m
order-notifications.spec.ts:171
Order Notifications › Seller receives notification when a return is requestedchromium
2.9m
order-notifications.spec.ts:196
premium-subscription.spec.ts
E. Stripe Checkout — Declined Card Scenarios › E1: Declined card (4000...0002) shows error — user stays non-premiumchromium
35.2s
premium-subscription.spec.ts:636
E. Stripe Checkout — Declined Card Scenarios › E2: Insufficient funds card (4000...9995) shows decline errorchromium
55.9s
premium-subscription.spec.ts:687
E. Stripe Checkout — Declined Card Scenarios › E3: Wrong CVC card (4000...0127) shows errorchromium
56.1s
premium-subscription.spec.ts:722
F. 3DS Authentication for Subscription › F2: 3DS card → cancel/fail authentication → isPremium stays falsechromium
58.9s
premium-subscription.spec.ts:827
M. Screen Rendering › M2: SubscriptionSuccessScreen renders at /subscription/success routechromium
34.7s
premium-subscription.spec.ts:1314
stripe-payment.spec.ts
Stripe Payment Flow › Full checkout → Stripe payment → order confirmedchromium
2.4m
stripe-payment.spec.ts:25
Stripe Payment Flow › Order document has correct structure after paymentchromium
2.9m
stripe-payment.spec.ts:40
Stripe Payment Flow › Stock decremented by exact ordered quantity after paymentchromium
2.3m
stripe-payment.spec.ts:66
Stripe Payment Flow › [BONUS] Order expiresAt is within 7-day authorization windowchromium
2.5m
stripe-payment.spec.ts:120
Stripe Payment Flow › [BONUS] Cart is cleared after successful order creationchromium
3.0m
stripe-payment.spec.ts:142
order-cancellation-refund.spec.ts
Order Cancellation & Refund › Buyer can cancel order before shippingchromium
1.1s
order-cancellation-refund.spec.ts:43
Order Cancellation & Refund › Cannot cancel a shipped orderchromium
930ms
order-cancellation-refund.spec.ts:56
Order Cancellation & Refund › Stock restores after cancellationchromium
1.0s
order-cancellation-refund.spec.ts:81
Order Cancellation & Refund › Cannot cancel an already cancelled orderchromium
198ms
order-cancellation-refund.spec.ts:104
add-product-e2e.spec.ts
PW IT Replica — Add Product Flow › T05: Category selector interactionchromium
5.9m
add-product-e2e.spec.ts:95
PW IT Replica — Add Product Flow › T06: Warehouse selection UIchromium
3.3m
add-product-e2e.spec.ts:107
PW IT Replica — Add Product Flow › T12: Back navigation and state resetchromium
4.0m
add-product-e2e.spec.ts:189
digital-products-e2e.spec.ts
B. Digital-Only Checkout › B.2 Buy digital software product → license key created on order itemchromium
2.5m
digital-products-e2e.spec.ts:120
B. Digital-Only Checkout › B.3 Buy digital book product → book license created with bookSourceUrlchromium
2.9m
digital-products-e2e.spec.ts:155
C. Mixed Cart — Digital + Physical › C.2 Mixed cart checkout creates order with both digital and physical itemschromium
1.0m
digital-products-e2e.spec.ts:207
new-notification-features.spec.ts
New Notification Features E2E › Price drop notification is triggered for favorited productschromium
12.4s
new-notification-features.spec.ts:33
New Notification Features E2E › Chat message notification is triggeredchromium
663ms
new-notification-features.spec.ts:83
New Notification Features E2E › Message reporting (flagging) creates a report recordchromium
6.5s
new-notification-features.spec.ts:110
notifications.spec.ts
Notifications E2E Tests › Notify Me button visibility on OOS productchromium
16.4s
notifications.spec.ts:23
Notifications E2E Tests › Subscription to stock notifications & idempotency via UIchromium
600ms
notifications.spec.ts:34
Notifications E2E Tests › Push notification opt-out is respected (pushEnabled: false)chromium
897ms
notifications.spec.ts:53
admin-panel.spec.ts
PW IT Replica — Admin Panel Flow › T01: Access Control — Non-admin cannot access admin panelchromium
1.1m
admin-panel.spec.ts:31
PW IT Replica — Admin Panel Flow › Admin Authenticated Tests › T11: Admin UI — Return to Home visibilitychromium
1.1m
admin-panel.spec.ts:173
shipping-approval.spec.ts
Shipping Approval › Seller can submit shipping cost for an orderchromium
2.5m
shipping-approval.spec.ts:30
Shipping Approval › Only the order seller can submit shipping costchromium
2.9m
shipping-approval.spec.ts:53
shipping-calculation.spec.ts
Shipping Calculation › Multiple quantity correctly multiplies subtotalchromium
5.4s
shipping-calculation.spec.ts:75
Shipping Calculation › International seller uses national ceiling shipping cost ($26.99)chromium
1.8s
shipping-calculation.spec.ts:147
payment-edge-cases.spec.ts
Payment Edge Cases › Declined card shows error on Stripe pagechromium
1.0m
payment-edge-cases.spec.ts:30
rate-limiting.spec.ts
Rate Limiting › Rapid checkout requests trigger rate limitingchromium
5.3s
rate-limiting.spec.ts:28
return-request.spec.ts
Return Request Flow (Flow 6) › Buyer can request return and seller can approvechromium
2.6m
return-request.spec.ts:33
trending-products.spec.ts
Trending Products flows › Premium user can toggle Trending Products notificationschromium
41.7s
trending-products.spec.ts:59