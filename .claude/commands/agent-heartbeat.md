# /agent-heartbeat — Agent Email Monitoring Loop

**Usage**: `/agent-heartbeat [setup|run|status]`

## Overview
Claude Code monitors `support@orignagta.ca` inbox for:
- Sentry error alerts → auto-analyze + fix or escalate
- Customer support emails → route to Support Agent
- Stripe webhook failures → auto-retry or escalate
- GitHub Actions failures → analyze + fix or escalate

Escalation path: `support@orignagta.ca` → `support@orignaventures.ca` → `yuniorrodriguezo460@gmail.com`

## Architecture
```
[Sentry/Stripe/GitHub] → support@orignagta.ca (Cloudflare Email)
                              ↓
                    Claude Code fetches via Gmail MCP
                              ↓
                    Analyze + attempt auto-fix
                              ↓ (if unresolved)
                    Escalate → support@orignaventures.ca
```

## Setup Steps

### 1. Configure Cloudflare Email Routing
```
Dashboard → orignagta.ca → Email → Email Routing
Add route: support@orignagta.ca → yuniorrodriguezo460@gmail.com
Add route: support@orignagta.ca → Claude Code Gmail MCP
```

### 2. Connect Gmail MCP
The Gmail MCP (`mcp__claude_ai_Gmail__*`) already has access.
Configure filter: from `sentry.io`, `stripe.com`, `github.com` → label `agent-inbox`

### 3. Configure Sentry
```
Sentry → Settings → Alerts → Integrations
Add email: support@orignagta.ca for all error alerts
```

### 4. Configure Stripe
```
stripe webhook update we_1T2ESaPPD6r8xGIzV45SJGbm \
  --add-metadata notification_email=support@orignagta.ca
```

## Run Heartbeat (manual)
```bash
# Check agent inbox for new issues
Use mcp__claude_ai_Gmail__gmail_search_messages with:
  query: "label:agent-inbox is:unread"

# For each unread:
# 1. Read full email
# 2. Identify source (Sentry/Stripe/GitHub/Customer)
# 3. Attempt resolution
# 4. Reply with resolution or escalate
```

## Heartbeat Plan File
See: `docs/plans/agent-heartbeat-plan.md` for full implementation details

## Auto-Resolution Playbook
| Source | Issue | Auto-Fix |
|--------|-------|----------|
| Sentry | NullPointerException | Find file + line, apply null check |
| Sentry | API timeout | Check OrignaBase logs, increase timeout |
| Stripe | Webhook 400 | Check endpoint URL, verify signature |
| GitHub | Test failure | Read log, fix failing test, push |
| Customer | Order status | Lookup order, reply with status |
| Customer | Refund request | Lookup order, initiate refund if eligible |

## Escalation Rules
- Auto-fix attempted twice with no resolution → escalate
- Refund > $500 → always escalate
- Security-related issues → always escalate immediately
- SLA: respond to customer emails within 1 hour (business hours)
