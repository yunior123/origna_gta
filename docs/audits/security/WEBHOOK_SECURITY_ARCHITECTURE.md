# 🔒 Architecture de Sécurité des Webhooks

## 🔄 Flux de Validation (Ordre Optimisé)

```
┌─────────────────────────────────────────────────────────────────┐
│                     WEBHOOK REQUEST REÇUE                        │
│              (Stripe ou Airwallex POST request)                  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌───────────────────────────────────────────────────────────────────┐
│  1️⃣  RATE LIMITING (PREMIER FILTRE)                              │
│                                                                   │
│  ✓ Extraction IP: X-Forwarded-For → client_ip                   │
│  ✓ Check: max 100 req/min par IP                                │
│  ✓ fail_closed=True (bloque en cas d'erreur)                    │
│                                                                   │
│  Collection: rate_limits/{action}_{ip}                           │
│  Atomique: Firestore transaction                                 │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
        ✅ AUTORISÉ            ❌ RATE LIMIT DÉPASSÉ
                │                       │
                │                       └──► HTTP 429 Too Many Requests
                │                            "Rate limit exceeded"
                │                            🔚 FIN (économie ressources)
                │
                ▼
┌───────────────────────────────────────────────────────────────────┐
│  2️⃣  SIGNATURE VERIFICATION (AUTHENTIFICATION)                    │
│                                                                   │
│  STRIPE:                                                          │
│  ✓ Header: Stripe-Signature                                      │
│  ✓ Method: stripe.Webhook.construct_event()                      │
│  ✓ Secret: STRIPE_WEBHOOK_SECRET                                 │
│  ✓ Algorithm: HMAC-SHA256 (timing-safe)                          │
│                                                                   │
│  AIRWALLEX:                                                       │
│  ✓ Header: X-Signature                                           │
│  ✓ Method: airwallex_service.verify_webhook_signature()          │
│  ✓ Secret: AIRWALLEX_WEBHOOK_SECRET                              │
│  ✓ Algorithm: HMAC-SHA256 (hmac.compare_digest)                  │
│  ✓ Support: hex + base64 encoding                                │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
        ✅ SIGNATURE VALIDE    ❌ SIGNATURE INVALIDE
                │                       │
                │                       └──► HTTP 400 Bad Request
                │                            "Invalid signature"
                │                            🔚 FIN (protection spoofing)
                │
                ▼
┌───────────────────────────────────────────────────────────────────┐
│  3️⃣  JSON PARSING (VALIDATION FORMAT)                             │
│                                                                   │
│  ✓ Parsing: json.loads(payload)                                  │
│  ✓ Seulement APRÈS signature verification                        │
│  ✓ Protection contre injection attacks                           │
│                                                                   │
│  Extraction:                                                      │
│  - event_id: Identifiant unique                                  │
│  - event_type: Type d'événement                                  │
│  - data: Payload métier                                          │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
         ✅ JSON VALIDE         ❌ JSON INVALIDE
                │                       │
                │                       └──► HTTP 400 Bad Request
                │                            "Invalid JSON"
                │                            🔚 FIN
                │
                ▼
┌───────────────────────────────────────────────────────────────────┐
│  4️⃣  IDEMPOTENCY CHECK (DÉDUPLICATION)                            │
│                                                                   │
│  Collection: webhook_events                                       │
│  Document ID: event_id (garantit unicité)                        │
│                                                                   │
│  ✓ Query: webhook_events/{event_id}.get()                        │
│  ✓ Check: document.exists ?                                      │
│                                                                   │
│  Si nouveau:                                                      │
│  ✓ Log event avec audit trail                                    │
│  ✓ Timestamp + client_ip + event_type                            │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
        ✅ NOUVEAU EVENT       ❌ DÉJÀ TRAITÉ
                │                       │
                │                       └──► HTTP 200 OK
                │                            "Already processed"
                │                            🔚 FIN (idempotence)
                │
                ▼
┌───────────────────────────────────────────────────────────────────┐
│  5️⃣  BUSINESS LOGIC (TRAITEMENT)                                  │
│                                                                   │
│  STRIPE EVENTS:                                                   │
│  ├─ checkout.session.completed → Update order (authorized)       │
│  ├─ payment_intent.succeeded → Confirm payment                   │
│  ├─ charge.refunded → Process refund                             │
│  ├─ charge.dispute.created → Alert fraud team                    │
│  └─ ... (12+ event types)                                        │
│                                                                   │
│  AIRWALLEX EVENTS:                                                │
│  ├─ payment_intent.succeeded → Update order (authorized)         │
│  ├─ payment_intent.failed → Cancel order                         │
│  ├─ payout.succeeded → Update seller balance                     │
│  └─ ... (8+ event types)                                         │
│                                                                   │
│  Firestore Updates:                                               │
│  ✓ orders/{order_id} → orderStatus, paymentStatus                │
│  ✓ users/{seller_id} → balance (payouts)                         │
│  ✓ Email notifications → customer + seller                       │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
          ✅ SUCCÈS              ❌ ERREUR TRAITEMENT
                │                       │
                │                       ├──► Log: type(e).__name__ uniquement
                │                       ├──► Response: "Internal processing error"
                │                       └──► HTTP 500 Internal Server Error
                │                            🔚 FIN (sanitized)
                │
                ▼
┌───────────────────────────────────────────────────────────────────┐
│                    ✅ HTTP 200 OK                                 │
│                      "Success"                                    │
│                                                                   │
│  Audit Log Complété:                                              │
│  ✓ webhook_events/{event_id}                                     │
│  ✓ Timestamp, IP, event_type                                     │
│  ✓ Order ID (si applicable)                                      │
└───────────────────────────────────────────────────────────────────┘
```

