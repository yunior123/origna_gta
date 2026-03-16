/**
 * Flutter Web E2E Test Helpers (Isolated)
 *
 * Bilingual (EN/FR) selector conventions — the app may render in French:
 *  - Home Settings button  → /settings|paramètres/i
 *  - Home Cart button      → /cart|shopping|panier/i
 *  - Home Add Product btn  → /add product|ajouter/i
 *  - Sign-in button        → /sign\s*in|se\s*connecter|connexion/i
 *  - Profile menu items    → locator('[aria-label="menu-my-orders"]') etc.  (language-independent)
 *  - Sign-out              → locator('[aria-label^="btn-sign-out"]')
 *  - Login email           → getByRole('textbox', { name: 'you@example.com' })
 *  - Login password        → getByRole('textbox', { name: '••••••••' })
 *  - Login submit          → locator('[aria-label^="login_submit_button"]')
 *  - Home search bar       → locator('[aria-label="input-home-search"]')
 *  - Product cards         → locator('[aria-label*="product-card-"]')  (groups use aria-label, not textContent)
 *  - Admin tabs            → locator('[aria-label="admin-tab-sellers"]') etc.
 */

import { Page, Locator, test, expect } from '@playwright/test';
import {
    WEB_APP_URL,
    ensureOrignaBaseUiAccount,
    useOrignaBaseAuth,
} from './api-helpers';

// ─── BILINGUAL PATTERNS ────────────────────────────────────────────
const BTN_SETTINGS = /settings|paramètres/i;
// Stable aria-label for the home settings button (language-independent)
const BTN_SETTINGS_LABEL = 'btn-home-settings';
const BTN_SIGN_IN = /sign\s*in|se\s*connecter|connexion/i;
const BTN_CART = /cart|shopping|panier/i;
const BTN_ADD_PRODUCT = /add\s*product|ajouter/i;

export { BTN_SETTINGS, BTN_SETTINGS_LABEL, BTN_SIGN_IN, BTN_CART, BTN_ADD_PRODUCT };

async function replaceFlutterInputValue(page: Page, input: Locator, value: string): Promise<void> {
    await expect(input).toBeVisible({ timeout: 30000 });
    await input.click();
    await page.waitForTimeout(1200);
    await page.evaluate(() => {
        const active = document.activeElement as HTMLInputElement | HTMLTextAreaElement | null;
        if (active && ('value' in active)) {
            active.value = '';
            active.dispatchEvent(new Event('input', { bubbles: true }));
            active.dispatchEvent(new Event('change', { bubbles: true }));
        }
    }).catch(() => { });
    await page.keyboard.insertText(value);
    await page.waitForTimeout(400);
    const actual = await page.evaluate(() => {
        const active = document.activeElement as HTMLInputElement | HTMLTextAreaElement | null;
        if (active && ('value' in active)) {
            return active.value ?? '';
        }
        return '';
    }).catch(() => '');
    if (actual !== value) {
        throw new Error(`Flutter input mismatch. Expected "${value}" but found "${actual}"`);
    }
}

// ─── SERVICE WORKER CLEANUP ────────────────────────────────────────

export async function clearServiceWorkers(page: Page): Promise<void> {
    try {
        await page.evaluate(async () => {
            const regs = await navigator.serviceWorker?.getRegistrations() ?? [];
            for (const reg of regs) await reg.unregister();
            const names = await caches?.keys() ?? [];
            for (const n of names) await caches.delete(n);
            localStorage?.clear();
            sessionStorage?.clear();
            if (indexedDB?.databases) {
                const dbs = await indexedDB.databases();
                await Promise.all(
                    dbs
                        .map(db => db.name)
                        .filter((name): name is string => Boolean(name))
                        .map(name => new Promise<void>(resolve => {
                            const req = indexedDB.deleteDatabase(name);
                            req.onsuccess = () => resolve();
                            req.onerror = () => resolve();
                            req.onblocked = () => resolve();
                        })),
                );
            }
        });
    } catch { /* SW not available */ }

    await page.context().clearCookies().catch(() => { });
}

// ─── FLUTTER INITIALIZATION ─────────────────────────────────────────

