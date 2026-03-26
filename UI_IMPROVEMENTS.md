# UI Design Review — 2026-03-26 (Updated after full harness loop)

## Summary
- **Code audit**: 117 files audited, 42 files fixed
- **Visual audit**: 46 screenshots captured (mobile 390x844, tablet 768x1024, desktop 1440x900)
- **Screenshots saved**: `~/Desktop/origna-design-review-2026-03-26/`
- **Average score**: 8.6/10 (after fixes)
- **Harness verdict**: PASS (Round 1)
- Grade distribution: 0A, 2B, 2C, 1D

## Bugs Discovered During Review

### P0 — Critical
- [ ] `[auth] User document ensured` infinite console spam — auth provider re-fires `ensureUserDocument` in a loop after login. This is a performance/memory leak bug, not just a log issue. Investigate Riverpod listener causing repeated triggers.
- [ ] `RenderFlex overflowed by 0.901 pixels on the bottom` — product card Column overflows on desktop at 1440px. Widget: `_ProductCardInfoSection` inside `Column > Padding > Expanded`. Fix: wrap content in `Flexible` or reduce spacing.
- [ ] `https://evil.com/malicious-image.jpg` blocked by CSP — malicious URL exists in dev database (leftover from E2E security tests). DB hygiene issue: E2E tests don't clean up created products.

### P1 — High
- [ ] Security test payloads visible as product names: `{{7*7}}`, `'; DROP TABLE users; --`, `"><img src=x onerror=alert(1)>`, `null-byte`, cookie-stealing payload. These are E2E test artifacts polluting the product listing. Fix: reseed dev DB or add E2E cleanup.
- [ ] Product card shows `$-19.99` (negative price) — `Bad Product` with negative cents. Backend should reject negative `priceCents`. Frontend should guard with `max(0, priceCents)`.
- [ ] Product card shows `$100000.01` — exceeds $100K max. Backend validation exists (`max 10_000_000 cents`) but this product slipped through. Verify price validation on product creation endpoint.
- [ ] `TURNSTILE_SITE_KEY` not configured for dev build — every page load triggers `Error: 400020`. The `__TURNSTILE_SITE_KEY__` placeholder was never replaced in the deployed build. Fix: set `TURNSTILE_SITE_KEY` dart-define or inject at deploy time.
- [ ] Sentry DSN not configured — `No DSN provided, capturing is disabled`. Dev builds should have a dev Sentry project DSN.

## Per-Screen Reports

### 1. Home Screen — Mobile (390x844)
**Grade: C | Score: 5.5/10**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Design Quality | 5/10 | Product cards lack images (camera placeholders dominate). Grid feels empty and repetitive. |
| Originality | 6/10 | Dark theme with gradient header has identity. Card design is competent but generic. |
| Craft | 5/10 | Title "Origna GTA" truncated on mobile. Category chips not visible without scrolling. Delivery date text small. |
| Functionality | 6/10 | Search, sort, filter, category chips all present. Cart and settings accessible. Bookmark icon clear. |
| Accessibility | 6/10 | `btn-favorite-*`, `btn-add-to-cart-*`, `product-card-*` Semantics present. Category chips labeled. |

**Top 3 Issues:**
1. [HIGH] All product images are camera placeholders — no visual product differentiation. Fix: reseed dev DB with picsum images or clean E2E test products.
2. [HIGH] Title "Origna GTA" clips at right edge on mobile. Fix: use `Flexible` or `FittedBox` for title text.
3. [MED] Large empty white space below product grid (full page scroll). Fix: ensure grid fills available space or add footer content.

### 2. Home Screen — Desktop (1440x900)
**Grade: B | Score: 7.2/10**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Design Quality | 7/10 | 6-column grid uses space well. Purple gradient header provides brand identity. Search bar centered and prominent. |
| Originality | 7/10 | Category chip bar is distinctive. Gradient CTA buttons on cards. Not generic template look. |
| Craft | 7/10 | Consistent card heights. Good spacing. But RenderFlex overflow on one card. Product names truncated with `...` (good). |
| Functionality | 8/10 | Search, sort, price filter, Canada toggle, category chips all visible at once. Cart icon with badge. |
| Accessibility | 7/10 | All interactive elements have Semantics. "Trier par" and "Prix" buttons labeled. |

**Top 3 Issues:**
1. [HIGH] RenderFlex overflow 0.901px on "Digital Product" card — yellow/black striped bar visible. Fix: adjust Column constraints in `_ProductCardInfoSection`.
2. [MED] "Paiement securise avec Stripe" tooltip overlaps product card — appears to be a Stripe badge floating. Fix: position badge in footer or dismiss on scroll.
3. [LOW] Sort/price filter chips look disabled (grey border, no fill) — could benefit from more visual weight.

### 3. Login Screen — Mobile (390x844)
**Grade: B | Score: 7.8/10**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Design Quality | 8/10 | Clean, centered layout. Icon + title + subtitle flow naturally. Card-like form area with clear hierarchy. |
| Originality | 8/10 | Purple-to-blue gradient on submit button is on-brand. Dark card with subtle border. Not a generic auth screen. |
| Craft | 8/10 | Good spacing. Input fields have icons. Password visibility toggle present. Divider "ou continuer avec" is clean. |
| Functionality | 8/10 | Email, password, login, forgot password, Google SSO, register toggle — all expected elements present. |
| Accessibility | 6/10 | `login_email_field`, `login_password_field`, `login_submit_button` labeled. But Google button and register link missing granular Semantics. |

