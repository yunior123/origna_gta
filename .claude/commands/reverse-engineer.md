# /reverse-engineer — Generate Docs from Code

**Usage**: `/reverse-engineer [$ARGUMENTS]`

Generate PRD and Design Docs from existing code. Useful for undocumented features.

## Process
1. **Trace entry points** — routes, API endpoints, screen entry
2. **Map architecture** — layers, data flow, dependencies
3. **Document behavior** — what the code does (not what it should do)
4. **Generate PRD** — user stories derived from observed behavior
5. **Generate Design Doc** — architecture, components, data flow
6. **Identify gaps** — undocumented edge cases, missing error handling

## Output
```markdown
## PRD: [Feature Name]
**User Stories**: ...
**Current Behavior**: ...
**Edge Cases Found**: ...

## Design Doc
**Architecture**: ...
**Data Flow**: ...
**Key Files**: ...
**Dependencies**: ...
```
