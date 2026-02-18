/**
 * Flutter Web E2E Test Helpers (Isolated)
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

export async function ensureLoggedInAsAdmin(page: Page, targetUrl: string, email?: string, pass?: string): Promise<void> {
    if (!email || !pass) {
        test.skip(true, 'Missing credentials');
        return;
    }

    console.log(`   ⌨️  Logging in as ${email}...`);

    // Check if already logged in by looking for a known element on the home page
    // Note: home_search_field is findable by aria-label='input-home-search'
    const homeSearch = page.getByLabel('input-home-search').first();
    const loginPath = `${targetUrl}/login`;

    // Try to detect existing session
    try {
        if (page.url().includes('/login')) {
            // We are on login page, proceed to fill
        } else {
            // Check if we can see the home search bar AND the profile button
            // This is more robust than just checking one.
            const profileBtn = page.getByLabel('menu-profile').first();
            const [searchVisible, profileVisible] = await Promise.all([
                homeSearch.isVisible({ timeout: 5000 }).catch(() => false),
                profileBtn.isVisible({ timeout: 5000 }).catch(() => false)
            ]);

            if (searchVisible && profileVisible) {
                console.log(`   ✅ Already logged in as ${email}. Skipping login.`);
                return;
            }
        }
    } catch (e) {
        // Ignore and proceed with login
    }

    // Proceed with login if not already logged in
    if (!page.url().includes('/login')) {
        await page.goto(loginPath);
    }

    // Using verified semantic labels from our app standardization
    const emailInput = page.getByLabel('login_email_field').first();
    await expect(emailInput).toBeVisible({ timeout: 30000 });
    await emailInput.fill(email);

    const passwordInput = page.getByLabel('login_password_field').first();
    await expect(passwordInput).toBeVisible({ timeout: 30000 });
    await passwordInput.fill(pass);

    const submitBtn = page.getByLabel('login_submit_button').first();
    await submitBtn.click({ force: true });

    // Proven success marker: Search Bar on home screen
    await expect(homeSearch).toBeVisible({ timeout: 60000 });

    console.log(`   ✅ Login successful for ${email}`);

    // Standard navigation to start tests from home
    if (!page.url().endsWith('/') && !page.url().endsWith(`${targetUrl}`)) {
        await page.goto(`${targetUrl}/`);
        // Only wait if navigation actually happened
        await waitForFlutter(page, 30000);
    }
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
