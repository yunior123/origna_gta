# Design: Admin CLI + Firebase Test Lab + Environment Build Modes

**Date:** 2026-02-18
**Status:** Approved
**Scope:** Three independent but coordinated improvements to the OrignaGTA developer workflow

---

## 1. Admin CLI (`cli/`)

### Goal
Replace 40+ loose bash/Python scripts with a single unified Python CLI covering every admin operation across dev, staging, and prod.

### Tech
- Python + `click` (command groups) + `rich` (tables, colors, progress)
- `firebase-admin`, `stripe`, `python-dotenv` dependencies
- Reads env secrets from `.env.dev`, `.env.staging`, `.env.prod`

### Structure

```
cli/
├── cli.py                     # Entry point
├── commands/
│   ├── deploy.py              # functions / rules / indexes / hosting / all
│   ├── db.py                  # seed / reset / verify / export / import
│   ├── secrets.py             # upload secrets, rotate, sync Remote Config
│   ├── tests.py               # backend / e2e / integration / all
│   ├── users.py               # list / ban / unban / delete / impersonate
│   ├── orders.py              # list / view / cancel / refund / force-status
│   ├── payments.py            # capture / refund / dispute / trigger-payouts
│   ├── products.py            # list / approve / reject / delete / algolia-sync
│   └── webhooks.py            # list / create / verify Stripe webhooks
└── utils/
    ├── firebase_client.py     # Admin SDK init per env
    ├── stripe_client.py       # Stripe client with env-aware keys
    └── output.py              # Rich output helpers
```

### Safety Rules
- Every command requires `--env=dev|staging|prod` — no default, hard fail
- `--env=prod` prompts confirmation for any destructive action
- Dry-run flag `--dry-run` available on all mutating commands

### Key Commands

```bash
# Deploy
python cli.py deploy all --env=dev
python cli.py deploy functions --env=staging --only=on_order_status_changed
python cli.py deploy rules --env=prod

# DB
python cli.py db seed --env=dev
python cli.py db reset --env=dev
python cli.py db verify --env=staging

# Secrets
python cli.py secrets upload --env=prod
python cli.py secrets sync-remote-config --env=staging

# Tests
python cli.py tests backend --env=dev
python cli.py tests e2e --env=staging
python cli.py tests all --env=dev

# Users
python cli.py users list --env=prod --role=seller
python cli.py users ban <uid> --env=prod --reason="TOS violation"
python cli.py users unban <uid> --env=prod
python cli.py users delete <uid> --env=prod

# Orders
python cli.py orders list --env=prod --status=disputed
python cli.py orders view <order_id> --env=prod
python cli.py orders refund <order_id> --env=prod --amount=5000
python cli.py orders force-status <order_id> --env=prod --status=delivered

# Payments
python cli.py payments capture <order_id> --env=prod
python cli.py payments trigger-payouts --env=prod
python cli.py payments dispute list --env=prod
python cli.py payments dispute resolve <dispute_id> --env=prod --action=accept

# Products
python cli.py products list --env=prod --pending-approval
python cli.py products approve <product_id> --env=prod
python cli.py products reject <product_id> --env=prod --reason="Prohibited item"
python cli.py products algolia-sync --env=dev

# Webhooks
python cli.py webhooks list --env=dev
python cli.py webhooks sync --env=staging
python cli.py webhooks verify --env=prod
```

---

## 2. Firebase Test Lab + GitHub Actions

### Goal
Run automated mobile tests on real virtual devices using Firebase Test Lab free tier (Spark plan: 5 virtual tests/day), triggered by GitHub Actions on PRs to `main`.

### Workflow Files

| File | Trigger | Purpose |
|------|---------|---------|
| `.github/workflows/ci-backend.yml` | Every push/PR | pytest backend tests |
| `.github/workflows/ci-flutter-web.yml` | Every push/PR | Flutter web build + Playwright E2E vs dev |
| `.github/workflows/ci-mobile.yml` | PR to `main` only | APK/IPA build + Firebase Test Lab |

### Test Lab Device Matrix (Free Tier)

| Platform | Device | OS | Test Type | Daily quota used |
|----------|--------|----|-----------|-----------------|
| Android | Pixel 6 (virtual) | API 33 | Flutter integration tests | 1 |
| iOS | iPhone 14 (virtual) | iOS 16 | Robo crawl | 1 |

Free tier allows 5 virtual tests/day — 2 used per CI run, leaving 3 for manual reruns.

