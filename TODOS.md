# TODOS.md — Reusable Execution Runbook

This file is the reusable execution checklist.

`STATE.md` is the evidence ledger.
Record every completed, blocked, or verified checkpoint in `STATE.md` immediately after evidence exists.

## Core Rules

- [ ] Never mark work done without test, live, or capture evidence.
- [ ] Save long-running command output to `/tmp/...`.
- [ ] Keep backend live validation ahead of Flutter live validation.
- [ ] Keep Flutter live validation ahead of browser/E2E capture.
- [ ] Keep browser/E2E capture ahead of screenshot rename/delete cleanup.
- [ ] Start load, stress, reliability, and benchmark work only after live and E2E are stable.
- [ ] Reseed dev/local as often as needed; do not preserve bad seed state.
- [ ] Fix root causes instead of silencing failures.
- [ ] Monitor VPS RAM, disk, rebuild progress, and container health during backend work.
- [ ] Kill stale local heavy processes before starting new heavy work.
- [ ] Dont be lazy, work, go the extra mile if needed
- [ ] When auditing the codebase do it as an outsider
- [ ] Document as you fix
- [ ] Deploy all then use agent-browser to test the changes
- [ ] Live tests are mandatory, do not skip them
- [ ] No sql injection

## Definition Of Done

A task is done only when all are true:

- [ ] Code or config is updated if needed.
- [ ] Relevant tests, live checks, or captures pass.
- [ ] New warnings introduced by the change are fixed.
- [ ] `STATE.md` records the result, evidence, and next blocking impact.

## Execution Order

1. [ ] Execute the current backend live wave.
2. [ ] Execute Flutter live only after backend live is stable.
3. [ ] Execute E2E and browser/design capture only after deploy and seed state are stable.
4. [ ] Execute screenshot/name audit only after manifest-driven capture is in place.
5. [ ] Execute reliability, load, stress, benchmarks, and example apps only after live and E2E are green.

Use `STATE.md` to determine the current active gate inside this order.

## Phase 0 — Control Plane

- [ ] Keep `STATE.md` current and compressed.
- [ ] Keep this file ordered; update existing items instead of appending duplicates.
- [ ] Keep `.claude/harness/` aligned with the active wave when using harness-loop.
- [ ] Monitor VPS health:
  - [ ] `docker compose ps`
  - [ ] memory / swap
  - [ ] disk / docker image growth
  - [ ] rebuild progress
- [ ] Monitor local RAM and clear zombie `flutter_test`, Chrome, agent-browser, Cargo, and stale dev servers before heavy runs.

## Phase 1 — Backend Live First

### 1A. VPS / Runtime Stability

- [ ] Confirm the newest intended dev/staging/prod images are actually running.
- [ ] Verify the current target health endpoints:
  - [ ] API dev health
  - [ ] API staging health
  - [ ] production app/backend health route behavior
- [ ] Confirm all required containers are healthy after restart or rebuild.
- [ ] Clean only safe old Docker artifacts when rebuilds are idle.

### 1B. Rust Live Test Wave

Run backend live files in priority order and fix as needed:

- [ ] smoke
- [ ] security/payment/storage/search/shipping/order/returns/reliability/stress core wave
- [ ] admin and other live-only ignored suites
- [ ] remaining `crates/orignabase/tests/*.rs` files that exercise live/dev behavior
- [ ] re-run any suite whose previous pass tolerated an error or depended on a stale assumption

### 1C. Backend Quality Gates

- [ ] `cargo clippy -D warnings`
- [ ] `cargo test`
- [ ] Fix real warnings instead of suppressing them.
- [ ] Run Stripe webhook CLI verification against current backend behavior using a metadata path that matches production expectations.
- [ ] Keep Flutter live blocked until backend webhook verification is green.

## Phase 2 — Flutter Live After Backend

- [ ] Ensure the active OrignaBase target is healthy and correctly seeded.
- [ ] Run Flutter live tests with `RUN_ORIGNABASE_LIVE_TESTS=true`.
- [ ] Fix live failures before broader UI audit.
- [ ] Run `flutter analyze --no-fatal-infos`.
- [ ] Run impacted unit/widget suites after live fixes.
- [ ] Fix analyzer warnings and test regressions introduced during the wave.

## Phase 3 — E2E And Design Capture

### 3A. Deterministic Seed

- [ ] Seed representative sample data, including image and video coverage where needed.
- [ ] Ensure major buyer, seller, and admin views have intended non-empty states.
- [ ] Ensure required test accounts exist, are usable, and match the current test manifest.
- [ ] Re-seed whenever drift invalidates a live or capture result.

### 3B. Browser / E2E

