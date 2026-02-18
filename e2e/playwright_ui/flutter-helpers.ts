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
 *  - Product cards         → locator('[aria-label^="product-card-"]')
 *  - Admin tabs            → locator('[aria-label="admin-tab-sellers"]') etc.
 */

import { Page, Locator, test, expect } from '@playwright/test';

// ─── BILINGUAL PATTERNS ────────────────────────────────────────────
const BTN_SETTINGS = /settings|paramètres/i;
const BTN_SIGN_IN = /sign\s*in|se\s*connecter|connexion/i;
const BTN_CART = /cart|shopping|panier/i;
const BTN_ADD_PRODUCT = /add\s*product|ajouter/i;

export { BTN_SETTINGS, BTN_SIGN_IN, BTN_CART, BTN_ADD_PRODUCT };

// ─── SERVICE WORKER CLEANUP ────────────────────────────────────────

async function clearServiceWorkers(page: Page): Promise<void> {
    try {
        await page.evaluate(async () => {
            const regs = await navigator.serviceWorker?.getRegistrations() ?? [];
            for (const reg of regs) await reg.unregister();
            const names = await caches?.keys() ?? [];
            for (const n of names) await caches.delete(n);
        });
    } catch { /* SW not available */ }
}

// ─── FLUTTER INITIALIZATION ─────────────────────────────────────────

export async function waitForFlutter(page: Page, timeout = 180000): Promise<void> {
    console.log(`⏳ Waiting for Flutter Web to initialize (timeout: ${timeout}ms)...`);
    const startTime = Date.now();

    await page.waitForFunction(() => {
        const glasspane = document.querySelector('flt-glass-pane');
        const flutterView = document.querySelector('flutter-view');
        const canvas = document.querySelector('canvas');
        return (
            !!glasspane ||
            !!flutterView ||
            (canvas instanceof HTMLCanvasElement && canvas.getBoundingClientRect().width > 0)
        );
    }, { timeout }).catch(() => { });

    await page
        .waitForFunction(() => {
            const splash = document.getElementById('splash');
            return !splash || splash.style.display === 'none' || splash.getAttribute('hidden') !== null;
        }, { timeout })
        .catch(() => { });

    const enableA11yBtn = page.locator('button:has-text("Enable accessibility")');
    const placeholder = page.locator('flt-semantics-placeholder');
    if ((await enableA11yBtn.count()) > 0) {
        await enableA11yBtn.first().click({ force: true }).catch(() => { });
    } else if ((await placeholder.count()) > 0) {
        await placeholder.first().click({ force: true }).catch(() => { });
        await page.keyboard.press('Tab');
    }

    await page
        .locator('flt-semantics')
        .first()
        .waitFor({ state: 'attached', timeout: 30000 })
        .catch(() => { });

    console.log(`   ✅ Flutter initialized in ${Date.now() - startTime}ms`);
}

// ─── REPLICA UTILS ──────────────────────────────────────────────────

export async function requireWebApp(page: Page, targetUrl: string): Promise<void> {
    const res = await page.request.get(`${targetUrl}/`).catch(() => null);
    const status = res?.status();
    if (!status || status < 200 || status >= 400) {
        test.skip(true, `Target not reachable at ${targetUrl} (status: ${status ?? 'ERR'})`);
    }
}

