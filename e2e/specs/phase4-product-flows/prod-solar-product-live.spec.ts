/**
 * Production solar product live verification.
 *
 * Safe checks only:
 * - verifies the live product document and solar asset URLs
 * - verifies the production product page requests the live product data
 * - verifies the corrected Stripe/passkeys script tags no longer emit the prior
 *   SRI/CORS console failures on the live page
 *
 * No live payment submission is performed here.
 */
import { describe, expect, test } from 'bun:test';
import { chromium } from 'playwright';

const PROD_API_URL = 'https://api.orignagta.ca';
const PROD_WEB_URL = 'https://orignagta.ca';
const PRODUCT_ID = '207123c5-a5ee-4a8e-8f3b-434664110bc0';
const PRODUCT_URL = `${PROD_WEB_URL}/product/${PRODUCT_ID}`;
const EXPECTED_TITLE =
  '10KW Hybrid Solar System - Split Phase AC120V + Home Delivery + Installation';
const EXPECTED_DESCRIPTION_SNIPPET =
  'Complete combo module for a split phase AC120V 10KW Hybrid Solar System';
const EXPECTED_IMAGE_URLS = [
  `${PROD_WEB_URL}/product-assets/solar/solar-panel.jpeg`,
  `${PROD_WEB_URL}/product-assets/solar/hybrid-inverter.jpeg`,
  `${PROD_WEB_URL}/product-assets/solar/battery-cabinet.jpeg`,
  `${PROD_WEB_URL}/product-assets/solar/combiner-box.jpeg`,
] as const;

type ProductDoc = {
  id: string;
  title?: string;
  name?: string;
  description?: string;
  imageUrls?: string[];
  sellerName?: string;
  priceCents?: number;
  lifecycleStatus?: string;
};

async function fetchProductDoc(): Promise<ProductDoc> {
  const query = `query GetDoc($collection:String!,$id:String!){ get(collection:$collection,id:$id) }`;
  const res = await fetch(`${PROD_API_URL}/graphql`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      query,
      variables: { collection: 'products', id: PRODUCT_ID },
    }),
  });
  expect(res.status).toBe(200);
  const body = (await res.json()) as { data?: { get?: ProductDoc } };
  expect(body.data?.get).toBeTruthy();
  return body.data!.get!;
}

describe('Production solar product live verification', () => {
  test('production product document has expected title, seller, price, and solar assets', async () => {
    const product = await fetchProductDoc();

    expect(product.id).toBe(PRODUCT_ID);
    expect(product.title ?? product.name).toBe(EXPECTED_TITLE);
    expect(product.description).toContain(EXPECTED_DESCRIPTION_SNIPPET);
    expect(product.sellerName).toBe('OrignaVentures');
    expect(product.priceCents).toBe(1_300_000);
    expect(product.lifecycleStatus).toBe('active');
    expect(product.imageUrls).toEqual(EXPECTED_IMAGE_URLS);

    for (const imageUrl of EXPECTED_IMAGE_URLS) {
      const imageRes = await fetch(imageUrl);
      expect(imageRes.status).toBe(200);
    }
  }, 60_000);

  test('production product page requests the live product doc and solar asset without prior Stripe/passkeys console failures', async () => {
    const browser = await chromium.launch({ headless: true });
    const page = await browser.newPage({ viewport: { width: 1440, height: 1400 } });
    const consoleMessages: string[] = [];
    const matchingGraphqlBodies: string[] = [];
    const matchedAssets = new Set<string>();

    page.on('console', (message) => {
      consoleMessages.push(`${message.type()}: ${message.text()}`);
    });

    page.on('response', async (response) => {
      const responseUrl = response.url();
      if (responseUrl.includes('/graphql')) {
        try {
          const text = await response.text();
          if (text.includes(PRODUCT_ID) || text.includes(EXPECTED_TITLE)) {
            matchingGraphqlBodies.push(text);
          }
        } catch {}
      }

      if (EXPECTED_IMAGE_URLS.includes(responseUrl as (typeof EXPECTED_IMAGE_URLS)[number])) {
        matchedAssets.add(responseUrl);
      }
    });

    await page.goto(PRODUCT_URL, { waitUntil: 'load', timeout: 60_000 });
    await page.waitForTimeout(15_000);

    const scriptInfo = await page.evaluate(() => ({
      stripeScript: [...document.scripts].find((script) =>
        script.src.includes('js.stripe.com/v3/'),
      )?.outerHTML,
      passkeyScript: [...document.scripts].find((script) =>
        script.src.includes('flutter-passkeys'),
      )?.outerHTML,
      glassPanePresent: !!document.querySelector('flt-glass-pane'),
    }));

    expect(scriptInfo.glassPanePresent).toBe(true);
    expect(scriptInfo.stripeScript).toContain('https://js.stripe.com/v3/');
    expect(scriptInfo.stripeScript).not.toContain('integrity=');
    expect(scriptInfo.passkeyScript).toContain('flutter-passkeys');
    expect(scriptInfo.passkeyScript).not.toContain('crossorigin=');
    expect(matchingGraphqlBodies.length).toBeGreaterThan(0);
    expect([...matchedAssets]).toContain(EXPECTED_IMAGE_URLS[0]);

    const joinedConsole = consoleMessages.join('\n');
    expect(joinedConsole).not.toContain('Failed to find a valid digest in the \'integrity\' attribute');
    expect(joinedConsole).not.toContain('Access to script at \'https://github.com/corbado/flutter-passkeys/releases/download/2.4.0/bundle.js\'');
    expect(joinedConsole).not.toContain('Failed to load resource: net::ERR_FAILED');

    await browser.close();
  }, 90_000);
});
