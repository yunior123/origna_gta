/**
 * Bun preload script — pre-authenticates all test accounts before tests start.
 * Prevents rate-limit cascade when multiple test files try to sign in simultaneously.
 * Tokens are cached to /tmp/origna_e2e_tokens.json and shared across all test files.
 * 
 * FIXED: Added timeout (30s total) to prevent hanging if backend is slow.
 */
import { signIn } from './lib/auth';
import { TEST_ACCOUNTS, DEFAULT_PASS } from './lib/config';

// Clear stale cache
try {
  const fs = require('fs');
  fs.unlinkSync('/tmp/origna_e2e_tokens.json');
} catch {
  // No cache file yet — that's fine
}

// Sign in all accounts sequentially to avoid quota
// WITH TIMEOUT: If backend is slow, skip pre-warming and let tests sign in
console.log('🔑 Pre-warming auth tokens...');

const timeoutPromise = (ms: number) => new Promise((_, reject) => 
  setTimeout(() => reject(new Error('Pre-warming timeout')), ms)
);

try {
  await Promise.race([
    (async () => {
      await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
      await signIn(TEST_ACCOUNTS.SELLER_EMAIL, DEFAULT_PASS);
      await signIn(TEST_ACCOUNTS.BUYER_EMAIL, DEFAULT_PASS);
    })(),
    timeoutPromise(30_000)  // 30s total timeout for all 3 sign-ins
  ]);
  console.log('✅ Auth tokens cached to disk for all workers');
} catch (e) {
  const err = e as Error;
  if (err.message === 'Pre-warming timeout') {
    console.warn('⚠️  Pre-warming timeout after 30s — tests will sign in individually');
  } else {
    console.warn(`⚠️  Pre-warming failed: ${err.message} — tests will sign in individually`);
  }
  // Don't block tests — they'll sign in on demand
}
