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
export const DEFAULT_PASS = process.env.E2E_TEST_PASSWORD || 'REDACTED_TEST_PASSWORD';

export const STRIPE_CARD = {
  number: '4242424242424242',
  exp: '12/34',
  cvc: '123',
  name: 'Test Buyer',
  postalCode: 'M5V 3A8',
};

export const STRIPE_PM_TOKENS = {
  VISA_SUCCESS: 'pm_card_visa',
  DECLINED: 'pm_card_chargeDeclined',
  INSUFFICIENT_FUNDS: 'pm_card_chargeInsufficientFunds',
  EXPIRED: 'pm_card_chargeDeclinedExpiredCard',
  INCORRECT_CVC: 'pm_card_chargeDeclinedIncorrectCvc',
  PROCESSING_ERROR: 'pm_card_chargeDeclinedProcessingError',
  LOST: 'pm_card_chargeDeclinedLostCard',
  STOLEN: 'pm_card_chargeDeclinedStolenCard',
  THREE_DS_REQUIRED: 'pm_card_authenticationRequired',
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
  REAL_ADMIN_EMAIL: process.env.E2E_ADMIN_EMAIL || 'e2e-admin@test.origna.ca',
  REAL_ADMIN_PASS: process.env.E2E_TEST_PASSWORD || 'REDACTED_TEST_PASSWORD',
  REAL_SELLER_EMAIL: process.env.E2E_SELLER_EMAIL || 'e2e-seller@test.origna.ca',
  REAL_SELLER_PASS: process.env.E2E_TEST_PASSWORD || 'REDACTED_TEST_PASSWORD',
  REAL_BUYER_EMAIL: process.env.E2E_BUYER_EMAIL || 'e2e-buyer@test.origna.ca',
  REAL_BUYER_PASS: process.env.E2E_TEST_PASSWORD || 'REDACTED_TEST_PASSWORD',
};

export const TEST_UIDS = {
  ADMIN: 'users:c0a113i0n51l0580xrdp',
  SELLER: 'users:5mbj8y8f56fhgorydkwr',
  BUYER: 'users:db8qdbn27z2md53c0cfs',
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

// ════════════════════════════════════════════════════════════════════
// ORIGNA VENTURES
// ════════════════════════════════════════════════════════════════════

export const VENTURES_WEB_URL = process.env.VENTURES_TARGET_URL ?? 'https://orignaventures.ca';
export const VENTURES_API_BASE = process.env.VENTURES_API_URL ?? 'https://api.orignaventures.ca';

export const VENTURES_TIERS = {
  ORIGNA_CODE: { code: 'origna_code', name: 'OrignaCode', priceCents: 500_00 },
  ORIGNA_LAUNCH: { code: 'origna_launch', name: 'OrignaLaunch', priceCents: 3000_00 },
  ORIGNA_TEAM: { code: 'origna_team', name: 'OrignaTeam', priceCents: 1000_00 },
} as const;
