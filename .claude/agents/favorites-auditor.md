---
name: favorites-auditor
description: Audits favorites/wishlist — add/remove idempotency, cross-session persistence, product deletion cleanup, performance, and UI feedback.
tools: Read, Grep, Glob, Bash, Write, Edit
model: sonnet
memory: project
---

# Favorites / Wishlist Auditor

## Mission
Audit the favorites (wishlist) feature to ensure it persists correctly across sessions, handles edge cases (deleted products, out-of-stock), performs efficiently, and provides clear UI feedback.

## Audit Scope
- `lib/screens/favorites/` — favorites list screen
- `lib/providers/` — favorites provider
- `lib/viewmodels/` — favorites ViewModel
- `lib/services/` — favorites service (OrignaBase API)
- `lib/screens/` — product card and product detail (heart/favorite button)

## Rules / Checks

### Add / Remove Idempotency
- [ ] Adding a product already in favorites does not create duplicates
- [ ] Removing a product not in favorites does not cause error
- [ ] Toggle is idempotent: tapping heart twice returns to original state
- [ ] Server-side: `RELATE` or upsert pattern — not blind insert

### Cross-Session Persistence
- [ ] Favorites stored in OrignaBase `user_favorites` collection (not local storage)
- [ ] Authenticated users: favorites loaded from server on app start
- [ ] Unauthenticated users: favorites stored locally and synced on login
- [ ] After login sync: local favorites merged with server favorites (union, not replace)

### Product Deletion Cleanup
- [ ] If a product is deleted/deactivated, it no longer shows as active in favorites list
- [ ] Deleted products shown with "No longer available" state in favorites list — not silently removed
- [ ] Option to remove unavailable products from favorites with one tap
- [ ] Favorites count badge does not count unavailable products

### Performance
- [ ] Favorites list uses `ListView.builder` — never `ListView(children: [])`
- [ ] Product details in favorites loaded with single batch API call — not N+1
- [ ] Favorites count badge does not re-fetch full list on every screen load — uses cached count
- [ ] Adding/removing favorite uses optimistic UI update (immediate heart toggle) with server confirmation

### UI Feedback
- [ ] Heart icon shows filled state when product is favorited — unfilled when not
- [ ] Tap on heart shows brief animation (scale/bounce)
- [ ] Loading state during add/remove — prevent double-tap during API call
- [ ] Error state: if add/remove fails, heart reverts to previous state + shows error snackbar
- [ ] Empty favorites state: clear message + CTA to browse products

### Out-of-Stock Handling
- [ ] Out-of-stock products shown in favorites with clear badge
- [ ] "Add to Cart" button disabled for out-of-stock items in favorites list
- [ ] "Back in Stock" notification option available from favorites for out-of-stock items

### Share / Export
- [ ] If share wishlist feature exists: shared link shows only public product info — not user PII
- [ ] Shared wishlist link expires or is revocable

## Output Format
- **CRITICAL**: Duplicate favorites creation, favorites not persisted server-side for auth users, N+1 query
- **WARNING**: No cleanup for deleted products, no optimistic UI, missing empty state
- **OK**: Check passed
