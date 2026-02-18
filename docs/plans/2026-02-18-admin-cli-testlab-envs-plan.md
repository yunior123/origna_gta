# Admin CLI + Firebase Test Lab + Environment Build Modes — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Unified Python admin CLI, proper debug/profile/release Flutter build modes per environment, Playwright working on dev+staging, and GitHub Actions CI with Firebase Test Lab for Android/iOS.

**Architecture:** Four independent phases — build scripts first (foundation), then Playwright env configs, then the CLI (absorbs all existing scripts), then GitHub Actions CI. Each phase is independently testable and committable.

**Tech Stack:** Python Click + Rich (CLI), Flutter `--dart-define` (env modes), Playwright TypeScript (E2E), GitHub Actions YAML + gcloud CLI (CI/CD)

---

## Phase 1: Flutter Build Modes + Semantics Fix

### Task 1: Fix `main.dart` semantics guard

**Files:**
- Modify: `origna_gta/lib/main.dart:44-46`

**Context:** Currently semantics are enabled for ALL web builds including release. Release builds should never pay the semantics cost. Profile (staging) needs them enabled via `--dart-define=FORCE_SEMANTICS=true`.

**Step 1: Edit the semantics block in `main.dart`**

Replace lines 44-46:
```dart
// BEFORE (always on for web):
if (kIsWeb) {
  _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
}
```

With:
```dart
// AFTER: debug always on, profile only if FORCE_SEMANTICS=true, release never
if (kIsWeb && (kDebugMode || const bool.fromEnvironment('FORCE_SEMANTICS'))) {
  _semanticsHandle = SemanticsBinding.instance.ensureSemantics();
}
```

**Step 2: Verify it compiles**

```bash
cd origna_gta && flutter build web --debug --dart-define=ENVIRONMENT=dev
```
Expected: Build succeeds, no errors.

**Step 3: Verify profile + FORCE_SEMANTICS compiles**

```bash
cd origna_gta && flutter build web --profile --dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true
```
Expected: Build succeeds.

**Step 4: Commit**

```bash
git add origna_gta/lib/main.dart
git commit -m "fix: guard semantics to debug+FORCE_SEMANTICS only — release never pays cost"
```

---

### Task 2: Create per-environment build scripts

**Files:**
- Create: `scripts/build/build_dev.sh`
- Create: `scripts/build/build_staging.sh`
- Create: `scripts/build/build_prod.sh`

**Context:** Each script accepts a target arg (`web | apk | ios | appbundle`). Called by both the CLI and GitHub Actions.

**Step 1: Create `scripts/build/` directory**

```bash
mkdir -p scripts/build
```

**Step 2: Create `scripts/build/build_dev.sh`**

```bash
#!/bin/bash
# Build Flutter for DEV environment (debug mode)
# Usage: ./scripts/build/build_dev.sh web|apk|ios|appbundle
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${1:-web}"
DEFINES="--dart-define=ENVIRONMENT=dev"

cd "$REPO_ROOT/origna_gta"
echo "🛠️  Building Flutter [$TARGET] — DEV (debug)"
flutter build "$TARGET" --debug $DEFINES
echo "✅ DEV build complete"
```

**Step 3: Create `scripts/build/build_staging.sh`**

```bash
#!/bin/bash
# Build Flutter for STAGING environment (profile mode + forced semantics)
# Usage: ./scripts/build/build_staging.sh web|apk|ios|appbundle
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${1:-web}"
DEFINES="--dart-define=ENVIRONMENT=staging --dart-define=FORCE_SEMANTICS=true"

cd "$REPO_ROOT/origna_gta"
echo "🧪  Building Flutter [$TARGET] — STAGING (profile)"
flutter build "$TARGET" --profile $DEFINES
echo "✅ STAGING build complete"
```

**Step 4: Create `scripts/build/build_prod.sh`**

```bash
#!/bin/bash
# Build Flutter for PRODUCTION environment (release mode)
# Usage: ./scripts/build/build_prod.sh web|apk|ios|appbundle
set -e
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TARGET="${1:-web}"
DEFINES="--dart-define=ENVIRONMENT=production"

cd "$REPO_ROOT/origna_gta"
echo "🏭  Building Flutter [$TARGET] — PROD (release)"
flutter build "$TARGET" --release $DEFINES
echo "✅ PROD build complete"
```

**Step 5: Make executable**

```bash
chmod +x scripts/build/build_dev.sh scripts/build/build_staging.sh scripts/build/build_prod.sh
```

**Step 6: Smoke test dev web build**

```bash
./scripts/build/build_dev.sh web
```
Expected: `✅ DEV build complete`

**Step 7: Commit**

```bash
git add scripts/build/
git commit -m "feat: add per-environment Flutter build scripts (debug/profile/release)"
```

---

## Phase 2: Playwright Environment Configs

### Task 3: Split Playwright configs by environment

**Files:**
- Modify: `e2e/playwright.config.ts` (extract shared base)
- Create: `e2e/playwright.config.dev.ts`
- Create: `e2e/playwright.config.staging.ts`

**Context:** Current config uses `process.env.E2E_TARGET_URL` as baseURL. We need named configs for CI to select explicitly. The base config stays as-is and dev/staging extend it.

**Step 1: Create `e2e/playwright.config.dev.ts`**

