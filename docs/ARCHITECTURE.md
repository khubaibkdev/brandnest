# BrandNest — System Architecture

Technical baseline derived from `brand-nest-general-plan.docx`. Stories/phases live in
`IMPLEMENTATION_PLAN.md`; crawling detail in `CRAWLER_PLAYBOOK.md`; operations in `RUNBOOK.md`.

**Principle:** one repo, one server language (Python), two long-running server processes,
three infra dependencies. Everything runs from a single `docker-compose.yml` whether on the
founder's machine or a VPS.

## 1. Components

| Component | What it is | Runs as |
|---|---|---|
| Flutter app | Android-first client: native discovery/search/deals UI + `flutter_inappwebview` brand browsing with native Smart Toolbar overlay | Play Store / APK |
| API service | FastAPI monolith: REST JSON for the app, Firebase token verification, catalog/deals/watchlist/points/squad/looks endpoints, **and** the deals-desk admin UI (Jinja2 + HTMX — no separate frontend build) | `api` container |
| Worker service | Same codebase, different entrypoint. APScheduler drives: crawler adapters, price-history diffing, sale-banner detection, Meilisearch sync, embedding jobs, watch-alert evaluation, FCM sends, VTO job polling | `worker` container |
| PostgreSQL 16 + pgvector | System of record: catalog, price history, deals, users, points, squads, looks, embeddings, and the `jobs` table (doubles as the queue) | `postgres` container |
| Meilisearch | Unified catalog search: typo-tolerant Roman-Urdu ("kurta", "khussa", "3 piece"), synonyms, faceted filters | `meilisearch` container |
| FCM / Firebase Auth | Push notifications (`firebase-admin` from worker); anonymous + Google sign-in, API verifies ID tokens | External (free) |
| Hosted AI APIs | Claude API (stylist RAG), FASHN.ai / Replicate IDM-VTON (virtual try-on) — called server-side only, never from the app | External, metered |
| Cloudflare Tunnel + R2 | Public HTTPS ingress to the home machine; R2 stores product thumbnails (CDN) and nightly DB backups | External (free tier) |

## 2. Communication

- **App → API:** HTTPS REST/JSON only. No websockets in v1 (squad boards poll; push covers real-time needs).
- **API / Worker → DB:** SQLAlchemy. API and worker never call each other — they share Postgres.
  Async jobs are rows in a `jobs` table claimed with `FOR UPDATE SKIP LOCKED` (no Celery, no Redis, no broker).
- **Worker → Meilisearch:** pushes changed documents after each crawl batch.
- **Worker → FCM:** batched sends for sale alerts, price drops, restocks.
- **App WebView → App native:** `window.flutter_inappwebview.callHandler(...)` message channel (Section 6).

## 3. Hosting Path

A store-listed app needs a stable public HTTPS endpoint; a home machine has neither a static IP
nor guaranteed uptime (load-shedding risk).

1. **Dev (now):** Docker Compose on the founder's machine; app talks to LAN IP.
2. **Closed beta (~500 users):** Cloudflare Tunnel — free stable hostname with TLS, no port
   forwarding, hides home IP.
3. **Public launch:** identical compose stack moves to one cheap VPS (Hetzner CPX31-class,
   ~$15/mo). No Kubernetes, ever, in this plan.

**Non-negotiable from week one:** nightly `pg_dump` to R2. The price-history archive is the
compounding asset and cannot be recomputed if lost.

## 4. Monorepo Layout

