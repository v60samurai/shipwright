# Implementation Guide: {{PRODUCT_NAME}}

> Status: Build-ready reference
> Date: {{DATE}}
> Architecture: {{ARCHITECTURE_SUMMARY}}
> Stack: {{STACK_SUMMARY}}

---

## How to Use This Document

This guide is the technical reference. You do not read it linearly. The Session Playbook tells you which section to read before each session. When Claude Code asks you to "read [IG → Section Name]", come here.

**Your input documents:**
- `PRD.md` — what to build, for whom, and why
- `USER_FLOWS.md` + `*.jsx` — how users move through the product
- `BRAND_GUIDE.md` — visual identity, palette, typography, tone

**What this document covers:** how to build it, how to structure it, how to make it reliable, and how to ship it.

---

## Architecture Overview

> Fill this in from your PRD.md and USER_FLOWS.md before starting.

```
{{ARCHITECTURE_DIAGRAM}}

Example structure:
USER ENTRY POINT(S)
    │
    ├── {{INTERFACE_1}} ─────── {{BACKEND_LAYER}} ─────── {{AI_LAYER if applicable}}
    │   ({{capture/input}})      ({{API type}})             ({{model/service}})
    │                                  │
    │                                  ▼
    │                            {{DATABASE}}
    │                       ({{services: auth/realtime/storage}})
    │                                  │
    │                                  ▼
    ├── {{INTERFACE_2}} ◄──── {{FRONTEND_FRAMEWORK}}
    │   ({{consumption}})
    │
    └── {{BACKGROUND_JOBS}} ──── {{SCHEDULER}}
        ({{job types}})           ({{cadence}})
```

**Decision log — one sentence per major choice:**
- Database: {{choice}} because {{reason}}
- Auth: {{choice}} because {{reason}}
- Frontend framework: {{choice}} because {{reason}}
- Background jobs: {{choice}} because {{reason}}
- AI provider (if applicable): {{choice}} because {{reason}}

---

## Tech Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Frontend | {{e.g. Next.js 14}} | {{reason}} |
| Backend API | {{e.g. FastAPI / Next.js API Routes}} | {{reason}} |
| Database | {{e.g. Supabase / PlanetScale / Neon}} | {{reason}} |
| Auth | {{e.g. Supabase Auth / Clerk / Auth.js}} | {{reason}} |
| Background jobs | {{e.g. Inngest / APScheduler / Trigger.dev}} | {{reason}} |
| File storage | {{e.g. Supabase Storage / S3 / Cloudflare R2}} | {{reason}} |
| Email | {{e.g. Resend / Postmark / SendGrid}} | {{reason}} |
| Analytics | {{e.g. PostHog}} | Self-hosted option, product analytics + session replay + feature flags |
| Error monitoring | {{e.g. Sentry}} | {{reason}} |
| Payments (if needed) | {{e.g. Stripe / Razorpay}} | {{reason}} |
| Hosting — frontend | {{e.g. Vercel}} | {{reason}} |
| Hosting — backend | {{e.g. Railway / Render / Fly.io}} | {{reason}} |

---

## System Design

### Input Pipeline Pattern

> Use this whenever the product processes user input through multiple stages (form submission, file upload, AI extraction, message processing). Replace stage names with your actual stages.

```python
from dataclasses import dataclass, field
from typing import Optional, List
from enum import Enum

class PipelineStage(Enum):
    VALIDATE    = "validate"     # Input shape is correct
    PREPROCESS  = "preprocess"   # Clean/transform input
    PROCESS     = "process"      # Core business logic
    ENRICH      = "enrich"       # Add context (AI, lookups)
    PERSIST     = "persist"      # Write to database
    NOTIFY      = "notify"       # Trigger downstream events

@dataclass
class PipelineContext:
    """Carries all state through the pipeline. Add your domain fields."""
    user_id: str
    
    # Input (set at entry)
    raw_input: Optional[str] = None
    input_type: Optional[str] = None
    
    # Processing results (set by each stage)
    processed: Optional[dict] = None
    enriched: Optional[dict] = None
    record_id: Optional[str] = None
    
    # Error tracking
    failed_stage: Optional[PipelineStage] = None
    error_message: Optional[str] = None
    
    # Flow control
    needs_clarification: bool = False
    skip_notification: bool = False

async def run_pipeline(ctx: PipelineContext) -> PipelineContext:
    stages = [
        (PipelineStage.VALIDATE,   validate_stage),
        (PipelineStage.PREPROCESS, preprocess_stage),
        (PipelineStage.PROCESS,    process_stage),
        (PipelineStage.ENRICH,     enrich_stage),
        (PipelineStage.PERSIST,    persist_stage),
        (PipelineStage.NOTIFY,     notify_stage),
    ]
    
    for stage_name, stage_fn in stages:
        try:
            ctx = await stage_fn(ctx)
            if ctx.needs_clarification:
                return ctx  # Pause pipeline, await user input
        except ExternalServiceError as e:
            ctx.failed_stage = stage_name
            ctx.error_message = str(e)
            await handle_graceful_failure(ctx, stage_name)
            logger.error(f"Pipeline failed at {stage_name.value}: {e}",
                         extra={"user_id": ctx.user_id, "stage": stage_name.value})
            return ctx
        except Exception as e:
            ctx.failed_stage = stage_name
            logger.exception(f"Unexpected error at {stage_name.value}",
                             extra={"user_id": ctx.user_id})
            return ctx
    return ctx
```