export async function waitForFlutter(page: Page, timeout = 180000): Promise<void> {
    const t0 = Date.now();

    // ── Fast path ──────────────────────────────────────────────────────────────
    // If semantics are already active or interactive UI is present, bail out.
    const hasSemFast = await page.locator('flt-semantics').count().catch(() => 0);
    const hasInteractiveUiFast = await page.evaluate(() => {
        // Flutter Web 3.41.3: button labels are in textContent, not aria-label.
        // Use textContent check for flt-semantics buttons; keep aria-label for inputs/groups.
        // Flutter Web 3.41.3: button labels (e.g. btn-home-settings) are in textContent,
        // not aria-label. Group labels (e.g. product-card-*) still use aria-label attribute.
        // Inputs (<input> elements) always use aria-label HTML attribute.
        const hasBtnHomeSettings = Array.from(document.querySelectorAll('flt-semantics[role="button"]'))
            .some(el => el.textContent?.trim() === 'btn-home-settings');
        return !!(
            hasBtnHomeSettings ||
            document.querySelector('[aria-label*="product-card-"]') ||
            document.querySelector('[aria-label="input-home-search"]') ||
            document.querySelector('input[aria-label="you@example.com"]') ||
            document.querySelector('input[aria-label="login_email_field"]') ||
            document.querySelector('[aria-label="menu-my-orders"]') ||
            document.querySelector('[aria-label="btn-sign-out"]') ||
            Array.from(document.querySelectorAll('flt-semantics[role="button"]')).some(
                el => el.textContent?.trim().toLowerCase() === 'back',
            )
        );
    }).catch(() => false);
    if (hasSemFast > 0 || hasInteractiveUiFast) {
        await page.waitForTimeout(500);
        return;
    }

    // ── Concurrent placeholder watcher ─────────────────────────────────────────
    // The flt-semantics-placeholder appears at ~2s on the FIRST page load and is
    // quickly replaced by flt-semantics once clicked. If we wait for engine load
    // (step 1) sequentially first, we miss it. Launch a concurrent task that clicks
    // the placeholder the moment it appears, so activation happens at ~2s regardless
    // of how long steps 1-2 take.
    // NOTE: Do NOT use document.querySelector('canvas') for isLoaded — Cloudflare
    // Turnstile renders a small canvas that would create a false positive before
    // Flutter initialises.
    const watchPlaceholder = async () => {
        try {
            const placeholder = page.locator('flt-semantics-placeholder');
            // Timeout = full budget: 17MB debug builds can take 40s+ to load over network.
            const found = await placeholder.first()
                .waitFor({ state: 'attached', timeout: timeout })
                .then(() => true)
                .catch(() => false);
            if (found) {
                await placeholder.first().click({ force: true }).catch(() => { });
            }
        } catch { /* page may navigate away */ }
    };
    const placeholderTask = watchPlaceholder(); // intentionally not awaited here

    // ── Step 1: Wait for Flutter engine render host ────────────────────────────
    const isLoaded = await page.evaluate(() => {
        const flutterCanvas = Array.from(document.querySelectorAll('canvas')).find(c => {
            const rect = c.getBoundingClientRect();
            return rect.width > 200 && rect.height > 200;
        });
        return !!(
            document.querySelector('flt-glass-pane') ||
            document.querySelector('flutter-view') ||
            flutterCanvas
        );
    }).catch(() => false);
    if (!isLoaded) {
        await page.waitForFunction(() => {
            const flutterCanvas = Array.from(document.querySelectorAll('canvas')).find(c => {
                const rect = c.getBoundingClientRect();
                return rect.width > 200 && rect.height > 200;
            });
            return !!(
                document.querySelector('flt-glass-pane') ||
                document.querySelector('flutter-view') ||
                flutterCanvas
            );
        }, { timeout }).catch(() => { });
    }

    // ── Step 2: Wait for loading indicator to clear ────────────────────────────
    await page.waitForFunction(() => {
        const loading = document.getElementById('loading');
        return !loading || loading.style.display === 'none' || loading.getAttribute('hidden') !== null;
    }, { timeout: 5000 }).catch(() => { });

    // ── Step 3: Ensure semantics are active ────────────────────────────────────
    // Allow a moment for the concurrent placeholder task to complete (it may have
    // clicked the placeholder at ~2s, causing flt-semantics to already be present).
    await Promise.race([placeholderTask, page.waitForTimeout(200)]).catch(() => { });

    // ── Step 3: Wait for flt-semantics using the remaining timeout budget ─────
    // flt-semantics only appears after the full widget tree renders (can be 30-40s
    // on a cold 17MB debug build). Use remaining time, not a fixed 20s cap.
    const remainingForSem = Math.max(20000, timeout - (Date.now() - t0) - 2000);
    const hasSemAfterPlaceholder = await page.locator('flt-semantics').count().catch(() => 0);
    if (hasSemAfterPlaceholder === 0) {
        // flt-semantics-placeholder is a custom element (not a <button>).
        // Some Flutter versions render it with a visible "Enable accessibility" text
        // but it must be selected by element name, not CSS button selector.
        const placeholder2 = page.locator('flt-semantics-placeholder');
        if ((await placeholder2.count().catch(() => 0)) > 0) {
            await placeholder2.first().click({ force: true }).catch(() => { });
        } else {
            // Older builds or different rendering: try dispatchEvent directly.
            await page.evaluate(() => {
                const el = document.querySelector('flt-semantics-placeholder') as HTMLElement | null;
                if (el) el.click();
            }).catch(() => { });
        }

        // Tab key as a last-resort activation trigger.
        await page.keyboard.press('Tab');

        // Wait using the remaining budget — don't give up after a fixed 20s.
        await page.locator('flt-semantics').first()
            .waitFor({ state: 'attached', timeout: remainingForSem })
            .catch(() => {
                console.log('   ⚠️  flt-semantics not found after activation attempts');
            });
    }

    // Settle time for semantic tree flush.
    await page.waitForTimeout(500);

    // Flutter Web 3.41.3: button labels are in textContent (use getByRole);
    // group/input labels still use aria-label attribute.
    if (
        await page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first().isVisible().catch(() => false) ||
        await page.locator('[aria-label="input-home-search"], [aria-label*="product-card-"]').first().isVisible().catch(() => false)
    ) {
        // Re-check semantics once app-level elements are visible — ensures the
        // semantic tree has also flushed by the time we return.
        if ((await page.locator('flt-semantics').count().catch(() => 0)) === 0) {
            await page.keyboard.press('Tab');
            await page.locator('flt-semantics').first()
                .waitFor({ state: 'attached', timeout: 10000 })
                .catch(() => { });
        }
        return;
    }

    const elapsed = Date.now() - t0;
    if (elapsed > 5000) {
        console.log(`   ✅ Flutter ready in ${elapsed}ms`);
    }
}

