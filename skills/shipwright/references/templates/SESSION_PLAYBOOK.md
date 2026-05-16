# Session Playbook: {{PRODUCT_NAME}}

> The only document you follow linearly. Everything else is reference.
> 
> IG = Implementation Guide
> FP = Final Push Guide  
> BG = Brand Guide
> PRD = Product Requirements Doc
> UF = User Flows doc

**Estimated time:** {{X}} hours solo with Claude Code
**Team size:** {{N}} people

---

## How to Use This Playbook

Each session has one goal. Do not start a session until the previous one's done-check is fully green. If anything is red, fix it before moving forward — discovering a broken foundation in Session 8 costs 3x what it costs in Session 2.

**Running a session:**

1. Read the "Read" section first (which IG/BG/PRD sections Claude Code needs)
2. Copy the Claude Code prompt exactly — don't paraphrase it
3. After the code is generated, run the tests manually
4. Only commit if all tests pass

**Prompt discipline:** Always prepend your Claude Code prompt with the files to read. Example: "Read docs/IMPLEMENTATION_GUIDE.md [Section Name] and docs/BRAND_GUIDE.md [Section]. Then build..."

---

## Pre-Flight (Before Session 1)

**Allow 30 minutes.**

### Services Setup

- [ ] **Supabase** — project created, Auth email provider enabled (Authentication → Providers → Email). Note: project URL, anon key, service role key.
- [ ] **Vercel** — account connected to GitHub. Project URL decided: `{{product-name}}.vercel.app`
- [ ] **Railway** — account connected to GitHub (for backend / workers). Skip if frontend-only.
- [ ] **PostHog** — account created, project created, keys noted.
- [ ] **Sentry** — account created, Next.js project created, DSN noted.
- [ ] **Resend** — account created, domain verified or using sandbox for dev. API key noted.
- [ ] **Stripe / Razorpay** — account created, test mode keys noted. (Skip if no payments in V1.)
- [ ] **{{External API}}** — account created, keys noted.

### Repository Setup

```bash
# Create monorepo
mkdir {{product-name}} && cd {{product-name}}
git init
git remote add origin {{your-github-repo-url}}

# Frontend scaffold
npx create-next-app@latest frontend --typescript --tailwind --app --src-dir
cd frontend
npm install @supabase/supabase-js @supabase/ssr posthog-js @sentry/nextjs resend lucide-react

# Backend scaffold (if applicable)
cd ..
mkdir backend && cd backend
python3 -m venv venv && source venv/bin/activate
pip install fastapi uvicorn supabase anthropic posthog sentry-sdk python-dotenv

# Docs folder
mkdir docs
# Copy: PRD.md, USER_FLOWS.md, BRAND_GUIDE.md, IMPLEMENTATION_GUIDE.md, SESSION_PLAYBOOK.md, FINAL_PUSH.md
```

### CLAUDE.md (project root)

This file tells Claude Code your project context. It is loaded automatically every session.

```markdown
# {{Product Name}} — Claude Code Context

## Project Overview
{{One paragraph from PRD: what the product does, who it's for, the core loop.}}

## Architecture
{{Copy the architecture diagram from your IG.}}

## Tech Stack
{{Copy the tech stack table from your IG.}}

## Key Constraints
- {{Constraint 1 — e.g. "Mobile-first. Design at 390px. Scale up."}}
- {{Constraint 2 — e.g. "Dark theme only. No toggle."}}
- {{Constraint 3 — e.g. "All AI prompts live in ai/prompts.py. Never inline them."}}
- {{Constraint 4 — e.g. "Analytics events must be tracked for every user action."}}
- {{Constraint 5 — e.g. "RLS must be enabled on every Supabase table."}}

## Naming Conventions
- {{e.g. "API routes: noun_verb. Events: entity_action. Files: kebab-case."}}

## Do Not
- {{e.g. "Do not use class components in React."}}
- {{e.g. "Do not put secrets in NEXT_PUBLIC_ env vars."}}
- {{e.g. "Do not use any UI library — Tailwind only."}}

## Reference Documents
All docs are in /docs. Read the relevant section before each task.
```

### Environment Files

