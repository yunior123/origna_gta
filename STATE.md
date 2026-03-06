# STATE.md — Session Progress


- [ ] Supplier field names consistent across stacks: PARTIAL — Python/Dart code consistent; JSON schema was stale (now fixed)


### Key Fix Patterns Discovered
- Flutter `Semantics(label:)` renders as **text content** in `flt-semantics` nodes, NOT `aria-label` — use `filter({ hasText: })` instead of `[aria-label=]` selectors
- `toFirestoreFields()` needs `new Date()` objects (not ISO strings) to produce `timestampValue` for Firestore rules validation
- `categoryId` comes as string from client callables — cast with `int()` before MAP lookup
- `history.pushState` does NOT trigger Flutter Web's internal router — use `page.goto()` instead
