# Build Doc Generator — Design Spec

> A two-phase Claude Code prompt system that generates production-grade implementation docs for any product, from any input quality.

---

## Problem

Building a product end-to-end with AI (Claude Code, Cursor, etc.) requires extremely detailed implementation docs — architecture, code patterns, session-by-session build sequences, design systems. Writing these docs manually takes days and requires deep engineering experience. Most people skip them and get mediocre output from AI.

HustlrAI proved that with the right docs (Implementation Guide + Session Playbook + Brand Guide + Final Push), a vibe coder can build a production-grade app in 10 hours. This system templatizes that approach for any product.

## Solution

Two prompt files that work as a pipeline:

1. **Phase 1: The Architect** — reads any input (PRD, rough idea, user journey, wireframes, existing code) and produces a normalized Product Blueprint (YAML)
2. **Phase 2: The Builder** — reads the Product Blueprint and generates 2-4 build docs + a project CLAUDE.md

## Target Users

- **Vibe coders** — non-technical or semi-technical builders who direct AI to write all code. Need maximum detail: exact code patterns, copy-paste prompts, test commands.
- **Experienced developers using AI** — know how to code, use AI to accelerate. Can skip sections, appreciate the architecture and session structure.

The docs work for both because they're structured: detailed enough for vibe coders to follow blindly, organized enough for devs to jump to what they need.

## Product Agnosticism

This system generates docs for ANY product: B2B SaaS, B2C app, D2C commerce, marketplace, dev tool, API service, internal tool, IoT, CLI, mobile app, browser extension, AI agent, game, AR/VR — anything that can be built with code.

The Product Blueprint schema is the universal normalizer. Every product, regardless of type, gets described in the same structured format. Phase 2's generators adapt their output based on what's in the blueprint.

---

## Architecture

```
USER INPUT (any quality)
    │
    ▼
Phase 1: The Architect (phase1-architect.md)
    │  - Reads docs/input/*
    │  - Scores completeness per section
    │  - Asks max 3 rounds of questions
    │  - Infers missing fields with opinionated defaults
    │  - Validates all fields filled
    │
    ▼
Product Blueprint (docs/product-blueprint.yaml)
    │  - Normalized intermediate format
    │  - Every field has a value
    │  - User can review/edit before Phase 2
    │
    ▼
Phase 2: The Builder (phase2-builder.md)
    │  - Reads blueprint
    │  - Reasons about engineering decisions
    │  - Generates docs adapted to the product
    │
    ▼
Output Docs (docs/)
    ├── CLAUDE.md (always)
    ├── Implementation-Guide.md (always)
    ├── Session-Playbook.md (always)
    ├── Design-System.md (conditional)
    └── Polish-Ship-Guide.md (conditional)
```

---

## Product Blueprint Schema

The normalized intermediate format. Every field must be filled before Phase 2 runs.

