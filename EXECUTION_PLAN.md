# Execution Plan — 15 Tasks / 5 Parallel Workstreams

> Generated: 2026-03-30 | All workstreams run simultaneously

---

## Dependency Graph

```
WS1 (Testing)  ──→  coverage target needs passing tests first
WS2 (Security)  ──→  independent, can start immediately
WS3 (Docs/State) ──→  independent, can start immediately
WS4 (Design/UX)  ──→  depends on WS1 live tests passing for screenshots
WS5 (Infra/Perf) ──→  depends on WS1 passing + WS2 auth audit done
```

---

## WS1 — Testing & Quality Gates

| # | Task | Effort | Priority | Depends On |
|---|------|--------|----------|------------|
| 1 | Run all live tests (backend + frontend), fix failures | **L (4-6h)** | P0 | — |
| 4 | Increase test coverage to 95%+ | **XL (8-12h)** | P1 | Task 1 |
| 14 | Fix all remaining warnings (analyze + clippy) | **M (2-4h)** | P1 | Task 1 |
| 2 | Run E2E tests all phases (agent-browser) | **L (4-6h)** | P1 | Task 1 |

**Total effort: ~18-28h**
**Execution order:** 1 → [4, 14] → 2
**Key commands:**
- `flutter analyze --no-fatal-infos && flutter test --exclude-tags golden`
- `cd ../orignabase && cargo clippy -D warnings && cargo test`
- `cd e2e-agent-browser && bun test specs/phase{1,2,3}/`
- Coverage: `flutter test --coverage`, then fill gaps

---

## WS2 — Security & Compliance Audits

| # | Task | Effort | Priority | Depends On |
|---|------|--------|----------|------------|
| 5 | Audit auth system (JWT, MFA, rate limiting, OAuth) | **L (4-6h)** | P0 | — |
| 9 | Audit Stripe webhooks (idempotency, amount integrity, Connect) | **L (4-6h)** | P0 | — |
| 10 | Audit all 10+ app flows (checkout, cart, orders, shipping…) | **XL (8-12h)** | P1 | Tasks 5, 9 |
| 6 | Audit full codebase with 30+ agents (swarm) | **XL (8-12h)** | P2 | Tasks 5, 9, 10 |

**Total effort: ~24-36h**
**Execution order:** [5, 9] → 10 → 6
**Key skills:** `/auth-coverage-audit`, `/stripe-audit`, `/flow-audit`, `/pentest-swarm`

---

## WS3 — Documentation & State Management

| # | Task | Effort | Priority | Depends On |
|---|------|--------|----------|------------|
| 13 | Resume and compress STATE.md | **S (1-2h)** | P0 | — |
| 7 | Document codebase (classes, functions, architecture) | **L (4-6h)** | P1 | Task 13 |
| 15 | Reseed DB for all variants/states (products, orders, users) | **M (2-4h)** | P1 | Task 13 |

**Total effort: ~7-12h**
**Execution order:** 13 → [7, 15]
**Key notes:**
- STATE.md first — it gates context for all other work
- DB reseed covers: all product categories, order states (pending→delivered), variant combos
- Docs: update ARCHITECTURE.md, inline dartdoc for public APIs

---

## WS4 — Design & UX Quality

| # | Task | Effort | Priority | Depends On |
|---|------|--------|----------|------------|
| 11 | Audit 305 screenshot filenames vs content | **M (2-4h)** | P1 | — |
| 12 | Full design audit with agent-browser (visual QA) | **L (4-6h)** | P1 | WS1 Task 1 |
| 3 | Improve dev seed with sample images/videos for all views | **M (2-4h)** | P2 | WS3 Task 15 |

**Total effort: ~8-14h**
**Execution order:** [11] → 12 → 3
**Key skills:** `/design-review`, `/browse`, `/qa`
**Notes:**
- Screenshot audit is independent — can start immediately
- Design audit needs live app (depends on WS1 tests passing)
- Seed images need DB reseed done first

---

## WS5 — Infrastructure & Performance

| # | Task | Effort | Priority | Depends On |
|---|------|--------|----------|------------|
| 8 | Run load/stress/reliability tests | **L (4-6h)** | P2 | WS1 Task 1, WS2 Task 5 |

**Total effort: ~4-6h**
**Execution order:** Wait for WS1 + WS2 auth audit
**Key notes:**
- OrignaBase: k6 or wrk against `/graphql` endpoint
- Flutter web: Lighthouse + Core Web Vitals baseline
- Stress: concurrent checkout, stock race conditions, webhook flood
- Use `/benchmark` skill for performance baselines

---

## Priority Matrix

| Priority | Tasks | Why |
|----------|-------|-----|
| **P0 — Do First** | 1 (live tests), 5 (auth audit), 9 (stripe audit), 13 (STATE.md) | Gates everything else — no point auditing broken code |
| **P1 — Do Next** | 4 (coverage), 14 (warnings), 2 (e2e), 10 (flows), 7 (docs), 15 (reseed), 11 (screenshots), 12 (design audit) | Quality + documentation + UX |
| **P2 — Do Last** | 6 (30+ agent swarm), 3 (seed images), 8 (load tests) | Polish + stress — needs stable base |

---

## Timeline (Solo Agent)

| Phase | Duration | Workstreams Active |
|-------|----------|--------------------|
| **Phase 1** (Day 1) | 8h | WS1[Task1], WS2[Tasks5,9], WS3[Task13], WS4[Task11] |
| **Phase 2** (Day 2) | 8h | WS1[Tasks4,14], WS2[Task10], WS3[Tasks7,15], WS4[Task12] |
| **Phase 3** (Day 3) | 8h | WS1[Task2], WS2[Task6], WS4[Task3], WS5[Task8] |

**Total: ~3 days solo / ~1.5 days with subagents**
