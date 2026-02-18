/**
 * OrignaGTA — Shared E2E API Helpers (Isolated)
 */

import { Page, APIRequestContext } from '@playwright/test';

// ════════════════════════════════════════════════════════════════════
// CONFIGURATION — Environment-aware URLs
// ════════════════════════════════════════════════════════════════════

const TEST_ENV = (process.env.TEST_ENVIRONMENT || 'emulator').toLowerCase();

const getEnvironmentConfig = () => {
    switch (TEST_ENV) {
        case 'dev':
            return {
                auth: 'https://identitytoolkit.googleapis.com',
                firestore: 'https://firestore.googleapis.com',
                functions: 'https://us-central1-orignagta-dev.cloudfunctions.net',
                webApp: 'https://orignagta-dev.web.app',
                projectId: 'orignagta-dev',
            };
        case 'staging':
            return {
                auth: 'https://identitytoolkit.googleapis.com',
                firestore: 'https://firestore.googleapis.com',
                functions: 'https://us-central1-orignagta-staging.cloudfunctions.net',
                webApp: 'https://orignagta-staging.web.app',
                projectId: 'orignagta-staging',
            };
        case 'production':
            return {
                auth: 'https://identitytoolkit.googleapis.com',
                firestore: 'https://firestore.googleapis.com',
                functions: 'https://us-central1-orignagta.cloudfunctions.net',
                webApp: 'https://orignagta.web.app',
                projectId: 'orignagta',
            };
        case 'emulator':
        default:
            return {
                auth: 'http://localhost:9099',
                firestore: 'http://localhost:8080',
                functions: 'http://localhost:5001',
                webApp: 'http://localhost:5005',
                projectId: 'orignagta',
            };
    }
};

const envConfig = getEnvironmentConfig();

export const AUTH_EMULATOR = envConfig.auth;
export const FIRESTORE_EMULATOR = envConfig.firestore;
export const FUNCTIONS_EMULATOR = envConfig.functions;
export const WEB_APP_URL = envConfig.webApp;
export const PROJECT_ID = envConfig.projectId;
export const TEST_ENVIRONMENT = TEST_ENV;

