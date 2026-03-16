/**
 * OrignaGTA — E2E API Helpers
 * ===========================
 * Targets the deployed environment. OrignaBase is the primary backend
 * contract. Legacy Cloud Functions endpoints may still exist for explicit
 * compatibility checks, but primary helper flows must not fall back to them.
 */

import { Page } from '@playwright/test';

// ════════════════════════════════════════════════════════════════════
// CONFIGURATION — Environment-aware deployed defaults
// ════════════════════════════════════════════════════════════════════

const FIREBASE_API_KEY = 'REDACTED_SECRET';
export const WEB_APP_URL = process.env.E2E_TARGET_URL ?? 'https://dev.orignagta.ca';

type E2EEnvironment = 'dev' | 'staging' | 'prod' | 'unknown';
type BackendProvider = 'orignabase';

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

function defaultFunctionsUrl(targetEnv: E2EEnvironment): string {
  switch (targetEnv) {
    case 'staging':
      return 'https://northamerica-northeast1-orignagta-staging.cloudfunctions.net';
    case 'prod':
      return 'https://northamerica-northeast1-orignagta.cloudfunctions.net';
    case 'dev':
    case 'unknown':
    default:
      return 'https://northamerica-northeast1-orignagta-dev.cloudfunctions.net';
  }
}

function defaultProjectId(targetEnv: E2EEnvironment): string {
  switch (targetEnv) {
    case 'staging':
      return 'orignagta-staging';
    case 'prod':
      return 'orignagta';
    case 'dev':
    case 'unknown':
    default:
      return 'orignagta-dev';
  }
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

function resolveBackendProvider(_targetEnv: E2EEnvironment): BackendProvider {
  const explicit = process.env.E2E_AUTH_PROVIDER?.trim().toLowerCase();
  if (explicit === 'orignabase') {
    return explicit;
  }
  return 'orignabase';
}

const TARGET_ENV = inferE2EEnvironment(WEB_APP_URL);
const AUTH_PROVIDER = resolveBackendProvider(TARGET_ENV);

export const AUTH_URL = process.env.FIREBASE_AUTH_URL ?? 'https://identitytoolkit.googleapis.com';
export const FUNCTIONS_URL = process.env.FUNCTIONS_URL ?? defaultFunctionsUrl(TARGET_ENV);
export const ORIGNABASE_URL = deriveOrignaBaseUrl(TARGET_ENV);
export const PROJECT_ID = process.env.FIREBASE_PROJECT_ID ?? defaultProjectId(TARGET_ENV);

// Legacy export kept only for old spec imports. Direct fetches should not use it.
export const FIRESTORE_BASE = `${ORIGNABASE_URL}/graphql`;

export const DEFAULT_PASS = 'REDACTED_TEST_PASSWORD';

export const STRIPE_CARD = {
  number: '4242424242424242',
  exp: '12/34',
  cvc: '123',
  name: 'Test Buyer',
  postalCode: 'M5V 3A8',
};

// ════════════════════════════════════════════════════════════════════
// TEST ACCOUNTS (Dev OrignaBase — real accounts)
// ════════════════════════════════════════════════════════════════════

export const TEST_ACCOUNTS = {
  ADMIN_EMAIL: 'e2e-admin@test.origna.ca',         // roles: buyer+seller+admin, chargesEnabled, onboardingCompleted
  ADMIN_PASS: 'REDACTED_TEST_PASSWORD',
  SELLER_EMAIL: 'e2e-seller@test.origna.ca',       // roles: buyer+seller, chargesEnabled
  SELLER_PASS: 'REDACTED_TEST_PASSWORD',
  BUYER_EMAIL: 'e2e-buyer@test.origna.ca',         // roles: buyer
  BUYER_PASS: 'REDACTED_TEST_PASSWORD',
  BUYER2_EMAIL: 'e2e-seller@test.origna.ca',       // Seller account; also has buyer role — used for adversarial tests
  BUYER2_PASS: 'REDACTED_TEST_PASSWORD',
  // Aliases for compatibility with spec files
  SELLER1_EMAIL: 'e2e-seller@test.origna.ca',
  SELLER2_EMAIL: 'e2e-admin@test.origna.ca',       // Admin also has seller role — acts as second seller in dev
  BUYER1_EMAIL: 'e2e-buyer@test.origna.ca',
  BUYER3_EMAIL: 'e2e-buyer@test.origna.ca',        // Same as buyer1 in dev
  SUSPENDED_EMAIL: 'e2e-buyer@test.origna.ca',     // No real suspended user in dev — tests check error codes
  NON_ONBOARDED_SELLER: 'e2e-buyer@test.origna.ca', // Buyer has no seller role — acts as non-onboarded
};

export const TEST_UIDS = {
  // These must match the JWT `sub` of the corresponding e2e accounts in dev SurrealDB.
  // If the accounts are recreated, update these AND the sellerId of all e2e stable products.
  ADMIN: 'users:3y681c490rcvrlcm1wwz',
  SELLER: 'users:lvoqmdam21bhaxd2fjgi',
  BUYER: 'users:itdb9cyp3nu45owy4bo1',
};

const _orignabaseUiAccountCache = new Map<string, { email: string; password: string }>();
let _stripeCliTestApiKey: string | null | undefined;
let _stripeCliLiveApiKey: string | null | undefined;
let _orignabaseBootstrapAdminToken: string | null | undefined;

type OrignaBaseUserSummary = {
  id: string;
  email: string;
  roles?: string[];
  email_verified?: boolean;
};

function rolesForEmail(email: string): string[] {
  const normalized = email.trim().toLowerCase();
  if (normalized === TEST_ACCOUNTS.ADMIN_EMAIL.toLowerCase()) return ['buyer', 'seller', 'admin'];
  if (
    [
      TEST_ACCOUNTS.SELLER_EMAIL,
      TEST_ACCOUNTS.SELLER1_EMAIL,
      TEST_ACCOUNTS.SELLER2_EMAIL,
    ].map(v => v.toLowerCase()).includes(normalized)
  ) {
    return ['buyer', 'seller'];
  }
  return ['buyer'];
}

function uiAliasForRoles(roles: string[]): string {
  const roleTag = roles.includes('admin') ? 'admin' : roles.includes('seller') ? 'seller' : 'buyer';
  const envTag = TARGET_ENV === 'unknown' ? 'adhoc' : TARGET_ENV;
  return `e2e-${roleTag}-${envTag}-ui@test.origna.ca`;
}

function uiFallbackAliasForRoles(roles: string[]): string {
  const roleTag = roles.includes('admin') ? 'admin' : roles.includes('seller') ? 'seller' : 'buyer';
  const envTag = TARGET_ENV === 'unknown' ? 'adhoc' : TARGET_ENV;
  const nonce = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  return `e2e-${roleTag}-${envTag}-${nonce}@test.origna.ca`;
}

function isStableMappedAccount(email: string): boolean {
  const normalized = email.trim().toLowerCase();
  return [
    TEST_ACCOUNTS.ADMIN_EMAIL,
    TEST_ACCOUNTS.SELLER_EMAIL,
    TEST_ACCOUNTS.SELLER1_EMAIL,
    TEST_ACCOUNTS.SELLER2_EMAIL,
    TEST_ACCOUNTS.BUYER_EMAIL,
    TEST_ACCOUNTS.BUYER1_EMAIL,
    TEST_ACCOUNTS.BUYER2_EMAIL,
    TEST_ACCOUNTS.BUYER3_EMAIL,
    TEST_ACCOUNTS.SUSPENDED_EMAIL,
    TEST_ACCOUNTS.NON_ONBOARDED_SELLER,
  ].map(v => v.toLowerCase()).includes(normalized);
}

/**
 * Resolve the stable UI alias email for a test account without touching the account state.
 * Safe to call even when email_verified=false (unlike ensureOrignaBaseUiAccount which repairs it).
 */
export function resolveUiEmail(email: string): string {
  if (!isStableMappedAccount(email)) return email.trim().toLowerCase();
  return uiAliasForRoles(rolesForEmail(email.trim().toLowerCase()));
}

function bootstrapAdminEmail(): string {
  const explicit = process.env.E2E_ORIGNABASE_ADMIN_EMAIL?.trim();
  if (explicit) return explicit.toLowerCase();
  // e2e-admin@test.origna.ca is the canonical dev/staging admin (clean schema-compatible record)
  // e2e-admin-staging-ui@test.origna.ca has an incompatible legacy user record (500 on login)
  return 'e2e-admin@test.origna.ca';
}

function bootstrapAdminPassword(): string {
  return process.env.E2E_ORIGNABASE_ADMIN_PASS?.trim() || DEFAULT_PASS;
}

function hasRequiredRoles(actualRoles: string[] | undefined, requiredRoles: string[]): boolean {
  const actual = new Set((actualRoles ?? []).map(role => role.toLowerCase()));
  return requiredRoles.every(role => actual.has(role.toLowerCase()));
}

export async function getBootstrapAdminAccessToken(): Promise<string> {
  if (_orignabaseBootstrapAdminToken !== undefined && _orignabaseBootstrapAdminToken !== null) {
    return _orignabaseBootstrapAdminToken;
  }

  const email = bootstrapAdminEmail();
  const password = bootstrapAdminPassword();
  const loginRes = await fetchWithRetry(`${ORIGNABASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  const loginBody = await loginRes.json().catch(() => ({} as any));
  if (!loginRes.ok || !loginBody?.access_token) {
    throw new Error(
      `Bootstrap OrignaBase admin unavailable for ${email}: ${loginBody?.error?.message || loginRes.status}`,
    );
  }
  _orignabaseBootstrapAdminToken = String(loginBody.access_token);
  return _orignabaseBootstrapAdminToken;
}

async function repairOrignaBaseUiAccount(
  user: OrignaBaseUserSummary,
  roles: string[],
  desiredDisplayName: string,
): Promise<void> {
  const actualRoles = user.roles ?? [];
  const needsRepair = user.email_verified !== true || !hasRequiredRoles(actualRoles, roles);
  if (!needsRepair) {
    return;
  }

  const adminToken = await getBootstrapAdminAccessToken();
  const patchRes = await fetch(
    `${ORIGNABASE_URL}/admin/users/${encodeURIComponent(String(user.id))}`,
    {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        display_name: desiredDisplayName,
        email_verified: true,
        roles,
      }),
    },
  );
  const patchBody = await patchRes.json().catch(() => ({} as any));
  if (!patchRes.ok) {
    if (patchRes.status === 429) {
      return;
    }
    throw new Error(
      `Failed to repair OrignaBase UI account ${user.email}: ${patchBody?.error?.message || patchBody?.message || patchRes.status}`,
    );
  }
}

function readStripeCliConfigValue(key: string): string | null {
  try {
    const { readFileSync } = require('fs');
    const configPath = process.env.STRIPE_CONFIG_FILE || `${process.env.HOME}/.config/stripe/config.toml`;
    const text = readFileSync(configPath, 'utf8');
    const line = text
      .split('\n')
      .map((entry: string) => entry.trim())
      .find((entry: string) => entry.startsWith(`${key} = `));
    if (!line) return null;
    const raw = line.split('=', 2)[1]?.trim() ?? '';
    return raw.replace(/^'/, '').replace(/'$/, '').replace(/^"/, '').replace(/"$/, '');
  } catch {
    return null;
  }
}

function getStripeCliTestApiKey(): string | null {
  if (_stripeCliTestApiKey !== undefined) return _stripeCliTestApiKey;
  _stripeCliTestApiKey =
    process.env.STRIPE_SECRET_KEY ||
    readStripeCliConfigValue('test_mode_api_key');
  return _stripeCliTestApiKey || null;
}

function getStripeCliLiveApiKey(): string | null {
  if (_stripeCliLiveApiKey !== undefined) return _stripeCliLiveApiKey;
  _stripeCliLiveApiKey =
    process.env.STRIPE_LIVE_SECRET_KEY ||
    readStripeCliConfigValue('live_mode_api_key');
  return _stripeCliLiveApiKey || null;
}

async function fetchWithRetry(url: string, init: RequestInit, attempts = 4): Promise<Response> {
  // Exponential backoff for 429 rate limits — OrignaBase rate windows are 10-60s.
  const delays429 = [5_000, 10_000, 20_000, 30_000];
  let lastResponse: Response | null = null;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    const response = await fetch(url, init);
    lastResponse = response;
    if (response.status !== 429) return response;
    const wait = delays429[attempt] ?? 30_000;
    console.log(`⏳ Rate limit on ${url}, waiting ${wait / 1000}s... (attempt ${attempt + 1}/${attempts})`);
    await new Promise(resolve => setTimeout(resolve, wait));
  }
  return lastResponse!;
}

async function fetchStripeCheckoutUrl(sessionId: string): Promise<string | null> {
  const apiKey = sessionId.startsWith('cs_live_') || sessionId.startsWith('cs_live')
    ? getStripeCliLiveApiKey()
    : getStripeCliTestApiKey();
  if (!apiKey) return null;

  try {
    const response = await fetch(`https://api.stripe.com/v1/checkout/sessions/${encodeURIComponent(sessionId)}`, {
      headers: {
        Authorization: `Bearer ${apiKey}`,
      },
    });
    const body = await response.json().catch(() => ({} as any));
    const url = body?.url;
    return typeof url === 'string' && url.length > 0 ? url : null;
  } catch {
    return null;
  }
}

