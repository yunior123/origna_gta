---
name: full-stack-audit
description: Run a comprehensive cross-stack audit like the Kimi K2.5 audit system. Reads ALL frontend-backend file pairs and reports every inconsistency.
context: fork
agent: cross-stack-auditor
disable-model-invocation: true
---

# Full Stack Audit

Run a comprehensive audit of ALL cross-stack interfaces in the project.

## File Pairs to Compare (read each pair together)

### 1. Checkout Flow
- `origna_gta/lib/features/checkout/checkout_provider.dart` ↔ `functions/handlers/payment_stripe.py`

### 2. Order Operations
- `origna_gta/lib/features/orders/seller_orders_viewmodel.dart` ↔ `functions/handlers/orders.py`
- `origna_gta/lib/features/orders/buyer_orders_viewmodel.dart` ↔ `functions/handlers/orders.py`

### 3. Product CRUD
- `origna_gta/lib/features/products/add_product_viewmodel.dart` ↔ `functions/handlers/products.py`

### 4. Auth & Admin
- `origna_gta/lib/features/auth/auth_provider.dart` ↔ `functions/handlers/admin.py`

### 5. Schema Constants (MUST be identical)
- `origna_gta/lib/core/schema/schema_constants.dart` ↔ `functions/schema_constants.py`

### 6. Models (field-by-field comparison)
- `origna_gta/lib/models/generated/order_models.dart` ↔ `functions/models/order.py`
- `origna_gta/lib/models/generated/product_models.dart` ↔ `functions/models/product.py`
- `origna_gta/lib/models/generated/user_models.dart` ↔ `functions/models/user.py`

### 7. Shipping
- `origna_gta/lib/features/checkout/checkout_provider.dart` ↔ `functions/services/shipping_service.py`

## For Each Pair
1. Read both files completely
2. Compare: field names, types, enums, error handling, response format
3. Report mismatches in the standard MISMATCH format

## Invocation
```
/full-stack-audit
```