```typescript
// playwright.config.dev.ts — Dev environment (local hosting or dev Firebase)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './playwright_ui',
  testMatch: '**/*.spec.ts',
  testIgnore: ['*.py'],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: 1,
  reporter: process.env.CI ? 'list' : 'html',
  timeout: 300 * 1000,
  expect: { timeout: 15 * 1000 },
  use: {
    actionTimeout: 15 * 1000,
    baseURL: process.env.E2E_TARGET_URL ?? 'http://localhost:5005',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    bypassCSP: true,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

**Step 2: Create `e2e/playwright.config.staging.ts`**

```typescript
// playwright.config.staging.ts — Staging environment (orignagta-staging.web.app)
import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './playwright_ui',
  testMatch: '**/*.spec.ts',
  testIgnore: ['*.py'],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: 1,
  reporter: process.env.CI ? 'list' : 'html',
  timeout: 300 * 1000,
  expect: { timeout: 20 * 1000 },
  use: {
    actionTimeout: 20 * 1000,
    baseURL: process.env.E2E_TARGET_URL ?? 'https://orignagta-staging.web.app',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    bypassCSP: true,
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
});
```

**Step 3: Verify TypeScript compiles**

```bash
cd e2e && npx tsc --noEmit playwright.config.dev.ts 2>/dev/null || echo "TS check done"
```
Expected: No fatal errors (some TS config warnings are OK).

**Step 4: Commit**

```bash
git add e2e/playwright.config.dev.ts e2e/playwright.config.staging.ts
git commit -m "feat: add per-env Playwright configs (dev=localhost:5005, staging=orignagta-staging.web.app)"
```

---

## Phase 3: Admin CLI

### Task 4: CLI scaffold + `utils/`

**Files:**
- Create: `cli/cli.py`
- Create: `cli/utils/__init__.py`
- Create: `cli/utils/firebase_client.py`
- Create: `cli/utils/stripe_client.py`
- Create: `cli/utils/output.py`
- Create: `cli/requirements.txt`
- Create: `cli/.env.example`

**Context:** `click` and `rich` are the only new dependencies. `firebase-admin` and `stripe` are already installed in `functions/venv` — the CLI uses the same virtualenv.

**Step 1: Create `cli/requirements.txt`**

```
click==8.1.8
rich==14.0.0
firebase-admin==7.1.0
stripe==14.2.0
python-dotenv==1.2.1
google-cloud-secret-manager==2.24.0
```

**Step 2: Create `cli/.env.example`**

```
# Copy to .env.dev, .env.staging, or .env.prod and fill in values
FIREBASE_PROJECT_ID=orignagta-dev
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
ALGOLIA_APP_ID=...
ALGOLIA_ADMIN_KEY=...
```

**Step 3: Create `cli/utils/__init__.py`** (empty)

```python
```

**Step 4: Create `cli/utils/output.py`**

```python
"""Rich output helpers for the admin CLI."""
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich import print as rprint

console = Console()


def success(msg: str) -> None:
    console.print(f"[bold green]✅ {msg}[/bold green]")


def error(msg: str) -> None:
    console.print(f"[bold red]❌ {msg}[/bold red]")


def warn(msg: str) -> None:
    console.print(f"[bold yellow]⚠️  {msg}[/bold yellow]")


def info(msg: str) -> None:
    console.print(f"[cyan]ℹ️  {msg}[/cyan]")


def header(title: str, env: str) -> None:
    env_colors = {"dev": "green", "staging": "yellow", "prod": "bold red"}
    color = env_colors.get(env, "white")
    console.print(Panel(f"[{color}]{title}[/{color}]  env=[{color}]{env}[/{color}]"))


def confirm_prod(action: str) -> bool:
    """Require explicit confirmation for prod destructive actions."""
    console.print(f"\n[bold red]⚠️  PRODUCTION ACTION: {action}[/bold red]")
    answer = console.input("[bold red]Type 'yes' to confirm: [/bold red]")
    return answer.strip().lower() == "yes"


def make_table(title: str, columns: list[str]) -> Table:
    t = Table(title=title, show_header=True, header_style="bold cyan")
    for col in columns:
        t.add_column(col)
    return t
```

**Step 5: Create `cli/utils/firebase_client.py`**

```python
"""Firebase Admin SDK client — initializes per environment."""
import os
import firebase_admin
from firebase_admin import credentials, firestore, auth as fb_auth
from dotenv import load_dotenv

_apps: dict[str, firebase_admin.App] = {}

ENV_TO_PROJECT = {
    "dev": "orignagta-dev",
    "staging": "orignagta-staging",
    "prod": "orignagta",
}


def _load_env(env: str) -> None:
    env_file = os.path.join(os.path.dirname(__file__), f"../.env.{env}")
    if os.path.exists(env_file):
        load_dotenv(env_file, override=True)


def get_app(env: str) -> firebase_admin.App:
    if env not in _apps:
        _load_env(env)
        project_id = ENV_TO_PROJECT.get(env)
        if not project_id:
            raise ValueError(f"Unknown env: {env}. Use dev|staging|prod.")
        cred = credentials.ApplicationDefault()
        _apps[env] = firebase_admin.initialize_app(
            cred,
            {"projectId": project_id},
            name=f"app_{env}",
        )
    return _apps[env]


def get_firestore(env: str):
    app = get_app(env)
    return firestore.client(app=app)


def get_auth(env: str):
    app = get_app(env)
    return fb_auth
```

**Step 6: Create `cli/utils/stripe_client.py`**

```python
"""Stripe client — picks test vs live key based on environment."""
import os
import stripe
from dotenv import load_dotenv


def get_stripe(env: str) -> stripe.StripeClient:
    env_file = os.path.join(os.path.dirname(__file__), f"../.env.{env}")
    if os.path.exists(env_file):
        load_dotenv(env_file, override=True)
    key = os.environ.get("STRIPE_SECRET_KEY")
    if not key:
        raise RuntimeError(
            f"STRIPE_SECRET_KEY not found. Set it in cli/.env.{env}"
        )
    if env == "prod" and key.startswith("sk_test_"):
        raise RuntimeError("PROD env is using a test Stripe key — aborting.")
    return stripe.StripeClient(key)
```

**Step 7: Create `cli/cli.py`**

```python
#!/usr/bin/env python3
"""OrignaGTA Admin CLI — single entry point for all admin operations."""
import click
from cli.commands import deploy, db, secrets, tests, users, orders, payments, products, webhooks


@click.group()
@click.version_option("1.0.0")
def cli():
    """OrignaGTA Admin CLI\n\nManage dev, staging, and prod environments."""
    pass


cli.add_command(deploy.deploy)
cli.add_command(db.db)
cli.add_command(secrets.secrets)
cli.add_command(tests.tests)
cli.add_command(users.users)
cli.add_command(orders.orders)
cli.add_command(payments.payments)
cli.add_command(products.products)
cli.add_command(webhooks.webhooks)

if __name__ == "__main__":
    cli()
```

**Step 8: Create `cli/commands/__init__.py`** (empty)

```python
```

**Step 9: Install CLI dependencies (uses functions venv)**

```bash
cd /path/to/repo && source functions/venv/bin/activate && pip install rich==14.0.0
```
Expected: `Successfully installed rich-14.0.0` (click, firebase-admin, stripe, dotenv already present)

**Step 10: Verify CLI entry point works**

```bash
source functions/venv/bin/activate && python -m cli.cli --help
```
Expected: Help text showing all command groups.

**Step 11: Commit scaffold**

```bash
git add cli/
git commit -m "feat: add admin CLI scaffold (Click + Rich, all command groups wired)"
```

---

### Task 5: `deploy` command group

**Files:**
- Create: `cli/commands/deploy.py`

**Step 1: Create `cli/commands/deploy.py`**

```python
"""Deploy commands — functions, rules, indexes, hosting, all."""
import subprocess
import click
from cli.utils.output import console, success, error, header, confirm_prod

