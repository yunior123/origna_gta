# OrignaGTA Flutter SDK Quick Start

The OrignaBase Flutter SDK provides type-safe, real-time database access to the OrignaGTA backend. This guide covers installation, initialization, common operations, and error handling.

---

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  orignabase: ^1.0.0
  freezed_annotation: ^2.4.0

dev_dependencies:
  build_runner: ^2.4.0
  freezed: ^2.4.0
```

Then run:

```bash
flutter pub get
```

---

## Initialization

Initialize OrignaBase once at app startup:

```dart
import 'package:orignabase/orignabase.dart';

Future<void> main() async {
  // Initialize OrignaBase SDK
  await OrignaBase.initialize(
    url: 'https://api.dev.orignagta.ca',  // dev/staging/production
    appId: 'origna_gta_flutter',
    debugMode: true,  // false in production
  );

  runApp(const MyApp());
}
```

**Configuration Options**:
- `url`: Backend URL (dev: https://api.dev.orignagta.ca, prod: https://api.orignagta.ca)
- `appId`: Unique app identifier for analytics
- `debugMode`: Enable console logging for debugging

---

## Authentication

### Register

```dart
final result = await OrignaBase.auth.register(
  email: 'user@example.com',
  password: 'SecurePassword123!',
  displayName: 'John Doe',
  turnstileToken: turnstileToken,  // Required on web
);

result.match(
  (user) {
    print('Registered: ${user.email}');
    // User is automatically signed in
  },
  (error) {
    print('Registration failed: ${error.message}');
  },
);
```

### Login

```dart
final result = await OrignaBase.auth.login(
  email: 'user@example.com',
  password: 'SecurePassword123!',
  turnstileToken: turnstileToken,
);

result.match(
  (authResponse) {
    print('Logged in as: ${authResponse.user.email}');
    
    if (authResponse.mfaRequired) {
      // Proceed to MFA challenge
      await showMFADialog();
    }
  },
  (error) {
    print('Login failed: ${error.message}');
  },
);
```

### MFA Challenge

If `mfaRequired=true` in login response:

```dart
final result = await OrignaBase.auth.mfaChallenge(
  code: '123456',  // 6-digit TOTP code
  sessionToken: authResponse.sessionToken,
);

result.match(
  (tokens) {
    print('MFA verified. Tokens: ${tokens.accessToken}');
  },
  (error) {
    print('Invalid MFA code: ${error.message}');
  },
);
```

### Logout

```dart
await OrignaBase.auth.signOut();
print('Logged out');
```

### Watch Auth State

```dart
OrignaBase.auth.authStateChanges().listen((user) {
  if (user != null) {
    print('User signed in: ${user.email}');
  } else {
    print('User signed out');
  }
});
```

### Refresh Token

The SDK automatically refreshes expired access tokens. You don't need to call this manually:

```dart
// Manual refresh (rarely needed)
final result = await OrignaBase.auth.refresh();
result.match(
  (tokens) => print('Token refreshed'),
  (error) => print('Refresh failed: ${error.message}'),
);
```

### Password Reset

Request:
```dart
final result = await OrignaBase.auth.forgotPassword(
  email: 'user@example.com',
);
```

Reset (from email link):
```dart
final result = await OrignaBase.auth.resetPassword(
  token: 'reset_abc123xyz',
  newPassword: 'NewPassword456!',
);
```

### Email Verification

```dart
final result = await OrignaBase.auth.verifyEmail(
  token: 'REDACTED_SECRET',
);

// Resend verification email
await OrignaBase.auth.sendVerificationEmail();
```

### Setup MFA

```dart
// 1. Start MFA setup
final result = await OrignaBase.auth.mfaSetup();

result.match(
  (mfaData) {
    print('Scan QR code: ${mfaData.qrCodeUrl}');
    print('Backup codes: ${mfaData.backupCodes}');
  },
  (error) => print('MFA setup error: ${error.message}'),
);

// 2. Verify with TOTP code
final verifyResult = await OrignaBase.auth.mfaVerifySetup(
  code: '123456',
);

verifyResult.match(
  (_) => print('MFA enabled'),
  (error) => print('Verification failed: ${error.message}'),
);
```

### Disable MFA

```dart
final result = await OrignaBase.auth.mfaDisable();
result.match(
  (_) => print('MFA disabled'),
  (error) => print('Disable failed: ${error.message}'),
);
```

---

## Database Collections

### Get a Reference

```dart
final productsRef = OrignaBase.collection('products');
final ordersRef = OrignaBase.collection('orders');
final usersRef = OrignaBase.collection('users');
```

### Create a Document

```dart
final result = await productsRef.add({
  'title': 'MacBook Pro 16"',
  'priceCents': 199999,
  'currency': 'CAD',
  'stockQuantity': 5,
  'dateCreated': OrignaBase.serverTimestamp(),
});