/**
 * Wait for a specific semantic element to appear after navigation.
 * Flutter Web rebuilds the semantic tree after route changes — this can take
 * several seconds if the new screen loads data from remote Firestore.
 * Returns the locator for further interaction.
 */
export async function waitForSemantic(
    page: Page,
    selector: string,
    timeout = 30000,
): Promise<Locator> {
    const loc = page.locator(selector).first();
    await loc.waitFor({ state: 'attached', timeout }).catch(() => {
        console.log(`   ⚠️  Semantic element not found: ${selector} (waited ${timeout}ms)`);
    });
    return loc;
}

/**
 * Wait for product cards to load from Firestore and appear in the semantic tree.
 * Scrolls to trigger lazy loading and retries multiple times.
 */
export async function waitForProductCards(
    page: Page,
    timeout = 45000,
): Promise<number> {
    const startTime = Date.now();
    // Product card groups use aria-label attribute (not textContent like buttons do).
    const cards = page.locator('[aria-label*="product-card-"]');

    // First, wait for at least one card to appear (Firestore data loading)
    await cards.first().waitFor({ state: 'attached', timeout }).catch(() => {});

    if ((await cards.count()) > 0) return cards.count();

    // If no cards yet, scroll to trigger lazy loading and wait
    for (let i = 0; i < 20; i++) {
        if (Date.now() - startTime > timeout) break;
        await page.mouse.wheel(0, 250);
        await page.waitForTimeout(1500);
        if ((await cards.count()) > 0) return cards.count();
    }

    const finalCount = await cards.count();
    if (finalCount === 0) {
        console.log(`   ⚠️  No product cards found after ${Date.now() - startTime}ms`);
    }
    return finalCount;
}

// ─── REPLICA UTILS ──────────────────────────────────────────────────

export async function requireWebApp(page: Page, targetUrl: string): Promise<void> {
    const res = await page.request.get(`${targetUrl}/`).catch(() => null);
    const status = res?.status();
    if (!status || status < 200 || status >= 400) {
        throw new Error(`Target not reachable at ${targetUrl} (status: ${status ?? 'ERR'})`);
    }
}