export async function ensureOrignaBaseUiAccount(email: string, password: string): Promise<{ email: string; password: string }> {
  const requestedEmail = email.trim().toLowerCase();
  const cacheKey = `${requestedEmail}:${password}`;
  const cached = _orignabaseUiAccountCache.get(cacheKey);
  if (cached) return cached;

  const roles = rolesForEmail(requestedEmail);
  const candidateEmails = isStableMappedAccount(requestedEmail)
    ? [uiAliasForRoles(roles), uiFallbackAliasForRoles(roles)]
    : [requestedEmail, uiFallbackAliasForRoles(roles)];
  let normalizedEmail = candidateEmails[0];
  let loginRes: Response | null = null;
  let loginBody: any = {};

  for (const candidateEmail of candidateEmails) {
    normalizedEmail = candidateEmail;
    loginRes = await fetchWithRetry(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: normalizedEmail, password }),
    });

    if (loginRes.status >= 400) {
      await fetchWithRetry(`${ORIGNABASE_URL}/auth/register`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: normalizedEmail, password }),
      }).catch(() => {});

      loginRes = await fetchWithRetry(`${ORIGNABASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: normalizedEmail, password }),
      });
    }

    loginBody = await loginRes.json().catch(() => ({} as any));
    if (loginRes.ok && loginBody?.access_token && loginBody?.user?.id) {
      break;
    }
  }

  if (!loginRes?.ok || !loginBody?.access_token || !loginBody?.user?.id) {
    throw new Error(`OrignaBase UI account unavailable for ${normalizedEmail}: ${loginBody?.error?.message || loginRes?.status}`);
  }

  const rawUserId = String(loginBody.user.id);
  const accessToken = String(loginBody.access_token);
  const displayName = normalizedEmail.split('@')[0];
  const profileRes = await fetch(`${ORIGNABASE_URL}/api/users/create-profile`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      userId: rawUserId,
      email: normalizedEmail,
      name: displayName,
      roles,
      preferredLanguage: 'en',
      marketingOptIn: false,
      consentMethod: 'signup_form',
    }),
  });
  if (!profileRes.ok) {
    const profileBody = await profileRes.json().catch(() => ({} as any));
    const profileError = String(profileBody?.error?.message || profileBody?.message || profileRes.status);
    const canReuseExistingProfile =
      profileRes.status === 409 ||
      profileRes.status === 429 ||
      /already exists|rate limit exceeded/i.test(profileError);
    if (!canReuseExistingProfile) {
      throw new Error(
        `Failed to provision OrignaBase profile for ${normalizedEmail}: ${profileError}`,
      );
    }
  }

  await repairOrignaBaseUiAccount(
    {
      id: rawUserId,
      email: normalizedEmail,
      roles: Array.isArray(loginBody?.user?.roles) ? loginBody.user.roles : [],
      email_verified: Boolean(loginBody?.user?.email_verified),
    },
    roles,
    displayName,
  );

  const resolved = { email: normalizedEmail, password };
  _orignabaseUiAccountCache.set(cacheKey, resolved);
  return resolved;
}

// ════════════════════════════════════════════════════════════════════
// FIREBASE AUTH — Sign In via REST API
// ════════════════════════════════════════════════════════════════════

export interface AuthData {
  idToken: string;
  refreshToken: string;
  localId: string;
  email: string;
  [key: string]: any;
}

// Auth token cache — avoids redundant signIn calls that hit OrignaBase quota
const _authCache = new Map<string, { data: AuthData; expiresAt: number }>();

// Disk-based token cache path (shared across all Playwright workers)
const TOKEN_CACHE_FILE = '/tmp/origna_e2e_tokens.json';

function _loadDiskTokens(): void {
  try {
    const { readFileSync } = require('fs');
    const raw = JSON.parse(readFileSync(TOKEN_CACHE_FILE, 'utf8'));
    for (const [k, v] of Object.entries(raw as Record<string, any>)) {
      if (v.expiresAt > Date.now()) _authCache.set(k, v);
    }
  } catch { /* no cache yet */ }
}

function _saveDiskTokens(): void {
  try {
    const { writeFileSync, renameSync } = require('fs');
    const obj: Record<string, any> = {};
    _authCache.forEach((v, k) => { obj[k] = v; });
    // Atomic write: write to temp file then rename to prevent multi-worker corruption
    const tmp = `${TOKEN_CACHE_FILE}.${process.pid}.tmp`;
    writeFileSync(tmp, JSON.stringify(obj));
    renameSync(tmp, TOKEN_CACHE_FILE);
  } catch { /* ignore */ }
}

_loadDiskTokens();

export function useOrignaBaseAuth(): boolean {
  return AUTH_PROVIDER === 'orignabase';
}

export type PublicAuthProviders = {
  google?: {
    enabled?: boolean;
    client_id_configured?: boolean;
    client_secret_configured?: boolean;
  };
  apple?: {
    enabled?: boolean;
    client_id_configured?: boolean;
    client_secret_configured?: boolean;
  };
  oidc?: {
    enabled?: boolean;
    client_id_configured?: boolean;
    client_secret_configured?: boolean;
  };
};

export async function getPublicConfigValue(key: string): Promise<any> {
  const response = await fetch(`${ORIGNABASE_URL}/config/${encodeURIComponent(key)}`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' },
  });
  const body = await response.json().catch(() => ({} as any));
  return body?.value;
}

export async function getAuthProviders(): Promise<PublicAuthProviders> {
  const response = await fetch(`${ORIGNABASE_URL}/auth/providers`, {
    method: 'GET',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!response.ok) {
    throw new Error(`Failed to fetch auth providers readiness: ${response.status}`);
  }
  return response.json();
}

async function signInOrignaBase(email: string, password: string): Promise<AuthData> {
  const provisioned = await ensureOrignaBaseUiAccount(email, password);
  const normalizedEmail = provisioned.email.trim().toLowerCase();
  const displayName = normalizedEmail.split('@')[0];

  let loginRes = await fetchWithRetry(`${ORIGNABASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: normalizedEmail, password }),
  });

  if (loginRes.status >= 400) {
    await fetchWithRetry(`${ORIGNABASE_URL}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: normalizedEmail, password, display_name: displayName }),
    }).catch(() => {});

    loginRes = await fetchWithRetry(`${ORIGNABASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: normalizedEmail, password }),
    });
  }

  const loginBody = await loginRes.json().catch(() => ({} as any));
  if (!loginRes.ok || !loginBody?.access_token || !loginBody?.user?.id) {
    throw new Error(`OrignaBase signIn FAILED for ${normalizedEmail}: ${loginBody?.error?.message || loginBody?.message || loginRes.status}`);
  }

  const rawUserId = String(loginBody.user.id);
  const localId = rawUserId.includes(':') ? rawUserId.split(':', 2)[1] : rawUserId;
  const reloginRes = await fetchWithRetry(`${ORIGNABASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: normalizedEmail, password }),
  });
  const reloginBody = await reloginRes.json().catch(() => loginBody);
  const accessToken = String(reloginBody?.access_token || loginBody.access_token);
  const refreshToken = String(reloginBody?.refresh_token || loginBody.refresh_token || '');

  return {
    idToken: accessToken,
    refreshToken,
    localId,
    email: normalizedEmail,
  };
}

export async function setOrignaBaseUserEmailVerified(
  email: string,
  password: string,
  emailVerified: boolean,
): Promise<void> {
  const auth = await signInOrignaBase(email, password);
  const adminToken = await getBootstrapAdminAccessToken();
  const userId = auth.localId;
  const patchRes = await fetch(
    `${ORIGNABASE_URL}/admin/users/${encodeURIComponent(userId)}`,
    {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${adminToken}`,
      },
      body: JSON.stringify({
        email_verified: emailVerified,
      }),
    },
  );
  let lastRes = patchRes;
  const delays = [5_000, 10_000, 20_000];
  for (let i = 0; !lastRes.ok && lastRes.status === 429 && i < delays.length; i++) {
    console.log(`⏳ Rate limit on PATCH email_verified for ${email}, waiting ${delays[i] / 1000}s... (retry ${i + 1}/${delays.length})`);
    await new Promise(r => setTimeout(r, delays[i]));
    lastRes = await fetch(
      `${ORIGNABASE_URL}/admin/users/${encodeURIComponent(userId)}`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${adminToken}` },
        body: JSON.stringify({ email_verified: emailVerified }),
      },
    );
  }
  const patchBody = await lastRes.json().catch(() => ({} as any));
  if (!lastRes.ok) {
    throw new Error(
      `Failed to set email verification for ${email}: ${patchBody?.error?.message || patchBody?.message || lastRes.status}`,
    );
  }
}

export async function setOrignaBaseUserTermsVersion(
  email: string,
  password: string,
  termsVersion: string,
): Promise<void> {
  // Resolve to the UI alias — same account that loginViaUi will use.
  const uiEmail = resolveUiEmail(email);
  // Use the profile update REST endpoint with the user's own token.
  // The /api/users/profile/update handler accepts termsVersion directly.
  const auth = await signInOrignaBase(uiEmail, password);
  const res = await fetch(`${ORIGNABASE_URL}/api/users/profile/update`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${auth.idToken}`,
    },
    body: JSON.stringify({ termsVersion }),
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({} as any));
    throw new Error(
      `Failed to set terms version for ${email}: ${body?.error?.message || body?.message || res.status}`,
    );
  }
}

export async function setOrignaBaseUserSuspended(
  email: string,
  password: string,
  suspended: boolean,
): Promise<void> {
  // Resolve to the UI alias — same account that loginViaUi will use.
  const uiEmail = resolveUiEmail(email);
  const auth = await signInOrignaBase(uiEmail, password);
  const adminToken = await getBootstrapAdminAccessToken();
  const ok = await writeDoc(
    `users/${auth.localId}`,
    {
      suspended,
      suspendedAt: suspended ? new Date().toISOString() : null,
      updatedAt: new Date().toISOString(),
    },
    adminToken,
    true,
  );
  if (!ok) {
    throw new Error(`Failed to set suspended=${String(suspended)} for ${email}`);
  }
}

/**
 * Sign in to OrignaBase Auth via Identity Toolkit REST API.
 * Caches tokens in memory AND on disk (shared across workers) for 50 minutes.
 */
export async function signIn(email: string, password: string = DEFAULT_PASS): Promise<AuthData> {
  const cacheKey = `${email}:${password}`;
  // Reload disk cache each call so workers share tokens
  _loadDiskTokens();
  const cached = _authCache.get(cacheKey);
  if (cached && Date.now() < cached.expiresAt) return cached.data;

  if (useOrignaBaseAuth()) {
    const data = await signInOrignaBase(email, password);
    _authCache.set(cacheKey, { data, expiresAt: Date.now() + 50 * 60_000 });
    _saveDiskTokens();
    return data;
  }

  const res = await fetch(
    `${AUTH_URL}/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password, returnSecureToken: true }),
    }
  );
  const data = await res.json() as any;

  if (!data.idToken) {
    const errMsg = data.error?.message || 'Unknown error';
    throw new Error(`signIn FAILED for ${email}: ${errMsg}`);
  }

  _authCache.set(cacheKey, { data: data as AuthData, expiresAt: Date.now() + 50 * 60_000 });
  _saveDiskTokens();
  return data as AuthData;
}


// ════════════════════════════════════════════════════════════════════
// ORIGNABASE GRAPHQL — OrignaBase-compatible helpers for E2E specs
// ════════════════════════════════════════════════════════════════════

type PathInfo = {
  collection: string;
  id?: string;
  parentId?: string;
  parentCollection?: string;
  firestorePath: string;
};

function splitPath(path: string): string[] {
  return path.split('/').map(s => s.trim()).filter(Boolean);
}

function pathInfo(path: string): PathInfo {
  const parts = splitPath(path);
  if (parts.length < 1 || parts.length % 2 !== 0) throw new Error(`Invalid document path: ${path}`);
  const collections = parts.filter((_, i) => i % 2 === 0);
  const ids = parts.filter((_, i) => i % 2 === 1);
  const collection = collections.join('__');
  const info: PathInfo = { collection, firestorePath: path };
  if (ids.length > 0) info.id = ids[ids.length - 1];
  if (collections.length > 1) {
    info.parentCollection = collections.slice(0, -1).join('__');
    info.parentId = ids[ids.length - 2];
  }
  return info;
}

function collectionPathInfo(path: string): PathInfo {
  const parts = splitPath(path);
  if (parts.length < 1 || parts.length % 2 === 0) throw new Error(`Invalid collection path: ${path}`);
  const collections = parts.filter((_, i) => i % 2 === 0);
  const ids = parts.filter((_, i) => i % 2 === 1);
  const info: PathInfo = {
    collection: collections.join('__'),
    firestorePath: path,
  };
  if (collections.length > 1) {
    info.parentCollection = collections.slice(0, -1).join('__');
    info.parentId = ids[ids.length - 1];
  }
  return info;
}

function toParentRef(info: PathInfo): string | undefined {
  if (!info.parentCollection || !info.parentId) return undefined;
  return `${info.parentCollection}:${info.parentId}`;
}

function normalizeFields(fields: Record<string, any>): Record<string, any> {
  const entries = Object.entries(fields || {});
  const looksSurrealDB =
    entries.length > 0 &&
    entries.every(([, value]) =>
      value &&
      typeof value === 'object' &&
      Object.keys(value).some(k =>
        [
          'stringValue',
          'integerValue',
          'doubleValue',
          'booleanValue',
          'nullValue',
          'timestampValue',
          'arrayValue',
          'mapValue',
        ].includes(k)
      )
    );

  if (!looksSurrealDB) return fields;

  const normalized: Record<string, any> = {};
  for (const [k, v] of entries) normalized[k] = parseVal(v);
  return normalized;
}

function wrapSurrealDBDoc(path: string, data: Record<string, any> | null): any {
  if (!data) return null;
  return {
    name: path,
    fields: toSurrealDBFields(data),
  };
}

function parseGraphQLValue(value: any): any {
  if (typeof value !== 'string') return value;
  try {
    return JSON.parse(value);
  } catch {
    return value;
  }
}

async function obGraphQL(query: string, variables: Record<string, any> = {}, token?: string): Promise<any> {
  if (!ORIGNABASE_URL) {
    return {
      ok: false,
      status: 503,
      body: { errors: [{ message: 'OrignaBase URL is not configured for this target environment' }] },
    };
  }
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${ORIGNABASE_URL}/graphql`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ query, variables }),
  });

  let body: any = {};
  try {
    body = await res.json();
  } catch {
    body = {};
  }

  return { ok: res.ok && !body?.errors, status: res.status, body };
}

