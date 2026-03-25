---
description: "Generate build docs from a Product Blueprint. Run /shipwright:blueprint first."
---

# Phase 2: The Builder

Generate production-grade build docs from the Product Blueprint.

## Pre-Check

Verify `docs/product-blueprint.yaml` exists. If not, tell the user to run `/shipwright:blueprint` first.

Read the blueprint fully. Understand what's being built, who it's for, how it's built, what can go wrong, how it should feel, and how long they have.

## Load Context

Read these reference files for templates and quality rules:
- `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/generator-templates.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/skill-mapping.md`

Read `docs/.shipwright-skills.json` to know which skills/commands are installed. Only recommend skills that appear in this file.

## Generate Docs (In Order)

Generate each doc sequentially. Each doc may reference previous ones.

### Doc 1: CLAUDE.md (always)

Write to project root `CLAUDE.md`. This is the first file Claude Code reads every session.

Contents (from generator-templates.md):
- Product identity from `product.*`
- Architecture diagram from `architecture.data_flow`
- Directory structure from `interfaces + features + stack`
- Tech stack table from `stack.*`
- Conventions per language (derived from stack choices + best practices)
- Styling conventions from `design.*`
- Git conventions from `constraints.team`
- Environment variables from `env_vars.*`
- Database summary from `data_model.*`
- Deferred features from `features.deferred`
- Design context from `users.*` + `voice.*` + `design.*`

### Doc 2: Implementation Guide (always)

Write to `docs/{product.name}-Implementation-Guide.md`.

Contents (from generator-templates.md):
- Architecture Overview with ASCII diagram
- Tech Stack table with "Why" column
- System Design subsections (only include what's relevant):
  - Staged Pipeline (if multi-step processing)
  - State Machine (if multi-step flows)
  - Retry Strategy (if external services)
  - Input Validation (if user/AI input processing)
  - JSON Parse Safety (if AI output consumption)
  - Atomic Persistence (if multi-table writes)
  - Graceful Degradation table (if external services)
  - Date/Time Resolution (if scheduling)
  - State Transitions (if constrained entity states)
  - Idempotency Guard (if duplicate events possible)
  - Structured Logging (always for backends)
  - Rate Limiting (if user-facing input)
  - Realtime Recovery (if realtime subscriptions)
- Database Schema with actual DDL/ORM code
- Build Phases (one per feature cluster)
- Edge Cases tables (per interface + data)
- Environment Variables with placeholders

**Quality rules:**
- Code blocks are copy-paste ready, never pseudocode
- Every code pattern handles errors
- Every external service has retry + degradation
- Every AI integration has validation layer
- Architecture diagrams use ASCII only
- Code matches the stack's language idioms
- Uses actual entity/product names, not generic placeholders

### Doc 3: Design System (conditional)

Generate only when `design.generate_design_system: true` in blueprint.

Write to `docs/{product.name}-Design-System.md`.

Contents (from generator-templates.md):
- Visual Direction (references, anti-references, mood)
- Typography system per interface
- Color token system with actual values
- Component rules (spacing, borders, radii, shadows, motion, icons)
- Voice & Copy (personality, tone examples, error messages, empty states)
- Per-interface rules (mobile touch targets, CLI colors, etc.)
- Design principles (5-7, derived from user context)

### Doc 4: Session Playbook (always)

Write to `docs/{product.name}-Session-Playbook.md`.

**This is skill-aware.** Read `docs/.shipwright-skills.json` and `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/skill-mapping.md` to embed recommendations.

Session generation algorithm:
```
Session 1: Database/schema (always first)
Session 2: Skeleton + connectivity proof
Sessions 3..N: One feature cluster per session (ordered by dependency)
  → Checkpoint A after core features work
Sessions N+1..M: Secondary interfaces
  → Checkpoint B: full loop test
Sessions M+1..: Background jobs, integrations
Session FINAL-1: Polish + edge cases
Session FINAL: Demo prep + ship
```

Per-session template:
```markdown
## Session X: [Title] ([estimated time])

**Skills for this session:**
- [Only skills from .shipwright-skills.json that match this session type]
- [Mapped via skill-mapping.md]

**Read:** [Doc] -> "[Section name]"

**Claude Code prompt:**
[Exact prompt, copy-paste ready, references specific doc sections by name]

**Test:**
[Exact commands to verify]

**Commit:**
[git add + conventional commit message]

**Milestone check:** [What should be true now]
```

**Quality rules:**
- Only recommend installed skills (check .shipwright-skills.json)
- Every session ends with test commands and commit message
- Deployment checkpoints are gates: "Do not proceed until X works"
- Time estimates respect constraints.time
- Hardest session is flagged
- Session prompts reference doc sections by exact name

### Doc 5: Polish & Ship Guide (conditional)

Generate only when `design.generate_polish_guide: true` in blueprint.

Write to `docs/{product.name}-Polish-Ship-Guide.md`.

Contents (from generator-templates.md):
- Demo script with exact steps and timing
- Seed data (actual data structures, not descriptions)
- Delight layer per feature
- Edge state polish (loading, error, empty, offline)
- Performance targets per interface
- Ship checklist (security, performance, reliability, UX, meta)

## Completion

After generating all docs, tell the user:

> Build docs generated:
> - `CLAUDE.md`
> - `docs/{name}-Implementation-Guide.md`
> - `docs/{name}-Session-Playbook.md`
> {- `docs/{name}-Design-System.md`}
> {- `docs/{name}-Polish-Ship-Guide.md`}
>
> Start building: run `/shipwright:session 1` to load the first session.
> Track progress anytime with `/shipwright:status`.