```yaml
# Product Blueprint v1

product:
  name: ""
  tagline: ""                    # One sentence: what it does for whom
  category: ""                   # b2b-saas | b2c-app | d2c-commerce | marketplace | dev-tool | api-service | internal-tool | hardware-software | game | ar-vr | other
  stage: ""                      # mvp | v1 | feature-addition | rebuild

users:
  primary_persona: ""            # Who, role, context, skill level
  secondary_personas: []
  usage_context: ""              # When/where/how they use it
  pain_points: []

interfaces:
  - type: ""                     # web-app | pwa | spa | static-site |
                                 # native-ios | native-android | react-native | flutter | kotlin-multiplatform |
                                 # desktop-electron | desktop-tauri | desktop-native |
                                 # cli | tui |
                                 # api-rest | api-graphql | api-grpc |
                                 # bot-telegram | bot-discord | bot-slack | bot-whatsapp | bot-generic |
                                 # browser-extension | vscode-extension |
                                 # embedded-iot | hardware-firmware |
                                 # chrome-app | smart-tv | wearable |
                                 # game | ar-vr |
                                 # wordpress-plugin | shopify-app | saas-plugin |
                                 # mcp-server | ai-agent |
                                 # other
    role: ""                     # primary-input | primary-consumption | admin | background | companion
    description: ""
    platform_specific:
      mobile:
        install_strategy: ""
        offline_strategy: ""
        safe_areas: bool
        native_features: []
        primary_hand: ""
      desktop:
        window_management: ""
        system_tray: bool
        auto_update: bool
        os_targets: []
      cli:
        package_manager: ""
        shell_completions: bool
        config_format: ""
      embedded:
        target_hardware: ""
        connectivity: ""
        power_constraints: ""
      extension:
        host_app: ""
        permissions: []

architecture:
  pattern: ""                    # monolith | client-server | microservices | serverless | jamstack | event-driven
  data_flow: ""                  # How data moves through the system (plain English)
  external_services: []          # Third-party APIs, AI models, payment processors
  background_jobs: []
  realtime_needs: ""

stack:
  frontend: {}
  backend: {}
  database: {}
  auth: {}
  hosting: {}
  ai: {}
  key_libraries: []

data_model:
  entities: []                   # name, key fields, relationships, access patterns
  enums: []
  views: []
  rls_strategy: ""

features:
  core: []                       # name, description, acceptance criteria
  deferred: []

user_journeys:
  - name: ""
    steps: []

design:
  generate_design_system: bool
  generate_polish_guide: bool
  aesthetic_direction: ""
  color_strategy: ""
  typography_strategy: ""
  key_rules: []

resilience:
  degradation_table: []          # Per service: failure mode, fallback, user-facing message
  retry_strategies: []
  data_loss_prevention: ""

voice:
  personality: ""
  tone_examples: []
  forbidden_language: []
  error_message_style: ""
  empty_state_style: ""
  aha_moment: ""

demo:
  seed_data_description: ""
  demo_script: ""
  pre_demo_checklist: []

env_vars:
  backend: []                    # name, description, source, secret: bool
  frontend: []
  ci_cd: []

testing:
  strategy: ""                   # manual-first | tdd | integration-heavy | e2e-only
  smoke_test_per_session: bool
  test_frameworks: []
  critical_paths: []

deployment:
  strategy: ""
  environments: []
  ci_cd: ""
  checkpoints: []

constraints:
  time: ""
  team: ""
  forbidden_patterns: []
  hard_requirements: []
```

---

## Phase 1: The Architect

### Behavior

1. Read all files in `docs/input/`
2. Score each blueprint section: complete | partial | missing
3. Present completeness report
4. For complete sections: map directly, confirm
5. For partial sections: infer, present inference, ask to confirm/correct
6. For missing sections: ask focused questions (max 3 rounds, multiple-choice preferred)
7. Make opinionated defaults for anything user says "you decide"
8. Output: `docs/product-blueprint.yaml` with every field filled

### Inference Rules (~40 rules)

Examples:
- If category=b2c and no interface specified → default PWA + mobile-first
- If AI/LLM mentioned anywhere → add `ai` section to stack, suggest extraction/generation patterns
- If "real-time" or "live" mentioned → add websocket/SSE to architecture
- If no design preferences stated → dark mode, system font stack, one accent color
- If category=api-service → set `generate_design_system: false`, `generate_polish_guide: false`
- If "bot" in interfaces → add state machine to system design
- If multiple interfaces → add deployment checkpoints between them
- If time <= "1 weekend" → compress features, suggest cutting deferred items
- If no auth mentioned but user data exists → suggest auth, ask to confirm

### Question Protocol

