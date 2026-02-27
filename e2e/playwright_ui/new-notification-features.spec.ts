import { test, expect } from '@playwright/test';
import {
  signIn,
  callOk,
  readDoc,
  writeDoc,
  toFirestoreFields,
  TEST_ACCOUNTS,
  discoverProducts,
  getDoc,
} from './api-helpers';

test.describe('New Notification Features E2E', () => {
  test.setTimeout(120_000);

  let buyerToken: string;
  let buyerUid: string;
  let adminToken: string;
  let product: any;

  test.beforeAll(async () => {
    const buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL);
    buyerToken = buyerAuth.idToken;
    buyerUid = buyerAuth.localId;

    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    adminToken = adminAuth.idToken;

    const products = await discoverProducts();
    product = products[0]; // e2e_product_admin_seller
  });

  test('Price drop notification is triggered for favorited products', async ({ page }) => {
    // 1. Buyer favorites the product
    const favPath = `users/${buyerUid}/favorites/${product.id}`;
    await writeDoc(favPath, toFirestoreFields({
      productId: product.id,
      dateFavorited: new Date(),
    }), buyerToken, false);

    // 2. Verify favorited
    const favDoc = await readDoc(favPath, buyerToken);
    expect(favDoc).toBeTruthy();

    // 3. Admin drops price by 20%
    const oldPrice = product.price;
    const newPrice = +(oldPrice * 0.8).toFixed(2);
    
    await callOk('update_product', {
      productId: product.id,
      productData: { price: newPrice }
    }, adminToken);

    // 4. Wait for background trigger
    await page.waitForTimeout(10000);

    // 5. Verify notification in mail_logs
    const mailLogsResult = await callOk('e2e_get_mail_logs', { to: TEST_ACCOUNTS.BUYER_EMAIL }, adminToken);
    const logs = mailLogsResult.logs;

    const priceDropMail = logs.find((l: any) => 
      l.subject.includes('Price Drop') || 
      l.html.includes(product.name) && l.html.includes(newPrice.toString())
    );

    // Note: If real email sending is disabled in dev, we check the logs.
    // If our logic uses push instead of email, we check the notifications collection.
    if (!priceDropMail) {
        // Check notifications subcollection
        const notifs = await callOk('get_user_profile', {}, buyerToken);
        // Assuming get_user_profile might return some notifs or we read direct
        const notifSnap = await readDoc(`users/${buyerUid}/notifications`, buyerToken);
        // listCollection is better for subcollections
        const { listCollection } = require('./api-helpers');
        const userNotifs = await listCollection(`users/${buyerUid}/notifications`, buyerToken);
        const priceNotif = userNotifs.find((n: any) => n.type === 'price_drop');
        expect(priceNotif || priceDropMail, 'Price drop notification should exist in mail logs or user notifications').toBeTruthy();
    } else {
        expect(priceDropMail).toBeTruthy();
    }
  });

  test('Chat message notification is triggered', async ({ page }) => {
    // 1. Buyer sends message to seller (Admin owns product[0])
    const chatResult = await callOk('get_or_create_chat', { productId: product.id }, buyerToken);
    const chatId = chatResult.chatId;

    await callOk('send_message', {
      chatId,
      text: 'Hello from E2E test'
    }, buyerToken);

    // 2. Seller (Admin) replies
    await callOk('send_message', {
      chatId,
      text: 'Reply from Seller'
    }, adminToken);

    // 3. Wait for push trigger
    await page.waitForTimeout(5000);

    // 4. Verify notification for Buyer
    const { listCollection } = require('./api-helpers');
    const userNotifs = await listCollection(`users/${buyerUid}/notifications`, buyerToken);
    const chatNotif = userNotifs.find((n: any) => n.type === 'new_message' && n.chatId === chatId);
    
    expect(chatNotif, 'Buyer should receive a notification for the new message').toBeTruthy();
  });

  test('Message reporting (flagging) creates a report record', async () => {
    // 1. Get a message to report
    const chatResult = await callOk('get_or_create_chat', { productId: product.id }, buyerToken);
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

    // 3. Verify report doc exists in Firestore (admin only read usually, but we check via adminToken)
    const reportDoc = await readDoc(`message_reports/${reportResult.reportId}`, adminToken);
    expect(reportDoc).toBeTruthy();
    expect(parseDoc(reportDoc).reason).toBe('Harassment');
  });
});
