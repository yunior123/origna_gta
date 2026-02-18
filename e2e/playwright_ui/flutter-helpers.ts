/**
 * Flutter Web E2E Test Helpers (Isolated)
 *
 * Selector conventions:
 *  - Home Settings button  → getByRole('button', { name: /settings/i })   (tooltip="Settings")
 *  - Home Cart button      → getByRole('button', { name: /cart|shopping/i }) (tooltip="Shopping cart")
 *  - Home Add Product btn  → getByRole('button', { name: /add product/i }) (tooltip="Add product")
 *  - Profile menu items    → locator('[aria-label="menu-my-orders"]') etc.   (semanticLabel set in profile_screen.dart)
 *  - Sign-out              → locator('[aria-label="btn-sign-out"]')
 *  - Login email           → getByRole('textbox', { name: /email/i })
 *  - Login password        → getByRole('textbox', { name: /password/i })
 *  - Login submit          → getByRole('button', { name: /sign\s*in/i })
 *  - Home search bar       → locator('[aria-label="input-home-search"]')
 *  - Product cards         → locator('[aria-label^="product-card-"]')
 *  - Admin tabs            → locator('[aria-label="admin-tab-sellers"]') etc.
 */

import { Page, Locator, test, expect } from '@playwright/test';

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
//   Settings button → profile page → "Sign in" button → LoginScreen appears at /login
//
// Session detection: click Settings → if "Sign in" button visible = logged out,
//   else already logged in.

export async function ensureLoggedInAsAdmin(page: Page, targetUrl: string, email?: string, pass?: string): Promise<void> {
    if (!email || !pass) {
        test.skip(true, 'Missing credentials');
        return;
    }

    console.log(`   ⌨️  Logging in as ${email}...`);

    // Ensure we're at home before checking auth state
    if (!page.url().startsWith(targetUrl) || page.url().includes('/login') || page.url().includes('/profile')) {
        await page.goto(`${targetUrl}/`);
        await waitForFlutter(page, 60000);
    }

    // Click Settings — this reveals auth state:
    //   logged in  → navigates to /profile (no sign-in button)
    //   logged out → shows sign-in prompt on profile page
    const settingsBtn = page.getByRole('button', { name: /settings/i }).first();
    await expect(settingsBtn).toBeAttached({ timeout: 20000 });
    await settingsBtn.click();

    // Check for "Sign in" button (unauthenticated state on profile page)
    const signInPrompt = page.getByRole('button', { name: /sign\s*in|connexion/i }).first();
    const isLoggedOut = await signInPrompt.isVisible({ timeout: 10000 }).catch(() => false);

    if (!isLoggedOut) {
        // Already logged in — return to home
        console.log(`   ✅ Already logged in. Skipping login.`);
        await page.goto(`${targetUrl}/`);
        await waitForFlutter(page, 30000);
        return;
    }

    // Tap "Sign in" to trigger in-app navigation to /login
    await signInPrompt.click();
    await expect(page).toHaveURL(/\/login(?:\b|\/|\?|#|$)/i, { timeout: 20000 });
    await waitForFlutter(page, 120000);

    // Flutter Web text input quirk: the <input> elements start disabled.
    // The flt-semantics label node IS clickable and triggers Flutter focus.
    // Approach: click the flt-semantics label node → keyboard.type() → Tab → type pass.
    const emailLabel = page.locator('flt-semantics').filter({ hasText: 'Email Address' }).first();
    await expect(emailLabel).toBeVisible({ timeout: 30000 });
    await emailLabel.click();
    await page.waitForTimeout(200);
    await page.keyboard.type(email);

    await page.keyboard.press('Tab');
    await page.waitForTimeout(200);
    await page.keyboard.type(pass);

    // Submit: 'auth.sign_in'.tr() = "Sign In"
    const submitBtn = page.getByRole('button', { name: /sign\s*in|connexion|log\s*in/i }).first();
    await submitBtn.click({ force: true });

    // Wait until login completes (navigates away from /login)
    await expect(page).not.toHaveURL(/\/login(?:\b|\/|\?|#|$)/i, { timeout: 30000 });

    // Return to home
    await page.goto(`${targetUrl}/`);
    await waitForFlutter(page, 30000);

    console.log(`   ✅ Login successful for ${email}`);
}

// ─── SIGN OUT HELPER ─────────────────────────────────────────────────

export async function performSignOut(page: Page, targetUrl: string): Promise<void> {
    const settingsBtn = page.getByRole('button', { name: /settings/i }).first();
    await settingsBtn.click();
    await page.waitForURL(/\/profile(?:\b|\/|\?|#|$)/i, { timeout: 20000 }).catch(() => { });
    await waitForFlutter(page, 30000);

    const signOut = page.locator('[aria-label="btn-sign-out"]').first();
    await expect(signOut).toBeAttached({ timeout: 15000 });
    await signOut.scrollIntoViewIfNeeded().catch(() => { });
    await signOut.click();
    await page.waitForTimeout(2000);

    // Confirm sign-out: navigating to settings should show login prompt
    await page.goto(`${targetUrl}/`);
    await waitForFlutter(page, 30000);
    await settingsBtn.click();
    await expect(
        page.getByRole('button', { name: /sign\s*in|connexion/i }).first()
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
