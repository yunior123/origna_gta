/**
 * OrignaGTA — E2E Configuration
 * Environment-aware config for agent-browser tests.
 */

// ════════════════════════════════════════════════════════════════════
// ENVIRONMENT DETECTION
// ════════════════════════════════════════════════════════════════════

type E2EEnvironment = 'dev' | 'staging' | 'prod' | 'unknown';

function inferE2EEnvironment(targetUrl: string): E2EEnvironment {
  try {
    const host = new URL(targetUrl).hostname.toLowerCase();
    if (host === 'localhost' || host === '127.0.0.1') return 'dev';
    if (host === 'staging.orignagta.ca' || host.includes('orignagta-staging')) return 'staging';
    if (host === 'dev.orignagta.ca' || host.includes('orignagta-dev')) return 'dev';
    if (host === 'orignagta.ca' || host === 'www.orignagta.ca') return 'prod';
  } catch {
    // Leave as unknown when the target URL is malformed.
  }
  return 'unknown';
}

function deriveOrignaBaseUrl(targetEnv: E2EEnvironment): string {
  const explicit = process.env.ORIGNABASE_URL?.trim();
  if (explicit) return explicit;

  switch (targetEnv) {
    case 'prod':
      return 'https://api.orignagta.ca';
    case 'dev':
      return 'https://api.dev.orignagta.ca';
    case 'staging':
      return 'https://api.staging.orignagta.ca';
    case 'unknown':
    default:
      return '';
  }
}

// ════════════════════════════════════════════════════════════════════
// EXPORTS
// ════════════════════════════════════════════════════════════════════

export const WEB_APP_URL = process.env.E2E_TARGET_URL ?? 'https://dev.orignagta.ca';
export const TARGET_ENV = inferE2EEnvironment(WEB_APP_URL);
export const ORIGNABASE_URL = deriveOrignaBaseUrl(TARGET_ENV);
export const DEFAULT_PASS = 'REDACTED_TEST_PASSWORD';

export const STRIPE_CARD = {
  number: '4242424242424242',
  exp: '12/34',
  cvc: '123',
  name: 'Test Buyer',
  postalCode: 'M5V 3A8',
};

export const TEST_ACCOUNTS = {
  ADMIN_EMAIL: 'e2e-admin@test.origna.ca',
  ADMIN_PASS: 'REDACTED_TEST_PASSWORD',
  SELLER_EMAIL: 'e2e-seller@test.origna.ca',
  SELLER_PASS: 'REDACTED_TEST_PASSWORD',
  BUYER_EMAIL: 'e2e-buyer@test.origna.ca',
  BUYER_PASS: 'REDACTED_TEST_PASSWORD',
  BUYER2_EMAIL: 'e2e-seller@test.origna.ca',
  BUYER2_PASS: 'REDACTED_TEST_PASSWORD',
  // Aliases for compatibility with spec files
  SELLER1_EMAIL: 'e2e-seller@test.origna.ca',
  SELLER2_EMAIL: 'e2e-admin@test.origna.ca',
  BUYER1_EMAIL: 'e2e-buyer@test.origna.ca',
  BUYER3_EMAIL: 'e2e-buyer@test.origna.ca',
  SUSPENDED_EMAIL: 'e2e-buyer@test.origna.ca',
  NON_ONBOARDED_SELLER: 'e2e-buyer@test.origna.ca',
  // Real accounts — for full-flow E2E with actual email delivery
  REAL_ADMIN_EMAIL: 'yr62813@gmail.com',
  REAL_ADMIN_PASS: 'REDACTED_TEST_PASSWORD',
  REAL_SELLER_EMAIL: 'yuniorrodriguezo4601@yahoo.com',
  REAL_SELLER_PASS: 'REDACTED_TEST_PASSWORD',
  REAL_BUYER_EMAIL: 'yuniorrodriguezo460@gmail.com',
  REAL_BUYER_PASS: 'REDACTED_TEST_PASSWORD',
};

export const TEST_UIDS = {
  ADMIN: 'users:3y681c490rcvrlcm1wwz',
  SELLER: 'users:lvoqmdam21bhaxd2fjgi',
  BUYER: 'users:itdb9cyp3nu45owy4bo1',
};

// Dynamic timeouts — override via env vars for CI or local tuning
export const TIMEOUTS = {
  /** Per-test timeout (default 60s, override: E2E_TEST_TIMEOUT) */
  TEST: Number(process.env.E2E_TEST_TIMEOUT) || 60_000,
  /** Flutter semantics load (default 45s, override: E2E_FLUTTER_TIMEOUT) */
  FLUTTER: Number(process.env.E2E_FLUTTER_TIMEOUT) || 45_000,
  /** API call timeout (default 30s, override: E2E_API_TIMEOUT) */
  API: Number(process.env.E2E_API_TIMEOUT) || 30_000,
  /** Stripe checkout flow (default 60s, override: E2E_STRIPE_TIMEOUT) */
  STRIPE: Number(process.env.E2E_STRIPE_TIMEOUT) || 60_000,
};

export const TEST_PRODUCTS = {
  HIGH_STOCK: 'e2e_product_admin_seller',
  DIGITAL: 'e2e_product_test_seller',
  SELLER2: 'e2e_product_intl_seller',
  OOS: 'e2e_product_oos',
};