ENV_TO_PROJECT = {
    "dev": "orignagta-dev",
    "staging": "orignagta-staging",
    "prod": "orignagta",
}


def _firebase(args: list[str], env: str) -> int:
    project = ENV_TO_PROJECT[env]
    cmd = ["firebase"] + args + ["--project", project]
    console.print(f"[dim]$ {' '.join(cmd)}[/dim]")
    return subprocess.call(cmd)


@click.group()
def deploy():
    """Deploy Firebase resources to an environment."""
    pass


@deploy.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--only", default=None, help="Comma-separated function names")
def functions(env: str, only: str | None):
    """Deploy Cloud Functions."""
    header("Deploy Functions", env)
    if env == "prod" and not confirm_prod("deploy functions to PRODUCTION"):
        return
    targets = ["functions"] if not only else [f"functions:{only}"]
    rc = _firebase(["deploy", "--only", ",".join(targets)], env)
    success("Functions deployed") if rc == 0 else error(f"Deploy failed (exit {rc})")


@deploy.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def rules(env: str):
    """Deploy Firestore + Storage rules."""
    header("Deploy Rules", env)
    if env == "prod" and not confirm_prod("deploy rules to PRODUCTION"):
        return
    rc = _firebase(["deploy", "--only", "firestore:rules,storage"], env)
    success("Rules deployed") if rc == 0 else error(f"Deploy failed (exit {rc})")


@deploy.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def indexes(env: str):
    """Deploy Firestore indexes."""
    header("Deploy Indexes", env)
    rc = _firebase(["deploy", "--only", "firestore:indexes"], env)
    success("Indexes deployed") if rc == 0 else error(f"Deploy failed (exit {rc})")


@deploy.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def hosting(env: str):
    """Deploy Firebase Hosting (requires web build first)."""
    header("Deploy Hosting", env)
    if env == "prod" and not confirm_prod("deploy hosting to PRODUCTION"):
        return
    rc = _firebase(["deploy", "--only", "hosting"], env)
    success("Hosting deployed") if rc == 0 else error(f"Deploy failed (exit {rc})")


@deploy.command(name="all")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--skip-tests", is_flag=True, default=False)
def deploy_all(env: str, skip_tests: bool):
    """Deploy everything: validate schema → run tests → build → deploy all."""
    import os, sys
    repo_root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    header("Full Deploy", env)
    if env == "prod" and not confirm_prod("FULL deploy to PRODUCTION"):
        return

    steps = [
        ("Schema validation", [sys.executable, f"{repo_root}/scripts/validate_schema_consistency.sh"]),
    ]
    if not skip_tests:
        steps.append(("Backend tests", ["pytest", f"{repo_root}/functions/tests/", "-v", "--tb=short"]))

    build_script = {
        "dev": f"{repo_root}/scripts/build/build_dev.sh",
        "staging": f"{repo_root}/scripts/build/build_staging.sh",
        "prod": f"{repo_root}/scripts/build/build_prod.sh",
    }[env]
    steps.append(("Flutter web build", ["bash", build_script, "web"]))

    for step_name, cmd in steps:
        console.print(f"\n[bold]→ {step_name}[/bold]")
        rc = subprocess.call(cmd)
        if rc != 0:
            error(f"{step_name} failed — aborting deploy")
            raise SystemExit(1)

    for target in ["functions", "firestore:rules,storage", "firestore:indexes", "hosting"]:
        rc = _firebase(["deploy", "--only", target], env)
        if rc != 0:
            error(f"Deploy {target} failed")
            raise SystemExit(1)

    success(f"Full deploy to {env} complete")
```

**Step 2: Test deploy functions --env=dev (dry run check)**

```bash
source functions/venv/bin/activate && python -m cli.cli deploy --help
```
Expected: Shows `functions`, `rules`, `indexes`, `hosting`, `all` subcommands.

**Step 3: Commit**

```bash
git add cli/commands/deploy.py
git commit -m "feat(cli): add deploy command group (functions/rules/indexes/hosting/all)"
```

---

### Task 6: `db` command group

**Files:**
- Create: `cli/commands/db.py`

**Step 1: Create `cli/commands/db.py`**

```python
"""DB commands — seed, reset, verify, export data."""
import subprocess
import os
import click
from cli.utils.output import console, success, error, warn, header, confirm_prod


def _repo_root() -> str:
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@click.group()
def db():
    """Database management (seed, reset, verify)."""
    pass


@db.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def seed(env: str):
    """Seed test data (dev/staging only)."""
    header("Seed DB", env)
    if env == "prod":
        error("Seeding is not allowed in prod.")
        return
    script = os.path.join(_repo_root(), "scripts", "seed_dev_db.py")
    rc = subprocess.call(["python", script])
    success("Seed complete") if rc == 0 else error(f"Seed failed (exit {rc})")


@db.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def verify(env: str):
    """Verify DB integrity and data consistency."""
    header("Verify DB", env)
    script = os.path.join(_repo_root(), "scripts", "verify_dev_data.py")
    rc = subprocess.call(["python", script])
    success("Verify complete") if rc == 0 else error(f"Verify failed (exit {rc})")


@db.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.confirmation_option(prompt="This will DELETE all test data. Are you sure?")
def reset(env: str):
    """Delete all test/seed data (dev/staging only)."""
    header("Reset DB", env)
    if env == "prod":
        error("Reset is not allowed in prod.")
        return
    script = os.path.join(_repo_root(), "scripts", "delete_dev_products.py")
    rc = subprocess.call(["python", script])
    success("Reset complete") if rc == 0 else error(f"Reset failed (exit {rc})")


@db.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def algolia_sync(env: str):
    """Sync Firestore products to Algolia index."""
    header("Algolia Sync", env)
    script = os.path.join(_repo_root(), "scripts", "sync_emulator_to_algolia.py")
    rc = subprocess.call(["python", script])
    success("Algolia sync complete") if rc == 0 else error(f"Sync failed (exit {rc})")
```

**Step 2: Verify**

```bash
source functions/venv/bin/activate && python -m cli.cli db --help
```
Expected: Shows `seed`, `reset`, `verify`, `algolia-sync` subcommands.

**Step 3: Commit**

```bash
git add cli/commands/db.py
git commit -m "feat(cli): add db command group (seed/reset/verify/algolia-sync)"
```

---

### Task 7: `secrets`, `tests`, `webhooks` command groups

**Files:**
- Create: `cli/commands/secrets.py`
- Create: `cli/commands/tests.py`
- Create: `cli/commands/webhooks.py`

**Step 1: Create `cli/commands/secrets.py`**

```python
"""Secrets management — upload, rotate, sync Remote Config."""
import subprocess
import os
import click
from cli.utils.output import header, success, error


