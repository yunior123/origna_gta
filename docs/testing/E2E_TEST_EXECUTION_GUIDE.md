# Guide pour Exécuter le Test E2E Complet du Marketplace

Ce guide décrit comment exécuter le test E2E complet qui couvre tout le flux du marketplace : inscription vendeur → approbation admin → ajout de produit → achat → livraison → paiement.

## Prérequis

### 1. Environnement de Test
Les tests utilisent les comptes suivants (assurez-vous qu'ils existent dans Firebase Auth) :

**Vendeur (Seller):**
- Email: `yr62813@gmail.com`
- Password: `960227Y#y`

**Acheteur (Buyer):**
- Email: `yuniorrodriguezo460@gmail.com`  
- Password: `960227Y#y`

**Admin:**
- Email: `yuniorrodriguezo460@gmail.com`
- Password: `960227yro#Y7`

### 2. Configurer l'Environnement

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
```

## Démarrage des Services

### Étape 1 : Construire Flutter Web

```bash
cd origna_gta
flutter build web --release
```

### Étape 2 : Démarrer Firebase Emulators

Dans un terminal séparé :

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
firebase emulators:start --only=auth,firestore,functions,storage
```

Attendez de voir :
```
✔  All emulators started, it is now safe to connect.
```

Les émulateurs démarrent sur :
- Auth: `http://localhost:9099`
- Firestore: `http://localhost:8080`
- Functions: `http://localhost:5001`
- Storage: `http://localhost:9199`

### Étape 3 : Démarrer le Serveur Web

Dans un autre terminal séparé :

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta
npx serve -s origna_gta/build/web -l 5005
```

Attendez de voir :
```
Serving!
- Local:    http://localhost:5005
```

### Étape 4 : Exécuter les Tests

Dans un troisième terminal :

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/e2e

# Exécuter tous les tests E2E du marketplace
npx playwright test full-marketplace-e2e.spec.ts

# Ou exécuter avec interface UI
npx playwright test full-marketplace-e2e.spec.ts --ui

# Ou exécuter en mode debug
npx playwright test full-marketplace-e2e.spec.ts --debug
```

## Structure du Test

Le fichier `full-marketplace-e2e.spec.ts` contient :

### 1. Suite Principale : "Full Marketplace E2E Flow"
Tests exécutés séquentiellement (`.serial`) :

1. **Seller Registration - Login as Seller**
   - Se connecte avec le compte vendeur
   - Vérifie l'accès

2. **Seller Registration - Navigate to Become a Seller**
   - Navigue vers la page d'inscription vendeur
   - Vérifie le contenu de la page

3. **Seller Registration - Start Stripe Onboarding**
   - Sélectionne Stripe comme fournisseur de paiement
   - Accepte les conditions
   - Prépare l'onboarding (sans cliquer - redirection Stripe)

4. **Admin - Approve Seller (Grant Seller Role)**
   - Se connecte comme admin
   - Accède au panneau admin
   - Recherche le vendeur
   - Accorde le rôle "seller"

5. **Seller - Add Product**
   - Se connecte comme vendeur
   - Accède à la page d'ajout de produit
   - Remplit le formulaire produit
   - Soumet (peut nécessiter un setup Stripe complet)

6. **Buyer - Login**
   - Se connecte avec le compte acheteur
   - Vérifie l'accès

7. **Buyer - Search and Add Product to Cart**
   - Recherche le produit de test
   - Clique sur le produit
   - Ajoute au panier

8. **Buyer - Checkout Flow**
   - Accède au panier
   - Lance le checkout
   - Remplit l'adresse de livraison
   - Prépare le paiement (sans cliquer - redirection Stripe)

9. **Verify Order Creation**
   - Vérifie la création de la commande
   - Accède à la page des commandes

10. **Seller - View and Ship Order**
    - Se connecte comme vendeur
    - Accède aux commandes vendeur
    - Marque la commande comme expédiée

11. **Buyer - Confirm Delivery**
    - Se connecte comme acheteur
    - Accède aux commandes
    - Confirme la réception

12. **Seller - Verify Payment Received**
    - Se connecte comme vendeur
    - Accède à la page des revenus/paiements
    - Vérifie les informations de paiement

### 2. Suite "Marketplace Smoke Tests"
Tests rapides de base :

- Home page loads
- Login page accessible
- Seller registration page accessible
- Cart page accessible when logged in

### 3. Suite "Backend Integration"
Tests de santé des services backend.

## Résolution de Problèmes

### L'application reste bloquée sur "Running in emulator mode"

**Cause:** L'AuthWrapper ou MainScreen prend trop de temps à charger.

**Solution:** Les timeouts ont été ajoutés dans :
- `web/index.html` : Splash timeout de 8s
- `screens/authwrapper_screen.dart` : Timeout de 5s
- `screens/main_screen.dart` : Timeout de 3s

Si le problème persiste, reconstruire :

```bash
cd origna_gta
flutter clean
flutter build web --release
```

### Ports déjà utilisés

```bash
# Libérer tous les ports
lsof -ti :5005,8080,9099,5001,9199 | xargs kill -9

# Ou redémarrer les services sur d'autres ports
```

### Les tests échouent avec "Timeout"

1. Vérifiez que tous les services sont en cours d'exécution
2. Augmentez les timeouts dans Playwright :

```bash
npx playwright test --timeout=120000  # 2 minutes par test
```

3. Utilisez le mode debug pour voir ce qui se passe :

```bash
npx playwright test --debug
```

### Firebase Emulators ne démarrent pas

```bash
# Nettoyer les processus
pkill -f firebase
sleep 2

# Redémarrer
firebase emulators:start --only=auth,firestore,functions,storage
```

### Les utilisateurs de test n'existent pas

Créez les utilisateurs dans Firebase Auth Emulator ou utilisez les identifiants d'utilisateurs existants.

## Modifier les Identifiants de Test

Éditez le fichier `e2e/full-marketplace-e2e.spec.ts` :

```typescript
// Lignes 17-29
const SELLER_EMAIL = 'votre-vendeur@example.com';
const SELLER_PASSWORD = 'votre-mot-de-passe';

const BUYER_EMAIL = 'votre-acheteur@example.com';
const BUYER_PASSWORD = 'votre-mot-de-passe';

const ADMIN_EMAIL = 'votre-admin@example.com';
const ADMIN_PASSWORD = 'votre-mot-de-passe';
```

## Résultats Attendus

### Tests qui Devraient Passer Complètement
- Login / Registration
- Navigation entre les pages
- Affichage du contenu
- Ajout au panier (si produit existe)

### Tests qui Peuvent Être Partiels
- **Stripe Onboarding** : Requiert une redirection externe
- **Paiement** : Requiert Stripe Checkout externe
- **Ajout de Produit** : Peut nécessiter un compte Stripe vendeur complet

### Workflow Complet en Mode Manuel

Pour tester le flux complet manuellement :

1. **Setup Vendeur:**
   - Connectez-vous avec yr62813@gmail.com
   - Allez dans Profile → Become a Seller
   - Complétez l'onboarding Stripe (lien externe)
   - Revenez à l'app

2. **Approbation Admin:**
   - Connectez-vous avec yuniorrodriguezo460@gmail.com (admin)
   - Admin Panel → Users → Trouvez yr62813@gmail.com
   - Cliquez "Make Seller"

3. **Ajout de Produit:**
   - Reconnectez-vous comme yr62813@gmail.com
   - Profile → My Products → Add Product
   - Remplissez les détails

4. **Achat:**
   - Connectez-vous comme yuniorrodriguezo460@gmail.com (buyer)
   - Recherchez le produit
   - Ajoutez au panier → Checkout
   - Complétez le paiement Stripe

5. **Livraison:**
   - Vendeur marque comme expédié
   - Acheteur confirme la réception

6. **Paiement:**
   - Vérifiez dans Stripe Dashboard que le paiement est capturé
   - Le vendeur reçoit son paiement (moins les frais plateforme)

## Logs et Debugging

### Activer les logs détaillés dans les tests

Dans `full-marketplace-e2e.spec.ts`, décommentez :

```typescript
page.on('console', msg => console.log(`BROWSER LOG: ${msg.text()}`));
page.on('pageerror', exception => console.log(`BROWSER ERROR: ${exception}`));
page.on('requestfailed', request => {
    console.log(`REQ FAILED: ${request.url()} - ${request.failure()?.errorText}`);
});
```

### Voir les screenshots des échecs

Les screenshots sont automatiquement sauvegardés dans :
```
e2e/test-results/*/test-failed-*.png
```

### Rapport HTML

```bash
npx playwright show-report
```

## Commandes Utiles

```bash
# Exécuter un seul test
npx playwright test -g "Seller Registration"

# Exécuter en mode headed (voir le navigateur)
npx playwright test --headed

# Exécuter sur un navigateur spécifique
npx playwright test --project=chromium
npx playwright test --project=firefox

# Générer un rapport trace
npx playwright test --trace=on
npx playwright show-trace trace.zip
```

## Structure des Helpers

Le fichier contient plusieurs fonctions helper :

- `waitForFlutterInit(page)` : Attend que Flutter soit initialisé
- `login(page, email, password)` : Connexion utilisateur
- `registerUser(page, name, email, password)` : Inscription utilisateur
- `navigateToSellerRegistration(page)` : Navigation vers inscription vendeur
- `logout(page)` : Déconnexion

Ces fonctions peuvent être réutilisées dans d'autres tests.

## Prochaines Étapes

1. **Compléter les fixtures de données** : Ajouter des produits de test dans Firestore
2. **Mocker Stripe** : Utiliser Stripe test mode pour les paiements
3. **Tests de Webhooks** : Vérifier le handling des webhooks Stripe
4. **Tests de Concurrence** : Plusieurs acheteurs simultanés
5. **Tests de Performance** : Mesurer les temps de chargement
6. **Tests d'Accessibilité** : Vérifier la conformité WCAG

## Support

En cas de problème :
1. Vérifiez que tous les services sont démarrés
2. Consultez les logs : `/tmp/firebase.log` et `/tmp/web.log`
3. Vérifiez les configurations dans `firebase.json` et `playwright.config.ts`
4. Assurez-vous que les utilisateurs de test existent dans Firebase Auth
