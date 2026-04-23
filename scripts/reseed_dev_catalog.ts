#!/usr/bin/env bun

import { callOk, listCollection, signIn } from '../e2e/lib/api-client.js';
import { TEST_ACCOUNTS } from '../e2e/lib/config.js';

const ORIGNABASE_URL = process.env.ORIGNABASE_URL || 'https://api.dev.orignagta.ca';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || TEST_ACCOUNTS.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || TEST_ACCOUNTS.ADMIN_PASS;
const SELLER_EMAIL = process.env.SELLER_EMAIL || TEST_ACCOUNTS.SELLER_EMAIL;
const SELLER_PASSWORD = process.env.SELLER_PASSWORD || TEST_ACCOUNTS.SELLER_PASS;
const DEV_R2_BASE = 'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples';
const DELETE_PAGE_SIZE = 100;

type SeedProduct = {
  title: string;
  description: string;
  priceCents: number;
  categoryId: number;
  categoryName: string;
  subcategory: string;
  stockQuantity: number;
  imageUrls: string[];
  sellerName: string;
  sellerId: string;
  shipFromCountry: string;
  shipFromProvince: string;
  shipFromCity: string;
  keywords: string[];
  specs?: {
    specs: Array<{
      key: string;
      value: string;
      valueType: 'text' | 'number';
      unit?: string;
      group: string;
    }>;
    brand?: string | null;
    color?: string | null;
    material?: string | null;
  };
  freeShipping?: boolean;
  isDigital?: boolean;
};

type SeedTemplate = {
  key: string;
  titleBase: string;
  descriptionBase: string;
  priceCents: number;
  categoryId: number;
  categoryName: string;
  subcategory: string;
  imageUrls: string[];
  keywords: string[];
  editions: string[];
  specs?: SeedProduct['specs'];
  freeShipping?: boolean;
  shipFromCountry?: string;
  shipFromProvince?: string;
  shipFromCity?: string;
  isDigital?: boolean;
};

function sellerLabel(email: string): string {
  return email === ADMIN_EMAIL ? 'OrignaVentures' : 'Northline Market';
}

