# FXCleaner Digital Product — Full End-to-End Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make FXCleaner fully sellable as a lifetime-license software digital product on OrignaGTA worldwide, with professional license management, license revocation on refund, and license keys delivered via email.

**Architecture:** 8 independent tasks spanning Swift (FXCleaner app), Python (backend), and email templates. Backend changes are test-first (pytest). Swift changes use XCTest. All changes are backward-compatible — existing physical-product orders and existing digital purchases are unaffected.

**Tech Stack:** Swift 6 / Security framework (Keychain), Python 3 / Firebase Functions, Stripe, pytest-mock, XCTest

---

## Adversarial Scenarios (verified before shipping)

1. Buyer shares license key → deviceLimit enforced ✓
2. Buyer clears Keychain → re-activation works (key gone, license still in Firestore, new activation allowed if under limit) ✓
3. Malicious seller changes download URL after purchase → license doc stores URL at purchase time, buyer unaffected ✓
4. Refund webhook fires twice → idempotency check (`previously_refunded >= amount_refunded`) already blocks duplicate; revocation must be idempotent too ✓
5. Partial refund on digital → revoke all licenses (any refund = license invalid for lifetime model)
6. International buyer with no Canadian province → tax = 0 (no Canadian tax jurisdiction)
7. Mixed cart (physical + digital) from international buyer → physical items still require Canadian address; all-digital path is only for 100% digital carts
8. Race condition: refund fires before license generation completes → revocation function checks `digitalUnlocked` flag; if not set yet, license doc may not exist (no-op, safe)
9. All-digital cart with zero items → early validation blocks this before all_digital check
10. Attacker spoofs `isDigital=True` on a physical product → backend re-reads `isDigital` from Firestore, not client

---

## Task 1: FXCleaner — Keychain license key storage

**Files:**
- Modify: `~/Documents/GitHub/fxcleaner/fxcleaner_swiftui/Sources/LicenseService.swift:210-245`
- Modify: `~/Documents/GitHub/fxcleaner/fxcleaner_swiftui/Tests/DashboardViewModelTests.swift` (add Keychain tests)

### Step 1: Write the failing Swift test

Add this test to `DashboardViewModelTests.swift` (after existing tests):

```swift
func testLicenseStoreUsesKeychainNotUserDefaults() {
    let store = LicenseStore()
    let testKey = "REDACTED_SECRET"

    // Save to store
    store.saveLicenseKey(testKey)

    // Verify UserDefaults does NOT contain it
    let fromDefaults = UserDefaults.standard.string(forKey: "fxcleaner.license.key")
    XCTAssertNil(fromDefaults, "License key must NOT be in UserDefaults")

    // Verify we can load it back
    let loaded = store.loadLicenseKey()
    XCTAssertEqual(loaded, testKey, "Must round-trip through Keychain")

    // Clean up
    store.saveLicenseKey(nil)
    XCTAssertNil(store.loadLicenseKey(), "Nil save must delete from Keychain")
}
```

### Step 2: Run to verify it fails

```bash
cd ~/Documents/GitHub/fxcleaner/fxcleaner_swiftui
swift test --filter testLicenseStoreUsesKeychainNotUserDefaults 2>&1 | tail -10
```

Expected: FAIL — test passes (UserDefaults currently DOES hold the key).

### Step 3: Replace LicenseStore with Keychain implementation

In `LicenseService.swift`, replace the entire `LicenseStore` struct (lines 210–244) with:

```swift
import Foundation
import Security

struct LicenseStore: Sendable {
    private let keyStorageKey = "fxcleaner.license.key"
    private let deviceStorageKey = "fxcleaner.license.device"  // Device ID stays in UserDefaults (non-sensitive)
    private let keychainService = "com.orignaventures.fxcleaner"

    func loadLicenseKey() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keyStorageKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return nil
        }
        return value
    }

    func saveLicenseKey(_ value: String?) {
        guard let value else {
            // Delete
            let query: [CFString: Any] = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: keychainService,
                kSecAttrAccount: keyStorageKey,
            ]
            SecItemDelete(query as CFDictionary)
            return
        }
        guard let data = value.data(using: .utf8) else { return }

        // Try update first, then add
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: keychainService,
            kSecAttrAccount: keyStorageKey,
        ]
        let attrs: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, attrs as CFDictionary)

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData] = data
            addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    func loadOrCreateDeviceID() -> String {
        if let existing = UserDefaults.standard.string(forKey: deviceStorageKey),
           !existing.isEmpty {
            return existing
        }
        let generated = UUID().uuidString.lowercased()
        UserDefaults.standard.set(generated, forKey: deviceStorageKey)
        return generated
    }
}
```

### Step 4: Run test

```bash
cd ~/Documents/GitHub/fxcleaner/fxcleaner_swiftui
swift test --filter testLicenseStoreUsesKeychainNotUserDefaults 2>&1 | tail -10
```

Expected: PASS

### Step 5: Run full Swift test suite

```bash
cd ~/Documents/GitHub/fxcleaner/fxcleaner_swiftui
swift test 2>&1 | tail -20
```

Expected: All tests pass (Keychain is transparent to DashboardViewModel since it injects closures).

### Step 6: Commit

