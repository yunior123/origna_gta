# /seed-dev — Seed the Dev Environment

**Usage**: `/seed-dev [products|reviews|all]`

## Prerequisites
- VPN/SSH not required — seed script hits `https://api.dev.orignagta.ca` directly
- Python 3.10+ with `requests` package
- Admin credentials: `yr62813@gmail.com` / `REDACTED_TEST_PASSWORD`

## Comprehensive All-States Seed (RECOMMENDED — TODO #6 + #8)
```bash
cd e2e/scripts/seed
pip3 install requests

# Seeds everything: products, reviews, Q&A, favorites, cart, orders,
# return requests, and notifications — covering ALL UI states.
python3 seed_all_states.py

echo "Done — all UI states seeded for https://dev.orignagta.ca"
```

### What `seed_all_states.py` seeds
| Section | Count | States covered |
|---------|-------|---------------|
| Products | 2000 | active / inactive / draft; all price ranges ($5–$2000+); stock: 0 / low / normal / high; digital / perishable / free-shipping |
| Reviews | varies | 0 (empty) / 1 (minimal) / 3-5 (few) / 10-50 (many); all star ratings 1-5; with and without text |
| Q&A | varies | 0 (empty) / few questions; unanswered / answered / multi-answer |
| Favorites | 20 | buyer's favorites list |
| Cart | 4 | items with qty 1-3 |
| Orders | 28 | pending(5) / confirmed(5) / shipped(5) / delivered(10) / cancelled(3) |
| Returns | 5 | requested(2) / approved(2) / rejected(1) |
| Notifications | ~30 | all notification types: order_confirmed, shipped, delivered, new_review, low_stock, price_drop, back_in_stock, return_request, payout, new_message |

## Seed Only Products (legacy)
```bash
cd e2e/scripts/seed
python3 seed_orignabase_2000.py
```

## Seed Only Reviews + Q&A (legacy)
```bash
cd e2e/scripts/seed
python3 seed_reviews.py
```

## Verify After Seeding
```bash
# Check Meilisearch has indexed products
curl -s "https://api.dev.orignagta.ca/search?q=&limit=1" | python3 -m json.tool | grep nbHits
```

## Seed Script Locations
- **All states (recommended)**: `e2e/scripts/seed/seed_all_states.py`
- Products only: `e2e/scripts/seed/seed_orignabase_2000.py`
- Reviews + Q&A only: `e2e/scripts/seed/seed_reviews.py`

## Category Coverage
All 21 categories seeded: Electronics, Computers, Gaming, Home & Kitchen, Fashion,
Shoes & Accessories, Jewelry & Watches, Beauty, Health, Sports, Automotive, Tools,
Office, Books, Music, Toys, Baby & Kids, Pet Supplies, Groceries, Art, Digital Products.