### Retry Strategy for External Services

```python
import asyncio
from functools import wraps

class ExternalServiceError(Exception):
    def __init__(self, service: str, message: str, retryable: bool = False):
        self.service = service
        self.retryable = retryable
        super().__init__(f"{service}: {message}")

def with_retry(service_name: str, max_retries: int = 2, base_delay: float = 1.0):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            last_error = None
            for attempt in range(max_retries + 1):
                try:
                    return await func(*args, **kwargs)
                except Exception as e:
                    last_error = e
                    error_str = str(e).lower()
                    if any(code in error_str for code in ['400', '401', '403', 'invalid']):
                        raise ExternalServiceError(service_name, str(e), retryable=False)
                    if attempt < max_retries:
                        delay = base_delay * (2 ** attempt)
                        await asyncio.sleep(delay)
            raise ExternalServiceError(service_name, str(last_error), retryable=True)
        return wrapper
    return decorator
```

### Atomic Persistence Pattern

When a single user action needs to write to multiple tables, use a database function so the entire operation succeeds or fails together. No partial writes.

```sql
-- Supabase / PostgreSQL
CREATE OR REPLACE FUNCTION create_{{entity}}(
    p_user_id UUID,
    -- add your params
) RETURNS UUID AS $$
DECLARE
    v_id UUID;
BEGIN
    -- Primary record
    INSERT INTO {{primary_table}} (user_id, ...)
    VALUES (p_user_id, ...)
    RETURNING id INTO v_id;
    
    -- Related records (run inside same transaction)
    INSERT INTO {{related_table}} ({{entity}}_id, ...)
    VALUES (v_id, ...);
    
    -- Activity feed / audit log
    INSERT INTO activity_feed (user_id, event_type, entity_id)
    VALUES (p_user_id, '{{entity}}_created', v_id);
    
    RETURN v_id;
END;
$$ LANGUAGE plpgsql;
```

### Idempotency Guard

Prevent duplicate processing when requests are retried (webhooks, network retries, double-submits).

```sql
-- Add to any table that receives idempotent writes
CREATE UNIQUE INDEX idx_{{table}}_idempotency_key
  ON {{table}}(user_id, idempotency_key)
  WHERE idempotency_key IS NOT NULL;
```

```typescript
// Frontend: generate idempotency key per user action
const idempotencyKey = `${userId}-${actionType}-${Date.now()}`
// Pass in request body, check on server before processing
```

### Graceful Degradation Map

> Fill this in for your specific external services before building.

| Service Down | What Happens | User Sees |
|-------------|-------------|-----------|
| {{Service 1}} | {{Fallback behavior}} | {{User-facing message}} |
| {{Service 2}} | {{Fallback behavior}} | {{User-facing message}} |
| {{Database}} | Queue writes in memory, retry every 30s | "Saving failed. Will retry." |
| {{AI service}} | Save raw input, queue for retry | "Processing queued. Back shortly." |
| Realtime sub | Fall back to polling every 10s | Dot turns gray, data still loads |

### Optimistic UI Pattern

```typescript
async function performAction(id: string, newState: Partial<Entity>) {
    // 1. Save previous state
    const prev = items.find(i => i.id === id)
    
    // 2. Update UI immediately
    setItems(items.map(i => i.id === id ? { ...i, ...newState } : i))
    
    try {
        // 3. Persist to server
        await api.update(id, newState)
    } catch {
        // 4. Revert on failure
        setItems(items.map(i => i.id === id ? prev! : i))
        toast.error("Couldn't save that. Try again.")
    }
}
```

### Structured Logging

```python
import logging
import json

class StructuredFormatter(logging.Formatter):
    def format(self, record):
        log_data = {
            "timestamp": self.formatTime(record),
            "level": record.levelname,
            "message": record.getMessage(),
        }
        for field in ['user_id', 'session_id', 'stage', 'duration_ms', 'entity_id']:
            if hasattr(record, field):
                log_data[field] = getattr(record, field)
        if record.exc_info:
            log_data['exception'] = self.formatException(record.exc_info)
        return json.dumps(log_data)

logger = logging.getLogger("{{app_name}}")
```

### Rate Limiting

```python
from collections import defaultdict
from datetime import datetime, timedelta

_request_times: dict[str, list] = defaultdict(list)

def check_rate_limit(user_id: str, limit: int = 60, window_seconds: int = 60) -> bool:
    now = datetime.utcnow()
    times = _request_times[user_id]
    _request_times[user_id] = [t for t in times if now - t < timedelta(seconds=window_seconds)]
    if len(_request_times[user_id]) >= limit:
        return False
    _request_times[user_id].append(now)
    return True
```

---

## Analytics Implementation

Analytics is not an afterthought. Instrument before you ship, or you will make decisions without data.

### PostHog Setup (Recommended)

PostHog handles: event tracking, session replay, feature flags, A/B tests, funnels, and cohorts. One tool instead of four.

```bash
# Frontend
npm install posthog-js

# Backend (for server-side events)
pip install posthog
```

