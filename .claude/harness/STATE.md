# State — Round 1

## Active Wave
- Harness scope has been re-anchored to the current `TODOS.md` active gate instead of the older already-closed stabilization slice.
- The all-up correctness gate is now closed green.
- Current follow-up wave:
  - diagnose and reduce the all-up E2E runtime after the successful green run.
- Current authoritative evidence source:
  - `/tmp/origna_e2e_run_all_after_deep_fix.log`

## Already Verified Before This Round
- `e2e/lib/auth.ts`
  - Fixed long-run bootstrap-admin token reuse in `repairOrignaBaseUiAccount(...)`.
  - Focused rerun passed: `specs/phase6-stripe/deep-ui-scenarios.spec.ts` -> `14 pass / 0 fail`.
- API portion of the all-up rerun is already green:
  - `582 pass / 2 skip / 0 fail`
- Final all-up wrapper result is green:
  - browser wave: `697 pass / 0 fail`
  - browser runtime: `4085.49s`
  - total wrapper runtime: `4899s`

## Changes Made This Round
- `.claude/harness/SPEC.md`
  - Rewritten to scope the harness to the current `TODOS.md` active gate.
- `.claude/harness/SPRINT.md`
  - Rewritten to enforce a narrow completion/fix loop around the active all-up E2E rerun.
- `.claude/harness/STATE.md`
  - Rewritten to track the active all-up rerun and defer the parking lot until gated work is closed.
- `STATE.md`
  - Updated with the final green all-up result and the first runtime-diagnosis evidence.
- `TODOS.md`
  - Updated Phase 3B progress to reflect the completed green rerun plus the remaining performance concern.
- `e2e/specs/phase4-product-flows/seller-integration.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)`.
- `e2e/specs/phase4-product-flows/bulk-upload.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)`.
- `e2e/specs/phase6-stripe/premium-subscription.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)` and removed one unauthenticated root-open path in `B2`.
- `e2e/specs/phase6-stripe/deep-ui-scenarios.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)` and removed the manual login form-driving in seller-products `B3`.
- `e2e/specs/phase6-stripe/seller-setup.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)`.
- `e2e/specs/phase5-complex-flows/admin-panel.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)`.
- `e2e/specs/phase5-complex-flows/admin-actions.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)`.
- `e2e/specs/phase5-complex-flows/admin-reviews.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)`.
- `e2e/specs/phase5-complex-flows/refund-buyer-flow.spec.ts`
  - Replaced bespoke UI login with `browser.loginViaApi(...)`.

## Known Issues
- Desktop screenshot capture is now manifest-driven for guest/legal views, but authenticated desktop capture is blocked by the deployed web shell.
- Verified blocker:
  - `cd e2e && bun run lib/debug_auth_session.ts`
  - after writing `orignabase_access_token`, `orignabase_refresh_token`, and `orignabase_email`, opening `https://dev.orignagta.ca/#/profile` still returned the legal bootstrap semantics:
    - `Enable accessibility`
    - `Privacy Policy`
    - `Terms of Service`
- This means the next fix is not more manifest guessing; it is authenticated hash-route boot/hydration on the deployed web app.
- The correctness gate is green, but runtime is far above target.
- Observed slow-run signals from the completed log:
  - `Navigation to https://dev.orignagta.ca/ timed out` x1
  - `chrome.*defunct` count observed after the run: `2`
- The repeated `loginAs` 30s click timeouts from the last all-up run were traced to legacy UI-login helpers and are now patched in the worst affected files, but another all-up timing pass is still needed to measure the suite-level win.
- Idle `agent-browser` daemons had accumulated during focused reruns; cleanup was run and the next all-up measurement should start from a much cleaner browser process set.
- The fresh all-up rerun after the runtime patches stayed green and improved materially:
  - total runtime dropped from `4899s` to `4269s`
  - browser runtime dropped from `4086s` to `3455s`
  - correctness remained `697 pass / 0 fail`
- Additional verified fixes after that rerun:
  - `order-detail-ui.spec.ts` improved and stayed green with direct authenticated `/#/orders` opens.
  - `chat-screen.spec.ts` now prefers `loginViaApi(...)` with UI fallback and no longer fails on brittle chat navigation waits.
  - `reorder-language.spec.ts` now uses direct authenticated `/#/orders` and `/#/profile` opens and is green again.
  - two surfaced clippy warnings were fixed and both `ob-handlers` and `orignabase` clippy gates are green.
- Parking-lot tasks remain intentionally deferred until the active phases are closed with evidence.

## Deferred Backlog
- repo/process improvements
- UI/UX model feedback loops
- lifecycle research and improvements
- VS Code warnings/TODO cleanup
- broader live-test and E2E expansion
- skills / routing-file / agents audits
- preview improvements
- coverage push to 95%+
- screenshot expansion and audit
- full codebase best-practice audits
- semantic-label expansion
- `e2e/ai` wave

## Verification
- Screenshot capture groundwork and verification:
  - `cd e2e && bun x tsc --noEmit`
  - `cd e2e && MANIFEST_FILE=desktop-capture-manifest-sample.json SCREENSHOT_OUT_DIR=/Users/yuniorrodriguezosorio/Desktop/origna-design-review-2026-04-17 bun run lib/manifest-runner.ts`
  - direct guest-home verification created `/Users/yuniorrodriguezosorio/Desktop/origna-design-review-2026-04-17/test-home-guest.png`
  - `cd e2e && bun run lib/debug_auth_session.ts`
- Harness planning documents updated to align with the active gate.
- Final all-up run evidence captured from `/tmp/origna_e2e_run_all_after_deep_fix.log`.
- Initial slowdown diagnosis captured with:
  - `rg -a -n "429|timed out|click timed out|loginAs warning|Navigation to https://dev\\.orignagta\\.ca/ timed out" /tmp/origna_e2e_run_all_after_deep_fix.log /tmp/e2e-api-results.log`
  - `ps aux | rg -c 'chrome.*defunct'`
- Focused runtime revalidation after the login-path fixes:
  - `cd e2e && bun x tsc --noEmit`
  - `cd e2e && bun test specs/phase4-product-flows/seller-integration.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase4-product-flows/bulk-upload.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase6-stripe/premium-subscription.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase6-stripe/deep-ui-scenarios.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase6-stripe/seller-setup.spec.ts --timeout 120000`
- Additional focused runtime revalidation after the phase-5 admin/refund login-path fixes:
  - `cd e2e && bun test specs/phase5-complex-flows/admin-panel.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase5-complex-flows/admin-actions.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase5-complex-flows/admin-reviews.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase5-complex-flows/refund-buyer-flow.spec.ts --timeout 120000`
  - `pkill -f '/Users/yuniorrodriguezosorio/.hermes/hermes-agent/node_modules/agent-browser/.*/dist/daemon.js'`
- Fresh suite-level timing verification:
  - `cd e2e && E2E_BROWSER_CONCURRENCY=1 E2E_API_CONCURRENCY=1 ./run-tests.sh all > /tmp/origna_e2e_run_all_after_runtime_patches.log 2>&1`
  - result: `697 pass / 0 fail`, `TOTAL 4269s`, `Browser 3455s`
- New focused revalidation after the next hotspot pass:
  - `cd e2e && bun test specs/phase5-complex-flows/order-detail-ui.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase5-complex-flows/chat-screen.spec.ts --timeout 120000`
  - `cd e2e && bun test specs/phase5-complex-flows/reorder-language.spec.ts --timeout 120000`
  - `cd orignabase && cargo clippy -p ob-handlers -- -D warnings`
  - `cd orignabase && cargo clippy -p orignabase -- -D warnings`
