## 🔍 Audit Complet: MVVM, Performance, Cohérence - OrignaGTA

**Date**: 2026-01-31  
**Score Global**: **8.7/10**

---

## 1️⃣ AUDIT MVVM ARCHITECTURE

### ✅ **Forces (9/10)**

#### **Séparation des responsabilités**
```dart
// ✅ EXCELLENT: Layer separation
View (Screens) → ViewModel (StateNotifier) → Repository → Firebase

// Examples:
- screens/checkout_screen.dart → features/checkout/checkout_provider.dart → core/repositories/order_repository.dart
- screens/login_screen.dart → features/auth/login_viewmodel.dart → core/repositories/auth_repository.dart
```

**Implémentation ViewModels**:
- ✅ **20+ ViewModels** avec `StateNotifier<T>` (Riverpod pattern)
- ✅ Tous les ViewModels sont `autoDispose` (pas de leaks mémoire)
- ✅ States immutables avec `copyWith()` pattern
- ✅ Pas de logique métier dans les Screens

**Exemples conformes**:
```dart
// ✅ checkout_provider.dart
class CheckoutNotifier extends StateNotifier<CheckoutState> {
  Future<CheckoutResult> startCheckout({...}) async {
    state = state.copyWith(isProcessing: true);
    try {
      final result = await _orderRepository.createCheckoutSession(orderData);
      return CheckoutSuccess(checkoutUrl: result['url']);
    } catch (e) {
      state = state.copyWith(errorMessage: AppError.getMessage(e));
      return CheckoutError(message: AppError.getMessage(e));
    }
  }
}

// ✅ Screen reads state, calls ViewModel methods
final result = await notifier.startCheckout(items: items, user: userModel);
```

#### **Repositories pattern**
```dart
// ✅ Abstract interfaces
abstract class AuthRepository {
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<void> signOut();
}

// ✅ Firebase implementation
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  // Implementation details hidden from ViewModels
}
```

**Services remplaçables**:
- ✅ Auth, Product, Cart, Order, User repositories tous abstraits
- ✅ Location service avec interface (Geoapify actuellement, OCI prévu)
- ✅ Aucune référence directe à `FirebaseFirestore.instance` dans les ViewModels

---

### ⚠️ **Problèmes MVVM (Critiques)**

#### **1. Business logic dans Screens (VIOLATION MVVM)**
```dart
// ❌ checkout_screen.dart ligne 185-220
Future<void> _refreshShipping(BuildContext context, WidgetRef ref) async {
  final address = state.address;
  if (address == null || address.latitude == null) return;
  
  // ❌ LOGIQUE MÉTIER DANS SCREEN
  notifier.setCalculatingShipping(true);
  
  final taxRate = getTaxRate(address.state);  // ❌ Calcul dans UI
  final tax = subtotal * taxRate;             // ❌ Calcul dans UI
  
  try {
    final shippingCost = await shipping_service.calculateShipping(...);  // ❌ Direct service call
    notifier.updateShippingCost(shippingCost);
  } catch (e) {
    notifier.setShippingError(e.toString());
  }
}
```

**FIX**: Déplacer vers `CheckoutNotifier`:
```dart
// ✅ checkout_provider.dart
Future<void> refreshShipping(Address address, double subtotal) async {
  state = state.copyWith(isCalculatingShipping: true, shippingError: null);
  
  try {
    // All business logic in ViewModel
    final taxRate = _getTaxRate(address.state);
    final tax = subtotal * taxRate;
    
    final shipping = await _orderRepository.calculateShipping(
      items: state.items,
      destination: address,
      speed: state.deliverySpeed
    );
    
    state = state.copyWith(
      shippingCost: shipping,
      taxes: {'gst': tax},
      isCalculatingShipping: false
    );
  } catch (e) {
    state = state.copyWith(
      shippingError: e.toString(),
      isCalculatingShipping: false
    );
  }
}
```

