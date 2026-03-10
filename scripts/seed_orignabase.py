#!/usr/bin/env python3
"""
Seed OrignaBase VPS — Dev Data
================================
Creates users, products, orders, and other collections on the OrignaBase
VPS at 204.168.137.16 via its REST/GraphQL API.

Mirrors the data structure from mega_seed_dev.py but targets OrignaBase
instead of Firestore.

Usage:
  python scripts/seed_orignabase.py [--url http://204.168.137.16:8080]
"""

from __future__ import annotations

import argparse
import datetime
import json
import sys
import time
import requests

DEFAULT_URL = "http://204.168.137.16:8080"

# ── Test accounts (must match E2E helpers) ──
ACCOUNTS = {
    "admin": {"email": "yr62813@gmail.com", "password": "TestAdmin2026!"},
    "buyer": {"email": "buyer_e2e@origna.dev", "password": "BuyerTest2026!"},
    "seller1": {"email": "seller1_e2e@origna.dev", "password": "SellerTest2026!"},
    "seller2": {"email": "seller2_e2e@origna.dev", "password": "SellerTest2026!"},
}

PREFIX = "mseed_"


def _now_iso() -> str:
    return datetime.datetime.now(datetime.timezone.utc).isoformat()


class OrignaBaseSeeder:
    def __init__(self, base_url: str):
        self.url = base_url.rstrip("/")
        self.session = requests.Session()
        self.tokens: dict[str, str] = {}  # role -> access_token

    def _gql(self, query: str, variables: dict | None = None, token: str | None = None) -> dict:
        headers = {"Content-Type": "application/json"}
        if token:
            headers["Authorization"] = f"Bearer {token}"
        payload: dict = {"query": query}
        if variables:
            payload["variables"] = variables
        resp = self.session.post(f"{self.url}/graphql", json=payload, headers=headers, timeout=30)
        resp.raise_for_status()
        data = resp.json()
        if "errors" in data:
            print(f"  GraphQL error: {data['errors']}", file=sys.stderr)
        return data

    def _create_doc(self, collection: str, doc_id: str, data: dict, token: str) -> dict:
        return self._gql(
            """mutation($collection: String!, $id: String!, $data: JSON!) {
                create(collection: $collection, id: $id, data: $data) { id }
            }""",
            {"collection": collection, "id": doc_id, "data": data},
            token,
        )

    def register_user(self, email: str, password: str) -> dict:
        resp = self.session.post(
            f"{self.url}/auth/register",
            json={"email": email, "password": password},
            timeout=30,
        )
        if resp.status_code == 409:
            # Already exists — login instead
            return self.login_user(email, password)
        resp.raise_for_status()
        return resp.json()

    def login_user(self, email: str, password: str) -> dict:
        resp = self.session.post(
            f"{self.url}/auth/login",
            json={"email": email, "password": password},
            timeout=30,
        )
        resp.raise_for_status()
        return resp.json()

    def health_check(self) -> bool:
        try:
            resp = self.session.get(f"{self.url}/health", timeout=10)
            return resp.status_code == 200 and resp.text.strip() == "ok"
        except Exception as e:
            print(f"Health check failed: {e}")
            return False

    def setup_accounts(self):
        print("=== Setting up accounts ===")
        for role, creds in ACCOUNTS.items():
            try:
                result = self.register_user(creds["email"], creds["password"])
                token = result.get("access_token") or result.get("token")
                if token:
                    self.tokens[role] = token
                    print(f"  {role}: registered/logged in ({creds['email']})")
                else:
                    print(f"  {role}: no token in response: {result}")
            except Exception as e:
                print(f"  {role}: FAILED — {e}")

    def seed_products(self):
        print("\n=== Seeding products ===")
        token = self.tokens.get("admin") or self.tokens.get("seller1")
        if not token:
            print("  No token available, skipping")
            return

        products = [
            {
                "id": "product_001",
                "name": "Organic Maple Syrup",
                "description": "Pure Canadian Grade A maple syrup from Quebec.",
                "price": 24.99,
                "priceCents": 2499,
                "stockQuantity": 100,
                "categoryId": 1,
                "lifecycleStatus": "active",
                "sellerId": "seller1_uid",
                "isDigital": False,
                "isPerishable": False,
                "isLocalDeliveryOnly": False,
                "freeShipping": False,
                "weightKg": 0.5,
                "shipFromCity": "Montreal",
                "shipFromProvince": "QC",
                "shipFromCountry": "Canada",
                "imageUrls": ["https://picsum.photos/seed/maple/600/600"],
                "keywords": ["maple", "syrup", "organic", "quebec"],
            },
            {
                "id": "product_002",
                "name": "Handmade Wool Scarf",
                "description": "Warm hand-knitted scarf from Nova Scotia artisan.",
                "price": 45.00,
                "priceCents": 4500,
                "stockQuantity": 30,
                "categoryId": 2,
                "lifecycleStatus": "active",
                "sellerId": "seller1_uid",
                "isDigital": False,
                "isPerishable": False,
                "isLocalDeliveryOnly": False,
                "freeShipping": False,
                "weightKg": 0.2,
                "shipFromCity": "Halifax",
                "shipFromProvince": "NS",
                "shipFromCountry": "Canada",
                "imageUrls": ["https://picsum.photos/seed/scarf/600/600"],
                "keywords": ["scarf", "wool", "handmade", "winter"],
            },
            {
                "id": "product_003",
                "name": "Artisan Coffee Beans",
                "description": "Single-origin Ethiopian beans roasted in Toronto.",
                "price": 18.50,
                "priceCents": 1850,
                "stockQuantity": 200,
                "categoryId": 1,
                "lifecycleStatus": "active",
                "sellerId": "seller2_uid",
                "isDigital": False,
                "isPerishable": True,
                "isLocalDeliveryOnly": False,
                "freeShipping": False,
                "weightKg": 0.35,
                "shipFromCity": "Toronto",
                "shipFromProvince": "ON",
                "shipFromCountry": "Canada",
                "imageUrls": ["https://picsum.photos/seed/coffee/600/600"],
                "keywords": ["coffee", "beans", "artisan", "ethiopian"],
            },
            {
                "id": "product_010",
                "name": "Canadian History eBook Bundle",
                "description": "Digital bundle of 5 Canadian history eBooks.",
                "price": 14.99,
                "priceCents": 1499,
                "stockQuantity": 9999,
                "categoryId": 5,
                "lifecycleStatus": "active",
                "sellerId": "seller1_uid",
                "isDigital": True,
                "isPerishable": False,
                "isLocalDeliveryOnly": False,
                "freeShipping": True,
                "weightKg": 0,
                "imageUrls": ["https://picsum.photos/seed/ebook/600/600"],
                "keywords": ["ebook", "history", "canada", "digital"],
            },
            {
                "id": "e2e_product_test_seller",
                "name": "E2E Test Product",
                "description": "Test product for E2E automation.",
                "price": 10.00,
                "priceCents": 1000,
                "stockQuantity": 999,
                "categoryId": 1,
                "lifecycleStatus": "active",
                "sellerId": "seller1_uid",
                "isDigital": False,
                "isPerishable": False,
                "isLocalDeliveryOnly": False,
                "freeShipping": False,
                "weightKg": 0.5,
                "shipFromCity": "Toronto",
                "shipFromProvince": "ON",
                "shipFromCountry": "Canada",
                "imageUrls": ["https://picsum.photos/seed/e2e/600/600"],
                "keywords": ["test", "e2e"],
            },
            {
                "id": "e2e_product_intl_seller",
                "name": "International Seller Product",
                "description": "Product from international seller for shipping tests.",
                "price": 29.99,
                "priceCents": 2999,
                "stockQuantity": 50,
                "categoryId": 3,
                "lifecycleStatus": "active",
                "sellerId": "seller2_uid",
                "isDigital": False,
                "isPerishable": False,
                "isLocalDeliveryOnly": False,
                "freeShipping": False,
                "weightKg": 1.0,
                "shipFromCity": "New York",
                "shipFromProvince": "NY",
                "shipFromCountry": "United States",
                "imageUrls": ["https://picsum.photos/seed/intl/600/600"],
                "keywords": ["international", "test"],
            },
        ]

        for p in products:
            doc_id = p.pop("id")
            p["dateCreated"] = _now_iso()
            p["dateUpdated"] = _now_iso()
            try:
                result = self._create_doc("products", doc_id, p, token)
                status = "ok" if "errors" not in result else "error"
                print(f"  {doc_id}: {status}")
            except Exception as e:
                print(f"  {doc_id}: FAILED — {e}")

    def seed_users(self):
        print("\n=== Seeding user profiles ===")
        token = self.tokens.get("admin")
        if not token:
            print("  No admin token, skipping")
            return

        profiles = [
            {
                "id": "admin_uid",
                "email": ACCOUNTS["admin"]["email"],
                "displayName": "Yunior Admin",
                "roles": ["admin", "buyer"],
                "preferredLanguage": "en",
                "emailConsent": True,
                "termsAcceptedAt": _now_iso(),
            },
            {
                "id": "buyer_uid",
                "email": ACCOUNTS["buyer"]["email"],
                "displayName": "Test Buyer",
                "roles": ["buyer"],
                "preferredLanguage": "en",
                "emailConsent": True,
            },
            {
                "id": "seller1_uid",
                "email": ACCOUNTS["seller1"]["email"],
                "displayName": "Seller One",
                "roles": ["seller", "buyer"],
                "preferredLanguage": "en",
                "emailConsent": True,
                "sellerProfile": {
                    "storeName": "Seller One Store",
                    "storeDescription": "Quality Canadian products",
                    "approved": True,
                },
            },
            {
                "id": "seller2_uid",
                "email": ACCOUNTS["seller2"]["email"],
                "displayName": "Seller Two",
                "roles": ["seller", "buyer"],
                "preferredLanguage": "fr",
                "emailConsent": True,
                "sellerProfile": {
                    "storeName": "Boutique Deux",
                    "storeDescription": "International seller",
                    "approved": True,
                },
            },
        ]

        for profile in profiles:
            doc_id = profile.pop("id")
            profile["createdAt"] = _now_iso()
            try:
                result = self._create_doc("users", doc_id, profile, token)
                status = "ok" if "errors" not in result else "error"
                print(f"  {doc_id}: {status}")
            except Exception as e:
                print(f"  {doc_id}: FAILED — {e}")

    def seed_config(self):
        print("\n=== Seeding remote config ===")
        token = self.tokens.get("admin")
        if not token:
            print("  No admin token, skipping")
            return

        configs = {
            "premium_price_cad": "9.99",
            "free_shipping_threshold_cents": "7500",
            "max_cart_items": "20",
            "maintenance_mode": "false",
            "feature_chat_enabled": "true",
            "feature_video_reviews": "true",
        }

        for key, value in configs.items():
            try:
                resp = self.session.put(
                    f"{self.url}/_admin/config",
                    json={"key": key, "value": value},
                    headers={"Authorization": f"Bearer {token}"},
                    timeout=10,
                )
                print(f"  {key}={value}: {resp.status_code}")
            except Exception as e:
                print(f"  {key}: FAILED — {e}")

    def run(self):
        print(f"OrignaBase Seeder — {self.url}")
        print("=" * 50)

        if not self.health_check():
            print("ERROR: OrignaBase health check failed. Is the server running?")
            sys.exit(1)

        print("Health check passed.\n")

        self.setup_accounts()
        self.seed_users()
        self.seed_products()
        self.seed_config()

        print("\n=== Seed complete ===")
        print(f"Tokens available for: {list(self.tokens.keys())}")


def main():
    parser = argparse.ArgumentParser(description="Seed OrignaBase VPS with dev data")
    parser.add_argument("--url", default=DEFAULT_URL, help="OrignaBase API URL")
    args = parser.parse_args()

    seeder = OrignaBaseSeeder(args.url)
    seeder.run()


if __name__ == "__main__":
    main()
