/**
 * Focused mobile pricing verification for OrignaVentures.
 * Keeps coverage short and stable while the broader legacy live suite remains flaky.
 */
import { test, expect } from 'bun:test';
import { chromium, devices } from 'playwright';

const VENTURES_WEB_URL = 'https://orignaventures.ca';
const VENTURES_MOBILE = devices['iPhone 12'];

async function openMobilePage() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ ...VENTURES_MOBILE });
  const page = await context.newPage();
  await page.goto(VENTURES_WEB_URL, {
    waitUntil: 'domcontentloaded',
    timeout: 60_000,
  });
  await page.waitForLoadState('load', { timeout: 20_000 }).catch(() => {});
  await page.waitForTimeout(2_000);
  return { browser, context, page };
}

async function closeMobilePage(browser: any, context: any) {
  await context.close();
  await browser.close();
}

async function enableFlutterSemantics(page: any) {
  const accessibilityToggle = page.locator('[aria-label="Enable accessibility"]');
  if (await accessibilityToggle.count()) {
    await accessibilityToggle.first().click({ force: true });
    await page.waitForTimeout(1_500);
  }
}

async function acceptCookiesIfVisible(page: any) {
  const acceptButton = page.locator('[aria-label="btn-cookie-accept"]');
  if (await acceptButton.count()) {
    await acceptButton.first().click();
    await page.waitForTimeout(1_000);
  }
}

test('mobile pricing reveals deck + all tier buy buttons', async () => {
  const { browser, context, page } = await openMobilePage();
  try {
    await enableFlutterSemantics(page);
    await acceptCookiesIfVisible(page);

    const viewPlans = page.locator('[aria-label="btn-hero-view-plans"]').first();
    await viewPlans.waitFor({ state: 'visible', timeout: 20_000 });
    await viewPlans.click();
    await page.waitForTimeout(2_000);
    await page.evaluate(() => window.scrollBy(0, 900));
    await page.waitForTimeout(1_000);

    await page.getByText(/View the investor deck|Voir le deck investisseur|Ver el deck para inversionistas/i).first().waitFor({ state: 'visible', timeout: 20_000 });
    await page.locator('[aria-label="btn-tier-buy-origna_code"]').first().waitFor({ state: 'visible', timeout: 20_000 });
    await page.locator('[aria-label="btn-tier-buy-origna_launch"]').first().waitFor({ state: 'visible', timeout: 20_000 });
    await page.locator('[aria-label="btn-tier-buy-origna_team"]').first().waitFor({ state: 'visible', timeout: 20_000 });
    expect(await page.getByText(/View the investor deck|Voir le deck investisseur|Ver el deck para inversionistas/i).count()).toBeGreaterThan(0);
    expect(await page.locator('[aria-label="btn-tier-buy-origna_code"]').count()).toBeGreaterThan(0);
    expect(await page.locator('[aria-label="btn-tier-buy-origna_launch"]').count()).toBeGreaterThan(0);
    expect(await page.locator('[aria-label="btn-tier-buy-origna_team"]').count()).toBeGreaterThan(0);
  } finally {
    await closeMobilePage(browser, context);
  }
}, 90_000);

test('mobile launch tier redirects to Stripe checkout', async () => {
  const { browser, context, page } = await openMobilePage();
  try {
    await enableFlutterSemantics(page);
    await acceptCookiesIfVisible(page);

    const viewPlans = page.locator('[aria-label="btn-hero-view-plans"]').first();
    await viewPlans.waitFor({ state: 'visible', timeout: 20_000 });
    await viewPlans.click();
    await page.waitForTimeout(2_000);
    await page.evaluate(() => window.scrollBy(0, 900));
    await page.waitForTimeout(1_000);

    const checkoutResponsePromise = page.waitForResponse(
      (response) =>
        response.url().includes('/payments/create-checkout-session') &&
        response.request().method() === 'POST',
      { timeout: 30_000 },
    );
    const stripeNavigationPromise = page.waitForURL(/https:\/\/checkout\.stripe\.com\/.*/, {
      timeout: 30_000,
    });

    const launchButton = page.locator('[aria-label="btn-tier-buy-origna_launch"]').first();
    await launchButton.waitFor({ state: 'visible', timeout: 20_000 });
    await launchButton.click();

    const checkoutResponse = await checkoutResponsePromise;
    expect(checkoutResponse.status()).toBe(200);
    await stripeNavigationPromise;
    expect(page.url()).toContain('checkout.stripe.com');
  } finally {
    await closeMobilePage(browser, context);
  }
}, 90_000);
