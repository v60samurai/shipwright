# Inference Rules

When filling blueprint gaps, apply these rules. Always tell the user what was inferred and why.

## Product & Interface Inference

| Signal | Inference |
|--------|-----------|
| Category is B2C and no interface specified | Default: PWA, mobile-first |
| Category is B2B SaaS | Default: web-app, responsive, desktop-primary |
| Category is dev-tool | Default: CLI + optional web dashboard |
| Category is API service | Default: api-rest, no frontend, generate_design_system: false |
| Category is marketplace | Default: web-app for buyers + seller dashboard |
| Category is game | Default: game engine (Unity/Godot/web), skip standard web patterns |
| "Mobile" mentioned but no specific type | Default: PWA (simplest, most universal) |
| "App" mentioned generically | Default: web-app unless mobile context is clear |
| "Bot" mentioned with a platform | Use that platform's bot type |
| "Bot" mentioned without platform | Default: bot-telegram (widest reach, simplest API) |
| Multiple interfaces detected | Order by: input interface first, consumption interface second |
| "Extension" mentioned with host app | Use that host's extension type |
| "IoT" or "hardware" mentioned | Default: embedded-iot + companion web-app or mobile app |
| "Plugin" mentioned with host platform | Use that platform's plugin type |

## Architecture Inference

| Signal | Inference |
|--------|-----------|
| Single interface, no external services | Default: monolith |
| Frontend + backend as separate concerns | Default: client-server |
| "Real-time" or "live updates" mentioned | Add websocket or SSE to architecture, add realtime_needs |
| "Scheduled" or "cron" or "daily" mentioned | Add background_jobs |
| Multiple independent services | Default: microservices or serverless |
| AI/LLM mentioned anywhere | Add ai section to stack, suggest extraction/generation pipeline pattern |
| "Webhook" mentioned | Add event-driven elements to architecture |
| File uploads mentioned | Add storage to stack (S3, Supabase Storage, Cloudinary) |
| "Queue" or "async processing" mentioned | Add message queue to architecture |
| "Notification" or "push" mentioned | Add notification service to external_services |
| "Analytics" or "tracking" mentioned | Add analytics to external_services |
| "Search" with large dataset | Add search engine (Algolia, Typesense, Elasticsearch) |

## Stack Inference

| Signal | Inference |
|--------|-----------|
| No frontend preference stated | Default: Next.js + Tailwind CSS (most versatile, best AI support) |
| No backend preference stated | Infer from language context. Python → FastAPI. JS/TS → Next.js API routes or Hono. Go → standard library or Gin. Rust → Axum |
| No database preference stated | Default: PostgreSQL. If simple key-value → SQLite. If document-heavy → MongoDB |
| No auth preference stated | If Supabase → Supabase Auth. If Next.js → NextAuth/Clerk. If custom → session-based |
| No hosting preference stated | Frontend → Vercel. Backend → Railway or Vercel. Database → Supabase or Neon |
| AI mentioned but no model specified | Default: Claude Sonnet for extraction/reasoning, GPT for embeddings |
| "Payments" mentioned | Add Stripe to external_services |
| "Email" or "transactional email" mentioned | Add Resend or SendGrid to external_services |
| "Search" mentioned | Add full-text search to database or Algolia/Typesense to external_services |
| "SMS" mentioned | Add Twilio to external_services |
| "Maps" or "location" mentioned | Add Google Maps or Mapbox to external_services |
| "Video" or "streaming" mentioned | Add Mux or Cloudflare Stream to external_services |
| "PDF" mentioned | Add PDF generation library (puppeteer, react-pdf) to key_libraries |
| React Native or Flutter mentioned | Add mobile-specific state management (React Query, Riverpod) |
| CLI tool | Default: Node.js + Commander/Yargs or Python + Click/Typer or Rust + Clap |

## Design Inference

| Signal | Inference |
|--------|-----------|
| No design preferences stated at all | Default: dark mode, zinc/neutral palette, one accent color, system font stack |
| "Dashboard" or "admin" or "data-heavy" | Dark mode, dense layout, monospace for data |
| "Consumer" or "friendly" or "fun" | Light mode option, rounded corners, warmer palette |
| "Professional" or "enterprise" | Neutral palette, conservative typography, minimal animation |
| "Developer tool" | Dark mode, monospace-heavy, terminal aesthetic |
| No typography preference | Default: Inter/Geist for UI, mono for data |
| "Minimal" or "clean" mentioned | Reduce accent usage, increase whitespace, fewer borders |
| Brand guide provided | Extract all design decisions from it, override defaults |
| "Playful" or "creative" | Allow more accent colors, larger radii, more animation |
| "Premium" or "luxury" | Generous whitespace, high type contrast, lighter weights |
| CLI tool | ANSI colors, no design system needed unless TUI |
| Bot | No visual design needed, focus on message formatting rules |

## Resilience Inference

| Signal | Inference |
|--------|-----------|
| AI/LLM as external service | Always add: retry with backoff, JSON parse safety, validation layer, degradation to "saved raw, will process later" |
| Payment processor | Always add: idempotency key, webhook verification, retry on 5xx only |
| Third-party API (any) | Always add: retry with backoff (2 retries, exponential), circuit breaker if > 3 services |
| Database | Always add: connection retry, transaction pattern for multi-table writes |
| Realtime/websocket | Always add: reconnection with polling fallback |
| No resilience input at all | Generate degradation table for every external service automatically |
| User-generated content | Add input sanitization, size limits, rate limiting |
| File uploads | Add file type validation, size limits, virus scanning consideration |

## Constraint Inference

| Signal | Inference |
|--------|-----------|
| "Weekend" or "hackathon" | time: "2 days", compress sessions, cut polish guide |
| "Sprint" or "1 week" | time: "5-7 days", full session set |
| "MVP" with no time given | Default: time: "1 week" |
| "Solo" or "just me" | team: "solo with AI" |
| No team info | Default: team: "solo with AI" |
| No forbidden patterns | Infer from stack: React → no class components. TypeScript → no any. Standard best practices |
| "Production" or "launch" mentioned | Add performance targets, monitoring, error tracking to requirements |
| "Prototype" or "proof of concept" | Reduce polish, skip design system, minimal testing |

## Conflict Resolution

When input contradicts itself:
- "No database" but features need persistence → ask user to clarify, suggest SQLite as minimal option
- Multiple stacks mentioned → ask which is primary, which is secondary
- Time constraint impossible for feature set → present tradeoff: cut features or extend time
- Brand guide conflicts with stated preferences → brand guide wins (it's more deliberate)
