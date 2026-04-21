#!/usr/bin/env bun
import { callOk, signIn } from '../e2e/lib/api-client.js';

// Configuration
const ORIGNABASE_URL = process.env.ORIGNABASE_URL || 'https://api.orignagta.ca';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;

async function run() {
  if (!ADMIN_EMAIL || !ADMIN_PASSWORD) {
    console.error("Please provide ADMIN_EMAIL and ADMIN_PASSWORD in your environment.");
    process.exit(1);
  }

  console.log(`Connecting to ${ORIGNABASE_URL}...`);
  const auth = await signIn(ADMIN_EMAIL, ADMIN_PASSWORD);
  console.log("Authenticated as admin.");

  const productData = {
    title: "10KW Hybrid Solar System - Split Phase AC120V",
    description: "Combo module for split phase AC120V 10KW Hybrid Solar System. Includes panels, inverter, and mounting hardware.",
    priceCents: 1500000, // example price: $15,000.00 CAD
    categoryId: 11, // Automotive/Hardware/Tools/Maintenance
    categoryName: "Tools",
    subcategory: "Power Tools",
    stockQuantity: 10,
    lifecycleStatus: "active",
    isDigital: false,
    isPerishable: false,
    keywords: ["solar", "hybrid", "10KW", "AC120V", "power", "system", "combo"],
    imageUrls: ["https://pub-f9698d0f50d146bcac0e2dc9eb09de57.r2.dev/dev/products/samples/electronics-1.jpg"], // REPLACE with uploaded images
    sellerId: auth.localId, // Associated with admin/company
    sellerName: "OrignaVentures",
    sellerStripeAccountId: null,
  };

  try {
    const res = await callOk('add_product', productData, auth.idToken);
    console.log("Product successfully added to production!");
    console.log(res);
  } catch (error) {
    console.error("Failed to add product:", error);
  }
}

run().catch(console.error);
