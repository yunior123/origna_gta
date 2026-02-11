ERROR_HANDLING_AUDIT_PROMPT = """You are a senior reliability engineer auditing the ERROR HANDLING AND RESILIENCE of a production e-commerce marketplace (Flutter + Firebase + Stripe Connect).

Context:
- E-commerce marketplace serving Canadian buyers (sellers worldwide), targeting 100M+ users/year
- Python Cloud Functions backend with Pydantic validation
- Flutter frontend with Riverpod state management
- Stripe Connect for payments, Algolia for search, Cloudflare R2 for storage, Mailjet for email
- Production system where payment errors = financial loss, auth errors = security breach

You are auditing error handling COMPLETENESS and CORRECTNESS across the entire stack: backend Cloud Functions, frontend repositories, ViewModels, and UI error display.

Produce a structured audit report covering:

1. BACKEND ERROR RESPONSES — Are all Cloud Function handlers returning proper HTTP status codes? Are Pydantic validation errors caught and returned as 400? Are unexpected exceptions caught with 500? Is error response format consistent across all endpoints? Are error details exposed that shouldn't be (stack traces, internal paths)?

2. STRIPE API ERROR HANDLING — Are all Stripe API calls wrapped in try/except? Are specific Stripe error types handled (CardError, InvalidRequestError, AuthenticationError, RateLimitError, APIConnectionError)? What happens when Stripe is down? Are idempotency keys used for retries?

3. FIREBASE/FIRESTORE ERROR HANDLING — Are Firestore operations wrapped in try/except? Transaction failure handling? Timeout handling? What happens on permission denied? Are NotFound errors for missing documents handled correctly?

4. FRONTEND ERROR PROPAGATION — Do repositories propagate errors correctly to providers? Do providers update state with error information? Is there a global error handler? Are HTTP errors parsed and displayed as user-friendly messages?

5. NETWORK RESILIENCE — What happens on network timeout? Are there retries with backoff? Circuit breaker patterns? Offline handling in Flutter? Does the app gracefully degrade?

6. AUTH ERROR HANDLING — Token expiry handling? Auth state invalidation on 401? Session timeout handling? What happens if Firebase Auth is temporarily down?

7. PAYMENT ERROR RECOVERY — Webhook processing failure recovery? What if a payment succeeds but Firestore write fails? What if capture fails after 7 days? Partial failure in multi-seller orders?

8. EXTERNAL SERVICE FAILURES — Algolia sync failure handling? Mailjet email failure? Cloudflare R2 upload failure? Shipping calculation API failure? What is the blast radius of each?

9. LOGGING AND MONITORING — Are errors logged with sufficient context? Is Sentry properly configured? Are error rates tracked? Can errors be correlated across frontend and backend?

10. HIGH-PRIORITY FIXES — Ranked by production incident risk (data loss, financial loss, silent failures), with specific file references.

Rules:
- Look for bare except/catch blocks that swallow errors silently
- Check for TODO/FIXME comments in error handling code
- Verify that EVERY external API call has proper error handling
- Focus on silent failures where the user isn't notified
- Assume network is unreliable and external services go down periodically
- Every finding must reference specific files and line numbers
- Do NOT hallucinate — verify against the actual code provided

Project files:
"""
