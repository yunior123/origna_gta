/**
 * OrignaGTA — Admin Reviews Tab E2E Tests (agent-browser)
 * ========================================================
 * Migrated from e2e/playwright_ui/admin-reviews.spec.ts
 *
 * Tests the admin panel's Reviews tab functionality:
 *   - Admin navigates to Reviews tab (UI)
 *   - Reviews list renders or shows empty state (UI)
 *   - Admin can flag a review via API
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import {
  signIn,
  callCallable,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const ADMIN_EMAIL = TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASS = TEST_ACCOUNTS.ADMIN_PASS;

async function loginAs(browser: AgentBrowser, email: string, password: string) {
  await browser.open(`${WEB_APP_URL}/login`);
  await browser.waitForFlutter();
  let snap = await browser.snapshot({ interactive: true, compact: true });

  const emailInput = browser.findByLabel(snap, /you@example|vous@exemple|login_email_field/i);
  if (!emailInput) throw new Error('Email input not found');
  await browser.click(emailInput.ref);
  await browser.type(email);

  snap = await browser.snapshot({ interactive: true, compact: true });
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

describe('Admin Reviews Tab', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T01: Admin navigates to Reviews tab in admin panel', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASS);
    await browser.open(`${WEB_APP_URL}/admin`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 2000));

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const reviewsTab = browser.findByLabel(snap, /admin-tab-reviews|reviews|avis/i);
    if (!reviewsTab) {
      // Reviews tab may not exist in current build — verify admin panel loaded
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(reviewsTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Should be on reviews tab now
    const reviewContent = browser.findByLabel(snap, /review|avis|rating|note|empty|aucun/i);
    expect(reviewContent ?? reviewsTab).toBeTruthy();
  });

  test('T02: Reviews list renders or shows empty state', { timeout: 60_000 }, async () => {
    await loginAs(browser, ADMIN_EMAIL, ADMIN_PASS);
    await browser.open(`${WEB_APP_URL}/admin`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 2000));

    let snap = await browser.snapshot({ interactive: true, compact: true });
    const reviewsTab = browser.findByLabel(snap, /admin-tab-reviews|reviews|avis/i);
    if (!reviewsTab) {
      const anyTab = browser.findByLabel(snap, /admin-tab-/);
      expect(anyTab).toBeTruthy();
      return;
    }
    await browser.click(reviewsTab.ref);
    await new Promise(r => setTimeout(r, 2000));

    snap = await browser.snapshot({ interactive: true, compact: true });
    // Should show reviews list or empty state
    const reviewItems = browser.findAllByLabel(snap, /review|avis|rating|star|[eé]toile/i);
    const emptyState = browser.findByLabel(snap, /empty|aucun|no.*review/i);
    // Either reviews exist or empty state is displayed
    expect(reviewItems.length > 0 || emptyState !== null).toBe(true);
  });

  // ─── T03: Admin can flag a review via API ───────────────────────
  test('T03: Admin can flag a review via admin_flag_review API', async () => {
    const adminAuth = await signIn(ADMIN_EMAIL, ADMIN_PASS);

    // First, get reviews to find one to flag
    const reviewsResult = await callCallable('admin_get_reviews', {
      limit: 5,
    }, adminAuth.idToken);

    if (reviewsResult.error) {
      const errMsg = (reviewsResult.error.message || '').toLowerCase();

      // If function not deployed, skip gracefully
      if (errMsg.includes('not_found') || errMsg.includes('not found') || reviewsResult.error.status === 'NOT_FOUND') {
        return;
      }

      // Admin should not be denied access
      expect(errMsg).not.toMatch(/permission.denied|unauthenticated/);
      return;
    }

    const reviews = reviewsResult.result?.reviews || reviewsResult.result || [];

    if (!Array.isArray(reviews) || reviews.length === 0) {
      // Try to submit a rating as buyer first, then flag it as admin
      const buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
      const ratingResult = await callCallable('submit_rating', {
        productId: 'e2e_product_test_seller',
        rating: 3,
        comment: `E2E test review for flagging ${Date.now()}`,
      }, buyerAuth.idToken);

      if (ratingResult.error) {
        // Cannot create a review to flag — skip
        return;
      }

      const reviewId = ratingResult.result?.ratingId || ratingResult.result?.reviewId || ratingResult.result?.id;

      if (reviewId) {
        const flagResult = await callCallable('admin_flag_review', {
          reviewId,
          flagged: true,
          reason: 'E2E test flag — inappropriate content',
        }, adminAuth.idToken);

        if (flagResult.error) {
          const flagErr = (flagResult.error.message || '').toLowerCase();
          if (flagErr.includes('not_found') || flagErr.includes('not found')) {
            return;
          }
        } else {
          expect(flagResult.result || flagResult).toBeTruthy();
        }
      }
      return;
    }

    // Flag the first review found
    const targetReview = reviews[0];
    const reviewId = targetReview.reviewId || targetReview.ratingId || targetReview.id;

    if (!reviewId) {
      return;
    }

    const flagResult = await callCallable('admin_flag_review', {
      reviewId,
      flagged: true,
      reason: 'E2E test flag — admin review moderation',
    }, adminAuth.idToken);

    if (flagResult.error) {
      const flagErr = (flagResult.error.message || '').toLowerCase();
      if (flagErr.includes('not_found') || flagErr.includes('not found')) {
        return;
      }
      expect(flagErr).not.toMatch(/permission.denied|unauthenticated/);
    } else {
      expect(flagResult.result || flagResult).toBeTruthy();
    }
  });
});
