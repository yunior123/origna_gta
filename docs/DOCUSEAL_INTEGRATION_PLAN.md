# DocuSeal Integration Plan — OrignaGTA

**Date**: 2026-05-02
**Status**: Research & Design (no implementation yet)
**Author**: Claude (Tech Lead)

---

## 1. Executive Summary

DocuSeal is an open-source document signing platform (MIT license) that provides legally-binding e-signatures via REST API and embedded web components. This plan covers integrating DocuSeal into OrignaGTA for seller agreements, vendor contracts, refund policies, and terms of service acceptance — replacing the current static text approach with auditable, signed documents.

**Recommendation**: Self-host DocuSeal on the existing VPS (204.168.137.16) using Docker. Cost: $0 (open-source). No per-signature fees. Full data control.

---

## 2. DocuSeal Research Summary

### 2.1 What Is DocuSeal

- Open-source document signing platform (GitHub: `docusealco/docuseal`)
- Ruby on Rails application, PostgreSQL or SQLite backend
- REST API + webhooks + embedded JavaScript SDK
- Multi-party signing workflows, audit trails, template management
- Self-hostable via Docker Compose

### 2.2 Pricing

| Option | Cost | Limits | Notes |
|--------|------|--------|-------|
| **Self-hosted OSS** | $0 | Unlimited docs/signatures | Own SMTP required, no branding |
| **Self-hosted Pro** | $20/user/mo | Unlimited | White-label, SSO, webhooks monitoring |
| **Cloud Basic** | $0 | 10 emails/mo | Too limited for production |
| **Cloud Pro** | $20/user/mo | Unlimited | Hosted by DocuSeal |

**Recommendation**: Self-hosted OSS ($0). Configure SMTP via existing Postal/email setup. No per-signature API fees.

### 2.3 API Overview

**Authentication**: API token sent as `X-Auth-Token: <API_KEY>` and stored in macOS Keychain as `docuseal-api-key`.

**Core Endpoints**:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| `GET` | `/api/templates` | List all templates |
| `POST` | `/api/templates` | Create template (PDF/DOCX upload or HTML) |
| `GET` | `/api/templates/:id` | Get template details |
| `PUT` | `/api/templates/:id` | Update template |
| `DELETE` | `/api/templates/:id` | Delete template |
| `POST` | `/api/submissions` | Create submission (send for signing) |
| `GET` | `/api/submissions` | List submissions |
| `GET` | `/api/submissions/:id` | Get submission details |
| `GET` | `/api/submitters` | List submitters |
| `PUT` | `/api/submitters/:id` | Update submitter (pre-fill values) |
| `GET` | `/api/submission_documents/:id` | Download signed PDF |
| `POST` | `/api/pdf` | Generate PDF from submission |

**Webhook Events**:

| Event | Trigger |
|-------|---------|
| `submission.completed` | All signers have signed |
| `submission.declined` | A signer declined |
| `submission.viewed` | Signer opened the document |
| `submission.started` | Signer began filling fields |

**Webhook Payload** (key fields):
```json
{
  "event_type": "submission.completed",
  "submission": {
    "id": 123,
    "template_id": 456,
    "status": "completed",
    "completed_at": "2026-05-02T14:30:00Z",
    "submitters": [
      {
        "id": 789,
        "email": "seller@example.com",
        "name": "John Doe",
        "status": "completed",
        "completed_at": "2026-05-02T14:30:00Z"
      }
    ]
  }
}
```

### 2.4 Embedded Signing

DocuSeal provides a `<docuseal-form>` JavaScript web component for inline embedding:

```html
<script src="https://cdn.docuseal.com/js/form.js"></script>
<docuseal-form
  data-src="https://docuseal.example.com/d/{{ template_slug }}"
  data-email="signer@example.com"
  data-completed-redirect-url="https://app.example.com/signing/done">
</docuseal-form>
```

**Events**: `init`, `load`, `completed`, `declined`

**Key attributes**:
- `data-language` — UI language (en, fr, es)
- `data-with-decline` — show decline button
- `data-custom-css` — custom styling
- `data-completed-redirect-url` — redirect after signing
- `data-values` — pre-fill fields as JSON

