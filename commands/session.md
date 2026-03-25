---
description: "Load a specific session with full context. Usage: /shipwright:session 3"
---

# Session Loader

Load a specific session from the Session Playbook with all referenced context pre-loaded.

## Steps

1. **Parse the session number from `$ARGUMENTS`.** If no number provided, run `/shipwright:status` logic to find the next incomplete session and use that.

2. **Find the Session Playbook.** Look for `docs/*-Session-Playbook.md`. If not found, tell the user to run `/shipwright:build` first.

3. **Extract the session.** Find the section matching `## Session {N}:` (or `## Checkpoint` if it's a checkpoint). Extract everything until the next `## Session` or `## Checkpoint` header.

4. **Parse referenced docs.** Look for the `**Read:**` line. It references doc sections like `IG → "System Design"` or `DS → "Typography"`. Map the abbreviations:
   - `IG` → `docs/*-Implementation-Guide.md`
   - `DS` → `docs/*-Design-System.md`
   - `PS` → `docs/*-Polish-Ship-Guide.md`

   Read the referenced sections from each doc.

5. **Load skill context.** If the session has a `**Skills for this session:**` block, list them prominently.

6. **Present everything:**

```markdown
# Session {N}: {Title}

## Skills Available
{list of skills for this session, with one-line description of when to invoke each}

## Context
{referenced doc sections, fully loaded — the user doesn't need to read anything else}

## Claude Code Prompt
{the exact prompt from the session, ready to copy-paste}

## Test
{test commands}

## Commit
{commit message}

## Milestone Check
{what should be true after this session}
```

7. **Offer to start.** After presenting, ask:

> Ready to start Session {N}? I can execute the Claude Code prompt above, or you can copy-paste it.

If the user says yes, execute the prompt directly — read the referenced Implementation Guide sections and begin building.
