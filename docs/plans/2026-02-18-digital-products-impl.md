# Digital Products Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Books + Software digital product support with license key delivery, server-side book redirect tokens, product slugs for sharing, and deep link routing.

**Architecture:** No file hosting — sellers provide external download URLs. On payment, backend generates license keys (XXXX-XXXX-XXXX-XXXX). Software uses JetBrains-style app activation; books use single-use 15-min server redirect tokens. Product slugs enable shareable `/p/{slug}` URLs that deep link into the app.

**Tech Stack:** Python/Pydantic (backend), Dart/Riverpod (Flutter), Firestore (licenses + tokens), existing `app_links` package (deep links), `share_plus` package (sharing)

**Design doc:** `docs/plans/2026-02-18-digital-products-design.md`

---

## Phase 1: Schema Constants

### Task 1: Add new constants to Python schema_constants.py

**Files:**
- Modify: `functions/schema_constants.py`

**Step 1: Write the failing test**

File: `functions/tests/test_schema_sync.py` — add to the bottom of the existing file:

```python
def test_digital_product_constants_exist():
    from schema_constants import Fields, Collections
    assert hasattr(Fields, 'DIGITAL_TYPE')
    assert hasattr(Fields, 'SLUG')
    assert hasattr(Fields, 'DIGITAL_BUILDS')
    assert hasattr(Fields, 'BOOK_SOURCE_URL')
    assert hasattr(Fields, 'DEVICE_LIMIT')
    assert hasattr(Fields, 'LICENSE_KEY')
    assert hasattr(Fields, 'DIGITAL_UNLOCKED')
    assert hasattr(Fields, 'SUPPORTED_PLATFORMS')
    assert hasattr(Fields, 'ACTIVATIONS')
    assert hasattr(Collections, 'LICENSES')
    assert hasattr(Collections, 'BOOK_ACCESS_TOKENS')

def test_digital_type_values_exist():
    from schema_constants import DigitalTypeValues, DigitalPlatformValues
    assert DigitalTypeValues.SOFTWARE == 'software'
    assert DigitalTypeValues.BOOK == 'book'
    assert 'macos' in DigitalPlatformValues.ALL
    assert 'windows' in DigitalPlatformValues.ALL
    assert 'linux' in DigitalPlatformValues.ALL
```

**Step 2: Run to confirm fail**

```bash
cd functions && python -m pytest tests/test_schema_sync.py::test_digital_product_constants_exist tests/test_schema_sync.py::test_digital_type_values_exist -v
```
Expected: `AttributeError` / `ImportError`

**Step 3: Add constants to `functions/schema_constants.py`**

Find the `class Fields:` block. After line with `IS_DIGITAL = "isDigital"` (~line 230), add:

```python
    # Digital product extended fields
    DIGITAL_TYPE = "digitalType"
    SLUG = "slug"
    DIGITAL_BUILDS = "digitalBuilds"
    BOOK_SOURCE_URL = "bookSourceUrl"
    DEVICE_LIMIT = "deviceLimit"
    LICENSE_KEY = "licenseKey"
    DIGITAL_UNLOCKED = "digitalUnlocked"
    SUPPORTED_PLATFORMS = "supportedPlatforms"
    ACTIVATIONS = "activations"
    DEVICE_ID = "deviceId"
    LAST_VERIFIED_AT = "lastVerifiedAt"
    ACCESS_TOKEN = "accessToken"
    BOOK_ACCESS_TOKEN = "bookAccessToken"
```

Find the `class Collections:` block, add:

```python
    LICENSES = "licenses"
    BOOK_ACCESS_TOKENS = "book_access_tokens"
```

Add two new value classes after the existing ones (e.g., after `PaymentStatusValues`):

```python
class DigitalTypeValues:
    SOFTWARE = "software"
    BOOK = "book"
    ALL = [SOFTWARE, BOOK]


class DigitalPlatformValues:
    MACOS = "macos"
    WINDOWS = "windows"
    LINUX = "linux"
    ALL = [MACOS, WINDOWS, LINUX]
```

**Step 4: Run to confirm pass**

```bash
cd functions && python -m pytest tests/test_schema_sync.py::test_digital_product_constants_exist tests/test_schema_sync.py::test_digital_type_values_exist -v
```
Expected: PASSED

**Step 5: Commit**

```bash
git add functions/schema_constants.py functions/tests/test_schema_sync.py
git commit -m "feat(schema): add digital product constants (license, slug, builds, tokens)"
```

---

### Task 2: Sync constants to Dart schema_constants.dart

**Files:**
- Modify: `origna_gta/lib/core/schema/schema_constants.dart`

**Step 1: Find the Fields class and add after `isDigital`**

Open `origna_gta/lib/core/schema/schema_constants.dart`. Find `static const isDigital = 'isDigital';` and add directly below:

```dart
  // Digital product extended fields
  static const digitalType = 'digitalType';
  static const slug = 'slug';
  static const digitalBuilds = 'digitalBuilds';
  static const bookSourceUrl = 'bookSourceUrl';  // server-side only, never sent to client
  static const deviceLimit = 'deviceLimit';
  static const licenseKey = 'licenseKey';
  static const digitalUnlocked = 'digitalUnlocked';
  static const supportedPlatforms = 'supportedPlatforms';
  static const activations = 'activations';
  static const deviceId = 'deviceId';
  static const lastVerifiedAt = 'lastVerifiedAt';
  static const accessToken = 'accessToken';
```

Find the end of the class (or constants area) and add new value classes:

```dart
class DigitalTypeValues {
  DigitalTypeValues._();
  static const software = 'software';
  static const book = 'book';
  static const all = [software, book];
}

class DigitalPlatformValues {
  DigitalPlatformValues._();
  static const macos = 'macos';
  static const windows = 'windows';
  static const linux = 'linux';
  static const all = [macos, windows, linux];
}
```

**Step 2: Verify no analysis errors**

```bash
cd origna_gta && flutter analyze lib/core/schema/schema_constants.dart
```
Expected: No issues

**Step 3: Commit**

```bash
git add origna_gta/lib/core/schema/schema_constants.dart
git commit -m "feat(schema): sync digital product constants to Dart"
```

---

## Phase 2: Backend Models

### Task 3: Update Product Pydantic model

**Files:**
- Modify: `functions/models/product.py`
- Test: `functions/tests/test_pydantic_models.py`

**Step 1: Write the failing test** — add to `functions/tests/test_pydantic_models.py`:

```python
def test_product_digital_software_fields():
    """Product model accepts digital software fields"""
    from models.product import Product
    p = Product(
        name="MacBook Cleaner Pro",
        description="Cleans your macOS system thoroughly",
        price=29.99,
        categoryId=1,
        stockQuantity=9999,
        imageUrls=["https://cdn.example.com/img.jpg"],
        sellerId="seller123",
        isDigital=True,
        digitalType="software",
        slug="macbook-cleaner-pro-a4f2",
        digitalBuilds={"macos": "https://releases.example.com/cleaner.dmg"},
        deviceLimit=3,
    )
    assert p.digitalType == "software"
    assert p.slug == "macbook-cleaner-pro-a4f2"
    assert p.digitalBuilds["macos"] == "https://releases.example.com/cleaner.dmg"
    assert p.deviceLimit == 3

def test_product_digital_book_fields():
    """Product model accepts digital book fields"""
    from models.product import Product
    p = Product(
        name="Python Mastery",
        description="Complete guide to Python programming",
        price=19.99,
        categoryId=1,
        stockQuantity=9999,
        imageUrls=["https://cdn.example.com/book.jpg"],
        sellerId="seller123",
        isDigital=True,
        digitalType="book",
        slug="python-mastery-b3c1",
        bookSourceUrl="https://storage.example.com/python-mastery.pdf",
    )
    assert p.digitalType == "book"
    assert p.bookSourceUrl == "https://storage.example.com/python-mastery.pdf"

def test_product_digital_type_invalid():
    """Invalid digitalType is rejected"""
    from models.product import Product
    import pytest
    from pydantic import ValidationError
    with pytest.raises(ValidationError, match="digitalType"):
        Product(
            name="Test",
            description="Test description for product",
            price=9.99,
            categoryId=1,
            stockQuantity=1,
            imageUrls=["https://cdn.example.com/img.jpg"],
            sellerId="seller123",
            isDigital=True,
            digitalType="video",  # invalid
        )

def test_product_software_requires_https_build_urls():
    """Software build URLs must be https"""
    from models.product import Product
    import pytest
    from pydantic import ValidationError
    with pytest.raises(ValidationError):
        Product(
            name="Test App",
            description="Test description for product",
            price=9.99,
            categoryId=1,
            stockQuantity=1,
            imageUrls=["https://cdn.example.com/img.jpg"],
            sellerId="seller123",
            isDigital=True,
            digitalType="software",
            digitalBuilds={"macos": "http://insecure.example.com/app.dmg"},  # not https
        )

def test_product_software_requires_at_least_one_platform():
    """Software product must have at least one platform URL"""
    from models.product import Product
    import pytest
    from pydantic import ValidationError
    with pytest.raises(ValidationError, match="at least one"):
        Product(
            name="Test App",
            description="Test description for product",
            price=9.99,
            categoryId=1,
            stockQuantity=1,
            imageUrls=["https://cdn.example.com/img.jpg"],
            sellerId="seller123",
            isDigital=True,
            digitalType="software",
            digitalBuilds={},  # empty
        )

def test_product_book_requires_https_source_url():
    """Book source URL must be https"""
    from models.product import Product
    import pytest
    from pydantic import ValidationError
    with pytest.raises(ValidationError):
        Product(
            name="Test Book",
            description="Test description for product",
            price=9.99,
            categoryId=1,
            stockQuantity=1,
            imageUrls=["https://cdn.example.com/img.jpg"],
            sellerId="seller123",
            isDigital=True,
            digitalType="book",
            bookSourceUrl="http://insecure.example.com/book.pdf",  # not https
        )
```

