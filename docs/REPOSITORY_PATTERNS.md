# Repository Pattern Reference

> **Purpose**: Repositories are the data access layer. They abstract database operations, handle API calls, and transform raw data into domain models. ViewModels call Repositories, Repositories call OrignaBase SDK.

---

## Architecture Position

```
┌─────────────────────────────────────────────────────────┐
│                   VIEWMODELS                             │
│  - Call Repository methods                              │
│  - Receive domain models                                │
│  - Never see raw API responses                          │
└──────────────────────┬──────────────────────────────────┘
                       │ Repository calls
                       ▼
┌─────────────────────────────────────────────────────────┐
│                   REPOSITORIES                           │
│  - Abstract data access                                 │
│  - Transform raw data to models                        │
│  - Handle query building                                │
│  - No business logic                                    │
└──────────────────────┬──────────────────────────────────┘
                       │ SDK calls
                       ▼
┌─────────────────────────────────────────────────────────┐
│                ORIGNABASE SDK                            │
│  - GraphQL queries                                      │
│  - REST endpoints                                       │
│  - Realtime subscriptions                               │
└─────────────────────────────────────────────────────────┘
```

---

## Repository Catalog

### Core Repositories

| Repository | File | Responsibility |
|------------|------|----------------|
| `ProductRepository` | `orignabase_product_repository.dart` | Product CRUD, search |
| `OrderRepository` | `orignabase_order_repository.dart` | Order operations |
| `CartRepository` | `orignabase_cart_repository.dart` | Cart management |
| `UserRepository` | `orignabase_user_repository.dart` | User profile CRUD |
| `AddressRepository` | `orignabase_address_repository.dart` | Address management |
| `SellerRepository` | `orignabase_seller_repository.dart` | Seller operations |
| `ChatRepository` | `orignabase_chat_repository.dart` | Chat messages |
| `ReviewRepository` | `orignabase_review_repository.dart` | Product reviews |

---

## Repository Interface Pattern

All repositories follow a consistent interface:

```dart
abstract class Repository<T> {
  /// Fetch single item by ID
  Future<T?> fetchById(String id);

  /// Fetch multiple items with filters
  Future<List<T>> fetchAll({
    Map<String, dynamic>? filters,
    int? limit,
    int? offset,
  });

  /// Create new item
  Future<T> create(T item);

  /// Update existing item
  Future<T> update(T item);

  /// Delete item
  Future<void> delete(String id);
}
```

---

## ProductRepository

**File**: `lib/core/repositories/orignabase_product_repository.dart`

### Methods

