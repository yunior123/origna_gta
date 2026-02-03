# 📚 Index de Documentation - Tests E2E OrignaGTA

## 🚀 Démarrage Rapide

**Commande la plus simple:**
```bash
./quick-test.sh
```

Cette commande unique :
1. Démarre tous les services
2. Exécute les tests
3. Arrête les services
4. Affiche les résultats

---

## 📖 Documentation Disponible

### 1. Vue d'Ensemble Générale
📄 **[E2E_TESTS_README.md](E2E_TESTS_README.md)**  
- Introduction complète
- Démarrage rapide
- Configuration
- Commandes utiles
- **👉 COMMENCEZ ICI si c'est votre première fois**

### 2. Guide d'Exécution Détaillé
📄 **[E2E_TEST_EXECUTION_GUIDE.md](E2E_TEST_EXECUTION_GUIDE.md)**  
- Instructions pas à pas
- Résolution de problèmes
- Configuration avancée
- Workflow manuel
- **👉 UTILISEZ CECI pour setup détaillé**

### 3. Résumé de Session
📄 **[E2E_SESSION_SUMMARY.md](E2E_SESSION_SUMMARY.md)**  
- Récapitulatif de ce qui a été créé
- Problèmes résolus
- Fichiers modifiés
- Prochaines étapes
- **👉 LISEZ CECI pour comprendre le contexte**

---

## 🛠️ Scripts Disponibles

### Script de Démarrage Complet
```bash
./start-e2e-services.sh
```
**Fait:**
- Nettoie les processus existants
- Construit Flutter Web
- Démarre Firebase Emulators
- Démarre le serveur web
- Vérifie que tout fonctionne
- Affiche les URLs et PIDs

**Options:**
```bash
./start-e2e-services.sh --rebuild  # Force la reconstruction Flutter
```

### Script d'Arrêt
```bash
./stop-e2e-services.sh
```
**Fait:**
- Arrête tous les services
- Libère les ports
- Nettoie les PIDs

### Script de Test Rapide
```bash
./quick-test.sh
```
**Fait:**
- Démarrage automatique
- Exécution des tests
- Arrêt automatique
- Rapport de résultats

---

## 🧪 Fichiers de Test

### Test E2E Complet
📄 **`e2e/full-marketplace-e2e.spec.ts`**
- 12 étapes de flow complet
- 4 tests smoke
- 1 test backend
- Helpers réutilisables

**Exécution:**
```bash
# Tous les tests
npx playwright test full-marketplace-e2e.spec.ts

# Avec interface UI
npx playwright test full-marketplace-e2e.spec.ts --ui

# Mode debug
npx playwright test full-marketplace-e2e.spec.ts --debug

# Un seul test
npx playwright test -g "Seller Registration"
```

### Tests Existants
📄 **`e2e/tests.spec.ts`**
- Tests admin existants
- Tests de workflow basiques

---

## 📊 Services et Ports

Lorsque les services sont démarrés :

| Service          | URL                         | Port  |
|------------------|-----------------------------|-------|
| Application Web  | http://localhost:5005       | 5005  |
| Firebase UI      | http://localhost:4000       | 4000  |
| Auth Emulator    | http://localhost:9099       | 9099  |
| Firestore        | http://localhost:8080       | 8080  |
| Functions        | http://localhost:5001       | 5001  |
| Storage          | http://localhost:9199       | 9199  |

---

## 🔑 Identifiants de Test

| Rôle     | Email                           | Mot de passe  |
|----------|--------------------------------|---------------|
| Vendeur  | yr62813@gmail.com              | 960227Y#y     |
| Acheteur | yuniorrodriguezo460@gmail.com | 960227Y#y     |
| Admin    | yuniorrodriguezo460@gmail.com | 960227yro#Y7  |

> Pour modifier, éditez `e2e/full-marketplace-e2e.spec.ts` lignes 17-29

---

## 📁 Logs et Résultats