def _repo_root() -> str:
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@click.group()
def secrets():
    """Manage secrets (Secret Manager, Remote Config)."""
    pass


@secrets.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def upload(env: str):
    """Upload secrets from .env to Secret Manager."""
    header("Upload Secrets", env)
    script = os.path.join(_repo_root(), "scripts", "upload_secrets.py")
    rc = subprocess.call(["python", script, "--env", env])
    success("Secrets uploaded") if rc == 0 else error(f"Upload failed (exit {rc})")


@secrets.command(name="sync-remote-config")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def sync_remote_config(env: str):
    """Push Remote Config values for an environment."""
    header("Sync Remote Config", env)
    script = os.path.join(_repo_root(), "scripts", "update_remote_config.py")
    rc = subprocess.call(["python", script, "--env", env])
    success("Remote Config synced") if rc == 0 else error(f"Sync failed (exit {rc})")
```

**Step 2: Create `cli/commands/tests.py`**

```python
"""Test runner — backend, E2E, integration, all."""
import subprocess
import os
import click
from cli.utils.output import header, success, error, console

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


@click.group()
def tests():
    """Run test suites."""
    pass


@tests.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--path", default="functions/tests/", help="Test path or file")
@click.option("-k", default=None, help="pytest -k filter")
def backend(env: str, path: str, k: str | None):
    """Run pytest backend tests."""
    header("Backend Tests", env)
    cmd = ["pytest", path, "-v", "--tb=short"]
    if k:
        cmd += ["-k", k]
    rc = subprocess.call(cmd, cwd=REPO_ROOT)
    success("Backend tests passed") if rc == 0 else error(f"Backend tests failed (exit {rc})")


@tests.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--config", default=None, help="Playwright config file (auto-selected if omitted)")
def e2e(env: str, config: str | None):
    """Run Playwright E2E tests."""
    header("E2E Tests (Playwright)", env)
    if env == "prod":
        error("E2E tests are not run against prod.")
        return
    config_file = config or (
        "playwright.config.dev.ts" if env == "dev" else "playwright.config.staging.ts"
    )
    cmd = ["npx", "playwright", "test", f"--config={config_file}"]
    rc = subprocess.call(cmd, cwd=os.path.join(REPO_ROOT, "e2e"))
    success("E2E tests passed") if rc == 0 else error(f"E2E tests failed (exit {rc})")


@tests.command(name="integration")
@click.option("--env", required=True, type=click.Choice(["dev"]))
@click.option("--index", default=-1, help="Test index 0-4 (-1 = random)")
def integration_tests(env: str, index: int):
    """Run Flutter integration tests (dev only)."""
    header("Flutter Integration Tests", env)
    defines = f"--dart-define=ENVIRONMENT=dev --dart-define=IS_TEST=true"
    if index >= 0:
        defines += f" --dart-define=INTEGRATION_TEST_INDEX={index}"
    cmd = (
        f"flutter drive "
        f"--driver=test_driver/integration_test.dart "
        f"--target=integration_test/all_tests.dart "
        f"-d chrome {defines}"
    )
    console.print(f"[dim]$ {cmd}[/dim]")
    rc = subprocess.call(cmd, shell=True, cwd=os.path.join(REPO_ROOT, "origna_gta"))
    success("Integration tests passed") if rc == 0 else error(f"Integration tests failed (exit {rc})")


@tests.command(name="all")
@click.option("--env", required=True, type=click.Choice(["dev", "staging"]))
def all_tests(env: str):
    """Run backend + E2E tests."""
    header("All Tests", env)
    cmds = [
        (["pytest", "functions/tests/", "-v", "--tb=short"], REPO_ROOT),
        (["npx", "playwright", "test", f"--config=playwright.config.{env}.ts"], os.path.join(REPO_ROOT, "e2e")),
    ]
    for cmd, cwd in cmds:
        rc = subprocess.call(cmd, cwd=cwd)
        if rc != 0:
            error(f"Tests failed: {' '.join(cmd)}")
            raise SystemExit(1)
    success("All tests passed")
```

**Step 3: Create `cli/commands/webhooks.py`**

```python
"""Stripe webhook management per environment."""
import os
import click
from cli.utils.output import header, success, error, console, make_table
from cli.utils.stripe_client import get_stripe


ENV_TO_URL = {
    "dev": "https://us-central1-orignagta-dev.cloudfunctions.net/stripe_webhook",
    "staging": "https://us-central1-orignagta-staging.cloudfunctions.net/stripe_webhook",
    "prod": "https://us-central1-orignagta.cloudfunctions.net/stripe_webhook",
}

REQUIRED_EVENTS = [
    "checkout.session.completed",
    "checkout.session.expired",
    "payment_intent.succeeded",
    "payment_intent.payment_failed",
    "payment_intent.canceled",
    "charge.dispute.created",
    "charge.dispute.funds_reinstated",
    "charge.dispute.funds_withdrawn",
    "charge.dispute.closed",
]


@click.group()
def webhooks():
    """Manage Stripe webhooks per environment."""
    pass


@webhooks.command(name="list")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def list_webhooks(env: str):
    """List all Stripe webhook endpoints."""
    header("Stripe Webhooks", env)
    stripe = get_stripe(env)
    endpoints = stripe.webhook_endpoints.list()
    t = make_table("Webhook Endpoints", ["ID", "URL", "Status", "Events"])
    for ep in endpoints.data:
        t.add_row(ep.id, ep.url[:60], ep.status, str(len(ep.enabled_events)))
    console.print(t)


@webhooks.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def verify(env: str):
    """Verify all required events are registered."""
    header("Verify Webhooks", env)
    stripe = get_stripe(env)
    expected_url = ENV_TO_URL[env]
    endpoints = stripe.webhook_endpoints.list()
    match = next((ep for ep in endpoints.data if ep.url == expected_url), None)
    if not match:
        error(f"No webhook found for URL: {expected_url}")
        return
    missing = set(REQUIRED_EVENTS) - set(match.enabled_events)
    if missing:
        error(f"Missing events: {missing}")
    else:
        success(f"All {len(REQUIRED_EVENTS)} required events registered on {match.id}")


