import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:origna_gta/firebase_options.dart';
import 'package:origna_gta/origna_app.dart';
import 'package:origna_gta/services/conf_services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://536779563eb50abc63b8c5d2db8d0dc7@o4510778090848256.ingest.us.sentry.io/4510778092421120';
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
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      await ConfigService().initialize();

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
//TODO add chatbot

    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // PlatformDispatcher.instance.onError = (error, stack) {
      //   FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      //   return true;
      // };
//Version 1.0
//TODO: contact us section
//TODO: seller should be able to edit their products, and mark them as sold out
//TODO: Terms and conditions screen needs to be added, link it in the signup screen, user must accept terms and conditions before signing up
//TODO: splash and launch icons need to be added later
//TODO: later on, move api keys to secure storage or similar, do not keep them hardcoded in the project

// -cloudflare r2 keys are also hardcoded in the project, that is ok for now

//TODO delete user account
//TODO terms conditions




//TODO:Delete in backend, write fn in python for firebase cloud fn
// Firebase Cloud Function - functions/index.js
// const functions = require('firebase-functions');
// const admin = require('firebase-admin');

// exports.deleteProduct = functions.https.onCall(async (data, context) => {
//   // Verify admin authentication
//   if (!context.auth) {
//     throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
//   }

//   const productId = data.productId;
//   const db = admin.firestore();
  
//   try {
//     // 1. Delete product document
//     await db.collection('products').doc(productId).delete();
    
//     // 2. Remove from carts (subcollection approach - MUCH more scalable)
//     // Query all cart items for this product across ALL users
//     const cartQuery = db.collectionGroup('cart').where('productId', '==', productId);
//     const cartSnapshot = await cartQuery.get();
    
//     const cartBatch = db.batch();
//     cartSnapshot.docs.forEach(doc => {
//       cartBatch.delete(doc.ref);
//     });
//     await cartBatch.commit();
    
//     // 3. Remove from favorites (batched cleanup)
//     // Use pagination to handle large user bases
//     let hasMore = true;
//     let lastDoc = null;
//     const batchSize = 500;
    
//     while (hasMore) {
//       let query = db.collection('users')
//         .where('favorites', 'array-contains', productId)
//         .limit(batchSize);
      
//       if (lastDoc) {
//         query = query.startAfter(lastDoc);
//       }
      
//       const snapshot = await query.get();
      
//       if (snapshot.empty) {
//         hasMore = false;
//         break;
//       }
      
//       const batch = db.batch();
//       snapshot.docs.forEach(doc => {
//         batch.update(doc.ref, {
//           favorites: admin.firestore.FieldValue.arrayRemove(productId)
//         });
//       });
      
//       await batch.commit();
//       lastDoc = snapshot.docs[snapshot.docs.length - 1];
//       hasMore = snapshot.docs.length === batchSize;
//     }
    
//     return { success: true, message: 'Product deleted and cleaned up' };
    
//   } catch (error) {
//     console.error('Error deleting product:', error);
//     throw new functions.https.HttpsError('internal', error.message);
//   }
// });


// TODO:2. Cart Data Model Issue (Multiple Files)
// Current approach: Cart stored as array in user document
// Problem: Race conditions with concurrent updates, document size limits
// Solution: You've partially implemented subcollections (cart_screen.dart uses them), but checkout_screen.dart and other places still reference the old model. Need consistency.



//TODO atomic stock validation
// Add to your create_checkout_session Cloud Function

// exports.create_checkout_session = functions.https.onCall(async (data, context) => {
//   if (!context.auth) {
//     throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
//   }

//   const db = admin.firestore();
//   const items = data.items || [];
  
//   try {
//     // 🔥 CRITICAL: Validate stock availability with transaction
//     await db.runTransaction(async (transaction) => {
//       const stockChecks = [];
      
//       // Read phase - check all products
//       for (const item of items) {
//         const productRef = db.collection('products').doc(item.productId);
//         const productDoc = await transaction.get(productRef);
        
//         if (!productDoc.exists) {
//           throw new Error(`Product ${item.name} no longer exists`);
//         }
        
//         const currentStock = productDoc.data().stockQuantity || 0;
        
//         if (currentStock < item.quantity) {
//           throw new Error(
//             `Insufficient stock for ${item.name}. ` +
//             `Available: ${currentStock}, Requested: ${item.quantity}`
//           );
//         }
        
//         stockChecks.push({
//           ref: productRef,
//           currentStock,
//           quantity: item.quantity
//         });
//       }
      
//       // Write phase - reserve stock (decrease by ordered quantity)
//       for (const check of stockChecks) {
//         transaction.update(check.ref, {
//           stockQuantity: admin.firestore.FieldValue.increment(-check.quantity)
//         });
//       }
//     });
    
