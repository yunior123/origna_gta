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
import { callOk, obGraphQL, parseGraphQLValue, writeDoc } from './api-client.js';
import { existsSync, unlinkSync } from 'node:fs';

type AuthBundle = Awaited<ReturnType<typeof signIn>>;

type SeedUser = {
  seedKey?: string;
  id: string;
  email: string;
  displayName: string;
  roles: string[];
  isPremium?: boolean;
  suspended?: boolean;
  stripeOnboarded?: boolean;
};

type SeededAuthBundle = AuthBundle & {
  seedKey?: string;
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
const DISPUTE_COUNT = 12;
const COUPON_COUNT = 18;
const PROMOTION_COUNT = 8;
const DOWNLOAD_SESSION_COUNT = 6;
const STOCK_NOTIFICATION_COUNT = 12;

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
const LEGACY_TEST_EMAILS = [
  'yuniorrodriguezo460@gmail.com',
  'yr62813@gmail.com',
  'yuniorrodriguezo4601@yahoo.com',
] as const;
const CANADIAN_ADDRESS_LABELS = ['Home', 'Work', 'Other', 'Studio', 'Parents'] as const;
const PRIMARY_SELLER_DASHBOARD_PRODUCTS = [
  { id: 'seller_dash_active_01', title: 'Seller Dashboard Active Camera', categoryId: 1, categoryName: 'Electronics', subcategory: 'Cameras', priceCents: 18999, lifecycleStatus: 'active', stockQuantity: 18 },
  { id: 'seller_dash_active_02', title: 'Seller Dashboard Active Headphones', categoryId: 1, categoryName: 'Electronics', subcategory: 'Audio', priceCents: 8999, lifecycleStatus: 'active', stockQuantity: 42 },
  { id: 'seller_dash_active_03', title: 'Seller Dashboard Active Desk Lamp', categoryId: 4, categoryName: 'Home & Kitchen', subcategory: 'Lighting', priceCents: 4599, lifecycleStatus: 'active', stockQuantity: 27 },
  { id: 'seller_dash_active_04', title: 'Seller Dashboard Active Sneakers', categoryId: 6, categoryName: 'Shoes & Accessories', subcategory: 'Sneakers', priceCents: 11999, lifecycleStatus: 'active', stockQuantity: 24 },
  { id: 'seller_dash_active_05', title: 'Seller Dashboard Active Keyboard', categoryId: 2, categoryName: 'Computers', subcategory: 'Accessories', priceCents: 13999, lifecycleStatus: 'active', stockQuantity: 35 },
  { id: 'seller_dash_draft_01', title: 'Seller Dashboard Draft Bundle', categoryId: 21, categoryName: 'Digital', subcategory: 'Templates', priceCents: 2999, lifecycleStatus: 'draft', stockQuantity: 0 },
  { id: 'seller_dash_draft_02', title: 'Seller Dashboard Draft Office Kit', categoryId: 13, categoryName: 'Office', subcategory: 'Desk', priceCents: 6599, lifecycleStatus: 'draft', stockQuantity: 0 },
  { id: 'seller_dash_draft_03', title: 'Seller Dashboard Draft Winter Coat', categoryId: 5, categoryName: 'Fashion', subcategory: 'Outerwear', priceCents: 22999, lifecycleStatus: 'draft', stockQuantity: 0 },
  { id: 'seller_dash_inactive_01', title: 'Seller Dashboard Inactive Monitor', categoryId: 2, categoryName: 'Computers', subcategory: 'Monitors', priceCents: 26999, lifecycleStatus: 'paused', stockQuantity: 0 },
  { id: 'seller_dash_inactive_02', title: 'Seller Dashboard Inactive Blender', categoryId: 4, categoryName: 'Home & Kitchen', subcategory: 'Cookware', priceCents: 9999, lifecycleStatus: 'archived', stockQuantity: 0 },
  { id: 'seller_dash_inactive_03', title: 'Seller Dashboard Inactive Cycling Jersey', categoryId: 10, categoryName: 'Sports', subcategory: 'Cycling', priceCents: 7499, lifecycleStatus: 'paused', stockQuantity: 0 },
  { id: 'seller_dash_inactive_04', title: 'Seller Dashboard Inactive Travel Bag', categoryId: 6, categoryName: 'Shoes & Accessories', subcategory: 'Travel', priceCents: 15999, lifecycleStatus: 'archived', stockQuantity: 0 },
] as const;

function isoDaysAgo(days: number, extraMinutes = 0): string {
  return new Date(Date.now() - days * 86_400_000 - extraMinutes * 60_000).toISOString();
}

// Product images hosted on Cloudflare R2 (orignagta bucket) — passes backend URL validation
const R2_BASE = 'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples';
const PRODUCT_IMAGE_POOLS: Record<string, string[]> = {
  electronics: [
    `${R2_BASE}/electronics-1.jpg`, // laptop
    `${R2_BASE}/electronics-2.jpg`, // headphones
    `${R2_BASE}/electronics-3.jpg`, // phone
    `${R2_BASE}/electronics-4.jpg`, // monitor
  ],
  groceries: [
    `${R2_BASE}/food-1.jpg`,   // vegetables
    `${R2_BASE}/food-2.jpg`,   // fruits
    `${R2_BASE}/food-3.jpg`,   // bread
    `${R2_BASE}/food-4.jpg`,   // burger
  ],
  clothing: [
    `${R2_BASE}/clothing-1.jpg`, // clothes
    `${R2_BASE}/clothing-2.jpg`, // shoes
    `${R2_BASE}/clothing-3.jpg`, // watch
    `${R2_BASE}/clothing-4.jpg`, // sneakers
  ],
  default: [
    `${R2_BASE}/home-1.jpg`,    // desk setup
    `${R2_BASE}/home-2.jpg`,    // bottles
    `${R2_BASE}/home-3.jpg`,    // product flat
    `${R2_BASE}/auto-1.jpg`,    // car
    `${R2_BASE}/auto-2.jpg`,    // car 2
    `${R2_BASE}/books-1.jpg`,   // book
    `${R2_BASE}/digital-1.jpg`, // code
    `${R2_BASE}/digital-2.jpg`, // laptop code
  ],
};

const PRODUCT_VIDEO_URLS = [
  'https://samplelib.com/lib/preview/mp4/sample-5s.mp4',
  'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
  'https://samplelib.com/lib/preview/mp4/sample-15s.mp4',
] as const;

function sampleVideo(seed: string): { url: string; durationSeconds: number } {
  let hash = 0;
  for (let i = 0; i < seed.length; i++) hash = ((hash << 5) - hash + seed.charCodeAt(i)) | 0;
  const index = Math.abs(hash % PRODUCT_VIDEO_URLS.length);
  return {
    url: PRODUCT_VIDEO_URLS[index],
    durationSeconds: index == 0 ? 5 : index == 1 ? 10 : 15,
  };
}

function sampleImageUrls(seed: string, count = 2, category?: string): string[] {
  const cat = (category || '').toLowerCase();
  const pool = cat.includes('electron') || cat.includes('digital') || cat.includes('computer')
    ? PRODUCT_IMAGE_POOLS.electronics
    : cat.includes('grocer') || cat.includes('food') || cat.includes('produce')
    ? PRODUCT_IMAGE_POOLS.groceries
    : cat.includes('cloth') || cat.includes('shoe') || cat.includes('accessor')
    ? PRODUCT_IMAGE_POOLS.clothing
    : PRODUCT_IMAGE_POOLS.default;

  // Deterministic selection based on seed hash
  let hash = 0;
  for (let i = 0; i < seed.length; i++) hash = ((hash << 5) - hash + seed.charCodeAt(i)) | 0;

  return Array.from({ length: count }, (_, index) => {
    const idx = Math.abs((hash + index * 7) % pool.length);
    return pool[idx];
  });
}

function slugify(input: string): string {
  return input.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

function userIdFromEmail(email: string): string {
  return `seed_${slugify(email.replace('@', '-at-'))}`;
}

function userRef(userId: string): string {
  return userId.startsWith('users:') ? userId : `users:${userId}`;
}

async function resolveSeedUser(email: string, password: string, fallbackRoles: string[]) {
  try {
    const auth = await signIn(email, password);
    return { id: auth.localId, email: auth.email, roles: fallbackRoles };
  } catch {
    return { id: userIdFromEmail(email), email, roles: fallbackRoles };
  }
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

// ════════════════════════════════════════════════════════════════════
// SYNTHETIC USER GENERATION — CANADIAN NAMES + ADDRESSES
// ════════════════════════════════════════════════════════════════════

const CANADIAN_FIRST_NAMES_EN = [
  'James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph', 'Thomas', 'Christopher',
  'Daniel', 'Matthew', 'Anthony', 'Donald', 'Steven', 'Paul', 'Andrew', 'Joshua', 'Kenneth', 'Kevin',
  'Brian', 'George', 'Edward', 'Ronald', 'Timothy', 'Jason', 'Jeffrey', 'Ryan', 'Jacob', 'Gary',
  'Sarah', 'Mary', 'Patricia', 'Jennifer', 'Linda', 'Barbara', 'Elizabeth', 'Susan', 'Jessica', 'Karen',
  'Nancy', 'Lisa', 'Betty', 'Margaret', 'Sandra', 'Ashley', 'Kimberly', 'Emily', 'Donna', 'Michelle',
  'Dorothy', 'Carol', 'Amanda', 'Melissa', 'Deborah', 'Stephanie', 'Rebecca', 'Sharon', 'Laura', 'Cynthia',
];

const CANADIAN_FIRST_NAMES_FR = [
  'Jean', 'Pierre', 'Marc', 'Alain', 'André', 'Paul', 'François', 'Michel', 'Georges', 'Luc',
  'Philippe', 'Christian', 'Claude', 'Serge', 'Gérard', 'Patrick', 'Daniel', 'Yves', 'Olivier', 'Laurent',
  'Marie', 'Cécile', 'Sylvie', 'Michèle', 'Christine', 'Chantal', 'Francine', 'Nicole', 'Rolande', 'Josée',
  'Danielle', 'Jacqueline', 'Hélène', 'Mariane', 'Pauline', 'Géraldine', 'Béatrice', 'Thérèse', 'Suzanne', 'Monique',
];

const CANADIAN_LAST_NAMES_EN = [
  'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez',
  'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson', 'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin',
  'Lee', 'White', 'Harris', 'King', 'Scott', 'Green', 'Hall', 'Young', 'Hernandez', 'Wood',
];

const CANADIAN_LAST_NAMES_FR = [
  'Dupont', 'Durand', 'Leclerc', 'Boucher', 'Gagnon', 'Côté', 'Gosselin', 'Beaumont', 'Delisle', 'Dion',
  'Fontaine', 'Gauthier', 'Giroux', 'Godin', 'Gravel', 'Grise', 'Grondines', 'Guérard', 'Guiel', 'Guimond',
  'Gujay', 'Guitard', 'Guimond', 'Labelle', 'Labonté', 'Laborde', 'Labrecque', 'Lacasse', 'Lacerne', 'Lachance',
];

const CANADIAN_CITIES = [
  { city: 'Toronto', province: 'ON', postalPrefix: 'M' },
  { city: 'Montreal', province: 'QC', postalPrefix: 'H' },
  { city: 'Vancouver', province: 'BC', postalPrefix: 'V' },
  { city: 'Calgary', province: 'AB', postalPrefix: 'T' },
  { city: 'Ottawa', province: 'ON', postalPrefix: 'K' },
  { city: 'Edmonton', province: 'AB', postalPrefix: 'T' },
  { city: 'Winnipeg', province: 'MB', postalPrefix: 'R' },
  { city: 'Quebec City', province: 'QC', postalPrefix: 'G' },
  { city: 'Hamilton', province: 'ON', postalPrefix: 'L' },
  { city: 'Kitchener', province: 'ON', postalPrefix: 'N' },
  { city: 'London', province: 'ON', postalPrefix: 'N' },
  { city: 'Halifax', province: 'NS', postalPrefix: 'B' },
  { city: 'Victoria', province: 'BC', postalPrefix: 'V' },
  { city: 'Saskatoon', province: 'SK', postalPrefix: 'S' },
  { city: 'Mississauga', province: 'ON', postalPrefix: 'L' },
];

function generateCanadianPostalCode(seed: number, postalPrefix: string): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  const rng = (seed * 9301 + 49297) % 233280; // Simple LCG
  const digit1 = String(Math.abs(rng) % 10);
  const letter1 = chars[Math.abs(rng * 17) % chars.length];
  const digit2 = String(Math.abs(rng * 19) % 10);
  const space = ' ';
  const digit3 = String(Math.abs(rng * 23) % 10);
  const letter2 = chars[Math.abs(rng * 29) % chars.length];
  const digit4 = String(Math.abs(rng * 31) % 10);
  return `${postalPrefix}${digit1}${letter1} ${digit2}${letter2}${digit4}`;
}

function generateCanadianAddress(seed: number) {
  const cityData = CANADIAN_CITIES[seed % CANADIAN_CITIES.length];
  const streetNum = 100 + (seed * 17) % 9900;
  const streetNames = ['Main', 'Oak', 'Maple', 'Pine', 'Elm', 'Cedar', 'King', 'Queen', 'Princess', 'Prince'];
  const streetName = streetNames[seed % streetNames.length];
  return {
    street: `${streetNum} ${streetName} St`,
    city: cityData.city,
    state: cityData.province,
    postalCode: generateCanadianPostalCode(seed, cityData.postalPrefix),
    country: 'Canada',
  };
}

function generateSyntheticUserName(seed: number): { firstName: string; lastName: string; email: string } {
  const isEnglish = seed % 3 !== 0; // ~67% English, ~33% French
  const isMale = seed % 2 === 0;
  
  let firstName: string;
  let lastName: string;

  if (isEnglish) {
    firstName = CANADIAN_FIRST_NAMES_EN[seed % CANADIAN_FIRST_NAMES_EN.length];
    lastName = CANADIAN_LAST_NAMES_EN[(seed * 7) % CANADIAN_LAST_NAMES_EN.length];
  } else {
    firstName = CANADIAN_FIRST_NAMES_FR[seed % CANADIAN_FIRST_NAMES_FR.length];
    lastName = CANADIAN_LAST_NAMES_FR[(seed * 7) % CANADIAN_LAST_NAMES_FR.length];
  }

  const email = `user-${String(seed).padStart(6, '0')}@test.origna.ca`;
  return { firstName, lastName, email };
}

async function seedSyntheticUsers(admin: AuthBundle, count: number = 5000) {
  console.log(`  Generating ${count} synthetic users...`);
  
  const users: SeedUser[] = [];
  
  for (let i = 0; i < count; i++) {
    const { firstName, lastName, email } = generateSyntheticUserName(i);
    const roleRoll = Math.random();
    let roles: string[];
    
    if (roleRoll < 0.80) {
      roles = ['buyer']; // 80% buyer only
    } else if (roleRoll < 0.95) {
      roles = ['buyer', 'seller']; // 15% buyer + seller
    } else {
      roles = ['buyer', 'admin']; // 5% buyer + admin
    }

    users.push({
      id: `synthetic_user_${String(i).padStart(6, '0')}`,
      email,
      displayName: `${firstName} ${lastName}`,
      roles,
      isPremium: Math.random() < 0.12, // ~12% premium
      stripeOnboarded: roles.includes('seller') ? Math.random() < 0.85 : false,
    });
  }

  // Write in batches of 50
  await writeMany(users, async user => {
    const cityData = CANADIAN_CITIES[Math.abs(user.id.charCodeAt(0) * 7) % CANADIAN_CITIES.length];
    const seed = parseInt(user.id.split('_')[2] || '0');
    const address = generateCanadianAddress(seed);
    
    await writeDoc(`users/${user.id}`, {
      email: user.email,
      displayName: user.displayName,
      roles: user.roles,
      isPremium: user.isPremium ?? false,
      premiumSince: user.isPremium ? isoDaysAgo(Math.random() * 180) : null,
      premiumExpiresAt: user.isPremium ? isoDaysAgo(-Math.random() * 90) : null,
      pushEnabled: Math.random() > 0.2, // 80% have push enabled
      notifyNewProducts: Math.random() > 0.3, // 70% subscribed to new products
      notifyTrending: Math.random() > 0.4, // 60% subscribed to trending
      emailVerified: true,
      suspended: false,
      stripeOnboarded: user.stripeOnboarded ?? false,
      preferredLanguage: Math.random() < 0.25 ? 'fr' : 'en',
      profileImageUrl: sampleImageUrls(`profile-${user.id}`, 1, 'fashion')[0],
      homeAddress: address,
      createdAt: isoDaysAgo(Math.random() * 365), // Random join date up to 1 year
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }, 50);

  console.log(`  ✓ ${count} synthetic users created`);
}

// ════════════════════════════════════════════════════════════════════
// ENHANCED FAVORITES — MORE REALISTIC DISTRIBUTION
// ════════════════════════════════════════════════════════════════════

async function seedEnhancedFavorites(admin: AuthBundle, buyerIds: string[], productIds: string[]) {
  const favorites: any[] = [];
  let favoriteIndex = 0;

  for (const buyerId of buyerIds) {
    // Each buyer has 5-20 favorites
    const favCount = 5 + Math.floor(Math.random() * 16);
    const buyerFavs = new Set<string>();
    
    while (buyerFavs.size < favCount && productIds.length > 0) {
      const product = productIds[Math.floor(Math.random() * productIds.length)];
      if (product !== 'e2e_product_oos') buyerFavs.add(product);
    }

    for (const productId of buyerFavs) {
      const createdAt = isoDaysAgo(Math.random() * 90);
      favorites.push({
        id: `favorite_${buyerId}_${favoriteIndex++}`,
        userId: buyerId,
        productId,
        createdAt,
        dateFavorited: createdAt,
        note: Math.random() > 0.7 ? 'Wishlist item' : undefined,
      });
    }
  }

  await writeMany(favorites, async fav => {
    await writeDoc(`favorites/${fav.id}`, fav, admin.idToken, true);
  }, 50);
}

async function listFavoritesForUser(token: string, userId: string): Promise<any[]> {
  const query = `
    query ListFavorites($collection: String!, $filters: JSON) {
      list(collection: $collection, filters: $filters, limit: 200)
    }
  `;
  const result = await obGraphQL(
    query,
    {
      collection: 'favorites',
      filters: { userId: { _eq: userRef(userId) } },
    },
    token,
  );
  if (!result.ok) return [];
  const raw = parseGraphQLValue(result.body?.data?.list);
  return Array.isArray(raw) ? raw.filter(item => item && typeof item === 'object') : [];
}

async function seedBuyerFavoritesViaApi(user: AuthBundle, productIds: string[]) {
  const existingFavorites = await listFavoritesForUser(user.idToken, user.localId);
  const existingProductIds = new Set(
    existingFavorites
      .map(item => item?.productId)
      .filter((productId): productId is string => typeof productId === 'string' && productId.length > 0),
  );

  const targetProductIds = productIds.slice(0, FAVORITE_COUNT).filter(productId => !existingProductIds.has(productId));
  for (const productId of targetProductIds) {
    await callOk('toggle_favorite', { productId }, user.idToken);
  }
}

// ════════════════════════════════════════════════════════════════════
// ENHANCED ADDRESSES — CANADIAN POSTAL CODE GENERATION
// ════════════════════════════════════════════════════════════════════

async function seedEnhancedAddresses(admin: AuthBundle, userId: string, userType: string, addressCount: number = 4) {
  const addresses = [];

  for (let i = 0; i < addressCount; i++) {
    const seed = (userId.charCodeAt(0) * (i + 1)) + (i * 137);
    const address = generateCanadianAddress(seed);
    const label = CANADIAN_ADDRESS_LABELS[i % CANADIAN_ADDRESS_LABELS.length];
    
    addresses.push({
      id: `address_${userId}_${i}`,
      userId,
      label,
      address: {
        street: address.street,
        city: address.city,
        province: address.state,
        postalCode: address.postalCode,
        country: address.country,
      },
      isDefault: i === 0,
      createdAt: isoDaysAgo(30 - i * 5),
      updatedAt: new Date().toISOString(),
    });
  }

  await writeMany(addresses, async addr => {
    await writeDoc(`addresses/${addr.id}`, addr, admin.idToken, true);
  }, 10);
}

async function listAddressesForUser(token: string, userId: string): Promise<any[]> {
  const query = `
    query ListAddresses($collection: String!, $filters: JSON) {
      list(collection: $collection, filters: $filters, limit: 200)
    }
  `;
  const result = await obGraphQL(
    query,
    {
      collection: 'addresses',
      filters: { userId: { _eq: userRef(userId) } },
    },
    token,
  );
  if (!result.ok) return [];
  const raw = parseGraphQLValue(result.body?.data?.list);
  return Array.isArray(raw) ? raw.filter(item => item && typeof item === 'object') : [];
}

async function seedBuyerAddressesViaApi(user: AuthBundle, userType: string, addressCount = 4) {
  const existingAddresses = await listAddressesForUser(user.idToken, user.localId);
  let currentAddressCount = existingAddresses.length;
  if (currentAddressCount >= 10) {
    return;
  }
  const existingKeys = new Set(
    existingAddresses.map(address => [
      address?.label ?? '',
      address?.street ?? address?.address?.street ?? '',
      address?.city ?? address?.address?.city ?? '',
      address?.province ?? address?.address?.province ?? '',
      address?.postalCode ?? address?.address?.postalCode ?? '',
      address?.country ?? address?.address?.country ?? '',
    ].join('|')),
  );

  for (let i = 0; i < addressCount; i++) {
    const seed = (user.localId.charCodeAt(0) * (i + 1)) + (i * 137);
    const address = generateCanadianAddress(seed);
    const label = CANADIAN_ADDRESS_LABELS[i % CANADIAN_ADDRESS_LABELS.length];
    const dedupeKey = [
      label,
      address.street,
      address.city,
      address.state,
      address.postalCode,
      address.country,
    ].join('|');
    if (existingKeys.has(dedupeKey)) continue;
    if (currentAddressCount >= 10) break;

    try {
      await callOk(
        'add_buyer_address',
        {
          label,
          street: address.street,
          city: address.city,
          province: address.state,
          postalCode: address.postalCode,
          country: address.country,
          isDefault: i === 0 && existingAddresses.length === 0,
        },
        user.idToken,
      );
    } catch (error) {
      if (String(error).includes('Maximum number of addresses (10) reached')) {
        break;
      }
      throw error;
    }
    existingKeys.add(dedupeKey);
    currentAddressCount += 1;
  }
}

// ════════════════════════════════════════════════════════════════════
// REALISTIC CART SEEDING — WITH IMAGES + PROPER STRUCTURE
// ════════════════════════════════════════════════════════════════════

async function seedEnhancedCart(admin: AuthBundle, buyerId: string, productIds: string[], products: any[]) {
  const cartItems = [];
  const productMap = new Map(products.map(product => [product.id, product]));
  const guaranteedProductIds = [...productIds.filter(id => id !== 'e2e_product_oos').slice(0, 3), 'e2e_product_oos'];
  const buyerRecordRef = userRef(buyerId);

  for (let i = 0; i < guaranteedProductIds.length; i++) {
    const productId = guaranteedProductIds[i];
    const product = productMap.get(productId);
    const fallbackPriceCents = productId === 'e2e_product_oos' ? 2999 : 1999 + (i * 500);
    const fallbackName = productId === 'e2e_product_oos' ? 'Sold Out Seed Item' : `Seed Cart Item ${i + 1}`;

    const isUnavailable = productId === 'e2e_product_oos' || Number(product?.stockQuantity ?? 1) <= 0;
    cartItems.push({
      id: `cart_item_${buyerId}_${i}`,
      userId: buyerRecordRef,
      productId,
      quantity: isUnavailable ? 1 : 1 + (i % 3),
      priceCents: Number(product?.priceCents ?? fallbackPriceCents),
      imageUrl: sampleImageUrls(productId, 1, product?.categoryName)[0],
      productName: String(product?.title ?? fallbackName),
      addedAt: isoDaysAgo(i + 1),
      updatedAt: new Date().toISOString(),
      availabilityStatus: isUnavailable ? 'unavailable' : 'available',
      isUnavailable,
      unavailableReason: isUnavailable ? 'out_of_stock' : null,
    });
  }

  if (cartItems.length === 0) return;

  // Write cart items
  await writeMany(cartItems, async item => {
    await writeDoc(`users/${buyerId}/cart/${item.id}`, item, admin.idToken, true);
  }, 10);

  // Write cart summary
  const totalCents = cartItems.reduce((sum, item) => sum + item.priceCents * item.quantity, 0);
  await writeDoc(`users/${buyerId}`, {
    cart: cartItems.map(item => ({
      productId: item.productId,
      quantity: item.quantity,
      priceCents: item.priceCents,
      productName: item.productName,
      imageUrl: item.imageUrl,
      availabilityStatus: item.availabilityStatus,
      isUnavailable: item.isUnavailable,
    })),
  }, admin.idToken, true);
  await writeDoc(`user_carts/${buyerId}`, {
    userId: buyerRecordRef,
    itemCount: cartItems.length,
    totalCents,
    unavailableItemCount: cartItems.filter(item => item.isUnavailable).length,
    lastUpdated: new Date().toISOString(),
  }, admin.idToken, true);
}

// ════════════════════════════════════════════════════════════════════
// COMPREHENSIVE SUBSCRIPTIONS — WITH PAYMENT HISTORY
// ════════════════════════════════════════════════════════════════════

async function seedEnhancedSubscriptions(admin: AuthBundle, userIds: string[]) {
  const subscriptions: any[] = [];
  const invoices: any[] = [];

  for (let i = 0; i < Math.min(userIds.length, 12); i++) {
    const userId = userIds[i];
    const tier = i === 0 ? 'premium' : i === 1 ? 'premium' : ['basic', 'pro', 'enterprise'][Math.floor(Math.random() * 3)];
    const priceCents = { basic: 499, pro: 999, enterprise: 2499 }[tier];
    
    const startDate = isoDaysAgo(Math.random() * 180);
    const isCancelled = i === 1 ? true : i === 0 ? false : Math.random() < 0.15;
    
    subscriptions.push({
      id: `subscription_${userId}`,
      userId,
      tier,
      planType: tier === 'premium' ? 'premium_monthly' : tier,
      status: isCancelled ? 'inactive' : 'active',
      priceCents: tier === 'premium' ? 786 : priceCents,
      renewalDate: isCancelled ? isoDaysAgo(-Math.random() * 30) : isoDaysAgo(-Math.random() * 30),
      startDate,
      cancelledAt: isCancelled ? isoDaysAgo(Math.random() * 20) : null,
      maxUsesTotal: tier === 'basic' ? 5 : tier === 'pro' ? 20 : 9999,
      usesRemaining: Math.floor(Math.random() * 10),
      createdAt: startDate,
      updatedAt: new Date().toISOString(),
    });

    // Generate 3-6 past invoices
    const invoiceCount = 3 + Math.floor(Math.random() * 4);
    for (let j = invoiceCount; j > 0; j--) {
      invoices.push({
        id: `invoice_${userId}_${j}`,
        subscriptionId: `subscription_${userId}`,
        userId,
        amountCents: priceCents,
        status: 'paid',
        issuedAt: isoDaysAgo(j * 30),
        dueAt: isoDaysAgo(j * 30 - 5),
        paidAt: isoDaysAgo(j * 30 - Math.floor(Math.random() * 3)),
        createdAt: isoDaysAgo(j * 30 + 1),
      });
    }
  }

  await writeMany(subscriptions, async sub => {
    await writeDoc(`subscriptions/${sub.id}`, sub, admin.idToken, true);
  }, 10);

  await writeMany(invoices, async inv => {
    await writeDoc(`subscription_invoices/${inv.id}`, inv, admin.idToken, true);
  }, 20);
}

// ════════════════════════════════════════════════════════════════════
// ENHANCED CHAT THREADS — WITH MESSAGE COUNT + METADATA
// ════════════════════════════════════════════════════════════════════

async function seedEnhancedChats(admin: AuthBundle, buyerIds: string[], sellerIds: string[], productIds: string[]) {
  const chats: any[] = [];
  const messages: any[] = [];
  const threadCount = Math.min(buyerIds.length * 3, 50); // Up to 50 chat threads

  for (let i = 0; i < threadCount; i++) {
    const buyerId = buyerIds[i % buyerIds.length];
    const sellerId = sellerIds[i % sellerIds.length];
    const productId = productIds[i % productIds.length];

    const chatId = `chat_thread_${i}`;
    const msgCount = 5 + Math.floor(Math.random() * 12);

    chats.push({
      id: chatId,
      participantIds: [buyerId, sellerId],
      productId,
      subject: ['Question about stock', 'Shipping inquiry', 'Product details', 'Custom order'][i % 4],
      lastMessage: `Message ${msgCount}`,
      lastMessageAt: isoDaysAgo(Math.random() * 30),
      messageCount: msgCount,
      isResolved: Math.random() < 0.6,
      createdAt: isoDaysAgo(Math.random() * 60),
      updatedAt: new Date().toISOString(),
    });

    // Generate chat messages
    for (let j = 1; j <= msgCount; j++) {
      const sender = j % 2 === 0 ? buyerId : sellerId;
      messages.push({
        id: `message_${chatId}_${j}`,
        chatThreadId: chatId,
        senderId: sender,
        text: [
          'Hi, is this still available?',
          'Yes, I can ship it tomorrow.',
          'Can you confirm the color variant?',
          'It is the same one shown in the photos.',
          'Perfect, I will place the order today.',
          'I can also bundle shipping if you add another item.',
        ][(j - 1) % 6],
        imageUrl: Math.random() < 0.15 ? sampleImageUrls(`${chatId}-${j}`, 1)[0] : null,
        createdAt: isoDaysAgo(Math.random() * 30),
      });
    }
  }

  await writeMany(chats, async chat => {
    await writeDoc(`chat_threads/${chat.id}`, chat, admin.idToken, true);
  }, 10);

  await writeMany(messages, async msg => {
    await writeDoc(`chat_messages/${msg.id}`, msg, admin.idToken, true);
  }, 30);
}

// ════════════════════════════════════════════════════════════════════
// COMPREHENSIVE REVIEWS — WITH IMAGES + VARIATIONS
// ════════════════════════════════════════════════════════════════════

async function seedEnhancedReviews(admin: AuthBundle, buyerIds: string[], sellerIds: string[], productIds: string[]) {
  const reviews: any[] = [];
  const reviewCount = Math.min(productIds.length * 5, 500); // Up to 500 reviews

  const reviewTexts = [
    'Great product, exactly as described!',
    'Fast shipping and excellent quality',
    'Not as expected, but still decent',
    'Outstanding value for money',
    'Perfect for my needs',
    'Would recommend to anyone',
    'Broke after one week',
    'Amazing customer service',
    'Product arrived damaged',
    'Better than other brands',
  ];

  for (let i = 0; i < reviewCount; i++) {
    const buyerId = buyerIds[i % buyerIds.length];
    const productId = productIds[i % productIds.length];
    const rating = 1 + Math.floor(Math.random() * 5); // 1-5 stars

    reviews.push({
      id: `review_${i}`,
      productId,
      buyerId,
      rating,
      title: `Review ${i + 1}`,
      text: reviewTexts[i % reviewTexts.length],
      sellerId: sellerIds[i % sellerIds.length],
      imageUrls: Math.random() < 0.3 ? sampleImageUrls(`review-${i}`, 1) : [],
      helpful: Math.floor(Math.random() * 50),
      unhelpful: Math.floor(Math.random() * 10),
      verified: Math.random() < 0.9,
      flagged: Math.random() < 0.05,
      createdAt: isoDaysAgo(Math.random() * 180),
      updatedAt: new Date().toISOString(),
    });
  }

  await writeMany(reviews, async review => {
    await writeDoc(`product_reviews/${review.id}`, review, admin.idToken, true);
  }, 50);
}

// ════════════════════════════════════════════════════════════════════
// RETURN REQUESTS — ALL STATES + PROPER TIMESTAMPS
// ════════════════════════════════════════════════════════════════════

async function seedEnhancedReturnRequests(admin: AuthBundle, buyerIds: string[], productIds: string[]) {
  const returns: any[] = [];
  const states = ['pending', 'approved', 'rejected', 'shipped_back', 'received'];

  for (let i = 0; i < 30; i++) {
    const buyerId = buyerIds[i % buyerIds.length];
    const productId = productIds[i % productIds.length];
    const state = states[i % states.length];
    const reason = ['Defective', 'Wrong size', 'Changed mind', 'Damaged', 'Missing parts'][i % 5];

    const createdDate = isoDaysAgo(Math.random() * 60);
    const approvedDate = state !== 'pending' ? isoDaysAgo(Math.random() * 45) : null;
    const shippedDate = (state === 'shipped_back' || state === 'received') ? isoDaysAgo(Math.random() * 20) : null;
    const receivedDate = state === 'received' ? isoDaysAgo(Math.random() * 5) : null;

    returns.push({
      id: `return_${i}`,
      buyerId,
      productId,
      reason,
      status: state,
      requestedAt: createdDate,
      approvedAt: approvedDate,
      shippedAt: shippedDate,
      receivedAt: receivedDate,
      refundedAt: state === 'received' ? new Date().toISOString() : null,
      notes: `${reason} item`,
      createdAt: createdDate,
      updatedAt: new Date().toISOString(),
    });
  }

  await writeMany(returns, async ret => {
    await writeDoc(`return_requests/${ret.id}`, ret, admin.idToken, true);
  }, 10);
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

async function upsertUsers(admin: AuthBundle, seller: AuthBundle, buyer: AuthBundle) {
  const legacyBuyer = await resolveSeedUser(LEGACY_TEST_EMAILS[0], TEST_ACCOUNTS.BUYER_PASS, ['buyer']);
  const legacyAdmin = await resolveSeedUser(LEGACY_TEST_EMAILS[1], TEST_ACCOUNTS.ADMIN_PASS, ['buyer', 'admin']);
  const legacySeller = await resolveSeedUser(LEGACY_TEST_EMAILS[2], TEST_ACCOUNTS.SELLER_PASS, ['buyer', 'seller']);
  const coreUsers: SeedUser[] = [
    {
      id: admin.localId,
      email: admin.email,
      displayName: 'E2E Admin',
      roles: ['buyer', 'seller', 'admin'],
      isPremium: true,
      stripeOnboarded: true,
    },
    {
      id: seller.localId,
      email: seller.email,
      displayName: 'E2E Seller',
      roles: ['buyer', 'seller'],
      isPremium: true,
      stripeOnboarded: true,
    },
    {
      id: buyer.localId,
      email: buyer.email,
      displayName: 'E2E Buyer',
      roles: ['buyer'],
      isPremium: true,
    },
    {
      id: legacyBuyer.id,
      email: legacyBuyer.email,
      displayName: 'Legacy Buyer Seed',
      roles: legacyBuyer.roles,
      isPremium: false,
    },
    {
      id: legacyAdmin.id,
      email: legacyAdmin.email,
      displayName: 'Legacy Admin Seed',
      roles: legacyAdmin.roles,
      isPremium: true,
      stripeOnboarded: true,
    },
    {
      id: legacySeller.id,
      email: legacySeller.email,
      displayName: 'Legacy Seller Seed',
      roles: legacySeller.roles,
      isPremium: false,
      stripeOnboarded: true,
    },
  ];

  const syntheticSpecs = [
    ...Array.from({ length: 8 }, (_, i) => ({
      seedKey: `seed_seller_${String(i + 1).padStart(2, '0')}`,
      email: `seed-seller-${i + 1}@test.origna.ca`,
      displayName: `Seed Seller ${i + 1}`,
      roles: ['buyer', 'seller'],
      isPremium: i % 2 === 0,
      stripeOnboarded: i % 3 !== 0,
    })),
    ...Array.from({ length: 16 }, (_, i) => ({
      seedKey: `seed_buyer_${String(i + 1).padStart(2, '0')}`,
      email: `seed-buyer-${i + 1}@test.origna.ca`,
      displayName: `Seed Buyer ${i + 1}`,
      roles: ['buyer'],
      isPremium: i % 4 === 0,
      suspended: i === 15,
    })),
  ] as const;
  const syntheticUsers: SeedUser[] = await Promise.all(
    syntheticSpecs.map(async spec => {
      const resolved = await resolveSeedUser(spec.email, TEST_ACCOUNTS.BUYER_PASS, [...spec.roles]);
      return {
        seedKey: spec.seedKey,
        id: resolved.id,
        email: resolved.email,
        displayName: spec.displayName,
        roles: [...spec.roles],
        isPremium: spec.isPremium,
        suspended: 'suspended' in spec ? spec.suspended : undefined,
        stripeOnboarded: 'stripeOnboarded' in spec ? spec.stripeOnboarded : undefined,
      };
    }),
  );

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
      profileImageUrl: sampleImageUrls(`profile-${user.id}`, 1, 'fashion')[0],
      createdAt: isoDaysAgo(45),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }, 20);

  const legacyUserIds = [legacyBuyer.id, legacyAdmin.id, legacySeller.id];
  const resolvedIdsByKey = Object.fromEntries(
    syntheticUsers
      .filter((user): user is SeedUser & { seedKey: string } => typeof user.seedKey === 'string' && user.seedKey.length > 0)
      .map(user => [user.seedKey, user.id]),
  );
  return {
    adminId: coreUsers[0].id,
    sellerId: coreUsers[1].id,
    buyerId: coreUsers[2].id,
    sellerPool: [...new Set([coreUsers[0].id, coreUsers[1].id, legacySeller.id, ...syntheticUsers.filter(u => u.roles.includes('seller')).map(u => u.id)])],
    buyerPool: [...new Set([coreUsers[2].id, legacyBuyer.id, legacyAdmin.id, legacySeller.id, ...syntheticUsers.filter(u => u.roles.length === 1).map(u => u.id)])],
    legacyUserIds,
    resolvedIdsByKey,
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
      isTrending: true,
      isLocalDeliveryOnly: false,
      reviewCount: 8,
      rating: 4.6,
      specs: {
        specs: [
          { key: 'brand', value: 'Samsung', valueType: 'text', group: 'General' },
          { key: 'model', value: 'Odyssey G9', valueType: 'text', group: 'General' },
          { key: 'screenSize', value: '49', valueType: 'number', unit: 'inches', group: 'Display' },
          { key: 'resolution', value: '5120 x 1440', valueType: 'text', group: 'Display' },
          { key: 'connectivity', value: 'HDMI 2.1, DisplayPort 1.4, USB-C', valueType: 'text', group: 'Connectivity' },
          { key: 'warranty', value: '3 years', valueType: 'text', group: 'General' },
          { key: 'certificationMark', value: 'CSA, cUL', valueType: 'text', group: 'General' },
        ],
        brand: 'Samsung',
        color: 'White',
        material: null,
      },
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
      isTrending: false,
      isLocalDeliveryOnly: false,
      reviewCount: 12,
      rating: 4.2,
      specs: {
        specs: [
          { key: 'platform', value: 'Windows, macOS, Linux', valueType: 'text', group: 'Technical' },
          { key: 'fileFormat', value: 'ZIP, PSD, AI', valueType: 'text', group: 'Technical' },
          { key: 'fileSize', value: '2.4 GB', valueType: 'text', group: 'Technical' },
          { key: 'licenseType', value: 'Single user, lifetime', valueType: 'text', group: 'License' },
          { key: 'version', value: '3.0', valueType: 'text', group: 'Technical' },
        ],
        brand: null,
        color: null,
        material: null,
      },
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
      isTrending: false,
      isLocalDeliveryOnly: false,
      reviewCount: 5,
      rating: 3.8,
    },
    {
      id: 'e2e_product_oos',
      sellerId: ids.sellerId,
      categoryId: 1,
      categoryName: 'Electronics',
      title: 'Sold Out Collector Camera',
      description: 'Rare vintage camera for collectors',
      priceCents: 49999,
      lifecycleStatus: 'active',
      stockQuantity: 0,
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
      hasVariants: false,
      subcategory: 'Cameras',
      shipFromCountry: 'Canada',
      isTrending: false,
      isLocalDeliveryOnly: false,
      reviewCount: 3,
      rating: 4.9,
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
      isTrending: true,
      isLocalDeliveryOnly: true,
      reviewCount: 15,
      rating: 4.5,
    },
    // === FASHION PRODUCT WITH TEXTILE COMPLIANCE ===
    {
      id: 'e2e_product_fashion',
      sellerId: ids.sellerId,
      categoryId: 5,
      categoryName: 'Fashion',
      title: 'Premium Merino Wool Sweater',
      description: 'Luxurious merino wool crewneck sweater. Made in Canada.',
      priceCents: 12999,
      lifecycleStatus: 'active',
      stockQuantity: 45,
      isDigital: false,
      isPerishable: false,
      freeShipping: true,
      hasVariants: true,
      subcategory: 'Tops',
      shipFromCountry: 'Canada',
      isTrending: false,
      isLocalDeliveryOnly: false,
      reviewCount: 9,
      rating: 4.6,
      specs: {
        specs: [
          { key: 'fibreContent', value: '80% Merino Wool, 20% Nylon', valueType: 'text', group: 'Fabric' },
          { key: 'material', value: 'Merino Wool Blend', valueType: 'text', group: 'Fabric' },
          { key: 'size', value: 'S, M, L, XL, XXL', valueType: 'text', group: 'Sizing' },
          { key: 'fit', value: 'Regular', valueType: 'text', group: 'Sizing' },
          { key: 'color', value: 'Navy', valueType: 'text', group: 'General' },
          { key: 'careInstructions', value: 'Hand wash cold. Lay flat to dry.', valueType: 'text', group: 'Care' },
          { key: 'season', value: 'Fall/Winter', valueType: 'text', group: 'General' },
          { key: 'gender', value: 'Unisex', valueType: 'text', group: 'Sizing' },
          { key: 'madeIn', value: 'Canada', valueType: 'text', group: 'General' },
        ],
        brand: 'Origna Essentials',
        color: 'Navy',
        material: 'Merino Wool Blend',
      },
    },
    // === COMPUTER PRODUCT WITH FULL SPECS ===
    {
      id: 'e2e_product_computer',
      sellerId: ids.sellerId,
      categoryId: 2,
      categoryName: 'Computers',
      title: 'Pro Workstation Laptop 16"',
      description: 'High-performance laptop for creators and developers. M4 Pro chip, 32GB RAM, 1TB SSD.',
      priceCents: 49999,
      lifecycleStatus: 'active',
      stockQuantity: 15,
      isDigital: false,
      isPerishable: false,
      freeShipping: true,
      hasVariants: false,
      subcategory: 'Laptops',
      shipFromCountry: 'Canada',
      isTrending: true,
      isLocalDeliveryOnly: false,
      reviewCount: 27,
      rating: 4.8,
      specs: {
        specs: [
          { key: 'processor', value: 'Apple M4 Pro', valueType: 'text', group: 'Performance' },
          { key: 'ram', value: '32', valueType: 'number', unit: 'GB', group: 'Performance' },
          { key: 'storage', value: '1000', valueType: 'number', unit: 'GB', group: 'Performance' },
          { key: 'storageType', value: 'NVMe SSD', valueType: 'text', group: 'Performance' },
          { key: 'gpu', value: 'Apple M4 Pro (20-core)', valueType: 'text', group: 'Performance' },
          { key: 'os', value: 'macOS Sequoia', valueType: 'text', group: 'Performance' },
          { key: 'screenSize', value: '16.2', valueType: 'number', unit: 'inches', group: 'Display' },
          { key: 'resolution', value: '3456 x 2234', valueType: 'text', group: 'Display' },
          { key: 'batteryLife', value: '22', valueType: 'number', unit: 'hours', group: 'Power' },
          { key: 'ports', value: '3x Thunderbolt 5, HDMI, SD, MagSafe', valueType: 'text', group: 'Connectivity' },
        ],
        brand: 'Apple',
        color: 'Space Black',
        material: 'Aluminum',
      },
    },
    // === FOOD PRODUCTS WITH NUTRITION DATA ===
    {
      id: 'e2e_food_strawberries',
      sellerId: ids.sellerId,
      categoryId: 19,
      categoryName: 'Groceries',
      title: 'Fresh Organic Strawberries 454g',
      description: 'Premium organic strawberries from Ontario farms. Hand-picked at peak ripeness.',
      priceCents: 1099,
      lifecycleStatus: 'active',
      stockQuantity: 50,
      isDigital: false,
      isPerishable: true,
      freeShipping: false,
      hasVariants: false,
      subcategory: 'Produce',
      shipFromCountry: 'Canada',
      isTrending: false,
      isLocalDeliveryOnly: true,
      reviewCount: 22,
      rating: 4.7,
      nutritionFacts: {
        servingSizeAmount: 147,
        servingSizeUnit: 'g',
        servingsPerContainer: 3,
        caloriesKcal: 47,
        totalFatMg: 400,
        saturatedFatMg: 0,
        transFatMg: 0,
        cholesterolMg: 0,
        sodiumMg: 1,
        totalCarbohydrateMg: 11000,
        fibreMg: 3000,
        sugarsMg: 7000,
        proteinMg: 1000,
        vitaminAMcg: 2,
        vitaminCMg: 85,
        calciumMg: 23,
        ironMg: 1,
        potassiumMg: 220,
      },
      foodMetadata: {
        ingredientsEn: 'Organic strawberries',
        ingredientsFr: 'Fraises biologiques',
        allergens: [],
        mayContainAllergens: [],
        storageInstructionsEn: 'Refrigerate at 4°C or below. Wash before eating.',
        storageInstructionsFr: 'Réfrigérer à 4°C ou moins. Laver avant de manger.',
        bestBeforeDays: 5,
        dietaryBadges: ['organic', 'vegan', 'non_gmo', 'gluten_free'],
        fopHighSodium: false,
        fopHighSugars: false,
        fopHighSaturatedFat: false,
      },
    },
    {
      id: 'e2e_food_maple_syrup',
      sellerId: ids.sellerId,
      categoryId: 19,
      categoryName: 'Groceries',
      title: 'Pure Maple Syrup 500mL — Grade A Amber',
      description: 'Authentic Quebec maple syrup. Grade A, Amber colour, Rich taste. Tapped from century-old sugar maples.',
      priceCents: 1499,
      lifecycleStatus: 'active',
      stockQuantity: 200,
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
      hasVariants: false,
      subcategory: 'Pantry',
      shipFromCountry: 'Canada',
      isTrending: true,
      isLocalDeliveryOnly: false,
      reviewCount: 38,
      rating: 4.9,
      nutritionFacts: {
        servingSizeAmount: 60,
        servingSizeUnit: 'mL',
        servingsPerContainer: 8,
        caloriesKcal: 210,
        totalFatMg: 0,
        saturatedFatMg: 0,
        transFatMg: 0,
        cholesterolMg: 0,
        sodiumMg: 7,
        totalCarbohydrateMg: 54000,
        fibreMg: 0,
        sugarsMg: 54000,
        proteinMg: 0,
        vitaminAMcg: 0,
        vitaminCMg: 0,
        calciumMg: 72,
        ironMg: 1,
        potassiumMg: 204,
      },
      foodMetadata: {
        ingredientsEn: 'Pure maple syrup',
        ingredientsFr: 'Sirop d\'érable pur',
        allergens: [],
        mayContainAllergens: [],
        storageInstructionsEn: 'Refrigerate after opening. Best consumed within 6 months.',
        storageInstructionsFr: 'Réfrigérer après ouverture. À consommer dans les 6 mois.',
        bestBeforeDays: 730,
        dietaryBadges: ['organic', 'vegan', 'gluten_free', 'non_gmo'],
        fopHighSodium: false,
        fopHighSugars: true,
        fopHighSaturatedFat: false,
      },
    },
    {
      id: 'e2e_food_almond_butter',
      sellerId: ids.sellerId,
      categoryId: 19,
      categoryName: 'Groceries',
      title: 'Natural Almond Butter 500g — Smooth',
      description: 'Stone-ground almond butter made from dry-roasted almonds. No added oils, sugars, or salt.',
      priceCents: 1299,
      lifecycleStatus: 'active',
      stockQuantity: 120,
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
      hasVariants: false,
      subcategory: 'Specialty',
      shipFromCountry: 'Canada',
      isTrending: false,
      isLocalDeliveryOnly: false,
      reviewCount: 14,
      rating: 4.4,
      nutritionFacts: {
        servingSizeAmount: 32,
        servingSizeUnit: 'g',
        servingsPerContainer: 15,
        caloriesKcal: 190,
        totalFatMg: 16000,
        saturatedFatMg: 3500,
        transFatMg: 0,
        cholesterolMg: 0,
        sodiumMg: 0,
        totalCarbohydrateMg: 7000,
        fibreMg: 3000,
        sugarsMg: 3000,
        proteinMg: 7000,
        vitaminAMcg: 0,
        vitaminCMg: 0,
        calciumMg: 80,
        ironMg: 1,
        potassiumMg: 200,
        vitaminDMcg: 0,
      },
      foodMetadata: {
        ingredientsEn: 'Dry-roasted almonds',
        ingredientsFr: 'Amandes rôties à sec',
        allergens: ['tree_nuts'],
        mayContainAllergens: ['peanuts'],
        storageInstructionsEn: 'Store in a cool, dry place. Refrigerate after opening. Stir before use.',
        storageInstructionsFr: 'Conserver dans un endroit frais et sec. Réfrigérer après ouverture. Remuer avant utilisation.',
        bestBeforeDays: 365,
        dietaryBadges: ['vegan', 'gluten_free'],
        fopHighSodium: false,
        fopHighSugars: false,
        fopHighSaturatedFat: true,
      },
    },
  ];

  const sellerDashboardProducts = PRIMARY_SELLER_DASHBOARD_PRODUCTS.map((product, index) => ({
    ...product,
    sellerId: ids.sellerId,
    description: `${product.title} seeded for seller dashboard coverage.`,
    isDigital: product.categoryId === 21,
    isPerishable: false,
    freeShipping: index % 2 === 0,
    hasVariants: index % 3 === 0,
    shipFromCountry: 'Canada',
    isTrending: product.lifecycleStatus === 'active' && index % 2 === 0,
    isLocalDeliveryOnly: false,
    reviewCount: 3 + (index % 6),
    rating: Number((3.8 + (index % 2) * 0.6).toFixed(1)),
  }));

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
    const priceCents = 1099 + (index % 250) * 196;
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

  const allProducts = [...stableProducts, ...sellerDashboardProducts, ...generatedProducts];

  await writeMany(allProducts, async product => {
    const variants = product.hasVariants ? productVariantSeed(product.id, product.id.startsWith('e2e_') ? 2499 : product.priceCents) : {
      hasVariants: false,
      variantOptions: [],
      variants: [],
    };
    const imageUrls = sampleImageUrls(product.id, product.hasVariants ? 3 : 2, product.categoryName);
    const productVideo = sampleVideo(product.id);
    await writeDoc(`products/${product.id}`, {
      productId: product.id,
      sellerId: userRef(product.sellerId),
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
      sellerDashboardStatus: product.lifecycleStatus === 'active' ? 'active' : product.lifecycleStatus === 'draft' ? 'draft' : 'inactive',
      sellerAddress: sellerAddress(product.categoryName, product.shipFromCountry),
      shipFromCountry: product.shipFromCountry,
      shipFromProvince: product.shipFromCountry === 'Canada' ? 'ON' : 'SH',
      shipFromCity: product.shipFromCountry === 'Canada' ? 'Toronto' : 'Shanghai',
      imageUrls,
      videoUrl: productVideo.url,
      videoDurationSeconds: productVideo.durationSeconds,
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
      // Food nutrition data (only for products that have it)
      ...((product as any).nutritionFacts ? { nutritionFacts: (product as any).nutritionFacts } : {}),
      ...((product as any).foodMetadata ? { foodMetadata: (product as any).foodMetadata } : {}),
      ...((product as any).specs ? { specs: (product as any).specs } : {}),
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
    const createdAt = isoDaysAgo(index % 14, index * 11);
    await writeDoc(`favorites/fav_${buyerId}_${productId}`, {
      userId: buyerId,
      productId,
      createdAt,
      dateFavorited: createdAt,
    }, admin.idToken, true);
  }, 20);
}

async function seedAddresses(admin: AuthBundle, userId: string, prefix: string) {
  const cities = ['Toronto', 'Mississauga', 'Ottawa', 'Montreal', 'Vancouver', 'Calgary', 'Halifax', 'Quebec City'];
  await writeMany(cities.slice(0, ADDRESS_COUNT), async (city, index) => {
    await writeDoc(`addresses/${prefix}_address_${index + 1}`, {
      userId,
      label: index === 0 ? 'Home' : index === 1 ? 'Work' : `Address ${index + 1}`,
      address: {
        street: `${100 + index} Demo ${city} St`,
        apartment: index % 2 === 0 ? `${index + 1}A` : '',
        city,
        province: ['ON', 'ON', 'ON', 'QC', 'BC', 'AB', 'NS', 'QC'][index],
        postalCode: ['M5V 3A8', 'L5B 2C9', 'K1P 1J1', 'H2Y 1C6', 'V6B 1A1', 'T2P 1J9', 'B3J 2K9', 'G1R 4P5'][index],
        country: 'Canada',
      },
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

async function seedOrders(admin: AuthBundle, buyerIds: string[], sellerId: string, secondarySellerId: string, productIds: string[]) {
  const orders = Array.from({ length: 45 }, (_, index) => {
    const status = ORDER_STATUSES[index % ORDER_STATUSES.length];
    const sellerIds = index % 4 === 0 ? [sellerId, secondarySellerId] : [sellerId];
    const buyerId = buyerIds[Math.floor(index / ORDER_STATUSES.length) % buyerIds.length];
    const sellerRecordRefs = sellerIds.map(userRef);
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
        sellerId: userRef(sid),
        status,
        isDigital: productId === 'e2e_product_test_seller',
        isPerishable: productId === 'e2e_product_perishable',
        freeShipping: itemIndex === 0,
      };
    });

    const subtotalCents = lineItems.reduce((sum, item) => sum + Math.round(item.price * 100) * item.quantity, 0);
    return {
      id: `seed_order_${String(index + 1).padStart(3, '0')}`,
      orderId: `seed_order_${String(index + 1).padStart(3, '0')}`,
      orderStatus: status,
      status,
      paymentStatus: status === 'cancelled' ? 'refunded' : 'paid',
      buyerId,
      userId: buyerId,
      sellerId: sellerRecordRefs[0],
      sellerIds: sellerRecordRefs,
      items: lineItems,
      subtotalCents,
      shippingCostCents: status === 'cancelled' ? 0 : 899 + (index % 3) * 200,
      taxAmountCents: Math.round(subtotalCents * 0.13),
      totalAmountCents: subtotalCents + Math.round(subtotalCents * 0.13) + (status === 'cancelled' ? 0 : 899 + (index % 3) * 200),
      createdAt: isoDaysAgo(index + 1),
      confirmedAt: ['confirmed', 'shipped', 'delivered'].includes(status) ? isoDaysAgo(Math.max(1, index)) : null,
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
  const notificationsPerUser = Math.max(6, Math.ceil(NOTIFICATION_COUNT / Math.max(1, userIds.length)));
  const items = userIds.flatMap((userId, userIndex) =>
    Array.from({ length: notificationsPerUser }, (_, index) => ({
      id: `notif_${userId}_${index + 1}`,
      userId,
      type: NOTIFICATION_TYPES[(userIndex + index) % NOTIFICATION_TYPES.length],
      title: `Seed notification ${index + 1}`,
      body: 'This seeded notification keeps the notifications center populated for demos.',
      isRead: index % 3 === 0,
      createdAt: isoDaysAgo(index % 10, index * 19),
      route: index % 2 === 0 ? '/orders' : '/notifications',
      orderId: `seed_order_${String(((userIndex * notificationsPerUser + index) % 45) + 1).padStart(3, '0')}`,
      productId: index % 2 === 0 ? `mega_seed_product_${String((index % 12) + 1).padStart(4, '0')}` : 'e2e_product_test_seller',
      chatThreadId: index % 4 === 0 ? `chat_thread_${(userIndex + index) % 12}` : null,
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
    const approvalStatus = i % 3 === 0 ? 'approved' : i % 3 === 1 ? 'pending' : 'rejected';
    
    await writeDoc(`seller_profiles/${sellerId}`, {
      sellerId,
      businessName: `Seed Business ${i + 1}`,
      description: `Seeded seller profile for demonstration and testing purposes.`,
      status: approvalStatus,
      approvalStatus,
      verificationStatus: approvalStatus,
      chargesEnabled: onboarded,
      payoutsEnabled: onboarded,
      detailsSubmitted: onboarded,
      onboardingCompleted: onboarded && i % 2 === 0,
      pendingRequirements: approvalStatus === 'pending' ? ['business_type', 'representative'] : [],
      rejectionReason: approvalStatus === 'rejected' ? 'Seeded KYC rejection example' : null,
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

async function seedDisputes(admin: AuthBundle, buyerId: string, sellerId: string, productIds: string[]) {
  const disputeStatuses = ['open', 'under_review', 'resolved_buyer', 'resolved_seller', 'closed', 'escalated'] as const;
  const disputeReasons = ['not_received', 'not_as_described', 'counterfeit', 'unauthorized_charge', 'duplicate_charge', 'defective'];
  const disputes = Array.from({ length: DISPUTE_COUNT }, (_, index) => {
    const status = disputeStatuses[index % disputeStatuses.length];
    const reason = disputeReasons[index % disputeReasons.length];
    const orderId = `seed_order_${String((index % 30) + 1).padStart(3, '0')}`;
    return {
      id: `dispute_${String(index + 1).padStart(3, '0')}`,
      orderId,
      buyerId,
      sellerId,
      productId: productIds[index % productIds.length],
      reason,
      description: `Seed dispute ${index + 1}: ${reason.replace(/_/g, ' ')}. Evidence provided for testing.`,
      status,
      amountCents: 1999 + (index * 800),
      evidencePhotos: index % 3 === 0 ? sampleImageUrls(`dispute-${index + 1}`, 2) : [],
      buyerMessage: `I dispute this order because: ${reason.replace(/_/g, ' ')}.`,
      sellerResponse: status !== 'open' ? 'We take this seriously and have reviewed the evidence.' : null,
      adminNotes: ['resolved_buyer', 'resolved_seller', 'closed'].includes(status) ? 'Reviewed and resolved per policy.' : null,
      stripeDisputeId: index % 2 === 0 ? `dp_test_${index + 1}` : null,
      openedAt: isoDaysAgo(index % 15),
      resolvedAt: ['resolved_buyer', 'resolved_seller', 'closed'].includes(status) ? isoDaysAgo(index % 5) : null,
    };
  });

  await writeMany(disputes, async dispute => {
    await writeDoc(`disputes/${dispute.id}`, dispute, admin.idToken, true);
  }, 10);
}

async function seedCoupons(admin: AuthBundle, sellerIds: string[]) {
  const couponTypes = ['percentage', 'fixed_amount', 'free_shipping'] as const;
  const coupons = [
    {
      id: 'coupon_active_platform',
      code: 'ACTIVE10',
      type: 'percentage',
      value: 10,
      minOrderCents: 2500,
      maxDiscountCents: 5000,
      sellerId: null,
      isGlobal: true,
      isActive: true,
      maxUsesTotal: 500,
      maxUsesPerUser: 2,
      currentUses: 41,
      startsAt: isoDaysAgo(7),
      expiresAt: isoDaysAgo(-21),
      description: 'Canonical active platform coupon.',
      createdAt: isoDaysAgo(14),
      updatedAt: new Date().toISOString(),
    },
    {
      id: 'coupon_expired_platform',
      code: 'EXPIRED15',
      type: 'fixed_amount',
      value: 1500,
      minOrderCents: 5000,
      maxDiscountCents: null,
      sellerId: null,
      isGlobal: true,
      isActive: false,
      maxUsesTotal: 100,
      maxUsesPerUser: 1,
      currentUses: 22,
      startsAt: isoDaysAgo(60),
      expiresAt: isoDaysAgo(2),
      description: 'Canonical expired platform coupon.',
      createdAt: isoDaysAgo(60),
      updatedAt: new Date().toISOString(),
    },
    {
      id: 'coupon_usage_limited_seller',
      code: 'LIMITSHIP',
      type: 'free_shipping',
      value: 0,
      minOrderCents: 3500,
      maxDiscountCents: null,
      sellerId: sellerIds[0] ?? null,
      isGlobal: false,
      isActive: false,
      maxUsesTotal: 5,
      maxUsesPerUser: 1,
      currentUses: 5,
      startsAt: isoDaysAgo(14),
      expiresAt: isoDaysAgo(-14),
      description: 'Canonical seller coupon that exhausted its usage limit.',
      createdAt: isoDaysAgo(20),
      updatedAt: new Date().toISOString(),
    },
    ...Array.from({ length: COUPON_COUNT }, (_, index) => {
    const type = couponTypes[index % couponTypes.length];
    const isExpired = index % 6 === 0;
    const isMaxedOut = index % 7 === 0;
    const sellerId = sellerIds[index % sellerIds.length];
    return {
      id: `coupon_seed_${String(index + 1).padStart(3, '0')}`,
      code: `SEED${String(index + 1).padStart(3, '0')}${type === 'percentage' ? 'PCT' : type === 'fixed_amount' ? 'FIX' : 'SHIP'}`,
      type,
      value: type === 'percentage' ? 10 + (index % 40) : type === 'fixed_amount' ? 500 + (index * 100) : 0,
      minOrderCents: index % 2 === 0 ? 2000 : 0,
      maxDiscountCents: type === 'percentage' ? 5000 : null,
      sellerId: index % 3 === 0 ? null : sellerId,
      isGlobal: index % 3 === 0,
      isActive: !isExpired && !isMaxedOut,
      maxUsesTotal: isMaxedOut ? 5 : 100 + (index * 50),
      maxUsesPerUser: 2 + (index % 3),
      currentUses: isMaxedOut ? 5 : index * 3,
      startsAt: isoDaysAgo(30),
      expiresAt: isExpired ? isoDaysAgo(1) : isoDaysAgo(-30),
      description: `Seed coupon ${index + 1} — ${type.replace(/_/g, ' ')} discount for demos.`,
      createdAt: isoDaysAgo(30),
      updatedAt: new Date().toISOString(),
    };
    }),
  ];

  await writeMany(coupons, async coupon => {
    await writeDoc(`coupons/${coupon.id}`, coupon, admin.idToken, true);
  }, 12);
}

async function seedPromotions(admin: AuthBundle, sellerIds: string[], productIds: string[]) {
  const promoTypes = ['banner', 'featured', 'flash_sale', 'bundle'] as const;
  const promotions = Array.from({ length: PROMOTION_COUNT }, (_, index) => {
    const type = promoTypes[index % promoTypes.length];
    const isActive = index % 3 !== 0;
    return {
      id: `promo_seed_${String(index + 1).padStart(3, '0')}`,
      type,
      title: `Seed Promotion ${index + 1}: ${type.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())}`,
      description: `Seeded ${type.replace(/_/g, ' ')} promotion for testing promotion UI.`,
      sellerId: index % 2 === 0 ? null : sellerIds[index % sellerIds.length],
      productIds: productIds.slice(index * 3, index * 3 + 5),
      discountPercentage: type === 'flash_sale' ? 15 + (index % 35) : 0,
      bannerImageUrl: type === 'banner' ? sampleImageUrls(`promo-banner-${index + 1}`, 1)[0] : null,
      isActive,
      displayOrder: index + 1,
      startsAt: isActive ? isoDaysAgo(5) : isoDaysAgo(-5),
      endsAt: isActive ? isoDaysAgo(-10) : isoDaysAgo(-2),
      clickCount: 50 + (index * 23),
      impressions: 500 + (index * 100),
      createdAt: isoDaysAgo(10),
      updatedAt: new Date().toISOString(),
    };
  });

  await writeMany(promotions, async promo => {
    await writeDoc(`promotions/${promo.id}`, promo, admin.idToken, true);
  }, 8);
}

async function seedDownloadSessions(admin: AuthBundle, buyerId: string, productIds: string[]) {
  const digitalProducts = productIds.filter(id => id === 'e2e_product_test_seller' || id.includes('mega_seed'));
  const sessions = Array.from({ length: DOWNLOAD_SESSION_COUNT }, (_, index) => {
    const productId = digitalProducts[index % Math.max(1, digitalProducts.length)] || productIds[0];
    const isExpired = index % 4 === 0;
    return {
      id: `dl_session_${String(index + 1).padStart(3, '0')}`,
      userId: buyerId,
      productId,
      orderId: `seed_order_${String((index % 30) + 1).padStart(3, '0')}`,
      downloadUrl: `https://example.com/download/${productId}/${index + 1}`,
      maxDownloads: 5,
      downloadCount: isExpired ? 5 : index % 3,
      isActive: !isExpired,
      expiresAt: isExpired ? isoDaysAgo(1) : isoDaysAgo(-30),
      createdAt: isoDaysAgo(index + 1),
    };
  });

  await writeMany(sessions, async session => {
    await writeDoc(`download_sessions/${session.id}`, session, admin.idToken, true);
  }, 6);
}

async function seedMfaSettings(admin: AuthBundle, userIds: string[]) {
  const mfaUsers = userIds.slice(0, 5);
  for (let i = 0; i < mfaUsers.length; i++) {
    const userId = mfaUsers[i];
    await writeDoc(`mfa_settings/${userId}`, {
      userId,
      isEnabled: true,
      method: i % 2 === 0 ? 'totp' : 'sms',
      phoneNumber: i % 2 === 1 ? `+1416555010${i}` : null,
      totpSecret: i % 2 === 0 ? `JBSWY3DPEHPK3PXP${i}` : null,
      recoveryCodes: Array.from({ length: 8 }, (_, j) => `RECOVERY-${userId.slice(-4)}-${String(j + 1).padStart(4, '0')}`),
      lastUsedAt: isoDaysAgo(i % 7),
      createdAt: isoDaysAgo(30 + i),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}

async function seedReviewAnswers(admin: AuthBundle, sellerId: string) {
  const answerStatuses = ['published', 'pending_moderation', 'rejected'];
  const answers = Array.from({ length: 20 }, (_, index) => ({
    id: `review_answer_${String(index + 1).padStart(3, '0')}`,
    reviewId: `review_${String((index % 120) + 1).padStart(3, '0')}`,
    sellerId,
    answer: `Thank you for your feedback. We ${index % 2 === 0 ? 'appreciate' : 'value'} your review and have addressed your concerns.`,
    status: answerStatuses[index % answerStatuses.length],
    createdAt: isoDaysAgo(index % 10),
    updatedAt: new Date().toISOString(),
  }));

  await writeMany(answers, async answer => {
    await writeDoc(`review_answers/${answer.id}`, answer, admin.idToken, true);
  }, 12);
}

async function seedMoreStockNotifications(admin: AuthBundle, buyerIds: string[], productIds: string[]) {
  const oosProducts = productIds.filter((_, i) => i % 23 === 0);
  const items = Array.from({ length: STOCK_NOTIFICATION_COUNT }, (_, index) => ({
    id: `stock_notif_${String(index + 1).padStart(3, '0')}`,
    userId: buyerIds[index % buyerIds.length],
    productId: oosProducts[index % Math.max(1, oosProducts.length)] || productIds[0],
    createdAt: isoDaysAgo(index % 10),
    isActive: index % 3 !== 0,
  }));

  await writeMany(items, async item => {
    await writeDoc(`stock_notifications/${item.id}`, item, admin.idToken, true);
  }, 10);
}

async function seedUserPreferences(admin: AuthBundle, userIds: string[]) {
  const timezones = ['America/Toronto', 'America/Vancouver', 'America/Montreal', 'America/Halifax', 'America/Edmonton'];
  const themes = ['system', 'light', 'dark'];
  await writeMany(userIds.slice(0, 10), async (userId, index) => {
    await writeDoc(`user_preferences/${userId}`, {
      userId,
      preferredLanguage: index % 4 === 0 ? 'fr' : 'en',
      preferredCurrency: 'CAD',
      timezone: timezones[index % timezones.length],
      theme: themes[index % themes.length],
      emailNotifications: true,
      pushNotifications: index % 3 !== 0,
      smsNotifications: index % 5 === 0,
      marketingEmails: index % 2 === 0,
      dateFormat: index % 3 === 0 ? 'DD/MM/YYYY' : 'MM/DD/YYYY',
      createdAt: isoDaysAgo(30),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }, 10);
}

async function seedPayouts(admin: AuthBundle, sellerIds: string[]) {
  const statuses = ['pending', 'completed', 'completed', 'completed', 'failed', 'processing', 'completed', 'pending'] as const;
  for (let i = 0; i < statuses.length; i++) {
    const sellerId = sellerIds[i % sellerIds.length];
    const status = statuses[i];
    const amountCents = 15000 + (i * 7500);
    const platformFeeCents = Math.round(amountCents * 0.10);
    await writeDoc(`payouts/payout_seed_${i}`, {
      sellerId,
      orderId: `orders:seed_order_${i}`,
      status,
      amountCents,
      platformFeeCents,
      netAmountCents: amountCents - platformFeeCents,
      currency: 'CAD',
      stripePayoutId: status === 'completed' ? `po_seed_${i}` : null,
      stripeTransferId: `tr_seed_${i}`,
      failureReason: status === 'failed' ? 'insufficient_funds' : null,
      scheduledAt: isoDaysAgo(15 - i),
      completedAt: status === 'completed' ? isoDaysAgo(10 - i) : null,
      createdAt: isoDaysAgo(20 - i),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}

// === ADDITIONAL SEED DATA FOR FULL VIEW COVERAGE ===

async function seedAdminAuditLogs(admin: AuthBundle, adminId: string, sellerIds: string[], buyerIds: string[]) {
  const actions = [
    'user_banned', 'user_unbanned', 'product_removed', 'order_refunded',
    'seller_verified', 'coupon_created', 'settings_changed',
  ] as const;
  const detailsMap: Record<string, string[]> = {
    user_banned: ['Spam', 'Fraudulent activity', 'Terms violation', 'Repeated abuse', 'Fake reviews'],
    user_unbanned: ['Appeal approved', 'Wrongful ban reversed', 'Account verified'],
    product_removed: ['Counterfeit item', 'Prohibited product', 'IP infringement', 'Misleading listing'],
    order_refunded: ['Buyer complaint', 'Seller failed to ship', 'Damaged in transit', 'Duplicate charge'],
    seller_verified: ['Documents approved', 'Business verification complete', 'Identity confirmed'],
    coupon_created: ['Holiday promo', 'New user discount', 'Loyalty reward', 'Flash sale'],
    settings_changed: ['Updated fee rate', 'Changed shipping policy', 'Modified return window', 'Updated TOS'],
  };
  const ipAddresses = ['192.168.1.1', '10.0.0.5', '172.16.0.12', '192.168.2.100', '10.10.1.50'];
  const allTargets = [...sellerIds, ...buyerIds];

  const logs = Array.from({ length: 55 }, (_, index) => {
    const action = actions[index % actions.length];
    const details = detailsMap[action][index % detailsMap[action].length];
    const targetId = allTargets[index % allTargets.length];
    return {
      id: `audit_log_${String(index + 1).padStart(3, '0')}`,
      adminId,
      action,
      targetId: `users:${targetId}`,
      details,
      timestamp: Math.floor(Date.now() / 1000) - index * 3600,
      ipAddress: ipAddresses[index % ipAddresses.length],
      createdAt: isoDaysAgo(index % 30),
    };
  });

  await writeMany(logs, async log => {
    await writeDoc(`admin_audit_logs/${log.id}`, log, admin.idToken, true);
  }, 20);
}

async function seedFlaggedReviews(admin: AuthBundle, buyerIds: string[], sellerId: string, productIds: string[]) {
  const flagReasons = ['spam', 'inappropriate', 'fake'] as const;
  const flaggedReviews = Array.from({ length: 10 }, (_, index) => {
    const productId = productIds[(index * 7) % productIds.length];
    const buyerId = buyerIds[index % buyerIds.length];
    return {
      id: `flagged_review_${String(index + 1).padStart(3, '0')}`,
      productId,
      userId: buyerId,
      sellerId,
      rating: 1 + (index % 3),
      review: `Flagged review ${index + 1} — content under moderation review.`,
      createdAt: isoDaysAgo((index % 15) + 1),
      hasPhotos: index % 3 === 0,
      photoUrls: index % 3 === 0 ? sampleImageUrls(`flagged-review-${index + 1}`, 1) : [],
      isFlagged: true,
      flagged: true,
      flagReason: flagReasons[index % flagReasons.length],
      reportCount: 3 + (index % 5),
      orderId: `seed_order_${String((index % 30) + 1).padStart(3, '0')}`,
    };
  });

  await writeMany(flaggedReviews, async review => {
    await writeDoc(`product_ratings/${review.id}`, review, admin.idToken, true);
  }, 10);
}

async function seedSuspendedSellers(admin: AuthBundle) {
  const suspendedSellers = [
    {
      id: 'seed_seller_suspended_01',
      status: 'suspended',
      businessName: 'Suspended Imports Ltd',
      suspensionReason: 'Multiple counterfeit product reports',
    },
    {
      id: 'seed_seller_suspended_02',
      status: 'suspended',
      businessName: 'Banned Electronics Co',
      suspensionReason: 'Fraudulent shipping claims',
    },
    {
      id: 'seed_seller_warned_01',
      status: 'warned',
      businessName: 'Warning Zone Goods',
      suspensionReason: 'Late shipping violations — 3 strikes',
    },
  ];

  for (const seller of suspendedSellers) {
    // Create user record
    await writeDoc(`users/${seller.id}`, {
      email: `${seller.id}@test.origna.ca`,
      displayName: seller.businessName,
      roles: ['buyer', 'seller'],
      isPremium: false,
      emailVerified: true,
      suspended: seller.status === 'suspended',
      stripeOnboarded: true,
      preferredLanguage: 'en',
      createdAt: isoDaysAgo(60),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);

    // Create seller profile with status
    await writeDoc(`seller_profiles/${seller.id}`, {
      sellerId: seller.id,
      businessName: seller.businessName,
      description: `Seeded ${seller.status} seller for admin moderation views.`,
      status: seller.status,
      suspensionReason: seller.suspensionReason,
      chargesEnabled: seller.status !== 'suspended',
      payoutsEnabled: seller.status !== 'suspended',
      detailsSubmitted: true,
      onboardingCompleted: true,
      pendingRequirements: [],
      defaultCurrency: 'CAD',
      defaultCountry: 'CA',
      stripeAccountId: `acct_seed_${seller.id}`,
      suspendedAt: seller.status === 'suspended' ? isoDaysAgo(5) : null,
      warnedAt: seller.status === 'warned' ? isoDaysAgo(3) : null,
      createdAt: isoDaysAgo(60),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}

async function seedShippingTracking(admin: AuthBundle) {
  const carriers = [
    { name: 'UPS', prefix: '1Z999AA1', urlBase: 'https://www.ups.com/track?tracknum=' },
    { name: 'FedEx', prefix: '7489', urlBase: 'https://www.fedex.com/fedextrack/?trknbr=' },
    { name: 'Canada Post', prefix: 'CPC', urlBase: 'https://www.canadapost-postescanada.ca/track-reperer/en#/details/' },
    { name: 'Purolator', prefix: 'PUR', urlBase: 'https://www.purolator.com/en/shipping/tracker?pin=' },
  ];

  for (let i = 0; i < 15; i++) {
    const carrier = carriers[i % carriers.length];
    const trackingNumber = `${carrier.prefix}${String(10000000 + i * 1234567).slice(0, 8)}`;
    const orderId = `seed_order_${String(i + 1).padStart(3, '0')}`;

    await writeDoc(`orders/${orderId}`, {
      trackingNumber,
      carrier: carrier.name,
      trackingUrl: `${carrier.urlBase}${trackingNumber}`,
      shippedAt: isoDaysAgo(3 + (i % 5)),
    }, admin.idToken, false); // merge, not overwrite
  }
}

async function seedReturnShippingLabels(admin: AuthBundle) {
  const carriers = ['Canada Post', 'UPS', 'FedEx', 'Purolator', 'Canada Post'];

  for (let i = 0; i < 5; i++) {
    const returnId = `return_${String(i + 1).padStart(3, '0')}`;
    const carrier = carriers[i];
    const trackingNumber = `RTN${carrier.replace(/\s/g, '').toUpperCase()}${String(20000000 + i * 987654).slice(0, 8)}`;

    await writeDoc(`return_requests/${returnId}`, {
      returnTrackingNumber: trackingNumber,
      returnCarrier: carrier,
      returnLabelUrl: `https://example.com/return-labels/${returnId}/${trackingNumber}.pdf`,
      returnShippedAt: isoDaysAgo(2 + i),
    }, admin.idToken, false); // merge
  }
}

async function seedSellerRatings(admin: AuthBundle, buyerIds: string[], sellerIds: string[]) {
  const comments = [
    'Great seller, fast shipping!',
    'Excellent communication throughout.',
    'Product exactly as described.',
    'Would buy again, very reliable.',
    'Good value, arrived on time.',
    'Packaging was superb, item perfect.',
    'Seller resolved my issue quickly.',
    'Friendly and professional service.',
    'Slightly delayed but great product.',
    'Amazing quality, highly recommend!',
  ];

  const ratings = Array.from({ length: 20 }, (_, index) => ({
    id: `seller_rating_${String(index + 1).padStart(3, '0')}`,
    buyerId: buyerIds[index % buyerIds.length],
    sellerId: sellerIds[index % sellerIds.length],
    orderId: `orders:seed_order_${String((index % 30) + 1).padStart(3, '0')}`,
    rating: 3 + (index % 3),
    comment: comments[index % comments.length],
    createdAt: Math.floor(Date.now() / 1000) - index * 86400,
  }));

  await writeMany(ratings, async rating => {
    await writeDoc(`seller_ratings/${rating.id}`, rating, admin.idToken, true);
  }, 10);
}

async function seedAbandonedCarts(admin: AuthBundle, buyerIds: string[], productIds: string[]) {
  for (let i = 0; i < 5; i++) {
    const buyerId = buyerIds[i % buyerIds.length];
    const productId = productIds[(i * 11) % productIds.length];
    const staleTimestamp = isoDaysAgo(2 + i); // 2-6 days old (well past 24h)

    await writeDoc(`users/${buyerId}/cart/abandoned_cart_${i + 1}`, {
      userId: buyerId,
      productId,
      quantity: 1 + (i % 2),
      priceCents: 2999 + (i * 500),
      createdAt: staleTimestamp,
      buyerNote: null,
      variantId: null,
      variantTitle: null,
      isAbandoned: true,
    }, admin.idToken, true);
  }
}

async function seedDashboardMetrics(admin: AuthBundle) {
  const metrics = Array.from({ length: 30 }, (_, index) => {
    const date = new Date(Date.now() - index * 86_400_000);
    const dateStr = date.toISOString().split('T')[0];
    const dayOfWeek = date.getDay();
    const isWeekend = dayOfWeek === 0 || dayOfWeek === 6;
    const baseOrders = isWeekend ? 25 : 47;
    const baseRevenue = isWeekend ? 750000 : 1250000;

    return {
      id: `metrics_${dateStr}`,
      date: dateStr,
      totalRevenueCents: baseRevenue + Math.floor(Math.random() * 500000),
      orderCount: baseOrders + Math.floor(Math.random() * 20),
      newUsers: 8 + Math.floor(Math.random() * 12),
      activeUsers: 120 + Math.floor(Math.random() * 80),
      conversionRate: Number((2.5 + Math.random() * 2.0).toFixed(1)),
      averageOrderValueCents: 4500 + Math.floor(Math.random() * 3000),
      returnsCount: Math.floor(Math.random() * 5),
      topCategory: CATEGORY_LABELS[index % CATEGORY_LABELS.length],
    };
  });

  await writeMany(metrics, async metric => {
    await writeDoc(`dashboard_metrics/${metric.id}`, metric, admin.idToken, true);
  }, 10);
}

async function seedImportJobs(admin: AuthBundle, sellerIds: string[]) {
  const jobs = [
    { id: 'import_job_001', sellerId: sellerIds[0], status: 'completed', totalRows: 150, processedRows: 150, failedRows: 2, filename: 'products_batch_jan.csv' },
    { id: 'import_job_002', sellerId: sellerIds[1], status: 'completed', totalRows: 80, processedRows: 80, failedRows: 0, filename: 'inventory_update.csv' },
    { id: 'import_job_003', sellerId: sellerIds[0], status: 'completed', totalRows: 200, processedRows: 200, failedRows: 5, filename: 'spring_collection.csv' },
    { id: 'import_job_004', sellerId: sellerIds[1], status: 'failed', totalRows: 50, processedRows: 12, failedRows: 12, filename: 'bad_format_import.xlsx', errorMessage: 'Invalid CSV format: unexpected column headers at row 13' },
    { id: 'import_job_005', sellerId: sellerIds[0], status: 'in_progress', totalRows: 300, processedRows: 187, failedRows: 0, filename: 'mega_catalog_update.csv' },
  ];

  for (const job of jobs) {
    await writeDoc(`import_jobs/${job.id}`, {
      ...job,
      startedAt: isoDaysAgo(job.status === 'in_progress' ? 0 : 5),
      completedAt: job.status === 'completed' ? isoDaysAgo(4) : job.status === 'failed' ? isoDaysAgo(3) : null,
      createdAt: isoDaysAgo(6),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}

async function seedComparisonLists(admin: AuthBundle, buyerIds: string[], productIds: string[]) {
  const lists = [
    { id: 'comparison_list_001', userId: buyerIds[0], name: 'Gaming Laptops', productIds: productIds.slice(0, 4) },
    { id: 'comparison_list_002', userId: buyerIds[1 % buyerIds.length], name: 'Kitchen Essentials', productIds: productIds.slice(10, 15) },
    { id: 'comparison_list_003', userId: buyerIds[2 % buyerIds.length], name: 'Gift Ideas', productIds: productIds.slice(20, 26) },
  ];

  for (const list of lists) {
    await writeDoc(`comparison_lists/${list.id}`, {
      ...list,
      createdAt: isoDaysAgo(3),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }
}


// ════════════════════════════════════════════════════════════════════
// EDGE-CASE SEEDERS — fills UI gaps for empty/edge/view states
// ════════════════════════════════════════════════════════════════════

/** Empty seller — has seller profile + warehouse but ZERO products → triggers seller_products_screen empty state */
async function seedEmptySeller(admin: AuthBundle) {
  const sellerId = 'seed_seller_empty_products';
  await writeDoc(`users/${sellerId}`, {
    email: 'seed-seller-empty@test.origna.ca',
    displayName: 'Empty Shelf Seller',
    roles: ['buyer', 'seller'],
    isPremium: true,
    emailVerified: true,
    suspended: false,
    stripeOnboarded: true,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(30),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`seller_profiles/${sellerId}`, {
    sellerId,
    businessName: 'Empty Shelf Co.',
    description: 'New seller — no products listed yet. Seeded for empty-state coverage.',
    status: 'approved',
    approvalStatus: 'approved',
    verificationStatus: 'approved',
    chargesEnabled: true,
    payoutsEnabled: true,
    detailsSubmitted: true,
    onboardingCompleted: true,
    pendingRequirements: [],
    defaultCurrency: 'CAD',
    defaultCountry: 'CA',
    stripeAccountId: 'acct_seed_empty_seller',
    createdAt: isoDaysAgo(30),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`users/${sellerId}/warehouses/wh_${sellerId}_main`, {
    warehouseId: `wh_${sellerId}_main`,
    label: 'Main Warehouse',
    type: 'warehouse',
    address: { street: '50 Empty Ave', city: 'Toronto', province: 'ON', postalCode: 'M5V 0A1', country: 'Canada' },
    isDefault: true,
    createdAt: isoDaysAgo(30),
  }, admin.idToken, true);

  await writeDoc(`seller_metrics/${sellerId}`, {
    sellerId,
    avgResponseTimeMinutes: 0,
    positiveRatePct: 0,
    totalReviews: 0,
    totalSales: 0,
    totalRevenueCents: 0,
    shipOnTimePct: 0,
    returnRatePct: 0,
    accountAgeDays: 30,
    lastActivityAt: isoDaysAgo(1),
    createdAt: isoDaysAgo(30),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  console.log(`  ✓ empty seller seeded (${sellerId}) — 0 products, profile complete`);
}

/**
 * Premium user with NO chat threads → triggers _ChatInboxBody empty state
 * (chat_conversations_screen.dart line 88-93: "No conversations yet")
 */
async function seedPremiumUserNoChats(admin: AuthBundle) {
  const userId = 'seed_premium_no_chats';
  await writeDoc(`users/${userId}`, {
    email: 'seed-premium-nochats@test.origna.ca',
    displayName: 'Premium Lone Wolf',
    roles: ['buyer'],
    isPremium: true,
    premiumSince: isoDaysAgo(45),
    premiumExpiresAt: isoDaysAgo(-30),
    emailVerified: true,
    suspended: false,
    stripeOnboarded: false,
    preferredLanguage: 'en',
    pushEnabled: true,
    notifyNewProducts: true,
    notifyTrending: false,
    createdAt: isoDaysAgo(90),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`subscriptions/${userId}`, {
    userId,
    planType: 'premium_monthly',
    status: 'active',
    currentPeriodStart: isoDaysAgo(10),
    currentPeriodEnd: isoDaysAgo(-20),
    cancelAtPeriodEnd: false,
    features: ['unlimited_listings', 'priority_support', 'analytics', 'chat_with_sellers'],
    stripeSubscriptionId: `sub_seed_no_chats_${userId}`,
    stripeCustomerId: `cus_seed_no_chats_${userId}`,
    createdAt: isoDaysAgo(45),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  console.log(`  ✓ premium user with NO chats seeded (${userId})`);
}

/**
 * Premium user with chat threads at 99+ unread → triggers "99+" overflow badge
 * (chat_conversations_screen.dart line 228-249)
 */
async function seedHighUnreadChats(admin: AuthBundle, sellerIds: string[]) {
  const buyerId = 'seed_buyer_high_unread';
  await writeDoc(`users/${buyerId}`, {
    email: 'seed-buyer-highunread@test.origna.ca',
    displayName: 'Busy Buyer (99+ unread)',
    roles: ['buyer'],
    isPremium: true,
    premiumSince: isoDaysAgo(60),
    premiumExpiresAt: isoDaysAgo(-15),
    emailVerified: true,
    suspended: false,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(120),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`subscriptions/${buyerId}`, {
    userId: buyerId,
    planType: 'premium_monthly',
    status: 'active',
    currentPeriodStart: isoDaysAgo(5),
    currentPeriodEnd: isoDaysAgo(-25),
    cancelAtPeriodEnd: false,
    features: ['unlimited_listings', 'priority_support', 'analytics', 'chat_with_sellers'],
    stripeSubscriptionId: 'sub_seed_high_unread',
    stripeCustomerId: 'cus_seed_high_unread',
    createdAt: isoDaysAgo(60),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  // Create 3 chat threads — one with 120 unread (→ shows "99+"), one with 47, one with 0
  const unreadCounts = [120, 47, 0];
  const productNames = ['Vintage Camera', 'Organic Maple Syrup', 'Gaming Keyboard'];

  for (let i = 0; i < 3; i++) {
    const sellerId = sellerIds[i % sellerIds.length];
    const chatId = `chat_high_unread_${i}`;
    const msgCount = 5;

    await writeDoc(`chats/${chatId}`, {
      participants: [buyerId, sellerId],
      productId: `mega_seed_product_${String(i + 1).padStart(4, '0')}`,
      buyerId,
      sellerId,
      productTitle: productNames[i],
      productImageUrl: sampleImageUrls(`chat-prod-${i}`, 1)[0],
      lastMessage: `You have ${unreadCounts[i]} unread messages from this seller.`,
      lastMessageAt: isoDaysAgo(i),
      unreadCount: unreadCounts[i],
      buyerUnreadCount: unreadCounts[i],
      sellerUnreadCount: 0,
      createdAt: isoDaysAgo(10 + i),
      updatedAt: isoDaysAgo(i),
    }, admin.idToken, true);

    // Write messages (all from seller so buyer has unread count)
    for (let j = 1; j <= Math.min(msgCount, 5); j++) {
      await writeDoc(`chats/${chatId}/messages/msg_${j}`, {
        chatId,
        senderId: sellerId,
        text: `Follow-up message ${j} about your order.`,
        isRead: false,
        createdAt: isoDaysAgo(i, j * 10),
      }, admin.idToken, true);
    }
  }

  console.log(`  ✓ high-unread chat threads seeded (${buyerId}) — unread: ${unreadCounts.join(', ')}`);
}

/**
 * Orders with awaiting_payment + shippingApprovalStatus pending
 * → triggers seller_orders_order_card authorization banner
 * → triggers shipping_approval_screen flow
 */
async function seedAwaitingPaymentOrders(admin: AuthBundle, buyerIds: string[], sellerId: string, productIds: string[]) {
  const orders = [
    {
      id: 'seed_order_awaiting_pay_01',
      orderStatus: 'pending',
      status: 'pending',
      paymentStatus: 'awaiting_payment',
      shippingApprovalStatus: 'pending',
      label: 'Awaiting payment + shipping approval pending',
    },
    {
      id: 'seed_order_awaiting_pay_02',
      orderStatus: 'confirmed',
      status: 'confirmed',
      paymentStatus: 'awaiting_payment',
      shippingApprovalStatus: 'approved',
      label: 'Awaiting payment + shipping approved',
    },
    {
      id: 'seed_order_payment_failed',
      orderStatus: 'pending',
      status: 'pending',
      paymentStatus: 'failed',
      shippingApprovalStatus: 'pending',
      label: 'Payment failed',
    },
    {
      id: 'seed_order_refunded_full',
      orderStatus: 'cancelled',
      status: 'cancelled',
      paymentStatus: 'refunded',
      shippingApprovalStatus: 'approved',
      label: 'Fully refunded',
    },
  ];

  for (let i = 0; i < orders.length; i++) {
    const spec = orders[i];
    const buyerId = buyerIds[i % buyerIds.length];
    const productId = productIds[i % productIds.length];
    const priceCents = 4999 + i * 2000;
    const quantity = 1 + (i % 2);
    const subtotalCents = priceCents * quantity;
    const shippingCostCents = spec.paymentStatus === 'awaiting_payment' ? 0 : 899;

    await writeDoc(`orders/${spec.id}`, {
      orderId: spec.id,
      orderStatus: spec.orderStatus,
      status: spec.status,
      paymentStatus: spec.paymentStatus,
      buyerId,
      userId: buyerId,
      sellerId: userRef(sellerId),
      sellerIds: [userRef(sellerId)],
      items: [{
        productId,
        cartItemId: `${spec.id}_item_1`,
        name: `Test Item — ${spec.label}`,
        description: `Seeded order for edge-case testing: ${spec.label}`,
        price: priceCents / 100,
        quantity,
        imageUrls: sampleImageUrls(`${productId}-order`, 1),
        sellerId: userRef(sellerId),
        status: spec.status,
        isDigital: false,
        isPerishable: false,
        freeShipping: i === 0,
      }],
      subtotalCents,
      shippingCostCents,
      taxAmountCents: Math.round(subtotalCents * 0.13),
      totalAmountCents: subtotalCents + Math.round(subtotalCents * 0.13) + shippingCostCents,
      createdAt: isoDaysAgo(3 + i),
      confirmedAt: spec.paymentStatus === 'awaiting_payment' && spec.orderStatus === 'confirmed' ? isoDaysAgo(2) : null,
      deliveredAt: null,
      shippedAt: null,
      trackingNumber: null,
      carrier: null,
      shippingApprovalStatus: spec.shippingApprovalStatus,
      shippingAddress: {
        street: '123 Buyer Demo St',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      },
      cancelledAt: spec.paymentStatus === 'refunded' ? isoDaysAgo(1) : null,
      cancelledBy: spec.paymentStatus === 'refunded' ? buyerId : null,
      refundAmountCents: spec.paymentStatus === 'refunded' ? subtotalCents + Math.round(subtotalCents * 0.13) + shippingCostCents : 0,
    }, admin.idToken, true);
  }

  console.log(`  ✓ awaiting-payment/failed/refunded orders seeded (${orders.length})`);
}

/**
 * Orders with delivery instructions
 * → triggers delivery instructions banner in order detail / seller order card
 */
async function seedOrdersWithDeliveryInstructions(admin: AuthBundle, buyerIds: string[], sellerId: string, productIds: string[]) {
  const instructions = [
    'Please leave at the back door. Ring doorbell twice.',
    'Fragile — handle with care. Do not stack.',
    'Deliver to concierge at lobby. Unit 1412.',
    'Gate code: #4521. Leave package at side porch.',
    'Call upon arrival: 416-555-0199.',
  ];

  for (let i = 0; i < instructions.length; i++) {
    const orderId = `seed_order_delinst_${String(i + 1).padStart(2, '0')}`;
    const buyerId = buyerIds[i % buyerIds.length];
    const productId = productIds[i % productIds.length];
    const status = i < 2 ? 'shipped' : i < 4 ? 'delivered' : 'confirmed';
    const priceCents = 2999 + i * 1500;

    await writeDoc(`orders/${orderId}`, {
      orderId,
      orderStatus: status,
      status,
      paymentStatus: 'paid',
      buyerId,
      userId: buyerId,
      sellerId: userRef(sellerId),
      sellerIds: [userRef(sellerId)],
      items: [{
        productId,
        cartItemId: `${orderId}_item_1`,
        name: `Delivery Instructions Test Item ${i + 1}`,
        description: 'Seeded order to test delivery instructions display.',
        price: priceCents / 100,
        quantity: 1,
        imageUrls: sampleImageUrls(`${productId}-di`, 1),
        sellerId: userRef(sellerId),
        status,
        isDigital: false,
        isPerishable: false,
        freeShipping: false,
      }],
      subtotalCents: priceCents,
      shippingCostCents: 899,
      taxAmountCents: Math.round(priceCents * 0.13),
      totalAmountCents: priceCents + Math.round(priceCents * 0.13) + 899,
      deliveryInstructions: instructions[i],
      createdAt: isoDaysAgo(5 + i),
      confirmedAt: isoDaysAgo(4 + i),
      deliveredAt: status === 'delivered' ? isoDaysAgo(i + 1) : null,
      shippedAt: status === 'shipped' || status === 'delivered' ? isoDaysAgo(2 + i) : null,
      trackingNumber: status === 'shipped' || status === 'delivered' ? `TRK-DI-${1000 + i}` : null,
      carrier: status === 'shipped' || status === 'delivered' ? 'canada_post' : null,
      shippingApprovalStatus: 'approved',
      shippingAddress: {
        street: `${100 + i} Demo Lane`,
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      },
    }, admin.idToken, true);
  }

  console.log(`  ✓ orders with delivery instructions seeded (${instructions.length})`);
}

/**
 * Age-restricted products → triggers age-gate text in checkout_screen.dart
 */
async function seedAgeRestrictedProducts(admin: AuthBundle, sellerId: string) {
  const products = [
    {
      id: 'e2e_product_age_restricted_knife',
      title: 'Professional Chef Knife Set — 8pc',
      description: 'High-carbon stainless steel chef knife set. Age verification required at checkout.',
      priceCents: 8999,
      stockQuantity: 25,
      categoryId: 4,
      categoryName: 'Home & Kitchen',
      subcategory: 'Cookware',
    },
    {
      id: 'e2e_product_age_restricted_whisky',
      title: 'Canadian Rye Whisky Infusion Kit',
      description: 'DIY whisky aging kit with oak chips and botanicals. Must be 19+ to purchase in Ontario.',
      priceCents: 5499,
      stockQuantity: 18,
      categoryId: 19,
      categoryName: 'Groceries',
      subcategory: 'Drinks',
      isPerishable: false,
    },
  ];

  for (const p of products) {
    await writeDoc(`products/${p.id}`, {
      productId: p.id,
      sellerId: userRef(sellerId),
      sellerSku: `SKU-AGE-${p.id.toUpperCase()}`,
      name: p.title,
      title: p.title,
      slug: slugify(p.title),
      description: p.description,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      subcategory: p.subcategory,
      price: p.priceCents / 100,
      priceCents: p.priceCents,
      compareAtPrice: Number(((p.priceCents + 500) / 100).toFixed(2)),
      stockQuantity: p.stockQuantity,
      lifecycleStatus: 'active',
      sellerDashboardStatus: 'active',
      isAgeRestricted: true,
      isDigital: false,
      isPerishable: p.isPerishable ?? false,
      isLocalDeliveryOnly: false,
      freeShipping: false,
      hasVariants: false,
      shipFromCountry: 'Canada',
      shipFromProvince: 'ON',
      shipFromCity: 'Toronto',
      imageUrls: sampleImageUrls(p.id, 2, p.categoryName),
      keywords: [p.categoryName.toLowerCase(), 'age_restricted', 'seeded'],
      createdAt: isoDaysAgo(15),
      updatedAt: new Date().toISOString(),
      rating: 4.3,
      ratingCount: 7,
      isTrending: false,
      trendingScore: 0,
      viewCount: 200,
      purchaseCount: 30,
      estimatedShipDays: 3,
      minimumOrderQuantity: 1,
      weightKg: 1.2,
      lengthCm: 30,
      widthCm: 20,
      heightCm: 10,
      warehouseIds: [`wh_${sellerId}_main`],
      warehouseStockMap: { [`wh_${sellerId}_main`]: p.stockQuantity },
      variantOptions: [],
      variants: [],
    }, admin.idToken, true);
  }

  console.log(`  ✓ age-restricted products seeded (${products.length})`);
}

/**
 * Cart with mixed available + unavailable items
 * → triggers unavailable items warning banner in cart_screen.dart line 160-207
 */
async function seedMixedAvailabilityCart(admin: AuthBundle, buyerId: string, productIds: string[]) {
  const cartItems = [
    { productId: productIds[0], available: true, quantity: 2, label: 'Available item' },
    { productId: productIds[1], available: true, quantity: 1, label: 'Available item' },
    { productId: 'e2e_product_oos', available: false, quantity: 1, label: 'Out of stock item' },
    { productId: productIds[2], available: true, quantity: 3, label: 'Available item' },
    { productId: 'mega_seed_product_0005', available: false, quantity: 1, label: 'Paused product' },
  ];

  for (let i = 0; i < cartItems.length; i++) {
    const item = cartItems[i];
    await writeDoc(`users/${buyerId}/cart/mixed_cart_${i}`, {
      userId: buyerId,
      productId: item.productId,
      quantity: item.quantity,
      priceCents: 1999 + (i * 700),
      imageUrl: sampleImageUrls(item.productId, 1)[0],
      productName: item.label,
      addedAt: isoDaysAgo(i + 1),
      updatedAt: new Date().toISOString(),
      availabilityStatus: item.available ? 'available' : 'unavailable',
      isUnavailable: !item.available,
      unavailableReason: !item.available ? (item.productId === 'e2e_product_oos' ? 'out_of_stock' : 'product_paused') : null,
    }, admin.idToken, true);
  }

  const totalCents = cartItems.reduce((sum, item, i) => sum + (1999 + i * 700) * item.quantity, 0);
  await writeDoc(`user_carts/${buyerId}`, {
    userId: buyerId,
    itemCount: cartItems.length,
    totalCents,
    unavailableItemCount: cartItems.filter(i => !i.available).length,
    lastUpdated: new Date().toISOString(),
  }, admin.idToken, true);

  console.log(`  ✓ mixed availability cart seeded for ${buyerId} (${cartItems.length} items, ${cartItems.filter(i => !i.available).length} unavailable)`);
}

/**
 * User with NO addresses → triggers checkout "add address" prompt
 * (checkout_screen.dart line 185, 275: _NoAddressView)
 */
async function seedUserNoAddresses(admin: AuthBundle) {
  const userId = 'seed_buyer_no_addresses';
  await writeDoc(`users/${userId}`, {
    email: 'seed-buyer-noaddr@test.origna.ca',
    displayName: 'No Address Buyer',
    roles: ['buyer'],
    isPremium: false,
    emailVerified: true,
    suspended: false,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(10),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  // Add a few cart items so checkout is reachable
  for (let i = 0; i < 2; i++) {
    await writeDoc(`users/${userId}/cart/noaddr_cart_${i}`, {
      userId,
      productId: `mega_seed_product_${String(i + 10).padStart(4, '0')}`,
      quantity: 1,
      priceCents: 2999 + i * 1000,
      imageUrl: sampleImageUrls(`noaddr-${i}`, 1)[0],
      productName: `No-Address Test Item ${i + 1}`,
      addedAt: isoDaysAgo(1),
      updatedAt: new Date().toISOString(),
      availabilityStatus: 'available',
      isUnavailable: false,
      unavailableReason: null,
    }, admin.idToken, true);
  }

  // Intentionally NOT writing any addresses for this user
  console.log(`  ✓ user with NO addresses seeded (${userId}) — checkout will show add-address prompt`);
}

/**
 * Products with bundledProductIds → triggers bundle display in product detail
 */
async function seedBundleProducts(admin: AuthBundle, sellerId: string, productIds: string[]) {
  const bundleId = 'e2e_product_bundle_starter';
  const bundledIds = productIds.slice(0, 3);

  await writeDoc(`products/${bundleId}`, {
    productId: bundleId,
    sellerId: userRef(sellerId),
    sellerSku: 'SKU-BUNDLE-STARTER',
    name: 'Starter Bundle — Desk Essentials',
    title: 'Starter Bundle — Desk Essentials',
    slug: 'starter-bundle-desk-essentials',
    description: 'Curated bundle: keyboard + mouse + monitor light. Save 15% vs buying separately.',
    categoryId: 2,
    categoryName: 'Computers',
    subcategory: 'Accessories',
    price: 79.99,
    priceCents: 7999,
    compareAtPrice: 94.99,
    stockQuantity: 30,
    lifecycleStatus: 'active',
    sellerDashboardStatus: 'active',
    isDigital: false,
    isPerishable: false,
    isLocalDeliveryOnly: false,
    freeShipping: true,
    hasVariants: false,
    isAgeRestricted: false,
    shipFromCountry: 'Canada',
    shipFromProvince: 'ON',
    shipFromCity: 'Toronto',
    imageUrls: sampleImageUrls(bundleId, 3, 'Computers'),
    keywords: ['bundle', 'desk', 'starter', 'seeded'],
    bundledProductIds: bundledIds,
    createdAt: isoDaysAgo(10),
    updatedAt: new Date().toISOString(),
    rating: 4.5,
    ratingCount: 12,
    isTrending: true,
    trendingScore: 320,
    trendingAt: isoDaysAgo(2),
    viewCount: 450,
    purchaseCount: 60,
    estimatedShipDays: 2,
    minimumOrderQuantity: 1,
    weightKg: 2.5,
    lengthCm: 40,
    widthCm: 30,
    heightCm: 15,
    warehouseIds: [`wh_${sellerId}_main`],
    warehouseStockMap: { [`wh_${sellerId}_main`]: 30 },
    variantOptions: [],
    variants: [],
  }, admin.idToken, true);

  console.log(`  ✓ bundle product seeded (${bundleId}) — references ${bundledIds.length} child products`);
}

/**
 * Premium user on cancelAtPeriodEnd → triggers subscription canceling state
 * (subscription_status_section.dart line 241-315: "subscription ends on" + reactivate)
 */
async function seedCancelingSubscription(admin: AuthBundle) {
  const userId = 'seed_buyer_canceling_sub';
  await writeDoc(`users/${userId}`, {
    email: 'seed-buyer-canceling@test.origna.ca',
    displayName: 'Canceling Premium User',
    roles: ['buyer'],
    isPremium: true,
    premiumSince: isoDaysAgo(90),
    premiumExpiresAt: isoDaysAgo(-5),
    emailVerified: true,
    suspended: false,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(180),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`subscriptions/${userId}`, {
    userId,
    planType: 'premium_monthly',
    status: 'active',
    currentPeriodStart: isoDaysAgo(25),
    currentPeriodEnd: isoDaysAgo(-5), // ends in 5 days
    cancelAtPeriodEnd: true,
    cancelledAt: isoDaysAgo(3),
    features: ['unlimited_listings', 'priority_support', 'analytics', 'chat_with_sellers'],
    stripeSubscriptionId: 'sub_seed_canceling_01',
    stripeCustomerId: 'cus_seed_canceling_01',
    createdAt: isoDaysAgo(90),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  console.log(`  ✓ canceling subscription seeded (${userId}) — cancelAtPeriodEnd=true`);
}

/**
 * Products with compareAtPrice much higher → ensures sale badge is visible
 * Also adds products with video for video player coverage
 */
async function seedSaleBadgeProducts(admin: AuthBundle, sellerId: string) {
  const products = [
    {
      id: 'e2e_product_deep_sale',
      title: 'Clearance — Wireless Earbuds Pro',
      priceCents: 2999,
      compareAtPriceCents: 12999, // 77% off
      stockQuantity: 50,
      subcategory: 'Audio',
    },
    {
      id: 'e2e_product_moderate_sale',
      title: 'Sale — Ergonomic Office Chair',
      priceCents: 19999,
      compareAtPriceCents: 29999, // 33% off
      stockQuantity: 12,
      subcategory: 'Desk',
    },
  ];

  for (const p of products) {
    await writeDoc(`products/${p.id}`, {
      productId: p.id,
      sellerId: userRef(sellerId),
      sellerSku: `SKU-SALE-${p.id.toUpperCase()}`,
      name: p.title,
      title: p.title,
      slug: slugify(p.title),
      description: `${p.title} — seeded for sale-badge and compare-at-price UI coverage.`,
      categoryId: 1,
      categoryName: 'Electronics',
      subcategory: p.subcategory,
      price: p.priceCents / 100,
      priceCents: p.priceCents,
      compareAtPrice: p.compareAtPriceCents / 100,
      stockQuantity: p.stockQuantity,
      lifecycleStatus: 'active',
      sellerDashboardStatus: 'active',
      isDigital: false,
      isPerishable: false,
      isLocalDeliveryOnly: false,
      freeShipping: false,
      isAgeRestricted: false,
      hasVariants: false,
      shipFromCountry: 'Canada',
      shipFromProvince: 'ON',
      shipFromCity: 'Toronto',
      imageUrls: sampleImageUrls(p.id, 2, 'Electronics'),
      videoUrl: PRODUCT_VIDEO_URLS[0],
      videoDurationSeconds: 5,
      keywords: ['sale', 'clearance', 'seeded'],
      createdAt: isoDaysAgo(7),
      updatedAt: new Date().toISOString(),
      rating: 4.1,
      ratingCount: 23,
      isTrending: false,
      trendingScore: 0,
      viewCount: 800,
      purchaseCount: 95,
      estimatedShipDays: 3,
      minimumOrderQuantity: 1,
      weightKg: 0.5,
      lengthCm: 20,
      widthCm: 15,
      heightCm: 8,
      warehouseIds: [`wh_${sellerId}_main`],
      warehouseStockMap: { [`wh_${sellerId}_main`]: p.stockQuantity },
      variantOptions: [],
      variants: [],
    }, admin.idToken, true);
  }

  console.log(`  ✓ sale-badge products seeded (${products.length}) — deep 77% and moderate 33% discounts`);
}

/**
 * Seller with acceptsReturns=false → tests "seller does not accept returns" state
 */
async function seedNoReturnsSeller(admin: AuthBundle) {
  const sellerId = 'seed_seller_no_returns';
  await writeDoc(`users/${sellerId}`, {
    email: 'seed-seller-noreturns@test.origna.ca',
    displayName: 'No Returns Electronics',
    roles: ['buyer', 'seller'],
    isPremium: false,
    emailVerified: true,
    suspended: false,
    stripeOnboarded: true,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(60),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`seller_profiles/${sellerId}`, {
    sellerId,
    businessName: 'No Returns Electronics',
    description: 'Final sale only — no returns accepted. Seeded for return-policy edge case.',
    status: 'approved',
    approvalStatus: 'approved',
    verificationStatus: 'approved',
    chargesEnabled: true,
    payoutsEnabled: true,
    detailsSubmitted: true,
    onboardingCompleted: true,
    pendingRequirements: [],
    acceptsReturns: false,
    returnWindowDays: 0,
    defaultCurrency: 'CAD',
    defaultCountry: 'CA',
    stripeAccountId: 'acct_seed_no_returns',
    createdAt: isoDaysAgo(60),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  // Seed 2 products from this seller
  for (let i = 0; i < 2; i++) {
    const productId = `e2e_product_no_returns_${i}`;
    await writeDoc(`products/${productId}`, {
      productId,
      sellerId: userRef(sellerId),
      sellerSku: `SKU-NR-${i}`,
      name: `Final Sale Item ${i + 1}`,
      title: `Final Sale Item ${i + 1}`,
      slug: slugify(`Final Sale Item ${i + 1}`),
      description: 'All sales final — no returns accepted.',
      categoryId: 1,
      categoryName: 'Electronics',
      subcategory: 'Accessories',
      price: 19.99 + i * 10,
      priceCents: 1999 + i * 1000,
      compareAtPrice: 29.99 + i * 10,
      stockQuantity: 20 + i * 5,
      lifecycleStatus: 'active',
      sellerDashboardStatus: 'active',
      isDigital: false,
      isPerishable: false,
      isLocalDeliveryOnly: false,
      freeShipping: false,
      isAgeRestricted: false,
      hasVariants: false,
      shipFromCountry: 'Canada',
      imageUrls: sampleImageUrls(productId, 1, 'Electronics'),
      keywords: ['final_sale', 'no_returns', 'seeded'],
      createdAt: isoDaysAgo(10),
      updatedAt: new Date().toISOString(),
      rating: 3.9,
      ratingCount: 5,
      isTrending: false,
      trendingScore: 0,
      viewCount: 100,
      purchaseCount: 15,
      estimatedShipDays: 3,
      minimumOrderQuantity: 1,
      weightKg: 0.3,
      lengthCm: 15,
      widthCm: 10,
      heightCm: 5,
      warehouseIds: [`wh_${sellerId}_main`],
      warehouseStockMap: { [`wh_${sellerId}_main`]: 20 },
      variantOptions: [],
      variants: [],
    }, admin.idToken, true);
  }

  await writeDoc(`seller_metrics/${sellerId}`, {
    sellerId,
    avgResponseTimeMinutes: 25,
    positiveRatePct: 78,
    totalReviews: 5,
    totalSales: 15,
    totalRevenueCents: 30000,
    shipOnTimePct: 90,
    returnRatePct: 0,
    accountAgeDays: 60,
    lastActivityAt: isoDaysAgo(1),
    createdAt: isoDaysAgo(60),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  console.log(`  ✓ no-returns seller seeded (${sellerId}) — acceptsReturns=false`);
}

// ════════════════════════════════════════════════════════════════════
// SECOND-PASS EDGE-CASE SEEDERS — deeper UI coverage
// ════════════════════════════════════════════════════════════════════

/**
 * Orders with ALL 12 status values — covers every statusConfig branch
 * in order_widgets.dart getOrderStatusConfig(): pending, confirmed, processing,
 * shipped, inTransit, delivered, cancelled, failed, expired, disputed,
 * refunded, partiallyRefunded
 */
async function seedAllStatusOrders(admin: AuthBundle, buyerIds: string[], sellerId: string, productIds: string[]) {
  const allStatuses = [
    { status: 'confirmed', paymentStatus: 'paid' },
    { status: 'processing', paymentStatus: 'paid' },
    { status: 'inTransit', paymentStatus: 'paid' },
    { status: 'failed', paymentStatus: 'failed' },
    { status: 'expired', paymentStatus: 'expired' },
    { status: 'disputed', paymentStatus: 'disputed' },
    { status: 'partiallyRefunded', paymentStatus: 'partially_refunded' },
  ] as const;

  for (let i = 0; i < allStatuses.length; i++) {
    const { status, paymentStatus } = allStatuses[i];
    const orderId = `seed_order_status_${status}`;
    const buyerId = buyerIds[i % buyerIds.length];
    const productId = productIds[i % productIds.length];
    const priceCents = 3999 + i * 1200;
    const subtotalCents = priceCents * 2;
    const hasTracking = status === 'inTransit';
    const isTerminal = ['failed', 'expired', 'disputed', 'partiallyRefunded', 'cancelled', 'refunded'].includes(status);

    await writeDoc(`orders/${orderId}`, {
      orderId,
      orderStatus: status,
      status,
      paymentStatus,
      buyerId,
      userId: buyerId,
      sellerId: userRef(sellerId),
      sellerIds: [userRef(sellerId)],
      items: [{
        productId,
        cartItemId: `${orderId}_item_1`,
        name: `Status Test — ${status}`,
        description: `Seeded order testing '${status}' status display.`,
        price: priceCents / 100,
        quantity: 2,
        imageUrls: sampleImageUrls(`${productId}-status`, 1),
        sellerId: userRef(sellerId),
        status,
        isDigital: false,
        isPerishable: false,
        freeShipping: false,
        trackingNumber: hasTracking ? `TRK-INT-${10000 + i}` : null,
        carrier: hasTracking ? 'canada_post' : null,
        variantTitle: i % 2 === 0 ? 'Size: M' : null,
        variantOptions: i % 2 === 0 ? { Size: 'M', Color: 'Navy' } : null,
      }],
      subtotalCents,
      shippingCostCents: 899,
      taxAmountCents: Math.round(subtotalCents * 0.13),
      totalAmountCents: subtotalCents + Math.round(subtotalCents * 0.13) + 899,
      createdAt: isoDaysAgo(20 + i),
      confirmedAt: isoDaysAgo(19 + i),
      shippedAt: hasTracking ? isoDaysAgo(5) : null,
      deliveredAt: null,
      trackingNumber: hasTracking ? `TRK-INT-${10000 + i}` : null,
      carrier: hasTracking ? 'canada_post' : null,
      shippingApprovalStatus: 'approved',
      shippingAddress: {
        street: '123 Status Test St',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      },
      cancelledAt: status === 'failed' || status === 'expired' ? isoDaysAgo(2) : null,
      refundAmountCents: paymentStatus === 'partially_refunded' ? Math.round(subtotalCents * 0.5) : 0,
      disputeReason: status === 'disputed' ? 'not_as_described' : null,
    }, admin.idToken, true);
  }

  console.log(`  ✓ all-status orders seeded (${allStatuses.length}) — ${allStatuses.map(s => s.status).join(', ')}`);
}

/**
 * Delivered order PAST return window → "Request Return" button disappears
 * + Delivered order WITHIN return window with mixed item eligibility
 */
async function seedReturnWindowOrders(admin: AuthBundle, buyerId: string, sellerId: string, productIds: string[]) {
  // 1) Delivered 45 days ago → PAST 30-day return window
  const pastOrderId = 'seed_order_return_expired';
  await writeDoc(`orders/${pastOrderId}`, {
    orderId: pastOrderId,
    orderStatus: 'delivered',
    status: 'delivered',
    paymentStatus: 'paid',
    buyerId,
    userId: buyerId,
    sellerId: userRef(sellerId),
    sellerIds: [userRef(sellerId)],
    items: [{
      productId: productIds[0],
      cartItemId: `${pastOrderId}_item_1`,
      name: 'Return-Expired Item',
      description: 'Delivered 45 days ago — return window closed.',
      price: 29.99,
      quantity: 1,
      imageUrls: sampleImageUrls(productIds[0], 1),
      sellerId: userRef(sellerId),
      status: 'delivered',
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
    }],
    subtotalCents: 2999,
    shippingCostCents: 899,
    taxAmountCents: 390,
    totalAmountCents: 4288,
    createdAt: isoDaysAgo(60),
    confirmedAt: isoDaysAgo(58),
    shippedAt: isoDaysAgo(55),
    deliveredAt: isoDaysAgo(45), // PAST 30-day window
    trackingNumber: 'TRK-RETEXP-001',
    carrier: 'canada_post',
    shippingApprovalStatus: 'approved',
    shippingAddress: { street: '123 Test St', city: 'Toronto', province: 'ON', postalCode: 'M5V 3A8', country: 'Canada' },
  }, admin.idToken, true);

  // 2) Delivered 3 days ago WITHIN return window — 3 items: 2 delivered, 1 still shipped
  const mixedOrderId = 'seed_order_return_mixed';
  await writeDoc(`orders/${mixedOrderId}`, {
    orderId: mixedOrderId,
    orderStatus: 'delivered', // overall status
    status: 'delivered',
    paymentStatus: 'paid',
    buyerId,
    userId: buyerId,
    sellerId: userRef(sellerId),
    sellerIds: [userRef(sellerId)],
    items: [
      {
        productId: productIds[0],
        cartItemId: `${mixedOrderId}_item_1`,
        name: 'Delivered Item A',
        description: 'Item within return window.',
        price: 19.99,
        quantity: 1,
        imageUrls: sampleImageUrls(productIds[0], 1),
        sellerId: userRef(sellerId),
        status: 'delivered',
        isDigital: false,
        isPerishable: false,
        freeShipping: false,
      },
      {
        productId: productIds[1],
        cartItemId: `${mixedOrderId}_item_2`,
        name: 'Delivered Item B',
        description: 'Also within return window.',
        price: 34.99,
        quantity: 2,
        imageUrls: sampleImageUrls(productIds[1], 1),
        sellerId: userRef(sellerId),
        status: 'delivered',
        isDigital: false,
        isPerishable: false,
        freeShipping: false,
      },
      {
        productId: productIds[2],
        cartItemId: `${mixedOrderId}_item_3`,
        name: 'Still-Shipped Item C',
        description: 'Not delivered yet — not return eligible.',
        price: 14.99,
        quantity: 1,
        imageUrls: sampleImageUrls(productIds[2], 1),
        sellerId: userRef(sellerId),
        status: 'shipped',
        isDigital: false,
        isPerishable: false,
        freeShipping: false,
      },
    ],
    subtotalCents: 1999 + 6998 + 1499,
    shippingCostCents: 0,
    taxAmountCents: 1365,
    totalAmountCents: 11861,
    createdAt: isoDaysAgo(7),
    confirmedAt: isoDaysAgo(6),
    shippedAt: isoDaysAgo(4),
    deliveredAt: isoDaysAgo(3), // WITHIN 30-day window
    trackingNumber: 'TRK-RETMIX-001',
    carrier: 'canada_post',
    shippingApprovalStatus: 'approved',
    shippingAddress: { street: '456 Mixed St', city: 'Toronto', province: 'ON', postalCode: 'M5V 3A8', country: 'Canada' },
  }, admin.idToken, true);

  console.log('  ✓ return-window orders seeded — 1 expired (45d), 1 mixed (3d, 2delivered+1shipped)');
}

/**
 * Notifications with ALL 7 UI types + today/this-week/earlier grouping + read/unread mix
 * notification types: orderConfirmation, shippingUpdate, paymentIssue, accountUpdate,
 *                     chatMessage, stockAvailable, newOrder
 */
async function seedAllNotificationTypes(admin: AuthBundle, userId: string) {
  const allTypes = [
    { type: 'orderConfirmation', route: '/orders', title: 'Order confirmed' },
    { type: 'shippingUpdate', route: '/orders', title: 'Your order shipped' },
    { type: 'paymentIssue', route: '/orders', title: 'Payment issue detected' },
    { type: 'accountUpdate', route: '/profile', title: 'Account security update' },
    { type: 'chatMessage', route: '/chat/inbox', title: 'New message' },
    { type: 'stockAvailable', route: '/notifications', title: 'Back in stock!' },
    { type: 'newOrder', route: '/seller/orders', title: 'New order received' },
  ];

  const notifications: any[] = [];

  // TODAY — 4 notifications, 3 unread
  for (let i = 0; i < 4; i++) {
    const t = allTypes[i % allTypes.length];
    notifications.push({
      id: `notif_all_today_${i}`,
      userId,
      type: t.type,
      title: `${t.title} — today #${i + 1}`,
      body: `This is a seeded ${t.type} notification from today.`,
      isRead: i === 2, // only #3 is read
      createdAt: isoDaysAgo(0, i * 60), // spread across today
      route: t.route,
      orderId: `seed_order_${String(i + 1).padStart(3, '0')}`,
      productId: `mega_seed_product_${String(i + 1).padStart(4, '0')}`,
      chatThreadId: t.type === 'chatMessage' ? 'chat_high_unread_0' : null,
    });
  }

  // THIS WEEK — 5 notifications, 2 unread
  for (let i = 0; i < 5; i++) {
    const t = allTypes[(i + 2) % allTypes.length];
    notifications.push({
      id: `notif_all_week_${i}`,
      userId,
      type: t.type,
      title: `${t.title} — this week #${i + 1}`,
      body: `This is a seeded ${t.type} notification from this week.`,
      isRead: i >= 2, // first 2 unread
      createdAt: isoDaysAgo(1 + i, i * 30),
      route: t.route,
      orderId: `seed_order_${String(i + 5).padStart(3, '0')}`,
      productId: `mega_seed_product_${String(i + 5).padStart(4, '0')}`,
    });
  }

  // EARLIER — 6 notifications, all read
  for (let i = 0; i < 6; i++) {
    const t = allTypes[(i + 4) % allTypes.length];
    notifications.push({
      id: `notif_all_earlier_${i}`,
      userId,
      type: t.type,
      title: `${t.title} — earlier #${i + 1}`,
      body: `This is a seeded ${t.type} notification from earlier.`,
      isRead: true,
      createdAt: isoDaysAgo(8 + i * 2, i * 15),
      route: t.route,
      orderId: `seed_order_${String(i + 10).padStart(3, '0')}`,
      productId: `mega_seed_product_${String(i + 10).padStart(4, '0')}`,
    });
  }

  await writeMany(notifications, async notif => {
    await writeDoc(`notifications/${notif.id}`, notif, admin.idToken, true);
  }, 20);

  console.log(`  ✓ all-notification-type seed (${notifications.length}) — 7 types, today(4)/week(5)/earlier(6), 5 unread`);
}

/**
 * Admin products: under_review + rejected + low_stock
 * → exercises admin_products_tab approval badge + stock filter chips
 */
async function seedAdminProducts(admin: AuthBundle, sellerId: string) {
  const products = [
    {
      id: 'e2e_product_under_review_01',
      title: 'Pending Review — Bluetooth Speaker',
      lifecycleStatus: 'under_review',
      stockQuantity: 15,
      approvalRejectionReason: null,
    },
    {
      id: 'e2e_product_under_review_02',
      title: 'Pending Review — LED Strip Kit',
      lifecycleStatus: 'under_review',
      stockQuantity: 40,
      approvalRejectionReason: null,
    },
    {
      id: 'e2e_product_rejected_01',
      title: 'Rejected — Suspicious Supplement',
      lifecycleStatus: 'rejected',
      stockQuantity: 0,
      approvalRejectionReason: 'Product listing does not meet marketplace guidelines. Unverified health claims detected.',
    },
    {
      id: 'e2e_product_low_stock_01',
      title: 'Low Stock — Limited Edition Vinyl',
      lifecycleStatus: 'active',
      stockQuantity: 2,
      approvalRejectionReason: null,
    },
    {
      id: 'e2e_product_low_stock_02',
      title: 'Low Stock — Rare Tea Sampler',
      lifecycleStatus: 'active',
      stockQuantity: 1,
      approvalRejectionReason: null,
    },
  ];

  for (const p of products) {
    await writeDoc(`products/${p.id}`, {
      productId: p.id,
      sellerId: userRef(sellerId),
      sellerSku: `SKU-ADMIN-${p.id.toUpperCase()}`,
      name: p.title,
      title: p.title,
      slug: slugify(p.title),
      description: `${p.title} — seeded for admin panel filter testing.`,
      categoryId: 1,
      categoryName: 'Electronics',
      subcategory: 'Audio',
      price: 24.99,
      priceCents: 2499,
      compareAtPrice: 39.99,
      stockQuantity: p.stockQuantity,
      lifecycleStatus: p.lifecycleStatus,
      sellerDashboardStatus: p.lifecycleStatus === 'active' ? 'active' : p.lifecycleStatus === 'under_review' ? 'draft' : 'inactive',
      isDigital: false,
      isPerishable: false,
      isLocalDeliveryOnly: false,
      freeShipping: false,
      isAgeRestricted: false,
      hasVariants: false,
      shipFromCountry: 'Canada',
      shipFromProvince: 'ON',
      shipFromCity: 'Toronto',
      imageUrls: sampleImageUrls(p.id, 1, 'Electronics'),
      keywords: ['admin_test', p.lifecycleStatus, 'seeded'],
      createdAt: isoDaysAgo(5),
      updatedAt: new Date().toISOString(),
      rating: 0,
      ratingCount: 0,
      isTrending: false,
      trendingScore: 0,
      viewCount: 10,
      purchaseCount: 0,
      estimatedShipDays: 3,
      minimumOrderQuantity: 1,
      weightKg: 0.5,
      lengthCm: 15,
      widthCm: 10,
      heightCm: 5,
      warehouseIds: [`wh_${sellerId}_main`],
      warehouseStockMap: { [`wh_${sellerId}_main`]: p.stockQuantity },
      variantOptions: [],
      variants: [],
      approvalRejectionReason: p.approvalRejectionReason,
    }, admin.idToken, true);
  }

  console.log(`  ✓ admin products seeded (${products.length}) — 2 under_review, 1 rejected, 2 low_stock`);
}

/**
 * Admin flagged reviews + reviews with photos
 * → exercises admin_reviews_tab flagged/photo filter chips
 */
async function seedAdminReviews(admin: AuthBundle, buyerIds: string[], sellerId: string, productIds: string[]) {
  const reviews = [
    {
      id: 'review_admin_flagged_spam',
      productId: productIds[0],
      userId: buyerIds[0],
      rating: 1,
      review: 'This is spam content — fake fake fake. Buy now at scam dot com!!!',
      isFlagged: true,
      flagReason: 'spam',
      reportCount: 8,
      hasPhotos: false,
    },
    {
      id: 'review_admin_flagged_photos',
      productId: productIds[1],
      userId: buyerIds[1],
      rating: 1,
      review: 'Terrible quality — see photos. Completely different from listing.',
      isFlagged: true,
      flagReason: 'inappropriate',
      reportCount: 4,
      hasPhotos: true,
    },
    {
      id: 'review_admin_photos_only',
      productId: productIds[2],
      userId: buyerIds[2],
      rating: 5,
      review: 'Amazing product! Here are my photos showing the quality.',
      isFlagged: false,
      flagReason: null,
      reportCount: 0,
      hasPhotos: true,
    },
    {
      id: 'review_admin_clean',
      productId: productIds[3],
      userId: buyerIds[3],
      rating: 4,
      review: 'Good product, minor issue with packaging.',
      isFlagged: false,
      flagReason: null,
      reportCount: 0,
      hasPhotos: false,
    },
  ];

  for (const r of reviews) {
    await writeDoc(`product_ratings/${r.id}`, {
      productId: r.productId,
      userId: r.userId,
      sellerId,
      rating: r.rating,
      review: r.review,
      createdAt: isoDaysAgo(3 + reviews.indexOf(r)),
      hasPhotos: r.hasPhotos,
      photoUrls: r.hasPhotos ? sampleImageUrls(r.id, 2) : [],
      isFlagged: r.isFlagged,
      flagged: r.isFlagged,
      flagReason: r.flagReason,
      reportCount: r.reportCount,
      orderId: `seed_order_${String(reviews.indexOf(r) + 1).padStart(3, '0')}`,
      verified: true,
    }, admin.idToken, true);
  }

  console.log(`  ✓ admin reviews seeded (${reviews.length}) — 2 flagged (1 with photos), 1 photos-only, 1 clean`);
}

/**
 * Digital delivered order with license key + download links
 * → exercises DigitalItemActions, BookDownloadButton, SoftwareDownloadLinks
 */
async function seedDigitalDeliveredOrder(admin: AuthBundle, buyerId: string, sellerId: string) {
  const orderId = 'seed_order_digital_delivered';
  await writeDoc(`orders/${orderId}`, {
    orderId,
    orderStatus: 'delivered',
    status: 'delivered',
    paymentStatus: 'paid',
    buyerId,
    userId: buyerId,
    sellerId: userRef(sellerId),
    sellerIds: [userRef(sellerId)],
    items: [
      {
        productId: 'e2e_product_test_seller',
        cartItemId: `${orderId}_item_sw`,
        name: 'Creator Power Pack',
        description: 'Professional content creation toolkit.',
        price: 49.99,
        quantity: 1,
        imageUrls: sampleImageUrls('e2e_product_test_seller', 1),
        sellerId: userRef(sellerId),
        status: 'delivered',
        isDigital: true,
        digitalType: 'software',
        licenseKey: 'XXXX-YYYY-ZZZZ-1234-ABCD',
        digitalBuilds: {
          mac: 'https://example.com/download/creator-pack/mac.dmg',
          windows: 'https://example.com/download/creator-pack/win.exe',
          linux: 'https://example.com/download/creator-pack/linux.AppImage',
        },
        isPerishable: false,
        freeShipping: true,
      },
      {
        productId: 'mega_seed_product_0014', // Books category
        cartItemId: `${orderId}_item_book`,
        name: 'Digital Cookbook — 500 Recipes',
        description: 'PDF cookbook with 500 recipes.',
        price: 14.99,
        quantity: 1,
        imageUrls: sampleImageUrls('book-digital', 1),
        sellerId: userRef(sellerId),
        status: 'delivered',
        isDigital: true,
        digitalType: 'book',
        licenseKey: 'BOOK-LIC-2026-0042',
        digitalBuilds: {
          pdf: 'https://example.com/download/cookbook.pdf',
          epub: 'https://example.com/download/cookbook.epub',
        },
        isPerishable: false,
        freeShipping: true,
      },
    ],
    subtotalCents: 6498,
    shippingCostCents: 0,
    taxAmountCents: 845,
    totalAmountCents: 7343,
    createdAt: isoDaysAgo(10),
    confirmedAt: isoDaysAgo(10),
    shippedAt: null,
    deliveredAt: isoDaysAgo(10), // instant digital delivery
    trackingNumber: null,
    carrier: null,
    shippingApprovalStatus: 'approved',
    shippingAddress: null, // digital-only, no address needed
  }, admin.idToken, true);

  console.log(`  ✓ digital delivered order seeded (${orderId}) — 1 software (license+3platforms) + 1 book (license+2formats)`);
}

/**
 * Product with variants where 1 variant is out of stock
 * → selecting that variant disables add-to-cart
 */
async function seedOosVariantProduct(admin: AuthBundle, sellerId: string) {
  const productId = 'e2e_product_variant_partial_oos';
  const sizes = ['S', 'M', 'L', 'XL'];
  const stockBySize: Record<string, number> = { S: 15, M: 0, L: 8, XL: 3 }; // M is OOS

  const variants = sizes.map(size => ({
    variantId: `${productId}_${size.toLowerCase()}`,
    title: size,
    sku: `SKU-VPOOS-${size}`,
    priceCents: 2499 + (sizes.indexOf(size) * 300),
    stockQuantity: stockBySize[size],
    imageUrls: sampleImageUrls(`${productId}-${size}`, 1),
    options: { Size: size },
  }));

  await writeDoc(`products/${productId}`, {
    productId,
    sellerId: userRef(sellerId),
    sellerSku: 'SKU-VPOOS-MAIN',
    name: 'Variant Stock Test — T-Shirt',
    title: 'Variant Stock Test — T-Shirt',
    slug: 'variant-stock-test-tshirt',
    description: 'T-Shirt with partial variant stock. Size M is out of stock.',
    categoryId: 5,
    categoryName: 'Fashion',
    subcategory: 'Tops',
    price: 24.99,
    priceCents: 2499,
    compareAtPrice: 34.99,
    stockQuantity: 26, // total across variants
    lifecycleStatus: 'active',
    sellerDashboardStatus: 'active',
    isDigital: false,
    isPerishable: false,
    isLocalDeliveryOnly: false,
    freeShipping: false,
    isAgeRestricted: false,
    hasVariants: true,
    variantOptions: [{ name: 'Size', values: sizes }],
    variants,
    shipFromCountry: 'Canada',
    imageUrls: sampleImageUrls(productId, 3, 'Fashion'),
    keywords: ['variant', 'stock', 'partial', 'seeded'],
    createdAt: isoDaysAgo(5),
    updatedAt: new Date().toISOString(),
    rating: 4.2,
    ratingCount: 9,
    isTrending: false,
    trendingScore: 0,
    viewCount: 350,
    purchaseCount: 45,
    estimatedShipDays: 3,
    minimumOrderQuantity: 1,
    weightKg: 0.3,
    lengthCm: 25,
    widthCm: 20,
    heightCm: 3,
    warehouseIds: [`wh_${sellerId}_main`],
    warehouseStockMap: { [`wh_${sellerId}_main`]: 26 },
  }, admin.idToken, true);

  console.log(`  ✓ partial-OOS variant product seeded (${productId}) — S:15, M:0, L:8, XL:3`);
}

/**
 * Products with French translations (Bill 96)
 * → exercises nameF/descriptionF in edit form + product detail
 */
async function seedBilingualProducts(admin: AuthBundle, sellerId: string) {
  const products = [
    {
      id: 'e2e_product_bilingual_01',
      title: 'Handcrafted Ceramic Mug',
      nameF: 'Tasse en céramique artisanale',
      descriptionF: 'Tasse en céramique faite à la main par des artisans canadiens. Parfait pour le café ou le thé.',
      categoryId: 20,
      categoryName: 'Art',
      subcategory: 'Ceramics',
    },
    {
      id: 'e2e_product_bilingual_02',
      title: 'Organic Lavender Soap Bar',
      nameF: 'Savon à la lavande biologique',
      descriptionF: 'Savon naturel à la lavande biologique, fabriqué au Québec. Idéal pour les peaux sensibles.',
      categoryId: 8,
      categoryName: 'Beauty',
      subcategory: 'Skincare',
    },
  ];

  for (const p of products) {
    await writeDoc(`products/${p.id}`, {
      productId: p.id,
      sellerId: userRef(sellerId),
      sellerSku: `SKU-BI-${p.id.toUpperCase()}`,
      name: p.title,
      title: p.title,
      nameF: p.nameF,
      slug: slugify(p.title),
      description: `${p.title} — high-quality Canadian-made product.`,
      descriptionF: p.descriptionF,
      categoryId: p.categoryId,
      categoryName: p.categoryName,
      subcategory: p.subcategory,
      price: 18.99,
      priceCents: 1899,
      compareAtPrice: 24.99,
      stockQuantity: 35,
      lifecycleStatus: 'active',
      sellerDashboardStatus: 'active',
      isDigital: false,
      isPerishable: false,
      isLocalDeliveryOnly: false,
      freeShipping: false,
      isAgeRestricted: false,
      hasVariants: false,
      shipFromCountry: 'Canada',
      imageUrls: sampleImageUrls(p.id, 2, p.categoryName),
      keywords: ['bilingual', 'french', 'canadian', 'seeded'],
      createdAt: isoDaysAgo(10),
      updatedAt: new Date().toISOString(),
      rating: 4.6,
      ratingCount: 14,
      isTrending: false,
      trendingScore: 0,
      viewCount: 200,
      purchaseCount: 25,
      estimatedShipDays: 3,
      minimumOrderQuantity: 1,
      weightKg: 0.4,
      lengthCm: 12,
      widthCm: 8,
      heightCm: 8,
      warehouseIds: [`wh_${sellerId}_main`],
      warehouseStockMap: { [`wh_${sellerId}_main`]: 35 },
      variantOptions: [],
      variants: [],
    }, admin.idToken, true);
  }

  console.log(`  ✓ bilingual products seeded (${products.length}) — nameF + descriptionF populated`);
}

/**
 * Seller with unanswered Q&A → red badge on seller products/orders screens
 */
async function seedUnansweredQa(admin: AuthBundle, sellerId: string, buyerIds: string[], productIds: string[]) {
  const questions = [
    { q: 'Does this come with a warranty?', productId: productIds[0] },
    { q: 'Can you ship internationally?', productId: productIds[1] },
    { q: 'Is this compatible with USB-C?', productId: productIds[2] },
    { q: 'What is the return policy?', productId: productIds[3] },
  ];

  for (let i = 0; i < questions.length; i++) {
    await writeDoc(`product_questions/qa_unanswered_${i}`, {
      questionId: `qa_unanswered_${i}`,
      productId: questions[i].productId,
      sellerId,
      askerId: buyerIds[i % buyerIds.length],
      question: questions[i].q,
      answer: null,
      answeredAt: null,
      answeredBy: null,
      isAnswered: false,
      upvotes: i + 1,
      createdAt: isoDaysAgo(i + 1),
    }, admin.idToken, true);
  }

  console.log(`  ✓ unanswered Q&A seeded (${questions.length}) — triggers seller badge count`);
}

/**
 * User with unverified email → triggers verification banner in profile
 */
async function seedUnverifiedUser(admin: AuthBundle) {
  const userId = 'seed_buyer_unverified_email';
  await writeDoc(`users/${userId}`, {
    email: 'seed-buyer-unverified@test.origna.ca',
    displayName: 'Unverified Email User',
    roles: ['buyer'],
    isPremium: false,
    emailVerified: false,
    suspended: false,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(5),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  console.log(`  ✓ unverified email user seeded (${userId})`);
}

// ════════════════════════════════════════════════════════════════════
// THIRD-PASS EDGE-CASE SEEDERS — remaining high-value gaps
// ════════════════════════════════════════════════════════════════════

/**
 * Security alerts — unacknowledged login alerts
 * → exercises security_alerts_section.dart "Was this you?" flow
 */
async function seedSecurityAlerts(admin: AuthBundle, userIds: string[]) {
  const alertTypes = [
    { type: 'new_device_login', details: 'New login from Chrome on Windows in Montreal, QC' },
    { type: 'new_device_login', details: 'New login from Safari on iPhone in Vancouver, BC' },
    { type: 'password_changed', details: 'Password was changed from an unrecognized device' },
    { type: 'failed_login_attempts', details: '5 failed login attempts detected from IP 203.0.113.42' },
  ];

  const targetUsers = userIds.slice(0, 3);
  for (let i = 0; i < targetUsers.length; i++) {
    const userId = targetUsers[i];
    for (let j = 0; j < alertTypes.length; j++) {
      const alert = alertTypes[j];
      await writeDoc(`security_alerts/alert_${userId}_${j}`, {
        userId,
        type: alert.type,
        details: alert.details,
        acknowledged: false,
        ipAddress: `203.0.113.${10 + j}`,
        userAgent: j % 2 === 0 ? 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/131.0' : 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0) Safari/605.1',
        createdAt: isoDaysAgo(j, i * 20),
      }, admin.idToken, true);
    }
  }

  console.log(`  ✓ security alerts seeded (${targetUsers.length} users × ${alertTypes.length} alerts)`);
}

/**
 * Seller with incomplete/pending Stripe verification
 * → exercises seller_setup_screen.dart _buildIncomplete + _buildPendingVerification
 */
async function seedSellerVerificationStates(admin: AuthBundle) {
  // Incomplete — needs identity documents
  const incompleteId = 'seed_seller_stripe_incomplete';
  await writeDoc(`users/${incompleteId}`, {
    email: 'seed-seller-incomplete@test.origna.ca',
    displayName: 'Incomplete Stripe Seller',
    roles: ['buyer', 'seller'],
    isPremium: false,
    emailVerified: true,
    suspended: false,
    stripeOnboarded: false,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(15),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`seller_profiles/${incompleteId}`, {
    sellerId: incompleteId,
    businessName: 'Incomplete Stripe Co.',
    description: 'Stripe onboarding started but identity documents missing.',
    status: 'pending',
    approvalStatus: 'pending',
    verificationStatus: 'pending',
    chargesEnabled: false,
    payoutsEnabled: false,
    detailsSubmitted: false,
    onboardingCompleted: false,
    needsIdentityDocuments: true,
    pendingRequirements: ['identity_document', 'business_verification'],
    pendingRequirementsDescription: 'Please upload a government-issued photo ID and business registration documents.',
    defaultCurrency: 'CAD',
    defaultCountry: 'CA',
    stripeAccountId: 'acct_seed_incomplete',
    createdAt: isoDaysAgo(15),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  // Pending verification — Stripe reviewing docs
  const pendingId = 'seed_seller_stripe_pending';
  await writeDoc(`users/${pendingId}`, {
    email: 'seed-seller-verification@test.origna.ca',
    displayName: 'Pending Verification Seller',
    roles: ['buyer', 'seller'],
    isPremium: false,
    emailVerified: true,
    suspended: false,
    stripeOnboarded: false,
    preferredLanguage: 'fr',
    createdAt: isoDaysAgo(8),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  await writeDoc(`seller_profiles/${pendingId}`, {
    sellerId: pendingId,
    businessName: 'Pending Verification Inc.',
    description: 'Documents submitted — Stripe reviewing identity.',
    status: 'pending',
    approvalStatus: 'pending',
    verificationStatus: 'pending',
    chargesEnabled: false,
    payoutsEnabled: false,
    detailsSubmitted: true,
    onboardingCompleted: false,
    isPendingVerification: true,
    pendingRequirements: [],
    defaultCurrency: 'CAD',
    defaultCountry: 'CA',
    stripeAccountId: 'acct_seed_pending_verify',
    documentsSubmittedAt: isoDaysAgo(3),
    createdAt: isoDaysAgo(8),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  console.log(`  ✓ seller verification states seeded — 1 incomplete (needs docs), 1 pending (reviewing)`);
}

/**
 * User at 10-address limit + addresses with phone numbers + custom labels
 * → exercises addressmanagement_screen.dart limit_reached + phone display + custom labels
 */
async function seedMaxAddressesUser(admin: AuthBundle) {
  const userId = 'seed_buyer_max_addresses';
  await writeDoc(`users/${userId}`, {
    email: 'seed-buyer-maxaddr@test.origna.ca',
    displayName: '10-Address Buyer',
    roles: ['buyer'],
    isPremium: false,
    emailVerified: true,
    suspended: false,
    preferredLanguage: 'en',
    createdAt: isoDaysAgo(90),
    updatedAt: new Date().toISOString(),
  }, admin.idToken, true);

  const cities = ['Toronto', 'Montreal', 'Vancouver', 'Calgary', 'Ottawa', 'Halifax', 'Winnipeg', 'Quebec City', 'Edmonton', 'Victoria'];
  const provinces = ['ON', 'QC', 'BC', 'AB', 'ON', 'NS', 'MB', 'QC', 'AB', 'BC'];
  const postalCodes = ['M5V 3A8', 'H2Y 1C6', 'V6B 1A1', 'T2P 1J9', 'K1P 1J1', 'B3J 2K9', 'R3C 1A5', 'G1R 4P5', 'T5J 0H3', 'V8W 1P6'];
  const labels = ['Home', 'Work', 'Cottage', 'Parents', null, 'Office', null, 'Chalet', null, 'Beach House']; // null = auto "Address N"
  const phones = ['416-555-0101', null, '604-555-0303', null, null, '902-555-0606', null, '418-555-0808', null, '250-555-1010'];

  for (let i = 0; i < 10; i++) {
    await writeDoc(`addresses/${userId}_addr_${i + 1}`, {
      userId,
      label: labels[i],
      address: {
        street: `${100 + i * 10} ${cities[i]} Main St`,
        apartment: i % 3 === 0 ? `${i + 1}A` : '',
        city: cities[i],
        province: provinces[i],
        postalCode: postalCodes[i],
        country: 'Canada',
      },
      phoneNumber: phones[i],
      isDefault: i === 0,
      createdAt: isoDaysAgo(90 - i * 5),
      updatedAt: new Date().toISOString(),
    }, admin.idToken, true);
  }

  console.log(`  ✓ max-address user seeded (${userId}) — 10 addresses with phone numbers + custom labels`);
}

/**
 * Perishable items in a "confirmed" (preparing) order
 * → exercises perishable urgency banner in order timeline step 0
 */
async function seedPerishablePreparingOrder(admin: AuthBundle, buyerId: string, sellerId: string) {
  const orderId = 'seed_order_perishable_preparing';
  await writeDoc(`orders/${orderId}`, {
    orderId,
    orderStatus: 'confirmed',
    status: 'confirmed',
    paymentStatus: 'paid',
    buyerId,
    userId: buyerId,
    sellerId: userRef(sellerId),
    sellerIds: [userRef(sellerId)],
    items: [
      {
        productId: 'e2e_food_strawberries',
        cartItemId: `${orderId}_item_1`,
        name: 'Fresh Ontario Strawberries — 1lb',
        description: 'Perishable item — requires expedited handling.',
        price: 8.99,
        quantity: 2,
        imageUrls: sampleImageUrls('e2e_food_strawberries', 1),
        sellerId: userRef(sellerId),
        status: 'confirmed',
        isDigital: false,
        isPerishable: true,
        freeShipping: false,
      },
      {
        productId: 'e2e_food_almond_butter',
        cartItemId: `${orderId}_item_2`,
        name: 'Natural Almond Butter 500g',
        description: 'Non-perishable item in same order.',
        price: 12.99,
        quantity: 1,
        imageUrls: sampleImageUrls('e2e_food_almond_butter', 1),
        sellerId: userRef(sellerId),
        status: 'confirmed',
        isDigital: false,
        isPerishable: false,
        freeShipping: false,
      },
    ],
    subtotalCents: 899 * 2 + 1299,
    shippingCostCents: 1299, // perishable expedited
    taxAmountCents: Math.round(3097 * 0.13),
    totalAmountCents: 3097 + Math.round(3097 * 0.13) + 1299,
    createdAt: isoDaysAgo(0, 30),
    confirmedAt: isoDaysAgo(0, 25),
    shippingApprovalStatus: 'approved',
    shippingAddress: {
      street: '123 Buyer Demo St',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
    },
    deliveryInstructions: 'Perishable — please keep refrigerated during transit.',
  }, admin.idToken, true);

  console.log(`  ✓ perishable preparing order seeded (${orderId}) — urgency banner for step-0 perishable`);
}

/**
 * Delivered order where buyer has NOT confirmed receipt and NOT rated
 * → exercises "Confirm Receipt" + "Rate" action buttons
 */
async function seedUnconfirmedDeliveredOrder(admin: AuthBundle, buyerId: string, sellerId: string, productIds: string[]) {
  const orderId = 'seed_order_unconfirmed_delivered';
  await writeDoc(`orders/${orderId}`, {
    orderId,
    orderStatus: 'delivered',
    status: 'delivered',
    paymentStatus: 'paid',
    buyerId,
    userId: buyerId,
    sellerId: userRef(sellerId),
    sellerIds: [userRef(sellerId)],
    items: [{
      productId: productIds[0],
      cartItemId: `${orderId}_item_1`,
      name: 'Unconfirmed Delivered Item',
      description: 'Delivered but buyer has not confirmed receipt yet.',
      price: 49.99,
      quantity: 1,
      imageUrls: sampleImageUrls(productIds[0], 1),
      sellerId: userRef(sellerId),
      status: 'delivered',
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
    }],
    subtotalCents: 4999,
    shippingCostCents: 899,
    taxAmountCents: 650,
    totalAmountCents: 6548,
    confirmedByClient: false, // NOT confirmed by buyer
    isRated: false, // NOT rated
    createdAt: isoDaysAgo(5),
    confirmedAt: isoDaysAgo(4),
    shippedAt: isoDaysAgo(3),
    deliveredAt: isoDaysAgo(1), // delivered yesterday
    trackingNumber: 'TRK-UNCONF-001',
    carrier: 'canada_post',
    shippingApprovalStatus: 'approved',
    shippingAddress: {
      street: '789 Unconfirmed Ave',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5V 3A8',
      country: 'Canada',
    },
  }, admin.idToken, true);

  console.log(`  ✓ unconfirmed/unrated delivered order seeded (${orderId}) — Confirm Receipt + Rate buttons`);
}

/**
 * Cart items pointing to deleted/missing products with snapshot data
 * → exercises cart_item_widget.dart "Currently Unavailable" overlay with snapshot
 */
async function seedDeletedProductCart(admin: AuthBundle, buyerId: string) {
  const userId = buyerId;
  const cartItems = [
    {
      cartId: `deleted_with_snapshot_1`,
      productId: 'product_deleted_001', // does not exist in products
      productName: 'Deleted Product — Vintage Camera (snapshot)',
      imageUrl: 'https://origna-static.b-cdn.net/images/origna_logo.png',
      priceCents: 8999,
      quantity: 1,
    },
    {
      cartId: `deleted_with_snapshot_2`,
      productId: 'product_deleted_002', // does not exist in products
      productName: 'Deleted Product — Wireless Headphones (snapshot)',
      imageUrl: 'https://origna-static.b-cdn.net/images/origna_logo.png',
      priceCents: 5499,
      quantity: 2,
    },
  ];

  for (const item of cartItems) {
    await writeDoc(`users/${userId}/cart/${item.cartId}`, {
      userId,
      productId: item.productId,
      quantity: item.quantity,
      priceCents: item.priceCents,
      imageUrl: item.imageUrl,
      productName: item.productName,
      addedAt: isoDaysAgo(14),
      updatedAt: new Date().toISOString(),
      availabilityStatus: 'unavailable',
      isUnavailable: true,
      unavailableReason: 'product_deleted',
      hasSnapshot: true,
    }, admin.idToken, true);
  }

  console.log(`  ✓ deleted-product cart items seeded (${cartItems.length}) — snapshot data available for unavailable overlay`);
}

async function main() {
  console.log(`🌱 Mega seeding ${process.env.ORIGNABASE_URL || 'default'} with ${PRODUCT_COUNT}+ products...`);

  // Force fresh auth resolution so seeded user-bound data lands on the current
  // canonical dev UI accounts instead of stale cached identities from /tmp.
  const tokenCacheFile = '/tmp/origna_e2e_tokens.json';
  if (existsSync(tokenCacheFile)) {
    unlinkSync(tokenCacheFile);
  }

  const admin = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const seller = await signIn(TEST_ACCOUNTS.SELLER_EMAIL, TEST_ACCOUNTS.SELLER_PASS);
  const buyer = await signIn(TEST_ACCOUNTS.BUYER_EMAIL, TEST_ACCOUNTS.BUYER_PASS);

  const ids = await upsertUsers(admin, seller, buyer);
  console.log(`  ✓ users seeded (admin=${ids.adminId}, seller=${ids.sellerId}, buyer=${ids.buyerId})`);

  // ════════════════════════════════════════════════════════════════════
  // SYNTHETIC USERS — 5000+ realistic users with Canadian names/addresses
  // ════════════════════════════════════════════════════════════════════
  const syntheticUserCount = Number(process.env.SEED_SYNTHETIC_USERS || 5000);
  if (syntheticUserCount > 0) {
    await seedSyntheticUsers(admin, syntheticUserCount);
  }

  await seedWarehouses(admin, [
    ids.adminId,
    ids.sellerId,
    ids.resolvedIdsByKey.seed_seller_01,
    ids.resolvedIdsByKey.seed_seller_02,
    ...ids.sellerPool.slice(0, 2),
  ].filter(Boolean));
  console.log('  ✓ warehouses seeded');

  const productIds = await seedProducts(admin, ids);
  console.log(`  ✓ products seeded (${productIds.length})`);

  // ════════════════════════════════════════════════════════════════════
  // ENHANCED FAVORITES — MORE REALISTIC DISTRIBUTION
  // ════════════════════════════════════════════════════════════════════
  const allBuyerIds = [...new Set([ids.buyerId, ...ids.buyerPool, ...ids.legacyUserIds])];
  await seedBuyerFavoritesViaApi(buyer, productIds);
  console.log(`  ✓ buyer favorites seeded (${buyer.localId})`);

  // ════════════════════════════════════════════════════════════════════
  // ENHANCED ADDRESSES — CANADIAN POSTAL CODES
  // ════════════════════════════════════════════════════════════════════
  await seedBuyerAddressesViaApi(buyer, 'buyer', 4);
  console.log(`  ✓ buyer addresses seeded (${buyer.localId})`);

  // ════════════════════════════════════════════════════════════════════
  // ENHANCED CART — WITH PRODUCT DETAILS
  // ════════════════════════════════════════════════════════════════════
  // Fetch product data for cart seeding
  const productsData = (await Promise.all(productIds.map(async id => {
    try {
      const res = await fetch(`${process.env.ORIGNABASE_URL || 'http://127.0.0.1:8080'}/documents/products/${id}`, {
        headers: { 'Authorization': `Bearer ${admin.idToken}` }
      });
      return res.json();
    } catch { return null; }
  }))).filter(p => p);

  await seedEnhancedCart(admin, ids.buyerId, productIds, productsData);
  for (const legacyUserId of ids.legacyUserIds) {
    await seedEnhancedCart(admin, legacyUserId, productIds, productsData);
  }
  for (let i = 0; i < 3; i++) {
    await seedEnhancedCart(admin, ids.buyerPool[i], productIds, productsData);
  }
  console.log(`  ✓ enhanced cart seeded (${BUYER_CART_COUNT} carts)`);

  // ════════════════════════════════════════════════════════════════════
  // ORIGINAL SEEDING (KEEP EXISTING DATA)
  // ════════════════════════════════════════════════════════════════════
  await seedOrders(
    admin,
    [ids.buyerId, ...ids.legacyUserIds, ...ids.buyerPool.slice(0, 6)],
    ids.sellerId,
    ids.resolvedIdsByKey.seed_seller_01 ?? ids.sellerId,
    productIds,
  );
  console.log('  ✓ orders seeded (45)');

  const notifUserIds = [ids.buyerId, ids.sellerId, ids.adminId, ...ids.legacyUserIds, ...ids.buyerPool.slice(0, 4), ...ids.sellerPool.slice(0, 2)];
  await seedNotifications(admin, notifUserIds);
  console.log(`  ✓ notifications seeded (6+ each across ${notifUserIds.length} users)`);

  // ════════════════════════════════════════════════════════════════════
  // ENHANCED REVIEWS — COMPREHENSIVE
  // ════════════════════════════════════════════════════════════════════
  await seedEnhancedReviews(admin, [ids.buyerId, ...ids.buyerPool.slice(0, 10)], [ids.sellerId, ...ids.sellerPool.slice(0, 3)], productIds);
  console.log('  ✓ enhanced reviews seeded (up to 500)');

  await seedQuestions(
    admin,
    [
      ids.buyerId,
      ids.resolvedIdsByKey.seed_buyer_04 ?? ids.buyerId,
      ids.resolvedIdsByKey.seed_buyer_05 ?? ids.buyerId,
    ],
    ids.sellerId,
    productIds,
  );
  console.log(`  ✓ Q&A seeded (${QUESTION_COUNT})`);

  // ════════════════════════════════════════════════════════════════════
  // ENHANCED CHATS — COMPLETE THREADS WITH MESSAGES
  // ════════════════════════════════════════════════════════════════════
  await seedEnhancedChats(admin, [ids.buyerId, ...ids.buyerPool.slice(0, 10)], [ids.sellerId, ...ids.sellerPool.slice(0, 3)], productIds);
  console.log('  ✓ enhanced chat threads seeded (up to 50)');

  await seedStockNotifications(admin, ids.buyerId);
  // More stock notifications for multiple users
  await seedMoreStockNotifications(admin, [ids.buyerId, ...ids.buyerPool.slice(0, 5)], productIds);
  console.log('  ✓ stock notifications seeded');

  const allUserIds = [...new Set([ids.adminId, ids.sellerId, ids.buyerId, ...ids.legacyUserIds, ...ids.sellerPool, ...ids.buyerPool])];
  const allSellerIds = [...new Set([ids.adminId, ids.sellerId, ...ids.sellerPool.slice(0, 4)])];

  // ════════════════════════════════════════════════════════════════════
  // ENHANCED SUBSCRIPTIONS — WITH PAYMENT HISTORY
  // ════════════════════════════════════════════════════════════════════
  await seedEnhancedSubscriptions(admin, allUserIds);
  console.log(`  ✓ enhanced subscriptions seeded (with invoice history)`);

  await seedSellerProfiles(admin, allSellerIds);
  console.log('  ✓ seller profiles seeded');

  await seedSellerMetrics(admin, allSellerIds);
  console.log('  ✓ seller metrics seeded');

  // ════════════════════════════════════════════════════════════════════
  // ENHANCED RETURN REQUESTS — ALL STATES
  // ════════════════════════════════════════════════════════════════════
  await seedEnhancedReturnRequests(admin, [ids.buyerId, ...ids.buyerPool.slice(0, 8)], productIds);
  console.log('  ✓ enhanced return requests seeded (all states)');

  await seedDisputes(admin, ids.buyerId, ids.sellerId, productIds);
  console.log(`  ✓ disputes seeded (${DISPUTE_COUNT})`);

  await seedCoupons(admin, allSellerIds);
  console.log(`  ✓ coupons seeded (${COUPON_COUNT})`);

  await seedPromotions(admin, allSellerIds, productIds);
  console.log(`  ✓ promotions seeded (${PROMOTION_COUNT})`);

  await seedDownloadSessions(admin, ids.buyerId, productIds);
  console.log(`  ✓ download sessions seeded (${DOWNLOAD_SESSION_COUNT})`);

  await seedMfaSettings(admin, [
    ids.adminId,
    ids.sellerId,
    ids.resolvedIdsByKey.seed_seller_01 ?? ids.sellerId,
    ids.resolvedIdsByKey.seed_buyer_01 ?? ids.buyerId,
    ids.resolvedIdsByKey.seed_buyer_02 ?? ids.buyerId,
  ]);
  console.log('  ✓ MFA settings seeded (5 users)');

  await seedReviewAnswers(admin, ids.sellerId);
  console.log('  ✓ review answers seeded (20)');

  await seedUserPreferences(admin, allUserIds);
  console.log('  ✓ user preferences seeded (10 users)');

  await seedPayouts(admin, allSellerIds);
  console.log('  ✓ seller payouts seeded (8)');

  await seedCategories(admin);
  console.log('  ✓ categories seeded (21)');

  const allBuyersExpanded = [ids.buyerId, ...ids.buyerPool.filter((_, i) => i < 10)];
  await seedMoreChats(admin, allBuyersExpanded, allSellerIds, productIds);
  console.log('  ✓ additional chat threads seeded (10)');

  // === ADDITIONAL SEED DATA FOR FULL VIEW COVERAGE ===

  await seedAdminAuditLogs(admin, ids.adminId, allSellerIds, ids.buyerPool.slice(0, 8));
  console.log('  ✓ admin audit logs seeded (55)');

  await seedFlaggedReviews(admin, [
    ids.buyerId,
    ids.resolvedIdsByKey.seed_buyer_01 ?? ids.buyerId,
    ids.resolvedIdsByKey.seed_buyer_02 ?? ids.buyerId,
    ids.resolvedIdsByKey.seed_buyer_03 ?? ids.buyerId,
  ], ids.sellerId, productIds);
  console.log('  ✓ flagged/reported reviews seeded (10)');

  await seedSuspendedSellers(admin);
  console.log('  ✓ suspended/warned seller profiles seeded (3)');

  await seedShippingTracking(admin);
  console.log('  ✓ shipping tracking data seeded (15 orders)');

  await seedReturnShippingLabels(admin);
  console.log('  ✓ return shipping labels seeded (5)');

  await seedSellerRatings(admin, [ids.buyerId, ...ids.buyerPool.slice(0, 5)], allSellerIds);
  console.log('  ✓ buyer-seller ratings seeded (20)');

  await seedAbandonedCarts(admin, ids.buyerPool.slice(0, 5), productIds);
  console.log('  ✓ abandoned carts seeded (5)');

  await seedDashboardMetrics(admin);
  console.log('  ✓ dashboard metrics seeded (30 days)');

  await seedImportJobs(admin, allSellerIds);
  console.log('  ✓ seller import jobs seeded (5)');

  await seedComparisonLists(admin, [ids.buyerId, ...ids.buyerPool.slice(0, 3)], productIds);
  console.log('  ✓ product comparison lists seeded (3)');

  // ════════════════════════════════════════════════════════════════════
  // EDGE-CASE SEEDERS — fills UI gaps for empty/edge/view states
  // ════════════════════════════════════════════════════════════════════

  await seedEmptySeller(admin);
  await seedPremiumUserNoChats(admin);
  await seedHighUnreadChats(admin, allSellerIds);
  await seedAwaitingPaymentOrders(admin,
    [ids.buyerId, ...ids.buyerPool.slice(0, 4)],
    ids.sellerId,
    productIds,
  );
  await seedOrdersWithDeliveryInstructions(admin,
    [ids.buyerId, ...ids.buyerPool.slice(0, 4)],
    ids.sellerId,
    productIds,
  );
  await seedAgeRestrictedProducts(admin, ids.sellerId);
  await seedMixedAvailabilityCart(admin, ids.buyerId, productIds);
  await seedUserNoAddresses(admin);
  await seedBundleProducts(admin, ids.sellerId, productIds);
  await seedCancelingSubscription(admin);
  await seedSaleBadgeProducts(admin, ids.sellerId);
  await seedNoReturnsSeller(admin);

  // ════════════════════════════════════════════════════════════════════
  // SECOND-PASS EDGE-CASE SEEDERS — deeper UI coverage
  // ════════════════════════════════════════════════════════════════════

  await seedAllStatusOrders(admin,
    [ids.buyerId, ...ids.buyerPool.slice(0, 6)],
    ids.sellerId,
    productIds,
  );
  await seedReturnWindowOrders(admin, ids.buyerId, ids.sellerId, productIds);
  await seedAllNotificationTypes(admin, ids.buyerId);
  await seedAdminProducts(admin, ids.sellerId);
  await seedAdminReviews(admin,
    [ids.buyerId, ...ids.buyerPool.slice(0, 3)],
    ids.sellerId,
    productIds,
  );
  await seedDigitalDeliveredOrder(admin, ids.buyerId, ids.sellerId);
  await seedOosVariantProduct(admin, ids.sellerId);
  await seedBilingualProducts(admin, ids.sellerId);
  await seedUnansweredQa(admin, ids.sellerId,
    [ids.buyerId, ...ids.buyerPool.slice(0, 3)],
    productIds,
  );
  await seedUnverifiedUser(admin);

  // ════════════════════════════════════════════════════════════════════
  // THIRD-PASS EDGE-CASE SEEDERS — remaining high-value gaps
  // ════════════════════════════════════════════════════════════════════

  await seedSecurityAlerts(admin, [ids.buyerId, ...ids.buyerPool.slice(0, 2)]);
  await seedSellerVerificationStates(admin);
  await seedMaxAddressesUser(admin);
  await seedPerishablePreparingOrder(admin, ids.buyerId, ids.sellerId);
  await seedUnconfirmedDeliveredOrder(admin, ids.buyerId, ids.sellerId, productIds);
  await seedDeletedProductCart(admin, ids.buyerId);

  await delay(1500);
  console.log('🌱 Mega seed complete.');
  console.log(`   Products: ${productIds.length}`);
  console.log(`   Synthetic users: ${syntheticUserCount}`);
  console.log(`   Collections seeded: users, products, favorites, addresses, warehouses, cart, orders,`);
  console.log(`     notifications, reviews, Q&A, chats, stock_notifications, subscriptions,`);
  console.log(`     seller_profiles, seller_metrics, return_requests, categories,`);
  console.log(`     disputes, coupons, promotions, download_sessions, mfa_settings,`);
  console.log(`     review_answers, user_preferences, payouts, admin_audit_logs,`);
  console.log(`     seller_ratings, dashboard_metrics, import_jobs, comparison_lists`);
  console.log(`   Multi-user: favorites(${allBuyerIds.length}), addresses(${allBuyerIds.length}+), cart(4+), chats(50+), reviews(500+)`);
  console.log(`   Additional: flagged reviews(10), suspended sellers(3), tracking(15), return labels(5),`);
  console.log(`     abandoned carts(5), audit logs(55), seller ratings(20), metrics(30d), imports(5), comparisons(3)`);
  console.log(`   All views and widgets now have populated non-empty state for demos.`);
  console.log(`   Canadian addresses & realistic names in ${syntheticUserCount} synthetic users.`);
  console.log(`   Edge cases: empty seller, premium-no-chats, 99+ unread chats, awaiting-payment orders,`);
  console.log(`     delivery instructions, age-restricted products, mixed cart, no-address user,`);
  console.log(`     bundle products, canceling subscription, sale-badge products, no-returns seller`);
  console.log(`   Deep coverage: all 12 order statuses, return-window expired/mixed, all 7 notification`);
  console.log(`     types with time grouping, admin under_review/rejected/low_stock, flagged reviews`);
  console.log(`     with photos, digital order with license+downloads, partial-OOS variants, bilingual`);
  console.log(`     products (FR), unanswered Q&A badge, unverified email user`);
  console.log(`   Third pass: security alerts, seller verification states (incomplete+pending),`);
  console.log(`     10-address limit user, perishable preparing order, unconfirmed/unrated delivered,`);
  console.log(`     deleted-product cart with snapshots`);
}

main().catch(err => {
  console.error('Mega seed failed:', err);
  process.exit(1);
});