**Step 2: Run to confirm fail**

```bash
cd functions && python -m pytest tests/test_pydantic_models.py::test_product_digital_software_fields tests/test_pydantic_models.py::test_product_digital_type_invalid -v
```
Expected: `ValidationError` or `AttributeError`

**Step 3: Add fields to `functions/models/product.py`**

After `isDigital: bool = Field(...)` (~line 249), add:

```python
    # Digital product extended fields
    digitalType: str | None = Field(
        default=None,
        description="Type of digital product: 'software' or 'book'",
    )
    slug: str | None = Field(
        default=None,
        max_length=80,
        description="URL-safe unique slug for sharing (e.g., macbook-cleaner-a4f2)",
    )
    digitalBuilds: dict[str, str] | None = Field(
        default=None,
        description="Platform -> external download URL map (software only)",
    )
    bookSourceUrl: str | None = Field(
        default=None,
        max_length=2048,
        description="External PDF/EPUB download URL (book only, never sent to client)",
    )
    deviceLimit: int | None = Field(
        default=None,
        ge=1,
        description="Max activations allowed (software only, null = unlimited)",
    )
```

Add validators after the existing `validate_description` validator:

```python
    @field_validator("digitalType")
    @classmethod
    def validate_digital_type(cls, v: str | None) -> str | None:
        if v is not None and v not in ["software", "book"]:
            raise ValueError(f"digitalType must be 'software' or 'book', got '{v}'")
        return v

    @field_validator("digitalBuilds")
    @classmethod
    def validate_digital_builds(cls, v: dict[str, str] | None) -> dict[str, str] | None:
        if v is None:
            return v
        valid_platforms = {"macos", "windows", "linux"}
        for platform, url in v.items():
            if platform not in valid_platforms:
                raise ValueError(f"Invalid platform '{platform}'. Must be one of: {valid_platforms}")
            if not url.startswith("https://"):
                raise ValueError(f"Build URL for '{platform}' must start with https://")
        return v

    @field_validator("bookSourceUrl")
    @classmethod
    def validate_book_source_url(cls, v: str | None) -> str | None:
        if v is not None and not v.startswith("https://"):
            raise ValueError("bookSourceUrl must start with https://")
        return v

    @model_validator(mode="after")
    def validate_digital_fields(self) -> "Product":
        if self.isDigital:
            if self.digitalType not in ["software", "book"]:
                raise ValueError("digitalType must be 'software' or 'book' when isDigital=True")
            if self.digitalType == "software":
                if not self.digitalBuilds:
                    raise ValueError("digitalBuilds must have at least one platform URL for software products")
            elif self.digitalType == "book":
                if not self.bookSourceUrl:
                    raise ValueError("bookSourceUrl is required for book products")
        return self
```

**Step 4: Run to confirm pass**

```bash
cd functions && python -m pytest tests/test_pydantic_models.py::test_product_digital_software_fields tests/test_pydantic_models.py::test_product_digital_type_invalid tests/test_pydantic_models.py::test_product_software_requires_https_build_urls tests/test_pydantic_models.py::test_product_software_requires_at_least_one_platform tests/test_pydantic_models.py::test_product_book_requires_https_source_url -v
```
Expected: all PASSED

**Step 5: Commit**

```bash
git add functions/models/product.py functions/tests/test_pydantic_models.py
git commit -m "feat(models): add digital product fields to Product model (type, slug, builds, bookSourceUrl)"
```

---

### Task 4: Update OrderItem Pydantic model

**Files:**
- Modify: `functions/models/order.py`
- Test: `functions/tests/test_pydantic_models.py`

**Step 1: Write the failing test** — add to test file:

```python
def test_order_item_digital_fields():
    """OrderItem model accepts digital unlock fields"""
    from models.order import OrderItem
    item = OrderItem(
        productId="prod123",
        name="MacBook Cleaner Pro",
        price=29.99,
        quantity=1,
        imageUrls=["https://cdn.example.com/img.jpg"],
        sellerId="seller123",
        isDigital=True,
        licenseKey="ABCD-EFGH-IJKL-MNOP",
        digitalUnlocked=True,
    )
    assert item.licenseKey == "ABCD-EFGH-IJKL-MNOP"
    assert item.digitalUnlocked is True
```

**Step 2: Run to confirm fail**

```bash
cd functions && python -m pytest tests/test_pydantic_models.py::test_order_item_digital_fields -v
```

**Step 3: Add fields to `functions/models/order.py`**

After `isDigital: bool = Field(...)` (~line 84), add:

```python
    # Digital product delivery (set on payment capture)
    licenseKey: str | None = Field(default=None, description="License key reference into licenses collection")
    digitalUnlocked: bool = Field(default=False, description="True after license has been generated on payment")
```

**Step 4: Run to confirm pass**

```bash
cd functions && python -m pytest tests/test_pydantic_models.py::test_order_item_digital_fields -v
```

**Step 5: Commit**

```bash
git add functions/models/order.py functions/tests/test_pydantic_models.py
git commit -m "feat(models): add licenseKey + digitalUnlocked to OrderItem"
```

---

## Phase 3: Slug Generation + Product Creation

### Task 5: Slug generation utility + product handler hook

**Files:**
- Modify: `functions/handlers/products.py`
- Test: `functions/tests/test_handlers_products_orders.py`

**Step 1: Write the failing test** — add to test file:

```python
def test_generate_product_slug_format():
    """Slug is lowercase, hyphenated, ends with 4-char hex suffix"""
    import re
    from handlers.products import _generate_product_slug
    slug = _generate_product_slug("MacBook Cleaner Pro!")
    assert re.match(r'^[a-z0-9\-]+-[a-f0-9]{4}$', slug), f"Bad slug format: {slug}"
    assert slug.startswith("macbook-cleaner-pro-")
    assert len(slug) <= 85

def test_generate_product_slug_strips_special_chars():
    """Special characters are stripped from slug"""
    from handlers.products import _generate_product_slug
    slug = _generate_product_slug("C++ App & More!!!   ")
    assert '+' not in slug
    assert '&' not in slug
    assert '!' not in slug
    assert '  ' not in slug

def test_generate_product_slug_different_each_call():
    """Each call produces a different suffix"""
    from handlers.products import _generate_product_slug
    s1 = _generate_product_slug("Same Name")
    s2 = _generate_product_slug("Same Name")
    # Extremely unlikely to collide (1/65536 chance)
    assert s1 != s2
```

**Step 2: Run to confirm fail**

```bash
cd functions && python -m pytest tests/test_handlers_products_orders.py::test_generate_product_slug_format -v
```

**Step 3: Add `_generate_product_slug` to `functions/handlers/products.py`**

At the top of the file, ensure these imports exist (add if missing):
```python
import re
import secrets
```

Then add this function near the top (after imports, before any handler functions):

```python
def _generate_product_slug(title: str) -> str:
    """Generate a URL-safe slug: {title-slug}-{4 random hex chars}.
    Collisions checked by caller — retry with new suffix if needed.
    """
    base = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:40]
    suffix = secrets.token_hex(2)  # 4 hex chars
    return f"{base}-{suffix}"
```

**Step 4: Add slug injection to `create_product` handler in `functions/handlers/products.py`**

Find the function that writes a new product to Firestore (likely `create_product` or `add_product`). Before the Firestore write, add:

```python
    # Generate unique slug for sharing URL
    from schema_constants import Collections
    db = get_db()
    for _ in range(5):
        candidate = _generate_product_slug(product_data.get("name", "product"))
        existing = db.collection(Collections.PRODUCTS).where("slug", "==", candidate).limit(1).get()
        if not existing:
            product_data["slug"] = candidate
            break
    else:
        # Fallback: use doc ID suffix (guaranteed unique)
        product_data["slug"] = f"product-{product_id[-8:]}"
```

**Step 5: Run to confirm pass**

```bash
cd functions && python -m pytest tests/test_handlers_products_orders.py::test_generate_product_slug_format tests/test_handlers_products_orders.py::test_generate_product_slug_strips_special_chars tests/test_handlers_products_orders.py::test_generate_product_slug_different_each_call -v
```

**Step 6: Commit**

```bash
git add functions/handlers/products.py functions/tests/test_handlers_products_orders.py
git commit -m "feat(products): add slug generation with collision check on product creation"
```

---

## Phase 4: License Generation on Payment Capture

### Task 6: License key generator utility

**Files:**
- Modify: `functions/handlers/payment_stripe.py`
- Test: `functions/tests/test_handlers_payment_stripe.py`

**Step 1: Write the failing test** — add to `test_handlers_payment_stripe.py`:

```python
def test_generate_license_key_format():
    """License key is XXXX-XXXX-XXXX-XXXX with uppercase alphanumeric"""
    import re
    from handlers.payment_stripe import _generate_license_key
    key = _generate_license_key()
    assert re.match(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$', key), f"Bad format: {key}"

def test_generate_license_key_unique():
    """Each call produces a different key"""
    from handlers.payment_stripe import _generate_license_key
    keys = {_generate_license_key() for _ in range(100)}
    assert len(keys) == 100  # all unique in 100 iterations
```

**Step 2: Run to confirm fail**

```bash
cd functions && python -m pytest tests/test_handlers_payment_stripe.py::test_generate_license_key_format -v
```

**Step 3: Add `_generate_license_key` to `functions/handlers/payment_stripe.py`**

After imports at the top, add:

```python
import secrets
import string as _string
```

Then add the function (near top, after imports):