//     // Create Stripe session
//     const session = await stripe.checkout.sessions.create({
//       payment_method_types: ['card'],
//       line_items: items.map(item => ({
//         price_data: {
//           currency: data.currency || 'cad',
//           product_data: {
//             name: item.name,
//             images: item.imageUrls?.slice(0, 1) || []
//           },
//           unit_amount: Math.round(item.price * 100)
//         },
//         quantity: item.quantity
//       })),
//       mode: 'payment',
//       success_url: `${data.successUrl}?session_id={CHECKOUT_SESSION_ID}`,
//       cancel_url: data.cancelUrl,
//       metadata: {
//         userId: context.auth.uid,
//         orderData: JSON.stringify(data)
//       }
//     });
    
//     // Store pending order with reserved stock
//     await db.collection('orders').doc(session.id).set({
//       ...data,
//       sessionId: session.id,
//       paymentStatus: 'pending',
//       stockReserved: true,
//       createdAt: admin.firestore.FieldValue.serverTimestamp()
//     });
    
//     return { url: session.url, sessionId: session.id };
    
//   } catch (error) {
//     console.error('Checkout error:', error);
//     throw new functions.https.HttpsError('internal', error.message);
//   }
// });

// 🔥 CRITICAL: Handle stock restoration on payment failure/cancellation
// exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
//   const sig = req.headers['stripe-signature'];
//   let event;
  
//   try {
//     event = stripe.webhooks.constructEvent(req.rawBody, sig, process.env.STRIPE_WEBHOOK_SECRET);
//   } catch (err) {
//     return res.status(400).send(`Webhook Error: ${err.message}`);
//   }
  
//   const db = admin.firestore();
  
//   if (event.type === 'checkout.session.completed') {
//     const session = event.data.object;
    
//     await db.collection('orders').doc(session.id).update({
//       paymentStatus: 'paid',
//       updatedAt: admin.firestore.FieldValue.serverTimestamp()
//     });
    
//     // Clear user's cart
//     const orderDoc = await db.collection('orders').doc(session.id).get();
//     const userId = orderDoc.data().userId;
    
//     const cartSnapshot = await db.collection('users').doc(userId).collection('cart').get();
//     const batch = db.batch();
//     cartSnapshot.docs.forEach(doc => batch.delete(doc.ref));
//     await batch.commit();
//   }
  
//   if (event.type === 'checkout.session.expired' || event.type === 'payment_intent.payment_failed') {
//     const session = event.data.object;
//     const orderDoc = await db.collection('orders').doc(session.id).get();
    
//     if (orderDoc.exists && orderDoc.data().stockReserved) {
//       // 🔥 RESTORE STOCK
//       const items = orderDoc.data().items || [];
//       const batch = db.batch();
      
//       for (const item of items) {
//         const productRef = db.collection('products').doc(item.productId);
//         batch.update(productRef, {
//           stockQuantity: admin.firestore.FieldValue.increment(item.quantity)
//         });
//       }
      
//       await batch.commit();
      
//       await db.collection('orders').doc(session.id).update({
//         paymentStatus: 'failed',
//         stockReserved: false
//       });
//     }
//   }
  
//   res.json({ received: true });
// });



//TODO security rules
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
    
//     // Helper functions
//     function isSignedIn() {
//       return request.auth != null;
//     }
    
//     function isOwner(userId) {
//       return isSignedIn() && request.auth.uid == userId;
//     }
    
//     function isAdmin() {
//       return isSignedIn() && 
//              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.roles.hasAny(['admin']);
//     }
    
//     function isSeller() {
//       return isSignedIn() && 
//              get(/databases/$(database)/documents/users/$(request.auth.uid)).data.roles.hasAny(['seller', 'admin']);
//     }
    
//     // Users collection
//     match /users/{userId} {
//       // Users can read their own data, admins can read all
//       allow read: if isOwner(userId) || isAdmin();
      
//       // Users can only update their own data (except roles)
//       allow update: if isOwner(userId) && 
//                       !request.resource.data.diff(resource.data).affectedKeys().hasAny(['roles', 'uid']);
      
//       // Only system can create users (via Cloud Functions on signup)
//       allow create: if false;
      
//       // Users cannot delete themselves
//       allow delete: if isAdmin();
      
//       // Cart subcollection
//       match /cart/{itemId} {
//         allow read, write: if isOwner(userId);
//       }
//     }
    
//     // Products collection
//     match /products/{productId} {
//       // Anyone can read products (for browsing)
//       allow read: if true;
      
