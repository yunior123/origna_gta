# 🤖 Agent & Subagent Guide

## When to Use Subagents (ALWAYS for auditing)
Use subagents to keep the main context clean. They run in separate context windows and return only summaries.

| Task | Agent | Invocation |
|------|-------|------------|
| Before ANY code change | `logic-auditor` | "Use the logic-auditor to verify [workflow] before I change it" |
| After changing frontend ↔ backend | `cross-stack-auditor` | "Use the cross-stack-auditor to verify checkout flow" |
| After changing payment code | `payment-auditor` | "Use the payment-auditor to audit the payment pipeline" |
| After changing schema/models | `schema-sync-checker` | "Use the schema-sync-checker to verify schema sync" |
| After changing order status logic | `order-lifecycle-auditor` | "Use the order-lifecycle-auditor to trace state transitions" |

## Best Practices (from Anthropic docs)
1. **Isolate high-volume reads** — Subagents read 10-15 files without cluttering main context
2. **Chain agents** — First audit with `logic-auditor`, then fix bugs, then re-audit to verify
3. **Run parallel research** — "Use subagents to investigate auth, payments, and orders in parallel"
4. **Always delegate investigation** — "Use a subagent to investigate how [feature] works"
5. **Resume subagents** — If an audit was interrupted, say "Continue that audit" to resume with full context
6. **Agents have persistent memory** — They remember patterns, bugs, and architectural decisions across sessions
7. **Foreground for interactive work, background for auditing** — Run audits in background with Ctrl+B

## Mandatory Agent Usage Rules
- **RULE: Before editing 3+ files → run `logic-auditor` on that workflow FIRST**
- **RULE: After editing payment files → run `payment-auditor` IMMEDIATELY**
- **RULE: After editing schema_constants → run `schema-sync-checker` IMMEDIATELY**
- **RULE: After editing order handler → run `order-lifecycle-auditor` IMMEDIATELY**
- **RULE: Audit results with 0 CRITICAL findings → proceed. Any CRITICAL → fix before committing**

## Slash Commands for Auditing
- `/audit-workflow [name]` — Run full logic audit on a workflow
- `/check-schema-sync` — Verify all 6 schema layers are in sync
- `/cross-stack-check` — Compare all frontend ↔ backend file pairs

---

## 📚 Workflow-Indexed File Reading (RAG Chunking)

**CRITICAL: Never edit a file in isolation. Always read the FULL file group for that workflow first.**

### Step 1: Identify the Workflow
Consult `docs/WORKFLOW_INDEX.md` to find which workflow the change belongs to.

### Step 2: Read ALL Files in the Group (Chunked)
Read files in this order — frontend first, then backend, then schema, then tests:

**Example: Checkout workflow → read these 12 files BEFORE making any change:**
```
CHUNK 1 (Frontend): checkout_screen.dart, checkout_provider.dart, cart_provider.dart
CHUNK 2 (Backend): payment_stripe.py, orders.py, shipping_service.py
CHUNK 3 (Schema): schema_constants.py, schema_constants.dart, database_schema.json
CHUNK 4 (Tests): test_payment_stripe.py, test_shipping_service.py, checkout e2e
```

### Step 3: Cross-Reference Before Editing
- Compare Dart field names with Python field names
- Compare Dart enums with Python enums
- Compare request payloads with handler expectations
- Compare error handling (what frontend expects vs what backend returns)

### Step 4: After Editing, Re-Read Impacted Files
If you changed `payment_stripe.py`, re-read `checkout_provider.dart` to verify the interface still matches.

### Workflow Quick-Index
| Workflow | Key Files to Read Together |
|----------|--------------------------|
| Checkout | `checkout_provider.dart`, `payment_stripe.py`, `shipping_service.py`, `schema_constants.*` |
| Orders | `seller_orders_viewmodel.dart`, `buyer_orders_viewmodel.dart`, `orders.py`, `cron_jobs.py`, `order_models.*` |
| Products | `add_product_viewmodel.dart`, `products.py`, `product_models.*`, `schema_constants.*` |
| Auth | `auth_provider.dart`, `admin.py`, `user_models.*`, `firestore.rules` |
| Payments | `checkout_provider.dart`, `payment_stripe.py`, `orders.py`, `cron_jobs.py` |
| Schema | ALL `schema_constants.*`, ALL `models/*`, `database_schema.json`, `firestore.rules` |

---

## 🔄 Session Management (Context Hygiene)

- `/clear` between unrelated tasks — don't pollute context
- `/compact Focus on [current workflow]` when context is getting full
- `/rewind` if Claude goes off track — cheaper than correcting
- After 2 failed corrections → `/clear` and start fresh with a better prompt
- Context fills fast with file reads. Delegate investigation to subagents to preserve main context
- Use `--continue` to resume sessions across terminal restarts
- Use `/pause-work` before ending a session to save state
- Use `/resume-work` to pick up where you left off
