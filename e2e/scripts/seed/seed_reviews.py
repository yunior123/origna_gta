#!/usr/bin/env python3
"""
Seed Reviews (product_ratings) and Q&A (product_questions) for dev environment.

Uses direct GraphQL mutations to bypass the orderId requirement of the
/api/products/submit-rating endpoint — suitable for test data only.

Usage:
    python3 e2e/scripts/seed/seed_reviews.py

Requirements:
    pip install requests
"""

from __future__ import annotations

import random
import sys
import time
import uuid
from datetime import datetime, timedelta, timezone

import requests

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

BASE_URL = "https://api.orignagta.ca"
ADMIN_EMAIL = "yr62813@gmail.com"
ADMIN_PASSWORD = "REDACTED_TEST_PASSWORD"
BUYER_EMAIL = "yuniorrodriguezo460@gmail.com"
BUYER_PASSWORD = "REDACTED_TEST_PASSWORD"

REVIEWS_PER_PRODUCT = 5
QUESTIONS_PER_PRODUCT = 3
MAX_PRODUCTS = 50  # Seed at most this many products to avoid timeout

# ---------------------------------------------------------------------------
# Review content pools
# ---------------------------------------------------------------------------

REVIEW_TEXTS_EN = [
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
]

ANSWER_TEXTS = [
    "Yes, this product fully complies with Canadian standards.",
    "It comes with a 1-year manufacturer warranty.",
    "You can return it within 30 days if unopened.",
    "Yes, French documentation is included.",
    "Delivery to Toronto typically takes 3–5 business days.",
    "Yes, we ship across Canada including Quebec.",
    "Orders over $75 qualify for free shipping.",
    "Please contact us for color options.",
    "The item weighs approximately 1.2 kg.",
    "Yes, this item is in stock and ships within 24 hours.",
]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def login(base_url: str, email: str, password: str) -> tuple[str | None, str | None]:
    """Log in and return (access_token, user_id)."""
    for attempt in range(3):
        try:
            resp = requests.post(
                f"{base_url}/auth/login",
                json={"email": email, "password": password},
                timeout=10,
            )
            if resp.status_code == 200:
                data = resp.json()
                return data.get("access_token"), data.get("user", {}).get("id")
            if resp.status_code == 429:
                print(f"Rate limited, waiting 5s… (attempt {attempt + 1})")
                time.sleep(5)
                continue
            print(f"Login failed: {resp.status_code} — {resp.text[:200]}")
            return None, None
        except Exception as exc:
            print(f"Login error: {exc}")
            time.sleep(3)
    return None, None


def graphql(
    base_url: str,
    token: str,
    query: str,
    variables: dict | None = None,
) -> dict:
    payload: dict = {"query": query}
    if variables:
        payload["variables"] = variables
    resp = requests.post(
        f"{base_url}/graphql",
        json=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        timeout=15,
    )
    resp.raise_for_status()
    return resp.json()


def list_products(base_url: str, token: str, limit: int = 50) -> list[dict]:
    """Fetch up to *limit* active products via GraphQL."""
    query = """
query ListProducts($limit: Int!) {
  list(collection: "products", filters: {isActive: {_eq: true}}, limit: $limit)
}
"""
    data = graphql(base_url, token, query, {"limit": limit + 1})  # +1 for hasMore check
    raw = data.get("data", {}).get("list") or []
    return raw[:limit]


def create_doc(base_url: str, token: str, collection: str, doc_data: dict) -> bool:
    """Insert a document into *collection* via GraphQL create mutation."""
    query = (
        'mutation CreateDoc($collection: String!, $data: JSON!) '
        '{ create(collection: $collection, data: $data) }'
    )
    for attempt in range(3):
        try:
            result = graphql(
                base_url, token, query, {"collection": collection, "data": doc_data}
            )
            if "errors" in result:
                print(f"  GraphQL error: {result['errors']}")
                return False
            return True
        except requests.HTTPError as exc:
            if exc.response is not None and exc.response.status_code == 429:
                print(f"  Rate limited, sleeping 3s… (attempt {attempt + 1})")
                time.sleep(3)
            else:
                print(f"  HTTP error: {exc}")
                return False
        except Exception as exc:
            print(f"  Error: {exc}")
            time.sleep(1)
    return False


def ts_ago(days: int = 0, hours: int = 0) -> int:
    """Return a Unix timestamp *days* and *hours* in the past."""
    dt = datetime.now(tz=timezone.utc) - timedelta(days=days, hours=hours)
    return int(dt.timestamp())


# ---------------------------------------------------------------------------
# Seeding functions
# ---------------------------------------------------------------------------