/**
 * Read a document by OrignaBase-style path (e.g. "orders/abc123").
 * Under the hood this uses OrignaBase GraphQL only.
 */
export async function readDoc(path: string, token?: string): Promise<any> {
  const info = pathInfo(path);
  if (!info.id) return null;
  const query = `
    query GetDoc($collection: String!, $id: String!) {
      get(collection: $collection, id: $id)
    }
  `;
  const result = await obGraphQL(query, { collection: info.collection, id: info.id }, token);
  if (!result.ok) return null;
  const raw = parseGraphQLValue(result.body?.data?.get);
  if (!raw || typeof raw !== 'object') return null;

  if (info.parentCollection && raw.parent_id && raw.parent_id !== toParentRef(info)) {
    return null;
  }

  return wrapSurrealDBDoc(path, raw as Record<string, any>);
}

/**
 * Read and parse a SurrealDB record. Returns parsed JS object or null.
 */
export async function getDoc(path: string, token?: string): Promise<any> {
  const doc = await readDoc(path, token);
  return doc ? parseDoc(doc) : null;
}

/**
 * Write a SurrealDB record via REST API.
 * Uses PATCH. If updateMask is provided via fields, it does a partial update.
 * If no field selection is needed, it performs a set (create/overwrite).
 */
export async function writeDoc(path: string, fields: Record<string, any>, token?: string, partial = true): Promise<boolean> {
  const info = pathInfo(path);
  if (!info.id) return false;

  const incoming = normalizeFields(fields);
  const parentRef = toParentRef(info);
  const baseData = parentRef ? { ...incoming, parent_id: parentRef, parent_collection: info.parentCollection } : incoming;
  const existingDoc = partial ? (await getDoc(path, token) || {}) : {};
  // Strip SurrealDB record ID field — merging `id: 'collection:xxx'` into a SET causes SurrealDB to reject it
  const { id: _stripId, ...existingClean } = existingDoc as Record<string, any>;
  const finalData = partial ? { ...existingClean, ...baseData } : baseData;

  const mutation = `
    mutation SetDoc($collection: String!, $id: String!, $data: JSON!) {
      set(collection: $collection, id: $id, data: $data)
    }
  `;
  const result = await obGraphQL(mutation, {
    collection: info.collection,
    id: info.id,
    data: finalData,
  }, token);
  return result.ok;
}

/**
 * Delete a SurrealDB record via REST API.
 */
export async function deleteDoc(path: string, token?: string): Promise<boolean> {
  const info = pathInfo(path);
  if (!info.id) return false;
  const mutation = `
    mutation DeleteDoc($collection: String!, $id: String!) {
      delete(collection: $collection, id: $id)
    }
  `;
  const result = await obGraphQL(mutation, { collection: info.collection, id: info.id }, token);
  return result.ok;
}

/**
 * List all documents in a SurrealDB collection path (REST list endpoint).
 * Returns an array of parsed document objects. Returns [] if collection is empty.
 */
export async function listCollection(collectionPath: string, token?: string): Promise<any[]> {
  const info = collectionPathInfo(collectionPath);
  const filters = toParentRef(info) ? { parent_id: { _eq: toParentRef(info) } } : {};
  const query = `
    query ListDocs($collection: String!, $filters: JSON) {
      list(collection: $collection, filters: $filters, limit: 200)
    }
  `;
  const result = await obGraphQL(query, { collection: info.collection, filters }, token);
  if (!result.ok) return [];
  const raw = parseGraphQLValue(result.body?.data?.list);
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((doc: any) => doc && typeof doc === 'object')
    .map((doc: any) => {
      const { id, _id, _rev, _created, _updated, ...rest } = doc;
      return id ? { id, ...rest } : rest;
    });
}

// ════════════════════════════════════════════════════════════════════
// FIRESTORE VALUE CONVERSION
// ════════════════════════════════════════════════════════════════════

export function parseVal(v: any): any {
  if (!v) return null;
  if (v.stringValue !== undefined) return v.stringValue;
  if (v.integerValue !== undefined) return parseInt(v.integerValue);
  if (v.doubleValue !== undefined) return v.doubleValue;
  if (v.booleanValue !== undefined) return v.booleanValue;
  if (v.nullValue !== undefined) return null;
  if (v.timestampValue) return v.timestampValue;
  if (v.arrayValue) return (v.arrayValue.values || []).map(parseVal);
  if (v.mapValue) {
    const o: Record<string, any> = {};
    for (const [k, val] of Object.entries((v.mapValue.fields || {}) as Record<string, any>)) {
      o[k] = parseVal(val);
    }
    return o;
  }
  return v;
}

export function parseDoc(doc: any): any {
  if (!doc?.fields) return null;
  const r: Record<string, any> = {};
  for (const [k, v] of Object.entries(doc.fields as Record<string, any>)) {
    r[k] = parseVal(v);
  }
  return r;
}

export function toSurrealDBFields(obj: Record<string, any>): any {
  const f: Record<string, any> = {};
  for (const [k, v] of Object.entries(obj)) f[k] = toFsVal(v);
  return f;
}

export function toFsVal(v: any): any {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'string') return { stringValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toFsVal) } };
  if (typeof v === 'object') return { mapValue: { fields: toSurrealDBFields(v) } };
  return { stringValue: String(v) };
}

// ════════════════════════════════════════════════════════════════════
// FIREBASE FUNCTIONS — Callable Invocation (deployed functions)
// ════════════════════════════════════════════════════════════════════

/**
 * Call a OrignaBase Callable Function on the deployed dev environment.
 * Returns the raw response body.
 */
/**
 * Call a callable function through the OrignaBase-compatible routing table.
 * Primary helper flows fail closed when a function has not been ported.
 */
