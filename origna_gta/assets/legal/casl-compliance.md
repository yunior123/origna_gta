# CASL Email Marketing Compliance Policy

**Effective Date:** March 18, 2026  
**Framework:** Canadian Anti-Spam Legislation (CASL) — R.S.C. 1985, c. E-1.6  
**Penalties:** Up to **CAD $1,000,000 per violation** (individuals) / **CAD $10,000,000 per violation** (organizations)

---

## 1. Overview

OrignaGTA complies fully with Canada's **Canadian Anti-Spam Legislation (CASL)**, which came into force January 1, 2014. This policy outlines how we:

- Collect and manage marketing consent
- Obtain and document express consent for promotional communications
- Provide functioning unsubscribe mechanisms
- Respond to unsubscribe requests
- Maintain compliance records

---

## 2. Consent Framework

### 2.1 Express Consent (Opt-In)

**Express consent** is the default requirement for sending commercial electronic messages (CEMs). Express consent is:

- **Written or electronic**
- **Informed:** The recipient knows they are consenting to receive CEMs from us
- **Unambiguous:** No pre-checked boxes; the user must actively opt in
- **Voluntary:** Not a condition of service; separate from account creation or ToS acceptance
- **Identifiable:** We clearly state who is requesting consent and for what purpose

**Express Consent Examples:**
- Checkbox: "Yes, send me promotional emails and offers from OrignaGTA"
- Verbal confirmation (recorded)
- Email reply confirming subscription to newsletters

**Invalid Consent (does NOT comply with CASL):**
- Pre-checked boxes
- Consent bundled with Terms of Service acceptance
- "I agree to receive emails" nested in a paragraph
- Silence or inaction (no consent)

### 2.2 Implied Consent (Narrow Exception)

Implied consent can arise from an **existing business relationship** only if:

1. **The recipient has made a purchase, lease, or contract within the past 2 years**, OR
2. **The recipient has submitted an inquiry or application within the past 6 months**, OR
3. **The recipient has published an email address in a context where the message is relevant to their published role or function**

**Important:** Implied consent is a **narrow exception** and should not be the primary basis for marketing. The CRTC recommends securing express consent whenever possible.

**Implied Consent Examples:**
- A buyer who purchased from OrignaGTA 10 months ago can receive promotional emails without express consent (2-year window)
- A person who requested a seller demo 3 months ago can receive OrignaGTA seller program emails (6-month window)
- A registered seller can receive operational updates about their seller account

**Implied Consent Does NOT Allow:**
- Emailing unrelated third parties because they have a business relationship with someone else
- Sending marketing to someone who unsubscribed (even if they once purchased)
- Reactivating old email addresses after CASL came into force (January 1, 2014)

---

## 3. Express Consent Collection

### 3.1 Consent Request Wording

When requesting express consent, OrignaGTA uses clear, standalone language:

#### Account Registration (Optional Checkbox)

```
☐ Yes, I would like to receive promotional emails, product recommendations, 
and special offers from OrignaGTA. I can change my preferences anytime.
```

**Key Elements:**
- Checkbox is **unchecked by default** (opt-in, not opt-out)
- Describes the type of messages (promotional, offers, recommendations)
- Mentions the ability to withdraw consent
- Separate from Terms of Service / Privacy Policy checkboxes

#### Standalone Subscription Signup (Email/Web Form)

```
Email Address: ___________________

☐ I want to subscribe to OrignaGTA's newsletters, product updates, and exclusive offers.

I understand I can unsubscribe anytime by clicking the link in any email.

[SUBSCRIBE BUTTON]
```

#### Post-Purchase Consent Request

```
Subject: Get exclusive deals and updates from OrignaGTA

Hi [Buyer Name],

We'd love to keep you updated on new products, sales, and seller highlights 
tailored to your interests.

☐ Yes, send me promotional emails from OrignaGTA.

You can change this preference anytime in your account settings or by 
clicking unsubscribe in any email.
```

### 3.2 Timing of Consent Request

- **At Registration:** Optional checkbox (unchecked by default)
- **Post-Purchase:** Email within 48 hours of order confirmation (optional opt-in)
- **Account Settings:** Always accessible; user can opt in or out anytime
- **Newsletter Signup Page:** Dedicated consent flow

### 3.3 Consent Documentation

For every user who opts in to marketing, OrignaGTA records:

| Field | Value | Example |
|-------|-------|---------|
| `userId` | Unique user ID | `users:abc123` |
| `email` | Subscriber email | `buyer@example.ca` |
| `consentType` | "EXPRESS" or "IMPLIED" | `EXPRESS` |
| `consentSource` | Where consent was collected | `registration_form`, `post_purchase_email` |
| `consentTimestamp` | When consent was collected | `2026-03-18T15:30:00Z` |
| `impliedBasisDate` | If implied: date of transaction/inquiry | `2025-09-10T08:00:00Z` |
| `consentVersion` | Version of consent text used | `v1.0` |
| `ipAddress` | IP of consent source (for audit) | `203.0.113.42` |

These records are stored in the `users` SurrealDB collection and are audit-logged.

---

## 4. Unsubscribe Mechanism

### 4.1 Unsubscribe Requirements

Every promotional email must include a **clear, easy-to-use, functioning unsubscribe mechanism**. CASL requires:

- **Conspicuous:** Visible, not hidden in fine print
- **Easy to Use:** No login required; one-click ideal
- **No Barriers:** Cannot require an account login or reason for unsubscribe
- **Fast:** Unsubscribe request must be honored within **10 business days**
- **Lasting:** Cannot re-subscribe the user without new express consent

### 4.2 Email Footer Template

Every promotional email sent by OrignaGTA includes this footer:

```
---

You're receiving this because you subscribed to OrignaGTA promotional emails.

[UNSUBSCRIBE] — Click here to stop receiving emails
[UPDATE PREFERENCES] — Manage which emails you receive
[PRIVACY POLICY] — See how we handle your information

© 2026 OrignaVentures Inc.
support@orignagta.ca
```

### 4.3 Unsubscribe Process

**One-Click Unsubscribe (Preferred):**
1. User clicks "UNSUBSCRIBE" link in email footer
2. Link contains tokenized unsubscribe URL: `orignagta.ca/unsub?token=xyz123`
3. OrignaGTA backend verifies token and immediately sets `marketingConsent: false`
4. User sees confirmation page: "You've been unsubscribed. You won't receive promotional emails from OrignaGTA."
5. **No confirmation email needed** (CASL allows silent unsubscribe)

**Preference Center (Secondary):**
1. User clicks "UPDATE PREFERENCES"
2. Opens account settings → Notifications
3. User can toggle:
   - ☐ Weekly newsletter
   - ☐ New seller arrivals
   - ☐ Product recommendations
   - ☐ Sales and offers
   - ☐ OrignaGTA news
4. Changes take effect immediately

### 4.4 Unsubscribe Compliance

- **Fulfillment Timeline:** Within **10 business days** of unsubscribe request
- **Proof of Fulfillment:** Logs stored in audit trail; query: `SELECT * FROM marketing_events WHERE type = 'unsubscribe' AND userId = ?`
- **No Re-subscription:** Unsubscribed users are not re-added to marketing lists without new express consent
- **No Selling:** Unsubscribed email addresses are not sold, shared, or transferred to third parties

---

## 5. Transactional Emails (Exempt from CASL)

The following emails are **transactional** and do not require express consent:

- Order confirmations
- Shipping notifications and tracking updates
- Delivery confirmations
- Refund confirmations
- Account creation and password reset
- Seller account status updates
- Account suspension or termination notices
- Payment receipt or invoice
- Return/refund request status updates

**Important:** Transactional emails must not include promotional content (e.g., "While we await your return, check out these trending products!"). If they do, they become commercial and must comply with CASL.

---

## 6. Third-Party Marketing (Marketplace Sellers)

### 6.1 Seller Responsibility

If a **third-party seller** sends direct emails to OrignaGTA users:

- The seller is the **sender of record** and must comply with CASL independently
- The seller must obtain express consent before sending promotional emails
- The seller must include their own unsubscribe mechanism
- OrignaGTA does not forward seller promotional emails on behalf of sellers

### 6.2 OrignaGTA-Mediated Communications

If OrignaGTA sends emails **on behalf of a seller** (e.g., "Message from [Seller Name]"):

- OrignaGTA is the **sender of record** and must comply with CASL
- OrignaGTA must obtain express consent before sending seller marketing
- OrignaGTA must include an unsubscribe mechanism that works for all such emails
- The buyer can opt out of seller messages separately from OrignaGTA marketing

---

## 7. Geographic and Jurisdictional Scope

### 7.1 Sending to Canadian Recipients

CASL applies to commercial electronic messages **sent to or from Canada**, regardless of sender location. OrignaGTA's compliance obligations apply to:

- All recipients with a `.ca` email domain
- All recipients located in Canada (inferred from account address or IP)
- All recipients who have a Canadian postal address or phone

### 7.2 Sending to Non-Canadian Recipients