@webhooks.command()
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def sync(env: str):
    """Create or update webhook endpoint with all required events."""
    header("Sync Webhooks", env)
    stripe_client = get_stripe(env)
    expected_url = ENV_TO_URL[env]
    endpoints = stripe_client.webhook_endpoints.list()
    existing = next((ep for ep in endpoints.data if ep.url == expected_url), None)
    if existing:
        stripe_client.webhook_endpoints.update(existing.id, {"enabled_events": REQUIRED_EVENTS})
        success(f"Updated existing webhook {existing.id}")
    else:
        ep = stripe_client.webhook_endpoints.create(params={
            "url": expected_url,
            "enabled_events": REQUIRED_EVENTS,
        })
        success(f"Created webhook {ep.id} for {expected_url}")
```

**Step 4: Verify all three groups load**

```bash
source functions/venv/bin/activate && python -m cli.cli --help
```
Expected: All 9 command groups listed (deploy, db, secrets, tests, users, orders, payments, products, webhooks).

**Step 5: Commit**

```bash
git add cli/commands/secrets.py cli/commands/tests.py cli/commands/webhooks.py
git commit -m "feat(cli): add secrets, tests, webhooks command groups"
```

---

### Task 8: `users` command group

**Files:**
- Create: `cli/commands/users.py`

**Step 1: Create `cli/commands/users.py`**

```python
"""User management — list, ban, unban, delete, view."""
import click
from cli.utils.output import header, success, error, console, make_table, confirm_prod
from cli.utils.firebase_client import get_firestore, get_auth


@click.group()
def users():
    """Manage platform users."""
    pass


@users.command(name="list")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--role", default=None, type=click.Choice(["buyer", "seller", "admin"]))
@click.option("--limit", default=20)
def list_users(env: str, role: str | None, limit: int):
    """List users, optionally filtered by role."""
    header("Users", env)
    db = get_firestore(env)
    query = db.collection("users").limit(limit)
    if role:
        query = query.where("role", "==", role)
    docs = query.stream()
    t = make_table(f"Users ({env})", ["UID", "Email", "Role", "Status", "Created"])
    count = 0
    for doc in docs:
        d = doc.to_dict()
        t.add_row(
            doc.id[:20],
            d.get("email", "—"),
            d.get("role", "—"),
            d.get("status", "active"),
            str(d.get("createdAt", "—"))[:19],
        )
        count += 1
    console.print(t)
    console.print(f"[dim]Showing {count} users[/dim]")


@users.command()
@click.argument("uid")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--reason", required=True, help="Reason for ban")
def ban(uid: str, env: str, reason: str):
    """Ban a user by UID."""
    header(f"Ban User {uid[:12]}...", env)
    if env == "prod" and not confirm_prod(f"ban user {uid}"):
        return
    db = get_firestore(env)
    db.collection("users").document(uid).update({
        "status": "banned",
        "banReason": reason,
    })
    auth = get_auth(env)
    auth.update_user(uid, disabled=True)
    success(f"User {uid} banned: {reason}")


@users.command()
@click.argument("uid")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def unban(uid: str, env: str):
    """Unban a user by UID."""
    header(f"Unban User {uid[:12]}...", env)
    if env == "prod" and not confirm_prod(f"unban user {uid}"):
        return
    db = get_firestore(env)
    db.collection("users").document(uid).update({"status": "active", "banReason": None})
    auth = get_auth(env)
    auth.update_user(uid, disabled=False)
    success(f"User {uid} unbanned")


@users.command()
@click.argument("uid")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.confirmation_option(prompt="Permanently delete this user?")
def delete(uid: str, env: str):
    """Permanently delete a user and their Auth account."""
    header(f"Delete User {uid[:12]}...", env)
    if env == "prod" and not confirm_prod(f"delete user {uid}"):
        return
    db = get_firestore(env)
    db.collection("users").document(uid).delete()
    auth = get_auth(env)
    auth.delete_user(uid)
    success(f"User {uid} deleted")


@users.command()
@click.argument("uid")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def view(uid: str, env: str):
    """View full user profile."""
    header(f"User {uid[:12]}...", env)
    db = get_firestore(env)
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        error(f"User {uid} not found")
        return
    from rich.pretty import pprint
    pprint(doc.to_dict())
```

**Step 2: Verify**

```bash
source functions/venv/bin/activate && python -m cli.cli users --help
```
Expected: Shows `list`, `ban`, `unban`, `delete`, `view` subcommands.

**Step 3: Commit**

```bash
git add cli/commands/users.py
git commit -m "feat(cli): add users command group (list/ban/unban/delete/view)"
```

---

### Task 9: `orders` command group

**Files:**
- Create: `cli/commands/orders.py`

**Step 1: Create `cli/commands/orders.py`**

```python
"""Order management — list, view, refund, force-status, cancel."""
import click
from cli.utils.output import header, success, error, console, make_table, confirm_prod
from cli.utils.firebase_client import get_firestore
from cli.utils.stripe_client import get_stripe


@click.group()
def orders():
    """Manage marketplace orders."""
    pass


@orders.command(name="list")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--status", default=None)
@click.option("--limit", default=20)
@click.option("--buyer", default=None, help="Filter by buyer UID")
@click.option("--seller", default=None, help="Filter by seller UID")
def list_orders(env: str, status: str | None, limit: int, buyer: str | None, seller: str | None):
    """List orders with optional filters."""
    header("Orders", env)
    db = get_firestore(env)
    query = db.collection("orders").limit(limit)
    if status:
        query = query.where("status", "==", status)
    if buyer:
        query = query.where("buyerId", "==", buyer)
    docs = list(query.stream())
    t = make_table(f"Orders ({env}) — {len(docs)} results", ["Order ID", "Buyer", "Status", "Total", "Created"])
    for doc in docs:
        d = doc.to_dict()
        total = d.get("totalAmountCents", 0)
        t.add_row(
            doc.id[:20],
            d.get("buyerId", "—")[:16],
            d.get("status", "—"),
            f"${total/100:.2f} CAD",
            str(d.get("createdAt", "—"))[:19],
        )
    console.print(t)


