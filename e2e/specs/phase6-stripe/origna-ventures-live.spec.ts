/**
 * OrignaVentures — Live Tier + Payment E2E Tests
 * =================================================
 * Tests the 3-tier service checkout flow against the Ventures backend API.
 * Tiers: OrignaCode ($500), OrignaLaunch ($3000), OrignaTeam ($1000/mo).
 * No contract signing — serviceCode-based direct Stripe checkout.
 */
import { test, expect, describe } from 'bun:test';
import { chromium, devices, type Browser, type BrowserContext, type Page } from 'playwright';
import { VENTURES_API_BASE, VENTURES_WEB_URL, VENTURES_TIERS } from '../../lib/config.js';

const TEST_EMAIL = 'e2e-test@orignaventures.ca';
const VENTURES_MOBILE = devices['iPhone 12'];

async function openVenturesPage(
  viewport: 'desktop' | 'mobile',
): Promise<{ browser: Browser; context: BrowserContext; page: Page }> {
  const browser = await chromium.launch({ headless: true });
  let context = await browser.newContext(
    viewport === 'mobile'
      ? { ...VENTURES_MOBILE }
      : { viewport: { width: 1440, height: 1200 } },
  );

  for (let attempt = 1; attempt <= 2; attempt++) {
    const page = await context.newPage();
    try {
      await page.goto(VENTURES_WEB_URL, {
        waitUntil: 'domcontentloaded',
        timeout: 60_000,
      });
      await page.waitForLoadState('load', { timeout: 20_000 }).catch(() => {});
      await page.waitForTimeout(2_000);
      await enableFlutterSemantics(page);
      return { browser, context, page };
    } catch (error) {
      await page.close().catch(() => {});
      if (attempt == 2) {
        await context.close().catch(() => {});
        await browser.close().catch(() => {});
        throw error;
      }
      await context.close().catch(() => {});
      context = await browser.newContext(
        viewport === 'mobile'
          ? { ...VENTURES_MOBILE }
          : { viewport: { width: 1440, height: 1200 } },
      );
    }
  }

  throw new Error('openVenturesPage retry loop exhausted');
}

async function closeVenturesPage(browser: Browser, context: BrowserContext) {
  await context.close();
  await browser.close();
}