```
brandnest/
├── CLAUDE.md
├── docker-compose.yml
├── docs/                           # this documentation set
├── app/                            # Flutter
│   ├── lib/
│   │   ├── core/                   # api client, router (go_router), theme, deep links
│   │   ├── data/                   # Drift DB, repositories, DTOs
│   │   └── features/
│   │       ├── home/  search/  deals/  calendar/  brand_webview/
│   │       ├── watchlist/  points/  squad/  looks/  stylist/  vto/
│   │       └── settings/           # data saver, notification prefs
│   └── assets/
│       └── toolbar/brandnest_reader.js # bundled fallback; live version served by API
├── backend/
│   ├── app/
│   │   ├── main.py                 # FastAPI entry
│   │   ├── worker.py               # APScheduler entry
│   │   ├── api/                    # routers: catalog, deals, users, watch, points, squad, looks, ai
│   │   ├── admin/                  # Jinja2+HTMX deals desk + brand config editor
│   │   ├── models/                 # SQLAlchemy tables
│   │   ├── crawlers/               # base.py, shopify.py, sitemap_html.py, overrides/
│   │   ├── pipeline/               # price diffing, sale detection, meili sync, image cache
│   │   ├── ai/                     # embeddings, stylist RAG, vto client
│   │   └── services/               # points, alerts, attribution, notifications
│   ├── alembic/
│   └── tests/
└── scripts/                        # backup.sh, seed_brands.py, embed_catalog.py
```

## 5. Data Model (table-level)

```
brand            id, slug, name, logo_url, categories[], website_url, platform(shopify|magento|custom),
                 is_active, priority_tier
brand_config     brand_id FK, webview_user_agent, product_url_regex, checkout_domains[],
                 order_confirm_patterns[], crawl:{products_json_ok, sitemap_url, frequency_tier,
                 max_rps}, toolbar_flags     # served to app + crawler; editable in admin —
                                             # a broken brand is a config edit, not an app release
product          id, brand_id FK, source_url, external_id, title, description, category, gender,
                 tags[], image_urls[], thumb_r2_key, first_seen, last_seen, is_available,
                 embedding vector(768)       # pgvector, HNSW index
product_variant  id, product_id FK, external_id, size, color, price, compare_at_price, in_stock,
                 last_checked
price_history    id, variant_id FK, price, compare_at_price, in_stock, observed_at
                 # row written only on change; UNIQUE(variant_id, observed_at)
sale_event       id, brand_id FK, title, discount_text, starts_at, ends_at,
                 status(draft|verified|live|expired|rejected), source(crawler|report|manual),
                 proof_url, verified_by, verified_at
bank             id, name, slug, logo, offer_page_url
bank_offer       id, bank_id FK, brand_id FK (nullable = multi-brand),
                 card_types[](credit|debit|islamic|wallet|bnpl), discount_pct, max_discount_amt,
                 min_spend, channel(online|instore|both), valid_from, valid_to, proof_url,
                 status, source, verified_by, verified_at
deal_report      id, user_id FK, screenshot_url, text, linked_offer_id/sale_id nullable,
                 status(new|accepted|rejected), points_awarded
user             id, firebase_uid UNIQUE, phone/email nullable, city, my_banks[](bank_id+card_type),
                 sizes_per_brand jsonb, budget_prefs jsonb, is_gold, created_at
device_token     user_id FK, fcm_token, platform, topics[]
watch_item       id, user_id FK, target(variant|product|brand|collection_url),
                 kind(price_drop|restock|prelaunch), threshold_price nullable,
                 created_at, last_notified_at
points_ledger    id, user_id FK, delta, reason(streak|report_verified|order_confirmed|referral|
                 rewarded_ad|redemption), ref_id, status(pending|confirmed|reversed),
                 idempotency_key UNIQUE      # append-only; balance = SUM(delta), never mutable
squad_event      id, owner_id FK, name, type(mehndi|baraat|walima|eid|other), event_date,
                 invite_code UNIQUE (WhatsApp deep link), budget_total
squad_member     squad_event_id FK, user_id FK, role, budget_personal
squad_item       id, squad_event_id FK, added_by FK, product_id FK (or url+snapshot for uncrawled),
                 assigned_to, note        + squad_vote(item_id, user_id, value)
look             id, creator_id FK, title, cover_image, status(draft|published), total_price_cached
look_item        look_id FK, product_id FK, position
jobs             id, kind, payload jsonb, run_after, attempts, locked_at, status   # the "queue"
```