```bash
# backend/.env
SUPABASE_URL=
SUPABASE_SERVICE_KEY=
SUPABASE_ANON_KEY=
ENVIRONMENT=development
LOG_LEVEL=DEBUG
FRONTEND_URL=http://localhost:3000
RESEND_API_KEY=
POSTHOG_API_KEY=
SENTRY_DSN=
# Add your domain-specific keys:
{{KEY}}=

# frontend/.env.local
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
NEXT_PUBLIC_APP_URL=http://localhost:3000
NEXT_PUBLIC_APP_NAME={{Product Name}}
NEXT_PUBLIC_POSTHOG_KEY=
NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com
NEXT_PUBLIC_SENTRY_DSN=
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=   # if using payments
```

**Pre-flight complete when:**
- [ ] All services have accounts and keys
- [ ] Monorepo scaffold runs without errors
- [ ] CLAUDE.md is at project root
- [ ] All .env files have real values for every key
- [ ] All 5 docs are in /docs

---

## Session 1: Database Schema

**Time: 30-45 min**

**Goal:** All tables exist in Supabase with correct columns, indexes, RLS, enums, views, auth trigger, and realtime publication.

**Read:** IG → "Database Schema" (full section)

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md "Database Schema" section.
Read docs/PRD.md to understand the domain entities.

Build the complete Supabase schema as a single SQL file at database/schema.sql.

Include:
1. All custom enum types (before tables)
2. All tables from the PRD with correct columns, types, nullable constraints, and defaults
3. Indexes: primary, user-scoped, status-filtered, any search columns
4. RLS: enabled on every table, user-scoped policies (user_id = auth.uid())
5. Waitlist table: insert-only policy, no select
6. Auth trigger: auto-creates users table row on signup
7. updated_at trigger: applied to every mutable table
8. Supabase Realtime: publish tables the frontend will subscribe to
9. Three views that power hot paths (e.g. dashboard_metrics, {{view_2}}, {{view_3}})
10. The log_{{primary_entity}} atomic database function

Do not include any application logic. Only schema.
```

**Apply schema:**
```bash
# Copy schema.sql contents → paste into Supabase SQL editor → Run
```

**Verification SQL (run in Supabase SQL editor):**
```sql
-- Tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;

-- Enums
SELECT typname FROM pg_type WHERE typtype = 'e' ORDER BY typname;

-- Views
SELECT table_name FROM information_schema.views WHERE table_schema = 'public';

-- RLS enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;
-- All tables must show rowsecurity = true

-- Realtime
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
```

**Done when:**
- [ ] All tables from PRD exist
- [ ] All enum types exist
- [ ] All views exist
- [ ] All tables show `rowsecurity = true`
- [ ] Realtime shows the correct tables
- [ ] Auth trigger exists (`handle_new_user`)

**Commit:**
```bash
git add . && git commit -m "feat: database schema, RLS, realtime, auth trigger"
```

---

## Session 2: Landing Page

**Time: 60-90 min**

**Goal:** Landing page is live at localhost:3000. Waitlist capture works. Brand is fully applied.

**Read:** BG → Full brand guide. PRD → "Target Users" and "Value Proposition". UF → Landing page flow.

**Claude Code prompt:**
```
Read docs/BRAND_GUIDE.md fully.
Read docs/PRD.md "Target Users" and "Value Proposition" sections.
Read docs/USER_FLOWS.md landing page flow.
Read docs/IMPLEMENTATION_GUIDE.md "File Structure" frontend section.

Build frontend/src/app/page.tsx as a single-file landing page with these sections:

1. Nav — Logo left, primary CTA right ("{{CTA text}}"). Sticky. Scroll-triggered border-bottom.
2. Hero — {{describe layout from UF}}. Headline uses display font. Email capture submits to Supabase waitlist table.
3. {{Section 3 from UF}} — {{describe}}
4. {{Section 4 from UF}} — {{describe}}
5. {{Section 5 from UF}} — {{describe}}
6. Pricing section — {{from PRD pricing}}
7. FAQ — accordion, common questions from PRD
8. Footer — minimal, logo, links

Design requirements from Brand Guide:
- Font stack: {{fonts from BG}}
- Color tokens: {{paste token map from BG}}
- Animation: {{Framer Motion / CSS — from BG}}
- Dark/light: {{from BG}}

Waitlist form behavior:
- On submit: INSERT into waitlist table via Supabase anon client
- Success: show confirmation ("You're on the list.") — no page redirect
- Duplicate email: show "You're already on the list."
- Network error: show "Something went wrong. Try again."

Include meta tags: title, description, OG image reference (/og-image.png), Twitter card.

