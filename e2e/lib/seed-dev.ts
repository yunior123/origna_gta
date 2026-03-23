#!/usr/bin/env bun
/**
 * OrignaGTA — Mega dev seed
 *
 * Seeds local/dev OrignaBase with:
 * - 2000+ products, all with sample images
 * - Stable canonical E2E products
 * - Full buyer state: favorites, addresses, cart, notifications
 * - Full seller state: warehouses, products, orders, chats, Q&A
 * - Full admin state: users, sellers, pending-review products, flagged reviews
 *
 * Usage:
 *   cd e2e-agent-browser
 *   ORIGNABASE_URL=http://127.0.0.1:8080 bun run lib/seed-dev.ts
 *
 * Optional env:
 *   SEED_PRODUCT_COUNT=2400
 */

import { signIn } from './auth.js';
import { TEST_ACCOUNTS } from './config.js';
import { writeDoc } from './api-client.js';

type AuthBundle = Awaited<ReturnType<typeof signIn>>;

type SeedUser = {
  id: string;
  email: string;
  displayName: string;
  roles: string[];
  isPremium?: boolean;
  suspended?: boolean;
  stripeOnboarded?: boolean;
};

const PRODUCT_COUNT = Math.max(2000, Number(process.env.SEED_PRODUCT_COUNT || 2400));
const PRODUCT_BATCH_SIZE = 24;
const REVIEW_COUNT = 120;
const QUESTION_COUNT = 80;
const NOTIFICATION_COUNT = 36;
const ADDRESS_COUNT = 8;
const FAVORITE_COUNT = 48;
const BUYER_CART_COUNT = 8;

const CATEGORY_LABELS = [
  'Electronics',
  'Computers',
  'Gaming',
  'Home & Kitchen',
  'Fashion',
  'Shoes & Accessories',
  'Jewelry & Watches',
  'Beauty',
  'Health',
  'Sports',
  'Automotive',
  'Tools',
  'Office',
  'Books',
  'Music',
  'Toys',
  'Baby',
  'Pets',
  'Groceries',
  'Art',
  'Digital',
];

const SUBCATEGORY_LABELS = [
  ['Phones', 'Audio', 'Cameras', 'Wearables'],
  ['Laptops', 'Monitors', 'Storage', 'Accessories'],
  ['Consoles', 'Controllers', 'Headsets', 'Furniture'],
  ['Cookware', 'Decor', 'Storage', 'Lighting'],
  ['Outerwear', 'Tops', 'Bottoms', 'Seasonal'],
  ['Sneakers', 'Bags', 'Belts', 'Travel'],
  ['Rings', 'Necklaces', 'Timepieces', 'Luxury'],
  ['Skincare', 'Haircare', 'Fragrance', 'Tools'],
  ['Supplements', 'Recovery', 'Care', 'Fitness'],
  ['Training', 'Outdoor', 'Cycling', 'Team'],
  ['Interior', 'Exterior', 'Safety', 'Maintenance'],
  ['Power Tools', 'Hand Tools', 'Shop', 'DIY'],
  ['Desk', 'Storage', 'Paper', 'Print'],
  ['Fiction', 'Nonfiction', 'Reference', 'Collectors'],
  ['Instruments', 'Recording', 'Vinyl', 'Accessories'],
  ['Board Games', 'Collectibles', 'STEM', 'Puzzles'],
  ['Nursery', 'Learning', 'Apparel', 'Travel'],
  ['Food', 'Toys', 'Beds', 'Care'],
  ['Produce', 'Pantry', 'Drinks', 'Specialty'],
  ['Originals', 'Prints', 'Ceramics', 'Decor'],
  ['Software', 'eBooks', 'Templates', 'Courses'],
];

const LIFECYCLE_SEQUENCE = [
  'active',
  'active',
  'active',
  'active',
  'draft',
  'under_review',
  'approved',
  'paused',
  'archived',
  'rejected',
];

const ORDER_STATUSES = ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled'] as const;
const NOTIFICATION_TYPES = [
  'order_confirmed',
  'order_shipped',
  'order_delivered',
  'new_review',
  'low_stock',
  'back_in_stock',
  'return_request',
  'payout_ready',
  'new_message',
];

function isoDaysAgo(days: number, extraMinutes = 0): string {
  return new Date(Date.now() - days * 86_400_000 - extraMinutes * 60_000).toISOString();
}

function sampleImageUrls(seed: string, count = 2): string[] {
  return Array.from({ length: count }, (_, index) =>
    `https://picsum.photos/seed/${encodeURIComponent(`${seed}-${index + 1}`)}/900/900`,
  );
}