```typescript
// frontend/lib/analytics.ts
import posthog from 'posthog-js'

export function initAnalytics() {
    if (typeof window === 'undefined') return
    posthog.init(process.env.NEXT_PUBLIC_POSTHOG_KEY!, {
        api_host: process.env.NEXT_PUBLIC_POSTHOG_HOST || 'https://app.posthog.com',
        capture_pageview: false,     // We handle this manually for SPAs
        capture_pageleave: true,
        session_recording: {
            maskAllInputs: true,     // Never record passwords or sensitive fields
        },
        loaded: (ph) => {
            if (process.env.NODE_ENV === 'development') ph.opt_out_capturing()
        }
    })
}

export function identifyUser(userId: string, traits: Record<string, unknown>) {
    posthog.identify(userId, traits)
}

export function trackEvent(event: string, properties?: Record<string, unknown>) {
    posthog.capture(event, properties)
}

export function trackPageView(path: string) {
    posthog.capture('$pageview', { $current_url: path })
}

export function resetUser() {
    posthog.reset()
}
```

```typescript
// frontend/app/layout.tsx — wrap with PostHog provider
import { PostHogProvider } from 'posthog-js/react'
```

### Event Taxonomy

Define your events before coding. Inconsistent naming makes analytics useless.

**Naming convention:** `noun_verb` or `noun_verb_modifier`
Examples: `user_signed_up`, `deal_created`, `follow_up_completed`, `feature_used_export`

**Core events to instrument for every product:**

| Event | When | Key Properties |
|-------|------|----------------|
| `user_signed_up` | After successful registration | `method` (email/google), `plan` |
| `user_logged_in` | After successful login | `method` |
| `onboarding_step_completed` | Each onboarding step | `step` (1-N), `step_name` |
| `onboarding_completed` | Full onboarding done | `time_to_complete_seconds` |
| `onboarding_skipped` | User skips onboarding | `at_step` |
| `feature_used_{{feature}}` | Core action performed | `input_type`, `context` |
| `cta_clicked` | Any CTA click | `cta_name`, `page`, `location` |
| `error_encountered` | User-visible error | `error_type`, `stage`, `recoverable` |
| `page_viewed` | Every page load | `path`, `referrer` |
| `session_started` | App opened | `platform`, `is_pwa` |
| `upgrade_prompted` | Paywall shown | `feature_attempted`, `plan_shown` |
| `subscription_started` | Payment completed | `plan`, `amount`, `currency` |
| `subscription_cancelled` | User cancels | `plan`, `reason` |

**Product-specific events (fill in from your PRD):**

| Event | When | Key Properties |
|-------|------|----------------|
| `{{entity}}_created` | {{trigger}} | `{{properties}}` |
| `{{entity}}_updated` | {{trigger}} | `{{properties}}`, `changed_fields` |
| `{{entity}}_deleted` | {{trigger}} | `{{properties}}`, `reason` |
| `{{core_action}}_performed` | {{trigger}} | `{{properties}}` |

### Funnel Tracking

Identify your critical funnels from the PRD and instrument them explicitly.

```typescript
// Track funnel steps consistently
const FUNNELS = {
    signup: ['page_viewed_signup', 'signup_form_started', 'user_signed_up', 'onboarding_completed'],
    core_action: ['{{step_1}}', '{{step_2}}', '{{step_3}}', '{{conversion_event}}'],
    upgrade: ['upgrade_prompted', 'pricing_viewed', 'checkout_started', 'subscription_started'],
}

// Instrument each step
trackEvent('signup_form_started', { source: document.referrer })
```

### Identifying Users

```typescript
// Call immediately after login / signup
identifyUser(user.id, {
    email: user.email,
    name: user.name,
    plan: user.plan,
    created_at: user.created_at,
    // Add any product-specific traits from PRD
    {{trait_1}}: user.{{field}},
})
```

### Server-Side Events (Python)

```python
from posthog import Posthog

posthog = Posthog(
    project_api_key=os.getenv('POSTHOG_API_KEY'),
    host='https://app.posthog.com'
)

# Send server-side events (webhooks, background jobs, bot interactions)
posthog.capture(
    distinct_id=user_id,
    event='{{event_name}}',
    properties={'{{key}}': '{{value}}'}
)
```

### Feature Flags

Use PostHog feature flags to control rollout and run A/B tests without deploys.

```typescript
import { useFeatureFlagEnabled } from 'posthog-js/react'

function MyComponent() {
    const newDashboardEnabled = useFeatureFlagEnabled('new-dashboard')
    return newDashboardEnabled ? <NewDashboard /> : <OldDashboard />
}
```

---

## Error Monitoring

### Sentry Setup

```bash
npm install @sentry/nextjs
# Run the wizard:
npx @sentry/wizard@latest -i nextjs
```

```typescript
// sentry.client.config.ts
import * as Sentry from '@sentry/nextjs'

Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
    tracesSampleRate: 0.1,          // 10% of transactions
    replaysSessionSampleRate: 0.1,  // 10% of sessions
    replaysOnErrorSampleRate: 1.0,  // 100% when errors occur
    environment: process.env.NODE_ENV,
    beforeSend(event) {
        // Scrub PII before sending
        if (event.user) {
            delete event.user.email
            delete event.user.ip_address
        }
        return event
    }
})
```

```python
# backend — pip install sentry-sdk
import sentry_sdk
sentry_sdk.init(
    dsn=os.getenv('SENTRY_DSN'),
    traces_sample_rate=0.1,
    environment=os.getenv('ENVIRONMENT', 'development'),
    before_send=lambda event, hint: None if os.getenv('ENVIRONMENT') == 'development' else event
)
```

### Error Boundary (React)