Do not add a signup modal or any auth flow to this page. The landing page is waitlist-only.
```

**Test:**
- [ ] Page loads at localhost:3000
- [ ] All sections render correctly
- [ ] Brand colors and fonts match the Brand Guide
- [ ] Email submission creates row in Supabase waitlist table
- [ ] Duplicate email shows correct error
- [ ] Meta tags are present (view source)
- [ ] Responsive at 390px and 1280px

**Commit:**
```bash
git add . && git commit -m "feat: landing page, waitlist capture, brand applied"
```

---

## Session 2.5: Schema Verification (15 min)

**Why:** Session 3+ backend code will break silently if column names are wrong. Verify now.

Run the verification SQL from Session 1's done-check. Fix any discrepancies. Then:

- [ ] Confirm every column name in the PRD maps to a real column in Supabase
- [ ] Confirm every enum value matches what the backend will use
- [ ] Confirm every foreign key relationship is correct

**Do not start Session 3 until this is 100% green.**

---

## Session 3: Backend Skeleton + Auth

**Time: 30-45 min**

**Goal:** Backend runs, all routes respond, Supabase client works.

**Read:** IG → "System Design: Structured Logging, Rate Limiting" + IG → "API Design" + IG → "Environment Variables"

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md "System Design" (Structured Logging, Rate Limiting sections) and "API Design" section.

Build:

1. backend/db/client.py — Supabase client init. Service role client for writes. Anon client not needed (frontend does reads via RLS).

2. backend/middleware/auth.py — verify Supabase JWT from Authorization header. Raise 401 if invalid. Extract user_id from token.

3. backend/middleware/rate_limit.py — check_rate_limit(user_id, limit, window_seconds) using in-memory defaultdict. Raise 429 if exceeded.

4. backend/main.py — FastAPI app:
   - GET /health → {"status": "ok", "env": ENVIRONMENT}
   - POST /api/{{entity}} → placeholder, returns {"status": "not implemented"}
   - All routes apply auth middleware except /health and /webhooks/*
   - StructuredFormatter logging from IG
   - Sentry init (import sentry_sdk, init with SENTRY_DSN)
   - CORS: allow FRONTEND_URL

5. backend/lib/email.py — Resend client. send_email(to, subject, template_name, props). Templates loaded from backend/emails/ directory.

Test:
```bash
cd backend && source venv/bin/activate && uvicorn main:app --reload
curl http://localhost:8000/health
```
Expected: {"status": "ok", "env": "development"}
```

**Done when:**
- [ ] `GET /health` returns 200
- [ ] Auth middleware rejects requests without valid JWT (401)
- [ ] Sentry catches a test error

**Commit:**
```bash
git add . && git commit -m "feat: backend skeleton, auth middleware, Sentry, email client"
```

---

## Session 4: Core Feature Pipeline

**Time: 45-90 min (this is the hardest session)**

**Goal:** The main value-creating action in your product works end to end.

**Read:** IG → "Input Pipeline Pattern" + IG → "Retry Strategy" + IG → "Atomic Persistence" + IG → "AI Integration" (if applicable). PRD → "Core Feature" section. UF → Core action flow.

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md "Input Pipeline Pattern", "Retry Strategy", "Atomic Persistence Pattern", and "AI Integration" sections.
Read docs/PRD.md "Core Feature" section.
Read docs/USER_FLOWS.md core action flow.

This is the central feature. Build it with care.

Build:

1. backend/{{feature}}/pipeline.py — Staged pipeline for {{core action}}:
   - PipelineContext dataclass (user_id + domain-specific fields)
   - PipelineStage enum (validate, preprocess, process, enrich, persist, notify)
   - Each stage is a separate async function
   - run_pipeline() with per-stage error handling and graceful degradation
   - Errors call handle_graceful_failure() and return degraded context, never crash

2. backend/{{feature}}/validators.py — Input/output validation:
   - Validate incoming request shape (Pydantic models)
   - Validate AI output if applicable (AIResult dataclass, clamping, never-throw pattern)
   - parse_ai_json() helper

3. backend/ai/prompts.py — All AI system prompts (only if product uses AI):
   - {{PROMPT_1}} for {{use case 1}}
   - {{PROMPT_2}} for {{use case 2}}
   - Never inline prompts in handler code

4. backend/db/{{entity}}.py — CRUD layer for primary entity:
   - create_{{entity}}(user_id, ...) — calls atomic DB function
   - get_{{entity}}(user_id, id)
   - list_{{entities}}(user_id, filters)
   - update_{{entity}}(user_id, id, changes)

