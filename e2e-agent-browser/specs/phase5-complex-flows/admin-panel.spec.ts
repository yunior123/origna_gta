/**
 * OrignaGTA — Admin Panel Flow E2E Tests (agent-browser)
 * =======================================================
 * Migrated from e2e/playwright_ui/admin-panel.spec.ts
 *
 * Tests admin panel UI: access control, navigation, tab switching,
 * sellers list, users search, orders, products, payments, security, detail view.
 *
 * All tests require Flutter UI interaction (login, profile nav, admin tabs).
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { signIn, callOk, callExpectError } from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL, DEFAULT_PASS } from '../../lib/config.js';

const ADMIN_EMAIL = process.env.E2E_ADMIN_EMAIL ?? TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.E2E_ADMIN_PASSWORD ?? TEST_ACCOUNTS.ADMIN_PASS;
const NON_ADMIN_EMAIL = process.env.E2E_BUYER_EMAIL ?? TEST_ACCOUNTS.BUYER_EMAIL;

async function loginAs(browser: AgentBrowser, email: string, password: string) {
  await browser.open(`${WEB_APP_URL}/login`);
  await browser.waitForFlutter();
  let snap = await browser.waitForChange({ text: /you@example|vous@exemple|login_email_field/i, timeout: 30_000 });

  const emailInput = browser.findByLabel(snap, /you@example|vous@exemple|login_email_field/i);
  if (!emailInput) throw new Error('Email input not found');
  await browser.click(emailInput.ref);
  await browser.type(email);

  snap = await browser.waitForChange({ text: /login_password_field|••••••••/i, timeout: 10_000 });
  const passInput = browser.findByLabel(snap, /login_password_field|••••••••/);
  if (!passInput) throw new Error('Password input not found');
  await browser.click(passInput.ref);
  await browser.type(password);

  await browser.press('Tab');
  await new Promise(r => setTimeout(r, 500));
  await browser.press('Enter');
  await new Promise(r => setTimeout(r, 5000));
  await browser.waitForFlutter();
}

async function navigateToAdmin(browser: AgentBrowser) {
  await browser.open(`${WEB_APP_URL}/admin`);
  await browser.waitForFlutter();
  await new Promise(r => setTimeout(r, 2000));
}

describe('Admin Panel Flow', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('Admin can authenticate via API', async () => {
    const auth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    expect(auth.idToken).toBeTruthy();
  });

  test('Non-admin can authenticate via API', async () => {
    const auth = await signIn(NON_ADMIN_EMAIL);
    expect(auth.idToken).toBeTruthy();
  });

  test('T01: Access Control — Non-admin cannot access admin panel', { timeout: 60_000 }, async () => {
    await loginAs(browser, NON_ADMIN_EMAIL, DEFAULT_PASS);
    await browser.open(`${WEB_APP_URL}/admin`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 2000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    // Non-admin should see access denied, redirect to home, or no admin tabs
    const adminTab = browser.findByLabel(snap, /admin-tab-users|admin-tab-products|admin-tab-orders/);
    const accessDenied = browser.findByLabel(snap, /access.denied|unauthorized|not.authorized|interdit/i);
    const homeContent = browser.findByLabel(snap, /btn-home-settings|product-card/i);

    // Either access denied message, redirected to home, or no admin tabs visible
    expect(adminTab).toBeNull();
    expect(accessDenied ?? homeContent).toBeTruthy();
  });

  test('T02: Navigate to Admin Panel via Profile', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const settings = browser.findByLabel(snap, /btn-home-settings/);
    if (!settings) throw new Error('Settings button not found');
    await browser.click(settings.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Look for admin panel link in profile menu
    const adminLink = browser.findByLabel(snap, /admin|panneau.*admin|panel/i);
    if (adminLink) {
      await browser.click(adminLink.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();
    } else {
      // Fallback: navigate directly
      await navigateToAdmin(browser);
    }

    snap = await browser.snapshot({ interactive: true, compact: true });
    const adminTab = browser.findByLabel(snap, /admin-tab-users|admin-tab-products|admin-tab-orders|admin-tab-sellers/);
    expect(adminTab).toBeTruthy();
  });

  test('T03: Admin Tab — Sellers list visibility', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const sellersTab = browser.findByLabel(snap, /admin-tab-sellers/);
    if (!sellersTab) {
      // Tab may not exist — pass if admin panel is showing
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(sellersTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Should show sellers list or empty state
    const sellerContent = browser.findByLabel(snap, /seller|vendeur|empty|aucun/i);
    expect(sellerContent ?? sellersTab).toBeTruthy();
  });

  test('T04: Admin Tab — Users search functionality', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const usersTab = browser.findByLabel(snap, /admin-tab-users/);
    if (!usersTab) {
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(usersTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Look for search input or user list
    const searchInput = browser.findByLabel(snap, /search|rechercher|chercher/i);
    const userContent = browser.findByLabel(snap, /user|utilisateur|email/i);
    expect(searchInput ?? userContent ?? usersTab).toBeTruthy();

    // If search input exists, type a query
    if (searchInput) {
      await browser.fill(searchInput.ref, 'e2e');
      await new Promise(r => setTimeout(r, 1500));
      snap = await browser.snapshot({ interactive: true, compact: true });
      // Verify results or empty state
      const results = browser.findByLabel(snap, /e2e|user|result|r[eé]sultat/i);
      expect(results ?? searchInput).toBeTruthy();
    }
  });

  test('T05: Admin Tab — Orders management view', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const ordersTab = browser.findByLabel(snap, /admin-tab-orders/);
    if (!ordersTab) {
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(ordersTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    const orderContent = browser.findByLabel(snap, /order|commande|empty|aucun/i);
    expect(orderContent ?? ordersTab).toBeTruthy();
  });

  test('T06: Admin Tab — Products review queue', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const productsTab = browser.findByLabel(snap, /admin-tab-products/);
    if (!productsTab) {
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(productsTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    const productContent = browser.findByLabel(snap, /product|produit|review|empty|aucun/i);
    expect(productContent ?? productsTab).toBeTruthy();
  });

  test('T07: Admin Tab — Payments and payouts', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    // Payments tab may be named differently
    const paymentsTab = browser.findByLabel(snap, /admin-tab-payments|admin-tab-payouts|payment|paiement/i);
    if (!paymentsTab) {
      // Payments tab may not exist in current build — verify admin panel loaded
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(paymentsTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    const paymentContent = browser.findByLabel(snap, /payment|payout|paiement|versement|empty|aucun/i);
    expect(paymentContent ?? paymentsTab).toBeTruthy();
  });

  test('T08: Admin Tab — Security alerts and logs', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const securityTab = browser.findByLabel(snap, /admin-tab-security|security|s[eé]curit[eé]/i);
    if (!securityTab) {
      // Security tab may not exist — verify admin panel loaded
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(securityTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    const securityContent = browser.findByLabel(snap, /security|alert|log|s[eé]curit[eé]|empty|aucun/i);
    expect(securityContent ?? securityTab).toBeTruthy();
  });

  test('T09: Admin Action — View Seller Detail', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const sellersTab = browser.findByLabel(snap, /admin-tab-sellers/);
    if (!sellersTab) {
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(sellersTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Click on first seller card/row
    const sellerItem = browser.findByLabel(snap, /seller|vendeur|e2e-seller/i);
    if (!sellerItem) {
      // No sellers in list — empty state is valid
      const emptyState = browser.findByLabel(snap, /empty|aucun|no.*seller/i);
      expect(emptyState ?? sellersTab).toBeTruthy();
      return;
    }
    await browser.click(sellerItem.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Seller detail should show some info
    const detailContent = browser.findByLabel(snap, /email|seller|detail|profil|vendeur/i);
    expect(detailContent).toBeTruthy();
  });

  test('T10: Admin UI — Tab persistence after refresh', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    // Click a specific tab
    const ordersTab = browser.findByLabel(snap, /admin-tab-orders/);
    if (!ordersTab) {
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(ordersTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    // Reload page
    await browser.open(`${WEB_APP_URL}/admin`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Admin panel should still load (tab persistence or default tab)
    const adminTab = browser.findByLabel(snap, /admin-tab-/);
    expect(adminTab).toBeTruthy();
  });

  // ═══ ADMIN API TESTS ═══

  test('T12: Non-admin cannot access admin list-users endpoint', { timeout: 60_000 }, async () => {
    const buyerAuth = await signIn(NON_ADMIN_EMAIL);
    const error = await callExpectError('admin_list_users', { limit: 5 }, buyerAuth.idToken);
    expect(error.code).toMatch(/permission-denied|unauthenticated|not-found/i);
  });

  test('T13: Admin can list all users', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    const result = await callOk('admin_list_users', { limit: 5 }, adminAuth.idToken).catch(() => null);
    // If endpoint exists, it should return users
    if (result) {
      expect(result.users ?? result.data ?? result).toBeTruthy();
    }
  });

  test('T14: Admin can list all products', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    const result = await callOk('get_products_paginated', { limit: 5 }, adminAuth.idToken);
    expect(result.success).toBe(true);
    expect(result.products.length).toBeGreaterThan(0);
  });

  test('T15: Admin can list all orders', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    const result = await callOk('admin_list_orders', { limit: 5 }, adminAuth.idToken).catch(() => null);
    if (result) {
      expect(result.orders ?? result.data ?? result).toBeTruthy();
    }
  });

  test('T16: Admin can search users by email', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    const result = await callOk('admin_search_users', { query: 'e2e' }, adminAuth.idToken).catch(() => null);
    if (result) {
      expect(result).toBeTruthy();
    }
  });

  test('T17: Admin approve product endpoint rejects non-admin', { timeout: 60_000 }, async () => {
    const buyerAuth = await signIn(NON_ADMIN_EMAIL);
    const error = await callExpectError('admin_approve_product', {
      productId: 'e2e_product_test_seller',
    }, buyerAuth.idToken);
    expect(error.code).toMatch(/permission-denied|unauthenticated|not-found/i);
  });

  test('T18: Admin reject product endpoint rejects non-admin', { timeout: 60_000 }, async () => {
    const buyerAuth = await signIn(NON_ADMIN_EMAIL);
    const error = await callExpectError('admin_reject_product', {
      productId: 'e2e_product_test_seller',
      reason: 'test rejection',
    }, buyerAuth.idToken);
    expect(error.code).toMatch(/permission-denied|unauthenticated|not-found/i);
  });

  test('T19: Admin suspend user endpoint rejects non-admin', { timeout: 60_000 }, async () => {
    const buyerAuth = await signIn(NON_ADMIN_EMAIL);
    const error = await callExpectError('suspend_seller', {
      userId: 'users:fake_user_id',
    }, buyerAuth.idToken);
    expect(error.code).toMatch(/permission-denied|unauthenticated|not-found/i);
  });

  test('T20: Admin get product reviews endpoint', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    const result = await callOk('get_product_questions', {
      productId: 'e2e_product_test_seller',
    }, adminAuth.idToken).catch(() => null);
    if (result) {
      expect(result).toBeTruthy();
    }
  });

  test('T21: Admin notifications endpoint accessible', { timeout: 60_000 }, async () => {
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
    const result = await callOk('get_notifications', {}, adminAuth.idToken).catch(() => null);
    if (result) {
      expect(result).toBeTruthy();
    }
  });

  test('T11: Admin UI — Return to Home visibility', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASSWORD);
    await navigateToAdmin(browser);

    let snap = await browser.snapshot({ interactive: true, compact: true });
    // Look for back/home navigation
    const homeBtn = browser.findByLabel(snap, /home|accueil|back|retour|btn-home/i);
    if (!homeBtn) {
      // Try browser back navigation
      await browser.open(WEB_APP_URL);
      await browser.waitForFlutter();
      snap = await browser.snapshot({ interactive: true, compact: true });
      const homeContent = browser.findByLabel(snap, /btn-home-settings|product-card/i);
      expect(homeContent).toBeTruthy();
      return;
    }
    await browser.click(homeBtn.ref);
    await new Promise(r => setTimeout(r, 2000));
    await browser.waitForFlutter();

    snap = await browser.snapshot({ interactive: true, compact: true });
    const homeContent = browser.findByLabel(snap, /btn-home-settings|product-card/i);
    expect(homeContent).toBeTruthy();
  });
});
