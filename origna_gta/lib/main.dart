import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// OrignaGta -e-commerce store in Canada only, inspired by Amazon, 
// Meta Marketplace, Alibaba, Instacart
// Coding principles and rules
// 1.MVVM arquitecture, clean code all the time
// 2.Logic between backend and frontend should be nice and clean
// 3.The code should be so robust that if you need to replace an api you only need to modify the service file
// of that api
// Store Creation Considerations
// 1.Avoid expensive APIs, only use them if really needed
// 2.Avoid fetching too much from database, keep this consistent 
// in the entire app.
// 3.Scale to more than 100 million users a year
// 4.Easy to maintain, only one developer with super powers using claude pro

// Review and finish up
// Confirm your funds flow and business details. We’ll review this information to determine onboarding requirements for sellers.
// Summary

// Funds flow
// Sellers will collect payments directly
// Industry
// E-commerce products
// Confirming this setup will set your platform configuration, you won’t be able to change it.
// You can continue creating test accounts and charges while we review your details.
// ============================================================================
// ARCHITECTURE NOTES 
// ============================================================================
// 1. Seller has Stripe Express account (connected)
// 2. Customer checks out
// 3. Payment is AUTHORIZED (manual capture)
// 4. Seller ships order + confirms tracking
// 5. Buyer confirms receipt OR 14 days pass
// 6. Payment is CAPTURED
// 7. Stripe automatically:
//    - Sends funds to seller
//    - Deducts platform fee (2.5%)
//    - Handles payout to seller’s bank
// Setup Funds flow Sellers will collect payments directly Industry E-commerce products Account creation Embedded onboarding components Account management 
// You’ll use embedded components to let users manage their Stripe account on your platform Pricing owner Stripe Enabled by default Risk and loss liability Stripe will manage risk and be liable if sellers can’t pay back losses—even if those losses result from fraud. Learn more about risk management

// ✅ Funds flow: Sellers will collect payments directly
// This is the WooCommerce-style “direct charges” model.
// Customer pays → Stripe routes funds directly to the seller.
// Your platform only takes an application fee (2.5%).
// Benefit: Lower liability, no need to hold funds, and simpler accounting.
// ✅ Industry: E-commerce products
// This matches your marketplace use case.
// Stripe will optimize integration guides and risk models for physical product sales.
// ✅ Account creation: Embedded onboarding components
// You are using Stripe Connect Express embedded in your app (WebView or browser).
// Stripe handles all KYC, identity, and bank account collection.
// Sellers feel like they’re still in your app, but compliance is Stripe’s responsibility.
// ✅ Account management: Embedded components
// Sellers manage payouts, bank info, tax info, and identity updates via Stripe-hosted Express Dashboard links.
// You never store or manage sensitive financial or identity data.
// Embedded components = WebView (or external browser) opening the dashboard.
// ✅ Pricing owner: Stripe
// Stripe collects card processing fees automatically.
// Your platform only collects the application fee.
// This is simplest and safest — no bookkeeping headaches or disputes with sellers.
// ✅ Risk and loss liability: Stripe manages
// Stripe assumes fraud and chargeback risk.
// You don’t need to handle seller losses if a buyer disputes a charge or if fraud occurs.
// Reduces legal and financial exposure for your platform.
// 🧩 Summary: Why this setup is ideal
// Scalable – works for millions of sellers and buyers.
// Low liability – you don’t hold funds or handle sensitive data.
// Smooth UX – sellers stay in your app via embedded onboarding and dashboard access.
// Simple fees – Stripe collects processing fees; you collect your platform fee only.
// Risk management – Stripe handles fraud, chargebacks, and payout failures.
// ✅ Verdict: Your setup is fully aligned with best practices for marketplaces like Etsy, Shopify, and Amazon.
// ✅ Best-practice solution (no async context usage)
// 1️⃣ Store the messenger synchronously
// Future<void> _deleteProduct() async {
//   final messenger = ScaffoldMessenger.of(context);

//   try {
//     final callable =
//         FirebaseFunctions.instance.httpsCallable('delete_product');

//     await callable.call({'productId': widget.productId});

//     if (!mounted) return;

//     messenger.showSnackBar(
//       const SnackBar(
//         content: Text('Product deleted successfully'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   } on FirebaseFunctionsException catch (e) {
//     if (!mounted) return;

//     messenger.showSnackBar(
//       SnackBar(
//         content: Text('Error: ${e.message ?? e.code}'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   } catch (e) {
//     if (!mounted) return;

