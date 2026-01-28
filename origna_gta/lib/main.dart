import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// OrignaGta -e-commerce store in Canada only, inspired by Amazon, 
// Meta Marketplace, Alibaba, Instacart
// Coding principles and rules
// 1.MVVM arquitecture, clean code all the time
// 2.Logic between backend and frontend should be nice and clean
// Store Creation Considerations
// 1.Avoid expensive APIs, only use them if really needed
// 2.Avoid fetching too much from database, keep this consistent 
// in the entire app.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await ConfigService().initialize();

  await SentryFlutter.init(
    (options) {
      options.dsn = ConfigService().sentryDnsKey;
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = 0.1; // 10% of transactions
      options.beforeSend = (event, hint) {
        // Filter sensitive data
        if (event.user != null) {
          event.user = event.user!.copyWith(
            email: null, // Don't send emails to Sentry
          );
        }
        return event;
      };

           // On web, disable frame tracking & auto performance
      if (kIsWeb) {
        options.enableAutoPerformanceTracing = false;
        options.enableFramesTracking = false;
        options.enableAutoSessionTracking = false;
      } else {
        // mobile defaults (optional tuning):
        options.tracesSampleRate = 1.0;
      }
    },
    appRunner: () async {

      // Set global Flutter error handler
      FlutterError.onError = (FlutterErrorDetails details) {
        final message = details.exceptionAsString();

        // Ignore the disposed Web engine view error
        if (kIsWeb && message.contains('disposed EngineFlutterView')) {
          return;
        }

        // Log to Sentry
        Sentry.captureException(
          details.exception,
          stackTrace: details.stack,
        );

        // Let Flutter still show errors in debug
        FlutterError.presentError(details);
      };
      runApp(const OrignaApp());
    },
  );
}

// ============================================================================
// VERSION 1.0 - COMPLETED FEATURES
// ============================================================================
// [DONE] Contact us section - Added to ProfileScreen
// [DONE] Seller can edit products and mark as sold out - EditProductScreen
// [DONE] Terms and conditions screen with signup checkbox - TermsScreen, LoginScreen
// [DONE] API keys moved to Firebase Remote Config - ConfigService
// [DONE] T&C link in checkout
// [DONE] Delete product cloud function - functions/main.py delete_product
// [DONE] Atomic stock validation in checkout
// [DONE] Amount verification in Stripe webhook
// [DONE] Stock restoration for failed/expired payments
// [DONE] Rating system for delivered products

// ============================================================================
// FUTURE VERSIONS
// ============================================================================
// TODO v4.0: Algolia search for better product discovery
// TODO v4.0: Build releases for android and ios using codemagic
// TODO v4.0: Chat integration, create chat room when a client trying to contact,
// only for chatting, remove current contact us, users can chat if they are logged, fully functional, 
// the chat should be between assistant and user, find some random user in the database with assistant role
// option if considered, show floating chat icon in homescreen. Simple chat that does not cost too much
// TODO v4.0: Platform should allow sellers creation without connection to stripe, 
// maybe some other less regulated and easy option, explore alternatives for receiving payment better than 
// stripe
// TODO v4.0: Add option of shipping integrated in the app so that seller can choose whether to ship them selves 
// or the platform, if it is the platform then handle accordingly, explore options like always ot, easy post, uber direct, 
// doordash api, etc or create a drivers partner option to handle pickup and delivery of merchandise depending on near by
// drivers

// ============================================================================
// CURRENT VERSION
// ============================================================================
// Todos for v1.0
// TODO Pay sellers automatically, charge a platform fee to buyers and sellers depending on the amount of the order, 
// should be a cheap fee, 2.5 percent.
// create seller registration workflow and payout once the order is confirmed by user
// in app, create a button and functionality so that user can confirm reception of the products. take some of this info below 
// into consideration: 