export async function callCallable(fn: string, data: any, token: string, timeoutMs = 20_000): Promise<any> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);

  function decodeJwtPayload(jwt: string): any {
    try {
      const [, payload] = jwt.split('.');
      if (!payload) return {};
      const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
      const pad = normalized.length % 4 === 0 ? '' : '='.repeat(4 - (normalized.length % 4));
      return JSON.parse(Buffer.from(`${normalized}${pad}`, 'base64').toString('utf8'));
    } catch {
      return {};
    }
  }

  function tokenUserId(jwt: string): string | undefined {
    const payload = decodeJwtPayload(jwt);
    return payload.user_id || payload.sub || payload.uid;
  }

  function remapSort(sortBy?: string): string | undefined {
    switch (sortBy) {
      case 'price_asc':
      case 'priceLowToHigh':
        return 'priceCents';
      case 'price_desc':
      case 'priceHighToLow':
        return 'priceCents';
      case 'newest':
      case 'relevance':
        return 'createdAt';
      default:
        return undefined;
    }
  }

  function portedRequest(fnName: string, payload: any): { path: string; body: any } | null {
    const userId = tokenUserId(token);
    switch (fnName) {
      case 'create_checkout_session': {
        // Strip userId from body — OrignaBase derives user identity from the JWT.
        // Sending the short-form uid causes "Authorization denied: Cannot act on another user".
        const { userId: _uid, ...checkoutRest } = payload ?? {};
        return { path: '/api/checkout/session', body: checkoutRest };
      }
      case 'get_user_profile':
        return { path: '/api/users/profile/get', body: { userId } };
      case 'update_user_profile':
        return { path: '/api/users/profile/update', body: { userId, ...payload } };
      case 'create_user_profile':
        return { path: '/api/users/create-profile', body: payload };
      case 'update_email_consent':
        return {
          path: '/api/users/email-consent',
          body: {
            userId,
            consent: Boolean(payload?.consent ?? payload?.emailConsent),
          },
        };
      case 'delete_account':
        return { path: '/api/auth/delete-account', body: payload };
      case 'submit_rating':
        return { path: '/api/products/submit-rating', body: payload };
      case 'ask_question':
        return { path: '/api/products/questions/ask', body: { userId, ...payload } };
      case 'answer_question':
        return { path: '/api/products/questions/answer', body: { userId, ...payload } };
      case 'vote_review_helpful':
        return { path: '/api/products/review-vote', body: { userId, ...payload } };
      case 'get_seller_metrics':
        // seller_metrics is a cron-computed collection — use GraphQL list
        return {
          path: '/graphql',
          body: {
            query: `query ListDocs($collection: String!, $filters: JSON) { list(collection: $collection, filters: $filters, limit: 50) }`,
            variables: { collection: 'seller_metrics', filters: { sellerId: { _eq: userId } } },
          },
        };
      case 'update_notification_preferences':
        return { path: '/api/users/notification-preferences', body: { userId, ...payload } };
      case 'add_buyer_address':
        return {
          path: '/api/users/address/add',
          body: {
            userId,
            street: payload?.street,
            apartment: payload?.apartment,
            city: payload?.city,
            province: payload?.province ?? payload?.state,
            postalCode: payload?.postalCode,
            country: payload?.country,
            phoneNumber: payload?.phoneNumber,
            label: payload?.label,
            isDefault: payload?.isDefault ?? false,
          },
        };
      case 'update_buyer_address':
        return {
          path: '/api/users/address/update',
          body: {
            userId,
            addressId: payload?.addressId,
            street: payload?.street,
            apartment: payload?.apartment,
            city: payload?.city,
            province: payload?.province ?? payload?.state,
            postalCode: payload?.postalCode,
            country: payload?.country,
            phoneNumber: payload?.phoneNumber,
            label: payload?.label,
            isDefault: payload?.isDefault,
          },
        };
      case 'delete_buyer_address':
        return {
          path: '/api/users/address/delete',
          body: {
            userId,
            addressId: payload?.addressId,
          },
        };
      case 'set_default_buyer_address':
        return {
          path: '/api/users/address/set-default',
          body: {
            userId,
            addressId: payload?.addressId,
          },
        };
      case 'get_mail_logs':
      case 'e2e_get_mail_logs':
        return { path: '/api/admin/mail-logs', body: payload };
      case 'get_products_paginated':
        return {
          path: '/api/products/list',
          body: {
            page: payload?.page ?? 1,
            limit: payload?.limit ?? 20,
            category: payload?.category,
            subcategory: payload?.subcategory,
            sellerId: payload?.sellerId,
            orderBy: remapSort(payload?.sortBy) ?? payload?.orderBy,
            orderDirection:
              payload?.sortBy === 'price_asc'
                ? 'asc'
                : payload?.sortBy === 'price_desc'
                  ? 'desc'
                  : (payload?.orderDirection ?? 'desc'),
            startAfter: payload?.startAfter,
            minPriceCents: payload?.minPriceCents,
            maxPriceCents: payload?.maxPriceCents,
          },
        };
      case 'get_seller_products_paginated':
        return {
          path: '/api/products/seller-list',
          body: {
            sellerId: payload?.sellerId ?? userId,
            page: payload?.page ?? 1,
            limit: payload?.limit ?? 20,
            startAfter: payload?.startAfter,
            includeInactive: payload?.includeInactive ?? false,
          },
        };
      case 'create_product_atomic': {
        if (!userId) return null;
        const {
          productData,
          testImageUrls,
          imageUrls,
          shippingConfig,
          ...rest
        } = payload || {};
        const source = productData && typeof productData === 'object'
          ? { ...productData, ...rest }
          : rest;
        return {
          path: '/api/products/create-atomic',
          body: {
            userId,
            productData: {
              ...source,
              title: source.title ?? source.name,
              name: source.name ?? source.title,
              categoryId: source.categoryId != null ? Number(source.categoryId) : source.categoryId,
              priceCents:
                source.priceCents ??
                (typeof source.price === 'number' ? Math.round(source.price * 100) : undefined),
              lifecycleStatus: source.lifecycleStatus ?? 'active',
              shippingConfig: shippingConfig ?? source.shippingConfig,
            },
            testImageUrls: testImageUrls ?? imageUrls ?? [],
          },
        };
      }
      case 'update_product': {
        if (!userId) return null;
        const { productId, userId: _ignored, ...productData } = payload || {};
        return {
          path: '/api/products/update',
          body: {
            productId,
            userId,
            productData,
          },
        };
      }
      case 'delete_product':
        return {
          path: '/api/products/delete',
          body: {
            productId: payload?.productId,
            userId,
          },
        };
      case 'bulk_update_products':
        return {
          path: '/api/products/bulk-update',
          body: {
            userId,
            productIds: payload?.productIds ?? [],
            action: payload?.action,
          },
        };
      case 'admin_approve_product':
        return {
          path: '/api/admin/approve-product',
          body: {
            adminId: userId,
            productId: payload?.productId,
          },
        };
      case 'toggle_favorite':
        return {
          path: '/api/products/toggle-favorite',
          body: {
            productId: payload?.productId,
            userId,
          },
        };
      case 'update_order_status':
        return {
          path: '/api/orders/update-status',
          body: {
            orderId: payload?.orderId,
            newStatus: payload?.newStatus,
            userId,
            trackingNumber: payload?.trackingNumber,
            carrier: payload?.carrier,
          },
        };
      case 'confirm_item_receipt':
        return {
          path: '/api/orders/confirm-receipt',
          body: {
            orderId: payload?.orderId,
            productId: payload?.productId ?? payload?.cartItemId ?? '',
            userId,
          },
        };
      case 'cancel_order':
        return {
          path: '/api/orders/cancel',
          body: {
            orderId: payload?.orderId,
            userId,
          },
        };
      case 'create_return_request':
        return {
          path: '/api/returns/create',
          body: {
            orderId: payload?.orderId,
            productId: payload?.productId ?? payload?.cartItemId ?? '',
            userId,
            returnReason: payload?.returnReason ?? payload?.reason,
          },
        };
      case 'approve_return_request':
        return {
          path: '/api/returns/approve',
          body: {
            returnId: payload?.returnId ?? payload?.orderId,
            userId,
            action: payload?.action ?? 'approve',
            returnTrackingNumber: payload?.returnTrackingNumber,
            returnAdminNote: payload?.returnAdminNote ?? payload?.adminNote,
          },
        };
      case 'activate_license':
        return { path: '/api/digital/activate-license', body: { userId, ...payload } };
      case 'e2e_seed_license':
        return { path: '/api/admin/e2e/seed-license', body: { adminId: userId, ...payload } };
      case 'admin_create_coupon':
        return { path: '/api/admin/create-coupon', body: { adminId: userId, ...payload } };
      case 'admin_delete_product_question':
        return { path: '/api/admin/delete-question', body: { adminId: userId, questionId: payload?.questionId } };
      case 'admin_delete_product_rating':
        return { path: '/api/admin/delete-rating', body: { adminId: userId, ratingId: payload?.ratingId } };
      case 'admin_delete_review':
        return { path: '/api/admin/delete-review', body: { adminId: userId, reviewId: payload?.reviewId } };
      case 'admin_flag_review':
        return { path: '/api/admin/flag-review', body: { adminId: userId, reviewId: payload?.reviewId, reason: payload?.reason } };
      case 'admin_get_reviews':
        return { path: '/api/admin/reviews', body: { adminId: userId, ...payload } };
      case 'admin_get_users':
        return { path: '/api/admin/users', body: { adminId: userId, ...payload } };
      case 'admin_mfa_enroll':
        return { path: '/api/admin/mfa-enroll', body: { adminId: userId, ...payload } };
      case 'admin_mfa_verify':
        return { path: '/api/admin/mfa-verify', body: { adminId: userId, ...payload } };
      case 'admin_mfa_verify_backup':
        return { path: '/api/admin/mfa-verify-backup', body: { adminId: userId, ...payload } };
      case 'admin_refund_order':
        return { path: '/api/admin/refund-order', body: { adminId: userId, orderId: payload?.orderId, reason: payload?.reason } };
      case 'admin_reject_product':
        return { path: '/api/admin/reject-product', body: { adminId: userId, productId: payload?.productId, reason: payload?.reason } };
      case 'admin_suspend_user':
        return { path: '/api/admin/suspend-user', body: { adminId: userId, targetUserId: payload?.userId ?? payload?.targetUserId, reason: payload?.reason } };
      case 'admin_update_product_stock':
        return { path: '/api/admin/update-stock', body: { adminId: userId, productId: payload?.productId, quantity: payload?.quantity } };
      case 'answer_product_question':
        return { path: '/api/qa/answer', body: { userId, questionId: payload?.questionId, answer: payload?.answer } };
      case 'answer_review':
        return { path: '/api/products/answer-review', body: { userId, reviewId: payload?.reviewId, answer: payload?.answer } };
      case 'apply_coupon':
        return { path: '/api/checkout/apply-coupon', body: { userId, couponCode: payload?.couponCode } };
      case 'approve_shipping_cost':
        return { path: '/api/shipping/approve', body: { userId, orderId: payload?.orderId, shippingCost: payload?.shippingCost } };
      case 'ask_product_question':
        return { path: '/api/qa/ask', body: { userId, productId: payload?.productId, question: payload?.question } };
      case 'calculate_shipping_cost':
        return { path: '/api/shipping/calculate', body: { ...payload } };
      case 'cancel_subscription':
        return { path: '/api/subscriptions/cancel', body: { userId, subscriptionId: payload?.subscriptionId } };
      case 'capture_payment':
        return { path: '/api/payments/capture', body: { userId, paymentIntentId: payload?.paymentIntentId } };
      case 'cleanup_fcm_token':
        return { path: '/api/users/cleanup-fcm-token', body: { userId } };
      case 'configure_algolia':
        return { path: '/api/admin/configure-algolia', body: { adminId: userId } };
      case 'create_account_link':
        return { path: '/api/connect/account-link', body: { userId } };
      case 'create_connect_account':
        return { path: '/api/connect/create-account', body: { userId } };
      case 'create_stripe_login_link':
        // No dedicated endpoint — use connect account-link as fallback
        return { path: '/api/connect/account-link', body: { userId } };
      case 'create_subscription':
        return { path: '/api/subscriptions/create', body: { userId, ...payload } };
      case 'create_warehouse':
        return { path: '/api/warehouses/create', body: { userId, ...payload } };
      case 'deactivate_license':
        return { path: '/api/digital/deactivate-license', body: { userId, ...payload } };
      case 'deactivate_supplier_platform':
        return { path: '/api/admin/deactivate-supplier-platform', body: { userId } };
      case 'delete_message':
        return { path: '/api/chat/delete-message', body: { userId, messageId: payload?.messageId } };
      case 'delete_product_images':
        return { path: '/api/products/delete-images', body: { userId, productId: payload?.productId, imageUrls: payload?.imageUrls } };
      case 'delete_warehouse':
        return { path: '/api/warehouses/delete', body: { userId, warehouseId: payload?.warehouseId } };
      case 'export_my_data':
        return { path: '/api/admin/export-data', body: { userId } };
      case 'generate_book_download_session':
        return { path: '/api/digital/book-download', body: { userId, productId: payload?.productId } };
      case 'generate_software_download_session':
        return { path: '/api/digital/software-download', body: { userId, productId: payload?.productId } };
      case 'get_address_suggestions':
        return { path: '/api/addresses/suggestions', body: { query: payload?.query } };
      case 'get_chat_threads':
        return { path: '/api/chat/threads', body: { userId, ...payload } };
      case 'get_connect_account_status':
        return { path: '/api/connect/status', body: { userId } };
      case 'get_or_create_chat':
        return { path: '/api/chat/get-or-create', body: {
          userId,
          otherUserId: payload?.otherUserId ?? payload?.other_user_id ?? payload?.participantId,
          other_user_id: payload?.otherUserId ?? payload?.other_user_id ?? payload?.participantId,
          // product_id required by OrignaBase endpoint before premium gate check is reached
          product_id: payload?.productId ?? payload?.product_id ?? null,
        }};
      case 'get_order_detail': {
        // No REST endpoint — use GraphQL get
        const rawOid = String(payload?.orderId ?? '');
        const oid = rawOid.includes(':') ? rawOid.split(':', 2)[1] : rawOid;
        return {
          path: '/graphql',
          body: {
            query: `query GetDoc($collection: String!, $id: String!) { get(collection: $collection, id: $id) }`,
            variables: { collection: 'orders', id: oid },
          },
        };
      }
      case 'get_orders': {
        // No REST endpoint — use GraphQL list with buyerId filter (field is 'buyerId' in SurrealDB)
        const filters: Record<string, any> = { buyerId: { _eq: userId } };
        if (payload?.status) {
          const s = String(payload.status).toLowerCase();
          if (s === 'completed' || s === 'delivered') {
            filters.status = { _in: ['delivered', 'DELIVERED', 'completed', 'COMPLETED'] };
          } else if (s === 'cancelled' || s === 'canceled') {
            filters.status = { _in: ['cancelled', 'CANCELLED', 'canceled'] };
          } else {
            filters.status = { _eq: payload.status };
          }
        }
        return {
          path: '/graphql',
          body: {
            query: `query ListOrders($collection: String!, $filters: JSON, $limit: Int) { list(collection: $collection, filters: $filters, limit: $limit) }`,
            variables: { collection: 'orders', filters, limit: payload?.limit ?? 50 },
          },
        };
      }
      case 'get_payment_providers':
        return { path: '/api/payments/providers/list', body: { ...payload } };
      case 'get_product_questions':
        return { path: '/api/products/questions/list', body: { productId: payload?.productId, ...payload } };
      case 'get_product_ratings_paginated':
        return { path: '/api/products/ratings', body: { productId: payload?.productId, page: payload?.page ?? 1, limit: payload?.limit ?? 20 } };
      case 'get_provider_status':
        return { path: '/api/payments/providers/status', body: { providerId: payload?.providerId } };
      case 'get_seller_warehouses':
        return { path: '/api/warehouses/list', body: { userId, ...payload } };
      case 'get_subscription_status':
        return { path: '/api/subscriptions/status', body: { userId, subscriptionId: payload?.subscriptionId } };
      case 'mark_messages_read':
        return { path: '/api/chat/mark-read', body: { userId, messageIds: payload?.messageIds } };
      case 'reactivate_subscription':
        return { path: '/api/subscriptions/reactivate', body: { userId, subscriptionId: payload?.subscriptionId } };
      case 'refund_order_item':
        return { path: '/api/orders/refund-item', body: { userId, orderId: payload?.orderId, itemId: payload?.itemId } };
      case 'reject_return_request':
        return { path: '/api/returns/reject', body: { userId, returnId: payload?.returnId } };
      case 'report_message':
        return { path: '/api/chat/report', body: { userId, messageId: payload?.messageId, reason: payload?.reason } };
      case 'search_products':
        return { path: '/api/products/search', body: { ...payload } };
      case 'send_chat_message':
        return { path: '/api/chat/send', body: { userId, threadId: payload?.threadId, message: payload?.message } };
      case 'send_message':
        return { path: '/api/chat/send', body: { userId, ...payload } };
      case 'start_chat_thread':
        return { path: '/api/chat/start', body: { userId, participantId: payload?.participantId } };
      case 'submit_product_rating':
        return { path: '/api/products/submit-rating', body: { userId, productId: payload?.productId, orderId: payload?.orderId, rating: payload?.rating, review: payload?.review } };
      case 'submit_product_rating_atomic':
        return { path: '/api/products/submit-rating-atomic', body: { userId, productId: payload?.productId, rating: payload?.rating, review: payload?.review } };
      case 'subscribe_stock_notification':
        return { path: '/api/products/stock-notify/subscribe', body: { userId, productId: payload?.productId, variantKey: payload?.variantKey } };
      case 'suspend_seller':
        return { path: '/api/admin/suspend-seller', body: { adminId: userId, sellerId: payload?.sellerId, reason: payload?.reason } };
      case 'unsubscribe_email':
        return { path: '/api/admin/unsubscribe-email', body: { email: payload?.email, token: payload?.token } };
      case 'unsubscribe_stock_notification':
        return { path: '/api/products/stock-notify/unsubscribe', body: { userId, productId: payload?.productId, variantKey: payload?.variantKey } };
      case 'unsuspend_seller':
        return { path: '/api/admin/unsuspend-seller', body: { adminId: userId, sellerId: payload?.sellerId } };
      case 'update_item_status':
        return { path: '/api/orders/update-item-status', body: { userId, orderId: payload?.orderId, productId: payload?.productId ?? payload?.itemId, newStatus: payload?.newStatus ?? payload?.status, trackingNumber: payload?.trackingNumber, carrier: payload?.carrier } };
      case 'update_payment_provider':
        return { path: '/api/payments/update-provider', body: { userId, ...payload } };
      case 'update_shipping_cost':
        return { path: '/api/orders/update-shipping', body: { userId, ...payload } };
      case 'update_user_roles':
        return { path: '/api/admin/update-roles', body: { adminId: userId, targetUserId: payload?.userId ?? payload?.targetUserId, roles: payload?.roles } };
      case 'update_warehouse':
        return { path: '/api/warehouses/update', body: { userId, warehouseId: payload?.warehouseId, ...payload } };
      case 'upload_product_images':
        return { path: '/api/products/upload-images', body: { userId, productId: payload?.productId, imageUrls: payload?.imageUrls } };
      case 'add_to_cart':
        return { path: '/api/cart/add', body: { userId, productId: payload?.productId, quantity: payload?.quantity ?? 1 } };
      case 'remove_from_cart':
        return { path: '/api/cart/remove', body: { userId, productId: payload?.productId } };
      case 'get_cart':
        return { path: '/api/cart/get', body: { userId } };
      case 'clear_cart':
        return { path: '/api/cart/clear', body: { userId } };
      case 'update_cart_quantity':
        return { path: '/api/cart/update', body: { userId, productId: payload?.productId, quantity: payload?.quantity } };
      case 'verify_cart_prices':
        return { path: '/api/cart/verify-prices', body: { userId, cartItems: payload?.cartItems } };
      case 'verify_license':
        return { path: '/api/digital/verify-license', body: { licenseKey: payload?.licenseKey, email: payload?.email } };

      default:
        return null;
    }
  }

  async function normalizePortedResponse(fnName: string, body: any): Promise<any> {
    switch (fnName) {
      case 'create_checkout_session': {
        const sessionId = body?.sessionId ?? body?.session_id ?? null;
        const checkoutUrl =
          body?.checkoutUrl ??
          body?.checkout_url ??
          body?.url ??
          (sessionId ? await fetchStripeCheckoutUrl(sessionId) : null);
        return {
          ...body,
          sessionId,
          checkoutUrl,
        };
      }
      case 'get_orders': {
        // GraphQL list response: { data: { list: [...] } } or already parsed
        const rawList = body?.data?.list ?? body?.orders ?? [];
        const orders = Array.isArray(rawList) ? rawList : (typeof rawList === 'string' ? JSON.parse(rawList) : []);
        return { success: true, orders };
      }
      case 'get_order_detail': {
        // GraphQL get response: { data: { get: {...} } }
        const order = body?.data?.get ?? body;
        return { success: true, ...order };
      }
      case 'get_connect_account_status':
        // Normalize accountId → stripeAccountId for test compatibility
        return {
          ...body,
          stripeAccountId: body?.stripeAccountId ?? body?.accountId ?? body?.account_id,
          onboardingCompleted: body?.onboardingCompleted ?? body?.onboarding_completed ?? false,
          chargesEnabled: body?.chargesEnabled ?? body?.charges_enabled ?? false,
          payoutsEnabled: body?.payoutsEnabled ?? body?.payouts_enabled ?? false,
        };
      case 'get_seller_metrics': {
        // GraphQL list response for seller_metrics collection
        const rawMetrics = body?.data?.list ?? [];
        const metrics = Array.isArray(rawMetrics) ? rawMetrics : [];
        return { success: true, metrics };
      }
      case 'get_products_paginated':
      case 'get_seller_products_paginated':
        return {
          success: true,
          products: Array.isArray(body?.products) ? body.products : [],
          nextCursor: body?.nextCursor ?? body?.next_cursor ?? null,
          hasMore: Boolean(body?.hasMore ?? body?.has_more),
          totalFetched: body?.totalFetched ?? body?.total_fetched ?? 0,
        };
      case 'toggle_favorite':
        // Backend returns { success, favorite } — normalize to { success, favorited }
        // so callers can rely on the stable `favorited` field name.
        return {
          success: Boolean(body?.success),
          favorited: body?.favorited ?? body?.favorite ?? false,
        };
      default:
        return body;
    }
  }

  const usePrimaryBackend = useOrignaBaseAuth();
  if (usePrimaryBackend && !ORIGNABASE_URL) {
    return {
      error: {
        message: `ORIGNABASE_URL is required for primary E2E backend calls (${fn})`,
        status: 'FAILED_PRECONDITION',
      },
    };
  }

  const ported = usePrimaryBackend ? portedRequest(fn, data) : null;
  if (usePrimaryBackend && !ported) {
    return {
      error: {
        message: `Primary E2E helper has no OrignaBase route for ${fn}. Add a portedRequest mapping instead of falling back to Cloud Functions.`,
        status: 'FAILED_PRECONDITION',
      },
    };
  }

  const url = ported
    ? `${ORIGNABASE_URL}${ported.path}`
    : `${FUNCTIONS_URL}/${fn}`;

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: JSON.stringify(ported ? ported.body : { data }),
      signal: controller.signal,
    });
    const text = await res.text();
    try {
      const body = JSON.parse(text);
      if (!res.ok) {
        const rawErr = body?.error ?? { code: res.status, status: res.status, message: body?.message || text.substring(0, 200) };
        // Normalize numeric HTTP status codes to OrignaBase-style string codes
        const normalizedCode = (() => {
          const c = rawErr.code ?? res.status;
          if (typeof c === 'string' && isNaN(Number(c))) return c; // already a string code
          const n = typeof c === 'number' ? c : Number(c);
          if (n === 401) return 'unauthenticated';
          if (n === 403) return 'permission-denied';
          if (n === 404) return 'not-found';
          if (n === 400 || n === 422) return 'invalid-argument';
          if (n === 409) return 'already-exists';
          if (n === 429) return 'resource-exhausted';
          if (n >= 500) return 'internal';
          return String(c);
        })();
        return { error: { ...rawErr, code: normalizedCode } };
      }
      if (ported) {
        return await normalizePortedResponse(fn, body);
      }
      // OrignaBase returns { result: ... } for compatibility, or raw JSON
      return body.data !== undefined ? { result: body.data } : body;
    } catch {
      return { error: { message: `Non-JSON response (${res.status}): ${text.substring(0, 200)}`, status: res.status >= 400 ? 'NOT_FOUND' : 'INTERNAL' } };
    }
  } catch (err: any) {
    if (err.name === 'AbortError') {
      return { error: { message: `Request timeout after ${timeoutMs}ms for ${fn}`, status: 'DEADLINE_EXCEEDED' } };
    }
    return { error: { message: err.message || String(err), status: 'INTERNAL' } };
  } finally {
    clearTimeout(timer);
  }
}

