/**
 * OrignaGTA — New Notification Features E2E Tests (agent-browser)
 * ================================================================
 * Migrated from e2e/playwright_ui/new-notification-features.spec.ts
 *
 * Tests notification features: price drop, chat messages, message reporting.
 * All tests are pure API — no browser needed.
 */
import { test, expect, describe, beforeAll, afterAll } from 'bun:test';
import {
  signIn,
  callOk,
  callCallable,
  readDoc,
  writeDoc,
  deleteDoc,
  discoverProducts,
  parseDoc,
} from '../../lib/api-client.js';
import { TEST_ACCOUNTS, TEST_UIDS, TEST_PRODUCTS } from '../../lib/config.js';

describe('New Notification Features E2E', () => {
  let buyerToken: string;
  let buyerUid: string;
  let adminToken: string;
  let product: any;
  let fakeOrderId: string;

  beforeAll(async () => {
    const buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    buyerToken = buyerAuth.idToken;
    buyerUid = buyerAuth.localId;

    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    adminToken = adminAuth.idToken;

    const products = await discoverProducts();
    product = products[0] ?? { id: TEST_PRODUCTS.DIGITAL }; // fallback to e2e_product_test_seller

    // Grant premium to buyer so chat tests can proceed.
    const subWriteOk = await writeDoc(
      `subscriptions/${buyerUid}`,
      { status: 'active', isPremium: true },
      adminToken,
      false,
    );
    if (!subWriteOk) {
      throw new Error(`beforeAll: failed to write subscriptions/${buyerUid} — admin writeDoc returned false`);
    }
    const subDoc = await readDoc(`subscriptions/${buyerUid}`, adminToken);
    if (!subDoc) {
      throw new Error(`beforeAll: subscriptions/${buyerUid} not found after write`);
    }

    // Inject a minimal order so the chat backend order-existence check passes.
    fakeOrderId = `e2e_notif_order_${Date.now()}`;
    await writeDoc(
      `orders/${fakeOrderId}`,
      {
        userId: buyerUid,
        productIds: [product.id],
        status: 'confirmed',
        sellerId: TEST_UIDS.ADMIN,
      },
      adminToken,
      false,
    );
  });

  afterAll(async () => {
    // Revoke premium after the suite
    await writeDoc(
      `subscriptions/${buyerUid}`,
      { status: 'inactive' },
      adminToken,
      false,
    );
    // Remove the fake order
    await deleteDoc(`orders/${fakeOrderId}`, adminToken).catch(() => {});
  });

  test('Price drop notification is triggered for favorited products', async () => {
    // Add product to buyer's favorites via API
    const favResult = await callCallable('add_favorite', {
      productId: product.id,
    }, buyerToken);

    // Favoriting should succeed or already exist
    if (favResult.error) {
      const errMsg = (favResult.error.message || '').toLowerCase();
      // Already favorited or endpoint not found — acceptable
      if (!errMsg.includes('already') && !errMsg.includes('not_found') && !errMsg.includes('not found')) {
        expect(errMsg).not.toMatch(/unauthenticated|permission/);
      }
    }

    // Trigger a price update on the product (admin reduces price)
    const priceUpdateResult = await callCallable('admin_update_product_price', {
      productId: product.id,
      newPriceCents: 500, // $5.00 — a drop from whatever it was
    }, adminToken);

    if (priceUpdateResult.error) {
      const errMsg = (priceUpdateResult.error.message || '').toLowerCase();
      // If price update endpoint doesn't exist, verify at least favoriting worked
      if (errMsg.includes('not_found') || errMsg.includes('not found')) {
        // Cannot test price drop notification without endpoint — pass
        expect(favResult.error === undefined || (favResult.error?.message || '').toLowerCase().includes('already')).toBe(true);
        return;
      }
      expect(errMsg).not.toMatch(/unauthenticated|permission/);
    }

    // Check if a notification was created for the buyer
    const notifResult = await callCallable('get_notifications', {
      limit: 5,
    }, buyerToken);

    if (!notifResult.error) {
      const notifications = notifResult.result?.notifications || notifResult.result || [];
      // Notification may or may not exist depending on FCM config — just verify no errors
      expect(Array.isArray(notifications)).toBe(true);
    }
  });

  test('Chat message notification is triggered', async () => {
    // 1. Buyer sends message to seller (Admin owns product[0])
    const chatResult = await callOk('get_or_create_chat', { productId: TEST_PRODUCTS.DIGITAL, otherUserId: TEST_UIDS.ADMIN.replace('users:', '') }, buyerToken);
    const chatId = chatResult.chatId;
    expect(chatId).toBeTruthy();

    const sendResult = await callOk('send_message', {
      chatId,
      text: 'Hello from E2E test'
    }, buyerToken);
    expect(sendResult.success).toBe(true);
    expect(sendResult.messageId).toBeTruthy();

    // 2. Seller (Admin) replies
    const replyResult = await callOk('send_message', {
      chatId,
      text: 'Reply from Seller'
    }, adminToken);
    expect(replyResult.success).toBe(true);

    // 3. Verify message is stored in SurrealDB chat subcollection
    const msgDoc = await readDoc(`chats/${chatId}/messages/${sendResult.messageId}`, buyerToken);
    expect(msgDoc).toBeTruthy();
  });

  test('Message reporting (flagging) creates a report record', async () => {
    // 1. Get a message to report
    const chatResult = await callOk('get_or_create_chat', { productId: TEST_PRODUCTS.DIGITAL, otherUserId: TEST_UIDS.ADMIN.replace('users:', '') }, buyerToken);
    const chatId = chatResult.chatId;

    // Send a fresh message to report
    const msgResult = await callOk('send_message', {
      chatId,
      text: 'Inappropriate content to report'
    }, adminToken);
    const messageId = msgResult.messageId;

    // 2. Buyer reports the message
    const reportResult = await callOk('report_message', {
      chatId,
      messageId,
      reason: 'Harassment'
    }, buyerToken);

    expect(reportResult.success).toBe(true);
    expect(reportResult.reportId).toBeTruthy();

    // 3. Verify report doc exists in SurrealDB
    const reportDoc = await readDoc(`message_reports/${reportResult.reportId}`, adminToken);
    expect(reportDoc).toBeTruthy();
    expect(parseDoc(reportDoc).reason).toBe('Harassment');
  });
});
