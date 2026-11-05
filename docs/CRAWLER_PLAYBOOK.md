# Crawler Playbook

How BrandNest sources catalog, price, and sale data — and the rules that keep it defensible.
Architecture context in `ARCHITECTURE.md`; incident procedures in `RUNBOOK.md`.

## 1. Adapter Model

Every brand is served by one adapter implementing:

```
BaseAdapter.discover() -> product URLs / payloads
BaseAdapter.parse()    -> NormalizedProduct {title, category, images, variants[{size, color,
                          price, compare_at_price, in_stock}], source_url, external_id}
```

Two concrete adapters cover nearly everything; per-brand subclasses in `crawlers/overrides/`
exist only when a brand genuinely deviates.

### ShopifyAdapter (~60% of PK fashion brands)
- Paginate `/products.json?limit=250` (cursor `page_info` fallback).
- Poll `/collections/sale/products.json` and `/collections/new-arrivals/products.json` for cheap
  high-frequency signals.
- Structured JSON: variants, prices, `compare_at_price`, availability, images — no HTML parsing.

### SitemapHtmlAdapter (Magento / custom sites)
- `sitemap.xml` for URL discovery, then fetch product pages.
- Parse order: JSON-LD `schema.org/Product` → OpenGraph → CSS-selector fallback (selectolax).
- `httpx` only. **Playwright is a per-brand exception, never the default** — headless browsers
  are the expensive path (CPU, RAM, detection risk) on a home machine.

## 2. Schedule Tiers (APScheduler in worker)

| Tier | What | Frequency |
|---|---|---|
| F — full catalog | All brands, complete crawl | Nightly 01:00–05:00 PKT |
| S — sale signals | Homepages, `/sale` collections, bank offer pages, brand/bank public social pages | Every 4h |
| W — watched variants | Variants with active `watch_item`s | Every 60 min |
| R — Lawn Radar | Admin-declared drop-window collections only | Every 5–10 min, only inside declared windows |

Tier R is the only high-frequency crawling in the system, and only for flagged collections
during launch windows (e.g., lawn season Feb–Apr).

## 3. Change Detection & Price History

- On each parse, compare `(price, compare_at_price, in_stock)` per variant against the latest
  `price_history` row; **insert only on change**, always update `last_seen`. The graph renders
  as a step function.
- Product missing from two consecutive full crawls → `is_available = false`. The inverse
  transition (false → true) is a **restock event**, feeding Lawn Radar and watch alerts.

### "Asli Sale" verification logic
A discount is genuine only if:
1. current price < 90-day modal/median price, AND
2. no pre-sale markup occurred in the prior 21 days (price raised then "discounted" back).

Badge renders on the price-history graph; fake-discount cards are one-tap shareable.

### Sale-banner detection
- Hash the homepage main content; on change, extract banner text/alt and keyword-match
  ("sale", "flat", "% off", "azadi", "eid", "blessed friday").
- Secondary signal: share of catalog variants with `compare_at_price > price` jumping >10
  percentage points in a day.
- Either signal creates a **draft** `sale_event` — never auto-published. Humans verify
  (state machine in `ARCHITECTURE.md` §8).

## 4. Bank Offer Sources

Crawled pages (Tier S): HBL "Discounts", Meezan "Card Offers", Bank Alfalah "Alfa Deals",
UBL, Faysal "DigiDiscounts", MCB, Standard Chartered — plus banks'/brands' public Instagram
and Facebook pages. All hits create **drafts** for human verification. Community
`deal_report`s (screenshot upload) are the second source; verified reporters earn points.

## 5. Images

- **Never rehost full-size imagery.** Store source URLs.
- Download one image per product → resize 256/512px WebP → upload to R2 → serve via CDN
  (powers thumbnails + Data Saver mode).
- Full images always hotlinked/credited to the brand. Purge-on-request honored within 48h.

## 6. Politeness & Legal Rules (enforced in `crawlers/base.py` middleware)

These are hard rules, not guidelines — PECA 2016 criminalizes unauthorized access, so we stay
strictly on public pages and behave like a polite visitor.

1. Obey `robots.txt`.
2. Max 1 concurrent request per domain; 2–5s delay with jitter between requests.
3. Use `If-Modified-Since` / ETag; cache aggressively.
4. Exponential backoff on 403/429 → automatic per-brand pause + admin alert.
   Observed 2026-07-25: some stores (Outfitters, J., Limelight) impose 429 penalty windows
   lasting tens of minutes after a pagination burst — retrying minutes later is pointless.
   Skip the brand for the run and let the nightly cycle catch up.
5. Honest, static User-Agent. No residential proxy rotation by default.
6. Public pages only. Never authenticate, never bypass bot protection.
7. Per-brand kill switch in `brand_config` — any brand can be paused instantly.
8. Prefer official channels in this order: brand-provided feed (partnership) → Shopify public
   JSON → sitemap → HTML. Each signed data-partnership removes a legal question mark; converting
   the top 10 brands to consented feeds is a standing BD priority.

## 7. Per-Brand Config Reference (`brand_config`)

| Field | Used by | Purpose |
|---|---|---|
| `products_json_ok` | crawler | Shopify JSON endpoint available/allowed |
| `sitemap_url` | crawler | discovery for non-Shopify brands |
| `frequency_tier` | crawler | F/S/W/R tier membership overrides |
| `max_rps` | crawler | politeness override (below global default only) |
| `webview_user_agent` | app | UA override where brands block in-app browsers |
| `product_url_regex` | app | cheap product-page detection before metadata parses |
| `checkout_domains[]` | app | address-strip "secure checkout" state + chip collapse |
| `order_confirm_patterns[]` | app | points attribution (`/thank_you` etc.) |
| `toolbar_flags` | app | per-brand feature toggles |

Server-editable in the admin UI. **A broken brand is a config edit, not an app release.**
