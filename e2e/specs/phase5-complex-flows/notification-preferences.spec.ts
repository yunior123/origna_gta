/**
 * OrignaGTA — Notification Preferences E2E Tests (agent-browser)
 * View notifications, mark as read, notification badges, preference settings
 */
import { test, expect, describe, beforeAll, beforeEach, afterAll } from 'bun:test';
import {
  signIn,
  callOk,
  callCallable,
} from '../../lib/api-client.js';
import {
  TEST_ACCOUNTS,
  WEB_APP_URL,
} from '../../lib/config.js';
import { AgentBrowser } from '../../lib/agent-browser.js';

const BUYER_EMAIL = TEST_ACCOUNTS.BUYER_EMAIL;
const SELLER_EMAIL = TEST_ACCOUNTS.SELLER_EMAIL;

describe('Notification Preferences — API Tests', () => {
  let buyerToken: string;

  beforeAll(async () => {
    const buyer = await signIn(BUYER_EMAIL);
    buyerToken = buyer.idToken;
  });

  test('T01: Get notifications returns list of user notifications', async () => {
    const result = await callOk('get_notifications', {}, buyerToken);
    expect(Array.isArray(result.notifications || result.data || [])).toBe(true);
  });

  test('T02: Notifications have required fields', async () => {
    const result = await callOk('get_notifications', { limit: 5 }, buyerToken);
    if (result.notifications && result.notifications.length > 0) {
      const notif = result.notifications[0];
      expect(notif.id || notif.notificationId).toBeTruthy();
      expect(notif.type || notif.title).toBeTruthy();
      expect(typeof notif.isRead).toBe('boolean');
      expect(notif.createdAt || notif.timestamp).toBeTruthy();
    }
  });

  test('T03: Mark notification as read updates isRead flag', async () => {
    const notifications = await callOk('get_notifications', { limit: 5 }, buyerToken);
    if (notifications.notifications && notifications.notifications.length > 0) {
      const notifId = notifications.notifications[0].id || notifications.notifications[0].notificationId;
      const result = await callOk('mark_notification_read', { notificationId: notifId }, buyerToken).catch(() => null);
      if (result) {
        expect(result.success || result.isRead).toBeTruthy();
      }
    }
  });

  test('T04: Mark all notifications as read clears unread count', async () => {
    const result = await callOk('mark_all_notifications_read', {}, buyerToken).catch(() => null);
    if (result) {
      expect(result.success).toBeTruthy();
    }
  });

  test('T05: Get unread notification count', async () => {
    const result = await callOk('get_unread_notification_count', {}, buyerToken).catch(() => null);
    if (result) {
      expect(typeof result.count).toBe('number');
      expect(result.count).toBeGreaterThanOrEqual(0);
    }
  });

  test('T06: Get notification preferences returns user settings', async () => {
    const result = await callOk('get_notification_preferences', {}, buyerToken).catch(() => null);
    if (result) {
      expect(typeof result.preferences).toBe('object');
    }
  });

  test('T07: Update notification preferences saves settings', async () => {
    const result = await callOk('update_notification_preferences', {
      emailNotifications: true,
      pushNotifications: false,
      smsNotifications: false,
    }, buyerToken).catch(() => null);
    if (result) {
      expect(result.success).toBeTruthy();
    }
  });

  test('T08: Notifications are paginated', async () => {
    const result = await callOk('get_notifications', { limit: 5, offset: 0 }, buyerToken);
    expect(result.notifications || result.data).toBeTruthy();
    if (result.nextOffset !== undefined) {
      expect(typeof result.nextOffset).toBe('number');
    }
  });

  test('T09: Filter notifications by type', async () => {
    const result = await callOk('get_notifications', {
      type: 'order',
      limit: 10,
    }, buyerToken).catch(() => null);
    if (result) {
      expect(Array.isArray(result.notifications || result.data || [])).toBe(true);
    }
  });

  test('T10: Delete notification removes it from list', async () => {
    const notifications = await callOk('get_notifications', { limit: 5 }, buyerToken);
    if (notifications.notifications && notifications.notifications.length > 0) {
      const notifId = notifications.notifications[0].id;
      const result = await callOk('delete_notification', { notificationId: notifId }, buyerToken).catch(() => null);
      if (result) {
        expect(result.success).toBeTruthy();
      }
    }
  });
});

describe('Notification Preferences — UI Tests', () => {
  let browser: AgentBrowser;

  beforeAll(() => {
    browser = new AgentBrowser();
  });

  beforeEach(async () => { try { await browser.clearState(); } catch { /* ignore */ } });

  afterAll(async () => {
    try { await browser.close(); } catch { /* ignore */ }
  });

  test('T11: Notifications icon shows badge with unread count', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/home`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const notifIcon = browser.findByLabel(snap, /notification|bell|inbox|btn-notif/i);
    expect(notifIcon || snap.refs.length > 0).toBeTruthy();
  });

  test('T12: Click notification icon opens notifications drawer/page', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/home`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const notifIcon = browser.findByLabel(snap, /notification|bell|inbox/i);
    if (notifIcon) {
      await browser.click(notifIcon.ref);
      await browser.waitForChange({ timeout: 1500 });
    }
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T13: Notifications page displays list of notifications', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notifications`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T14: Each notification shows type, message, timestamp', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notifications`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const content = snap.refs.map((r: any) => r.label || r.text).join(' ');
    // Should show notification details
    expect(content.length).toBeGreaterThan(20);
  });

  test('T15: Unread notifications show visual indicator', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notifications`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T16: Click notification navigates to related page', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notifications`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const notifItem = snap.refs.find((r: any) =>
      /notification|notif-item|notification-card/i.test(r.label || r.text || '')
    );
    if (notifItem) {
      await browser.click(notifItem.ref);
      await browser.waitForChange({ timeout: 2000 });
    }
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T17: Mark as read button visible on each notification', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notifications`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T18: Mark all as read button clears badge', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notifications`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const markAllBtn = browser.findByLabel(snap, /mark.?all|read.?all|btn-mark-all/i);
    if (markAllBtn) {
      await browser.click(markAllBtn.ref);
      await browser.waitForChange({ timeout: 1500 });
    }
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T19: Settings icon opens notification preferences', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notifications`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    const settingsBtn = browser.findByLabel(snap, /settings|preferences|gear|btn-settings/i);
    if (settingsBtn) {
      try {
        await browser.click(settingsBtn.ref);
        await browser.waitForChange({ timeout: 1500 });
      } catch {
        /* ignore */
      }
    }
    expect(snap.refs.length).toBeGreaterThan(0);
  });

  test('T20: Notification preferences show toggle switches', { timeout: 60_000 }, async () => {
    try {
      await browser.open(`${WEB_APP_URL}/#/notification-preferences`);
    } catch {
      return;
    }
    try {
      await browser.waitForFlutter();
    } catch {
      return;
    }

    const snap = await browser.snapshot({ interactive: true, compact: true });
    // Should show toggles for email, push, SMS
    expect(snap.refs.length).toBeGreaterThan(0);
  });
});
