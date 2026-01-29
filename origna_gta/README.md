# origna_gta

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


firebase functions:config:set stripe.secret="REDACTED_SECRET"
firebase deploy --only functions

🧪 Testing
Test Cards
Use these test cards in your development environment:
Card NumberDescription4242 4242 4242 4242Successful payment4000 0000 0000 9995Declined (insufficient funds)4000 0000 0000 0002Declined (generic decline)4000 0025 0000 3155Requires 3D Secure authentication

Use any future expiry date (e.g., 12/34)
Use any 3-digit CVC (e.g., 123)
Use any postal code (e.g., 12345)

<script src="https://js.stripe.com/v3/"></script>



// ============================================================================
// REMAINING V1.1 TODOS
// ============================================================================
// TODO v1.1: MVVM with Riverpod for state management (major refactor, do after launch)
// TODO v1.1: Improve UI/UX with animations throughout the app
// TODO v1.1: Admin panel for moderation (seller management, user messages, etc.)
// TODO:v1.1: change way payment is handled, do it like below, Woocommerce, shoppify way, release payment to seller onces delivery is confirmed:
// stripe.accounts.create({ type: 'express' })
// Generate onboarding link:
// stripe.accountLinks.create({
//   account: acct_id,
//   refresh_url: YOUR_URL,
//   return_url: YOUR_URL,
//   type: 'account_onboarding',
// })
// Buyers will purchase directly from sellers via stripe, search for best practices.
// The core problem
// User pays → shipping is only estimated → seller later discovers shipping costs way more than expected.
// If you do pure WooCommerce-style instant payouts, this can hurt sellers badly and create disputes.
// The correct marketplace pattern (used by Amazon, Etsy, Airbnb)
// 👉 Authorize first, capture later
// 👉 Delay seller payout until shipping is confirmed
// This solves your issue without going full “Custom payouts”.
// ✅ Recommended solution (Stripe-native & safe)
// 1️⃣ Use Payment Intent with manual capture
// At checkout:
// Authorize full amount (product + estimated shipping)
// Do NOT capture yet
// Funds are held (up to ~7 days on cards)
// 2️⃣ Seller confirms real shipping cost
// Seller enters actual shipping price
// Your system compares:
// estimated vs real shipping
// If higher → you:
// update the amount (within Stripe rules)
// or request user confirmation (clean UX)
// 3️⃣ Capture payment only when shipping is locked
// Capture final amount
// Create transfer to seller (minus platform fee)
// Stripe handles payout timing
// This is how Amazon handles variable shipping.
// What if shipping becomes much more expensive?
// You have 3 safe options:
// Option A — Ask buyer for approval (best UX)
// “Shipping cost updated from $12 → $28. Approve?”
// One-click confirmation
// Capture after approval
// Option B — Split payment
// Capture product price immediately
// Capture shipping separately once confirmed
// Option C — Cap shipping risk
// Platform covers difference up to X$
// Beyond that → seller must approve or cancel
// 🚫 What NOT to do
// ❌ Instant payout to seller
// ❌ Let seller lose money
// ❌ Auto-charge extra without buyer consent
// ❌ Manual Stripe Custom unless necessary
// Those cause disputes, chargebacks, and Stripe account reviews.
// Stripe setup you should use
// Best combo for you:
// Stripe Connect Express
// Payment Intents
// capture_method = manual
// Delayed transfer to seller
// You keep:
// Low fees
// Low legal risk
// High trust
// Flow summary (simple)
// Buyer checks out (estimated shipping)
// Payment authorized (not captured)
// Seller ships & confirms cost
// Buyer approves if needed
// Payment captured
// Stripe pays seller automatically
// Bonus: Seller protection rule (important)
// Add this to your marketplace rules:
// “If actual shipping exceeds estimate by more than X%, buyer confirmation is required.”
// This protects you, buyers, and sellers.
// TODO: Remove unnecessary webhooks, it should be woocommerce style:
//    - checkout.session.completed, async_payment_succeeded, async_payment_failed, expired
//    - payment_intent.succeeded, payment_intent.payment_failed
//    - charge.refunded, charge.dispute.created, charge.dispute.closed
//    - account.updated
//    - transfer.created, transfer.reversed
//    - payout.paid, payout.failed
//    - refund.created, refund.failed
//TODO should we modify the code like this or will it break somehting otherwise?
// static const List<String> ALLOWED_FORMATS = ['jpg', 'jpeg', 'png', 'webp'];
// final extension = model.fileName.split('.').last.toLowerCase();
// if (!ALLOWED_FORMATS.contains(extension)) return null;

// TODO fix all dart compiler warnings, code should be clean.
// TODO refunds flow working accordinly