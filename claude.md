# 🤖 Claude AI Configuration - OrignaGta Project

## Project Overview

**OrignaGta** is a Canada-only e-commerce marketplace built for scale (100M+ users/year target).

### Tech Stack
- **Frontend**: Flutter 3.10.7 Web + Riverpod
- **Backend**: Python 3.11 Cloud Functions
- **Database**: Firestore
- **Payments**: Stripe Connect + Airwallex  
- **Search**: Algolia
- **Storage**: Cloudflare R2

---

## 🚀 Parallel Agent System

### Quick Start
```bash
# Start 5+ agents in parallel terminals
./orchestrate-agents.sh

# Stop all agents
./stop-agents.sh

# View agent logs
tail -f .agent-logs/*.log
```

### 6 Always-Running Agents

1. **🧪 Test Runner** (CRITICAL - Always Active)
   - Runs tests every 60s (backend + frontend)
   - Auto-fixes common failures
   - Maintains 90%+ pass rate
   - Logs: `.agent-logs/test-runner.log`
   - Config: `.claude/test_runner_agent.md`

2. **🔧 Backend Guardian**
   - Monitors `functions/handlers/`
   - Scans for code quality issues
   - Finds TODOs and print statements
   - Logs: `.agent-logs/backend-guardian.log`

3. **✨ Frontend Polish**
   - Monitors `origna_gta/lib/`
   - Checks for missing widget Keys
   - Finds print() statements (should use debugPrint)
   - Logs: `.agent-logs/frontend-polish.log`

4. **🔒 Security Audit**
   - Scans for exposed secrets
   - Checks for security vulnerabilities
   - Monitors webhook security
   - Logs: `.agent-logs/security-scan.log`

5. **⚡ Performance Optimizer**
   - Detects N+1 query patterns
   - Monitors bundle sizes
   - Tracks response times
   - Logs: `.agent-logs/performance-n1.log`

6. **📚 Docs Keeper**
   - Maintains documentation freshness
   - Checks for broken links
   - Tracks pending TODOs
   - Logs: `.agent-logs/docs-todos.log`

### File Conflict Prevention

Each agent has exclusive write access to specific directories:

```yaml
file_ownership:
  test_runner:
    exclusive_write: ["functions/tests/", "origna_gta/test/", "integration_test/"]
    read_only: ["functions/handlers/", "origna_gta/lib/"]
  
  backend_guardian:
    exclusive_write: ["functions/handlers/", "functions/utils/"]
    read_only: ["functions/tests/"]
  
  frontend_polish:
    exclusive_write: ["origna_gta/lib/screens/", "origna_gta/lib/widgets/"]
    read_only: ["origna_gta/test/"]
  
  security_audit:
    exclusive_write: ["docs/security/", ".github/workflows/"]
    read_only: ["functions/", "origna_gta/"]
  
  performance_optimizer:
    exclusive_write: ["firestore.indexes.json", "docs/performance/"]
    read_only: ["functions/", "origna_gta/"]
  
  docs_keeper:
    exclusive_write: ["*.md", "docs/", ".claude/"]
    read_only: ["functions/", "origna_gta/"]
```

### Agent Coordination

Agents communicate via:
- **Shared logs**: `.agent-logs/*.log`
- **Status files**: `.agent-logs/status.json`
- **Lock files**: `.agent-locks/*.lock` (prevent concurrent edits)

Example status file:
```json
{
  "test_runner": {
    "status": "running",
    "last_run": "2026-02-03T10:30:00Z",
    "pass_rate": 92.5,
    "last_failure": "test_handlers_products_orders.py::test_create_product"
  },
  "backend_guardian": {
    "status": "idle",
    "last_scan": "2026-02-03T10:28:00Z",
    "issues_found": 3
  }
}
```

---

## 🎯 Specialized Agents (`.claude/`)

10 expert agents provide domain-specific guidance:

1. **backend_expert.md** - Python, Firebase, Cloud Functions
2. **flutter_expert.md** - Flutter, Dart, Riverpod, MVVM
3. **security_expert.md** - Auth, XSS, CSRF, MFA, GDPR
4. **testing_expert.md** - pytest, flutter_test, E2E
5. **database_expert.md** - Firestore schema, queries, rules
6. **payment_expert.md** - Stripe, Airwallex, webhooks
7. **devops_expert.md** - CI/CD, deployment, monitoring
8. **api_expert.md** - REST, integrations, rate limiting
9. **ui_ux_expert.md** - Material Design, responsive, a11y
10. **data_expert.md** - Analytics, search, migrations
11. **test_runner_agent.md** - Continuous testing (ALWAYS RUNNING)

Reference agent expertise for domain-specific tasks.

---

## ⚡ Slash Commands (`.claude/commands/`)

Quick actions for common tasks:

### `/permissions`
Pre-approved safe operations. Use this at the start of any session.

**Grants automatic approval for:**
- ✅ Read/write project files (code, docs, configs)
- ✅ Run tests (pytest, flutter test)
- ✅ Git operations (add, commit, push)
- ✅ Install dependencies (pip, npm, flutter pub)
- ✅ Build and deploy (firebase deploy)

**Restricted (requires manual approval):**
- ❌ System-wide changes (sudo)
- ❌ Delete .git or node_modules
- ❌ Modify file permissions (chmod 777)

**Usage:** Type `/permissions` to activate for current session.

### `/test-all`
Run complete test suite (backend + frontend + integration).

```bash
/test-all              # Run all tests once
/test-all --watch      # Continuous mode
/test-all --integration # Include E2E tests
```

### `/fix-tests [backend|frontend|all]`
Auto-fix common test failures.

Fixes:
- Missing imports
- Mock/fixture issues  
- Type mismatches
- Assertion errors

