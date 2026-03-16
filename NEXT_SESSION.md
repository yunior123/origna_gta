# Next Session Instructions — origna_gta (2026-03-16)

## State at end of this session

### Flutter tests
- **Unit/widget**: 2360 passing, 0 failing, 73 skipped
- **Coverage**: 86.8% (target: 90%) — 3.2 pts to go
- **Live tests**: 25 files in `test/live/`, last run: 57 pass / 55 fail

### Rust tests
- ~16 new integration test files in `crates/orignabase/tests/`
- Not yet run against live server

---

## Priority 1 — Grant roles to dev test accounts (10 min)

SSH to VPS and fix live test accounts so 55 failing tests pass:

```bash
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16
docker exec -it orignabase-surrealdb-1 surreal sql \
  --conn http://localhost:8000 \
  --user root --pass orignabase_root_2026 \
  --ns orignabase --db production

-- Run these in SurrealDB:
UPDATE users:9w0xa6lkt9f4oglea65c SET roles = ['admin','buyer'];
UPDATE users:lvoqmdam21bhaxd2fjgi SET roles = ['seller','buyer'];
```

Then re-run live tests — should jump from 57→90+ pass:
```bash
cd origna_gta/origna_gta
/Users/yuniorrodriguezosorio/flutter/bin/flutter test test/live/ \
  --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=dev \
  --dart-define=ORIGNABASE_URL=https://api.dev.orignagta.ca \
  --no-pub --reporter=compact
```

---

## Priority 2 — Push coverage from 86.8% → 90%

Biggest gaps (attack in order):

| File | Current | Missed lines | Action |
|------|---------|-------------|--------|
| `lib/features/support/support_viewmodel.dart` | 17.7% | 130 | Add real ViewModel tests with fake Anthropic client |
| `lib/utils/utils.dart` | 73.8% | 80 | Add tests for uncovered helper functions |
| `lib/core/repositories/orignabase_auth_repository.dart` | 69.3% | 66 | Add Google/Apple signIn tests (platform guards) |
| `lib/features/qa/orignabase_qa_repository.dart` | 37.5% | 35 | Test all methods with fake OrignaBase |
| `lib/core/providers.dart` | 45.2% | 34 | Add provider chain tests |

**Measure coverage** (full suite, NOT single file):
```bash
cd origna_gta/origna_gta
/Users/yuniorrodriguezosorio/flutter/bin/flutter test --coverage --no-pub
# Then parse:
python3 -c "
total=0; covered=0
for l in open('coverage/lcov.info'):
    if l.startswith('DA:'):
        total+=1
        if int(l.split(',')[1])>0: covered+=1
print(f'{covered}/{total} = {covered/total*100:.1f}%')
"
```

---

## Priority 3 — Run Rust integration tests

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/orignabase

# Start SurrealDB + OrignaBase (if not running):
# docker compose -f docker/docker-compose.yml up -d

# Run new tests:
cargo test --test auth_repository_test -- --ignored
cargo test --test user_repository_test -- --ignored
cargo test --test product_repository_test -- --ignored
cargo test --test cart_repository_test -- --ignored
cargo test --test order_repository_test -- --ignored
cargo test --test order_lifecycle_test -- --ignored
cargo test --test search_integration_test -- --ignored
```

---

## Key facts for next session

### Dev server accounts
| Role | Email | Password | SurrealDB ID |
|------|-------|----------|-------------|
| Admin | e2e-admin@test.origna.ca | REDACTED_TEST_PASSWORD | users:9w0xa6lkt9f4oglea65c |
| Seller | e2e-seller@test.origna.ca | REDACTED_TEST_PASSWORD | users:lvoqmdam21bhaxd2fjgi |
| Buyer | e2e-buyer@test.origna.ca | REDACTED_TEST_PASSWORD | users:itdb9cyp3nu45owy4bo1 |

> ⚠️ Gmail/Yahoo emails BLOCKED on dev (domain validation). Always use `@test.origna.ca` for new test accounts.

### Live test failures — root causes
1. **403 Permission denied** — roles not in SurrealDB JWT claims (fix: Priority 1 above)
2. **400 on signInWithEmail** — `OrignaBaseAuthRepository._createUserDocumentIfNeeded` called after login, throws 400 when profile already exists but error not suppressed correctly
3. **422 missing field `userId`** — some test payloads use wrong field name (check `Fields.userId` vs `Fields.uid`)

### Flutter test fake pattern (works without build_runner)
```dart
class _FakeOrignaBase extends Fake implements OrignaBase {
  @override
  Future<dynamic> request(String method, String path, {Map<String, dynamic>? body, Map<String, String>? headers}) async {
    return {'success': true};
  }
  @override
  OrignaBaseAuth get auth => _fakeAuth;
  @override
  CollectionReference collection(String name) => _FakeCollectionRef();
  @override
  String get url => 'https://api.test.origna.ca';
}
```

### DO NOT
- Run `flutter test --coverage` on a single file — it overwrites lcov.info and destroys full coverage report
- Let coverage booster agents append to test files without reading current file end — causes parse errors
- Use `@GenerateMocks` without running `build_runner` (breaks compilation)

---

## What was done this session (for git log context)
- Added 55-test auth repo impl file (`orignabase_auth_repository_impl_test.dart`)
- Added 25 Dart live test files in `test/live/`
- Added ~16 Rust integration test files in `crates/orignabase/tests/`
- Fixed broken test files: deleted `support_viewmodel_expanded_test.dart`, trimmed `auth_provider_test.dart`
- Seeded 3 dev test accounts with profiles
- Replaced all live test files' gmail/yahoo emails with `@test.origna.ca` accounts