//       // Only sellers can create products
//       allow create: if isSeller() && 
//                       request.resource.data.sellerId == request.auth.uid &&
//                       request.resource.data.stockQuantity >= 0 &&
//                       request.resource.data.price > 0;
      
//       // Only product owner or admin can update
//       allow update: if (isOwner(resource.data.sellerId) || isAdmin()) &&
//                       request.resource.data.sellerId == resource.data.sellerId && // Can't change seller
//                       request.resource.data.stockQuantity >= 0 &&
//                       request.resource.data.price > 0;
      
//       // Only admin can delete (should use Cloud Function to clean up dependencies)
//       allow delete: if isAdmin();
//     }
    
//     // Orders collection
//     match /orders/{orderId} {
//       // Users can read their own orders, sellers can read orders containing their products
//       allow read: if isSignedIn() && 
//                     (resource.data.userId == request.auth.uid || 
//                      resource.data.sellerIds.hasAny([request.auth.uid]) ||
//                      isAdmin());
      
//       // Only Cloud Functions should create/update orders (payment processing)
//       allow create, update: if false;
      
//       // Sellers can update item status within their orders
//       allow update: if isSignedIn() && 
//                       resource.data.sellerIds.hasAny([request.auth.uid]) &&
//                       // Only allow updating item statuses, not order-level data
//                       request.resource.data.diff(resource.data).affectedKeys().hasOnly(['items']);
      
//       allow delete: if isAdmin();
//     }
    
//     // Deny all other access
//     match /{document=**} {
//       allow read, write: if false;
//     }
//   }
// }


//TODO algolia
// 1. Add to pubspec.yaml:
// algolia: ^1.1.2

// // 2. services/search_service.dart
// import 'package:algolia/algolia.dart';

// class SearchService {
//   static final Algolia _algolia = Algolia.init(
//     applicationId: 'YOUR_APP_ID',
//     apiKey: 'YOUR_SEARCH_API_KEY', // Search-only key, safe for client
//   );

//   /// Production-grade search with typo tolerance, faceting, and ranking
//   static Future<List<ProductModel>> searchProducts({
//     required String query,
//     String? categoryId,
//     int page = 0,
//     int hitsPerPage = 20,
//   }) async {
//     try {
//       AlgoliaQuery algoliaQuery = _algolia.instance
//           .index('products')
//           .query(query)
//           .setPage(page)
//           .setHitsPerPage(hitsPerPage);

//       // Apply category filter if provided
//       if (categoryId != null) {
//         algoliaQuery = algoliaQuery.filters('categoryId:$categoryId');
//       }

//       // Configure search parameters
//       algoliaQuery = algoliaQuery
//           .setTypoTolerance(AlgoliaTypoTolerance.strict)
//           .setAttributesToRetrieve([
//             'objectID',
//             'name',
//             'price',
//             'imageUrls',
//             'rating',
//             'categoryId',
//             'sellerId',
//             'stockQuantity'
//           ])
//           .setAttributesToHighlight(['name', 'description'])
//           .setRankingInfo(true);

//       AlgoliaQuerySnapshot snap = await algoliaQuery.getObjects();

//       return snap.hits.map((hit) {
//         return ProductModel(
//           id: hit.objectID,
//           name: hit.data['name'],
//           price: (hit.data['price'] as num).toDouble(),
//           imageUrls: List<String>.from(hit.data['imageUrls'] ?? []),
//           rating: (hit.data['rating'] as num?)?.toDouble() ?? 0.0,
//           categoryId: hit.data['categoryId'],
//           sellerId: hit.data['sellerId'],
//           stockQuantity: hit.data['stockQuantity'] ?? 0,
//           // ... other fields
//         );
//       }).toList();
      
//     } catch (e) {
//       print('Search error: $e');
//       return [];
//     }
//   }
// }

// 3. Cloud Function to sync products to Algolia
// functions/index.js

// const algoliasearch = require('algoliasearch');
// const client = algoliasearch('YOUR_APP_ID', 'YOUR_ADMIN_API_KEY');
// const index = client.initIndex('products');

// exports.syncProductToAlgolia = functions.firestore
//   .document('products/{productId}')
//   .onWrite(async (change, context) => {
//     const productId = context.params.productId;
    
//     // Delete
//     if (!change.after.exists) {
//       await index.deleteObject(productId);
//       return null;
//     }
    
//     // Create or Update
//     const product = change.after.data();
//     const algoliaObject = {
//       objectID: productId,
//       name: product.name,
//       description: product.description,
//       price: product.price,
//       categoryId: product.categoryId,
//       sellerId: product.sellerId,
//       imageUrls: product.imageUrls,
//       rating: product.rating || 0,
//       stockQuantity: product.stockQuantity || 0,
//       searchKeywords: product.searchKeywords || [],
//       createdAt: product.dateCreated?._seconds || 0,
//     };
    
