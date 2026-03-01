> **Source of Truth:** [CLAUDE.md](./CLAUDE.md) — single source of truth.
> **Goal:** Launch by March 2026.

1.- run full audit of the repo thoroughly, using all agents from .claude/agents to identify issues, bugs, security vulnerabilities, performance issues, etc plus any other thing u think it should be fixed plus any other things that could prevent a successful launch, up and running, be honest, dont try to please me. ex: right now the tests do not deeply cover the full code base, e2e full scenarios representing real user scenarios should be created and implemented, etc. There are many ways in which we mght enforce the app correctly running, like more integration tests in flutter, more unit tests, more playwright tests, etc.
2.- add playwright tests to cover all apis used in the app, it includes cloudflare r2, stripe, firestore, etc
3.- improve existing playwright ui tests to go deeper into e2e scenarios, ex: products should be added in the tests, right now we only validate visivility of componenets.
4.- update repo map
5.- update docs, readme, etc in the repo. New devs should be able to know how to run playwright tests one by one, run group of tests or batches, run all tests, run tests in dev, run tests in staging, run tests in prod, etc. There should be docs and updates for all, not just tests. 