### 2.5 Self-Hosting Requirements

```yaml
# docker-compose.yml (DocuSeal)
services:
  docuseal:
    image: docuseal/docuseal:latest
    ports:
      - "3100:3000"  # Internal port, Caddy reverse-proxies
    environment:
      - DATABASE_URL=REDACTED_SECRET/docuseal
      - SMTP_ADDRESS=smtp.postal.email.com
      - SMTP_PORT=587
      - SMTP_USERNAME=support@orignagta.ca
      - SMTP_PASSWORD=<from-vault>
      - SMTP_FROM=noreply@orignagta.ca
      - HOST=https://signatures.orignagta.ca
    depends_on:
      - docuseal-db
  docuseal-db:
    image: postgres:16-alpine
    environment:
      - POSTGRES_DB=docuseal
      - POSTGRES_USER=docuseal
      - POSTGRES_PASSWORD=<generated>
    volumes:
      - docuseal_data:/var/lib/postgresql/data
volumes:
  docuseal_data:
```

---

## 3. Documents Requiring Signing

### 3.1 Seller Onboarding Documents

| Document | Template | Signers | When |
|----------|----------|---------|------|
| **Seller Agreement** | `seller_agreement_v1` | Seller (individual or business rep) | During seller registration |
| **Marketplace Terms** | `marketplace_terms_v1` | Seller | During seller registration |
| **Commission & Payout Terms** | `commission_terms_v1` | Seller | During seller registration |
| **Product Listing Policy** | `product_listing_policy_v1` | Seller | During seller registration |
| **Return/Refund Policy Acknowledgment** | `refund_policy_ack_v1` | Seller | During seller registration |

### 3.2 Buyer Documents

| Document | Template | Signers | When |
|----------|----------|---------|------|
| **Terms of Service Acceptance** | `tos_acceptance_v1` | Buyer | Account registration (currently static text) |
| **High-Value Order Agreement** | `high_value_order_v1` | Buyer | Orders > $500 CAD |
| **Subscription Terms** | `subscription_terms_v1` | Buyer | Premium subscription purchase |

### 3.3 Operational Documents

| Document | Template | Signers | When |
|----------|----------|---------|------|
| **Seller Cancellation Reason** | `seller_cancel_ack_v1` | Seller | Seller-initiated order cancellation |
| **Return Authorization** | `return_auth_v1` | Buyer + Seller | Return request approval |
| **Vendor Contract (Custom)** | `vendor_contract_{seller_id}` | Seller + OrignaGTA admin | Special arrangements |

### 3.4 Document Lifecycle

```
Template created (admin) → Submission created (API) → Signer notified (email)
    → Signer opens & signs → Webhook fires → OrignaBase updates record
    → Signed PDF stored in R2 → Audit trail preserved
```

---

## 4. Backend Integration (OrignaBase Rust)

### 4.1 New Crate: `ob-docuseal`

Add a new workspace crate for DocuSeal API client logic.

```
orignabase/crates/ob-docuseal/
├── Cargo.toml
└── src/
    ├── lib.rs          — Public API, re-exports
    ├── client.rs       — DocuSeal HTTP client (reqwest + `X-Auth-Token` auth)
    ├── templates.rs    — Template CRUD (create, list, update, delete)
    ├── submissions.rs  — Submission management (create, list, get PDF)
    ├── webhooks.rs     — Webhook signature verification + event processing
    ├── models.rs       — Rust structs for DocuSeal API types
    └── config.rs       — DocuSeal configuration (URL, API key, webhook secret)
```

**Dependencies**: `reqwest`, `serde`, `serde_json`, `hmac`, `sha2`, `tokio`

### 4.2 Configuration

Add to `orignabase.toml`:

```toml
[docuseal]
enabled = true
base_url = "https://signatures.orignagta.ca"
api_key = ""  # Loaded from env: OB_DOCUSEAL__API_KEY
webhook_secret = ""  # Loaded from env: OB_DOCUSEAL__WEBHOOK_SECRET
timeout_seconds = 30
```