/**
 * Call a callable function and throw if it returns an error.
 * Auto-retries on transient server errors (cold start 500s); does NOT block
 * on rate-limit errors — those fail fast so tests don't hang.
 */
export async function callOk(fn: string, data: any, token: string): Promise<any> {
  const MAX_ATTEMPTS = 7;
  // Exponential backoff for rate limits: 15, 30, 60, 90, 90, 90s
  const RATE_LIMIT_WAITS = [15_000, 30_000, 60_000, 90_000, 90_000, 90_000];
  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const body = await callCallable(fn, data, token);
    if (body.error) {
      const status = body.error.status;
      // Retry on transient 500s (cold start) and 429s (rate limit)
      if (attempt < MAX_ATTEMPTS - 1) {
        const errMsg = (body.error.message || '');
        const is429 = status === 429 || errMsg.includes('429') || errMsg.toLowerCase().includes('too many') || errMsg.toLowerCase().includes('rate limit') || errMsg.toLowerCase().includes('duplicate order');
        const is500 = status === 500;
        if (is500 || is429) {
          const wait = is429 ? (RATE_LIMIT_WAITS[attempt] ?? 90_000) : 5_000;
          console.log(`⏳ ${is429 ? 'Rate limit' : 'Server error'} on ${fn}, waiting ${wait / 1000}s... (attempt ${attempt + 1}/${MAX_ATTEMPTS})`);
          await new Promise(r => setTimeout(r, wait));
          continue;
        }
      }
      throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
    }
    return body.result || body;
  }
  throw new Error(`${fn} failed after ${MAX_ATTEMPTS} retries`);
}

/**
 * Checks if an email was sent to the given address by querying _mail_logs via the admin callable function.
 * E2E tests can use this to verify emails without actually sending them via Mailjet.
 */
export async function verifyEmailSent(email: string, adminToken?: string): Promise<any[]> {
  let token = adminToken;
  if (!token) {
    const auth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    token = auth.idToken;
  }
  const res = await callOk('e2e_get_mail_logs', { to: email }, token);
  return res.logs || [];
}

/**
 * Normalize OrignaBase/gRPC error codes to OrignaBase SDK style.
 */
function normalizeErrorCode(error: any): { code: string; message: string } {
  const STATUS_TO_CODE: Record<string, string> = {
    'PERMISSION_DENIED': 'permission-denied',
    'FAILED_PRECONDITION': 'failed-precondition',
    'NOT_FOUND': 'not-found',
    'UNAUTHENTICATED': 'unauthenticated',
    'INVALID_ARGUMENT': 'invalid-argument',
    'ALREADY_EXISTS': 'already-exists',
    'RESOURCE_EXHAUSTED': 'resource-exhausted',
    'CANCELLED': 'cancelled',
    'UNAVAILABLE': 'unavailable',
    'INTERNAL': 'internal',
    'DEADLINE_EXCEEDED': 'deadline-exceeded',
    'UNIMPLEMENTED': 'unimplemented',
    'OUT_OF_RANGE': 'out-of-range',
    'DATA_LOSS': 'data-loss',
    'ABORTED': 'aborted',
  };
  const HTTP_TO_CODE: Record<number, string> = {
    400: 'invalid-argument',
    401: 'unauthenticated',
    403: 'permission-denied',
    404: 'not-found',
    405: 'unimplemented',
    409: 'already-exists',
    410: 'not-found',
    422: 'invalid-argument',
    429: 'resource-exhausted',
    500: 'internal',
    502: 'unavailable',
    503: 'unavailable',
    504: 'deadline-exceeded',
  };
  // OrignaBase (Rust) may return { "code": "permission_denied", "message": "..." }
  // Extract the code from the body first, then fall back to status code.
  const bodyCode = error.code;
  const rawCode = typeof bodyCode === 'string' && isNaN(Number(bodyCode))
    ? bodyCode
    : (bodyCode ?? error.status);
  const code = typeof rawCode === 'number'
    ? (HTTP_TO_CODE[rawCode] ?? String(rawCode))
    : (STATUS_TO_CODE[rawCode] ?? rawCode?.toLowerCase()?.replace(/_/g, '-') ?? 'unknown');
  return { code, message: error.message || error.details || '' };
}

/**
 * Call a callable function expecting it to fail.
 * Returns normalized error { code, message }.
 */
export async function callExpectError(fn: string, data: any, token: string): Promise<{ code: string; message: string }> {
  const body = await callCallable(fn, data, token);
  if (body.error) return normalizeErrorCode(body.error);
  if (body.result?.error) return normalizeErrorCode(body.result.error);
  return {
    code: 'unexpected-success',
    message: `Expected ${fn} to fail but it succeeded: ${JSON.stringify(body)}`,
  };
}

// ════════════════════════════════════════════════════════════════════
// CHECKOUT HELPERS — Build payloads from live SurrealDB data
// ════════════════════════════════════════════════════════════════════

/**
 * Build a valid checkout payload from live SurrealDB product + buyer data.
 * Reads product and buyer docs to construct the payload.
 */
