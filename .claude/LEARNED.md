# Learned Knowledge Archive

---

## Mac RAM Management During Dev Sessions (Feb 2026)

### Quick Health Check
```bash
# One-liner: swap + free RAM + process count
sysctl vm.swapusage && vm_stat | grep "Pages free" && echo "Chrome: $(ps aux | grep -c '[C]hrome')" && echo "Dart: $(ps aux | grep -c '[d]art')"
```

### Danger Thresholds
- **Swap > 4 GB** → performance degrades noticeably, kills start happening
- **Swap > 8 GB** → critical, close everything non-essential immediately
- **Pages free < 200 (~3 MB)** → macOS will start swapping aggressively
- **Chrome processes > 10** → too many tabs/instances, kill orphans
- **Dart processes > 6** → stale `flutter drive` sessions accumulating

### Cleanup Commands (Safe)
```bash
# Kill ALL orphan Chrome instances (stale from flutter drive)
pkill -f "Chrome.*--headless" 2>/dev/null
pkill -f "Google Chrome for Testing" 2>/dev/null

# Kill stale Dart processes (leftover from crashed flutter drive)
ps aux | grep dart | grep -v grep | grep -v "dart-sdk/bin/dart " | awk '{print $2}' | xargs kill -9 2>/dev/null

# Kill orphan chromedriver instances
pkill -f chromedriver 2>/dev/null

# Purge inactive RAM (macOS only, safe)
sudo purge
```

### Prevention Rules
1. **Always kill chromedriver + Chrome after flutter drive** — orphans accumulate fast
2. **One flutter drive at a time** — each spawns Chrome + Dart VM + chromedriver
3. **Close Chrome DevTools tabs** — each one is ~100-200 MB
4. **Avoid `isBackground: true` for flutter drive** — use foreground so it auto-cleans
5. **Monitor swap between test runs** — if > 4 GB, clean before next run
6. **32 open terminals = problem** — close unused ones, each holds shell memory

### Recovery When Swap > 8 GB
```bash
# Nuclear cleanup: kill all test-related processes
pkill -f chromedriver; pkill -f "Chrome.*Testing"; ps aux | grep dart | grep -v grep | grep -v "dart-sdk/bin/dart " | awk '{print $2}' | xargs kill -9 2>/dev/null
# Wait for OS to reclaim
sleep 5
# Verify recovery
sysctl vm.swapusage && vm_stat | grep "Pages free"
```

### Typical RAM Usage (MacBook Pro M-series, 8 GB)
- VS Code + extensions: ~800 MB
- Flutter Web build (debug): ~1.5 GB
- Chrome (flutter drive): ~500-800 MB per instance
- Dart VM (tests): ~200-400 MB each
- chromedriver: ~50 MB
- **Budget**: 1 VS Code + 1 flutter drive + 1 Chrome = ~3.5 GB, leaves ~4.5 GB headroom

---

## Product Data Resilience & Meilisearch Indexing (Mar 2026)

### Meilisearch Primary Key Issue
- Error: "can't auto-detect primary key because both id and origId end with id"
- Fix: Explicit `primaryKey: "id"` when creating/updating products index in sync script.
- Affects all product syncs; must specify on index creation and settings update.

### OrignaBaseProductRepository Resilience
- `_docToProduct`: Normalizes nanosecond timestamps (truncate to 6 decimals via regex) before `Product.fromJson`.
- Query methods: Use `.expand((doc) => { try { return [_docToProduct(doc)]; } catch (e) { debugPrint(...); return []; } })` instead of direct `.map` to skip individual bad docs without crashing entire list.
- fetchProductsByIds still direct (consider wrapping for full safety).
- Ensures app loads even with Bulk_/test/malformed entries in DB.

### Deployment Notes
- Use `./scripts/deploy_web.sh <env>` with VPS_HOST for staged releases (timestamped dirs + current symlink).
- Always run `flutter analyze` pre-deploy.
- Verify: 68 active products post-deploy; GraphQL filters by `lifecycleStatus == 'active'`.
- Update STATE.md after every test/deploy run.

---

## TODO Verification Notes (Apr 2026)

- On 2026-04-21, both Flutter apps analyzed clean locally: `origna_gta/origna_gta` and `origna_ventures` each returned `No issues found!`.
- The OrignaVentures single-page shell already covers several formerly-open TODOs: homepage is the default view, tier cards live on the homepage, Stripe checkout is launched directly from those cards, and the manual EN/FR/ES selector is reactive in `origna_ventures/lib/main.dart`.
- Repo documentation for `origna_ventures/` is already present in `docs/REPO_MAP.md`, `CLAUDE.md`, and `AGENTS.md`; re-check TODOs against code/docs before assuming they are still open.

---