#### **2. Logique métier dans utils.dart**
```dart
// ❌ utils.dart ligne 80-120
Future<void> addToCartFromScreen(BuildContext context, WidgetRef ref, ...) async {
  // ❌ BUSINESS LOGIC en helper global
  if (quantity < 1 || quantity > 100) {
    ScaffoldMessenger.of(context).showSnackBar(...);
    return;
  }
  
  final cartRepository = ref.read(cartRepositoryProvider);
  await cartRepository.addToCart(userId, productId, quantity);
  ScaffoldMessenger.of(context).showSnackBar(...);
}
```

**FIX**: Créer `CartViewModel`:
```dart
// ✅ features/cart/cart_viewmodel.dart
class CartViewModel extends StateNotifier<CartState> {
  Future<void> addToCart(String productId, int quantity) async {
    if (quantity < 1 || quantity > 100) {
      state = state.copyWith(error: 'Invalid quantity');
      return;
    }
    
    state = state.copyWith(isLoading: true);
    try {
      await _cartRepository.addToCart(_userId, productId, quantity);
      state = state.copyWith(isLoading: false, successMessage: 'Cart updated');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

#### **3. BuildContext dans méthodes async (VIOLATION Flutter)**
```dart
// ❌ rating_dialog.dart lignes 110-125
Future<void> _submitRating() async {
  // ... async work ...
  await viewModel.submitRating(widget.orderId, widget.productId, _rating, _comment);
  
  // ❌ BuildContext utilisé après await sans mounted check
  if (!mounted) return;  // ✅ Présent MAIS...
  
  ScaffoldMessenger.of(context).showSnackBar(...);  // ⚠️ Still risky
}
```

**FIX complet**:
```dart
// ✅ Extraire ScaffoldMessenger AVANT await
Future<void> _submitRating() async {
  final messenger = ScaffoldMessenger.of(context);  // ✅ Extract before async
  
  await viewModel.submitRating(widget.orderId, widget.productId, _rating, _comment);
  
  if (!mounted) return;
  messenger.showSnackBar(SnackBar(content: Text('Thank you!')));
}
```

**Occurrences à corriger**:
- ✅ `checkout_screen.dart:129` - CORRECT (extracts messenger)
- ❌ `rating_dialog.dart:121-125` - Uses context after await
- ❌ `shipping_approval_screen.dart:79` - Uses context after await
- ⚠️ `addproduct_screen.dart:67` - listener, mais ref.listen OK pour ça

---

## 2️⃣ AUDIT PERFORMANCE

### ✅ **Forces (8.5/10)**

#### **Provider optimization**
```dart
// ✅ autoDispose prevent memory leaks
final checkoutStateProvider = StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(...);

// ✅ Selective watching prevents unnecessary rebuilds
final isProcessing = ref.watch(checkoutStateProvider.select((state) => state.isProcessing));
```

**Analyses**:
- ✅ **100% des StateNotifiers** utilisent `autoDispose`
- ✅ **Selective watching** largement utilisé (checkout_screen.dart, orders_screen.dart)
- ✅ `const` constructors sur widgets statiques
- ✅ Pas de `setState` dans build methods

#### **Firestore query optimization**
```dart
// ✅ Indexed queries
.where('userId', '==', userId)
.where('status', '==', 'pending')
.orderBy('createdAt', descending: true)
.limit(20)  // ✅ Limite résultats
```

---

### ⚠️ **Problèmes Performance (Moyens)**

#### **1. StreamProvider sans limite**
```dart
// ❌ Potential: Streams all products without pagination
final productsStreamProvider = StreamProvider<List<ProductModel>>((ref) {
  return _firestore
    .collection('products')
    .where('isActive', isEqualTo: true)
    .snapshots()
    .map((snapshot) => snapshot.docs.map((doc) => ProductModel.fromMap(doc.data())).toList());
});
```

**Impact**: À 100M+ utilisateurs, 10K+ produits actifs = ~10MB par page load.

**FIX**:
```dart
// ✅ Pagination avec limit + startAfter
final productsPageProvider = StreamProvider.family<List<ProductModel>, ProductFilter>((ref, filter) {
  var query = _firestore
    .collection('products')
    .where('isActive', isEqualTo: true)
    .orderBy('createdAt', descending: true)
    .limit(20);  // ✅ Pagination
  
  if (filter.lastDoc != null) {
    query = query.startAfterDocument(filter.lastDoc!);
  }
  
  return query.snapshots().map(...);
});
```

#### **2. Nested watch dans build()**
```dart
// ⚠️ checkout_screen.dart lignes 100-150
@override
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.watch(checkoutStateProvider);
  final userModel = ref.watch(userModelProvider).valueOrNull;  // ⚠️ Could be null
  final items = ref.watch(cartItemsProvider).valueOrNull ?? [];
  
  // ⚠️ Multiple watches can cause unnecessary rebuilds
}
```

**Optimisation**:
```dart
// ✅ Combine related state
final checkoutDependencies = ref.watch(checkoutDependenciesProvider);
// Provider combines user + cart + address in single watch
```

#### **3. No caching for static data**
```dart
// ❌ Tax rates recalculated every checkout
final taxRate = getTaxRate(address.state);  // ❌ Map lookup every time

