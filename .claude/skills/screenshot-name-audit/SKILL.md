---
name: screenshot-name-audit
description: "Manifest-driven screenshot filename vs content audit for OrignaGTA. Use when recapturing app screenshots, verifying route/state/persona correctness, renaming mismatches, removing duplicates, and fixing capture flows that drift from the intended screen."
---

# Screenshot Name Audit

Audit screenshot truth, not just capture success.

## Goal

For every screenshot, prove:

- filename matches intended route/state/persona
- actual screen content matches the filename
- capture navigation was deterministic

## Required Contract

Every capture should be backed by a manifest entry with:

- filename
- route
- persona
- seeded preconditions
- required visible keywords/semantics
- forbidden keywords when useful

## Process

1. Deploy dev first
2. Seed required personas/states
3. Capture with strict route + keyword verification
4. Compare filename vs manifest vs actual content
5. Rename mismatches
6. Delete true duplicates only after confirming sameness
7. Re-run affected captures

## Root-Cause Checks

Look for:

- loose keyword-only success checks
- navigation that does not verify route change
- capture names coupled to optional clicks
- wrong persona/session reuse
- stale seeded state causing unexpected destination screens

## Save Path

Primary artifacts should be saved to Desktop when requested by the user.

## Validation

Do not claim completion until:

- mismatches are enumerated
- duplicates are enumerated
- capture flow fixes are applied
- a recapture subset proves the fix