export async function checkSemantics(page: Page): Promise<void> {
    let sems = await page.locator('flt-semantics').count();
    if (sems > 0) return;

    // Flutter Web 3.41.3: button labels use textContent; use getByRole for btn-home-settings.
    const hasInteractiveUi = await page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first().isVisible().catch(() => false) ||
        await page.locator(
            '[aria-label="input-home-search"], [aria-label*="product-card-"], input[aria-label="you@example.com"], input[aria-label="login_email_field"], [aria-label="menu-my-orders"], [aria-label="btn-sign-out"]',
        ).first().isVisible().catch(() => false);
    if (hasInteractiveUi) {
        return;
    }

    // Retry: try activating semantics one more time before skipping.
    // Sometimes the placeholder needs a second click or Tab press.
    console.log('   ♿ checkSemantics: 0 flt-semantics found, retrying activation...');
    const placeholder = page.locator('flt-semantics-placeholder');
    if ((await placeholder.count()) > 0) {
        await placeholder.first().click({ force: true }).catch(() => { });
    }
    await page.keyboard.press('Tab');
    await page.locator('flt-semantics').first()
        .waitFor({ state: 'attached', timeout: 45000 })
        .catch(() => { });

    sems = await page.locator('flt-semantics').count();
    if (sems === 0) {
        console.warn('⚠️ No <flt-semantics> — build with --dart-define=FORCE_SEMANTICS=true');
        return;
    }
}

// ─── LOGIN HELPER ───────────────────────────────────────────────────
// Flutter Web routing: page.goto('/login') shows the home screen underneath.
// The login form is only rendered via IN-APP navigation:
//   Settings button → "login required" dialog → "Se connecter" → LoginScreen at /login
//
// Session detection: click Settings → if dialog appears = logged out, else → /profile = logged in.