5. backend/db/activity.py — write_activity(user_id, event_type, title, entity_id, metadata)

6. POST /api/{{entity}} in main.py — wires pipeline to HTTP endpoint

7. Track analytics on every successful creation:
   posthog.capture(user_id, '{{entity}}_created', {{{key properties}}})
```

**Test manually:**
```bash
# Send a test request with a valid JWT
curl -X POST http://localhost:8000/api/{{entity}} \
  -H "Authorization: Bearer {{test_jwt}}" \
  -H "Content-Type: application/json" \
  -d '{"{{field}}": "{{test value}}"}'
```

- [ ] Creates row in Supabase table
- [ ] Activity feed row created
- [ ] PostHog event visible in dashboard
- [ ] Pipeline handles intentional failure at each stage without crashing

**Commit:**
```bash
git add . && git commit -m "feat: core feature pipeline, validators, AI prompts, CRUD layer"
```

---

## Session 5: Auth UI + Onboarding

**Time: 45-60 min**

**Goal:** User can sign up, onboard, and reach the dashboard. Aha moment lands in the onboarding flow.

**Read:** IG → "Auth, Onboarding" section + UF → Auth and onboarding flows + BG → UI patterns for forms and auth screens

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md "Auth" and "Onboarding" sections.
Read docs/USER_FLOWS.md auth and onboarding flows.
Read docs/BRAND_GUIDE.md form and auth screen design patterns.

Build:

1. frontend/src/lib/supabase.ts — browser client (createBrowserClient)
2. frontend/src/lib/supabase-server.ts — server client (createServerClient for server components)
3. frontend/src/middleware.ts — route protection:
   - Public: /, /login, /signup, /waitlist, /forgot-password
   - Auth redirect: / and /login → /dashboard if already logged in
   - Protected: /onboarding, /dashboard/* → /login if not authenticated

4. frontend/src/app/(auth)/signup/page.tsx — Signup page:
   - Standalone full-viewport page (not a modal)
   - Fields: {{name, email, company, password}} — from PRD required fields
   - Calls supabase.auth.signUp() with user metadata
   - Error states: duplicate email, weak password, network
   - Loading state on submit button
   - Google OAuth button (if configured)
   - Track 'user_signed_up' event on success

5. frontend/src/app/(auth)/login/page.tsx — Login page:
   - Email + password
   - Loading and error states
   - Forgot password link → supabase.auth.resetPasswordForEmail()
   - Track 'user_logged_in' on success

6. frontend/src/app/onboarding/page.tsx — Onboarding:
   - {{Describe onboarding steps from UF}}
   - Each step tracks 'onboarding_step_completed' with step number and step_name
   - Final step tracks 'onboarding_completed'
   - Skip option tracks 'onboarding_skipped' with current step
   - Progress indicator (N steps, current filled)

7. frontend/src/lib/analytics.ts — Analytics wrapper from IG "Analytics Implementation"
   - initAnalytics(), identifyUser(), trackEvent(), trackPageView(), resetUser()
   - Called in layout.tsx root

Include the identifyUser() call after both signup and login, with the user's profile traits.
```

**Test:**
- [ ] Signup creates Supabase Auth user AND users table row (check both in Supabase)
- [ ] Duplicate email shows correct error message
- [ ] Login redirects to onboarding for new users, dashboard for returning users
- [ ] All onboarding steps complete and redirect to dashboard
- [ ] `user_signed_up` event visible in PostHog
- [ ] `onboarding_completed` event visible in PostHog
- [ ] Protected routes redirect unauthenticated users to login

**Commit:**
```bash
git add . && git commit -m "feat: signup, login, onboarding, analytics events, auth middleware"
```

---

## 🚀 Checkpoint A: Deploy Backend (15 min)

Before building the dashboard, confirm the backend works on real infrastructure.

**Steps:**
1. `git push origin main`
2. Railway: create project → connect GitHub → root `/backend` → process type `Worker` → add all env vars from IG
3. Set any external webhooks to the Railway URL
4. Test: `curl https://{{railway-url}}.railway.app/health` → should return `{"status": "ok"}`
5. Send a real request with a valid JWT → confirm row appears in Supabase

**Do not proceed to Session 6 until `/health` returns 200 from Railway.**

---

## Session 6: Dashboard Shell + Home Screen

**Time: 60-90 min**

**Goal:** Dashboard loads, auth is enforced, nav works, home screen shows real data, realtime updates fire.

