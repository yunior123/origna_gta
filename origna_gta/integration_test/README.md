# 🧪 Tests d'Intégration Flutter - Création de Produits

## 📋 Description

Ce test d'intégration simule un flux complet utilisateur :
1. **Connexion** avec email/password
2. **Navigation** vers l'écran d'ajout de produit
3. **Création de 10 produits** avec des données variées
4. **Tests de cas limites** (produits minimaux, produits numériques)

## 🏗️ Structure des Tests

```
integration_test/
└── product_creation_test.dart    # Tests d'intégration création produits
```

## 📦 Produits de Test Créés

Le test principal crée **10 produits variés** :

1. **Organic Green Tea** - Produit périssable avec livraison gratuite
2. **Wireless Bluetooth Headphones** - Électronique standard
3. **Yoga Mat** - Article de fitness éco-friendly
4. **E-Book Flutter Development** - Produit numérique
5. **Ceramic Coffee Mug** - Artisanat avec commande minimum
6. **Fresh Organic Honey** - Produit périssable local
7. **Stainless Steel Water Bottle** - Produit réutilisable
8. **Online Course Digital Marketing** - Formation en ligne
9. **Cotton T-Shirt** - Vêtement avec commande minimum
10. **Plant-Based Protein Powder** - Supplément nutritionnel

### Variation des Paramètres

- **Prix** : de 15.99$ à 149.99$
- **Stock** : de 30 à 999 unités
- **Villes** : Toronto, Montreal, Vancouver, Calgary, Ottawa, etc.
- **Types** : Physiques, numériques, périssables
- **Livraison** : Gratuite ou payante
- **Commande minimum** : 1 ou 2 unités

## 🚀 Prérequis

### 1. Dépendances Flutter

Assurez-vous que `pubspec.yaml` contient :

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### 2. Configuration Firebase

- Firebase doit être configuré pour les tests
- Un compte vendeur de test doit exister : `seller@origna.ca` avec mot de passe `Test123456!`

### 3. Émulateur ou Appareil Physique

Les tests d'intégration nécessitent :
- Un émulateur Android/iOS lancé
- **OU** un appareil physique connecté en mode debug

## ▶️ Exécution des Tests

### Test Complet (10 produits)

```bash
cd origna_gta
flutter test integration_test/product_creation_test.dart
```

### Test Spécifique

```bash
# Test avec produit minimal
flutter test integration_test/product_creation_test.dart -n "minimum required fields"

# Test produit numérique
flutter test integration_test/product_creation_test.dart -n "digital product"
```

### Avec Émulateur Spécifique

```bash
# Lister les appareils disponibles
flutter devices

# Exécuter sur un appareil spécifique
flutter test integration_test/product_creation_test.dart -d <device_id>
```

### Mode Verbose (pour debugging)

```bash
flutter test integration_test/product_creation_test.dart --verbose
```

## 📱 Exécution sur Plateformes Spécifiques

### Android

```bash
flutter test integration_test/product_creation_test.dart -d android
```

### iOS (nécessite macOS)

```bash
flutter test integration_test/product_creation_test.dart -d ios
```

### Chrome (Web)

```bash
flutter test integration_test/product_creation_test.dart -d chrome --web-renderer html
```

## 🐛 Debugging

### Afficher les Logs

Les tests affichent des logs détaillés :
- `📱 Step 1: Logging in...`
- `📦 Creating product X/10: Product Name`
- `✏️ Entering product name...`
- `✅ Product X created successfully!`

### Ralentir l'Exécution

Pour mieux observer les actions :

```dart
// Dans le test, ajoutez des délais
await tester.pumpAndSettle(const Duration(seconds: 5)); // Au lieu de 2s
```

### Captures d'Écran

Ajouter dans le test :

```dart
await tester.takeScreenshot('product_${i}_created');
```

## ⚠️ Limitations Actuelles

1. **Keys non implémentées** : Le test utilise `find.byType()` et `find.text()` au lieu de Keys
   - Pour améliorer : Ajouter les Keys du fichier `lib/utils/test_keys.dart` aux widgets
   
2. **Timing sensible** : Les délais (`Duration`) peuvent nécessiter ajustement selon la vitesse de l'appareil

3. **Images non testées** : Le test ne télécharge pas d'images produits (fonctionnalité future)

## 🔧 Améliorations Futures

### 1. Ajouter des Keys aux Widgets

Dans `lib/features/add_product/add_product_screen.dart` :

```dart
import 'package:origna_gta/utils/test_keys.dart';

// Exemple
TextFormField(
  key: const ValueKey(TestKeys.productNameField),
  controller: _nameController,
  ...
)
```

### 2. Vérification en Base de Données

Ajouter après la création des produits :

```dart
// Vérifier que les produits existent dans Firestore
final db = FirebaseFirestore.instance;
final productsSnapshot = await db.collection('products')
    .where('name', whereIn: testProducts.map((p) => p['name']).toList())
    .get();
    
expect(productsSnapshot.docs.length, equals(10));
```

### 3. Nettoyage après Tests

```dart
tearDown(() async {
  // Supprimer les produits de test créés
  final db = FirebaseFirestore.instance;
  final testProductNames = testProducts.map((p) => p['name']).toList();
  final snapshot = await db.collection('products')
      .where('name', whereIn: testProductNames)
      .get();
  
  for (final doc in snapshot.docs) {
    await doc.reference.delete();
  }
});
```

## 📊 Métriques de Performance

Le test mesure :
- **Temps de login** : ~5 secondes
- **Temps par produit** : ~10-15 secondes
- **Temps total** : ~2-3 minutes pour 10 produits

## ✅ Checklist Pré-Exécution

- [ ] Firebase configuré et accessible
- [ ] Compte vendeur de test créé (`seller@origna.ca`)
- [ ] Émulateur/appareil lancé et détecté (`flutter devices`)
- [ ] Dépendances installées (`flutter pub get`)
- [ ] Backend Firebase Functions déployé
- [ ] Connexion Internet active

## 🎯 Cas d'Usage

Ces tests sont utiles pour :
- ✅ Validation du flux complet utilisateur
- ✅ Tests de régression avant releases
- ✅ Démonstration de l'application
- ✅ Génération de données de test
- ✅ Validation de l'UI/UX

## 📚 Ressources

- [Flutter Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [Integration Test Package](https://pub.dev/packages/integration_test)
- [Testing Best Practices](https://docs.flutter.dev/testing/overview)

---

**Dernière mise à jour** : 3 février 2026  
**Auteur** : Équipe OrignaGta  
**Version** : 1.0.0