### GitHub Actions Secrets Required

```
FIREBASE_SERVICE_ACCOUNT_DEV     # JSON service account for orignagta-dev
GCLOUD_PROJECT_DEV               # "orignagta-dev"
STRIPE_TEST_KEY                  # sk_test_... (for E2E)
ALGOLIA_ADMIN_KEY                # Algolia admin key (for E2E)
```

### Flow: `ci-mobile.yml`

1. Checkout + Flutter setup
2. Build Android: `flutter build apk --debug --dart-define=ENVIRONMENT=dev`
3. Build iOS: `flutter build ios --no-codesign --debug --dart-define=ENVIRONMENT=dev`
4. Authenticate gcloud with service account
5. Android: `gcloud firebase test android run --type instrumentation --app app-debug.apk --test app-debug-androidTest.apk --device model=Pixel6,version=33`
6. iOS: `gcloud firebase test ios run --test Runner.zip --device model=iphone14,version=16.6`
7. Post results to GitHub Actions summary

---

## 3. Environment + Build Mode

### Goal
Flutter compiled as debug (dev), profile (staging), release (prod). Playwright works on dev and staging. Profile build keeps semantics alive for E2E testing.

### Build Mode Map

| Env | Flutter mode | `ENVIRONMENT=` | `FORCE_SEMANTICS=` | Playwright | Sentry |
|-----|-------------|-----------------|---------------------|------------|--------|
| emulator | debug | emulator | — | ✅ | no |
| dev | debug | dev | — | ✅ | no |
| staging | profile | staging | true | ✅ | yes (staging) |
| prod | release | production | — | ❌ | yes (prod) |

### `main.dart` Semantics Change

```dart
// Before: always on for web
if (kIsWeb) {
  _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
}

// After: debug always on, profile only if forced, release never
if (kIsWeb && (kDebugMode || const bool.fromEnvironment('FORCE_SEMANTICS'))) {
  _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
}
```

### Build Scripts

```
scripts/build/
├── build_dev.sh       # --debug  --dart-define=ENVIRONMENT=dev
├── build_staging.sh   # --profile --dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true
└── build_prod.sh      # --release --dart-define=ENVIRONMENT=production
```

Each accepts a target argument: `web | apk | ios | appbundle`

```bash
./scripts/build/build_dev.sh web
./scripts/build/build_staging.sh apk
./scripts/build/build_prod.sh appbundle
```

### Playwright Config Per Env

```
e2e/
├── playwright.config.ts           # base (shared)
├── playwright.config.dev.ts       # baseURL: http://localhost:5005
└── playwright.config.staging.ts   # baseURL: https://orignagta-staging.web.app
```

CI uses:
- `ci-flutter-web.yml` → `--config=playwright.config.dev.ts`
- Manual staging run → `--config=playwright.config.staging.ts`

### Firebase Deploy — Always Explicit Project

Every `firebase deploy` in CLI and CI always passes `--project`:
- `--project orignagta-dev` for dev
- `--project orignagta-staging` for staging
- `--project orignagta` for prod

No implicit default project. The CLI enforces this — `--env` flag maps directly to project ID.

---

## Implementation Order

1. **Environment build scripts** (`scripts/build/`) + `main.dart` semantics fix — foundation everything else depends on
2. **Playwright configs** (`playwright.config.dev.ts`, `playwright.config.staging.ts`)
3. **Admin CLI** (`cli/`) — Python Click app with all command groups
4. **GitHub Actions** — `ci-backend.yml` first (easiest), then `ci-flutter-web.yml`, then `ci-mobile.yml`

---

## Files Changed / Created

### New files
- `cli/cli.py` + `cli/commands/*.py` + `cli/utils/*.py` + `cli/requirements.txt`
- `scripts/build/build_dev.sh`, `build_staging.sh`, `build_prod.sh`
- `e2e/playwright.config.dev.ts`, `playwright.config.staging.ts`
- `.github/workflows/ci-backend.yml`
- `.github/workflows/ci-flutter-web.yml`
- `.github/workflows/ci-mobile.yml`

### Modified files
- `origna_gta/lib/main.dart` — semantics guard
- `e2e/playwright.config.ts` — extract shared base config
- `scripts/deploy_with_validation.sh` — delegate to CLI

### Not changed
- `origna_gta/lib/utils/env_config.dart` — already handles all env logic
- `.firebaserc` — already has all three projects
- `firebase.json` — no changes needed
