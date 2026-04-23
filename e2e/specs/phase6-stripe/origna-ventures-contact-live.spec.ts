/**
 * Focused live contact-form verification for OrignaVentures.
 *
 * This file exists separately from the broad ventures live suite so the contact
 * path can be rerun quickly while iterating on form semantics and email wiring.
 */
import { describe, expect, test } from 'bun:test';
import { chromium, type Browser, type BrowserContext, type Page } from 'playwright';

const VENTURES_WEB_URL = 'https://orignaventures.ca';

async function openPage(): Promise<{ browser: Browser; context: BrowserContext; page: Page }> {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 1200 } });
  const page = await context.newPage();
  await page.goto(VENTURES_WEB_URL, { waitUntil: 'networkidle', timeout: 60_000 });
  await page.waitForTimeout(3_000);

  const accessibilityToggle = page.locator('[aria-label="Enable accessibility"]').first();
  if (await accessibilityToggle.count()) {
    const box = await accessibilityToggle.boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
      await page.waitForTimeout(1_500);
    }
  }

  const acceptCookies = page.locator('[aria-label="btn-cookie-accept"]').first();
  if (await acceptCookies.count()) {
    await acceptCookies.click();
    await page.waitForTimeout(800);
  }

  return { browser, context, page };
}

async function closePage(browser: Browser, context: BrowserContext) {
  await context.close();
  await browser.close();
}

async function fillFlutterField(page: Page, label: string, value: string) {
  const semanticField = page.locator(`[aria-label="${label}"]`).first();
  await semanticField.waitFor({ state: 'visible', timeout: 20_000 });

  const editableDescendant = semanticField
    .locator('xpath=ancestor::flt-semantics[1]')
    .locator('input:not([disabled]), textarea:not([disabled])')
    .first();
  if (await editableDescendant.count()) {
    await editableDescendant.click();
    await page.waitForTimeout(250);
    await page.keyboard.type(value);
    return;
  }

  const box = await semanticField.boundingBox();
  if (!box) throw new Error(`No bounding box for ${label}`);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(250);
  await page.keyboard.type(value);
}

describe('OrignaVentures contact form live verification', () => {
  test('desktop contact form sends support + confirmation email according to live API response', async () => {
    const unique = Date.now();
    const contactEmail = `e2e-contact+${unique}@orignaventures.ca`;
    const { browser, context, page } = await openPage();

    try {
      await page.evaluate(() => window.scrollTo({ top: document.body.scrollHeight, behavior: 'instant' }));
      await page.waitForTimeout(1_500);

      await fillFlutterField(page, 'input-contact-name', `E2E Contact ${unique}`);
      await fillFlutterField(page, 'input-contact-email', contactEmail);
      await fillFlutterField(page, 'input-contact-company', 'Origna Ventures E2E');
      await fillFlutterField(
        page,
        'input-contact-message',
        `Live contact form verification ${unique}. Please ignore this automated support check.`,
      );

      const responsePromise = page.waitForResponse(
        (response) => response.url().includes('/api/contact') && response.request().method() === 'POST',
        { timeout: 30_000 },
      );

      await page.getByRole('button', { name: 'btn-contact-submit' }).first().click();

      const response = await responsePromise;
      expect(response.status()).toBe(200);
      const body = await response.json();
      expect(body?.status).toBe('ok');
      expect(String(body?.id ?? '')).toMatch(/^ct-/);
      expect(body?.emails?.support?.status).toBe('sent');
      expect(body?.emails?.confirmation?.status).toBe('sent');

      const status = page.getByLabel('status-contact-result').first();
      await status.waitFor({ state: 'visible', timeout: 20_000 });
    } finally {
      await closePage(browser, context);
    }
  }, 90_000);
});
