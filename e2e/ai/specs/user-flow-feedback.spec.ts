/**
 * AI User Flow Feedback — Phase 7
 *
 * AI navigates multi-step user flows and provides UX improvement feedback.
 * Uses both screenshots and accessibility snapshots for comprehensive analysis.
 */
import { test, expect, describe } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { AiAnalyzer } from '../lib/analyzer.js';
import { AiReport } from '../lib/reporter.js';
import { navigateToScreen, captureScreenshot } from '../lib/flows.js';
import { AI_CONFIG } from '../config.js';

const report = new AiReport();

describe('AI User Flow Feedback', () => {
  test('Flow: Guest browsing → product discovery', async () => {
    const browser = new AgentBrowser();
    try {
      const steps: string[] = [];

      // Step 1: Home page (guest)
      await navigateToScreen(browser, { name: 'home', path: '/', role: 'guest', description: '' });
      steps.push('Navigate to home page');

      // Step 2: Search for products
      let snap = await browser.snapshot({ interactive: true, compact: true });
      const searchInput = browser.findByLabel(snap, /input-home-search|search|rechercher/i);
      if (searchInput) {
        await browser.fill(searchInput.ref, 'test');
        await browser.press('Enter');
        await browser.waitForFlutter();
        steps.push('Search for products using search bar');
      } else {
        steps.push('Look for search bar (not found — potential UX issue)');
      }

      // Step 3: Scroll to discover products
      for (let i = 0; i < 3; i++) {
        await browser.press('PageDown');
        await new Promise(r => setTimeout(r, 500));
      }
      steps.push('Scroll through product grid to discover products');

      // Step 4: Click a product card
      snap = await browser.snapshot({ interactive: true, compact: true });
      const productCard = snap.refs.find(r => /product-card-/.test(r.name));
      if (productCard) {
        await browser.click(productCard.ref);
        await browser.waitForFlutter();
        steps.push('Click on a product card to view details');
      } else {
        steps.push('Attempt to click a product card (none found)');
      }

      const screenshotBase64 = await captureScreenshot(browser, 'flow-guest-browse');
      const analyzer = new AiAnalyzer();
      const feedback = await analyzer.analyzeUserFlow('guest-browse', screenshotBase64, snap, steps);
      report.addResult(feedback);

      console.log(`  [guest-browse] score=${feedback.score}/10`);
      for (const s of feedback.suggestions) console.log(`    💡 ${s}`);

      if (feedback.score < 3) {
        expect(feedback.score).toBeGreaterThanOrEqual(3);
      }
    } finally {
      await browser.close();
    }
  }, 180_000);

  test('Flow: Login → profile navigation', async () => {
    const browser = new AgentBrowser();
    try {
      const steps: string[] = [];

      // Login via settings menu
      await navigateToScreen(browser, {
        name: 'home-authenticated',
        path: '/',
        role: 'buyer',
        description: '',
      });
      steps.push('Login with buyer credentials');

      // Open settings
      let snap = await browser.snapshot({ interactive: true, compact: true });
      const settingsBtn = browser.findByLabel(snap, /btn-home-settings/);
      if (settingsBtn) {
        await browser.click(settingsBtn.ref);
        await browser.waitForFlutter();
        await new Promise(r => setTimeout(r, 2_000));
        steps.push('Open settings menu');
      }

      snap = await browser.snapshot({ interactive: true, compact: true });
      const menuItems = snap.refs.filter(r => /menu-/.test(r.name));
      steps.push(`Explore settings: found ${menuItems.length} menu items`);

      // Navigate to orders
      const ordersBtn = browser.findByLabel(snap, /menu-my-orders|my orders/i);
      if (ordersBtn) {
        await browser.click(ordersBtn.ref);
        await browser.waitForFlutter();
        steps.push('Navigate to My Orders');
      }

      const screenshotBase64 = await captureScreenshot(browser, 'flow-login-profile');
      const analyzer = new AiAnalyzer();
      const feedback = await analyzer.analyzeUserFlow('login-profile', screenshotBase64, snap, steps);
      report.addResult(feedback);

      console.log(`  [login-profile] score=${feedback.score}/10`);
      for (const s of feedback.suggestions) console.log(`    💡 ${s}`);

      if (feedback.score < 3) {
        expect(feedback.score).toBeGreaterThanOrEqual(3);
      }
    } finally {
      await browser.close();
    }
  }, 180_000);

  test('Flow: Cart → checkout entry point', async () => {
    const browser = new AgentBrowser();
    try {
      const steps: string[] = [];

      // Login then navigate to cart
      await navigateToScreen(browser, {
        name: 'cart',
        path: '/cart',
        role: 'buyer',
        description: '',
      });
      steps.push('Login and navigate to cart page');

      const snap = await browser.snapshot({ interactive: true, compact: true });
      steps.push(`Cart page: ${snap.refs.length} interactive elements`);

      const hasCheckout = snap.refs.some(r => /checkout|payer|passer/i.test(r.name));
      const isEmpty = snap.refs.some(r => /empty|vide|go shopping/i.test(r.name));
      if (hasCheckout) steps.push('Checkout button found — cart has items');
      else if (isEmpty) steps.push('Empty cart state displayed');
      else steps.push('Cart state unclear — may need better empty/populated distinction');

      const screenshotBase64 = await captureScreenshot(browser, 'flow-cart-checkout');
      const analyzer = new AiAnalyzer();
      const feedback = await analyzer.analyzeUserFlow('cart-checkout', screenshotBase64, snap, steps);
      report.addResult(feedback);

      console.log(`  [cart-checkout] score=${feedback.score}/10`);
      for (const s of feedback.suggestions) console.log(`    💡 ${s}`);

      if (feedback.score < 3) {
        expect(feedback.score).toBeGreaterThanOrEqual(3);
      }
    } finally {
      await browser.close();
    }
  }, 180_000);

  test('REPORT: Save user flow report', async () => {
    if (report.count === 0) return;
    const { mdPath } = await report.save('user-flow-feedback');
    console.log(`\n🧭 User flow report saved: ${mdPath}`);
    console.log(`   Avg score: ${report.averageScore.toFixed(1)}/10 | Tokens: ${report.totalTokens}`);
    expect(report.count).toBeGreaterThan(0);
  }, 10_000);
});
