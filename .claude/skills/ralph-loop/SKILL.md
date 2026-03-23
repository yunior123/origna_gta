---
name: ralph-loop
description: "Autonomous multi-hour coding loop. Claude works through a task list, committing between iterations, maintaining fresh context per task. Use for bulk implementation, CRUD generation, test coverage, or overnight work."
---

# Ralph Loop

Autonomous development loop — work through tasks sequentially, committing between iterations, fresh context each round.

## When to Use

- Implementing multiple related features from a plan
- Generating CRUD operations across many models
- Adding test coverage to multiple files
- Bulk refactoring with verification
- Overnight autonomous coding sessions

## How It Works

1. **Define the task list** — break work into independent, verifiable units
2. **Loop** — for each task:
   a. Read the task specification
   b. Implement the change
   c. Verify (analyze + test)
   d. Commit with descriptive message
   e. Move to next task
3. **Stop conditions** — all tasks done, or error that can't be auto-resolved

## Instructions

### Step 1: Create Task File

Create a `TASKS.md` file listing all work items:

```markdown
## Tasks

- [ ] Create user registration endpoint
- [ ] Add email validation
- [ ] Implement password hashing
- [ ] Create login endpoint
- [ ] Add JWT token generation
- [ ] Write unit tests for auth service
```

### Step 2: Execute Loop

For each unchecked task:

1. **Read** the task and understand scope
2. **Implement** the minimal change
3. **Verify**:
   - `flutter analyze --no-fatal-infos` (if Dart changed)
   - `flutter test --exclude-tags golden` (if Dart changed)
   - `cd orignabase && cargo clippy -D warnings && cargo test` (if Rust changed)
4. **If verification fails**: fix the issue, re-verify (max 3 attempts)
5. **If still failing after 3 attempts**: mark task as blocked, move to next
6. **Commit**: `git add <specific files> && git commit -m "feat: <task description>"`
7. **Mark done** in TASKS.md: `- [x] Create user registration endpoint`
8. **Next task**

### Step 3: Stop Conditions

Stop the loop when:
- All tasks are checked off
- 3 consecutive tasks fail (systemic issue)
- A blocking dependency is discovered
- Manual intervention is needed (e.g., environment issue)

### Step 4: Summary

After loop completes, produce:

```
RALPH LOOP SUMMARY
==================
Completed: X/Y tasks
Blocked: Z tasks
Commits: N

Completed Tasks:
- [x] Task 1 (commit abc123)
- [x] Task 2 (commit def456)

Blocked Tasks:
- [ ] Task 3 — reason: [why it failed]

Next Steps:
- [action items for blocked tasks]
```

## Safety Rules

- **Atomic commits** — one commit per task, never batch
- **Verify before commit** — never commit failing code
- **No force push** — additive commits only
- **Fresh context** — each task starts clean, don't carry debugging state
- **Max 3 retries** per task — don't loop forever on one problem
- **8GB RAM** — sequential only, never parallel builds

## Iteration Template

Each iteration follows this exact pattern:

```
1. Read next unchecked task from TASKS.md
2. Identify files to create/modify
3. Implement the change
4. Run: flutter analyze --no-fatal-infos (or cargo clippy)
5. Run: flutter test --exclude-tags golden (or cargo test)
6. If PASS → git add <files> && git commit -m "type: description"
7. If FAIL → attempt fix (max 3 tries)
8. Update TASKS.md checkbox
9. → Next task
```