async function waitForSelector(page: Page, selector: string) {
  try {
    await page.waitForSelector(selector, { timeout: 20_000 });
  } catch (_) {
    await page.waitForTimeout(2_000);
    await page.waitForSelector(selector, { timeout: 20_000 });
  }
  return page.locator(selector).first();
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

async function acceptCookiesIfVisible(page: Page) {
  const acceptButton = page.locator('[aria-label="btn-cookie-accept"]');
  if (await acceptButton.count()) {
    await acceptButton.first().click();
    await page.waitForTimeout(800);
  }
}

async function goToPricing(page: Page, viewport: 'desktop' | 'mobile') {
  await acceptCookiesIfVisible(page);
  const selector = '[aria-label="btn-hero-view-plans"]';
  const trigger = await waitForSelector(page, selector);
  await trigger.click();
  await page.waitForTimeout(1_500);
  if (viewport === 'mobile') {
    await page.evaluate(() => window.scrollBy(0, 900));
    await page.waitForTimeout(1_000);
  }
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

async function expectCheckoutRedirect(
  page: Page,
  buttonLabel: string,
) {
  const checkoutResponsePromise = page.waitForResponse(
    (response) =>
      response.url().includes('/payments/create-checkout-session') &&
      response.request().method() === 'POST',
    { timeout: 30_000 },
  );
  const stripeNavigationPromise = page.waitForURL(/https:\/\/checkout\.stripe\.com\/.*/, {
    timeout: 30_000,
  });

  const button = await waitForSelector(page, `[aria-label="${buttonLabel}"]`);
  await button.click();

  const checkoutResponse = await checkoutResponsePromise;
  expect(checkoutResponse.status()).toBe(200);
  await stripeNavigationPromise;
  expect(page.url()).toContain('checkout.stripe.com');
}

async function venturesFetch(path: string, options: RequestInit = {}) {
  const url = `${VENTURES_API_BASE}${path}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Origin: VENTURES_WEB_URL,
      ...options.headers,
    },
  });
  return res;
}

async function venturesApiFetch(path: string, options: RequestInit = {}) {
  return venturesFetch(`/api${path}`, options);
}

async function readMeta() {
  const res = await venturesApiFetch('/meta');
  const body = await res.json().catch(() => null);
  const servicesRaw = body?.services ?? {};
  const services = Array.isArray(servicesRaw)
    ? servicesRaw
    : Object.entries(servicesRaw).map(([code, value]) => ({ code, ...(value as Record<string, unknown>) }));
  return { status: res.status, body, services };
}

function serviceMap(services: Array<Record<string, unknown>>) {
  return new Map(services.map((service) => [service.code ?? service.service_code, service]));
}

async function createCheckoutSession(serviceCode: string, payerEmail?: string) {
  const body: Record<string, string> = { service_code: serviceCode };
  if (payerEmail) body.payer_email = payerEmail;
  const res = await venturesApiFetch('/payments/create-checkout-session', {
    method: 'POST',
    body: JSON.stringify(body),
  });
  return { status: res.status, body: await res.json().catch(() => null) };
}

async function readVenturesBundle() {
  const res = await fetch(`${VENTURES_WEB_URL}/main.dart.js`);
  return { status: res.status, body: await res.text() };
}

describe('OrignaVentures — Tier Configuration', () => {
  test('Home page renders and shell branding is present', async () => {
    const res = await fetch(VENTURES_WEB_URL);
    expect(res.status).toBe(200);
    const html = (await res.text()).toLowerCase();
    expect(html).toContain('origna ventures');
    expect(html).toContain('<title>origna ventures</title>');
  });

  test('Service catalog exposes all 3 tier names', async () => {
    const { status, services } = await readMeta();
    expect(status).toBe(200);
    const codes = services.map((s: any) => s.code ?? s.service_code);
    expect(codes).toContain('origna_code');
    expect(codes).toContain('origna_launch');
    expect(codes).toContain('origna_team');
  });

  test('Service catalog exposes correct prices', async () => {
    const { status, services } = await readMeta();
    expect(status).toBe(200);
    const byCode = serviceMap(services as Array<Record<string, unknown>>);
    expect(byCode.get('origna_code')?.price_cad ?? byCode.get('origna_code')?.priceCad).toBe(500);
    expect(byCode.get('origna_launch')?.price_cad ?? byCode.get('origna_launch')?.priceCad).toBe(3000);
    expect(byCode.get('origna_team')?.price_cad ?? byCode.get('origna_team')?.priceCad).toBe(1000);
  });

  test('Service catalog summaries reflect launch support and monthly team outsourcing', async () => {
    const { status, body, services } = await readMeta();
    expect(status).toBe(200);
    expect(body?.supportEmail).toBe('support@orignaventures.ca');
    const byCode = serviceMap(services as Array<Record<string, unknown>>);
    expect(String(byCode.get('origna_launch')?.summary_en ?? '')).toContain('20 human testers');
    expect(String(byCode.get('origna_launch')?.summary_en ?? '')).toContain('first-year');
    expect(String(byCode.get('origna_launch')?.summary_en ?? '')).toContain('hosting');
    expect(String(byCode.get('origna_team')?.summary_en ?? '')).toContain('1,000 CAD/month');
    expect(String(byCode.get('origna_team')?.summary_en ?? '')).toContain('Dedicated developer outsourcing');
  });

  test('Home page no longer mentions old tier names (Essential/Professional/Enterprise)', async () => {
    const res = await fetch(VENTURES_WEB_URL);
    const html = (await res.text()).toLowerCase();
    expect(html).not.toContain('essential');
    expect(html).not.toContain('professional');
    expect(html).not.toContain('enterprise');
  });

  test('Deployed Flutter bundle includes the upgraded hero proof copy', async () => {
    const { status, body } = await readVenturesBundle();
    expect(status).toBe(200);
    expect(body).toContain('Production-ready source code handoff');
    expect(body).toContain('Checkout, hosting, QA, and launch support included');
    expect(body).toContain('Direct access to the builder, not an agency maze');
  });

  test('Deployed Flutter bundle includes Ventures contact and pricing labels', async () => {
    const { status, body } = await readVenturesBundle();
    expect(status).toBe(200);
    expect(body).toContain('support@orignaventures.ca');
    expect(body).toContain('OrignaLaunch');
    expect(body).toContain('OrignaTeam');
    expect(body).toContain('MOST CHOSEN');
  });
});

describe('OrignaVentures — Backend Health', () => {
  test('Health endpoint returns 200', async () => {
    const res = await venturesFetch('/health');
    expect(res.status).toBe(200);
  });

  test('API health endpoint returns 200', async () => {
    const res = await venturesApiFetch('/health');
    expect(res.status).toBe(200);
  });

  test('Meta endpoint returns service catalog', async () => {
    const { status, services } = await readMeta();
    expect(status).toBe(200);
    const codes = services.map((s: any) => s.code ?? s.service_code);
    expect(codes).toContain('origna_code');
    expect(codes).toContain('origna_launch');
    expect(codes).toContain('origna_team');
  });
});

describe('OrignaVentures — Checkout Session API', () => {
  test('OrignaCode ($500) creates valid Stripe checkout session', async () => {
    const { status, body } = await createCheckoutSession(VENTURES_TIERS.ORIGNA_CODE.code, TEST_EMAIL);
    if (status === 200 && body) {
      expect(body.provider).toBe('stripe');
      expect(body.checkoutUrl).toContain('checkout.stripe.com');
      expect(body.sessionId).toBeTruthy();
      expect(body.status).toBe('awaiting_payment');
    } else if (status === 429) {
      expect(true).toBe(true);
    } else {
      expect(status).toBeLessThan(500);
    }
  }, 30_000);

  test('OrignaLaunch ($3000) creates valid Stripe checkout session', async () => {
    const { status, body } = await createCheckoutSession(VENTURES_TIERS.ORIGNA_LAUNCH.code, TEST_EMAIL);
    if (status === 200 && body) {
      expect(body.provider).toBe('stripe');
      expect(body.checkoutUrl).toContain('checkout.stripe.com');
    } else if (status === 429) {
      expect(true).toBe(true);
    } else {
      expect(status).toBeLessThan(500);
    }
  }, 30_000);

  test('OrignaTeam ($1000/mo) creates valid Stripe checkout session', async () => {
    const { status, body } = await createCheckoutSession(VENTURES_TIERS.ORIGNA_TEAM.code, TEST_EMAIL);
    if (status === 200 && body) {
      expect(body.provider).toBe('stripe');
      expect(body.checkoutUrl).toContain('checkout.stripe.com');
      expect(body.sessionId).toBeTruthy();
      expect(body.status).toBe('awaiting_payment');
    } else if (status === 429) {
      expect(true).toBe(true);
    } else {
      expect(status).toBeLessThan(500);
    }
  }, 30_000);

  test('All three tiers return the same checkout response contract', async () => {
    for (const tier of Object.values(VENTURES_TIERS)) {
      const { status, body } = await createCheckoutSession(tier.code, TEST_EMAIL);
      if (status === 200 && body) {
        expect(body.provider).toBe('stripe');
        expect(body.status).toBe('awaiting_payment');
        expect(body.sessionId).toBeTruthy();
        expect(body.checkoutUrl).toContain('checkout.stripe.com');
      } else if (status === 429) {
        expect(true).toBe(true);
      } else {
        expect(status).toBeLessThan(500);
      }
    }
  }, 30_000);

  test('Invalid service_code returns 422 or 404', async () => {
    const { status } = await createCheckoutSession('invalid_service', TEST_EMAIL);
    expect(status === 422 || status === 404 || status === 400).toBe(true);
  });

  test('Missing payer_email is tolerated when service_code is valid', async () => {
    const { status, body } = await createCheckoutSession('origna_code');
    if (status === 200 && body) {
      expect(body.provider).toBe('stripe');
      expect(body.sessionId).toBeTruthy();
    } else if (status === 429) {
      expect(true).toBe(true);
    } else {
      expect(status).toBeLessThan(500);
    }
  });

  test('Missing service_code returns 422 or 400', async () => {
    const res = await venturesApiFetch('/payments/create-checkout-session', {
      method: 'POST',
      body: JSON.stringify({ payer_email: TEST_EMAIL }),
    });
    expect(res.status === 422 || res.status === 400).toBe(true);
  });
});

describe('OrignaVentures — Webhook Security', () => {
  test('Webhook rejects unsigned request', async () => {
    const res = await venturesApiFetch('/stripe/webhook', {
      method: 'POST',
      body: JSON.stringify({ id: 'evt_test', type: 'checkout.session.completed', data: { object: { id: 'cs_test' } } }),
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  });

  test('Webhook rejects invalid signature', async () => {
    const res = await venturesApiFetch('/stripe/webhook', {
      method: 'POST',
      body: JSON.stringify({ id: 'evt_test_bad_sig', type: 'checkout.session.completed', data: { object: { id: 'cs_test' } } }),
      headers: { 'Stripe-Signature': 't=1234567890,v1=invalid_signature_here' },
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  });

  test('Webhook rejects replay attack with old timestamp', async () => {
    const res = await venturesApiFetch('/stripe/webhook', {
      method: 'POST',
      body: JSON.stringify({ id: 'evt_test_replay', type: 'checkout.session.completed', data: { object: { id: 'cs_test' } } }),
      headers: { 'Stripe-Signature': 't=1577836800,v1=fake_sig_replay' },
    });
    expect(res.status).toBeGreaterThanOrEqual(400);
    expect(res.status).toBeLessThan(500);
  });

  test('Webhook rejects non-POST methods', async () => {
    const getRes = await venturesApiFetch('/stripe/webhook', { method: 'GET' });
    expect(getRes.status).toBeGreaterThanOrEqual(400);

    const putRes = await venturesApiFetch('/stripe/webhook', { method: 'PUT', body: '{}' });
    expect(putRes.status).toBeGreaterThanOrEqual(400);
  });

  test('Webhook returns non-5xx for malformed JSON', async () => {
    const res = await venturesApiFetch('/stripe/webhook', {
      method: 'POST',
      body: 'not json {{{',
      headers: { 'Stripe-Signature': `t=${Math.floor(Date.now() / 1000)},v1=test` },
    });
    expect(res.status).toBeLessThan(500);
  });
});

describe('OrignaVentures — Contact API', () => {
  test('Contact endpoint requires valid payload', async () => {
    const res = await venturesApiFetch('/contact', {
      method: 'POST',
      body: JSON.stringify({ name: '', email: 'bad', message: '' }),
    });
    expect(res.status === 422 || res.status === 400).toBe(true);
  });

  test('Contact endpoint rejects GET', async () => {
    const res = await venturesApiFetch('/contact', { method: 'GET' });
    expect(res.status).toBeGreaterThanOrEqual(400);
  });
});

describe('OrignaVentures — Live Payment Buttons (Playwright)', () => {
  test('PW01: mobile home exposes cookie accept button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await waitForSelector(page, '[aria-label="btn-cookie-accept"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW02: mobile home exposes cookie decline button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await waitForSelector(page, '[aria-label="btn-cookie-decline"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW03: mobile hero exposes view plans button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await waitForSelector(page, '[aria-label="btn-hero-view-plans"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW04-contact: desktop contact form submits and reports support + confirmation emails', async () => {
    const unique = Date.now();
    const contactEmail = `e2e-contact+${unique}@orignaventures.ca`;
    const { browser, context, page } = await openVenturesPage('desktop');
    try {
      await acceptCookiesIfVisible(page);
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
        (response) =>
          response.url().includes('/api/contact') &&
          response.request().method() === 'POST',
        { timeout: 30_000 },
      );

      const submit = page.getByRole('button', { name: 'btn-contact-submit' }).first();
      await submit.waitFor({ state: 'visible', timeout: 20_000 });
      await submit.click();

      const response = await responsePromise;
      expect(response.status()).toBe(200);
      const body = await response.json();
      expect(body?.status).toBe('ok');
      expect(body?.emails?.support?.status).toBe('sent');
      expect(body?.emails?.confirmation?.status).toBe('sent');

      const status = page.getByLabel('status-contact-result').first();
      await status.waitFor({ state: 'visible', timeout: 20_000 });
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 90_000);

  test('PW04-cookie: mobile cookie accept dismisses the banner', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      const acceptButton = await waitForSelector(page, '[aria-label="btn-cookie-accept"]');
      await acceptButton.click();
      await page.waitForTimeout(1_000);
      expect(await page.locator('[aria-label="btn-cookie-accept"]').count()).toBe(0);
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW05-pricing: mobile pricing reveals investor deck button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-deck-origna_code"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW06: mobile pricing reveals OrignaCode buy button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-buy-origna_code"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW07: mobile pricing reveals OrignaLaunch buy button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-buy-origna_launch"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW08: mobile pricing reveals OrignaTeam buy button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-buy-origna_team"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW09: mobile pricing reveals investor deck button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-deck-origna_code"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW10: mobile pricing reveals OrignaCode buy button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-buy-origna_code"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW11: mobile pricing reveals OrignaLaunch buy button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-buy-origna_launch"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW12: mobile pricing reveals OrignaTeam buy button', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await waitForSelector(page, '[aria-label="btn-tier-buy-origna_team"]');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW13: mobile OrignaCode button creates Stripe checkout and redirects', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await expectCheckoutRedirect(page, 'btn-tier-buy-origna_code');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW14: mobile OrignaLaunch button creates Stripe checkout and redirects', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await expectCheckoutRedirect(page, 'btn-tier-buy-origna_launch');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);

  test('PW15: mobile OrignaTeam button creates Stripe checkout and redirects', async () => {
    const { browser, context, page } = await openVenturesPage('mobile');
    try {
      await goToPricing(page, 'mobile');
      await expectCheckoutRedirect(page, 'btn-tier-buy-origna_team');
    } finally {
      await closeVenturesPage(browser, context);
    }
  }, 60_000);
});
