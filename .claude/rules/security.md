# Security Rules — origna_gta

## Secrets — Never in Code
- No API keys, JWT secrets, Stripe keys, or other credentials in source code.
- Secrets live in: VPS `.env` files, or GitHub Actions secrets.
- GitHub Actions secrets: `STRIPE_TEST_KEY`, `MAIL_USERNAME`, `MAIL_PASSWORD`.
- `dart-define` values at build time: OK for non-secret config (env URLs, feature flags) — not for keys.
- Never commit `.env` or any credentials file.

## Cloudflare Turnstile (Bot Protection)
- Turnstile replaces reCAPTCHA — no Firebase App Check (Firebase is gone)
- Site key injected into `build/web/index.html` at deploy time via `TURNSTILE_SITE_KEY` env var
- Turnstile token validated server-side on auth and checkout endpoints
- Never bypass Turnstile in production builds

## Authentication (OrignaBase — Firebase Auth is gone)
- OrignaBase handles all auth: `/auth/register`, `/auth/login`, `/auth/google/start`
- Google Sign-In on web: OrignaBase server-side OAuth redirect — NOT `google_sign_in` package's `authenticate()`
- Email verification required before seller features are unlocked
- Password reset emails sent from `support@orignagta.ca` via OrignaBase
- JWTs are short-lived; refresh handled automatically by OrignaBase SDK

## Authorization
- Sellers can only read/write their own products, orders, and `seller_profiles` record.
- Buyers can only read their own orders and profile.
- Admins have elevated access — all admin actions must be logged with `adminUid` in the event log.
- Never trust `userId` sent from Flutter — always derive it from the verified JWT on the backend.
- Row-level security enforced in PostgreSQL via `RLS` policies on all tables.

## Rate Limiting
- OrignaBase uses `tower_governor` for rate limiting — respect 429 responses.
- Flutter SDK must implement exponential backoff on 429: start at 1s, max at 60s.
- Auth endpoints (login, register) have stricter rate limits — do not retry aggressively.
- Meilisearch search: debounce user input by 300ms minimum before firing queries.

## Input Validation
- All user input validated client-side (Flutter form validators) AND server-side (OrignaBase).
- Client-side validation is UX only — never rely on it for security.
- Canadian postal code format: `[A-Z]\d[A-Z] \d[A-Z]\d` — validate on address forms.
- Phone numbers: E.164 format required (`+1XXXXXXXXXX` for Canada).
- Product prices: must be positive integers in cents, max 10,000,000 ($100,000 CAD).

## Stripe Security
- Webhook signature (HMAC) verified on every incoming request — reject anything that fails.
- Stripe secret key never leaves the VPS/Cloud Function environment.
- Checkout Sessions created server-side only — Flutter never touches Stripe API directly.
- `payment_intent` IDs stored in orders for audit trail.

## Turnstile (Cloudflare)
- Turnstile site key injected into `build/web/index.html` at deploy time — not hardcoded.
- Turnstile token validated server-side on auth and checkout endpoints.
- Never bypass Turnstile in production builds.

## Data Privacy
- PII (name, email, phone, address) never logged in plaintext.
- Buyer addresses are never exposed to sellers beyond what is needed for shipping.
- Seller bank account details never stored in PostgreSQL — Stripe Connect handles it.
- User data deletion: OrignaBase must support GDPR delete request that purges all user records.

## Dependency Security
- Run `flutter pub audit` before every release — block on high/critical vulnerabilities.
- Pin major versions in `pubspec.yaml` — do not use `any` version constraints.
- Backend Rust dependencies: `cargo audit` in CI pipeline.

## Forbidden
- Hardcoded credentials or tokens of any kind in any file.
- Disabling App Check in production.
- Skipping webhook signature verification.
- Logging PII (emails, phone numbers, addresses, payment card info).
- Storing Stripe API keys in environment variables accessible to Flutter.
- `debugShowCheckedModeBanner: true` in production builds.
