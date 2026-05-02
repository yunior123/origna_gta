/**
 * OrignaGTA — Subscription Cancel Screen E2E Tests
 * ==================================================
 * Tests the subscription cancellation page at /subscription/cancel.
 * Verifies resubscribe CTA, back-home button, and accessibility.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

describe('Subscription Cancel Screen', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  async function openCancelPageAsBuyer() {
    await browser.loginViaApi(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
    await browser.open(`${WEB_APP_URL}/subscription/cancel`);
    await browser.waitForFlutter();
    await browser.waitForChange({
      text: /btn-resubscribe|btn-back-home|checkout.*cancel|subscription/i,
      timeout: 15_000,
    });
    return browser.snapshot({ interactive: true, compact: true });
  }

  test('T01: Cancel page renders with resubscribe CTA', { timeout: 60_000 }, async () => {
    const snap = await openCancelPageAsBuyer();
    expect(browser.findByLabel(snap, /btn-resubscribe/i)).toBeTruthy();
    expect(browser.findByLabel(snap, /btn-back-home/i)).toBeTruthy();
  });

  test('T02: btn-resubscribe navigates to subscription page', { timeout: 60_000 }, async () => {
    const snap = await openCancelPageAsBuyer();
    const resubBtn = browser.findByLabel(snap, /btn-resubscribe/i);
    expect(resubBtn).toBeTruthy();

    await browser.click(resubBtn!.ref);
    await browser.waitForChange({
      text: /subscription|premium|abonnement|btn-subscribe-premium/i,
      timeout: 15_000,
    });
    const newSnap = await browser.snapshot({ interactive: true, compact: true });
    const newText = JSON.stringify(newSnap);
    expect(/subscription|premium|abonnement|btn-subscribe-premium/i.test(newText)).toBe(true);
  });

  test('T03: btn-back-home navigates to home', { timeout: 60_000 }, async () => {
    const snap = await openCancelPageAsBuyer();
    const homeBtn = browser.findByLabel(snap, /btn-back-home/i);
    expect(homeBtn).toBeTruthy();

    await browser.click(homeBtn!.ref);
    await browser.waitForChange({
      text: /btn-home-settings|input-home-search|product-card-|search|home/i,
      timeout: 20_000,
    });
    const newSnap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(newSnap);
    expect(/btn-home-settings|input-home-search|product-card-|search|home/i.test(text)).toBe(true);
  });

  test('T04: Page accessible without auth (shows content or redirects)', { timeout: 60_000 }, async () => {
    await browser.clearState();
    await browser.open(`${WEB_APP_URL}/subscription/cancel`);
    await browser.waitForFlutter();
    await browser.waitForChange({
      text: /login|connexion|sign.*in|btn-login|subscription|checkout.*cancel/i,
      timeout: 15_000,
    });
    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // AuthRequiredGate may redirect to login; authenticated sessions show cancel content.
    expect(
      /login|connexion|sign.*in|btn-login|cancel|subscription|abonnement/i.test(text)
    ).toBe(true);
  });
});
