/**
 * OrignaGTA — E2E Authentication Helpers
 * Extracted from api-helpers.ts for use in Vitest-based agent-browser tests.
 * OrignaBase is the only auth backend (Firebase is gone).
 */

import { readFileSync, writeFileSync, renameSync } from 'node:fs';
import {
  ORIGNABASE_URL,
  DEFAULT_PASS,
  TEST_ACCOUNTS,
  TARGET_ENV,
} from './config.js';
import type { AuthData, PublicAuthProviders } from './types.js';
import { writeDoc } from './api-client.js';

// ════════════════════════════════════════════════════════════════════
// INTERNAL STATE
// ════════════════════════════════════════════════════════════════════

const _orignabaseUiAccountCache = new Map<string, { email: string; password: string }>();
let _orignabaseBootstrapAdminToken: string | null | undefined;

type OrignaBaseUserSummary = {
  id: string;
  email: string;
  roles?: string[];
  email_verified?: boolean;
};

// ════════════════════════════════════════════════════════════════════
// TOKEN CACHE (memory + disk, shared across workers)
// ════════════════════════════════════════════════════════════════════

const _authCache = new Map<string, { data: AuthData; expiresAt: number }>();
const TOKEN_CACHE_FILE = '/tmp/origna_e2e_tokens.json';

function _loadDiskTokens(): void {
  try {
    const raw = JSON.parse(readFileSync(TOKEN_CACHE_FILE, 'utf8'));
    for (const [k, v] of Object.entries(raw as Record<string, any>)) {
      if (v.expiresAt > Date.now()) _authCache.set(k, v);
    }
  } catch { /* no cache yet */ }
}

function _saveDiskTokens(): void {
  try {
    const obj: Record<string, any> = {};
    _authCache.forEach((v, k) => { obj[k] = v; });
    const tmp = `${TOKEN_CACHE_FILE}.${process.pid}.tmp`;
    writeFileSync(tmp, JSON.stringify(obj));
    renameSync(tmp, TOKEN_CACHE_FILE);
  } catch { /* ignore */ }
}

// Load tokens on module init
_loadDiskTokens();

// ════════════════════════════════════════════════════════════════════
// ROLE & ALIAS HELPERS
// ════════════════════════════════════════════════════════════════════

