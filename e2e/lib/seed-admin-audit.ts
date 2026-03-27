#!/usr/bin/env bun

import { writeDoc } from './api-client.js';
import { ORIGNABASE_URL, TEST_ACCOUNTS } from './config.js';

const R2_BASE =
  'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples';

const SAMPLE_IMAGES = {
  electronics: `${R2_BASE}/electronics-1.jpg`,
  groceries: `${R2_BASE}/food-2.jpg`,
  clothing: `${R2_BASE}/clothing-2.jpg`,
};

function isoDaysAgo(days: number, extraMinutes = 0): string {
  return new Date(
    Date.now() - days * 86_400_000 - extraMinutes * 60_000,
  ).toISOString();
}

function isoDaysFromNow(days: number): string {
  return new Date(Date.now() + days * 86_400_000).toISOString();
}

async function main() {
  const login = async (email: string, password: string) => {
    const response = await fetch(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });
    const body = await response.json().catch(() => ({} as any));
    if (!response.ok || !body?.access_token || !body?.user?.id) {
      throw new Error(`Login failed for ${email}: ${body?.error?.message || response.status}`);
    }
    const rawId = String(body.user.id);
    return {
      token: String(body.access_token),
      rawId,
      bareId: rawId.includes(':') ? rawId.split(':', 2)[1] : rawId,
    };
  };

  const admin = await login(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const seller = await login(TEST_ACCOUNTS.SELLER_EMAIL, TEST_ACCOUNTS.SELLER_PASS);

  const adminId = admin.bareId;
  const sellerId = seller.bareId;
  const adminToken = admin.token;
  const adminUserRef = admin.rawId;
  const sellerUserRef = seller.rawId;

  const electronicsProduct = 'audit_product_electronics';
  const computerProduct = 'audit_product_computer';
  const digitalProduct = 'audit_product_digital';
  const foodProduct = 'audit_product_food';
  const intlProduct = 'audit_product_intl';

  const auditProducts = [
    {
      productId: electronicsProduct,
      sellerId: adminUserRef,
      name: 'Audit Desk Setup Bundle',
      description: 'Electronics product seeded for design audit detail screens.',
      categoryId: 1,
      subcategory: 'Monitors',
      priceCents: 24999,
      stockQuantity: 80,
      isDigital: false,
      isPerishable: false,
      freeShipping: true,
      isLocalDeliveryOnly: false,
      shipFromCountry: 'Canada',
      shipFromProvince: 'ON',
      shipFromCity: 'Toronto',
      imageUrls: [
        `${R2_BASE}/electronics-1.jpg`,
        `${R2_BASE}/electronics-4.jpg`,
      ],
      specs: {
        specs: [
          { key: 'brand', value: 'Samsung', valueType: 'text', group: 'General' },
          { key: 'model', value: 'Odyssey G9', valueType: 'text', group: 'General' },
          { key: 'screenSize', value: '49', valueType: 'number', unit: 'inches', group: 'Display' },
          { key: 'resolution', value: '5120 x 1440', valueType: 'text', group: 'Display' },
          { key: 'connectivity', value: 'HDMI 2.1, DisplayPort 1.4, USB-C', valueType: 'text', group: 'Connectivity' },
        ],
        brand: 'Samsung',
        color: 'White',
        material: 'Aluminum',
      },
      bundledProductIds: [digitalProduct, foodProduct],
    },
    {
      productId: computerProduct,
      sellerId: adminUserRef,
      name: 'Audit Pro Workstation Laptop',
      description: 'Computer product with rich specs for the specifications table.',
      categoryId: 2,
      subcategory: 'Laptops',
      priceCents: 349999,
      stockQuantity: 14,
      isDigital: false,
      isPerishable: false,
      freeShipping: true,
      isLocalDeliveryOnly: false,
      shipFromCountry: 'Canada',
      shipFromProvince: 'ON',
      shipFromCity: 'Toronto',
      imageUrls: [
        `${R2_BASE}/electronics-3.jpg`,
        `${R2_BASE}/electronics-4.jpg`,
      ],
      specs: {
        specs: [
          { key: 'processor', value: 'Apple M4 Pro', valueType: 'text', group: 'Performance' },
          { key: 'ram', value: '32', valueType: 'number', unit: 'GB', group: 'Performance' },
          { key: 'storage', value: '1000', valueType: 'number', unit: 'GB', group: 'Performance' },
          { key: 'gpu', value: 'Apple 20-core GPU', valueType: 'text', group: 'Performance' },
          { key: 'batteryLife', value: '22', valueType: 'number', unit: 'hours', group: 'Power' },
        ],
        brand: 'Apple',
        color: 'Space Black',
        material: 'Aluminum',
      },
      bundledProductIds: [],
    },
    {
      productId: digitalProduct,
      sellerId: adminUserRef,
      name: 'Audit Creator Power Pack',
      description: 'Digital product for checkout and seller listing coverage.',
      categoryId: 21,
      subcategory: 'Software',
      priceCents: 4999,
      stockQuantity: 300,
      isDigital: true,
      isPerishable: false,
      freeShipping: true,
      isLocalDeliveryOnly: false,
      shipFromCountry: 'Canada',
      shipFromProvince: 'ON',
      shipFromCity: 'Toronto',
      imageUrls: [
        `${R2_BASE}/digital-1.jpg`,
        `${R2_BASE}/digital-2.jpg`,
      ],
      specs: {
        specs: [
          { key: 'platform', value: 'Windows, macOS, Linux', valueType: 'text', group: 'Technical' },
          { key: 'fileFormat', value: 'ZIP, PSD, AI', valueType: 'text', group: 'Technical' },
        ],
        brand: null,
        color: null,
        material: null,
      },
      bundledProductIds: [],
    },
    {
      productId: foodProduct,
      sellerId: adminUserRef,
      name: 'Audit Maple Syrup',
      description: 'Food product with nutrition facts for product detail audit.',
      categoryId: 19,
      subcategory: 'Pantry',
      priceCents: 1499,
      stockQuantity: 200,
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
      isLocalDeliveryOnly: false,
      shipFromCountry: 'Canada',
      shipFromProvince: 'QC',
      shipFromCity: 'Montreal',
      imageUrls: [
        `${R2_BASE}/food-2.jpg`,
        `${R2_BASE}/food-3.jpg`,
      ],
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
        calciumMg: 72,
        ironMg: 1,
        potassiumMg: 204,
      },
      foodMetadata: {
        ingredientsEn: 'Pure maple syrup',
        ingredientsFr: 'Sirop d\'erable pur',
        allergens: [],
        mayContainAllergens: [],
        storageInstructionsEn: 'Refrigerate after opening.',
        storageInstructionsFr: 'Refrigerer apres ouverture.',
        bestBeforeDays: 730,
        dietaryBadges: ['organic', 'vegan', 'gluten_free'],
        fopHighSodium: false,
        fopHighSugars: true,
        fopHighSaturatedFat: false,
      },
      bundledProductIds: [],
    },
    {
      productId: intlProduct,
      sellerId: adminUserRef,
      name: 'Audit Imported Performance Parts',
      description: 'International product for shipped/tracking scenarios.',
      categoryId: 11,
      subcategory: 'Exterior',
      priceCents: 15999,
      stockQuantity: 120,
      isDigital: false,
      isPerishable: false,
      freeShipping: false,
      isLocalDeliveryOnly: false,
      shipFromCountry: 'China',
      shipFromProvince: 'SH',
      shipFromCity: 'Shanghai',
      imageUrls: [
        `${R2_BASE}/auto-1.jpg`,
        `${R2_BASE}/auto-2.jpg`,
      ],
      bundledProductIds: [],
    },
  ];

  for (const product of auditProducts) {
    await writeDoc(
      `products/${product.productId}`,
      {
        productId: product.productId,
        sellerId: product.sellerId,
        sellerSku: `SKU-${product.productId.toUpperCase()}`,
        name: product.name,
        title: product.name,
        slug: product.productId,
        description: product.description,
        categoryId: product.categoryId,
        subcategory: product.subcategory,
        price: product.priceCents / 100,
        priceCents: product.priceCents,
        compareAtPrice: Number(((product.priceCents + 900) / 100).toFixed(2)),
        stockQuantity: product.stockQuantity,
        lifecycleStatus: 'active',
        sellerAddress: {
          street: '100 Warehouse Way',
          city: product.shipFromCity,
          province: product.shipFromProvince,
          postalCode: 'M5V 3A8',
          country: product.shipFromCountry,
        },
        shipFromCountry: product.shipFromCountry,
        shipFromProvince: product.shipFromProvince,
        shipFromCity: product.shipFromCity,
        imageUrls: product.imageUrls,
        keywords: ['audit', 'design', product.subcategory.toLowerCase()],
        createdAt: isoDaysAgo(10),
        updatedAt: new Date().toISOString(),
        rating: 4.6,
        ratingCount: 12,
        isTrending: true,
        trendingScore: 250,
        trendingAt: isoDaysAgo(1),
        viewCount: 560,
        purchaseCount: 140,
        freeShipping: product.freeShipping,
        isDigital: product.isDigital,
        digitalType: product.isDigital ? 'software' : null,
        digitalBuilds: product.isDigital
          ? {
              mac: 'https://example.com/download/mac',
              windows: 'https://example.com/download/windows',
            }
          : null,
        isPerishable: product.isPerishable,
        ...(product.nutritionFacts ? { nutritionFacts: product.nutritionFacts } : {}),
        ...(product.foodMetadata ? { foodMetadata: product.foodMetadata } : {}),
        ...(product.specs ? { specs: product.specs } : {}),
        isLocalDeliveryOnly: product.isLocalDeliveryOnly,
        estimatedShipDays: product.isDigital ? 0 : 3,
        minimumOrderQuantity: 1,
        weightKg: product.isDigital ? 0.01 : 1.2,
        lengthCm: product.isDigital ? 1 : 22,
        widthCm: product.isDigital ? 1 : 16,
        heightCm: product.isDigital ? 1 : 8,
        warehouseIds: [`wh_${adminId}_main`, `wh_${adminId}_east`],
        warehouseStockMap: {
          [`wh_${adminId}_main`]: Math.floor(product.stockQuantity * 0.7),
          [`wh_${adminId}_east`]: product.stockQuantity - Math.floor(product.stockQuantity * 0.7),
        },
        hasVariants: product.productId === electronicsProduct,
        variantOptions:
          product.productId === electronicsProduct
            ? [{ name: 'Color', values: ['Crimson', 'Ocean'] }, { name: 'Size', values: ['M', 'L'] }]
            : [],
        variants:
          product.productId === electronicsProduct
            ? [
                {
                  variantId: `${electronicsProduct}_crimson_m`,
                  title: 'M / Crimson',
                  sku: 'AUDIT-CR-M',
                  priceCents: product.priceCents,
                  stockQuantity: 24,
                  optionValues: { Color: 'Crimson', Size: 'M' },
                },
              ]
            : [],
        bundledProductIds: product.bundledProductIds,
      },
      adminToken,
      true,
    );
  }

  await writeDoc(
    `users/${adminId}`,
      {
        email: TEST_ACCOUNTS.ADMIN_EMAIL,
        displayName: 'E2E Admin',
      roles: ['buyer', 'seller', 'admin'],
      isPremium: true,
      premiumSince: isoDaysAgo(60),
      premiumExpiresAt: isoDaysFromNow(30),
      pushEnabled: true,
      notifyNewProducts: true,
      notifyTrending: true,
      emailVerified: true,
      suspended: false,
      stripeOnboarded: true,
      preferredLanguage: 'en',
      createdAt: isoDaysAgo(45),
      updatedAt: new Date().toISOString(),
    },
    adminToken,
    true,
  );

  const addressDocs = [
    {
      id: 'audit_home',
      street: '123 Front St W',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5J 2M2',
      country: 'Canada',
      label: 'Home',
      isDefault: true,
    },
    {
      id: 'audit_work',
      street: '111 Richmond St W',
      city: 'Toronto',
      province: 'ON',
      postalCode: 'M5H 2G4',
      country: 'Canada',
      label: 'Work',
      isDefault: false,
    },
    {
      id: 'audit_montreal',
      street: '350 Rue Saint-Paul E',
      city: 'Montreal',
      province: 'QC',
      postalCode: 'H2Y 1H2',
      country: 'Canada',
      label: 'Other',
      isDefault: false,
    },
  ];

  for (const address of addressDocs) {
    await writeDoc(
      `addresses/${adminId.replace(':', '_')}_${address.id}`,
      {
        userId: adminUserRef,
        street: address.street,
        city: address.city,
        province: address.province,
        postalCode: address.postalCode,
        country: address.country,
        label: address.label,
        isDefault: address.isDefault,
      },
      adminToken,
      true,
    );
  }

  const warehouses = [
    {
      id: `wh_${adminId}_main`,
      label: 'Main Warehouse',
      isDefault: true,
      address: {
        street: '100 Warehouse Way',
        city: 'Toronto',
        province: 'ON',
        postalCode: 'M5V 3A8',
        country: 'Canada',
      },
    },
    {
      id: `wh_${adminId}_east`,
      label: 'East Fulfillment',
      isDefault: false,
      address: {
        street: '250 Harbor Rd',
        city: 'Montreal',
        province: 'QC',
        postalCode: 'H2Y 1C6',
        country: 'Canada',
      },
    },
  ];

  for (const warehouse of warehouses) {
    await writeDoc(
      `users/${adminId}/warehouses/${warehouse.id}`,
      {
        warehouseId: warehouse.id,
        label: warehouse.label,
        type: 'warehouse',
        address: warehouse.address,
        isDefault: warehouse.isDefault,
        createdAt: isoDaysAgo(20),
      },
      adminToken,
      true,
    );
  }

  await writeDoc(
    `seller_profiles/${adminId}`,
    {
      sellerId: adminUserRef,
      storeName: 'E2E Admin Store',
      storeSlug: 'e2e-admin-store',
      description:
        'Audit-focused admin seller profile with populated metrics, warehouses, and listings.',
      stripeOnboarded: true,
      onboardingComplete: true,
      onboardingStep: 2,
      supportEmail: TEST_ACCOUNTS.ADMIN_EMAIL,
      warehouseIds: warehouses.map((warehouse) => warehouse.id),
      createdAt: isoDaysAgo(30),
      updatedAt: new Date().toISOString(),
    },
    adminToken,
    true,
  );

  await writeDoc(
    `subscriptions/${adminId}`,
    {
      userId: adminUserRef,
      planType: 'premium_monthly',
      status: 'active',
      currentPeriodStart: isoDaysAgo(5),
      currentPeriodEnd: isoDaysFromNow(25),
      cancelAtPeriodEnd: false,
      features: [
        'unlimited_listings',
        'priority_support',
        'analytics',
        'bulk_tools',
      ],
      stripeSubscriptionId: `sub_audit_${adminId.replace(':', '_')}`,
      stripeCustomerId: `cus_audit_${adminId.replace(':', '_')}`,
      createdAt: isoDaysAgo(30),
      updatedAt: new Date().toISOString(),
    },
    adminToken,
    true,
  );

  await writeDoc(
    `mfa_settings/${adminId}`,
    {
      userId: adminUserRef,
      isEnabled: true,
      method: 'totp',
      phoneNumber: null,
      totpSecret: 'JBSWY3DPEHPK3PXPAUDIT',
      recoveryCodes: Array.from(
        { length: 8 },
        (_, index) => `AUDIT-${String(index + 1).padStart(4, '0')}`,
      ),
      lastUsedAt: isoDaysAgo(1),
      createdAt: isoDaysAgo(30),
      updatedAt: new Date().toISOString(),
    },
    adminToken,
    true,
  );

  const cartItems = [
    {
      id: 'audit_cart_1',
      productId: electronicsProduct,
      quantity: 1,
      priceCents: 24999,
      buyerNote: 'Deliver after 5 PM.',
      variantId: `${electronicsProduct}_crimson_m`,
      variantTitle: 'M / Crimson',
    },
    {
      id: 'audit_cart_2',
      productId: computerProduct,
      quantity: 1,
      priceCents: 349999,
      buyerNote: null,
      variantId: null,
      variantTitle: null,
    },
    {
      id: 'audit_cart_3',
      productId: foodProduct,
      quantity: 2,
      priceCents: 1499,
      buyerNote: 'Freshest stock only.',
      variantId: null,
      variantTitle: null,
    },
    {
      id: 'audit_cart_4',
      productId: digitalProduct,
      quantity: 1,
      priceCents: 4999,
      buyerNote: null,
      variantId: null,
      variantTitle: null,
    },
  ];

  for (const item of cartItems) {
    await writeDoc(
      `users/${adminId}/cart/${item.id}`,
      {
        userId: adminUserRef,
        productId: item.productId,
        quantity: item.quantity,
        priceCents: item.priceCents,
        createdAt: isoDaysAgo(1),
        buyerNote: item.buyerNote,
        variantId: item.variantId,
        variantTitle: item.variantTitle,
      },
      adminToken,
      true,
    );
  }

  const auditOrders = [
    {
      id: 'audit_order_pending',
      status: 'pending',
      paymentStatus: 'paid',
      productId: electronicsProduct,
      sellerIds: [adminUserRef],
      shippingApprovalStatus: 'pending',
      carrier: null,
      trackingNumber: null,
      shippedAt: null,
      deliveredAt: null,
    },
    {
      id: 'audit_order_confirmed',
      status: 'confirmed',
      paymentStatus: 'paid',
      productId: computerProduct,
      sellerIds: [adminUserRef],
      shippingApprovalStatus: 'approved',
      carrier: null,
      trackingNumber: null,
      shippedAt: null,
      deliveredAt: null,
    },
    {
      id: 'audit_order_shipped',
      status: 'shipped',
      paymentStatus: 'paid',
      productId: intlProduct,
      sellerIds: [adminUserRef, sellerUserRef],
      shippingApprovalStatus: 'approved',
      carrier: 'Canada Post',
      trackingNumber: 'CPC12345678',
      shippedAt: isoDaysAgo(2),
      deliveredAt: null,
    },
    {
      id: 'audit_order_delivered',
      status: 'delivered',
      paymentStatus: 'paid',
      productId: foodProduct,
      sellerIds: [adminUserRef],
      shippingApprovalStatus: 'approved',
      carrier: 'UPS',
      trackingNumber: '1Z999AA10123456784',
      shippedAt: isoDaysAgo(6),
      deliveredAt: isoDaysAgo(2),
    },
    {
      id: 'audit_order_cancelled',
      status: 'cancelled',
      paymentStatus: 'refunded',
      productId: digitalProduct,
      sellerIds: [adminUserRef],
      shippingApprovalStatus: 'approved',
      carrier: null,
      trackingNumber: null,
      shippedAt: null,
      deliveredAt: null,
    },
  ];

  for (const [index, order] of auditOrders.entries()) {
    const createdAt = isoDaysAgo(10 - index);
    const itemPriceCents =
      order.id === 'audit_order_shipped'
        ? 15999
        : order.id === 'audit_order_delivered'
          ? 1499
          : order.id === 'audit_order_cancelled'
            ? 4999
            : order.id === 'audit_order_confirmed'
              ? 349999
              : 24999;

    await writeDoc(
      `orders/${order.id}`,
      {
        orderStatus: order.status,
        paymentStatus: order.paymentStatus,
        userId: adminUserRef,
        sellerIds: order.sellerIds,
        items: [
          {
            productId: order.productId,
            cartItemId: `${order.id}_item_1`,
            name: `Audit ${order.status} order item`,
            description: 'Purpose-built order record for design audit coverage.',
            price: itemPriceCents / 100,
            quantity: 1,
            imageUrls: [
              order.productId === foodProduct
                ? SAMPLE_IMAGES.groceries
                : SAMPLE_IMAGES.electronics,
            ],
            sellerId: order.sellerIds[0],
            status: order.status,
            trackingNumber: order.trackingNumber,
            carrier: order.carrier,
            sellerName:
              order.sellerIds[0] === adminUserRef
                ? 'E2E Admin Store'
                : 'E2E Seller',
            isDigital: order.productId === digitalProduct,
            isPerishable: order.productId === foodProduct,
            freeShipping: order.status !== 'cancelled',
          },
        ],
        subtotalCents: itemPriceCents,
        shippingCostCents: order.status === 'cancelled' ? 0 : 599,
        taxAmountCents: Math.round(itemPriceCents * 0.13),
        totalAmountCents:
          itemPriceCents +
          Math.round(itemPriceCents * 0.13) +
          (order.status === 'cancelled' ? 0 : 599),
        createdAt,
        deliveredAt: order.deliveredAt,
        shippedAt: order.shippedAt,
        trackingNumber: order.trackingNumber,
        carrier: order.carrier,
        trackingUrl: order.trackingNumber
          ? `https://tracking.example/${order.trackingNumber}`
          : null,
        shippingApprovalStatus: order.shippingApprovalStatus,
        shippingAddress: {
          street: '123 Front St W',
          city: 'Toronto',
          province: 'ON',
          postalCode: 'M5J 2M2',
          country: 'Canada',
        },
      },
      adminToken,
      true,
    );
  }

  const returnRequests = [
    {
      id: 'audit_return_pending',
      orderId: 'audit_order_delivered',
      status: 'pending',
      reason: 'not_as_described',
    },
    {
      id: 'audit_return_approved',
      orderId: 'audit_order_delivered',
      status: 'approved',
      reason: 'arrived_damaged',
    },
  ];

  for (const [index, request] of returnRequests.entries()) {
    await writeDoc(
      `return_requests/${request.id}`,
      {
        returnId: request.id,
        orderId: request.orderId,
        buyerId: adminUserRef,
        sellerId: adminUserRef,
        productId: foodProduct,
        reason: request.reason,
        description: `Audit return request ${index + 1}.`,
        status: request.status,
        refundAmountCents: 1499,
        refundMethod:
          request.status === 'approved' ? 'original_payment' : null,
        requestedAt: isoDaysAgo(1 + index),
        reviewedAt: request.status === 'approved' ? isoDaysAgo(index) : null,
        resolvedAt: null,
        adminNotes:
          request.status === 'approved'
            ? 'Approved for screenshot coverage.'
            : null,
        returnTrackingNumber:
          request.status === 'approved' ? 'RTNCPC20000000' : null,
        returnCarrier: request.status === 'approved' ? 'Canada Post' : null,
        returnLabelUrl:
          request.status === 'approved'
            ? 'https://example.com/return-label.pdf'
            : null,
      },
      adminToken,
      true,
    );
  }

  const chatId = `chat_${adminId.replace(':', '_')}_${sellerId.replace(':', '_')}_audit`;
  await writeDoc(
    `chats/${chatId}`,
    {
      participants: [adminUserRef, sellerUserRef],
      productId: electronicsProduct,
      createdAt: isoDaysAgo(3),
      updatedAt: isoDaysAgo(0, 30),
      lastMessage: 'Tracking has been updated for your order.',
      lastMessageAt: isoDaysAgo(0, 30),
    },
    adminToken,
    true,
  );

  const messages = [
    {
      id: 'msg_1',
      senderId: adminUserRef,
      text: 'Can you confirm the shipping timeline?',
      createdAt: isoDaysAgo(3),
    },
    {
      id: 'msg_2',
      senderId: sellerUserRef,
      text: 'Yes. Shipping will update once the label is purchased.',
      createdAt: isoDaysAgo(2),
    },
    {
      id: 'msg_3',
      senderId: adminUserRef,
      text: 'Perfect. I also need the tracking number added to the order.',
      createdAt: isoDaysAgo(1),
    },
    {
      id: 'msg_4',
      senderId: sellerUserRef,
      text: 'Tracking has been updated for your order.',
      createdAt: isoDaysAgo(0, 30),
    },
  ];

  for (const message of messages) {
    await writeDoc(
      `chats/${chatId}/messages/${message.id}`,
      { ...message, isRead: message.senderId === sellerUserRef },
      adminToken,
      true,
    );
  }

  const notifications = [
    ['order_confirmed', 'Order confirmed', '/orders'],
    ['shipment_update', 'Shipment update', '/orders/detail?orderId=audit_order_shipped'],
    ['new_message', 'New support message', '/chat/inbox'],
    ['promotional', 'Premium spring sale', '/subscription'],
    ['security_alert', 'New login on macOS', '/security-settings'],
    ['payout_ready', 'Payout ready for seller account', '/seller/analytics'],
  ];

  for (const [index, [type, title, route]] of notifications.entries()) {
    const payload = {
      userId: adminUserRef,
      type,
      title,
      body: `Audit notification ${index + 1}`,
      isRead: index % 3 === 0,
      createdAt: isoDaysAgo(index, index * 17),
      route,
    };
    await writeDoc(
      `notifications/audit_notif_${index + 1}`,
      payload,
      adminToken,
      true,
    );
    await writeDoc(
      `users/${adminId}/notifications/audit_notif_${index + 1}`,
      payload,
      adminToken,
      true,
    );
  }

  await writeDoc(
    'import_jobs/audit_import_001',
    {
      sellerId: adminUserRef,
      status: 'completed',
      totalRows: 150,
      processedRows: 150,
      failedRows: 2,
      filename: 'audit_bulk_upload.csv',
      startedAt: isoDaysAgo(5),
      completedAt: isoDaysAgo(4),
      createdAt: isoDaysAgo(6),
      updatedAt: new Date().toISOString(),
    },
    adminToken,
    true,
  );

  await writeDoc(
    `seller_metrics/audit_metrics_${adminId.replace(':', '_')}`,
    {
      sellerId: adminUserRef,
      totalRevenueCents: 2450099,
      orderCount: 42,
      averageOrderValueCents: 58335,
      responseRate: 98.2,
      shipOnTimeRate: 97.5,
      cancellationRate: 1.2,
      period: '30d',
      createdAt: isoDaysAgo(1),
      updatedAt: new Date().toISOString(),
    },
    adminToken,
    true,
  );

  console.log(JSON.stringify({
    adminId,
    sellerId,
    products: {
      electronicsProduct,
      computerProduct,
      digitalProduct,
      foodProduct,
      intlProduct,
    },
    orders: auditOrders.map((order) => order.id),
    chatId,
  }, null, 2));
}

await main();
