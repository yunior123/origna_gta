# /deploy — Deploy Flutter Web to VPS (Caddy)

**Usage**: `/deploy [dev|staging|production]`

We own our hosting — all web deployments go to the VPS at `204.168.137.16` served by Caddy.
- Dev: `/var/www/orignagta/dev/current`
- Staging: `/var/www/orignagta/staging/current`
- Production: `/var/www/orignagta/production/current`

## Rules (NEVER break these)
- ALWAYS build for the target environment before deploying
- ALWAYS inject `TURNSTILE_SITE_KEY` into `build/web/index.html` for staging/production
- NEVER skip the build step — stale builds cause silent env mismatches
- NEVER deploy staging/production without explicit user confirmation

## Step-by-Step

### Dev Deploy
```bash
cd origna_gta

# Build
flutter build web --debug \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca \
  --dart-define=FORCE_SEMANTICS=true

# Deploy to VPS
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/dev/current/
```

### Staging Deploy
```bash
cd origna_gta

# Build
flutter build web --profile \
  --dart-define=ENVIRONMENT=staging \
  --dart-define=ORIGNABASE_URL=https://api.staging.orignagta.ca \
  --dart-define=FORCE_SEMANTICS=true

# Inject Turnstile key
sed -i "s/__TURNSTILE_SITE_KEY__/${TURNSTILE_SITE_KEY}/g" build/web/index.html

# Deploy to VPS
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/staging/current/
```

### Production Deploy
```bash
cd origna_gta

# Build
flutter build web --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=ORIGNABASE_URL=https://api.orignagta.ca

# Inject Turnstile key
sed -i "s/__TURNSTILE_SITE_KEY__/${TURNSTILE_SITE_KEY}/g" build/web/index.html

# Deploy to VPS
rsync -az --delete build/web/ root@204.168.137.16:/var/www/orignagta/production/current/
```

## Or use the deploy script
```bash
bash scripts/deploy_web.sh dev
bash scripts/deploy_web.sh staging
bash scripts/deploy_web.sh production
```

## Pre-deploy Checklist
1. `flutter analyze --no-fatal-infos` passes
2. User has confirmed target environment
3. `TURNSTILE_SITE_KEY` env var is set (staging/production)
4. Git working tree is clean
5. SSH key `~/.ssh/id_ed25519` works: `ssh root@204.168.137.16 echo ok`

## Post-deploy Verification
- Dev: `https://dev.orignagta.ca`
- Staging: `https://staging.orignagta.ca`
- Production: `https://orignagta.ca`
- Confirm Flutter loads + OrignaBase connectivity (products appear)