### `/commit-push [message]`
Smart commit and push.

```bash
/commit-push                           # Auto-generate message
/commit-push "Fix webhook security"    # Custom message
```

### `/deploy [staging|production]`
Deploy with pre-flight checks.

```bash
/deploy staging      # Deploy to staging
/deploy production   # Deploy to production (requires tests passing)
```

### `/audit-security [--fix]`
Run comprehensive security audit.

```bash
/audit-security       # Scan only
/audit-security --fix # Auto-fix issues
```

### `/optimize-db [--analyze|--fix]`
Database query optimization.

```bash
/optimize-db --analyze  # Find inefficiencies
/optimize-db --fix      # Apply optimizations
```

**All commands documented in:** `.claude/commands/*.md`

---

## 🚨 Critical Rules

### NEVER
- ❌ Trust client input (validate server-side)
- ❌ Use `db = firestore.client()` at module level
- ❌ Skip input validation/sanitization
- ❌ Commit secrets to git
- ❌ Deploy without testing

### ALWAYS  
- ✅ Use lazy loading: `get_db()` pattern
- ✅ Sanitize with `utils/validation.py`
- ✅ Type hints (Python) + types (Dart)
- ✅ Write tests for new features
- ✅ Log security events
- ✅ Test payments in test mode

## 🔐 Security Checklist

- [x] XSS prevention (sanitized_text)
- [x] Path traversal prevention (sanitize_path)
- [x] Webhook signature verification
- [x] Rate limiting (5→8 attempts exponential)
- [x] MFA for admin (TOTP with backup codes)
- [x] HTTPS enforced
- [x] Secrets in environment
- [x] Audit logging

## 📊 Current Status

### Tests
- **Backend**: 92/160 passing (57.5%) - Firebase init issue
- **Frontend**: 29/31 passing (93.5%)
- **Integration**: 10 scenarios created, not executed

### Active Agents
- ✅ **Test Runner**: Running continuously (every 60s)
- ✅ **Backend Guardian**: Monitoring code quality
- ✅ **Frontend Polish**: UI/UX checks
- ✅ **Security Audit**: Vulnerability scanning
- ✅ **Performance Optimizer**: Query analysis
- ✅ **Docs Keeper**: Documentation maintenance

### Priorities
1. ✅ Fix Firebase lazy loading (all handlers)
2. ✅ Add widget Keys for tests (3 screens)
3. ✅ Webhook security hardening (PRODUCTION READY)
4. ✅ Database optimization (-90% reads, $162/month saved)
5. ⏳ Execute integration tests (needs seller@origna.ca)
6. ⏳ Fix remaining 68 backend test failures
7. ⏳ Deploy to production at orignagta.ca

---

## 🧪 Testing in Production

**Safe to test at orignagta.ca** (no clients yet).

### Chrome Extension Workflow
1. Open Chrome DevTools
2. Use Flutter DevTools for widget inspection
3. Test workflows:
   - User registration/login
   - Product creation (10 variants)
   - Checkout flow
   - Payment processing
   - Order management

### Iteration Process
```bash
# 1. Test in production
# Open: https://orignagta.ca
# Use: seller@origna.ca / Test123456!

# 2. Find issues
# Check console errors, network failures

# 3. Fix locally
# Edit code, run tests

# 4. Deploy immediately
/deploy production

# 5. Verify fix
# Re-test in production

# 6. Iterate until perfect
# Repeat steps 1-5
```

### UI/UX Testing Checklist
- [ ] Mobile responsive (320px, 480px, 768px, 1024px+)
- [ ] Touch targets (48x48 minimum)
- [ ] Loading states
- [ ] Error messages
- [ ] Empty states
- [ ] Success feedback
- [ ] Accessibility (screen reader, keyboard nav)

---

## 🔧 Key Patterns

### Backend Lazy Loading
```python
_db = None

def get_db():
    global _db
    if _db is None:
        from firebase_admin import firestore
        _db = firestore.client()
    return _db

# Use: get_db().collection('products')
```

### Frontend Keys
```dart
import 'package:origna_gta/utils/test_keys.dart';

TextFormField(
  key: ValueKey(TestKeys.productNameField),
  // ...
)
```

### Input Validation
```python
from utils import sanitized_text, sanitize_path

clean_name = sanitized_text(product_name)
safe_path = sanitize_path(file_path)
```

## 📁 Critical Files

```
functions/
├── handlers/          # Backend modules
├── utils/validation.py # Security utils
├── tests/conftest.py  # Test fixtures
└── main.py

origna_gta/lib/
├── features/         # MVVM modules
├── core/repositories/ # Data layer
├── utils/test_keys.dart
└── models/models.dart

.claude/              # Agent configs
firestore.rules       # Security
```

## 🚀 Quick Commands

```bash
# Backend tests
cd functions && pytest tests/ -v

# Frontend tests  
cd origna_gta && flutter test

# Integration tests
cd origna_gta && flutter test integration_test/

# Deploy
firebase deploy --only functions,hosting
```

## 💡 Architecture Principles

1. **MVVM Pattern** - ViewModels manage state
2. **Repository Pattern** - Abstract data access
3. **Lazy Loading** - Initialize on first use
4. **Feature Folders** - Group by domain
5. **Fail Fast** - No secret fallbacks
6. **Test Everything** - 80%+ coverage goal

## 📚 Documentation

- Architecture: `ARCHITECTURE_AUDIT_FINAL.md`
- Security: `SECURITY_AUDIT_2026_01_31.md`
- Tests: `COMPREHENSIVE_TESTS_DOCUMENTATION.md`
- Integration: `origna_gta/integration_test/README.md`

---

**Version**: 2.0.0  
**Last Updated**: 2026-02-03  
**Scale Target**: 100M+ users/year