Environment variables:
- `OB_DOCUSEAL__API_KEY` — DocuSeal API key (secret, in VPS `.env`)
- `OB_DOCUSEAL__WEBHOOK_SECRET` — Webhook HMAC secret (secret, in VPS `.env`)
- `OB_DOCUSEAL__BASE_URL` — DocuSeal instance URL

### 4.3 New PostgreSQL Tables

#### `document_templates`
```sql
CREATE TABLE document_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    docuseal_template_id INTEGER NOT NULL,  -- DocuSeal's template ID
    name VARCHAR(255) NOT NULL,             -- Human-readable name
    slug VARCHAR(100) NOT NULL UNIQUE,      -- e.g., 'seller_agreement_v1'
    category VARCHAR(50) NOT NULL,          -- 'seller_onboarding', 'buyer', 'operational'
    version INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    required_roles TEXT[] NOT NULL,          -- ['seller'], ['buyer'], ['admin', 'seller']
    signers_config JSONB NOT NULL,          -- [{role, email_field, name_field}]
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

#### `document_submissions`
```sql
CREATE TABLE document_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES document_templates(id),
    docuseal_submission_id INTEGER,         -- DocuSeal's submission ID
    user_id UUID NOT NULL,                  -- Who triggered the signing
    order_id UUID,                          -- Associated order (nullable)
    seller_profile_id UUID,                 -- Associated seller profile (nullable)
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    -- Status: 'pending', 'sent', 'viewed', 'started', 'completed', 'declined', 'expired'
    signer_email VARCHAR(255) NOT NULL,
    signer_name VARCHAR(255),
    signing_url TEXT,                       -- DocuSeal signing URL
    signed_pdf_url TEXT,                    -- R2 URL of signed PDF
    completed_at TIMESTAMPTZ,
    declined_at TIMESTAMPTZ,
    decline_reason TEXT,
    metadata JSONB DEFAULT '{}',            -- Pre-filled values, custom data
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_doc_submissions_user ON document_submissions(user_id);
CREATE INDEX idx_doc_submissions_order ON document_submissions(order_id);
CREATE INDEX idx_doc_submissions_seller ON document_submissions(seller_profile_id);
CREATE INDEX idx_doc_submissions_status ON document_submissions(status);
```

#### `document_audit_log`
```sql
CREATE TABLE document_audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_id UUID NOT NULL REFERENCES document_submissions(id),
    event_type VARCHAR(50) NOT NULL,        -- 'created', 'sent', 'viewed', 'signed', 'declined', 'completed'
    actor_email VARCHAR(255),
    actor_ip VARCHAR(45),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 4.4 New API Endpoints

Add to `ob-handlers` crate:

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `POST` | `/signatures/templates/sync` | Sync templates from DocuSeal | Admin |
| `GET` | `/signatures/templates` | List active templates | Admin |
| `POST` | `/signatures/request` | Create signing request for a user | Admin/Seller |
| `GET` | `/signatures/submissions` | List submissions (filtered by user) | Authenticated |
| `GET` | `/signatures/submissions/:id` | Get submission details + signing URL | Authenticated |
| `GET` | `/signatures/submissions/:id/pdf` | Download signed PDF | Authenticated |
| `POST` | `/signatures/webhook` | DocuSeal webhook receiver (HMAC verified) | Webhook secret |
| `GET` | `/signatures/required/:role` | Get required unsigned documents for a role | Authenticated |

#### Key Endpoint Details

**`POST /signatures/request`** — Create signing request:
```json
{
  "template_slug": "seller_agreement_v1",
  "user_id": "uuid",
  "signer_email": "seller@example.com",
  "signer_name": "John Doe",
  "order_id": "uuid",           // optional
  "seller_profile_id": "uuid",  // optional
  "prefill_values": {           // optional
    "business_name": "Maple Foods",
    "province": "ON"
  }
}
```

Response:
```json
{
  "submission_id": "uuid",
  "signing_url": "https://signatures.orignagta.ca/s/abc123",
  "status": "sent",
  "template_name": "Seller Agreement v1"
}
```