```python
def _generate_license_key() -> str:
    """Generate a XXXX-XXXX-XXXX-XXXX format license key using crypto-random characters."""
    alphabet = _string.ascii_uppercase + _string.digits
    segments = ["".join(secrets.choice(alphabet) for _ in range(4)) for _ in range(4)]
    return "-".join(segments)
```

**Step 4: Run to confirm pass**

```bash
cd functions && python -m pytest tests/test_handlers_payment_stripe.py::test_generate_license_key_format tests/test_handlers_payment_stripe.py::test_generate_license_key_unique -v
```

**Step 5: Commit**

```bash
git add functions/handlers/payment_stripe.py functions/tests/test_handlers_payment_stripe.py
git commit -m "feat(payment): add crypto-random license key generator"
```

---

### Task 7: `_generate_digital_licenses` and hook into checkout completion

**Files:**
- Modify: `functions/handlers/payment_stripe.py`
- Test: `functions/tests/test_handlers_payment_stripe.py`

**Step 1: Write the failing test** — add to test file:

```python
def test_generate_digital_licenses_software(mocker):
    """Generates license for software item, writes to licenses collection, updates order item"""
    from handlers.payment_stripe import _generate_digital_licenses
    from unittest.mock import MagicMock, patch

    mock_db = MagicMock()
    mock_product = MagicMock()
    mock_product.exists = True
    mock_product.to_dict.return_value = {
        "digitalType": "software",
        "digitalBuilds": {"macos": "https://example.com/app.dmg"},
        "deviceLimit": 3,
    }
    mock_db.collection.return_value.document.return_value.get.return_value = mock_product
    # License collision check: first query returns empty (no collision)
    mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = []

    order_data = {
        "userId": "buyer123",
        "items": [{
            "productId": "prod123",
            "isDigital": True,
            "digitalUnlocked": False,
            "name": "MacBook Cleaner",
            "price": 29.99,
            "quantity": 1,
        }]
    }

    with patch("handlers.payment_stripe.get_db", return_value=mock_db):
        _generate_digital_licenses("order123", order_data)

    # Verify license was written
    mock_db.collection.assert_any_call("licenses")

def test_generate_digital_licenses_skips_already_unlocked(mocker):
    """Idempotent: skips items where digitalUnlocked=True"""
    from handlers.payment_stripe import _generate_digital_licenses
    from unittest.mock import MagicMock, patch

    mock_db = MagicMock()
    order_data = {
        "userId": "buyer123",
        "items": [{
            "productId": "prod123",
            "isDigital": True,
            "digitalUnlocked": True,  # already done
            "licenseKey": "ABCD-EFGH-IJKL-MNOP",
        }]
    }
    with patch("handlers.payment_stripe.get_db", return_value=mock_db):
        _generate_digital_licenses("order123", order_data)

    # Should NOT write to licenses collection
    mock_db.collection.return_value.document.return_value.set.assert_not_called()

def test_generate_digital_licenses_book(mocker):
    """Generates license + access token for book item"""
    from handlers.payment_stripe import _generate_digital_licenses
    from unittest.mock import MagicMock, patch

    mock_db = MagicMock()
    mock_product = MagicMock()
    mock_product.exists = True
    mock_product.to_dict.return_value = {
        "digitalType": "book",
        "bookSourceUrl": "https://storage.example.com/book.pdf",
    }
    mock_db.collection.return_value.document.return_value.get.return_value = mock_product
    mock_db.collection.return_value.where.return_value.limit.return_value.get.return_value = []

    order_data = {
        "userId": "buyer123",
        "items": [{
            "productId": "prod456",
            "isDigital": True,
            "digitalUnlocked": False,
            "name": "Python Mastery",
            "price": 19.99,
            "quantity": 1,
        }]
    }
    with patch("handlers.payment_stripe.get_db", return_value=mock_db):
        _generate_digital_licenses("order123", order_data)

    # Both licenses and book_access_tokens must be written
    calls = [str(c) for c in mock_db.collection.call_args_list]
    assert any("licenses" in c for c in calls)
```

**Step 2: Run to confirm fail**

```bash
cd functions && python -m pytest tests/test_handlers_payment_stripe.py::test_generate_digital_licenses_software tests/test_handlers_payment_stripe.py::test_generate_digital_licenses_skips_already_unlocked -v
```

**Step 3: Add `_generate_digital_licenses` to `functions/handlers/payment_stripe.py`**

Add this function (before `process_checkout_session_completed`):

```python
def _generate_digital_licenses(order_id: str, order_data: dict) -> None:
    """Generate license keys for all digital items in an order.
    Idempotent: skips items where digitalUnlocked=True.
    Called immediately after order is confirmed on payment capture.
    """
    import secrets as _secrets
    from datetime import datetime, timezone, timedelta
    from schema_constants import (
        Collections, Fields, DigitalTypeValues
    )

    db = get_db()
    items = order_data.get(Fields.ITEMS, [])
    buyer_id = order_data.get(Fields.USER_ID, "")
    updated_items = list(items)
    any_generated = False

    for idx, item in enumerate(items):
        if not item.get(Fields.IS_DIGITAL, False):
            continue
        if item.get(Fields.DIGITAL_UNLOCKED, False):
            logger.info(f"⏭ Digital item {item.get(Fields.PRODUCT_ID)} already unlocked, skipping")
            continue

        product_id = item.get(Fields.PRODUCT_ID)
        product_doc = db.collection(Collections.PRODUCTS).document(product_id).get()
        if not product_doc.exists:
            logger.warning(f"⚠️ Product {product_id} not found for digital license generation")
            continue

        product_data = product_doc.to_dict()
        digital_type = product_data.get(Fields.DIGITAL_TYPE)
        if not digital_type:
            logger.warning(f"⚠️ Product {product_id} has isDigital=True but no digitalType")
            continue

        # Generate unique license key (collision-safe)
        license_key = None
        for _ in range(5):
            candidate = _generate_license_key()
            existing = db.collection(Collections.LICENSES).document(candidate).get()
            if not existing.exists:
                license_key = candidate
                break
        if not license_key:
            logger.error(f"❌ Could not generate unique license key for product {product_id}")
            continue

        now = datetime.now(timezone.utc)

        if digital_type == DigitalTypeValues.SOFTWARE:
            builds = product_data.get(Fields.DIGITAL_BUILDS, {})
            supported_platforms = list(builds.keys())
            license_doc = {
                Fields.LICENSE_KEY: license_key,
                Fields.PRODUCT_ID: product_id,
                Fields.ORDER_ID: order_id,
                Fields.USER_ID: buyer_id,
                "digitalType": DigitalTypeValues.SOFTWARE,
                "status": "active",
                Fields.SUPPORTED_PLATFORMS: supported_platforms,
                Fields.DEVICE_LIMIT: product_data.get(Fields.DEVICE_LIMIT),
                Fields.ACTIVATIONS: [],
                Fields.DIGITAL_BUILDS: builds,
                Fields.CREATED_AT: now,
            }
            db.collection(Collections.LICENSES).document(license_key).set(license_doc)

        elif digital_type == DigitalTypeValues.BOOK:
            book_source_url = product_data.get(Fields.BOOK_SOURCE_URL, "")
            license_doc = {
                Fields.LICENSE_KEY: license_key,
                Fields.PRODUCT_ID: product_id,
                Fields.ORDER_ID: order_id,
                Fields.USER_ID: buyer_id,
                "digitalType": DigitalTypeValues.BOOK,
                "status": "active",
                Fields.BOOK_SOURCE_URL: book_source_url,
                Fields.CREATED_AT: now,
            }
            db.collection(Collections.LICENSES).document(license_key).set(license_doc)

            # Also create initial short-lived access token (refreshed on each download request)
            token = "tok_" + _secrets.token_hex(32)
            token_doc = {
                Fields.ACCESS_TOKEN: token,
                Fields.LICENSE_KEY: license_key,
                Fields.USER_ID: buyer_id,
                Fields.PRODUCT_ID: product_id,
                Fields.BOOK_SOURCE_URL: book_source_url,
                "expiresAt": now + timedelta(minutes=15),
                "used": False,
                Fields.CREATED_AT: now,
            }
            db.collection(Collections.BOOK_ACCESS_TOKENS).document(token).set(token_doc)

        # Update item in order
        updated_item = dict(updated_items[idx])
        updated_item[Fields.LICENSE_KEY] = license_key
        updated_item[Fields.DIGITAL_UNLOCKED] = True
        updated_items[idx] = updated_item
        any_generated = True
        logger.info(f"✅ License {license_key} generated for product {product_id} (type={digital_type})")

    if any_generated:
        # Write updated items back to order
        order_ref = db.collection(Collections.ORDERS).document(order_id)
        order_ref.update({Fields.ITEMS: updated_items, Fields.UPDATED_AT: datetime.now(timezone.utc)})
```

**Step 4: Hook into `process_checkout_session_completed`**

Find `# Clear user's cart` (~line 1483). **Before** that block, add:

```python
    # Generate digital licenses for any digital items
    try:
        _generate_digital_licenses(order_id, order_data)
    except Exception as e:
        logger.error(f"❌ Digital license generation failed for order {order_id}: {str(e)}")
        # Non-fatal: order is confirmed, license can be re-generated by admin
```

**Step 5: Run to confirm pass**

```bash
cd functions && python -m pytest tests/test_handlers_payment_stripe.py::test_generate_digital_licenses_software tests/test_handlers_payment_stripe.py::test_generate_digital_licenses_skips_already_unlocked tests/test_handlers_payment_stripe.py::test_generate_digital_licenses_book -v
```

**Step 6: Run full payment test suite**

```bash
cd functions && python -m pytest tests/test_handlers_payment_stripe.py -v
```
Expected: all existing tests still pass.

**Step 7: Commit**