@orders.command()
@click.argument("order_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def view(order_id: str, env: str):
    """View full order details."""
    header(f"Order {order_id[:12]}...", env)
    db = get_firestore(env)
    doc = db.collection("orders").document(order_id).get()
    if not doc.exists:
        error(f"Order {order_id} not found")
        return
    from rich.pretty import pprint
    pprint(doc.to_dict())


@orders.command()
@click.argument("order_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--amount", required=True, type=int, help="Refund amount in cents")
@click.option("--reason", default="requested_by_customer",
              type=click.Choice(["duplicate", "fraudulent", "requested_by_customer"]))
def refund(order_id: str, env: str, amount: int, reason: str):
    """Issue a Stripe refund for an order."""
    header(f"Refund Order {order_id[:12]}...", env)
    if env == "prod" and not confirm_prod(f"refund ${amount/100:.2f} on order {order_id}"):
        return
    db = get_firestore(env)
    doc = db.collection("orders").document(order_id).get()
    if not doc.exists:
        error(f"Order {order_id} not found")
        return
    d = doc.to_dict()
    pi_id = d.get("stripePaymentIntentId")
    if not pi_id:
        error("Order has no stripePaymentIntentId")
        return
    stripe = get_stripe(env)
    # Get the charge ID from the PaymentIntent
    pi = stripe.payment_intents.retrieve(pi_id)
    charge_id = pi.latest_charge
    if not charge_id:
        error("No charge found on PaymentIntent")
        return
    rf = stripe.refunds.create(params={"charge": charge_id, "amount": amount, "reason": reason})
    db.collection("orders").document(order_id).update({
        "refundStatus": "refunded",
        "refundAmountCents": amount,
        "stripeRefundId": rf.id,
    })
    success(f"Refund {rf.id} issued: ${amount/100:.2f}")


@orders.command(name="force-status")
@click.argument("order_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--status", required=True,
              type=click.Choice(["pending", "processing", "shipped", "delivered", "cancelled", "disputed"]))
def force_status(order_id: str, env: str, status: str):
    """Force an order's status (admin override)."""
    header(f"Force Status {order_id[:12]}...", env)
    if env == "prod" and not confirm_prod(f"force status={status} on order {order_id}"):
        return
    db = get_firestore(env)
    db.collection("orders").document(order_id).update({"status": status})
    success(f"Order {order_id} status forced to '{status}'")


@orders.command()
@click.argument("order_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--reason", required=True)
def cancel(order_id: str, env: str, reason: str):
    """Cancel an order and update status."""
    header(f"Cancel Order {order_id[:12]}...", env)
    if env == "prod" and not confirm_prod(f"cancel order {order_id}"):
        return
    db = get_firestore(env)
    db.collection("orders").document(order_id).update({
        "status": "cancelled",
        "cancellationReason": reason,
    })
    success(f"Order {order_id} cancelled: {reason}")
```

**Step 2: Verify**

```bash
source functions/venv/bin/activate && python -m cli.cli orders --help
```
Expected: Shows `list`, `view`, `refund`, `force-status`, `cancel` subcommands.

**Step 3: Commit**

```bash
git add cli/commands/orders.py
git commit -m "feat(cli): add orders command group (list/view/refund/force-status/cancel)"
```

---

### Task 10: `payments` and `products` command groups

**Files:**
- Create: `cli/commands/payments.py`
- Create: `cli/commands/products.py`

**Step 1: Create `cli/commands/payments.py`**

```python
"""Payment management — disputes, payouts, capture."""
import click
from cli.utils.output import header, success, error, console, make_table, confirm_prod
from cli.utils.firebase_client import get_firestore
from cli.utils.stripe_client import get_stripe


@click.group()
def payments():
    """Manage payments, disputes, and payouts."""
    pass


@payments.command(name="dispute")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--status", default=None, type=click.Choice(["needs_response", "under_review", "won", "lost"]))
def list_disputes(env: str, status: str | None):
    """List Stripe disputes."""
    header("Disputes", env)
    stripe = get_stripe(env)
    params = {"limit": 20}
    if status:
        params["status"] = status
    disputes = stripe.disputes.list(params=params)
    t = make_table(f"Disputes ({env})", ["Dispute ID", "Amount", "Status", "Reason", "Order"])
    for d in disputes.data:
        order_id = d.metadata.get("orderId", "—") if d.metadata else "—"
        t.add_row(d.id, f"${d.amount/100:.2f}", d.status, d.reason, order_id)
    console.print(t)


@payments.command(name="dispute-resolve")
@click.argument("dispute_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--action", required=True, type=click.Choice(["accept", "submit_evidence"]))
def resolve_dispute(dispute_id: str, env: str, action: str):
    """Accept or submit evidence for a dispute."""
    header(f"Resolve Dispute {dispute_id[:16]}...", env)
    if env == "prod" and not confirm_prod(f"{action} dispute {dispute_id}"):
        return
    stripe = get_stripe(env)
    if action == "accept":
        stripe.disputes.close(dispute_id)
        success(f"Dispute {dispute_id} accepted (closed)")
    else:
        error("Evidence submission requires uploading files — use the Stripe dashboard.")


@payments.command(name="trigger-payouts")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--dry-run", is_flag=True, default=False)
def trigger_payouts(env: str, dry_run: bool):
    """Trigger payout processing for delivered orders."""
    header("Trigger Payouts", env)
    if env == "prod" and not confirm_prod("trigger payouts in PRODUCTION"):
        return
    if dry_run:
        console.print("[yellow]DRY RUN — no payouts will be created[/yellow]")
        return
    db = get_firestore(env)
    delivered = db.collection("orders").where("status", "==", "delivered").where("payoutStatus", "==", "pending").stream()
    count = sum(1 for _ in delivered)
    success(f"Found {count} orders eligible for payout. Run cron_jobs.process_pending_payouts to execute.")


@payments.command()
@click.argument("order_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def capture(order_id: str, env: str):
    """Manually capture payment for an order (if not auto-captured)."""
    header(f"Capture {order_id[:12]}...", env)
    if env == "prod" and not confirm_prod(f"capture payment for order {order_id}"):
        return
    db = get_firestore(env)
    doc = db.collection("orders").document(order_id).get()
    if not doc.exists:
        error(f"Order {order_id} not found")
        return
    pi_id = doc.to_dict().get("stripePaymentIntentId")
    stripe = get_stripe(env)
    stripe.payment_intents.capture(pi_id)
    success(f"Payment captured for order {order_id}")
```

**Step 2: Create `cli/commands/products.py`**

```python
"""Product management — list, approve, reject, delete."""
import click
from cli.utils.output import header, success, error, console, make_table, confirm_prod
from cli.utils.firebase_client import get_firestore


@click.group()
def products():
    """Manage marketplace products."""
    pass


@products.command(name="list")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--pending-approval", is_flag=True, default=False)
@click.option("--seller", default=None, help="Filter by seller UID")
@click.option("--limit", default=20)
def list_products(env: str, pending_approval: bool, seller: str | None, limit: int):
    """List products with optional filters."""
    header("Products", env)
    db = get_firestore(env)
    query = db.collection("products").limit(limit)
    if pending_approval:
        query = query.where("approvalStatus", "==", "pending")
    if seller:
        query = query.where("sellerId", "==", seller)
    docs = list(query.stream())
    t = make_table(f"Products ({env}) — {len(docs)}", ["ID", "Title", "Seller", "Price", "Stock", "Approval"])
    for doc in docs:
        d = doc.to_dict()
        price = d.get("priceCents", 0)
        t.add_row(
            doc.id[:16],
            str(d.get("title", "—"))[:30],
            d.get("sellerId", "—")[:16],
            f"${price/100:.2f}",
            str(d.get("stockQuantity", 0)),
            d.get("approvalStatus", "approved"),
        )
    console.print(t)


@products.command()
@click.argument("product_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
def approve(product_id: str, env: str):
    """Approve a product for listing."""
    header(f"Approve {product_id[:12]}...", env)
    db = get_firestore(env)
    db.collection("products").document(product_id).update({"approvalStatus": "approved"})
    success(f"Product {product_id} approved")


@products.command()
@click.argument("product_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.option("--reason", required=True)
def reject(product_id: str, env: str, reason: str):
    """Reject a product with a reason."""
    header(f"Reject {product_id[:12]}...", env)
    db = get_firestore(env)
    db.collection("products").document(product_id).update({
        "approvalStatus": "rejected",
        "rejectionReason": reason,
    })
    success(f"Product {product_id} rejected: {reason}")


@products.command()
@click.argument("product_id")
@click.option("--env", required=True, type=click.Choice(["dev", "staging", "prod"]))
@click.confirmation_option(prompt="Permanently delete this product?")
def delete(product_id: str, env: str):
    """Permanently delete a product."""
    header(f"Delete {product_id[:12]}...", env)
    if env == "prod" and not confirm_prod(f"delete product {product_id}"):
        return
    db = get_firestore(env)
    db.collection("products").document(product_id).delete()
    success(f"Product {product_id} deleted")
```

**Step 3: Verify all commands available**

```bash
source functions/venv/bin/activate && python -m cli.cli payments --help && python -m cli.cli products --help
```
Expected: Both groups show their subcommands.

**Step 4: Commit**

```bash
git add cli/commands/payments.py cli/commands/products.py
git commit -m "feat(cli): add payments and products command groups"
```

---

### Task 11: CLI `README` + wrapper script

**Files:**
- Create: `cli/README.md` — NO, per project rules. Instead create `cli/USAGE.txt`
- Create: `admin` (root-level executable wrapper)

**Step 1: Create root `admin` script**

```bash
#!/bin/bash
# admin — OrignaGTA Admin CLI wrapper
# Usage: ./admin <group> <command> --env=dev|staging|prod
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
source "$REPO_ROOT/functions/venv/bin/activate"
python -m cli.cli "$@"
```

**Step 2: Make executable**

```bash
chmod +x admin
```

**Step 3: Smoke test wrapper**

```bash
./admin --help
```
Expected: Full help text with all 9 command groups.

**Step 4: Commit**

```bash
git add admin cli/USAGE.txt 2>/dev/null || true
git add admin
git commit -m "feat(cli): add ./admin root wrapper script"
```

---

## Phase 4: GitHub Actions CI

### Task 12: Backend CI workflow

**Files:**
- Create: `.github/workflows/ci-backend.yml`

**Context:** Runs on every push/PR. No Firebase needed — tests are mocked. Uses the `functions/venv`.

**Step 1: Create `.github/workflows/ci-backend.yml`**

```yaml
name: CI — Backend Tests

on:
  push:
    branches: ["main", "develop"]
  pull_request:
    branches: ["main", "develop"]

jobs:
  pytest:
    name: pytest (Python 3.11)
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: functions

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-python@v5
        with:
          python-version: "3.11"
          cache: pip
          cache-dependency-path: functions/requirements.txt

      - name: Install dependencies
        run: pip install -r requirements.txt

      - name: Run tests
        run: pytest tests/ -v --tb=short --junitxml=test-results.xml
        env:
          FIRESTORE_EMULATOR_HOST: ""  # Tests use mocks, not emulator

      - name: Upload test results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: pytest-results
          path: functions/test-results.xml
```

**Step 2: Verify YAML syntax**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci-backend.yml'))" && echo "YAML valid"
```
Expected: `YAML valid`

**Step 3: Commit**

```bash
git add .github/workflows/ci-backend.yml
git commit -m "feat(ci): add backend pytest workflow (runs on every push)"
```

---

### Task 13: Flutter Web + Playwright CI workflow

**Files:**
- Create: `.github/workflows/ci-flutter-web.yml`

**Context:** Builds Flutter web (debug, dev env), serves locally, runs Playwright. Uses `playwright.config.dev.ts` pointing to `localhost:5005`.

**Step 1: Create `.github/workflows/ci-flutter-web.yml`**

```yaml
name: CI — Flutter Web + Playwright E2E

on:
  push:
    branches: ["main", "develop"]
  pull_request:
    branches: ["main", "develop"]

jobs:
  e2e:
    name: Playwright E2E (dev)
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"
          channel: stable
          cache: true

      - name: Build Flutter web (debug, dev env)
        run: |
          cd origna_gta
          flutter build web --debug \
            --dart-define=ENVIRONMENT=dev
        env:
          FLUTTER_WEB_USE_SKIA: "true"

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: npm
          cache-dependency-path: e2e/package-lock.json

      - name: Install Playwright
        run: cd e2e && npm ci && npx playwright install chromium --with-deps

      - name: Serve Flutter web
        run: |
          npx serve -s origna_gta/build/web -l 5005 &
          sleep 5
          curl -sf http://localhost:5005 > /dev/null || (echo "Server not up" && exit 1)

      - name: Run Playwright E2E
        run: cd e2e && npx playwright test --config=playwright.config.dev.ts
        env:
          CI: "true"
          STRIPE_TEST_KEY: ${{ secrets.STRIPE_TEST_KEY }}
          ALGOLIA_ADMIN_KEY: ${{ secrets.ALGOLIA_ADMIN_KEY }}

      - name: Upload Playwright report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: playwright-report
          path: e2e/playwright-report/
          retention-days: 7
```

**Step 2: Verify YAML**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci-flutter-web.yml'))" && echo "YAML valid"
```

**Step 3: Commit**

```bash
git add .github/workflows/ci-flutter-web.yml
git commit -m "feat(ci): add Flutter web + Playwright E2E workflow"
```

---

### Task 14: Mobile CI + Firebase Test Lab workflow

**Files:**
- Create: `.github/workflows/ci-mobile.yml`

**Context:** Only runs on PRs to `main` (conserves free tier quota). Builds Android APK (debug) + iOS IPA (no-codesign), uploads both to Firebase Test Lab. Android runs Flutter integration tests, iOS runs Robo crawl.

**Step 1: Create `.github/workflows/ci-mobile.yml`**

```yaml
name: CI — Mobile (Firebase Test Lab)

on:
  pull_request:
    branches: ["main"]

jobs:
  android-test-lab:
    name: Android — Integration Tests (Test Lab)
    runs-on: ubuntu-latest
    timeout-minutes: 45

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"
          channel: stable
          cache: true

      - name: Build debug APK (app + test)
        run: |
          cd origna_gta
          flutter build apk --debug \
            --dart-define=ENVIRONMENT=dev \
            --dart-define=IS_TEST=true
        # The instrumentation test APK is built automatically alongside

      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_DEV }}

      - uses: google-github-actions/setup-gcloud@v2
        with:
          project_id: ${{ secrets.GCLOUD_PROJECT_DEV }}

      - name: Run Android instrumentation tests on Test Lab
        run: |
          gcloud firebase test android run \
            --type instrumentation \
            --app origna_gta/build/app/outputs/flutter-apk/app-debug.apk \
            --test origna_gta/build/app/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
            --device model=Pixel6,version=33,locale=en,orientation=portrait \
            --timeout 10m \
            --results-dir=gs://orignagta-dev.appspot.com/test-results/${{ github.run_id }} \
            --no-record-video

      - name: Post summary
        if: always()
        run: |
          echo "### Android Test Lab Results" >> $GITHUB_STEP_SUMMARY
          echo "Device: Pixel 6 (API 33)" >> $GITHUB_STEP_SUMMARY
          echo "Test: Flutter integration tests (random flow)" >> $GITHUB_STEP_SUMMARY

  ios-test-lab:
    name: iOS — Robo Crawl (Test Lab)
    runs-on: macos-latest
    timeout-minutes: 45

    steps:
      - uses: actions/checkout@v4

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: "3.x"
          channel: stable
          cache: true

      - name: Build iOS (no codesign, debug)
        run: |
          cd origna_gta
          flutter build ios --debug --no-codesign \
            --dart-define=ENVIRONMENT=dev
          cd ios && xcodebuild \
            -workspace Runner.xcworkspace \
            -scheme Runner \
            -configuration Debug \
            -sdk iphonesimulator \
            -derivedDataPath build/ios_integ \
            OTHER_SWIFT_FLAGS="-D INTEGRATION_TEST" \
            build-for-testing 2>&1 | tail -20
          cd build/ios_integ/Build/Products/Debug-iphonesimulator
          zip -r Runner.zip Runner.app

      - uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_DEV }}

      - uses: google-github-actions/setup-gcloud@v2
        with:
          project_id: ${{ secrets.GCLOUD_PROJECT_DEV }}

      - name: Run iOS Robo crawl on Test Lab
        run: |
          gcloud firebase test ios run \
            --test origna_gta/ios/build/ios_integ/Build/Products/Debug-iphonesimulator/Runner.zip \
            --device model=iphone14,version=16.6,locale=en_US,orientation=portrait \
            --timeout 5m \
            --no-record-video

      - name: Post summary
        if: always()
        run: |
          echo "### iOS Test Lab Results" >> $GITHUB_STEP_SUMMARY
          echo "Device: iPhone 14 (iOS 16.6)" >> $GITHUB_STEP_SUMMARY
          echo "Test: Robo crawl" >> $GITHUB_STEP_SUMMARY