- [ ] Run E2E smoke first.
- [ ] Run remaining E2E phases in order.
- [ ] Fix failures instead of documenting them as expected.
- [ ] Exercise required email-triggering flows for the test accounts in scope.
- [ ] Save outputs to `/tmp/...` and summarize verified results in `STATE.md`.

### 3C. Screenshot / Naming Audit

- [ ] Use a manifest-driven capture source of truth.
- [ ] Enforce `filename -> persona -> route -> seeded state -> required anchors`.
- [ ] Save screenshots to the agreed output location.
- [ ] Audit filename/content alignment.
- [ ] Rename mismatches only after verification.
- [ ] Delete true duplicates only after verification.
- [ ] Re-run captures after each navigation or seed fix until the set is trustworthy.

### 3D. Full Design Audit

- [ ] Audit every major view, widget family, variant, and state.
- [ ] Cover desktop and mobile layouts.
- [ ] Audit full-page screenshots, not only top-of-screen captures.
- [ ] Check beginning, middle, and end states for long scrolling views.
- [ ] Record verified findings and fixes in `STATE.md`.

## Phase 4 — Codebase Audits And Fixes

### 4A. Magic Strings

- [ ] Audit Rust runtime magic strings file by file.
- [ ] Audit Dart runtime magic strings file by file.
- [ ] Replace contract strings, route fragments, persisted status values, and payload keys with shared constants or enums.
- [ ] Prioritize hotspots already verified in `STATE.md`, then expand outward.
- [ ] Fix warnings and todos in vscode panel

### 4B. Auth / Payments / Webhooks / Infra

- [ ] Audit auth end to end in backend and frontend using the current project skills/runbooks where relevant.
- [ ] Audit Stripe checkout, Connect, payouts, refunds, and webhook handling using real seller-account state.
- [ ] Improve localhost test configuration for PostgreSQL, Meilisearch, Stripe CLI, Flutter, and OrignaBase.
- [ ] Reinforce Rust and Dart error code / error handling quality.
- [ ] Review environment handling for localhost, dev, staging, and prod against current repo reality.
- [ ] Apply infra/security findings conservatively and only after verification.

### 4C. Unwired / Incomplete Features

- [ ] Audit for unwired features, stale TODOs, dead paths, and incomplete integrations.
- [ ] Add only validated findings to `STATE.md`.

## Phase 5 — Reliability, Load, Stress, Benchmarks, Example Apps

Start only after Phases 1 through 3 are stable.

- [ ] Run all example app tests.
- [ ] Clean generated artifacts and stale processes after example app runs.
- [ ] Run reliability tests.
- [ ] Run load tests.
- [ ] Run stress tests.
- [ ] Run benchmarks.
- [ ] Record commands, pass/fail counts, and bottlenecks in `STATE.md`.

## Phase 6 — Coverage And Documentation

- [ ] Push Rust and Flutter coverage higher only after live-path correctness is stable.
- [ ] Prioritize tests that exercise localhost/dev integrations over shallow unit-only gains.
- [ ] Document functions, classes, systems, and tricky flows that caused repeated drift or confusion.
- [ ] Search current best practices before final docs for complex systems.
- [ ] Improve weak runbooks/skills that caused avoidable churn during the wave.

## Delegation Rules

- [ ] Delegate bounded audits and disjoint implementation work when appropriate.
- [ ] Verify delegated findings locally before escalating them into `STATE.md`.
- [ ] Prefer existing local skills/runbooks over noisy ad hoc workflows.
- [ ] Do not let delegated work bypass local verification.

## Parking Lot

- [ ] Study repo/process improvements that materially reduce repeat failures.
- [ ] Explore additional AI/model feedback loops for UI/UX review only if they improve verified output quality.
- [ ] Revisit app-update prompting and other future enhancements after the active delivery gates are green.
- [ ] improve flutter app lifecycle events handling, search web, github for examples for e-commerce app
- [ ] fix todos, warnings in vscode panel
- [ ] improve e2e api tests, add more live tests, run them all
- [ ] use them all for full audit:/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/.claude/skills
- [ ] improve previews, cover all gaps
- [ ] audit and improve skills, claude.md, agents.md, etc
- [ ] track all notes in app and make sure all is wired
- [ ] increase number of live tests, cover more gaps, do it for rust and flutter, search web in depth to do it like a pro
- [ ] increase number of e2e visual tests, cover all gaps, execute them, debug, fix ui ux errors or issues
- [ ] after a fix then add 5+ tests to prevent the same issue from happening, also add inline docs for it
- [ ] use strong pro try catch that log the errors to sentry or logs collection. use modern tecniques, search web for rust and flutter best practices
- [ ] make sure db is replaceable using hexagonal architecture
- [ ] orignabase rules should be as strong as firebase rules
- [ ] orignabase queries should be similar to firebase
- [ ] fix gaps with previews, right now it shows only empty state in some views.