```bash
git add functions/handlers/payment_stripe.py functions/tests/test_handlers_payment_stripe.py
git commit -m "feat(payment): generate digital licenses on checkout completion (idempotent)"
```

---

## Phase 5: Digital API Handlers

### Task 8: Create `functions/handlers/digital.py`

**Files:**
- Create: `functions/handlers/digital.py`
- Create: `functions/tests/test_handlers_digital.py`

**Step 1: Write failing tests** — create `functions/tests/test_handlers_digital.py`:

```python
"""Tests for digital product API handlers (license activation, book redirect)."""
import pytest
from unittest.mock import MagicMock, patch, call
from datetime import datetime, timezone, timedelta


# ── Helpers ────────────────────────────────────────────────────────────────────

def _make_license(overrides=None):
    base = {
        "licenseKey": "ABCD-EFGH-IJKL-MNOP",
        "productId": "prod123",
        "orderId": "order123",
        "userId": "buyer123",
        "digitalType": "software",
        "status": "active",
        "supportedPlatforms": ["macos", "windows"],
        "deviceLimit": 3,
        "activations": [],
        "digitalBuilds": {
            "macos": "https://example.com/app.dmg",
            "windows": "https://example.com/app.exe",
        },
    }
    if overrides:
        base.update(overrides)
    return base


# ── activate_license ────────────────────────────────────────────────────────────

def test_activate_license_success(mocker):
    """Valid license + valid platform + under device limit → approved"""
    from handlers.digital import _activate_license_impl
    license_data = _make_license()
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        result = _activate_license_impl("ABCD-EFGH-IJKL-MNOP", "device-uuid-001", "macos")

    assert result["approved"] is True
    assert result["licenseKey"] == "ABCD-EFGH-IJKL-MNOP"
    assert "downloadUrls" in result


def test_activate_license_not_found(mocker):
    """Non-existent license key → 404"""
    from handlers.digital import _activate_license_impl
    mock_doc = MagicMock()
    mock_doc.exists = False
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        with pytest.raises(Exception, match="not_found"):
            _activate_license_impl("XXXX-XXXX-XXXX-XXXX", "device1", "macos")


def test_activate_license_revoked(mocker):
    """Revoked license → 403"""
    from handlers.digital import _activate_license_impl
    license_data = _make_license({"status": "revoked"})
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        with pytest.raises(Exception, match="revoked"):
            _activate_license_impl("ABCD-EFGH-IJKL-MNOP", "device1", "macos")


def test_activate_license_wrong_platform(mocker):
    """Platform not in supportedPlatforms → 403"""
    from handlers.digital import _activate_license_impl
    license_data = _make_license({"supportedPlatforms": ["macos"]})
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        with pytest.raises(Exception, match="platform_not_supported"):
            _activate_license_impl("ABCD-EFGH-IJKL-MNOP", "device1", "linux")


def test_activate_license_device_limit_exceeded(mocker):
    """All device slots filled → 403"""
    from handlers.digital import _activate_license_impl
    activations = [
        {"deviceId": f"dev{i}", "platform": "macos"} for i in range(3)
    ]
    license_data = _make_license({"deviceLimit": 3, "activations": activations})
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        with pytest.raises(Exception, match="device_limit_exceeded"):
            _activate_license_impl("ABCD-EFGH-IJKL-MNOP", "dev-new", "macos")


def test_activate_license_idempotent_reactivation(mocker):
    """Same deviceId re-activating → approved without adding new activation"""
    from handlers.digital import _activate_license_impl
    activations = [{"deviceId": "dev-existing", "platform": "macos", "activatedAt": "2026-01-01"}]
    license_data = _make_license({"deviceLimit": 3, "activations": activations})
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        result = _activate_license_impl("ABCD-EFGH-IJKL-MNOP", "dev-existing", "macos")

    assert result["approved"] is True
    # Should update lastVerifiedAt but not add a new activation entry
    update_call = mock_db.collection.return_value.document.return_value.update
    update_call.assert_called_once()
    update_args = update_call.call_args[0][0]
    assert len(update_args.get("activations", activations)) == 1  # still only 1 activation


def test_activate_license_unlimited_devices(mocker):
    """deviceLimit=None means unlimited — always allow"""
    from handlers.digital import _activate_license_impl
    activations = [{"deviceId": f"dev{i}", "platform": "macos"} for i in range(100)]
    license_data = _make_license({"deviceLimit": None, "activations": activations})
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        result = _activate_license_impl("ABCD-EFGH-IJKL-MNOP", "dev-new", "macos")

    assert result["approved"] is True


# ── book redirect ────────────────────────────────────────────────────────────

def test_get_book_redirect_success(mocker):
    """Valid unused non-expired token → returns bookSourceUrl for redirect"""
    from handlers.digital import _get_book_redirect_impl
    now = datetime.now(timezone.utc)
    token_data = {
        "token": "tok_abc123",
        "licenseKey": "ABCD-EFGH-IJKL-MNOP",
        "buyerId": "buyer123",
        "productId": "prod123",
        "bookSourceUrl": "https://storage.example.com/book.pdf",
        "expiresAt": now + timedelta(minutes=10),
        "used": False,
    }
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = token_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        result = _get_book_redirect_impl("tok_abc123")

    assert result == "https://storage.example.com/book.pdf"


def test_get_book_redirect_already_used(mocker):
    """Used token → raises 'already_used' error"""
    from handlers.digital import _get_book_redirect_impl
    now = datetime.now(timezone.utc)
    token_data = {
        "bookSourceUrl": "https://storage.example.com/book.pdf",
        "expiresAt": now + timedelta(minutes=10),
        "used": True,
    }
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = token_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        with pytest.raises(Exception, match="already_used"):
            _get_book_redirect_impl("tok_abc123")


def test_get_book_redirect_expired(mocker):
    """Expired token → raises 'expired' error"""
    from handlers.digital import _get_book_redirect_impl
    now = datetime.now(timezone.utc)
    token_data = {
        "bookSourceUrl": "https://storage.example.com/book.pdf",
        "expiresAt": now - timedelta(minutes=1),  # past
        "used": False,
    }
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = token_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        with pytest.raises(Exception, match="expired"):
            _get_book_redirect_impl("tok_abc123")


# ── generate_book_download_session ──────────────────────────────────────────

def test_generate_book_download_session_success(mocker):
    """Authenticated buyer with active license → new token created"""
    from handlers.digital import _generate_book_download_session_impl
    license_data = {
        "licenseKey": "ABCD-EFGH-IJKL-MNOP",
        "userId": "buyer123",
        "digitalType": "book",
        "status": "active",
        "bookSourceUrl": "https://storage.example.com/book.pdf",
    }
    mock_lic_doc = MagicMock()
    mock_lic_doc.exists = True
    mock_lic_doc.to_dict.return_value = license_data

    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_lic_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        result = _generate_book_download_session_impl("ABCD-EFGH-IJKL-MNOP", "buyer123")

    assert "downloadUrl" in result
    assert "tok_" in result["downloadUrl"]


def test_generate_book_download_session_wrong_buyer(mocker):
    """Buyer trying to get token for someone else's license → 403"""
    from handlers.digital import _generate_book_download_session_impl
    license_data = {
        "licenseKey": "ABCD-EFGH-IJKL-MNOP",
        "userId": "other-buyer",
        "digitalType": "book",
        "status": "active",
        "bookSourceUrl": "https://storage.example.com/book.pdf",
    }
    mock_lic_doc = MagicMock()
    mock_lic_doc.exists = True
    mock_lic_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_lic_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        with pytest.raises(Exception, match="unauthorized"):
            _generate_book_download_session_impl("ABCD-EFGH-IJKL-MNOP", "attacker-uid")
```

**Step 2: Run to confirm fail**

```bash
cd functions && python -m pytest tests/test_handlers_digital.py -v
```
Expected: `ModuleNotFoundError: No module named 'handlers.digital'`

**Step 3: Create `functions/handlers/digital.py`**

