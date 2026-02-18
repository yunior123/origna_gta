# Tests E2E Complets - Marketplace OrignaGTA

Ce dossier contient la suite complète de tests End-to-End (E2E) qui valident le flux entier du marketplace, de l'inscription du vendeur au paiement final.

## 🎯 Ce qui a été Créé

### 1. **Test E2E Complet** (`e2e/full-marketplace-e2e.spec.ts`)

Un test complet qui couvre :

#### Flow Principal (12 étapes)
1. ✅ **Seller Registration - Login as Seller**
   - Connexion avec les identifiants vendeur
   - Vérification de l'accès

2. ✅ **Seller Registration - Navigate to Become a Seller**
   - Navigation vers la page d'inscription vendeur

3. ✅ **Seller Registration - Start Stripe Onboarding**
   - Sélection du fournisseur de paiement (Stripe)
   - Acceptation des conditions
   - Préparation de l'onboarding

4. ✅ **Admin - Approve Seller (Grant Seller Role)**
   - Connexion admin
   - Attribution du rôle "seller"

5. ✅ **Seller - Add Product**
   - Ajout d'un nouveau produit avec tous les détails

6. ✅ **Buyer - Login**
   - Connexion acheteur

7. ✅ **Buyer - Search and Add Product to Cart**
   - Recherche de produit
   - Ajout au panier

8. ✅ **Buyer - Checkout Flow**
   - Process de checkout
   - Saisie de l'adresse
   - Préparation du paiement

9. ✅ **Verify Order Creation**
   - Vérification de la création de commande

10. ✅ **Seller - View and Ship Order**
    - Marquage de la commande comme expédiée

11. ✅ **Buyer - Confirm Delivery**
    - Confirmation de la réception

12. ✅ **Seller - Verify Payment Received**
    - Vérification du paiement reçu

#### Tests Smoke (4 tests)
- Home page loads
- Login page accessible
- Seller registration page accessible
- Cart page accessible

#### Tests Backend (1 test)
- Health check des Firebase Functions

### 2. **Scripts de Démarrage Automatique**

#### `start-e2e-services.sh` ⭐
Script intelligent qui :
- ✅ Nettoie les processus existants
- ✅ Construit Flutter Web (si nécessaire)
- ✅ Démarre Firebase Emulators (Auth, Firestore, Functions, Storage)
- ✅ Démarre le serveur web (port 5005)
- ✅ Vérifie que tous les services sont prêts
- ✅ Affiche un résumé avec URLs et PIDs
- ✅ Sauvegarde les logs dans `/tmp/origna_e2e_logs/`

#### `stop-e2e-services.sh`
Script pour arrêter proprement tous les services.

### 3. **Documentation Complète**

#### `E2E_TEST_EXECUTION_GUIDE.md`
Guide détaillé avec :
- Prérequis et configuration
- Instructions pas à pas
- Résolution de problèmes
- Commandes utiles Playwright
- Structure des tests
- Workflow manuel pour validation

## 🚀 Démarrage Rapide

### Option 1 : Utiliser le Script Automatique (Recommandé)

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta

# Démarrer tous les services
./scripts/start-e2e-services.sh

# Dans un autre terminal, exécuter les tests
cd e2e
npx playwright test full-marketplace-e2e.spec.ts

# Arrêter les services
./scripts/stop-e2e-services.sh
```

### Option 2 : Démarrage Manuel

**Terminal 1 - Firebase Emulators:**
```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
firebase emulators:start --only=auth,firestore,functions,storage
```

**Terminal 2 - Web Server:**
```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
npx serve -s origna_gta/build/web -l 5005
```

**Terminal 3 - Tests:**
```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e
npx playwright test full-marketplace-e2e.spec.ts
```

## 📝 Identifiants de Test

Les tests utilisent ces comptes (configurés dans le fichier de test) :

**Vendeur:**
- Email: `yr62813@gmail.com`
- Password: `960227Y#y`

**Acheteur:**
- Email: `yuniorrodriguezo460@gmail.com`
- Password: `960227Y#y`

**Admin:**
- Email: `yuniorrodriguezo460@gmail.com`
- Password: `960227yro#Y7`

> ⚠️ **Important:** Assurez-vous que ces utilisateurs existent dans Firebase Auth avant d'exécuter les tests.

## 🔧 Configuration Playwright

Les tests sont configurés avec :
- Timeout par défaut : **60 secondes** par test
- Suite principale : **180 secondes** (3 minutes) par test
- Tests exécutés **séquentiellement** (`.serial`) pour respecter les dépendances
- Screenshots automatiques en cas d'échec
- Logs du navigateur capturés

## 📊 Commandes de Test Avancées

