# AI Coordination

Purpose: keep multiple AIs from editing the same surface at the same time.

## Source Of Truth

- Active backlog: `CORE.md`
- Historical proof: `STATE.md`
- Live file/path ownership: `WORK_CLAIMS.md`

## Required Flow

1. Before editing, read `WORK_CLAIMS.md`.
2. Claim exact paths, not vague themes.
3. Keep claims small and disjoint.
4. Update `CORE.md` so the task state matches the claim.
5. Release the claim when verification is done or when blocked.

## Claim Format

Each claim must include:

- agent name
- task summary
- owned paths
- start time
- expiry time
- verification command
- status: `active`, `blocked`, `handoff`, `done`

## Ownership Rules

- Ownership is path-based, not topic-based.
- One primary owner per file at a time.
- If two tasks need the same file, the second task must wait or split scope.
- If a shared file is unavoidable, re-read immediately before patching and update the claim.

## Lease Rules

- Default lease: 90 minutes.
- Renew the lease if work is still active.
- Expired claims may be taken over, but the new agent must note the takeover in `WORK_CLAIMS.md`.

## Handoff Rules

When handing work to another agent, record:

- exact files touched
- current state
- failing command or blocker
- next expected command

Do not hand off a theme like "auth" or "payments" without the concrete paths.

## Recommended Splits

- `orignabase/crates/**` — backend/Rust owner
- `origna_gta/lib/**` — Flutter app owner
- `origna_ventures/backend/**` — Ventures backend owner
- `origna_ventures/lib/**` — Ventures frontend owner
- `e2e/specs/**` — E2E owner
- `docs/**`, `AGENTS.md`, `CLAUDE.md`, `CORE.md`, `STATE.md` — docs/coordination owner

## Anti-Collision Rules

- Do not let two agents edit `CLAUDE.md`, `AGENTS.md`, `CORE.md`, `STATE.md`, or `WORK_CLAIMS.md` at the same time.
- Do not let two agents edit the same test file and implementation file pair simultaneously.
- If a hot file is shared, assign one integrator to merge the final patch.

## Progress Tracking

- `CORE.md` tracks task status.
- `WORK_CLAIMS.md` tracks ownership.
- `STATE.md` records verified outcomes only.

## Verification Rule

Claims are not released until the owner records at least one concrete verification command or a concrete blocker.
