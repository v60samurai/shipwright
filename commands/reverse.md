---
description: "Reverse-engineer a Product Blueprint from an existing codebase."
---

# Reverse Engineer Blueprint

Analyze the current codebase and generate a Product Blueprint (`docs/product-blueprint.yaml`).

## When to Use

- Documenting an existing project that was built without Shipwright
- Onboarding onto someone else's codebase
- Creating a blueprint before a major feature addition or rebuild
- Generating build docs for a project mid-development

## Steps

1. **Scan project structure.** Read the directory tree:
```bash
find . -type f -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/venv/*' -not -path '*/__pycache__/*' -not -path '*/.next/*' -not -path '*/dist/*' | head -200
```

2. **Read key files.** Identify and read:
   - `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod` (dependencies → stack)
   - `CLAUDE.md`, `README.md` (project description → product)
   - Database schema files: `schema.prisma`, `drizzle/schema.ts`, SQL migrations, `models.py`
   - Config files: `next.config.*`, `tailwind.config.*`, `tsconfig.json`, `.env.example`
   - Auth config: middleware files, auth route handlers
   - Main entry points: `app/layout.tsx`, `main.py`, `index.ts`, `App.tsx`

3. **Infer blueprint sections:**

   - `product` → from README, package.json description, CLAUDE.md
   - `interfaces` → from directory structure (app/ = web, bot/ = bot, cli/ = CLI, api/ = API)
   - `architecture` → from how directories connect, imports between modules
   - `stack` → from package.json/requirements.txt dependencies
   - `data_model` → from schema files (Prisma, Drizzle, SQL, Django models)
   - `features` → from route handlers, pages, commands (each route/page = a feature)
   - `design` → from tailwind config, CSS variables, globals.css
   - `env_vars` → from .env.example or .env*.local patterns
   - `deployment` → from Procfile, vercel.json, Dockerfile, CI config

4. **Fill gaps.** For sections that can't be inferred from code:
   - `users` → ask the user (1 question)
   - `voice` → infer from existing copy in the UI, or ask
   - `resilience` → infer from error handling patterns in the code
   - `testing` → from test files and test config
   - `user_journeys` → infer from route structure + auth middleware

5. **Run skill detection:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/detect-skills.sh"
```
Save to `docs/.shipwright-skills.json`.

6. **Validate and output.** Run validation, write to `docs/product-blueprint.yaml`.

7. **Present summary:**

> Reverse-engineered blueprint from your codebase:
>
> - Product: {name} — {tagline}
> - {N} interfaces detected: {list}
> - {N} entities in data model
> - {N} core features identified
> - Stack: {frontend} + {backend} + {database}
>
> Blueprint written to `docs/product-blueprint.yaml`. Review it, then run `/shipwright:build` to generate build docs.
