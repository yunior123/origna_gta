# Master TODO List - Origna Ecosystem

## Priority: Payment & Security
- [x] Fix payment endpoints (disable seller onboarding logic) for OrignaGTA/Ventures
- [x] Security enhancement: Switch to manual repo access for clients (no automated emails)
- [x] Backend isolation: OrignaGTA & OrignaVentures independent
- [ ] Test Stripe payments (E2E) in OrignaGTA/Ventures (Stripe/Klarna/Webhooks)
- [ ] Audit email delivery/cleanup test accounts (Postal)
- [ ] Audit all Stripe webhooks
- [ ] Increase security so source code exposure doesn't allow hacking

## Priority: Regional Support (Cuba)
- [x] Cuba Shipping — Havana maritime weight-based shipping (Flutter side)
- [x] Cuba address form — collects full address, validates Havana, maritime shipping notice
- [x] Cuba provinces in address form, country selector
- [x] es.json translations for Cuba shipping
- [ ] Cuba store support — full parity with Canada (backend Rust, address validation, etc.)
- [ ] Rust backend: Cuba shipping support

## Priority: Visual & Investor Audit
- [ ] 300+ Desktop screenshots (clear before generating, match real views, cover all states/variants)
- [ ] Audit screenshots vs views/widgets gaps
- [ ] PDF generation (include screenshots/new tiers, remove contract references)
- [ ] Improve/fix generated PDFs in OrignaVentures
- [ ] Contact form (OrignaVentures → support@orignaventures.ca via Hetzner backend)
- [ ] Audit all QR codes
- [ ] Audit PDF tiers are clickable
- [ ] Put OrignaVentures logo/specs in OrignaGTA to indicate company behind the software
- [ ] Add realistic test products from AliExpress, upload images to Cloudflare
- [ ] Add first products to production (Quote for split phase AC120V 10KW Hybrid Solar System)
- [ ] Make UI/UX feel expensive — investors will see it
- [ ] Don't stop till 300+ screenshots on desktop

## Priority: OrignaVentures
- [x] Move origna_ventures inside /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/
- [x] Remove contract signing — 3 tappable services → Stripe payment directly
- [x] Rename tiers: OrignaCode ($500) / OrignaLaunch ($2,000) / OrignaTeam ($1,000+/mo)
- [x] Include 20 human testers (20h QA) in OrignaLaunch tier
- [x] Spanish translations audit — all loc.tr() calls have proper ES
- [x] Theme unification — blue-violet palette (ThemeConfig) matching OrignaGTA
- [x] Fix backend SERVICE_CATALOG: origna_launch price 1000→2000
- [x] Add create_checkout_session_from_service() to backend
- [x] Fix theme_config.dart — proper ThemeConfig class
- [x] Create origna_ventures/.gitignore
- [x] Update AGENTS.md to include OrignaVentures
- [x] PayPage rewritten — serviceCode dropdown, no contractId
- [ ] Pricing page style like kimi.com (only subscription for team plan)
- [ ] Deploy latest version of OrignaVentures
- [ ] Move OrignaVentures hosting from Firebase to Hetzner (update Cloudflare, remove Firebase)
- [ ] Seller onboarding disabled — OrignaVentures IS the seller (support@orignaventures.ca)
- [ ] If seller is OrignaVentures, user doesn't pay premium to chat — chat directly
- [ ] Set chatting to sellers as "coming soon" until seller onboarding enabled

## Priority: Localization & Cookies
- [x] Spanish locale support in OrignaGTA (es.json with 150+ keys)
- [x] Spanish locale support in OrignaVentures (all loc.tr() calls have ES)
- [x] LanguageSelector supports EN/FR/ES
- [x] CookieConsentBanner — proper persistence, decline option, conditional display
- [x] Translation keys added (cookie.decline, cookie.accept, cookie.consent, language.spanish)
- [ ] Auto-language detection from IP/browser for both apps
- [ ] Request cookie permissions

## Priority: Operations & Infrastructure
- [x] Consolidate OrignaVentures into repo root
- [x] Remove legacy Firebase configuration
- [x] Update .gitignore for all apps
- [ ] iOS app build verification (Xcode required)
- [ ] Audit VSCode setup (tasks/launch/extensions)
- [ ] Fix VSCode warnings/issues
- [ ] Always keep VPS updated with latest deployment
- [ ] Delete users not in Postal API to restart free tier (<1000 users)
- [ ] Commit and push all to GitHub

## Priority: Testing
- [ ] Improve E2E API tests, add more live tests
- [ ] Run all E2E phases (e2e/specs phase1-6), fix as needed
- [ ] Run AI E2E tests (e2e/ai)
- [ ] Add E2E payment tests for both OrignaGTA and OrignaVentures
- [ ] Increase live test coverage to 95%+ (Rust and Flutter)
- [ ] Increase E2E visual test coverage
- [ ] After a fix, add 5+ tests to prevent regression + inline docs
- [ ] Coverage for live tests and E2E should be 95+
- [ ] Add tests to DB
- [ ] Fix testing failures as pro
- [ ] Make sure login works — if login fails, crash and nuke test suite and investigate

## Priority: Code Quality & Architecture
- [ ] Use strong try/catch that logs errors to Sentry/logs. Search web for Rust/Flutter best practices
- [ ] Make sure DB is replaceable using hexagonal architecture
- [ ] OrignaBase rules should be as strong as Firebase rules
- [ ] OrignaBase queries should be similar to Firebase
- [ ] Search Rust docs for best practices — websockets, GraphQL, etc. Audit full codebase
- [ ] Create/improve skills as needed
- [ ] Audit and improve skills, CLAUDE.md, AGENTS.md, etc
- [ ] Track all notes in app and make sure all is wired
- [ ] Study repo/process improvements that reduce repeat failures
- [ ] Audit for not connected elements in app
- [ ] No legacy code — removed ApiKeys.images, snapshot['images'], 'images' string, province backward compat
- [ ] Audit all app code now that seller onboarding is disabled

## Priority: Semantic Labels & Accessibility
- [ ] Make sure semantic labels are everywhere — find gaps and fix
- [ ] Add more E2E tests for semantics if needed

## Priority: Previews & Screenshots
- [x] Fix gaps with previews — empty states fixed, mockup data improved
- [ ] Add missing mockups for previews in lib/screens/
- [ ] Add missing mockups for previews in lib/widgets/
- [ ] Fix overflows or display issues in previews
- [ ] Every pass marks completed items with star

## Completed ✅
- [x] No legacy code — removed ApiKeys.images, snapshot['images'], 'images' review payload string, province backward compat
- [x] Products can have shipping disabled for specific countries — allowedShippingCountries, country-specific shipping
- [x] Fix bug with mobile layout not showing images in product details — _GalleryImage logging, empty-list fallback, removed legacy 'images' field
- [x] Improve Flutter app lifecycle events handling
- [x] Cuba shipping — Flutter side: maritime weight-based, Cuba provinces, address form, Havana validation, es.json
