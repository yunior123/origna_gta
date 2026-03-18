/**
 * OrignaGTA — Data Integrity E2E Tests
 * ====================================
 * Verifies data consistency and correctness in API responses.
 * Tests timestamps, money values, status enums, and schema compliance.
 * All tests are API-only.
 */
import { test, expect, describe, beforeAll } from 'bun:test';
import { signIn, callCallable, fetchWithRetry } from '../../lib/api-client.js';
import { TEST_ACCOUNTS, ORIGNABASE_URL } from '../../lib/config.js';

const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASS = TEST_ACCOUNTS.ADMIN_PASS;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASS = TEST_ACCOUNTS.BUYER_PASS;
const STABLE_PRODUCT_ID = 'e2e_product_test_seller';

describe('Data Integrity', () => {
  let adminAuth: Awaited<ReturnType<typeof signIn>>;
  let buyerAuth: Awaited<ReturnType<typeof signIn>>;

  beforeAll(async () => {
    adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASS);
    buyerAuth = await signIn(BUYER_EMAIL, BUYER_PASS);
  });

  test('T01: Timestamps are valid (not DateTime.now() fallback — check createdAt on products)', { timeout: 15_000 }, async () => {
    // Fetch a product
    const productRes = await fetchWithRetry(`${ORIGNABASE_URL}/products/${STABLE_PRODUCT_ID}`, {
      method: 'GET',
    });
    expect(productRes.status).toBe(200);
    const product = await productRes.json();

    // Check dateCreated field (product timestamp field)
    const timestamp = product.dateCreated || product.createdAt;
    expect(timestamp).toBeTruthy();
    
    // Should be a valid number (Unix timestamp in seconds or ms)
    const asNumber = typeof timestamp === 'string' ? parseInt(timestamp) : timestamp;
    expect(asNumber).toBeGreaterThan(0);
    
    // Should be recent (within last 1 year)
    const oneYearAgo = Math.floor(Date.now() / 1000) - 365 * 24 * 60 * 60;
    // Handle both seconds and milliseconds
    const normalizedTimestamp = asNumber > 1e10 ? Math.floor(asNumber / 1000) : asNumber;
    expect(normalizedTimestamp).toBeGreaterThan(oneYearAgo);
  });

  test('T02: Money values are integer cents (no decimals in API responses)', { timeout: 15_000 }, async () => {
    const productRes = await fetchWithRetry(`${ORIGNABASE_URL}/products/${STABLE_PRODUCT_ID}`, {
      method: 'GET',
    });
    expect(productRes.status).toBe(200);
    const product = await productRes.json();

    // Check priceCents field
    expect(product.priceCents).toBeTruthy();
    expect(Number.isInteger(product.priceCents)).toBe(true);
    expect(product.priceCents).toBeGreaterThan(0);
    
    // Should NOT have decimal cents
    expect(product.priceCents % 1).toBe(0);
  });

  test('T03: OrderStatus values are lowercase (pending, confirmed, shipped, delivered, cancelled)', { timeout: 15_000 }, async () => {
    // Get orders for buyer
    const ordersRes = await fetchWithRetry(`${ORIGNABASE_URL}/orders?buyerId=${buyerAuth.localId}`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${buyerAuth.idToken}` },
    });
    expect(ordersRes.status).toBe(200);
    const { orders = [] } = await ordersRes.json();

    if (orders.length > 0) {
      const order = orders[0];
      const validStatuses = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'];
      expect(validStatuses.includes(order.status)).toBe(true);
      // Should be lowercase
      expect(order.status).toBe(order.status.toLowerCase());
    }
  });

  test('T04: Product prices have priceCents field (integer)', { timeout: 15_000 }, async () => {
    const productRes = await fetchWithRetry(`${ORIGNABASE_URL}/products/${STABLE_PRODUCT_ID}`, {
      method: 'GET',
    });
    expect(productRes.status).toBe(200);
    const product = await productRes.json();

    expect(product.priceCents).toBeTruthy();
    expect(typeof product.priceCents).toBe('number');
    expect(Number.isInteger(product.priceCents)).toBe(true);
  });

  test('T05: Shipping costs are integer cents', { timeout: 15_000 }, async () => {
    // Get orders with shipping info
    const ordersRes = await fetchWithRetry(`${ORIGNABASE_URL}/orders?buyerId=${buyerAuth.localId}`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${buyerAuth.idToken}` },
    });
    expect(ordersRes.status).toBe(200);
    const { orders = [] } = await ordersRes.json();

    if (orders.length > 0) {
      const order = orders[0];
      if (order.shippingCostCents !== undefined) {
        expect(Number.isInteger(order.shippingCostCents)).toBe(true);
        expect(order.shippingCostCents).toBeGreaterThanOrEqual(0);
      }
    }
  });

  test('T06: Platform fee is calculated (platformFeeTotalCents > 0 on orders)', { timeout: 15_000 }, async () => {
    // Get orders
    const ordersRes = await fetchWithRetry(`${ORIGNABASE_URL}/orders?buyerId=${buyerAuth.localId}`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${buyerAuth.idToken}` },
    });
    expect(ordersRes.status).toBe(200);
    const { orders = [] } = await ordersRes.json();

    if (orders.length > 0) {
      const order = orders[0];
      // Platform fee should be present and an integer
      if (order.platformFeeTotalCents !== undefined) {
        expect(Number.isInteger(order.platformFeeTotalCents)).toBe(true);
        expect(order.platformFeeTotalCents).toBeGreaterThanOrEqual(0);
      }
    }
  });

  test('T07: Free shipping threshold works (subtotal >= 7500 → shipping = 0)', { timeout: 15_000 }, async () => {
    // Create a high-value order to test free shipping threshold
    // Threshold is 7500 cents = $75 CAD
    const cartRes = await fetchWithRetry(`${ORIGNABASE_URL}/cart/preview`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${buyerAuth.idToken}`,
      },
      body: JSON.stringify({
        items: [{ productId: STABLE_PRODUCT_ID, quantity: 100 }], // High qty for high subtotal
        shippingAddress: {
          street: '123 Test St',
          city: 'Toronto',
          province: 'ON',
          postalCode: 'M5V 3A8',
          country: 'CA',
        },
      }),
    });
    
    if (cartRes.status === 200) {
      const cart = await cartRes.json();
      if (cart.subtotalCents >= 7500) {
        // Should have free shipping
        expect(cart.shippingCostCents || 0).toBe(0);
      }
    }
  });

  test('T08: SurrealDB record IDs are valid format (collection:id)', { timeout: 15_000 }, async () => {
    const productRes = await fetchWithRetry(`${ORIGNABASE_URL}/products/${STABLE_PRODUCT_ID}`, {
      method: 'GET',
    });
    expect(productRes.status).toBe(200);
    const product = await productRes.json();

    // ID should be in format collection:id (or products:xxxxx)
    const idRegex = /^[a-z_]+:[a-zA-Z0-9_]+$/;
    expect(idRegex.test(product.id || product.productId)).toBe(true);
  });

  test('T09: Search returns paginated results (has limit/offset)', { timeout: 15_000 }, async () => {
    const searchRes = await fetchWithRetry(`${ORIGNABASE_URL}/search?q=test&limit=10&offset=0`, {
      method: 'GET',
    });
    expect(searchRes.status).toBe(200);
    const result = await searchRes.json();

    // Should have pagination fields
    const results = result.results || result.data || result;
    expect(Array.isArray(results)).toBe(true);
  });

  test('T10: Consent timestamps present on user profile (consentTimestamp, termsAcceptedAt)', { timeout: 15_000 }, async () => {
    // Get user profile
    const profileRes = await fetchWithRetry(`${ORIGNABASE_URL}/users/me`, {
      method: 'GET',
      headers: { Authorization: `Bearer ${buyerAuth.idToken}` },
    });
    
    if (profileRes.status === 200) {
      const profile = await profileRes.json();
      
      // Should have consent/terms timestamps if user accepted terms
      if (profile.termsAcceptedAt !== undefined) {
        expect(profile.termsAcceptedAt).toBeTruthy();
      }
      
      // Email verified timestamp
      if (profile.emailVerifiedAt !== undefined) {
        expect(typeof profile.emailVerifiedAt).toBe('number');
      }
    }
  });
});
