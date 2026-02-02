# Migration Frontend Flutter - Guide Complet

## Vue d'ensemble

Ce guide détaille le processus de migration des anciens modèles basés sur `Map<String, dynamic>` vers les nouveaux modèles **Freezed** immuables et typés.

**Date de début**: 2 février 2026  
**Statut**: 🚧 **EN COURS**

---

## Stratégie de Migration

### Approche Progressive (Migration Graduée)

Pour minimiser les risques et permettre un déploiement continu, nous utilisons une approche de **migration progressive** :

1. ✅ **Phase 1** : Création des adapters (COMPLÉTÉ)
2. 🚧 **Phase 2** : Migration des repositories (EN COURS)
3. ⏳ **Phase 3** : Migration des ViewModels
4. ⏳ **Phase 4** : Migration des UI widgets
5. ⏳ **Phase 5** : Nettoyage et suppression des anciens modèles

---

## Fichiers Créés

### 1. `lib/models/migration_adapters.dart`

Fournit des extensions pour convertir entre anciens et nouveaux modèles :

```dart
// Conversion Product: Legacy → Freezed
Product newProduct = oldProductModel.toFreezed();

// Conversion Product: Freezed → Legacy (pour période de transition)
ProductModel oldProduct = newProduct.toLegacy();

// Lecture depuis Firestore avec nouveau modèle
Product product = ProductFromFirestore.fromDocumentSnapshot(doc);
```

**Extensions disponibles** :
- ✅ `ProductModelToFreezed` - Converti ProductModel → Product
- ✅ `ProductToLegacy` - Converti Product → ProductModel
- ✅ `ProductFromFirestore` - Créer Product depuis DocumentSnapshot
- ✅ `OrderModelToFreezed` - Converti OrderModel → Order
- ✅ `OrderToLegacy` - Converti Order → OrderModel
- ✅ `OrderFromFirestore` - Créer Order depuis DocumentSnapshot
- ✅ `UserFromFirestore` - Créer User depuis DocumentSnapshot

---

## Phase 2 : Migration des Repositories

### Repositories à Migrer

#### ✅ Priorité Haute (Impact maximal)
1. **ProductRepository** - Utilisé partout dans l'app
   - `lib/core/repositories/product_repository.dart`
   - `lib/core/repositories/algolia_product_repository.dart`
   - `lib/core/repositories/firebase_product_repository.dart`

2. **OrderRepository** - Checkout et historique commandes
   - `lib/core/repositories/order_repository.dart`

3. **UserRepository** - Authentification et profils
   - `lib/core/repositories/user_repository.dart`

#### ⏳ Priorité Moyenne
4. **AdminRepository** - Panneau admin
   - `lib/admin/admin_repository.dart`

#### ⏳ Priorité Basse
5. Autres repositories spécialisés

---

## Guide de Migration - Repositories

### Étape 1 : Import des nouveaux modèles

**Avant** :
```dart
import 'package:origna_gta/models/models.dart';
```

**Après** :
```dart
import 'package:origna_gta/models/generated/models.dart';
import 'package:origna_gta/models/migration_adapters.dart'; // Pour période de transition
```

---

### Étape 2 : Conversion des signatures de méthodes

#### ProductRepository

**Avant** :
```dart
Future<ProductModel?> fetchProductById(String productId) async {
  final doc = await _firestore.collection('products').doc(productId).get();
  if (!doc.exists) return null;
  return ProductModel.fromDocument(doc);
}
```

**Après** :
```dart
Future<Product?> fetchProductById(String productId) async {
  final doc = await _firestore.collection('products').doc(productId).get();
  if (!doc.exists) return null;
  return ProductFromFirestore.fromDocumentSnapshot(doc);
}
```

**Bénéfices** :
- ✅ Type safety complète
- ✅ Validation automatique des champs
- ✅ Immutabilité garantie
- ✅ Autocomplete IDE amélioré

---

### Étape 3 : Conversion des Query Results

**Avant** :
```dart
Future<List<ProductModel>> fetchProducts() async {
  final snapshot = await _firestore.collection('products').get();
  return snapshot.docs.map((doc) => ProductModel.fromDocument(doc)).toList();
}
```

**Après** :
```dart
Future<List<Product>> fetchProducts() async {
  final snapshot = await _firestore.collection('products').get();
  return snapshot.docs
      .map((doc) => ProductFromFirestore.fromDocumentSnapshot(doc))
      .toList();
}
```

---

### Étape 4 : Conversion avec Streams

**Avant** :
```dart
Stream<List<ProductModel>> watchProducts() {
  return _firestore.collection('products')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProductModel.fromDocument(doc))
          .toList());
}
```

**Après** :
```dart
Stream<List<Product>> watchProducts() {
  return _firestore.collection('products')
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ProductFromFirestore.fromDocumentSnapshot(doc))
          .toList());
}
```

---

## Guide de Migration - ViewModels

### Étape 1 : Utiliser `copyWith()` au lieu de mutation manuelle

#### Avant (Mutable)
```dart
class HomeViewModel extends ChangeNotifier {
  ProductModel? _selectedProduct;
  
  void updateProductPrice(double newPrice) {
    if (_selectedProduct != null) {
      _selectedProduct = ProductModel(
        productId: _selectedProduct!.productId,
        name: _selectedProduct!.name,
        description: _selectedProduct!.description,
        price: newPrice, // Nouveau prix
        // ... copie de tous les autres champs manuellement
      );
      notifyListeners();
    }
  }
}
```

#### Après (Immutable avec Freezed)
```dart
class HomeViewModel extends ChangeNotifier {
  Product? _selectedProduct;
  
  void updateProductPrice(double newPrice) {
    if (_selectedProduct != null) {
      _selectedProduct = _selectedProduct!.copyWith(price: newPrice);
      notifyListeners();
    }
  }
}
```