result.match(
  (docId) {
    print('Created product: $docId');
  },
  (error) {
    print('Create failed: ${error.message}');
  },
);
```

### Read a Document

```dart
final result = await productsRef.doc('products:xyz123').get();

result.match(
  (doc) {
    final title = doc.get('title');
    final price = doc.get('priceCents') as int;
    print('Title: $title, Price: \$${price / 100}');
  },
  (error) {
    print('Read failed: ${error.message}');
  },
);
```

### Update a Document

```dart
final result = await productsRef.doc('products:xyz123').update({
  'stockQuantity': 4,
  'lastUpdated': OrignaBase.serverTimestamp(),
});

result.match(
  (_) => print('Updated'),
  (error) => print('Update failed: ${error.message}'),
);
```

### Delete a Document

```dart
final result = await productsRef.doc('products:xyz123').delete();

result.match(
  (_) => print('Deleted'),
  (error) => print('Delete failed: ${error.message}'),
);
```

---

## Queries

### Query Basics

```dart
final query = productsRef
    .where('lifecycleStatus', '==', 'active')
    .where('priceCents', '<=', 500000)  // Max $5000
    .orderBy('dateCreated', Direction.descending)
    .limit(20);

final result = await query.get();

result.match(
  (docs) {
    for (final doc in docs) {
      print('${doc.get("title")}: \$${doc.get("priceCents") / 100}');
    }
  },
  (error) => print('Query failed: ${error.message}'),
);
```

### Comparison Operators

- `'=='`: Equals
- `'<'`: Less than
- `'<='`: Less than or equal
- `'>'`: Greater than
- `'>='`: Greater than or equal
- `'!='`: Not equal
- `'in'`: Value in array
- `'array-contains'`: Array contains value

### Pagination

```dart
const pageSize = 20;
int offset = 0;

final query = productsRef
    .limit(pageSize)
    .offset(offset);

final nextPage = await query.get();
nextPage.match(
  (docs) {
    offset += pageSize;
    print('Next page: ${docs.length} items');
  },
  (error) => print('Error: ${error.message}'),
);
```

### Search (Meilisearch)

```dart
final result = await productsRef.search(
  query: 'laptop',
  filters: {
    'lifecycleStatus': 'active',
    'priceCents': {'min': 100000, 'max': 500000},
  },
  sort: ['priceCents:asc'],
  limit: 20,
);

result.match(
  (docs) => print('Found ${docs.length} products'),
  (error) => print('Search failed: ${error.message}'),
);
```

---

## Real-Time Subscriptions

Listen for live changes:

```dart
final subscription = productsRef
    .where('sellerId', '==', 'users:seller_xyz')
    .onSnapshot()
    .listen((result) {
      result.match(
        (docs) {
          print('Seller has ${docs.length} products');
          // UI automatically updates
        },
        (error) => print('Stream error: ${error.message}'),
      );
    });

// Unsubscribe when done
subscription.cancel();
```

### Filtered Subscriptions

```dart
ordersRef
    .where('buyerId', '==', currentUserId)
    .where('status', '==', 'pending')
    .onSnapshot()
    .listen((result) {
      result.match(
        (docs) => print('Pending orders: ${docs.length}'),
        (error) => print('Error: ${error.message}'),
      );
    });
```

---

## Sub-collections

Some documents contain sub-collections (e.g., order items):

```dart
// Get order items
final orderId = 'orders:ord_abc123';
final itemsRef = ordersRef.doc(orderId).collection('items');

final result = await itemsRef.get();

result.match(
  (items) {
    for (final item in items) {
      print('${item.get("productName")}: x${item.get("quantity")}');
    }
  },
  (error) => print('Error: ${error.message}'),
);
```

---

## Transactions

Ensure data consistency:

```dart
final result = await OrignaBase.runTransaction((transaction) async {
  // Read
  final orderDoc = await transaction.get(ordersRef.doc('orders:ord_abc123'));
  final currentStock = orderDoc.get('stockQuantity') as int;

  // Modify
  if (currentStock <= 0) {
    throw Exception('Out of stock');
  }

  // Write
  await transaction.update(ordersRef.doc('orders:ord_abc123'), {
    'stockQuantity': currentStock - 1,
  });

  return 'Stock decremented';
});

result.match(
  (message) => print(message),
  (error) => print('Transaction failed: ${error.message}'),
);
```

---

## Batch Writes

Update multiple documents atomically:

```dart
final batch = OrignaBase.batch();