function buildCatalog(sellers: Array<{ localId: string; email: string }>): SeedProduct[] {
  const templates: SeedTemplate[] = [
    {
      key: 'ultrabook',
      titleBase: 'NebulaBook 14 Ultrabook',
      descriptionBase: 'Slim aluminum productivity laptop with an all-day battery, crisp display, and quiet cooling for remote work or school.',
      priceCents: 129999,
      categoryId: 2,
      categoryName: 'Computers',
      subcategory: 'Laptops',
      imageUrls: [`${DEV_R2_BASE}/electronics-1.jpg`],
      keywords: ['laptop', 'ultrabook', 'ssd', 'remote work'],
      editions: ['16GB / 512GB', '16GB / 1TB', '32GB / 1TB', 'Creator Edition', 'Travel Edition'],
      freeShipping: true,
      specs: {
        specs: [
          { key: 'processor', value: 'Intel Core Ultra 7', valueType: 'text', group: 'Performance' },
          { key: 'ram', value: '16', valueType: 'number', unit: 'GB', group: 'Performance' },
          { key: 'storage', value: '512', valueType: 'number', unit: 'GB', group: 'Performance' },
          { key: 'display', value: '14-inch 2880×1800', valueType: 'text', group: 'Display' },
        ],
        brand: 'NebulaTech',
        color: 'Space Gray',
        material: 'Aluminum',
      },
    },
    {
      key: 'headphones',
      titleBase: 'QuietTone Wireless ANC Headphones',
      descriptionBase: 'Over-ear Bluetooth headphones with strong noise cancellation, low-latency mode, and plush memory-foam earcups.',
      priceCents: 18999,
      categoryId: 1,
      categoryName: 'Electronics',
      subcategory: 'Audio',
      imageUrls: [`${DEV_R2_BASE}/electronics-2.jpg`],
      keywords: ['headphones', 'anc', 'bluetooth', 'wireless'],
      editions: ['Midnight Black', 'Silver Mist', 'Travel Kit', 'Studio Bundle', 'Long-Haul Edition'],
      freeShipping: true,
      specs: {
        specs: [
          { key: 'batteryLife', value: '40', valueType: 'number', unit: 'hours', group: 'Power' },
          { key: 'bluetooth', value: '5.3', valueType: 'text', group: 'Connectivity' },
          { key: 'driverSize', value: '40', valueType: 'number', unit: 'mm', group: 'Audio' },
        ],
        brand: 'QuietTone',
        color: 'Black',
        material: 'ABS / Memory Foam',
      },
    },
    {
      key: 'smartphone',
      titleBase: 'Atlas X5 5G Smartphone',
      descriptionBase: 'Unlocked 5G smartphone with a bright OLED screen, optical image stabilization, and fast USB-C charging.',
      priceCents: 89999,
      categoryId: 1,
      categoryName: 'Electronics',
      subcategory: 'Phones',
      imageUrls: [`${DEV_R2_BASE}/electronics-3.jpg`],
      keywords: ['smartphone', '5g', 'oled', 'camera'],
      editions: ['128GB', '256GB', '256GB Pro Camera', '512GB', '512GB Matte Blue'],
      freeShipping: true,
      specs: {
        specs: [
          { key: 'display', value: '6.7-inch OLED', valueType: 'text', group: 'Display' },
          { key: 'camera', value: '50MP main + 12MP ultrawide', valueType: 'text', group: 'Camera' },
          { key: 'battery', value: '5000', valueType: 'number', unit: 'mAh', group: 'Power' },
        ],
        brand: 'Atlas Mobile',
        color: 'Graphite',
        material: 'Glass / Aluminum',
      },
    },
    {
      key: 'monitor',
      titleBase: 'StudioView 34 Ultrawide Monitor',
      descriptionBase: '34-inch ultrawide monitor tuned for design and productivity with a USB-C dock, slim bezels, and ergonomic stand.',
      priceCents: 52999,
      categoryId: 2,
      categoryName: 'Computers',
      subcategory: 'Monitors',
      imageUrls: [`${DEV_R2_BASE}/electronics-4.jpg`],
      keywords: ['monitor', 'ultrawide', 'usb-c', 'workstation'],
      editions: ['Standard Stand', 'Ergo Arm Bundle', 'Color-Calibrated', 'Creator Pack', 'Office Pack'],
      freeShipping: true,
      specs: {
        specs: [
          { key: 'panel', value: 'IPS', valueType: 'text', group: 'Display' },
          { key: 'resolution', value: '3440 × 1440', valueType: 'text', group: 'Display' },
          { key: 'refreshRate', value: '100', valueType: 'number', unit: 'Hz', group: 'Display' },
        ],
        brand: 'StudioView',
        color: 'Silver',
        material: 'Aluminum / Plastic',
      },
    },
    {
      key: 'sweater',
      titleBase: 'Everyday Knit Crew Sweater',
      descriptionBase: 'Soft mid-weight knit sweater with a relaxed silhouette for cool evenings, office layering, and daily wear.',
      priceCents: 6999,
      categoryId: 5,
      categoryName: 'Fashion',
      subcategory: 'Tops',
      imageUrls: [`${DEV_R2_BASE}/clothing-1.jpg`],
      keywords: ['sweater', 'knit', 'casual', 'layering'],
      editions: ['Heather Gray', 'Forest Green', 'Sand Beige', 'Navy', 'Charcoal'],
      specs: {
        specs: [
          { key: 'material', value: 'Cotton blend knit', valueType: 'text', group: 'Fabric' },
          { key: 'fit', value: 'Relaxed', valueType: 'text', group: 'Sizing' },
        ],
        brand: 'Northline',
        color: 'Heather Gray',
        material: 'Cotton Blend',
      },
    },
    {
      key: 'duffel',
      titleBase: 'Weekender Travel Duffel',
      descriptionBase: 'Structured travel duffel with reinforced handles, shoe compartment, and a water-resistant base panel.',
      priceCents: 11999,
      categoryId: 6,
      categoryName: 'Shoes & Accessories',
      subcategory: 'Travel',
      imageUrls: [`${DEV_R2_BASE}/clothing-2.jpg`],
      keywords: ['bag', 'duffel', 'travel', 'carry-on'],
      editions: ['Black Canvas', 'Olive Canvas', 'Stone Gray', 'Weekend Pack', 'Carry-On Pro'],
      freeShipping: true,
      specs: {
        specs: [
          { key: 'capacity', value: '32', valueType: 'number', unit: 'L', group: 'General' },
          { key: 'material', value: 'Waxed canvas', valueType: 'text', group: 'Fabric' },
        ],
        brand: 'Northline',
        color: 'Black',
        material: 'Waxed Canvas',
      },
    },
    {
      key: 'watch',
      titleBase: 'Classic Field Watch',
      descriptionBase: 'Minimalist field watch with a readable dial, brushed metal case, and comfortable everyday strap.',
      priceCents: 14999,
      categoryId: 7,
      categoryName: 'Jewelry & Watches',
      subcategory: 'Timepieces',
      imageUrls: [`${DEV_R2_BASE}/clothing-3.jpg`],
      keywords: ['watch', 'quartz', 'field watch', 'timepiece'],
      editions: ['Black Dial', 'Sand Dial', 'Steel Bracelet', 'Leather Strap', 'Weekend Edition'],
      specs: {
        specs: [
          { key: 'movement', value: 'Japanese quartz', valueType: 'text', group: 'Movement' },
          { key: 'caseSize', value: '40', valueType: 'number', unit: 'mm', group: 'General' },
        ],
        brand: 'Northline',
        color: 'Black',
        material: 'Stainless Steel',
      },
    },
    {
      key: 'sneakers',
      titleBase: 'City Runner Sneakers',
      descriptionBase: 'Lightweight everyday sneakers with cushioned midsoles, breathable mesh panels, and durable rubber traction.',
      priceCents: 9999,
      categoryId: 6,
      categoryName: 'Shoes & Accessories',
      subcategory: 'Sneakers',
      imageUrls: [`${DEV_R2_BASE}/clothing-4.jpg`],
      keywords: ['sneakers', 'running', 'streetwear', 'mesh'],
      editions: ['White / Gum', 'Black / White', 'Navy / Gray', 'Sand / Cream', 'All Black'],
      specs: {
        specs: [
          { key: 'upper', value: 'Breathable mesh', valueType: 'text', group: 'Construction' },
          { key: 'sole', value: 'Rubber traction outsole', valueType: 'text', group: 'Construction' },
        ],
        brand: 'Northline',
        color: 'White',
        material: 'Mesh / Rubber',
      },
    },
    {
      key: 'produce-box',
      titleBase: 'Farmer\'s Market Produce Box',
      descriptionBase: 'Seasonal produce box packed with crisp vegetables for soups, sautés, and weekly meal prep.',
      priceCents: 3299,
      categoryId: 19,
      categoryName: 'Groceries',
      subcategory: 'Produce',
      imageUrls: [`${DEV_R2_BASE}/food-1.jpg`],
      keywords: ['produce', 'vegetables', 'local', 'meal prep'],
      editions: ['Family Box', 'Dinner Box', 'Chef Box', 'Veggie Box', 'Fresh Box'],
      specs: {
        specs: [
          { key: 'origin', value: 'Ontario farms', valueType: 'text', group: 'Origin' },
          { key: 'storage', value: 'Refrigerate upon arrival', valueType: 'text', group: 'Handling' },
        ],
        brand: 'Harvest North',
        color: null,
        material: null,
      },
    },
    {
      key: 'fruit-box',
      titleBase: 'Honeycrisp Apple Sampler',
      descriptionBase: 'Fresh apple box selected for snacking and lunch prep, with firm texture and balanced sweetness.',
      priceCents: 2499,
      categoryId: 19,
      categoryName: 'Groceries',
      subcategory: 'Produce',
      imageUrls: [`${DEV_R2_BASE}/food-2.jpg`],
      keywords: ['fruit', 'apples', 'fresh', 'snack'],
      editions: ['6-Pack', '10-Pack', 'Family Share', 'School Week Box', 'Crunch Pack'],
    },
    {
      key: 'bread',
      titleBase: 'Country Sourdough Loaf',
      descriptionBase: 'Slow-fermented sourdough loaf with a crisp crust and soft interior, baked fresh each morning.',
      priceCents: 899,
      categoryId: 19,
      categoryName: 'Groceries',
      subcategory: 'Pantry',
      imageUrls: [`${DEV_R2_BASE}/food-3.jpg`],
      keywords: ['bread', 'sourdough', 'bakery', 'artisan'],
      editions: ['Classic Loaf', 'Sesame Crust', 'Whole Wheat', 'Sandwich Slice', 'Weekend Bake'],
    },
    {
      key: 'burger-kit',
      titleBase: 'Smash Burger Dinner Kit',
      descriptionBase: 'Weekend burger kit with seasoned patties, buns, and toppings for quick family dinners.',
      priceCents: 1899,
      categoryId: 19,
      categoryName: 'Groceries',
      subcategory: 'Specialty',
      imageUrls: [`${DEV_R2_BASE}/food-4.jpg`],
      keywords: ['burger', 'meal kit', 'dinner', 'specialty'],
      editions: ['Classic Kit', 'Family Kit', 'Cheese Kit', 'BBQ Kit', 'Party Kit'],
    },
    {
      key: 'desk-lamp',
      titleBase: 'Walnut Desk Lamp',
      descriptionBase: 'Warm LED desk lamp with a wood base and adjustable head, designed for calm workspaces and bedside tables.',
      priceCents: 7999,
      categoryId: 4,
      categoryName: 'Home & Kitchen',
      subcategory: 'Lighting',
      imageUrls: [`${DEV_R2_BASE}/home-1.jpg`],
      keywords: ['desk lamp', 'lighting', 'led', 'home office'],
      editions: ['Warm Light', 'Touch Dimmer', 'USB-C Base', 'Nightstand Edition', 'Workday Edition'],
      specs: {
        specs: [
          { key: 'brightness', value: '600', valueType: 'number', unit: 'lumens', group: 'Lighting' },
          { key: 'material', value: 'Walnut / Aluminum', valueType: 'text', group: 'Construction' },
        ],
        brand: 'Hearthlight',
        color: 'Walnut',
        material: 'Wood / Aluminum',
      },
    },
    {
      key: 'travel-bottles',
      titleBase: 'Refillable Travel Bottle Set',
      descriptionBase: 'Leak-resistant toiletry bottles and jars for carry-on travel, gym bags, and organized bathroom storage.',
      priceCents: 2599,
      categoryId: 8,
      categoryName: 'Beauty',
      subcategory: 'Tools',
      imageUrls: [`${DEV_R2_BASE}/home-2.jpg`],
      keywords: ['travel bottles', 'beauty', 'toiletry', 'organizer'],
      editions: ['4-Piece Set', '6-Piece Set', 'Weekend Set', 'Gym Set', 'Family Set'],
    },
    {
      key: 'pour-over',
      titleBase: 'Ceramic Pour-Over Coffee Kit',
      descriptionBase: 'Countertop coffee set with a ceramic dripper, glass carafe, and reusable filter for daily brewing.',
      priceCents: 5499,
      categoryId: 4,
      categoryName: 'Home & Kitchen',
      subcategory: 'Cookware',
      imageUrls: [`${DEV_R2_BASE}/home-3.jpg`],
      keywords: ['coffee', 'pour over', 'kitchen', 'brew kit'],
      editions: ['Starter Kit', 'Black Ceramic', 'Natural Ceramic', 'Gift Box', 'Countertop Set'],
    },
    {
      key: 'dash-cam',
      titleBase: 'RoadGuard 4K Dash Camera',
      descriptionBase: 'Wide-angle dash camera with night vision, loop recording, and app-based clip downloads for daily driving.',
      priceCents: 16999,
      categoryId: 11,
      categoryName: 'Automotive',
      subcategory: 'Safety',
      imageUrls: [`${DEV_R2_BASE}/auto-1.jpg`],
      keywords: ['dash cam', 'automotive', '4k', 'safety'],
      editions: ['Front Camera', 'Front + Rear', 'Parking Mode', 'Winter Kit', 'Road Trip Kit'],
      specs: {
        specs: [
          { key: 'resolution', value: '4K UHD', valueType: 'text', group: 'Video' },
          { key: 'storageSupport', value: 'Up to 256GB microSD', valueType: 'text', group: 'Storage' },
        ],
        brand: 'RoadGuard',
        color: 'Black',
        material: 'ABS',
      },
    },
    {
      key: 'emergency-kit',
      titleBase: 'Winter Emergency Car Kit',
      descriptionBase: 'Vehicle emergency kit packed with gloves, cables, tools, and reflective safety gear for cold-weather travel.',
      priceCents: 8499,
      categoryId: 12,
      categoryName: 'Tools',
      subcategory: 'DIY',
      imageUrls: [`${DEV_R2_BASE}/auto-2.jpg`],
      keywords: ['emergency kit', 'car', 'winter', 'tools'],
      editions: ['Compact Kit', 'Family Kit', 'Truck Kit', 'Snow Belt Kit', 'Roadside Pro'],
    },
    {
      key: 'book',
      titleBase: 'Modern Product Design Monograph',
      descriptionBase: 'Hardcover visual reference book featuring studio interiors, materials, packaging, and product design case studies.',
      priceCents: 4499,
      categoryId: 14,
      categoryName: 'Books',
      subcategory: 'Reference',
      imageUrls: [`${DEV_R2_BASE}/books-1.jpg`],
      keywords: ['book', 'design', 'reference', 'hardcover'],
      editions: ['Volume I', 'Volume II', 'Collector Edition', 'Studio Edition', 'Gift Edition'],
    },
    {
      key: 'landing-page',
      titleBase: 'SaaS Landing Page Template Pack',
      descriptionBase: 'Figma and HTML landing page bundle for startups with responsive sections, onboarding flows, and pricing blocks.',
      priceCents: 3900,
      categoryId: 21,
      categoryName: 'Digital',
      subcategory: 'Templates',
      imageUrls: [`${DEV_R2_BASE}/digital-1.jpg`],
      keywords: ['template', 'saas', 'figma', 'html'],
      editions: ['Starter', 'Growth', 'Agency', 'Indie Hacker', 'Launch Week'],
      isDigital: true,
      freeShipping: true,
    },
    {
      key: 'admin-kit',
      titleBase: 'Commerce Admin Dashboard Kit',
      descriptionBase: 'UI kit for analytics, order management, seller dashboards, and reporting flows with editable components.',
      priceCents: 4900,
      categoryId: 21,
      categoryName: 'Digital',
      subcategory: 'Software',
      imageUrls: [`${DEV_R2_BASE}/digital-2.jpg`],
      keywords: ['dashboard', 'ui kit', 'admin', 'analytics'],
      editions: ['Figma Source', 'HTML Export', 'Flutter Wireframe', 'Team License', 'Pro Pack'],
      isDigital: true,
      freeShipping: true,
    },
  ];

  const products: SeedProduct[] = [];
  let index = 0;
  for (const template of templates) {
    for (const edition of template.editions) {
      const seller = sellers[index % sellers.length];
      products.push({
        title: `${template.titleBase} — ${edition}`,
        description: `${template.descriptionBase} Edition: ${edition}. Shipped with polished merchandising copy and matching imagery for dev QA.`,
        priceCents: template.priceCents + (index % 3) * 700,
        categoryId: template.categoryId,
        categoryName: template.categoryName,
        subcategory: template.subcategory,
        stockQuantity: template.isDigital ? 999 : 8 + (index % 18) * 2,
        imageUrls: template.imageUrls,
        sellerName: sellerLabel(seller.email),
        sellerId: seller.localId,
        shipFromCountry: template.shipFromCountry ?? 'CA',
        shipFromProvince: template.shipFromProvince ?? 'ON',
        shipFromCity: template.shipFromCity ?? 'Toronto',
        keywords: [...template.keywords, template.categoryName.toLowerCase(), template.subcategory.toLowerCase()],
        specs: template.specs,
        freeShipping: template.freeShipping ?? false,
        isDigital: template.isDigital ?? false,
      });
      index += 1;
    }
  }
  return products;
}