```tsx
import { ErrorBoundary } from '@sentry/nextjs'

function ErrorFallback({ error, resetError }: { error: Error; resetError: () => void }) {
    return (
        <div className="flex flex-col items-center justify-center h-64 text-center px-6">
            <p className="text-sm text-secondary">Something went wrong loading this view.</p>
            <button onClick={resetError} className="mt-3 text-sm text-accent hover:opacity-80">
                Try again
            </button>
        </div>
    )
}

// Wrap every page
<ErrorBoundary fallback={ErrorFallback}>
    <YourPageContent />
</ErrorBoundary>
```

---

## Email Service

### Resend Setup

Resend is the cleanest option for transactional email with React templates.

```bash
npm install resend react-email @react-email/components
```

```typescript
// lib/email.ts
import { Resend } from 'resend'

const resend = new Resend(process.env.RESEND_API_KEY)

export async function sendEmail({
    to, subject, template, props
}: {
    to: string
    subject: string
    template: React.ComponentType<any>
    props: Record<string, unknown>
}) {
    const { data, error } = await resend.emails.send({
        from: '{{SENDER_NAME}} <{{SENDER_EMAIL}}>',
        to,
        subject,
        react: template(props),
    })
    if (error) throw new Error(`Email failed: ${error.message}`)
    return data
}
```

### Email Templates to Build

Every product needs these. Build them before you need them.

| Template | Trigger | Key Variables |
|----------|---------|--------------|
| `WelcomeEmail` | User signs up | `name`, `product_name`, `cta_url` |
| `OnboardingReminder` | 24h after signup, onboarding not complete | `name`, `onboarding_url`, `step_stuck_on` |
| `MagicLink` / `PasswordReset` | Auth actions | `reset_url`, `expires_in` |
| `WeeklyDigest` | Every Sunday (if applicable) | `name`, `stats`, `highlights` |
| `UsageMilestone` | Key milestones | `name`, `milestone`, `next_milestone` |
| `TrialExpiring` | 3 days before trial ends | `name`, `days_left`, `upgrade_url` |
| `PaymentFailed` | Stripe/Razorpay webhook | `name`, `retry_url`, `amount` |
| `AccountDeleted` | User deletes account | `name`, feedback form link |

```tsx
// emails/WelcomeEmail.tsx
import { Html, Head, Body, Container, Text, Button, Hr } from '@react-email/components'

interface WelcomeEmailProps {
    name: string
    ctaUrl: string
}

export default function WelcomeEmail({ name, ctaUrl }: WelcomeEmailProps) {
    return (
        <Html>
            <Head />
            <Body style={{ fontFamily: 'sans-serif', backgroundColor: '#f9fafb' }}>
                <Container style={{ maxWidth: '560px', margin: '0 auto', padding: '40px 20px' }}>
                    <Text style={{ fontSize: '24px', fontWeight: 'bold' }}>
                        Welcome, {name}.
                    </Text>
                    <Text style={{ color: '#6b7280' }}>
                        {{Personalized welcome message from brand voice.}}
                    </Text>
                    <Button href={ctaUrl} style={{ backgroundColor: '{{PRIMARY_COLOR}}', color: '#fff', padding: '12px 24px', borderRadius: '6px' }}>
                        {{CTA text}}
                    </Button>
                    <Hr />
                    <Text style={{ color: '#9ca3af', fontSize: '12px' }}>
                        {{Product name}} · {{Address}} · 
                        <a href="{{unsubscribe_url}}">Unsubscribe</a>
                    </Text>
                </Container>
            </Body>
        </Html>
    )
}
```

---

## Payment Integration

> Skip this section if the MVP has no monetization. Come back at V2.

### Stripe Setup

```bash
npm install stripe @stripe/stripe-js @stripe/react-stripe-js
pip install stripe  # backend
```

**Webhook handler pattern (backend):**

```python
import stripe
from fastapi import Request, HTTPException

stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET')

@app.post('/webhooks/stripe')
async def handle_stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get('stripe-signature')
    
    try:
        event = stripe.Webhook.construct_event(payload, sig_header, webhook_secret)
    except (ValueError, stripe.error.SignatureVerificationError):
        raise HTTPException(status_code=400, detail="Invalid signature")
    
    handlers = {
        'checkout.session.completed':    handle_checkout_completed,
        'customer.subscription.created': handle_subscription_created,
        'customer.subscription.deleted': handle_subscription_deleted,
        'invoice.payment_failed':        handle_payment_failed,
        'invoice.payment_succeeded':     handle_payment_succeeded,
    }
    
    handler = handlers.get(event['type'])
    if handler:
        await handler(event['data']['object'])
    
    return {"status": "ok"}
```

**Track payment events in analytics:**

```python
async def handle_checkout_completed(session):
    await update_user_plan(session['client_reference_id'], plan='pro')
    posthog.capture(
        distinct_id=session['client_reference_id'],
        event='subscription_started',
        properties={
            'plan': 'pro',
            'amount': session['amount_total'] / 100,
            'currency': session['currency'],
        }
    )
```

### Pricing Page Pattern

```tsx
// components/pricing/PricingCard.tsx
interface Plan {
    name: string
    price: number
    currency: string
    interval: 'month' | 'year'
    features: string[]
    ctaText: string
    stripePriceId: string
    highlighted?: boolean
}

async function handleCheckout(priceId: string, userId: string) {
    trackEvent('checkout_started', { price_id: priceId })
    const res = await fetch('/api/checkout', {
        method: 'POST',
        body: JSON.stringify({ priceId, userId }),
    })
    const { url } = await res.json()
    window.location.href = url
}
```

---

## Database Schema

> Replace all `{{placeholder}}` values with your actual domain entities from the PRD.

