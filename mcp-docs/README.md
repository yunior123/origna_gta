# OrignaGTA MCP Documentation Site

This directory contains comprehensive documentation for the OrignaGTA Model Context Protocol (MCP) server, designed for AI agents to discover and use marketplace capabilities.

## Documentation Structure

```
mcp-docs/
├── index.html                           # Homepage — overview & quick start
├── getting-started.html                 # 5-minute setup guide
├── llms.txt                            # AI-readable documentation (standard format)
├── README.md                            # This file
├── CADDY_CONFIG.md                      # VPS deployment & Caddy configuration
├── API_LLMS_TXT_INTEGRATION.md         # How to add llms.txt to OrignaBase API
├── .well-known/
│   └── mcp.json                        # Machine-readable discovery manifest
└── api-reference/
    └── index.html                      # Complete API reference for all 14 tools
```

## Key Files

### 1. llms.txt (780 lines)
**AI-Readable Documentation** following the [llms.txt specification](https://llmstxt.org)

Features:
- Tool-by-tool reference for all 14 MCP tools
- Input/output schemas with examples
- Authentication flow and JWT details
- Data format conventions (money, addresses, timestamps)
- Error codes and rate limits
- Integration examples

**Served at:**
- `https://mcp.docs.orignagta.ca/llms.txt`
- `https://api.orignagta.ca/llms.txt` (when integrated with OrignaBase API)

### 2. .well-known/mcp.json
**Machine-Readable Discovery Manifest** for automated agent discovery

Contains:
- Server name, version, status
- Tool categories and count
- Authentication requirements and supported roles
- Rate limits and security features
- Environment URLs
- Links to documentation

**Served at:**
- `https://mcp.docs.orignagta.ca/.well-known/mcp.json`
- `https://api.orignagta.ca/.well-known/mcp.json` (when integrated)

### 3. index.html (300+ lines)
**Homepage** with:
- Feature overview
- Quick start guide (5 steps)
- All 14 tools summarized
- Example agent purchase flow
- Authentication information
- Links to detailed documentation

### 4. getting-started.html (400+ lines)
**Installation & Integration Guide** covering:
- Prerequisites (Node.js 18+)
- Step-by-step installation (6 steps)
- JWT token retrieval
- Claude Desktop integration
- Environment configuration
- Troubleshooting common issues

### 5. api-reference/index.html (500+ lines)
**Complete API Documentation** with:
- All 14 tools fully documented
- Parameters with types and descriptions
- Response examples (JSON)
- Error handling and error codes
- Rate limits table
- Tool categorization (Search, Cart, Checkout, Orders, etc.)

## Documentation URLs

### Development
| Resource | URL |
|----------|-----|
| Homepage | https://mcp.docs.dev.orignagta.ca |
| llms.txt | https://mcp.docs.dev.orignagta.ca/llms.txt |
| API Reference | https://mcp.docs.dev.orignagta.ca/api-reference/ |
| Getting Started | https://mcp.docs.dev.orignagta.ca/getting-started.html |
| Manifest | https://mcp.docs.dev.orignagta.ca/.well-known/mcp.json |

### Staging
Same as above, replace `dev` with `staging`

### Production
Same as above, replace `dev` with nothing:
- https://mcp.docs.orignagta.ca
- https://mcp.docs.orignagta.ca/llms.txt
- etc.

## Deployment

### Option A: Standalone Documentation Site (Recommended)

Deploy to VPS using the provided script:

```bash
# Deploy to development
./scripts/deploy_mcp_docs.sh dev

# Deploy to staging
./scripts/deploy_mcp_docs.sh staging

# Deploy to production
./scripts/deploy_mcp_docs.sh prod
```

Then configure Caddy (see CADDY_CONFIG.md):

```bash
ssh -i ~/.ssh/id_ed25519 root@204.168.137.16
nano /etc/caddy/Caddyfile
# Add mcp.docs.orignagta.ca blocks
caddy reload --config /etc/caddy/Caddyfile
```

### Option B: Integrated with OrignaBase API

Serve llms.txt and mcp.json directly from the API (see API_LLMS_TXT_INTEGRATION.md):

```rust
// In orignabase/src/routes.rs
.route("/llms.txt", get(get_llms_txt))
.route("/.well-known/mcp.json", get(get_mcp_manifest))
```

## Local Testing

### View locally
```bash
# Start a simple HTTP server
cd mcp-docs
python3 -m http.server 8000

# Open browser
open http://localhost:8000
```

### Validate JSON
```bash
jq . .well-known/mcp.json

# Should output valid JSON with no errors
```

### Validate llms.txt format
```bash
# Check first few lines
head -20 llms.txt

# Should start with:
# # OrignaGTA MCP Server — AI-Readable Documentation
```

## File Size Reference

| File | Size | Lines | Purpose |
|------|------|-------|---------|
| llms.txt | ~25 KB | 780 | AI-readable docs |
| .well-known/mcp.json | ~8 KB | 150 | Machine-readable manifest |
| index.html | ~30 KB | 400 | Homepage |
| getting-started.html | ~25 KB | 450 | Setup guide |
| api-reference/index.html | ~40 KB | 600+ | API reference |
| **Total** | **~128 KB** | **~2,400** | All docs |

## Browser Compatibility

All HTML files use:
- CSS Grid for responsive layouts
- Standard HTML5 semantics
- No JavaScript (static content only)
- Dark theme optimized for developer experience
- Mobile-responsive design

Tested browsers:
- Chrome 90+
- Safari 14+
- Firefox 88+
- Edge 90+

## Content Updates

To update documentation:

1. **Edit HTML files** in `mcp-docs/`
2. **Update llms.txt** for tool changes
3. **Update .well-known/mcp.json** for manifest changes
4. **Test locally** with `python3 -m http.server 8000`
5. **Deploy** with `./scripts/deploy_mcp_docs.sh`

## Integration with MCP Server

The documentation site is separate from the MCP server codebase but provides comprehensive coverage:

```
orignabase/                         ← Backend + API
├── src/
│   ├── tools/                      ← Tool implementations
│   └── routes.rs
└── README.md                        ← Technical details

mcp-server/                          ← MCP Protocol
├── src/
│   ├── tools/
│   └── index.ts                    ← Tool definitions
└── README.md

mcp-docs/                            ← AI Agent Documentation (this directory)
├── llms.txt                         ← AI-readable
├── .well-known/mcp.json            ← Machine-readable
├── index.html                       ← Human-readable (homepage)
├── getting-started.html             ← Setup guide
└── api-reference/                   ← Full API reference
```

## SEO & Discovery

### For Search Engines
- All pages have proper `<meta>` tags
- Semantic HTML structure
- Open Graph tags for social sharing (can be added)
- Canonical URLs (can be added)

### For AI Agents
- llms.txt follows official standard
- .well-known/mcp.json is discoverable
- Content-Type headers set correctly
- No authentication required for discovery

## Security

### Public Information Only
- No API keys, tokens, or secrets in documentation
- No internal system details or IP addresses
- No sensitive business logic exposed

### HTTPS Only
- Caddy enforces HTTPS automatically
- Certificates from Let's Encrypt
- HSTS headers in production

### Rate Limiting
- Documentation endpoints are public (no auth)
- Rate limiting applied at Caddy level if needed
- llms.txt and mcp.json have generous cache times

## Support

### For Developers
- **Getting Started**: See `getting-started.html`
- **API Reference**: See `api-reference/index.html`
- **Issues**: Report on GitHub

### For AI Agents
- **Discovery**: Check `/.well-known/mcp.json`
- **Documentation**: Read `llms.txt`
- **Integration**: Follow examples in llms.txt

## Contributing

To contribute to documentation:

1. Fork the repository
2. Make changes to HTML/Markdown files
3. Test locally with `python3 -m http.server`
4. Submit pull request
5. Updates deployed automatically

## License

Documentation is part of the OrignaGTA project.

## Changelog

### March 2026
- Initial release
- All 14 tools documented
- HTML documentation site
- llms.txt format compliance
- .well-known/mcp.json manifest
- Caddy deployment guide
- API integration guide

---

**Status**: Production Ready ✓  
**Last Updated**: March 2026  
**Version**: 1.0.0
