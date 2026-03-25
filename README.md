# Shipwright

> Any idea. Any product. Production-grade build docs in minutes.

Shipwright generates detailed implementation docs for any product — from a napkin sketch to a full PRD. Feed it your idea, get back the exact docs a vibe coder or experienced developer needs to build the entire thing.

**Two ways to use it:**

| | Plugin (Recommended) | Standalone Prompts |
|-|---------------------|-------------------|
| **Install** | `claude plugin add ./shipwright` | Copy 2 files to `~/.claude/prompts/` |
| **Invoke** | `/shipwright:blueprint` | Paste a one-liner into Claude Code |
| **Skill-aware** | Yes — detects installed plugins, embeds skill recs per session | No — generic prompts only |
| **Session tracking** | `/shipwright:status` shows progress | Manual (check git log) |
| **Session loader** | `/shipwright:session 3` loads full context | Manual (scroll the playbook) |
| **Reverse-engineer** | `/shipwright:reverse` reads existing code | Not available |
| **Works with** | Claude Code only | Any AI tool (Claude Code, Cursor, Windsurf, etc.) |

Pick whichever fits your workflow. Both produce the same quality docs.

---

## Route 1: Plugin (Full Experience)

### Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code/overview) installed and working (`claude` command available in terminal)
- Access to this private repository (you need to be a collaborator or the owner)
- Authentication set up for GitHub (SSH key or Personal Access Token)

### Authenticating with GitHub (Private Repo)

This is a private repository. You need one of these auth methods configured before cloning:

**Option A: SSH Key (recommended)**

```bash
# Check if you have an SSH key
ls ~/.ssh/id_ed25519.pub 2>/dev/null || ls ~/.ssh/id_rsa.pub 2>/dev/null

# If not, generate one
ssh-keygen -t ed25519 -C "your_email@example.com"

# Copy the public key
cat ~/.ssh/id_ed25519.pub | pbcopy   # macOS
cat ~/.ssh/id_ed25519.pub | xclip    # Linux

# Add it to GitHub: Settings → SSH and GPG keys → New SSH key → paste
# Test it works
ssh -T git@github.com
```

**Option B: Personal Access Token (PAT)**

```bash
# Generate a token: GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
# Select scope: repo (full control of private repositories)
# Copy the token — you'll use it as your password when cloning via HTTPS
```

### Install

**Option A: Clone via SSH and install locally (recommended)**

```bash
git clone git@github.com:v60samurai/shipwright.git ~/shipwright
claude plugin add ~/shipwright
```

**Option B: Clone via HTTPS with PAT**

```bash
# When prompted for password, paste your Personal Access Token
git clone https://github.com/v60samurai/shipwright.git ~/shipwright
claude plugin add ~/shipwright
```

**Option C: Clone via HTTPS with token inline**

```bash
git clone https://<YOUR_PAT>@github.com/v60samurai/shipwright.git ~/shipwright
claude plugin add ~/shipwright
```

> **Note:** Replace `<YOUR_PAT>` with your actual Personal Access Token. Do not commit this token anywhere.

### Verify Installation

Open Claude Code in any project and run:

```
/shipwright:status
```

If you see a response (even "no session playbook found"), the plugin is installed correctly. If the command isn't recognized, restart Claude Code and try again.

### Uninstall

```bash
claude plugin remove shipwright
```

### How Plugins Work in Claude Code

Claude Code plugins extend Claude's capabilities with custom commands, skills, and hooks:

- **Commands** (`/shipwright:blueprint`, etc.) are slash commands you type in the Claude Code prompt. They load specialized instructions that guide Claude through a specific workflow.
- **Skills** auto-trigger when Claude detects relevant context. The Shipwright skill activates when you mention "generate build docs" or "implementation guide" without using a slash command.
- **Hooks** run automatically on events. Shipwright's hook fires on session start — if it finds `docs/input/` without a blueprint, it reminds you to run `/shipwright:blueprint`.
- **Scripts** are shell utilities the plugin uses internally (skill detection, blueprint validation). You don't run these directly.

Plugins are local — they run on your machine, not in the cloud. The plugin reads your files and generates docs in your project directory.

### Commands

| Command | What It Does |
|---------|-------------|
| `/shipwright:blueprint` | Phase 1: reads your input, asks questions, generates Product Blueprint |
| `/shipwright:build` | Phase 2: reads blueprint, generates CLAUDE.md + Implementation Guide + Session Playbook + more |
| `/shipwright:status` | Show session progress (done/next/pending via git log) |
| `/shipwright:session N` | Load a specific session with full context, ready to build |
| `/shipwright:reverse` | Reverse-engineer a blueprint from an existing codebase |

### Workflow

```
1. mkdir -p docs/input && [drop your PRD/idea/notes there]
2. /shipwright:blueprint        → generates docs/product-blueprint.yaml
3. Review the blueprint, edit if needed
4. /shipwright:build            → generates all build docs
5. /shipwright:session 1        → load first session, start building
6. /shipwright:status           → check progress anytime
```

### Skill-Aware Sessions

The plugin detects your installed Claude Code plugins and weaves relevant skills into each session:

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

## Route 2: Standalone Prompts (Universal)

Works with any AI coding tool — Claude Code, Cursor, Windsurf, Copilot, or anything that reads markdown prompts. No plugin system required.

### Install

Since this is a private repo, clone it first (using the same auth method from Route 1), then copy the prompt files:

**Option A: Clone via SSH and copy**