export function rolesForEmail(email: string): string[] {
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

export function uiAliasForRoles(roles: string[]): string {
  const roleTag = roles.includes('admin') ? 'admin' : roles.includes('seller') ? 'seller' : 'buyer';
  const envTag = TARGET_ENV === 'unknown' ? 'adhoc' : TARGET_ENV;
  return `e2e-${roleTag}-${envTag}-ui@test.origna.ca`;
}

export function uiFallbackAliasForRoles(roles: string[]): string {
  const roleTag = roles.includes('admin') ? 'admin' : roles.includes('seller') ? 'seller' : 'buyer';
  const envTag = TARGET_ENV === 'unknown' ? 'adhoc' : TARGET_ENV;
  const nonce = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  return `e2e-${roleTag}-${envTag}-${nonce}@test.origna.ca`;
}

export function isStableMappedAccount(email: string): boolean {
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
 */
export function resolveUiEmail(email: string): string {
  if (!isStableMappedAccount(email)) return email.trim().toLowerCase();
  return uiAliasForRoles(rolesForEmail(email.trim().toLowerCase()));
}

export function bootstrapAdminEmail(): string {
  const explicit = process.env.E2E_ORIGNABASE_ADMIN_EMAIL?.trim();
  if (explicit) return explicit.toLowerCase();
  return 'e2e-admin@test.origna.ca';
}

export function bootstrapAdminPassword(): string {
  return process.env.E2E_ORIGNABASE_ADMIN_PASS?.trim() || DEFAULT_PASS;
}

export function hasRequiredRoles(actualRoles: string[] | undefined, requiredRoles: string[]): boolean {
  const actual = new Set((actualRoles ?? []).map(role => role.toLowerCase()));
  return requiredRoles.every(role => actual.has(role.toLowerCase()));
}

// ════════════════════════════════════════════════════════════════════
// FETCH WITH RETRY (429 backoff)
// ════════════════════════════════════════════════════════════════════

export async function fetchWithRetry(url: string, init: RequestInit, attempts = 4): Promise<Response> {
  const delays429 = [2_000, 5_000, 10_000, 15_000];
  let lastResponse: Response | null = null;
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    const response = await fetch(url, init);
    lastResponse = response;
    if (response.status !== 429) return response;
    const wait = delays429[attempt] ?? 30_000;
    console.log(`Rate limit on ${url}, waiting ${wait / 1000}s... (attempt ${attempt + 1}/${attempts})`);
    await new Promise(resolve => setTimeout(resolve, wait));
  }
  return lastResponse!;
}

// ════════════════════════════════════════════════════════════════════
// BACKEND PROVIDER
// ════════════════════════════════════════════════════════════════════

/**
 * OrignaBase is the only backend. Always returns true.
 */
export function useOrignaBaseAuth(): boolean {
  return true;
}

// ════════════════════════════════════════════════════════════════════
// BOOTSTRAP ADMIN
// ════════════════════════════════════════════════════════════════════

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

// ════════════════════════════════════════════════════════════════════
// ACCOUNT REPAIR
// ════════════════════════════════════════════════════════════════════

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

// ════════════════════════════════════════════════════════════════════
// ACCOUNT PROVISIONING
// ════════════════════════════════════════════════════════════════════

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
// SIGN IN
// ════════════════════════════════════════════════════════════════════

export async function signInOrignaBase(email: string, password: string): Promise<AuthData> {
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
  const accessToken = String(loginBody.access_token);
  const refreshToken = String(loginBody.refresh_token || '');

  return {
    idToken: accessToken,
    refreshToken,
    localId,
    email: normalizedEmail,
  };
}

/**
 * Decode a JWT and return the expiry timestamp in milliseconds.
 * Falls back to 10 minutes from now if decoding fails.
 */
function _jwtExpiresAtMs(jwt: string): number {
  try {
    const [, payload] = jwt.split('.');
    if (!payload) return Date.now() + 10 * 60_000;
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
    const pad = normalized.length % 4 === 0 ? '' : '='.repeat(4 - (normalized.length % 4));
    const decoded = JSON.parse(Buffer.from(`${normalized}${pad}`, 'base64').toString('utf8'));
    if (typeof decoded.exp === 'number') {
      // Subtract 60s safety margin so we refresh before actual expiry
      return decoded.exp * 1000 - 60_000;
    }
  } catch { /* fall through */ }
  return Date.now() + 10 * 60_000;
}

/**
 * Sign in to OrignaBase Auth.
 * Caches tokens in memory AND on disk (shared across workers) until JWT expiry minus 60s safety margin.
 */
export async function signIn(email: string, password: string = DEFAULT_PASS): Promise<AuthData> {
  const cacheKey = `${email}:${password}`;
  _loadDiskTokens();
  const cached = _authCache.get(cacheKey);
  if (cached && Date.now() < cached.expiresAt) return cached.data;

  const data = await signInOrignaBase(email, password);
  const expiresAt = _jwtExpiresAtMs(data.idToken);
  _authCache.set(cacheKey, { data, expiresAt });
  _saveDiskTokens();
  return data;
}

// ════════════════════════════════════════════════════════════════════
// USER STATE MANIPULATION
// ════════════════════════════════════════════════════════════════════

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
    console.log(`Rate limit on PATCH email_verified for ${email}, waiting ${delays[i] / 1000}s... (retry ${i + 1}/${delays.length})`);
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
  const uiEmail = resolveUiEmail(email);
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

// ════════════════════════════════════════════════════════════════════
// PUBLIC CONFIG / AUTH PROVIDERS
// ════════════════════════════════════════════════════════════════════

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
