# Environment Configuration Guide

## Overview

OrignaGTA supports two environments:

| Environment | Description | Database | R2 Storage | Stripe |
|-------------|-------------|----------|------------|--------|
| **Emulator** (Micro-Staging) | Local development | Firebase Emulator | `emulator/` folder | Test keys (`sk_test_*`) |
| **Production** | Live deployment | Firebase Cloud | Root folders | Live keys (`sk_live_*`) |

## Quick Start

### Option 1: VS Code (Recommended)

1. Open VS Code in the project root
2. Go to **Run and Debug** (Ctrl+Shift+D / Cmd+Shift+D)
3. Select a configuration:
   - **🔧 Flutter Emulator (Debug)** - Development with hot reload
   - **🔧 Flutter Emulator (Release)** - Performance testing
   - **🌐 Flutter Production (Debug)** - Test against live Firebase

4. Press **F5** to start

> **Note:** Emulator configurations automatically start Firebase emulators before launching Flutter.

### Option 2: Command Line

```bash
# Start emulators
./scripts/start-emulators.sh

# In another terminal, run Flutter
./scripts/run-flutter-emulator.sh chrome debug
./scripts/run-flutter-emulator.sh chrome release
```

## Architecture

### Environment Detection

#### Python (Firebase Functions)

```python
# functions/config.py
from config import IS_EMULATOR, CURRENT_ENV, Environment

if IS_EMULATOR:
    # Running locally with emulators
    # Secrets loaded from .env file
    pass
else:
    # Production deployment
    # Secrets loaded from Google Secret Manager
    pass
```

#### Flutter

```dart
// lib/utils/env_config.dart
import 'package:origna_gta/utils/env_config.dart';

if (envConfig.isEmulator) {
  // Uses Firebase emulators
  // R2 uploads go to emulator/ folder
}
```

## R2 Storage Paths

Images are stored in different folders based on environment:

| Type | Emulator | Production |
|------|----------|------------|
| Product Images | `emulator/products/{id}.jpg` | `products/{id}.jpg` |
| User Avatars | `emulator/users/{id}.jpg` | `users/{id}.jpg` |

This prevents test data from polluting production storage.

## Algolia Indexes

| Environment | Index Name |
|-------------|------------|
| Emulator | `products_emulator` |
| Production | `products` |

## Stripe Webhook Forwarding

En mode émulateur, les webhooks Stripe doivent être redirigés vers localhost pour tester les paiements.

### Option 1: VS Code Task (Recommandé)

1. Ouvrez la palette de commandes (`Cmd+Shift+P`)
2. Sélectionnez **Tasks: Run Task**
3. Choisissez **Stripe: Forward Webhooks to Emulator**

### Option 2: Configuration "Full Stack + Stripe"

1. Allez dans **Run and Debug** (`Cmd+Shift+D`)
2. Sélectionnez **🚀 Full Stack + Stripe Webhooks**
3. Appuyez sur **F5**

Ceci démarre :
- Firebase Emulators (Auth, Firestore, Functions, Storage)
- Stripe CLI (webhook forwarding)
- Flutter en mode émulateur

### Option 3: Ligne de commande

```bash
# Terminal 1: Démarrer tous les services
./scripts/start-all-services.sh

# Ou démarrer Stripe séparément
./scripts/start-stripe-webhooks.sh
```

### Endpoint des Webhooks

Les webhooks sont redirigés vers :
```
http://localhost:5001/orignagta/us-central1/stripe_webhook
```

### Prérequis

1. **Installer Stripe CLI** :
   ```bash
   brew install stripe/stripe-cli/stripe
   ```

2. **Se connecter à Stripe** :
   ```bash
   stripe login
   ```

3. **Récupérer le webhook signing secret** :
   Le CLI affiche un `whsec_...` au démarrage. Ajoutez-le dans `functions/.env` :
   ```env
   STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET_REDACTED
   ```

### Tester les Webhooks

```bash
# Déclencher un événement de test
stripe trigger payment_intent.succeeded

# Écouter les événements en temps réel
stripe listen --forward-to localhost:5001/orignagta/us-central1/stripe_webhook
```

## Configuration Files

### VS Code

- [.vscode/launch.json](../.vscode/launch.json) - Debug configurations
- [.vscode/tasks.json](../.vscode/tasks.json) - Tasks (emulators, tests, build)

### Python Functions

- [functions/config.py](../functions/config.py) - Environment-aware configuration
- `functions/.env` - Local secrets (not committed)

### Flutter

- [lib/utils/env_config.dart](../origna_gta/lib/utils/env_config.dart) - Runtime environment config

## Secrets Management

### Local Development (Emulator)

1. Create `functions/.env` file:

```env
# Stripe (use TEST keys for emulator)
STRIPE_SECRET_KEY=STRIPE_SECRET_KEY_REDACTED
STRIPE_WEBHOOK_SECRET=STRIPE_WEBHOOK_SECRET_REDACTED

# Other required secrets
MAILJET_API_KEY=MAILJET_CREDENTIAL_REDACTED
MAILJET_SECRET_KEY=MAILJET_CREDENTIAL_REDACTED
GEOAPIFY_API_KEY=your_key
ALGOLIA_APP_ID=your_app_id
ALGOLIA_WRITE_API_KEY=your_key

# R2 Storage
R2_ACCESS_KEY=your_key
R2_SECRET_KEY=your_secret
R2_ACCOUNT_ID=your_account
```

2. **Never commit `.env` files** - They are in `.gitignore`

### Production

Secrets are stored in **Google Secret Manager** and accessed via `params.SecretParam()`.

To set secrets:
```bash
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set STRIPE_WEBHOOK_SECRET
# ... etc
```

## Deployment Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Local Dev      │     │  GitHub Push    │     │  Production     │
│  (Emulator)     │ ──▶ │  + Tests Pass   │ ──▶ │  (Firebase)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
     │                        │                        │
     ▼                        ▼                        ▼
  Emulator DB            Run pytest              Cloud Firestore
  Test Stripe            All 164 tests           Live Stripe
  R2 emulator/           Must pass               R2 production
```

### Manual Deployment

```bash
# Deploy functions only
firebase deploy --only functions

# Deploy everything
firebase deploy
```

### Automatic Deployment (CI/CD)

Push to `main` branch triggers:
1. Run all tests
2. If tests pass → Deploy to Firebase

## Testing

### Run All Tests
```bash
cd functions
source venv/bin/activate
pytest tests/ -v
```

### Run with Emulator Environment
```bash
FUNCTIONS_EMULATOR=true pytest tests/ -v
```

### VS Code
- Use **🐍 Python: Run Tests (Emulator)** configuration
- Or press **Ctrl+Shift+P** → "Tasks: Run Test Task"

## Troubleshooting

### Emulators won't start
```bash
# Check if ports are in use
lsof -i :8080  # Firestore
lsof -i :9099  # Auth
lsof -i :5001  # Functions

# Kill Firebase processes
pkill -f firebase
```

### Flutter can't connect to emulators
1. Ensure emulators are running (http://localhost:4000)
2. Check you're using emulator launch configuration
3. Verify `--dart-define=USE_EMULATORS=true` is passed

### Secrets not loading in emulator
1. Check `functions/.env` exists
2. Verify environment variables are set
3. Run `source functions/.env` before starting emulators

## VS Code Shortcuts

| Shortcut | Action |
|----------|--------|
| F5 | Start debugging |
| Ctrl+Shift+D | Open Run and Debug |
| Ctrl+Shift+P | Command Palette |
| Ctrl+` | Toggle Terminal |