export async function buildCheckoutPayload(
  buyerUid: string,
  productId: string,
  quantity = 1,
  token?: string
): Promise<{ data: any; product: any; buyer: any }> {
  const fallbackAddress = {
    street: '100 King St W',
    apartment: '',
    city: 'Toronto',
    state: 'ON',
    province: 'ON',
    postalCode: 'M5X 1A9',
    country: 'Canada',
    phoneNumber: '+14165550000',
  };

  // Strip SurrealDB collection prefix (e.g. "products:abc123" → "abc123") to avoid
  // SurrealDB parse errors when the ID is used in a query: Unexpected token `:`.
  const stripCollectionPrefix = (id: string): string =>
    id.includes(':') ? id.split(':', 2)[1] : id;

  let resolvedProductId = stripCollectionPrefix(productId);
  let prodDoc = await readDoc(`products/${resolvedProductId}`, token);
  let product = parseDoc(prodDoc);
  if (!product) {
    const products = await listCollection('products', token);
    const fallback = products.find((p) =>
      (p.stockQuantity ?? 0) > 0 &&
      ((p.lifecycleStatus ?? p.status) === 'active')
    ) ?? products.find((p) => (p.stockQuantity ?? 0) > 0) ?? products[0];
    if (fallback?.id) {
      // SurrealDB returns full record IDs like "products:abc123" — strip prefix before use
      resolvedProductId = stripCollectionPrefix(String(fallback.id));
      prodDoc = await readDoc(`products/${resolvedProductId}`, token);
      product = parseDoc(prodDoc);
    }
  }
  if (!product) {
    resolvedProductId = 'product_001';
  }

  const buyerDoc = await readDoc(`users/${buyerUid}`, token);
  const buyer = parseDoc(buyerDoc);
  const address = buyer?.address || {};

  if (!product) {
    return {
      data: {
        userId: buyerUid,
        items: [{ productId: resolvedProductId, quantity }],
        shippingAddress: {
          ...fallbackAddress,
          street: address.street || fallbackAddress.street,
          apartment: address.apartment || fallbackAddress.apartment,
          city: address.city || fallbackAddress.city,
          state: address.state || fallbackAddress.state,
          province: address.province || address.state || fallbackAddress.province,
          postalCode: address.postalCode || fallbackAddress.postalCode,
          country: address.country || fallbackAddress.country,
          phoneNumber: address.phoneNumber || fallbackAddress.phoneNumber,
        },
        deliverySpeed: 'standard',
      },
      product: { id: resolvedProductId },
      buyer,
    };
  }

  // OrignaBase stores price as priceCents (integer cents). Derive float price for
  // the checkout payload and subtotalCents. Fall back to legacy 'price' float if present.
  const productPriceCents: number = product.priceCents ?? Math.round((product.price ?? 0) * 100);
  const productPriceFloat: number = product.price ?? (productPriceCents / 100);

  const data = {
    userId: buyerUid,
    items: [{
      productId: resolvedProductId,
      name: product.name ?? product.title,
      price: productPriceFloat,
      quantity,
      sellerId: product.sellerId,
      imageUrls: product.imageUrls || [`https://picsum.photos/seed/${product.id ?? 'default'}/400/400`],
      isDigital: product.isDigital || false,
    }],
    subtotalCents: productPriceCents * quantity,
    shippingAddress: {
      street: address.street || fallbackAddress.street,
      apartment: address.apartment || '',
      city: address.city || fallbackAddress.city,
      state: address.state || fallbackAddress.state,
      province: address.province || address.state || fallbackAddress.province,
      postalCode: address.postalCode || fallbackAddress.postalCode,
      country: address.country || fallbackAddress.country,
      phoneNumber: address.phoneNumber || fallbackAddress.phoneNumber,
    },
  };
  return { data, product, buyer };
}

/**
 * Build multi-seller checkout payload.
 */
export async function buildMultiSellerPayload(
  buyerUid: string,
  items: { productId: string; quantity: number }[],
  token?: string
): Promise<any> {
  const buyerDoc = await readDoc(`users/${buyerUid}`, token);
  const buyer = parseDoc(buyerDoc);
  const address = buyer?.address || {};

  const cartItems: any[] = [];
  let subtotal = 0;
  for (const { productId, quantity } of items) {
    const prodDoc = await readDoc(`products/${productId}`, token);
    const product = parseDoc(prodDoc);
    if (!product) throw new Error(`Product ${productId} not found in SurrealDB.`);
    cartItems.push({
      productId,
      name: product.name,
      price: product.price,
      quantity,
      sellerId: product.sellerId,
      imageUrls: product.imageUrls || [`https://picsum.photos/seed/${product.id ?? 'default'}/400/400`],
      isDigital: product.isDigital || false,
    });
    subtotal += product.price * quantity;
  }

  return {
    userId: buyerUid,
    items: cartItems,
    subtotalCents: Math.round(subtotal * 100),
    shippingAddress: {
      street: address.street || '100 King St W',
      apartment: address.apartment || '',
      city: address.city || 'Toronto',
      state: address.state || 'ON',
      postalCode: address.postalCode || 'M5X 1A9',
      country: address.country || 'Canada',
      phoneNumber: address.phoneNumber || '+14165550000',
    },
  };
}

// ════════════════════════════════════════════════════════════════════
// ORDER HELPERS — Polling & status checking
// ════════════════════════════════════════════════════════════════════

/**
 * Read and parse an order document. Returns null if not found.
 */
function normalizeOrderShape(order: any): any {
  if (!order || typeof order !== 'object') return order;
  return {
    ...order,
    orderStatus: order.orderStatus ?? order.status ?? null,
    paymentStatus: order.paymentStatus ?? order.payment_status ?? null,
    userId: order.userId ?? order.buyerId ?? order.buyer_id ?? null,
  };
}

export async function getOrder(orderId: string, token?: string): Promise<any> {
  const doc = await readDoc(`orders/${orderId}`, token);
  return doc ? normalizeOrderShape(parseDoc(doc)) : null;
}

/**
 * Read product stock quantity. Returns 0 if product not found.
 */
export async function getProductStock(productId: string, token?: string): Promise<number> {
  const doc = await readDoc(`products/${productId}`, token);
  return doc ? (parseDoc(doc)?.stockQuantity ?? 0) : 0;
}

/**
 * Poll until a SurrealDB record field matches expected value.
 */
export async function pollDocField(
  path: string,
  field: string,
  expected: any,
  token?: string,
  maxMs = 30_000
): Promise<any> {
  const start = Date.now();
  while (Date.now() - start < maxMs) {
    const doc = await readDoc(path, token);
    if (doc) {
      const parsed = parseDoc(doc);
      if (parsed?.[field] === expected) return parsed;
    }
    await new Promise(r => setTimeout(r, 2_000));
  }
  const doc = await readDoc(path, token);
  return doc ? parseDoc(doc) : null;
}

/**
 * Simulate concurrent calls — useful for testing race conditions and idempotency.
 */
export async function simulateConcurrent(
  fn: () => Promise<unknown>,
  concurrency: number
): Promise<{ succeeded: number; failed: number; errors: string[] }> {
  const results = await Promise.allSettled(
    Array.from({ length: concurrency }, fn)
  );
  const succeeded = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected').length;
  const errors = results
    .filter((r): r is PromiseRejectedResult => r.status === 'rejected')
    .map(r => r.reason?.message ?? String(r.reason));
  return { succeeded, failed, errors };
}

/**
 * Poll SurrealDB until condition is true (eventual consistency helper).
 * Throws if condition is not met within timeout.
 */
export async function pollDoc<T>(
  path: string,
  condition: (data: T) => boolean,
  token?: string,
  { timeout = 10_000, interval = 500 } = {}
): Promise<T> {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const doc = await readDoc(path, token);
    const data = doc ? parseDoc(doc) as T : null;
    if (data && condition(data)) return data;
    await new Promise(r => setTimeout(r, interval));
  }
  throw new Error(`pollDoc timeout: condition not met for ${path} within ${timeout}ms`);
}

/**
 */
export async function waitForOrderStatus(
  orderId: string,
  targetStatuses: string[],
  token?: string,
  maxWaitMs = 90_000
): Promise<any> {
  const start = Date.now();
  let lastOrder: any = null;
  while (Date.now() - start < maxWaitMs) {
    const doc = await readDoc(`orders/${orderId}`, token);
    if (doc) {
      const order = parseDoc(doc);
      lastOrder = order;
      if (order && targetStatuses.includes(order.orderStatus)) return order;
    }
    await new Promise(r => setTimeout(r, 3_000));
  }
  const currentStatus = lastOrder?.orderStatus || 'unknown';
  throw new Error(
    `waitForOrderStatus timeout: order ${orderId} expected [${targetStatuses}] but got "${currentStatus}" after ${maxWaitMs}ms`
  );
}

// ════════════════════════════════════════════════════════════════════
// STRIPE CHECKOUT — Page interaction helpers
// ════════════════════════════════════════════════════════════════════

/**
 * Dismiss Stripe modals that may block the checkout form.
 */
export async function dismissStripeModals(page: Page): Promise<void> {
  // Handle "Pay without Link" button (Stripe Link OTP/authentication flow)
  const payWithoutLink = page.locator('button:has-text("Pay without Link")').first();
  if (await payWithoutLink.isVisible({ timeout: 3_000 }).catch(() => false)) {
    await payWithoutLink.click().catch(() => { });
    await page.waitForTimeout(1_000);
  }

  const linkDismiss = page.locator(
    'button:has-text("Not now"), ' +
    'button:has-text("Pay another way"), ' +
    'button:has-text("Cancel"), ' +
    '[data-testid="link-dismiss"], ' +
    '.LinkModal--close, ' +
    '[aria-label="Close"]'
  ).first();
  if (await linkDismiss.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await linkDismiss.click().catch(() => { });
    await page.waitForTimeout(500);
  }

  // Handle 3DS authentication test iframe
  const threeDSFrame = page.frameLocator('iframe[name*="stripe-challenge"], iframe[name*="__privateStripeFrame"]');
  try {
    const completeBtn = threeDSFrame.locator(
      'button:has-text("Complete"), button:has-text("Approve"), #test-source-authorize-3ds'
    ).first();
    if (await completeBtn.isVisible({ timeout: 1_000 }).catch(() => false)) {
      await completeBtn.click().catch(() => { });
      await page.waitForTimeout(1_000);
    }
  } catch {
    // No 3DS frame — expected for 4242 card
  }

  // Dismiss generic overlays
  const overlay = page.locator('.Modal-overlay, .VerificationModal, [data-testid="modal-overlay"]').first();
  if (await overlay.isVisible({ timeout: 500 }).catch(() => false)) {
    await page.keyboard.press('Escape').catch(() => { });
    await page.waitForTimeout(300);
  }
}

/**
 * Fill and submit Stripe Checkout hosted page.
 * Handles email, card number, expiry, CVC, billing, modals, and 3DS.
 */
