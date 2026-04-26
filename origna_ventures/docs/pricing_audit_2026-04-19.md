# Origna Ventures Pricing Audit

Date checked: 2026-04-19

This audit reflects the external services visibly used across `origna_gta`, `orignabase`, and the Origna Ventures launch flow.

## Service pricing

| Service | Price | Notes |
|---|---:|---|
| OrignaCode | 500 CAD one-time | Source code, private repo delivery, lifetime source updates, no resale |
| OrignaLaunch | 3,000 CAD one-time | Includes OrignaCode, Hetzner year 1, Apple Developer year 1, Google Play registration, store deployment, 4 weeks support |
| OrignaTeam | 1,000+ CAD / month | Dedicated developer outsourcing, daily meeting required, time tracking supported, third-party/API costs billed separately |

## Competitor framing

| Product | Current public entry pricing | Positioning note |
|---|---:|---|
| Shopify Basic | 37 CAD/month billed yearly | Still adds transaction fees and app ecosystem costs |
| Replit Core | 25 USD/month or 20 USD/month billed annually | Credit model, deployment/build budget still applies |
| Lovable Pro | 25 USD/month or 21 USD/month annually | Frontend/prototyping friendly, third-party services billed separately |
| OrignaGTA | 500 CAD or 3,000 CAD one-time, or 1,000+ CAD/month | Source ownership + cross-platform + custom backend |

## External services used by the stack

| Service | Current public pricing | Free tier | Required or optional |
|---|---|---|---|
| Apple Developer Program | 99 USD/year | Free Apple developer account exists, but not App Store distribution | Required for iOS release |
| Google Play Console | 25 USD one-time | None for public publishing | Required for Android release |
| Stripe Payments (Canada) | 2.9% + CA$0.30 domestic cards | No monthly fee | Required if card checkout is used |
| Postal | Premium 27 USD/month | 6,000 emails/month, 200/day | Optional upgrade; free tier may be enough at launch |
| Cloudflare Turnstile | Enterprise contact sales | Free | Optional but recommended |
| Cloudflare R2 | 0.015 USD/GB-month + request pricing | 10 GB-month + 1M Class A + 10M Class B ops/month | Optional |
| Sentry | Team 26 USD/month | Developer 0 USD | Optional |
| Meilisearch Cloud | Starts at 30 USD/month | OSS self-host remains free, Cloud trial available | Optional because OrignaBase can self-host |
| GitHub | Team 4 USD/user/month | Free with unlimited private repos | Optional paid upgrade |
| Bitbucket | Standard 3.65 USD/user/month | Free up to 5 users, unlimited private repos | Optional alternative |

## Included cost logic for Service 1

Included by default:

- Hetzner server (8 GB RAM + 80 GB disk) for year 1
- Apple Developer Program year 1
- Google Play registration fee
- App Store + Play deployment work
- 4 weeks of post-launch support

Optional upgrades, not assumed mandatory in the 3,000 CAD base:

- Postal Premium
- Sentry Team or Business
- Cloudflare R2 paid usage beyond free tier
- Meilisearch Cloud instead of self-hosted search
- GitHub Team / Bitbucket paid plans

## Verified project stack signals

- Payments: Stripe Checkout + webhooks
- Email: Postal
- Search: Meilisearch
- Bot protection: Cloudflare Turnstile
- Storage: local + S3/R2-compatible
- Monitoring: Sentry
- App distribution: Apple + Google Play

## Live URL status snapshot

- `https://orignaventures.ca` resolves successfully
- `https://www.orignaventures.ca/` resolves successfully
- route-specific browser QA is still recommended after deploy for any legacy/public paths that were historically exposed
- `https://dev.orignagta.ca/` is live
