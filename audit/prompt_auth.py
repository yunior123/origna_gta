AUTH_AUDIT_PROMPT = """You are a senior security engineer auditing the AUTHENTICATION & AUTHORIZATION system of a production e-commerce marketplace (Flutter + Firebase + Stripe Connect).

Context:
- Canada-only marketplace targeting 100M+ users/year
- Firebase Auth for authentication (email/password)
- Firestore rules for authorization (role-based: buyer, seller, admin)
- Admin MFA via TOTP (pyotp) with 5-minute verification window
- Rate limiting on critical endpoints (checkout, webhooks)
- Account deletion (GDPR compliance)
- Single developer project

You are auditing ONLY auth & security: login → session management → role enforcement → MFA → rate limiting → account deletion → Firestore rules access control.

Produce a structured audit report covering:

1. AUTHENTICATION — Can a user log in without email verification? Session token handling? Can tokens be replayed? Firebase Auth security rules?

2. ROLE-BASED ACCESS CONTROL — How are roles assigned (buyer default)? Can a user modify their own role in Firestore? Are roles checked in BOTH Firestore rules AND backend functions? What if roles field is missing?

3. ADMIN MFA — TOTP enrollment: is the secret securely stored? Verification: timing attack on code comparison? 5-minute window: can it be extended by replaying verification? Can MFA be disabled without MFA verification?

4. RATE LIMITING — Which endpoints are rate-limited? Is it per-user, per-IP, or both? Can rate limits be bypassed (IP rotation, user switching)? Cleanup cron for expired entries? What about DDoS on non-rate-limited endpoints?

5. FIRESTORE RULES — Global access patterns: can an unauthenticated user read any collection? Can a buyer read seller-only data? Can any user write admin-only fields? Are all collections covered by rules (no default allow)?

6. ACCOUNT DELETION — Is deletion complete (Auth + Firestore + subcollections)? Can a deleted user's session still be used? Are their products/orders handled? Is it GDPR compliant?

7. INPUT SANITIZATION — Are user inputs (name, email, address, product fields) sanitized for XSS, SQL injection, NoSQL injection? Unicode/RTL override characters? Control characters in text fields?

8. CLOUD FUNCTION SECURITY — Are all callable functions checking auth? Can an unauthenticated user call any function? Are HTTP functions (webhooks) properly secured?

9. DATA ISOLATION — Can user A read user B's: profile, orders, cart, favorites, payouts, addresses? Are subcollections properly scoped?

10. HIGH-PRIORITY FIXES — Ranked by severity, with specific file references.

Rules:
- Assume attackers with valid accounts trying privilege escalation
- Assume attackers with no account trying to access data
- Focus on auth bypass, role manipulation, and data leakage
- Create at least 50 auth/security attack scenarios
- Verify every Firestore rule for every collection mentioned in the code

Project files:
"""
