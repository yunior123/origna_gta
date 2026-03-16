#!/usr/bin/env python3
"""
Seed Orignabase Products — Creates ~2000 realistic Canadian marketplace products
in the live 'orignabase' dev database (https://api.dev.orignagta.ca).

Usage:
1. python3 e2e/scripts/seed/seed_orignabase_2000.py
"""

from __future__ import annotations

import random
import uuid
import time
import requests
from datetime import datetime, timedelta, timezone
import concurrent.futures

BASE_URL = "https://api.orignagta.ca"

CITIES = ["Toronto", "Vancouver", "Montreal", "Calgary", "Ottawa", "Edmonton", "Winnipeg", "Quebec City", "Hamilton", "Halifax"]
PROVINCES = ["ON", "BC", "QC", "AB", "ON", "AB", "MB", "QC", "ON", "NS"]
POSTAL_CODES = ["M5V 3A8", "V6B 1A1", "H3B 1A1", "T2P 1H7", "K1P 1J1", "T5J 2R7", "R3C 0V8", "G1R 4P5", "L8P 4S6", "B3J 1T9"]

CATEGORIES = [
    (1, "Electronics", ["Smartphone", "Laptop", "Headphones", "Camera", "Tablet"]),
    (2, "Computers", ["Desktop PC", "Monitor", "Keyboard", "Mouse", "Router"]),
    (3, "Gaming", ["Console", "Controller", "Game", "Headset", "Chair"]),
    (4, "Home & Kitchen", ["Blender", "Coffee Maker", "Vacuum", "Toaster", "Microwave"]),
    (5, "Fashion", ["Jacket", "Jeans", "T-Shirt", "Sneakers", "Watch"]),
    (6, "Shoes & Accessories", ["Running Shoes", "Boots", "Sunglasses", "Belt", "Backpack"]),
    (7, "Jewelry & Watches", ["Necklace", "Bracelet", "Ring", "Smartwatch", "Earrings"]),
    (8, "Beauty & Personal Care", ["Perfume", "Lotion", "Trimmer", "Hair Dryer", "Makeup"]),
    (9, "Health & Wellness", ["Vitamins", "Yoga Mat", "Theragun", "Protein", "Water Bottle"]),
    (10, "Sports & Fitness", ["Dumbbells", "Bicycle", "Hockey Stick", "Soccer Ball", "Tennis Racket"]),
    (11, "Automotive", ["Tires", "Oil", "Wipers", "Car Play", "Jump Starter"]),
    (12, "Tools & Hardware", ["Drill", "Saw", "Hammer", "Wrench Set", "Tape Measure"]),
    (13, "Office Supplies", ["Notebook", "Pens", "Desk", "Office Chair", "Printer"]),
    (14, "Books", ["Novel", "Textbook", "Cookbook", "Biography", "Comic"]),
    (15, "Music & Instruments", ["Guitar", "Keyboard", "Drums", "Microphone", "Amp"]),
    (16, "Toys & Games", ["Lego", "Board Game", "Action Figure", "Puzzle", "Doll"]),
    (17, "Baby & Kids", ["Stroller", "Crib", "Baby Monitor", "Toys", "Bibs"]),
    (18, "Pet Supplies", ["Dog Food", "Cat Litter", "Leash", "Pet Bed", "Aquarium"]),
    (19, "Groceries", ["Coffee Beans", "Maple Syrup", "Pasta", "Olive Oil", "Tea"]),
    (20, "Art & Collectibles", ["Painting", "Sculpture", "Coin", "Stamp", "Poster"]),
    (21, "Digital Products", ["Software", "E-Book", "Course", "Gift Card", "Subscription"]),
]

ADJECTIVES = ["Premium", "Essential", "Pro", "Elite", "Classic", "Modern", "Advanced", "Ultra", "Lite", "Max"]
BRANDS = ["Samsung", "Apple", "Sony", "LG", "Asus", "Nike", "Adidas", "Breville", "Dyson", "DeWalt", "Lego", "Nintendo", "Canon", "Razer"]