```dart
class ProductRepository {
  final OrignaBase _ob;

  ProductRepository(this._ob);

  /// Fetch product by ID
  /// Returns null if not found (no exception)
  Future<Product?> fetchById(String productId) async {
    final doc = await _ob
        .collection(Collections.products)
        .doc(productId)
        .get();

    if (!doc.exists) return null;

    return Product.fromMap(doc.data()!, id: doc.id);
  }

  /// Fetch products with pagination
  /// Uses N+1 cursor pattern for hasMore detection
  Future<ProductQueryResult> fetchProducts({
    String? sellerId,
    int? categoryId,
    int? minPriceCents,
    int? maxPriceCents,
    String? searchQuery,
    String? lastDocumentId,
    int pageSize = 20,
  }) async {
    // Build query
    var query = _ob.collection(Collections.products);

    // Apply filters
    if (sellerId != null) {
      query = query.where(Fields.sellerId, '==', sellerId);
    }

    if (categoryId != null) {
      query = query.where(Fields.categoryId, '==', categoryId);
    }

    if (minPriceCents != null) {
      query = query.where(Fields.priceCents, '>=', minPriceCents);
    }

    if (maxPriceCents != null) {
      query = query.where(Fields.priceCents, '<=', maxPriceCents);
    }

    // Order and paginate
    query = query.orderBy(Fields.createdAt, descending: true);

    // N+1 pattern: request pageSize + 1 to detect hasMore
    query = query.limit(pageSize + 1);

    if (lastDocumentId != null) {
      query = query.startAfterId(lastDocumentId);
    }

    final snapshot = await query.get();

    // Determine if more results exist
    final hasMore = snapshot.docs.length > pageSize;
    final docsToMap = hasMore
        ? snapshot.docs.take(pageSize).toList()
        : snapshot.docs;

    final products = docsToMap.map((doc) {
      return Product.fromMap(doc.data()!, id: doc.id);
    }).toList();

    return ProductQueryResult(
      products: products,
      lastDocumentId: docsToMap.isNotEmpty ? docsToMap.last.id : null,
      hasMore: hasMore,
    );
  }

  /// Create product with atomic stock reservation
  Future<Product> createProduct(CreateProductData data) async {
    final productData = {
      Fields.sellerId: data.sellerId,
      Fields.name: data.name,
      Fields.description: data.description,
      Fields.priceCents: data.priceCents,
      Fields.stockQuantity: data.stockQuantity,
      Fields.categoryId: data.categoryId,
      Fields.imageUrls: data.imageUrls,
      Fields.createdAt: DateTime.now(),
      Fields.isDigital: data.isDigital,
      if (data.isDigital) ...{
        Fields.digitalType: data.digitalType,
        Fields.supportedPlatforms: data.supportedPlatforms,
      },
    };

    final docRef = await _ob
        .collection(Collections.products)
        .add(productData);

    return Product.fromMap(productData, id: docRef.id);
  }

  /// Update product (partial update)
  Future<Product> updateProduct(String productId, Map<String, dynamic> updates) async {
    updates[Fields.updatedAt] = DateTime.now();

    await _ob
        .collection(Collections.products)
        .doc(productId)
        .update(updates);

    // Fetch and return updated product
    return (await fetchById(productId))!;
  }

  /// Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    await _ob
        .collection(Collections.products)
        .doc(productId)
        .update({
          Fields.deletedAt: DateTime.now(),
          Fields.deletedBy: _ob.auth.currentUserId,
        });
  }

  /// Search products via Meilisearch
  Future<List<Product>> searchProducts(String query, {int limit = 20}) async {
    final response = await _ob.search(
      index: 'products',
      query: query,
      limit: limit,
    );

    return response.hits.map((hit) {
      return Product.fromMap(hit, id: hit['id']);
    }).toList();
  }
}
```

### Provider

```dart
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final ob = ref.watch(orignabaseProvider);
  return ProductRepository(ob);
});
```

### Usage in ViewModel

```dart
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    final repo = ref.watch(productRepositoryProvider);
    final result = await repo.fetchProducts(pageSize: 20);
    return result.products;
  }

  Future<void> loadMore() async {
    final currentProducts = state.valueOrNull ?? [];
    if (currentProducts.isEmpty) return;

    final repo = ref.read(productRepositoryProvider);
    final result = await repo.fetchProducts(
      lastDocumentId: currentProducts.last.id,
      pageSize: 20,
    );

    state = AsyncValue.data([...currentProducts, ...result.products]);
  }
}
```

---

## OrderRepository

**File**: `lib/core/repositories/orignabase_order_repository.dart`

### Key Methods

