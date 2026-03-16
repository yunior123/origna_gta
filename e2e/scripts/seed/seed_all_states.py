#!/usr/bin/env python3
"""
seed_all_states.py — Comprehensive OrignaGTA Dev-Environment Seeder
====================================================================
Populates EVERY screen and widget with data in ALL states and variants
so that UI/UX debugging is possible without hitting the live backend.

Sections seeded
---------------
1. Products — 2000 total, all categories, all price ranges, all lifecycle states,
   all stock levels, digital / perishable / free-shipping mix.
2. Reviews — 0 / few / many review states, all star ratings (1-5), with/without text.
3. Q&A — 0 / few questions, unanswered / answered / multi-answer states.
4. Favorites — 20 products in buyer's favorites list.
5. Cart — 4 items in buyer's cart with different quantities.
6. Orders — all status states: pending, confirmed, shipped, delivered, cancelled.
7. Return requests — requested / approved / rejected states.
8. Notifications — various notification types in buyer's notifications subcollection.

Usage
-----
    cd e2e/scripts/seed
    pip install requests
    python3 seed_all_states.py            # uses defaults (dev environment)
    python3 seed_all_states.py --env dev  # explicit env flag (no-op, kept for CI compat)

Requirements
------------
- Python 3.10+
- requests library
- Network access to https://api.dev.orignagta.ca

Credentials (dev only)
----------------------
Admin  : yr62813@gmail.com / REDACTED_TEST_PASSWORD
Seller : yuniorrodriguezo4601@yahoo.com / REDACTED_TEST_PASSWORD
Buyer  : yuniorrodriguezo460@gmail.com / REDACTED_TEST_PASSWORD
"""

from __future__ import annotations

import argparse
import random
import sys
import time
import uuid
from datetime import datetime, timedelta, timezone
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BASE_URL = "https://api.dev.orignagta.ca"

ADMIN_EMAIL = "yr62813@gmail.com"
ADMIN_PASSWORD = "REDACTED_TEST_PASSWORD"
SELLER_EMAIL = "yuniorrodriguezo4601@yahoo.com"
SELLER_PASSWORD = "REDACTED_TEST_PASSWORD"
BUYER_EMAIL = "yuniorrodriguezo460@gmail.com"
BUYER_PASSWORD = "REDACTED_TEST_PASSWORD"

TOTAL_PRODUCTS = 2000

CATEGORIES = [
    (1, "Electronics", ["Smartphone", "Laptop", "Headphones", "Camera", "Tablet", "Smart Speaker", "Power Bank"]),
    (2, "Computers", ["Desktop PC", "Monitor", "Keyboard", "Mouse", "Router", "SSD", "RAM"]),
    (3, "Gaming", ["Console", "Controller", "Game", "Headset", "Gaming Chair", "GPU", "Capture Card"]),
    (4, "Home & Kitchen", ["Blender", "Coffee Maker", "Vacuum", "Toaster", "Microwave", "Air Fryer", "Instant Pot"]),
    (5, "Fashion", ["Jacket", "Jeans", "T-Shirt", "Sneakers", "Watch", "Hoodie", "Dress"]),
    (6, "Shoes & Accessories", ["Running Shoes", "Boots", "Sunglasses", "Belt", "Backpack", "Wallet", "Hat"]),
    (7, "Jewelry & Watches", ["Necklace", "Bracelet", "Ring", "Smartwatch", "Earrings", "Pendant", "Anklet"]),
    (8, "Beauty & Personal Care", ["Perfume", "Lotion", "Trimmer", "Hair Dryer", "Makeup", "Serum", "Shampoo"]),
    (9, "Health & Wellness", ["Vitamins", "Yoga Mat", "Theragun", "Protein", "Water Bottle", "Resistance Bands", "Foam Roller"]),
    (10, "Sports & Fitness", ["Dumbbells", "Bicycle", "Hockey Stick", "Soccer Ball", "Tennis Racket", "Skates", "Swimming Goggles"]),
    (11, "Automotive", ["Tires", "Oil", "Wipers", "Car Play", "Jump Starter", "Floor Mats", "Dash Cam"]),
    (12, "Tools & Hardware", ["Drill", "Saw", "Hammer", "Wrench Set", "Tape Measure", "Level", "Utility Knife"]),
    (13, "Office Supplies", ["Notebook", "Pens", "Desk", "Office Chair", "Printer", "Stapler", "Whiteboard"]),
    (14, "Books", ["Novel", "Textbook", "Cookbook", "Biography", "Comic", "Self-Help", "Science"]),
    (15, "Music & Instruments", ["Guitar", "Keyboard", "Drums", "Microphone", "Amp", "Violin", "Ukulele"]),
    (16, "Toys & Games", ["Lego", "Board Game", "Action Figure", "Puzzle", "Doll", "RC Car", "Science Kit"]),
    (17, "Baby & Kids", ["Stroller", "Crib", "Baby Monitor", "Toys", "Bibs", "High Chair", "Baby Carrier"]),
    (18, "Pet Supplies", ["Dog Food", "Cat Litter", "Leash", "Pet Bed", "Aquarium", "Scratching Post", "Pet Camera"]),
    (19, "Groceries", ["Coffee Beans", "Maple Syrup", "Pasta", "Olive Oil", "Tea", "Honey", "Granola"]),
    (20, "Art & Collectibles", ["Painting", "Sculpture", "Coin", "Stamp", "Poster", "Vintage Toy", "Sports Card"]),
    (21, "Digital Products", ["Software License", "E-Book", "Online Course", "Gift Card", "Subscription Box", "Music Album", "Photo Pack"]),
]