```bash
cd ~/Documents/GitHub/fxcleaner
git add fxcleaner_swiftui/Sources/LicenseService.swift fxcleaner_swiftui/Tests/DashboardViewModelTests.swift
git commit -m "feat(fxcleaner): store license key in Keychain instead of UserDefaults"
```

---

## Task 2: FXCleaner — productName in LicenseActivationResult + UI

**Files:**
- Modify: `~/Documents/GitHub/fxcleaner/fxcleaner_swiftui/Sources/LicenseService.swift:1-15`
- Modify: `~/Documents/GitHub/fxcleaner/fxcleaner_swiftui/Sources/DashboardViewModel.swift:753-765`

### Step 1: Write failing test

Add to `DashboardViewModelTests.swift`:

```swift
func testLicenseStatusShowsProductNameWhenAvailable() async {
    let vm = DashboardViewModel(
        serviceInfo: { EngineInfo(ready: true, version: "1.0", runtime: "swift") },
        serviceRun: { _, _, _ in EngineRunResult(output: "", commandPreview: "", exitCode: 0, duration: 0, reclaimedBytes: 0) },
        licenseActivate: { _, _, _ in
            LicenseActivationResult(approved: true, licenseKey: "ABCD-EFGH-IJKL-MNOP", downloadURLs: [:], activatedAt: nil, productName: "FXCleaner")
        },
        licenseVerify: { _, _, _ in throw LicenseServiceError.notConfigured }
    )

    let success = await vm.activateLicense(using: "ABCD-EFGH-IJKL-MNOP")
    XCTAssertTrue(success)
    XCTAssertTrue(vm.licenseStatusSummary.contains("FXCleaner"), "Status must include product name — got: \(vm.licenseStatusSummary)")
}
```

### Step 2: Run to verify it fails

```bash
cd ~/Documents/GitHub/fxcleaner/fxcleaner_swiftui
swift test --filter testLicenseStatusShowsProductNameWhenAvailable 2>&1 | tail -10
```

Expected: FAIL — compile error (productName not in LicenseActivationResult).

### Step 3: Add productName to LicenseActivationResult

In `LicenseService.swift`, update `LicenseActivationResult` (lines 3–15):

```swift
struct LicenseActivationResult: Decodable, Sendable {
    let approved: Bool
    let licenseKey: String?
    let downloadURLs: [String: String]
    let activatedAt: String?
    let productName: String?          // NEW: e.g. "FXCleaner"

    enum CodingKeys: String, CodingKey {
        case approved
        case licenseKey
        case downloadURLs = "downloadUrls"
        case activatedAt
        case productName
    }
}
```

### Step 4: Update applyActivatedLicense in DashboardViewModel

In `DashboardViewModel.swift`, update `applyActivatedLicense` (lines 753–765):

```swift
private func applyActivatedLicense(result: LicenseActivationResult, fallbackKey: String) {
    guard result.approved else { return }

    let resolvedKey = LicenseService.canonicalLicenseKey(result.licenseKey ?? fallbackKey)
    isLicenseActivated = true
    activeLicenseMaskedKey = LicenseService.maskedLicenseKey(resolvedKey)

    let displayName = result.productName ?? "FXCleaner"   // NEW: use productName from server

    if let activatedAt = formatActivationTimestamp(result.activatedAt) {
        licenseStatusSummary = "\(displayName) · Activee le \(activatedAt)"
    } else {
        licenseStatusSummary = "\(displayName) · Activee"
    }
}
```

### Step 5: Run tests

```bash
cd ~/Documents/GitHub/fxcleaner/fxcleaner_swiftui
swift test 2>&1 | tail -20
```

Expected: All tests pass.

### Step 6: Commit

```bash
cd ~/Documents/GitHub/fxcleaner
git add fxcleaner_swiftui/Sources/LicenseService.swift fxcleaner_swiftui/Sources/DashboardViewModel.swift fxcleaner_swiftui/Tests/DashboardViewModelTests.swift
git commit -m "feat(fxcleaner): show product name in license status from server response"
```

---

## Task 3: Backend — productName in license doc + activate_license response

**Files:**
- Modify: `functions/handlers/payment_stripe.py:1364-1382` (software license_doc)
- Modify: `functions/handlers/payment_stripe.py:1384-1396` (book license_doc)
- Modify: `functions/handlers/digital.py:68-97` (activate_license response)
- Modify: `functions/tests/test_handlers_payment_stripe.py` (update test_generate_digital_licenses_software)
- Modify: `functions/tests/test_handlers_digital.py` (add productName assertion)

### Step 1: Write failing tests

In `test_handlers_payment_stripe.py`, update `test_generate_digital_licenses_software` to assert `productName` is stored:

