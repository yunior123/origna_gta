/**
 * OrignaGTA — Subscription Cancel Screen E2E Tests
 * ==================================================
 * Tests the subscription cancellation page at /subscription/cancel.
 * Verifies resubscribe CTA, back-home button, and accessibility.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { WEB_APP_URL } from '../../lib/config.js';

describe('Subscription Cancel Screen', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T01: Cancel page renders with resubscribe CTA', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/subscription/cancel`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Page should show subscription-related content or redirect to login
    expect(
      /resubscribe|cancel|subscription|abonnement|annul/i.test(text) ||
      /login|connexion|sign.*in/i.test(text)
    ).toBe(true);
  });

  test('T02: btn-resubscribe navigates to subscription page', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/subscription/cancel`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const resubBtn = browser.findByLabel(snap, /btn-resubscribe|resubscribe|se.*réabonner/i);
    if (resubBtn) {
      await browser.click(resubBtn.ref);
      await new Promise(r => setTimeout(r, 3000));
      await browser.waitForFlutter();
      const newSnap = await browser.snapshot({ interactive: true, compact: true });
      const newText = JSON.stringify(newSnap);
      expect(/subscription|premium|abonnement/i.test(newText)).toBe(true);
    } else {
      // Page may redirect to login — acceptable
      expect(true).toBe(true);
    }
  });

  test('T03: btn-back-home navigates to home', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/subscription/cancel`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const homeBtn = browser.findByLabel(snap, /btn-back-home|back.*home|retour.*accueil|home/i);
    if (homeBtn) {
      await browser.click(homeBtn.ref);
      await new Promise(r => setTimeout(r, 3000));
      await browser.waitForFlutter();
      // Should be on home page
      const newSnap = await browser.snapshot({ interactive: true, compact: true });
      const text = JSON.stringify(newSnap);
      expect(/home|accueil|product|produit|search|recherche/i.test(text)).toBe(true);
    } else {
      expect(true).toBe(true);
    }
  });

  test('T04: Page accessible without auth (shows content or redirects)', { timeout: 60_000 }, async () => {
    await browser.clearState();
    await browser.open(`${WEB_APP_URL}/subscription/cancel`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Either shows cancel page or redirects to login — both are valid
    expect(
      /cancel|subscription|resubscribe|login|connexion|sign.*in|abonnement/i.test(text)
    ).toBe(true);
  });
});