**`GET /signatures/required/:role`** — Check what a user still needs to sign:
```json
// GET /signatures/required/seller?user_id=uuid
{
  "required": [
    {
      "template_slug": "seller_agreement_v1",
      "template_name": "Seller Agreement",
      "submission_id": "uuid",
      "signing_url": "https://signatures.orignagta.ca/s/abc123",
      "status": "sent"
    }
  ],
  "all_signed": false
}
```

### 4.5 Webhook Processing

```rust
// crates/ob-docuseal/src/webhooks.rs
pub async fn handle_webhook(
    body: Bytes,
    signature: &str,
    secret: &str,
) -> Result<DocuSealWebhookEvent, WebhookError> {
    // 1. Verify HMAC signature (constant-time comparison)
    // 2. Parse event JSON
    // 3. Match event_type:
    //    - "submission.completed" → update status, store signed PDF in R2, log audit
    //    - "submission.declined" → update status, notify admin
    //    - "submission.viewed" → update status
    //    - "submission.started" → update status
    // 4. Update document_submissions record
    // 5. Write document_audit_log entry
    // 6. If completed: download PDF from DocuSeal, upload to R2, update signed_pdf_url
    // 7. If seller agreement completed: update seller_profiles.onboarding_complete = true
}
```

### 4.6 Signed PDF Storage

On `submission.completed`:
1. Download signed PDF from DocuSeal via `GET /api/submission_documents/:id`
2. Upload to Cloudflare R2 at `signatures/{user_id}/{submission_id}.pdf`
3. Update `document_submissions.signed_pdf_url` with R2 public URL
4. Signed PDFs are retained indefinitely for audit/legal purposes

### 4.7 Integration with Existing Flows

#### Seller Registration Flow (current)
```
Seller registers → Stripe Connect onboarding → Account active
```

#### Seller Registration Flow (with DocuSeal)
```
Seller registers → Sign required documents (seller agreement, terms, etc.)
    → All documents signed → Stripe Connect onboarding → Account active
```

Add check: `seller_profiles` get a new field `onboarding_documents_complete BOOLEAN DEFAULT false`.
Seller cannot list products or receive orders until all required documents are signed.

#### Buyer Registration Flow (with DocuSeal)
```
Buyer registers → Accept Terms of Service (signed document instead of static text)
    → Account active
```

#### Order Cancellation Flow
```
Seller cancels order → Sign cancellation acknowledgment → Order cancelled
```

---

## 5. Frontend Integration (Flutter)

### 5.1 Signing Flow Architecture

Two approaches, recommend **Approach B** for better UX:

**Approach A: WebView redirect**
- Open DocuSeal signing URL in a WebView
- Listen for redirect to `completed-redirect-url`
- Simple but leaves the app context

**Approach B: Embedded `<docuseal-form>` in Flutter Web (recommended)**
- Embed via `HtmlElementView` on web
- Use `dart:js_interop` to listen for `completed` event
- On mobile: open in-app browser (url_launcher) with deep link back
- Keeps user in-app on web, graceful fallback on mobile

### 5.2 New Files

```
origna_gta/lib/
├── features/signatures/
│   ├── signatures_provider.dart           — Riverpod providers
│   ├── signatures_viewmodel.dart          — Signing request state management
│   ├── signatures_repository.dart         — API calls to OrignaBase /signatures/*
│   └── models/
│       ├── document_template_model.dart   — Freezed model
│       ├── document_submission_model.dart — Freezed model
│       └── generated/                     — Freezed generated files
├── screens/
│   ├── signing_screen.dart                — Embedded signing view
│   ├── signing_complete_screen.dart       — Post-signing confirmation
│   └── signing_required_screen.dart       — Gate screen (must sign before proceeding)
└── widgets/
    └── signatures/
        ├── docuseal_form_widget.dart      — Embedded DocuSeal form (web)
        ├── signing_status_badge.dart      — Signed/Pending/Declined badge
        └── required_documents_list.dart   — List of documents to sign
```

### 5.3 Signing Screen (Web — Embedded)

