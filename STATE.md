# STATE.md

All audit issues and STATE.md suggestions have been fixed and committed. See git log for details.

## Deferred for future sessions
- Add `import_supplier_product` Cloud Function (maps supplier images to R2, enforces sellerSku dedup, sellerId == auth.uid)
- Move all supplier/inventory UI state out of addproduct_screen.dart into AddProductState/ViewModel (BONUS MVVM — large refactor)
