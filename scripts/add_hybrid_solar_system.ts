#!/usr/bin/env bun
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { callOk, signIn } from '../e2e/lib/api-client.js';

// Configuration
const ORIGNABASE_URL = process.env.ORIGNABASE_URL || 'https://api.orignagta.ca';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
const PRODUCT_MANIFEST_PATH =
  process.env.PRODUCT_MANIFEST_PATH || 'scripts/data/solar_product_manifest.json';
const IMAGE_URLS_JSON_PATH = process.env.IMAGE_URLS_JSON_PATH;

type ProductManifest = {
  title: string;
  description: string;
  priceCents: number;
  categoryId: number;
  categoryName?: string;
  subcategory?: string;
  stockQuantity?: number;
  lifecycleStatus?: string;
  isDigital?: boolean;
  isPerishable?: boolean;
  keywords?: string[];
  imageUrls?: string[];
  sellerName?: string;
  sellerStripeAccountId?: string | null;
  shipFromCity?: string;
  shipFromProvince?: string;
  shipFromCountry?: string;
};

function loadJsonFile(path: string) {
  return JSON.parse(readFileSync(resolve(path), 'utf8'));
}

function isAllowedImageUrl(url: string): boolean {
  return (
    /^https:\/\/pub-[^.]+\.r2\.dev\//.test(url) ||
    /^https:\/\/([a-z0-9-]+\.)?orignagta\.ca\//.test(url) ||
    /^https:\/\/([a-z0-9-]+\.)?origna\.ca\//.test(url) ||
    /^(dev\/)?products\//.test(url)
  );
}

function resolveImageUrls(manifest: ProductManifest): string[] {
  if (IMAGE_URLS_JSON_PATH) {
    const uploaded = loadJsonFile(IMAGE_URLS_JSON_PATH) as { imageUrls?: string[] };
    if (Array.isArray(uploaded.imageUrls) && uploaded.imageUrls.length > 0) {
      return uploaded.imageUrls;
    }
  }

  if (Array.isArray(manifest.imageUrls) && manifest.imageUrls.length > 0) {
    return manifest.imageUrls;
  }

  throw new Error(
    'No image URLs provided. Upload product assets first or populate imageUrls in the manifest.',
  );
}

async function run() {
  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
    console.error("Please provide ADMIN_EMAIL and ADMIN_PASSWORD in your environment.");
    process.exit(1);
  }

  console.log(`Connecting to ${ORIGNABASE_URL}...`);
  const auth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
  console.log("Authenticated as admin.");

  const manifest = loadJsonFile(PRODUCT_MANIFEST_PATH) as ProductManifest;
  const imageUrls = resolveImageUrls(manifest);
  if (imageUrls.some((url) => !isAllowedImageUrl(url))) {
    throw new Error(
      'All product image URLs must resolve to Cloudflare R2 or an Origna CDN domain.',
    );
  }

  const productData = {
    title: manifest.title,
    description: manifest.description,
    priceCents: manifest.priceCents,
    categoryId: manifest.categoryId,
    categoryName: manifest.categoryName ?? "Tools",
    subcategory: manifest.subcategory ?? "Power Tools",
    stockQuantity: manifest.stockQuantity ?? 10,
    lifecycleStatus: manifest.lifecycleStatus ?? "active",
    isDigital: manifest.isDigital ?? false,
    isPerishable: manifest.isPerishable ?? false,
    keywords: manifest.keywords ?? ["solar", "hybrid", "installation"],
    imageUrls,
    sellerId: auth.localId, // Associated with admin/company
    sellerName: manifest.sellerName ?? "OrignaVentures",
    sellerStripeAccountId: manifest.sellerStripeAccountId ?? null,
    shipFromCity: manifest.shipFromCity,
    shipFromProvince: manifest.shipFromProvince,
    shipFromCountry: manifest.shipFromCountry,
  };

  try {
    const res = await callOk(
      'create_product_atomic',
      {
        productData,
        testImageUrls: imageUrls,
      },
      auth.idToken,
    );
    console.log("Product successfully added to production!");
    console.log(res);
  } catch (error) {
    console.error("Failed to add product:", error);
  }
}

run().catch(console.error);
