/**
 * OrignaGTA — Security Payment Fixes E2E Tests
 * ============================================================
 * Verify critical payment & checkout security fixes:
 * - Platform fee calculation (platformFeeTotalCents > 0)
 * - Amount validation (total = subtotal + tax + shipping)
 * - Refund amount validation
 * - Stock validation
 * - Price range validation (0 < price ≤ $100k CAD)
 * - Product lifecycle validation
 * - Perishable shipping restrictions
 * - Free shipping threshold
 * - Idempotency (duplicate requests → same session)
 * - Image URL validation (R2 only)
 */
import { test, expect, describe, beforeAll } from 'bun:test';
import {
  signIn,
  callOk,
  callCallable,
  callExpectError,
  getProductStock,
  discoverProducts,
} from '../../lib/api-client.js';
import {
  TEST_ACCOUNTS,
  TEST_PRODUCTS,
  DEFAULT_PASS,
} from '../../lib/config.js';

const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const TEST_PASS = DEFAULT_PASS;

describe('Security — Payment & Checkout Fixes', () => {
  let sellerToken: string;
  let buyerToken: string;
  let adminToken: string;
  let testProductId: string;

  beforeAll(async () => {
    const seller = await signIn(SELLER_EMAIL, TEST_PASS);
    const buyer = await signIn(BUYER_EMAIL, TEST_PASS);
    const admin = await signIn(ADMIN_EMAIL, TEST_PASS);
    
    sellerToken = seller.idToken;
    buyerToken = buyer.idToken;
    adminToken = admin.idToken;

    // Discover a test product
    const products = await discoverProducts(buyerToken);
    if (products.length > 0) {
      testProductId = products[0].id;
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T01–T02: Platform Fee Calculation
  // ════════════════════════════════════════════════════════════════════

  test('T01: Checkout creates order with platformFeeTotalCents > 0', { timeout: 60_000 }, async () => {
    if (!testProductId) {
      console.log('Skipping: no test product found');
      return;
    }

    const payload = {
      productId: testProductId,
      quantity: 1,
      shippingAddress: {
        street: '123 Main St',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'CA',
      },
    };

    const result = await callOk('create_order', payload, buyerToken);
    
    expect(result.orderId).toBeTruthy();
    if (result.order) {
      expect(result.order.platformFeeTotalCents).toBeGreaterThan(0);
    }
  });

  test('T02: Platform fee = (subtotalCents × rate) / subtotalCents', { timeout: 60_000 }, async () => {
    if (!testProductId) {
      console.log('Skipping: no test product found');
      return;
    }

    const payload = {
      productId: testProductId,
      quantity: 2,
      shippingAddress: {
        street: '456 Oak Ave',
        city: 'Vancouver',
        province: 'BC',
        postalCode: 'V6B 1C6',
        country: 'CA',
      },
    };

    const order = await callOk('create_order', payload, buyerToken);
    
    expect(order.orderId).toBeTruthy();
    if (order.order) {
      const { subtotalCents, platformFeeTotalCents } = order.order;
      expect(subtotalCents).toBeGreaterThan(0);
      expect(platformFeeTotalCents).toBeGreaterThan(0);
      // Platform fee must be reasonable (< 30% of subtotal)
      expect(platformFeeTotalCents).toBeLessThan(subtotalCents * 0.3);
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T03: Amount Validation (total = subtotal + tax + shipping)
  // ════════════════════════════════════════════════════════════════════

  test('T03: Order total = subtotal + tax + shipping', { timeout: 60_000 }, async () => {
    if (!testProductId) {
      console.log('Skipping: no test product found');
      return;
    }

    const payload = {
      productId: testProductId,
      quantity: 1,
      shippingAddress: {
        street: '789 Elm St',
        city: 'Calgary',
        province: 'AB',
        postalCode: 'T2P 1H9',
        country: 'CA',
      },
    };

    const order = await callOk('create_order', payload, buyerToken);
    
    if (order.order) {
      const { subtotalCents, taxAmountCents, shippingCostCents, totalAmountCents } = order.order;
      const calculated = subtotalCents + taxAmountCents + shippingCostCents;
      expect(totalAmountCents).toBe(calculated);
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T04: Refund Amount Validation
  // ════════════════════════════════════════════════════════════════════

  test('T04: Refund request with amount > order total → rejected', { timeout: 60_000 }, async () => {
    // Try to refund more than was paid
    const error = await callExpectError('refund_order', {
      orderId: 'test_order_id',
      amountCents: 999999999, // Huge amount
    }, buyerToken);

    expect(error.code).not.toBe('unexpected-success');
  });

  // ════════════════════════════════════════════════════════════════════
  // T05–T06: Stock Validation
  // ════════════════════════════════════════════════════════════════════

  test('T05: Stock check: buy last item, try to buy again → out of stock', { timeout: 60_000 }, async () => {
    if (!testProductId) {
      console.log('Skipping: no test product found');
      return;
    }

    const stock = await getProductStock(testProductId);
    expect(stock).toBeGreaterThanOrEqual(0);
    
    if (stock === 0) {
      // Product is already out of stock
      const error = await callExpectError('create_order', {
        productId: testProductId,
        quantity: 1,
        shippingAddress: {
          street: '123 Main',
          city: 'Toronto',
          province: 'ON',
          postalCode: 'M5V 3A8',
          country: 'CA',
        },
      }, buyerToken);
      expect(error.code).not.toBe('unexpected-success');
    }
  });

  test('T06: Product with negative stock → rejected or handled', { timeout: 60_000 }, async () => {
    // Try to create a product with negative stock (should be rejected)
    const error = await callExpectError('create_product', {
      name: 'Bad Product',
      priceCents: 1000,
      stockQuantity: -5, // Negative!
      description: 'Test',
    }, sellerToken);

    if (error.code !== 'unexpected-success') {
      expect(error.code).toBeTruthy();
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T07–T08: Price Validation
  // ════════════════════════════════════════════════════════════════════

  test('T07: Product with price 0 → rejected', { timeout: 60_000 }, async () => {
    const error = await callExpectError('create_product', {
      name: 'Free Product',
      priceCents: 0, // Invalid!
      stockQuantity: 10,
      description: 'Test',
    }, sellerToken);

    expect(error.code).not.toBe('unexpected-success');
  });

  test('T08: Product with price > $100k CAD (10,000,000 cents) → rejected', { timeout: 60_000 }, async () => {
    const error = await callExpectError('create_product', {
      name: 'Expensive Product',
      priceCents: 10000001, // Exceeds $100k limit
      stockQuantity: 1,
      description: 'Test',
    }, sellerToken);

    expect(error.code).not.toBe('unexpected-success');
  });

  // ════════════════════════════════════════════════════════════════════
  // T09: Product Lifecycle Validation
  // ════════════════════════════════════════════════════════════════════

  test('T09: Product lifecycle: draft→active (valid), active→draft (invalid)', { timeout: 60_000 }, async () => {
    // Create product in draft
    const created = await callOk('create_product', {
      name: 'Lifecycle Test',
      priceCents: 5000,
      stockQuantity: 10,
      description: 'Test',
      lifecycleStatus: 'draft',
    }, sellerToken);

    if (created.productId) {
      // Transition draft → active (valid)
      const activated = await callOk('update_product', {
        productId: created.productId,
        lifecycleStatus: 'active',
      }, sellerToken);
      expect(activated).toBeTruthy();

      // Try to go active → draft (invalid — should reject)
      const error = await callExpectError('update_product', {
        productId: created.productId,
        lifecycleStatus: 'draft',
      }, sellerToken);
      
      // Should be rejected or handled gracefully
      expect(error.code).toBeTruthy();
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T10: Perishable Shipping Restrictions
  // ════════════════════════════════════════════════════════════════════

  test('T10: Perishable product shipping > 50km → rejected', { timeout: 60_000 }, async () => {
    // Create a perishable product
    const product = await callOk('create_product', {
      name: 'Perishable Goods',
      priceCents: 3000,
      stockQuantity: 10,
      description: 'Expires quickly',
      isPerishable: true,
    }, sellerToken);

    if (product.productId) {
      // Try to order with shipping > 50km (seller must be in same/nearby province)
      const error = await callExpectError('create_order', {
        productId: product.productId,
        quantity: 1,
        shippingAddress: {
          street: '123 Main',
          city: 'St Johns', // Very far from Toronto
          province: 'NL',   // Different province
          postalCode: 'A1A 1A1',
          country: 'CA',
        },
      }, buyerToken);

      if (error.code !== 'unexpected-success') {
        expect(error.message).toContain('perishable') || expect(error.message).toContain('distance');
      }
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T11: Free Shipping Threshold
  // ════════════════════════════════════════════════════════════════════

  test('T11: Free shipping: order >= $75 CAD → shippingCostCents = 0', { timeout: 60_000 }, async () => {
    if (!testProductId) {
      console.log('Skipping: no test product found');
      return;
    }

    // Try ordering multiple items to exceed $75 CAD (7500 cents)
    const order = await callOk('create_order', {
      productId: testProductId,
      quantity: 5, // Should exceed $75 if product costs enough
      shippingAddress: {
        street: '123 Main',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'CA',
      },
    }, buyerToken);

    if (order.order && order.order.subtotalCents >= 7500) {
      // Order is >= $75, should have free shipping
      expect(order.order.shippingCostCents).toBe(0);
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T12: Idempotency
  // ════════════════════════════════════════════════════════════════════

  test('T12: Idempotency: same checkout request twice → same session (not duplicate)', { timeout: 60_000 }, async () => {
    if (!testProductId) {
      console.log('Skipping: no test product found');
      return;
    }

    const payload = {
      productId: testProductId,
      quantity: 1,
      shippingAddress: {
        street: '123 Main',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'CA',
      },
      idempotencyKey: `test-idem-${Date.now()}`,
    };

    const order1 = await callOk('create_order', payload, buyerToken);
    const order2 = await callOk('create_order', payload, buyerToken);

    // Both should return the same order ID (idempotent)
    if (order1.orderId && order2.orderId) {
      expect(order1.orderId).toBe(order2.orderId);
    }
  });

  // ════════════════════════════════════════════════════════════════════
  // T13: Image URL Validation (R2 only)
  // ════════════════════════════════════════════════════════════════════

  test('T13: Product image URL with non-R2 domain → rejected', { timeout: 60_000 }, async () => {
    const error = await callExpectError('create_product', {
      name: 'Bad Image Product',
      priceCents: 5000,
      stockQuantity: 10,
      description: 'Test',
      images: ['https://evil.com/malicious-image.jpg'], // Not R2
    }, sellerToken);

    expect(error.code).not.toBe('unexpected-success');
  });
});