ADJECTIVES = ["Premium", "Essential", "Pro", "Elite", "Classic", "Modern", "Advanced", "Ultra", "Lite", "Max",
               "Canadian", "Heritage", "Signature", "Exclusive", "Limited", "Deluxe", "Compact", "Wireless"]
BRANDS = ["Samsung", "Apple", "Sony", "LG", "Asus", "Nike", "Adidas", "Breville", "Dyson", "DeWalt",
          "Lego", "Nintendo", "Canon", "Razer", "Philips", "Bosch", "Black+Decker", "KitchenAid"]

CITIES = ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa", "Edmonton", "Winnipeg", "Quebec City", "Hamilton", "Halifax"]
PROVINCES = ["ON", "BC", "QC", "AB", "ON", "AB", "MB", "QC", "ON", "NS"]
POSTAL_CODES = ["M5V 3A8", "V6B 1A1", "H3B 1A1", "T2P 1H7", "K1P 1J1", "T5J 2R7", "R3C 0V8", "G1R 4P5", "L8P 4S6", "B3J 1T9"]

REVIEW_TEXTS = [
    "Great product! Exactly as described. Fast shipping too.",
    "Really happy with this purchase. Would definitely buy again.",
    "Good quality for the price. Delivery was on time.",
    "Exceeded my expectations. Solid build quality.",
    "Decent product but packaging could be improved.",
    "Works perfectly. The seller was very responsive.",
    "Excellent value for money. Highly recommended.",
    "Product is as shown in the pictures. Happy with the purchase.",
    "Very good quality. My order arrived in perfect condition.",
    "Five stars! Will purchase again.",
    "OK product, does what it says.",
    "Not bad, but I expected better quality for this price.",
    "Amazing deal. Super fast delivery.",
    "Good overall but instructions were unclear.",
    "Exactly what I was looking for. Great experience.",
    "Arrived damaged. Seller replaced it quickly though.",
    "Poor quality. Not what I expected.",
    "Terrible experience. Do not recommend.",
    "Average product. Nothing special but gets the job done.",
    "Absolutely love it! Best purchase I've made this year.",
]

QUESTION_TEXTS = [
    "Is this compatible with Canadian voltage standards?",
    "Does this come with a warranty?",
    "What is the return policy for this item?",
    "Is there a French manual included?",
    "How long does delivery typically take to Toronto?",
    "Does this ship to Quebec?",
    "Is this product eligible for free shipping?",
    "Can I get this in a different color?",
    "What is the weight of this item?",
    "Is this item in stock for immediate shipping?",
    "Is this a genuine brand product or a knockoff?",
    "Can you ship this to a PO Box?",
    "What payment methods do you accept?",
    "Is this BPA-free?",
    "Does this come in a gift box?",
]

