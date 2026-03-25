---
name: shipwright
description: >
  This skill should be used when the user asks to "generate build docs",
  "create an implementation guide", "create a session playbook",
  "generate project docs", "create build plan from PRD",
  "templatize docs", "generate implementation docs",
  "create production docs for my project",
  or mentions wanting production-grade implementation documentation,
  session-by-session build guides, or Claude Code-ready project docs.
---

# Shipwright — Build Doc Generator

Shipwright generates production-grade implementation docs for any product from any input quality. It turns a rough idea, PRD, or existing codebase into the exact docs needed to build with AI.

## Two-Phase Pipeline

### Phase 1: The Architect (`/shipwright:blueprint`)

Reads input docs from `docs/input/` and produces a normalized Product Blueprint (`docs/product-blueprint.yaml`). Handles any input quality — from a 3-sentence idea to a 40-page PRD.

- Assesses completeness per blueprint section
- Asks max 3 rounds of focused questions
- Infers missing fields with opinionated defaults
- Validates all fields before output

### Phase 2: The Builder (`/shipwright:build`)

Reads the Product Blueprint and generates build docs:

| Doc | Always? | Purpose |
|-----|---------|---------|
| `CLAUDE.md` | Yes | Project instructions for Claude Code |
| `Implementation-Guide.md` | Yes | Architecture, schema, code patterns, edge cases |
| `Session-Playbook.md` | Yes | Linear build sequence with exact prompts |
| `Design-System.md` | Conditional | Typography, colors, component rules, voice |
| `Polish-Ship-Guide.md` | Conditional | Demo prep, delight layer, ship checklist |

Session Playbook is **skill-aware** — it detects installed Claude Code skills/plugins and embeds recommendations into each session.

## Additional Commands

| Command | Purpose |
|---------|---------|
| `/shipwright:status` | Show session progress (done/next/pending) |
| `/shipwright:session N` | Load a specific session with full context |
| `/shipwright:reverse` | Reverse-engineer blueprint from existing codebase |

## When to Use Which Command

- Starting a new project from scratch → `/shipwright:blueprint` then `/shipwright:build`
- Documenting an existing codebase → `/shipwright:reverse` then `/shipwright:build`
- Mid-build, need current session → `/shipwright:session N`
- Check progress → `/shipwright:status`

## Reference Files

For detailed information, consult:
- **`references/blueprint-schema.md`** — Full Product Blueprint YAML schema with field descriptions
- **`references/inference-rules.md`** — All inference rules for filling blueprint gaps
- **`references/skill-mapping.md`** — Session type to skill/command recommendations
- **`references/generator-templates.md`** — Doc generator templates and quality rules