// The correct Stripe architecture for marketplaces
// 1️⃣ Use Stripe Connect
// This is Stripe’s system for multi-seller platforms (like Etsy, Uber, Airbnb).
// You’ll:
// Onboard sellers as Connected Accounts
// Collect payments from customers
// Automatically (or manually) split money between you and sellers
// Let Stripe handle KYC, payouts, tax forms, etc.
// 2️⃣ Choose your seller account type
// Stripe gives you 3 options:
// 🔹 Express (recommended for most apps)
// ✅ Stripe handles KYC
// ✅ Sellers get a Stripe dashboard
// ✅ You control payouts
// ❌ Less branding control
// 👉 Best balance for online marketplaces
// 🔹 Standard
// ✅ Sellers have full Stripe accounts
// ❌ You lose payout control
// ❌ Worse UX (seller leaves your app)
// 👉 Good if sellers are already Stripe users
// 🔹 Custom
// ✅ Full control
// ❌ You handle compliance, KYC, risk
// ❌ More expensive + complex
// 👉 Only for large platforms
// 👉 I strongly recommend Express.
// 3️⃣ Payment flow with Stripe Checkout (IMPORTANT)
// When creating a Checkout Session, you must use Connect parameters.
// Option A: Destination charges (most common)
// Customer pays → Stripe → Seller
// You take a platform fee
// stripe.checkout.sessions.create({
//   mode: "payment",
//   line_items: [...],
//   payment_intent_data: {
//     application_fee_amount: 1500, // your fee in cents
//     transfer_data: {
//       destination: SELLER_STRIPE_ACCOUNT_ID,
//     },
//   },
//   success_url,
//   cancel_url,
// });
// ✔ Stripe sends the rest to the seller
// ✔ Stripe pays the seller automatically
// ✔ You keep your fee
// Option B: Separate charges & transfers
// More control (escrow-like behavior)
// Customer pays → You → Seller later
// // 1. Charge customer normally (money goes to you)

