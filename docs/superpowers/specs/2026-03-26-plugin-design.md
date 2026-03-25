# Shipwright Plugin — Design Spec

> Convert the Shipwright two-phase prompt system into a Claude Code plugin with 5 commands, auto-trigger skill, skill-aware session generation, and session tracking.

---

## Problem

Shipwright currently lives as two standalone markdown files. Users must manually copy them to `~/.claude/prompts/` and type long invocation strings. There's no session tracking, no skill awareness, and no way to jump to a specific session.

## Solution

Package Shipwright as a Claude Code plugin with:
- 5 slash commands for explicit invocation
- 1 auto-trigger skill for implicit discovery
- Skill detection that maps installed plugins to session recommendations
- Session progress tracking via git log analysis
- Session loader that extracts and loads full context for a single session

## Plugin Structure

```
shipwright/
├── .claude-plugin/
│   └── plugin.json
├── commands/
│   ├── blueprint.md          # /shipwright:blueprint
│   ├── build.md              # /shipwright:build
│   ├── status.md             # /shipwright:status
│   ├── session.md            # /shipwright:session N
│   └── reverse.md            # /shipwright:reverse
├── skills/
│   └── shipwright/
│       ├── SKILL.md
│       └── references/
│           ├── blueprint-schema.md
│           ├── inference-rules.md
│           ├── skill-mapping.md
│           └── generator-templates.md
├── scripts/
│   ├── detect-skills.sh
│   └── validate-blueprint.sh
├── hooks/
│   └── hooks.json
├── LICENSE
└── README.md
```

## Commands

### /shipwright:blueprint
- Reads `docs/input/*`
- Scores completeness per blueprint section
- Asks max 3 rounds of questions
- Runs `scripts/validate-blueprint.sh`
- Outputs `docs/product-blueprint.yaml`
- Also runs `scripts/detect-skills.sh` → saves to `docs/.shipwright-skills.json`

### /shipwright:build
- Checks `docs/product-blueprint.yaml` exists
- Reads `docs/.shipwright-skills.json` for installed skills
- Generates in order: CLAUDE.md → Implementation Guide → Design System (conditional) → Session Playbook → Polish & Ship Guide (conditional)
- Session Playbook embeds skill/command recommendations per session based on detected skills

### /shipwright:status
- Reads Session Playbook to extract session list
- Reads git log to match commit messages against session commit patterns
- Shows progress: done/next/pending per session
- No state files — purely derived from git history

### /shipwright:session N
- Extracts Session N from the Session Playbook
- Reads Implementation Guide sections referenced by "Read:" line
- Reads Design System sections if referenced
- Presents: full context, Claude Code prompt, skills to use, test commands
- Single command gives full session context

### /shipwright:reverse
- Reads current codebase: package.json, schema files, directory structure, key source files
- Reverse-engineers a Product Blueprint
- Outputs `docs/product-blueprint.yaml`
- Useful for: documenting existing projects, onboarding, pre-rebuild planning

## Skill (Auto-Trigger)

Triggers on: "generate build docs", "create implementation guide", "session playbook", "project docs from PRD", etc. Points user to the appropriate command.

## Skill Detection

`scripts/detect-skills.sh` scans `~/.claude/plugins/` and outputs JSON:
- Lists available skills with name, source plugin, and trigger description
- Lists available commands with name and source plugin
- Phase 2 reads this to only recommend skills that are actually installed

## Skill Mapping

`references/skill-mapping.md` maps session types to skill recommendations:
- Database → vercel:vercel-storage, vercel:bootstrap
- Backend API → vercel:nextjs, vercel:vercel-functions
- AI pipeline → vercel:ai-sdk, vercel:ai-gateway
- Frontend UI → frontend-design, shadcn, react-best-practices
- Auth → vercel:auth
- Bot → vercel:chat-sdk
- Deploy → vercel:deploy, vercel:deployments-cicd
- Debug → superpowers:systematic-debugging
- Review → superpowers:requesting-code-review
- Planning → superpowers:brainstorming, superpowers:writing-plans

Only recommends skills present in `.shipwright-skills.json`.

## Hook

SessionStart hook: if `docs/input/` exists with files and `docs/product-blueprint.yaml` doesn't exist, remind user to run `/shipwright:blueprint`.

## Migration

Existing `phase1-architect.md` and `phase2-builder.md` content moves into commands + references. The standalone files remain in the repo for users who prefer the raw prompt approach.