ANSWER_TEXTS = [
    "Yes, this product fully complies with Canadian standards.",
    "It comes with a 1-year manufacturer warranty.",
    "You can return it within 30 days if unopened.",
    "Yes, French documentation is included.",
    "Delivery to Toronto typically takes 3-5 business days.",
    "Yes, we ship across Canada including Quebec.",
    "Orders over $75 qualify for free shipping.",
    "Please contact us for color options.",
    "The item weighs approximately 1.2 kg.",
    "Yes, this item is in stock and ships within 24 hours.",
]

RETURN_REASONS = [
    "Item arrived damaged",
    "Product does not match description",
    "Wrong item received",
    "Item defective",
    "Changed my mind",
    "Better price found elsewhere",
    "Product quality not as expected",
]

NOTIFICATION_TYPES = [
    "order_confirmed",
    "order_shipped",
    "order_delivered",
    "new_review",
    "low_stock_alert",
    "price_drop",
    "back_in_stock",
    "return_request",
    "payout_processed",
    "new_message",
]

# ---------------------------------------------------------------------------
# Price ranges for variety
# ---------------------------------------------------------------------------
PRICE_BUCKETS = [
    (499, 1499),      # $5-$15 (budget)
    (1500, 4999),     # $15-$50 (mid-low)
    (5000, 9999),     # $50-$100 (mid)
    (10000, 19999),   # $100-$200 (mid-high)
    (20000, 50000),   # $200-$500 (premium)
    (50000, 200000),  # $500+ (luxury)
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def ts_ago(days: int = 0, hours: int = 0) -> int:
    dt = datetime.now(tz=timezone.utc) - timedelta(days=days, hours=hours)
    return int(dt.timestamp())


def login(email: str, password: str, label: str = "") -> tuple[str | None, str | None]:
    for attempt in range(5):
        try:
            resp = requests.post(
                f"{BASE_URL}/auth/login",
                json={"email": email, "password": password},
                timeout=15,
            )
            if resp.status_code == 200:
                data = resp.json()
                token = data.get("access_token")
                uid = data.get("user", {}).get("id")
                tag = f" ({label})" if label else ""
                print(f"  Logged in{tag}: {email} [uid={uid}]")
                return token, uid
            if resp.status_code == 429:
                print(f"  Rate limited, sleeping 5s (attempt {attempt + 1})")
                time.sleep(5)
                continue
            print(f"  Login failed {resp.status_code}: {resp.text[:200]}")
            return None, None
        except Exception as exc:
            print(f"  Login error: {exc}")
            time.sleep(3)
    return None, None


def graphql(token: str, query: str, variables: dict | None = None) -> dict:
    payload: dict = {"query": query}
    if variables:
        payload["variables"] = variables
    resp = requests.post(
        f"{BASE_URL}/graphql",
        json=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        timeout=20,
    )
    resp.raise_for_status()
    return resp.json()


def create_doc(token: str, collection: str, data: dict, retries: int = 3) -> str | None:
    """Insert a document via GraphQL; returns doc id on success, None on failure."""
    query = (
        "mutation CreateDoc($collection: String!, $data: JSON!) "
        "{ create(collection: $collection, data: $data) }"
    )
    for attempt in range(retries):
        try:
            result = graphql(token, query, {"collection": collection, "data": data})
            if "errors" in result:
                print(f"    GraphQL error in {collection}: {result['errors'][:1]}")
                return None
            return result.get("data", {}).get("create")
        except requests.HTTPError as exc:
            if exc.response is not None and exc.response.status_code == 429:
                time.sleep(3)
            else:
                print(f"    HTTP error: {exc}")
                return None
        except Exception as exc:
            print(f"    Error: {exc}")
            time.sleep(1)
    return None


def api_post(token: str, path: str, body: dict, retries: int = 3) -> dict | None:
    """POST to the REST API; returns parsed JSON or None."""
    for attempt in range(retries):
        try:
            resp = requests.post(
                f"{BASE_URL}{path}",
                json=body,
                headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                timeout=20,
            )
            if resp.status_code in (200, 201):
                return resp.json() if resp.text else {}
            if resp.status_code == 429:
                time.sleep(3)
                continue
            print(f"    POST {path} failed {resp.status_code}: {resp.text[:150]}")
            return None
        except Exception as exc:
            print(f"    POST {path} error: {exc}")
            time.sleep(1)
    return None


def list_products(token: str, limit: int = 200) -> list[dict]:
    query = """
query ListProducts($limit: Int!) {
  list(collection: "products", limit: $limit)
}
"""
    try:
        data = graphql(token, query, {"limit": limit})
        raw = data.get("data", {}).get("list") or []
        return raw[:limit]
    except Exception as exc:
        print(f"  Error listing products: {exc}")
        return []


# ---------------------------------------------------------------------------
# Section 1: Products
# ---------------------------------------------------------------------------

def generate_product(seller_id: str) -> dict:
    cat_id, cat_name, items = random.choice(CATEGORIES)
    item_type = random.choice(items)
    brand = random.choice(BRANDS)
    adj = random.choice(ADJECTIVES)
    name = f"{brand} {item_type} {adj} Edition"

    # Price variety
    price_bucket = random.choice(PRICE_BUCKETS)
    price_cents = random.randint(*price_bucket)

    is_digital = (cat_id == 21)
    is_perishable = (cat_id == 19)

    # Stock levels: 0 (OOS), 1-5 (low), 10-100 (normal), 1000+ (high)
    stock_choice = random.choices(
        [0, random.randint(1, 5), random.randint(10, 100), random.randint(500, 2000)],
        weights=[10, 15, 60, 15],
    )[0]

    # Lifecycle states: active (85%), inactive (8%), draft (7%)
    lifecycle = random.choices(
        ["active", "inactive", "draft"],
        weights=[85, 8, 7],
    )[0]

    city_idx = random.randint(0, len(CITIES) - 1)
    img_seed = uuid.uuid4().hex[:8]
    images = [
        f"https://picsum.photos/seed/{img_seed}_A/400/400",
        f"https://picsum.photos/seed/{img_seed}_B/400/400",
    ]

    created_ts = ts_ago(days=random.randint(0, 180))

    return {
        "name": name,
        "priceCents": price_cents,
        "description": (
            f"This is a high-quality {name}. "
            f"It features incredible specs and is designed to meet your needs. "
            f"Rated highly in the {cat_name} category."
        ),
        "imageUrls": images,
        "sellerId": seller_id,
        "sellerAddress": {
            "street": f"{random.randint(1, 999)} Main St",
            "apartment": None,
            "city": CITIES[city_idx],
            "state": PROVINCES[city_idx],
            "postalCode": POSTAL_CODES[city_idx],
            "country": "Canada",
            "phoneNumber": "4165551234",
            "isDefault": True,
            "label": "Storefront",
            "latitude": 43.6 + random.uniform(-3, 3),
            "longitude": -79.3 + random.uniform(-5, 5),
        },
        "categoryId": cat_id,
        "stockQuantity": stock_choice,
        "rating": round(random.uniform(1.0, 5.0), 1),
        "ratingCount": random.randint(0, 500),
        "keywords": [brand.lower(), item_type.lower(), adj.lower(), cat_name.lower()],
        "lifecycleStatus": lifecycle,
        "isDigital": is_digital,
        "isLocalDeliveryOnly": False,
        "isPerishable": is_perishable,
        "estimatedShipDays": 0 if is_digital else random.randint(1, 10),
        "minimumOrderQuantity": 1,
        "freeShipping": random.choice([True, False]),
        "weightKg": None if is_digital else round(random.uniform(0.1, 20.0), 1),
        "createdAt": created_ts,
        "deliveryOptions": [
            {
                "type": "standard",
                "description": "Standard Shipping",
                "cost": 0.0 if random.choice([True, False]) else 9.99,
                "estimatedDays": random.randint(3, 10),
                "quantityDiscounts": [],
                "maxItemsPerShipment": 0,
                "additionalItemCost": 0,
                "availableInternational": False,
            }
        ],
    }


def _create_product_task(args: tuple) -> bool:
    token, seller_id = args
    product_data = generate_product(seller_id)
    test_image_urls = product_data.pop("imageUrls", [])

    result = api_post(
        token,
        "/api/products/create-atomic",
        {
            "userId": seller_id,
            "productData": product_data,
            "testImageUrls": test_image_urls,
        },
    )
    return result is not None


def seed_products(admin_token: str, seller_id: str) -> list[dict]:
    print(f"\n[1/8] PRODUCTS — seeding {TOTAL_PRODUCTS} products...")
    tasks = [(admin_token, seller_id)] * TOTAL_PRODUCTS
    success = 0

    with ThreadPoolExecutor(max_workers=6) as executor:
        futures = {executor.submit(_create_product_task, t): i for i, t in enumerate(tasks)}
        for i, future in enumerate(as_completed(futures)):
            try:
                if future.result():
                    success += 1
            except Exception as exc:
                print(f"  Task error: {exc}")
            if (i + 1) % 200 == 0:
                print(f"  Progress: {i + 1}/{TOTAL_PRODUCTS} (ok={success})")

    print(f"  Done: {success}/{TOTAL_PRODUCTS} products created.")

    # Return a sample of products for downstream seeding
    print("  Fetching product list for reviews/orders...")
    time.sleep(2)  # Let DB settle
    return list_products(admin_token, limit=300)


# ---------------------------------------------------------------------------
# Section 2: Reviews (all star ratings, all states)
# ---------------------------------------------------------------------------

def seed_reviews(admin_token: str, products: list[dict], buyer_id: str) -> None:
    print(f"\n[2/8] REVIEWS — seeding reviews across {len(products)} products...")

    if not products:
        print("  No products found, skipping reviews.")
        return

    ok = fail = 0

    # Distribute review states:
    # 20% → 0 reviews (empty state — no writes)
    # 20% → 1 review (minimal state)
    # 30% → 3-5 reviews (few reviews)
    # 30% → 10-50 reviews (many reviews)
    for i, product in enumerate(products):
        product_id = product.get("id") or product.get("productId", "")
        if not product_id:
            continue
        seller_id = product.get("sellerId", "unknown")

        roll = random.random()
        if roll < 0.20:
            count = 0  # empty state
        elif roll < 0.40:
            count = 1  # minimal
        elif roll < 0.70:
            count = random.randint(3, 5)  # few
        else:
            count = random.randint(10, 50)  # many

        for j in range(count):
            # Ensure we cover all star ratings (1-5) for the first 5 products
            if i < 5:
                rating_val = (i % 5) + 1  # 1, 2, 3, 4, 5
            else:
                rating_val = random.choices([1, 2, 3, 4, 5], weights=[5, 10, 20, 30, 35])[0]

            # Mix: 80% with text, 20% rating-only
            include_text = random.random() > 0.20
            text = random.choice(REVIEW_TEXTS) if include_text else None

            doc = {
                "productId": product_id,
                "userId": buyer_id,
                "sellerId": seller_id,
                "rating": rating_val,
                "createdAt": ts_ago(days=random.randint(1, 90), hours=random.randint(0, 23)),
                "helpfulCount": random.randint(0, 25),
                "unhelpfulCount": random.randint(0, 5),
                "isFlagged": False,
                "hasPhotos": False,
                "reviewImageUrls": [],
                "isVerifiedPurchase": True,
            }
            if text:
                doc["reviewText"] = text

            result = create_doc(admin_token, "product_ratings", doc)
            if result:
                ok += 1
            else:
                fail += 1

    print(f"  Reviews: {ok} created, {fail} failed.")


# ---------------------------------------------------------------------------
# Section 3: Q&A
# ---------------------------------------------------------------------------

def seed_qa(admin_token: str, products: list[dict], buyer_id: str, seller_id: str) -> None:
    print(f"\n[3/8] Q&A — seeding questions and answers...")

    if not products:
        print("  No products found, skipping Q&A.")
        return

    ok = fail = 0

    for product in products:
        product_id = product.get("id") or product.get("productId", "")
        if not product_id:
            continue
        prod_seller_id = product.get("sellerId", seller_id)

        roll = random.random()
        if roll < 0.30:
            count = 0  # empty Q&A state
        elif roll < 0.55:
            count = random.randint(1, 2)  # few questions
        else:
            count = random.randint(3, 8)  # many questions

        pool = random.sample(QUESTION_TEXTS, min(count, len(QUESTION_TEXTS)))
        for i, question in enumerate(pool):
            days_ago = random.randint(1, 60)

            # States: unanswered (30%), answered (60%), multi-answer (10%)
            answer_count = random.choices([0, 1, 2], weights=[30, 60, 10])[0]

            doc = {
                "productId": product_id,
                "userId": buyer_id,
                "sellerId": prod_seller_id,
                "question": question,
                "questionText": question,
                "isAnswered": answer_count > 0,
                "createdAt": ts_ago(days=days_ago, hours=random.randint(0, 23)),
                "helpfulCount": random.randint(0, 10),
            }
            if answer_count > 0:
                doc["answer"] = random.choice(ANSWER_TEXTS)
                doc["answerText"] = doc["answer"]
                doc["answeredAt"] = ts_ago(days=max(0, days_ago - random.randint(1, 5)))

            result = create_doc(admin_token, "product_questions", doc)
            if result:
                ok += 1
            else:
                fail += 1

    print(f"  Q&A: {ok} created, {fail} failed.")


# ---------------------------------------------------------------------------
# Section 4: Favorites
# ---------------------------------------------------------------------------

def seed_favorites(admin_token: str, products: list[dict], buyer_id: str) -> None:
    print(f"\n[4/8] FAVORITES — adding 20 products to buyer's favorites...")

    if not products:
        print("  No products found, skipping favorites.")
        return

    sample = random.sample(products, min(20, len(products)))
    ok = fail = 0

    for product in sample:
        product_id = product.get("id") or product.get("productId", "")
        if not product_id:
            continue

        doc = {
            "userId": buyer_id,
            "productId": product_id,
            "createdAt": ts_ago(days=random.randint(1, 30)),
        }
        result = create_doc(admin_token, "favorites", doc)
        if result:
            ok += 1
        else:
            fail += 1

    print(f"  Favorites: {ok} created, {fail} failed.")


# ---------------------------------------------------------------------------
# Section 5: Cart items
# ---------------------------------------------------------------------------

def seed_cart(admin_token: str, products: list[dict], buyer_id: str) -> None:
    print(f"\n[5/8] CART — adding 4 items to buyer's cart...")

    if not products:
        print("  No products found, skipping cart.")
        return

    sample = random.sample(products, min(4, len(products)))
    ok = fail = 0

    quantities = [1, 2, 3, 1]  # varied quantities
    for i, product in enumerate(sample):
        product_id = product.get("id") or product.get("productId", "")
        if not product_id:
            continue

        doc = {
            "productId": product_id,
            "quantity": quantities[i % len(quantities)],
            "createdAt": ts_ago(days=random.randint(0, 5)),
        }

        # Write into users/{buyerId}/cart subcollection via direct doc creation
        query = """
mutation CreateCartItem($collection: String!, $docId: String!, $data: JSON!) {
  set(collection: $collection, id: $docId, data: $data)
}
"""
        cart_collection = f"users/{buyer_id}/cart"
        result = create_doc(admin_token, cart_collection, doc)
        if result:
            ok += 1
        else:
            fail += 1

    print(f"  Cart: {ok} items added, {fail} failed.")


# ---------------------------------------------------------------------------
# Section 6: Orders (all status states)
# ---------------------------------------------------------------------------

ORDER_STATUSES = [
    # (item_status, payment_status, count, has_tracking)
    ("pending", "authorized", 5, False),
    ("confirmed", "authorized", 5, False),
    ("shipped", "authorized", 5, True),
    ("delivered", "captured", 10, True),
    ("cancelled", "cancelled", 3, False),
]


def seed_orders(admin_token: str, products: list[dict], buyer_id: str, seller_id: str) -> list[dict]:
    print(f"\n[6/8] ORDERS — seeding orders in all status states...")

    if not products:
        print("  No products found, skipping orders.")
        return []

    created_orders = []
    ok = fail = 0

    active_products = [p for p in products if p.get("lifecycleStatus") == "active" or "id" in p]
    if not active_products:
        active_products = products

    for item_status, payment_status, count, has_tracking in ORDER_STATUSES:
        print(f"  Creating {count} '{item_status}' orders...")
        for _ in range(count):
            product = random.choice(active_products)
            product_id = product.get("id") or product.get("productId", "")
            if not product_id:
                continue

            price_cents = product.get("priceCents", 2999)
            qty = random.randint(1, 3)
            subtotal = price_cents * qty
            shipping_cents = 0 if product.get("freeShipping") else 999
            total = subtotal + shipping_cents
            platform_fee = int(total * 0.05)

            cart_item_id = str(uuid.uuid4())
            order_id = str(uuid.uuid4())
            days_ago = random.randint(1, 60)

            tracking_number = f"1Z{uuid.uuid4().hex[:14].upper()}" if has_tracking else None
            carrier = random.choice(["Canada Post", "UPS", "FedEx", "Purolator"]) if has_tracking else None

            items = [{
                "productId": product_id,
                "cartItemId": cart_item_id,
                "sellerId": seller_id,
                "name": product.get("name", "Product"),
                "quantity": qty,
                "priceCents": price_cents,
                "subtotalCents": subtotal,
                "itemStatus": item_status,
                "isDigital": product.get("isDigital", False),
                "isPerishable": product.get("isPerishable", False),
                "imageUrl": (product.get("imageUrls") or ["https://picsum.photos/seed/order/400/400"])[0],
                **({"trackingNumber": tracking_number, "carrier": carrier} if tracking_number else {}),
            }]

            doc = {
                "orderId": order_id,
                "userId": buyer_id,
                "sellerIds": [seller_id],
                "items": items,
                "subtotalCents": subtotal,
                "shippingCostCents": shipping_cents,
                "taxAmountCents": int(subtotal * 0.13),  # Ontario HST 13%
                "totalAmountCents": total + int(subtotal * 0.13),
                "platformFeeTotalCents": platform_fee,
                "paymentStatus": payment_status,
                "stripeSessionId": f"cs_test_{uuid.uuid4().hex}",
                "createdAt": ts_ago(days=days_ago, hours=random.randint(0, 23)),
                "shippingAddress": {
                    "street": "123 Buyer St",
                    "city": "Toronto",
                    "state": "ON",
                    "postalCode": "M5V 2H1",
                    "country": "Canada",
                    "phoneNumber": "4165559999",
                },
                "buyerEmail": BUYER_EMAIL,
                "buyerName": "Test Buyer",
            }

            result = create_doc(admin_token, "orders", doc)
            if result:
                ok += 1
                created_orders.append({
                    "orderId": order_id,
                    "cartItemId": cart_item_id,
                    "productId": product_id,
                    "buyerId": buyer_id,
                    "sellerId": seller_id,
                    "item_status": item_status,
                    "productName": product.get("name", "Product"),
                })
            else:
                fail += 1

    print(f"  Orders: {ok} created, {fail} failed.")
    return created_orders


# ---------------------------------------------------------------------------
# Section 7: Return Requests
# ---------------------------------------------------------------------------

RETURN_STATE_PLAN = [
    # (return_status, count)
    ("requested", 2),
    ("approved", 2),
    ("rejected", 1),
]


def seed_return_requests(admin_token: str, orders: list[dict], buyer_id: str, seller_id: str) -> None:
    print(f"\n[7/8] RETURN REQUESTS — seeding return requests...")

    delivered = [o for o in orders if o.get("item_status") == "delivered"]
    if not delivered:
        print("  No delivered orders available, skipping return requests.")
        return

    ok = fail = 0

    for return_status, count in RETURN_STATE_PLAN:
        for _ in range(count):
            if not delivered:
                break
            order = random.choice(delivered)

            doc = {
                "orderId": order["orderId"],
                "cartItemId": order["cartItemId"],
                "orderItemId": order["cartItemId"],
                "buyerId": buyer_id,
                "sellerId": seller_id,
                "productId": order["productId"],
                "productName": order.get("productName", "Product"),
                "quantity": 1,
                "returnStatus": return_status,
                "returnReason": random.choice(RETURN_REASONS),
                "requestedAt": ts_ago(days=random.randint(1, 14)),
                "updatedAt": ts_ago(days=random.randint(0, 3)),
                **({"returnAdminNote": "Return approved by admin."} if return_status == "approved" else {}),
                **({"returnAdminNote": "Return rejected: item not eligible."} if return_status == "rejected" else {}),
            }

            result = create_doc(admin_token, "return_requests", doc)
            if result:
                ok += 1
            else:
                fail += 1

    print(f"  Return requests: {ok} created, {fail} failed.")


# ---------------------------------------------------------------------------
# Section 8: Notifications
# ---------------------------------------------------------------------------

def seed_notifications(admin_token: str, products: list[dict], buyer_id: str) -> None:
    print(f"\n[8/8] NOTIFICATIONS — seeding buyer notifications...")

    ok = fail = 0
    sample_products = random.sample(products, min(10, len(products))) if products else []

    for notif_type in NOTIFICATION_TYPES:
        for _ in range(random.randint(1, 3)):
            product = random.choice(sample_products) if sample_products else None
            product_id = (product.get("id") or product.get("productId", "")) if product else ""
            product_name = product.get("name", "A Product") if product else "A Product"

            doc = {
                "type": notif_type,
                "title": _notif_title(notif_type, product_name),
                "body": _notif_body(notif_type, product_name),
                "isRead": random.choice([True, False]),
                "createdAt": ts_ago(days=random.randint(0, 30), hours=random.randint(0, 23)),
                "productId": product_id,
            }

            # Write into users/{buyerId}/notifications subcollection
            notif_collection = f"users/{buyer_id}/notifications"
            result = create_doc(admin_token, notif_collection, doc)
            if result:
                ok += 1
            else:
                fail += 1

    print(f"  Notifications: {ok} created, {fail} failed.")


def _notif_title(notif_type: str, product_name: str) -> str:
    titles = {
        "order_confirmed": "Order Confirmed!",
        "order_shipped": "Your order is on its way",
        "order_delivered": "Order Delivered",
        "new_review": f"New review for {product_name}",
        "low_stock_alert": f"Low stock: {product_name}",
        "price_drop": f"Price drop on {product_name}",
        "back_in_stock": f"{product_name} is back in stock",
        "return_request": "Return Request Update",
        "payout_processed": "Payout Processed",
        "new_message": "New message from buyer",
    }
    return titles.get(notif_type, "Notification")


def _notif_body(notif_type: str, product_name: str) -> str:
    bodies = {
        "order_confirmed": "Your order has been confirmed and will ship soon.",
        "order_shipped": f"Your {product_name} has shipped. Track your order.",
        "order_delivered": f"{product_name} has been delivered. How did we do?",
        "new_review": f"Someone left a review on {product_name}. Check it out.",
        "low_stock_alert": f"Only 2 units left of {product_name}. Restock soon!",
        "price_drop": f"{product_name} price has dropped. Grab it now.",
        "back_in_stock": f"Good news! {product_name} is back in stock.",
        "return_request": "A return request has been submitted for your order.",
        "payout_processed": "Your payout has been processed and is on its way.",
        "new_message": "A buyer sent you a message about your product.",
    }
    return bodies.get(notif_type, "You have a new notification.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Seed OrignaGTA dev environment")
    parser.add_argument("--env", default="dev", help="Environment (ignored, always dev)")
    args = parser.parse_args()

    print("=" * 65)
    print("OrignaGTA — Comprehensive Dev Seed (all UI states)")
    print(f"Target: {BASE_URL}")
    print("=" * 65)

    # Authenticate
    print("\nAuthenticating...")
    admin_token, admin_id = login(ADMIN_EMAIL, ADMIN_PASSWORD, "admin")
    if not admin_token:
        print("ERROR: Admin login failed. Aborting.")
        sys.exit(1)

    seller_token, seller_id = login(SELLER_EMAIL, SELLER_PASSWORD, "seller")
    if not seller_id:
        print("WARNING: Seller login failed, using admin as seller.")
        seller_id = admin_id

    _, buyer_id = login(BUYER_EMAIL, BUYER_PASSWORD, "buyer")
    if not buyer_id:
        print("WARNING: Buyer login failed, using admin as buyer.")
        buyer_id = admin_id

    start = time.time()

    # 1. Products
    products = seed_products(admin_token, seller_id)

    if not products:
        print("\nWARNING: No products returned after seeding. Downstream sections may be empty.")

    # 2. Reviews
    seed_reviews(admin_token, products, buyer_id)

    # 3. Q&A
    seed_qa(admin_token, products, buyer_id, seller_id)

    # 4. Favorites
    seed_favorites(admin_token, products, buyer_id)

    # 5. Cart
    seed_cart(admin_token, products, buyer_id)

    # 6. Orders
    orders = seed_orders(admin_token, products, buyer_id, seller_id)

    # 7. Return Requests
    seed_return_requests(admin_token, orders, buyer_id, seller_id)

    # 8. Notifications
    seed_notifications(admin_token, products, buyer_id)

    elapsed = time.time() - start
    print(f"\n{'=' * 65}")
    print(f"Done in {elapsed:.1f}s — all UI states seeded for https://dev.orignagta.ca")
    print("=" * 65)


if __name__ == "__main__":
    main()
