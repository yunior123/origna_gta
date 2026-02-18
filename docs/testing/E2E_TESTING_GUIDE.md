# E2E Testing Guide - OrignaGTA

## 🎯 Solutions de Test Configurées

### 1. **Playwright E2E Tests** (14 tests ✅)
Tests d'infrastructure et de chargement Flutter Web.

```bash
# Lancer les tests Playwright
cd e2e && npx playwright test flutter-web-e2e.spec.ts --project=chromium
```

### 2. **Flutter Integration Tests** (avec `flutter drive`)
Tests natifs Flutter qui fonctionnent avec le widget tree.

```bash
# Lancer sur Chrome (nécessite chromedriver)
cd origna_gta
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d web-server --browser-name=chrome
```

### 3. **Patrol Tests** (Flutter Web avec Playwright backend)
La meilleure solution pour tester les widgets Flutter sur le web.

```bash
# Installation
flutter pub add patrol --dev
dart pub global activate patrol_cli

# Lancer sur Chrome
cd origna_gta
patrol test --device chrome --target integration_test/patrol_test.dart
```

---

## 🚀 Automatisation (Pre-Push Hook)

Le hook `pre-push` exécute automatiquement **6 étapes** avant chaque push :

| Étape | Test | Status |
|-------|------|--------|
| 1/6 | Flutter Analyze | ✅ Bloquant |
| 2/6 | Flutter Tests | ✅ Bloquant |
| 3/6 | Dart Unit Tests | ✅ Bloquant |
| 4/6 | Flutter Integration | ⚠️ Skip si pas de device |
| 5/6 | Playwright E2E | ⚠️ Skip si services non actifs |
| 6/6 | Python Tests | ✅ Bloquant |

**Pour activer les tests E2E avant push :**
```bash
./scripts/start-e2e-services.sh
```

---

## 📂 Structure des Fichiers

```
origna_gta/
├── integration_test/
│   ├── app_test.dart          # Tests d'intégration Flutter
│   ├── patrol_test.dart       # Tests Patrol (widget interaction)
│   ├── checkout_flow_test.dart # Tests flow checkout existants
│   └── database_reactivity_test.dart
├── test_driver/
│   └── integration_test.dart  # Driver pour flutter drive
└── patrol.yaml                # Configuration Patrol

e2e/
├── flutter-web-e2e.spec.ts    # Tests Playwright (14 ✅)
├── full-marketplace-e2e.spec.ts # Tests marketplace (5 ✅, 12 skipped)
└── playwright.config.ts

# Scripts
scripts/e2e-with-services.sh           # Script complet E2E
scripts/start-e2e-services.sh          # Démarrer Firebase + Web Server
scripts/stop-e2e-services.sh           # Arrêter les services
```

---

## 🔧 Commandes Utiles

### Démarrer les services E2E
```bash
./scripts/start-e2e-services.sh
```

### Arrêter les services E2E
```bash
./scripts/stop-e2e-services.sh
```

### Lancer tous les E2E avec gestion des services
```bash
./scripts/e2e-with-services.sh all      # Tous les tests
./scripts/e2e-with-services.sh playwright  # Playwright uniquement
./scripts/e2e-with-services.sh flutter     # Flutter integration uniquement
./scripts/e2e-with-services.sh patrol      # Patrol uniquement
```

### Vérifier si les services sont actifs
```bash
lsof -i :5005 -i :9099 -i :8080
```

---

## 📊 Résultats Actuels

| Suite | Passés | Skipped | Échecs |
|-------|--------|---------|--------|
| Playwright E2E | 14 | 0 | 0 |
| Playwright Marketplace | 5 | 12 | 0 |
| Flutter Integration | - | - | - |
| Patrol | - | - | - |

**Note :** Les 12 tests skipped dans `full-marketplace-e2e.spec.ts` nécessitent l'interaction avec les widgets Flutter (login, registration). Utilisez Patrol ou Flutter Integration Tests pour ces cas.

---

## 🛠️ Dépannage

### Chromedriver non trouvé
```bash
brew install chromedriver
# Ou
npm install -g chromedriver
```

### Démarrer chromedriver
```bash
chromedriver --port=4444
```

### Services E2E ne démarrent pas
```bash
# Tuer tous les processus sur les ports
lsof -ti:5005,9099,8080,4000 | xargs kill -9
# Redémarrer
./scripts/start-e2e-services.sh
```
