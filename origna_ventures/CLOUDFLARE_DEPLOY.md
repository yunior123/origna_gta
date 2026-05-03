# Deployment Checklist for Hetzner + Cloudflare
1. Update DNS records (A record -> VPS IP).
2. Ensure Caddy handles SSL (tls-alpn-01).
3. Confirm the frontend uses FastAPI/OrignaBase endpoints only.
4. Confirm no retired hosting or backend SDK initialization is present.
