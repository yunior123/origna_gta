---
name: adversarial-logic-architect
description: Mastermind logic for predicting and mitigating malicious behavior, race conditions, and system-wide edge cases (Magnus Carlsen approach).
---

# Adversarial Logic Architect Skill

## Instructions

1.  **50+ Adversarial Scenarios**:
    - For every new feature, predict 5+ ways a user or bot could abuse it.
    - Examples: `price_tampering`, `stock_race_condition`, `seller_self_purchase`, `unauthorized_refund`, `mfa_bypass`, `fcm_token_spoofing`.

2.  **Logic-First Architecture (Magnus Carlsen)**:
    - Think 5-10 steps ahead. If the seller does X, and the buyer does Y, and Stripe does Z, what is the final state?
    - Use `@firestore.transactional` for all state-dependent writes.
    - Use idempotency keys for all transactional requests.

3.  **No Trusting the Client**:
    - Assume EVERY value from the Flutter app is malicious or incorrect.
    - Re-fetch `price`, `stock`, `status`, and `uid` from Firestore during Backend processing.

4.  **Security Rules as a Shield**:
    - Use `rules_version = '2';`.
    - Validate every field's type, size, and presence.
    - Prevent changing immutable fields (e.g., `ownerId`, `orderId`) during updates.

5.  **Role-Based Auditing**:
    - Verify that `isAdmin()`, `isSeller()`, and `isOwner()` are checked in BOTH rules and handlers.

6.  **Concurrency Management**:
    - Identify potential race conditions (e.g., two buyers buying the last item simultaneously).
    - Use atomic increments (`firestore.Increment(1)`) for stock/metrics.

## Checklist
- [ ] 5+ adversarial scenarios documented for this feature.
- [ ] No values trusted from the client (re-fetched from DB).
- [ ] All state-dependent writes are inside transactions.
- [ ] Idempotency keys used for all external API calls (Stripe, etc.).
- [ ] Security rules protect immutable fields during updates.
- [ ] Rate limits exist for all user-facing endpoints.

## Rationale
- High-scale systems attract malicious actors.
- "Logic-First" prevents bugs that traditional tests might miss.
- Bulletproof architecture is the only way to reach 100M+ users safely.