//     await index.saveObject(algoliaObject);
//     return null;
//   });



//TODO 
//7. Race Conditions in Cart Management
// The cart uses subcollection which is good, but there's no optimistic locking for quantity updates.

//TODO
// functions/index.js

// const functions = require('firebase-functions');
// const admin = require('firebase-admin');

// /**
//  * Rate limiter using Firestore for distributed counting
//  * Prevents abuse of expensive operations
//  */
// class RateLimiter {
//   constructor(maxAttempts, windowSeconds) {
//     this.maxAttempts = maxAttempts;
//     this.windowSeconds = windowSeconds;
//   }

//   async checkLimit(userId, action) {
//     const db = admin.firestore();
//     const now = Date.now();
//     const windowStart = now - (this.windowSeconds * 1000);
    
//     const rateLimitRef = db
//       .collection('rate_limits')
//       .doc(`${userId}_${action}`);
    
//     return db.runTransaction(async (transaction) => {
//       const doc = await transaction.get(rateLimitRef);
      
//       if (!doc.exists) {
//         transaction.set(rateLimitRef, {
//           attempts: [now],
//           expiresAt: admin.firestore.Timestamp.fromMillis(now + (this.windowSeconds * 1000))
//         });
//         return { allowed: true, remaining: this.maxAttempts - 1 };
//       }
      
//       const data = doc.data();
//       const recentAttempts = data.attempts.filter(t => t > windowStart);
      
//       if (recentAttempts.length >= this.maxAttempts) {
//         const oldestAttempt = Math.min(...recentAttempts);
//         const retryAfter = Math.ceil((oldestAttempt + (this.windowSeconds * 1000) - now) / 1000);
        
//         throw new functions.https.HttpsError(
//           'resource-exhausted',
//           `Rate limit exceeded. Try again in ${retryAfter} seconds.`,
//           { retryAfter }
//         );
//       }
      
//       recentAttempts.push(now);
//       transaction.update(rateLimitRef, {
//         attempts: recentAttempts,
//         expiresAt: admin.firestore.Timestamp.fromMillis(now + (this.windowSeconds * 1000))
//       });
      
//       return {
//         allowed: true,
//         remaining: this.maxAttempts - recentAttempts.length
//       };
//     });
//   }
// }

// // Different limits for different operations
// const checkoutLimiter = new RateLimiter(3, 300); // 3 attempts per 5 minutes
// const cartLimiter = new RateLimiter(30, 60); // 30 additions per minute
// const productCreationLimiter = new RateLimiter(10, 3600); // 10 products per hour

// // Wrap your Cloud Functions with rate limiting
// exports.create_checkout_session = functions.https.onCall(async (data, context) => {
//   if (!context.auth) {
//     throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
//   }
  
//   // Check rate limit
//   await checkoutLimiter.checkLimit(context.auth.uid, 'checkout');
  
//   // ... rest of your checkout logic
// });

// // Clean up expired rate limit documents (run daily)
// exports.cleanupRateLimits = functions.pubsub
//   .schedule('every 24 hours')
//   .onRun(async (context) => {
//     const db = admin.firestore();
//     const now = admin.firestore.Timestamp.now();
    
//     const expiredDocs = await db.collection('rate_limits')
//       .where('expiresAt', '<', now)
//       .limit(500)
//       .get();
    
//     const batch = db.batch();
//     expiredDocs.docs.forEach(doc => batch.delete(doc.ref));
//     await batch.commit();
    
//     console.log(`Deleted ${expiredDocs.size} expired rate limit documents`);
//   });

// High Priority:

// Order Status Sync: When seller updates item status, buyer should see it in real-time (use StreamBuilder in orders_screen.dart)
// Indexing: Create composite indexes for all queries (Firestore will prompt you)
// Cart Cleanup: Add Cloud Function to clean up abandoned carts (older than 30 days)
// Email Notifications: Implement order confirmation emails via SendGrid/Mailgun
// Admin Panel: Build separate admin dashboard for moderation
// Testing: Add integration tests for checkout, payment flows

// Performance Optimizations:

// Image CDN: Use Cloudflare Image Resizing for different thumbnail sizes
// Caching: Implement Redis for frequently accessed data (categories, top products)
// Database Sharding: Consider partitioning orders by date for better query performance
// Lazy Loading: Implement proper pagination in all lists

// Security Additions:

// API Key Rotation: Don't hardcode keys, use environment variables
// Input Sanitization: Validate all user inputs on backend
// CORS Configuration: Properly configure Cloud Functions CORS
// PCI Compliance: Ensure Stripe integration follows PCI-DSS

//TODO: send notifications to sellers and customer