#!/usr/bin/env bun
/**
 * OrignaGTA — Dev Seed Script
 * Seeds the dev OrignaBase database with test data for E2E tests.
 * Idempotent — safe to run multiple times.
 *
 * Usage: cd e2e-agent-browser && bun run lib/seed-dev.ts
 */
import { writeDoc } from './api-client.js';
import { signIn } from './auth.js';
import { TEST_ACCOUNTS } from './config.js';

async function seed() {
  console.log('🌱 Seeding dev database...');

  // Get tokens
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const sellerAuth = await signIn(TEST_ACCOUNTS.SELLER_EMAIL, TEST_ACCOUNTS.SELLER_PASS);
  const buyerAuth = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);
  const adminToken = adminAuth.idToken;
  const sellerToken = sellerAuth.idToken;
  const buyerToken = buyerAuth.idToken;

  const now = Date.now();
  const buyerId = buyerAuth.localId;
  const sellerId = sellerAuth.localId;

  // ── Products ──
  console.log('  Products...');
  const products = [
    {
      id: 'e2e_seed_product_1',
      title: 'E2E Test Widget',
      description: 'A standard test product for E2E tests',
      priceCents: 2999,
      stockQuantity: 100,
      categoryId: 'electronics',
      subcategory: 'gadgets',
      lifecycleStatus: 'active',
      sellerId: `users:${sellerId}`,
      isDigital: false,
      isPerishable: false,
      imageUrl: 'https://placehold.co/400x400/667EEA/white?text=Widget',
      dateCreated: now,
    },
    {
      id: 'e2e_seed_product_2',
      title: 'E2E Premium Headphones',
      description: 'High-quality headphones for testing',
      priceCents: 8999,
      stockQuantity: 50,
      categoryId: 'electronics',
      subcategory: 'audio',
      lifecycleStatus: 'active',
      sellerId: `users:${sellerId}`,
      isDigital: false,
      isPerishable: false,
      imageUrl: 'https://placehold.co/400x400/764BA2/white?text=Headphones',
      dateCreated: now,
    },
    {
      id: 'e2e_seed_product_3',
      title: 'E2E Laptop Stand',
      description: 'Ergonomic laptop stand',
      priceCents: 4999,
      stockQuantity: 75,
      categoryId: 'office',
      subcategory: 'accessories',
      lifecycleStatus: 'active',
      sellerId: `users:${sellerId}`,
      isDigital: false,
      isPerishable: false,
      imageUrl: 'https://placehold.co/400x400/4ECDC4/white?text=Stand',
      dateCreated: now,
    },
    {
      id: 'e2e_product_digital',
      title: 'E2E Digital Guide',
      description: 'A digital product for testing digital flows',
      priceCents: 1499,
      stockQuantity: 999,
      categoryId: 'digital',
      subcategory: 'ebooks',
      lifecycleStatus: 'active',
      sellerId: `users:${sellerId}`,
      isDigital: true,
      isPerishable: false,
      imageUrl: 'https://placehold.co/400x400/FF6B6B/white?text=Digital',
      dateCreated: now,
    },
    {
      id: 'e2e_product_oos',
      title: 'E2E Out of Stock Item',
      description: 'A product with zero stock for OOS testing',
      priceCents: 3999,
      stockQuantity: 0,
      categoryId: 'electronics',
      subcategory: 'gadgets',
      lifecycleStatus: 'active',
      sellerId: `users:${sellerId}`,
      isDigital: false,
      isPerishable: false,
      imageUrl: 'https://placehold.co/400x400/95A5A6/white?text=OOS',
      dateCreated: now,
    },
    {
      id: 'e2e_product_perishable',
      title: 'E2E Fresh Organic Jam',
      description: 'A perishable product — local delivery only (50km)',
      priceCents: 1299,
      stockQuantity: 30,
      categoryId: 'food',
      subcategory: 'preserves',
      lifecycleStatus: 'active',
      sellerId: `users:${sellerId}`,
      isDigital: false,
      isPerishable: true,
      imageUrl: 'https://placehold.co/400x400/E67E22/white?text=Jam',
      dateCreated: now,
    },
  ];

  for (const p of products) {
    const { id, ...data } = p;
    try {
      await writeDoc(`products/${id}`, data, adminToken, false);
      console.log(`    ✓ Product: ${data.title}`);
    } catch (e: any) {
      console.log(`    ⚠ Product ${id}: ${e.message}`);
    }
  }

  // ── Favorites ──
  console.log('  Favorites...');
  const favProducts = ['e2e_seed_product_1', 'e2e_seed_product_2', 'e2e_product_digital'];
  for (const productId of favProducts) {
    const favId = `fav_${buyerId}_${productId}`;
    try {
      await writeDoc(`favorites/${favId}`, {
        userId: `users:${buyerId}`,
        productId: `products:${productId}`,
        createdAt: now,
      }, buyerToken, false);
      console.log(`    ✓ Favorite: ${productId}`);
    } catch (e: any) {
      console.log(`    ⚠ Favorite ${productId}: ${e.message}`);
    }
  }

  // ── Orders ──
  console.log('  Orders...');
  const orderItems = [
    { productId: `products:e2e_seed_product_1`, name: 'E2E Test Widget', quantity: 1, unitPriceCents: 2999, imageUrl: 'https://placehold.co/100' },
  ];
  const orders = [
    { id: 'e2e_order_pending', status: 'pending', createdAt: now - 86400000 * 2 },
    { id: 'e2e_order_confirmed', status: 'confirmed', createdAt: now - 86400000 },
    { id: 'e2e_order_delivered', status: 'delivered', createdAt: now - 86400000 * 7 },
  ];

  for (const o of orders) {
    try {
      await writeDoc(`orders/${o.id}`, {
        buyerId: `users:${buyerId}`,
        sellerId: `users:${sellerId}`,
        status: o.status,
        items: orderItems,
        subtotalCents: 2999,
        taxAmountCents: 390,
        shippingCostCents: 0,
        totalAmountCents: 3389,
        platformFeeTotalCents: 300,
        createdAt: o.createdAt,
        shippingAddress: {
          street: '123 Test St',
          city: 'Toronto',
          province: 'ON',
          postalCode: 'M5V 3A8',
          country: 'CA',
        },
      }, adminToken, false);
      console.log(`    ✓ Order: ${o.id} (${o.status})`);
    } catch (e: any) {
      console.log(`    ⚠ Order ${o.id}: ${e.message}`);
    }
  }

  // ── Seller Orders (assigned to seller) ──
  console.log('  Seller orders...');
  const sellerOrders = [
    { id: 'e2e_seller_order_1', status: 'confirmed', createdAt: now - 86400000 },
    { id: 'e2e_seller_order_2', status: 'shipped', createdAt: now - 86400000 * 3 },
  ];
  for (const o of sellerOrders) {
    try {
      await writeDoc(`orders/${o.id}`, {
        buyerId: `users:${buyerId}`,
        sellerId: `users:${sellerId}`,
        status: o.status,
        items: orderItems,
        subtotalCents: 2999,
        taxAmountCents: 390,
        shippingCostCents: 0,
        totalAmountCents: 3389,
        platformFeeTotalCents: 300,
        createdAt: o.createdAt,
        shippingAddress: {
          street: '456 Seller View Blvd',
          city: 'Montreal',
          province: 'QC',
          postalCode: 'H2X 1Y4',
          country: 'CA',
        },
      }, adminToken, false);
      console.log(`    ✓ Seller Order: ${o.id} (${o.status})`);
    } catch (e: any) {
      console.log(`    ⚠ Seller Order ${o.id}: ${e.message}`);
    }
  }

  // ── Addresses ──
  console.log('  Addresses...');
  const addresses = [
    {
      id: `addr_${buyerId}_toronto`,
      label: 'Home',
      street: '123 Test St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'CA',
      isDefault: true,
    },
    {
      id: `addr_${buyerId}_ottawa`,
      label: 'Office',
      street: '456 Parliament Hill',
      city: 'Ottawa',
      province: 'ON',
      postalCode: 'K1A 0A6',
      country: 'CA',
      isDefault: false,
    },
  ];
  for (const a of addresses) {
    const { id, ...data } = a;
    try {
      await writeDoc(`users/${buyerId}/addresses/${id}`, {
        ...data,
        userId: `users:${buyerId}`,
        createdAt: now,
      }, buyerToken, false);
      console.log(`    ✓ Address: ${data.city} (${data.label})`);
    } catch (e: any) {
      console.log(`    ⚠ Address ${id}: ${e.message}`);
    }
  }

  // ── Cart Items ──
  console.log('  Cart items...');
  const cartItems = [
    { id: `cart_${buyerId}_1`, productId: `products:e2e_seed_product_1`, quantity: 2, priceCents: 2999 },
    { id: `cart_${buyerId}_2`, productId: `products:e2e_seed_product_2`, quantity: 1, priceCents: 8999 },
  ];
  for (const c of cartItems) {
    const { id, ...data } = c;
    try {
      await writeDoc(`cart/${id}`, {
        ...data,
        userId: `users:${buyerId}`,
        dateCreated: now,
      }, buyerToken, false);
      console.log(`    ✓ Cart item: ${data.productId}`);
    } catch (e: any) {
      console.log(`    ⚠ Cart ${id}: ${e.message}`);
    }
  }

  // ── Chat Thread ──
  console.log('  Chat thread...');
  const chatId = `chat_${buyerId}_${sellerId}`;
  try {
    await writeDoc(`chats/${chatId}`, {
      participants: [`users:${buyerId}`, `users:${sellerId}`],
      lastMessage: 'Hi, is this item still available?',
      lastMessageAt: now,
      createdAt: now,
    }, buyerToken, false);

    await writeDoc(`chats/${chatId}/messages/msg_1`, {
      senderId: `users:${buyerId}`,
      text: 'Hi, is this item still available?',
      createdAt: now - 60000,
      read: false,
    }, buyerToken, false);

    await writeDoc(`chats/${chatId}/messages/msg_2`, {
      senderId: `users:${sellerId}`,
      text: 'Yes! It is in stock. Would you like to purchase?',
      createdAt: now,
      read: false,
    }, sellerToken, false);

    console.log('    ✓ Chat thread with 2 messages');
  } catch (e: any) {
    console.log(`    ⚠ Chat: ${e.message}`);
  }

  console.log('🌱 Seed complete!');
}

seed().catch((err) => {
  console.error('Seed failed:', err);
  process.exit(1);
});