```bash
git clone git@github.com:v60samurai/shipwright.git ~/shipwright

mkdir -p ~/.claude/prompts
cp ~/shipwright/phase1-architect.md ~/.claude/prompts/
cp ~/shipwright/phase2-builder.md ~/.claude/prompts/
```

**Option B: Clone via HTTPS and copy**

```bash
git clone https://github.com/v60samurai/shipwright.git ~/shipwright

mkdir -p ~/.claude/prompts
cp ~/shipwright/phase1-architect.md ~/.claude/prompts/
cp ~/shipwright/phase2-builder.md ~/.claude/prompts/
```

**Option C: Use directly from the cloned repo**

No need to copy — just reference the full path when invoking:

```
Read ~/shipwright/phase1-architect.md and docs/input/. Generate the product blueprint.
```

### Using with Other AI Tools

The standalone prompts work with any tool that can read a file and follow instructions:

- **Cursor:** Open the prompt file in a tab, paste your input, ask Cursor to follow the instructions
- **Windsurf:** Same approach — reference the prompt file and your input docs
- **ChatGPT/Claude web:** Copy-paste the prompt into the conversation, then paste your PRD/idea
- **Any coding agent:** Point it at the prompt file and your input directory

### Workflow

```bash
# 1. Create project and add your input
mkdir -p my-project/docs/input
# Drop your PRD/idea/notes into docs/input/

# 2. Generate the blueprint (Phase 1)
# In Claude Code or any AI tool:
"Read ~/.claude/prompts/phase1-architect.md and the files in docs/input/. Generate the product blueprint."

# 3. Review docs/product-blueprint.yaml, edit if needed

# 4. Generate the build docs (Phase 2)
"Read ~/.claude/prompts/phase2-builder.md and docs/product-blueprint.yaml. Generate the build docs."

# 5. Build by following docs/Session-Playbook.md session by session
```

### What the Standalone Prompts Include

**`phase1-architect.md`** (The Architect)
- Reads any input quality (3-sentence idea to 40-page PRD)
- Completeness scoring per blueprint section
- ~40 inference rules for filling gaps intelligently
- Max 3 rounds of focused questions
- Field validation rules (required vs conditional vs optional)
- Outputs normalized Product Blueprint YAML

**`phase2-builder.md`** (The Builder)
- Full templates for each generated doc
- Code-level quality rules (copy-paste ready, never pseudocode)
- Session generation algorithm with time estimation
- Conditional doc generation (Design System, Polish Guide)
- 10 meta quality rules enforced across all output

---

## The Two-Phase Pipeline (Both Routes)

Regardless of which route you use, the pipeline is the same:

```
YOUR INPUT (any quality)
    │
    ▼
Phase 1: The Architect
    │  Reads docs/input/*
    │  Scores completeness
    │  Asks max 3 rounds of questions
    │  Infers missing fields with opinionated defaults
    │  Validates all fields
    │
    ▼
Product Blueprint (docs/product-blueprint.yaml)
    │  Normalized intermediate format
    │  Every field has a value
    │  Editable before Phase 2
    │
    ▼
Phase 2: The Builder
    │  Reads blueprint
    │  Detects installed skills (plugin only)
    │  Generates docs adapted to the product
    │
    ▼
Output Docs
    ├── CLAUDE.md                    (always)
    ├── Implementation-Guide.md      (always)
    ├── Session-Playbook.md          (always, skill-aware in plugin mode)
    ├── Design-System.md             (conditional — if product has UI)
    └── Polish-Ship-Guide.md         (conditional — if product is user-facing)
```

---

## What Products Can This Build?

Anything that can be built with code:

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

## Project Structure

```
shipwright/
│
├── # Plugin (Route 1)
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
│           ├── blueprint-schema.md    # Full YAML schema + validation rules
│           ├── inference-rules.md     # All inference rules for filling gaps
│           ├── skill-mapping.md       # Session type → skill recommendations
│           └── generator-templates.md # Doc generator templates + quality rules
├── scripts/
│   ├── detect-skills.sh         # Scans installed plugins for skill-aware sessions
│   └── validate-blueprint.sh    # Validates blueprint YAML completeness
├── hooks/
│   └── hooks.json               # Auto-detect docs/input/ on session start
│
├── # Standalone Prompts (Route 2)
├── phase1-architect.md          # Complete Phase 1 prompt — works with any AI tool
├── phase2-builder.md            # Complete Phase 2 prompt — works with any AI tool
│
├── # Docs
├── design-spec.md               # System design spec
├── docs/
│   └── superpowers/specs/       # Plugin conversion spec
│
├── LICENSE                      # MIT
└── README.md                    # You are here
```

---

## Tips

- **Edit the blueprint.** Phase 1 is smart but not omniscient. Review `product-blueprint.yaml` before Phase 2.
- **"You decide" is valid.** If Phase 1 asks something you don't care about, say "you decide." It picks a sensible default.
- **Re-run Phase 2 after edits.** Changed your mind? Edit the blueprint, re-run. Docs regenerate in minutes.
- **Checkpoints are gates.** When the playbook says "do not proceed until X works," it means it.
- **Session Playbook is linear.** Follow it in order. Each session builds on the previous one.

---

## Origin

Shipwright was extracted from the doc system that powered [HustlrAI](https://github.com/harshitbadiger) — a Telegram-first CRM built in 10 hours with Claude Code. The Implementation Guide + Session Playbook pattern proved that with the right docs, anyone can build a production-grade app with AI. Shipwright templatizes that approach for any product.

---

## License

MIT — see [LICENSE](LICENSE).