---

## 🛡️ Couches de Protection

```
╔════════════════════════════════════════════════════════════════╗
║                   PROTECTION MULTICOUCHE                        ║
╚════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────┐
│  COUCHE 1: RATE LIMITING (DDoS Protection)                  │
│  🚫 Bloque: 100+ req/min par IP                             │
│  💰 Économie: Évite traitement coûteux                       │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  COUCHE 2: SIGNATURE (Authentication)                       │
│  🔐 Bloque: Webhooks sans signature valide                  │
│  🛡️ Protège: Contre spoofing & man-in-the-middle           │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  COUCHE 3: IDEMPOTENCY (Deduplication)                      │
│  🔄 Bloque: Webhooks en double (replay attacks)             │
│  📊 Garantit: Traitement unique par event_id                │
└─────────────────────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────┐
│  COUCHE 4: SANITIZATION (Information Protection)            │
│  🕵️ Bloque: Fuite de données sensibles                      │
│  📝 Logs: Types d'erreur uniquement, pas de détails         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Collection Firestore: webhook_events

```javascript
// Document ID = event_id (garantit unicité)
webhook_events/{event_id}
{
  "provider": "stripe" | "airwallex",
  "type": "checkout.session.completed",
  "processed": true,
  "timestamp": Timestamp(2026-02-03T14:30:00Z),
  "client_ip": "192.168.1.1",      // Audit trail
  "event_id": "evt_1abc123...",    // Stripe/Airwallex event ID
  "order_id": "order_xyz"          // Optionnel (pour Stripe)
}

// Index recommandés:
// - provider + timestamp (queries par provider)
// - type + timestamp (queries par event type)
// - client_ip + timestamp (analyse d'attaques)
```

---

## 🧪 Scénarios de Test

### ✅ Scénario 1: Webhook Légitime

```
REQUEST:
POST /stripe-webhook
Headers:
  Stripe-Signature: t=1675436400,v1=abc123...
Body:
  {"id": "evt_new", "type": "checkout.session.completed", ...}

FLOW:
1. Rate Limiting  → ✅ 15/100 req utilisées → AUTORISÉ
2. Signature      → ✅ HMAC-SHA256 valide → AUTORISÉ
3. JSON Parsing   → ✅ JSON valide → event_id=evt_new
4. Idempotency    → ✅ Nouveau event → LOG créé
5. Business Logic → ✅ Order updated → Order #123 confirmed

RESPONSE:
HTTP 200 OK
"Success"
```

---

### ❌ Scénario 2: Webhook Frauduleux (Signature Invalide)

```
REQUEST:
POST /airwallex-webhook
Headers:
  X-Signature: fake_signature_12345
Body:
  {"id": "evt_fraud", "name": "payment_intent.succeeded", ...}

FLOW:
1. Rate Limiting  → ✅ 5/100 req utilisées → AUTORISÉ
2. Signature      → ❌ HMAC mismatch → BLOQUÉ
                     Log: "⚠️ Invalid signature from IP: 192.168.1..."

RESPONSE:
HTTP 400 Bad Request
"Invalid signature"

🔒 ATTAQUE BLOQUÉE: Webhook frauduleux rejeté AVANT traitement
```

---

### ❌ Scénario 3: Attaque DDoS

```
REQUEST: (101 requêtes en 1 minute)
POST /stripe-webhook (x101)
Headers:
  Stripe-Signature: valid_sig
Body:
  {"id": "evt_1", "type": "...", ...}

FLOW:
Requêtes 1-100:
1. Rate Limiting  → ✅ AUTORISÉ
2-5. Processing   → ✅ Traité normalement

Requête 101:
1. Rate Limiting  → ❌ 101/100 → BLOQUÉ
                     Log: "⚠️ Rate limit exceeded for IP: 192.168.1..."

RESPONSE (requête 101):
HTTP 429 Too Many Requests
"Rate limit exceeded"

🔒 ATTAQUE BLOQUÉE: DDoS stoppé à 100 req/min
💰 ÉCONOMIE: Requêtes 101+ ne consomment pas de ressources
```

---

### 🔄 Scénario 4: Replay Attack (Idempotency)

```
REQUEST 1:
POST /airwallex-webhook
Headers:
  X-Signature: valid_sig