**Read:** IG → "System Design: Realtime Connection Recovery" + UF → Dashboard home flow + BG → Dashboard/functional interface design patterns

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md "System Design: Realtime Connection Recovery" section.
Read docs/USER_FLOWS.md dashboard home screen flow.
Read docs/BRAND_GUIDE.md "Functional Interface" design patterns.

Build:

1. frontend/src/app/dashboard/layout.tsx — Dashboard shell:
   - Auth check (redirect to /login if no session)
   - Mobile (0-640px): bottom nav with {{N}} tabs + FAB for primary action
   - Desktop (1025px+): sidebar nav ({{sidebar_width}}px)
   - Supabase realtime subscription on activity_feed (and other tables from IG)
   - Toast notification on new activity events
   - Connection status indicator (green/gray dot)
   - Error boundary wrapping all content

2. frontend/src/app/dashboard/page.tsx — Home screen:
   - {{Section 1 from UF home screen — e.g. metrics overview}}
   - {{Section 2 from UF home screen — e.g. action items}}
   - {{Section 3 from UF home screen — e.g. recent activity}}
   - Empty state for each section (ghost UI or message)
   - Skeleton screens while data loads (pulsing rectangles, not spinners)
   - Staggered load animation (100ms delay between sections)
   - trackPageView('/dashboard') on mount

3. frontend/src/components/ui/Skeleton.tsx — Skeleton loader
4. frontend/src/components/ui/Toast.tsx — Toast notification (or use a library)
5. frontend/src/lib/hooks.ts:
   - useAuth() — current user + loading state
   - useRealtime(table, userId) — realtime subscription with polling fallback (from IG)

Design system tokens from Brand Guide:
- {{paste relevant token variables}}
- Typography scale: {{from BG}}
```

**Test:**
- [ ] Dashboard loads with real data from Supabase
- [ ] Unauthenticated access redirects to login
- [ ] Skeleton screens appear during loading
- [ ] Realtime: trigger a backend write → toast appears on dashboard without refresh
- [ ] Connection dot turns gray if realtime disconnects (test by blocking Supabase in network tab)
- [ ] All empty states display the correct message
- [ ] Mobile layout at 390px: bottom nav, full-width cards
- [ ] Desktop layout at 1280px: sidebar nav

**Commit:**
```bash
git add . && git commit -m "feat: dashboard shell, home screen, realtime subscription, skeleton screens"
```

---

## Session 7: Core Dashboard Screens

**Time: 60-90 min**

**Goal:** All screens from the user flows are built and showing real data.

**Read:** UF → All dashboard screen flows + BG → Component design patterns

**Claude Code prompt:**
```
Read docs/USER_FLOWS.md for all dashboard screens.
Read docs/BRAND_GUIDE.md component design patterns.

Build these pages (one session — keep each page focused):

{{For each screen in your UF, describe it here. Example template:}}

1. frontend/src/app/dashboard/{{screen_1}}/page.tsx
   - Shows: {{what it shows}}
   - Actions: {{what user can do}}
   - Empty state: "{{message}}"
   - trackPageView('/dashboard/{{screen_1}}') on mount

2. frontend/src/app/dashboard/{{screen_2}}/page.tsx
   - Shows: {{what it shows}}
   - Actions: {{what user can do}}
   - Empty state: "{{message}}"

3. frontend/src/app/dashboard/{{entity}}/[id]/page.tsx — Detail view:
   - Header: key entity fields
   - Timeline / history (most recent first)
   - Related entities
   - Action buttons: {{edit, delete, etc.}}

4. Shared components:
   - frontend/src/components/dashboard/{{EntityCard}}.tsx
   - frontend/src/components/dashboard/{{ActivityItem}}.tsx
   - frontend/src/components/dashboard/{{StatusBadge}}.tsx

Track key interactions:
- trackEvent('{{entity}}_viewed', {id, source})
- trackEvent('{{action}}_clicked', {entity_id, location})
```

**Test:**
- [ ] All screens load with real data
- [ ] All empty states show
- [ ] Detail views load individual entities correctly
- [ ] Key interactions tracked in PostHog
- [ ] All screens usable at 390px and 1280px

**Commit:**
```bash
git add . && git commit -m "feat: all dashboard screens, entity detail views, shared components"
```

---

## Session 8: Settings + Billing

**Time: 30-45 min**

**Goal:** User can update their profile. Billing page shows current plan. Upgrade flow works.

**Read:** PRD → "Pricing and Plans" section + IG → "Payment Integration" section

**Claude Code prompt:**
```
Read docs/PRD.md "Pricing and Plans" section.
Read docs/IMPLEMENTATION_GUIDE.md "Payment Integration" section.

