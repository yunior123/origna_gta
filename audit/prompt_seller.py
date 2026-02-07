SELLER_AUDIT_PROMPT = """You are a senior software architect auditing the SELLER ONBOARDING & MANAGEMENT system of a production e-commerce marketplace (Flutter + Firebase + Stripe Connect).

Context:
- Canada-only marketplace targeting 100M+ users/year
- Sellers onboard via Stripe Connect Express (KYC handled by Stripe)
- Seller approval requires: onboardingCompleted + chargesEnabled + payoutsEnabled + !suspended
- Sellers manage products, view orders, track payouts
- Admin can suspend/unsuspend sellers, view all seller data
- Firestore rules enforce seller permissions per collection

You are auditing ONLY the seller flow: registration → Stripe onboarding → KYC verification → product creation permissions → order management → payout tracking → suspension.

Produce a structured audit report covering:

1. ONBOARDING SECURITY — Can a user become a seller without completing Stripe onboarding? Can they bypass KYC? What if onboarding webhook fails — is user stuck? Can they create products before approval?

2. STRIPE CONNECT ACCOUNT — Account link generation: can it be replayed? Dashboard link: is it user-scoped? What if Stripe account is disabled externally — is it reflected in Firestore?

3. SELLER PERMISSIONS — Can a seller access other sellers' data? Products, orders, payouts? Are Firestore rules strict per-seller? Can a seller modify their own role/approval status?

4. PRODUCT MANAGEMENT — Can a suspended seller still create/edit products? Is isActive enforced when seller suspended? Can a seller transfer product ownership (change sellerId)?

5. PAYOUT TRACKING — Can a seller see other sellers' payout amounts? Are payout records immutable? Can a seller dispute a payout amount? What if payout record creation fails after Stripe transfer?

6. ADMIN OPERATIONS — MFA required for sensitive operations? Can admin operations be replayed? Audit logging for all admin actions? Can a non-admin call admin endpoints?

7. SELLER SUSPENSION FLOW — When suspended: are products deactivated? Are pending orders affected? Are in-flight payouts stopped? Can a suspended seller still access the dashboard?

8. FIRESTORE RULES FOR SELLERS — users collection: what can a seller write? Can they escalate roles? Can they modify stripeAccountId? Are sensitive fields (suspended, roles, onboardingCompleted) protected?

9. EDGE CASES — Seller deletes Stripe account externally? Multiple Stripe accounts for same seller? Seller in non-Canadian province? Concurrent onboarding from multiple devices?

10. HIGH-PRIORITY FIXES — Ranked by severity, with specific file references.

Rules:
- Assume a malicious user trying to: become a seller without KYC, create products without approval, access other sellers' data, bypass suspension
- Focus on privilege escalation and data isolation
- Create at least 50 seller attack/edge scenarios
- If something is correctly implemented, say it in one line

Project files:
"""
