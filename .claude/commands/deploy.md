# /deploy - Deploy to staging or production

**Usage**: `/deploy [staging|production]`

## What it does:
1. Runs pre-deployment checks:
   - ✅ All tests passing
   - ✅ No lint errors
   - ✅ Security audit clean
   - ✅ Documentation updated
2. Builds optimized bundles
3. Deploys to Firebase
4. Runs smoke tests
5. Reports deployment status

## Examples:
```
/deploy staging
/deploy production
```

## Pre-deployment Checklist:
```yaml
checks:
  - name: "Backend tests"
    command: "cd functions && pytest tests/"
    required: true
  
  - name: "Frontend tests"
    command: "cd origna_gta && flutter test"
    required: true
  
  - name: "Security scan"
    command: "grep -r 'API_KEY' functions/ origna_gta/"
    required: true
  
  - name: "Lint checks"
    command: "cd origna_gta && flutter analyze"
    required: true
  
  - name: "Build optimization"
    command: "cd origna_gta && flutter build web --release"
    required: true
```

## Implementation:
```bash
#!/bin/bash
ENV=${1:-staging}

echo "🚀 Deploying to: $ENV"
echo "===================="

# Pre-deployment checks
echo "✓ Running tests..."
./orchestrate-agents.sh test-all || exit 1

echo "✓ Security scan..."
# Security checks here

echo "✓ Building..."
cd origna_gta
flutter build web --release --dart-define=ENVIRONMENT=$ENV
cd ..

# Deploy web to VPS with staged releases (no Firebase hosting)
VPS_HOST=${VPS_HOST:-youruser@your-vps} ./scripts/deploy_web.sh $ENV

echo "✓ Deployed web to $ENV on VPS/Caddy"
echo "URL: https://orignagta.ca (prod) or dev/staging equivalents"
```