### Schema Design Principles

1. Every table has `id UUID PRIMARY KEY DEFAULT gen_random_uuid()`
2. Every table has `created_at TIMESTAMPTZ DEFAULT NOW()`
3. Every mutable table has `updated_at TIMESTAMPTZ DEFAULT NOW()`
4. Every user-owned table has `user_id UUID REFERENCES users(id) ON DELETE CASCADE`
5. Add RLS to every table. Service role bypasses RLS for backend writes.
6. Every enum used in multiple tables is a PostgreSQL custom type.

### Custom Enum Types

```sql
-- Define all enums before tables
CREATE TYPE {{enum_1}} AS ENUM ('{{val_a}}', '{{val_b}}', '{{val_c}}');
CREATE TYPE {{enum_2}} AS ENUM ('{{val_a}}', '{{val_b}}');
-- e.g.:
-- CREATE TYPE subscription_plan AS ENUM ('free', 'pro', 'enterprise');
-- CREATE TYPE entity_status    AS ENUM ('active', 'archived', 'deleted');
```

### Core Tables

**users**

```sql
CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT UNIQUE NOT NULL,
    name          TEXT,
    avatar_url    TEXT,
    plan          TEXT DEFAULT 'free',
    plan_expires_at TIMESTAMPTZ,
    stripe_customer_id TEXT,
    onboarding_completed_at TIMESTAMPTZ,
    onboarding_step INTEGER DEFAULT 0,
    timezone      TEXT DEFAULT 'UTC',
    notification_email_enabled BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);
```

**{{primary_entity}} — your main domain object**

```sql
CREATE TABLE {{entities}} (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    -- core fields from PRD
    {{field_1}}   TEXT NOT NULL,
    {{field_2}}   {{type}},
    status        {{enum_1}} DEFAULT '{{default}}',
    -- metadata
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_{{entities}}_user    ON {{entities}}(user_id);
CREATE INDEX idx_{{entities}}_status  ON {{entities}}(user_id, status);
```

**activity_feed — denormalized event log for real-time UI**

```sql
CREATE TABLE activity_feed (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
    event_type    TEXT NOT NULL,
    title         TEXT NOT NULL,
    description   TEXT,
    entity_id     UUID,
    entity_type   TEXT,
    metadata      JSONB DEFAULT '{}',
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_user ON activity_feed(user_id, created_at DESC);
```

**waitlist**

```sql
CREATE TABLE waitlist (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email      TEXT NOT NULL UNIQUE,
    source     TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE waitlist ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can join waitlist" ON waitlist FOR INSERT WITH CHECK (true);
CREATE POLICY "No public reads"          ON waitlist FOR SELECT USING (false);
```

### Row Level Security

```sql
-- Pattern: apply to every user-owned table
ALTER TABLE {{table}} ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own their data" ON {{table}}
    FOR ALL USING (user_id = auth.uid());
```

### Supabase Auth Trigger

```sql
-- Auto-create users row on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();
```

### Supabase Realtime

```sql
-- Only publish tables the frontend subscribes to
ALTER PUBLICATION supabase_realtime ADD TABLE activity_feed;
ALTER PUBLICATION supabase_realtime ADD TABLE {{table_2}};
```

### Updated_at Trigger

```sql
-- Apply to every table with updated_at
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON {{table}}
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

## File Structure

### Backend

```
backend/
├── main.py                  # App init, routes, startup
├── {{core_feature}}/
│   ├── pipeline.py          # Staged processing pipeline
│   ├── prompts.py           # All AI prompts (single source of truth)
│   └── validators.py        # Input/output validation
├── db/
│   ├── client.py            # DB client init
│   ├── {{entity_1}}.py      # CRUD for entity 1
│   └── {{entity_2}}.py      # CRUD for entity 2
├── jobs/
│   ├── scheduler.py         # Job runner setup
│   ├── {{job_1}}.py         # e.g. reminders, digests
│   └── {{job_2}}.py
├── integrations/
│   ├── stripe.py            # Payment webhooks
│   ├── email.py             # Email sending
│   └── {{external_api}}.py
├── middleware/
│   ├── auth.py              # Token verification
│   └── rate_limit.py
├── requirements.txt
└── Procfile
```

### Frontend

```
frontend/
├── app/
│   ├── layout.tsx               # Root: fonts, analytics init, error boundary
│   ├── page.tsx                 # Landing page
│   ├── (auth)/
│   │   ├── login/page.tsx
│   │   ├── signup/page.tsx
│   │   └── forgot-password/page.tsx
│   ├── onboarding/page.tsx
│   ├── dashboard/
│   │   ├── layout.tsx           # Shell: nav, auth guard, realtime sub
│   │   ├── page.tsx             # Home / overview
│   │   ├── {{section_1}}/page.tsx
│   │   └── {{section_2}}/page.tsx
│   ├── settings/
│   │   ├── page.tsx             # Account settings
│   │   └── billing/page.tsx     # Plan + payment
│   └── manifest.ts              # PWA manifest
├── components/
│   ├── ui/                      # Primitives: Button, Card, Input, Modal, Toast
│   ├── dashboard/               # Dashboard-specific components
│   ├── landing/                 # Landing page sections
│   └── emails/                  # React Email templates
├── lib/
│   ├── analytics.ts             # PostHog wrapper
│   ├── supabase.ts              # Browser client
│   ├── supabase-server.ts       # Server client
│   ├── api.ts                   # API call helpers
│   └── utils.ts                 # Formatting, dates, etc.
├── middleware.ts                # Auth + route protection
└── tailwind.config.ts
```

---

## API Design

### Route Conventions

```
GET    /api/{{entities}}              List (with pagination)
POST   /api/{{entities}}              Create
GET    /api/{{entities}}/{{id}}       Get single
PATCH  /api/{{entities}}/{{id}}       Update
DELETE /api/{{entities}}/{{id}}       Delete
POST   /api/{{entities}}/{{action}}   Non-CRUD action

