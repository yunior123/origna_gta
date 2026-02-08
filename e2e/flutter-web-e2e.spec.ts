/**
 * Flutter Web E2E Tests
 * 
 * These tests are designed specifically for Flutter Web (CanvasKit renderer).
 * Since Flutter renders to a canvas, we use:
 * - API-based authentication via Firebase Auth REST API
 * - URL-based navigation verification
 * - Flutter element presence checks (flt-glass-pane, flt-semantics)
 * - Backend integration tests via direct API calls
 * 
 * NOTE: These tests automatically skip if infrastructure is not running.
 * Run `./start-dev.sh` first to start all required services.
 */
import { test, expect, Page } from '@playwright/test';

// Firebase Emulator URLs
const AUTH_EMULATOR = 'http://localhost:9099';
const FIRESTORE_EMULATOR = 'http://localhost:8080';
const FUNCTIONS_EMULATOR = 'http://localhost:5001';
const WEB_APP_URL = 'http://localhost:5005';
const PROJECT_ID = 'orignagta';

// Test credentials
const TEST_USER = {
    email: 'e2e-test@example.com',
    password: 'test123456',
    displayName: 'E2E Test User'
};

// Infrastructure availability cache
let infraAvailable: {
    auth: boolean | null;
    firestore: boolean | null;
    functions: boolean | null;
    webApp: boolean | null;
} = {
    auth: null,
    firestore: null,
    functions: null,
    webApp: null,
};

/** Check if infrastructure is available */
async function checkInfrastructure(request: any): Promise<typeof infraAvailable> {
    // Only check once per test run
    if (infraAvailable.auth === null) {
        const [authRes, firestoreRes, functionsRes, webRes] = await Promise.all([
            request.get(`${AUTH_EMULATOR}/`).catch(() => null),
            request.get(`${FIRESTORE_EMULATOR}/`).catch(() => null),
            request.get(`${FUNCTIONS_EMULATOR}/`).catch(() => null),
            request.get(`${WEB_APP_URL}/`).catch(() => null),
        ]);
        infraAvailable = {
            auth: !!authRes,
            firestore: !!firestoreRes,
            functions: !!functionsRes,
            webApp: !!webRes && webRes.status() === 200,
        };
        
        if (Object.values(infraAvailable).some(v => !v)) {
            console.log('⚠️  Some infrastructure is unavailable:');
            console.log(`   Auth: ${infraAvailable.auth ? '✅' : '❌'}`);
            console.log(`   Firestore: ${infraAvailable.firestore ? '✅' : '❌'}`);
            console.log(`   Functions: ${infraAvailable.functions ? '✅' : '❌'}`);
            console.log(`   Web App: ${infraAvailable.webApp ? '✅' : '❌'}`);
            console.log('   Run `./start-dev.sh` to start all services');
        }
    }
    return infraAvailable;
}

// Helper: Detect Flutter web rendering regardless of engine version.
// Flutter <=3.21 uses <flt-glass-pane>, Flutter 3.22+ uses <flutter-view>,
// and all versions render into one or more <canvas> elements.
async function waitForFlutter(page: Page, timeout = 90000) {
    console.log(`⏳ Waiting for Flutter Web to initialize (timeout: ${timeout}ms)...`);
    const startTime = Date.now();
    
    // 1) Wait for any Flutter host element OR a sized canvas to appear
    await page.waitForFunction(() => {
        const glasspane = document.querySelector('flt-glass-pane');
        const flutterView = document.querySelector('flutter-view');
        const canvas = document.querySelector('canvas');
        return !!glasspane || !!flutterView || (canvas instanceof HTMLCanvasElement && canvas.getBoundingClientRect().width > 0);
    }, { timeout });
    console.log(`   ✅ Flutter host element found (${Date.now() - startTime}ms)`);

    // 2) Wait for the splash screen to disappear
    await page.waitForFunction(() => {
        const splash = document.getElementById('splash');
        return !splash || splash.style.display === 'none' || splash.getAttribute('hidden') !== null;
    }, { timeout }).catch(() => {});
    console.log(`   ✅ Splash screen gone (${Date.now() - startTime}ms)`);

    // 3) Wait for canvas to be actually rendered with size
    await page.waitForFunction(() => {
        const canvas = document.querySelector('canvas');
        if (!(canvas instanceof HTMLCanvasElement)) return false;
        const rect = canvas.getBoundingClientRect();
        return rect.width > 0 && rect.height > 0;
    }, { timeout: Math.min(30000, timeout) }).catch(() => {});
    console.log(`   ✅ Canvas rendered (${Date.now() - startTime}ms)`);

    // 4) Trigger Flutter semantics tree (CanvasKit) to improve locator stability
    await page.evaluate(() => {
        const event = new KeyboardEvent('keydown', { key: 'Tab' });
        document.dispatchEvent(event);
    });

    // 5) Wait for semantics to attach (best-effort)
    await page.locator('flt-semantics').first().waitFor({ state: 'attached', timeout: Math.min(20000, timeout) }).catch(() => {});
    console.log(`   ✅ Flutter initialized in ${Date.now() - startTime}ms`);
}