Relationships: Brand 1—N Product 1—N Variant 1—N PriceHistory; BankOffer N—1 Bank, N—0..1 Brand;
everything user-facing hangs off `user`.

## 6. WebView Smart Toolbar Protocol

The toolbar is the moat: it makes the WebView smarter than Chrome while never touching the
brand's page ("clean window" doctrine — legal bright line).

- **Injection:** `UserScript` at `AT_DOCUMENT_END` on every main-frame load, re-run on SPA route
  changes (History API hook + `onUpdateVisitedHistory`). The script **reads only**:
  `location.href`, `document.title`, JSON-LD `schema.org/Product` blocks, OpenGraph metas, and
  on Shopify `window.ShopifyAnalytics.meta`. It never mutates the DOM.
- **Message channel:** script → `callHandler('brandnest', {type, url, product})`; Flutter registers
  `addJavaScriptHandler('brandnest')`. Types: `page_view`, `product_view`, `checkout_enter`,
  `order_confirmation`.
- **Per-brand config** (`brand_config`, fetched from API, cached in Drift): UA override,
  product URL regex, checkout-domain allowlist, order-confirmation patterns, cookie flags.
- **Toolbar UI:** native Flutter overlay in a `Stack` above the WebView — bank-offer chips
  (matched on `brand_id` × user's saved cards), Compare, Try-on, Watch-price toggle (enabled on
  `product_view`), points chip. Address strip always shows current host + padlock; on a
  checkout-allowlist host it switches to "Paying securely on [brand]'s official checkout".
- **Windows/3DS:** `onCreateWindow` opens `window.open` targets as in-app tabs sharing the cookie
  session (required for OTP/3DS); `shouldOverrideUrlLoading` routes `whatsapp://`, `tel:`,
  `intent:` to the OS.
- **Order confirmation → points:** URL match on Shopify `/thank_you` (+ per-brand patterns).
  Emits `order_confirmation` → API writes a **pending** `points_ledger` entry (daily cap, dedupe
  by order ref), confirmed after a fraud window. Receipt-upload OCR is the fallback; voucher
  codes become ground truth once brand partnerships sign.

## 7. AI Features — Phased, Cost-Gated

| Phase | Feature | How | Cost gate |
|---|---|---|---|
| A (M3–6) | "Similar for less" | SigLIP (`open_clip`) embeddings computed in worker at ingest; pgvector ANN filtered by `price < source AND in_stock AND brand != source` | Self-hosted, ~zero marginal cost |
| B (M6–9) | Stylist chat | RAG: parse budget/occasion → retrieve ~30 candidates (Meilisearch + vector) → Claude with strict JSON schema `{picks:[{product_id, why}], total_price}` → native cards. LLM selects and explains, never invents products | 5 free msgs/day; more via points/Gold; cache recurring seasonal queries; target ≤ PKR 5/session |
| C (M9–12) | Virtual try-on (beta) | Hosted API (FASHN.ai or Replicate IDM-VTON, ~$0.04–0.10/img); async via `jobs` → push on completion. Kurtas/pret only at launch | 3 free/month, then points/Gold; hard monthly spend cap that disables the feature rather than overrunning |

**VTO photo policy:** explicit consent screen, transient encrypted storage, auto-delete inputs
after processing, opt-in to save results, never used for training, no third-party sharing.

## 8. Deals Verification State Machine

```
draft → needs_verification → verified → live → expired
   └────────── rejected (any pre-live state)      live → corrected (edit + re-verify)
```

- Crawler signal, community `deal_report`, or manual admin entry creates a `draft`.
- **Only humans set `verified`** (founder is the deals desk v1, via the admin UI; a future
  2-person desk inherits the same screens). Verification records validity dates, card types,
  min-spend, channel, proof.
- `verified → live` at `valid_from` and `live → expired` at `valid_to` are automatic (worker
  cron) — expiry is automatic because a stale deal shown is worse than a live deal missed.
- Verifying a community report awards points via `points_ledger` (idempotent).
- The in-app "Verified ✓" badge renders only for `status in (verified, live)`.