// // 2. Later transfer to seller
// stripe.transfers.create({
//   amount: 8500,
//   currency: "cad",
//   destination: SELLER_STRIPE_ACCOUNT_ID,
// });
// ✔ You control when sellers get paid
// ✔ Useful for refunds, disputes, delivery-based payouts
// 4️⃣ What you should store in your database
// For each seller:
// {
//   "userId": "seller_123",
//   "stripeAccountId": "acct_1Qxxxx",
//   "payoutsEnabled": true
// }
// For each order:
// {
//   "orderId": "ord_456",
//   "checkoutSessionId": "cs_test_...",
//   "paymentIntentId": "pi_...",
//   "sellerId": "seller_123",
//   "stripeTransferId": "tr_...",
//   "platformFee": 15.00
// }
// 👉 Do NOT store Stripe balances manually
// 👉 Treat Stripe as the source of truth
// 5️⃣ Seller onboarding flow
// Seller clicks “Start selling”
// You create a Stripe Connect account
// Redirect them to Stripe onboarding
// Stripe notifies you via webhook when:
// charges_enabled = true
// payouts_enabled = true
// Only then can they receive money.
// 6️⃣ Payout timing
// By default:
// Stripe pays sellers daily
// You can change this (weekly / manual)
// You do not send money yourself — Stripe does.
// 7️⃣ Taxes & compliance (good news)
// Stripe:
// Handles identity verification
// Collects required tax info
// Generates 1099 / tax forms (US/Canada supported)
// TL;DR
// ✔ Stripe Checkout → collect money
// ✔ Stripe Connect → pay sellers
// ✔ Use Express accounts
// ✔ Use destination charges unless you need escrow
// ✔ Store Stripe IDs, not balances
// Alright — multiple sellers per single order is the hard mode of Stripe 😄
// Totally doable, but there’s one correct approach and a couple of tempting wrong ones.
// 🚨 First: a hard Stripe limitation (very important)
// A single Checkout Session / PaymentIntent can only have ONE destination account.
// ❌ You cannot do:
// One Checkout
// Multiple sellers
// Multiple transfer_data.destination
// Stripe simply doesn’t allow it.
// So… we adapt.
// ✅ The ONLY scalable solution: Separate charges & transfers
// Money flow
// Customer → Platform (you) → Multiple sellers
// You:
// Collect 100% of the payment
// Later split & transfer money to each seller
// This is how Amazon, DoorDash, Uber Eats do it.
// 🧠 High-level architecture
// Checkout (customer pays)
//         ↓
// PaymentIntent (owned by YOU)
//         ↓
// Order confirmed
//         ↓
// For each seller in order:
//     → stripe.transfers.create()
// 🛒 Example order (multi-seller)
// Order #123
// {
//   "items": [
//     { "sellerId": "A", "price": 40 },
//     { "sellerId": "B", "price": 25 },
//     { "sellerId": "A", "price": 15 }
//   ]
// }
// Totals:
// Seller A → $55
// Seller B → $25
// Platform fee → e.g. 10%
// 1️⃣ Checkout Session (NO destination)
// Create Checkout normally — money lands in your platform account.
// stripe.checkout.sessions.create({
//   mode: "payment",
//   line_items,
//   success_url,
//   cancel_url,
// });
// ✔ Simple
// ✔ One payment
// ✔ No seller logic here
// 2️⃣ Store a seller breakdown on your side
// In Firestore / DB:
// {
//   "orderId": "ord_123",
//   "paymentIntentId": "pi_...",
//   "sellers": [
//     {
//       "sellerId": "sellerA",
//       "stripeAccountId": "acct_1A",
//       "gross": 55.00,
//       "platformFee": 5.50,
//       "net": 49.50
//     },
//     {
//       "sellerId": "sellerB",
//       "stripeAccountId": "acct_1B",
//       "gross": 25.00,
//       "platformFee": 2.50,
//       "net": 22.50
//     }
//   ],
//   "status": "paid"
// }
// 👉 This breakdown is critical.
// 3️⃣ Webhook: checkout.session.completed
// Only after this event do you pay sellers.
// if (event.type === "checkout.session.completed") {
//   // confirm order
//   // trigger transfers
// }
// 4️⃣ Create one transfer per seller
// await stripe.transfers.create({
//   amount: 4950,
//   currency: "cad",
//   destination: "acct_1A",
//   source_transaction: paymentIntentId,
// });
// await stripe.transfers.create({
//   amount: 2250,
//   currency: "cad",
//   destination: "acct_1B",
//   source_transaction: paymentIntentId,
// });
// ✔ Unlimited sellers
// ✔ Clean accounting
// ✔ Fully Stripe-compliant
// 5️⃣ Refunds & disputes (this is why this model wins)
// Partial refund?
// ✔ Refund item → reduce seller transfer
// ✔ Or claw back from future balance
// Dispute?
// ✔ Stripe pulls from your account
// ✔ You decide how to handle seller liability
// This is impossible with destination charges.
// 6️⃣ Payout timing (very flexible)
// You can:
// Pay sellers instantly
// Delay until delivery
// Batch weekly
// Hold funds for disputes
// Just don’t create the transfer yet.
// 7️⃣ What NOT to do ❌
// ❌ Multiple Checkout Sessions per order
// ❌ One Checkout per seller
// ❌ Manual PayPal-style payouts
// ❌ Storing balances yourself
// ❌ Trying to split a PaymentIntent
// 🧩 Recommended Stripe Connect setup
// Thing	Choice
// Account type	Express
// Charge type	Separate charges & transfers
// Checkout	Single session
// Payout control	Platform
// Seller UX	Stripe-hosted onboarding
// TL;DR
// ✔ One Checkout
// ✔ Money lands on YOU
// ✔ Split order by seller
// ✔ One transfer per seller
// ✔ Stripe Connect Express
// Perfect — that’s actually the cleanest and safest model. You’re basically building a built-in escrow 👍
// Stripe is very happy with this setup.
// Let’s lock it in step by step.
// ✅ Correct model for your case
// Separate charges & transfers + delayed payout
// Customer pays (Checkout)
//         ↓
// Money sits on YOUR Stripe balance
//         ↓
// Order delivered
//         ↓
// Client confirms receipt in app
//         ↓
// You release funds → sellers
// No hacks. No ToS issues. Fully compliant.
// 1️⃣ Checkout: collect money (nothing special here)
// Money must land on your platform account, not sellers.
// stripe.checkout.sessions.create({
//   mode: "payment",
//   line_items,
//   success_url,
//   cancel_url,
// });
// ❗ Do NOT use transfer_data
// ❗ Do NOT auto-pay sellers yet
// 2️⃣ Order states (this is key)
// Your order lifecycle should look like:
// created
// → paid
// → shipped
// → delivered
// → confirmed_by_client
// → sellers_paid
// You only pay sellers at confirmed_by_client.
// 3️⃣ Store seller escrow data per order
// Example Firestore document:
// {
//   "orderId": "ord_789",
//   "paymentIntentId": "pi_...",
//   "status": "confirmed_by_client",
//   "sellers": [
//     {
//       "sellerId": "sellerA",
//       "stripeAccountId": "acct_1A",
//       "gross": 80.00,
//       "platformFee": 8.00,
//       "net": 72.00,
//       "paid": false
//     },
//     {
//       "sellerId": "sellerB",
//       "stripeAccountId": "acct_1B",
//       "gross": 40.00,
//       "platformFee": 4.00,
//       "net": 36.00,
//       "paid": false
//     }
//   ]
// }
// Think of this as your escrow ledger (Stripe holds the money, you hold the logic).
// 4️⃣ Client confirmation → trigger payouts
// When the client taps “I received my items”:
// Backend only (never client-side!)
// for (const seller of order.sellers) {
//   if (!seller.paid) {
//     const transfer = await stripe.transfers.create({
//       amount: Math.round(seller.net * 100),
//       currency: "cad",
//       destination: seller.stripeAccountId,
//       source_transaction: order.paymentIntentId,
//     });

