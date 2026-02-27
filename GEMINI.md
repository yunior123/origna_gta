# GEMINI.md

## 🎯 PROJECT VISION: OrignaGta
OrignaGta is a next-generation e-commerce marketplace specialized for the Canadian market (Quebec-first compliance) with worldwide sellers. The goal is to scale to 100M+ users within the first year.

**Launch Date:** March 2026.
**Motto:** Logic First, Action over Discussion, Fix Silently.

## 🛠 TECH STACK & INFRASTRUCTURE
- **Frontend:** Flutter (Mobile/Web) with **MVVM + Riverpod** (Non-negotiable).
- **Backend:** Python Google Cloud Functions with **Pydantic** for schema enforcement.
- **Database:** Firestore (NoSQL) with strict security rules.
- **Search:** Algolia (Product discovery).
- **Payments:** Stripe Connect Express (Worldwide payouts, Canadian tax compliance).
- **Media:** Cloudflare R2 (CDN for images/assets).
- **Observability:** Sentry + Google Cloud Logging.

## 📐 ARCHITECTURAL MANDATES
- **MVVM Architecture:** UI Screens must contain ZERO logic. All logic resides in ViewModels/Providers.
- **Idempotency:** All financial transfers, stock updates, and order status transitions must be idempotent.
- **Eventually Consistent:** Optimize for speed by minimizing synchronous database operations where background tasks suffice.
- **Canada-First Enforcement:** Strict location-based enforcement for buyers (Canadian addresses only for now).
- **Security-First:** 50+ adversarial scenarios considered for every feature. Protect against malicious sellers, buyers, and race conditions.

## 🚦 OPERATIONAL RULES
All technical and procedural rules are defined in [CLAUDE.md](./CLAUDE.md). 
**CLAUDE.md is the absolute source of truth.**

### Core Principles Summary (from CLAUDE.md):
- **Chain of Verification:** Multi-step reasoning and self-correction.
- **Research → Strategy → Execution → Verification:** The mandatory GSD lifecycle.
- **No Legacy Code:** We fix forward; backward compatibility is not handled as the DB is currently empty.
- **Bilingual (EN/FR):** Quebec Law 25 and Bill 96 compliance is mandatory for all UI and user-facing communications.
- **Logic Over Magic:** No magic strings, no hardcoded values. Everything synced across stacks via `schema_constants`.

---
*For a dense overview of the codebase, refer to `llms.txt` and `llms-full.txt`.*
