# Final Push Guide: {{PRODUCT_NAME}}

> The 5% that makes 95% of the difference.
> Nothing here adds features. Everything adds feeling.
> Read this before Session 12. Run it during Session 12.

---

## Part 1: The Kill Shot (Demo)

Every product needs a moment where the evaluator, investor, or user understands what just happened and wants it. This is that moment. Design it deliberately, not accidentally.

### Define Your Kill Shot

Answer these before building the demo flow:

- **The action:** What does the user do? (30 seconds or less. One tap, one input, one interaction.)
- **The wait:** How long until the result? (Under 10 seconds is magic. 10-30 is fine. 30+ loses the room.)
- **The reveal:** What does the user see that proves the product worked?
- **The line:** What do you say after the reveal? (One sentence. Don't explain. Just land it.)

**Template:**
```
[PRESENTER does {{one simple action}}.]
[{{X}} seconds of silence. Audience watches the screen.]
[{{The reveal happens on screen — data appears, dashboard updates, result is shown}}.]
[PRESENTER says: "{{One sentence that names what just happened and why it matters.}}"]
```

**HustlrAI example for reference:**
> *Records a 30-second voice note about a sales call.*
> *5 seconds. Dashboard updates live. Contact card slides in. Follow-up is scheduled.*
> "That took me 30 seconds. The CRM built itself."

### Demo Account Preparation

Pre-seed realistic data before the demo. A lived-in product is more convincing than an empty one.

```python
# backend/scripts/seed_demo.py — admin-only script
# Run against your demo account before presentations

DEMO_DATA = {
    "{{entity_type_1}}": [
        {"{{field}}": "{{value}}", "{{field}}": "{{value}}"},
        {"{{field}}": "{{value}}", "{{field}}": "{{value}}"},
        # 5-8 records is enough to look lived-in without being overwhelming
    ],
    "{{entity_type_2}}": [
        # Mix of statuses: some active, some completed, one at risk
    ],
}

# Run: python scripts/seed_demo.py --user-id {{demo_user_id}} --env production
```

**Demo account rules:**
- Use a real account (not localhost) with a real login
- Pre-seed data the day before, not 5 minutes before
- Test the kill shot 3 times on the actual device you'll use for the demo
- Have a backup: a recording of the kill shot in case the live demo breaks

---

## Part 2: Bot / Input Formatting (if applicable)

> If your product has a Telegram bot, CLI, or any text-based interface, this section applies.
> Skip if your product is web-only.

### Response Structure Principles

Every automated response should follow this hierarchy:
1. **Confirmation** — what action was taken (one line, bold)
2. **Summary** — what was extracted/processed (2-3 lines)
3. **Next steps** — what's scheduled or required (if any)
4. **Milestone** (optional) — if the user hit a threshold

```python
def format_response(result: dict, milestone_line: str | None = None) -> str:
    """
    Build a MarkdownV2 response for Telegram (or plain markdown for other surfaces).
    Adapt the emoji and structure to your product's tone from the Brand Guide.
    """
    msg = f"*{{Opening word}}* {escape_md(result.get('primary_field', ''))}\n\n"
    
    # Core extracted fields
    if result.get('{{field_1}}'):
        msg += f"{{emoji}} {escape_md(result['{{field_1}}'])}\n"
    if result.get('{{field_2}}'):
        msg += f"{{emoji}} {escape_md(result['{{field_2}}'])}\n"
    
    # Next steps
    for step in result.get('next_steps', []):
        msg += f"⏰ {escape_md(step)}\n"
    
    # Milestone (appended, not shown every time)
    if milestone_line:
        msg += f"\n_{escape_md(milestone_line)}_"
    
    return msg
```

### Personality Variation

Vary the opening word based on context. Tiny variation. Zero AI cost. Prevents the interface from feeling robotic.

```python
def opening_word(context: dict) -> str:
    if context.get('no_action_items'):
        return "Noted."
    if context.get('high_frequency_user'):  # 3+ actions in 5 min
        return "Logged."
    return "Got it."
```

### Processing Indicator

Show feedback immediately — don't let users wonder if something is happening.

```python
async def handle_input(update, context):
    # 1. Immediately acknowledge
    await update.message.chat.send_action("typing")
    
    # 2. For long operations (AI, transcription): send interim message
    interim = await update.message.reply_text("_Processing{{...}}_", parse_mode="MarkdownV2")
    
    # 3. Process
    result = await run_pipeline(input_data)
    
    # 4. Replace interim with result
    await interim.edit_text(format_response(result), parse_mode="MarkdownV2")
```

---

## Part 3: Dashboard Micro-Details

These are the things evaluators notice without being able to name. Each one takes under 30 minutes. Together they're the difference between "this looks like a student project" and "this feels like a product."

### Contextual Greeting

Replace "Welcome back" with a greeting that uses real data.

```typescript
function getGreeting(user: User, data: DashboardData): string {
    const hour = new Date().getHours()
    const timePrefix = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
    const firstName = user.name?.split(' ')[0] || ''
    
    // Build a data-driven suffix
    const pending = data.{{action_items}}.filter(i => i.status === 'pending' && isPast(i.due_date))
    const atRisk = data.{{entities}}.filter(e => e.health === 'at_risk')
    
    let suffix = ''
    if (pending.length > 0) {
        suffix = ` ${pending.length} overdue.`
    } else if (atRisk.length > 0) {
        suffix = ` ${atRisk.length} need${atRisk.length === 1 ? 's' : ''} attention.`
    } else {
        suffix = " Everything looks clean."
    }
    
    return `${timePrefix}${firstName ? `, ${firstName}` : ''}.${suffix}`
}
```

### Deterministic Avatar Colors

Same color every time for the same name. The user's brain starts pattern-matching avatars before reading the text.

```typescript
const AVATAR_COLORS = [
    '{{primary_color}}',  // brand color first
    '#4A7FB5',            // adjust to brand palette
    '#3D8C5C',
    '#8B5CF6',
    '#C44D3E',
    '#C9962B',
    '#2D9C9C',
]

function getAvatarColor(name: string): string {
    let hash = 0
    for (let i = 0; i < name.length; i++) {
        hash = name.charCodeAt(i) + ((hash << 5) - hash)
    }
    return AVATAR_COLORS[Math.abs(hash) % AVATAR_COLORS.length]
}

function Avatar({ name, size = 40 }: { name: string; size?: number }) {
    const color = getAvatarColor(name)
    return (
        <div style={{ width: size, height: size, backgroundColor: color, borderRadius: '50%' }}
             className="flex items-center justify-center text-white font-medium">
            {name.charAt(0).toUpperCase()}
        </div>
    )
}
```

### Relative Time (Always)

Never show raw timestamps to users.

```typescript
export function relativeTime(date: Date | string): string {
    const d = typeof date === 'string' ? new Date(date) : date
    const diff = Date.now() - d.getTime()
    const minutes = Math.floor(diff / 60000)
    const hours = Math.floor(diff / 3600000)
    const days = Math.floor(diff / 86400000)
    
    if (minutes < 1)  return 'Just now'
    if (minutes < 60) return `${minutes}m ago`
    if (hours < 24)   return `${hours}h ago`
    if (days === 1)   return 'Yesterday'
    if (days < 7)     return `${days}d ago`
    if (days < 30)    return `${Math.floor(days / 7)}w ago`
    return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short' })
}
```

### Animated Number on Real-Time Updates

When a metric changes, count up to the new value instead of snapping.

```typescript
function AnimatedNumber({ value, className }: { value: number; className?: string }) {
    const [display, setDisplay] = useState(value)
    const prevRef = useRef(value)
    
    useEffect(() => {
        const prev = prevRef.current
        if (prev === value) return
        const duration = 200
        const start = performance.now()
        function tick(now: number) {
            const progress = Math.min((now - start) / duration, 1)
            const eased = 1 - Math.pow(1 - progress, 3)
            setDisplay(Math.round(prev + (value - prev) * eased))
            if (progress < 1) requestAnimationFrame(tick)
        }
        requestAnimationFrame(tick)
        prevRef.current = value
    }, [value])
    
    return <span className={className}>{display.toLocaleString()}</span>
}
```

### Card Arrival Animation

New items from realtime subscriptions should animate in, not just appear.

```css
/* tailwind.config.ts — add to theme.extend.keyframes and theme.extend.animation */
@keyframes card-arrive {
    from { opacity: 0; transform: translateY(8px); }
    to   { opacity: 1; transform: translateY(0); }
}
.animate-card-arrive { animation: card-arrive 300ms ease-out both; }
```

```tsx
// Apply to items arriving from realtime subscription (not initial page load)
const isNew = newItemIds.has(item.id)
<div className={cn("...", isNew && "animate-card-arrive")}>
```

### Visual Timeline Component

For any entity detail view with a history, use a connected timeline instead of a flat list.

```tsx
function Timeline({ items }: { items: TimelineItem[] }) {
    return (
        <div className="relative pl-8">
            {/* Connecting line */}
            <div className="absolute left-3 top-2 bottom-2 w-px bg-border" />
            
            {items.map((item) => (
                <div key={item.id} className="relative pb-6 last:pb-0">
                    {/* Node — color-coded by type or sentiment */}
                    <div className={cn(
                        "absolute left-[-20px] top-1 w-2.5 h-2.5 rounded-full border-2 border-surface",
                        item.sentiment === 'positive' && "bg-green-500",
                        item.sentiment === 'negative' && "bg-red-500",
                        !item.sentiment && "bg-text-muted"
                    )} />
                    
                    <div>
                        <div className="flex items-center gap-2 mb-1">
                            <TypeIcon type={item.type} className="w-4 h-4 text-muted" />
                            <span className="text-xs font-mono text-muted">{relativeTime(item.created_at)}</span>
                        </div>
                        <p className="text-sm">{item.summary}</p>
                        {item.action && (
                            <p className="text-xs text-warning mt-1">⏰ {item.action}</p>
                        )}
                    </div>
                </div>
            ))}
        </div>
    )
}
```

### Skeleton Screens (Not Spinners)

Every page has a skeleton that matches the exact layout of the real content.

```tsx
// Match your actual page layout, not a generic shimmer
function DashboardHomeSkeleton() {
    return (
        <div className="space-y-6 p-4">
            {/* Greeting */}
            <div className="h-7 w-48 rounded-md bg-surface-raise animate-pulse" />
            
            {/* Action items section */}
            <div className="space-y-3">
                <div className="h-4 w-32 rounded bg-surface-raise animate-pulse" />
                {[...Array(3)].map((_, i) => (
                    <div key={i} className="h-20 rounded-xl bg-surface-raise animate-pulse" />
                ))}
            </div>
            
            {/* Metrics bar */}
            <div className="h-12 rounded-xl bg-surface-raise animate-pulse" />
            
            {/* Activity */}
            {[...Array(5)].map((_, i) => (
                <div key={i} className="h-14 rounded-lg bg-surface-raise animate-pulse" />
            ))}
        </div>
    )
}
```

### Optimistic UI (All Write Actions)

```typescript
// Template: apply to any write action (mark done, update, delete, etc.)
async function performAction(id: string, optimisticUpdate: Partial<Entity>) {
    const previous = items.find(i => i.id === id)
    
    // Immediately update UI
    setItems(prev => prev.map(i => i.id === id ? { ...i, ...optimisticUpdate } : i))
    
    try {
        await api.update(id, optimisticUpdate)
        // Optionally: refetch to sync server state
    } catch {
        // Revert
        setItems(prev => prev.map(i => i.id === id ? previous! : i))
        toast.error("Couldn't save that. Try again.")
    }
}
```

### Staggered Load Animation

```tsx
// Apply delay classes to sections as they load in
{sections.map((section, index) => (
    <div
        key={section.id}
        className="animate-fade-in"
        style={{ animationDelay: `${index * 100}ms` }}
    >
        {section.content}
    </div>
))}
```

```css
@keyframes fade-in {
    from { opacity: 0; transform: translateY(6px); }
    to   { opacity: 1; transform: translateY(0); }
}
.animate-fade-in { animation: fade-in 300ms ease-out both; }
```

---

## Part 4: Landing Page Refinement

The landing page is done from Session 2. This section covers what to change or add based on what you know now that the product is built.

### Checklist Before Launch

- [ ] **Hero headline** reflects the actual core value, not the aspirational pitch. Change it if the product's value turned out differently than the PRD assumed.
- [ ] **The demo widget** shows the real product flow, not a hypothetical one. If you built a live demo component, it uses real data patterns.
- [ ] **Pricing section** reflects actual prices and feature gating (which features are gated was probably decided during build).
- [ ] **Testimonials** are either real quotes (from beta users) or clearly labeled as fictional. No fake-looking placeholders.
- [ ] **FAQ** answers the questions real users asked during beta, not the questions you assumed they'd ask.
- [ ] **CTA** is the real action: either waitlist (if not launched), signup (if launched), or something else. No hedging.

### Live Demo Widget

Build this only if it can accurately represent the product's core loop.

```tsx
// components/landing/LiveDemo.tsx
// Auto-playing demonstration of the core loop
// Uses hardcoded realistic data — no API calls

const DEMO_SCRIPT = [
    // Step 1: User input
    { type: 'input', content: '{{Realistic user input example}}', delay: 0 },
    // Step 2: Processing state
    { type: 'processing', content: 'Processing...', delay: 1500 },
    // Step 3: Output / result
    { type: 'output', fields: [
        { label: '{{Field 1}}', value: '{{Realistic value}}' },
        { label: '{{Field 2}}', value: '{{Realistic value}}' },
    ], delay: 3000 },
]

export function LiveDemo() {
    const [step, setStep] = useState(0)
    const [typing, setTyping] = useState('')
    
    useEffect(() => {
        // Auto-advance through script, loop every 12 seconds
        const timer = setInterval(() => {
            setStep(s => (s + 1) % DEMO_SCRIPT.length)
        }, 12000)
        return () => clearInterval(timer)
    }, [])
    
    // Render current step with typewriter animation
    return (
        <div className="{{phone-mockup-classes}}">
            {/* Render DEMO_SCRIPT[step] with typewriter for input, fade for output */}
        </div>
    )
}
```

### Social Proof Before You Have It

If you don't have real users yet, don't fake testimonials. Use these instead:
- **Usage numbers:** "Built by {{your background}}. Tested across {{N}} real sales pipelines."
- **Problem validation:** "{{X}}% of founders track deals in spreadsheets." (cite a real source)
- **Beta feedback:** If you ran a beta, use direct quotes from beta users (with permission)
- **Founder credibility:** Your own story of the problem. Founders buy from founders who've felt the pain.

---

## Part 5: Milestone Moments

Design these before Session 12. They are the product's version of "congratulations" — they should feel earned, not generic.

### Milestone Trigger Framework

```python
MILESTONES = {
    # Key thresholds from the product's core loop
    1:  "{{Message for first completion. Should feel like a beginning, not an achievement.}}",
    5:  "{{Message for 5 completions. Reference what they now have that they didn't before.}}",
    10: "{{Message for 10 completions. Use a specific number from their data.}}",
    # Add product-specific milestones:
    # "first_win": "{{Message for first conversion / success event}}",
    # "streak_7":  "{{Message for 7-day streak}}",
}

async def check_milestone(user_id: str, entity_count: int, context: dict) -> str | None:
    # Never repeat a milestone
    triggered = await get_triggered_milestones(user_id)
    
    if entity_count in MILESTONES and entity_count not in triggered:
        await record_milestone(user_id, entity_count)
        return MILESTONES[entity_count]
    
    # Product-specific: check non-count milestones
    if context.get('first_win') and 'first_win' not in triggered:
        await record_milestone(user_id, 'first_win')
        return MILESTONES['first_win']
    
    return None
```

**Rules for milestone messages:**
- Reference a specific number from their actual data when possible
- Never use "Congratulations" or "Great job"
- Focus on what they now have, not what they did
- Keep under 15 words
- Match the product's voice from the Brand Guide

---

## Part 6: Invisible Technical Polish

Things no one sees but everyone feels.

### Tab Title

```typescript
// Updates the browser tab with actionable context
useEffect(() => {
    const count = {{actionItems}}.filter(i => i.status === 'pending' && isPast(i.due_date)).length
    document.title = count > 0 ? `{{Product Name}} (${count})` : '{{Product Name}}'
}, [{{actionItems}}])
```

### Keyboard Shortcuts

```typescript
useEffect(() => {
    function handleKeyDown(e: KeyboardEvent) {
        // Skip if user is typing in an input
        if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
        
        if (e.key === '/') {
            e.preventDefault()
            searchRef.current?.focus()
        }
        if (e.key === 'n' && (e.metaKey || e.ctrlKey)) {
            e.preventDefault()
            router.push('/dashboard/{{primary_entity}}/new')
        }
    }
    
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
}, [])
```

### Console Easter Egg

```typescript
// In frontend/src/app/layout.tsx useEffect
useEffect(() => {
    console.log(
        '%c{{Product Name}}',
        'font-size: 20px; font-weight: bold; color: {{PRIMARY_COLOR}};'
    )
    console.log('{{One line that reflects brand voice.}}')
    console.log('{{Optional: GitHub link or job posting if relevant.}}')
}, [])
```

### Meta Tags (Complete)

```typescript
// frontend/src/app/layout.tsx
export const metadata = {
    title: '{{Product Name}} — {{Tagline}}',
    description: '{{155 characters max. First sentence of your hero copy.}}',
    openGraph: {
        title: '{{Product Name}}',
        description: '{{130 characters. Slightly different from meta description.}}',
        images: [{ url: '/og-image.png', width: 1200, height: 630 }],
        type: 'website',
        url: 'https://{{yourdomain.com}}',
    },
    twitter: {
        card: 'summary_large_image',
        title: '{{Product Name}}',
        description: '{{Tagline}}',
        images: ['/og-image.png'],
    },
    robots: { index: true, follow: true },
}
```

### Custom 404 Page

```tsx
// frontend/src/app/not-found.tsx
export default function NotFound() {
    return (
        <div className="flex flex-col items-center justify-center min-h-screen text-center px-6">
            <p className="text-6xl font-display font-bold text-accent">404</p>
            <p className="mt-4 text-xl text-primary">{{On-brand "page not found" line}}</p>
            <p className="mt-2 text-secondary">{{Second line — can be light or direct}}</p>
            <a href="/dashboard" className="mt-8 btn-primary">
                Back to {{dashboard / home / wherever}}
            </a>
        </div>
    )
}
```

### OG Image

Generate a 1200x630 PNG. Options:

**Option A (Figma):** Build it in Figma in 5 minutes. Export as PNG.

**Option B (Next.js ImageResponse):**
```typescript
// frontend/src/app/og/route.tsx — generates OG image dynamically
import { ImageResponse } from 'next/og'

export const runtime = 'edge'
export async function GET() {
    return new ImageResponse(
        (
            <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center',
                         justifyContent: 'center', width: '100%', height: '100%',
                         backgroundColor: '{{BG_COLOR}}' }}>
                <p style={{ fontSize: 72, fontWeight: 700, color: '{{TEXT_COLOR}}' }}>
                    {{Product Name}}
                </p>
                <p style={{ fontSize: 32, color: '{{SECONDARY_COLOR}}', marginTop: 16 }}>
                    {{Tagline}}
                </p>
            </div>
        ),
        { width: 1200, height: 630 }
    )
}
```

---

## Part 7: Pre-Demo Checklist

Run through this on the day before the demo.

### Technical
- [ ] Production URL loads at `{{yourdomain.com}}` (not .vercel.app)
- [ ] Demo account login works
- [ ] Kill shot tested 3 times on the actual demo device (phone/laptop)
- [ ] Demo data is seeded and looks realistic (not empty, not over-stuffed)
- [ ] Realtime update fires in under 5 seconds (measure it)
- [ ] No console errors on the demo account
- [ ] Railway backend is running (check health endpoint)
- [ ] PostHog session replay is recording

### Presentation
- [ ] Kill shot is the opening, not the closing
- [ ] The "one sentence" after the kill shot is memorized (not improvised)
- [ ] Backup: screen recording of the kill shot in case live demo fails
- [ ] Walk-through of other screens is under 3 minutes total
- [ ] You know the answer to: "What happens in V2?"
- [ ] You know the answer to: "What does growth look like?"
- [ ] You know the answer to: "Why won't {{large competitor}} just build this?"

### If the Live Demo Fails

Don't panic. Switch to the screen recording immediately. Say: "The live demo works — here's a recording from earlier today." Then move on. Judges care more about your recovery than the failure.

---

## Part 8: The Details That Win

A checklist of micro-decisions. Each one takes under 10 minutes. None appear in the implementation guide. All of them add up.

**Favicon:** Test at 16px in a browser tab next to 5 other tabs. If you can't identify it, it failed. Simplify.

**Loading state on all buttons:** Every button that triggers an async action should show a spinner inside the button during the request. Not a full-page loading state. Just the button.

**Error messages are actionable:** "Something went wrong." is useless. "Couldn't save — check your connection and try again." is useful. Every user-visible error message should tell the user what to do.

**Touch targets on mobile:** Every tappable element is at least 44x44px. Including icon buttons, nav items, and small action links.

**Form submission on Enter:** Every single-field form submits on Enter. Every multi-field form submits on Cmd+Enter or the submit button. Never make users reach for the mouse.

**Empty search results:** When search returns nothing, show a helpful message: "No {{entities}} match '{{query}}'." plus an option to create a new one or clear the search.

**Pluralization:** "1 item" not "1 items." Either use a pluralization library or handle the most important ones manually.

**Number formatting:** "₹1,23,456" not "₹123456". "2.5K" not "2500" for large numbers in summaries. Apply locale-aware formatting.

**Scrollable modals:** If a modal or bottom sheet might have more content than fits on a small screen, make it scrollable. Test at 375px height (shortest common iPhone).

**Dark mode colors:** If you're dark-only, make sure your dark theme isn't just an inverted light theme. Borders should be subtle. Shadows don't work the same way. Background layers need more intentional elevation distinction.

**Supabase realtime green dot:** A small indicator in the header showing realtime connection status. Green = live. Gray = polling fallback. This is a trust signal. It shows the product is thoughtfully built.

**Draft confirmation:** If a user navigates away from an unsaved form, show a browser confirmation dialog ("Leave page? Changes you made may not be saved."). Use the `beforeunload` event.

```typescript
useEffect(() => {
    if (!isDirty) return
    const handleBeforeUnload = (e: BeforeUnloadEvent) => {
        e.preventDefault()
        e.returnValue = ''
    }
    window.addEventListener('beforeunload', handleBeforeUnload)
    return () => window.removeEventListener('beforeunload', handleBeforeUnload)
}, [isDirty])
```