def seed_reviews(
    base_url: str,
    token: str,
    products: list[dict],
    buyer_id: str,
    count_per_product: int,
) -> tuple[int, int]:
    ok = fail = 0
    for product in products:
        product_id = product.get("id") or product.get("productId", "")
        if not product_id:
            continue
        seller_id = product.get("sellerId", "unknown")

        for i in range(count_per_product):
            rating_val = random.randint(3, 5)  # mostly positive reviews
            text = random.choice(REVIEW_TEXTS_EN) if random.random() > 0.2 else None
            days_ago = random.randint(1, 60)

            doc = {
                "productId": product_id,
                "userId": buyer_id,
                "sellerId": seller_id,
                "rating": rating_val,
                "createdAt": ts_ago(days=days_ago, hours=random.randint(0, 23)),
                "helpfulCount": random.randint(0, 15),
                "unhelpfulCount": random.randint(0, 3),
                "isFlagged": False,
                "hasPhotos": False,
                "reviewImageUrls": [],
            }
            if text:
                doc["reviewText"] = text

            result = create_doc(base_url, token, "product_ratings", doc)
            if result:
                ok += 1
            else:
                fail += 1

    return ok, fail


def seed_questions(
    base_url: str,
    token: str,
    products: list[dict],
    buyer_id: str,
    count_per_product: int,
) -> tuple[int, int]:
    ok = fail = 0
    for product in products:
        product_id = product.get("id") or product.get("productId", "")
        if not product_id:
            continue
        seller_id = product.get("sellerId", "unknown")

        questions_pool = random.sample(QUESTION_TEXTS, min(count_per_product, len(QUESTION_TEXTS)))
        for i, question in enumerate(questions_pool):
            days_ago = random.randint(1, 45)
            answered = random.random() > 0.4  # 60% have an answer

            doc = {
                "productId": product_id,
                "userId": buyer_id,
                "sellerId": seller_id,
                "question": question,
                "createdAt": ts_ago(days=days_ago, hours=random.randint(0, 23)),
                "helpfulCount": random.randint(0, 8),
            }
            if answered:
                doc["answer"] = random.choice(ANSWER_TEXTS)
                doc["answeredAt"] = ts_ago(days=max(0, days_ago - random.randint(1, 5)))

            result = create_doc(base_url, token, "product_questions", doc)
            if result:
                ok += 1
            else:
                fail += 1

    return ok, fail


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    print("=" * 60)
    print("OrignaGTA — Seed Reviews & Q&A")
    print(f"Target: {BASE_URL}")
    print("=" * 60)

    # Login as admin (admin token has write permissions for all collections)
    print("\nLogging in as admin…")
    admin_token, admin_id = login(BASE_URL, ADMIN_EMAIL, ADMIN_PASSWORD)
    if not admin_token or not admin_id:
        print("Admin login failed. Trying buyer account…")
        admin_token, admin_id = login(BASE_URL, BUYER_EMAIL, BUYER_PASSWORD)
        buyer_id = admin_id or "seed-buyer"
    else:
        # Also resolve buyer id for the review author field
        print("Logging in as buyer to get buyer ID…")
        _, buyer_id_raw = login(BASE_URL, BUYER_EMAIL, BUYER_PASSWORD)
        buyer_id = buyer_id_raw or admin_id or "seed-buyer"

    if not admin_token:
        print("ERROR: Could not authenticate with any account. Aborting.")
        sys.exit(1)

    print(f"  Admin ID : {admin_id}")
    print(f"  Buyer ID : {buyer_id}")

    # Fetch products
    print(f"\nFetching up to {MAX_PRODUCTS} products…")
    products = list_products(BASE_URL, admin_token, limit=MAX_PRODUCTS)
    print(f"  Found {len(products)} products")

    if not products:
        print("No products found. Run seed_orignabase_2000.py first.")
        sys.exit(1)

    # Seed reviews
    print(f"\nSeeding {REVIEWS_PER_PRODUCT} review(s) per product…")
    reviews_ok, reviews_fail = seed_reviews(
        BASE_URL, admin_token, products, buyer_id, REVIEWS_PER_PRODUCT
    )
    print(f"  Reviews created: {reviews_ok} / failed: {reviews_fail}")

    # Seed Q&A
    print(f"\nSeeding {QUESTIONS_PER_PRODUCT} Q&A(s) per product…")
    qa_ok, qa_fail = seed_questions(
        BASE_URL, admin_token, products, buyer_id, QUESTIONS_PER_PRODUCT
    )
    print(f"  Q&A created: {qa_ok} / failed: {qa_fail}")

    total_ok = reviews_ok + qa_ok
    total_fail = reviews_fail + qa_fail
    print(f"\nDone! {total_ok} documents created, {total_fail} failed.")


if __name__ == "__main__":
    main()
