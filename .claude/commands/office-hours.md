# /office-hours — Problem Framing Before Code

**Usage**: `/office-hours [$ARGUMENTS]`

Frame the problem through 6 forcing questions before writing any code. Adapted from gstack.

## Process

Ask and answer these 6 questions for the feature/problem described in `$ARGUMENTS`:

### 1. What problem are we actually solving?
Not the solution — the problem. What pain exists today?

### 2. Who is affected and how do they experience it?
Buyer? Seller? Admin? What's their current workflow?

### 3. What does success look like?
How will we measure it? What's the acceptance criteria?

### 4. What are the constraints?
- 8GB RAM Mac — no emulators, sequential only
- OrignaBase backend (not Firebase)
- main-only git policy
- Must pass flutter analyze + flutter test
- Money in integer cents

### 5. What have we tried before?
What didn't work and why? Check STATE.md for prior decisions.

### 6. What's the simplest thing that could work?
Start with MVP. No over-engineering.

## Output

After answering all 6, produce a **Design Doc Summary**:
```
## Design Doc: [Feature Name]
**Problem**: ...
**User**: ...
**Success Criteria**: ...
**Constraints**: ...
**Prior Art**: ...
**Proposed Approach**: ...
**Files to Modify**: ...
**Tests Needed**: ...
```