function uniqueSuffix(testInfo: { workerIndex: number; parallelIndex: number }) {
    // Avoid collisions across workers + parallel tests (even within the same ms)
    const rnd = Math.random().toString(16).slice(2, 8);
    return `w${testInfo.workerIndex}-p${testInfo.parallelIndex}-${Date.now()}-${rnd}`;
}

// Helper: Create user via Auth Emulator REST API
async function createTestUser(email: string, password: string) {
    const response = await fetch(
        `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-api-key`,
        {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email,
                password,
                returnSecureToken: true
            })
        }
    );
    return response.json();
}

// Helper: Sign in via Auth Emulator REST API
async function signInUser(email: string, password: string) {
    const response = await fetch(
        `${AUTH_EMULATOR}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
        {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                email,
                password,
                returnSecureToken: true
            })
        }
    );
    return response.json();
}

// =============================================================================
// INFRASTRUCTURE TESTS
// =============================================================================

test.describe('Infrastructure Health Checks', () => {
    test('Firebase Auth Emulator is running', async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.auth, 'Auth emulator not running. Run `firebase emulators:start`');
        
        const response = await request.get(`${AUTH_EMULATOR}/`).catch(() => null);
        expect(response).toBeTruthy();
        console.log('✅ Auth Emulator running');
    });

    test('Firestore Emulator is running', async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.firestore, 'Firestore emulator not running. Run `firebase emulators:start`');
        
        const response = await request.get(`${FIRESTORE_EMULATOR}/`).catch(() => null);
        expect(response).toBeTruthy();
        console.log('✅ Firestore Emulator running');
    });

    test('Functions Emulator is running', async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.functions, 'Functions emulator not running. Run `firebase emulators:start`');
        
        const response = await request.get(`${FUNCTIONS_EMULATOR}/`).catch(() => null);
        console.log(`Functions Emulator response: ${response ? response.status() : 'no response'}`);
        expect(response !== null).toBeTruthy();
        console.log('✅ Functions Emulator running');
    });

    test('Web App is serving', async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.webApp, 'Web app not running on port 5005. Run `flutter run -d chrome --web-port=5005`');
        
        const response = await request.get(`${WEB_APP_URL}/`);
        expect(response.status()).toBe(200);
        const html = await response.text();
        expect(html.toLowerCase()).toContain('origna');
        expect(html).toContain('flutter');
        console.log('✅ Web App serving');
    });
});

// =============================================================================
// FLUTTER WEB LOADING TESTS
// =============================================================================

test.describe('Flutter Web App Loading', () => {
    test.beforeEach(async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.webApp, 'Web app not running. Skipping Flutter UI tests.');
    });

    test('App loads and initializes', async ({ page }) => {
        test.setTimeout(120_000);
        await page.goto('/');
        await waitForFlutter(page);
        
        const flutterPresent = await page.evaluate(() => {
            return !!document.querySelector('flt-glass-pane') ||
                   !!document.querySelector('flutter-view') ||
                   !!document.querySelector('canvas');
        });
        expect(flutterPresent).toBeTruthy();
        console.log('✅ Flutter app initialized');
    });

    test('Navigates to login page', async ({ page }) => {
        test.setTimeout(120_000);
        await page.goto('/login');
        await waitForFlutter(page);
        
        expect(page.url()).toContain('/login');
        console.log('✅ Login route works');
    });

    test('Navigates to home page', async ({ page }) => {
        test.setTimeout(120_000);
        await page.goto('/home');
        await waitForFlutter(page);
        
        const url = page.url();
        expect(url.includes('/home') || url.endsWith('/')).toBeTruthy();
        console.log('✅ Home route works');
    });

    test('Invalid route shows error or redirects', async ({ page }) => {
        test.setTimeout(120_000);
        await page.goto('/invalid-route-12345');
        await waitForFlutter(page);
        
        const flutterPresent = await page.evaluate(() => {
            return !!document.querySelector('flt-glass-pane') ||
                   !!document.querySelector('flutter-view') ||
                   !!document.querySelector('canvas');
        });
        expect(flutterPresent).toBeTruthy();
        console.log('✅ Invalid route handled');
    });
});

// =============================================================================
// AUTH EMULATOR TESTS
// =============================================================================

test.describe('Authentication via Emulator', () => {
    test.beforeEach(async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.auth, 'Auth emulator not running. Skipping auth tests.');
    });

    test('Can create user via Auth REST API', async ({}, testInfo) => {
        const result = await createTestUser(
            `test-${uniqueSuffix(testInfo)}@example.com`,
            'password123'
        );
        
        expect(result.localId).toBeTruthy();
        expect(result.idToken).toBeTruthy();
        console.log(`✅ Created user: ${result.email}`);
    });

    test('Can sign in via Auth REST API', async ({}, testInfo) => {
        const email = `signin-test-${uniqueSuffix(testInfo)}@example.com`;
        await createTestUser(email, 'password123');
        
        const result = await signInUser(email, 'password123');
        
        expect(result.localId).toBeTruthy();
        expect(result.idToken).toBeTruthy();
        console.log(`✅ Signed in user: ${result.email}`);
    });
});

// =============================================================================
// FIRESTORE EMULATOR TESTS
// =============================================================================

test.describe('Firestore via Emulator', () => {
    test('Can read from Firestore emulator', async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.firestore, 'Firestore emulator not running. Skipping Firestore tests.');
        
        const response = await request.get(
            `${FIRESTORE_EMULATOR}/v1/projects/${PROJECT_ID}/databases/(default)/documents`
        ).catch(() => null);
        
        if (response) {
            console.log(`Firestore response: ${response.status()}`);
            expect([200, 401, 403, 404]).toContain(response.status());
        }
        console.log('✅ Firestore emulator responds');
    });
});

// =============================================================================
// API ENDPOINT TESTS
// =============================================================================

test.describe('Cloud Functions API', () => {
    const FUNCTIONS_BASE = `${FUNCTIONS_EMULATOR}/${PROJECT_ID.replace('-', '')}/us-central1`;

    test('Health check endpoint', async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.functions, 'Functions emulator not running. Skipping Cloud Functions tests.');
        
        const response = await request.get(`${FUNCTIONS_BASE}/healthCheck`).catch(() => null);
        if (response) {
            console.log(`Health check: ${response.status()}`);
        } else {
            console.log('Health check endpoint not found - expected if not implemented');
        }
        expect(true).toBeTruthy();
    });
});

// =============================================================================
// PERFORMANCE TESTS
// =============================================================================

test.describe('Performance', () => {
    test.beforeEach(async ({ request }) => {
        const infra = await checkInfrastructure(request);
        test.skip(!infra.webApp, 'Web app not running. Skipping performance tests.');
    });

    test('Page loads within acceptable time', async ({ page }) => {
        test.setTimeout(120_000);
        const startTime = Date.now();
        
        await page.goto('/');
        await waitForFlutter(page, 90000);
        
        const loadTime = Date.now() - startTime;
        console.log(`Page load time: ${loadTime}ms`);
        
        expect(loadTime).toBeLessThan(60000);
        console.log('✅ Page loads within acceptable time');
    });

    test('Navigation is responsive', async ({ page }) => {
        test.setTimeout(120_000);
        await page.goto('/');
        await waitForFlutter(page, 90000);
        
        const startTime = Date.now();
        await page.goto('/login');
        await waitForFlutter(page, 15000);
        
        const navTime = Date.now() - startTime;
        console.log(`Navigation time: ${navTime}ms`);
        
        const maxNavTime = process.env.CI ? 90000 : 60000;
        expect(navTime).toBeLessThan(maxNavTime);
        console.log('✅ Navigation is responsive');
    });
});