```bash
# Exécuter avec UI interactive
npx playwright test full-marketplace-e2e.spec.ts --ui

# Mode debug (pause à chaque étape)
npx playwright test full-marketplace-e2e.spec.ts --debug

# Exécuter un seul test
npx playwright test -g "Seller Registration"

# Voir le navigateur pendant l'exécution
npx playwright test --headed

# Générer un rapport HTML
npx playwright test
npx playwright show-report

# Tracer l'exécution
npx playwright test --trace=on
npx playwright show-trace trace.zip
```

## 🐛 Résolution de Problèmes

### L'app reste bloquée sur "Running in emulator mode"

**Solutions appliquées:**
1. ✅ Timeout de splash réduit à 8s (`web/index.html`)
2. ✅ AuthWrapper avec timeout de 5s
3. ✅ MainScreen avec timeout de 3s

Si le problème persiste :
```bash
cd origna_gta
flutter clean
flutter build web --release
```

### Ports déjà utilisés

```bash
# Libérer tous les ports
lsof -ti :5005,8080,9099,5001,9199 | xargs kill -9

# Ou utiliser le script
./scripts/stop-e2e-services.sh
```

### Firebase Emulators ne démarrent pas

```bash
# Vérifier les logs
tail -f /tmp/origna_e2e_logs/firebase.log

# Redémarrer proprement
./scripts/stop-e2e-services.sh
./scripts/start-e2e-services.sh
```

## 📁 Structure des Fichiers

```
origna_gta/
├── e2e/
│   ├── full-marketplace-e2e.spec.ts  # ⭐ Test E2E complet
│   ├── tests.spec.ts                  # Tests existants
│   ├── playwright.config.ts           # Configuration Playwright
│   └── test-results/                  # Screenshots et rapports
├── start-e2e-services.sh              # ⭐ Script de démarrage
├── stop-e2e-services.sh               # ⭐ Script d'arrêt
└── E2E_TEST_EXECUTION_GUIDE.md        # ⭐ Guide détaillé
```

## 🎓 Fonctions Helper Réutilisables

Le fichier de test contient des helpers pratiques :

```typescript
// Attendre que Flutter s'initialise
await waitForFlutterInit(page);

// Login utilisateur
await login(page, email, password);

// Inscription
await registerUser(page, name, email, password);

// Navigation vers inscription vendeur
await navigateToSellerRegistration(page);

// Déconnexion
await logout(page);
```

Ces fonctions peuvent être extraites dans un fichier séparé pour réutilisation.

## 📈 Prochaines Améliorations

- [ ] Mock Stripe pour éviter les redirections externes
- [ ] Tests de webhooks Stripe
- [ ] Tests de concurrence (plusieurs acheteurs)
- [ ] Tests de performance
- [ ] Tests d'accessibilité (WCAG)
- [ ] Fixtures de données automatisées
- [ ] CI/CD integration (GitHub Actions)
- [ ] Tests cross-browser (Safari, Firefox)

## 🔍 Logs et Debugging

Tous les logs sont sauvegardés dans `/tmp/origna_e2e_logs/` :
- `firebase.log` - Logs des émulateurs Firebase
- `web_server.log` - Logs du serveur web
- `flutter_build.log` - Logs de construction Flutter

Pour activer plus de logs dans les tests :
```typescript
page.on('console', msg => console.log(`BROWSER: ${msg.text()}`));
page.on('pageerror', err => console.log(`ERROR: ${err}`));
```

## ✅ Validation

Pour valider que tout fonctionne :

1. **Démarrer les services:**
   ```bash
   ./scripts/start-e2e-services.sh
   ```

2. **Vérifier les URLs:**
   - App: http://localhost:5005
   - Firebase UI: http://localhost:4000
   - Auth: http://localhost:9099
   - Firestore: http://localhost:8080

3. **Exécuter les tests:**
   ```bash
   cd e2e
   npx playwright test full-marketplace-e2e.spec.ts --reporter=list
   ```

4. **Vérifier les résultats:**
   - Tous les tests smoke devraient passer
   - Les tests du flow principal devraient atteindre les points de redirection Stripe
   - Aucune erreur 404 ou timeout de 60s+

## 📞 Support

En cas de problème :
1. Consultez `E2E_TEST_EXECUTION_GUIDE.md` pour des solutions détaillées
2. Vérifiez les logs dans `/tmp/origna_e2e_logs/`
3. Utilisez `--debug` mode pour voir l'exécution pas à pas
4. Capturez les screenshots des échecs dans `test-results/`

---

**Créé le:** 3 février 2026  
**Version:** 1.0  
**Statut:** ✅ Prêt pour utilisation
