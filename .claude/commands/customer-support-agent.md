# /customer-support-agent — Claude Agent SDK Support Integration

**Usage**: `/customer-support-agent [plan|implement|test]`

## Overview
In-app customer support powered by Claude Agent SDK. Handles returns, billing disputes,
account issues with 80%+ first-contact resolution. Only available to logged-in users.

## Architecture
```
Flutter Chat UI
     ↓
OrignaBase Proxy (no direct Anthropic calls from Flutter)
     ↓
Claude Agent SDK (claude-opus-4-6) + MCP Tools
     ↓ ↓ ↓ ↓
get_customer  lookup_order  process_refund  escalate_to_human
(PostgreSQL)   (PostgreSQL)   (Stripe)        (email)
```

## MCP Tools Spec
```typescript
// get_customer — fetch user profile + order history
tool: get_customer(userId: string) → { user, orders[], addresses[] }

// lookup_order — full order details
tool: lookup_order(orderId: string) → { order, items[], tracking, seller }

// process_refund — initiate Stripe refund
tool: process_refund(orderId: string, amountCents: int, reason: string)
  → { refundId, status, expectedDate }
// Guards: amount ≤ order.totalAmountCents, order must be delivered
// Always requires: 30-day window check

// escalate_to_human — send email to support@orignaventures.ca
tool: escalate_to_human(reason: string, context: object)
  → sends email with full conversation transcript
```

## System Prompt
```
You are Origna Support, a helpful customer support agent for Origna —
a Canadian e-commerce marketplace. You help buyers with orders, returns,
billing, and account issues.

Rules:
- Always verify the user's identity via their session (never ask for password)
- For refunds: check 30-day eligibility window before processing
- For disputes: look up the order facts before forming an opinion
- Escalate to human if: issue > $500, security concern, 2+ failed resolution attempts
- Always be empathetic, concise, and solution-focused
- Language: respond in the same language the user writes in (FR/EN/ES)
- Never make up information — use tools to get real data
```

## Flutter Implementation
```dart
// lib/screens/support/support_chat_screen.dart
// lib/viewmodels/support_chat_viewmodel.dart
// lib/services/support_agent_service.dart

// Route: /support (only for authenticated users)
// Entry points: Orders screen → "Get Help" button, Profile → "Support"
```

## OrignaBase Endpoint
```
POST /support/chat
Body: { message: string, conversationId: string? }
Response: { reply: string, conversationId: string, actions: [] }
```

## Implementation Plan
1. **OrignaBase handler**: `ob-handlers/src/support.rs` — proxy to Anthropic API
2. **MCP tools**: implement 4 tools in Rust with PostgreSQL + Stripe access
3. **Flutter service**: `SupportAgentService` wraps OrignaBase `/support/chat`
4. **Flutter UI**: `SupportChatScreen` — chat bubble UI, typing indicator
5. **Route guard**: only authenticated users can access `/support`

## Plan File
Full implementation plan: `docs/plans/customer-support-agent-plan.md`

## Test Accounts
- Buyer: `yuniorrodriguezo460@gmail.com` — use for support testing
- Seller: `yuniorrodriguezo4601@yahoo.com` — for seller-side escalations

## Escalation Email Template
```
Subject: [ESCALATION] {issue_type} — Order {orderId}
To: support@orignaventures.ca

User: {userName} ({userId})
Issue: {description}
Order: {orderId} — {orderTotal}
Attempts: {attemptCount}
Transcript: [attached]
```