def generate_product(seller_id):
    cat_id, cat_name, items = random.choice(CATEGORIES)
    item_type = random.choice(items)
    brand = random.choice(BRANDS)
    adj = random.choice(ADJECTIVES)
    
    name = f"{brand} {item_type} {adj} Edition"
    price = round(random.uniform(9.99, 1499.99), 2)
    stock = random.randint(0, 500)
    city_idx = random.randint(0, len(CITIES) - 1)
    img_seed = uuid.uuid4().hex[:8]
    images = [
        f"https://picsum.photos/seed/{img_seed}_A/400/400",
        f"https://picsum.photos/seed/{img_seed}_B/400/400"
    ]
    is_digital = (cat_id == 21)
    created_ts = int((datetime.now(timezone.utc) - timedelta(days=random.randint(0, 100))).timestamp())

    return {
        "name": name,
        "price": price,
        "description": f"This is a high-quality {name}. It features incredible specs and is designed to meet your needs perfectly. Rated highly in {cat_name}.",
        "imageUrls": images,
        "sellerId": seller_id,
        "sellerAddress": {
            "street": f"{random.randint(1, 999)} Main St",
            "apartment": "",
            "city": CITIES[city_idx],
            "state": PROVINCES[city_idx],
            "postalCode": POSTAL_CODES[city_idx],
            "country": "Canada",
            "phoneNumber": "4165551234",
            "isDefault": True,
            "label": "Storefront",
            "latitude": 43.6 + random.uniform(-2, 2),
            "longitude": -79.3 + random.uniform(-4, 4),
        },
        "categoryId": cat_id,
        "stockQuantity": stock,
        "rating": round(random.uniform(3.0, 5.0), 1),
        "ratingCount": random.randint(0, 300),
        "keywords": [brand.lower(), item_type.lower(), adj.lower(), cat_name.lower()],
        "isActive": True,
        "createdAt": created_ts,
        "isDigital": is_digital,
        "isLocalDeliveryOnly": False,
        "isPerishable": (cat_id == 19),
        "estimatedShipDays": 0 if is_digital else random.randint(1, 7),
        "minimumOrderQuantity": 1,
        "freeShipping": random.choice([True, False]),
        "status": "active",
        "weightKg": None if is_digital else round(random.uniform(0.1, 20.0), 1),
        "deliveryOptions": [
            {
                "type": "standard",
                "description": "Standard Shipping",
                "cost": 0.0 if random.choice([True, False]) else 9.99,
                "estimatedDays": 5,
                "quantityDiscounts": [],
                "maxItemsPerShipment": 0,
                "additionalItemCost": 0,
                "availableInternational": False,
            }
        ]
    }

def register_or_login(base_url, email, password, name):
    for attempt in range(5):
        try:
            r = requests.post(f"{base_url}/auth/login", json={"email": email, "password": password}, timeout=10)
            if r.status_code == 200:
                data = r.json()
                print(f"Logged in dummy seller: {email}")
                return data.get("access_token"), data.get("user", {}).get("id")
            elif r.status_code == 429:
                print(f"Login rate limited, HTTP 429 Response: {r.headers} - {r.text}")
                print(f"Waiting 5 seconds... (Attempt {attempt+1})")
                time.sleep(5)
                continue
            elif r.status_code in (401, 404):
                # Try register
                reg_r = requests.post(f"{base_url}/auth/register", json={"email": email, "password": password, "display_name": name}, timeout=10)
                if reg_r.status_code in (200, 201):
                    data = reg_r.json()
                    print(f"Registered dummy seller: {email}")
                    return data.get("access_token"), data.get("user", {}).get("id")
                elif reg_r.status_code == 429:
                    print(f"Register rate limited, waiting 5 seconds...")
                    time.sleep(5)
                    continue
                else:
                    print(f"Register failed: {reg_r.status_code} - {reg_r.text}")
                    return None, None
            else:
                print(f"Login failed: {r.status_code} - {r.text}")
                return None, None
        except Exception as e:
            print(f"Auth error: {e}")
            time.sleep(5)
    return None, None

def create_product(args):
    base_url, token, product_data = args
    
    # Extract images and remove from productData (following Orignabase SDK pattern)
    test_image_urls = product_data.pop("imageUrls", [])
    uid = product_data.get("sellerId")
    
    payload = {
        "userId": uid,
        "productData": product_data,
        "testImageUrls": test_image_urls,
    }
    
    for attempt in range(5):
        try:
            r = requests.post(
                f"{base_url}/api/products/create-atomic",
                json=payload,
                headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
                timeout=15
            )
            print(f"create-atomic attempt {attempt+1} status: {r.status_code}")
            if r.status_code == 200 or r.status_code == 201:
                return True
            elif r.status_code == 429:
                time.sleep(2)
            else:
                print(f"Failed to create product: {r.status_code} - {r.text[:100]}")
                time.sleep(1)
        except Exception as e:
            print(f"create-atomic error: {e}")
            time.sleep(1)
    return False

def main():
    print(f"===========================================================")
    print(f"🍁 OrignaGTA — Bulk Seeding ~2000 Products via GraphQL API")
    print(f"   Target: {BASE_URL}")
    print(f"===========================================================")

    seller_email = "seller1@example.com"
    seller_pass = "TestPass123"
    
    token, uid = register_or_login(BASE_URL, seller_email, seller_pass, "Test Seller 1")
    if not token or not uid:
        print("Failed to authenticate with Orignabase. Aborting.")
        return


    
    TOTAL_PRODUCTS = 2
    print(f"\n📦 Generating {TOTAL_PRODUCTS} products...")
    
    products_to_create = [generate_product(uid) for _ in range(TOTAL_PRODUCTS)]
    tasks = [(BASE_URL, token, prod) for prod in products_to_create]
    
    print(f"🚀 Injecting products (in parallel)...")
    success_count = 0
    start_time = time.time()
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
        for i, result in enumerate(executor.map(create_product, tasks)):
            if result:
                success_count += 1
            if (i + 1) % 100 == 0:
                print(f"  ➜ Processed {i + 1}/{TOTAL_PRODUCTS}...")
                
    elapsed = time.time() - start_time
    print(f"\n🏁 Successfully seeded {success_count}/{TOTAL_PRODUCTS} products in {elapsed:.1f}s!")

if __name__ == "__main__":
    main()