**Bénéfices** :
- 🎯 **90% réduction de code** (1 ligne vs 15+ lignes)
- ✅ **Aucun oubli de champ** (copyWith copie automatiquement tout)
- 🔒 **Immutabilité garantie** (impossible de modifier l'original)
- 📝 **Plus lisible** (intention claire)

---

### Étape 2 : Comparaison d'objets avec `==`

#### Avant (Comparaison manuelle)
```dart
bool areProductsEqual(ProductModel p1, ProductModel p2) {
  return p1.productId == p2.productId &&
         p1.name == p2.name &&
         p1.description == p2.description &&
         p1.price == p2.price &&
         // ... 20+ comparaisons manuelles
}
```

#### Après (Equality automatique)
```dart
bool areProductsEqual(Product p1, Product p2) {
  return p1 == p2; // Freezed génère == et hashCode automatiquement
}
```

---

## Tests de Migration

### Test de Conversion Legacy ↔ Freezed

```dart
test('ProductModel converts to Product and back', () {
  // Legacy product
  final legacyProduct = ProductModel(
    productId: 'prod123',
    name: 'Test Product',
    price: 29.99,
    categoryId: 5,
    sellerId: 'seller123',
    sellerAddress: Address(...),
    imageUrls: ['https://example.com/image.jpg'],
    stockQuantity: 10,
  );
  
  // Convert to Freezed
  final freezedProduct = legacyProduct.toFreezed();
  expect(freezedProduct.name, 'Test Product');
  expect(freezedProduct.price, 29.99);
  
  // Convert back to legacy
  final convertedBack = freezedProduct.toLegacy();
  expect(convertedBack.name, legacyProduct.name);
  expect(convertedBack.price, legacyProduct.price);
});
```

---

## Checklist de Migration

### Repository Migration

- [ ] Importer nouveaux modèles (`generated/models.dart`)
- [ ] Remplacer `ProductModel` → `Product`
- [ ] Remplacer `OrderModel` → `Order`
- [ ] Remplacer `UserModel` → `User`
- [ ] Utiliser `ProductFromFirestore.fromDocumentSnapshot()`
- [ ] Mettre à jour les tests

### ViewModel Migration

- [ ] Remplacer muta tions manuelles par `copyWith()`
- [ ] Utiliser `==` au lieu de comparaisons manuelles
- [ ] Mettre à jour les providers
- [ ] Tester l'immutabilité

### UI Migration

- [ ] Vérifier que les widgets acceptent les nouveaux modèles
- [ ] Utiliser les getters générés (ex: `product.formattedPrice`)
- [ ] Tester les interactions utilisateur

---

## Commandes Utiles

### Regénérer code Freezed après modifications
```bash
cd origna_gta
flutter pub run build_runner build --delete-conflicting-outputs
```

### Exécuter tests
```bash
# Tests modèles Freezed
flutter test test/unit/schema_models_test.dart

# Tous les tests Dart
flutter test

# Tests Python backend
cd ../functions && python3 -m pytest tests/ -v
```

### Validation complète
```bash
./scripts/validate_schema_consistency.sh
```

---

## Problèmes Courants et Solutions

### Erreur: "The argument type 'Product' can't be assigned to 'ProductModel'"

**Solution** : Utiliser l'adapter pendant la migration

```dart
// Option 1: Convertir Product → ProductModel temporairement
ProductModel legacy = freezedProduct.toLegacy();

// Option 2: Migrer le code appelant pour accepter Product
void processProduct(Product product) { // au lieu de ProductModel
  // ...
}
```

---

### Erreur: "Nested Address object is not Map<String, dynamic>"

**Solution** : Freezed ne convertit pas automatiquement les objets imbriqués en Map

```dart
// ❌ Ne fonctionne pas
final json = product.toJson();
// json['sellerAddress'] est un objet Address, pas un Map

// ✅ Solution: Utiliser fromFirestore/toMap helpers
final product = Product.fromFirestore(firestoreData);
```

---

## Métriques de Succès

| Métrique | Objectif | Actuel |
|----------|----------|--------|
| Repositories migrés | 5 | 0 |
| ViewModels migrés | 10 | 0 |
| Tests UI passants | 100% | - |
| Code coverage | >85% | - |
| Réduction lignes code | -30% | - |

---

## Prochaines Actions

### Immediate (Cette session)
1. ✅ Créer migration_adapters.dart
2. 🚧 Migrer AlgoliaProductRepository
3. ⏳ Migrer ProductRepository interface
4. ⏳ Tester la migration avec tests existants

### Court terme (Cette semaine)
5. ⏳ Migrer OrderRepository
6. ⏳ Migrer UserRepository
7. ⏳ Migrer providers Riverpod

### Moyen terme (Prochaine semaine)
8. ⏳ Migrer ViewModels (Home, Checkout, Orders)
9. ⏳ Mettre à jour tests d'intégration
10. ⏳ Documentation API avec nouveaux modèles

---

## Ressources

- [Freezed Documentation](https://pub.dev/packages/freezed)
- [JSON Serializable](https://pub.dev/packages/json_serializable)
- [Pydantic Documentation](https://docs.pydantic.dev/)
- [BACKEND_MIGRATION_COMPLETE.md](BACKEND_MIGRATION_COMPLETE.md)

---

## Support

Pour questions ou problèmes de migration, consulter:
1. Ce document (FRONTEND_MIGRATION_GUIDE.md)
2. Adapters (`lib/models/migration_adapters.dart`)
3. Tests de référence (`test/unit/schema_models_test.dart`)