export async function fillStripeCheckout(
  page: Page,
  email: string,
  card = STRIPE_CARD
): Promise<void> {
  await page.waitForLoadState('networkidle', { timeout: 60_000 }).catch(() => { });
  // Give Stripe's JS time to boot and render its iframe-based fields
  await page.waitForTimeout(3_000);
  await dismissStripeModals(page);

  // Fill email if visible — use the caller's email so Stripe doesn't create a new Link account
  const emailInput = page.locator('#email, input[name="email"]').first();
  if (await emailInput.isVisible({ timeout: 5_000 }).catch(() => false)) {
    await emailInput.fill(email);
    await page.waitForTimeout(1_500);

    // Dismiss Stripe Link SMS verification if it appears
    const smsInput = page.locator('[data-testid="sms-code-input-0"]').first();
    if (await smsInput.isVisible({ timeout: 3_000 }).catch(() => false)) {
      console.log('Stripe Link SMS verification detected — dismissing...');
      const dismissSelectors = [
        'button:has-text("Pay another way")',
        'button:has-text("Not now")',
        'button:has-text("Cancel")',
        '[data-testid="link-dismiss"]',
        '[aria-label="Close"]',
      ];
      for (const sel of dismissSelectors) {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 1_000 }).catch(() => false)) {
          await el.click().catch(() => { });
          await page.waitForTimeout(1_500);
          break;
        }
      }
    }
    await dismissStripeModals(page);
  }

  // Select "Card" payment method if hidden behind accordion
  const cardField = page.locator('#cardNumber, input[name="cardNumber"]').first();
  const cardVisible = await cardField.isVisible({ timeout: 5_000 }).catch(() => false);
  if (!cardVisible) {
    const cardRadio = page.locator('#payment-method-accordion-item-title-card').first();
    if (await cardRadio.isVisible({ timeout: 5_000 }).catch(() => false)) {
      const cardLabel = page.locator('label[for="payment-method-accordion-item-title-card"], #payment-method-accordion-item-title-card').first();
      await cardLabel.click({ force: true }).catch(() => { });
      await page.waitForTimeout(3_000);
    } else {
      const fallbackSelectors = [
        '[data-testid="card-accordion-item-button"]',
        'button:has-text("Card")',
        'button:has-text("Pay with card")',
        '[data-testid="card-tab"]',
        'input[value="card"]',
      ];
      for (const sel of fallbackSelectors) {
        const el = page.locator(sel).first();
        if (await el.isVisible({ timeout: 2_000 }).catch(() => false)) {
          await el.click().catch(() => { });
          await page.waitForTimeout(2_000);
          break;
        }
      }
    }
    await dismissStripeModals(page);
  }

  // Wait for card number field (direct page — Stripe Checkout v1/Elements)
  const cardReady = await cardField.isVisible({ timeout: 20_000 }).catch(() => false);
  if (!cardReady) {
    // Fallback 1: frameLocator approach (Stripe Checkout v2/newer hosted page)
    // Stripe renders card fields inside iframes; try common iframe URL patterns first.
    const stripeIframeSelectors = [
      'iframe[src*="js.stripe.com"]',
      'iframe[src*="checkout.stripe.com"]',
      'iframe[name*="__privateStripeFrame"]',
      'iframe[title*="Secure card"]',
      'iframe[title*="card"]',
    ];
    let foundViaFrameLocator = false;
    for (const iframeSel of stripeIframeSelectors) {
      try {
        const fl = page.frameLocator(iframeSel);
        const cardInput = fl.locator(
          'input[name="cardnumber"], input[autocomplete="cc-number"], input[name="number"], ' +
          'input[data-elements-stable-field-name="cardNumber"], input[placeholder*="1234"]'
        ).first();
        if (await cardInput.isVisible({ timeout: 5_000 }).catch(() => false)) {
          await cardInput.fill(card.number);
          // Expiry and CVC may be in the same frame or separate frames
          const expInput = fl.locator('input[name="exp-date"], input[autocomplete="cc-exp"]').first();
          if (await expInput.isVisible({ timeout: 3_000 }).catch(() => false)) await expInput.fill(card.exp);
          const cvcInput = fl.locator('input[name="cvc"], input[autocomplete="cc-csc"]').first();
          if (await cvcInput.isVisible({ timeout: 3_000 }).catch(() => false)) await cvcInput.fill(card.cvc);
          foundViaFrameLocator = true;
          return await submitStripePayment(page, card);
        }
      } catch { /* iframe not accessible or not present */ }
    }

    // Fallback 2: page.frames() loop — covers split-field Stripe Elements layout
    if (!foundViaFrameLocator) {
      const allFrames = page.frames();
      let foundInFrame = false;
      for (let i = 0; i < allFrames.length; i++) {
        const f = allFrames[i];
        try {
          const cardInput = f.locator(
            'input[name="cardnumber"], input[autocomplete="cc-number"], input[name="number"], ' +
            'input[data-elements-stable-field-name="cardNumber"], input[placeholder*="1234"]'
          ).first();
          if (await cardInput.isVisible({ timeout: 5_000 }).catch(() => false)) {
            await cardInput.fill(card.number);
            for (let j = 0; j < allFrames.length; j++) {
              if (j === i) continue;
              const expInput = allFrames[j].locator('input[name="exp-date"], input[autocomplete="cc-exp"]').first();
              if (await expInput.isVisible({ timeout: 2_000 }).catch(() => false)) await expInput.fill(card.exp);
              const cvcInput = allFrames[j].locator('input[name="cvc"], input[autocomplete="cc-csc"]').first();
              if (await cvcInput.isVisible({ timeout: 2_000 }).catch(() => false)) await cvcInput.fill(card.cvc);
            }
            foundInFrame = true;
            return await submitStripePayment(page, card);
          }
        } catch { /* frame not accessible */ }
      }
      if (!foundInFrame) {
        await page.screenshot({ path: '/tmp/stripe-checkout-debug.png', fullPage: true }).catch(() => { });
        throw new Error(`Stripe card field not found. URL: ${page.url()}`);
      }
    }
  } else {
    await cardField.fill(card.number);
  }

  // Fill expiry
  await page.locator('#cardExpiry, input[name="cardExpiry"]').first().fill(card.exp);

  // Fill CVC
  await page.locator('#cardCvc, input[name="cardCvc"]').first().fill(card.cvc);

  // Fill billing name if visible
  const nameField = page.locator('#billingName, input[name="billingName"]').first();
  if (await nameField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await nameField.fill(card.name);
  }

  // Fill phone number if visible
  const phoneField = page.locator('#phoneNumber, input[name="phoneNumber"]').first();
  if (await phoneField.isVisible({ timeout: 1_000 }).catch(() => false)) {
    await phoneField.fill('+14165550000');
  }

  // Fill postal code if visible
  const postalField = page.locator('#billingPostalCode, input[name="billingPostalCode"]').first();
  if (await postalField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await postalField.fill(card.postalCode);
  }

  await dismissStripeModals(page);

  // Click Pay and wait for redirect
  const payBtn = page.locator(
    '[data-testid="hosted-payment-submit-button"], .SubmitButton, button[type="submit"]'
  ).first();
  await payBtn.waitFor({ state: 'visible', timeout: 10_000 });
  await payBtn.click();

  try {
    await page.waitForURL(
      (url: URL) => !url.hostname.includes('checkout.stripe.com'),
      { timeout: 45_000 }
    );
  } catch {
    const errorEl = page.locator('.FieldError, [data-testid="error-message"], .p-Alert, [role="alert"]').first();
    const hasError = await errorEl.isVisible({ timeout: 2_000 }).catch(() => false);
    if (hasError) {
      const text = await errorEl.textContent().catch(() => 'unknown');
      throw new Error(`Stripe payment failed: ${text}`);
    }
    console.log('Still on Stripe Checkout after 45s — payment may still be processing');
  }
}

/** Submit Stripe payment (used after iframe card fill) */
async function submitStripePayment(page: Page, card: typeof STRIPE_CARD): Promise<void> {
  const nameField = page.locator('#billingName, input[name="billingName"]').first();
  if (await nameField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await nameField.fill(card.name);
  }
  const postalField = page.locator('#billingPostalCode, input[name="billingPostalCode"]').first();
  if (await postalField.isVisible({ timeout: 2_000 }).catch(() => false)) {
    await postalField.fill(card.postalCode);
  }
  await dismissStripeModals(page);
  const payBtn = page.locator(
    '[data-testid="hosted-payment-submit-button"], .SubmitButton, button[type="submit"]'
  ).first();
  await payBtn.waitFor({ state: 'visible', timeout: 10_000 });
  await payBtn.click();
}

// ════════════════════════════════════════════════════════════════════
// FULL CHECKOUT FLOWS
// ════════════════════════════════════════════════════════════════════

/**
 * Full checkout + pay: create checkout session → navigate to Stripe → fill & submit.
 */
export async function fullCheckoutAndPay(
  page: Page,
  buyerEmail: string,
  productId: string,
  quantity = 1,
  password = DEFAULT_PASS
): Promise<{ orderId: string; checkoutUrl: string }> {
  const auth = await signIn(buyerEmail, password);
  const { data } = await buildCheckoutPayload(auth.localId, productId, quantity, auth.idToken);
  const result = await callOk('create_checkout_session', data, auth.idToken);

  if (!result.orderId) throw new Error('Checkout failed: no orderId returned');
  if (!result.checkoutUrl) throw new Error('Checkout failed: no checkoutUrl returned');

  await page.goto(result.checkoutUrl);
  await fillStripeCheckout(page, buyerEmail);
  await page.waitForTimeout(5_000);

  return { orderId: result.orderId, checkoutUrl: result.checkoutUrl };
}

/**
 * Full multi-seller checkout + pay.
 */
export async function fullMultiSellerCheckoutAndPay(
  page: Page,
  buyerEmail: string,
  items: { productId: string; quantity: number }[],
  password = DEFAULT_PASS
): Promise<{ orderId: string }> {
  const auth = await signIn(buyerEmail, password);
  const payload = await buildMultiSellerPayload(auth.localId, items, auth.idToken);
  const result = await callOk('create_checkout_session', payload, auth.idToken);

  if (!result.orderId) throw new Error('Multi-seller checkout failed: no orderId');

  await page.goto(result.checkoutUrl);
  await fillStripeCheckout(page, buyerEmail);
  await page.waitForTimeout(5_000);

  return { orderId: result.orderId };
}

// ════════════════════════════════════════════════════════════════════
// PRODUCT DISCOVERY — Dev SurrealDB has auto-generated product IDs
// ════════════════════════════════════════════════════════════════════

interface DiscoveredProduct {
  id: string;
  name: string;
  price: number;
  sellerId: string;
  stockQuantity: number;
  lifecycleStatus: string;
}

let _cachedProducts: DiscoveredProduct[] | null = null;

/** Clear the product cache so the next call re-fetches from SurrealDB. */
export function invalidateProductCache(): void {
  _cachedProducts = null;
}

/**
 * Stable product IDs used across E2E test runs.
 * Using fixed IDs + getDoc (single-document GET) avoids runQuery (list) permission
 * issues — OrignaBase rules evaluate `resource.data` reliably for individual GETs.
 */
const STABLE_TEST_PRODUCTS: Array<{ id: string; sellerUid: string; prefix: string; country?: string }> = [
  { id: 'e2e_product_admin_seller', sellerUid: TEST_UIDS.ADMIN, prefix: 'A' },
  { id: 'e2e_product_test_seller', sellerUid: TEST_UIDS.SELLER, prefix: 'B' },
  { id: 'e2e_product_intl_seller', sellerUid: TEST_UIDS.SELLER, prefix: 'C', country: 'China' },
];

/**
 * Discover available products in dev SurrealDB.
 * Uses stable product IDs + individual getDoc calls instead of runQuery to avoid
 * SurrealDB list-operation permission issues. Creates products if they don't exist.
 * Results are cached for the test run (call invalidateProductCache() to refresh).
 */
export async function discoverProducts(_token?: string): Promise<DiscoveredProduct[]> {
  if (_cachedProducts) return _cachedProducts;

  if (useOrignaBaseAuth()) {
    // Check if stable test products already exist before creating new ones.
    // createDummyProduct with writeDoc uses the stable productId (never random IDs).
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
    const obProducts: DiscoveredProduct[] = [];
    for (const { id, sellerUid, prefix, country } of STABLE_TEST_PRODUCTS) {
      let product: DiscoveredProduct | null = null;
      try {
        const fields = await getDoc(`products/${id}`, adminAuth.idToken);
        if (fields && (fields.lifecycleStatus === 'active' || fields.status === 'active') && (fields.stockQuantity ?? 0) > 0) {
          // Auto-fix sellerId if it doesn't match expected e2e account (accounts may be recreated).
          if (fields.sellerId !== sellerUid) {
            await writeDoc(`products/${id}`, toSurrealDBFields({ sellerId: sellerUid }), adminAuth.idToken, true);
            fields.sellerId = sellerUid;
          }
          product = {
            id,
            name: fields.name || `E2E Product ${prefix}`,
            price: fields.priceCents ? fields.priceCents / 100 : (fields.price ?? 0),
            sellerId: sellerUid,
            stockQuantity: fields.stockQuantity ?? 100,
            lifecycleStatus: 'active',
          };
        }
      } catch { /* will create below */ }

      if (!product) {
        const address = country === 'China'
          ? { street: 'Nanjing Rd', city: 'Shanghai', state: 'SH', postalCode: '200001', country: 'China' }
          : undefined;
        product = await createDummyProduct(sellerUid, prefix, id, address);
      }
      obProducts.push(product);
    }
    _cachedProducts = obProducts;
    return _cachedProducts;
  }

  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  const products: DiscoveredProduct[] = [];

  for (const { id, sellerUid, prefix, country } of STABLE_TEST_PRODUCTS) {
    let product: DiscoveredProduct | null = null;
    try {
      const fields = await getDoc(`products/${id}`, adminAuth.idToken);
      if (fields && (fields.lifecycleStatus === 'active' || fields.status === 'active')) {
        // Auto-restore stock if too low (tests decrement stock with each checkout)
        const currentStock = fields.stockQuantity ?? 0;
        if (currentStock < 10) {
          await writeDoc(`products/${id}`, toSurrealDBFields({ stockQuantity: 200 }), adminAuth.idToken, true);
          fields.stockQuantity = 200;
        }

        // FIX: Ensure Product C has international address + isInternational flag
        if (id === 'e2e_product_intl_seller') {
          const patches: Record<string, unknown> = {};
          if (fields.sellerAddress?.country !== 'China') {
            patches.sellerAddress = { street: 'Nanjing Rd', city: 'Shanghai', state: 'SH', postalCode: '200001', country: 'China' };
            fields.sellerAddress = patches.sellerAddress as typeof fields.sellerAddress;
          }
          if (!fields.isInternational) {
            patches.isInternational = true;
            fields.isInternational = true;
          }
          if (Object.keys(patches).length > 0) {
            await writeDoc(`products/${id}`, toSurrealDBFields(patches), adminAuth.idToken, true);
          }
        }

        // Auto-fix sellerId if it doesn't match expected e2e account (accounts may be recreated).
        if (fields.sellerId !== sellerUid) {
          await writeDoc(`products/${id}`, toSurrealDBFields({ sellerId: sellerUid }), adminAuth.idToken, true);
          fields.sellerId = sellerUid;
        }

        if ((fields.stockQuantity ?? 0) > 0) {
          product = {
            id,
            name: fields.name || `E2E Product ${prefix}`,
            price: fields.price || 0,
            sellerId: sellerUid,
            stockQuantity: fields.stockQuantity,
            lifecycleStatus: 'active',
          };
        }
      }
    } catch { /* will create below */ }

    if (!product) {
      const address = country === 'China'
        ? { street: 'Nanjing Rd', city: 'Shanghai', state: 'SH', postalCode: '200001', country: 'China' }
        : undefined;
      product = await createDummyProduct(sellerUid, prefix, id, address);
    }
    products.push(product);
  }

  _cachedProducts = products;
  return _cachedProducts;
}

