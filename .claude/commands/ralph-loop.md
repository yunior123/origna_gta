# /ralph-loop — Autonomous Coding Loop

**Usage**: `/ralph-loop [$ARGUMENTS]`

Start an autonomous coding loop. If `$ARGUMENTS` provided, use as the task list. Otherwise look for TASKS.md.

Invoke the ralph-loop skill. Work through tasks sequentially:
1. Read next unchecked task
2. Implement
3. Verify (analyze + test)
4. Commit
5. Mark done
6. Next task

Stop after all tasks done or 3 consecutive failures.