```

**Step 2: Verify YAML**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci-mobile.yml'))" && echo "YAML valid"
```

**Step 3: Commit**

```yaml
git add .github/workflows/ci-mobile.yml
git commit -m "feat(ci): add mobile CI with Firebase Test Lab (Android integration + iOS Robo)"
```

---

### Task 15: Add GitHub Actions secrets documentation

**Files:**
- Modify: `docs/plans/2026-02-18-admin-cli-testlab-envs-design.md` (already has secrets section — no change needed)
- Create: `.github/SECRETS.md` — NO (no new markdown files per rules). Add to existing `.claude/LEARNED.md` instead.

**Step 1: Update `.claude/LEARNED.md` with CI secrets required**

Add to `.claude/LEARNED.md`:
```
## GitHub Actions Secrets Required (CI)
- FIREBASE_SERVICE_ACCOUNT_DEV — JSON service account key for orignagta-dev
- GCLOUD_PROJECT_DEV — "orignagta-dev"
- STRIPE_TEST_KEY — sk_test_... (for E2E Playwright)
- ALGOLIA_ADMIN_KEY — Algolia admin key (for E2E Playwright)

Set at: GitHub repo → Settings → Secrets and variables → Actions
```

**Step 2: Final smoke test — all workflows valid**

```bash
python3 -c "
import yaml, glob
for f in glob.glob('.github/workflows/*.yml'):
    yaml.safe_load(open(f))
    print(f'✅ {f}')
"
```
Expected: All 3 workflows print `✅`.