GET    /api/me                        Current user profile
PATCH  /api/me                        Update profile
DELETE /api/me                        Delete account (GDPR)
```

### Auth Middleware Pattern

```typescript
// middleware.ts
import { createServerClient } from '@supabase/ssr'
import { NextResponse } from 'next/server'

const PUBLIC_ROUTES  = ['/', '/login', '/signup', '/forgot-password', '/waitlist']
const AUTH_REDIRECTS = ['/', '/login', '/signup']  // Redirect to /dashboard if logged in

export async function middleware(request: NextRequest) {
    const response = NextResponse.next()
    const supabase = createServerClient(...)
    const { data: { user } } = await supabase.auth.getUser()
    const path = request.nextUrl.pathname
    
    if (!user && !PUBLIC_ROUTES.some(r => path.startsWith(r))) {
        return NextResponse.redirect(new URL('/login', request.url))
    }
    if (user && AUTH_REDIRECTS.includes(path)) {
        return NextResponse.redirect(new URL('/dashboard', request.url))
    }
    return response
}
```

### Standard API Response Shape

```typescript
// Always return this shape from API routes
type ApiResponse<T> = {
    data?: T
    error?: { code: string; message: string }
    meta?: { total: number; page: number; per_page: number }
}
```

---

## AI Integration (if applicable)

### Prompt Management

```python
# ai/prompts.py — single source of truth for ALL prompts
# Never inline prompts in handler code

EXTRACTION_PROMPT = """{{system prompt for your use case}}

Return ONLY valid JSON with these fields:
{
    "{{field_1}}": "{{description}}",
    "{{field_2}}": "{{description}}",
    "confidence": 0.0 to 1.0
}

Rules:
- {{rule 1}}
- {{rule 2}}
"""

ANALYSIS_PROMPT = """{{prompt for analysis use case}}"""
SUMMARY_PROMPT  = """{{prompt for summary use case}}"""
```

### Output Validation

```python
from dataclasses import dataclass
from typing import Optional

VALID_{{ENUM_FIELD}} = {'{{val_1}}', '{{val_2}}', '{{val_3}}'}

@dataclass
class AIResult:
    {{field_1}}: Optional[str] = None
    {{field_2}}: Optional[str] = None
    confidence: float = 0.0
    raw_json: Optional[dict] = None

def validate_ai_output(raw_json: dict) -> AIResult:
    result = AIResult()
    result.{{field_1}} = _clean_string(raw_json.get('{{field_1}}'))
    
    # Enum clamping
    val = _clean_string(raw_json.get('{{enum_field}}'))
    result.{{enum_field}} = val if val in VALID_{{ENUM_FIELD}} else '{{default}}'
    
    # Numeric clamping
    try:
        conf = float(raw_json.get('confidence', 0))
        result.confidence = max(0.0, min(1.0, conf))
    except (TypeError, ValueError):
        result.confidence = 0.0
    
    result.raw_json = raw_json
    return result

def _clean_string(val) -> Optional[str]:
    if val is None: return None
    s = str(val).strip()
    return s if s and s.lower() not in ('null', 'none', 'n/a', '') else None
```

### JSON Parse Safety

```python
import json, re

def parse_ai_json(raw_text: str) -> dict:
    text = raw_text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    fence_match = re.search(r'```(?:json)?\s*\n?(.*?)\n?```', text, re.DOTALL)
    if fence_match:
        try:
            return json.loads(fence_match.group(1).strip())
        except json.JSONDecodeError:
            pass
    first, last = text.find('{'), text.rfind('}')
    if first != -1 and last > first:
        try:
            return json.loads(text[first:last + 1])
        except json.JSONDecodeError:
            pass
    logger.error(f"Failed to parse AI JSON: {text[:200]}")
    return {}
