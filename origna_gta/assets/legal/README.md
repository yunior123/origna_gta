# OrignaGTA Legal Documents — Canadian Launch Package

**Created:** March 18, 2026  
**Status:** P0 BLOCKING — Ready for Legal Review  
**Jurisdiction:** Canada (Primary), Quebec (Secondary)  
**Company:** OrignaVentures Inc. (OrignaGTA)

---

## Document Index

### 1. **privacy-policy.md** (498 lines)
**Scope:** PIPEDA-compliant privacy policy  
**Key Topics:**
- What personal data is collected (account, address, payment via Stripe, browsing, usage)
- How data is used (service delivery, compliance, marketing, fraud prevention)
- Third-party sharing (Stripe, Cloudflare, Postal, self-hosted GlitchTip)
- Data retention (7 years for tax, 90 days for logs)
- PIPEDA rights (access, correction, deletion, complaint)
- Breach notification procedures
- Cross-border transfers (US-based service providers)
- Cookies (Cloudflare Turnstile, session cookies)
- **Bilingual:** Full French translation included

**Action Items:**
- [ ] Review with qualified Canadian privacy lawyer
- [ ] Ensure alignment with any provincial privacy laws (Quebec: Law 25)
- [ ] Deploy to `/privacy-policy.html` and `/privacy-policy-fr.html`
- [ ] Link from footer on all pages
- [ ] Update last modified date before launch

---

### 2. **terms-of-service.md** (569 lines)
**Scope:** Marketplace Terms — buyer and seller obligations  
**Key Topics:**
- Marketplace model clarification (OrignaGTA ≠ seller; seller is independent contractor)
- Platform fee (5% of subtotal)
- Stripe payment processing (OrignaGTA absorbs fees)
- User accounts and prohibited uses
- Product listings and prohibited items (weapons, counterfeit, unsafe)
- Seller verification requirements
- Purchasing and order confirmation process
- Payment and refund policy (30-day returns)
- Shipping and delivery timelines
- Seller indemnification (seller responsible for product quality, safety, legality)
- Liability limitations (OrignaGTA not liable for product defects)
- Dispute resolution (Quebec courts, Quebec law)
- Termination conditions
- CASL anti-spam compliance
- **Bilingual:** Full French translation included

**Action Items:**
- [ ] Review with business law attorney (marketplace liability focus)
- [ ] Ensure "seller of record" language clearly distinguishes OrignaGTA from product liability
- [ ] Verify limitation of liability clause aligns with Quebec consumer law
- [ ] Deploy to `/terms-of-service.html` and `/conditions-utilisation.html`
- [ ] Require explicit acceptance at account signup
- [ ] Display French version first for Quebec users

---

### 3. **casl-compliance.md** (367 lines)
**Scope:** Canadian Anti-Spam Legislation compliance  
**Key Topics:**
- Express consent requirement (opt-in, unchecked checkbox)
- Implied consent exception (2-year purchase window, 6-month inquiry window)
- Consent documentation (consentTimestamp, consentSource stored in DB)
- Unsubscribe mechanism (one-click, 10-day processing required)
- Transactional emails (order confirmations exempt from CASL)
- Marketplace seller marketing (seller responsible for own CASL compliance)
- Penalties ($1M individual / $10M organization per violation)
- Audit and compliance monitoring (monthly email audit)
- Postal vendor compliance requirements
- Training requirements for staff

**Action Items:**
- [ ] Update user registration form to add **unchecked** marketing opt-in checkbox
- [ ] Add unsubscribe link to **all** promotional emails (footer template provided)
- [ ] Store `consentTimestamp`, `consentSource` for every opt-in user (SurrealDB schema)
- [ ] Set up monthly CASL audit process (query transactional vs. promotional emails)
- [ ] Train marketing and support teams on CASL rules (annual requirement)
- [ ] Verify Postal contract includes CASL compliance obligations

---