```dart
class OrderRepository {
  final OrignaBase _ob;

  /// Create order with Stripe Checkout Session
  Future<CheckoutResult> createCheckoutSession({
    required String userId,
    required List<CartItem> items,
    required Address shippingAddress,
    required String idempotencyKey,
  }) async {
    final response = await _ob.functions.call(
      CloudFunctionEndpoints.createCheckoutSession,
      {
        ApiKeys.idempotencyKey: idempotencyKey,
        Fields.items: items.map((i) => i.toMap()).toList(),
        Fields.shippingAddress: shippingAddress.toMap(),
      },
    );

    return CheckoutResult(
      checkoutUrl: response[ApiKeys.checkoutUrl],
      orderId: response[ApiKeys.orderId],
      sessionId: response[ApiKeys.sessionId],
    );
  }

  /// Verify cart prices before checkout
  Future<CartVerification> verifyCartPrices(List<String> productIds) async {
    final response = await _ob.functions.call(
      CloudFunctionEndpoints.verifyCartPrices,
      { Fields.items: productIds },
    );

    return CartVerification(
      hasChanges: response[ApiKeys.hasChanges],
      priceChanges: (response[ApiKeys.priceChanges] as List)
          .map((c) => PriceChange.fromMap(c))
          .toList(),
      stockChanges: (response[ApiKeys.stockChanges] as List)
          .map((c) => StockChange.fromMap(c))
          .toList(),
    );
  }

  /// Fetch user's orders with status filter
  Future<List<Order>> fetchOrders({
    required String userId,
    String? status,
    int limit = BusinessRules.ordersPageSize,
  }) async {
    var query = _ob
        .collection(Collections.orders)
        .where(Fields.userId, '==', userId);

    if (status != null) {
      query = query.where(Fields.status, '==', status);
    }

    query = query
        .orderBy(Fields.createdAt, descending: true)
        .limit(limit);

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return Order.fromMap(doc.data()!, id: doc.id);
    }).toList();
  }

  /// Cancel order (if within cancellation window)
  Future<void> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    await _ob.functions.call(
      CloudFunctionEndpoints.cancelOrder,
      {
        Fields.orderId: orderId,
        Fields.cancellationReason: reason,
      },
    );
  }

  /// Update order item status (seller action)
  Future<void> updateItemStatus({
    required String orderId,
    required String itemId,
    required String newStatus,
    String? trackingNumber,
    String? carrier,
  }) async {
    await _ob.functions.call(
      CloudFunctionEndpoints.updateItemStatus,
      {
        Fields.orderId: orderId,
        'itemId': itemId,
        ApiKeys.newStatus: newStatus,
        if (trackingNumber != null) Fields.trackingNumber: trackingNumber,
        if (carrier != null) Fields.carrier: carrier,
      },
    );
  }
}
```

---

## CartRepository

**File**: `lib/core/repositories/orignabase_cart_repository.dart`

### Key Methods

```dart
class CartRepository {
  final OrignaBase _ob;

  /// Fetch user's cart
  Future<List<CartItem>> fetchCart(String userId) async {
    final snapshot = await _ob
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.cart)
        .orderBy(Fields.createdAt, descending: true)
        .get();

    return snapshot.docs.map((doc) {
      return CartItem.fromMap(doc.data()!, id: doc.id);
    }).toList();
  }

  /// Add item to cart
  Future<CartItem> addItem({
    required String userId,
    required String productId,
    required int quantity,
  }) async {
    // Check if item already exists
    final existing = await _ob
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.cart)
        .where(Fields.productId, '==', productId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update quantity
      final doc = existing.docs.first;
      final currentQty = doc.data()![Fields.quantity] as int;
      await doc.reference.update({
        Fields.quantity: currentQty + quantity,
        Fields.updatedAt: DateTime.now(),
      });
      return CartItem.fromMap(doc.data()!, id: doc.id);
    }

    // Create new item
    final cartItemData = {
      Fields.productId: productId,
      Fields.quantity: quantity,
      Fields.createdAt: DateTime.now(),
    };

    final docRef = await _ob
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.cart)
        .add(cartItemData);

    return CartItem.fromMap(cartItemData, id: docRef.id);
  }

  /// Update item quantity
  Future<void> updateQuantity({
    required String userId,
    required String itemId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(userId: userId, itemId: itemId);
      return;
    }

    await _ob
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.cart)
        .doc(itemId)
        .update({
          Fields.quantity: quantity,
          Fields.updatedAt: DateTime.now(),
        });
  }

  /// Remove item from cart
  Future<void> removeItem({
    required String userId,
    required String itemId,
  }) async {
    await _ob
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.cart)
        .doc(itemId)
        .delete();
  }

  /// Clear entire cart (after checkout)
  Future<void> clearCart(String userId) async {
    final batch = _ob.batch();

    final cart = await _ob
        .collection(Collections.users)
        .doc(userId)
        .collection(Collections.cart)
        .get();

    for (final doc in cart.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
```

---

## Query Building Patterns

### Filtering

```dart
// Single filter
query = query.where(Fields.sellerId, '==', sellerId);

// Range filter (price between)
query = query.where(Fields.priceCents, '>=', minPrice);
query = query.where(Fields.priceCents, '<=', maxPrice);

// Array contains
query = query.whereArrayContains(Fields.tags, 'organic');

// IN query (one of multiple values)
query = query.where(Fields.status, 'in', ['pending', 'confirmed']);
```

### Ordering

