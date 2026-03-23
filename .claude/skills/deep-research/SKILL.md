---
name: deep-research
description: "Multi-source deep research combining web search, documentation, codebase analysis, and memory recall. Produces structured findings with confidence levels and sources. Use for technical decisions, library evaluation, or problem investigation."
---

# Deep Research

Multi-source research workflow that synthesizes information from web, documentation, codebase, and memory into a structured report with confidence levels.

## When to Use

- Evaluating a library, framework, or tool for the project
- Investigating a technical problem with unclear root cause
- Making architecture decisions that need evidence
- Comparing approaches or solutions
- Understanding unfamiliar APIs or protocols

## Workflow

### Step 1: Define the Research Question

Clarify the research question with the user. A good research question is:
- Specific enough to search for
- Scoped to a decision or problem
- Has clear success criteria

Example: "Should we use `riverpod_generator` for code generation?" not "Tell me about Riverpod."

### Step 2: Search Multiple Sources in Parallel

Launch searches across all available sources simultaneously. Do not wait for one to finish before starting another.

#### Source A: Web Search
Use WebSearch for recent information, blog posts, Stack Overflow, GitHub issues.
- Search 2-3 variations of the query
- Prioritize results from the last 12 months

#### Source B: WebFetch
Use WebFetch for specific URLs the user provides or that appear in search results.
- Official documentation pages
- GitHub READMEs and changelogs
- Relevant issue threads

#### Source C: Context7 (Library Documentation)
Use Context7 MCP for library-specific documentation.
- `resolve-library-id` first, then `query-docs`
- Get API signatures, usage examples, version compatibility

#### Source D: Pinecone (Semantic Memory)
Use Pinecone MCP to search for relevant past findings.
- Search with the research question as query
- Check if this topic was researched before

#### Source E: Codebase Context
Use Grep and Glob to understand current usage in the project.
- How is the relevant code currently structured?
- Are there existing patterns or conventions?
- What dependencies are already in use?

#### Source F: Memory Files
Read relevant memory files:
- `~/.claude/projects/-Users-yuniorrodriguezosorio/memory/MEMORY.md`
- Topic-specific files referenced in MEMORY.md

### Step 3: Cross-Reference Findings

Compare information across sources:
- Do sources agree? Flag contradictions.
- Is information current? Flag outdated findings.
- Is the source authoritative? Prefer official docs over blog posts.
- Does it apply to our stack? (Flutter/Dart, Rust, 8GB RAM Mac, etc.)

### Step 4: Synthesize Report

Produce a structured report in this format:

```markdown
## Research Report: [Question]

### Key Findings

1. **[Finding title]** — [1-2 sentence summary]
   - Confidence: HIGH/MEDIUM/LOW
   - Sources: [URL or file path]

2. **[Finding title]** — [1-2 sentence summary]
   - Confidence: HIGH/MEDIUM/LOW
   - Sources: [URL or file path]

### Contradictions / Caveats
- [Any conflicting information between sources]

### Relevance to origna_gta
- [How findings apply to this specific project]
- [Compatibility with current stack: Flutter, Riverpod, Rust, 8GB RAM]

### Recommendations
1. [Actionable recommendation with rationale]
2. [Actionable recommendation with rationale]

### Sources
| # | Source | URL/Path | Date | Reliability |
|---|--------|----------|------|-------------|
| 1 | Official Docs | https://... | 2026-03 | HIGH |
| 2 | GitHub Issue | https://... | 2026-01 | MEDIUM |
```

### Step 5: Save Key Findings

If the research produced stable facts relevant to the project:

1. Append key findings to MEMORY.md (use Edit, never overwrite)
2. If findings are substantial, create a topic file:
   `~/.claude/projects/-Users-yuniorrodriguezosorio/memory/research_[topic]_[date].md`
3. Run `ai-sync` to propagate knowledge

### Confidence Levels

| Level | Meaning |
|-------|---------|
| **HIGH** | Multiple authoritative sources agree, verified in codebase or official docs |
| **MEDIUM** | Single authoritative source, or multiple non-authoritative sources agree |
| **LOW** | Single non-authoritative source, outdated info, or extrapolation from related topics |

## Tips

- Always check the date of sources — Flutter/Dart ecosystem moves fast
- If a finding contradicts project CLAUDE.md rules, flag it but defer to CLAUDE.md
- For library evaluation, always check: bundle size impact, 8GB RAM compatibility, Dart 3 support
- Prefer solutions that don't add new dependencies