```python
"""Digital product handlers: license activation, book redirect, deactivation."""
import logging
import re
import secrets
from datetime import datetime, timezone, timedelta

from firebase_functions import https_fn
from firebase_functions.params import StringParam

from db import get_db
from schema_constants import Collections, Fields, DigitalTypeValues

logger = logging.getLogger(__name__)

# Regex for license key format validation (prevents DB lookup on garbage input)
_LICENSE_KEY_RE = re.compile(r'^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$')
_TOKEN_RE = re.compile(r'^tok_[a-f0-9]{64}$')

APP_BASE_URL = StringParam("APP_BASE_URL", default="https://app.origna.com")


# ── Internal implementations (pure functions, testable without HTTP context) ──

def _activate_license_impl(license_key: str, device_id: str, platform: str) -> dict:
    """Core activation logic. Raises ValueError with error code on failure."""
    if not _LICENSE_KEY_RE.match(license_key):
        raise ValueError("invalid_key_format")

    db = get_db()
    lic_doc = db.collection(Collections.LICENSES).document(license_key).get()
    if not lic_doc.exists:
        raise ValueError("not_found")

    lic = lic_doc.to_dict()
    if lic.get("status") != "active":
        raise ValueError("revoked")

    supported = lic.get(Fields.SUPPORTED_PLATFORMS, [])
    if platform not in supported:
        raise ValueError("platform_not_supported")

    activations: list = list(lic.get(Fields.ACTIVATIONS, []))
    now = datetime.now(timezone.utc)

    # Idempotent re-activation: same device already registered
    for i, act in enumerate(activations):
        if act.get(Fields.DEVICE_ID) == device_id:
            activations[i] = {**act, Fields.LAST_VERIFIED_AT: now}
            db.collection(Collections.LICENSES).document(license_key).update(
                {Fields.ACTIVATIONS: activations, "updatedAt": now}
            )
            return {
                "approved": True,
                "licenseKey": license_key,
                "downloadUrls": lic.get(Fields.DIGITAL_BUILDS, {}),
                "activatedAt": act.get("activatedAt"),
            }

    # Check device limit
    device_limit = lic.get(Fields.DEVICE_LIMIT)
    if device_limit is not None and len(activations) >= device_limit:
        raise ValueError("device_limit_exceeded")

    # New activation
    new_activation = {
        Fields.DEVICE_ID: device_id,
        "platform": platform,
        "activatedAt": now,
        Fields.LAST_VERIFIED_AT: now,
    }
    activations.append(new_activation)
    db.collection(Collections.LICENSES).document(license_key).update(
        {Fields.ACTIVATIONS: activations, "updatedAt": now}
    )

    return {
        "approved": True,
        "licenseKey": license_key,
        "downloadUrls": lic.get(Fields.DIGITAL_BUILDS, {}),
        "activatedAt": now.isoformat(),
    }


def _deactivate_license_impl(license_key: str, device_id: str, caller_uid: str) -> dict:
    """Remove a device activation. Requires caller to be the license owner."""
    if not _LICENSE_KEY_RE.match(license_key):
        raise ValueError("invalid_key_format")

    db = get_db()
    lic_doc = db.collection(Collections.LICENSES).document(license_key).get()
    if not lic_doc.exists:
        raise ValueError("not_found")

    lic = lic_doc.to_dict()
    if lic.get(Fields.USER_ID) != caller_uid:
        raise ValueError("unauthorized")

    activations = [a for a in lic.get(Fields.ACTIVATIONS, []) if a.get(Fields.DEVICE_ID) != device_id]
    db.collection(Collections.LICENSES).document(license_key).update(
        {Fields.ACTIVATIONS: activations, "updatedAt": datetime.now(timezone.utc)}
    )
    return {"deactivated": True, "remainingActivations": len(activations)}


def _generate_book_download_session_impl(license_key: str, caller_uid: str) -> dict:
    """Create a new 15-min single-use download token for a book license.
    Returns { downloadUrl } pointing to /dl?t={token}.
    """
    if not _LICENSE_KEY_RE.match(license_key):
        raise ValueError("invalid_key_format")

    db = get_db()
    lic_doc = db.collection(Collections.LICENSES).document(license_key).get()
    if not lic_doc.exists:
        raise ValueError("not_found")

    lic = lic_doc.to_dict()
    if lic.get(Fields.USER_ID) != caller_uid:
        raise ValueError("unauthorized")
    if lic.get("status") != "active":
        raise ValueError("revoked")
    if lic.get("digitalType") != DigitalTypeValues.BOOK:
        raise ValueError("not_a_book_license")

    token = "tok_" + secrets.token_hex(32)
    now = datetime.now(timezone.utc)
    token_doc = {
        Fields.ACCESS_TOKEN: token,
        Fields.LICENSE_KEY: license_key,
        Fields.USER_ID: caller_uid,
        Fields.PRODUCT_ID: lic.get(Fields.PRODUCT_ID),
        Fields.BOOK_SOURCE_URL: lic.get(Fields.BOOK_SOURCE_URL),
        "expiresAt": now + timedelta(minutes=15),
        "used": False,
        Fields.CREATED_AT: now,
    }
    db.collection(Collections.BOOK_ACCESS_TOKENS).document(token).set(token_doc)

    base_url = APP_BASE_URL.value
    return {"downloadUrl": f"{base_url}/dl?t={token}"}


def _get_book_redirect_impl(token: str) -> str:
    """Validate token and return the bookSourceUrl for redirect.
    Uses an atomic transaction to mark token as used (prevents race condition).
    Raises ValueError with error code on any failure.
    """
    if not _TOKEN_RE.match(token):
        raise ValueError("invalid_token_format")

    db = get_db()
    token_ref = db.collection(Collections.BOOK_ACCESS_TOKENS).document(token)

    def _atomic_claim(transaction):
        doc = token_ref.get(transaction=transaction)
        if not doc.exists:
            raise ValueError("not_found")
        data = doc.to_dict()
        if data.get("used"):
            raise ValueError("already_used")
        expires_at = data.get("expiresAt")
        now = datetime.now(timezone.utc)
        # Handle both Firestore Timestamp and Python datetime
        if hasattr(expires_at, 'timestamp'):
            expires_dt = expires_at.replace(tzinfo=timezone.utc) if expires_at.tzinfo is None else expires_at
        else:
            expires_dt = expires_at
        if expires_dt < now:
            raise ValueError("expired")
        transaction.update(token_ref, {"used": True, "usedAt": now})
        return data.get(Fields.BOOK_SOURCE_URL, "")

    transaction = db.transaction()
    book_url = _atomic_claim(transaction)
    if not book_url:
        raise ValueError("missing_source_url")
    return book_url


# ── Cloud Function endpoints ────────────────────────────────────────────────

@https_fn.on_request(cors=True)
def activate_license(req: https_fn.Request) -> https_fn.Response:
    """Public endpoint called by installed desktop app to activate a license.
    POST /activate_license
    Body: { licenseKey, deviceId, platform }
    No Firebase auth required (app-to-server).
    """
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)

    try:
        body = req.get_json(silent=True) or {}
        license_key = str(body.get("licenseKey", "")).strip().upper()
        device_id = str(body.get("deviceId", "")).strip()
        platform = str(body.get("platform", "")).strip().lower()

        if not license_key or not device_id or not platform:
            return https_fn.Response(
                '{"error": "licenseKey, deviceId, and platform are required"}',
                status=400, content_type="application/json"
            )

        result = _activate_license_impl(license_key, device_id, platform)
        import json
        return https_fn.Response(json.dumps(result), status=200, content_type="application/json")

    except ValueError as e:
        code = str(e)
        status_map = {
            "not_found": 404,
            "revoked": 403,
            "platform_not_supported": 403,
            "device_limit_exceeded": 403,
            "invalid_key_format": 400,
        }
        status = status_map.get(code, 400)
        import json
        return https_fn.Response(json.dumps({"error": code}), status=status, content_type="application/json")
    except Exception as e:
        logger.exception("activate_license unexpected error")
        return https_fn.Response('{"error": "internal_error"}', status=500, content_type="application/json")


@https_fn.on_call()
def deactivate_license(req: https_fn.CallableRequest) -> dict:
    """Authenticated: buyer removes a device from their license.
    Called from Flutter app: licenseKey + deviceId in request data.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Login required")

    license_key = str(req.data.get("licenseKey", "")).strip().upper()
    device_id = str(req.data.get("deviceId", "")).strip()
    if not license_key or not device_id:
        raise https_fn.HttpsError("invalid-argument", "licenseKey and deviceId required")

    try:
        return _deactivate_license_impl(license_key, device_id, req.auth.uid)
    except ValueError as e:
        code = str(e)
        if code == "not_found":
            raise https_fn.HttpsError("not-found", "License not found")
        if code == "unauthorized":
            raise https_fn.HttpsError("permission-denied", "Not your license")
        raise https_fn.HttpsError("invalid-argument", code)


@https_fn.on_call()
def generate_book_download_session(req: https_fn.CallableRequest) -> dict:
    """Authenticated: generates a 15-min single-use redirect token for a book.
    Called from Flutter app before buyer clicks Download.
    Returns { downloadUrl }.
    """
    if not req.auth:
        raise https_fn.HttpsError("unauthenticated", "Login required")

    license_key = str(req.data.get("licenseKey", "")).strip().upper()
    if not license_key:
        raise https_fn.HttpsError("invalid-argument", "licenseKey required")

    try:
        return _generate_book_download_session_impl(license_key, req.auth.uid)
    except ValueError as e:
        code = str(e)
        if code == "not_found":
            raise https_fn.HttpsError("not-found", "License not found")
        if code == "unauthorized":
            raise https_fn.HttpsError("permission-denied", "Not your license")
        if code == "revoked":
            raise https_fn.HttpsError("failed-precondition", "License revoked")
        raise https_fn.HttpsError("invalid-argument", code)


@https_fn.on_request()
def get_book_redirect(req: https_fn.Request) -> https_fn.Response:
    """Public redirect endpoint. Browser follows URL, gets 302 to external PDF.
    GET /dl?t={token}
    Single-use, 15-min expiry. Marks token as used atomically.
    bookSourceUrl is NEVER sent to client — only used server-side for redirect.
    """
    token = req.args.get("t", "").strip()
    if not token:
        return https_fn.Response("Missing token", status=400)

    try:
        book_url = _get_book_redirect_impl(token)
        return https_fn.Response(
            "", status=302,
            headers={"Location": book_url, "Cache-Control": "no-store"}
        )
    except ValueError as e:
        code = str(e)
        messages = {
            "not_found": "Download link not found.",
            "already_used": "This download link has already been used. Return to the app to generate a new one.",
            "expired": "This download link has expired. Return to the app to generate a new one.",
            "invalid_token_format": "Invalid download link.",
        }
        msg = messages.get(code, "Invalid request.")
        return https_fn.Response(msg, status=410)
    except Exception:
        logger.exception("get_book_redirect unexpected error")
        return https_fn.Response("Internal error", status=500)


@https_fn.on_request(cors=True)
def verify_license(req: https_fn.Request) -> https_fn.Response:
    """Public endpoint: installed app periodically re-verifies license when online.
    Same as activate_license but only updates lastVerifiedAt (no new activation).
    POST /verify_license
    Body: { licenseKey, deviceId, platform }
    """
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)

    try:
        body = req.get_json(silent=True) or {}
        license_key = str(body.get("licenseKey", "")).strip().upper()
        device_id = str(body.get("deviceId", "")).strip()
        platform = str(body.get("platform", "")).strip().lower()

        if not license_key or not device_id or not platform:
            return https_fn.Response(
                '{"error": "licenseKey, deviceId, platform required"}',
                status=400, content_type="application/json"
            )

        # Reuse activation impl — idempotent re-activation updates lastVerifiedAt
        result = _activate_license_impl(license_key, device_id, platform)
        import json
        return https_fn.Response(json.dumps(result), status=200, content_type="application/json")

    except ValueError as e:
        code = str(e)
        import json
        status = 403 if code in ("revoked", "device_limit_exceeded") else 400
        return https_fn.Response(json.dumps({"error": code}), status=status, content_type="application/json")
    except Exception:
        logger.exception("verify_license unexpected error")
        return https_fn.Response('{"error": "internal_error"}', status=500, content_type="application/json")
```