```dart
// signing_screen.dart (web implementation)
class SigningScreen extends ConsumerStatefulWidget {
  final String submissionId;
  final String signingUrl;
  final String templateName;

  @override
  ConsumerState<SigningScreen> createState() => _SigningScreenState();
}

class _SigningScreenState extends ConsumerState<SigningScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: widget.templateName),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ResponsiveBreakpoints.contentMaxWidth),
          child: DocusealFormWidget(
            signingUrl: widget.signingUrl,
            onCompleted: () {
              // Update submission status via provider
              ref.read(signaturesProvider.notifier).markCompleted(widget.submissionId);
              context.go('/signing-complete');
            },
            onDeclined: () {
              ref.read(signaturesProvider.notifier).markDeclined(widget.submissionId);
              context.go('/signing-declined');
            },
          ),
        ),
      ),
    );
  }
}
```

### 5.4 Signing Gate Screen

For seller onboarding — blocks product listing until documents are signed:

```dart
// signing_required_screen.dart
class SigningRequiredScreen extends ConsumerWidget {
  final String role; // 'seller' or 'buyer'

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requiredDocs = ref.watch(requiredDocumentsProvider(role));

    return requiredDocs.when(
      data: (docs) {
        if (docs.allSigned) {
          // Navigate to actual destination
          return const SizedBox.shrink();
        }
        return Scaffold(
          body: Column(
            children: [
              Text('Before you can continue, please sign the following documents:'),
              Expanded(
                child: RequiredDocumentsList(
                  documents: docs.required,
                  onSign: (doc) => context.push('/sign/${doc.submissionId}'),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const ModernLoadingIndicator(),
      error: (e, _) => ErrorScreen(message: e.toString()),
    );
  }
}
```

### 5.5 Mobile Signing (In-App Browser)

On iOS/Android, use `url_launcher` to open the signing URL in an in-app browser:

```dart
// For mobile platforms
Future<void> _openSigningUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.inAppWebView);
    // After returning, poll for status update
    await _checkSubmissionStatus();
  }
}
```

### 5.6 Schema Constants Addition

Add to `schema_constants.dart`:

```dart
class SignatureEndpoints {
  static const templates = '/signatures/templates';
  static const request = '/signatures/request';
  static const submissions = '/signatures/submissions';
  static const required = '/signatures/required';
  static const webhook = '/signatures/webhook';
}

class DocumentStatus {
  static const pending = 'pending';
  static const sent = 'sent';
  static const viewed = 'viewed';
  static const started = 'started';
  static const completed = 'completed';
  static const declined = 'declined';
  static const expired = 'expired';
}
```

---

## 6. Deployment Architecture

### 6.1 VPS Layout (204.168.137.16)

```
/opt/orignabase/docker/
├── docker-compose.yml          # Existing: OrignaBase + PostgreSQL + Meilisearch + Caddy
└── docker-compose.docuseal.yml # New: DocuSeal + its PostgreSQL
```

### 6.2 Caddy Configuration

Add to Caddyfile:

```
signatures.dev.orignagta.ca {
    reverse_proxy docuseal:3000
}

signatures.orignagta.ca {
    reverse_proxy docuseal:3000
}
```

### 6.3 DNS

Add Cloudflare DNS records:
- `signatures.dev.orignagta.ca` → `204.168.137.16` (proxied)
- `signatures.staging.orignagta.ca` → `204.168.137.16` (proxied)
- `signatures.orignagta.ca` → `204.168.137.16` (proxied)

### 6.4 Resource Impact

DocuSeal is lightweight (Ruby app). Estimated additional resource usage:
- **RAM**: ~200-300MB (DocuSeal + its PostgreSQL)
- **Disk**: ~500MB (Docker images) + signed PDFs in R2
- **CPU**: Minimal (document signing is low-frequency)

Current VPS has adequate headroom for this addition.

---

## 7. Testing Strategy

### 7.1 Unit Tests (Rust)

```
crates/ob-docuseal/src/
├── client.rs       — Test HTTP client with mock server (wiremock)
├── templates.rs    — Test template CRUD parsing
├── submissions.rs  — Test submission creation, status mapping
├── webhooks.rs     — Test HMAC verification, event parsing, signature rejection
└── models.rs       — Test serialization/deserialization
```

