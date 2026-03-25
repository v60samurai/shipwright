---
description: "Show session progress — which sessions are done, which is next."
---

# Session Progress Tracker

Show the user's build progress by cross-referencing the Session Playbook with git history.

## Steps

1. **Find the Session Playbook.** Look for `docs/*-Session-Playbook.md`. If not found, tell the user to run `/shipwright:build` first.

2. **Extract sessions.** Parse the playbook for all session headers matching the pattern `## Session N:` and `## Checkpoint`. Extract: session number, title, estimated time, and the commit message pattern from the `**Commit:**` section.

3. **Read git log.** Run:
```bash
git log --oneline --all | head -50
```

4. **Match sessions to commits.** For each session, check if a commit message matches its commit pattern (fuzzy match on the key words). Mark as done if found.

5. **Determine "next" session.** The first session without a matching commit is the next session.

6. **Present progress:**

```
Shipwright Progress: {done}/{total} sessions completed

  [done] Session 1: Database Schema
  [done] Session 2: Backend Skeleton
  [done] Checkpoint A: Deploy Backend
  [next] Session 3: AI Pipeline              ← you are here
  [ ]   Session 4: Bot Handlers
  [ ]   Session 5: Auth + Onboarding
  [ ]   Checkpoint B: Full Loop Test
  [ ]   Session 6: Dashboard
  [ ]   Session 7: Polish + Edge Cases
  [ ]   Session 8: Demo Prep

  Time remaining: ~{sum of pending session times}
  Next: Run /shipwright:session 3 to load the AI Pipeline session.
```

Use `[done]` for completed, `[next]` with arrow for current, `[ ]` for pending. Show time remaining as sum of pending session time estimates.