```

---

## Security Checklist

Complete these before any external user touches the product.

### Authentication

- [ ] All sensitive routes require authentication (middleware enforces this)
- [ ] Tokens expire — short-lived access tokens, refresh token rotation enabled
- [ ] Magic links / reset tokens are single-use and expire in 1 hour
- [ ] Failed login attempts are rate-limited
- [ ] Passwords are never logged

### Database

- [ ] RLS enabled on every table
- [ ] Service role key is server-only (never in frontend env vars)
- [ ] Anon key is scoped to read-only where applicable
- [ ] No raw SQL queries with string interpolation (use parameterized queries)
- [ ] GDPR: DELETE account cascades to all user data

### API

- [ ] All API routes validate input (Zod on frontend, Pydantic on backend)
- [ ] File uploads: type validation, size limits, stored outside public directory
- [ ] Webhook endpoints verify signatures before processing
- [ ] CORS is configured (not `*` in production)
- [ ] Rate limiting on all API routes (not just the bot)

### Frontend

- [ ] No secrets in client-side code or env vars with `NEXT_PUBLIC_` prefix except safe keys
- [ ] Content Security Policy headers set
- [ ] User-provided content is sanitized before rendering (no `dangerouslySetInnerHTML` with user content)
- [ ] Session replay (PostHog / FullStory) masks all form inputs

### Infrastructure

- [ ] All services use environment variables (no hardcoded keys anywhere)
- [ ] Production and development use separate Supabase projects / databases
- [ ] Database backups are enabled (Supabase handles this automatically on paid plans)
- [ ] Dependency audit run: `npm audit --production` and `pip-audit`

---

## Performance Targets

Set these before building. Measure against them before launching.

| Metric | Target | Tool |
|--------|--------|------|
| First Contentful Paint | < 1.5s | Lighthouse, Vercel Analytics |
| Time to Interactive | < 3s | Lighthouse |
| Core Web Vitals (LCP) | < 2.5s | Vercel Speed Insights |
| API response (P95) | < 500ms | Railway metrics |
| AI response (P95) | < 5s | Custom logging |
| Dashboard initial load | < 2s | Lighthouse |
| Realtime update lag | < 500ms | Manual test |

### Performance Patterns

```typescript
// Skeleton screens — never show blank pages or spinners
function PageSkeleton() {
    return (
        <div className="space-y-4">
            {[...Array(5)].map((_, i) => (
                <div key={i} className="h-16 bg-gray-100 rounded-lg animate-pulse" />
            ))}
        </div>
    )
}

// Staggered load animation — data feels fast even when it isn't
<div className={cn("animate-fade-in", { "animation-delay-100": index === 1, "animation-delay-200": index === 2 })}>

// Cache expensive queries
const { data } = await supabase
    .from('{{table}}')
    .select('*')
    .eq('user_id', userId)
    // Supabase caches automatically; use SWR or React Query on the client
```

---

## CI/CD Pipeline

### GitHub Actions — Full Pipeline

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  lint-and-type-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
        working-directory: frontend
      - run: npm run lint
        working-directory: frontend
      - run: npm run type-check
        working-directory: frontend

  test-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - run: pip install -r requirements.txt
        working-directory: backend
      - run: pytest tests/ -v
        working-directory: backend
        env:
          SUPABASE_URL: ${{ secrets.TEST_SUPABASE_URL }}
          SUPABASE_SERVICE_KEY: ${{ secrets.TEST_SUPABASE_SERVICE_KEY }}

  deploy-frontend:
    needs: [lint-and-type-check]
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          vercel-args: '--prod'

  # Railway auto-deploys on push to main — no action needed
  # Configure in Railway dashboard: Settings → Deploy → Auto Deploy on Push
```

### Branch Strategy

```
main          → production (auto-deploy to Vercel + Railway)
develop       → staging (optional, skip for solo builds)
feature/*     → pull requests only, no deploy
```

### Pre-Deploy Checklist (add to PR template)

```markdown
## Pre-Deploy Checklist
- [ ] New env vars added to Railway AND Vercel dashboards
- [ ] Database migrations run (if schema changed)
- [ ] New tables have RLS enabled
- [ ] New analytics events are instrumented
- [ ] Tested on mobile (390px) and desktop (1280px)
- [ ] No `console.log` with sensitive data
```

---

## Deployment Topology

```
GitHub (monorepo)
├── /frontend  → Vercel (auto-deploy on push to main)
│               Framework: Next.js
│               Env: NEXT_PUBLIC_* vars only
│
├── /backend   → Railway (Worker process, auto-deploy on push to main)
│               Procfile: worker: python main.py
│               Env: all secrets including service role key
│
└── Supabase (managed)
     ├── PostgreSQL
     ├── Auth
     ├── Realtime
     └── Storage
```

**Environment separation:**

| Environment | Supabase project | Vercel URL | Railway service |
|-------------|-----------------|-----------|----------------|
| Production  | {{project-prod}} | {{product}}.vercel.app | {{service-prod}} |
| Development | {{project-dev}}  | localhost:3000 | localhost:8000 |

---

## Environment Variables (Complete List)

### Backend (Railway)

```
# Database
SUPABASE_URL=https://{{project}}.supabase.co
SUPABASE_SERVICE_KEY=eyJ...          # service role, never public
SUPABASE_ANON_KEY=eyJ...

# App
ENVIRONMENT=production
LOG_LEVEL=INFO
FRONTEND_URL=https://{{product}}.vercel.app

# AI (if applicable)
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...                # if using OpenAI

# Email
RESEND_API_KEY=re_...

# Payments (if applicable)
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Analytics / Monitoring
POSTHOG_API_KEY=phc_...
SENTRY_DSN=https://...@sentry.io/...

# External integrations
{{EXTERNAL_API_KEY}}=...
```

### Frontend (Vercel)

```
# Database (public — only anon key)
NEXT_PUBLIC_SUPABASE_URL=https://{{project}}.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...

# Analytics (public keys only)
NEXT_PUBLIC_POSTHOG_KEY=phc_...
NEXT_PUBLIC_POSTHOG_HOST=https://app.posthog.com
NEXT_PUBLIC_SENTRY_DSN=https://...@sentry.io/...

# App config
NEXT_PUBLIC_APP_URL=https://{{product}}.vercel.app
NEXT_PUBLIC_APP_NAME={{Product Name}}

# Payments (public key only)
NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_live_...
```

---

## Known Limitations (Document Before Shipping)

> Fill this in from your PRD. Be honest. Users respect founders who are upfront about V1 scope.