### Logs des Services
```bash
# Logs en temps réel
tail -f /tmp/origna_e2e_logs/firebase.log
tail -f /tmp/origna_e2e_logs/web_server.log

# Logs de build
cat /tmp/origna_e2e_logs/flutter_build.log
```

### Résultats des Tests
```
e2e/test-results/           # Screenshots et traces
e2e/playwright-report/      # Rapport HTML
```

**Voir le rapport:**
```bash
cd e2e
npx playwright show-report
```

---

## 🎯 Workflows Courants

### Développement Actif
```bash
# Terminal 1
./start-e2e-services.sh

# Terminal 2 - Exécuter les tests en boucle
cd e2e
npx playwright test --watch
```

### Test Rapide
```bash
./quick-test.sh
```

### Debug d'un Test
```bash
# Démarrer les services
./start-e2e-services.sh

# Dans un autre terminal
cd e2e
npx playwright test full-marketplace-e2e.spec.ts --debug -g "Nom du test"
```

### Test avec UI
```bash
# Démarrer les services
./start-e2e-services.sh

# Dans un autre terminal
cd e2e
npx playwright test full-marketplace-e2e.spec.ts --ui
```

---

## ⚠️ Résolution de Problèmes Rapide

### Services ne démarrent pas
```bash
./stop-e2e-services.sh
lsof -ti :5005,8080,9099,5001,9199 | xargs kill -9
./start-e2e-services.sh
```

### Tests timeout
```bash
# Augmenter le timeout
npx playwright test --timeout=120000
```

### App bloquée sur splash
```bash
cd origna_gta
flutter clean
flutter build web --release
```

### Pour plus de détails
Consultez [E2E_TEST_EXECUTION_GUIDE.md](E2E_TEST_EXECUTION_GUIDE.md) section "Résolution de Problèmes"

---

## 🔄 Ordre de Lecture Recommandé

### Pour Débutant
1. **[E2E_TESTS_README.md](E2E_TESTS_README.md)** - Vue d'ensemble
2. Exécuter `./quick-test.sh` - Test rapide
3. **[E2E_TEST_EXECUTION_GUIDE.md](E2E_TEST_EXECUTION_GUIDE.md)** - Setup détaillé

### Pour Développeur Expérimenté
1. **[E2E_SESSION_SUMMARY.md](E2E_SESSION_SUMMARY.md)** - Contexte
2. `e2e/full-marketplace-e2e.spec.ts` - Code source
3. Exécuter `./start-e2e-services.sh` puis les tests

### Pour Debugging
1. **[E2E_TEST_EXECUTION_GUIDE.md](E2E_TEST_EXECUTION_GUIDE.md)** - Résolution de problèmes
2. Logs dans `/tmp/origna_e2e_logs/`
3. Mode debug : `npx playwright test --debug`

---

## 📞 Aide Rapide

**Problème ?** Essayez dans cet ordre :
1. Vérifier que les services sont démarrés : `lsof -i :5005,9099,8080`
2. Redémarrer les services : `./stop-e2e-services.sh && ./start-e2e-services.sh`
3. Consulter les logs : `tail -f /tmp/origna_e2e_logs/*.log`
4. Lire la documentation : [E2E_TEST_EXECUTION_GUIDE.md](E2E_TEST_EXECUTION_GUIDE.md)

**Besoin d'aide ?**
- Tous les détails sont dans les fichiers markdown
- Les logs sont dans `/tmp/origna_e2e_logs/`
- Les screenshots d'échec dans `e2e/test-results/`

---

## ✅ Checklist de Validation

Avant de commencer, vérifiez :
- [ ] Node.js installé
- [ ] Flutter installé et configuré
- [ ] Firebase CLI installé
- [ ] Playwright installé (`cd e2e && npm install`)
- [ ] Scripts rendus exécutables (`chmod +x *.sh`)
- [ ] Utilisateurs de test créés dans Firebase Auth

Pour valider l'installation :
```bash
./quick-test.sh
```

Si tous les tests smoke passent, vous êtes prêt ! 🎉

---

**Dernière mise à jour:** 3 février 2026  
**Version:** 1.0  
**Statut:** ✅ Production Ready