Body:
  {"id": "evt_duplicate", "name": "payment_intent.succeeded", ...}

FLOW:
1-2. Rate + Sig   → ✅ AUTORISÉ
3. Parsing        → ✅ event_id=evt_duplicate
4. Idempotency    → ✅ Nouveau → LOG créé
5. Business Logic → ✅ Order #456 confirmed

RESPONSE:
HTTP 200 OK
"Success"

---

REQUEST 2 (REPLAY - même event_id):
POST /airwallex-webhook
Headers:
  X-Signature: valid_sig
Body:
  {"id": "evt_duplicate", "name": "payment_intent.succeeded", ...}

FLOW:
1-2. Rate + Sig   → ✅ AUTORISÉ
3. Parsing        → ✅ event_id=evt_duplicate
4. Idempotency    → ❌ EXISTE DÉJÀ → BLOQUÉ
                     Log: "✓ Already processed: payment_intent.succeeded"

RESPONSE:
HTTP 200 OK
"Already processed"

🔒 ATTAQUE BLOQUÉE: Replay attack détecté et ignoré
✅ SÉCURITÉ: Order #456 PAS modifié deux fois
```

---

## 🔐 Cryptographie

### Stripe Signature Verification

```
SIGNATURE FORMAT:
Stripe-Signature: t=1675436400,v1=abc123def456...

ALGORITHM:
1. Extract timestamp (t) and signature (v1)
2. Construct signed_payload = "t.payload"
3. Compute HMAC-SHA256:
   expected_sig = HMAC(STRIPE_WEBHOOK_SECRET, signed_payload)
4. Compare (timing-safe):
   hmac.compare_digest(expected_sig, v1)

PROTECTION:
✓ Timing-safe comparison (pas de timing attacks)
✓ Timestamp validation (reject old events)
✓ Multiple signatures (graceful key rotation)
```

### Airwallex Signature Verification

```
SIGNATURE FORMAT:
X-Signature: abc123def456... (hex ou base64)

ALGORITHM:
1. Get raw payload bytes
2. Compute HMAC-SHA256:
   expected_digest = HMAC(AIRWALLEX_WEBHOOK_SECRET, payload)
3. Normalize signature (strip prefix, lowercase)
4. Compare (timing-safe):
   IF hex (64 chars):
     hmac.compare_digest(expected_digest.hex(), signature)
   ELSE base64:
     hmac.compare_digest(expected_digest, base64.decode(signature))

PROTECTION:
✓ Timing-safe comparison (hmac.compare_digest)
✓ Support multiple encodings (hex + base64)
✓ Raw bytes handling (no encoding ambiguity)
```

---

## 📈 Métriques de Monitoring

### Métriques à Surveiller

```
1. RATE LIMITING
   ├─ webhook.rate_limit.hits (counter)
   ├─ webhook.rate_limit.blocks (counter)
   └─ Alerte: blocks > 100/heure → Possible attaque

2. SIGNATURE VERIFICATION
   ├─ webhook.signature.invalid (counter)
   ├─ webhook.signature.valid (counter)
   └─ Alerte: invalid > 5% du total → Investigation requise

3. IDEMPOTENCY
   ├─ webhook.duplicate.detected (counter)
   ├─ webhook.unique.processed (counter)
   └─ Alerte: duplicates > 10% → Retry logic à vérifier

4. LATENCY
   ├─ webhook.processing.duration (histogram)
   ├─ P50, P95, P99 latencies
   └─ Alerte: P95 > 1000ms → Performance dégradée

5. ERRORS
   ├─ webhook.error.{type} (counter par type)
   ├─ webhook.error.total (counter)
   └─ Alerte: error_rate > 5% → Incident
```

---

## 🚨 Réponse aux Incidents

### Détection d'Attaque

```
SIGNES D'ATTAQUE:
1. Rate limiting hits > 1000/min
2. Signature invalides > 100/min
3. IP unique avec 100% rejets

ACTION:
1. Bloquer IP au niveau Cloud Armor
2. Notifier équipe sécurité (PagerDuty)
3. Analyser logs webhook_events
4. Vérifier intégrité des commandes
```

### Signature Compromise

```
SI STRIPE_WEBHOOK_SECRET OU AIRWALLEX_WEBHOOK_SECRET COMPROMIS:

1. IMMÉDIAT (< 5 min):
   - Régénérer secret dans Stripe/Airwallex dashboard
   - Mettre à jour Firebase Functions config
   - Redéployer functions

2. COURT TERME (< 1 heure):
   - Analyser logs des dernières 24h
   - Identifier webhooks suspects
   - Vérifier intégrité des ordres affectés

3. POST-MORTEM (< 24 heures):
   - Root cause analysis
   - Plan d'amélioration
   - Rotation automatique future
```

---

*Architecture documentée le 3 février 2026*