| Limitation | Impact | Planned |
|------------|--------|---------|
| {{Limitation 1}} | {{Who it affects, how often}} | V2 |
| {{Limitation 2}} | {{Who it affects, how often}} | V2 |
| No mobile app (PWA only) | Power users on mobile may want native | Evaluate post-launch based on usage |
| No API / integrations | Can't connect to existing tools | V2 if requested by 10+ users |
| Single user (no teams) | Blocks enterprise use cases | V2 if deal value justifies it |

---

## Testing Checklist

Run through this before sharing with anyone outside the team.

### Auth + Onboarding
- [ ] Signup with email creates Auth user + users table row
- [ ] OAuth creates both
- [ ] Duplicate email shows correct error
- [ ] Invalid password shows inline validation
- [ ] Forgot password sends email
- [ ] Onboarding flow completes and redirects correctly
- [ ] Skipping onboarding persists the preference
- [ ] Protected routes redirect unauthenticated users

### Core Feature (from your PRD)
- [ ] {{Core action 1}} works end to end
- [ ] {{Core action 2}} works end to end
- [ ] {{Core action 3}} works end to end
- [ ] All empty states display correctly
- [ ] All error states display correctly (network, validation, server)

### Analytics
- [ ] PostHog receives `user_signed_up` event
- [ ] PostHog receives `onboarding_completed` event
- [ ] PostHog receives core action events
- [ ] User is identified in PostHog after login
- [ ] Session replay is recording (check PostHog dashboard)

### Email
- [ ] Welcome email arrives after signup (check spam)
- [ ] Password reset email arrives and link works
- [ ] Digest / notification emails arrive at correct time (if applicable)

### Payments (if applicable)
- [ ] Checkout flow completes in Stripe test mode
- [ ] Webhook fires and updates user plan
- [ ] Payment failed email sends correctly
- [ ] Cancellation flow works

### Monitoring
- [ ] Sentry receives test error (throw one deliberately)
- [ ] Sentry PII scrubbing is working (no emails in error payload)

### Performance
- [ ] Lighthouse score > 80 on mobile
- [ ] Core Web Vitals are green in Vercel Analytics
- [ ] No N+1 queries (check Supabase logs for repeated queries)

### Responsive
- [ ] All screens usable at 390px (iPhone SE)
- [ ] All screens usable at 768px (tablet)
- [ ] All screens usable at 1280px (laptop)
- [ ] Touch targets are 44px minimum on mobile
- [ ] Safe area insets correct on iPhone (notch) and Android (gesture bar)

### PWA
- [ ] Installs correctly on iOS (Safari → Add to Home Screen)
- [ ] Installs correctly on Android (Chrome → Install)
- [ ] Offline banner appears when network is lost
- [ ] App works with cached data when offline

---

## Launch Checklist

Complete these before any public announcement.

### Technical
- [ ] Custom domain configured on Vercel (not .vercel.app)
- [ ] SSL certificate active (automatic on Vercel)
- [ ] OG image is set and renders correctly (test with opengraph.xyz)
- [ ] Favicon is crisp at 16px and 32px
- [ ] robots.txt allows search engine crawling
- [ ] sitemap.xml exists at /sitemap.xml
- [ ] 404 page is custom (not Vercel default)
- [ ] All dead links fixed
- [ ] Console is clean (no errors, no `console.log` left in)
- [ ] Database backups confirmed active (Supabase dashboard)

### Analytics & Monitoring
- [ ] PostHog is receiving events in production
- [ ] Sentry is active and receiving test error
- [ ] Uptime monitoring set up (Better Uptime, UptimeRobot — free tier sufficient)
- [ ] Alerting configured: Sentry emails on error spike, uptime on downtime

### Legal / Compliance
- [ ] Privacy Policy page exists at /privacy (use termly.io or similar)
- [ ] Terms of Service page exists at /terms
- [ ] Cookie consent banner if tracking EU users (PostHog has built-in consent mode)
- [ ] Unsubscribe link in all marketing emails
- [ ] DELETE account deletes all user data (GDPR Article 17)

### User Experience
- [ ] Kill shot demo tested 3 times on actual phone (not simulator)
- [ ] Onboarding tested with someone who has never seen the product
- [ ] All email templates previewed in real email clients (Gmail, Apple Mail, Outlook)
- [ ] Loading states exist on every async action
- [ ] No blank white screens at any point in any flow

### Content
- [ ] Meta title and description set for all public pages
- [ ] Social preview (OG image) tests correctly on Twitter, LinkedIn, WhatsApp
- [ ] Pricing is accurate and up to date
- [ ] "Coming soon" is not used anywhere (either build it or don't mention it)

---

## Post-Launch: What to Track Week 1

These are the signals that tell you if your bets are working.

| North Star | What it measures | Target (set from PRD) |
|------------|-----------------|----------------------|
| {{North Star Metric}} | {{Definition}} | {{Week 1 target}} |

| Leading Indicator | What it predicts | Healthy range |
|------------------|-----------------|---------------|
| Onboarding completion rate | Activation | > {{X}}% |
| Day 1 retention | Initial value delivered | > {{X}}% |
| Core action completion (first session) | Aha moment | > {{X}}% |

| Counter-Metric | What it warns | Threshold |
|---------------|-------------|----------|
| Error rate | Technical stability | < 1% of sessions |
| Onboarding drop-off at step N | Friction point | > 40% drop = fix immediately |
| Support requests per active user | UX confusion | > 5% = investigate |

Check these every day for the first two weeks. Set up a PostHog dashboard before launch so you're not scrambling to build one while also responding to user feedback.
