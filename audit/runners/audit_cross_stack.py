#!/usr/bin/env python3
"""
Cross-Stack Audit — Sends matched frontend↔backend file pairs to Kimi K2.5
for deep analysis of inconsistencies at the stack boundary.

Usage: python3 audit/runners/audit_cross_stack.py
"""
import sys
from pathlib import Path

_audit_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(_audit_dir))
from common import bundle_targeted_files, run_streaming_audit, save_report

WORKFLOW_NAME = "Cross-Stack Consistency"

# Matched file pairs: each group contains the frontend + backend files that must agree
CROSS_STACK_FILES = [
    # --- Schema Constants (MUST be identical) ---
    "functions/schema_constants.py",
    "origna_gta/lib/core/schema/schema_constants.dart",
    "docs/database_schema.json",
    
    # --- Order Models (fields must match) ---
    "functions/models/order.py",
    "origna_gta/lib/models/generated/order_models.dart",
    
    # --- Product Models ---
    "functions/models/product.py",
    "origna_gta/lib/models/generated/product_models.dart",
    
    # --- User Models ---
    "functions/models/user.py",
    "origna_gta/lib/models/generated/user_models.dart",
    
    # --- Base Models / Enums ---
    "functions/models/base.py",
    "origna_gta/lib/models/generated/base_models.dart",
    
    # --- Checkout ↔ Payment ---
    "origna_gta/lib/features/checkout/checkout_provider.dart",
    "functions/handlers/payment_stripe.py",
    
    # --- Orders ↔ Orders ---
    "origna_gta/lib/features/orders/seller_orders_viewmodel.dart",
    "origna_gta/lib/features/orders/buyer_orders_viewmodel.dart",
    "functions/handlers/orders.py",
    
    # --- Products ↔ Products ---
    "origna_gta/lib/features/products/add_product_viewmodel.dart",
    "origna_gta/lib/features/products/products_provider.dart",
    "functions/handlers/products.py",
    
    # --- Auth ↔ Admin ---
    "origna_gta/lib/features/auth/auth_provider.dart",
    "origna_gta/lib/core/repositories/auth_repository.dart",
    "functions/handlers/admin.py",
    
    # --- Firestore Rules ---
    "firestore.rules",
]

PROMPT = """# Cross-Stack Consistency Audit — OrignaGta

You are an expert code auditor specializing in full-stack consistency for Flutter + Python Firebase projects.

## Your Task
Analyze the files below, which are MATCHED PAIRS of frontend (Dart/Flutter) and backend (Python/Firebase) code that MUST agree. Find every inconsistency, mismatch, or logic bug at the boundary between frontend and backend.

## What to Check

### 1. Schema Constants Sync
- Compare `schema_constants.py` (Python) vs `schema_constants.dart` (Dart) — every field name, collection name, and enum value must be identical
- Compare both against `database_schema.json` — any field in the schema that's missing from constants?
- Any constant that's used in code but not defined in the schema?

### 2. Model Field Mismatches
For each model pair (Order, Product, User):
- Field names: identical between Python (Pydantic) and Dart (Freezed)?
- Field types: compatible? (String↔String, int↔int, Timestamp↔DateTime)
- Required vs Optional: same on both sides?
- Default values: same on both sides?
- Enum values: every value exists in both Python and Dart?

### 3. API Contract Mismatches
For each handler↔provider pair:
- Request body: fields sent by Dart match what Python expects?
- Response body: fields returned by Python match what Dart parses?
- Error handling: Dart handles all error codes Python can return?
- HTTP method and URL: correct?

### 4. State Machine Consistency
- Order status enum values: identical between `base_models.dart` and `models/base.py`?
- Transition rules: same transitions allowed in backend handler AND frontend UI?
- Any status shown in UI that backend doesn't support?

### 5. Firestore Rules vs Code
- Field names in `firestore.rules` match `schema_constants`?
- Rules enforce the same permissions as backend code?
- Any field writable in rules but not validated in backend?

### 6. Common Bug Patterns
- camelCase vs snake_case mismatches in Firestore field access
- Frontend sends a field the backend ignores (data loss)
- Backend returns a field the frontend doesn't parse (missed data)
- Price/amount as float in one stack, int in the other
- Timestamp handling differences (Firestore Timestamp vs ISO string vs epoch)
- Null vs empty string vs missing field handling differences

## Output Format
For each finding:
```
## [CRITICAL/HIGH/MEDIUM/LOW] — Brief title

**Frontend:** file:approximate_line — what it does
**Backend:** file:approximate_line — what it does
**Mismatch:** What's inconsistent
**Impact:** What breaks for the user
**Fix:** Which side to change and how
```

Sort by severity (CRITICAL first). Be specific — quote actual field names and values.
"""


def main():
    print(f"🔍 Starting {WORKFLOW_NAME} Audit...")
    print(f"   Bundling {len(CROSS_STACK_FILES)} files...")
    
    project_text = bundle_targeted_files(CROSS_STACK_FILES)
    
    print(f"   Sending to model for analysis...\n")
    report = run_streaming_audit(PROMPT, project_text, temperature=0.2, max_tokens=12000)
    
    save_report(report, "cross_stack", WORKFLOW_NAME)
    print(f"\n✅ {WORKFLOW_NAME} audit complete!")


if __name__ == "__main__":
    main()