**Step 4: Run tests to confirm pass**

```bash
cd functions && python -m pytest tests/test_handlers_digital.py -v
```
Expected: all PASSED

**Step 5: Commit**

```bash
git add functions/handlers/digital.py functions/tests/test_handlers_digital.py
git commit -m "feat(digital): add license activation, book redirect, and deactivation handlers"
```

---

### Task 9: Register digital handlers in `functions/main.py`

**Files:**
- Modify: `functions/main.py`

**Step 1: Add imports and exports**

Open `functions/main.py`. Find the section where other handlers are imported. Add:

```python
from handlers.digital import (
    activate_license,
    deactivate_license,
    generate_book_download_session,
    get_book_redirect,
    verify_license,
)
```

**Step 2: Verify import works**

```bash
cd functions && python -c "from main import activate_license, get_book_redirect; print('OK')"
```
Expected: `OK`

**Step 3: Commit**

```bash
git add functions/main.py
git commit -m "feat(main): register digital product Cloud Function handlers"
```

---

## Phase 6: Firestore Rules + Indexes

### Task 10: Update `firestore.rules`

**Files:**
- Modify: `firestore.rules`

**Step 1: Add new collection rules**

Find `// CATCH-ALL: Deny access...` (~line 465). **Before** that block, add:

```javascript
    // ================================================================
    // LICENSES COLLECTION
    // Buyers read their own licenses. Backend-only write.
    // ================================================================
    match /licenses/{licenseKey} {
      // Buyer reads their own license
      allow read: if isAuthenticated() && resource.data.userId == request.auth.uid;
      // Admin reads all
      allow read: if isAdmin();
      // Backend-only writes
      allow create, update, delete: if false;
    }

    // ================================================================
    // BOOK_ACCESS_TOKENS COLLECTION
    // Single-use redirect tokens — backend creates, no client read.
    // ================================================================
    match /book_access_tokens/{token} {
      // No client reads — token is consumed server-side via redirect
      allow read, write: if false;
    }
```

Also update the `products` create rule `keys().hasOnly([...])` list to add new digital fields.
Find the `allow create:` block in `match /products/{productId}` and add to `hasOnly`:

```javascript
          // Digital product fields
          'digitalType', 'slug', 'digitalBuilds', 'bookSourceUrl', 'deviceLimit',
```

Also update the `allow update:` `affectedKeys().hasOnly([...])` list to include:

```javascript
          'digitalType', 'slug', 'digitalBuilds', 'bookSourceUrl', 'deviceLimit',
```

**Step 2: Deploy rules to dev**

```bash
firebase deploy --only firestore:rules --project orignagta-dev
```
Expected: `Deploy complete!`

**Step 3: Commit**

```bash
git add firestore.rules
git commit -m "feat(firestore): add rules for licenses + book_access_tokens collections"
```

---

### Task 11: Add Firestore indexes

**Files:**
- Modify: `firestore.indexes.json`

**Step 1: Add new indexes** — append to the `"indexes"` array in `firestore.indexes.json`:

```json
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "slug", "order": "ASCENDING" }
      ],
      "comment": "DIGITAL: Slug lookup for /p/{slug} routing"
    },
    {
      "collectionGroup": "licenses",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ],
      "comment": "DIGITAL: Buyer's licenses list"
    },
    {
      "collectionGroup": "licenses",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "productId", "order": "ASCENDING" }
      ],
      "comment": "DIGITAL: License lookup by buyer + product"
    },
    {
      "collectionGroup": "book_access_tokens",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "licenseKey", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ],
      "comment": "DIGITAL: Token lookup by license (cleanup)"
    }
```

**Step 2: Deploy indexes to dev**

```bash
firebase deploy --only firestore:indexes --project orignagta-dev
```
Expected: `Deploy complete!`

**Step 3: Commit**

```bash
git add firestore.indexes.json
git commit -m "feat(firestore): add indexes for slug lookup and licenses collection"
```

---

## Phase 7: Flutter Models

### Task 12: Update product_models.dart

**Files:**
- Modify: `origna_gta/lib/models/generated/product_models.dart`

**Step 1: Read the current model** to find the `Product` freezed class. Add new fields after `isDigital`:

```dart
  // Digital product extended fields
  @Default(null) String? digitalType,
  @Default(null) String? slug,
  @Default(null) Map<String, String>? digitalBuilds,
  // bookSourceUrl intentionally NOT included — server-side only, never sent to client
  @Default(null) int? deviceLimit,
```

**Step 2: Update `fromMap` factory** — find `isDigital: _safeBool(map[Fields.isDigital])` and add below:

```dart
      digitalType: map[Fields.digitalType] as String?,
      slug: map[Fields.slug] as String?,
      digitalBuilds: map[Fields.digitalBuilds] != null
          ? Map<String, String>.from(map[Fields.digitalBuilds] as Map)
          : null,
      deviceLimit: map[Fields.deviceLimit] as int?,
```

**Step 3: Update `toMap`** — find where `isDigital` is written and add:

```dart
      if (digitalType != null) Fields.digitalType: digitalType,
      if (slug != null) Fields.slug: slug,
      if (digitalBuilds != null) Fields.digitalBuilds: digitalBuilds,
      if (deviceLimit != null) Fields.deviceLimit: deviceLimit,
```

**Step 4: Verify no analysis errors**

```bash
cd origna_gta && flutter analyze lib/models/generated/product_models.dart
```

**Step 5: Commit**

```bash
git add origna_gta/lib/models/generated/product_models.dart
git commit -m "feat(flutter-models): add digital fields to Product model (type, slug, builds)"
```

---

### Task 13: Update order_models.dart

**Files:**
- Modify: `origna_gta/lib/models/generated/order_models.dart`

**Step 1: Find `OrderItem` class. Add after `isDigital` field:**

```dart
  @Default(null) String? licenseKey,
  @Default(false) bool digitalUnlocked,
```

**Step 2: Update `fromMap`** — after `isDigital: _safeBool(map[Fields.isDigital])`:

```dart
      licenseKey: map[Fields.licenseKey] as String?,
      digitalUnlocked: _safeBool(map[Fields.digitalUnlocked]),
```

**Step 3: Update `toMap`** — add:

```dart
      if (licenseKey != null) Fields.licenseKey: licenseKey,
      Fields.digitalUnlocked: digitalUnlocked,
```

**Step 4: Verify**

```bash
cd origna_gta && flutter analyze lib/models/generated/order_models.dart
```

**Step 5: Commit**

```bash
git add origna_gta/lib/models/generated/order_models.dart
git commit -m "feat(flutter-models): add licenseKey + digitalUnlocked to OrderItem"
```

---

## Phase 8: Flutter Add Product State + ViewModel

### Task 14: Update AddProductState

**Files:**
- Modify: `origna_gta/lib/features/products/add_product_state.dart`

**Step 1: Add new fields to `AddProductState`** — after `isDigital`:

```dart
  final String? digitalType;          // 'software' | 'book' | null
  final String? macosDownloadUrl;
  final String? windowsDownloadUrl;
  final String? linuxDownloadUrl;
  final String? bookSourceUrl;
  final int? deviceLimit;
```

**Step 2: Update constructor** — add defaults after `isDigital = false`:

```dart
    this.digitalType,
    this.macosDownloadUrl,
    this.windowsDownloadUrl,
    this.linuxDownloadUrl,
    this.bookSourceUrl,
    this.deviceLimit,
```

**Step 3: Update `copyWith`** — add params using `_sentinel` pattern for nullable strings:

```dart
    Object? digitalType = _sentinel,
    Object? macosDownloadUrl = _sentinel,
    Object? windowsDownloadUrl = _sentinel,
    Object? linuxDownloadUrl = _sentinel,
    Object? bookSourceUrl = _sentinel,
    Object? deviceLimit = _sentinel,
```

And in the return statement:

```dart
      digitalType: digitalType == _sentinel ? this.digitalType : digitalType as String?,
      macosDownloadUrl: macosDownloadUrl == _sentinel ? this.macosDownloadUrl : macosDownloadUrl as String?,
      windowsDownloadUrl: windowsDownloadUrl == _sentinel ? this.windowsDownloadUrl : windowsDownloadUrl as String?,
      linuxDownloadUrl: linuxDownloadUrl == _sentinel ? this.linuxDownloadUrl : linuxDownloadUrl as String?,
      bookSourceUrl: bookSourceUrl == _sentinel ? this.bookSourceUrl : bookSourceUrl as String?,
      deviceLimit: deviceLimit == _sentinel ? this.deviceLimit : deviceLimit as int?,
```

**Step 4: Verify**

```bash
cd origna_gta && flutter analyze lib/features/products/add_product_state.dart
```

**Step 5: Commit**

```bash
git add origna_gta/lib/features/products/add_product_state.dart
git commit -m "feat(add-product): add digital type + build URL fields to state"
```

---

### Task 15: Update add_product_viewmodel.dart

**Files:**
- Modify: `origna_gta/lib/features/products/add_product_viewmodel.dart`