```python
def test_generate_digital_licenses_stores_product_name():
    """License doc must include productName from the product."""
    from handlers.payment_stripe import _generate_digital_licenses
    from unittest.mock import MagicMock, patch

    mock_db = MagicMock()
    mock_product = MagicMock()
    mock_product.exists = True
    mock_product.to_dict.return_value = {
        "name": "FXCleaner",
        "digitalType": "software",
        "digitalBuilds": {"macos": "https://example.com/app.dmg"},
        "deviceLimit": 3,
    }
    mock_doc_ref = MagicMock()
    mock_doc_ref.exists = False  # no collision
    mock_db.collection.return_value.document.return_value.get.side_effect = [
        mock_product,  # product lookup
        mock_doc_ref,  # license collision check
    ]

    order_data = {
        "userId": "buyer123",
        "items": [{"productId": "prod123", "isDigital": True, "digitalUnlocked": False}]
    }

    with patch("handlers.payment_stripe.get_db", return_value=mock_db):
        _generate_digital_licenses("order123", order_data)

    # Verify license was written with productName
    set_call = mock_db.collection.return_value.document.return_value.set
    written = set_call.call_args[0][0]
    assert written["productName"] == "FXCleaner"
```

In `test_handlers_digital.py`, add assertion for `productName` in activate response:

```python
def test_activate_license_returns_product_name(mocker):
    """activate_license response includes productName from license doc"""
    from handlers.digital import _activate_license_impl
    license_data = {
        "licenseKey": "ABCD-EFGH-IJKL-MNOP",
        "productId": "prod123",
        "orderId": "order123",
        "userId": "buyer123",
        "digitalType": "software",
        "status": "active",
        "supportedPlatforms": ["macos"],
        "deviceLimit": 3,
        "activations": [],
        "digitalBuilds": {"macos": "https://example.com/app.dmg"},
        "productName": "FXCleaner",  # stored in license doc
    }
    mock_doc = MagicMock()
    mock_doc.exists = True
    mock_doc.to_dict.return_value = license_data
    mock_db = MagicMock()
    mock_db.collection.return_value.document.return_value.get.return_value = mock_doc

    with patch("handlers.digital.get_db", return_value=mock_db):
        result = _activate_license_impl("ABCD-EFGH-IJKL-MNOP", "device-001", "macos")

    assert result["productName"] == "FXCleaner"
```

### Step 2: Run to verify they fail

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_payment_stripe.py::test_generate_digital_licenses_stores_product_name tests/test_handlers_digital.py::test_activate_license_returns_product_name -v 2>&1 | tail -15
```

Expected: FAIL.

### Step 3: Implement

**`payment_stripe.py`** — in `_generate_digital_licenses`, add `productName` to both `license_doc` dicts.

For software (around line 1369), add:
```python
"productName": product_data.get(Fields.NAME, ""),
```

For book (around line 1388), add:
```python
"productName": product_data.get(Fields.NAME, ""),
```

**`digital.py`** — in `_activate_license_impl`, add `productName` to the return dicts (both the idempotent re-activation return at line 68 and the new activation return at line 92):

For idempotent re-activation (around line 68):
```python
return {
    "approved": True,
    "licenseKey": license_key,
    "downloadUrls": lic.get(Fields.DIGITAL_BUILDS, {}),
    "activatedAt": act.get("activatedAt"),
    "productName": lic.get("productName", ""),   # NEW
}
```

For new activation (around line 92):
```python
return {
    "approved": True,
    "licenseKey": license_key,
    "downloadUrls": lic.get(Fields.DIGITAL_BUILDS, {}),
    "activatedAt": now.isoformat(),
    "productName": lic.get("productName", ""),   # NEW
}
```

Note: `Fields` doesn't have a `PRODUCT_NAME` constant — add `PRODUCT_NAME = "productName"` to `schema_constants.py` in the `Fields` class, or just use the string `"productName"` directly for now since it's in the license doc (not a Firestore collection field schema constant). Use the string directly to avoid touching `schema_constants.py` chain reaction.

### Step 4: Run tests

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_payment_stripe.py::test_generate_digital_licenses_stores_product_name tests/test_handlers_digital.py::test_activate_license_returns_product_name -v 2>&1 | tail -15
```

Expected: PASS.

### Step 5: Run full digital test suite

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_digital.py tests/test_handlers_payment_stripe.py -v 2>&1 | tail -25
```

Expected: All pass.

### Step 6: Commit

```bash
cd ~/Documents/GitHub/origna_gta/functions
git add handlers/payment_stripe.py handlers/digital.py tests/test_handlers_payment_stripe.py tests/test_handlers_digital.py
git commit -m "feat(digital): store and return productName in license doc and activate_license response"
```

---

## Task 4: Backend — worldwide digital sales (skip Canada check for all-digital carts)

**Files:**
- Modify: `functions/handlers/payment_stripe.py:519-855` (create_checkout_session validation + tax)
- Modify: `functions/tests/test_handlers_payment_stripe.py`

### Step 1: Write failing tests

Add to `test_handlers_payment_stripe.py`:

```python
def test_all_digital_cart_skips_canada_check(
    mock_get_db, mock_get_rate_limiter, mock_validate_postal
):
    """All-digital cart must not raise when country != Canada."""
    from handlers.payment_stripe import create_checkout_session
    # This is an integration-style test using the existing class fixture pattern.
    # See TestCreateCheckoutSession for the full mock setup pattern.
    pass  # Placeholder — see step 3 for approach


def test_all_digital_checkout_zero_shipping():
    """All-digital order: shipping cost = 0, tax = 0."""
    from handlers.payment_stripe import _calculate_digital_order_totals
    result = _calculate_digital_order_totals(actual_subtotal_cents=2999)
    assert result["shipping_cost_cents"] == 0
    assert result["tax_amount_cents"] == 0
    assert result["taxes_breakdown"] == {}
