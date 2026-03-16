# Agent Heartbeat Plan — origna_gta

## Purpose
Autonomous monitoring loop: Claude Code watches `support@orignagta.ca` for errors
from Sentry, Stripe, GitHub Actions, and customer support — auto-resolves or escalates.

## Architecture

```
[Sentry / Stripe / GitHub Actions / Customers]
          ↓  (email alerts sent to)
  support@orignagta.ca  (Cloudflare Email Routing)
          ↓  (forwards to)
  yuniorrodriguezo460@gmail.com  (Gmail MCP)
          ↓  (Claude Code reads via)
  mcp__claude_ai_Gmail__gmail_search_messages
          ↓  (analyzes + acts)
  Auto-fix  OR  Escalate → support@orignaventures.ca
```

## Email Labels (configure in Gmail)
- `agent-inbox` — all alerts from Sentry, Stripe, GitHub, customer support
- `agent-resolved` — after auto-fix
- `agent-escalated` — after human escalation

## Gmail Filter Setup
Create filter: `(from:sentry.io OR from:stripe.com OR from:github.com OR to:support@orignagta.ca)`
→ Apply label: `agent-inbox`, Skip inbox: No

## Alert Sources

### Stripe Webhook Failures
- Search: `from:stripe.com (subject:webhook OR subject:failed) label:agent-inbox is:unread`
- Endpoint IDs: dev `we_1T2ESaPPD6r8xGIzV45SJGbm`, staging `we_1T5bO3PPD6r8xGIzBmeQRLwK`
- Auto-resolution: verify endpoint URL vs `api.{env}.orignagta.ca/api/webhooks/stripe`

### Sentry Errors
- Search: `(from:sentry.io OR from:sentry) label:agent-inbox is:unread`
- Triage: stack trace → file/line in Flutter codebase → apply null check or fix
- Escalate: unknown errors, security-related, payment-critical paths

### GitHub Actions Failures
- Search: `from:github.com (subject:failed OR subject:failure) label:agent-inbox is:unread`
- Triage: which workflow? transient vs code bug
- Workflows: ci-backend, ci-flutter-web, ci-mobile, strict-quality-audit

### Customer Support
- Search: `to:support@orignagta.ca label:agent-inbox is:unread`
- Order status, refunds, account issues
- Always escalate refunds > $500, security issues, billing disputes

## Auto-Resolution Playbook
| Source | Issue | Auto-Fix |
|--------|-------|----------|
| Sentry | NullPointerException | Null check at file:line |
| Sentry | API timeout | Check OrignaBase logs, raise timeout |
| Stripe | Webhook 400 | Verify endpoint URL + HMAC secret |
| Stripe | Webhook 404 | Check router path in ob-handlers |
| GitHub | Analyze failure | `flutter analyze --no-fatal-infos` fix |
| GitHub | Test failure | Read log, fix test, commit, push |
| Customer | Order status | Lookup via OrignaBase API, reply |
| Customer | Return request | Initiate if ≤ 30 days since delivery |

## Escalation Format
```
Subject: [ESCALATION] origna_gta — {category} — {brief description}

Alert source: {Stripe/Sentry/GitHub/Customer}
Received at: {timestamp}
Summary: {1-2 sentence description}
Attempted resolution: {what was tried}
Why escalating: {why auto-resolution failed}
Raw alert: {paste original alert}
```
Send to: support@orignaventures.ca

## Escalation Rules
- Auto-fix attempted twice, no resolution → escalate
- Refund > $500 → always escalate
- Security-related → escalate immediately
- Customer SLA: < 1 hour response (business hours)

## Running the Heartbeat
Use `/agent-heartbeat run` in Claude Code, or invoke the `heartbeat-agent` sub-agent.
The `heartbeat-agent.md` agent in `.claude/agents/` has full execution instructions.

## Future: Cron Integration
Set up a cron via Claude Code CronCreate tool to run heartbeat every 30 minutes:
```
/loop 30m /agent-heartbeat run
```

## Future: Custom OpenClaw
Build an osascript-powered automation that:
1. Opens a new Claude Code Terminal window via osascript
2. Targets it by window ID
3. Sends `/agent-heartbeat run` keystroke
4. Reads output and logs to `~/.claude/heartbeat.log`
Reference: `~/.claude/projects/*/memory/osascript-patterns.md`