export async function checkSemantics(page: Page): Promise<void> {
    const sems = await page.locator('flt-semantics').count();
    if (sems === 0) {
        test.skip(true, 'No <flt-semantics> — run debug build with ensureSemantics enabled.');
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
        test.skip(true, 'Missing credentials');
        return;
    }

    console.log(`   ⌨️  Logging in as ${email}...`);

    // Clear service workers that might cache old builds
    await clearServiceWorkers(page);

    // Ensure we're at home before checking auth state
    if (!page.url().startsWith(targetUrl) || page.url().includes('/login') || page.url().includes('/profile')) {
        await page.goto(`${targetUrl}/`);
        await waitForFlutter(page, 60000);
    }

    // Click Settings — this reveals auth state:
    //   logged in  → navigates to /profile (no dialog)
    //   logged out → shows "Connexion requise" / "Login required" dialog
    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await expect(settingsBtn).toBeAttached({ timeout: 20000 });
    await settingsBtn.click();

    // Check for sign-in dialog button (unauthenticated state)
    // Dialog shows "Se connecter" / "Sign in" button
    const signInPrompt = page.getByRole('button', { name: BTN_SIGN_IN }).first();
    const isLoggedOut = await signInPrompt.isVisible({ timeout: 10000 }).catch(() => false);

    if (!isLoggedOut) {
        // Already logged in — might be on /profile or still at home
        console.log(`   ✅ Already logged in. Skipping login.`);
        await page.goto(`${targetUrl}/`);
        await waitForFlutter(page, 30000);
        return;
    }

    // Tap "Se connecter" / "Sign in" to trigger in-app navigation to /login
    await signInPrompt.click();
    await expect(page).toHaveURL(/\/login/i, { timeout: 20000 });
    await waitForFlutter(page, 120000);

    // Flutter Web text inputs: there are two textboxes per field:
    //   1. Disabled one with the label ("Adresse courriel" / "Email Address")
    //   2. Enabled one with placeholder text ("you@example.com" / "••••••••")
    // We fill the ENABLED ones using their placeholder names.
    const emailInput = page.getByRole('textbox', { name: 'you@example.com' });
    await expect(emailInput).toBeVisible({ timeout: 30000 });
    await emailInput.click();
    await emailInput.fill(email);

    const passInput = page.getByRole('textbox', { name: '••••••••' });
    await passInput.click();
    await passInput.fill(pass);

    // Submit via the semantic-labeled button (language-independent)
    const submitBtn = page.locator('[aria-label^="login_submit_button"]').first();
    await submitBtn.click();

    // Flutter Web quirk: after successful login, the app rebuilds to show
    // the home screen but the URL may stay at /login. Instead of waiting
    // for URL change, wait for the login form to disappear (meaning auth
    // state changed and Flutter rebuilt), then force-navigate to home.
    await Promise.race([
        // Option A: URL changes away from /login (ideal)
        expect(page).not.toHaveURL(/\/login/i, { timeout: 15000 }).catch(() => {}),
        // Option B: login form disappears (auth succeeded, URL lagging)
        expect(emailInput).not.toBeVisible({ timeout: 15000 }).catch(() => {}),
    ]);

    // Give Flutter a moment to settle auth state
    await page.waitForTimeout(2000);

    // Force navigate to home to fix any stale URL
    await page.goto(`${targetUrl}/`);
    await waitForFlutter(page, 30000);

    // Verify login actually succeeded: Settings click should NOT show sign-in dialog
    const verifySettingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await expect(verifySettingsBtn).toBeAttached({ timeout: 15000 });
    await verifySettingsBtn.click();

    // If we see the sign-in dialog, login failed
    const signInCheck = page.getByRole('button', { name: BTN_SIGN_IN }).first();
    const stillLoggedOut = await signInCheck.isVisible({ timeout: 5000 }).catch(() => false);
    if (stillLoggedOut) {
        throw new Error(`Login failed for ${email} — sign-in dialog still showing after submit`);
    }

    // We're on /profile now (logged in) — go back to home
    await page.goto(`${targetUrl}/`);
    await waitForFlutter(page, 30000);

    console.log(`   ✅ Login successful for ${email}`);
}

// ─── SIGN OUT HELPER ─────────────────────────────────────────────────

export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
    const settingsBtn = page.getByRole('button', { name: BTN_SETTINGS }).first();
    await settingsBtn.click();
    await page.waitForURL(/\/profile/i, { timeout: 20000 }).catch(() => { });
    await waitForFlutter(page, 30000);

    const signOut = page.locator('[aria-label^="btn-sign-out"]').first();
    await expect(signOut).toBeAttached({ timeout: 15000 });
    await signOut.scrollIntoViewIfNeeded().catch(() => { });
    await signOut.click();
    await page.waitForTimeout(2000);

    // Confirm sign-out: navigating to settings should show login dialog
    await page.goto(`${targetUrl}/`);
    await waitForFlutter(page, 30000);
    await settingsBtn.click();
    await expect(
        page.getByRole('button', { name: BTN_SIGN_IN }).first()
    ).toBeVisible({ timeout: 20000 });
    console.log('   ✅ Sign-out confirmed');
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