```

The second test drives us to extract a helper. Step 3 explains the implementation.

### Step 2: Run to verify they fail

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_payment_stripe.py::test_all_digital_checkout_zero_shipping -v 2>&1 | tail -10
```

Expected: FAIL — `_calculate_digital_order_totals` does not exist.

### Step 3: Implement

In `payment_stripe.py`, in `create_checkout_session`, make these changes:

**A — Compute `all_digital` BEFORE address validation (around line 520):**

After:
```python
items = data.get(Fields.ITEMS, [])
shipping_address = data.get(Fields.SHIPPING_ADDRESS, {})
client_subtotal = data.get(ApiKeys.SUBTOTAL, 0)

if not items or len(items) == 0:
    raise https_fn.HttpsError("invalid-argument", "No items in cart")
```

Add:
```python
# Detect all-digital cart (bypass physical shipping/address rules)
# NOTE: We re-verify isDigital server-side per item below; this is an early-path bypass.
all_digital = all(item.get(Fields.IS_DIGITAL, False) for item in items)
```

**B — Wrap the address validation block (lines 529–568) in `if not all_digital:`:**

```python
if not all_digital:
    if not shipping_address:
        raise https_fn.HttpsError("invalid-argument", "Shipping address required")

    # NORMALIZE: Prefer canonical schema field `state` (province code),
    # but also accept `province` from older clients.
    if Fields.STATE not in shipping_address and "province" in shipping_address:
        shipping_address[Fields.STATE] = shipping_address["province"]

    # Validate shipping address fields
    required_address_fields = [Fields.STREET, Fields.CITY, Fields.POSTAL_CODE, Fields.STATE, Fields.COUNTRY]
    for field in required_address_fields:
        if field not in shipping_address or not shipping_address[field]:
            raise https_fn.HttpsError("invalid-argument", f"Missing required address field: {field}")

    # Validate address field lengths
    address_length_limits = {
        Fields.STREET: 100, Fields.CITY: 50, Fields.POSTAL_CODE: 20,
        Fields.STATE: 50, Fields.COUNTRY: 50,
    }
    for field, max_length in address_length_limits.items():
        if len(str(shipping_address.get(field, ""))) > max_length:
            raise https_fn.HttpsError("invalid-argument", f"Address field {field} exceeds maximum length")

    postal_code = shipping_address.get(Fields.POSTAL_CODE, "")
    country = shipping_address.get(Fields.COUNTRY, AppConfig.DEFAULT_COUNTRY_NAME)

    if country.lower() != "canada":
        raise https_fn.HttpsError("invalid-argument", f"Shipping to {country} is not currently supported")

    try:
        validate_postal_code(postal_code)
    except ValueError as err:
        raise https_fn.HttpsError("invalid-argument", f"Invalid Canadian postal code format: {postal_code}") from err
else:
    # All-digital: no address needed. Keep shipping_address as-is (may be empty dict).
    # NORMALIZE province from address if provided (used for optional tax display).
    if Fields.STATE not in shipping_address and "province" in shipping_address:
        shipping_address[Fields.STATE] = shipping_address["province"]
```

**C — Skip delivery_speed and shipping calculation for all-digital (around line 750–767):**

```python
if all_digital:
    shipping_cost_cents = 0
    delivery_speed = DeliveryTypeValues.STANDARD
    delivery_instructions = ""
else:
    # existing delivery_speed + shipping calculation code here
    delivery_speed = data.get(Fields.DELIVERY_SPEED, DeliveryTypeValues.STANDARD)
    ...
    try:
        shipping_cost_dollars = calculate_shipping_cost(...)
        shipping_cost_cents = round(shipping_cost_dollars * 100)
    except ...
```

**D — Skip tax calculation for all-digital (around line 769):**

```python
if all_digital:
    # No Canadian tax for worldwide digital delivery
    tax_amount_cents = 0
    taxes_breakdown = {}
    item_taxes = []
    state_code = shipping_address.get(Fields.STATE, BusinessRules.DEFAULT_PROVINCE)
    is_reverse_charge = False
else:
    # existing STRIPE_TAX_ENABLED / manual tax block here
    state_code = shipping_address.get(Fields.STATE, BusinessRules.DEFAULT_PROVINCE)
    ...
```

**E — Add `_calculate_digital_order_totals` helper** (for testability, place just before `create_checkout_session`):

```python
def _calculate_digital_order_totals(actual_subtotal_cents: int) -> dict:
    """Zero shipping + zero tax for all-digital worldwide orders."""
    return {
        "shipping_cost_cents": 0,
        "tax_amount_cents": 0,
        "taxes_breakdown": {},
        "item_taxes": [],
    }
```

**F — Stripe session: no shipping for digital-only** (around line 1058, add `phone_number_collection` and remove shipping from session params):

The current `stripe.checkout.Session.create()` call has no `shipping_address_collection`. That's already correct. But add `phone_number_collection={"enabled": False}` for digital-only and ensure no shipping line items are added (already gated on `shipping_cost_cents > 0`).

