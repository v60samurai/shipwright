# Shipwright

> Two prompts. Any product. Production-grade build docs in minutes.

Shipwright is a two-phase prompt system for Claude Code (or any AI coding tool) that generates detailed implementation docs for any product -- from a napkin sketch to a full PRD. Feed it your idea, get back the exact docs a vibe coder or experienced developer needs to build the entire thing.

---

## The Problem

Building with AI requires incredibly detailed implementation docs -- architecture diagrams, database schemas, code patterns, session-by-session build sequences. Without them, AI produces mediocre, inconsistent output. Writing these docs manually takes days and deep engineering experience.

## The Solution

Shipwright splits the work into two phases:

**Phase 1: The Architect** reads whatever you have (PRD, rough idea, user journey, brand guide, existing code) and produces a structured **Product Blueprint** -- a normalized YAML spec that captures every technical and design decision.

**Phase 2: The Builder** reads the Product Blueprint and generates 2-4 production-grade build docs:

| Doc | Always? | What It Is |
|-----|---------|------------|
| `CLAUDE.md` | Yes | Project instructions for Claude Code -- stack, conventions, file structure |
| `Implementation-Guide.md` | Yes | Architecture, database schema, code patterns, edge cases, error handling |
| `Session-Playbook.md` | Yes | Linear build sequence with exact Claude Code prompts, test commands, commit messages |
| `Design-System.md` | Conditional | Typography, colors, component rules, voice and copy system |
| `Polish-Ship-Guide.md` | Conditional | Demo prep, seed data, delight layer, ship checklist |

---

## Quick Start

### 1. Install the prompts

Copy the two prompt files to your Claude Code prompts directory:

```bash
mkdir -p ~/.claude/prompts
cp phase1-architect.md ~/.claude/prompts/
cp phase2-builder.md ~/.claude/prompts/
```

### 2. Prepare your input

Create a new project and drop whatever you have into `docs/input/`:

```bash
mkdir -p my-project/docs/input
```

Put any of these into `docs/input/`:
- A PRD (product requirements document)
- A rough idea written in plain English
- User journey maps
- Brand guidelines
- Wireframe descriptions
- Technical specs
- Competitor analysis notes
- Pain points and user research
- An existing codebase you want to build on top of

**Any level of completeness works.** A 3-sentence idea is fine. A 40-page PRD is fine. Shipwright adapts.

### 3. Run Phase 1: Generate the Blueprint

Open Claude Code in your project directory:

```
Read ~/.claude/prompts/phase1-architect.md and the files in docs/input/. Generate the product blueprint.
```

