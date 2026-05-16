---
description: "Generate build docs from a Product Blueprint. Run /shipwright:blueprint first."
---

# Phase 2: The Builder

Generate production-grade build docs from the Product Blueprint by filling in the actual template files.

## Pre-Check

Verify `docs/product-blueprint.yaml` exists. If not, tell the user to run `/shipwright:blueprint` first and stop.

Read `docs/product-blueprint.yaml` fully. Understand everything in it before generating any doc.

## Load Templates

Read these template files — they are the exact output structure for each doc:

- `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/templates/IMPLEMENTATION_GUIDE.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/templates/SESSION_PLAYBOOK.md`
- `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/templates/FINAL_PUSH.md`

Also read for skill-aware session generation:
- `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/skill-mapping.md`
- `docs/.shipwright-skills.json` (if it exists — lists installed plugins for skill recommendations)

## How to Fill Templates

Every `{{PLACEHOLDER}}` in a template must be replaced with a real value derived from the blueprint. Rules:

1. **Never leave a placeholder unfilled.** If the blueprint doesn't have the value, infer it from context or make an opinionated choice.
2. **Never write placeholder text in the output.** No `{{PRODUCT_NAME}}`, no `TBD`, no `fill this in later`.
3. **Use actual entity names.** Not "User" and "Item" — the real names from the blueprint.
4. **Code blocks are copy-paste ready.** Real function signatures, real types, real error handling. Never pseudocode.
5. **Architecture diagrams use ASCII only.** No image references.

## Generate Docs (In Order)

### Doc 1: CLAUDE.md (always)

Write to project root `CLAUDE.md`.

Structure:
- What this is: product tagline + 2-3 sentences on what it does, who it's for, how interfaces connect
- Architecture: ASCII diagram showing all interfaces, data flow, external services
- Monorepo structure: full directory tree with key files
- Tech stack table: Layer | Technology | Notes
- Conventions per language/runtime in the stack
- Environment variables table per environment
- Database summary (tables count, ORM, RLS strategy)
- Deferred features list
- Design context (users, brand personality, aesthetic direction)

Note at top: "This file is the project-level Claude Code context. It extends the global CLAUDE.md — only project-specific rules live here."

If the blueprint has `design.persona_file_path`, add a Persona File section:
```
## Persona File
[persona_file_path] is the product's AI voice — loaded as the AI system prompt at runtime.
CLAUDE.md (this file) is the developer context for Claude Code.
Do not confuse them.
```

### Doc 2: Implementation Guide (always)

Read `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/templates/IMPLEMENTATION_GUIDE.md`.

Fill every `{{PLACEHOLDER}}` from the blueprint. Key substitutions:
- `{{PRODUCT_NAME}}` → `product.name`
- `{{DATE}}` → today's date
- `{{ARCHITECTURE_SUMMARY}}` → one-line from `architecture.data_flow`
- `{{STACK_SUMMARY}}` → comma-separated from `stack.*`
- `{{ARCHITECTURE_DIAGRAM}}` → ASCII diagram from `architecture.data_flow`
- All `{{INTERFACE_N}}`, `{{BACKEND_LAYER}}`, `{{DATABASE}}` → actual names from blueprint
- All `{{choice}}` and `{{reason}}` in decision log → actual decisions from `stack.*`
- All `{{entity}}`, `{{field}}`, `{{type}}` in schema → actual entities from `data_model.*`

Write to `docs/{product.name}-Implementation-Guide.md`.

### Doc 3: Session Playbook (always)

Read `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/templates/SESSION_PLAYBOOK.md`.

Fill every `{{PLACEHOLDER}}`. Key additions beyond the template:

**Session generation:** Create one session per feature cluster from the blueprint, ordered by dependency. Every session must have:
- An exact Claude Code prompt (copy-paste ready, references specific IG sections by name)
- A test step with exact commands
- A commit step with conventional commit message
- A done-check: specific things that must be true before next session

**Skill-aware sessions:** If `docs/.shipwright-skills.json` exists, check `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/skill-mapping.md` and embed relevant skill recommendations into each session. Only recommend skills that appear in the JSON file.

Write to `docs/{product.name}-Session-Playbook.md`.

### Doc 4: Final Push Guide (conditional)

Generate only when `design.generate_polish_guide: true` in blueprint.

Read `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/templates/FINAL_PUSH.md`.

Fill every `{{PLACEHOLDER}}` with actual product-specific content. Key substitutions:
- Kill shot demo script: based on `demo.demo_script` from blueprint
- Seed data: based on `demo.seed_data_description` — write actual data structures
- Milestone messages: based on product's core loop and `voice.personality`
- All color/style references: from `design.*` tokens

Write to `docs/{product.name}-Final-Push-Guide.md`.

## Completion

After generating all docs, tell the user:

> Build docs generated:
> - `CLAUDE.md`
> - `docs/{name}-Implementation-Guide.md`
> - `docs/{name}-Session-Playbook.md`
> {- `docs/{name}-Final-Push-Guide.md`}
>
> Next: `/shipwright:session 1` to load the first session and start building.
> Track progress anytime with `/shipwright:status`.