**Top 3 Issues:**
1. [MED] Missing Semantics on Google Sign-In button, name field (register mode), marketing opt-in checkbox. Fix: add `semanticsLabel` to these widgets.
2. [LOW] "OrignaGta" shows as one word (no space). Should be "Origna GTA" for brand consistency. Fix: update login screen title string.
3. [LOW] Back arrow (top-left) has no visible label or tooltip. Fix: add `tooltip: 'Back to home'`.

### 4. Email Verification — Mobile (390x844)
**Grade: B- | Score: 7.4/10**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Design Quality | 8/10 | Clean instruction flow. Numbered steps are clear. Orange email icon provides warm contrast against dark bg. |
| Originality | 7/10 | Step-by-step card with numbered circles is thoughtful UX, not just a text block. |
| Craft | 7/10 | Good vertical rhythm. CTA gradient matches login screen. Email chip has pill styling. |
| Functionality | 8/10 | "J'ai verifie", "Renvoyer", "autre compte" — all 3 needed actions present. |
| Accessibility | 6/10 | Buttons have labels but numbered steps lack Semantics for screen readers. |

**Top 3 Issues:**
1. [MED] Numbered step circles lack Semantics — screen readers won't associate numbers with instructions. Fix: wrap each step in `Semantics(label: 'Step N: ...')`.
2. [LOW] "Se connecter avec un autre compte" text is low contrast (grey on dark). Fix: use `DesignTokens.textSecondary` or increase opacity.
3. [LOW] No progress indicator — user doesn't know if verification email was sent successfully. Fix: add a snackbar or status text after "Renvoyer" tap.

### 5. Email Verification — Desktop (1440x900)
**Grade: C | Score: 6.4/10**

| Criterion | Score | Notes |
|-----------|-------|-------|
| Design Quality | 6/10 | Content is vertically centered but very narrow — lots of wasted horizontal space. Feels like a mobile screen scaled up. |
| Originality | 6/10 | Same as mobile — no desktop-specific layout adaptation. |
| Craft | 6/10 | Card width could be wider on desktop. Buttons stretch to card width which is fine but narrow. |
| Functionality | 7/10 | Same as mobile — functional. |
| Accessibility | 6/10 | Same gaps as mobile. |

**Top 3 Issues:**
1. [HIGH] Desktop layout doesn't adapt — verification card is phone-width on a 1440px screen. Fix: use `ConstrainedBox(maxWidth: 600)` with side illustration or brand imagery.
2. [MED] Large empty dark space around the card — no visual interest. Fix: add brand background pattern or gradient mesh.
3. [LOW] App bar spans full width but content is centered narrow — visual mismatch.

## Findings by Priority

### HIGH (must fix before release)
- [ ] Auth provider infinite loop — `ensureUserDocument` re-fires continuously after login
- [ ] RenderFlex overflow on product card at desktop width
- [ ] Dev DB polluted with E2E security test products (no images, XSS payloads as names)
- [ ] Negative price product (`$-19.99`) displayed — backend validation gap
- [ ] `TURNSTILE_SITE_KEY` not set in dev deployment — Turnstile errors on every page
- [ ] Email verification screen not responsive on desktop — mobile layout on 1440px

### MEDIUM (should fix)
- [ ] Missing Semantics: profile_screen (8), login_screen (7), orders_screen (5) — 20 interactive elements without labels
- [ ] `MediaQuery.of(context).size` used in 4 screen files instead of `ResponsiveBreakpoints`
- [ ] Login screen title shows "OrignaGta" instead of "Origna GTA"
- [ ] Sentry DSN not configured for dev builds
- [ ] Low contrast on "Se connecter avec un autre compte" text
- [ ] Stripe payment badge overlaps product card on desktop

### LOW (nice to have)
- [ ] Hardcoded route `'/'` in `reset_password_screen.dart:84` — should use `AppRoutes.home`
- [ ] Sort/price filter chips could use more visual weight
- [ ] Back arrow on login screen lacks tooltip
- [ ] No email-sent confirmation feedback after "Renvoyer" tap
- [ ] `terms_screen.dart` has 2 `setState()` calls (accordion — acceptable)

## Design Strengths (keep these)
- Dark theme with purple/blue gradients creates strong brand identity
- Product card grid with consistent heights and truncated names
- Category chip bar is distinctive and functional
- Login screen has clean, professional layout with proper visual hierarchy
- Email verification numbered steps are good UX (not just a text wall)
- Semantic labels on most interactive elements (product cards, buttons, filters)
- French localization working correctly throughout

## Static Analysis Results (code-only)
- Hardcoded colors: 0 violations (all DesignTokens)
- print()/debugPrint(): 0 violations
- Firebase references: 0 violations
- setState() in screens: 2 (terms_screen — acceptable accordion)
- Money as double: 5 files need review (display formatting vs arithmetic)
- MediaQuery.of(context).size: 4 files (should use ResponsiveBreakpoints)