### 4. **bill96-compliance.md** (322 lines)
**Scope:** Quebec Law 96 (French Language) requirements  
**Key Topics:**
- French language accessibility requirements (≥June 1, 2025 effective)
- Website and app localization checklist
- Legal document translation (Privacy Policy, ToS in French first)
- Product descriptions in French (seller requirement for Quebec listings)
- Customer support in French (24-hour response)
- Trademark/product name generic descriptors in French
- Prominence parity (French text same size/visibility as English)
- Auto-translation option for seller listings
- OQLF enforcement risk and penalties ($7,000 per violation)
- **Bilingual:** Full French translation included

**Action Items:**
- [ ] Audit current UI localization (`en.json` / `fr.json`) for completeness
- [ ] Translate Privacy Policy + ToS professionally (budget $800–1200)
- [ ] Integrate Google Translate API for seller product auto-translation (budget $1000 dev)
- [ ] Add "Available in Quebec?" toggle to seller listing form
- [ ] Require or auto-translate French descriptions for Quebec listings
- [ ] Implement French-first presentation of legal documents
- [ ] Set up monthly OQLF compliance audit (French content coverage %)
- [ ] Contact OQLF Aide aux Entreprises for guidance (free service)

---

### 5. **shipping-policy.md** (437 lines)
**Scope:** Shipping, delivery, and fulfillment standards  
**Key Topics:**
- Geographic coverage (Canada-wide; seller-configurable)
- Shipping timeline (3 business days seller processing; 3–10 days standard delivery)
- Shipping rates (seller-set; no OrignaGTA mark-up)
- Free shipping threshold ($75 CAD subtotal)
- Tracking requirements (all orders must include tracking number)
- Perishable item handling (expedited shipping, insulation, 24–48h delivery)
- Non-delivery and damage claims (14-day reporting window)
- Return shipping policy (seller pays for defective items)
- Customs and cross-province restrictions
- **Bilingual:** Full French translation included

