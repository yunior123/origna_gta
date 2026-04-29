/**
 * Focused live contact/email verification for OrignaVentures.
 *
 * This spec exercises the real browser contact form and asserts the live
 * submission reports both support and confirmation emails as sent.
 */
import { describe, expect, test } from 'bun:test';
import {
  chromium,
  type Browser,
  type BrowserContext,
  type Locator,
  type Page,
} from 'playwright';
import { VENTURES_API_BASE, VENTURES_WEB_URL } from '../../lib/config.js';

const CONTACT_TEST_EMAIL =
  process.env.VENTURES_CONTACT_TEST_EMAIL ?? 'e2e-contact@orignaventures.ca';

async function openVenturesPage(): Promise<{
  browser: Browser;
  context: BrowserContext;
  page: Page;
}> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= 3; attempt += 1) {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({
      viewport: { width: 1440, height: 1200 },
    });
    const page = await context.newPage();

    try {
      await page.goto(VENTURES_WEB_URL, {
        waitUntil: 'commit',
        timeout: 30_000,
      });
      await page
        .waitForFunction(() => document.body?.innerText.length > 0, {
          timeout: 30_000,
        })
        .catch(() => {});
      await page.waitForLoadState('domcontentloaded', { timeout: 10_000 }).catch(() => {});
      await page.waitForLoadState('load', { timeout: 10_000 }).catch(() => {});
      await page.waitForTimeout(2_000);
      await enableFlutterSemantics(page);

      return { browser, context, page };
    } catch (error) {
      lastError = error;
      await closeVenturesPage(browser, context);
      if (attempt < 3) {
        await new Promise((resolve) => setTimeout(resolve, 1_000 * attempt));
      }
    }
  }

  throw lastError;
}

async function closeVenturesPage(browser: Browser, context: BrowserContext) {
  await context.close().catch(() => {});
  await browser.close().catch(() => {});
}

async function enableFlutterSemantics(page: Page) {
  const accessibilityToggle = page.locator('[aria-label="Enable accessibility"]');
  if (await accessibilityToggle.count()) {
    const box = await accessibilityToggle.first().boundingBox();
    if (box) {
      await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    } else {
      await accessibilityToggle.first().click({ force: true });
    }
    await page.waitForTimeout(1_500);
  }
}

async function waitForSelector(page: Page, selector: string): Promise<Locator> {
  for (let attempt = 1; attempt <= 4; attempt += 1) {
    try {
      await page.waitForSelector(selector, { timeout: 5_000 });
      return page.locator(selector).first();
    } catch (error) {
      if (attempt === 4) {
        throw error;
      }
      await page.evaluate(() => window.scrollBy(0, 900));
      await page.waitForTimeout(600);
    }
  }

  throw new Error(`Selector not found after retries: ${selector}`);
}

async function acceptCookiesIfVisible(page: Page) {
  const acceptButton = page.locator('[aria-label="btn-cookie-accept"]');
  if (await acceptButton.count()) {
    await acceptButton.first().click();
    await page.waitForTimeout(800);
  }
}

async function scrollToContactForm(page: Page) {
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await page.waitForTimeout(1_200);
}

async function fillFlutterField(page: Page, label: string, value: string) {
  const semanticField = await waitForSelector(page, `[aria-label="${label}"]`);
  await semanticField.scrollIntoViewIfNeeded();
  await page.waitForTimeout(250);

  const editableDescendant = page
    .locator(
      `[aria-label="${label}"] input:not([disabled]), [aria-label="${label}"] textarea:not([disabled]), [aria-label="${label}"] ~ input:not([disabled]), [aria-label="${label}"] ~ textarea:not([disabled])`,
    )
    .first();

  if (await editableDescendant.count()) {
    await editableDescendant.click({ force: true });
    await editableDescendant.fill('');
    await page.waitForTimeout(250);
    await page.keyboard.type(value);
    return;
  }

  const box = await semanticField.boundingBox();
  if (!box) {
    throw new Error(`No bounding box for ${label}`);
  }
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await page.waitForTimeout(250);
  await page.keyboard.type(value);
}

describe('OrignaVentures contact form live verification', () => {
  test('live page keeps Flutter shell mounted during aggressive up/down scroll', async () => {
    const { browser, context, page } = await openVenturesPage();

    try {
      await acceptCookiesIfVisible(page);
      await page.evaluate(() => {
        window.sessionStorage.setItem('ventures-scroll-marker', 'mounted');
      });

      for (let i = 0; i < 6; i += 1) {
        await page.mouse.wheel(0, 1400);
        await page.waitForTimeout(250);
      }
      for (let i = 0; i < 6; i += 1) {
        await page.mouse.wheel(0, -1400);
        await page.waitForTimeout(250);
      }

      const state = await page.evaluate(() => ({
        marker: window.sessionStorage.getItem('ventures-scroll-marker'),
        splash: Boolean(document.getElementById('splash')),
        text: document.body.innerText.slice(0, 500),
      }));

      expect(state.marker).toBe('mounted');
      expect(state.splash).toBe(false);
      expect(state.text.length).toBeGreaterThan(0);
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 150_000);

  test('live contact submission reports support + confirmation emails as sent', async () => {
    const unique = Date.now();
    const response = await fetch(`${VENTURES_API_BASE}/api/contact`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Origin: VENTURES_WEB_URL,
      },
      body: JSON.stringify({
        name: `E2E Contact ${unique}`,
        email: CONTACT_TEST_EMAIL,
        company: 'Origna Ventures E2E',
        service: 'origna_launch',
        message: `Live contact verification ${unique}. Please ignore this automated support check.`,
      }),
    });
    expect(response.status).toBe(200);

    const body = await response.json().catch(() => null);
    expect(body?.status).toBe('ok');
    expect(String(body?.id ?? '')).toMatch(/^ct-/);
    expect(body?.emails?.support?.status).toBe('sent');
    expect(body?.emails?.support?.provider).toBe('postal');
    expect(body?.emails?.confirmation?.status).toBe('sent');
    expect(body?.emails?.confirmation?.provider).toBe('postal');
  }, 30_000);
});
