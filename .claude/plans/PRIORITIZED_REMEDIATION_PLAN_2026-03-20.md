# Prioritized Remediation Plan

Based on the comprehensive audit of the OrignaBase backend, Flutter SDK, and tooling, this remediation plan categorizes findings by exploitability and blast radius. The issues reveal a pattern of trust-boundary and session-boundary mistakes across the stack.

## Phase 0: Incident Response & Immediate Rotation (P0 - CRITICAL)
**Goal:** Stop active or potential credential leaks and lock down known compromised secrets.
*Blast Radius: Total system compromise if keys are exploited.*

1. **Rotate JWT Keys and Secrets:**
   - **Action:** Immediately rotate all signing keys if the committed `jwt_private.pem` and `jwt_public.pem` were ever used in production.
   - **Action:** Update `.gitignore` to strictly exclude `data/keys` and any `.pem` files.
2. **Remove Hardcoded Secrets from E2E Tests:**
   - **Action:** Remove the hardcoded Stripe test secret and real account credentials from the E2E harness (`config.ts`, `api-client.ts`, `auth.ts`).
   - **Action:** Move the token cache out of `/tmp` or secure it properly, and stop keying it by `email:password`.
3. **Disable Default JWT Fallback:**
   - **Action:** Remove the default JWT secret fallback in `config.rs`. The application must fail to start if a secure, explicit JWT secret is not provided in the environment.

## Phase 1: Critical Authorization & Data Leaks (P0 - CRITICAL)
**Goal:** Prevent unauthorized data access, impersonation, and unauthenticated system abuse.
*Blast Radius: High. Allows unauthorized users to mutate data, read private collections, and spam notifications.*

1. **Fix Impersonation in Privileged Mutations:**
   - **Action:** Refactor handlers for refunds, cancels, returns, product updates/deletes, warehouses, and shipping approvals (`refunds.rs`, `crud.rs`, `warehouses/mod.rs`).
   - **Action:** Stop trusting caller-supplied `user_id` fields in request bodies. Derive the identity strictly from the authenticated `AuthContext`.
2. **Secure Notifications Surface:**
   - **Action:** Require authentication for all notification routes (`routes.rs`). Prevent anonymous callers from registering/unregistering device tokens, subscribing to topics, or sending pushes.
3. **Patch GraphQL Config Exposure:**
   - **Action:** Apply the same public-key filtering used by admin HTTP routes to the GraphQL `config/config_all` resolver to prevent disclosure of arbitrary backend config values (`resolvers.rs`).
4. **Fix Realtime Data Leakage & Enforcement:**
   - **Action:** Enforce per-document authorization and filter parameters on all websocket realtime subscriptions (`websocket.rs`, `dispatcher.rs`). Prevent clients from receiving raw `before_data`/`after_data` across entire collections.
5. **Correct Security Rule Engine Semantics:**
   - **Action:** Fix the parser and evaluator (`parser.rs`, `evaluator.rs`) so that `validate` rules are not treated as standalone `allow` rules, `!expr` negation is respected, and collection rules compose correctly with wildcard guardrails instead of replacing them.

## Phase 2: Core Auth Flows & Trust Boundaries (P1 - HIGH)
**Goal:** Ensure session integrity, correct MFA enforcement, and secure token lifecycle management.
*Blast Radius: Medium-High. Allows session hijacking, bypass of MFA, and token leakage.*

1. **Fix Password Reset Token Revocation:**
   - **Action:** Ensure that executing a password reset explicitly revokes all outstanding refresh tokens for that user (`routes.rs`).
2. **Fix Flutter MFA Login & Token Clearing:**
   - **Action:** Fix the state machine in `login_viewmodel.dart` and `orignabase_auth_repository.dart` to properly preserve the challenge token and transition into the MFA challenge flow.
   - **Action:** Update `signInWithEmail()` in the Flutter SDK (`auth.dart`) to clear existing session tokens when returning an MFA challenge, preventing the SDK from using old bearer tokens during an account switch.
3. **Prevent Token Leakage in Websockets (Flutter SDK):**
   - **Action:** Stop sending the bearer token in the websocket query string (`realtime.dart`). Migrate to sending the token in a connection initialization payload or a secure header to prevent leakage in proxy logs and telemetry.
4. **Fix Flutter SDK Refresh Token Erasure:**
   - **Action:** Modify refresh handling (`auth.dart`) so that if the backend returns only a new access token, the SDK retains the existing refresh token instead of erasing it.
5. **Await Offline Cache Clearing on Logout:**
   - **Action:** Ensure `signOut()` in the Flutter SDK (`auth.dart`) strictly `await`s the clearing of the offline cache (`offline.dart`) to prevent persisted user data from surviving logout/relaunch races.

## Phase 3: Product Correctness & Business Logic (P1/P2 - HIGH/MEDIUM)
**Goal:** Fix critical bugs in the checkout flow, product management, and background tasks.
*Blast Radius: Medium. Affects revenue (shipping costs), seller experience (lost images), and system reliability (duplicate jobs).*

1. **Fix Checkout Shipping Recalculation:**
   - **Action:** Update `orignabase_checkout_provider.dart` to recalculate shipping costs (and free-shipping eligibility) whenever a coupon is applied or removed, not just the tax.
2. **Fix Product Edit Flow Image Persistence:**
   - **Action:** Wire `ProductAddImages.onImagesChanged` back into the viewmodel (`edit_product_viewmodel.dart`, `editproduct_screen.dart`) so newly added images are actually persisted when the seller saves.
3. **Fix Flutter SDK Storage URL Rewriting:**
   - **Action:** Stop the SDK (`storage.dart`) from rewriting presigned storage URLs to the API host when the hosts differ. This breaks legitimate S3/GCS signed URLs.
4. **Fix Flutter SDK Realtime Subscription Filters:**
   - **Action:** Ensure the SDK passes and respects subscription filters correctly so callers do not receive whole-collection traffic when they intended to subscribe narrowly (`realtime.dart`).
5. **Fix Task Queue Race Conditions:**
   - **Action:** Implement lease/heartbeat tokens for reclaimed tasks in `task_queue.rs` to prevent duplicate long-running jobs and stop stale workers from overwriting newer state.

## Phase 4: Operational & Tooling Stability (P2 - MEDIUM)
**Goal:** Maintain stability during architectural transitions.

1. **Delay Rust MCP Transition:**
   - **Action:** Keep the TypeScript MCP server active. Do not deprecate it yet.
   - **Action:** The Rust `ob-mcp` target needs significant work to reach functional and security parity (fix transport auth dropping, placeholder auth parsing, and contract drift) before it can replace the TS server.