Build:

1. frontend/src/app/settings/page.tsx — Account settings:
   - Profile: name, email (read-only if Supabase-managed), avatar upload
   - Notification preferences: {{from PRD}}
   - Danger zone: "Delete account" (with confirmation dialog)
   - PATCH /api/me on save. Track 'settings_updated'.

2. frontend/src/app/settings/billing/page.tsx — Billing:
   - Current plan badge: {{Free / Pro / etc.}}
   - Plan features list (from PRD)
   - Upgrade button → calls POST /api/checkout → redirects to Stripe
   - Manage subscription button → calls POST /api/billing-portal → redirects to Stripe portal (for existing subscribers)
   - Track 'upgrade_prompted' when page loads for free users

3. backend: POST /api/checkout — creates Stripe checkout session:
   - price_id from request body
   - client_reference_id = user_id (for webhook matching)
   - success_url = FRONTEND_URL/settings/billing?success=true
   - cancel_url = FRONTEND_URL/settings/billing

4. backend: POST /api/billing-portal — creates Stripe billing portal session

5. backend/integrations/stripe.py — webhook handler:
   - checkout.session.completed → update user plan + track 'subscription_started'
   - customer.subscription.deleted → downgrade user + track 'subscription_cancelled'
   - invoice.payment_failed → send payment failed email + track 'payment_failed'

6. backend: DELETE /api/me — delete account (GDPR):
   - Verify password / require confirmation
   - Delete user from Supabase Auth (cascades to all user data via ON DELETE CASCADE)
   - Track 'account_deleted'
```

**Test:**
- [ ] Settings page loads and saves profile changes
- [ ] Stripe checkout flow completes in test mode
- [ ] Webhook fires and updates user plan in database (check Supabase)
- [ ] `subscription_started` visible in PostHog
- [ ] Delete account deletes all user data (check Supabase tables)

**Commit:**
```bash
git add . && git commit -m "feat: settings, billing, Stripe integration, GDPR delete"
```

---

## Session 9: Background Jobs + Emails

**Time: 45-60 min**

**Goal:** Scheduled jobs run. Emails send correctly.

**Read:** IG → "Background Jobs" pattern + PRD → "Notifications" section

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md background jobs section.
Read docs/PRD.md "Notifications" section.

Build:

1. backend/jobs/scheduler.py — APScheduler setup. Register all jobs. Called in main.py startup.

2. backend/jobs/{{job_1}}.py — {{e.g. daily digest, reminders, health checks}}:
   - Runs every {{interval}}
   - Queries Supabase for {{trigger condition}}
   - Sends {{action: email / notification / update}}
   - Tracks analytics: posthog.capture(user_id, '{{event}}', {...})

3. backend/jobs/{{job_2}}.py — {{e.g. cleanup, scoring, recalculation}}

4. backend/emails/{{WelcomeEmail}}.tsx — React Email template (in frontend, built by Next.js)
   Or: python backend/emails/templates.py using Jinja2 templates

5. Wire up email sends:
   - On signup → send WelcomeEmail (from Supabase auth webhook or backend)
   - On {{trigger}} → send {{EmailTemplate}}
   - Track 'email_sent' with template name

6. backend: POST /webhooks/auth — Supabase auth webhook for signup events:
   - Sends welcome email
   - Triggers any new user setup (e.g. create default data)
   - No auth required (webhook signature verification only)
```

**Test:**
- [ ] Trigger each job manually: `python -c "from jobs.{{job}} import run; import asyncio; asyncio.run(run())"`
- [ ] Welcome email arrives in inbox (check spam)
- [ ] Job results visible in Supabase (e.g. updated rows, activity feed entries)
- [ ] Analytics events visible in PostHog

**Commit:**
```bash
git add . && git commit -m "feat: background jobs, email templates, welcome email"
```

---

## Session 10: PWA + Responsive Polish

**Time: 30-45 min**

**Goal:** Works on real phones. Installs as PWA. No broken layouts.

**Read:** IG → "Performance Targets" + BG → "Responsive design" section

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md "Performance Targets" section.
Read docs/BRAND_GUIDE.md responsive design section.

1. frontend/src/app/manifest.ts — PWA manifest:
   - name, short_name, description
   - start_url: '/dashboard'
   - display: 'standalone'
   - background_color, theme_color (from Brand Guide)
   - icons: 192x192, 512x512, maskable 512x512

