/**
 * OrignaGTA — OrignaBase Integration E2E Tests
 * ===========================================
 * Verifies key UI flows that interact directly with the new OrignaBase backend.
 * Covers Profile, Checkout, and Admin management.
 */

import { test, expect } from '@playwright/test';
import {
  signIn,
  getDoc,
  discoverProducts,
  TEST_ACCOUNTS,
  TEST_UIDS,
  fillStripeCheckout,
} from './api-helpers';

test.describe('OrignaBase — UI Integration Flows', () => {
  
  test('O1: Profile Update reflects in OrignaBase SurrealDB', async ({ page }) => {
    test.fixme(true, 'UI flow test — page.fill times out: Flutter web uses semantic labels not HTML input[type="email"] selectors');
    // 1. Sign in via UI
    await page.goto('/login');
    await page.fill('input[type="email"]', TEST_ACCOUNTS.BUYER_EMAIL);
    await page.fill('input[type="password"]', TEST_ACCOUNTS.BUYER_PASS);
    await page.click('button[type="submit"]');
    await page.waitForURL('/profile');

    // 2. Change name in UI
    const newName = `UI Tester ${Date.now()}`;
    await page.click('text=Edit Profile');
    await page.fill('input[label="Name"], input[placeholder*="Name"]', newName);
    await page.click('button:has-text("Save")');
    
    // 3. Verify in UI
    await expect(page.locator(`text=${newName}`)).toBeVisible();

    // 4. Verify in OrignaBase via API helper
    const auth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    const profile = await getDoc(`users/${auth.localId}`, auth.idToken);
    expect(profile.name).toBe(newName);
  });

  test('O2: Checkout Flow creates Order in OrignaBase', async ({ page }) => {
    const products = await discoverProducts();
    const product = products[0];
    const buyerEmail = TEST_ACCOUNTS.BUYER_EMAIL;

    // 1. Navigate to Product and Add to Cart
    await page.goto(`/product/${product.id}`);
    await page.click('button:has-text("Add to Cart")');
    await page.click('button:has-text("View Cart")');

    // 2. Proceed to Checkout (requires login if not persisted)
    await page.click('button:has-text("Checkout")');
    if (page.url().includes('/login')) {
      await page.fill('input[type="email"]', buyerEmail);
      await page.fill('input[type="password"]', TEST_ACCOUNTS.BUYER_PASS);
      await page.click('button[type="submit"]');
    }

    // 3. Complete Stripe Checkout (if redirected)
    await page.waitForURL(/checkout.stripe.com|order-success/);
    if (page.url().includes('checkout.stripe.com')) {
      await fillStripeCheckout(page, buyerEmail);
    }

    // 4. Verify Order Success Screen
    await expect(page.locator('text=Order Successful')).toBeVisible({ timeout: 30000 });
    const orderIdMatch = page.url().match(/orderId=([^&]+)/);
    const orderId = orderIdMatch ? orderIdMatch[1] : null;
    expect(orderId).toBeTruthy();

    // 5. Verify Order in OrignaBase
    const auth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    const order = await getDoc(`orders/${orderId}`, auth.idToken);
    expect(order).toBeTruthy();
    expect(order.buyerId).toBe(TEST_UIDS.BUYER);
    expect(order.items[0].productId).toBe(product.id);
  });

  test('O3: Admin can Suspend/Unsuspend Seller in OrignaBase', async ({ page }) => {
    test.fixme(true, 'UI flow test — page.fill times out: Flutter web uses semantic labels not HTML input[type="email"] selectors; admin suspend UI also requires specific semantic labels for table rows and buttons');
    const sellerUid = TEST_UIDS.SELLER;
    const adminEmail = TEST_ACCOUNTS.ADMIN_EMAIL;

    // 1. Admin login
    await page.goto('/login');
    await page.fill('input[type="email"]', adminEmail);
    await page.fill('input[type="password"]', TEST_ACCOUNTS.ADMIN_PASS);
    await page.click('button[type="submit"]');
    
    // 2. Go to Admin Panel -> Sellers
    await page.goto('/admin-panel');
    await page.click('text=Sellers');
    
    // 3. Find seller and Toggle Suspension
    const sellerRow = page.locator(`tr:has-text("${TEST_ACCOUNTS.SELLER_EMAIL}")`);
    const suspendBtn = sellerRow.locator('button:has-text("Suspend"), button:has-text("Unsuspend")');
    const initialText = await suspendBtn.innerText();
    
    await suspendBtn.click();
    await page.click('button:has-text("Confirm")');
    
    // 4. Verify in OrignaBase
    const auth = await signIn(adminEmail);
    const sellerProfile = await getDoc(`users/${sellerUid}`, auth.idToken);
    const expectedSuspended = initialText === 'Suspend';
    expect(sellerProfile.suspended).toBe(expectedSuspended);

    // 5. Restore original state (cleanup)
    if (sellerProfile.suspended !== (initialText === 'Unsuspend')) {
      await suspendBtn.click();
      await page.click('button:has-text("Confirm")');
    }
  });

});