function slugify(input: string): string {
  return input.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

function sellerAddress(label: string, country = 'Canada') {
  return {
    street: `${100 + label.length} ${label} Ave`,
    city: country === 'Canada' ? 'Toronto' : 'Shanghai',
    state: country === 'Canada' ? 'ON' : 'SH',
    postalCode: country === 'Canada' ? 'M5V 3A8' : '200001',
    country,
  };
}

function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function writeMany<T>(
  items: T[],
  worker: (item: T, index: number) => Promise<void>,
  batchSize = PRODUCT_BATCH_SIZE,
) {
  for (let start = 0; start < items.length; start += batchSize) {
    const slice = items.slice(start, start + batchSize);
    await Promise.all(
      slice.map((item, offset) => worker(item, start + offset)),
    );
  }
}

async function upsertUsers(admin: AuthBundle) {
  const coreUsers: SeedUser[] = [
    {
      id: admin.localId,
      email: TEST_ACCOUNTS.ADMIN_EMAIL,
      displayName: 'E2E Admin',
      roles: ['buyer', 'seller', 'admin'],
      isPremium: true,
      stripeOnboarded: true,
    },
    {
      id: (await signIn(TEST_ACCOUNTS.SELLER_EMAIL, TEST_ACCOUNTS.SELLER_PASS)).localId,
      email: TEST_ACCOUNTS.SELLER_EMAIL,
      displayName: 'E2E Seller',
      roles: ['buyer', 'seller'],
      isPremium: true,
      stripeOnboarded: true,
    },
    {
      id: (await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS)).localId,
      email: TEST_ACCOUNTS.BUYER_EMAIL,
      displayName: 'E2E Buyer',
      roles: ['buyer'],
      isPremium: true,
    },
  ];

  const syntheticUsers: SeedUser[] = [
    ...Array.from({ length: 8 }, (_, i) => ({
      id: `seed_seller_${String(i + 1).padStart(2, '0')}`,
      email: `seed-seller-${i + 1}@test.origna.ca`,
      displayName: `Seed Seller ${i + 1}`,
      roles: ['buyer', 'seller'],
      isPremium: i % 2 === 0,
      stripeOnboarded: i % 3 !== 0,
    })),
    ...Array.from({ length: 16 }, (_, i) => ({
      id: `seed_buyer_${String(i + 1).padStart(2, '0')}`,
      email: `seed-buyer-${i + 1}@test.origna.ca`,
      displayName: `Seed Buyer ${i + 1}`,
      roles: ['buyer'],
      isPremium: i % 4 === 0,
      suspended: i === 15,
    })),
  ];

  const users = [...coreUsers, ...syntheticUsers];
  await writeMany(users, async user => {
    await writeDoc(`users/${user.id}`, {
      email: user.email,
      displayName: user.displayName,
      roles: user.roles,
      isPremium: user.isPremium ?? false,
      premiumSince: user.isPremium ? isoDaysAgo(60) : null,
      premiumExpiresAt: user.isPremium ? isoDaysAgo(-30) : null,
      pushEnabled: true,
      notifyNewProducts: true,
      notifyTrending: true,
      emailVerified: true,
      suspended: user.suspended ?? false,
      stripeOnboarded: user.stripeOnboarded ?? false,
      preferredLanguage: 'en',
      createdAt: isoDaysAgo(45),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }, 20);

  return {
    adminId: coreUsers[0].id,
    sellerId: coreUsers[1].id,
    buyerId: coreUsers[2].id,
    sellerPool: [...new Set([coreUsers[0].id, coreUsers[1].id, ...syntheticUsers.filter(u => u.roles.includes('seller')).map(u => u.id)])],
    buyerPool: [...new Set([coreUsers[2].id, ...syntheticUsers.filter(u => u.roles.length === 1).map(u => u.id)])],
  };
}

function productVariantSeed(productId: string, basePriceCents: number) {
  const colors = ['Crimson', 'Ocean', 'Forest'];
  const sizes = ['S', 'M', 'L'];
  const variants = [];
  for (const color of colors) {
    for (const size of sizes) {
      variants.push({
        variantId: `${productId}_${slugify(color)}_${size.toLowerCase()}`,
        title: `${size} / ${color}`,
        sku: `${productId.toUpperCase()}-${size}-${color.slice(0, 2).toUpperCase()}`,
        priceCents: basePriceCents + sizes.indexOf(size) * 200,
        stockQuantity: 4 + colors.indexOf(color) + sizes.indexOf(size),
        imageUrls: sampleImageUrls(`${productId}-${size}-${color}`, 1),
        options: { Size: size, Color: color },
      });
    }
  }
  return {
    hasVariants: true,
    variantOptions: [
      { name: 'Size', values: sizes },
      { name: 'Color', values: colors },
    ],
    variants,
  };
}

async function seedProducts(
  admin: AuthBundle,
  ids: { adminId: string; sellerId: string; buyerId: string; sellerPool: string[]; buyerPool: string[] },
) {
  const stableProducts = [
    {
      id: 'e2e_product_admin_seller',
      sellerId: ids.adminId,
      categoryId: 1,
      categoryName: 'Electronics',
      title: 'Flagship Desk Setup Bundle',
      description: 'Complete desk setup with monitor stand, keyboard, and accessories',
      priceCents: 24999,
      lifecycleStatus: 'active',
      stockQuantity: 90,
      isDigital: false,
      isPerishable: false,
      freeShipping: true,
      hasVariants: true,
      subcategory: 'Monitors',
      shipFromCountry: 'Canada',
    },
    {
      id: 'e2e_product_test_seller',
      sellerId: ids.sellerId,
      categoryId: 21,
      categoryName: 'Digital',
      title: 'Creator Power Pack',
      description: 'Professional content creation toolkit with templates and assets',
      priceCents: 4999,
      lifecycleStatus: 'active',
      stockQuantity: 500,
      isDigital: true,
      isPerishable: false,
      freeShipping: true,
      hasVariants: false,
      subcategory: 'Software',
      shipFromCountry: 'Canada',
    },
    {
      id: 'e2e_product_intl_seller',
      sellerId: ids.sellerId,
      categoryId: 11,
      categoryName: 'Automotive',
      title: 'Imported Performance Parts Kit',
      description: 'High-quality aftermarket parts for performance upgrades',
      priceCents: 15999,
      lifecycleStatus: 'active',
      stockQuantity: 120,
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
      hasVariants: true,
      subcategory: 'Exterior',
      shipFromCountry: 'China',
    },
    {
      id: 'e2e_product_oos',
      sellerId: ids.sellerId,
      categoryId: 1,
      categoryName: 'Electronics',
      title: 'Sold Out Collector Camera',
      description: 'Rare vintage camera for collectors',
      priceCents: 89999,
      lifecycleStatus: 'active',
      stockQuantity: 0,
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
      hasVariants: false,
      subcategory: 'Cameras',
      shipFromCountry: 'Canada',
    },
    {
      id: 'e2e_product_perishable',
      sellerId: ids.sellerId,
      categoryId: 19,
      categoryName: 'Groceries',
      title: 'Fresh Small-Batch Citrus Box',
      description: 'Fresh seasonal citrus fruits from local farms',
      priceCents: 3499,
      lifecycleStatus: 'active',
      stockQuantity: 32,
      isDigital: false,
      isPerishable: true,
      freeShipping: false,
      hasVariants: false,
      subcategory: 'Produce',
      shipFromCountry: 'Canada',
    },
  ];

  const generatedProducts = Array.from({ length: PRODUCT_COUNT }, (_, index) => {
    const categoryId = (index % 21) + 1;
    const categoryName = CATEGORY_LABELS[categoryId - 1];
    const subcategory = SUBCATEGORY_LABELS[categoryId - 1][index % 4];
    const lifecycleStatus = LIFECYCLE_SEQUENCE[index % LIFECYCLE_SEQUENCE.length];
    const sellerId = ids.sellerPool[index % ids.sellerPool.length];
    const isDigital = categoryId === 21 || index % 17 === 0;
    const isPerishable = !isDigital && (categoryId === 19 || index % 19 === 0);
    const hasVariants = !isDigital && index % 5 === 0;
    const stockQuantity = lifecycleStatus === 'active'
      ? (index % 23 === 0 ? 0 : 5 + (index % 160))
      : 0;
    const priceCents = 500 + (index % 250) * 137;
    const id = `mega_seed_product_${String(index + 1).padStart(4, '0')}`;

    return {
      id,
      sellerId,
      categoryId,
      categoryName,
      subcategory,
      lifecycleStatus,
      title: `${categoryName} Showcase ${index + 1}`,
      description: `Seeded ${categoryName.toLowerCase()} product ${index + 1} for populated desktop and mobile states.`,
      stockQuantity,
      priceCents,
      isDigital,
      isPerishable,
      freeShipping: index % 6 === 0,
      isLocalDeliveryOnly: isPerishable || index % 9 === 0,
      hasVariants,
      shipFromCountry: sellerId === ids.sellerId && index % 11 === 0 ? 'China' : 'Canada',
      isTrending: lifecycleStatus === 'active' && index % 12 === 0,
      reviewCount: 2 + (index % 11),
      rating: Number((3.2 + ((index % 18) / 10)).toFixed(1)),
    };
  });

  const allProducts = [...stableProducts, ...generatedProducts];

  await writeMany(allProducts, async product => {
    const variants = product.hasVariants ? productVariantSeed(product.id, product.id.startsWith('e2e_') ? 2499 : product.priceCents) : {
      hasVariants: false,
      variantOptions: [],
      variants: [],
    };
    const imageUrls = sampleImageUrls(product.id, product.hasVariants ? 3 : 2);
    await writeDoc(`products/${product.id}`, {
      productId: product.id,
      sellerId: product.sellerId,
      sellerSku: `SKU-${product.id.toUpperCase()}`,
      name: product.title,
      title: product.title,
      slug: slugify(product.title),
      description: product.description,
      categoryId: product.categoryId,
      subcategory: product.subcategory,
      price: product.priceCents / 100,
      priceCents: product.priceCents,
      compareAtPrice: Number(((product.priceCents + 900) / 100).toFixed(2)),
      stockQuantity: product.stockQuantity,
      lifecycleStatus: product.lifecycleStatus,
      sellerAddress: sellerAddress(product.categoryName, product.shipFromCountry),
      shipFromCountry: product.shipFromCountry,
      shipFromProvince: product.shipFromCountry === 'Canada' ? 'ON' : 'SH',
      shipFromCity: product.shipFromCountry === 'Canada' ? 'Toronto' : 'Shanghai',
      imageUrls,
      videoUrl: product.id.endsWith('0001') ? 'https://samplelib.com/lib/preview/mp4/sample-5s.mp4' : null,
      videoDurationSeconds: product.id.endsWith('0001') ? 5 : null,
      keywords: [(product.categoryName || 'product').toLowerCase(), product.subcategory.toLowerCase(), 'seeded', 'demo'],
      createdAt: isoDaysAgo((allProducts.indexOf(product) % 60) + 1),
      updatedAt: new Date().toISOString(),
      rating: product.rating,
      ratingCount: product.reviewCount,
      isTrending: product.isTrending,
      trendingScore: product.isTrending ? 250 + (allProducts.indexOf(product) % 75) : 0,
      trendingAt: product.isTrending ? isoDaysAgo(1) : null,
      viewCount: 300 + (allProducts.indexOf(product) % 500),
      purchaseCount: 40 + (allProducts.indexOf(product) % 150),
      freeShipping: product.freeShipping,
      isDigital: product.isDigital,
      digitalType: product.isDigital ? (product.categoryId === 21 ? 'software' : 'book') : null,
      digitalBuilds: product.isDigital ? {
        mac: 'https://example.com/download/mac',
        windows: 'https://example.com/download/windows',
      } : null,
      isPerishable: product.isPerishable,
      isLocalDeliveryOnly: product.isLocalDeliveryOnly,
      estimatedShipDays: product.isDigital ? 0 : (product.isPerishable ? 1 : 3 + (allProducts.indexOf(product) % 4)),
      minimumOrderQuantity: product.isDigital ? 1 : 1 + (allProducts.indexOf(product) % 3),
      weightKg: product.isDigital ? 0.01 : Number((0.4 + ((allProducts.indexOf(product) % 15) * 0.2)).toFixed(2)),
      lengthCm: product.isDigital ? 1 : 18 + (allProducts.indexOf(product) % 20),
      widthCm: product.isDigital ? 1 : 12 + (allProducts.indexOf(product) % 12),
      heightCm: product.isDigital ? 1 : 4 + (allProducts.indexOf(product) % 10),
      warehouseIds: product.hasVariants ? [`wh_${product.sellerId}_main`, `wh_${product.sellerId}_east`] : [`wh_${product.sellerId}_main`],
      warehouseStockMap: product.hasVariants ? {
        [`wh_${product.sellerId}_main`]: Math.max(0, Math.floor(product.stockQuantity * 0.65)),
        [`wh_${product.sellerId}_east`]: Math.max(0, product.stockQuantity - Math.floor(product.stockQuantity * 0.65)),
      } : { [`wh_${product.sellerId}_main`]: product.stockQuantity },
      ...variants,
      approvalRejectionReason: product.lifecycleStatus === 'rejected' ? 'Seeded moderation rejection example' : null,
    }, admin.idToken, true);
  });

  return allProducts.map(product => product.id);
}

async function seedFavorites(admin: AuthBundle, buyerId: string, productIds: string[]) {
  const favorites = productIds.slice(0, FAVORITE_COUNT);
  await writeMany(favorites, async (productId, index) => {
    await writeDoc(`favorites/fav_${buyerId}_${productId}`, {
      userId: buyerId,
      productId,
      createdAt: isoDaysAgo(index % 14, index * 11),
    }, admin.idToken, true);
  }, 20);
}

async function seedAddresses(admin: AuthBundle, userId: string, prefix: string) {
  const cities = ['Toronto', 'Mississauga', 'Ottawa', 'Montreal', 'Vancouver', 'Calgary', 'Halifax', 'Quebec City'];
  await writeMany(cities.slice(0, ADDRESS_COUNT), async (city, index) => {
    await writeDoc(`addresses/${prefix}_address_${index + 1}`, {
      userId,
      label: index === 0 ? 'Home' : index === 1 ? 'Work' : `Address ${index + 1}`,
      street: `${100 + index} Demo ${city} St`,
      apartment: index % 2 === 0 ? `${index + 1}A` : '',
      city,
      province: ['ON', 'ON', 'ON', 'QC', 'BC', 'AB', 'NS', 'QC'][index],
      postalCode: ['M5V 3A8', 'L5B 2C9', 'K1P 1J1', 'H2Y 1C6', 'V6B 1A1', 'T2P 1J9', 'B3J 2K9', 'G1R 4P5'][index],
      country: 'Canada',
      isDefault: index === 0,
      createdAt: isoDaysAgo(index + 1),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }, 8);
}

async function seedWarehouses(admin: AuthBundle, sellerIds: string[]) {
  const warehouseEntries = sellerIds.flatMap(sellerId => [
    {
      path: `users/${sellerId}/warehouses/wh_${sellerId}_main`,
      data: {
        warehouseId: `wh_${sellerId}_main`,
        label: 'Main Warehouse',
        type: 'warehouse',
        address: {
          street: '100 Warehouse Way',
          city: 'Toronto',
          province: 'ON',
          postalCode: 'M5V 3A8',
          country: 'Canada',
        },
        isDefault: true,
        createdAt: isoDaysAgo(20),
      },
    },
    {
      path: `users/${sellerId}/warehouses/wh_${sellerId}_east`,
      data: {
        warehouseId: `wh_${sellerId}_east`,
        label: 'East Fulfillment',
        type: 'warehouse',
        address: {
          street: '250 Harbor Rd',
          city: 'Montreal',
          province: 'QC',
          postalCode: 'H2Y 1C6',
          country: 'Canada',
        },
        isDefault: false,
        createdAt: isoDaysAgo(12),
      },
    },
  ]);

  await writeMany(warehouseEntries, async entry => {
    await writeDoc(entry.path, entry.data, admin.idToken, true);
  }, 12);
}

async function seedCart(admin: AuthBundle, buyerId: string, productIds: string[]) {
  const cartProductIds = productIds.slice(0, BUYER_CART_COUNT);
  await writeMany(cartProductIds, async (productId, index) => {
    await writeDoc(`users/${buyerId}/cart/cart_${buyerId}_${index + 1}`, {
      userId: buyerId,
      productId,
      quantity: 1 + (index % 3),
      priceCents: 1999 + (index * 200),
      createdAt: isoDaysAgo(1, index * 4),
      buyerNote: index % 2 === 0 ? 'Gift wrap if available' : null,
      variantId: index % 2 === 0 ? `${productId}_crimson_m` : null,
      variantTitle: index % 2 === 0 ? 'M / Crimson' : null,
    }, admin.idToken, true);
  }, 10);
}

async function seedOrders(admin: AuthBundle, buyerId: string, sellerId: string, productIds: string[]) {
  const orders = Array.from({ length: 30 }, (_, index) => {
    const status = ORDER_STATUSES[index % ORDER_STATUSES.length];
    const sellerIds = index % 4 === 0 ? [sellerId, 'seed_seller_01'] : [sellerId];
    const lineItems = sellerIds.map((sid, itemIndex) => {
      const productId = productIds[(index * 3 + itemIndex) % productIds.length];
      return {
        productId,
        cartItemId: `order_${index + 1}_item_${itemIndex + 1}`,
        name: `Ordered Item ${index + 1}.${itemIndex + 1}`,
        description: 'Seeded order item for buyer/seller/admin dashboards.',
        price: 19.99 + itemIndex * 6,
        quantity: 1 + ((index + itemIndex) % 3),
        imageUrls: sampleImageUrls(`${productId}-order`, 1),
        sellerId: sid,
        status,
        isDigital: productId === 'e2e_product_test_seller',
        isPerishable: productId === 'e2e_product_perishable',
        freeShipping: itemIndex === 0,
      };
    });

    const subtotalCents = lineItems.reduce((sum, item) => sum + Math.round(item.price * 100) * item.quantity, 0);
    return {
      id: `seed_order_${String(index + 1).padStart(3, '0')}`,
      orderStatus: status,
      paymentStatus: status === 'cancelled' ? 'refunded' : 'paid',
      userId: buyerId,
      sellerIds,
      items: lineItems,
      subtotalCents,
      shippingCostCents: status === 'cancelled' ? 0 : 899 + (index % 3) * 200,
      taxAmountCents: Math.round(subtotalCents * 0.13),
      totalAmountCents: subtotalCents + Math.round(subtotalCents * 0.13) + (status === 'cancelled' ? 0 : 899 + (index % 3) * 200),
      createdAt: isoDaysAgo(index + 1),
      deliveredAt: status === 'delivered' ? isoDaysAgo(Math.max(1, index - 2)) : null,
      shippedAt: status === 'shipped' || status === 'delivered' ? isoDaysAgo(Math.max(1, index - 1)) : null,
      trackingNumber: status === 'shipped' || status === 'delivered' ? `TRK-${1000 + index}` : null,
      carrier: status === 'shipped' || status === 'delivered' ? 'canada_post' : null,
      shippingApprovalStatus: index % 7 === 0 ? 'pending' : 'approved',
      shippingAddress: {
        street: '123 Buyer Demo St',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      },
    };
  });

  await writeMany(orders, async order => {
    await writeDoc(`orders/${order.id}`, order, admin.idToken, true);
  }, 10);
}

async function seedNotifications(admin: AuthBundle, userIds: string[]) {
  const items = userIds.flatMap((userId, userIndex) =>
    Array.from({ length: NOTIFICATION_COUNT / userIds.length }, (_, index) => ({
      id: `notif_${userId}_${index + 1}`,
      userId,
      type: NOTIFICATION_TYPES[(userIndex + index) % NOTIFICATION_TYPES.length],
      title: `Seed notification ${index + 1}`,
      body: 'This seeded notification keeps the notifications center populated for demos.',
      isRead: index % 3 === 0,
      createdAt: isoDaysAgo(index % 10, index * 19),
      route: index % 2 === 0 ? '/orders' : '/notifications',
    })),
  );

  await writeMany(items, async item => {
    await writeDoc(`notifications/${item.id}`, item, admin.idToken, true);
  }, 24);
}

async function seedReviews(admin: AuthBundle, buyerIds: string[], sellerId: string, productIds: string[]) {
  const reviews = Array.from({ length: REVIEW_COUNT }, (_, index) => {
    const productId = productIds[index % productIds.length];
    const buyerId = buyerIds[index % buyerIds.length];
    return {
      id: `review_${String(index + 1).padStart(3, '0')}`,
      productId,
      userId: buyerId,
      sellerId,
      rating: (index % 5) + 1,
      review: `Seed review ${index + 1} for ${productId}`,
      createdAt: isoDaysAgo((index % 25) + 1, index),
      hasPhotos: index % 4 === 0,
      photoUrls: index % 4 === 0 ? sampleImageUrls(`review-${index + 1}`, 2) : [],
      isFlagged: index % 9 === 0,
      orderId: `seed_order_${String((index % 30) + 1).padStart(3, '0')}`,
    };
  });

  await writeMany(reviews, async review => {
    await writeDoc(`product_ratings/${review.id}`, review, admin.idToken, true);
  }, 24);
}

async function seedQuestions(admin: AuthBundle, buyerIds: string[], sellerId: string, productIds: string[]) {
  const questions = Array.from({ length: QUESTION_COUNT }, (_, index) => ({
    id: `qa_${String(index + 1).padStart(3, '0')}`,
    productId: productIds[index % productIds.length],
    sellerId,
    askerId: buyerIds[index % buyerIds.length],
    question: `Does seeded product ${index + 1} include extended warranty coverage?`,
    answer: index % 3 === 0 ? 'Yes, the seeded listing includes a sample answer for non-empty Q&A.' : null,
    answeredAt: index % 3 === 0 ? isoDaysAgo(index % 14) : null,
    answeredBy: index % 3 === 0 ? sellerId : null,
    isAnswered: index % 3 === 0,
    upvotes: index % 8,
    createdAt: isoDaysAgo((index % 20) + 1),
  }));

  await writeMany(questions, async question => {
    await writeDoc(`product_questions/${question.id}`, {
      questionId: question.id,
      ...question,
    }, admin.idToken, true);
  }, 24);
}

async function seedChats(admin: AuthBundle, buyerId: string, sellerId: string) {
  await writeDoc(`chats/chat_${buyerId}_${sellerId}`, {
    participants: [buyerId, sellerId],
    createdAt: isoDaysAgo(3),
    updatedAt: isoDaysAgo(1),
    lastMessage: 'The seeded catalog looks great. Can you bundle shipping?',
    lastMessageAt: isoDaysAgo(1),
  }, admin.idToken, true);

  const messages = [
    { id: 'msg_1', senderId: buyerId, text: 'Hi, I am interested in a bulk order.', createdAt: isoDaysAgo(3, 5) },
    { id: 'msg_2', senderId: sellerId, text: 'Absolutely. The seeded seller dashboard now has active conversations.', createdAt: isoDaysAgo(2, 45) },
    { id: 'msg_3', senderId: buyerId, text: 'Perfect. I also saved several items to favorites.', createdAt: isoDaysAgo(1, 15) },
  ];
  await writeMany(messages, async message => {
    await writeDoc(`chats/chat_${buyerId}_${sellerId}/messages/${message.id}`, {
      ...message,
      isRead: message.senderId === sellerId,
    }, admin.idToken, true);
  }, 8);
}

async function seedStockNotifications(admin: AuthBundle, buyerId: string) {
  await writeDoc(`stock_notifications/stock_${buyerId}_oos`, {
    userId: buyerId,
    productId: 'e2e_product_oos',
    createdAt: isoDaysAgo(2),
    isActive: true,
  }, admin.idToken, true);
}

async function seedSubscriptions(admin: AuthBundle, userIds: string[]) {
  const premiumUsers = userIds.slice(0, 18);
  const plans = ['premium_monthly', 'premium_yearly', 'premium_lifetime'] as const;
  
  for (let i = 0; i < premiumUsers.length; i++) {
    const userId = premiumUsers[i];
    const plan = plans[i % plans.length];
    const isActive = i < 15;
    const createdAt = isoDaysAgo(30 + (i % 20));
    
    await writeDoc(`subscriptions/${userId}`, {
      userId,
      planType: plan,
      status: isActive ? 'active' : i < 17 ? 'cancelled' : 'expired',
      currentPeriodStart: isActive ? isoDaysAgo(5) : createdAt,
      currentPeriodEnd: isActive ? isoDaysAgo(-10) : isoDaysAgo(2),
      cancelAtPeriodEnd: i === 16,
      features: ['unlimited_listings', 'priority_support', 'analytics', 'bulk_tools'],
      stripeSubscriptionId: `sub_seed_${userId}_${i}`,
      stripeCustomerId: `cus_seed_${userId}`,
      createdAt,
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}

async function seedSellerProfiles(admin: AuthBundle, sellerIds: string[]) {
  for (let i = 0; i < sellerIds.length; i++) {
    const sellerId = sellerIds[i];
    const onboarded = i % 3 !== 2;
    
    await writeDoc(`seller_profiles/${sellerId}`, {
      sellerId,
      businessName: `Seed Business ${i + 1}`,
      description: `Seeded seller profile for demonstration and testing purposes.`,
      chargesEnabled: onboarded,
      payoutsEnabled: onboarded,
      detailsSubmitted: onboarded,
      onboardingCompleted: onboarded && i % 2 === 0,
      pendingRequirements: onboarded ? [] : ['business_type', 'representative'],
      chargesEnabledAt: onboarded ? isoDaysAgo(15) : null,
      payoutsEnabledAt: onboarded ? isoDaysAgo(10) : null,
      defaultCurrency: 'CAD',
      defaultCountry: 'CA',
      stripeAccountId: `acct_seed_${sellerId}`,
      createdAt: isoDaysAgo(30),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}

async function seedSellerMetrics(admin: AuthBundle, sellerIds: string[]) {
  for (let i = 0; i < sellerIds.length; i++) {
    const sellerId = sellerIds[i];
    const totalReviews = 15 + (i * 12);
    const positiveReviews = Math.floor(totalReviews * (0.75 + (i % 20) / 100));
    
    await writeDoc(`seller_metrics/${sellerId}`, {
      sellerId,
      avgResponseTimeMinutes: 15 + (i * 8),
      positiveRatePct: Math.round((positiveReviews / totalReviews) * 100),
      totalReviews,
      totalSales: 50 + (i * 35),
      totalRevenueCents: 500000 + (i * 150000),
      shipOnTimePct: 85 + (i % 15),
      returnRatePct: 3 + (i % 8),
      accountAgeDays: 30 + (i * 15),
      lastActivityAt: isoDaysAgo(i % 5),
      createdAt: isoDaysAgo(30),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}

async function seedReturnRequests(admin: AuthBundle, buyerId: string, sellerId: string, productIds: string[]) {
  const statuses = ['pending', 'approved', 'rejected', 'completed', 'refunded'] as const;
  const reasons = ['defective_product', 'wrong_item', 'not_as_described', 'arrived_damaged', 'changed_mind'];
  
  for (let i = 0; i < 15; i++) {
    const orderId = `seed_order_${String((i % 30) + 1).padStart(3, '0')}`;
    const status = statuses[i % statuses.length];
    const productId = productIds[i % productIds.length];
    
    await writeDoc(`return_requests/return_${String(i + 1).padStart(3, '0')}`, {
      returnId: `return_${String(i + 1).padStart(3, '0')}`,
      orderId,
      buyerId,
      sellerId,
      productId,
      reason: reasons[i % reasons.length],
      description: `Seed return request ${i + 1} for testing return flow UI.`,
      status,
      refundAmountCents: 1999 + (i * 500),
      refundMethod: status === 'refunded' ? 'original_payment' : null,
      requestedAt: isoDaysAgo(i % 20),
      reviewedAt: status !== 'pending' ? isoDaysAgo(i % 10) : null,
      resolvedAt: ['completed', 'refunded'].includes(status) ? isoDaysAgo(i % 5) : null,
      adminNotes: status === 'rejected' ? 'Seed rejection reason' : null,
    }, admin.idToken, true);
  }
}

async function seedCategories(admin: AuthBundle) {
  const categories = [
    { id: 1, name: 'Electronics', icon: '📱', displayOrder: 1 },
    { id: 2, name: 'Computers', icon: '💻', displayOrder: 2 },
    { id: 3, name: 'Gaming', icon: '🎮', displayOrder: 3 },
    { id: 4, name: 'Home & Kitchen', icon: '🏠', displayOrder: 4 },
    { id: 5, name: 'Fashion', icon: '👕', displayOrder: 5 },
    { id: 6, name: 'Shoes & Accessories', icon: '👟', displayOrder: 6 },
    { id: 7, name: 'Jewelry & Watches', icon: '💎', displayOrder: 7 },
    { id: 8, name: 'Beauty', icon: '💄', displayOrder: 8 },
    { id: 9, name: 'Health', icon: '💪', displayOrder: 9 },
    { id: 10, name: 'Sports', icon: '⚽', displayOrder: 10 },
    { id: 11, name: 'Automotive', icon: '🚗', displayOrder: 11 },
    { id: 12, name: 'Tools', icon: '🔧', displayOrder: 12 },
    { id: 13, name: 'Office', icon: '📋', displayOrder: 13 },
    { id: 14, name: 'Books', icon: '📚', displayOrder: 14 },
    { id: 15, name: 'Music', icon: '🎵', displayOrder: 15 },
    { id: 16, name: 'Toys', icon: '🧸', displayOrder: 16 },
    { id: 17, name: 'Baby', icon: '👶', displayOrder: 17 },
    { id: 18, name: 'Pets', icon: '🐾', displayOrder: 18 },
    { id: 19, name: 'Groceries', icon: '🥦', displayOrder: 19 },
    { id: 20, name: 'Art', icon: '🎨', displayOrder: 20 },
    { id: 21, name: 'Digital', icon: '💾', displayOrder: 21 },
  ];

  for (const cat of categories) {
    await writeDoc(`categories/${cat.id}`, {
      id: cat.id,
      name: cat.name,
      icon: cat.icon,
      displayOrder: cat.displayOrder,
      productCount: 80 + (cat.id * 12),
      isActive: true,
      createdAt: isoDaysAgo(60),
    }, admin.idToken, true);
  }
}

async function seedMoreChats(admin: AuthBundle, buyerIds: string[], sellerIds: string[], productIds: string[]) {
  const chatPairs = [];
  
  for (let i = 0; i < 10; i++) {
    const buyerId = buyerIds[i % buyerIds.length];
    const sellerId = sellerIds[i % sellerIds.length];
    if (buyerId !== sellerId) {
      chatPairs.push({ buyerId, sellerId, productId: productIds[(i * 3) % productIds.length] });
    }
  }

  for (let i = 0; i < chatPairs.length; i++) {
    const { buyerId, sellerId, productId } = chatPairs[i];
    const chatId = `chat_${buyerId}_${sellerId}_${i}`;
    
    await writeDoc(`chats/${chatId}`, {
      participants: [buyerId, sellerId],
      productId,
      createdAt: isoDaysAgo(5 - (i % 5)),
      updatedAt: isoDaysAgo(i % 3),
      lastMessage: `Seed chat message ${i + 1}`,
      lastMessageAt: isoDaysAgo(i % 3, i * 10),
    }, admin.idToken, true);

    const messages = [
      { id: `msg_1`, senderId: buyerId, text: `Hi, is product ${productId} available?`, createdAt: isoDaysAgo(5 - (i % 5)) },
      { id: `msg_2`, senderId: sellerId, text: 'Yes, it is in stock!', createdAt: isoDaysAgo(4 - (i % 5), 30) },
      { id: `msg_3`, senderId: buyerId, text: 'Great, can you hold it for me?', createdAt: isoDaysAgo(3 - (i % 5), 15) },
      { id: `msg_4`, senderId: sellerId, text: `Seed reply ${i + 1}`, createdAt: isoDaysAgo(i % 3, i * 10) },
    ];

    for (const msg of messages) {
      await writeDoc(`chats/${chatId}/messages/${msg.id}`, {
        ...msg,
        isRead: msg.senderId === sellerId,
      }, admin.idToken, true);
    }
  }
}

async function main() {
  console.log(`🌱 Mega seeding ${process.env.ORIGNABASE_URL || 'default'} with ${PRODUCT_COUNT}+ products...`);

  const admin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const seller = await signIn(TEST_ACCOUNTS.SELLER_EMAIL, TEST_ACCOUNTS.SELLER_PASS);
  const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);

  const ids = await upsertUsers(admin);
  console.log(`  ✓ users seeded (admin=${ids.adminId}, seller=${ids.sellerId}, buyer=${ids.buyerId})`);

  await seedWarehouses(admin, [ids.adminId, ids.sellerId, 'seed_seller_01', 'seed_seller_02']);
  console.log('  ✓ warehouses seeded');

  const productIds = await seedProducts(admin, ids);
  console.log(`  ✓ products seeded (${productIds.length})`);

  await seedFavorites(admin, ids.buyerId, productIds.filter(id => id !== 'e2e_product_oos'));
  console.log(`  ✓ favorites seeded (${FAVORITE_COUNT})`);

  await seedAddresses(admin, ids.buyerId, 'buyer');
  await seedAddresses(admin, ids.adminId, 'admin');
  console.log(`  ✓ addresses seeded (${ADDRESS_COUNT * 2})`);

  await seedCart(admin, ids.buyerId, productIds);
  console.log(`  ✓ cart seeded (${BUYER_CART_COUNT})`);

  await seedOrders(admin, ids.buyerId, ids.sellerId, productIds);
  console.log('  ✓ orders seeded (30)');

  await seedNotifications(admin, [ids.buyerId, ids.sellerId, ids.adminId]);
  console.log(`  ✓ notifications seeded (${NOTIFICATION_COUNT})`);

  await seedReviews(admin, [ids.buyerId, 'seed_buyer_01', 'seed_buyer_02', 'seed_buyer_03'], ids.sellerId, productIds);
  console.log(`  ✓ reviews seeded (${REVIEW_COUNT})`);

  await seedQuestions(admin, [ids.buyerId, 'seed_buyer_04', 'seed_buyer_05'], ids.sellerId, productIds);
  console.log(`  ✓ Q&A seeded (${QUESTION_COUNT})`);

  await seedChats(admin, ids.buyerId, ids.sellerId);
  await seedStockNotifications(admin, ids.buyerId);
  console.log('  ✓ chats and stock notifications seeded');

  const allUserIds = [ids.adminId, ids.sellerId, ids.buyerId, ...ids.sellerPool, ...ids.buyerPool];
  const allSellerIds = [ids.adminId, ids.sellerId, 'seed_seller_01', 'seed_seller_02'];

  await seedSubscriptions(admin, allUserIds);
  console.log(`  ✓ subscriptions seeded (18)`);

  await seedSellerProfiles(admin, allSellerIds);
  console.log('  ✓ seller profiles seeded');

  await seedSellerMetrics(admin, allSellerIds);
  console.log('  ✓ seller metrics seeded');

  await seedReturnRequests(admin, ids.buyerId, ids.sellerId, productIds);
  console.log('  ✓ return requests seeded (15)');

  await seedCategories(admin);
  console.log('  ✓ categories seeded (21)');

  const allBuyerIds = [ids.buyerId, ...ids.buyerPool.filter((_, i) => i < 10)];
  await seedMoreChats(admin, allBuyerIds, allSellerIds, productIds);
  console.log('  ✓ additional chat threads seeded (10)');

  await delay(1500);
  console.log('🌱 Mega seed complete.');
  console.log(`   Products: ${productIds.length}`);
  console.log(`   Collections seeded: users, products, favorites, addresses, warehouses, cart, orders,`);
  console.log(`     notifications, reviews, Q&A, chats, stock_notifications, subscriptions,`);
  console.log(`     seller_profiles, seller_metrics, return_requests, categories`);
  console.log(`   All views and widgets now have populated non-empty state for demos.`);
}

main().catch(err => {
  console.error('Mega seed failed:', err);
  process.exit(1);
});
