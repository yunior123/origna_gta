#!/usr/bin/env bun
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

import { signIn } from '../e2e/lib/api-client.js';

const ORIGNABASE_URL = process.env.ORIGNABASE_URL || 'https://api.orignagta.ca';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL;
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
const ASSET_MANIFEST_PATH = process.env.ASSET_MANIFEST_PATH || 'scripts/data/solar_product_manifest.json';
const OUTPUT_PATH =
  process.env.UPLOAD_OUTPUT_PATH || 'scripts/data/solar_product_uploaded_urls.json';

type AssetManifest = {
  slug?: string;
  imageLocalPaths: string[];
  r2ObjectKeys: string[];
};

function detectContentType(filePath: string): string {
  const lower = filePath.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

function requireEnv(value: string | undefined, name: string): string {
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function loadManifest(): AssetManifest {
  const raw = readFileSync(resolve(ASSET_MANIFEST_PATH), 'utf8');
  const manifest = JSON.parse(raw) as AssetManifest;
  if (
    !Array.isArray(manifest.imageLocalPaths) ||
    !Array.isArray(manifest.r2ObjectKeys) ||
    manifest.imageLocalPaths.length == 0 ||
    manifest.imageLocalPaths.length != manifest.r2ObjectKeys.length
  ) {
    throw new Error(
      'Asset manifest must provide matching imageLocalPaths and r2ObjectKeys arrays.',
    );
  }
  return manifest;
}

async function presignUploads(token: string, paths: string[]) {
  const response = await fetch(`${ORIGNABASE_URL}/storage/presign/upload`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({
      paths,
      ttl_secs: 3600,
    }),
  });

  const body = await response.json().catch(() => ({}));
  if (!response.ok || !Array.isArray(body?.urls)) {
    throw new Error(
      `Failed to get presigned upload URLs: ${JSON.stringify(body) || response.status}`,
    );
  }

  return body.urls as Array<{ path: string; upload_url: string }>;
}

async function uploadOne(
  localPath: string,
  uploadUrl: string,
  contentType: string,
): Promise<void> {
  const bytes = readFileSync(resolve(localPath));
  const response = await fetch(uploadUrl, {
    method: 'PUT',
    headers: {
      'Content-Type': contentType,
    },
    body: bytes,
  });
  if (!response.ok) {
    const text = await response.text().catch(() => '');
    throw new Error(
      `Upload failed for ${localPath}: ${response.status} ${text}`.trim(),
    );
  }
}

async function run() {
  const manifest = loadManifest();
  const email = requireEnv(ADMIN_EMAIL, 'ADMIN_EMAIL');
  const password = requireEnv(ADMIN_PASSWORD, 'ADMIN_PASSWORD');

  const auth = await signIn(email, password);
  const presigned = await presignUploads(auth.idToken, manifest.r2ObjectKeys);

  if (presigned.length != manifest.imageLocalPaths.length) {
    throw new Error(
      `Expected ${manifest.imageLocalPaths.length} presigned URLs, got ${presigned.length}.`,
    );
  }

  const uploadedUrls: string[] = [];
  for (let i = 0; i < manifest.imageLocalPaths.length; i += 1) {
    const localPath = manifest.imageLocalPaths[i];
    const upload = presigned[i];
    await uploadOne(localPath, upload.upload_url, detectContentType(localPath));
    uploadedUrls.push(upload.path);
    console.log(`Uploaded ${localPath} -> ${upload.path}`);
  }

  const output = {
    manifestPath: resolve(ASSET_MANIFEST_PATH),
    generatedAt: new Date().toISOString(),
    imageUrls: uploadedUrls,
  };

  writeFileSync(resolve(OUTPUT_PATH), `${JSON.stringify(output, null, 2)}\n`);
  console.log(`Wrote upload output to ${resolve(OUTPUT_PATH)}`);
  console.log(JSON.stringify(output, null, 2));
}

run().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