2. frontend/public/sw.js — Service worker:
   - Cache app shell on install
   - Network-first for API calls, cache-first for static assets
   - Offline fallback page

3. frontend/src/app/layout.tsx — register service worker on mount

4. Offline banner component: "You're offline. Showing last saved data." Appears when navigator.onLine is false. Disable write actions when offline.

5. Audit all pages at these widths and fix issues:
   - 390px (iPhone SE) — minimum supported
   - 768px (tablet)
   - 1280px (laptop)
   
   Required: 44px minimum touch targets, safe area insets on iOS (env(safe-area-inset-bottom)), no horizontal overflow.

6. Run Lighthouse and fix any issues below target thresholds:
   - Performance: 80+
   - Accessibility: 90+
   - Best Practices: 90+
   - SEO: 90+
```

**Test on a real phone (not simulator):**
- [ ] Open in Safari on iOS → install as PWA → launches in standalone mode
- [ ] Open in Chrome on Android → install as PWA → launches in standalone mode
- [ ] Turn off WiFi → offline banner appears
- [ ] Core navigation works offline
- [ ] Touch targets all feel comfortable to tap

**Commit:**
```bash
git add . && git commit -m "feat: PWA, service worker, offline mode, responsive polish"
```

---

## 🚀 Checkpoint B: Full Loop Test (20 min)

Deploy frontend to Vercel. Run the complete user journey from sign up to core value.

**Steps:**
1. `git push origin main`
2. Vercel: connect GitHub repo → root `/frontend` → add all `NEXT_PUBLIC_*` env vars → deploy
3. Run full loop:
   - Visit `{{product}}.vercel.app`
   - Sign up with a new email
   - Complete onboarding
   - Perform the core action
   - Verify it works end to end on production (not localhost)
4. Check PostHog: `user_signed_up`, `onboarding_completed`, `{{core_event}}` all visible
5. Check Sentry: no errors in production

**If the loop breaks here, fix it before continuing. Every session after this builds on this working baseline.**

---

## Session 11: Edge Cases + Error States

**Time: 30-45 min**

**Goal:** Nothing crashes. Every empty state guides. Every error is recoverable.

**Read:** PRD → Edge cases section. UF → Error states in flows.

**Claude Code prompt:**
```
Read docs/PRD.md edge cases section.
Read docs/USER_FLOWS.md error states.

Implement every edge case and error state:

Backend edge cases:
- {{Input edge case 1}} → {{response}}
- {{Input edge case 2}} → {{response}}
- AI output is malformed → validate_ai_output() handles it, degraded result, no crash
- External service is down → graceful fallback from IG degradation map

Dashboard edge cases:
- {{Screen}} with no data → empty state: "{{message}}"
- {{Action}} fails → optimistic rollback + error toast
- User has no subscription but tries a Pro feature → upgrade prompt, not a crash

Data edge cases:
- {{Data consistency issue 1}} → {{handling}}
- Concurrent edit (two sessions) → last-write-wins with warning

Make sure every interactive element on the dashboard has a loading state, a success state, and an error state. No element should silently do nothing.
```

**Test:** Go through every empty state and error state from the UF. Every single one should show a useful message, not a blank screen.

**Commit:**
```bash
git add . && git commit -m "feat: edge cases, error states, empty states"
```

---

## Session 12: Delight Layer

**Time: 30-45 min**

**Goal:** The product feels alive and intentional. The micro-details land.

**Read:** FP → Full document + BG → "Delight and Motion" section

**Claude Code prompt:**
```
Read docs/FINAL_PUSH.md fully.
Read docs/BRAND_GUIDE.md "Delight and Motion" section.

Add:

1. {{Milestone moments}} — {{define your milestones from FP}}
2. Realtime card animation — new items slide in rather than appearing
3. Number animations — AnimatedNumber component (200ms tween)
4. Optimistic UI — all write actions update instantly, revert on failure
5. Page transitions — subtle fade/slide between dashboard routes
6. Tab title badge — "{{Product}} ({{count}})" when action items are pending
7. Keyboard shortcuts — "/" for search, "{{key}}" for primary action
8. Custom 404 page — on-brand with link back to dashboard
9. Console easter egg — branded message for developers who open devtools
10. {{Any product-specific delight from FP}}
11. Error boundaries — on every page, clean fallback with "Try again"
12. Meta tags — complete OG/Twitter tags on all public pages
13. Loading states — spinner inside buttons during async operations (never disable the whole page)
14. {{Landing page: live demo widget from FP}} — auto-playing demo of core value proposition
```

**Commit:**
```bash
git add . && git commit -m "feat: delight layer, animations, milestones, easter eggs"
```

---

## Session 13: Analytics Audit + Monitoring Verify

**Time: 20-30 min**

**Goal:** Every event from the taxonomy fires. Monitoring works. You can make decisions from data on day 1.

**Claude Code prompt:**
```
Read docs/IMPLEMENTATION_GUIDE.md "Analytics Implementation" — Event Taxonomy table.

