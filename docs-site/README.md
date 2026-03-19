# OrignaGTA Documentation Site

Static documentation site built with **Next.js** + **Nextra** for OrignaGTA e-commerce platform.

## Quick Start

### Development

```bash
cd docs-site
npm install
npm run dev
```

Open http://localhost:3000 in your browser.

### Build for Production

```bash
npm run build
```

Generates static site in `out/` directory.

### Deploy to VPS

```bash
../scripts/deploy_docs.sh
```

Syncs `out/` to VPS at `docs.orignagta.ca`.

## Structure

```
docs-site/
├── pages/
│   ├── en/                           # English docs
│   │   ├── index.mdx                # Home
│   │   ├── getting-started/
│   │   │   ├── _meta.json           # Nav metadata
│   │   │   ├── quickstart.mdx
│   │   │   └── seller-guide.mdx
│   │   ├── api-reference/           # REST API docs
│   │   │   ├── authentication.mdx
│   │   │   ├── products.mdx
│   │   │   ├── orders.mdx
│   │   │   └── ...
│   │   └── guides/                  # Howto guides
│   │       ├── seller-onboarding.mdx
│   │       └── deployment.mdx
│   └── fr/                           # French docs (TODO)
├── theme.config.jsx                  # Nextra theme config
├── next.config.js                    # Next.js config
├── package.json
└── README.md
```

## Tech Stack

- **Next.js 14** — React framework
- **Nextra 2** — Documentation theme
- **Markdown** — Content format
- **Flexsearch** — Full-text search (built-in)
- **Static Export** — Deploys to any static host (VPS, S3, etc.)

## Features

✅ Dark mode (default)  
✅ Bilingual ready (EN/FR structure in place)  
✅ Full-text search  
✅ Mobile-responsive  
✅ API reference documentation  
✅ Seller/buyer guides  
✅ SEO-friendly (static HTML)  

## Content Guidelines

### Markdown Files

- **Metadata**: Use YAML frontmatter for custom headers
- **Code blocks**: Specify language (`bash`, `http`, `json`, `dart`)
- **Links**: Use relative paths (`/en/api-reference/products`)
- **Tables**: Use standard Markdown syntax

### Navigation

- Edit `_meta.json` in each directory to control sidebar order
- Files not in `_meta.json` won't appear in nav

### Images

Place images in `public/images/` and reference:

```markdown
![Alt text](/images/screenshot.png)
```

## Deployment

### VPS Setup (One-time)

```bash
# SSH to VPS
ssh root@204.168.137.16

# Create docs directory
mkdir -p /var/www/orignagta/docs/current
chown www-data:www-data /var/www/orignagta/docs/current

# Add Caddyfile entry (from Caddyfile.docs in repo root)
```

### Deploy Script

```bash
./scripts/deploy_docs.sh
```

This script:
1. Builds the site (`npm run build`)
2. Syncs `out/` directory to VPS
3. Caddy automatically serves from `/var/www/orignagta/docs/current`

### Manual Verification

```bash
# After deploy, verify site is live
curl https://docs.orignagta.ca
# Should return HTML homepage
```

## Editing Pages

1. Find the `.mdx` file in `pages/en/` or `pages/fr/`
2. Edit in your text editor
3. Save — `npm run dev` hot-reloads instantly
4. Commit to git: `git add docs-site/ && git commit -m "docs: update page"`
5. Deploy: `./scripts/deploy_docs.sh`

## TODO

- [ ] Add French translations (`pages/fr/`)
- [ ] Write "Operations & Troubleshooting" section
- [ ] Add interactive API explorer
- [ ] API endpoint testing widget
- [ ] Video tutorials
- [ ] Glossary
- [ ] Change log / Release notes

## Troubleshooting

### Build fails with "Module not found"

```bash
npm install
npm run build
```

### Port 3000 already in use

```bash
# Use different port
PORT=3001 npm run dev
```

### Deployment timeout

- Check VPS SSH connectivity: `ssh root@204.168.137.16`
- Verify deploy script has correct permissions: `chmod +x scripts/deploy_docs.sh`
- Check VPS disk space: `ssh root@204.168.137.16 df -h`

## References

- **Nextra Docs**: https://nextra.site/docs
- **Next.js Docs**: https://nextjs.org/docs
- **Markdown Guide**: https://www.markdownguide.org/

---

**Last Updated**: March 2026  
**Maintainer**: OrignaGTA Team