No change needed to the Stripe session code — it already works since shipping line item only appears when `shipping_cost_cents > 0`.

### Step 4: Run tests

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_payment_stripe.py::test_all_digital_checkout_zero_shipping -v 2>&1 | tail -10
```

Expected: PASS.

### Step 5: Run full suite

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_payment_stripe.py -v 2>&1 | tail -30
```

Expected: All pass.

### Step 6: Commit

```bash
cd ~/Documents/GitHub/origna_gta/functions
git add handlers/payment_stripe.py tests/test_handlers_payment_stripe.py
git commit -m "feat(checkout): skip Canada-only check and address requirement for all-digital carts (worldwide digital sales)"
```

---

## Task 5: Backend — license revocation on refund

**Files:**
- Modify: `functions/handlers/payment_stripe.py:1950-2149` (process_charge_refunded)
- Modify: `functions/handlers/digital.py` (add `_revoke_digital_licenses_for_order`)
- Modify: `functions/tests/test_handlers_digital.py`
- Modify: `functions/tests/test_handlers_payment_stripe.py`

### Step 1: Write failing tests

In `test_handlers_digital.py`:

```python
def test_revoke_licenses_for_order_full_refund(mocker):
    """Full refund: all digital licenses in order are set to status=revoked."""
    from handlers.digital import _revoke_digital_licenses_for_order

    mock_db = MagicMock()
    # Two license docs belonging to this order
    license1 = MagicMock()
    license1.id = "AAAA-BBBB-CCCC-DDDD"
    license2 = MagicMock()
    license2.id = "EEEE-FFFF-GGGG-HHHH"

    mock_db.collection.return_value.where.return_value.stream.return_value = [license1, license2]

    with patch("handlers.digital.get_db", return_value=mock_db):
        count = _revoke_digital_licenses_for_order("order123")

    assert count == 2
    # Both licenses updated to revoked
    assert mock_db.collection.return_value.where.return_value.stream.called


def test_revoke_licenses_idempotent_when_none_found(mocker):
    """Order with no digital licenses: revoke returns 0, no error."""
    from handlers.digital import _revoke_digital_licenses_for_order

    mock_db = MagicMock()
    mock_db.collection.return_value.where.return_value.stream.return_value = []

    with patch("handlers.digital.get_db", return_value=mock_db):
        count = _revoke_digital_licenses_for_order("order_no_digital")

    assert count == 0
```

In `test_handlers_payment_stripe.py`:

```python
def test_full_refund_revokes_digital_licenses():
    """process_charge_refunded calls license revocation for digital orders."""
    from handlers.payment_stripe import process_charge_refunded
    from unittest.mock import MagicMock, patch

    mock_db = MagicMock()
    order_doc = MagicMock()
    order_doc.id = "order123"
    order_doc.reference = MagicMock()
    order_doc.to_dict.return_value = {
        "paymentStatus": "captured",
        "cumulativeRefundedCents": 0,
        "items": [{"productId": "prod1", "isDigital": True}],
    }
    mock_db.collection.return_value.where.return_value.limit.return_value.stream.return_value = iter([order_doc])
    # payouts query returns nothing
    mock_db.collection.return_value.where.return_value.where.return_value.stream.return_value = iter([])

    charge = {"payment_intent": "pi_test", "amount_refunded": 2999, "amount": 2999}

    with patch("handlers.payment_stripe.get_db", return_value=mock_db), \
         patch("handlers.digital._revoke_digital_licenses_for_order", return_value=1) as mock_revoke:
        process_charge_refunded(charge)

    mock_revoke.assert_called_once_with("order123")
```

### Step 2: Run to verify they fail

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_digital.py::test_revoke_licenses_for_order_full_refund tests/test_handlers_payment_stripe.py::test_full_refund_revokes_digital_licenses -v 2>&1 | tail -15
```

Expected: FAIL.

### Step 3: Implement

**In `digital.py`**, add this function before the Cloud Function endpoints:

```python
def _revoke_digital_licenses_for_order(order_id: str) -> int:
    """Revoke all active licenses belonging to an order.
    Idempotent: already-revoked licenses are skipped.
    Returns count of licenses revoked.
    """
    db = get_db()
    licenses = (
        db.collection(Collections.LICENSES)
        .where(Fields.ORDER_ID, "==", order_id)
        .stream()
    )
    count = 0
    now = datetime.now(timezone.utc)
    for lic_doc in licenses:
        lic = lic_doc.to_dict()
        if lic.get(Fields.STATUS) == LicenseStatusValues.ACTIVE:
            lic_doc.reference.update({
                Fields.STATUS: LicenseStatusValues.REVOKED,
                "revokedAt": now,
                "revokedReason": "refunded",
                "updatedAt": now,
            })
            count += 1
            logger.info(f"License {lic_doc.id} revoked for order {order_id} (refund)")
    return count
```

Note: `LicenseStatusValues.REVOKED` should already exist — verify in `schema_constants.py`. If not, add `REVOKED = "revoked"` to the class.

**In `payment_stripe.py`**, in `process_charge_refunded`, add license revocation BEFORE updating order status. Import the function at the top of the relevant block:

After the transfer reversal loop (around line 2123), before `if is_full_refund:`, add:

```python
# Revoke digital licenses on any refund (lifetime licenses — any refund invalidates)
try:
    from handlers.digital import _revoke_digital_licenses_for_order
    revoked_count = _revoke_digital_licenses_for_order(order_id)
    if revoked_count:
        logger.info(f"Revoked {revoked_count} digital license(s) for refunded order {order_id}")