### 7.2 Integration Tests (Rust)

```
crates/orignabase/tests/docuseal_integration_test.rs
— Test full flow: create template → create submission → simulate webhook → verify status update
— Requires running DocuSeal instance (gated with #[ignore])
```

### 7.3 Widget Tests (Flutter)

```
test/features/signatures/
├── signatures_provider_test.dart     — Provider state management
├── signatures_repository_test.dart   — API call mocking
└── signatures_viewmodel_test.dart    — Business logic
test/screens/
├── signing_screen_test.dart          — Screen rendering
└── signing_required_screen_test.dart — Gate behavior
test/widgets/signatures/
├── docuseal_form_widget_test.dart    — Embedded form
└── signing_status_badge_test.dart    — Badge states
```

### 7.4 E2E Tests

```
e2e/specs/phase7-signatures/
├── seller-onboarding-signing.spec.ts  — Seller signs agreement during registration
├── buyer-tos-signing.spec.ts          — Buyer signs ToS during account creation
├── signing-gate-blocks.spec.ts        — Unsigned seller cannot list products
├── webhook-completion.spec.ts         — Webhook updates status correctly
└── signed-pdf-download.spec.ts        — Signed PDF accessible after completion
```

### 7.5 Manual Testing Checklist

- [ ] DocuSeal instance accessible at `signatures.dev.orignagta.ca`
- [ ] SMTP sends signing emails correctly
- [ ] Template creation via API works
- [ ] Embedded signing form loads in Flutter web
- [ ] Signing completion triggers webhook
- [ ] Webhook updates database and stores PDF in R2
- [ ] Seller with all signed documents can list products
- [ ] Seller without signed documents is blocked from listing
- [ ] Mobile signing via in-app browser works
- [ ] Declined documents are handled gracefully
- [ ] Audit log captures all events

---

## 8. Implementation Phases

### Phase 1: Infrastructure (1-2 days)
- [x] Add DocuSeal Docker container definition to OrignaBase compose
- [x] Add dedicated DocuSeal PostgreSQL service and persistent volume
- [x] Configure Caddy reverse proxy for `signatures.*.orignagta.ca`
- [x] Allow DocuSeal CDN and signatures hosts in OrignaGTA web CSP
- [x] Configure SMTP (Postal/email) via DocuSeal SMTP env wiring in OrignaBase compose
- [x] Set up DNS records for `signatures` (proxied), `signatures.dev` (DNS-only), and `signatures.staging` (DNS-only)
- [x] Verify DocuSeal admin dashboard accessible at `https://signatures.orignagta.ca/setup`
- [x] Create API key in DocuSeal and save it to macOS Keychain as `docuseal-api-key`

### Phase 2: Backend Core (3-4 days)
- [ ] Create `ob-docuseal` crate (client, models, config)
- [ ] Create PostgreSQL tables (document_templates, document_submissions, document_audit_log)
- [ ] Implement template sync endpoint
- [ ] Implement submission creation endpoint
- [ ] Implement webhook receiver with HMAC verification
- [ ] Implement signed PDF download + R2 upload
- [ ] Implement required-documents check endpoint
- [ ] Add `ob-docuseal` to workspace Cargo.toml
- [ ] Wire routes into main server assembly

### Phase 3: Template Creation (1-2 days)
- [ ] Design seller agreement PDF template with form fields
- [ ] Design marketplace terms template
- [ ] Design commission terms template
- [ ] Design refund policy acknowledgment template
- [ ] Design buyer ToS acceptance template
- [ ] Upload all templates to DocuSeal via API
- [ ] Create seed data for document_templates table

### Phase 4: Frontend Core (3-4 days)
- [ ] Create `signatures_repository.dart` (API calls)
- [ ] Create `signatures_provider.dart` (Riverpod providers)
- [ ] Create freezed models (DocumentTemplate, DocumentSubmission)
- [ ] Create `signing_screen.dart` with embedded DocuSeal form (web)
- [ ] Create `signing_complete_screen.dart`
- [ ] Create `signing_required_screen.dart` (gate screen)
- [ ] Add signing route to GoRouter
- [ ] Add schema constants for signature endpoints
- [ ] Widget tests for all new screens

