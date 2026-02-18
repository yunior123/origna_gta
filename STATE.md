# PLAN: Token optimization + performance audit + push to main

## Scope
- Files to modify: `MEMORY.md`, `functions/services/airwallex_service.py`, `functions/services/algolia_service.py`, `functions/ruff.toml`, `functions/requirements-dev.txt`, backend handler files (performance), Riverpod provider files (performance)
- Files to create: none
- Tests to update: none (improvements only)

---

## Phase 1: Token Optimization (AI context)

**Goal:** MEMORY.md under 100 lines with only what's NOT already in LEARNED.md or CLAUDE.md.

- [ ] Trim MEMORY.md — remove content duplicated in CLAUDE.md (env tables, quick commands, gotchas already in KEY GOTCHAS section)
- [ ] Keep: test account UIDs/emails, critical bugs with non-obvious fixes, unique E2E patterns
- [ ] Move bulk content to LEARNED.md sections already there
- [ ] Target: ~80 lines in MEMORY.md

**What to cut from MEMORY.md (already in CLAUDE.md or LEARNED.md):**
- Environment table (in CLAUDE.md and LEARNED.md)
- Quick commands (in CLAUDE.md)
- All "Audit Fixes" sections (verbatim in LEARNED.md)
- E2E test tips (verbatim in LEARNED.md)

**What to keep in MEMORY.md (genuinely cross-session critical):**
- Critical bug fixes with non-obvious patterns (authtype patch, webhook secret shadow)
- Schema contract table (timestamp field names per collection)
- Key conventions (cents, stockQuantity, signIn returns idToken, etc.)
- Test account table (email/UID/password)
- Most critical audit fix summaries (1 line each)

---

## Phase 2: Performance Audit & Improvements

### Backend
- [ ] Fix 2 UP007 ruff violations (auto-fix in airwallex_service.py, algolia_service.py)
- [ ] Scan orders.py for N+1 Firestore reads (document reads inside loops)
- [ ] Scan cron_jobs.py for sequential awaits that could be `asyncio.gather()`
- [ ] Scan payment_stripe.py for redundant document reads
- [ ] Check cold start: are imports at module level minimal?

### Frontend
- [ ] Scan providers for `ref.watch()` where `ref.read()` suffices (event handlers)
- [ ] Check if `.select()` is used to limit rebuilds on large providers
- [ ] Scan for `build()` methods doing expensive work without `const` constructors or caching

---

## Phase 3: Push to Main + Pipeline Fix

- [ ] Stage ruff.toml + requirements-dev.txt (already modified, needed for CI)
- [ ] Auto-fix 2 UP007 ruff violations
- [ ] Run backend tests locally to verify Python 3.13 compat
- [ ] Stage all changes
- [ ] Commit + push
- [ ] Monitor GitHub Actions run (backend CI should pass; E2E CI will skip actual tests if secrets not set)

## Quality Gates
- [ ] `ruff check .` → 0 errors in functions/
- [ ] `pytest tests/ -v` → all passing
- [ ] Pipeline triggers on push → no red jobs
