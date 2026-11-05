# Implementation Plan

> Planning happens here **before** development. No story is implemented until it is defined
> here and its blocking decisions are resolved. Business baseline:
> `brand-nest-general-plan.docx`. Technical detail: `ARCHITECTURE.md`, `CRAWLER_PLAYBOOK.md`,
> `RUNBOOK.md`. Status tracking: `PROGRESS.md`.

## 1. Project Overview

- **What are we building:** BrandNest — Pakistan's fashion super-app. Aggregates 100+ Pakistani
  fashion brands behind one Flutter app: native discovery/search/deals UI, brand shopping via
  optimized WebView (checkout stays 100% on the brand's own site), a verified sale calendar +
  bank-card discount engine, price history with fake-discount detection, and an AI layer
  (similar-for-less, stylist chat, virtual try-on). We hold no inventory, process no brand
  payments, ship nothing — we own discovery, comparison, alerts, and loyalty.
- **Who is it for:** Pakistani branded-fashion shoppers (Android-first, event-driven buying:
  Eid, lawn season, shaadi season, Blessed Friday) who currently juggle 10–20 brand sites,
  WhatsApp sale forwards, and bank SMS to find deals.
- **Problem it solves:** fragmented discovery, tribal sale timing, invisible bank discounts at
  decision time, no cross-brand memory, and try-before-COD anxiety.
- **Development reality:** solo founder + Claude Code; team expands later. Every technical
  choice optimizes for one person: boring tech, minimal ops, one server language.

## 2. Tech Stack

| Layer | Choice | Rationale |
|---|---|---|
| Mobile app | Flutter 3.x (Android-first) | One codebase for an 85%+ Android market |
| App state | Riverpod | Dominant, well-documented Flutter pattern |
| App local DB | Drift (SQLite) | Actively maintained (Isar effectively isn't); offline brand grid + sale calendar |
| Brand browsing | flutter_inappwebview | JS injection, cookie control, per-brand UA, `window.open`/3DS handling that basic webview_flutter lacks |
| Backend API | FastAPI (Python) monolith | One language shared with crawlers + AI; the common stack for crawler-fed catalog + RAG products; fewest moving parts for a solo dev |
| Worker | Same codebase, APScheduler entrypoint | Crawls, diffs, alerts, embeddings, pushes — no second deploy artifact |
| Database | PostgreSQL 16 + pgvector | Relational data + vector search + job queue in one boring store |
| Queue | `jobs` table + `FOR UPDATE SKIP LOCKED` | Kills Celery + Redis + broker ops entirely at this scale |
| Search | Meilisearch | Single binary; typo tolerance + synonyms handle Roman Urdu out of the box; sub-50ms |
| Crawling | httpx + selectolax; Playwright per-brand exception only | Shopify `/products.json` covers ~60% of brands; headless browsers are the expensive path |
| Auth | Firebase Auth (anonymous → Google link), API verifies ID tokens | Zero auth code to own; guest-first matches a discovery app |
| Push | FCM via firebase-admin (worker) | Free, standard; topics map to brand/bank follows |
| Admin UI | Jinja2 + HTMX inside FastAPI | No second frontend stack for a one-person deals desk |
| Images | Thumbnails-only (WebP 256/512) rehosted to Cloudflare R2 + CDN; full images hotlinked | Legal bright line + bandwidth + Data Saver satisfied at once |
| AI — similarity | SigLIP embeddings (open_clip) in pgvector | Self-hosted, ~zero marginal cost; embed once at ingest |
| AI — stylist | Claude API, RAG over catalog, strict JSON output | LLM selects and explains from retrieved candidates, never invents products |
| AI — try-on | Hosted API (FASHN.ai / Replicate IDM-VTON) | ~$0.04–0.10/image; self-hosting out of scope until ~50k try-ons/month |
| Deploy | Docker Compose everywhere: local → Cloudflare Tunnel → single VPS | Identical stack at every stage; migration is rsync + compose up. No K8s |

## 3. User Stories

Format: `As a <role>, I want <capability>, so that <benefit>` — compressed to capability + AC.
Statuses tracked in `PROGRESS.md`.

### Phase 1 — The Wedge (Months 0–3)

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-1 | Browse a categorized brand grid (Women/Men/Kids/Shoes/Unstitched/Sale Now) and open any brand | 40 brands seeded; grid loads offline from Drift cache |
| US-2 | Shop a brand inside the optimized WebView and complete checkout on the brand's own site | Host + padlock always visible; 3DS/OTP popups open in-app; COD flow works end-to-end on 5 test brands |
| US-3 | See this brand's bank offers as toolbar chips while browsing it | Verified offers appear <1s after page load; chip detail shows card type, min-spend, validity, proof link |
| US-4 | View a verified sale calendar (list + month view) | Only `verified/live` events show the badge; readable offline; countdown for upcoming sales |
| US-5 | Browse/filter the bank-discount directory by my banks and card types | User saves "my cards"; expired offers auto-hidden |
| US-6 | Get push notifications when a followed brand's sale starts or a matching bank offer goes live | FCM topic per brand/bank; tap deep-links to the right screen; per-category opt-out |
| US-7 | (Admin) Review draft deals and verify/reject with proof | State machine enforced server-side; `verified_by/at` recorded; expiry automatic |
| US-8 | (System) Crawl top 25 Shopify brands nightly into the catalog and record price snapshots | Adapter runs unattended; a price change writes exactly one history row; failures alert the founder |
| US-9 | Use the app as a guest, sign in only when saving things | Firebase anonymous → Google link-on-demand; API verifies ID tokens |
| US-10 | Earn points for daily streaks and rewarded ads | Append-only ledger; idempotent; balance = SUM(delta) |

### Phase 2 — Search, Price Truth, Sharing (Months 3–6)

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-11 | Search all brands at once with Roman-Urdu typo tolerance and price/brand/category filters | "kurta under 3000" returns cross-brand results <300ms; synonyms for common transliterations |
| US-12 | See a 90-day price graph and "Asli Sale" badge on any catalog product | Badge logic per CRAWLER_PLAYBOOK §3; one-tap shareable image card for fake discounts |
| US-13 | Watch a price from the toolbar or catalog and get a push on drop/restock | Watch toggle activates when toolbar detects a product; alert within one Tier-W cycle (≤60 min) |
| US-14 | Report a deal with a screenshot and earn points when verified | Report creates a draft; reporter push-notified on outcome; points idempotent |
| US-15 | See my Bachat Meter (yearly savings) grow and share it | Savings accrue from redeemed offers + price-drop purchases; renders a WhatsApp-shareable card |
| US-16 | Share any deal/product/price-graph to WhatsApp as a deep link | Link opens the app to the exact item; web fallback page if app not installed |
| US-17 | Enable Data Saver mode | Thumbnail-only images on cellular; VTO/stylist deferred to Wi-Fi |
| US-18 | Earn points automatically when my order completes on a brand site | `/thank_you` detection on Shopify brands; pending → confirmed ledger flow; per-brand patterns editable server-side |

### Phase 3 — AI & Viral (Months 6–12)

| ID | Story | Acceptance Criteria |
|----|-------|---------------------|
| US-19 | Tap "Similar for less" on any product and see cheaper lookalikes across brands | ≥5 in-stock, cheaper, visually similar items; <500ms; excludes source brand by default |
| US-20 | Chat with the AI stylist and get shoppable outfit cards within my budget | Only real in-stock catalog items; structured JSON rendered natively; daily free quota enforced |
| US-21 | Create a Shaadi Squad event, invite family via WhatsApp, and plan outfits on a shared board | Invite deep link joins the squad; pin from any brand; per-person budget tracking; votes/comments |
| US-22 | Get Lawn Radar alerts the moment a tracked collection launches or a sold-out SKU restocks | Alert <5 min from detection during drop windows; historical sell-out speed shown per design |
| US-23 | Scroll the Mukammal Look feed and shop any item in a look in two taps | Vertical feed; total look price computed live; out-of-stock flagged; creator attribution |
| US-24 | Try an outfit on my photo (VTO beta) | Consent + auto-delete; kurtas/pret only; async with push on completion; monthly quota + global spend cap |

**Deferred (Phase 3+/BD-dependent, from the business doc — not silently dropped):** BrandNest Gold
premium tier, sponsored placements, emerging-brand listings, B2B insights dashboards, size
advisor, BNPL badges, WhatsApp channel integration, affiliate voucher integration.

## 4. Phases

### Phase 0 — Planning ✅ (this document)

### Phase 1 — The Wedge (Months 0–3)
- Scope: US-1 … US-10. Sale/discount tracking is the wedge; ship it first.
- Foundations: monorepo + compose stack, data model + migrations, Shopify adapter, deals desk
  admin, FCM, Firebase Auth. **Price-history recording starts day one — the archive compounds.**
- Exit criteria (from business doc): closed beta with 500 users; D7 retention >20%; deal-alert
  accuracy >95%.

### Phase 2 — Search, Price Truth, Sharing (Months 3–6)
- Scope: US-11 … US-18. 80+ brands crawled; Meilisearch live; sharing loops on.
- Exit criteria: 100k installs, 35k MAU, 100k monthly click-outs, D30 retention >12%, one
  signed brand + one bank pilot.

### Phase 3 — AI & Viral (Months 6–12)
- Scope: US-19 … US-24, sequenced to the shopping calendar: Shaadi Squad before Nov wedding
  season; Lawn Radar by January (before Feb–Apr lawn season).
- Exit criteria: 750k installs, 250k MAU, 400k monthly click-outs, PKR 8–12M monthly run-rate,
  D30 retention >15%.

## 5. Open Decisions

| # | Decision needed | Options considered | Status |
|---|-----------------|--------------------|--------|
| D-2 | VTO vendor at Phase-3 time | FASHN.ai vs Replicate-hosted IDM-VTON/CatVTON | Open (defer to M9; re-quote pricing then) |
| D-3 | VPS provider & migration date | Hetzner vs regional provider; trigger per RUNBOOK §4 | **Partly resolved 2026-11-05** — a Pakistan-based provider (founder's call). Specific provider and migration date still open; set up together with the domain and Play Console once the app is final |
| D-4 | First 25 brands to crawl (priority list) | Top Shopify-based brands by traffic | **Resolved 2026-09-04** — all 25 active. The 5 pilots, then Beechtree/Edenrobe/Zellbury, then Sapphire and Khaadi on the two SFCC adapters, then the founder-approved wave of 15: Gul Ahmed, Nishat Linen, Sana Safinaz, Maria B, Chinyere, Cross Stitch, Generation, Almirah, Asim Jofa, Breakout, Zeen, Saya, Diners, Uniworth and **Khas Stores**. Every one was probe-verified before seeding. **Ideas was dropped**: `ideas.com.pk` redirects to `gulahmedshop.com` and served the identical products, so it was the Gul Ahmed store twice; Khas Stores replaced it. Also working if a swap is wanted: Zara Shahjahan, Republic Womenswear, Elan, Sania Maskatiya (all premium/couture). Not taken, and why: Warda, Charizma and Agha Noor disallow `/products.json` in robots.txt; Ethnic returns 403; Bareeze's sitemap index is empty; Kayseria is Shopify but served an empty feed |
| D-5 | Analytics tooling | PostHog self-hosted (doc's suggestion) vs simple event tables in Postgres first | Open (lean toward event tables until B2B product matters) |
| D-6 | Ship on a beta WebView plugin? | `flutter_inappwebview` 6.2.0-beta.3 (only version supporting AGP 9, which the Flutter template ships) vs downgrading AGP to 8.x to stay on stable 6.1.5 | Open (on the beta since 2026-07-26; it builds and shops correctly. Move to 6.2.0 stable when released — before Play Store listing, since the WebView is the checkout path) |

### Resolved

| Date | Decision | Outcome |
|------|----------|---------|
| 2026-07-25 | App name (D-1) | BrandNest (was Pehnawa in the business doc's working title) |
| 2026-07-25 | Team model | Solo founder + Claude; optimize all choices for one person |
| 2026-07-25 | Planning scope | Full Phase 1+2 (12-month) product planned now; wedge built first |
| 2026-07-25 | Backend | FastAPI monolith + worker, one Python codebase (not NestJS + separate AI service) |
| 2026-07-25 | Hosting | Local Docker Compose → Cloudflare Tunnel (beta) → single VPS (public). No K8s |
| 2026-07-25 | Stack details | Postgres+pgvector, jobs-table queue, Meilisearch, Riverpod, Drift, Firebase Auth, FCM, Jinja2+HTMX admin, httpx crawling, thumbnails-to-R2 |

## 6. Top Risks

1. **Order-confirmation/attribution fragility (US-18):** Shopify checkout consolidation and
   in-app-browser blocking can silently break per-brand detection — and with it the
   points/affiliate proof loop. Mitigations: server-editable patterns, pending-points state,
   receipt OCR fallback, voucher codes as eventual ground truth. Track attribution accuracy as
   a monitored metric from day one.
2. **Shopify JSON/sitemaps closing off:** the entire catalog/price-history/AI stack sits on
   polite access to public endpoints. Mitigations: per-brand kill switches, low-frequency
   tiers, convert top 10 brands to consented feeds early (BD priority).
3. **Home-machine reliability for beta:** load-shedding, ISP flakiness, disk failure — and the
   price archive is irreplaceable. Mitigations: nightly `pg_dump` to R2 from week one; VPS
   migration scheduled before any public listing, not after the first outage.