export async function ensureLoggedInAsAdmin(page: Page, targetUrl: string, email?: string, pass?: string): Promise<void> {
    if (!email || !pass) {
        throw new Error('Missing credentials');

    }

    let loginEmail = email;
    let loginPass = pass;
    if (useOrignaBaseAuth()) {
        const provisioned = await ensureOrignaBaseUiAccount(email, pass);
        loginEmail = provisioned.email;
        loginPass = provisioned.password;
    }

    console.log(`   ⌨️  Logging in as ${loginEmail}...`);
    // Ensure we're on the target origin before clearing persisted site state.
    if (!page.url().startsWith(targetUrl)) {
        await page.goto(`${targetUrl}/`, { waitUntil: 'domcontentloaded' });
        await waitForFlutter(page, 120000);
    }

    // Full state clearing is only needed for explicit guest-mode tests.
    // For the main dev suite, reusing the browser context dramatically reduces
    // login latency and avoids repeated semantics/bootstrap churn.
    if (process.env.E2E_FORCE_GUEST === '1') {
        await clearServiceWorkers(page);
        await page.goto(`${targetUrl}/`, { waitUntil: 'domcontentloaded' });
        await waitForFlutter(page, 120000);
    }

    // NOTE: btn-home-settings is visible in BOTH guest and authenticated modes.
    // Do NOT use it as an auth indicator — it would always fire a false positive.
    // Use only profile-page elements that are exclusively shown when logged in.
    // These selectors intentionally return false on the home page; the redirect
    // detection below handles the "already authenticated" case via page.goto.
    const authenticatedShellNow = page.locator(
        '[aria-label="menu-my-orders"], [aria-label="btn-sign-out"], [aria-label="menu-admin-panel"]',
    ).first();
    if (await authenticatedShellNow.isVisible({ timeout: 3000 }).catch(() => false)) {
        console.log(`   ✅ Already logged in (profile shell visible). Skipping login.`);
        await navigateHome(page, targetUrl);
        return;
    }

    // Directly opening /login is more stable than routing through the settings dialog.
    await page.goto(`${targetUrl}/login`, { waitUntil: 'domcontentloaded' });
    await waitForFlutter(page, 120000);

    // If Flutter already has a valid JWT in localStorage, it will redirect away from
    // /login immediately (before the login form renders). Detect this redirect and bail out.
    const afterGotoUrl = page.url();
    const isStillOnLogin = /\/login/i.test(afterGotoUrl) || afterGotoUrl.endsWith('/login');
    if (!isStillOnLogin) {
        console.log(`   ✅ Already authenticated (Flutter redirected /login → ${afterGotoUrl}). Skipping login.`);
        return;
    }
    // Wait for the login form to appear — more robust than URL check because
    // some Flutter Web routing setups (nested navigators) may not update the URL.
    // rootNavigator: true in utils.dart ensures the URL updates, but we also
    // wait for form content as a belt-and-suspenders approach.
    // Flutter Web text inputs: there are two textboxes per field:
    //   1. Disabled one with the label ("Adresse courriel" / "Email Address")
    //   2. Enabled one with placeholder text ("you@example.com" / "••••••••")
    // We fill the ENABLED ones using their placeholder names.
    // IMPORTANT: Flutter Web text inputs need careful handling.
    // 1. fill() may not trigger Flutter's form state updates.
    // 2. pressSequentially() can lose the first character if focus isn't settled.
    // Solution: click → wait for focus → clear → type key-by-key.
    const emailInput = page.locator(
        'input[aria-label="you@example.com"], input[aria-label="login_email_field"]',
    ).last();
    // Wait for login form (URL or form appearance — URL may not update in nested nav)
    await Promise.race([
        page.waitForURL(/\/login/i, { timeout: 60000 }).catch(() => { }),
        emailInput.waitFor({ state: 'visible', timeout: 60000 }),
    ]);
    await replaceFlutterInputValue(page, emailInput, loginEmail);

    const passInput = page.locator(
        'input[aria-label="••••••••"], input[aria-label="login_password_field"]',
    ).last();
    await replaceFlutterInputValue(page, passInput, loginPass);
    await passInput.press('Tab').catch(() => { });
    await page.waitForTimeout(500);

    const submitBtn = page.locator('[aria-label="login_submit_button"]').first();
    const visibleSubmit = page.locator('text=/^(Sign In|Se connecter|Connexion)$/i').last();
    await passInput.press('Enter').catch(() => { });
    await page.waitForTimeout(1500);

    const loginStillVisible =
        await emailInput.isVisible().catch(() => false) ||
        await passInput.isVisible().catch(() => false);
    if (loginStillVisible) {
        await Promise.race([
            submitBtn.waitFor({ state: 'visible', timeout: 20000 }).catch(() => { }),
            visibleSubmit.waitFor({ state: 'visible', timeout: 20000 }).catch(() => { }),
        ]);
        await visibleSubmit.click({ force: true }).catch(async () => {
            await submitBtn.click({ force: true }).catch(async () => {
                await passInput.press('Enter').catch(() => { });
            });
        });
        await page.waitForTimeout(1500);
    }

    // After login, Flutter rebuilds and shows the home screen in-place.
    // The URL may stay at /login but the content changes.
    // IMPORTANT: Do NOT use page.goto() — Firebase Auth indexedDB
    // persistence does not survive full page reloads in Playwright's
    // isolated browser contexts. Use in-app navigation only.

    // Wait for a positive authenticated signal instead of requiring the login
    // fields to fully unmount. Staging sometimes keeps the form mounted longer
    // even after auth succeeds and navigation begins.
    const postLoginSignals = await Promise.race([
        page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first()
            .waitFor({ state: 'attached', timeout: 60000 })
            .then(() => 'home')
            .catch(() => null),
        page.locator('[aria-label^="btn-sign-out"], [aria-label="menu-my-orders"]').first()
            .waitFor({ state: 'visible', timeout: 60000 })
            .then(() => 'profile')
            .catch(() => null),
        page.getByRole('button', { name: /i'?ve verified my email/i }).first()
            .waitFor({ state: 'visible', timeout: 60000 })
            .then(() => 'verify-email')
            .catch(() => null),
        page.waitForURL(url => !/\/login/i.test(url.toString()), { timeout: 60000 })
            .then(() => 'route-changed')
            .catch(() => null),
    ]);

    if (!postLoginSignals) {
        throw new Error(`Login submit did not produce an authenticated UI for ${loginEmail}`);
    }

    if (postLoginSignals === 'verify-email') {
        const verifyBtn = page.getByRole('button', { name: /i'?ve verified my email/i }).first();
        await verifyBtn.click({ force: true });
        await page.waitForTimeout(2000);
        await waitForFlutter(page, 60000);
    }

    await page.waitForTimeout(2000);
    await waitForFlutter(page, 60000);

    // We already observed a positive post-login signal above. Do not add another
    // hard gate here: Flutter semantics can continue rebinding after auth even
    // though the authenticated shell is already present.
    const verifySettingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    const signInCheck = page.getByRole('button', { name: BTN_SIGN_IN }).first();
    if (await verifySettingsBtn.isVisible({ timeout: 5000 }).catch(() => false)) {
        await verifySettingsBtn.click({ timeout: 30000 });
        const stillLoggedOut = await signInCheck.isVisible({ timeout: 5000 }).catch(() => false);
        if (stillLoggedOut) {
            throw new Error(`Login failed for ${loginEmail} — sign-in dialog still showing after submit`);
        }
    }

    // Navigate back to home via in-app back navigation (NOT page.goto)
    await navigateHome(page, targetUrl);

    console.log(`   ✅ Login successful for ${loginEmail}`);
}

/** Generic alias for any user role — the underlying login is role-agnostic. */
export const ensureLoggedIn = ensureLoggedInAsAdmin;

/**
 * Login helper for buyer tests — same underlying flow as ensureLoggedInAsAdmin
 * but named to make explicit that no elevated roles are granted during login.
 * The login function is purely credential-based and never modifies user roles.
 */
export const ensureLoggedInAsBuyer = ensureLoggedInAsAdmin;

export async function openHomeSettings(page: Page): Promise<void> {
    if (/\/profile/i.test(page.url())) {
        const profileLoading = page.getByText(/setting up your profile/i).first();
        await profileLoading.waitFor({ state: 'hidden', timeout: 60000 }).catch(() => { });
        await waitForFlutter(page, 15000).catch(() => { });
        return;
    }
    const settingsScreenMarkers = page.locator(
        '[aria-label="menu-my-orders"], [aria-label="btn-sign-out"], [aria-label="menu-admin-panel"], button:has-text("Back")',
    );
    if ((await settingsScreenMarkers.count().catch(() => 0)) > 0) {
        const profileLoading = page.getByText(/setting up your profile/i).first();
        await profileLoading.waitFor({ state: 'hidden', timeout: 60000 }).catch(() => { });
        await waitForFlutter(page, 15000).catch(() => { });
        return;
    }

    for (let attempt = 0; attempt < 4; attempt++) {
        // Flutter Web 3.41.3: btn-home-settings uses textContent, not aria-label → getByRole.
        const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
        const hasSettingsUi = await settingsBtn.waitFor({ state: 'attached', timeout: 3000 }).then(() => true).catch(() => false);
        if (!hasSettingsUi) {
            await page.waitForTimeout(1000);
            await waitForFlutter(page, 15000).catch(() => { });
            continue;
        }
        try {
            const clicked = await settingsBtn.click({ force: true, timeout: 15000 })
                .then(() => true)
                .catch(() => false);
            if (!clicked) {
                await settingsBtn.dispatchEvent('click').catch(() => { });
            }
            const profileLoading = page.getByText(/setting up your profile/i).first();
            await profileLoading.waitFor({ state: 'hidden', timeout: 60000 }).catch(() => { });
            await waitForFlutter(page, 15000).catch(() => { });
            return;
        } catch (_) {
            await page.waitForTimeout(1000);
            await waitForFlutter(page, 15000);
        }
    }
    await page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first().dispatchEvent('click').catch(() => { });
}

// ─── NAVIGATE HOME (auth-safe, no full page reload) ────────────────

/**
 * Navigate to the home screen without page.goto() — which would kill
 * Firebase Auth state in Playwright's isolated browser contexts.
 * Uses the app heading / logo click or browser back navigation.
 */
export async function navigateHome(page: Page, targetUrl: string): Promise<void> {
    // URL is the PRIMARY ground truth for Flutter Web SPA navigation.
    // Flutter keeps background routes alive in the DOM — do NOT use element
    // visibility to decide "are we on home?" when the URL says otherwise.
    const isHomeUrl = () => {
        const u = page.url();
        return u === `${targetUrl}/` || u === targetUrl ||
            u.endsWith(':5005/') || u.endsWith(':5005');
    };

    // Fast path: URL is already home.
    if (isHomeUrl()) {
        // Flutter Web 3.41.3: semantic labels are in textContent, not aria-label.
        // Use getByRole (Chrome AOM reads textContent) instead of [aria-label=...].
        // Use 'attached' not 'visible': flt-semantics elements are in DOM but may have
        // zero dimensions while Flutter's layout pass is still running after navigation.
        await page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first()
            .waitFor({ state: 'attached', timeout: 15000 }).catch(() => {});
        return;
    }

    // URL is NOT home — navigate there via Flutter in-app back buttons.
    // IMPORTANT: Do NOT check DOM element visibility for early-return here.
    // Flutter Web keeps background home route elements in the DOM even when
    // product-details or another foreground route is active. Those background
    // elements look "visible" but clicking them fires events on the wrong route.

    for (let i = 0; i < 5; i++) {
        // Cast a wide net for back buttons across all Flutter screen patterns:
        //   - btn-back-* (Semantics label convention)
        //   - "Back" text (English default for arrow_back icon)
        //   - "Go Back" / "Go back" (product-details tooltip in English)
        //   - "Retour" (product-details tooltip in French)
        const backCandidates = [
            page.locator('[aria-label^="btn-back"]').first(),
            page.getByRole('button', { name: /^(back|go\s*back|retour)$/i }).first(),
        ];

        let clicked = false;
        for (const backBtn of backCandidates) {
            if (await backBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
                await backBtn.click({ force: true }).catch(() => { });
                clicked = true;
                // Wait for URL to reach home.
                await page.waitForURL(() => isHomeUrl(), { timeout: 10000 }).catch(() => { });
                await waitForFlutter(page, 10000).catch(() => { });
                if (isHomeUrl()) return;
                break;
            }
        }

        if (!clicked) {
            // No back button found — try browser back as a fallback.
            await page.goBack().catch(() => { });
            await page.waitForTimeout(1500);
            await waitForFlutter(page, 10000).catch(() => { });
            if (isHomeUrl()) return;
        }
    }

    if (!isHomeUrl()) {
        console.log('   ⚠️ navigateHome fallback: using page.goto');
        await page.goto(`${targetUrl}/`, { waitUntil: 'domcontentloaded' });
    }

    await waitForFlutter(page, 15000);
}

/**
 * Navigate to the subscription screen in-app (auth-safe).
 * Route: home → settings → profile → premium menu item → subscription.
 * Never uses page.goto() which would kill Firebase Auth state.
 */
export async function navigateToSubscription(page: Page): Promise<void> {
    // Go to profile screen via settings button
    await openHomeSettings(page);
    await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });

    // Wait for profile-specific content — Flutter puts label text in node textContent not aria-label
    // when child has text nodes, so use getByRole + name regex (stable identifier in textContent)
    const premiumBtn = page.getByRole('button', { name: /menu-premium/i }).first();
    await expect(premiumBtn).toBeAttached({ timeout: 30000 });

    await premiumBtn.click();
    await page.waitForURL(/\/subscription/i, { timeout: 20000 }).catch(() => { });
    await waitForFlutter(page, 30000);
}

/**
 * Navigate to the admin panel in-app (auth-safe).
 * Route: home → settings → profile → admin panel menu item → /admin.
 * Never uses page.goto() which would kill Firebase Auth state.
 */
export async function navigateToAdmin(page: Page): Promise<void> {
    // Go to profile screen via settings button
    await openHomeSettings(page);
    await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });

    // Wait for profile-specific content - Admin Panel menu item
    const adminBtn = page.getByRole('button', { name: /menu-admin-panel|admin panel/i }).first();
    await expect(adminBtn).toBeAttached({ timeout: 30000 });
    await adminBtn.scrollIntoViewIfNeeded();

    await adminBtn.click();
    await page.waitForURL(/\/admin/i, { timeout: 20000 }).catch(() => { });
    await waitForFlutter(page, 30000);
}