// ✅ Should be const
static const _taxRates = {
  'AB': 0.05,
  'ON': 0.13,
  // ...
};
```

---

## 3️⃣ AUDIT COHÉRENCE BACKEND/FRONTEND

### ✅ **Forces (9/10)**

#### **Constants synchronisés**
```dart
// ✅ Frontend: constants.dart
class Collections {
  static const String users = 'users';
  static const String products = 'products';
  static const String orders = 'orders';
}

// ✅ Backend: config.py
class Collections:
    USERS = 'users'
    PRODUCTS = 'products'
    ORDERS = 'orders'
```

**Status enums**:
- ✅ `OrderStatus`, `PaymentStatus`, `DeliveryStatus` identiques
- ✅ `UserRoles`, `Collections` cohérents
- ✅ `CaptureMethod` synchronisé

---

### ⚠️ **Incohérences (Critiques)**

#### **1. AUTO_CONFIRM_DAYS désynchronisé**
```dart
// ❌ Frontend: constants.dart ligne 16
static const int autoConfirmDays = 14;  // ❌ 14 jours

// ✅ Backend: config.py ligne 63 (FIXED)
AUTO_CONFIRM_DAYS = 7  # ✅ Stripe limit
```

**Impact**: UI affiche "14 jours" mais backend annule après 7 jours.

**FIX**:
```dart
// constants.dart
static const int autoConfirmDays = 7;  // ✅ Match backend
static const int authorizationValidDays = 7;  // ✅ Add this
```

#### **2. PLATFORM_FEE_PERCENT pas utilisé frontend**
```dart
// ✅ Backend: config.py
PLATFORM_FEE_PERCENT = 0.025  // 2.5%

// ❌ Frontend: constants.dart
static const double platformFeePercent = 0.025;  // ✅ Déclaré MAIS...

// ❌ Jamais utilisé dans l'app (pas de calcul de frais visible)
```

**Recommandation**: Si pas utilisé, supprimer de constants.dart pour éviter confusion.

#### **3. Shipping calculation logic duplicated**
```python
# Backend: shipping_service.py (lignes 60-100)
def _calculate_tiered_shipping(distance_km, seller_items, speed):
    if distance_km <= 15:
        base_cost = 1.99
    elif distance_km <= 50:
        base_cost = 4.99
    # ...
```

```dart
// ❌ Frontend: PAS de calcul shipping (bon pour MVVM)
// MAIS: Pas de preview avant checkout
```

**Recommandation**: Ajouter Cloud Function `estimate_shipping` pour preview sans créer commande.

---

## 4️⃣ AUDIT GLOBAL

### ✅ **Architecture solide**

**Dépendances**:
```
main.dart
  └─ ProviderScope
       └─ OrignaApp (MaterialApp)
            └─ AuthWrapper
                 ├─ LoginScreen (unauthenticated)
                 └─ HomeScreen (authenticated)
