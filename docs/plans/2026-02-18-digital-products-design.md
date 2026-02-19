# Digital Products — Design Document
**Date:** 2026-02-18
**Status:** Approved
**Scope:** Books + Software only (v1)

---

## Overview

Sell digital products (books and desktop software) on the marketplace without hosting files. Sellers provide external download URLs; the platform generates license keys and manages access control server-side. No CDN hosting required.

Two product sub-types:
- **Software** — multi-platform builds (macOS .dmg, Windows .exe/.msi, Linux .deb/.AppImage). License key activation model (JetBrains-style). Buyers enter the key in the installed app to unlock.
- **Book** — single external PDF/EPUB URL. Access via server-side redirect token (never expose raw URL). No license activation in the installed sense — buyer clicks Download, gets a 15-min single-use redirect.

---

## 1. Schema

### Product (`products/{id}`) — additions

| Field | Type | Notes |
|---|---|---|
| `isDigital` | bool | already exists |
| `digitalType` | `"software" \| "book"` | new, required when isDigital=true |
| `slug` | string | URL-safe unique ID, server-generated at creation |
| `digitalBuilds` | map | software only: `{ macos, windows, linux }` → external URLs |
| `bookSourceUrl` | string | book only: raw external URL, **never sent to client** |
| `deviceLimit` | int? | software only, null = unlimited |

Slug format: `{title-slug}-{4 random hex chars}` e.g. `macbook-cleaner-pro-a4f2`
Collision check performed at write time; retry with new suffix on collision.

### `licenses` collection — new top-level collection

```
licenses/{licenseKey}
  licenseKey: string           # doc ID, format XXXX-XXXX-XXXX-XXXX
  productId: string
  orderId: string
  buyerId: string
  digitalType: "software" | "book"
  status: "active" | "revoked"
  supportedPlatforms: string[] # software only ["macos", "windows", "linux"]
  deviceLimit: int | null      # software only
  activations: [               # software only
    { deviceId, platform, activatedAt, lastVerifiedAt }
  ]
  bookSourceUrl: string | null # book only, kept server-side
  createdAt: timestamp
```

### `book_access_tokens` collection — ephemeral, per-download-session

```
book_access_tokens/{token}
  token: string          # doc ID, "tok_" + 32 random hex
  licenseKey: string
  buyerId: string
  productId: string
  bookSourceUrl: string  # copied from license at generation time
  expiresAt: timestamp   # now + 15 minutes
  used: bool             # single-use: true after first redirect
  createdAt: timestamp
```

### Order item — additions

| Field | Type | Notes |
|---|---|---|
| `licenseKey` | string? | reference into licenses collection |
| `digitalUnlocked` | bool | false until payment confirmed |

---

## 2. Add Product Flow (Seller)

### UI changes in `addproduct_screen.dart`

When `isDigital = true`, show a new "Digital Product" section:

```
Sub-type:  ● Software   ○ Book

── SOFTWARE ──
macOS download URL   (.dmg)     [required if software]
Windows download URL (.exe/.msi) [optional]
Linux download URL   (.deb/.AppImage) [optional]
Device limit         [number, optional — blank = unlimited]

── BOOK ──
Download source URL  [required, https:// only]
Version/edition label [optional, e.g. "2nd Edition"]
```

### Validations

**Frontend (soft, immediate feedback):**
- `digitalType` required when `isDigital=true`
- Software: at least one platform URL required
- All URLs: must start with `https://`
- URLs must not end in `.php` or `.html` (warn only)
- `deviceLimit` ≥ 1 if provided

**Backend (hard, enforced in handler):**
- Same URL rules
- `bookSourceUrl` length ≤ 2048
- `digitalBuilds` keys must be in `["macos", "windows", "linux"]`
- `deviceLimit` must be positive int or null
- `digitalType` must be `"software"` or `"book"`

### Slug generation (backend, at product creation)

```python
def generate_product_slug(title: str) -> str:
    base = re.sub(r'[^a-z0-9]+', '-', title.lower()).strip('-')[:40]
    suffix = secrets.token_hex(2)  # 4 hex chars
    return f"{base}-{suffix}"
```