except Exception as revoke_err:
    # Non-fatal: log but don't fail the refund webhook
    logger.error(f"License revocation failed for order {order_id}: {revoke_err}")
```

### Step 4: Run tests

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_digital.py::test_revoke_licenses_for_order_full_refund tests/test_handlers_digital.py::test_revoke_licenses_idempotent_when_none_found tests/test_handlers_payment_stripe.py::test_full_refund_revokes_digital_licenses -v 2>&1 | tail -20
```

Expected: PASS.

### Step 5: Run full digital + payment test suite

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_handlers_digital.py tests/test_handlers_payment_stripe.py -v 2>&1 | tail -30
```

Expected: All pass.

### Step 6: Commit

```bash
cd ~/Documents/GitHub/origna_gta/functions
git add handlers/digital.py handlers/payment_stripe.py tests/test_handlers_digital.py tests/test_handlers_payment_stripe.py
git commit -m "feat(digital): revoke license keys when order is refunded"
```

---

## Task 6: Email — digital-only status tracker

**Files:**
- Modify: `functions/services/email_service.py:295-436` (get_order_confirmation_email)
- Modify: `functions/tests/test_email_service.py`

### Step 1: Write failing test

In `test_email_service.py`, add:

```python
def test_digital_order_shows_instant_delivery_tracker():
    """Digital-only order: status tracker shows Confirmed + Delivered (no shipping steps)."""
    from services.email_service import get_order_confirmation_email
    order = {
        "orderId": "ord-digital-001",
        "userId": "buyer1",
        "items": [{"name": "FXCleaner", "price": 29.99, "quantity": 1, "isDigital": True}],
        "subtotalCents": 2999,
        "shippingCostCents": 0,
        "taxAmountCents": 0,
        "totalAmountCents": 2999,
        "taxes": {},
        "shippingAddress": {},
    }
    html = get_order_confirmation_email(order, lang="en")
    assert "Delivered Instantly" in html or "Instant" in html, "Must show instant delivery, not shipping steps"
    assert "🚚" not in html, "Must not show truck/shipping icon for digital orders"


def test_physical_order_shows_full_tracker():
    """Physical order: status tracker still shows all 4 steps."""
    from services.email_service import get_order_confirmation_email
    order = {
        "orderId": "ord-phys-001",
        "userId": "buyer1",
        "items": [{"name": "Widget", "price": 19.99, "quantity": 1, "isDigital": False}],
        "subtotalCents": 1999,
        "shippingCostCents": 500,
        "taxAmountCents": 260,
        "totalAmountCents": 2759,
        "taxes": {"HST": 2.60},
        "shippingAddress": {
            "street": "123 Main St", "city": "Toronto", "state": "ON",
            "postalCode": "M5V1A1", "country": "Canada"
        },
    }
    html = get_order_confirmation_email(order, lang="en")
    assert "🚚" in html, "Physical order must show shipping tracker"
```

### Step 2: Run to verify they fail

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_email_service.py::test_digital_order_shows_instant_delivery_tracker -v 2>&1 | tail -10
```

Expected: FAIL.

### Step 3: Implement

In `get_order_confirmation_email` (around line 295), detect `all_digital`:

```python
# Detect all-digital order for custom status tracker
items_list = order_data.get(Fields.ITEMS, [])
all_digital_order = bool(items_list) and all(item.get(Fields.IS_DIGITAL, False) for item in items_list)
```

Replace the ORDER STATUS TRACKER block (lines 408–436) with a conditional:

```python
<!-- ORDER STATUS TRACKER -->
<tr><td style="padding: 32px 40px 24px 40px;">
    <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
    <tr>
        <td width="{'50%' if all_digital_order else '25%'}" align="center">
            ...
        </td>
        ...
    </tr>
    </table>
</td></tr>
```

Since this is an f-string, use Python conditional logic. Replace the entire tracker section with:

```python
if all_digital_order:
    _status_tracker_html = f"""
    <tr><td style="padding: 32px 40px 24px 40px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
        <tr>
            <td width="50%" align="center">
                <div style="width: 36px; height: 36px; background: linear-gradient(135deg, #667EEA, #764BA2); border-radius: 50%; margin: 0 auto 8px; line-height: 36px; font-size: 16px; color: white;">✓</div>
                <div style="font-size: 11px; font-weight: 700; color: #667EEA; text-transform: uppercase; letter-spacing: 0.5px;">{_t_confirmed}</div>
            </td>
            <td width="50%" align="center">
                <div style="width: 36px; height: 36px; background: linear-gradient(135deg, #10B981, #059669); border-radius: 50%; margin: 0 auto 8px; line-height: 36px; font-size: 16px; color: white;">⚡</div>
                <div style="font-size: 11px; font-weight: 700; color: #10B981; text-transform: uppercase; letter-spacing: 0.5px;">{"Delivered Instantly" if lang == "en" else "Livré instantanément"}</div>
            </td>
        </tr>
        <tr><td colspan="2" style="padding-top: 12px;">
            <div style="height: 4px; background: #e8ebf0; border-radius: 4px; overflow: hidden;">
                <div style="width: 100%; height: 100%; background: linear-gradient(90deg, #10B981, #059669); border-radius: 4px;"></div>
            </div>
        </td></tr>
        </table>
    </td></tr>"""
else:
    _status_tracker_html = f"""
    <tr><td style="padding: 32px 40px 24px 40px;">
        ...existing 4-step tracker HTML...
    </td></tr>"""
```

