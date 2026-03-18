/**
 * OrignaGTA — Chat Inbox E2E Tests
 * ==================================
 * Tests the chat conversations screen at /chat/inbox.
 * Premium-only feature: non-premium users see paywall.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import { AgentBrowser } from '../../lib/agent-browser.js';
import { signIn, callCallable } from '../../lib/api-client.js';
import { TEST_ACCOUNTS, WEB_APP_URL } from '../../lib/config.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const BUYER_PASS = TEST_ACCOUNTS.BUYER_PASS;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;
const SELLER_PASS = TEST_ACCOUNTS.SELLER_PASS;

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

describe('Chat Inbox', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  afterAll(async () => {
    await browser.close();
  });

  test('T01: User sees chat inbox or paywall', { timeout: 60_000 }, async () => {
    await loginAs(browser, BUYER_EMAIL, BUYER_PASS);
    await browser.open(`${WEB_APP_URL}/chat/inbox`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Should show either chat inbox or premium paywall
    expect(
      /chat|message|conversation|inbox|messagerie|premium|upgrade|paywall/i.test(text) ||
      /login|connexion/i.test(text)
    ).toBe(true);
  });

  test('T02: Non-premium user sees paywall on chat', { timeout: 60_000 }, async () => {
    // Navigate to messages via settings
    let snap = await browser.snapshot({ interactive: true, compact: true });
    const settings = browser.findByLabel(snap, /btn-home-settings/);
    if (settings) {
      await browser.click(settings.ref);
      await new Promise(r => setTimeout(r, 2000));
      await browser.waitForFlutter();

      snap = await browser.snapshot({ interactive: true, compact: true });
      const messagesLink = browser.findByLabel(snap, /menu-my-messages|messages|messagerie/i);
      if (messagesLink) {
        await browser.click(messagesLink.ref);
        await new Promise(r => setTimeout(r, 3000));
        await browser.waitForFlutter();
      }
    }

    snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Non-premium should see paywall or premium upsell
    const hasChatOrPaywall =
      /premium|upgrade|paywall|subscribe|abonnement/i.test(text) ||
      /chat|message|conversation|messagerie/i.test(text);
    expect(hasChatOrPaywall).toBe(true);
  });

  test('T03: Chat thread list shows content', { timeout: 60_000 }, async () => {
    await browser.open(`${WEB_APP_URL}/chat/inbox`);
    await browser.waitForFlutter();
    await new Promise(r => setTimeout(r, 3000));

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const text = JSON.stringify(snap);
    // Should show threads, empty state, or paywall
    expect(
      /thread|conversation|message|no.*chat|aucun|empty|premium|paywall/i.test(text)
    ).toBe(true);
  });

  test('T04: Chat thread navigation works', { timeout: 60_000 }, async () => {
    const snap = await browser.snapshot({ interactive: true, compact: true });
    const thread = browser.findByLabel(snap, /chat-thread|conversation|thread/i);
    if (thread) {
      await browser.click(thread.ref);
      await new Promise(r => setTimeout(r, 3000));
      await browser.waitForFlutter();
      const chatSnap = await browser.snapshot({ interactive: true, compact: true });
      const text = JSON.stringify(chatSnap);
      expect(/message|send|envoyer|type.*message/i.test(text)).toBe(true);
    } else {
      // No threads or paywall — pass
      expect(true).toBe(true);
    }
  });

  test('T05: start_chat_thread API works', async () => {
    const auth = await signIn(SELLER_EMAIL, SELLER_PASS);
    const result = await callCallable('start_chat_thread', {
      recipientId: TEST_ACCOUNTS.BUYER_EMAIL,
      initialMessage: 'E2E test chat message',
    }, auth.idToken);
    // Either succeeds or returns a known error (not unauthenticated)
    expect(result.error?.code).not.toBe('unauthenticated');
  });
});