// ─── SIGN OUT HELPER ─────────────────────────────────────────────────

export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
    await navigateHome(page, targetUrl).catch(() => { });

    let signOutClicked = false;
    for (let attempt = 0; attempt < 3; attempt++) {
        await openHomeSettings(page);
        await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
        await waitForFlutter(page, 30000);

        const signOut = page.locator('[aria-label^="btn-sign-out"]').first();
        const profileLoading = page.getByText(/setting up your profile/i).first();
        if (!(await signOut.isVisible({ timeout: 2000 }).catch(() => false))) {
            if (await profileLoading.isVisible({ timeout: 1000 }).catch(() => false)) {
                await profileLoading.waitFor({ state: 'hidden', timeout: 30000 }).catch(() => { });
                await waitForFlutter(page, 15000).catch(() => { });
            }
        }

        if (await signOut.isVisible({ timeout: 3000 }).catch(() => false)) {
            await signOut.scrollIntoViewIfNeeded().catch(() => { });
            await signOut.click();
            await page.waitForTimeout(3000);
            signOutClicked = true;
            break;
        }

        await page.goBack().catch(() => { });
        await waitForFlutter(page, 15000).catch(() => { });
    }

    if (!signOutClicked) {
        console.log('   ⚠️ performSignOut fallback: clearing persisted auth state');
        await clearServiceWorkers(page).catch(() => { });
        await page.goto(`${targetUrl}/`, { waitUntil: 'domcontentloaded' }).catch(() => { });
        await waitForFlutter(page, 10000).catch(() => { });
    }

    // After sign-out, the app rebuilds to home (logged out).
    // Verify by clicking Settings — should show login dialog.
    const homeSettingsBtn = page.getByRole('button', { name: BTN_SETTINGS_LABEL }).first();
    const hasSettings = await homeSettingsBtn.isVisible({ timeout: 3000 }).catch(() => false);
    if (!hasSettings) {
        console.log('   ⚠️ Sign-out confirmation skipped: home settings button unavailable after cleanup');
        return;
    }
    await homeSettingsBtn.click().catch(() => { });
    const signInVisible = await page
        .getByRole('button', { name: BTN_SIGN_IN }).first()
        .isVisible({ timeout: 5000 })
        .catch(() => false);
    if (!signInVisible) {
        console.log('   ⚠️ Sign-out confirmation skipped: login prompt not visible after cleanup');
        return;
    }
    // Dismiss the dialog
    const cancelBtn = page.getByRole('button', { name: /cancel|annuler/i }).first();
    await cancelBtn.click().catch(() => { });
    await page.waitForTimeout(500);
    console.log('   ✅ Sign-out confirmed');
}