export const FIRESTORE_BASE = `${FIRESTORE_EMULATOR}/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
export const DEFAULT_PASS = 'REDACTED_TEST_PASSWORD';

export const STRIPE_CARD = {
    number: '4242424242424242',
    exp: '12/30',
    cvc: '123',
    name: 'Test Buyer',
    postalCode: 'M5V 3A8',
};

export const TEST_ACCOUNTS = {
    ADMIN_EMAIL: 'yr62813@gmail.com',
    ADMIN_PASS: '960227Y#y',
    SELLER1_EMAIL: 'seller1@test.origna.ca',
    SELLER2_EMAIL: 'seller2@test.origna.ca',
    BUYER1_EMAIL: 'buyer1@test.origna.ca',
    BUYER2_EMAIL: 'buyer2@test.origna.ca',
    BUYER3_EMAIL: 'buyer3@test.origna.ca',
    SUSPENDED_EMAIL: 'suspended@test.origna.ca',
    NON_ONBOARDED_SELLER: 'seller9@test.origna.ca',
};

export const TEST_PRODUCTS = {
    HIGH_STOCK: 'product_024',
    DIGITAL: 'product_010',
    SELLER2: 'product_004',
};

// ════════════════════════════════════════════════════════════════════
// INFRASTRUCTURE CHECK
// ════════════════════════════════════════════════════════════════════

export interface InfraStatus {
    auth: boolean | null;
    firestore: boolean | null;
    functions: boolean | null;
}

let infraCache: InfraStatus = { auth: null, firestore: null, functions: null };

export async function checkInfrastructure(request: APIRequestContext): Promise<InfraStatus> {
    if (infraCache.auth === null) {
        const [authRes, firestoreRes, functionsRes] = await Promise.all([
            request.get(`${AUTH_EMULATOR}/`).catch(() => null),
            request.get(`${FIRESTORE_EMULATOR}/`).catch(() => null),
            request.get(`${FUNCTIONS_EMULATOR}/`).catch(() => null),
        ]);
        infraCache = {
            auth: !!authRes,
            firestore: !!firestoreRes,
            functions: !!functionsRes,
        };
    }
    return infraCache;
}

export function resetInfraCache() {
    infraCache = { auth: null, firestore: null, functions: null };
}

// ════════════════════════════════════════════════════════════════════
// SEED VALIDATION
// ════════════════════════════════════════════════════════════════════

let seedValidated = false;

export async function ensureSeedData(): Promise<void> {
    if (seedValidated) return;

    try {
        const res = await fetch(
            `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
            {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    email: TEST_ACCOUNTS.BUYER1_EMAIL,
                    password: DEFAULT_PASS,
                    returnSecureToken: true,
                }),
            }
        );
        const data = await res.json() as { idToken?: string };
        if (!data.idToken) {
            const res2 = await fetch(
                `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
                {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        email: TEST_ACCOUNTS.SELLER1_EMAIL,
                        password: DEFAULT_PASS,
                        returnSecureToken: true,
                    }),
                }
            );
            const data2 = await res2.json() as { idToken?: string };
            if (!data2.idToken) {
                throw new Error('NO SEED DATA: Auth Emulator has no test users.');
            }
        }
        seedValidated = true;
    } catch (e) {
        if (e instanceof Error && e.message.startsWith('NO SEED DATA')) throw e;
        throw new Error(`Auth Emulator unreachable at ${AUTH_EMULATOR}: ${e}`);
    }
}

// ════════════════════════════════════════════════════════════════════
// FIREBASE AUTH — Sign In
// ════════════════════════════════════════════════════════════════════

export interface AuthData {
    idToken: string;
    refreshToken: string;
    localId: string;
    email: string;
    [key: string]: any;
}

export async function signIn(email: string, password: string = DEFAULT_PASS): Promise<AuthData> {
    const res = await fetch(
        `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
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

    return data as AuthData;
}

// ════════════════════════════════════════════════════════════════════
// FIRESTORE REST API — CRUD
// ════════════════════════════════════════════════════════════════════

export async function readDoc(path: string): Promise<any> {
    const res = await fetch(`${FIRESTORE_BASE}/${path}`, {
        headers: { 'Authorization': 'Bearer owner' },
    });
    if (!res.ok) return null;
    return res.json();
}

export async function writeDoc(path: string, fields: Record<string, any>): Promise<boolean> {
    const fieldPaths = Object.keys(fields).map(k => `updateMask.fieldPaths=${k}`).join('&');
    const res = await fetch(`${FIRESTORE_BASE}/${path}?${fieldPaths}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer owner' },
        body: JSON.stringify({ fields: toFirestoreFields(fields) }),
    });
    return res.ok;
}

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
        for (const [k, val] of Object.entries((v.mapValue.fields || {}) as Record<string, any>)) o[k] = parseVal(val);
        return o;
    }
    return v;
}

export function parseDoc(doc: any): any {
    if (!doc?.fields) return null;
    const r: Record<string, any> = {};
    for (const [k, v] of Object.entries(doc.fields as Record<string, any>)) r[k] = parseVal(v);
    return r;
}

export function toFirestoreFields(obj: Record<string, any>): any {
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
    if (typeof v === 'object') return { mapValue: { fields: toFirestoreFields(v) } };
    return { stringValue: String(v) };
}

// ════════════════════════════════════════════════════════════════════
// FUNCTIONS CALLABLE
// ════════════════════════════════════════════════════════════════════

export async function callCallable(fn: string, data: any, token: string): Promise<any> {
    const res = await fetch(`${FUNCTIONS_EMULATOR}/${PROJECT_ID}/us-central1/${fn}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({ data }),
    });
    return res.json();
}

export async function callOk(fn: string, data: any, token: string): Promise<any> {
    const body = await callCallable(fn, data, token);
    if (body.error) {
        throw new Error(`${fn} failed: ${body.error.message || JSON.stringify(body.error)}`);
    }
    return body.result || body;
}

// ════════════════════════════════════════════════════════════════════
// STRIPE HELPERS (Minimal for Add Product Flow)
// ════════════════════════════════════════════════════════════════════

export async function dismissStripeModals(page: Page): Promise<void> {
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
}

// ════════════════════════════════════════════════════════════════════
// CONVENIENCE
// ════════════════════════════════════════════════════════════════════

export function uid(): string {
    return `${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
}

export async function getProductStock(productId: string): Promise<number> {
    const doc = await readDoc(`products/${productId}`);
    return doc ? (parseDoc(doc)?.stockQuantity ?? 0) : 0;
}