**Step 1: Add setters after `toggleDigital`:**

```dart
  void setDigitalType(String? type) => state = state.copyWith(digitalType: type);
  void setMacosDownloadUrl(String? url) => state = state.copyWith(macosDownloadUrl: url);
  void setWindowsDownloadUrl(String? url) => state = state.copyWith(windowsDownloadUrl: url);
  void setLinuxDownloadUrl(String? url) => state = state.copyWith(linuxDownloadUrl: url);
  void setBookSourceUrl(String? url) => state = state.copyWith(bookSourceUrl: url);
  void setDeviceLimit(int? limit) => state = state.copyWith(deviceLimit: limit);
```

**Step 2: Update `toggleDigital(false)` to clear digital sub-fields:**

Find `void toggleDigital(bool value)` and update so that when `value=false`, sub-fields are cleared:

```dart
  void toggleDigital(bool value) => state = state.copyWith(
    isDigital: value,
    freeShipping: value ? true : state.freeShipping,
    isPerishable: value ? false : state.isPerishable,
    isLocalDeliveryOnly: value ? false : state.isLocalDeliveryOnly,
    standardEnabled: value ? false : true,
    expressEnabled: value ? false : state.expressEnabled,
    sameDayEnabled: value ? false : state.sameDayEnabled,
    // Clear sub-fields when going back to physical
    digitalType: value ? state.digitalType : null,
    macosDownloadUrl: value ? state.macosDownloadUrl : null,
    windowsDownloadUrl: value ? state.windowsDownloadUrl : null,
    linuxDownloadUrl: value ? state.linuxDownloadUrl : null,
    bookSourceUrl: value ? state.bookSourceUrl : null,
    deviceLimit: value ? state.deviceLimit : null,
  );
```

**Step 3: Update validation in `addProduct` method**

Find the validation section (where address, price etc. are validated). Add digital validation before the submit:

```dart
    // Digital product validation
    if (state.isDigital) {
      if (state.digitalType == null) {
        state = state.copyWith(errorMessage: 'Select a digital product type (Software or Book)');
        return;
      }
      if (state.digitalType == DigitalTypeValues.software) {
        final urls = [state.macosDownloadUrl, state.windowsDownloadUrl, state.linuxDownloadUrl];
        if (urls.every((u) => u == null || u.trim().isEmpty)) {
          state = state.copyWith(errorMessage: 'Add at least one platform download URL');
          return;
        }
        final allUrls = urls.whereType<String>().where((u) => u.trim().isNotEmpty);
        if (allUrls.any((u) => !u.startsWith('https://'))) {
          state = state.copyWith(errorMessage: 'Download URLs must start with https://');
          return;
        }
      } else if (state.digitalType == DigitalTypeValues.book) {
        if (state.bookSourceUrl == null || state.bookSourceUrl!.trim().isEmpty) {
          state = state.copyWith(errorMessage: 'Enter the book download URL');
          return;
        }
        if (!state.bookSourceUrl!.startsWith('https://')) {
          state = state.copyWith(errorMessage: 'Book URL must start with https://');
          return;
        }
      }
    }
```

**Step 4: Pass digital fields to `addProduct` call**

Find where `ProductCreate` or the product map is built. Add:

```dart
      if (state.isDigital && state.digitalType != null) ...{
        Fields.digitalType: state.digitalType,
        if (state.digitalType == DigitalTypeValues.software) ...{
          Fields.digitalBuilds: {
            if (state.macosDownloadUrl?.isNotEmpty == true)
              DigitalPlatformValues.macos: state.macosDownloadUrl!,
            if (state.windowsDownloadUrl?.isNotEmpty == true)
              DigitalPlatformValues.windows: state.windowsDownloadUrl!,
            if (state.linuxDownloadUrl?.isNotEmpty == true)
              DigitalPlatformValues.linux: state.linuxDownloadUrl!,
          },
          if (state.deviceLimit != null)
            Fields.deviceLimit: state.deviceLimit,
        },
        if (state.digitalType == DigitalTypeValues.book)
          Fields.bookSourceUrl: state.bookSourceUrl,
      },
```

**Step 5: Verify**

```bash
cd origna_gta && flutter analyze lib/features/products/add_product_viewmodel.dart
```

**Step 6: Commit**

```bash
git add origna_gta/lib/features/products/add_product_viewmodel.dart
git commit -m "feat(add-product): add digital type setters, validation, and field submission in viewmodel"
```

---

## Phase 9: Flutter Add Product Screen UI

### Task 16: Add digital sub-type section to `addproduct_screen.dart`

**Files:**
- Modify: `origna_gta/lib/screens/addproduct_screen.dart`

**Step 1: Find where the digital toggle is rendered** (search for `toggleDigital` or `isDigital` in the screen). Immediately after the digital toggle card, add a new `_buildDigitalProductSection()` method call that is shown when `state.isDigital`.

**Step 2: Add `_buildDigitalProductSection` method:**

```dart
Widget _buildDigitalProductSection(AddProductState state, AddProductViewModel viewModel) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),
      // Sub-type selector
      Row(
        children: [
          Expanded(
            child: _DigitalTypeCard(
              label: 'Software',
              icon: Icons.computer_outlined,
              selected: state.digitalType == DigitalTypeValues.software,
              onTap: () => viewModel.setDigitalType(DigitalTypeValues.software),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DigitalTypeCard(
              label: 'Book',
              icon: Icons.menu_book_outlined,
              selected: state.digitalType == DigitalTypeValues.book,
              onTap: () => viewModel.setDigitalType(DigitalTypeValues.book),
            ),
          ),
        ],
      ),
      if (state.digitalType == DigitalTypeValues.software) ...[
        const SizedBox(height: 16),
        _sectionLabel('Download Links', subtitle: 'At least one platform required'),
        _buildUrlField(
          label: 'macOS (.dmg)',
          placeholder: 'https://releases.yoursite.com/app.dmg',
          value: state.macosDownloadUrl,
          onChanged: viewModel.setMacosDownloadUrl,
        ),
        _buildUrlField(
          label: 'Windows (.exe / .msi)',
          placeholder: 'https://releases.yoursite.com/app.exe',
          value: state.windowsDownloadUrl,
          onChanged: viewModel.setWindowsDownloadUrl,
        ),
        _buildUrlField(
          label: 'Linux (.deb / .AppImage)  — optional',
          placeholder: 'https://releases.yoursite.com/app.deb',
          value: state.linuxDownloadUrl,
          onChanged: viewModel.setLinuxDownloadUrl,
        ),
        const SizedBox(height: 12),
        _buildDeviceLimitField(state, viewModel),
      ],
      if (state.digitalType == DigitalTypeValues.book) ...[
        const SizedBox(height: 16),
        _sectionLabel('Book Download URL', subtitle: 'PDF or EPUB link (never shown to buyers directly)'),
        _buildUrlField(
          label: 'Download source URL',
          placeholder: 'https://storage.yoursite.com/book.pdf',
          value: state.bookSourceUrl,
          onChanged: viewModel.setBookSourceUrl,
        ),
      ],
    ],
  );
}

Widget _buildUrlField({
  required String label,
  required String placeholder,
  required String? value,
  required void Function(String?) onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, hintText: placeholder),
      keyboardType: TextInputType.url,
      onChanged: (v) => onChanged(v.trim().isEmpty ? null : v.trim()),
    ),
  );
}

Widget _buildDeviceLimitField(AddProductState state, AddProductViewModel viewModel) {
  return TextFormField(
    initialValue: state.deviceLimit?.toString(),
    decoration: const InputDecoration(
      labelText: 'Device limit',
      hintText: 'Leave blank for unlimited',
    ),
    keyboardType: TextInputType.number,
    onChanged: (v) => viewModel.setDeviceLimit(int.tryParse(v.trim())),
  );
}
```

Also add a simple `_DigitalTypeCard` private widget:

```dart
class _DigitalTypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DigitalTypeCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.transparent,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon,
              color: selected ? Theme.of(context).colorScheme.primary : null),
            const SizedBox(height: 4),
            Text(label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Theme.of(context).colorScheme.primary : null,
              )),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Call `_buildDigitalProductSection` in the build tree**

After the digital toggle, add:

```dart
if (state.isDigital)
  _buildDigitalProductSection(state, viewModel),
```

**Step 4: Verify no analysis errors**

```bash
cd origna_gta && flutter analyze lib/screens/addproduct_screen.dart
```

**Step 5: Commit**

```bash
git add origna_gta/lib/screens/addproduct_screen.dart
git commit -m "feat(add-product-ui): add software/book sub-type selector and URL input fields"
```

---

## Phase 10: Product Slug Routing + Sharing

### Task 17: Add `/p/{slug}` route and `getProductBySlug` repository method

**Files:**
- Modify: `origna_gta/lib/core/routes.dart`
- Modify: `origna_gta/lib/core/repositories/product_repository.dart`
- Modify: `origna_gta/lib/origna_app.dart`

**Step 1: Add route constant to `routes.dart`**

```dart
static const String productBySlug = '/p';  // used as /p/{slug}
```

Add typed arg class:

```dart
/// Arguments for [AppRoutes.productBySlug].
class ProductSlugArgs {
  final String slug;
  const ProductSlugArgs({required this.slug});
}
```

**Step 2: Add `getProductBySlug` to `product_repository.dart`**

```dart
Future<Product?> getProductBySlug(String slug) async {
  final snap = await _db
      .collection(Collections.products)
      .where(Fields.slug, isEqualTo: slug)
      .limit(1)
      .get();
  if (snap.docs.isEmpty) return null;
  return Product.fromMap(snap.docs.first.data(), snap.docs.first.id);
}
```

**Step 3: Handle `/p/{slug}` in `onGenerateRoute` in `origna_app.dart`**

Find the section that handles routes (around line 234 where `productDetails` is handled). Add:

```dart
  // /p/{slug} — shareable product URL (web + deep link)
  if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'p') {
    final slug = uri.pathSegments[1];
    return MaterialPageRoute(
      builder: (_) => _ProductBySlugScreen(slug: slug),
    );
  }