- Max 3 rounds of questions
- Group related questions (don't mix "what database?" with "what color scheme?")
- Multiple-choice with recommended option when possible
- Open-ended only for: product description, user personas, pain points
- If user says "you decide" or "whatever works": pick opinionated default, explain why in a one-liner

---

## Phase 2: The Builder

### CLAUDE.md Generator

Always generated first. Maps from blueprint:
- `product` → project identity section
- `stack` → tech stack section
- `constraints.forbidden_patterns` → forbidden patterns
- `interfaces + features` → file structure
- `env_vars` → environment variables section
- Conventions auto-derived from stack choices

### Implementation Guide Generator

Section mapping:
- `architecture` → Architecture Overview with ASCII diagram
- `stack` → Tech Stack table with "Why" reasoning
- `architecture + external_services` → System Design subsections:
  - Per external service: retry strategy, degradation table
  - State machines (if multi-step flows detected)
  - Data validation patterns
  - Idempotency guards
  - Realtime/sync strategy
- `data_model` → Database Schema with actual DDL/ORM code
- `features.core` → Build Phases, each with:
  - Description and files to create
  - Code patterns (copy-paste ready, with error handling)
  - Edge cases
- Auto-generated edge cases table from features + external services

### Session Playbook Generator

Session generation algorithm:
```
Session 1: Database/schema setup (always first)
Session 2: Skeleton + connectivity proof (simplest interface working end-to-end)
Sessions 3..N: One feature cluster per session (ordered by dependency)
  → Insert Checkpoint A after core features work
Sessions N+1..M: Secondary interfaces, consumption layers
  → Insert Checkpoint B: full loop test
Sessions M+1..: Background jobs, integrations
Session FINAL-1: Polish + edge cases
Session FINAL: Demo prep + ship
```

Per-session template:
```markdown
## Session X: [Title] ([estimated time])

**Read:** [Doc] → "[Section name]"

**Claude Code prompt:**
[Exact prompt, copy-paste ready, references specific doc sections]

**Test:**
[Exact commands to verify the session's output]

**Commit:**
[git add + commit message]

**Milestone check:** [What should be true after this session]
```

Time allocation: `constraints.time / session_count`, with harder sessions getting more time.

### Design System Generator (conditional)

Generated when `design.generate_design_system: true`.

Maps from:
- `design.aesthetic_direction` → references, anti-references, mood
- `design.color_strategy` → full token system with hex/rgba values
- `design.typography_strategy` → font stack, type scale, loading method
- `design.key_rules` → hard constraints (radii, spacing grid, motion rules)
- `interfaces` → per-interface rules (touch targets, CLI colors, etc.)
- `voice` → copy system (error messages, empty states, personality)

### Polish & Ship Guide Generator (conditional)

Generated when `design.generate_polish_guide: true`.

Maps from:
- `demo` → demo script with exact steps
- `demo.seed_data_description` → actual seed data/commands
- `features.core` → delight layer per feature (milestones, micro-interactions)
- `user_journeys` → pre-ship verification (every journey step becomes a checklist item)
- Edge state polish: empty states, error states, loading states, offline states

---

## Output Files

| File | Always? | Purpose |
|------|---------|---------|
| `docs/product-blueprint.yaml` | Yes (Phase 1) | Normalized product spec, editable |
| `CLAUDE.md` | Yes (Phase 2) | Project instructions for Claude Code |
| `docs/Implementation-Guide.md` | Yes (Phase 2) | Architecture, schema, code patterns, edge cases |
| `docs/Session-Playbook.md` | Yes (Phase 2) | Linear build sequence with exact prompts |
| `docs/Design-System.md` | Conditional | Typography, colors, component rules, voice |
| `docs/Polish-Ship-Guide.md` | Conditional | Demo prep, delight layer, ship checklist |

---

## Workflow

1. Create project directory, add `docs/input/` with whatever you have (PRD, notes, wireframes, existing code)
2. Open Claude Code: `"Read ~/.claude/prompts/phase1-architect.md and the files in docs/input/. Generate the product blueprint."`
3. Answer 1-3 rounds of clarifying questions
4. Review `docs/product-blueprint.yaml`, edit if needed
5. `"Read ~/.claude/prompts/phase2-builder.md and docs/product-blueprint.yaml. Generate the build docs."`
6. Build by following `docs/Session-Playbook.md` session by session

---

## Quality Bars (enforced by Phase 2)

- Code blocks are copy-paste ready, never pseudocode
- Every code pattern handles errors and edge cases
- Every session ends with test commands and a commit message
- Deployment checkpoints inserted after every 3-4 sessions
- Every external service has a degradation strategy
- Every user-facing state is accounted for: loading, error, empty, data, offline
- Session prompts reference specific doc sections (not "see the implementation guide")
- Time estimates per session respect the total time constraint

---

## What This Is NOT

- Not a code generator — it generates DOCS that guide a human+AI to build
- Not a project scaffolder — it doesn't create files, it describes what files to create
- Not opinionated about stack — it works with whatever stack the user chooses
- Not a substitute for product thinking — it needs real input about what to build and why
