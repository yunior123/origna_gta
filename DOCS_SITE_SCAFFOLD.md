# OrignaGTA Docs Site — Scaffold Complete ✅

**Date**: March 18, 2026  
**Framework**: Nextra 2 (Next.js 14) + Markdown  
**Target**: Static export to VPS at docs.orignagta.ca

## What Was Created

### Directory Structure
```
docs-site/
├── package.json                    # npm config
├── next.config.js                  # Next.js + Nextra setup
├── theme.config.jsx                # Sidebar nav, logo, footer
├── README.md                        # Docs site documentation
├── pages/
│   ├── _app.js                    # React app wrapper
│   ├── _document.js               # HTML document template
│   └── en/                        # English documentation (9 pages)
│       ├── index.mdx              # Home — platform overview
│       ├── _meta.json             # Main sidebar navigation
│       ├── getting-started/
│       │   ├── _meta.json
│       │   └── quickstart.mdx      # Setup guide for devs/sellers
│       ├── api-reference/
│       │   ├── _meta.json
│       │   ├── authentication.mdx  # JWT, login, Google OAuth
│       │   └── products.mdx        # CRUD, search, filtering
│       └── guides/
│           ├── _meta.json
│           └── seller-onboarding.mdx # Step-by-step seller workflow
└── public/                        # Static assets (images, etc.)
```

### Files Created (9 pages so far)

| File | Purpose | Content |
|------|---------|---------|
| **pages/en/index.mdx** | Home page | Welcome, platform overview, architecture diagram |
| **pages/en/getting-started/quickstart.mdx** | Setup guide | Prerequisites, dev server, test accounts |
| **pages/en/api-reference/authentication.mdx** | Auth API | JWT, register, login, OAuth, refresh |
| **pages/en/api-reference/products.mdx** | Products API | List, create, update, search endpoints |
| **pages/en/guides/seller-onboarding.mdx** | Seller guide | Requirements, profile, Stripe connect, inventory |
| **theme.config.jsx** | Nextra theme | Logo, nav, footer, dark mode, multilingual |
| **next.config.js** | Build config | Nextra plugin, i18n setup |
| **README.md** | Docs site docs | Dev setup, structure, deployment |
| **scripts/deploy_docs.sh** | Deploy script | Build + rsync to VPS |

### Deployment Config

**Caddyfile.docs** block for VPS:
```
docs.orignagta.ca {
    root * /var/www/orignagta/docs/current
    file_server
    encode gzip
    try_files {path} {path}.html /index.html
    ...
}
```

**Deploy flow:**
```bash
# Local: Build static site
npm run build  # → out/

# Deploy: Sync to VPS
./scripts/deploy_docs.sh  # → rsync out/ to VPS
```

## Why Nextra?

✅ **Static export** — Deploy anywhere (VPS, S3, Vercel)  
✅ **Zero runtime** — Just static HTML/CSS/JS  
✅ **Dark mode built-in** — Matches OrignaGTA UI  
✅ **Search included** — Flexsearch (no backend needed)  
✅ **Markdown-native** — Easy to edit & version control  
✅ **Bilingual ready** — i18n structure in place  
✅ **SEO-friendly** — Static HTML, fast load times  
✅ **Responsive** — Mobile-first design  

**Comparison vs. other tools:**

| Tool | Static | Search | Dark Mode | i18n | Learning Curve |
|------|--------|--------|-----------|------|-----------------|
| Nextra | ✅ | ✅ | ✅ | ✅ | Low |
| Docusaurus | ✅ | Algolia$ | ✅ | ✅ | Medium |
| Mintlify | ✅ | ✅ | ✅ | ❌ | Low |
| GitBook | 🔒 | ✅ | ✅ | ✅ | None (SaaS) |
| Fumadocs | ✅ | ✅ | ✅ | ✅ | Medium |

**Chosen: Nextra** for simplicity + full control + zero cost.

## Next Steps (After Launch)

### Phase 1: Expand Content (1–2 days)
- [ ] Orders API documentation
- [ ] Cart API documentation
- [ ] Payments & Webhooks documentation
- [ ] Error codes reference
- [ ] Buyer guide
- [ ] Shipping & delivery guide

### Phase 2: Multilingual (1 day)
- [ ] Create `pages/fr/` structure
- [ ] Translate all pages to French
- [ ] Test i18n routing

### Phase 3: Enhanced Features (2–3 days)
- [ ] OpenAPI/Swagger spec for APIs
- [ ] Interactive API explorer
- [ ] Video tutorials (embedded YouTube)
- [ ] Changelog / Release notes
- [ ] Glossary of terms
- [ ] Troubleshooting FAQ

### Phase 4: Polish (1 day)
- [ ] Custom CSS for branding
- [ ] Legal pages (privacy, ToS)
- [ ] Operations guide (deployment, monitoring)
- [ ] Analytics integration (optional)

## Commands

### Development
```bash
cd docs-site
npm install
npm run dev        # http://localhost:3000
```

### Production
```bash
npm run build      # Static export to out/
./scripts/deploy_docs.sh  # Deploy to VPS
```

### Edit Content
1. Edit `.mdx` file in `pages/en/`
2. Save → dev server hot-reloads
3. Test locally
4. Commit & deploy

## File Paths

- **Docs site**: `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/docs-site/`
- **Deploy script**: `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/scripts/deploy_docs.sh`
- **Caddyfile config**: `/Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/Caddyfile.docs`
- **VPS target**: `/var/www/orignagta/docs/current`

## Verification Checklist

- [x] Nextra + Next.js config created
- [x] Theme configured (dark mode, nav, footer)
- [x] English docs structure in place
- [x] 5+ content pages written
- [x] i18n setup ready (French structure prepared)
- [x] Deploy script created
- [x] Caddyfile config documented
- [x] README with setup instructions
- [ ] Run `npm install && npm run build` to verify
- [ ] Test local dev server
- [ ] Deploy to staging (when ready)

## Common Tasks

**Add a new page:**
```bash
# Create file
touch pages/en/section/new-page.mdx

# Edit
echo "# New Page\nContent here..." > pages/en/section/new-page.mdx

# Add to nav (edit pages/en/section/_meta.json)
# {"new-page": "New Page Title"}
```

**Update nav order:**
```bash
# Edit _meta.json in the section
vim pages/en/getting-started/_meta.json
```

**Deploy changes:**
```bash
./scripts/deploy_docs.sh
```

---

**Status**: ✅ Ready for initial build test  
**Next**: `npm install && npm run build` to verify Nextra setup, then prepare test deployment to staging
