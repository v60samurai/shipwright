# Skill Mapping: Session Type → Recommended Skills

When generating the Session Playbook, match each session's type to relevant skills from this map. **Only recommend skills that appear in `docs/.shipwright-skills.json`.**

## Universal (Every Session)

| When | Skill/Command | Why |
|------|--------------|-----|
| After every session | `/commit` | Atomic commits per session |
| Before claiming done | `superpowers:verification-before-completion` | Verify before asserting success |
| Before complex session | `superpowers:writing-plans` | Break down multi-step work |

## Database / Schema Setup

| Skill/Command | Why |
|--------------|-----|
| `vercel:vercel-storage` | If using Vercel storage products (Blob, Edge Config) |
| `vercel:bootstrap` | If project needs Vercel linking and env setup |

## Backend API / Server Logic

| Skill/Command | Why |
|--------------|-----|
| `vercel:nextjs` | If Next.js API routes or Server Actions |
| `vercel:vercel-functions` | If deploying functions to Vercel |
| `vercel:routing-middleware` | If auth/routing middleware needed |
| `vercel:vercel-services` | If multi-service backend |

## AI / LLM Pipeline

| Skill/Command | Why |
|--------------|-----|
| `vercel:ai-sdk` | For any AI feature (chat, extraction, generation) |
| `vercel:ai-gateway` | For model routing, failover, cost tracking |
| `vercel:ai-elements` | For rendering AI text in UI (mandatory for AI text display) |
| `vercel:workflow` | For durable AI agents that survive crashes |

## Frontend UI

| Skill/Command | Why |
|--------------|-----|
| `frontend-design` | For all UI component creation |
| `vercel:shadcn` | If using shadcn/ui components |
| `vercel:react-best-practices` | Auto-triggers on TSX edits |
| `animate` | For adding purposeful animations |
| `polish` | Final quality pass before shipping UI |
| `delight` | For adding moments of joy |
| `colorize` | If interface is too monochromatic |
| `adapt` | For responsive design across devices |

## Authentication

| Skill/Command | Why |
|--------------|-----|
| `vercel:auth` | Clerk, NextAuth, Supabase Auth patterns |
| `vercel:sign-in-with-vercel` | If using Vercel as identity provider |

## Bot / Chat

| Skill/Command | Why |
|--------------|-----|
| `vercel:chat-sdk` | Multi-platform bot (Slack, Telegram, Discord, etc.) |
| `vercel:ai-sdk` | For AI-powered bot responses |

## Deployment Checkpoints

| Skill/Command | Why |
|--------------|-----|
| `vercel:deploy` | For Vercel deployments |
| `vercel:deployments-cicd` | For CI/CD pipeline configuration |
| `vercel:env-vars` | For environment variable management |
| `vercel:vercel-cli` | For CLI-based deployment operations |

## Debugging (When Stuck)

| Skill/Command | Why |
|--------------|-----|
| `superpowers:systematic-debugging` | Structured debugging methodology |
| `/debug` | Quick debug invocation |
| `vercel:investigation-mode` | For deployment/runtime issues on Vercel |
| `vercel:agent-browser` | For verifying UI in browser |

## Review & Ship

| Skill/Command | Why |
|--------------|-----|
| `superpowers:requesting-code-review` | Before merging features |
| `superpowers:verification-before-completion` | Before claiming done |
| `/review` | Quick review pass |
| `/test` | Run tests after implementation |
| `vercel:verification` | Full end-to-end verification |

## Planning (Complex Sessions)

| Skill/Command | Why |
|--------------|-----|
| `superpowers:brainstorming` | Before ambiguous features |
| `superpowers:writing-plans` | For multi-step implementation |
| `superpowers:dispatching-parallel-agents` | For independent parallel tasks |

## Testing

| Skill/Command | Why |
|--------------|-----|
| `superpowers:test-driven-development` | If TDD strategy in blueprint |
| `/test` | Run tests after implementation |

## Polish / Final Pass

| Skill/Command | Why |
|--------------|-----|
| `polish` | Final alignment, spacing, consistency fixes |
| `harden` | Error handling, i18n, edge cases |
| `audit` | Comprehensive interface quality audit |
| `optimize` | Performance improvements |
| `clarify` | Improve UX copy and error messages |

## Session Type Detection

To determine which skills apply to a session, check the session title and content for these keywords:

| Keywords in Session | Session Type |
|-------------------|-------------|
| database, schema, migration, table, enum | Database/Schema |
| skeleton, API, endpoint, route, handler | Backend API |
| extraction, AI, LLM, Claude, pipeline, prompt | AI Pipeline |
| dashboard, page, component, UI, layout, form | Frontend UI |
| auth, login, signup, middleware, session | Authentication |
| bot, telegram, discord, slack, webhook | Bot/Chat |
| deploy, vercel, railway, production, checkpoint | Deployment |
| polish, delight, animation, edge case, empty state | Polish |
| test, spec, e2e, integration | Testing |