//     messenger.showSnackBar(
//       SnackBar(
//         content: Text('Error deleting product: $e'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }
// 2️⃣ Call it normally
// onPressed: _deleteProduct,
// ✔ No BuildContext passed
// ✔ No lints
// ✔ Safe after await
// ✔ Future-proof
// ❌ What NOT to do
// Future<void> _deleteProduct(BuildContext context) async { ... }
// Even with mounted, this triggers:
// “Avoid using BuildContext across async gaps”
// 🔍 Why this works
// ScaffoldMessenger.of(context) is resolved before await
// You’re no longer holding onto a BuildContext
// mounted still protects against widget disposal
// 🧠 Extra-clean pattern (optional)
// If you want it even tighter:
// void _showSnack(SnackBar bar) {
//   if (!mounted) return;
//   ScaffoldMessenger.of(context).showSnackBar(bar);
// }
// Yep — withOpacity is deprecated on Color in recent Flutter versions 👀
// The fix is simple: use withValues (preferred) or Color.fromARGB.
// ✅ Recommended fix (modern Flutter)
// Container(
//   decoration: BoxDecoration(
//     color: Colors.black.withValues(alpha: 0.5),
//     shape: BoxShape.circle,
//   ),
//   child: IconButton(
//     icon: const Icon(Icons.close, color: Colors.white, size: 28),
//     onPressed: () => Navigator.pop(context),
//   ),
// );

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await ConfigService().initialize();

    await SentryFlutter.init(
      (options) {
        options.dsn = ConfigService().sentryDnsKey;
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = 0.1; // 10% of transactions
        options.beforeSend = (event, hint) {
          // Filter sensitive data - strip emails before sending
          if (event.user != null) {
            event.user = SentryUser(
              id: event.user!.id,
              username: event.user!.username,
              ipAddress: event.user!.ipAddress,
              data: event.user!.data,
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
    );

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

    runApp(const ProviderScope(child: OrignaApp()));
  }, (exception, stackTrace) async {
    // Capture unhandled errors to Sentry
    await Sentry.captureException(exception, stackTrace: stackTrace);
  });
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
// [DONE] Stripe Connect seller payouts with 2.5% platform fee
// [DONE] Seller registration workflow with Stripe Express onboarding
// [DONE] Order confirmation button for buyers to confirm receipt
// [DONE] Auto-release payout fallback (14 days after delivery)
// [DONE] Custom reusable AppBar widget (widgets/custom_app_bar.dart)
// [DONE] Database schema documentation (docs/database_schema.json)
// [DONE] Improved shipping calculation for long distances (tiered pricing)
// [DONE] Idempotency keys for Stripe transfers to prevent double-payments
// [DONE] Webhook handlers for disputes, refunds, payouts
// [DONE] Stock restoration on refunds
// [DONE] Admin can sell products and receive payouts
// [DONE] Delete Account feature for GDPR/PIPEDA compliance
// [DONE] Canada-only shipping restriction (addresses validated backend & frontend)
// [DONE] Weight/volume/dimensions fields in ProductModel for accurate shipping

// ============================================================================
// FUTURE VERSIONS
// ============================================================================
// TODO v4.0: CloudFlare Domain + Flutter web Firebase Hosting + OCI->Appwrite + Typesense. R2 Cloudflare + Geoapify + Mailjet + Stripe + Sentry
//  Mail services are only used after user pays, for delivery updates and payment confirmation. Geopify is used when adding new product and when user add address
// Esta configuración es el "Santo Grial" del ahorro para startups. Estás utilizando estratégicamente los servicios gestionados (Cloudflare, Firebase Hosting) donde la fiabilidad es crítica, y el auto-hospedaje (OCI) donde los costos de escalabilidad de Firebase te arruinarían.

// Aquí tienes el análisis de viabilidad técnica y cómo interactúan estas piezas:

// 1. El Flujo de Datos y Conexiones

// Tu arquitectura separa perfectamente las responsabilidades para maximizar el rendimiento:

// Frontend (Firebase Hosting + Flutter Web): Es ideal porque Firebase Hosting ofrece un CDN global gratuito y excelente soporte para Flutter Web. Al estar bajo tu Cloudflare Domain, obtienes una capa extra de seguridad (WAF) y caché.

// Backend & Search (OCI): Appwrite y Typesense viven en tu instancia Ampere de 24GB. Tu Flutter Web hablará con la IP/Dominio de tu servidor OCI para autenticación y búsquedas.

// Archivos (R2): Cuando un usuario sube una foto en AddProductScreen, Appwrite la recibe pero la "empuja" automáticamente a Cloudflare R2. Esto mantiene tu disco de OCI limpio.

// 2. Análisis de Costos y Límites (Escala de 50M de Usuarios)

// Componente	Rol	Costo en Escala (50M Users)	Riesgo / Nota
// Firebase Hosting	Hosting Web	Bajo/Medio	Solo pagas por transferencia de datos (Egress). Cloudflare delante puede reducir esto mediante caché.
// OCI (Appwrite/Typesense)	DB, Auth, Search	$0	Tu mayor ahorro. Firebase Auth para 50M te costaría >$100k/mes. Aquí es gratis.
// Cloudflare R2	Imágenes	$0.015 / GB	Lo mejor: $0 costo de descarga (Egress). Es el único servicio que permite 50M de usuarios viendo fotos sin quebrar el banco.
// Geoapify	Direcciones	Variable	Como solo lo usas al añadir producto/dirección, los 3,000 créditos gratuitos durarán mucho.
// Mailjet	Email Transaccional	$0 hasta 6k/mes	Al enviarlo solo tras el pago, el volumen es bajo. Es escalable.
// Stripe	Pagos	2.9% + $0.30	Estándar de la industria. Solo pagas si ganas dinero.
// Geoapify: El Seguro de Vida
// Typesense: Si el stock llega a 0, otra función de Dart elimina el producto del índice de búsqueda.
// Como planeas 50M de usuarios, eventualmente superarás los 3,000 créditos diarios de Geoapify.

// Estrategia: Implementa un "Debounce" en tu campo de búsqueda en Flutter (esperar 500ms antes de llamar a la API) para evitar llamadas innecesarias mientras el usuario escribe.
// TODO v4.0: Algolia search for better product discovery. Algolia / Typesense. 
// Two cloud fn, one for product creation and the other for product update to send data to algolia, 
// or typesense instance in OCI
// TODO v4.0: Build releases for android and ios using codemagic
// TODO v4.0: Chat integration, create chat room when a client trying to contact,
// TODO v4.0: Caching	CachedNetworkImage	CDN + Local DB (Hive/Drift)
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
// REMAINING V1.1 TODOS
// ============================================================================

// [DONE] v1.1: UI/UX animations - FadeSlideIn, AnimatedEmptyState, staggered lists, rounded AppBar with shadow
// [DONE] v1.1: Admin panel - seller management, user management, order overview, product moderation with stock control
// [DONE] v1.1: Integration and unit tests created - 69 tests covering models, business logic, widgets, and checkout flow
// [DONE] v1.1: Use Stripe Tax instead of hardcoding taxes calculation (compliance automation, product exemptions)

// [DONE] Remove unnecessary webhooks - cleaned up payment_intent.amount_capturable_updated and payment_intent.canceled
// [DONE] Image format validation - added allowedFormats check in _uploadImagesInParallel
// [DONE] Fix all dart compiler warnings - flutter analyze shows 0 issues
// [DONE] Use same custom app bar in all screens - adopted CustomAppBar via AppBarFactory.simple()
// [DONE] Payment flow change (WooCommerce/Shopify style) - Manual capture, seller confirms shipping,
//        buyer approval for >20% increase, delayed payout to seller with 2.5% fee, auto-release after 14 days
// TODO v4.0 google ranking in search SEO optimization
// [ACTION REQUIRED] Enable Stripe Tax in your Stripe Dashboard Settings
// TODO: Finish MVVM, 1.services like database connection should not handled in UI, keep separation of concerns, state managers in a separate file, one for each view is 
// the ideal v1.1: MVVM with Riverpod - 5 provider files, 7 screens migrated (home, cart, login, orders, productdetails, seller_orders)
// TODO create script to trigger all tests, the python ones and the flutter and dart ones before push is made to the main branch. All tests need to pass to be able to push
// TODO delete all cloud functions from console and registries and then redeploy

// TODO when the cart get cleared in the database after the user finish checkout, the ui of home screen and cart screen do not reflect the changes
// TODO in cart screen when tapping the plus button the ui rebuilds entirely, fix that
// TODO after the success url is triggered the user is redirected to another tab of the app home view,
// it should redirect to same tab and to the success screen instead