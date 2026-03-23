# /code-review — Multi-Agent Code Review

**Usage**: `/code-review`

Run 4 parallel review agents on current changes:
1. Correctness & Logic
2. Security & Safety
3. Performance & Efficiency
4. Standards & Conventions

Each finding gets a confidence score (1-10). Score ≥9 blocks commit.

Invokes the code-review-multi skill.