//     // Mark seller as paid
//     seller.paid = true;
//     seller.transferId = transfer.id;
//   }
// }
// ✔ One transfer per seller
// ✔ Idempotent logic
// ✔ Safe to retry
// 5️⃣ Protect yourself (VERY important)
// ⏳ Auto-release fallback
// What if the client disappears?
// Example:
// Auto-confirm after 7–14 days
// Or seller marks as delivered + grace period
// delivered + 7 days → auto confirmed
// Stripe does NOT do this for you — your app must.
// 6️⃣ Refund rules (before confirmation)
// Situation	What you do
// Not delivered	Full refund
// Partial items	Partial refund
// Seller canceled	Remove seller from payout
// Before confirmation	No transfers yet
// After confirmation:
// Refunds come from your account
// Optionally deduct from seller’s future payouts
// 7️⃣ Disputes (you’re doing this right)
// Because funds stayed with you:
// Stripe pulls disputed funds from you
// You’re not breaking seller payouts
// You stay in control
// This is exactly why Stripe recommends this model.
// 8️⃣ Stripe Connect settings (recommended)
// Setting	Value
// Account type	Express
// Payout schedule	Manual or Daily
// Transfers	Manual
// Capability	card_payments, transfers
// 9️⃣ What NOT to do ❌
// ❌ Pay sellers immediately
// ❌ Let sellers trigger payouts
// ❌ Do payouts from client app
// ❌ Store balances outside Stripe
// ❌ Skip auto-release fallback
// TL;DR (sticky note version)
// ✔ Single Checkout
// ✔ Money → you
// ✔ Order confirmation unlocks escrow
// ✔ One transfer per seller
// ✔ Stripe Connect Express
// ✔ Auto-release safety net

// TODO shipping calculation is amazing in the app but only for local distances, if the seller is in BC Canada,
// shipping should be cheaper using a shipping provider, in which case the seller can set the tracking number, 
// but the shipping algorithm should be as precise as possible according to recent data, no API calls, just pure 
// algorithm as precise as possible, the seller should agree to this stimate in the terms and conditions.
// TODO MVVM required. Use riverpod for flutter for state management in the entire app, to follow modern clean arquitecture patterns

// TODO the app bar for the home view is awesome, but in the rest of the app there is inconsistency with the color
// and letters, create custom app bar similar to the one in home view but without any oval rounding, just the similar ui as the one from 
// home so there is ui consistency, make it reusable

// TODO: improve UI and UX in the entire app, make sure that there are nice animations

// TODO: only users with admin or assistant roles can see Admin Panel - Build separate admin dashboard for moderation, to see sellers info, block them from the platform
// if needed, see users messages, etc. Show automatic email to newly registered sellers with a welcoming message.
// TODO make sure that the flow of the app is ok, check latest docs for best practices
// TODO create a database schema, save it as json or any better way of your choice to keep track of the fields an structure
// and avoid inconsistencies
// TODO check entire workflow and files of the app to make sure there are no errors or mistakes, check cloud functions 
// logic too, review everything, be creative too and propose out of the art changes with latest updated info with best
// practices.
// TODO Create a presentation file that is easy to edit with all workflows of the app and logic, refine logic as
// needed, propose changes, to make sure that the e-commerce store is successfull and bullet prove, solid.
// TODO reuse code and refactor in the entire app, keep code clean

// TODO make layout responsive and working for all sort of screen, mobile, web, etc
// TODO set todos and improvements as done an answer this: Is the app ready for production, with more than 100 000 clients
// and more than 10 000 sellers? if yes mark as done too, if no, make changes or suggestions so that it is bullet prove