/**
 * Navigate to /add-product via in-app navigation (auth-safe).
 * IMPORTANT: Never use page.goto('/add-product') — that causes a Flutter cold-start
 * which loses the OrignaBase SDK's in-memory JWT. Always click the Add Product
 * button from the home screen instead.
 * Must be called after ensureLoggedIn (requires authenticated admin/seller role).
 */
export async function navigateToAddProduct(page: Page, targetUrl: string): Promise<void> {
    // Ensure we are on the home screen first
    await navigateHome(page, targetUrl);

    // Look for the "Add Product" FAB / button on the home screen
    const addBtn = page.getByRole('button', { name: BTN_ADD_PRODUCT }).first();
    const found = await addBtn.waitFor({ state: 'attached', timeout: 20_000 })
        .then(() => true)
        .catch(() => false);

    if (found) {
        await addBtn.click({ force: true });
    } else {
        // The button wasn't found — the user may not have the right role,
        // or the layout changed. Log and fall through to the URL check below.
        console.warn('   ⚠️  navigateToAddProduct: Add Product button not found');
    }

    await page.waitForURL(/\/add-product/i, { timeout: 30_000 }).catch(() => { });
    await waitForFlutter(page, 30_000);
}

// ─── UNIQUE SUFFIX ──────────────────────────────────────────────────

export function uniqueSuffix(testInfo: { workerIndex: number; parallelIndex: number }): string {
    const rnd = Math.random().toString(16).slice(2, 8);
    return `w${testInfo.workerIndex}-p${testInfo.parallelIndex}-${Date.now()}-${rnd}`;
}

// ─── SELECTORS ──────────────────────────────────────────────────────

export function flutterButton(page: Page, nameOrLabel: string | RegExp): Locator {
    return page.getByRole('button', { name: nameOrLabel });
}

export function flutterInput(page: Page, label: string | RegExp): Locator {
    return page.getByRole('textbox', { name: label });
}

export function flutterCheckbox(page: Page, label: string | RegExp): Locator {
    return page.getByRole('checkbox', { name: label });
}

export function flutterByLabel(page: Page, label: string | RegExp): Locator {
    if (typeof label === 'string') {
        return page.locator(`[aria-label="${label}"]`);
    }
    return page.locator('flt-semantics').filter({ has: page.locator(`[aria-label]`) }).filter({
        hasText: label,
    });
}

export function flutterByExactLabel(page: Page, label: string): Locator {
    return page.locator(`[aria-label="${label}"]`);
}