Phase 1 will:
1. Read all your input files
2. Show a completeness report (what it found, what's missing)
3. Ask 1-3 rounds of focused questions to fill gaps
4. Make opinionated defaults for anything you say "you decide"
5. Output `docs/product-blueprint.yaml` -- a complete, structured spec

**Review the blueprint.** Edit anything that doesn't match your vision -- especially `features.core`, `data_model`, and `stack`.

### 4. Run Phase 2: Generate the Build Docs

```
Read ~/.claude/prompts/phase2-builder.md and docs/product-blueprint.yaml. Generate the build docs.
```

Phase 2 generates all the docs. This takes a few minutes.

### 5. Build

Open the Session Playbook and follow it session by session. Each session has:
- **Read:** which doc sections to reference
- **Claude Code prompt:** exact prompt to copy-paste
- **Test:** exact commands to verify
- **Commit:** commit message

---

## What Products Can This Build?

Anything. The Product Blueprint schema supports:

| Category | Examples |
|----------|----------|
| B2B SaaS | CRM, project management, analytics dashboard |
| B2C App | Social, fitness, food delivery, dating |
| D2C Commerce | Storefront, subscription box, marketplace |
| Dev Tool | CLI, VS Code extension, MCP server, SDK |
| API Service | REST API, GraphQL, webhook processor |
| Bot | Telegram, Discord, Slack, WhatsApp |
| Mobile | PWA, React Native, Flutter, native iOS/Android |
| Desktop | Electron, Tauri, native macOS/Windows |
| AI Agent | Extraction pipeline, chatbot, workflow automation |
| Game | Web game, Unity, Godot |
| IoT | Embedded firmware, hardware-software bridge |
| Internal Tool | Admin panel, dashboard, automation script |

---

## File Reference

```
shipwright/
  phase1-architect.md     # Phase 1 prompt: input -> Product Blueprint
  phase2-builder.md       # Phase 2 prompt: blueprint -> build docs
  design-spec.md          # Design spec documenting the system
  LICENSE                 # MIT
  README.md               # You are here
```

### phase1-architect.md (The Architect)

The Architect's job is normalization. It takes messy, incomplete, or overly ambitious input and produces a precise, buildable Product Blueprint.

Key behaviors:
- **Reads anything:** PRDs, rough notes, existing code, wireframes, pitch decks
- **Assesses completeness:** scores each blueprint section as complete, partial, or missing
- **Asks focused questions:** max 3 rounds, multiple-choice preferred, groups related topics
- **Infers intelligently:** ~40 inference rules for filling gaps (e.g., B2C app with no interface specified defaults to PWA + mobile-first)
- **Validates before output:** every entity has fields, every feature has acceptance criteria, every external service has a degradation strategy

### phase2-builder.md (The Builder)

The Builder's job is generation. It reads the structured blueprint and produces docs so detailed that an AI can build the entire system without asking questions.

Key behaviors:
- **Code is copy-paste ready:** real function signatures, real error handling, real types. Never pseudocode.
- **Every session has a test:** not "verify it works" -- exact commands and expected output
- **Deployment checkpoints as gates:** "do not proceed until X works on live infrastructure"
- **Stack-native:** Python backend gets Python examples. TypeScript gets TypeScript idioms.
- **Opinionated:** one way to do things. The right way. No "you could also..."

### Product Blueprint Schema

The blueprint is a YAML file with these sections:

| Section | What It Captures |
|---------|-----------------|
| `product` | Name, tagline, category, stage |
| `users` | Primary persona, pain points, usage context |
| `interfaces` | Every interface (web, mobile, bot, CLI, API, etc.) with platform-specific config |
| `architecture` | Pattern, data flow, external services, background jobs, realtime needs |
| `stack` | Frontend, backend, database, auth, hosting, AI, key libraries |
| `data_model` | Entities with fields, relationships, access patterns, enums, views, RLS |
| `features` | Core features with acceptance criteria, deferred features |
| `user_journeys` | Step-by-step flows through the product |
| `design` | Aesthetic direction, colors, typography, component rules |
| `resilience` | Degradation table, retry strategies, data loss prevention |
| `voice` | Personality, tone examples, error/empty state copy, aha moment |
| `demo` | Seed data, demo script, pre-demo checklist |
| `env_vars` | Every environment variable per environment |
| `testing` | Strategy, frameworks, critical paths |
| `deployment` | Strategy, environments, pipeline, checkpoints |
| `constraints` | Time, team, forbidden patterns, hard requirements |

---

## Examples

### Minimal input (napkin sketch)

```
docs/input/idea.md:
  "I want to build a Telegram bot that tracks my reading habits.
   I send it a book title when I start/finish, it tracks my stats.
   Simple web dashboard to see my reading history and streaks."
```

Phase 1 will infer: bot-telegram + web-app, Python backend, Supabase, dark mode dashboard, etc. It'll ask 2-3 questions about features and design preference.

### Detailed input (full PRD)

```
docs/input/prd.md           # 20-page PRD with user stories
docs/input/brand-guide.md   # Typography, colors, voice
docs/input/user-research.md # Interview transcripts, pain points
docs/input/wireframes.md    # Screen descriptions
```

Phase 1 will map everything directly, confirm a few technical decisions, and output the blueprint with 0-1 rounds of questions.

---

## Tips

- **Edit the blueprint.** Phase 1 is smart but not omniscient. Review `product-blueprint.yaml` before running Phase 2, especially the `features.core` and `data_model` sections.
- **"You decide" is valid.** If Phase 1 asks a question you don't have an opinion on, say "you decide." It'll pick a sensible default and explain why.
- **Re-run Phase 2 after edits.** Changed your mind about the stack? Edit the blueprint and re-run Phase 2. The docs regenerate in minutes.
- **Session Playbook is linear.** Follow it in order. Don't skip sessions. Don't jump ahead. Each session builds on the previous one.
- **Checkpoints are gates.** When the playbook says "do not proceed until X works," it means it. Bugs found later are 10x harder to fix than bugs found at checkpoints.

---

## Origin

Shipwright was extracted from the doc system that powered the build of [HustlrAI](https://github.com/harshitbadiger) -- a Telegram-first CRM built in 10 hours with Claude Code. The Implementation Guide + Session Playbook pattern proved that with the right docs, anyone can build a production-grade app with AI. Shipwright templatizes that pattern for any product.

---

## License

MIT -- see [LICENSE](LICENSE).