```

Create `_ProductBySlugScreen` as a private widget in the same file (or a separate file if preferred):

```dart
class _ProductBySlugScreen extends ConsumerWidget {
  final String slug;
  const _ProductBySlugScreen({required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Product?>(
      future: ref.read(productRepositoryProvider).getProductBySlug(slug),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final product = snapshot.data;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Product not found')),
          );
        }
        // Reuse existing product detail screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.productDetails,
            arguments: ProductDetailsArgs(productId: product.id, product: product.toMap()),
          );
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
```

Also update the deep link handler in `initState` to handle `/p/{slug}`:

```dart
_deepLinkSubscription = appLinks.uriLinkStream.listen((Uri uri) {
  final navigator = _navigatorKey.currentState;
  if (navigator == null) return;
  final segs = uri.pathSegments;
  if (segs.length == 2 && segs[0] == 'p') {
    navigator.pushNamed('/p/${segs[1]}');
    return;
  }
  final path = uri.path.isNotEmpty ? uri.path : '/';
  final query = uri.query.isNotEmpty ? '?${uri.query}' : '';
  navigator.pushNamed('$path$query');
});
```

**Step 4: Verify**

```bash
cd origna_gta && flutter analyze lib/core/routes.dart lib/origna_app.dart lib/core/repositories/product_repository.dart
```

**Step 5: Commit**

```bash
git add origna_gta/lib/core/routes.dart origna_gta/lib/origna_app.dart origna_gta/lib/core/repositories/product_repository.dart
git commit -m "feat(routing): add /p/{slug} product share route + deep link handling"
```

---

### Task 18: Add share button to product detail screen

**Files:**
- Modify: `origna_gta/lib/screens/productdetails_screen.dart`

**Step 1: Check if `share_plus` is in pubspec**

```bash
grep "share_plus" origna_gta/pubspec.yaml
```

If not present, add it:
```bash
cd origna_gta && flutter pub add share_plus
```

**Step 2: Add share button to the `AppBar` actions in `productdetails_screen.dart`**

Find the `AppBar` widget. Add to `actions`:

```dart
if (product.slug != null)
  IconButton(
    icon: const Icon(Icons.share_outlined),
    tooltip: 'Share',
    onPressed: () {
      Share.share(
        'Check out ${product.name} on Origna!\nhttps://origna.com/p/${product.slug}',
        subject: product.name,
      );
    },
  ),
```

**Step 3: Add import at top of file:**

```dart
import 'package:share_plus/share_plus.dart';
```

**Step 4: Verify**

```bash
cd origna_gta && flutter analyze lib/screens/productdetails_screen.dart
```

**Step 5: Commit**

```bash
git add origna_gta/lib/screens/productdetails_screen.dart origna_gta/pubspec.yaml origna_gta/pubspec.lock
git commit -m "feat(product-detail): add share button with slug-based URL"
```

---

## Phase 11: Orders UI — License Display

### Task 19: Add license key display and download button to order item card

**Files:**
- Modify: `origna_gta/lib/features/orders/` (identify the order item card widget — check `orders_screen.dart` or `order_detail_screen.dart`)

**Step 1: Find the order item card widget**

```bash
grep -r "OrderItem\|orderItem\|item.name\|item.price" origna_gta/lib/features/orders/ -l
```

**Step 2: In the order item card**, after existing item display, add:

```dart
if (item.isDigital && item.digitalUnlocked) ...[
  const SizedBox(height: 12),
  _DigitalItemActions(item: item),
],
```

**Step 3: Create `_DigitalItemActions` widget** (in the same file or a new `digital_item_actions.dart`):

```dart
class _DigitalItemActions extends ConsumerWidget {
  final OrderItem item;
  const _DigitalItemActions({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // License key row
          if (item.licenseKey != null) ...[
            const Text('License Key', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    item.licenseKey!,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 14, letterSpacing: 1.2),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.licenseKey!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('License key copied'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Software: download links per platform
          if (_isSoftware(item)) _SoftwareDownloadLinks(item: item),

          // Book: download button
          if (_isBook(item)) _BookDownloadButton(item: item),
        ],
      ),
    );
  }

  bool _isSoftware(OrderItem item) {
    // Detect from product details in order — check if digitalBuilds exist via order metadata
    // For now use licenseKey presence + no accessToken as heuristic (backend sets digitalType on item)
    return item.isDigital && item.digitalUnlocked && item.licenseKey != null;
  }

  bool _isBook(OrderItem item) => false; // refined in next step
}
```

> **Note:** To properly distinguish software vs book in the order item card, `digitalType` should also be stored on the order item. If it's not yet there, add it to the order item model (follow same pattern as `licenseKey` in Task 13) and populate it in `_generate_digital_licenses`. This makes the UI logic clean.

**Step 4: Add `digitalType` to OrderItem if missing**

If `digitalType` is not yet on `OrderItem`, add it following Task 13 pattern:
- Python: `digitalType: str | None = Field(default=None)`
- Dart: `@Default(null) String? digitalType`
- Set in `_generate_digital_licenses`: `updated_item["digitalType"] = digital_type`

**Step 5: Implement `_SoftwareDownloadLinks` widget:**

```dart
class _SoftwareDownloadLinks extends StatelessWidget {
  final OrderItem item;
  const _SoftwareDownloadLinks({required this.item});

  @override
  Widget build(BuildContext context) {
    // digitalBuilds stored on order item (populated from product at purchase time)
    final builds = item.digitalBuilds ?? {};
    if (builds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Download', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: builds.entries.map((e) {
            final platformLabel = {
              'macos': 'macOS',
              'windows': 'Windows',
              'linux': 'Linux',
            }[e.key] ?? e.key;
            return OutlinedButton.icon(
              icon: const Icon(Icons.download_outlined, size: 16),
              label: Text(platformLabel),
              onPressed: () => launchUrl(Uri.parse(e.value)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

> Add `digitalBuilds: Map<String, String>?` to `OrderItem` model following same pattern as Task 13.

**Step 6: Implement `_BookDownloadButton` widget:**

```dart
class _BookDownloadButton extends ConsumerStatefulWidget {
  final OrderItem item;
  const _BookDownloadButton({required this.item});

  @override
  ConsumerState<_BookDownloadButton> createState() => _BookDownloadButtonState();
}

class _BookDownloadButtonState extends ConsumerState<_BookDownloadButton> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await functions
          .httpsCallable('generate_book_download_session')
          .call({'licenseKey': widget.item.licenseKey});
      final downloadUrl = result.data['downloadUrl'] as String;
      await launchUrl(Uri.parse(downloadUrl), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: _loading
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download_outlined, size: 16),
      label: const Text('Download Book'),
      onPressed: _loading ? null : _download,
    );
  }
}
```

**Step 7: Verify all**

```bash
cd origna_gta && flutter analyze lib/features/orders/
```

**Step 8: Commit**

```bash
git add origna_gta/lib/features/orders/
git commit -m "feat(orders-ui): add license key display, software download links, and book download button"
```

---

## Phase 12: Final Verification

### Task 20: Run all backend tests

```bash
cd functions && python -m pytest tests/test_handlers_digital.py tests/test_handlers_payment_stripe.py tests/test_pydantic_models.py tests/test_schema_sync.py -v
```
Expected: all PASSED

### Task 21: Run full Flutter analysis

```bash
cd origna_gta && flutter analyze --no-fatal-infos
```
Expected: No errors

### Task 22: Deploy backend to dev

```bash
cd functions && firebase deploy --only functions --project orignagta-dev
```

### Task 23: Manual smoke test (dev environment)

1. Seller creates a Software digital product → verify slug generated in Firestore
2. Buyer purchases → verify `licenses` collection has new doc, order item has `licenseKey`
3. Navigate to `https://orignagta-dev.web.app/p/{slug}` → verify redirect to product detail
4. Share button appears on product detail → verify URL format
5. In buyer orders → verify license key shown + copy button works
6. Book product: tap "Download Book" → verify redirect flow (410 on reuse, redirect on first use)

### Task 24: Final commit + deploy

```bash
git add -A
git commit -m "feat: complete digital products MVP (license keys, book redirect, slug sharing, deep links)"
firebase deploy --project orignagta-dev
```

---

## Adversarial Scenarios Covered

| Scenario | Defense |
|---|---|
| Buyer shares license key with friend | `activate_license` checks nothing — but device limit enforces max activations |
| Attacker guesses license key | Key space: 36^16 ≈ 7.96×10²⁴ — brute force infeasible |
| Attacker replays book redirect token | `used=true` check + atomic transaction prevents double-use |
| Race condition: two simultaneous book redirects | Firestore transaction makes `used=true` atomic |
| Seller provides malicious redirect URL | URL validated as `https://` at product creation; stored server-side, never user-controlled at redirect time |
| Buyer claims another user's license | `generate_book_download_session` checks `license.userId == caller_uid` |
| Webhook fires twice (idempotency) | `digitalUnlocked=true` check skips re-generation |
| Seller changes bookSourceUrl after sale | License doc stores URL at sale time — not re-fetched from product |
| SQL/NoSQL injection via licenseKey input | Regex `^[A-Z0-9]{4}-...$` rejects any non-conforming input before DB lookup |
| Platform not supported | `platform_not_supported` error before activation recorded |
| Unlimited device limit with malicious loop | Each activation is a Firestore write — Cloud Function timeout + per-IP rate limiting via Cloud Armor |