**Action Items:**
- [ ] Implement shipping cost calculation at checkout (based on seller's rates)
- [ ] Display tracking links from Canada Post, UPS, FedEx in customer dashboard
- [ ] Create seller guidelines for perishable items (expedited shipping requirements)
- [ ] Establish claim process for lost/damaged orders (14-day window)
- [ ] Monitor seller compliance with 3-day shipping timeline (dashboard metric)
- [ ] Document carrier partner integrations (Canada Post API, UPS, FedEx)

---

### 6. **seller-fee-structure.md** (430 lines)
**Scope:** Transparent fee breakdown and payout schedule  
**Key Topics:**
- 5% platform commission on subtotal (product price only)
- Stripe processing fees absorbed by OrignaGTA (included in 5%)
- Tax handling (OrignaGTA collects and remits GST/HST/PST to CRA)
- Shipping cost handling (seller-set, not subject to commission)
- Payout schedule (2–5 business days after delivery via Stripe Connect)
- Complete revenue breakdown example ($100 product → $92 net after all fees)
- No additional fees (no monthly subscription, no listing fee, no withdrawal fee)
- Premium subscription (future; optional)
- Refund and chargeback policy
- Tax documentation (monthly T5A equivalent for CRA reporting)
- Seller dashboard reporting (real-time sales, commission, payout history)

**Action Items:**
- [ ] Create seller dashboard displaying commission, payout, tax breakdown
- [ ] Implement Stripe Connect payout integration (daily batch processing)
- [ ] Document seller onboarding flow for Stripe Connect account linking
- [ ] Set up monthly tax remittance process to CRA (GST/HST/PST)
- [ ] Create seller-facing payout forecasting tool ("earn $X by delivery date")
- [ ] Implement chargeback monitoring (flag if seller exceeds 1% rate)
- [ ] Build monthly T5A equivalent statement generator for seller tax filing

---

## Compliance Checklist (By Date)

### Pre-Launch (This Week — March 18–25, 2026)
- [ ] Legal review (privacy lawyer + business lawyer): 2 days
- [ ] Incorporate feedback and revisions: 2 days
- [ ] Finalize translations and review for Quebec compliance: 1 day
- [ ] Deploy documents to website and link from all pages: 1 day

### At Launch (March 25–April 1, 2026)
- [ ] Require all users to accept ToS at signup
- [ ] Display Privacy Policy + CASL consent prominently
- [ ] Ensure French versions available alongside English
- [ ] Activate CASL email consent flow (separate from ToS)
- [ ] Begin seller onboarding with Bill 96 notification

### 30 Days Post-Launch (April 18–25, 2026)
- [ ] First CASL audit (all emails sent must have documented consent)
- [ ] First OQLF compliance audit (French content coverage %)
- [ ] First shipping timeline audit (% of sellers shipping within 3 days)
- [ ] Review any legal inquiries or Privacy Commissioner questions

### Ongoing (Monthly)
- [ ] CASL compliance audit (marketing consent, unsubscribe processing)
- [ ] OQLF audit (French accessibility, product descriptions)
- [ ] Shipping performance monitoring (% on-time shipments)
- [ ] Privacy breach review (incident log, zero reported breaches ideally)
- [ ] Fee structure transparency (seller dashboard accuracy)

---

## Risk Mitigation

### High-Risk Areas Addressed

| Risk | Mitigation |
|------|-----------|
| **PIPEDA breach** | Clear consent, retention limits, breach notification SOP, encryption |
| **CASL violation** | Express opt-in (unchecked), unsubscribe within 10 days, audit trail |
| **Quebec law non-compliance** | French versions, auto-translation, seller guidance, OQLF contact |
| **Seller liability** | Clear "seller of record" language, indemnification clause, liability limits |
| **Payment fraud** | Stripe signature verification, idempotency keys, chargeback monitoring |
| **Tax remittance failure** | Centralized CRA remittance, monthly reconciliation, seller documentation |

### Legal Review Recommendations

Before launch, engage:

1. **Canadian Privacy Lawyer** (PIPEDA/provincial)
   - Review Privacy Policy for completeness
   - Ensure breach notification procedures align with OPC guidance
   - Verify cross-border data transfer clauses

2. **Quebec Business Lawyer** (Bill 96 + consumer law)
   - Ensure ToS complies with Quebec consumer protection law
   - Verify French version legal parity
   - Review seller agreement for Quebec jurisdiction

3. **E-Commerce/Marketplace Lawyer**
   - Marketplace liability allocation (seller vs. platform)
   - Third-party product liability indemnification
   - Return/refund policy enforceability

4. **Tax Accountant** (CRA compliance)
   - GST/HST registration and remittance process
   - Marketplace facilitator reporting rules (Form GST-44)
   - Seller T5A issuance requirements

---

## Implementation Roadmap

| Phase | Timeline | Tasks |
|-------|----------|-------|
| **Phase 1: Foundation** | Week 1–2 | Legal review, revisions, French translations finalized |
| **Phase 2: System Integration** | Week 3–4 | Deploy documents, CASL consent flow, tax remittance automation |
| **Phase 3: Seller Onboarding** | Week 4–5 | Seller dashboard, Stripe Connect integration, fee transparency |
| **Phase 4: Monitoring** | Week 5+ | Monthly audits, incident response, updates |

---

## Document Version History

| Version | Date | Changes |
|---------|------|---------|
| **1.0** | March 18, 2026 | Initial creation; 6 core documents |
| *[TBD]* | *[Date]* | Updates post-legal review |

---

## Contact and Escalation

**For Legal Questions:**
- **Email:** legal@orignagta.ca
- **Privacy/PIPEDA:** privacy@orignagta.ca
- **Compliance/Bill 96:** compliance@orignagta.ca
- **OQLF (Quebec):** courrier@oqlf.gouv.qc.ca / 1-800-363-2555

---

## Disclaimer

**These are template documents** created for OrignaGTA's Canadian launch. They reflect current best practices as of March 2026 and general legal principles. **Before deployment:**

1. **Engage a qualified Canadian lawyer** to review for compliance with your specific jurisdiction and operations
2. **Consult with a tax accountant** for GST/HST/PST remittance procedures
3. **Review with an IT security professional** for encryption and data protection implementation
4. **Contact the OQLF** for specific guidance on French language compliance for your marketplace

These documents do not constitute legal advice and are not binding without review and approval by your legal counsel and execution by authorized signatories.

---

**Created by:** OrignaGTA Legal + Compliance Team  
**Last Updated:** March 18, 2026  
**Status:** DRAFT — Awaiting Legal Review
