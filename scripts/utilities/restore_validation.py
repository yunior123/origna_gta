
import os

FILE_PATH = 'functions/handlers/payment_stripe.py'

with open(FILE_PATH, 'r') as f:
    lines = f.readlines()

validation_block = [
    "
",
    "    # --- SERVER-SIDE PRODUCT VALIDATION ---
",
    "    # F-01:Authoritative price check. Never trust client-supplied prices.
",
    "    # F-02:Atomic stock check (implemented in transaction below).
",
    "    validated_items = []
",
    "    actual_subtotal_cents = 0
",
    "    sellers = set()
",
    "    
",
    "    # Batch fetch all products for efficiency (Max 30 items per cart)
",
    "    product_ids = [item.get(Fields.PRODUCT_ID) for item in items if item.get(Fields.PRODUCT_ID)]
",
    "    if not product_ids: raise https_fn.HttpsError('invalid-argument', 'No valid product IDs')
",
    "    
",
    "    product_docs = {d.id: d.to_dict() for d in get_db().get_all([get_db().collection(Collections.PRODUCTS).document(pid) for pid in product_ids]) if d.exists}
",
    "    
",
    "    # Batch fetch all seller profiles
",
    "    seller_ids = list({p.get(Fields.SELLER_ID) for p in product_docs.values() if p.get(Fields.SELLER_ID)})
",
    "    seller_docs = {d.id: d.to_dict() for d in get_db().get_all([get_db().collection(Collections.USERS).document(sid) for sid in seller_ids]) if d.exists}
",
    "    
",
    "    for item in items:
",
    "        pid = item.get(Fields.PRODUCT_ID)
",
    "        p_data = product_docs.get(pid)
",
    "        if not p_data: raise https_fn.HttpsError('not-found', f'Product {pid} not found')
",
    "        
",
    "        # Security: check if seller is active
",
    "        sid = p_data.get(Fields.SELLER_ID)
",
    "        s_data = seller_docs.get(sid) or {}
",
    "        if s_data.get(Fields.SUSPENDED, False): raise https_fn.HttpsError('failed-precondition', f'Seller for {p_data.get(Fields.NAME)} is currently inactive')
",
    "        
",
    "        # Authoritative price lookup
",
    "        price_cents = round(p_data.get(Fields.PRICE, 0) * 100)
",
    "        qty = int(item.get(Fields.QUANTITY, 1))
",
    "        actual_subtotal_cents += price_cents * qty
",
    "        sellers.add(sid)
",
    "        
",
    "        # Merge client info with authoritative server data
",
    "        validated_item = {
",
    "            **item,
",
    "            Fields.PRICE: p_data.get(Fields.PRICE),
",
    "            Fields.NAME: p_data.get(Fields.NAME),
",
    "            Fields.IMAGE_URLS: p_data.get(Fields.IMAGE_URLS, []),
",
    "            Fields.SELLER_ID: sid,
",
    "            Fields.IS_DIGITAL: p_data.get(Fields.IS_DIGITAL, False),
",
    "            Fields.IS_SMALL_SUPPLIER: s_data.get(Fields.IS_SMALL_SUPPLIER, False)
",
    "        }
",
    "        validated_items.append(validated_item)
",
    "
",
    "    # Tolerance check: 1% subtotal drift allowed for rounding variances
",
    "    if abs(actual_subtotal_cents - client_subtotal_cents) > (actual_subtotal_cents * 0.01):
",
    "        raise https_fn.HttpsError('invalid-argument', f'Cart total mismatch. Expected ${actual_subtotal_cents/100:.2f}')
"
]

target_line = "    # Recompute all_digital from server-verified validated_items — never trust client payload
"
for i, line in enumerate(lines):
    if line == target_line:
        final_lines = lines[:i] + validation_block + lines[i:]
        with open(FILE_PATH, 'w') as f:
            f.writelines(final_lines)
        print(f"Successfully restored validation block at line {i}")
        break
else:
    print("FAILED to find insertion point")