Collision check: if `slug` already exists in products collection, regenerate with new suffix.

---

## 3. Payment → License Generation

Hook into `process_checkout_session_completed()` in `payment_stripe.py`, after order is confirmed.

### `_generate_digital_licenses(order_id, order_data)`

```
for each order item where isDigital=true and digitalUnlocked=false:
  fetch product doc → get digitalType, digitalBuilds/bookSourceUrl, deviceLimit

  generate licenseKey = _generate_license_key()
  # format: XXXX-XXXX-XXXX-XXXX (crypto-random A-Z0-9)
  # collision check against licenses collection

  if digitalType == "software":
    write licenses/{licenseKey}:
      all fields, activations=[], supportedPlatforms=list(digitalBuilds.keys())
    update order item: licenseKey, digitalUnlocked=true

  if digitalType == "book":
    write licenses/{licenseKey}:
      all fields, bookSourceUrl=product.bookSourceUrl
    update order item: licenseKey, digitalUnlocked=true

  send digital delivery email (separate from order confirmation):
    software → license key + platform download URLs
    book     → "Your book is ready — tap Download in your order"
```

**Idempotency guard:** check `digitalUnlocked=true` on item before generating. Webhook retries safe.

---

## 4. Book Download API (2-step)

**Step 1 — authenticated: generate session token**

```
CF: generate_book_download_session(licenseKey)
  Auth: Firebase ID token required (buyer only)
  Checks:
    license exists
    license.buyerId == caller uid
    license.status == "active"
    license.digitalType == "book"
  Action:
    generate token = "tok_" + secrets.token_hex(32)
    write book_access_tokens/{token}
    return { downloadUrl: "https://app.origna.com/dl?t={token}" }
```

**Step 2 — unauthenticated redirect (follows the link)**

```
CF: get_book_redirect(t: query param)
  No auth required (link may be opened in browser)
  Checks:
    token doc exists
    token.used == false
    token.expiresAt > now
  Action:
    atomic update: used=true
    HTTP 302 → token.bookSourceUrl
  On fail:
    HTTP 410 Gone (expired or already used)
```

Security properties:
- Raw `bookSourceUrl` never touches the client
- Token is single-use + 15-min window
- Re-download = buyer clicks "Download" again → fresh token
- Open redirect protected: URL stored server-side at product creation, validated to be `https://`

---

## 5. Software License Activation API

**Activate (called by installed app — no Firebase auth)**

```
POST /activate_license
Body: { licenseKey, deviceId, platform }

Checks (in order):
  1. license exists → 404 if not
  2. license.status == "active" → 403 revoked if not
  3. platform in license.supportedPlatforms → 403 platform_not_supported
  4. deviceId already in activations → 200 approved (idempotent)
  5. activations.length < deviceLimit (or deviceLimit is null) → add, 200 approved
  6. else → 403 device_limit_exceeded

Response 200:
  {
    approved: true,
    licenseKey: "XXXX-XXXX-XXXX-XXXX",
    productName: "...",
    downloadUrls: { macos: "...", windows: "...", linux: "..." },
    activatedAt: "..."
  }

Side effect: update activations[], lastVerifiedAt on existing activation
```

**Deactivate (authenticated — buyer removes a device)**

```
POST /deactivate_license
Auth: Firebase ID token required
Body: { licenseKey, deviceId }
Checks: license.buyerId == caller uid
Action: remove deviceId from activations[]
```

**Periodic re-verification (called by app when online)**

```
POST /verify_license
Body: { licenseKey, deviceId, platform }  # no auth, same as activate
→ same checks, updates lastVerifiedAt, returns approved/revoked
→ app caches result locally for offline use
```

---

## 6. Product Slug & Sharing

### Route
`/p/{slug}` → product detail page
Added to `AppRoutes` and `onGenerateRoute`.

Web: render product detail page directly.
Mobile/desktop: deep link via existing `app_links` subscription → `pushNamed('/p/$slug')` → resolve slug to productId → ProductDetailsScreen.