async function graphqlDeleteProduct(id: string, token: string) {
  const response = await fetch(`${ORIGNABASE_URL}/graphql`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      query: 'mutation DeleteDoc($collection: String!, $id: String!) { delete(collection: $collection, id: $id) }',
      variables: { collection: 'products', id },
    }),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok || body?.errors?.length) {
    throw new Error(`Delete failed for ${id}: ${JSON.stringify(body)}`);
  }
}

async function deleteAllProducts(token: string) {
  let deleted = 0;
  while (true) {
    const ids = (await listCollection('products', token))
      .map((product) => product.id)
      .filter((id): id is string => Boolean(id))
      .slice(0, DELETE_PAGE_SIZE);
    if (ids.length === 0) break;
    await Promise.all(ids.map((id) => graphqlDeleteProduct(id, token)));
    deleted += ids.length;
    console.log(`Deleted ${deleted} products...`);
    if (ids.length < DELETE_PAGE_SIZE) break;
  }
  return deleted;
}

async function createProducts(products: SeedProduct[], token: string) {
  for (const product of products) {
    await callOk(
      'create_product_atomic',
      {
        productData: {
          title: product.title,
          description: product.description,
          priceCents: product.priceCents,
          categoryId: product.categoryId,
          categoryName: product.categoryName,
          subcategory: product.subcategory,
          stockQuantity: product.stockQuantity,
          lifecycleStatus: 'active',
          isDigital: product.isDigital ?? false,
          isPerishable: false,
          freeShipping: product.freeShipping ?? false,
          keywords: product.keywords,
          imageUrls: product.imageUrls,
          specs: product.specs,
          sellerId: product.sellerId,
          sellerName: product.sellerName,
          sellerStripeAccountId: null,
          shipFromCity: product.shipFromCity,
          shipFromProvince: product.shipFromProvince,
          shipFromCountry: product.shipFromCountry,
        },
        testImageUrls: product.imageUrls,
      },
      token,
    );
    console.log(`Seeded ${product.title}`);
  }
}

async function run() {
  console.log(`Connecting to ${ORIGNABASE_URL}`);
  const admin = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
  const seller = await signIn(SELLER_EMAIL, SELLER_PASSWORD);
  const deleted = await deleteAllProducts(admin.idToken);
  console.log(`Deleted total products: ${deleted}`);
  const catalog = buildCatalog([
    { localId: admin.localId, email: admin.email },
    { localId: seller.localId, email: seller.email },
  ]);
  await createProducts(catalog, admin.idToken);
  console.log(`Seeded total products: ${catalog.length}`);
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
