# Shipwright

> Two commands. Any product. Production-grade build docs in minutes.

Shipwright is a Claude Code plugin that generates detailed implementation docs for any product — from a napkin sketch to a full PRD. Feed it your idea, get back the exact docs a vibe coder or experienced developer needs to build the entire thing.

**Skill-aware:** Shipwright detects your installed Claude Code plugins and embeds skill recommendations into every session. If you have `vercel`, `superpowers`, `frontend-design`, or any other plugin — Shipwright tells you exactly when to use each skill during your build.

---

## Install

```bash
claude plugin add /path/to/shipwright
```

Or clone and install:
```bash
git clone https://github.com/v60samurai/shipwright.git
claude plugin add ./shipwright
```

---

## Commands

| Command | What It Does |
|---------|-------------|
| `/shipwright:blueprint` | Phase 1: reads your input, asks questions, generates Product Blueprint |
| `/shipwright:build` | Phase 2: reads blueprint, generates CLAUDE.md + Implementation Guide + Session Playbook + more |
| `/shipwright:status` | Show session progress (done/next/pending) |
| `/shipwright:session N` | Load a specific session with full context, ready to build |
| `/shipwright:reverse` | Reverse-engineer a blueprint from an existing codebase |

---

## Quick Start

### 1. Prepare your input

```bash
mkdir -p docs/input
```

Drop whatever you have into `docs/input/`:
- A PRD, rough idea, user journey, brand guide, wireframes, technical spec, pitch deck, or braindump
- Any level of completeness works — a 3-sentence idea is fine, a 40-page PRD is fine

### 2. Generate the Blueprint

```
/shipwright:blueprint
```

Shipwright reads your input, shows a completeness report, asks 1-3 rounds of focused questions, and outputs `docs/product-blueprint.yaml`.

Review the blueprint. Edit anything that doesn't match your vision.

### 3. Generate the Build Docs

```
/shipwright:build
```

Generates:

| Doc | Always? | Purpose |
|-----|---------|---------|
| `CLAUDE.md` | Yes | Project instructions for Claude Code |
| `Implementation-Guide.md` | Yes | Architecture, schema, code patterns, edge cases |
| `Session-Playbook.md` | Yes | Linear build sequence with exact prompts + skill recommendations |
| `Design-System.md` | Conditional | Typography, colors, components, voice |
| `Polish-Ship-Guide.md` | Conditional | Demo prep, delight, ship checklist |

### 4. Build

Load the first session:

```
/shipwright:session 1
```

Or check your progress anytime:

```
/shipwright:status
```

---

## Skill-Aware Sessions

Shipwright detects your installed plugins and embeds relevant skill recommendations into each session:

```markdown
## Session 7: Dashboard Home Screen (60-90 min)

**Skills for this session:**
- Run `frontend-design` skill for all UI components
- `react-best-practices` will auto-trigger on TSX edits
- If using shadcn: invoke `shadcn` skill for component patterns
- If stuck: `/debug` to systematically diagnose

**Claude Code prompt:**
...

**After building:**
- Run `/review` to check for issues
- Run `/commit` to create an atomic commit
```

Only skills you actually have installed are recommended — no phantom suggestions.

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

## Reverse Engineering

Already have a codebase? Generate docs for it:

```
/shipwright:reverse
```

Reads your code, package.json, schema files, config — and produces a Product Blueprint. Then run `/shipwright:build` to generate the docs.

---

## Plugin Structure

```
shipwright/
├── .claude-plugin/
│   └── plugin.json              # Plugin metadata
├── commands/
│   ├── blueprint.md             # /shipwright:blueprint
│   ├── build.md                 # /shipwright:build
│   ├── status.md                # /shipwright:status
│   ├── session.md               # /shipwright:session N
│   └── reverse.md               # /shipwright:reverse
├── skills/
│   └── shipwright/
│       ├── SKILL.md             # Auto-trigger skill
│       └── references/
│           ├── blueprint-schema.md    # Full YAML schema
│           ├── inference-rules.md     # Gap-filling inference rules
│           ├── skill-mapping.md       # Session type → skill recommendations
│           └── generator-templates.md # Doc generator templates
├── scripts/
│   ├── detect-skills.sh         # Scans installed plugins
│   └── validate-blueprint.sh    # Validates blueprint completeness
├── hooks/
│   └── hooks.json               # Auto-detect docs/input/ on session start
├── phase1-architect.md          # Standalone prompt (for non-plugin use)
├── phase2-builder.md            # Standalone prompt (for non-plugin use)
├── LICENSE
└── README.md
```

---

## Standalone Use (Without Plugin)

If you prefer raw prompts over a plugin:

```bash
mkdir -p ~/.claude/prompts
cp phase1-architect.md ~/.claude/prompts/
cp phase2-builder.md ~/.claude/prompts/
```

Then in any project:
```
Read ~/.claude/prompts/phase1-architect.md and docs/input/. Generate the product blueprint.
```
```
Read ~/.claude/prompts/phase2-builder.md and docs/product-blueprint.yaml. Generate the build docs.
```

---

## Origin

Shipwright was extracted from the doc system that powered [HustlrAI](https://github.com/harshitbadiger) — a Telegram-first CRM built in 10 hours with Claude Code. The Implementation Guide + Session Playbook pattern proved that with the right docs, anyone can build a production-grade app with AI. Shipwright templatizes that approach for any product.

---

## License

MIT — see [LICENSE](LICENSE).