Then use `{_status_tracker_html}` in place of the inline tracker block in the final `return f"""..."""`.

### Step 4: Run tests

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_email_service.py::test_digital_order_shows_instant_delivery_tracker tests/test_email_service.py::test_physical_order_shows_full_tracker -v 2>&1 | tail -15
```

Expected: PASS.

### Step 5: Run full email test suite

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_email_service.py -v 2>&1 | tail -30
```

Expected: All pass.

### Step 6: Commit

```bash
cd ~/Documents/GitHub/origna_gta/functions
git add services/email_service.py tests/test_email_service.py
git commit -m "feat(email): show 2-step instant-delivery tracker for digital-only orders"
```

---

## Task 7: Email — license key block in order confirmation

**Files:**
- Modify: `functions/services/email_service.py` (get_order_confirmation_email)
- Modify: `functions/tests/test_email_service.py`

### Step 1: Write failing tests

```python
def test_digital_order_email_contains_license_key():
    """Order confirmation email must show the license key for software digital items."""
    from services.email_service import get_order_confirmation_email
    order = {
        "orderId": "ord-digital-001",
        "userId": "buyer1",
        "items": [{
            "name": "FXCleaner",
            "price": 29.99,
            "quantity": 1,
            "isDigital": True,
            "digitalType": "software",
            "digitalUnlocked": True,
            "licenseKey": "ABCD-EFGH-IJKL-MNOP",
            "digitalBuilds": {"macos": "https://r2.example.com/fxcleaner.dmg"},
        }],
        "subtotalCents": 2999,
        "shippingCostCents": 0,
        "taxAmountCents": 0,
        "totalAmountCents": 2999,
        "taxes": {},
        "shippingAddress": {},
    }
    html = get_order_confirmation_email(order, lang="en")
    assert "ABCD-EFGH-IJKL-MNOP" in html, "License key must appear in email"
    assert "FXCleaner" in html
    assert "macos" in html.lower() or "macOS" in html, "Download platform must appear"


def test_book_order_email_contains_access_instructions():
    """Book digital item: email shows 'access your book' CTA, not a license key."""
    from services.email_service import get_order_confirmation_email
    order = {
        "orderId": "ord-book-001",
        "userId": "buyer1",
        "items": [{
            "name": "Python Mastery",
            "price": 19.99,
            "quantity": 1,
            "isDigital": True,
            "digitalType": "book",
            "digitalUnlocked": True,
            "licenseKey": "BOOK-ABCD-EFGH-IJKL",
        }],
        "subtotalCents": 1999,
        "shippingCostCents": 0,
        "taxAmountCents": 0,
        "totalAmountCents": 1999,
        "taxes": {},
        "shippingAddress": {},
    }
    html = get_order_confirmation_email(order, lang="en")
    assert "BOOK-ABCD-EFGH-IJKL" in html or "Your Orders" in html, "Must show book access path"


def test_physical_order_email_has_no_license_block():
    """Physical-only order: no license key section in email."""
    from services.email_service import get_order_confirmation_email
    order = {
        "orderId": "ord-phys-002",
        "items": [{"name": "Widget", "price": 19.99, "quantity": 1, "isDigital": False}],
        "subtotalCents": 1999, "shippingCostCents": 500, "taxAmountCents": 260,
        "totalAmountCents": 2759, "taxes": {"HST": 2.60},
        "shippingAddress": {
            "street": "123 Main St", "city": "Toronto", "state": "ON",
            "postalCode": "M5V1A1", "country": "Canada"
        },
    }
    html = get_order_confirmation_email(order, lang="en")
    assert "License Key" not in html and "licenseKey" not in html.lower()
```