### Phase 5: Integration (2-3 days)
- [ ] Hook seller registration → require signed documents before Stripe Connect
- [ ] Hook buyer registration → require signed ToS
- [ ] Add `onboarding_documents_complete` to seller_profiles
- [ ] Add signing status badges to admin panel
- [ ] Add signed document viewer in admin panel
- [ ] Mobile fallback (in-app browser for signing)

### Phase 6: Testing & Polish (2-3 days)
- [ ] Unit tests for `ob-docuseal` crate
- [ ] Integration tests for webhook flow
- [ ] Widget tests for Flutter signing screens
- [ ] E2E tests for seller onboarding signing
- [ ] E2E tests for buyer ToS signing
- [ ] Security audit: webhook HMAC, PDF access control
- [ ] Performance test: signing flow latency

**Total estimated effort**: 12-18 days

---

## 9. Security Considerations

### 9.1 Webhook Security
- HMAC-SHA256 signature verification on every webhook (constant-time comparison)
- Reject webhooks older than 300 seconds (replay protection)
- Webhook secret stored in VPS `.env`, never in code
- Log all webhook events to `document_audit_log` for forensic review

### 9.2 Access Control
- Signed PDFs accessible only by: the signer, admins, and associated order parties
- Signing URLs are single-use tokens (DocuSeal handles expiry)
- Document templates can only be managed by admins
- Submission list filtered by `user_id` — users see only their own documents

### 9.3 Data Retention
- Signed PDFs stored in R2 indefinitely (legal requirement)
- Audit log entries are append-only, never deleted
- Template versioning preserves old templates even when updated
- User deletion must archive (not purge) signed documents for legal compliance

### 9.4 PII Handling
- Signer email/name passed to DocuSeal for signing — stored in DocuSeal's PostgreSQL
- DocuSeal instance is self-hosted — all data stays on VPS
- No PII in webhook logs (only submission IDs and status)
- Signed PDFs contain signer PII — access-controlled via R2 signed URLs if needed

---

## 10. Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| DocuSeal Ruby app adds RAM pressure on 8GB VPS | Medium | Monitor RAM; DocuSeal is lightweight (~200MB). If tight, use SQLite instead of separate PostgreSQL |
| SMTP delivery failures for signing emails | High | Use existing Postal config; add retry logic; show signing URL in-app as fallback |
| DocuSeal API downtime blocks seller onboarding | High | Cache templates locally; queue signing requests; allow admin manual override |
| Legal enforceability of e-signatures in Canada | Medium | DocuSeal supports PIPEDA-compliant signatures; consult legal for specific document types |
| Template changes break existing submissions | Low | Version templates (v1, v2); old submissions reference old template version |
| Mobile signing UX is degraded (in-app browser) | Medium | Prioritize web experience; consider Flutter native signing fields as future enhancement |

---

## 11. Future Enhancements

- **Bulk signing**: Send multiple documents as a single signing session (seller onboarding bundle)
- **Template builder**: Admin UI for creating document templates without uploading PDFs
- **AI field detection**: Auto-detect where signature/date fields should go in uploaded PDFs
- **Multi-language templates**: French and English versions of all legal documents
- **Signing reminders**: Automated email reminders for unsigned documents (cron job)
- **Digital certificates**: Trusted signing certificates for higher-assurance documents
- **Analytics**: Track signing completion rates, time-to-sign, decline reasons
- **Mobile native**: Custom Flutter signing widget (draw signature on canvas) instead of WebView

---

## 12. Sources

- DocuSeal official docs: https://www.docuseal.com/docs
- DocuSeal pricing: https://www.docuseal.com/pricing
- DocuSeal GitHub: https://github.com/docusealco/docuseal
- DocuSeal embedded docs: https://www.docuseal.com/docs/embedded/form
- DocuSeal API docs: https://www.docuseal.com/docs/api
- Canadian e-signature law (PIPEDA): https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/
