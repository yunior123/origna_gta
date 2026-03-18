/**
 * Bun preload script — pre-authenticates all test accounts before tests start.
 * Prevents rate-limit cascade when multiple test files try to sign in simultaneously.
 * Tokens are cached to /tmp/origna_e2e_tokens.json and shared across all test files.
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
console.log('🔑 Pre-warming auth tokens...');
await signIn(TEST_ACCOUNTS.ADMIN_EMAIL, TEST_ACCOUNTS.ADMIN_PASS);
await signIn(TEST_ACCOUNTS.SELLER_EMAIL, DEFAULT_PASS);
await signIn(TEST_ACCOUNTS.BUYER_EMAIL, DEFAULT_PASS);
console.log('✅ Auth tokens cached to disk for all workers');