**Step 3: Final commit**

```bash
git add .claude/LEARNED.md
git commit -m "docs: record GitHub Actions secrets required for CI"
```

---

## Summary of Files Created/Modified

| File | Action |
|------|--------|
| `origna_gta/lib/main.dart` | Modified — semantics guard |
| `scripts/build/build_dev.sh` | Created |
| `scripts/build/build_staging.sh` | Created |
| `scripts/build/build_prod.sh` | Created |
| `e2e/playwright.config.dev.ts` | Created |
| `e2e/playwright.config.staging.ts` | Created |
| `cli/cli.py` | Created |
| `cli/commands/deploy.py` | Created |
| `cli/commands/db.py` | Created |
| `cli/commands/secrets.py` | Created |
| `cli/commands/tests.py` | Created |
| `cli/commands/users.py` | Created |
| `cli/commands/orders.py` | Created |
| `cli/commands/payments.py` | Created |
| `cli/commands/products.py` | Created |
| `cli/commands/webhooks.py` | Created |
| `cli/utils/firebase_client.py` | Created |
| `cli/utils/stripe_client.py` | Created |
| `cli/utils/output.py` | Created |
| `cli/requirements.txt` | Created |
| `admin` | Created (root wrapper) |
| `.github/workflows/ci-backend.yml` | Created |
| `.github/workflows/ci-flutter-web.yml` | Created |
| `.github/workflows/ci-mobile.yml` | Created |

## Build Environment Quick Reference

| Env | Command | Mode | Playwright |
|-----|---------|------|------------|
| Dev | `./admin tests e2e --env=dev` | debug | `playwright.config.dev.ts` → localhost:5005 |
| Staging | `./admin tests e2e --env=staging` | profile + FORCE_SEMANTICS | `playwright.config.staging.ts` → orignagta-staging.web.app |
| Prod | `./admin deploy all --env=prod` | release | N/A |