### Share button
Added to product detail screen (top-right action).
Share URL: `https://origna.com/p/{slug}`
Uses Flutter `share_plus` (already in pubspec or to be added).

### Slug lookup
Backend: Firestore query `products.where('slug', '==', slug).limit(1)`.
Frontend: `ProductRepository.getProductBySlug(slug)` → wraps same query.
Algolia: `slug` added to indexed attributes for search routing (optional v2).

---

## 7. UI — Order Screen Changes

When an order item has `isDigital=true` and `digitalUnlocked=true`:

**Software item card:**
```
[License Key]  XXXX-XXXX-XXXX-XXXX  [Copy]
[Download]  macOS  /  Windows  /  Linux   ← opens external URL directly
[Manage Devices]  (2 / 3 activated)       ← shows activations, deactivate button
```

**Book item card:**
```
[Download Book]  ← calls generate_book_download_session → opens redirect URL
```

No "Track Shipment" shown for digital items. Status chip shows "Delivered" immediately on unlock.

---

## 8. Security Checklist

- [ ] `bookSourceUrl` never returned to any client endpoint
- [ ] `activate_license` rate-limited (10 req/min per IP via Cloud Armor or Functions rate limit)
- [ ] `generate_book_download_session` requires valid Firebase auth token
- [ ] License key format validated server-side before lookup (regex)
- [ ] `deactivate_license` checks buyerId ownership
- [ ] Book redirect uses atomic Firestore transaction to prevent race on `used=true`
- [ ] Open redirect: `bookSourceUrl` validated as `https://` at product creation, not re-validated at redirect (trust the stored value)
- [ ] Slug collision handled with retry loop (max 5 attempts)
- [ ] Digital license generation is idempotent (check `digitalUnlocked` flag)

---

## 9. Files Touched

| File | Change |
|---|---|
| `functions/schema_constants.py` | Add `DIGITAL_TYPE`, `SLUG`, `DIGITAL_BUILDS`, `BOOK_SOURCE_URL`, `DEVICE_LIMIT`, `LICENSE_KEY`, `DIGITAL_UNLOCKED`, `SUPPORTED_PLATFORMS`, `ACTIVATIONS` |
| `functions/models/product.py` | Add `digitalType`, `slug`, `digitalBuilds`, `bookSourceUrl`, `deviceLimit` |
| `functions/models/order.py` | Add `licenseKey`, `digitalUnlocked` to order item |
| `functions/handlers/payment_stripe.py` | Add `_generate_digital_licenses()` call after order confirmed |
| `functions/handlers/digital.py` | New file: `activate_license`, `deactivate_license`, `verify_license`, `generate_book_download_session`, `get_book_redirect` |
| `functions/main.py` | Register new digital handlers |
| `lib/core/schema/schema_constants.dart` | Sync all new constants |
| `lib/models/generated/product_models.dart` | Add new fields |
| `lib/models/generated/order_models.dart` | Add `licenseKey`, `digitalUnlocked` to item |
| `lib/core/repositories/product_repository.dart` | Add `getProductBySlug()` |
| `lib/core/routes.dart` | Add `/p/{slug}` route + `ProductSlugArgs` |
| `lib/origna_app.dart` | Handle `/p/{slug}` in `onGenerateRoute` + deep link handler |
| `lib/features/products/add_product_state.dart` | Add `digitalType`, `digitalBuilds`, `bookSourceUrl`, `deviceLimit` |
| `lib/features/products/add_product_viewmodel.dart` | Add setters + validation for digital fields |
| `lib/screens/addproduct_screen.dart` | Add digital sub-type UI section |
| `lib/screens/productdetails_screen.dart` | Add share button |
| `lib/features/orders/` | Add license display, download button, device management |
| `docs/database_schema.json` | Add new fields and collections |
| `firestore.rules` | Add rules for `licenses` and `book_access_tokens` |
| `firestore.indexes.json` | Add slug index, licenses composite indexes |