Audit every event in the taxonomy table. For each event:
1. Confirm the trackEvent() call exists in the correct component/handler
2. Confirm the properties object includes all required fields
3. Add any missing events

Then:
4. Create a PostHog dashboard with these panels:
   - Daily active users (DAU)
   - Signup funnel: {{page_viewed_signup → signup_form_started → user_signed_up → onboarding_completed}}
   - Core action funnel: {{step_1 → step_2 → conversion_event}}
   - Upgrade funnel: upgrade_prompted → checkout_started → subscription_started

5. Verify Sentry:
   - Throw a test error in production and confirm it appears in Sentry
   - Confirm source maps are uploaded (stack traces show readable code)

6. Set up uptime monitoring (Better Uptime free tier):
   - Monitor: {{product}}.vercel.app
   - Monitor: {{railway-url}}.railway.app/health
   - Alert email: {{your email}}
```

**Done when:**
- [ ] All taxonomy events fire (verify in PostHog → Live Events)
- [ ] PostHog dashboard panels have data
- [ ] Sentry test error visible with readable stack trace
- [ ] Uptime monitors active

**Commit:**
```bash
git add . && git commit -m "chore: analytics audit, PostHog dashboard, monitoring setup"
```

---

## Session 14: Launch Prep

**Time: 30 min**

**Goal:** Complete all items in the Launch Checklist from the IG. Ship.

**Read:** IG → "Launch Checklist" (full section)

**Steps (no Claude Code for this session):**

1. **Custom domain:** Add `{{yourdomain.com}}` in Vercel → set DNS records → wait for propagation → test
2. **OG image:** Generate 1200x630 PNG with product name and tagline. Upload to `frontend/public/og-image.png`. Test at https://www.opengraph.xyz/
3. **Legal pages:** Create `/privacy` and `/terms` using Termly.io or Iubenda. Add to footer links.
4. **Seed demo data:** Run your seed script (built in Session 3 or as a separate admin script) against the production account
5. **Kill shot rehearsal:** Run through the primary demo flow 3 times on a real phone → production URL → all the way through
6. **Final checklist:** Go through every item in IG → "Launch Checklist". Check every box.

**Commit:**
```bash
git add . && git commit -m "chore: custom domain, OG image, legal pages, launch ready"
git tag v0.1.0
git push origin main --tags
```

**Ship it.**

---

## Appendix: Common Failure Modes

**Bot / backend doesn't respond:**
- Check Railway logs (Deployments → latest → View Logs)
- Common: `Procfile` says `web:` instead of `worker:`
- Common: missing env var (check Railway Variables tab)

**Realtime doesn't fire:**
- Check `pg_publication_tables`: `SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime'`
- Common: table not added to publication
- Common: RLS blocks the subscription (check policy for the subscribed table)

**Auth trigger doesn't create users row:**
- Check Supabase → Database → Triggers → `on_auth_user_created` exists
- Common: trigger missing (schema didn't apply fully)
- Common: users table has a NOT NULL column the trigger doesn't populate

**PostHog not receiving events:**
- Check `NEXT_PUBLIC_POSTHOG_KEY` is the project API key, not the personal API key
- Common: `opt_out_capturing()` is running in production (check the env condition)
- Common: events fire server-side with the wrong distinct_id (check backend POSTHOG_API_KEY)

**Stripe webhook not firing:**
- Check Stripe Dashboard → Webhooks → delivery attempts for failures
- Common: `STRIPE_WEBHOOK_SECRET` uses the endpoint secret, not the API key
- Common: endpoint URL is wrong (check Railway URL is current — Railway regenerates URLs on plan changes)

**Sentry not receiving errors:**
- Common: `SENTRY_DSN` is the DSN for the wrong project
- Common: `before_send` is dropping all events (check the dev environment filter)