```dart
// Single order
query = query.orderBy(Fields.createdAt, descending: true);

// Multiple orders (must match index)
query = query.orderBy(Fields.status)
            .orderBy(Fields.createdAt, descending: true);
```

### Pagination

```dart
// Cursor-based (N+1 pattern)
query = query.limit(pageSize + 1);
if (lastDocumentId != null) {
  query = query.startAfterId(lastDocumentId);
}
final snapshot = await query.get();
final hasMore = snapshot.docs.length > pageSize;
```

### Batch Operations

```dart
// Chunked batch writes (max 30 operations per batch)
for (int i = 0; i < items.length; i += 30) {
  final chunk = items.skip(i).take(30);
  final batch = _ob.batch();

  for (final item in chunk) {
    batch.add(
      _ob.collection(Collections.products).doc(),
      item.toMap(),
    );
  }

  await batch.commit();
}
```

---

## Error Handling in Repositories

```dart
class ProductRepository {
  Future<Product?> fetchById(String productId) async {
    try {
      final doc = await _ob
          .collection(Collections.products)
          .doc(productId)
          .get();

      if (!doc.exists) return null;

      return Product.fromMap(doc.data()!, id: doc.id);
    } on OrignaBaseException catch (e) {
      // Transform SDK errors to domain errors
      throw AppError.fromOrignaBaseError(e);
    } catch (e, st) {
      // Log unexpected errors
      AppError.log(e, stackTrace: st, context: 'ProductRepository.fetchById');
      rethrow;
    }
  }
}
```

---

## Testing Repositories

### Mock Repository

```dart
class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockProductRepository();
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('fetchProducts returns products', () async {
    // Arrange
    final mockProducts = [
      Product(id: '1', name: 'Product 1', priceCents: 1000),
    ];
    when(() => mockRepo.fetchProducts(pageSize: any(named: 'pageSize')))
        .thenAnswer((_) async => ProductQueryResult(
          products: mockProducts,
          hasMore: false,
        ));

    // Act
    final repo = container.read(productRepositoryProvider);
    final result = await repo.fetchProducts(pageSize: 20);

    // Assert
    expect(result.products, equals(mockProducts));
    expect(result.hasMore, isFalse);
  });
}
```

---

## Repository vs ViewModel

| Aspect | Repository | ViewModel |
|--------|------------|-----------|
| Purpose | Data access | Business logic |
| State | Stateless | Stateful |
| Knowledge | Knows API/DB | Knows UI requirements |
| Returns | Domain models | Domain models |
| Errors | Wraps SDK errors | Handles user-facing errors |
| Location | `lib/core/repositories/` | `lib/features/*/` |

---

## Best Practices

### 1. Return Domain Models, Not Raw Data

```dart
// ❌ Wrong - Returns raw map
Future<Map<String, dynamic>> fetchProduct(String id);

// ✅ Correct - Returns domain model
Future<Product?> fetchById(String id);
```

### 2. Use Schema Constants

```dart
// ❌ Wrong - Magic strings
query.where('priceCents', '>', 1000);

// ✅ Correct - Schema constants
query.where(Fields.priceCents, '>', 1000);
```

### 3. Handle Pagination Consistently

```dart
// ✅ Always use N+1 pattern
query = query.limit(pageSize + 1);
final hasMore = snapshot.docs.length > pageSize;
```

### 4. Soft Delete by Default

```dart
// ✅ Soft delete (recoverable)
await doc.update({
  Fields.deletedAt: DateTime.now(),
  Fields.deletedBy: userId,
});

// Hard delete only when explicitly required
await doc.delete();  // Use sparingly
```

---

## Quick Reference

| Repository | Key Methods |
|------------|-------------|
| `ProductRepository` | `fetchById()`, `fetchProducts()`, `createProduct()`, `searchProducts()` |
| `OrderRepository` | `createCheckoutSession()`, `fetchOrders()`, `cancelOrder()` |
| `CartRepository` | `fetchCart()`, `addItem()`, `updateQuantity()`, `clearCart()` |
| `UserRepository` | `fetchProfile()`, `updateProfile()`, `deleteAccount()` |
| `AddressRepository` | `fetchAddresses()`, `addAddress()`, `setDefault()` |

---

*Last updated: 2026-03-25 | Source: `lib/core/repositories/*.dart`*
