---
description: "Generate a Product Blueprint from input docs. Drop your PRD, notes, or rough idea into docs/input/ first."
---

# Phase 1: The Architect

Generate a complete Product Blueprint from whatever input the user has provided.

## Step 1: Detect Installed Skills

Run the skill detection script to capture what's available for Phase 2:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/detect-skills.sh"
```

Save the output to `docs/.shipwright-skills.json`.

## Step 2: Read All Input

Read every file in `docs/input/`. Accept any format: PRDs, rough notes, wireframes, brand guides, technical specs, pitch decks, braindumps, existing code references, user research, API docs. If `docs/input/` doesn't exist or is empty, ask the user what they want to build.

If `$ARGUMENTS` is provided, treat it as inline input (the user typed their idea directly).

## Step 3: Assess Completeness

Read `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/blueprint-schema.md` for the full schema.

Map the input against the Product Blueprint schema. For each top-level section, score it:

| Score | Meaning | Action |
|-------|---------|--------|
| **complete** | All fields fillable from input | Map directly, confirm with user |
| **partial** | Some fields need inference | Infer, present inference, ask to confirm |
| **missing** | No input for this section | Ask questions OR apply opinionated defaults |

Present the completeness report to the user showing all sections and their scores.

## Step 4: Ask Questions (Max 3 Rounds)

Read `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/inference-rules.md` for all inference rules.

Rules:
- Max 3 rounds of questions. Group related questions per round.
- Multiple-choice with recommended option when possible.
- Open-ended only for: product description, user personas, pain points, aesthetic direction.
- If user says "you decide": pick opinionated default, explain why in one line.
- Never ask about things inferable from input.

Round priority:
1. Product category, interfaces, primary user (changes everything)
2. Stack, database, auth, external services (technical decisions)
3. Design direction, voice, demo strategy (polish decisions)

## Step 5: Validate

Read `${CLAUDE_PLUGIN_ROOT}/skills/shipwright/references/blueprint-schema.md` for field requirement rules.

Structural validation:
- Every entity has at least 3 fields
- Every core feature has acceptance criteria
- Every external service has a degradation entry
- Every user journey has 3+ steps
- env_vars covers every service needing credentials
- interfaces and features are consistent
- testing.critical_paths covers every user journey
- deployment.checkpoints has at least 2 for multi-interface products

Run the validation script:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-blueprint.sh" docs/product-blueprint.yaml
```

## Step 6: Output

Write the complete blueprint to `docs/product-blueprint.yaml`.

Tell the user:

> Blueprint written to `docs/product-blueprint.yaml`.
>
> Review it — especially `features.core`, `data_model`, and `stack`. Edit anything that doesn't match your vision.
>
> When ready, run `/shipwright:build` to generate the build docs.