```

**Providers injection**: ✅ Tout via Riverpod, pas de singletons globaux

**Error handling**: ✅ Try-catch dans tous les ViewModels, states immutables

---

### ⚠️ **Anti-patterns détectés**

#### **1. God Object: constants.dart (383 lignes)**
```dart
// ❌ Trop de responsabilités dans 1 fichier
- Collections names
- Enums (OrderStatus, PaymentStatus, DeliveryStatus, etc.)
- Tax rates
- Delivery options
- User models
- Address models
- Cart models
```

**FIX**: Séparer en modules
```
utils/
  ├─ collections.dart
  ├─ enums.dart
  ├─ config.dart
models/
  ├─ user_model.dart
  ├─ address_model.dart
  ├─ cart_model.dart
```

#### **2. utils.dart avec business logic (244 lignes)**
```dart
// ❌ Helper functions avec side effects
Future<void> addToCartFromScreen(BuildContext context, WidgetRef ref, ...) {
  // Business logic + UI updates
}
```

**FIX**: Migrer vers ViewModels dédiés.

#### **3. Missing error boundary**
```dart
// ⚠️ App crash si provider throws
final userProfile = ref.watch(userProfileProvider);  // Can throw

// ✅ Should use AsyncValue
final userProfileAsync = ref.watch(userProfileProvider);
userProfileAsync.when(
  data: (profile) => ...,
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => ErrorWidget(error),
);
```

---

## 📊 RÉSUMÉ DES SCORES

| Catégorie | Score | Commentaire |
|-----------|-------|-------------|
| **MVVM Separation** | 9/10 | Excellent mais business logic dans screens |
| **ViewModel Quality** | 9.5/10 | Tous StateNotifier + autoDispose |
| **Repository Pattern** | 10/10 | Parfait, abstractions + implémentations |
| **Performance** | 8.5/10 | Bon mais manque pagination + caching |
| **Cohérence Backend/Frontend** | 9/10 | Constants sync mais autoConfirmDays désynchronisé |
| **Error Handling** | 8/10 | Try-catch présent mais manque AsyncValue pattern |
| **Code Organization** | 7/10 | God objects (constants.dart, utils.dart) |

**SCORE GLOBAL**: **8.7/10** 🟢

---

## 🔧 PLAN D'ACTION PRIORITAIRE

### **CRITIQUE (À corriger immédiatement)**
1. ✅ **autoConfirmDays sync**: `14 → 7` dans constants.dart
2. ❌ **Business logic extraction**: Migrer `_refreshShipping` vers CheckoutNotifier
3. ❌ **BuildContext safety**: Extraire ScaffoldMessenger avant await (3 fichiers)

### **IMPORTANT (Sprint prochain)**
4. ⚠️ **Pagination**: StreamProvider avec limit(20) + startAfter
5. ⚠️ **CartViewModel**: Créer ViewModel dédié (actuellement dans utils.dart)
6. ⚠️ **Split constants.dart**: Séparer en modules thématiques

### **NICE-TO-HAVE (Améliorations)**
7. 🔧 **AsyncValue pattern**: Wrapper tous les StreamProvider
8. 🔧 **Caching**: Provider avec keepAlive pour données statiques
9. 🔧 **Shipping preview**: Cloud Function estimate_shipping

---

## ✅ CONFORMITÉ AVEC RÈGLES PROJET

**claude.md compliance**:
- ✅ MVVM architecture enforced (ViewModels séparés)
- ✅ No business logic in widgets (sauf violations listées)
- ✅ APIs replaceable via repositories ✅
- ⚠️ BuildContext across async (3 violations)
- ✅ Riverpod state management ✅
- ✅ Error handling explicit ✅

**Score conformité**: **8.5/10**
