# Deployment Checklist for Hetzner + Cloudflare
1. Update DNS records (A record -> VPS IP).
2. Ensure Caddy handles SSL (tls-alpn-01).
3. Confirm Firebase usage is purged (except FCM).
4. Remove any hardcoded Firebase SDK init if present.
