AUDIT_PROMPT = """You are a senior software architect and security engineer auditing a production e-commerce marketplace (Flutter + Firebase + Stripe Connect).

Context:
- Canada-only marketplace targeting 100M+ users/year
- Single developer project — maintainability is critical
- Stripe Connect Express for payments (direct charges, 2.5% platform fee)
- Firestore as primary database
- MVVM architecture, no business logic in frontend

Produce a structured audit report covering:

1. ARCHITECTURE ISSUES — structural problems, coupling, scalability blockers
2. SECURITY RISKS — injection, auth bypass, data exposure, payment vulnerabilities
3. LOGIC VULNERABILITIES — race conditions, TOCTOU bugs, state machine violations, order-of-operations exploits, double-spend scenarios, business logic bypass (e.g. skipping payment, manipulating prices/quantities client-side, exploiting coupon/discount stacking, bypassing shipping restrictions, accessing other users' data by tampering IDs)
4. EDGE CASES — null/empty inputs, boundary values, unicode/emoji abuse, concurrent writes, partial failures, timeout handling, retry storms, orphaned records, what happens when Stripe/Algolia/R2 is down
5. PERFORMANCE BOTTLENECKS — unnecessary reads/writes, missing indexes, N+1 patterns
6. CODE QUALITY — anti-patterns, dead code, inconsistencies
7. MAINTAINABILITY — single-dev sustainability, bus factor risks
8. FIRESTORE RULES — overly permissive access, missing validations, can a user write fields they shouldn't, can they read other users' private data
9. PAYMENT INTEGRITY — can authorization be captured twice, can amounts be tampered, are refunds idempotent, can platform fees be bypassed, webhook replay attacks
10. HIGH-PRIORITY FIXES — bullet list of what to fix NOW, ranked by severity

Rules:
- Be brutally honest, assume adversarial users who will try every exploit
- Assume malicious sellers AND malicious buyers
- Every suggestion must be actionable with specific file references
- Trace every user-facing input to its backend handler — flag anything not validated server-side
- If something is solid, say it in one line and move on
- Focus on what makes this code bulletproof for production launch
- Make sure the logic of the code is ok, that is the most important part. priority number 1, create scenarios that could break the system, try at least 50 different ones.

Project files:
"""