batch.set(productsRef.doc('products:xyz1'), {
  'stockQuantity': 0,
  'lifecycleStatus': 'inactive',
});

batch.set(productsRef.doc('products:xyz2'), {
  'priceCents': 250000,
});

final result = await batch.commit();

result.match(
  (_) => print('Batch committed'),
  (error) => print('Batch failed: ${error.message}'),
);
```

---

## Error Handling

All SDK methods return `Result<T, AppError>`:

```dart
abstract class AppError {
  String get message;
  String? get code;
  dynamic get originalError;
}

// Usage
result.match(
  (success) => print('Success: $success'),
  (error) {
    switch (error.code) {
      case 'UNAUTHORIZED':
        // User not authenticated
        navigateToLogin();
      case 'FORBIDDEN':
        // User not permitted
        showError('You do not have permission');
      case 'NOT_FOUND':
        // Document doesn't exist
        showError('Not found');
      case 'VALIDATION_ERROR':
        // Invalid input
        showError(error.message);
      default:
        // Unknown error
        reportToCrashlytics(error);
    }
  },
);
```

### Common Error Codes

| Code | Meaning |
|------|---------|
| `UNAUTHORIZED` | Not authenticated or JWT expired |
| `FORBIDDEN` | Authenticated but not permitted |
| `NOT_FOUND` | Resource doesn't exist |
| `VALIDATION_ERROR` | Invalid input or business logic error |
| `NETWORK_ERROR` | Network timeout or connectivity issue |
| `DATABASE_ERROR` | Server-side database error |
| `RATE_LIMITED` | Too many requests |

---

## Offline Support

The SDK supports offline reads/writes (auto-sync when online):

```dart
// Write while offline
await productsRef.doc('products:xyz123').set({
  'title': 'Updated offline',
}, offline: true);

// When connection restored, sync automatically
OrignaBase.connected.listen((isConnected) {
  if (isConnected) {
    print('Back online, syncing...');
  }
});
```

---

## Type Safety with Freezed

Define models for type-safe access:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String title,
    required int priceCents,
    required int stockQuantity,
    required DateTime dateCreated,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

// Usage
final result = await productsRef.doc('products:xyz123').get();

result.match(
  (doc) {
    final product = Product.fromJson(doc.data());
    print('Product: ${product.title}, Price: \$${product.priceCents / 100}');
  },
  (error) => print('Error: ${error.message}'),
);
```

---

## Performance Best Practices

1. **Use `.select()` in Riverpod** to avoid unnecessary rebuilds:
   ```dart
   final productRef = FutureProvider((ref) => 
     ref.watch(productsProvider.select((p) => p.title))
   );
   ```

2. **Paginate instead of fetching all**:
   ```dart
   // Good
   final page = await productsRef.limit(20).offset(0).get();
   
   // Bad
   final all = await productsRef.get();  // 10,000+ docs = slow
   ```

3. **Use indexes for frequent queries**:
   ```dart
   // Request index for sellerId + status
   // Contact support: support@orignagta.ca
   ```

4. **Subscribe only to what you need**:
   ```dart
   // Good
   ordersRef.where('buyerId', '==', userId).onSnapshot()
   
   // Bad
   ordersRef.onSnapshot()  // All orders = heavy load
   ```

5. **Limit real-time subscriptions**:
   - Max 5 concurrent subscriptions per user
   - Unsubscribe when screen closes

---

## Advanced: Custom Queries

For complex filtering, use SurrealDB query syntax:

```dart
final result = await OrignaBase.query('''
  SELECT * FROM products 
  WHERE lifecycleStatus = 'active' 
    AND priceCents <= $price 
    AND sellerId != $currentSellerId
  ORDER BY dateCreated DESC
  LIMIT 20
''', params: {
  'price': 500000,
  'currentSellerId': userId,
});

result.match(
  (docs) => print('${docs.length} products found'),
  (error) => print('Query error: ${error.message}'),
);
```

---

## Metrics & Analytics

Track app usage:

```dart
await OrignaBase.analytics.logEvent(
  name: 'product_viewed',
  parameters: {
    'product_id': 'products:xyz123',
    'price': 199999,
  },
);

await OrignaBase.analytics.logEvent(
  name: 'checkout_completed',
  parameters: {
    'total_cents': 225998,
    'item_count': 3,
  },
);
```

---

## Support & Resources

- **API Docs**: `/docs/api-reference.md`
- **Schema Reference**: `/docs/schema-reference.md`
- **Issues**: Report bugs to support@orignagta.ca
- **Example App**: `/examples/flutter_app_example/`

---

**Last Updated**: March 18, 2026  
**SDK Version**: 1.0.0  
**Minimum Flutter**: 3.10.0
