---
name: live-test-ops
description: "Backend-first live test operations for OrignaGTA + OrignaBase. Use when running remote/live suites, monitoring VPS RAM/disk/health, sequencing Rust before Flutter, updating STATE.md, and fixing infra/runtime blockers instead of skipping tests."
---

# Live Test Ops

Run live validation in production order, with infra monitoring and exact evidence.

## Use When

- Running remote dev/staging/prod health checks
- Running Rust live suites in `orignabase/scripts/run-live-tests.sh`
- Running Flutter live tests against localhost or dev
- Monitoring VPS RAM, disk, swap, docker state, and rebuild progress
- Fixing infra/runtime blockers discovered by live tests

## Order

1. VPS health + RAM/disk snapshot
2. Rust backend live tests on dev
3. Fix backend blockers
4. Flutter live tests
5. E2E phases
6. Load/reliability/stress/benchmarks

Never move to Flutter live while backend live has a known blocker.

## Mandatory Commands

### VPS snapshot

```bash
ssh root@204.168.137.16 '
  date
  free -h
  df -h /
  docker system df
  cd /opt/orignabase && docker compose ps
'
```

### Backend live

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/orignabase
./scripts/run-live-tests.sh https://api.dev.orignagta.ca --smoke
./scripts/run-live-tests.sh https://api.dev.orignagta.ca --file security_fixes_test
```

### Flutter live

```bash
cd /Users/yuniorrodriguezosorio/Documents/GitHub/origna_gta/origna_gta
flutter test test/live/ \
  --dart-define=RUN_ORIGNABASE_LIVE_TESTS=true \
  --dart-define=ENVIRONMENT=emulator
```

## Monitoring Rule

Use sleep-based monitors for long-running rebuilds/tests:

```bash
while true; do
  date
  ssh root@204.168.137.16 'cd /opt/orignabase && docker compose ps'
  sleep 240
done
```

Do not busy-poll.

## Evidence Rule

Every blocker added to `STATE.md` must include:

- exact command
- exact failing suite/test
- exact status/code/log symptom
- exact file or infra root cause once known

## Fix Rule

- Fix infra/runtime causes instead of weakening tests
- Do not mark live work done from local-only evidence
- If dev/staging/prod behavior differs, record the exact environment difference
