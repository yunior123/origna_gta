#!/usr/bin/env bun
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { callOk, signIn } from '../e2e/lib/api-client.js';

const ORIGNABASE_URL = process.env.ORIGNABASE_URL || 'https://api.dev.orignagta.ca';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
const PRODUCTS_PATH =
  process.env.PRODUCTS_PATH || 'scripts/data/aliexpress_test_products.json';
const IMAGE_URLS_JSON_PATH =
  process.env.IMAGE_URLS_JSON_PATH || 'scripts/data/solar_product_uploaded_urls.json';
const DEV_PUBLIC_SAMPLE_BASE =
  'https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples';

type SeedProduct = {
  title: string;
  description: string;
  priceCents: number;
  categoryId: number;
  categoryName?: string;
  subcategory?: string;
  stockQuantity?: number;
  keywords?: string[];
  supplier?: Record<string, unknown>;
};

function requireEnv(value: string | undefined, name: string): string {
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function loadProducts(): SeedProduct[] {
  return JSON.parse(readFileSync(resolve(PRODUCTS_PATH), 'utf8')) as SeedProduct[];
}

function loadImageUrls(): string[] {
  const data = JSON.parse(readFileSync(resolve(IMAGE_URLS_JSON_PATH), 'utf8')) as {
    imageUrls?: string[];
  };
  if (!Array.isArray(data.imageUrls) || data.imageUrls.length == 0) {
    throw new Error(`No imageUrls found in ${IMAGE_URLS_JSON_PATH}`);
  }
  return data.imageUrls;
}

function normalizeSeedImageUrls(urls: string[]): string[] {
  const httpsUrls = urls.filter((url) => url.startsWith('https://'));
  if (httpsUrls.length > 0) return httpsUrls;
  return [
    `${DEV_PUBLIC_SAMPLE_BASE}/electronics-1.jpg`,
    `${DEV_PUBLIC_SAMPLE_BASE}/electronics-2.jpg`,
    `${DEV_PUBLIC_SAMPLE_BASE}/electronics-3.jpg`,
  ];
}

async function run() {
  const email = requireEnv(ADMIN_EMAIL, 'ADMIN_EMAIL');
  const password = requireEnv(ADMIN_PASSWORD, 'ADMIN_PASSWORD');
  const products = loadProducts();
  const imageUrls = normalizeSeedImageUrls(loadImageUrls());

  const auth = await signIn(email, password);
  console.log(`Authenticated on ${ORIGNABASE_URL} as ${auth.email}`);

  for (let i = 0; i < products.length; i += 1) {
    const product = products[i];
    const imageUrl = imageUrls[i % imageUrls.length];
    const payload = {
      title: product.title,
      description: product.description,
      priceCents: product.priceCents,
      categoryId: product.categoryId,
      categoryName: product.categoryName ?? 'Tools',
      subcategory: product.subcategory ?? 'Power Tools',
      stockQuantity: product.stockQuantity ?? 10,
      lifecycleStatus: 'active',
      isDigital: false,
      isPerishable: false,
      keywords: product.keywords ?? [],
      imageUrls: [imageUrl],
      sellerId: auth.localId,
      sellerName: 'OrignaVentures',
      sellerStripeAccountId: null,
      supplier: product.supplier ?? null,
      shipFromCity: 'Toronto',
      shipFromProvince: 'ON',
      shipFromCountry: 'CA',
    };

    const result = await callOk(
      'create_product_atomic',
      {
        productData: payload,
        testImageUrls: [imageUrl],
      },
      auth.idToken,
    );
    console.log(
      JSON.stringify({
        title: product.title,
        productId:
          (result as Record<string, unknown>)['productId'] ??
          (result as Record<string, unknown>)['id'] ??
          null,
      }),
    );
  }
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
