# Master Plan — OrignaGTA Full Audit, Tests, Seed, Coverage, Documentation (2026-03-23)

## Context

The project has a mature codebase (Flutter frontend + Rust backend) with extensive tests, but many live tests are skipped, coverage is below 95%, the seed script has gaps, documentation is incomplete, and several audits remain pending. This plan addresses all 19 items from the user's request plus MEMORY.md creation.

**Current state (from STATE.md):**
- Rust: 3,228 pass, 0 fail, 0 skip
- Flutter: 3,986 pass, 2 live fail (expected), 146 skip (without live flag)
- Flutter (live): 4,953 pass, 0 fail
- OrignaBase SDK: 538 pass, 0 fail, 0 skip
- E2E: 112 spec files across 6 phases
- Seed: 2400+ products but gaps in disputes, coupons, MFA, multi-user favorites

---

## Phase 0: MEMORY.md Creation + Cleanup (Immediate)

### Step 0.1: Create `MEMORY.md` at project root
Create a concise (<200 lines) MEMORY.md following Claude Code best practices:
- **What it contains:** Learnings, patterns, decisions (NOT instructions — that's CLAUDE.md)
- **Structure:** Project context, tech stack summary, key decisions log, common pitfalls, current status, VPS/env info
- **Sections:** Identity, Architecture, Decisions, Pitfalls, Current State, Quick Reference
- **Reference:** https://code.claude.com/docs/en/memory

### Step 0.2: Clean build artifacts
- Run `cargo clean` in `orignabase/` to free disk space
- Run `flutter clean` in `origna_gta/` to free disk space
- Clean `orignabase/target/` subdirectories (dev, test, coverage, release)

---

## Phase 1: Run All Live Tests (Backend + Frontend)

### Step 1.1: OrignaBase Rust — all tests
```bash
cd orignabase && cargo clippy -D warnings 2>&1 | tee /tmp/rust-clippy-results.txt
cargo test --workspace 2>&1 | tee /tmp/rust-test-results.txt
```
- Fix any clippy warnings
- Fix any test failures
- Run live tests if server is available: `OB_TEST_URL=http://localhost:8080 cargo test --workspace`

### Step 1.2: Flutter — all tests (non-live)
```bash
cd origna_gta && flutter analyze --no-fatal-infos 2>&1 | tee /tmp/flutter-analyze-results.txt
flutter test --exclude-tags golden 2>&1 | tee /tmp/flutter-test-results.txt
```
- Fix all analyze warnings
- Fix any test failures (note: 6 `edit_product_viewmodel_test` failures from parallel WIP changes)

### Step 1.3: Flutter — live tests (with OrignaBase backend)
```bash
flutter test --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true --dart-define=ENVIRONMENT=dev --exclude-tags golden 2>&1 | tee /tmp/flutter-live-test-results.txt
```
- Ensure OrignaBase backend is running (VPS or local)
- Fix any live test failures
- Remove "skip" annotations where tests now pass

### Step 1.4: OrignaBase SDK tests
```bash
cd orignabase/sdks/flutter/orignabase && flutter test 2>&1 | tee /tmp/sdk-test-results.txt
```

### Step 1.5: Clean artifacts after tests
```bash
cd orignabase && ./scripts/clean_rust_artifacts.sh
cd origna_gta && flutter clean
```

---

## Phase 2: Run E2E Tests

### Step 2.1: Ensure backend is running
- Check if OrignaBase is running on VPS (api.dev.orignagta.ca) or locally
- If not, start it or note as blocker

### Step 2.2: Run E2E API tests
```bash
cd e2e && bun test specs/phase1-api/ 2>&1 | tee /tmp/e2e-api-results.txt
```
- Fix any failures

### Step 2.3: Run E2E browser tests (sequential, 8GB RAM constraint)
```bash
bun test specs/phase2-smoke/ 2>&1 | tee /tmp/e2e-smoke-results.txt
bun test specs/phase3-auth-nav/ 2>&1 | tee /tmp/e2e-auth-results.txt
bun test specs/phase4-product-flows/ 2>&1 | tee /tmp/e2e-products-results.txt
bun test specs/phase5-complex-flows/ 2>&1 | tee /tmp/e2e-flows-results.txt
bun test specs/phase6-stripe/ 2>&1 | tee /tmp/e2e-stripe-results.txt
```
- Kill orphan Chrome processes before each phase: `pkill -f "chrome.*--remote-debugging"`
- Fix failures as they arise

### Step 2.4: TypeScript check
```bash
cd e2e && bun x tsc --noEmit 2>&1 | tee /tmp/e2e-tsc-results.txt
```

---

## Phase 3: Improve Mega Seed (2000+ products, all states)

### Step 3.1: Fill seed gaps in `e2e/lib/seed-dev.ts`
Current gaps to fill:
- **Disputes:** Add `seedDisputes()` — create 10+ dispute records
- **Coupons:** Add `seedCoupons()` — create 15+ coupons (percentage, fixed, free shipping, expired, max-uses-reached)
- **Download sessions:** Add `seedDownloadSessions()` for digital products
- **Multi-user favorites:** Seed favorites for 5+ buyer accounts
- **Multi-user addresses:** Seed addresses for 5+ buyer accounts
- **Multi-user cart:** Seed cart items for 3+ buyer accounts
- **Multi-user notifications:** Seed notifications for 5+ accounts
- **MFA settings:** Seed MFA enrollment for admin + seller accounts
- **Seller review answers:** Seed seller replies to reviews
- **Stock notifications:** Seed for 10+ product/user combinations
- **User preferences:** Seed preferredCurrency, timezone, theme
- **Promotions:** Seed 5+ promotion records
- **Suspended users:** Add suspended sellers
- **Expired/cancelled subscriptions:** Add trial, payment-failed, grace-period states

### Step 3.2: Ensure all products have images
- Verify `sampleImageUrls()` covers all 2400+ products
- Add variant images where missing
- Use `picsum.photos/seed/{id}` pattern consistently

### Step 3.3: Run seed against VPS
```bash
cd e2e && bun run lib/seed-dev.ts 2>&1 | tee /tmp/seed-results.txt
```

### Step 3.4: Verify all views have non-empty state
- Favorites view, Seller dashboard, Admin dashboard, Addresses, Notifications, Chat, Return requests, Disputes, Coupons

---

## Phase 4: Coverage 95+ (Rust + Flutter)

### Step 4.1: Rust coverage
```bash
cd orignabase && ./scripts/coverage.sh --html 2>&1 | tee /tmp/rust-coverage-results.txt
```
- Identify uncovered code paths
- Add tests for uncovered handlers, edge cases, error paths
- Priority: live integration tests over unit tests
- Fix all clippy warnings

### Step 4.2: Flutter coverage
```bash
cd origna_gta && flutter test --coverage --exclude-tags golden 2>&1 | tee /tmp/flutter-coverage-results.txt
lcov --summary coverage/lcov.info
```
- Identify uncovered files (ViewModels, Services, Repositories)
- Add tests for uncovered paths
- Run quality gate: `./scripts/run_quality_gate.sh`
- Increase threshold to 95% in quality gate script

### Step 4.3: Fix all warnings
- Rust: `cargo clippy -D warnings` — fix ALL
- Flutter: `flutter analyze --no-fatal-infos` — fix ALL
- No suppressions, no `// ignore` comments

---

## Phase 5: Example Apps Tests

### Step 5.1: Todo app example
```bash
cd orignabase/examples/todo-app && bash test.sh 2>&1 | tee /tmp/todo-example-results.txt
```

### Step 5.2: Chat app example
- No test script exists — create if needed, or skip with note

### Step 5.3: Flutter SDK examples
- Verify they compile: `cd orignabase/sdks/flutter/orignabase && dart analyze example/`

### Step 5.4: Clean after done
```bash
cd orignabase && ./scripts/clean_rust_artifacts.sh
cd origna_gta && flutter clean
```

---

## Phase 6: Stripe Webhook Audit (CLI)

### Step 6.1: Audit test mode webhooks
```bash
source orignabase/scripts/stripe-cli-env.sh --test
stripe listen --forward-to http://localhost:8080/api/webhooks/stripe
stripe trigger checkout.session.completed
stripe trigger charge.dispute.created
stripe trigger checkout.session.expired
# ... all 13 configured events
```

### Step 6.2: Audit live mode webhooks
- Verify prod webhook endpoint via Stripe Dashboard or CLI

### Step 6.3: Verify webhook handling
- Check logs, idempotency, replay protection

---

## Phase 7: Load/Stress/Reliability Tests

### Step 7.1: k6 load tests
```bash
cd orignabase && k6 run load-tests/k6/mixed-workload.js 2>&1 | tee /tmp/k6-load-results.txt
k6 run stress-tests/k6/large-payloads.js 2>&1 | tee /tmp/k6-stress-results.txt
```

### Step 7.2: Rust benchmarks
```bash
cd orignabase && cargo bench --bench core_benchmarks 2>&1 | tee /tmp/rust-bench-results.txt
cargo bench --bench throughput_bench 2>&1 | tee /tmp/rust-throughput-bench-results.txt
```

### Step 7.3: Reliability/chaos tests
```bash
cd orignabase && bash reliability-tests/chaos/kill-surrealdb.sh 2>&1 | tee /tmp/chaos-surrealdb-results.txt
bash reliability-tests/chaos/kill-meilisearch.sh 2>&1 | tee /tmp/chaos-meilisearch-results.txt
```

### Step 7.4: Rust stress/integration tests
```bash
cd orignabase && cargo test --test stress_test 2>&1 | tee /tmp/rust-stress-results.txt
cargo test --test reliability_test 2>&1 | tee /tmp/rust-reliability-results.txt
```

---

## Phase 8: Codebase Documentation (10+ Parallel Agents)

### Step 8.1: Document with parallel agents
- Agent 1: `orignabase/` architecture (crates, data flow, API surface)
- Agent 2: `origna_gta/lib/` architecture (MVVM, providers, services)
- Agent 3: E2E test architecture (phases, helpers, patterns)
- Agent 4: Deployment pipeline (CI/CD, scripts, VPS config)
- Agent 5: Auth system (JWT, MFA, OAuth, session management)
- Agent 6: Payment system (Stripe, Connect, webhooks, refunds)
- Agent 7: Search system (Meilisearch, indexing, sync)
- Agent 8: Realtime system (WebSocket, subscriptions, NATS)
- Agent 9: Seed/data system (scripts, schemas, test data)
- Agent 10: SDK (Flutter SDK, API surface, examples)

### Step 8.2: Key decisions to document
- Image compression pattern evolution
- Money handling: double → int cents
- Auth: Firebase → OrignaBase
- State: setState → Riverpod

---

## Phase 9: Full Codebase Audit (30+ Agents)

### Step 9.1: Security audit (5 agents)
- Auth system, API security, data protection, infrastructure, dependencies

### Step 9.2: Architecture audit (5 agents)
- MVVM compliance, Riverpod patterns, error handling, state management, performance

### Step 9.3: Code quality audit (5 agents)
- Code duplication, naming conventions, imports, dead code, test quality

### Step 9.4: UX/accessibility audit (5 agents)
- Semantics labels, design tokens, localization, responsive design, error/empty states

### Step 9.5: Backend audit (5 agents)
- GraphQL schema, SurrealDB queries, webhooks, search indexing, realtime

### Step 9.6: DevOps audit (5 agents)
- CI/CD, Docker, Caddy, backup/recovery, monitoring

### Step 9.7: Validate findings
- Cross-reference, eliminate false positives, add to STATE.md

---

## Phase 10: Auth System Audit (Deep)

### Step 10.1: Audit auth flows
- Registration, login, JWT issuance/refresh, MFA, session timeout, password reset, RBAC

### Step 10.2: Audit auth security
- Argon2id params, JWT key rotation, rate limiting, brute force protection, token storage

### Step 10.3: Document findings in STATE.md

---

## Phase 11: Final Cleanup + Loose Ends

### Step 11.1: Clean all build artifacts
```bash
cd orignabase && ./scripts/clean_rust_artifacts.sh
cd origna_gta && flutter clean
```

### Step 11.2: Update STATE.md + TODOS.md

### Step 11.3: Verify no loose ends

---

## Blockers (to track in STATE.md)

| Blocker | Impact | Mitigation |
|---------|--------|------------|
| OrignaBase backend must be running for live tests | Cannot run live/E2E tests | Start local or use VPS |
| 8GB RAM constraint | Limits parallel Chrome | Sequential, concurrency=4 max |
| 6 `edit_product_viewmodel_test` failures | Parallel WIP changes | Fix or regenerate mocks |
| Stripe CLI requires login | Cannot audit webhooks | `stripe login` first |

---

## Execution Order

1. Phase 0: MEMORY.md + cleanup (5 min)
2. Phase 1: All tests (30-60 min)
3. Phase 2: E2E tests (30-60 min)
4. Phase 3: Seed improvements (30-60 min)
5. Phase 4: Coverage to 95+ (60-120 min)
6. Phase 5: Example apps (15 min)
7. Phase 6: Stripe webhook audit (30 min)
8. Phase 7: Load/stress/benchmarks (30 min)
9. Phase 8: Documentation (60 min, parallel)
10. Phase 9: Full audit (60 min, parallel)
11. Phase 10: Auth audit (30 min)
12. Phase 11: Final cleanup (15 min)

**Estimated total: 6-10 hours**

## Verification

- `cargo test --workspace` → 0 failures
- `flutter test --exclude-tags golden` → 0 failures
- Coverage: Rust 95%+, Flutter 95%+
- No warnings in either codebase
- MEMORY.md created and concise
- STATE.md updated with all findings
