# Backend / OrignaBase Rules — origna_gta

## OrignaBase is the Backend (Firebase is GONE)
- All data, auth, search through OrignaBase SDK (`orignabase/sdks/flutter/orignabase`)
- Firebase has been fully replaced — no Firestore, no Firebase Auth, no Firebase Storage, no Cloud Functions
- Web hosting uses VPS (Caddy) — rsync to `204.168.137.16:/var/www/orignagta/{env}/current`
- PostgreSQL accessed only via OrignaBase (never directly from Flutter)
- Meilisearch accessed only via OrignaBase (never directly from Flutter)

## Environments
| Env | OrignaBase URL | Flutter flag |
|-----|----------------|-------------|
| emulator | `http://localhost:8080` | `ENVIRONMENT=emulator` |
| dev | `https://api.dev.orignagta.ca` | `ENVIRONMENT=dev` |
| staging | `https://api.staging.orignagta.ca` | `ENVIRONMENT=staging` |
| production | `https://api.orignagta.ca` | `ENVIRONMENT=production` |

- Source: `lib/utils/env_config.dart` — never hardcode URLs
- Build: `flutter build web --dart-define=ENVIRONMENT=dev`

## Authentication (OrignaBase — not Firebase)
- OrignaBase handles all auth: `/auth/register`, `/auth/login`, `/auth/google/start`
- Never manually refresh tokens — SDK handles this
- Logout: `OrignaBaseAuth.signOut()` — clears SDK state
- Admin operations require `admin` role in `users` PostgreSQL record

## Schema — Timestamp Fields (CRITICAL)
| Collection | Timestamp field |
|------------|----------------|
| `orders`, `users`, `payouts`, `return_requests` | `createdAt` |
| `products`, `cart` | `dateCreated` |
| `webhook_events` | `timestamp` |

Mixing these up causes sort/query failures. Always use `schema_constants.dart`.

## Money / Pricing (non-negotiable)
- **ALL monetary values in integer cents**
- Field names: `priceCents`, `subtotalCents`, `taxAmountCents`, `totalAmountCents`, `shippingCostCents`
- Platform fee: `platformFeeTotalCents / subtotalCents` (not totalAmountCents)
- Free shipping threshold: `BusinessRules.freeShippingThresholdCents = 7500` ($75 CAD)
- Never use `double` for money — rounding errors accumulate

## Products
- `lifecycleStatus`: `draft` → `active` → `inactive` → `deleted`
- Digital (`isDigital: true`): no weight, no shipping, no perishable
- Perishable (`isPerishable: true`): ≤ 50km local delivery, no cross-province shipping
- Images: Cloudflare R2 URLs (never Firebase Storage for products)
- Stock: `stockQuantity` (integer); 0 = out of stock

## PostgreSQL IDs
- Format: standard UUID (e.g., `abc123-def456-...`)
- For Meilisearch: use the record ID directly as document ID

## Search (Meilisearch config)
- Filterable: `lifecycleStatus`, `categoryId`, `subcategory`, `priceCents`, `sellerId`, `isPerishable`
- Sortable: `priceCents`, `createdAt`
- Searchable: `title`, `name`, `description`, `keywords`, `subcategory`

## API Patterns
- OrignaBase SDK methods return `Result<T, AppError>` — handle both branches
- Retry logic is in SDK — don't add custom retry loops
- Pagination: `limit` + `offset`; default page size = 20
- Never fetch all records — always paginate

## OrignaBase VPS Info (for ops/debugging only)
- IP: `204.168.137.16` | SSH: `ssh -i ~/.ssh/id_ed25519 root@204.168.137.16`
- Docker Compose at `/opt/orignabase/`
- PostgreSQL creds: stored in VPS `.env` files, database: `orignabase`
- Meilisearch master key: stored in VPS `.env` file — never hardcode or log it.

## Forbidden
- ❌ Any Firebase SDK calls from Flutter (Firestore, Auth, Storage, Functions — all gone)
- ❌ Hardcoded OrignaBase URLs — use `EnvConfig`
- ❌ Float/double for money
- ❌ Direct PostgreSQL or Meilisearch connections from Flutter
- ❌ Bypassing OrignaBase SDK with raw HTTP calls
- ❌ Storing Stripe card data anywhere
