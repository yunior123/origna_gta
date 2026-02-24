# STATE.md

All audit issues from the 2025 session have been fixed and committed. See git log for details.

## Suggestions for future sessions
- Add `import_supplier_product` Cloud Function (maps supplier images to R2, enforces sellerSku dedup, sellerId == auth.uid)
- Add `helpfulVoterIds` subcollection migration (replace unbounded array with review_votes/{userId} subcollection for scale)
- Add `FUNCTION_OPTIONS` with `timeout_sec=120` for payment handlers
- Add Geoapify address proxy Cloud Function (currently API key is in client JS bundle)
- Move all supplier/inventory UI state out of addproduct_screen.dart into AddProductState/ViewModel (BONUS MVVM)