/**
 * Get a single test product with live stock check.
 * Prefers products with highest stock. The buyer must NOT be the seller.
 */
export async function getTestProduct(token: string, excludeSellerId?: string): Promise<DiscoveredProduct> {
  const products = await discoverProducts(token);
  const candidates = excludeSellerId
    ? products.filter(p => p.sellerId !== excludeSellerId)
    : products;

  if (candidates.length === 0) {
    throw new Error('No purchasable products found (after excluding seller).');
  }

  // Re-check stock for top candidates (cache may be stale)
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  for (const product of candidates.slice(0, 5)) {
    try {
      const doc = await readDoc(`products/${product.id}`, adminAuth.idToken);
      const live = parseDoc(doc);
      if (live && live.stockQuantity > 0) {
        product.stockQuantity = live.stockQuantity; // update cache
        return product;
      }
    } catch { /* skip, try next */ }
  }

  // Fallback: invalidate cache and re-discover
  invalidateProductCache();
  const fresh = await discoverProducts(token);
  const freshCandidates = excludeSellerId
    ? fresh.filter(p => p.sellerId !== excludeSellerId)
    : fresh;

  if (freshCandidates.length === 0) {
    throw new Error('All products are out of stock. Restock dev SurrealDB.');
  }
  return freshCandidates[0];
}

/**
 * Get two products from different sellers (for multi-seller tests).
 * Returns null if only one seller has products with stock.
 */
export async function getTwoSellerProducts(token: string): Promise<[DiscoveredProduct, DiscoveredProduct] | null> {
  const products = await discoverProducts(token);
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL);
  const sellers = new Map<string, DiscoveredProduct>();

  for (const p of products) {
    if (sellers.has(p.sellerId)) continue;
    // Live stock check
    try {
      const doc = await readDoc(`products/${p.id}`, adminAuth.idToken);
      const live = parseDoc(doc);
      if (live && live.stockQuantity > 0) {
        p.stockQuantity = live.stockQuantity;
        sellers.set(p.sellerId, p);
      }
    } catch { /* skip */ }
    if (sellers.size >= 2) break;
  }

  if (sellers.size < 2) return null;
  const [a, b] = [...sellers.values()];
  return [a, b];
}

export async function createDummyProduct(
  sellerUid: string,
  prefix: string,
  productId?: string,
  customAddress?: { street: string; city: string; state: string; postalCode: string; country: string }
): Promise<DiscoveredProduct> {
  const sampleImageUrls = [
    `https://picsum.photos/seed/${prefix}a/400/400`,
    `https://picsum.photos/seed/${prefix}b/400/400`,
  ];

  // For OrignaBase auth, use writeDoc with the stable productId (same as non-OB path).
  // create_product_atomic generates a random ID and ignores productId, breaking stable-ID lookups.
  if (useOrignaBaseAuth()) {
    const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
    const id = productId ?? `test_dummy_${prefix}_${Date.now()}`;
    const productData = {
      sellerId: sellerUid,
      sellerSku: `DUMMY-${prefix}-STABLE`,
      name: `Dummy Test Product ${prefix}`,
      title: `Dummy Test Product ${prefix}`,
      description: 'A high-quality test product created for E2E testing purposes.',
      priceCents: 1599,
      price: 15.99,
      lifecycleStatus: 'active',
      stockQuantity: 100,
      categoryId: 1,
      imageUrls: sampleImageUrls,
      keywords: ['dummy', prefix],
      sellerAddress: customAddress || {
        street: '100 University Ave',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5J 1V6',
        country: 'Canada',
      },
      isInternational: customAddress ? customAddress.country !== 'Canada' : false,
    };
    const ok = await writeDoc(`products/${id}`, toSurrealDBFields(productData), adminAuth.idToken, true);
    if (!ok) throw new Error(`createDummyProduct: writeDoc failed for ${id}`);
    return {
      id,
      name: productData.name,
      price: productData.price,
      sellerId: sellerUid,
      stockQuantity: 100,
      lifecycleStatus: 'active',
    };
  }

  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const id = productId ?? `test_dummy_${prefix}_${Date.now()}`;
  const productData = {
    sellerId: sellerUid,
    sellerSku: `DUMMY-${prefix}-STABLE`,
    name: `Dummy Test Product ${prefix}`,
    description: `A high-quality test product created for E2E testing purposes.`,
    price: 15.99,
    lifecycleStatus: 'active',
    stockQuantity: 100,
    categoryId: 1,
      imageUrls: sampleImageUrls,
    keywords: ['dummy', prefix],
    sellerAddress: customAddress || {
      street: '100 University Ave',
      city: 'Toronto',
      state: 'ON',
      postalCode: 'M5J 1V6',
      country: 'Canada'
    },
    isInternational: customAddress ? customAddress.country !== 'Canada' : false,
  };

  const ok = await writeDoc(`products/${id}`, toSurrealDBFields(productData), adminAuth.idToken, true);
  if (!ok) throw new Error(`Failed to create dummy product for ${sellerUid}`);

  return {
    id,
    name: productData.name,
    price: productData.price,
    sellerId: productData.sellerId,
    stockQuantity: productData.stockQuantity,
    lifecycleStatus: productData.lifecycleStatus,
  };
}

/**
 * Ensures two products from different sellers exist on the dev environment.
 * Delegates to discoverProducts which creates stable products if missing.
 */
export async function ensureTwoSellerProducts(_token: string): Promise<[DiscoveredProduct, DiscoveredProduct]> {
  const products = await discoverProducts();
  const adminProd = products.find(p => p.sellerId === TEST_UIDS.ADMIN);
  const sellerProd = products.find(p => p.sellerId === TEST_UIDS.SELLER);
  if (!adminProd || !sellerProd) {
    // Stale cache — invalidate and retry once
    invalidateProductCache();
    const fresh = await discoverProducts();
    const a = fresh.find(p => p.sellerId === TEST_UIDS.ADMIN);
    const b = fresh.find(p => p.sellerId === TEST_UIDS.SELLER);
    if (!a || !b) throw new Error('ensureTwoSellerProducts: failed to ensure products for both sellers');
    return [a, b];
  }
  return [adminProd, sellerProd];
}

// ════════════════════════════════════════════════════════════════════
// SELLER AUTH — Map known seller UIDs to test accounts
// ════════════════════════════════════════════════════════════════════

const SELLER_UID_TO_EMAIL: Record<string, string> = {
  [TEST_UIDS.ADMIN]: TEST_ACCOUNTS.ADMIN_EMAIL,
  [TEST_UIDS.SELLER]: TEST_ACCOUNTS.SELLER_EMAIL,
};

/**
 * Sign in as the seller who owns a product (by sellerId).
 * In dev, all products are owned by the admin account.
 */
export async function getSellerAuth(sellerId: string): Promise<AuthData> {
  const email = SELLER_UID_TO_EMAIL[sellerId];
  if (!email) throw new Error(`Unknown seller UID: ${sellerId}. Add mapping to SELLER_UID_TO_EMAIL.`);
  return signIn(email);
}

// ════════════════════════════════════════════════════════════════════
// CONVENIENCE
// ════════════════════════════════════════════════════════════════════

export function uid(): string {
  return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

// ════════════════════════════════════════════════════════════════════
// PRODUCT MANIPULATION
// ════════════════════════════════════════════════════════════════════

/**
 * Programmatically updates the trending status of a product.
 * Used to set up E2E tests for trending products.
 */
export async function setProductTrending(productId: string, isTrending: boolean, adminToken?: string): Promise<boolean> {
  const token = adminToken ?? (await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS)).idToken;
  const docData = await getDoc(`products/${productId}`, token);
  if (!docData) throw new Error(`Product ${productId} not found`);

  const updates: Record<string, any> = {
    isTrending: isTrending,
    trendingAt: isTrending ? new Date() : null
  };

  return writeDoc(`products/${productId}`, toSurrealDBFields(updates), token, true);
}

// ════════════════════════════════════════════════════════════════════
// TEST PRODUCTS — stable IDs for dev E2E
// ════════════════════════════════════════════════════════════════════

export const TEST_PRODUCTS = {
  HIGH_STOCK: 'e2e_product_admin_seller',
  DIGITAL: 'e2e_product_test_seller',
  SELLER2: 'e2e_product_intl_seller',
  OOS: 'e2e_product_oos',
};

/**
 * Ensure the dedicated OOS (out-of-stock) product exists in dev SurrealDB.
 * stockQuantity is always forced to 0. Owner is ADMIN so seller-owns tests work correctly.
 * This product must NEVER have its stock restored — it is permanently OOS for UI tests.
 */
export async function ensureOosProduct(): Promise<void> {
  const adminAuth = await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
  const id = TEST_PRODUCTS.OOS;
  let exists = false;
  try {
    const fields = await getDoc(`products/${id}`, adminAuth.idToken);
    exists = !!(fields && (fields.lifecycleStatus === 'active' || fields.status === 'active'));
    if (exists && (fields.stockQuantity ?? 1) !== 0) {
      // Force stock to 0 if someone accidentally restored it
      await writeDoc(`products/${id}`, toSurrealDBFields({ stockQuantity: 0 }), adminAuth.idToken, true);
    }
  } catch { /* not found — will create */ }

  if (!exists) {
    await writeDoc(`products/${id}`, toSurrealDBFields({
      productId: id,
      sellerId: TEST_UIDS.ADMIN,
      sellerSku: 'OOS-E2E-STABLE',
      name: 'Out-of-Stock Test Product (E2E)',
      description: 'Dedicated out-of-stock product for stock notification E2E tests. Stock must always be 0.',
      price: 49.99,
      priceCents: 4999,
      lifecycleStatus: 'active',
      stockQuantity: 0,
      categoryId: 1,
      imageUrls: ['https://picsum.photos/seed/oos-test-e2e/400/400'],
      keywords: ['oos', 'test', 'e2e'],
      hasVariants: false,
      variants: [],
      isDigital: false,
      sellerAddress: {
        street: '100 University Ave',
        city: 'Toronto',
        state: 'ON',
        postalCode: 'M5J 1V6',
        country: 'Canada',
      },
      isInternational: false,
      rating: 0,
      ratingCount: 0,
    }), adminAuth.idToken, true);
  }
}

// ════════════════════════════════════════════════════════════════════
// COLLECTION LISTING — List/query SurrealDB collections
// ════════════════════════════════════════════════════════════════════

/**
 * List all documents in a SurrealDB collection.
 * Alias for listCollection for compatibility.
 */
export async function listDocs(collectionPath: string, token?: string): Promise<any[]> {
  return listCollection(collectionPath, token);
}

/**
 * List documents in a SurrealDB subcollection.
 */
export async function listSubcollection(
  parentCollection: string,
  parentId: string,
  subcollection: string,
  token?: string
): Promise<any[]> {
  return listCollection(`${parentCollection}/${parentId}/${subcollection}`, token);
}

/**
 * List buyer addresses directly from the 'addresses' collection (OrignaBase).
 * OrignaBase stores addresses in a flat 'addresses' collection with a 'userId' field,
 * NOT as a subcollection of 'users'. Use this instead of listSubcollection for addresses.
 */
export async function listUserAddresses(userId: string, token?: string): Promise<any[]> {
  const query = `
    query ListAddresses($collection: String!, $filters: JSON) {
      list(collection: $collection, filters: $filters, limit: 200)
    }
  `;
  const result = await obGraphQL(query, {
    collection: 'addresses',
    filters: { userId: { _eq: userId } },
  }, token);
  if (!result.ok) return [];
  const raw = parseGraphQLValue(result.body?.data?.list);
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((doc: any) => doc && typeof doc === 'object')
    .map((doc: any) => {
      const { id, _id, _rev, _created, _updated, ...rest } = doc;
      // Strip SurrealDB record prefix (e.g. 'addresses:abc123' → 'abc123')
      // so the id matches what add_buyer_address returns as addressId.
      const strippedId = typeof id === 'string' && id.includes(':') ? id.split(':', 2)[1] : id;
      return strippedId ? { id: strippedId, ...rest } : rest;
    });
}

/**
 * Run a structured query against OrignaBase REST API.
 */
export async function querySurrealDB(structuredQuery: any, token?: string): Promise<any[]> {
  const from = structuredQuery?.from?.[0]?.collectionId;
  if (!from) return [];
  return listCollection(from, token);
}
