# /deep-research — Multi-Source Deep Research

**Usage**: `/deep-research $ARGUMENTS`

Research a topic using multiple sources and produce a structured report.

## Process

1. **Define question** — Clarify the research question from `$ARGUMENTS`

2. **Search in parallel**:
   - WebSearch for recent info and trends
   - WebFetch for specific documentation URLs
   - Context7 for library documentation
   - Pinecone for relevant memory entries
   - Grep/Glob for codebase context

3. **Cross-reference** — Compare findings across sources

4. **Synthesize report**:
```
## Research: [Topic]

### Key Findings
- Finding 1 [HIGH confidence] — Source: ...
- Finding 2 [MEDIUM confidence] — Source: ...

### Sources
- [Source 1](url)
- [Source 2](url)

### Recommendations
1. Actionable recommendation
2. ...

### Open Questions
- What remains unclear
```

5. **Save to memory** — Auto-save key findings to MEMORY.md if significant