OrignaGTA may send transactional emails to non-Canadian users without CASL consent (e.g., international order confirmations). Promotional emails to non-Canadian recipients should comply with the applicable jurisdiction's laws (e.g., CAN-SPAM in the US, GDPR in EU).

---

## 8. Penalties and Enforcement

### 8.1 Violation Penalties

**CASL violations are civil contraventions with severe penalties:**

| Violation Type | Individual | Organization |
|----------------|------------|--------------|
| **Private lawsuits** | Up to CAD $1,000,000 per violation | Up to CAD $10,000,000 per violation |
| **CRTC enforcement** | Up to CAD $1,000,000 per violation | Up to CAD $10,000,000 per violation |

A "violation" is typically **each commercial email sent in breach**, so a single campaign to 10,000 recipients can result in 10,000 violations.

### 8.2 Risk Areas

OrignaGTA prioritizes these high-risk areas:

1. **Pre-checked boxes:** Never. All consent is explicit opt-in.
2. **Implied consent abuse:** Strictly limit to valid 2-year/6-month windows.
3. **Unsubscribe delays:** Process within 10 days; monitor and audit.
4. **Misleading sender:** Always identify as "OrignaGTA" clearly.
5. **Bundled consent:** Marketing consent separate from ToS/privacy.

---

## 9. Audit and Compliance Monitoring

### 9.1 Monthly Audit

OrignaGTA conducts monthly audits of:

- **Consent Records:** Verify that all marketing emails have express consent (or valid implied consent) documented
- **Unsubscribe Processing:** Verify that all unsubscribe requests are processed within 10 days
- **Email Content:** Verify that promotional emails are labeled as such and include unsubscribe links
- **Transactional vs. Promotional:** Verify that transactional emails do not include promotional content

**Audit Query (SurrealDB):**
```sql
-- Check recent marketing emails sent without documented consent
SELECT 
  user:userId, 
  marketing_consents.consentTimestamp, 
  marketing_emails.sentAt 
FROM marketing_emails 
WHERE sentAt > marketing_consents.consentTimestamp 
  AND consentType != 'IMPLIED'
LIMIT 100;
```

### 9.2 Incident Response

If OrignaGTA discovers a CASL violation:

1. **Immediate Action:** Stop sending to affected recipients
2. **Investigation:** Identify root cause (e.g., system error, manual mistake)
3. **Notification:** Inform Privacy Officer and Legal within 24 hours
4. **Documentation:** Record incident in audit log with date, scope, corrective action
5. **CRTC Report (if required):** Report to CRTC if violation is material or pattern of violations

### 9.3 Vendor Compliance (Email Service Provider)

OrignaGTA uses **Mailjet** for email delivery. Mailjet is contractually required to:

- Provide bounce and unsubscribe reports daily
- Not re-send to unsubscribed addresses
- Honor CASL requirements in its service
- Provide audit logs upon request

---

## 10. Employee and Contractor Training

All OrignaGTA staff involved in marketing must complete CASL training, including:

- What constitutes express vs. implied consent
- Valid and invalid consent mechanisms
- Unsubscribe processes and timelines
- Consequences of violations
- Real-world examples and case studies

Training is conducted:
- **Annually** for all staff
- **Onboarding** for new hires
- **Ad hoc** when new marketing campaigns launch

---

## 11. Contact and Questions

For questions about this CASL Compliance Policy or to report concerns:

**OrignaGTA Privacy and Compliance**
- **Email:** privacy@orignagta.ca or compliance@orignagta.ca
- **Response Time:** Within 5 business days

**Canadian Radio-Television and Telecommunications Commission (CRTC) — CASL Enforcement**
- **Website:** https://crtc.gc.ca/eng/com500/
- **FAQ:** https://crtc.gc.ca/eng/com500/faq500.htm
- **Complaint Form:** https://crtc.gc.ca/eng/com/complain.htm

---

## 12. References

- **CASL Statute:** https://laws-lois.justice.gc.ca/eng/acts/e-1.6/
- **CASL Regulations (Consent):** https://laws-lois.justice.gc.ca/eng/regulations/SOR-2012-36/
- **CRTC Implementation Guidelines:** https://crtc.gc.ca/eng/com500/guide.htm
- **CRTC FAQ:** https://crtc.gc.ca/eng/com500/faq500.htm
- **OPC Consent Guidance:** https://www.priv.gc.ca/en/privacy-topics/collecting-personal-information/consent/gl_omc_201805/

---

**Last Updated:** March 18, 2026

**Disclaimer:** This is a policy template. Before using this policy in production, consult with a qualified Canadian lawyer specializing in CASL compliance to ensure it aligns with your specific operations and messaging.
