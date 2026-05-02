# Deployment Checklist for Hetzner + Cloudflare
1. Update DNS records (A record -> VPS IP).
2. Ensure Caddy handles SSL (tls-alpn-01).
3. Confirm Firebase usage remains purged.
4. Confirm no hardcoded Firebase SDK init is present.