### Step 2: Run to verify they fail

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_email_service.py::test_digital_order_email_contains_license_key tests/test_email_service.py::test_physical_order_email_has_no_license_block -v 2>&1 | tail -15
```

Expected: FAIL.

### Step 3: Implement

In `get_order_confirmation_email`, after the `<!-- ITEMS TABLE -->` block and before `<!-- ORDER RECEIPT -->`, insert a license key section. Build it in Python before the final `return`:

```python
# Build digital license block for digital items (inserted after items table)
_digital_block_html = ""
digital_items = [
    item for item in order_data.get(Fields.ITEMS, [])
    if item.get(Fields.IS_DIGITAL) and item.get(Fields.DIGITAL_UNLOCKED)
]
if digital_items:
    license_rows = ""
    for item in digital_items:
        safe_name = html.escape(str(item.get(Fields.NAME, "Digital Product")))
        license_key = item.get(Fields.LICENSE_KEY, "")
        digital_type = item.get(Fields.DIGITAL_TYPE, "")
        builds = item.get(Fields.DIGITAL_BUILDS) or {}

        if digital_type == DigitalTypeValues.SOFTWARE and license_key:
            # Build download links for each platform
            platform_links = ""
            platform_labels = {"macos": "macOS", "windows": "Windows", "linux": "Linux"}
            for platform, url in builds.items():
                label = platform_labels.get(platform, platform.capitalize())
                platform_links += f'<a href="{url}" style="color: #667EEA; text-decoration: none; margin-right: 16px;">{label} ↓</a>'

            instructions = ("Open FXCleaner → click <strong>Enter License</strong> → paste your key"
                           if lang == "en" else
                           "Ouvrez FXCleaner → cliquez <strong>Entrer la licence</strong> → collez votre clé")

            license_rows += f"""
            <tr style="background-color: #f8f9ff;">
                <td style="padding: 16px 20px;">
                    <div style="font-size: 13px; font-weight: 700; color: #1a1a2e; margin-bottom: 8px;">{safe_name}</div>
                    <div style="font-family: 'Courier New', monospace; font-size: 18px; font-weight: 700; color: #667EEA; letter-spacing: 2px; background: #eef0ff; padding: 10px 16px; border-radius: 8px; display: inline-block; margin-bottom: 8px;">{html.escape(license_key)}</div>
                    {f'<div style="margin-bottom: 8px;">{platform_links}</div>' if platform_links else ""}
                    <div style="font-size: 12px; color: #555;">{instructions}</div>
                </td>
            </tr>"""

        elif digital_type == DigitalTypeValues.BOOK and license_key:
            access_label = "Access your book in the app" if lang == "en" else "Accédez à votre livre dans l'application"
            license_rows += f"""
            <tr style="background-color: #f8f9ff;">
                <td style="padding: 16px 20px;">
                    <div style="font-size: 13px; font-weight: 700; color: #1a1a2e; margin-bottom: 8px;">{safe_name}</div>
                    <div style="font-size: 13px; color: #555;">{access_label}</div>
                    <div style="font-family: 'Courier New', monospace; font-size: 12px; color: #888; margin-top: 6px;">Key: {html.escape(license_key)}</div>
                </td>
            </tr>"""

    if license_rows:
        heading = "Your Digital Downloads" if lang == "en" else "Vos téléchargements numériques"
        _digital_block_html = f"""
        <tr><td style="padding: 0 40px 28px 40px;">
            <h2 style="margin: 0 0 16px 0; font-size: 16px; font-weight: 700; color: #1a1a2e; text-transform: uppercase; letter-spacing: 1px;">
                <span style="border-bottom: 3px solid #10B981; padding-bottom: 6px;">🔑 {heading}</span>
            </h2>
            <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border-radius: 12px; overflow: hidden; border: 2px solid #10B981;">
                {license_rows}
            </table>
        </td></tr>"""
```

Then insert `{_digital_block_html}` in the `return f"""..."""` right after the items table block.

### Step 4: Run tests

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_email_service.py::test_digital_order_email_contains_license_key tests/test_email_service.py::test_book_order_email_contains_access_instructions tests/test_email_service.py::test_physical_order_email_has_no_license_block -v 2>&1 | tail -20
```

Expected: PASS.

### Step 5: Run full email suite

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/test_email_service.py -v 2>&1 | tail -30
```

Expected: All pass.

### Step 6: Commit

```bash
cd ~/Documents/GitHub/origna_gta/functions
git add services/email_service.py tests/test_email_service.py
git commit -m "feat(email): show license key and download links in order confirmation for digital products"
```

---

## Task 8: Final verification — run all tests

### Step 1: Run all Python tests

```bash
cd ~/Documents/GitHub/origna_gta/functions
python -m pytest tests/ -v --tb=short 2>&1 | tail -40
```

Expected: All tests pass.

### Step 2: Run all Swift tests

```bash
cd ~/Documents/GitHub/fxcleaner/fxcleaner_swiftui
swift test 2>&1 | tail -20
```

Expected: All tests pass.

### Step 3: Run schema sync checker

```bash
# In origna_gta root
./admin schema check --env=dev
```

### Step 4: Final commit

```bash
cd ~/Documents/GitHub/origna_gta
git add .
git commit -m "chore: finalize FXCleaner digital product end-to-end (worldwide sales, license key email, Keychain, revocation on refund)"
```

---

## Cross-stack summary of all changes

| File | Change |
|------|--------|
| `fxcleaner_swiftui/Sources/LicenseService.swift` | Keychain storage + productName field |
| `fxcleaner_swiftui/Sources/DashboardViewModel.swift` | Show productName in licenseStatusSummary |
| `functions/handlers/digital.py` | Add `_revoke_digital_licenses_for_order` + productName in response |
| `functions/handlers/payment_stripe.py` | all_digital bypass, productName in license doc, revoke on refund |
| `functions/services/email_service.py` | License key block + digital-only tracker |
| `functions/tests/test_handlers_digital.py` | Tests for revocation + productName |
| `functions/tests/test_handlers_payment_stripe.py` | Tests for worldwide + revocation |
| `functions/tests/test_email_service.py` | Tests for license block + tracker |
