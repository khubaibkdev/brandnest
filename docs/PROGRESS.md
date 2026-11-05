# Progress

> Read before starting work. Update when a story's status changes or a decision is made.
> Story IDs and decision IDs reference `IMPLEMENTATION_PLAN.md`.

**Current phase:** Phase 1 — The Wedge is **feature-complete**: US-8's brand count reached **25 of 25** on 2026-09-04, resolving D-4. Catalogs for the newest 15 are still filling from the nightly crawl. Phase 2 is underway: US-13 (price-watch / restock alerts), US-12 (price graph + Asli Sale badge), US-11 (cross-brand search), US-14 (community deal reporting) and US-17 (Data Saver) are Done. US-18 (order-confirmation points) is Done bar a real order. Next up: US-15 (now unblocked by US-18) and US-16 (still needs a public HTTPS domain), and US-8's brand count is now closed, so the next real work is Phase 3 or unblocking one of those three.

## Story Status

Statuses: `Not started` → `In progress` → `Done` (or `Blocked` with reason).

| ID | Story (short) | Status | Notes |
|----|---------------|--------|-------|
| US-1 | Brand grid | Done | `GET /brands` + Flutter grid with data-driven category tabs, Drift offline cache. Verified on emulator: 5 active brands render, Men tab filters to J. + Outfitters, cold start with networking off still renders from cache. 5 brands seeded, not the 40 in the AC — deferred to D-4 |
| US-2 | WebView shopping + checkout | Done (one AC step unverified) | `GET /brands/{slug}/config` + `flutter_inappwebview` browser with an always-visible host/padlock strip, in-app `window.open` popups (3DS/OTP), and non-web schemes routed to the OS. Verified on emulator: all 5 pilots open in-app with the correct host + padlock; Outfitters taken category → PDP → add-to-cart → Shopify checkout with COD preselected; Limelight's `tel:` link opened the OS dialer; system back walks brand history then exits; X returns to the grid. **Not verified: placing an actual order (0/5) and the 3DS popup path** — both need a real transaction, so the founder must do them (see Work Log) |
| US-3 | Bank-offer toolbar chips | Done (no offers live — fixtures retired) | `GET /brands/{slug}/offers` (desk-approved + in-window only, multi-brand included) + a chip strip under the address bar; tapping a chip opens card types, min spend, cap, validity, channel and a proof link to the bank's own page. Verified on emulator for Outfitters and Limelight. **The fixtures were retired on 2026-09-05** — every offer the app served was invented and signed `dev-fixture`, which is worse than showing none in a product whose promise is trustworthy deals. Their validity windows were back-dated and the worker's own transition job moved them `live → expired`, so nothing false is served. The rows still exist: **`DELETE FROM bank_offer WHERE source = 'fixture'` is still owed** and was refused by the sandbox as destructive. Real offers now need sourcing through the desk (US-7) |
| US-4 | Verified sale calendar | Done | `GET /sales` (windowed, desk-approved only) + a Sales tab with List and Month views, Drift-cached. Verified on emulator: both live sales render with the Verified badge, and a cold start in airplane mode still shows the whole calendar. The dated paths — month-grid dots and "Starts in N days" — are covered by tests only: no pilot brand had an announced dated sale on 2026-07-27 |
| US-5 | Bank-discount directory | Done (no offers live — fixtures retired) | `GET /offers` (every brand, desk-approved + in-window) + a Discounts tab grouped by bank, best saving first, "All brands" for multi-brand offers, tapping through to the same detail sheet US-3 uses. "My cards" is saved device-local in Drift as (bank, card type) pairs and filters the list. Verified on emulator: Drift v2→v3 migration over the **existing** install (brand + calendar caches survived), ticking a card filtered 6 offers to 1, cold start in airplane mode still renders the directory and the saved filter. **Same as US-3: the fixtures were retired 2026-09-05, so the directory now shows its empty state** — "No bank discounts yet. Every offer here is checked against the bank's own page by a person before it appears." |
| US-6 | Sale/offer push notifications | Done | Topic per active brand (`sale-{slug}`) and per bank (`offer-{slug}`) — no follow feature exists, so every device subscribes to everything and the two on-device toggles (Sale alerts / Offer alerts) are the only opt-out. `run_deal_transitions` pushes the moment a deal reaches `live`. Verified for real: a manually published MCB offer produced an actual FCM push, a system notification while the app was backgrounded on the emulator, and tapping it opened the app straight to the Discounts tab |
| US-7 | Admin deals desk | Done | Jinja2 + HTMX desk at `/admin` behind basic auth: review queue, offer/sale lists with filters, manual entry forms, and verify/reject actions. The state machine is enforced in `services/deals.py` — verifying needs a proof link and signs itself with the desk user; `verified → live → expired` belongs to the hourly worker job. Two real sales entered and verified through it |
| US-8 | Nightly crawl + price history | Done (catalogs still filling) | Pipeline live, **25 of 25 target brands active** — D-4 resolved 2026-09-04. The 5 pilots plus Beechtree/Edenrobe/Zellbury (same Shopify adapter, already-seeded configs re-verified live before activating — ~34.4k products, idempotency confirmed). Plus Sapphire — the first brand on the new `SitemapHtmlAdapter` (`crawlers/sitemap_html.py`) for Salesforce Commerce Cloud, which has no product-feed API the way Shopify does; scrapes each product page's own GA4 tracking data instead. Verified live (5-sample parse, a real delisted-product redirect correctly read as unavailable, 20 products actually ingested into the DB). Sprint 18 fixed the adapter's missing **product images** (it captured none, so Sapphire showed placeholders everywhere) — images are lazy-loaded, so the gallery's `data-high-src` is now the source. Still **single-variant only** — no per-size/color like Shopify gives us — and **one HTTP request per product** (~4,130 for Sapphire's full catalog, ≈3.4h at the polite 3s delay), which the nightly cron will backfill over several nights the way the original 5 brands did, not all at once. **Khaadi is now active** (Sprint 18) on a second SFCC strategy, `crawlers/category_html.py`: its sitemap lists *category* pages, so product URLs come from paging each top-level listing (`?start=&sz=96`) rather than from a product sitemap. `brand_config.sitemap_lists` picks between the two. The seeded `www.khaadi.com` was a country splash page, not a store — the real PK storefront is `pk.khaadi.com`. The final wave of 15 (Gul Ahmed, Nishat Linen, Sana Safinaz, Maria B, Chinyere, Cross Stitch, Generation, Almirah, Asim Jofa, Breakout, Khas Stores, Zeen, Saya, Diners, Uniworth) are all Shopify on the original adapter — no new code. Seeded and activated; their **catalogs are still filling from the nightly crawl**, so counts are small until it completes |
| US-9 | Guest-first auth | Done (Google-link path unverified with a real account) | API verifies Firebase ID tokens and provisions a `user` row per UID (race-safe); `GET`/`PUT /me/banks` store the shopper's cards. App: anonymous sign-in at launch, `my_cards` reconciled with `/me/banks` on a dirty-flag/account-wins basis, link-on-demand Google banner on the Discounts tab. Verified end-to-end on the emulator with a real Firebase project (`allbrand-1`): ticking a card fired a real `PUT /me/banks` that the API verified and persisted. **Not verified:** completing a real Google link — the emulator has no Google account, so only the native Credential Manager flow launching and failing gracefully was confirmed (see Work Log) |
| US-10 | Points (streaks + rewarded ads) | Done | `GET/POST /me/points`, `/checkin`, `/rewarded-ad` on the existing `points_ledger` table — append-only, idempotent, balance = SUM(delta). Rewarded ads run on Google's public test AdMob IDs (no account needed yet); check-in is +10/day, ads are +20 capped at 5/day. Verified for real on the emulator: check-in and a genuine watched test ad (Google's IKEA creative, "Reward granted") both landed in the real ledger, balance and remaining-count updated live. **Swap the test AdMob app ID / ad unit ID for the founder's own before the beta** |
| US-11 | Cross-brand search | Done | Meilisearch container + a `products` index rebuilt from Postgres (81,461 docs, ~26s), `GET /search` with Roman-Urdu synonyms and a query parser that lifts "under 3000"/"3000 se kam" out of the text, and a Search tab (now the app's 2nd destination). Filters are brand, a **canonical category** derived from the brands' 423 raw strings, the brand's own category as a drill-down under it, audience, and price. Verified live on the emulator: "kurta under 3000" → "1369 results under PKR 3,000" cross-brand, drilling into Kurta & Kurti → Kurti gave exactly the 218 the facet promised, and tapping a result opened that exact product on junaidjamshed.com. Queries return in 8–55ms against the 300ms AC |
| US-12 | Price graph + Asli Sale badge | Done (one rule unexercised on real data) | `GET /products/{id}/price-history` returns a daily price series plus the Asli Sale verdict (CRAWLER_PLAYBOOK §3), and a graph sheet opens from a chart icon beside US-13's Watch bell. Verified live on two real Alkaram products: a genuine drop (PKR 4,790 → 3,353) badged **Asli Sale**, and a flat-priced one correctly refused the badge with "This is the usual price". **The `pre_sale_markup` rule has never fired on real data** — 1,770 candidate products scanned, 0 hits; it needs a price rise inside the 21-day lookback, which the catalog has not seen yet. Unit-tested, but unproven in the wild until a real sale event |
| US-13 | Price-watch / restock alerts | Done | Watch toggle on the address bar of any detected product page (OpenGraph-based reader JS), backed by `watch_item` (`price_drop`/`restock` per user) and an hourly Tier-W worker job that re-fetches only the watched products and sends a direct-to-device FCM push on a real change. Verified for real on the emulator: a genuine product page detected, the watch toggle created real DB rows, an artificial price inflation + `run_watch_alerts()` re-fetched the true price and a real system notification ("Price drop — ... — now Rs 3,353") landed on the device |
| US-14 | Community deal reporting | Done (one path verified by test, not live) | `POST /me/reports` (multipart) stores a screenshot on a local volume and queues a `deal_report`; a Community reports queue on the desk accepts or rejects it, paying **50 points** idempotently and pushing the outcome to the reporter. App: a "Report a deal" FAB and a My reports sheet on the Discounts tab. Verified live end to end — a real report with a real screenshot, accepted from the desk, 50 points in the ledger, and the "Your deal was verified" push received on the device; a second accept returned 409 and left the balance at 50. **The reject path is covered by tests but was not exercised live** — it differs from accept only in status and wording, and shares the same proven notification call |
| US-15 | Bachat Meter | Not started | Phase 2 |
| US-16 | WhatsApp deep-link sharing | Not started | Phase 2 |
| US-17 | Data Saver mode | Done (images half only) | A Data Saver switch (Drift `display_prefs`, schema v6) that requests smaller images from `cdn.shopify.com` while on mobile data. Verified on the emulator against the real stack: the **v5 → v6 migration ran over the existing install** (`user_version` 5 → 6, `display_prefs` created, brand/sale/offer caches all intact at 9/2/4), the switch persists across a force-stop, and a scripted launch-plus-search session was **measured** at the device's own byte counter — **3,166,455 B saver-off vs 359,149 B saver-on on cellular, an 88.7% saving**, with **3,326,812 B on Wi-Fi with the saver still on**, proving the mobile-data-only rule holds on device. The AC's "VTO/stylist deferred to Wi-Fi" half still has no subject — US-20 and US-24 are Phase 3 and unbuilt |
| US-18 | Order-confirmation points | Done (one AC step needs a real order) | The app's reader script tests the URL against `brand_config.order_confirm_patterns`; a match posts to `POST /me/points/order`, which **re-checks the URL server-side** (the client's copy of the patterns comes from a public endpoint) and awards **100 pending** points, idempotent on brand+URL. A daily 05:00 worker job promotes pending → confirmed after a **14-day** hold; `balance()` already counted confirmed rows only, so pending is visible without being spendable. Patterns are editable per brand on the desk at `/admin/brands`, which refuses a pattern that will not compile. Verified live on the emulator by pointing Outfitters' pattern at a reachable page: a real `pending` row appeared, the sheet read "50 points" with "+100 pending from orders", and after backdating the row the worker promoted it and the app read **150 points**. **Not verified: detection on a genuine Shopify thank-you page** — that needs a real completed order, the same outstanding step as US-2 |
| US-19 | Similar for less | Not started | Phase 3 |
| US-20 | AI stylist chat | Not started | Phase 3 |
| US-21 | Shaadi Squad | Not started | Phase 3 — ship before Nov wedding season |
| US-22 | Lawn Radar | Not started | Phase 3 — ship by January |
| US-23 | Mukammal Look feed | Not started | Phase 3 |
| US-24 | VTO beta | Not started | Phase 3 |

## Decision Log

| Date | Decision | Outcome |
|------|----------|---------|
| 2026-07-25 | Project workflow | Plan in `IMPLEMENTATION_PLAN.md` before development; track status here |
| 2026-07-25 | App name (D-1) | BrandNest (was Pehnawa working title); synced across all docs |
| 2026-07-25 | Team model | Solo founder + Claude; all choices optimized for one person |
| 2026-07-25 | Planning scope | Full 12-month product planned; wedge (US-1…10) built first |
| 2026-07-25 | Backend | FastAPI monolith + APScheduler worker, single Python codebase |
| 2026-07-25 | Hosting path | Local compose → Cloudflare Tunnel (beta) → single VPS (public); no K8s |
| 2026-07-25 | Stack | Postgres 16 + pgvector, jobs-table queue (no Celery/Redis), Meilisearch, Riverpod, Drift, Firebase Auth, FCM, Jinja2+HTMX admin, httpx crawling, thumbnails-to-R2 |
| 2026-07-25 | Pilot brands (D-4 partial) | Active: Outfitters, Junaid Jamshed, Bonanza Satrangi, Limelight, Alkaram Studio. Next wave (seeded inactive): Beechtree, Edenrobe, Zellbury. Khaadi & Sapphire are Salesforce Commerce Cloud (NOT Shopify) — need SitemapHtmlAdapter later |
| 2026-07-25 | Crawler policy | robots.txt fetched with our own honest UA (Python-urllib UA gets 403 → false full-disallow); 5xx → one retry after 30s then skip brand; 429/403 → skip brand for the run (penalty windows last tens of minutes — nightly cycle catches up) |
| 2026-09-03 | Two SFCC discovery strategies, one parser (US-8) | `brand_config.sitemap_lists` says whether a brand's sitemap lists products (Sapphire) or categories to page through (Khaadi). Product *pages* are identical across SFCC stores, so only discovery forks — and delisting/image extraction were moved off Sapphire-shaped assumptions (URL segment, `pdp-image` class) onto signals every SFCC store publishes: the tracking blob, and schema.org `Product` JSON-LD with the gallery as fallback |
| 2026-07-26 | Category tabs (US-1) | Driven by the categories the cached brands actually carry, not a hardcoded list — a tab with no brands never renders. "Shoes" therefore absent today; "Sale Now" joins once sale events exist (US-4) |
| 2026-07-26 | Brand logos (US-1) | Curated by hand in `seed_brands.py` (`LOGOS` dict) from each brand's own Shopify CDN at `width=512`; Shopify rasterises SVG sources when asked for `format=png`, so no `flutter_svg` dependency is needed. Hand-curation beats auto-discovery at 5–25 brands — favicons are 32px and og:image is often a banner, so both need a human eye. Brands with no entry keep the monogram tile (initials on a colour from a stable hash of the slug) |
| 2026-07-26 | Logos are hotlinked | Tiles render logos on a white plate with padding (sources mix transparent PNG and white-background JPEG). Offline they fail and the monogram takes over — the grid itself still loads from cache. Caching logos properly is the R2 thumbnail pipeline in ARCHITECTURE §1, not yet built |
| 2026-07-26 | App API base URL | `--dart-define=API_BASE_URL`, defaulting to `http://10.0.2.2:8000` (host loopback from the Android emulator). Cleartext HTTP allowed in the **debug** manifest only |
| 2026-07-26 | App packages | Riverpod 3.3.2 (providers are keep-alive by default in v3 — verified, so the Drift DB is not closed underneath us), Drift 2.34.2 + drift_flutter, `http`. Drift's generated row class is the model; no separate DTO layer |
| 2026-07-26 | Repo location | Moved off the `=` path to `C:\Users\arsla\dev\brandnest` (out of OneDrive, so build output no longer syncs). Android builds now run from the repo itself — the robocopy workaround is retired. **Compose project name is pinned to `brand` in `docker-compose.yml`**: Compose derives it from the folder name, so without the pin the rename would have pointed at a new empty `brandnest_pgdata` volume and the price archive would have looked deleted. A `pg_dump` was taken first (`C:\Users\arsla\dev\brandnest-pgdump-2026-07-26.sql`, 31M); row counts identical before and after the move |
| 2026-07-26 | US-2 scope | Trust shell only: WebView + address strip + in-app popups + external-scheme routing. The injected reader JS of ARCHITECTURE §6 (`page_view`/`product_view`) is deferred to US-3, which is the first story with a UI that consumes it |
| 2026-07-26 | `checkout_domains` semantics | Holds only **third-party** payment hosts (`shop.app`, `pay.shopify.com`, `checkout.shopify.com`), not the brand's own. Shopify checkout runs same-domain at `brand.com/checkouts/...`, where showing the brand's real host already is the reassurance; the "Paying securely on the official X checkout" line exists for the case where the host changes to something the shopper doesn't recognise. This keeps the column honest as *domains* and needs no app release to fix a brand |
| 2026-07-26 | Brand config not cached in Drift | Deviates from ARCHITECTURE §6. Config is fetched per brand open and falls back to `BrandConfig.defaults` on any failure, so a dead API still lets people shop. A Drift table + migration buys only the "our API is down **and** the brand's site is up **and** the secure-checkout label matters" case — revisit if that stops feeling marginal |
| 2026-07-27 | US-7 built before US-4 | US-3 shipped on fixture offers and US-4 would have been the second story in a row rendering invented data. The deals desk is what turns US-3, US-4, US-5 and US-6 into a product, so it jumped the queue. US-4 then launched on two real, desk-verified sales |
| 2026-07-27 | Verification needs proof and a name | `transition()` refuses `verified` without a `proof_url` and without an actor, and stamps `verified_by`/`verified_at` from the logged-in desk user. The badge in the app is a claim by a named person, so the machine will not let that claim be anonymous or unevidenced |
| 2026-07-27 | The desk cannot publish | `live` and `expired` are not offered to a human at all — the desk's buttons are only `needs_verification`, `verified`, `rejected`, `corrected`, and the route rejects anything else with a 400. Publishing is the worker's hourly job, so a sale cannot go live before its start date because somebody was impatient |
| 2026-07-27 | Admin auth is HTTP Basic | `admin_user`/`admin_password` in settings, and the username is what signs verifications. Basic auth is enough for a desk of one and needs no session store — but **both must be overridden before the Cloudflare Tunnel goes up** (RUNBOOK §2), since the desk writes to the data shoppers trust |
| 2026-07-27 | Desk times are Pakistan times | `datetime-local` inputs carry no zone. The desk types PKT and the API stores UTC; the form converts both ways. Storing the raw input as UTC would have shifted every sale start by five hours, which US-6's "sale started" push would then have sent at the wrong time |
| 2026-07-27 | Ended sales stay in the calendar (US-4) | `GET /sales` serves `verified`, `live` **and** `expired` inside the window: a month view that hides last week's sale is not a calendar. The AC's badge rule does the work instead — the app badges only `verified`/`live` and greys the rest |
| 2026-07-27 | Undated sales are first-class | Brands announce "sale is live" far more often than they announce dates. A sale with no dates reads as "Live now", belongs to no square on the month grid, and gets its own "Running now, no end date announced" section. Inventing an end date to fill the grid would put a countdown on a guess |
| 2026-07-27 | First app schema migration | Drift `schemaVersion` 1 → 2 with a real `MigrationStrategy` adding `sale_events`. Verified by installing over the existing v1 install rather than a clean one — the brand grid kept its cache and the calendar table appeared |
| 2026-07-27 | Two destinations, no router yet | A `NavigationBar` shell (Brands / Sales) over an `IndexedStack`, still no `go_router`. Deep links are what will justify it (US-16); until then a router is a dependency with nothing to route |
| 2026-08-01 | The catalog stays public (US-9) | Only `/me/*` requires a token; `/brands`, `/sales` and `/offers` keep serving anyone. Guest-first means the app has to work before a token exists, and the Drift caches must not depend on auth. It also keeps a Firebase outage away from the part of the app people mostly use |
| 2026-08-01 | A missing service-account key is a `/me` outage, not a dead API | firebase-admin initialises lazily on first use rather than at import. The API boots, the catalog serves, and `/me` answers 401 — verified live with no key on disk. Initialising at startup would have meant a machine without the key could not serve the brand grid |
| 2026-08-01 | The `user` row is keyed to the Firebase UID, created on first sight | Anonymous sign-in gives a UID at first launch and linking Google keeps that same UID, so the row created for a guest simply becomes the signed-in user's — there is no guest→user migration step to get wrong. Creation is `ON CONFLICT DO NOTHING` because the app fires several requests at launch and two can race for a brand-new UID |
| 2026-08-01 | `my_banks` speaks slugs, stores ids | The wire format is `{bank_slug, card_type}` because the slug is the identity the app already knows from `/offers`; the column keeps `bank_id` as ARCHITECTURE §5 designed it, so renaming a bank's slug cannot orphan a shopper's list. An unknown slug is a 400 rather than a silently dropped card |
| 2026-08-01 | `PUT /me/banks` replaces the whole set | It is a list of ticks, not a log. Merging device-local cards into an account is the app's decision at sign-in; by the time it calls the API it has already decided what the set should be, which keeps the server free of sync rules it cannot arbitrate |
| 2026-08-01 | "My cards" lives on the device (US-5) | A Drift `my_cards` table, not a Firebase anonymous UID writing `user.my_banks`. US-9 is a story with its own AC (anonymous → Google link, API verifies ID tokens); half-building it inside US-5 means building it twice. A reinstall costs the shopper a few taps, and when US-9 lands the local rows upload once and the table becomes the offline cache of the server value — the same shape as brands and sales |
| 2026-08-01 | A saved card is a (bank, card type) pair | Not two independent lists. Holding a Meezan debit card does not make a Standard Chartered debit offer usable, and showing a discount someone cannot claim is the exact failure this feature exists to prevent. Matches `user.my_banks`'s `{bank_id, card_type}` shape, so US-9 inherits it unchanged |
| 2026-08-01 | Directory filters on the device, not the server | `GET /offers` serves the whole set unfiltered (6 rows today, low hundreds at 25 brands). Query-param filtering would make the directory need a connection, and it is a top-level tab next to two that read offline. Filtering is a pure function over the cached list |
| 2026-08-01 | Expiry is re-checked on read, not only at fetch | The API already hides expired offers, but a cached one can run out while the phone has no signal. `isOfferCurrent` filters again on the way out of the repository, so "expired offers auto-hidden" is true offline too. It re-evaluates per emission, which a refresh triggers — an offer expiring at midnight with the app open survives until the next refresh, which is the tab's own on-open behaviour |
| 2026-08-01 | One offer model, not two | `BankOffer` now serves both the brand-scoped chips and the cached directory, gaining `bank_slug` (the stable key "my cards" saves against) and nullable brand fields. The alternative — Drift's generated row class as the directory's model, per the 2026-07-26 convention — would have meant duplicating every formatter, since US-3's chips are deliberately not Drift-backed. The repository maps rows → model; that convention still holds where one representation is enough |
| 2026-08-01 | Offer presentation moved to `features/offers/` | The formatters and `OfferDetailSheet` left `features/brand_webview/offer_chips.dart` once a second feature needed them; `directory → brand_webview` would have been a backwards dependency. `offer_chips.dart` keeps only the chip strip. Names unchanged, so the move is behaviour-free |
| 2026-08-01 | The card picker is built from the offers on hand | Not a fixed list of banks, so it never asks about a bank we carry nothing from, and each bank shows only the card types its own offers mention. A bank whose offers name no card types has nothing to tick and is left out — its offers stay reachable by browsing unfiltered. No such row exists in the real data today |
| 2026-08-01 | One definition of "shopper-visible offer" | `_visible_today()` is shared by `/offers` and `/brands/{slug}/offers`, so the directory and the toolbar chips cannot come to disagree about which offers exist. The window is still enforced independently of the status machine |
| 2026-07-26 | Offer visibility (US-3) | The API serves an offer only when `status IN (verified, live)` **and** today falls inside `valid_from…valid_to` (NULL = open-ended). The dates are enforced independently of the status machine, so an offer never shows a day early or late even though the `verified → live → expired` cron of ARCHITECTURE §8 does not exist yet (it lands with US-7). This also gives US-5 its "expired offers auto-hidden" for free |
| 2026-07-26 | Bank offers are fixtures for now | The five banks are real and every `offer_page_url` was checked to resolve on 2026-07-26, but **nobody has verified the offer terms with any bank** — they exist so the toolbar has data before the deals desk (US-7). Every row carries `source='fixture'`; `DELETE FROM bank_offer WHERE source = 'fixture'` clears the set before the closed beta. Two of the eight are deliberately invisible (one out-of-window, one draft) so the filtering can be checked against the real database |
| 2026-07-26 | Chips are a strip, not an overlay | ARCHITECTURE §6 describes the toolbar as a `Stack` above the WebView. It is a strip under the address bar instead: a floating overlay would cover the brand's own page, which is exactly what the clean-window doctrine avoids. The address strip and the chips together are the toolbar; later toolbar items (Compare, Watch, points) join the same row |
| 2026-07-26 | Reader JS deferred again (US-3) | US-2 parked the injected `page_view`/`product_view` script on US-3. US-3 does not need it: the chips are brand-level, so they depend on *which brand* is open, not on what the page contains, and they are on screen before the page finishes loading. The reader JS earns its place at US-13 (price watch), the first story that genuinely needs `product_view` |
| 2026-07-26 | Offers not cached in Drift | Same reasoning as brand config: fetched per brand open, and a failure simply means no chips rather than a broken brand. Offline chips are not in the AC and would cost a table + migration |
| 2026-07-26 | Backend tests exist now | First `backend/tests`: a session fixture on a connection whose transaction is always rolled back, plus a FastAPI dependency override. Tests run against the real migrated database and leave nothing behind, so there is no second schema to keep in step. `docker compose exec api python -m pytest tests` |
| 2026-07-26 | `flutter_inappwebview` 6.2.0-**beta**.3 | Forced: Flutter's template now ships AGP 9.0.1, which rejects the `getDefaultProguardFile('proguard-android.txt')` used by stable 6.1.5, so the build fails outright. Beta 6.2.0-beta.3 lists "[Android] Upgrade to AGP 9" (#2765) as fixed and builds/runs clean. The alternative was downgrading AGP to 8.x and fighting the Flutter template. Tracked as D-6 |
| 2026-08-22 | Firebase project is `allbrand-1` | Provisioned via the Firebase CLI (device-code login, since this machine has no browser to open) rather than by hand in the console: Android app registered under package `pk.brandnest.brandnest`, the debug SHA-1 added, and Anonymous + Google sign-in enabled by deploying a checked-in `firebase.json` auth block (`npx firebase-tools deploy --only auth`). `google-services.json` was pulled with `apps:sdkconfig` straight into `app/android/app/`, so it always matches what the console has. The service-account key still had to be generated by hand in the console — a private key with Admin SDK access is not something to automate through a CLI session |
| 2026-08-22 | `my_cards` sync is a dirty flag, not a timestamp | A new Drift table `SyncState` (schema v3→4) holds one boolean: true whenever a local tick hasn't been pushed yet. Reconciling on sign-in is then two branches — dirty pushes local, clean pulls the account's set — matching the Sprint 7 decision that a pending offline edit must win over an older server set. The alternative (comparing modification timestamps) needed a clock on both sides to agree; a boolean needs nothing |
| 2026-08-22 | `OfferDirectoryRepository` takes an `IdTokenProvider` callback, not `AuthService` | Passing the whole service would have made every existing repository test (built on a bare `NativeDatabase.memory()`, no Firebase) either construct a real `FirebaseAuth` or grow a mock. A `Future<String?> Function()` needs neither — tests keep their 2-argument constructor call unchanged (the parameter is optional, defaulting to a no-token stub), and the real app wires `authService.idToken` at the provider |
| 2026-08-22 | US-6 has no brand-follow feature | The AC says "a followed brand's sale," but nothing follows anything yet — no button, no column. Building that first would have been a second story. Every device subscribes to every active brand's sale topic and every bank behind a saved card's offer topic instead; the two on-device switches (Sale alerts / Offer alerts) are the only opt-out. Revisit if the brand count outgrows "subscribe to all of them" |
| 2026-08-22 | `firebase_admin` init moved to `app/firebase.py` | `app/auth.py`'s private `_firebase()` became the shared `firebase_app()` once `services/notifications.py` needed the same app for `messaging.send()` — initialising `firebase_admin` twice raises. Both callers still degrade the same way: no service-account key skips the feature (`/me` returns 401, a push is skipped and logged) rather than taking the API down |
| 2026-08-22 | Push is topic-only; `device_token` stays empty | The table ARCHITECTURE.md §5 already defines exists for *direct*-to-device sends, which nothing in US-6 needs — subscribing is a pure client-SDK-to-FCM call, no backend involvement. Populating it now would have been a table and an endpoint with zero bearing on this story's AC. It is real infrastructure for US-13/US-18 (per-item, per-user alerts), which is when it should actually be wired up |
| 2026-08-23 | Rewarded ads run on Google's public test AdMob IDs | No AdMob account exists yet, but Google publishes a real test app ID and rewarded ad-unit ID that serve genuine ad creative to anyone — no account, no console setup. That let the whole flow (load, show, `onUserEarnedReward`, points awarded) get built and verified for real today instead of stubbed. **Must be swapped for the founder's own AdMob app ID and ad unit ID before the closed beta** — same shape as the fixture bank offers needing real desk verification first |
| 2026-08-23 | A rewarded-ad reward is trusted from the client | `POST /me/points/rewarded-ad` pays out on the app's word that `onUserEarnedReward` fired, guarded only by a daily cap and one idempotency key per watch. AdMob's harder guarantee — Server-Side Verification, a signed callback to a public URL — needs a public URL, which does not exist until the Cloudflare Tunnel goes up (RUNBOOK, hosting path). Acceptable now: no real ad revenue is at stake yet, and a determined shopper gaming 5 extra check-ins a day is not the wedge's threat model. Revisit alongside the tunnel |
| 2026-08-23 | `IdTokenProvider`/`noIdToken` moved from `offer_directory_repository.dart` to `auth_service.dart` | `PointsRepository` needed the identical "ask for a token without a hard `AuthService` dependency" seam `OfferDirectoryRepository` already had. Two repositories wanting the same pattern is exactly when a private, file-local helper earns being made a shared one — `auth_service.dart` is the natural owner, since it's the module that knows what a token *is* |
| 2026-08-23 | SFCC's `SitemapHtmlAdapter` reads one variant per product, from the site's own GA4 tracking data | No page-level source of size/color variant data was found on either Khaadi or Sapphire product pages (no Product/Offer JSON-LD, no embedded variation matrix) — only a `dataLayerEvent` blob meant for the site's own Google Analytics, carrying one `{id, name, category, price, compare_price}`. Depending on a site's own analytics is sturdier than depending on incidental DOM structure, since breaking it breaks their own business reporting, but it caps what this adapter can ever know to one variant. Revisit only if a real per-size need shows up (US-13 watch alerts on a specific size, say) |
| 2026-08-23 | A redirect away from a product's own URL means delisted | SFCC bounces a dead/sold-through product's URL back to its collection page rather than 404ing or showing a "gone" state on the same URL. `sitemap_html.py` checks the *final* URL after following the redirect, not the requested one — confirmed against a real dead Sapphire product URL before trusting the signal |
| 2026-08-23 | Khaadi stays inactive; its sitemap has no products | `sitemap_0.xml` lists exactly 3 URLs (home + two disallowed paths) — either abandoned or never wired to the catalog. `SitemapHtmlAdapter` assumes a sitemap that actually lists products, which Sapphire's does (4,130 URLs) and Khaadi's doesn't; forcing Khaadi through it wasn't an option. It needs category-page crawling instead — a different, larger adapter, out of scope today |
| 2026-08-23 | Sapphire's full crawl isn't attempted in one run | Shopify's `/products.json` returns 250 products per request; SFCC has no equivalent, so `SitemapHtmlAdapter` costs one polite request *per product* — ≈4,130 requests, ≈3.4h at the standard 3s delay, for this one brand. Rather than change the politeness delay (a deliberate, hard-won crawler rule — see CRAWLER_PLAYBOOK §6) or build incremental crawling (the sitemap's own `<lastmod>` would support it) under time pressure, this is left to the nightly cron to backfill over several nights, same as the original 5 pilots' first crawl. **Worth building before a second SFCC brand joins** — two brands at this cost would risk overrunning the 4-hour nightly window (01:00–05:00 PKT) entirely |

| 2026-08-23 | The reader script detects a product via OpenGraph, not JSON-LD (US-13) | `og:type`/`og:url`/`og:title` were sampled across real product pages on multiple brands and set consistently everywhere; `Product`-typed JSON-LD, the originally assumed source, was absent on real sampled pages. `productUrlRegex` (already on `brand_config` from US-2/US-8) is a cheap pre-filter so the script skips DOM inspection on obviously non-product URLs first |
| 2026-08-23 | Reader-script injection triggers on `onProgressChanged` reaching 100%, not `onLoadStop` | `onLoadStop` does not reliably fire on the pinned `flutter_inappwebview` 6.2.0-beta.3 (confirmed by comparison: `onLoadStart` fires every time, `onLoadStop` intermittently doesn't). `onProgressChanged` does fire reliably. `onLoadStop` is kept as a harmless redundant trigger since the script is read-only and re-running it costs nothing |
| 2026-08-23 | Watch alerts push direct-to-device, not by topic | Unlike US-6's sale/offer pushes (broadcast to everyone subscribed to a brand/bank topic), a watch is personal — only the one shopper who tapped Watch should be notified. `device_token` (defined but left empty by US-6) is what this story populates: `PUT /me/device-token` registers/refreshes a token per user, and `send_device_notification` sends by FCM token instead of topic |
| 2026-08-23 | Watch alerts are their own Tier-W worker job, not folded into the nightly crawl | CRAWLER_PLAYBOOK's Tier system already reserves "W = watched variants every 60min" as distinct from the nightly full crawl (Tier F). `run_watch_alerts` re-fetches only the specific product URLs someone is watching (via the platform adapter's new `fetch_one_product`/`fetch_one_product`-style single-product fetch, not a full site walk), so its cost stays proportional to watch count, not catalog size |
| 2026-08-23 | Re-notification is suppressed for one hour per watch | Without a cooldown, a flapping price (in stock, then out, then in again within the same hourly tick's re-checks, or a brand's own site glitching) could spam the same shopper repeatedly. `RENOTIFY_AFTER = timedelta(hours=1)`, checked per `watch_item.last_notified_at`, matches the job's own 60-minute cadence — the tightest cooldown that still can't fire twice from a single run |

| 2026-08-31 | The graph's series is per product, not per variant (US-12) | `price_history` stores a row per variant, but a shopper sees one price on the page. Each variant's step function is reconstructed separately, then each day takes the **cheapest** variant. Reconstructing per variant first matters because a crawl only writes rows for variants that actually moved, so the cheapest row *at* a timestamp is not the cheapest price *on* that day. A variant first seen later never backdates its price, so a cheap size appearing today cannot make last week look like a sale |
| 2026-08-31 | "Typical price" is time-weighted, not a median of rows (US-12) | Rows exist only on change, so a price that held one day has exactly as many rows as one that held a month — a row median would let a brief dip masquerade as the normal price and hand out the badge wrongly. The step function is sampled once per day and the median taken over those samples. Verified on Bonanza product 918: 8,490 → 5,094 on day 3 of 37 reads as `not_lowest`, because 5,094 *is* the price now, not a discount |
| 2026-08-31 | The badge labels its real window, not the 90 days the rule assumes (US-12) | CRAWLER_PLAYBOOK §3 is written against a 90-day window; the crawl started 2026-07-25, so ~37 days exist. Rather than hold the badge back or silently imply 90 days, the API returns the days actually covered and the sheet says "Based on 37 days of price checks so far." It self-limits honestly at the short end too: with one day of history the median equals today's price, so no discount can be claimed. Founder's call, taken 2026-08-31 |
| 2026-08-31 | Pre-sale markup = a rise inside the 21-day lookback (US-12) | Operationalises "price raised then discounted back" as: the highest price in the last 21 days exceeds the price at the start of that window. Combined with rule 1 (today is below typical), that is exactly the raised-then-marked-down shape. **Never observed on real data yet** — see US-12's row |
| 2026-08-31 | The verdict is computed server-side only (US-12) | The app renders `verdict` and never recomputes it, so the badge cannot say different things on different app versions, and the rule can be corrected without shipping a release |
| 2026-08-31 | The graph endpoint is unauthenticated and reuses US-13's product id | What a product has cost is the same fact for everyone, so `GET /products/{id}/price-history` takes no token. The app already learns the product id from US-13's watch-status call on the same page, so nothing new resolves a URL to a product — the chart icon appears on exactly the same condition as the Watch bell |
| 2026-08-31 | Price history is not cached in Drift (US-12) | Unlike brands, sales and offers, the graph is only ever opened from a product page the shopper is browsing online, so an offline copy would have no reader |
| 2026-08-31 | The chart is a `CustomPainter`, no charting package (US-12) | One step-function line with two axis labels is ~120 lines of painter; `fl_chart` or similar is a large dependency for a single chart type. Drawn as steps rather than a smooth line because that is what the data is — a price holds until the day it changes |

| 2026-08-31 | Search filters on a derived canonical category, not the brands' own (US-11) | The 9 active brands use **423** different category strings ("Woman Un Stitched Allure Khaddar", "BTK-EAST", "Essential Pret") — unusable as a cross-brand facet. `services/categories.py` maps them to 13 shopper-facing categories by ordered keyword rules; 0.17% of 81,461 products fall through to `Other`. The founder's call was that the filter must work *completely* and still reach the original detail, so the raw string is kept on every document, shown on every result row, and offered as a second-level filter under the canonical one |
| 2026-08-31 | Classification reads the title, not just the category (US-11) | Junaid Jamshed files both "SKY BLUE LAWN UNSTITCHED 3PC" and "GREEN JACQUARD EMBROIDERED 3PC STITCHED" under `3 Piece`, and unstitched-vs-stitched is the single biggest thing a shopper here filters on. Rule order encodes the same insight: fabric state is read before any garment word, so Zellbury's "Shirt Shalwar Dupatta" under `Essential Unstitched` is fabric, not a dupatta. Getting that order wrong put 4,754 products in Dupatta & Shawls |
| 2026-08-31 | Two garment words mean a set (US-11) | Zellbury names sets by listing their parts — "Shirt Shalwar Dupatta", "Kurta Dupatta Trouser", "Kurta Trouser" — and enumerating those pairs never finishes. Counting *distinct garment groups* does it in one rule. The grouping is load-bearing: "pants" and "trousers" are one garment, and without it "Barrel Fit Pants" filed under `TROUSERS` reads as two and becomes a suit |
| 2026-08-31 | Tags are a fallback for classification, never a peer (US-11) | Plenty of products are titled with a bare SKU ("JJKS-A-36753") and their tags are the only signal. But a product carries dozens of tags, and letting them vote alongside the title let one stray "dupatta" tag file a kurta under Dupatta & Shawls. So the title and the brand's category are read first, and tags only when those said nothing |
| 2026-08-31 | Audience is derived, since `product.gender` is empty (US-11) | The column is NULL on all 81,461 rows — nothing has ever populated it — but the same text says "Men Kurta" and "Girls Frocks" out loud. Deriving it gives search a fourth real filter (Women/Men/Girls/Boys/Kids) at no crawler cost; 21.5% of products name no audience and simply do not appear under that filter |
| 2026-08-31 | The price in the query beats the filter sheet (US-11) | The AC's own example is "kurta under 3000" — one box holding both the thing and its price. The phrase is *removed* from the text, not merely read, or Meilisearch hunts for products whose titles say "under". The sheet then shows the ceiling that was understood ("Your search already said under PKR 3,000") rather than the query silently meaning something the UI never admits to |
| 2026-08-31 | The reported result count comes from the facets, not `estimatedTotalHits` (US-11) | Meilisearch caps that number at its 1,000-hit pagination limit, so a search matching 1,369 products reported 1,000 — a number a shopper reads as the truth. Every document has a category and facet counts cover the whole filtered set, so summing the category facet is exact and free |
| 2026-08-31 | The index is a projection, rebuilt, never patched (US-11) | Every field is derived from Postgres on each sync, so a wrong classification rule is fixed by re-running the job rather than by editing documents. That is also why the canonical category has no `product` column: derived data with one consumer, and a migration would only give it somewhere else to go stale. Rebuild runs at 04:00 PKT, after the 01:00 crawl has finished changing what it projects |
| 2026-08-31 | Search became the app's 2nd tab, moving Sales and Discounts (US-11) | It is the headline of Phase 2 and deserves a first-class destination. The cost was real and easy to miss: US-6's push notifications map `sale`→1 and `offer`→2 by index, so both had to shift or every sale push would have opened Search |

| 2026-08-31 | Deal screenshots go to a local volume, not R2 (US-14) | ARCHITECTURE §1 puts thumbnails on Cloudflare R2 and these belong there eventually, but R2 needs an account only the founder can create. A Docker volume is the same move the rest of the stack is making ("local compose → tunnel → VPS"), and `deal_report.screenshot_url` holds a URL either way, so the migration later touches `services/uploads.py` and nothing else. Explicitly **not** Postgres: the nightly `pg_dump` protects the price-history archive, and padding it with image bytes makes the one backup that matters slower |
| 2026-08-31 | An upload's type is read from its bytes (US-14) | The filename and the `Content-Type` header are both the uploader's to claim; the magic number is not. Only JPEG/PNG/WebP are accepted, and the size is checked before anything is written. Filenames are random rather than sequential — the desk's screenshots are reachable by URL, and a guessable name would let anyone walk other people's reports |
| 2026-08-31 | The app downscales before uploading (US-14) | `image_picker` is asked for `maxWidth: 1600, imageQuality: 85`, which puts a modern phone's screenshot well under the 6MB API limit. The limit still exists and is tested, but a shopper should never meet it — the real screenshot sent during verification arrived at 112KB from a 219KB original |
| 2026-08-31 | Accepting a report pays once, and a decision is final (US-14) | Points go through `points.award_points` under `deal_report:{id}`, so the append-only ledger cannot double-pay; and a report already accepted or rejected raises rather than being re-decided, because undoing a decision would push a second notification about an outcome the reporter already heard. The desk sees a 409, not a silent second payment. Verified live: the second accept returned 409 with the balance still at 50 |
| 2026-08-31 | Accepting a report publishes nothing on its own (US-14) | ARCHITECTURE §8 is explicit that **only humans set `verified`**. Accepting says "this was worth sending" and pays the reporter; the desk still writes the offer or sale itself. Wiring accept straight through to a live deal would put a stranger's screenshot in front of shoppers with no one having checked it |
| 2026-08-31 | A report can be words only (US-14) | The screenshot is what makes a report checkable, so it is asked for first — but someone standing in a shop looking at a poster has something worth telling us and no screenshot to take. Only a report with neither words nor an image is refused |
| 2026-08-31 | Reporting lives on the Discounts tab (US-14) | That tab is the directory these reports feed, and until now every offer on it was entered by hand — US-3 and US-5 are still "Done (on fixture offers)". A "Report a deal" FAB sits over the list the reports are meant to fill, and My reports hangs off the same screen |
| 2026-08-31 | A report is worth 50 points (US-14) | Against a daily check-in (10) and a rewarded ad (20). Reporting costs a screenshot and someone's attention, and it is the only one of the three that produces something another shopper can use |

| 2026-08-31 | Data Saver resizes at the brand's CDN, not via the R2 pipeline (US-17) | ARCHITECTURE §1 puts thumbnails on R2, which does not exist. But **100% of the 80,921 catalogued product images are on `cdn.shopify.com`**, which resizes from a `width` query parameter — a real thumbnail, not a full image scaled down after it has already crossed the network. Same trick `seed_brands.py` uses for logos at `width=512`. Measured on 10 random real products: 2.99MB → 67KB at `width=160`, a 98% saving (avg 299KB → 6.7KB each). A host not on the resize list is left untouched, since sending `width` to a CDN that ignores it costs a cache miss and saves nothing |
| 2026-08-31 | Data Saver only acts on mobile data (US-17) | The AC says "thumbnail-only images **on cellular**", so on Wi-Fi the switch deliberately changes nothing — there is no data to save there. Default off: quietly serving someone smaller images than they asked for is a choice they should make. Until connectivity has reported in, images load full size — briefly serving a good image is a better failure than briefly serving a blurry one that then has to be replaced |
| 2026-08-31 | The notification sheet became the settings sheet (US-17) | `notification_settings_sheet.dart` → `settings_sheet.dart`, titled "Settings" with Notifications and Data subheadings, and the app-bar icon moved from a bell to a cog. Renamed rather than hiding a data setting under a heading that does not describe it; a second app-bar icon for one switch would have been worse |
| 2026-09-05 | Frontend/design skill library (`docs/frontend-designer/`) | Reference docs to consult before any UI design/dev work, not code — built once from current design-system and UX research rather than re-derived per task. Covers visual design fundamentals, avoiding the generic "AI-generated" look, Flutter/Material 3 implementation craft, motion, BrandNest's own e-commerce/fashion UX patterns, and accessibility/responsive rules for both the app and the HTMX admin panel. The app's theme (`app/lib/core/theme.dart`) is still just a bare seed color — none of this has been applied to the codebase yet; it's groundwork for the first real theming/UI pass |
| 2026-11-05 | Features before beta | Founder chose to keep building features rather than run the Phase 1 closed beta first. Domain, Play Console account and VPS come once the app is final. Next: US-21 Shaadi Squad (wedding season is already under way), then US-22 Lawn Radar by January |
| 2026-11-05 | VPS region (D-3) | A Pakistan-based provider, not Hetzner. Provider and date still open |
| 2026-11-05 | Invite/share links go through ngrok until there is a domain (US-21, US-16) | Founder's call, over Firebase Hosting or plain invite codes. WhatsApp only makes http(s) links tappable, and ngrok gives a free HTTPS host for the API's invite page and `/.well-known/assetlinks.json`. The public host is one config value so it can move to the real domain later. Links only work while this machine and the tunnel are up |

## Work Log

- **2026-09-05** — **Built `docs/frontend-designer/`, a frontend/UI-design skill library.**
  Researched current (2025/2026) professional design-system documentation, UX research, and
  design-critique sources (five parallel research passes) and wrote it up as 7 reference files
  plus an index: visual design fundamentals (type scale, color/contrast, spacing, hierarchy),
  the specific named tells of AI-generated/templated UI and their fixes, Flutter/Material 3
  implementation craft (theming architecture, elevation, custom components, dark mode), motion
  and interaction design, BrandNest-specific e-commerce/fashion UX patterns (trust signals vs.
  dark patterns, price-history UI, WhatsApp-optimized sharing, gamification), accessibility and
  responsive design for both the Flutter app and the HTMX admin panel, and a pass/fail design
  review checklist. Purely additive reference documentation — no app code changed; this is
  groundwork to apply on the next screen/theming pass, starting from `app/lib/core/theme.dart`,
  which is still just `ColorScheme.fromSeed()` with nothing else themed.

- **2026-09-05 (Sprint 22)** — **Sapphire has a real logo now, not a monogram.** The
  2026-09-04 curation pass (`seed_brands.py` LOGOS) had marked it a dead end: the header is only
  an inline white SVG (would vanish on the tile's white plate) and the site links no `og:image` or
  manifest icons, only a 32px favicon. Re-checked by probing the same Demandware
  `static/.../images/` bucket the SVG and favicon live in for likely filenames — `sapphire-logo.png`
  answered 200: an 800×98 black wordmark PNG, `Image.network`-safe, not linked from any page.
  `LOGOS['sapphire']` added and the stale "keeps the monogram" comment removed. Verified live:
  reseeded against the running stack (`1 logos updated`), and `GET /brands` now returns the real
  URL for Sapphire.

- **2026-09-06 (Sprint 26)** — **Eleven banks wired in, 1,113 offers read weekly, and the first
  real bank discount is live in the app.**
  **Banks: 6 seeded, 12 total.** Probed 25 Pakistani banks for a Peekaboo tenant; **11 resolve**.
  Added **Askari, Bank Al Habib, Allied Bank, Soneri, HabibMetro, Bank of Punjab** to the existing
  HBL, MCB, UBL, Meezan, Bank Alfalah and Standard Chartered. **Faysal, JS, Dubai Islamic,
  BankIslami, NBP, Summit and Silkbank have no tenant** and cannot be scanned this way. Listings
  are built from a slug -> tenant map, so another bank is one line.
  **The scan now reads 1,113 merchant offers across 33 listings** (11 banks x Karachi/Lahore/
  Islamabad), up from 52 two sprints ago — a 21x increase driven entirely by the founder catching
  two of my mistakes: scanning one category instead of nine, and never checking HBL at all.
  **A correction to an earlier claim:** I recorded in Sprint 21 that Meezan publishes nothing
  readable, judging by its website rendering a blank content area. **Meezan actually runs one of
  the largest programmes of the eleven** — 170 merchants in Karachi, 122 in Lahore — all behind
  the same Peekaboo widget. The website was never the right place to look.
  **Merchants per bank (Karachi):** Meezan 170, HBL 166, Askari 21, Allied 22, Bank Alfalah 18,
  UBL 16, Bank Al Habib 16, MCB 13, HabibMetro 10, Bank of Punjab 8, Soneri 2.
  **Still exactly one match across all 1,113: HBL x Khas Stores 15%.** That is now the settled
  answer on supply, measured rather than assumed: Pakistani bank card programmes are dining plus
  international labels, and our 25 local fashion houses are almost entirely absent.
  **The offer is live.** Verified through the desk's own endpoint rather than by editing the row,
  so the state machine applied — it demanded a proof link and a named actor, and the row is
  stamped `verified_by='founder'`. `GET /offers` now serves **HBL / Khas Stores / 15%** with its
  proof link. **This is the first real bank discount BrandNest has ever shown**, replacing the
  three invented ones retired on 2026-09-05.
  **Cost note:** 33 headless-Chromium renders is heavy — it wedged the Android emulator running
  alongside it. Fine at 06:30 on a Monday on a dedicated machine, worth knowing before running it
  by hand mid-session.

- **2026-09-06 (Sprint 25)** — **The bank scan was reading one category out of nine. Founder
  caught it; coverage went from 52 merchants to 348.**
  Sprint 24 hardcoded `places/18/clothing--footwear` because that is the category the founder's
  screenshot showed. HBL's listing actually has **nine**: Dining (84 merchants in Karachi),
  Health & Fitness (3), Clothing & Footwear (20), Travel, Home Decor (1), Entertainment (2),
  Beauty & Personal Care (11), **e-Stores (3)** and Miscellaneous (1). Scanning one of them was a
  silent blind spot — and would have stayed silent as banks add categories.
  **Fixed by scanning `places/_all/all`** rather than enumerating category ids, so a new category
  is picked up automatically, with the See-More budget raised from 6 clicks to 20 to page the
  whole city. **Live run: 348 merchants across Karachi (166), Lahore (84) and Islamabad (98)** —
  6.7x the previous coverage.
  **The result did not change: still exactly one match, Khas Stores 15%.** e-Stores, the category
  most likely to hold online Pakistani retailers, contains three merchants — **Daraz 10%,
  foodpanda 25%, Telemart 10%** — marketplaces, not brands we carry. Miscellaneous holds Liberty
  Books. Dining is more than half of HBL's entire programme.
  **So the conclusion now rests on 348 offers instead of 52**, which is worth more than the
  conclusion itself: HBL runs a large, real discount programme, and our 25 Pakistani fashion
  houses are almost entirely absent from it. The seam is thin because of who the banks partner
  with, not because of anything the scanner is failing to read.
  **249 tests pass.** The Khas Stores offer still sits `needs_verification` at `/admin`.
  **What would actually raise the hit rate**, in order: seed more banks (Faysal, Askari, Bank Al
  Habib and Meezan may partner with local fashion where HBL partners with Nike and Lacoste), and
  lean on **US-14 community reports**, which catch the in-store and Instagram campaigns no bank
  page carries.

- **2026-09-05 (Sprint 24)** — **The crawler now reads bank deal pages itself
  (`services/bank_scan.py`).** Answering "does the crawler get discounts from the bank site?" —
  it did not, and now it does.
  **Why the old one could not.** `offer_scan` is httpx. Pointed straight at HBL's deals page it
  got 314KB of HTML down to 12,002 characters of navigation with **zero percentages and zero
  merchants**; pointed at the widget URL it got **92 characters** — "You are using an outdated
  browser". The listings only exist after JavaScript runs. The HBL x Khas Stores offer filed in
  Sprint 23 was found by a human driving a browser, not by any crawler.
  **Built to the founder's spec: take the whole listing, then intersect.** Rather than searching
  the bank site brand by brand, it scrapes every merchant the bank publishes and keeps the ones we
  carry — the bank decides what it runs. Playwright + Chromium added to the backend image
  (`playwright install --with-deps chromium`), imported lazily so the rest of the stack is
  unaffected. Clicks "See More" until the list stops growing. Scheduled **Mondays 06:30 PKT**,
  after the brand-site scan.
  **First live run — it works:**
  | City | Merchants read | Ours |
  |------|----------------|------|
  | Karachi | 20 | 0 |
  | Lahore | 19 | **Khas Stores 15%** |
  | Islamabad | 13 | **Khas Stores 15%** |
  **52 merchant offers read automatically**, 2 matched, 0 newly filed — correctly deduped against
  the row filed by hand in Sprint 23. The scraper also beat the manual browse: it paged Karachi to
  20 merchants where clicking "See More" by hand had stalled at 12.
  **What HBL is actually running** (Karachi, the full set): Toni&Guy 25, Charles & Keith 30,
  Pedro 30, Speed Sports 25, Nike 30, HOBO 20, ChenOne 15, The Shoe Makers 15, Almas 25,
  Mothercare 20, Souk Galleria 25, Malak 30, TAG Heuer 20, POLICE 20, Design District 25, Danish
  Design 20, U.S. Polo Assn. 20, Timex 20, Omega Boutique 20, Nautica 20. Lahore adds Crocs, Vans,
  Lacoste and Khas Stores. **The programme is overwhelmingly international labels** — one hit in
  52 against our catalogue, which is the honest measure of this seam's yield.
  **Matching is deliberately strict.** Names are normalised (case, spaces, punctuation) and a
  brand under 5 characters can only match exactly — otherwise "Nike" matches "Nishat", which is
  pinned by a test. The listed merchant name is logged with each match so the desk can see what it
  was matched from.
  **Two things the founder should weigh, stated once and not buried:** the listing is served by
  **Peekaboo, a third-party deals-aggregation platform** — the same business BrandNest is in — and
  its page carries `<meta name="robots" content="noindex">`. `hbl.com/robots.txt` is `Allow: /`,
  there is no robots.txt on the widget host, and no login or paywall is bypassed, so nothing is
  blocked; but this is republishing a competitor's curated compilation, which is a business call,
  not an engineering one. HBL publishes no PDF or alternative list — the widget is the only source.
  **Tests: 249** (+8), the parser pinned against the real rendered HBL output rather than an
  invented fixture. **Still needs the founder:** the Khas Stores offer sits `needs_verification`
  at `/admin` — one click publishes it and it appears in the app.

- **2026-09-05 (Sprint 23)** — **I was wrong about bank sites, and the founder caught it. First
  real bank offer is now filed.**
  I had concluded that Pakistani bank programmes are dining-only and that brand sites were the
  only valid source. That generalised from **five** banks — and **HBL, the largest bank in the
  country, was never seeded, so I never looked at it.** The founder sent screenshots of
  `hbl.com/personal/cards/hbl-deals-and-discounts` showing a **Clothing & Footwear** category with
  apparel merchants and percentages. The conclusion was too broad and the sample was the problem.
  **What HBL actually publishes** (read in a browser; the widget is the same Peekaboo iframe MCB
  uses, reachable at `hbl-web.peekaboo.guru/<city>/places/18/clothing--footwear`):
  - **Islamabad, 13 merchants**: Charles & Keith 30, Nike 30, ChenOne 15, **Khas Stores 15**,
    Almas Jewelers 25, Mothercare 20, Souk Galleria 25, TAG Heuer 20, BOSS 25, POLICE 20, Danish
    Design 20, U.S. Polo Assn. 20, Timex 20.
  - **Karachi, 12 shown**: Toni&Guy, Charles & Keith, Pedro, Speed Sports, Nike, HOBO, ChenOne,
    The Shoe Makers, Almas, Mothercare, Souk Galleria, Malak.
  **Exactly one match against our 25 brands: HBL x Khas Stores, 15%.** Seeded **HBL** as a bank
  and filed that offer `needs_verification`, `source='bank-page'`, with the deep link that shows
  it as proof. It is sitting in the desk queue at `/admin` now. **Not verified by me** — the
  2026-07-27 rule holds, and these are financial terms a shopper acts on.
  **What this corrects, and what it does not.** Bank sites *are* a valid source — HBL carries
  apparel where MCB does not. What survives is the narrower finding: **our particular 25 brands
  are largely absent from bank programmes**, which skew to international labels (Nike, BOSS,
  Charles & Keith) and dining. One hit in 25 across two cities.
  **The automation gap this exposes:** HBL's list is JS-rendered inside a third-party iframe, so
  `offer_scan` — an httpx crawler — cannot read it. The weekly job still only watches brand sites.
  Making bank pages autonomous would need either a headless browser in the worker, or scraping
  Peekaboo's private API, which is a line worth not crossing. **HBL was added to the scanner's
  aliases** so brand-side mentions of it are caught.
  **Unexplored, and worth someone's time:** Lahore/Rawalpindi/Multan/Peshawar were not checked,
  Karachi's list did not finish paginating, and only the Clothing & Footwear category was read.
  **241 tests pass.** A browser tab was left open on the user's machine — the extension
  disconnected before it could be closed.

- **2026-09-05 (Sprint 22)** — **Autonomous weekly bank-offer scan (`services/offer_scan.py`).**
  Founder asked for the offer listing to become automatic — a crawler on a valid source, checking
  each brand, running weekly.
  **The source question decided the design.** Bank websites are not a usable source: their public
  programmes are dining (Sprint 21), and MCB's data sits behind an obfuscated POST on
  `secure-sdk.peekaboo.guru`, a third party's commercial dataset that CRAWLER_PLAYBOOK's
  polite-public-access policy does not stretch to. The source that *is* valid is the one we
  already crawl: **the brands' own sites**, which is where Eid and end-of-season bank campaigns
  actually get announced.
  **Built:** a weekly sweep of every active brand's homepage plus up to 3 offer-ish pages it links
  to, looking for a bank name within 120 characters of a plausible discount percentage. Hits are
  filed **`needs_verification`** with `source='auto-scan'` and the page as `proof_url`, landing in
  the desk's existing review queue. **Nothing it finds can reach a shopper**: the 2026-07-27 rule
  still stands that a named human must verify. Scheduled **Mondays 06:00 PKT**.
  **Precision was designed for, because a false positive is the expensive failure.** A missed
  offer is caught next week or by a community report; a false one that gets waved through puts an
  invented discount back where I just removed one. So: word boundaries (UBL lives inside DOUBLE,
  Alfalah inside a customer named Ullah — both real hits from Sprint 21), two-digit percentages
  only (every product page says "100% cotton"), a 5-75% plausibility band, and bank aliases listed
  explicitly rather than derived — deriving from "Standard Chartered" yields "Standard", which
  matches "standard delivery" on every clothing site.
  **The live run found two defects the tests could not have.** Fetching real sites showed
  `https://www.mariab.pk/www.mariab.pk/cdn/...` 404s — protocol-relative `//host/path` hrefs
  pasted onto our own host instead of resolved — and four fetches of theme assets like
  `component-discounts.css`, which match the keyword and are never announcements. Both fixed
  (`urljoin` against the landed URL; an asset-suffix skip) and both now pinned by regression tests.
  **Result: 25 brands, 0 offers filed — and that zero is verified, not assumed.** A diagnostic
  pass over the same pages read **546,061 characters** and matched **970 percentages** (brand sale
  copy), with **zero mentions of any of the five banks anywhere**. So the pipeline reads and
  parses correctly; there is simply no bank offer being advertised on any of our 25 brands' sites
  today. That independently confirms Sprint 21's finding at catalogue scale.
  **Tests: 241 backend** (+15). What this job really is: a watchdog. It costs ~25 polite fetches a
  week and will file a draft the week a brand announces a campaign, which is the only moment these
  offers exist.
  **Still owed:** `DELETE FROM bank_offer WHERE source = 'fixture'` — eight fabricated rows,
  expired and invisible, awaiting one approval the sandbox refuses to give me.

- **2026-09-05 (Sprint 21, evening)** — **Went looking for real bank offers and found the supply
  may not exist. No offers were entered.**
  With the fixtures retired, the task was to replace them with real, current bank discounts on
  our brands. Founder granted browser access for it. **I found none, and entered nothing.**
  **What the five seeded banks actually publish:**
  - **MCB** is the only one with a real, browsable discount platform. Its widget is an iframe onto
    **`mcb-web.peekaboo.guru`** (Peekaboo, a third-party merchant-discount service). Browsing
    Karachi: the categories are Food, **Lifestyle**, Health, plus day-of-week and card-tier tabs.
    **Lifestyle contains exactly one merchant — Lafanzo, leather goods, up to 20%.** The default
    grid is entirely restaurants (Cafe Aylanto, Bar.B.Q Tonight, English Tea House, Xander's…)
    plus Daraz 15% and foodpanda 30%. Typing "Khaadi" into its search suggested Kababjees, K BOYS
    and Tyso. **Not one of our 25 apparel brands appears.**
  - **Standard Chartered** renders fine but its promotions are *programmes* — Liverpool FC,
    Good Life Privileges, Reward Program, remittance, RAAST — not brand discounts.
  - **Meezan** (`/card-discounts`) renders a hero with decorative "15%"/"10%" over card art and a
    blank content area. **Bank Alfalah** serves 1,494 characters of pure navigation. **UBL**
    returns a 246-byte stub.
  **The finding that matters, and it questions a premise:** Pakistani bank card-discount
  programmes are overwhelmingly **dining**. US-3, US-5 and US-6 are built, tested and working, but
  they were designed assuming a supply of bank discounts on *fashion* brands that these banks'
  public programmes do not carry. Real bank×fashion offers do happen here, but as time-boxed
  campaigns around Eid and end-of-season, announced by the brand or on social media — which is
  exactly what **US-14 community reporting** and the desk exist to catch, and is not something
  scrapable from a bank's website.
  **A line I did not cross:** MCB's data comes from a single POST to an obfuscated endpoint on
  `secure-sdk.peekaboo.guru`. Reading the rendered page as a visitor is ordinary use; building a
  crawler against a third party's private, obfuscated API for their curated commercial dataset is
  not, and would sit outside CRAWLER_PLAYBOOK's polite-public-access policy. It was not done.
  **Also unchanged:** `DELETE FROM bank_offer WHERE source = 'fixture'` is still owed — the
  sandbox refuses it as destructive and it needs one approval. Eight fabricated rows remain in the
  archive, expired and invisible to shoppers but still present.
  **Next session:** the honest options for bank offers are (a) treat community reports (US-14) as
  the real intake and let the desk verify them, (b) check banks outside the seeded five — HBL,
  Faysal, Askari, JS, Bank Al Habib — though MCB's platform suggests the category pattern holds,
  or (c) accept that bank offers are a thin seam and let the **sale calendar (US-4)**, which
  already runs on real desk-verified data, carry the deals promise.

- **2026-09-05 (Sprint 21, later)** — **The app stopped showing invented bank discounts.**
  Asked what was next on the plan, I checked the live data rather than the story table. Three
  offers were `status=live` and rendering to shoppers — **Standard Chartered 15%, UBL 12%,
  Meezan Bank 10%** — all `source=fixture`, all signed `verified_by='dev-fixture'`. I had seen
  two of those chips myself while testing US-18 on Outfitters and not registered what they were.
  Eight fixture rows in total. This was flagged in Sprint 3 and again in Sprint 16 as "the thing
  to fix first"; it was still first.
  **Why it outranked every remaining feature:** it is the only open item that actively misleads.
  A missing feature is absent; a fabricated discount carrying a verification signature is a lie
  in the exact place the product asks to be trusted.
  **Retired without deleting anything.** `_visible_today` gates on `valid_to >= today`, so
  back-dating the windows removed them from both surfaces immediately, and the worker's own
  `run_deal_transitions` then moved the three `live → expired` — the designed lifecycle, not a
  hand-edited status. `GET /offers` and `GET /brands/outfitters/offers` both return **0**. The
  toolbar chips are not Drift-cached (2026-08-01 decision), so the API is conclusive for them;
  the directory was checked on the emulator and shows its real empty state: **"No bank discounts
  yet. Every offer here is checked against the bank's own page by a person before it appears."**
  **Still owed, and blocked:** `DELETE FROM bank_offer WHERE source = 'fixture'` — the statement
  `seed_bank_offers.py`'s own docstring prescribes for exactly this moment. The sandbox refused
  it as destructive and **I did not route around it**; expiring is a weaker fix that leaves eight
  fabricated rows in the archive, where they could later read as real historical deals. It needs
  one approval from the founder, and re-running `python -m scripts.seed_bank_offers` restores the
  set if it is ever wanted back.
  **What this does not fix:** there are now no bank offers at all. US-3, US-5 and US-6 are built
  and proven but have nothing real to show, and sourcing real offers is desk work needing a named
  human — by the 2026-07-27 decision the desk refuses to mark anything verified without a proof
  URL *and* an actor, which is precisely the safeguard that makes the empty state the honest
  state until then.

- **2026-09-05 (Sprint 21)** — **Backups exist, and a restore has actually been proven.**
  Not a story — RUNBOOK §3 is titled "Backups (non-negotiable, from week one)" and specified
  `scripts/backup.sh`. **That file had never been written.** The worker ran four jobs and none of
  them was a backup, and §5's daily checklist told an operator to "verify backup job ran" for a
  job that did not exist. The only dump on disk was from **2026-07-26**, taken incidentally
  during the repo move, 40 days stale.
  **The overnight crawl made the case sharper.** The D-4 wave filled in: products
  **83,492 → 165,341**, price history **438,763 → 734,902**, database **287 MB → 460 MB**. The
  machine had also restarted overnight, which is precisely Top Risk #3's scenario.
  **Built two scripts, both run and verified:**
  - `scripts/backup.sh` — `pg_dump -Fc` (custom format, so `pg_restore` can rebuild it), keeping
    the newest 14. Written `.partial` and renamed only on success, so a dump cut short by a power
    cut never sits in the directory looking usable. Produced a **46 MB** dump.
  - `scripts/verify-restore.sh` — rebuilds the newest dump into a throwaway container and
    compares row counts. **All five tables matched exactly**, including 165,341 products,
    645,346 variants and 734,902 price-history rows. Pruning was tested separately against dated
    dummy dumps: 6 files with `KEEP=3` left the newest 3.
  **Scheduled daily at 06:00** via Windows Task Scheduler (`BrandNest nightly backup`), after the
  01:00 crawl, 04:00 reindex and 05:00 order confirmations. Triggered once by hand end to end:
  exit code 0 and a second dump on disk. Remove with
  `schtasks /delete /tn "BrandNest nightly backup"`.
  **Said plainly — this is not yet the backup RUNBOOK §3 asked for.** The R2 upload is **not
  wired**, because it needs Cloudflare credentials that do not exist. Every copy currently sits
  on the same machine as the database. That covers a bad migration, a dropped table or a
  corrupted volume; it does **not** cover the disk failure or machine loss Top Risk #3 is
  actually about. An off-machine copy is the remaining work and needs credentials from the
  founder.
  **A test that lied, worth recording:** the first pruning check ran the script three times in one
  minute and found a single file left, which looked like the prune deleting too much. The
  filename stamp is minute-resolution, so all three runs wrote the *same* name — the test was
  invalid, not the code. Re-tested with distinct dated files, pruning is correct. Daily runs
  cannot collide; two manual runs inside a minute overwrite one good dump with another, which is
  harmless.
  **Next session:** unchanged and both need the founder — **an off-machine backup target**
  (credentials), and **redemption**, which is still the gap that ends the points loop in a number
  shoppers cannot spend. US-15 (Bachat Meter) is now unblocked by US-18 if a story is wanted.

- **2026-09-04 (Sprint 20)** — **US-18, order-confirmation points.** Asked whether the points
  system was complete; it was not. Three of the model's six intended reasons had no code:
  `order_confirmed`, `referral` and `redemption`. This sprint built the first — the only one of
  the three with a user story behind it.
  **Said plainly: `referral` and `redemption` are still missing, and were not built.** `referral`
  is named in a model comment but has **no story anywhere in the plan**, so there is nothing to
  build against. `redemption` is a *spending* feature, not earning, and equally unspecified —
  which means shoppers still accumulate a number they cannot use. Neither was invented here.
  **Built:** `services/orders.py` (pattern match, pending award, hold promotion),
  `POST /me/points/order`, a `pending` field on `GET /me/points`, a daily 05:00 worker job, and a
  desk page at `/admin/brands` for editing each brand's patterns. `award_points` gained a
  `status` argument; `balance()` needed no change because it already counted confirmed rows only.
  **Two decisions worth keeping:**
  1. **The server re-checks the URL.** The app's copy of the patterns comes from
     `/brands/{slug}/config`, which anyone can call, so the reward cannot depend on the client
     having applied them honestly. A URL that matches nothing is a 400, and one brand's
     confirmation URL does not pay under another brand's slug.
  2. **Points land `pending`, not `confirmed`.** At detection all we know is that a thank-you
     page rendered — the order can still be cancelled or returned. The hold is 14 days, which is
     also what IMPLEMENTATION_PLAN's top risk means by "pending-points state". A bad pattern
     saved by the desk is refused at save time, and a bad one already stored is skipped rather
     than allowed to break the others.
  **Verified live on the emulator, the whole chain.** A genuine thank-you page needs a real
  purchase — still outstanding since US-2 — so instead I used the feature's own server-side
  configurability: Outfitters' pattern was temporarily pointed at a reachable page. That produced
  a real `order_confirmed` row with `status=pending`, 100 points, keyed
  `order_confirmed:outfitters:<url>`; the sheet showed **"50 points"** with **"+100 pending from
  orders — unlocks when your return window closes"**; backdating the row and running the worker
  promoted it, and the app then read **"150 points"** with the pending line gone. Patterns were
  restored afterwards.
  **The debugging trap that cost the most time:** `_reportOrder` deliberately swallows every
  error so a shopper mid-checkout is never interrupted — which also means a failure looks
  identical to nothing happening. Three wrong hypotheses in, the answer was found only by adding
  temporary `debugPrint`s (since removed). **Worth knowing: `brandConfigProvider` is keep-alive,
  so a pattern edited on the desk does not reach an already-running app** — the AC's "editable
  server-side" holds in that no app *release* is needed, but an app restart is. Anyone testing
  pattern changes must force-stop first.
  **Tests: 226 backend** (+12) and **131 app** (+11), `flutter analyze` clean. The same 11
  pre-existing fixture-date app failures carried since Sprint 8 remain — confirmed unrelated (a
  lapsed offer window, not this change).
  **Next session:** the earning side is now complete bar a real order. The gap that would most
  change the product is **redemption** — there is still no way to spend points, so the whole loop
  ends in a number. That needs a product decision from the founder before any code.

- **2026-09-04 (Sprint 19, later)** — Curated the brand logos, and in doing so found a
  **duplicate brand I had just added**.
  **Ideas is not a separate store.** `ideas.com.pk` 301s to `gulahmedshop.com`, both serve the
  title "Gul Ahmed Ideas", and the two brand rows shared **all 8 external product ids**. I had
  seeded the same catalogue twice. It surfaced only because logo curation returned the *identical*
  file for both — a reminder that the probe I used to justify the wave (does `products.json`
  answer?) cannot tell two hosts of one store apart. **Anything added this way should be checked
  for redirect and id overlap**, not just for a working feed.
  **Fixed by deactivating, not deleting.** `search_index.build_documents` filters on
  `Brand.is_active`, so `is_active=false` removes the duplicate from `/brands` and from search
  while keeping its price history. The seed entry is kept, inactive, with the reason, so a reseed
  cannot recreate it. (A bulk `DELETE` was refused by the sandbox as destructive, which was the
  right call — the non-destructive fix is better anyway.)
  **Replaced with Khas Stores** to keep the count at 25, chosen because it matches the approved
  set's profile — mainstream lawn/pret, like Gul Ahmed and Nishat. Probing turned up four other
  working Shopify stores if this one is unwanted: **Zara Shahjahan, Republic Womenswear, Elan,
  Sania Maskatiya** — all premium/couture, a different tier from the rest of the catalogue.
  **This substitution is mine, not the founder's, and one `is_active` flag reverses it.**
  **Logos: 24 of 25 now render a real mark, up from 5.** Curated by eye against contact sheets
  built from each store's own header and og:image, on a grey plate so white-on-white logos give
  themselves away. The 2026-07-26 decision that this "needs a human eye" was exactly right —
  automated picking would have shipped:
  - **Baadmay's logo for Almirah and Beechtree.** Both headers link a *payment partner's* mark
    before their own.
  - **Marketing banners for Chinyere, Nishat Linen and Zellbury**, whose og:image is a 1200x628
    campaign image — Nishat's was a red "SALE" poster.
  - **Invisible logos for Cross Stitch and Asim Jofa**, whose header assets are white artwork for
    a dark header; on the tile's white plate they would have rendered as blank cards.
  **Zellbury has no dark wordmark published anywhere**, so its favicon is used instead — that
  asset is a real 512x512 brand mark on Shopify's CDN, not the 32px favicon the old decision
  rightly dismissed. **Sapphire is the one brand still on a monogram**: it publishes only an SVG
  on a Demandware path that will not rasterise it, plus a 32px `.ico`, and the app has no
  `flutter_svg`.
  **Verified on the emulator**: the grid renders 25 brands with 24 real logos. **214 tests pass**
  (no code changed — this was data). The 01:00 nightly crawl is running and filling catalogues
  (83,492 products and climbing as it works through the Shopify feeds).
  **Operational gotcha, cost me a silent watch:** `docker compose logs --since` is **useless on
  this stack**. The containers log in UTC while the host runs PKT (+5), so `--since 60m` compares
  against a wall clock five hours ahead of every timestamp and returns **nothing** — not an error,
  just silence, which reads exactly like "the job never ran". A monitor armed on it stayed quiet
  through a crawl that was in fact running. Use `--tail N`, or check the database, which is ground
  truth: `SELECT MAX(last_seen) ... GROUP BY brand` shows the crawl walking the brand list.
  **The nightly crawl is confirmed working on the new brands** — Gul Ahmed went from the 8 seeded
  products to **6,777** during this session, with outfitters, junaid-jamshed, bonanza-satrangi,
  limelight, alkaram-studio, beechtree, edenrobe and zellbury all refreshed ahead of it.
  **Next session:** the substitution above is worth a yes/no. Otherwise Phase 1 is done and the
  open items are unchanged: US-15/16/18 each need something external (a public HTTPS domain
  unblocks US-16 and is the RUNBOOK §2 prerequisite for exposing the deals desk), or Phase 3 opens.

- **2026-09-04 (Sprint 19)** — **US-8 reaches 25 of 25 brands; D-4 is resolved.**
  D-4 had sat open since Sprint 0 as "needs founder's brand shortlist", so the blocker was a
  decision, not code. What made it hard to decide was not knowing which brands were even
  crawlable, so this sprint probed 22 candidates first and put a verified list in front of the
  founder, who approved all 15.
  **The probe** (one-off, not kept) asked each candidate for `/products.json`, then fell back to
  sitemaps. **15 came back as Shopify with an open feed** — the same adapter running since Sprint
  1, so the wave needed **no new code at all**. Recorded for whoever revisits the rejects:
  **Warda, Charizma and Agha Noor disallow `/products.json` in robots.txt**, **Ethnic** returns
  **403**, **Bareeze**'s sitemap index is empty, and **Kayseria** is Shopify but served an empty
  feed. Those five are not impossible, just not free — they would need the category-listing
  approach Khaadi now uses, or nothing.
  **Seeded and activated:** Gul Ahmed, Nishat Linen, Sana Safinaz, Maria B, Chinyere, Cross
  Stitch, Generation, Almirah, Asim Jofa, Breakout, Ideas, Zeen, Saya, Diners, Uniworth. The
  seed script also picked up two corrections it had been carrying: Khaadi's URL (the splash-page
  finding from Sprint 18) and both SFCC brands' `is_active`, which had only ever been set by hand
  in the database.
  **Verified:** a bounded ingest of 8 products per brand succeeded for **all 15** — real prices,
  multi-variant (Breakout gave 80 history rows from 8 products), and **118 of 120 products carried
  images**, matching the existing brands' rate. Reindexed to 82,742 docs. On the emulator the grid
  now caches and renders **25 brands**, and the new brands appear as search facets. **214 tests
  pass**, unchanged — nothing in the crawl path was touched.
  **The catalogs are deliberately still nearly empty.** Only 8 products per brand were ingested,
  to prove the path without a 15-brand full crawl at 00:45; `mark_stale_unavailable` was not
  called for the same reason it was skipped for Sapphire and Khaadi. The 01:00 PKT nightly crawl
  fills them.
  **The honest caveat — the grid got worse-looking, not better.** Only the 5 original pilots have
  curated logos, so **20 of 25 tiles are now monograms**. I tried to extract header logos
  automatically and stopped: it worked for Sana Safinaz and returned nothing for Gul Ahmed, which
  is exactly what the 2026-07-26 decision predicted ("favicons are 32px and og:image is often a
  banner, so both need a human eye"). Rather than ship an unreliable guess, this is left as the
  single biggest visible follow-up: **15-20 logos need hand-curation into `seed_brands.LOGOS`.**
  **Also noticed:** Sana Safinaz's feed carries **no product category at all** (0 distinct), so
  its products will not appear under any category facet until US-11's canonical mapping is given
  something to work with. Every other new brand returned between 1 and 7 categories.
  **A gesture trap, for anyone scripting the emulator:** a full-height `adb shell input swipe` is
  read by Android as a system navigation gesture — it sent the app to the background and opened
  the app drawer, which looks exactly like the app hanging on the Flutter splash. Pull-to-refresh
  needs a shorter swipe that stays clear of the screen edges (`540 650 -> 540 1500` works).
  **Next session:** Phase 1 is feature-complete. The logo curation above is the highest-value
  small job. Otherwise Phase 3 opens, or unblock US-15/16/18 (a public HTTPS domain would unblock
  US-16 and is also the RUNBOOK §2 prerequisite for exposing the deals desk).

- **2026-09-03 (Sprint 18, evening)** — US-8: **Khaadi is active — 10 of 25 brands.** It had been
  blocked since Sprint 12 as "sitemap is a 3-URL stub, needs category-page crawling".
  **The first finding was that the seeded brand was the wrong site.** `www.khaadi.com` is a country
  splash page whose only links are to regional stores; the Pakistani storefront is
  **`pk.khaadi.com`**, and it has its own sitemap of **655 category pages**. So the recorded
  diagnosis was right about the mechanism and wrong about the host — the stub sitemap belonged to
  the splash site. `brand.website_url` was corrected, which also fixes where US-2's WebView opens.
  **A wrong turn worth recording:** the first two category pages I checked rendered **zero**
  products, and I nearly concluded the grid was client-side only and therefore unreachable (the
  AJAX grid lives under `/on/demandware.store/`, which robots.txt disallows). Checking more
  categories showed `/ready-to-wear/`, `/sale/` and `/fabrics/` each render **48 tiles
  server-side** — the two I picked first are simply empty categories. Generalising from one sample
  would have marked a crawlable brand impossible.
  **Built — `crawlers/category_html.py`:** read the sitemap, keep the **top-level** sections
  (sub-categories are subsets, so paging both would fetch the same product from several
  listings), page each with `?start=N&sz=96`, and take product URLs from the listing's own
  `plpRedirectPdp` links. Product *pages* are ordinary SFCC, so `sitemap_html` parses them
  unchanged. `brand_config.sitemap_lists` (`products` | `categories`, Alembic
  `2d4d39eec503`) picks the strategy; Sapphire keeps `products`.
  **Robots.txt shaped three decisions, not just one:** the listing's own links carry
  `?source=plp` and `Disallow: /*source=`, so the query is stripped before fetching; the sitemap
  lists the site's own disallowed pages (`/checkout`, `/login`), so discovery skips them via a new
  `PoliteFetcher.can_fetch()` rather than letting a `CrawlBlocked` abort the brand — reaching a
  disallowed URL from a site's own sitemap is expected, and is not the site refusing us the way a
  403 is. `/women/` is disallowed outright and is correctly excluded.
  **Two parser changes, both to remove Sapphire-shaped assumptions:**
  1. `_parse_product_page` no longer requires `/products/` in the URL. That was Sapphire's
     delisting test; Khaadi's URLs have no such segment. The real signal is the tracking blob —
     a delisted Sapphire product 301s to a collection page whose blob carries `impressions` and
     no `detail`, verified live, so it already yields no product. The test that pinned the URL
     rule now pins that observed blob instead. Khaadi delists by **404**, which the new adapter
     treats as a skip; a 500 is deliberately still raised, so a site in trouble cannot look like
     an empty catalog.
  2. Images. Khaadi's PDP has no `pdp-image` gallery, so this morning's extractor returned **0
     images** for it — the same defect I had just fixed for Sapphire. Khaadi instead publishes
     **schema.org `Product` JSON-LD** listing its images; Sapphire publishes no `Product` node at
     all (only `Organization`/`ClothingStore`, the latter with a *logo* under `image`, which the
     code must not mistake for the gallery). So extraction now tries JSON-LD first and falls back
     to the lazy gallery — one ordered rule, no per-brand config, and relative paths are resolved
     against the page because Khaadi's are site-relative.
  **Tests: 214** (was 203) — 7 for the new adapter, 4 for the image sources.
  **Verified live end to end:** 25 real products ingested, **25 of 25 with images** (6-7 each),
  across 6 categories with prices and stock; reindexed (82,622 docs); and on the emulator Khaadi
  appears on the brand grid and its products render in search with real photographs.
  **Noticed, not changed:**
  1. The app's launch-time `/brands` refresh did not pick up the newly activated brand — the grid
     still showed 9 from cache until a pull-to-refresh, which brought it to 10. Pre-existing US-1
     behaviour, not touched here.
  2. **Khaadi has no curated logo**, so it renders a monogram tile — allowed by the 2026-07-26
     fallback, but it is the only tier-1 brand without one. Its logo is not on a Shopify CDN, so
     `seed_brands.LOGOS` would need a different source.
  3. **SFCC crawl config lives only in the database.** `seed_brands.py` never set Sapphire's
     `sitemap_url` and does not set Khaadi's either, so both brands' crawl settings are
     unreproducible from code — a restore from the schema alone would silently crawl nothing.
  4. **Nightly capacity is now a real question.** Sapphire (~2,869 products) and Khaadi (~3,000)
     are one HTTP request each at the polite 3s delay — roughly 2.4h and 2.5h — against a
     01:00-05:00 window. The Shopify brands are fast (paged JSON), but the two SFCC brands alone
     now exceed four hours.
  **Next session:** 15 brands still to source. Worth deciding first whether every SFCC brand
  really needs a per-product fetch: Khaadi's *listing* already carries id, name, category, price
  and images in `data-gtmdata`/`data-hi-res-*`, so a listing-only crawl would cost ~31 requests
  instead of ~3,000 and lose only stock status.

- **2026-09-03 (Sprint 18, later)** — US-8: the SFCC adapter now captures product images.
  This was the gap found while measuring Data Saver in Sprint 17 and confirmed in the morning's
  session — **Sapphire had 300 products and 0 images**, against ~100% for every other brand, so
  its products showed a placeholder everywhere they appeared.
  **Why it was missing:** the images are not in the GA4 tracking blob the adapter reads, and the
  gallery is lazy-loaded — `src` holds an inline base64 pixel until JavaScript runs. Reading `src`
  would have given every product the same non-image. The real file is in `data-high-src`
  (full-resolution, no query parameters); `data-src` is the same file with `?sw=1000&sh=1200`.
  Confirmed against three live product pages before writing anything: `data-high-src` count
  matched the `pdp-image` count exactly on each, and extensions vary in case (`.JPG` and `.jpg`),
  which is why a first grep for images found nothing.
  **Scoped to the gallery's own `pdp-image` class** rather than every `data-high-src` on the page,
  so a recommendation carousel cannot attach another product's photos to this one.
  **Backend:** `_gallery_image_urls()` in `crawlers/sitemap_html.py` and `image_urls=` on the
  returned product — about 12 lines. 4 new tests (**203** total, up from 199); the existing
  ingest already overwrites `image_urls` on every crawl, so no backfill script was needed.
  **Verified end to end on the real stack:** a live parse returned 3 and 4 real images for two
  Sapphire products; the URLs were fetched and are genuine JPEGs (343KB); a bounded ingest of a
  random 25-URL sample wrote **10 products with 4-5 images each** into Postgres; a Meilisearch
  reindex (82,597 docs) put them in `GET /search`; and on the emulator, filtering search to
  Sapphire showed **three real product photographs** where placeholders used to be.
  **`mark_stale_unavailable` was deliberately not called** — a partial ingest would have marked
  the rest of the catalog delisted. The remaining ~299 Sapphire rows keep their old state until
  the nightly full crawl, which is the same backfill-over-several-nights pattern the original 5
  brands used (2,869 sitemap URLs at the polite 3s delay is ~2.4h, too long to run inline).
  **Two things learned about this catalog, both pre-existing:**
  1. **A large share of the sitemap is delisted.** The sitemap opens with the entire
     `womens-body-mists` collection, every one of which 301s away — the first attempt at a bounded
     ingest drew 20 URLs from the top and got 0 products, which looked like a bug and was not. A
     random sample ran about 10 live in 25. It also explains why the oldest stored Sapphire rows
     are stale.
  2. **Sapphire numbers its product images from `_2`, not `_1`** — no image is being missed.
  **Follow-up worth doing, not done here (belongs to US-17):** this CDN resizes too — the same
  image is **343KB full size and 5,931 bytes at `?sw=160`**, measured. Data Saver's
  `_resizingHosts` only knows `cdn.shopify.com` and the `width` parameter, so Sapphire's images
  are served full-size to every device. Adding the host and its `sw` parameter would extend the
  88.7% saving to this brand; the images visibly load in late on the search list today.
  **Next session:** US-8's brand count is still 9 of 25. Khaadi remains the known-hard one (its
  sitemap is a 3-URL stub, so it needs category-page discovery); the other 15 still need sourcing.

- **2026-09-03 (Sprint 18)** — US-17 device verification. No code was written this sprint; the
  Sprint 17 build was installed and put through the three checks it had been left waiting on.
  **The migration was tested the way it needed to be — over the real, existing install.** The
  emulator still carried the Sprint 16 database, confirmed at `user_version = 5` with six tables
  and no `display_prefs` before anything was installed. After `adb install -r`, `user_version`
  read **6**, `display_prefs` existed with the right columns, and every cache survived unchanged:
  brands 9, sale_events 2, directory_offers 4, identical to the pre-install counts. That was the
  single most likely thing to be broken, and it was not.
  **Worth knowing:** the first `PRAGMA user_version` read after launch returned **5**, which looks
  exactly like a failed migration. It was a race — the app takes ~16s to first draw and the read
  landed mid-flight. Reading the SQLite header directly (bytes 60-63 = `00 00 00 06`) settled it,
  and a re-read then agreed. Anyone re-running this should wait for first draw before reading.
  **The switch persists.** Toggled on, `display_prefs` went to `0|1`; after a force-stop and
  relaunch the sheet came back with `checked="true"` read from the migrated table.
  **The saving was measured on the device, not inferred.** Sprint 17's 98% figure came from
  fetching CDN images with a script; this sprint measured the app itself. Same scripted session
  each run (cold launch → grid → Search → "kurta" → wait), bytes read from the kernel's own
  per-uid BPF counter (`dumpsys netstats`, `mAppUidStatsMap`, uid 10218):
  | Run | State | Bytes received |
  |-----|-------|----------------|
  | A | Data Saver ON, cellular | **359,149** |
  | B | Data Saver OFF, cellular | **3,166,455** |
  | C | Data Saver ON, **Wi-Fi** | **3,326,812** |
  A vs B is an **88.7% saving** on the real app — lower than the 98% measured on raw images,
  which is what you would expect once API JSON and the Meilisearch response are in the total.
  C is the rule that matters most and had never been exercised: with the setting still on, moving
  to Wi-Fi restored full-size images, so Data Saver really is mobile-data-only rather than a
  permanent quality downgrade. Search returned 3,489 results with every thumbnail rendering in
  all three runs; the brand grid rendered logos throughout.
  **Note the per-uid BPF counter, not `dumpsys netstats --uid`** — the latter's history buckets
  are 2h and update lazily, and a first attempt at measuring returned a delta of 0 because of it.
  **Two things found, neither fixed** (both outside this task):
  1. Sprint 17's hand-off said the Settings sheet opens from "a cog on the Brands tab". There is
     no cog — it is `Icons.notifications_outlined` with `tooltip: 'Settings'`
     (`brand_grid_screen.dart:70`). The sheet was renamed to Settings and grew a Data section in
     Sprint 17, but the icon stayed a notification bell, so Data Saver now hides behind a bell.
  2. **Sapphire still has zero product images** (carried from Sprint 17, belongs to US-8): the
     SFCC `SitemapHtmlAdapter` never captured image URLs.
  **Next session:** US-15, US-16 and US-18 are the remaining Phase 2 stories and each is blocked
  on something real — US-16 on a public HTTPS domain, US-15 on US-18's purchase tracking, US-18
  on placing a real order. US-8's brand count (9 of 25) is the unblocked work.

- **2026-08-31 (Sprint 17)** — US-17, Data Saver. *(Finished in Sprint 18 above.)* The code is
  written, analyzed and unit-tested, and the APK builds; **none of it has been run on a
  device.** The session ended while the emulator was restarting for exactly that check.
  **Said plainly before building:** half the AC has no subject. "VTO/stylist deferred to
  Wi-Fi" refers to US-20 and US-24, both Phase 3 and unbuilt, so there is nothing to defer.
  This sprint built the images half only.
  **The finding that made it buildable at all:** ARCHITECTURE §1 puts thumbnails on R2, which
  does not exist — but every one of the 80,921 catalogued product images is on
  `cdn.shopify.com`, which resizes on request. Measured against the real CDN, not assumed:
  10 random real product images came to **2.99MB full size and 67KB at `width=160` — a 98%
  saving**. A 20-result search page drops from roughly 6MB to 134KB.
  **Built:** Drift `DisplayPrefs` (schema 5 → 6, migration written), `core/image_urls.dart`
  (`sizedImageUrl`, replaces rather than appends a `width` so the curated `width=512` logos do
  not end up asking for two), `data/display_prefs_repository.dart` (the setting, an
  `onMobileDataProvider` off `connectivity_plus`, and the `saveImageDataProvider` that ANDs
  them). Applied at the app's only two network-image sites: brand logos at `width=240` and
  search thumbnails at `width=160`. `notification_settings_sheet.dart` renamed to
  `settings_sheet.dart` and given a Data section. `connectivity_plus` added.
  **Tests:** 9 new (`test/data_saver_test.dart`), all passing. `flutter analyze` clean; 120 of
  131 app tests pass — the same 11 pre-existing fixture-date failures since Sprint 8.
  Backend untouched this sprint (still **199**).
  **Worth knowing about those tests:** the first version of the provider tests passed
  vacuously. `Stream.value` had not emitted by the time the container was read, so every case
  saw `AsyncLoading` and returned the same default the assertions expected. They now attach a
  listener and await both streams — without which an unlistened provider is disposed mid-load
  and its future never completes at all.
  **TO DO NEXT SESSION — this is the whole remaining task:**
  1. Start the emulator, install, open Settings (cog on the Brands tab) and confirm the Data
     Saver switch is there and persists across a restart (it is a new Drift table on a **schema
     migration**, v5 → v6, which has never run against a real installed database — that is the
     single most likely thing to be broken).
  2. Turn it on, then `adb shell svc wifi disable` so the emulator falls back to mobile data,
     and confirm images still render in search and on the brand grid.
  3. Re-enable Wi-Fi (`adb shell svc wifi enable`) and confirm full-size images come back.
  **Found while measuring, NOT fixed — belongs to US-8, not here:** **Sapphire has zero product
  images.** Every other active brand has them on the Shopify CDN; the SFCC `SitemapHtmlAdapter`
  built in Sprint 12 never captured image URLs at all. So Sapphire's products show a placeholder
  in search results today, and Data Saver has nothing to shrink for them.

- **2026-08-31 (Sprint 16)** — US-14, community deal reporting. Picked because it is the only
  remaining Phase 2 story that is both buildable and *verifiable* today, and because it closes a
  real gap: US-3 and US-5 are still marked "Done (on fixture offers)", so every bank offer in the
  app is invented data. This is the pipeline for real ones.
  **Why not the others:** US-16 (WhatsApp sharing) needs a public HTTPS domain for the "web
  fallback page" in its AC, which does not exist yet; US-15 (Bachat Meter) needs the purchase
  tracking US-18 would provide; US-18 itself could be *built* — `brand_config.order_confirm_patterns`
  has been sitting unused since Sprint 1 — but not *verified*, because confirming an order
  detection means placing a real order, the same thing still outstanding from US-2.
  **Much of the shape was already specified.** The `deal_report` table has been in the migrated
  schema since Sprint 1, unused, and ARCHITECTURE §8 already said a community report is one of
  three things that create a draft and that "verifying a community report awards points via
  `points_ledger` (idempotent)". This sprint built that path rather than inventing one.
  **Backend:** `services/uploads.py` (magic-number type detection, size cap, unguessable
  filenames), `services/reports.py` (create / accept / reject, idempotent points, outcome push),
  `api/reports.py` (`POST`/`GET /me/reports`), a Community reports queue on the desk with
  accept/reject HTMX actions and the screenshot inline, a `/uploads` static mount and a Docker
  volume behind it. 19 new tests (**199** total).
  **App:** `report_repository.dart`, `features/reports/` (the report sheet with camera/gallery
  attachment, and a My reports sheet), a "Report a deal" FAB and a My reports icon on the
  Discounts tab, `image_picker` added, and `report` wired into the notification tab routing.
  5 new app tests. `flutter analyze` clean; 111 of 122 pass — the same 11 pre-existing
  fixture-date failures carried since Sprint 8, untouched.
  **Verified live, the whole loop, on the emulator against the real stack:** attached a real
  image from the device gallery, typed "HBL 20% off at Sapphire till Sunday", sent it — a
  `deal_report` row appeared with `status=new` and the screenshot written to the volume
  (112KB, downscaled by the picker from 219KB) and served back over HTTP as `image/png`. The
  desk queue rendered it with its thumbnail and reporter id; accepting it set `accepted`,
  wrote one `points_ledger` row (`deal_report:27`, +50), and the device received **"Your deal
  was verified: Thanks — 50 points are in your balance."** A second accept returned **409**
  with still one ledger row and the balance still 50. My reports then showed it as
  "Verified · +50 points".
  **Not exercised live:** the **reject** path. It is unit-tested and differs from accept only in
  status and wording, sharing the same notification call that was just proven — but no rejected
  report has actually reached a device.
  **Left alone, not silently pushed through:** the real report and its ledger row were left in
  the database — the full backend suite passes with them present, unlike Sprint 13's watch rows,
  so there was nothing to clean up. Also noted and not fixed, since it predates this work:
  `services/notifications.py` logs `Message.token is deprecated. Use Message.fid instead.` on
  every direct push, from US-13.
  **Left for the founder — a real gap before this is public:** there is **no rate limit on
  reporting**. Any signed-in device (which is every device, since auth is guest-first) can post
  reports as fast as it likes, each one writing a file to the volume. That is fine for a closed
  beta with a desk watching the queue, and not fine on the open Play Store. A per-user daily cap
  is the smallest fix; the points ledger already shows how to count per-day actions
  (`rewarded_ads_watched`).
  **Next session:** US-17 (Data Saver) is small and self-contained. US-16 and US-18 both need a
  founder action first — a domain, and a real order respectively.

- **2026-08-31 (Sprint 15)** — US-11, cross-brand search. The Phase 2 story with real new
  infrastructure, and the one that turned the crawl into something you can ask a question of.
  **Scope settled first, against the data rather than the spec.** The AC asks for
  "price/brand/category filters", so the catalog was checked before any code: 81,461 products,
  **423** distinct raw category strings, and `product.gender` NULL on every single row. Price
  and brand were clean; category was not, and gender was not available at all. Put to the
  founder, whose call was that the filter should work *completely* and still reach the original
  detail — so this sprint built a derived canonical taxonomy **and** kept every brand's own
  string as a drill-down beneath it, rather than the cheaper "let the search text handle
  categories" option.
  **Backend — classification (`services/categories.py`):** 13 canonical categories from ordered
  keyword rules, plus an audience (Women/Men/Girls/Boys/Kids) derived from the same text to fill
  the gap `gender` left. Every rule was measured against all 81,461 real products, not designed
  in the abstract, and the measuring is what found the bugs: plural forms silently failing
  ("bag" not matching "Bags") left 7% unclassified; Dupatta & Shawls sitting above Unstitched
  put **4,754** unstitched three-piece sets under "dupatta"; a synonym pair counted as two
  garments turned "Barrel Fit Pants" filed under `TROUSERS` into a suit; and tags voting
  alongside the title filed a kurta under Dupatta & Shawls. Final: **0.17%** fall through to
  `Other`. 29 tests, every case a real (title, category) pair from the catalog and most of them
  a pair an earlier version got wrong.
  **Backend — search:** `meilisearch` added to `docker-compose.yml` with its own volume;
  `services/search_index.py` projects the catalog into a `products` index (81,461 docs in ~26s)
  with Roman-Urdu synonyms; `services/search.py` parses the query and builds the filter;
  `api/search.py` serves `GET /search` with facet counts for all four dimensions. Wired into the
  worker at 04:00 PKT, after the 01:00 crawl. 53 new backend tests (**180** total).
  **App:** `search_repository.dart`, `features/search/` (screen + filter sheet), a `Search` tab
  that became the app's 2nd destination, and an `initialUrl` on `BrandWebViewScreen` so a result
  opens on the product itself rather than the brand's home page. Debounced at 300ms with a
  generation counter, so a slow reply to an earlier keystroke cannot overwrite a later one.
  12 new app tests. `flutter analyze` clean; 106 of 117 pass — the same 11 pre-existing
  fixture-date failures carried since Sprint 8, untouched.
  **Verified live on the emulator, against the real 81k-product index:** typing the AC's own
  "kurta under 3000" gave **"1369 results under PKR 3,000"** — the price phrase understood and
  said back — cross-brand across Junaid Jamshed, Alkaram, Zellbury and more, every price under
  the ceiling. Opening the filters showed live facet counts including the derived audience
  (Girls 219, Women 171, Men 98). Picking **Kurta & Kurti** revealed "Within that, by the
  brand's own name" — Essential Pret (845), Kurti (218), Tunics (52), Jubba (3) — and choosing
  Kurti returned exactly the **218** the facet promised. Tapping a result opened that exact
  product ("OFF WHITE LAWN EMBROIDERED KURTA", PKR 2,690) on junaidjamshed.com, inside the US-2
  toolbar with US-3's offer chips and US-12/13's icons already live on it. Direct API timings
  8–55ms against the AC's 300ms.
  **Fixed after seeing it on a real screen, not in a test:** brand filter chips read
  "junaid-jamshed" — the facet is keyed by slug, because that is what the index filters on.
  They now resolve to the brand's display name from the Drift cache.
  **Left for the founder / next session:**
  • **Roman-Urdu synonyms are a first pass** (~20 entries, hand-written). They work on the ones
  tested live — "salwar qameez", "khusa", "3000 se kam" all land — but the real list should come
  from what people actually type once there are users; the search log is the source, not
  guesswork.
  • **Category rules will drift as brands are added.** The 13 canonical names fit today's 9
  brands; a new brand with an unusual vocabulary should be re-measured with the same coverage
  script before being trusted, and `Other` is the number to watch.
  • US-16 (WhatsApp sharing) and US-14 (community deal reporting) are the natural next Phase 2
  picks; US-16 now has both a price graph and a search result worth sharing.

- **2026-08-31 (Sprint 14)** — US-12, the price graph and Asli Sale badge — the story that
  finally shows shoppers what a month of crawling was for.
  **Scope decided first:** the badge rule (CRAWLER_PLAYBOOK §3) is written against a 90-day
  window and the crawl is 37 days old, so the founder chose up front to compute over the window
  that exists and label it honestly rather than hold the badge until late October. The AC's
  "one-tap shareable image card" was deliberately left with US-16 (WhatsApp deep-links) instead
  of half-building sharing here.
  **Backend:** `services/price_history.py` — pure series-building and verdict logic, separated
  from the one DB read (`load_variant_rows`), so 11 of the 13 new tests need no database. Two
  data-shape decisions drove it and are in the Decision Log: the series is per *product*
  (cheapest variant per day, each variant's step function rebuilt separately first), and
  "typical" is *time-weighted* rather than a median over rows — rows exist only on change, so
  counting them would let a one-day dip outweigh a month at full price and hand out the badge
  wrongly. `api/products.py` serves `GET /products/{id}/price-history`, unauthenticated. 13 new
  backend tests (127 total).
  **App:** `price_history_repository.dart` (model + `PriceVerdict` enum + provider),
  `price_graph_sheet.dart` (the sheet, the verdict banner, and a `CustomPainter` step chart —
  no charting dependency), one `api_client` method, and a `historyAction` slot on `address_bar`
  beside US-13's `watchAction`. The chart icon appears on exactly the same condition as the
  Watch bell and reuses the product id from the same watch-status call, so no new URL-to-product
  resolution was needed. 10 new app tests. `flutter analyze` clean; 97 of 108 app tests pass —
  the same 11 pre-existing fixture-date failures carried since Sprint 8, untouched.
  **Verified live on the emulator against real crawled data, two products, both reached by
  genuine browsing (Alkaram home → Ready to Stitch → product):** a real drop — PKR 4,790 held
  for 28 days, then 3,353 — rendered the step chart and the green **Asli Sale** badge reading
  "Cheaper than the PKR 4,790 it normally sells for"; a second, flat-priced product correctly
  *refused* the badge with "This is the usual price — PKR 3,390 is what it has cost for most of
  this time, whatever the crossed-out price says." Both footed with "Based on 37 days of price
  checks so far." Nothing was written to the database by this verification — the endpoint is
  read-only, so unlike Sprint 13 there was no test data to clean up afterwards.
  **Not proven, and worth knowing before trusting the badge in a sale:** the `pre_sale_markup`
  rule has never fired on real data. A scan of 1,770 products that had any price change inside
  the 21-day lookback produced 0 hits — no brand has yet raised a price and discounted it back
  within our window. The rule is unit-tested and the other two verdicts occur naturally (of 400
  real products sampled: 221 `genuine`, 179 `not_lowest`), but the fake-discount case itself is
  unexercised until a real sale event. **Re-check it during Blessed Friday**, which is exactly
  when a brand would do this and exactly when the badge matters.
  **Also noted, not changed:** day buckets use UTC while the audience is PKT (UTC+5). It is
  internally consistent — observations and buckets use the same clock, and the 01:00 PKT nightly
  crawl lands in a distinct UTC day each night — but "today" on the graph turns over at 05:00 PKT.
  **Next session:** US-11 (cross-brand search) is the natural remaining Phase 2 anchor, and it
  needs Meilisearch added to `docker-compose.yml` — the one Phase 2 story with real new infra.
  US-16 (WhatsApp sharing) is more attractive than it was, since US-12 has now given it
  something worth sharing (a fake-discount card beats a bare link).

- **2026-08-23/24 (Sprint 13)** — US-13, price-watch / restock alerts, the first Phase 2 story.
  **Scope:** a Watch toggle appears on the address bar once the injected reader script detects a
  product page *and* the API confirms it's a product already in our catalog; toggling it creates
  both a `price_drop` and a `restock` watch row (a shopper watching a sold-out item wants to know
  the moment it's back, not just if its price moves). An hourly worker job re-fetches only
  watched products and pushes a direct-to-device notification on a real change.
  **Backend:** `crawlers/base.py`'s `PoliteFetcher` gained `get_text`/`get_html` alongside the
  existing `get_json`, all sharing one `_fetch()` — so a single-product re-check gets the same
  robots.txt/rate-limit/retry behavior as a full crawl. Both adapters gained a `fetch_one_product`
  that re-checks one product without re-walking a sitemap or re-listing a collection.
  `services/watches.py` (find/is-watching/start/stop) + `api/watches.py` (watch-status, create,
  delete) + `api/me.py`'s `PUT /device-token`. `services/watch_alerts.py` is the Tier-W job:
  per watched product, re-fetch, `ingest_products` the result (so price history stays correct
  regardless of watch alerts existing), compare before/after variant state, and notify watchers
  of whichever of `price_drop`/`restock` actually fired — see Decision Log for the OpenGraph,
  direct-push, and renotify-cooldown calls. `services/notifications.py` gained
  `send_device_notification` alongside US-6's topic sender. Wired into `worker.py` on a 60-minute
  interval. 23 new backend tests (114 total).
  **App:** `product_reader.dart` — the injected script (read-only per ARCHITECTURE §6) and the
  `DetectedPage` model. `brand_webview_screen.dart` wires it: `addJavaScriptHandler` receives
  the page report, fetches watch status only for a detected product, and shows a bell icon
  (`notifications_none`/`notifications_active`) that toggles the watch with an optimistic local
  update. `watch_repository.dart`, `api_client.dart` additions, and `address_bar.dart` gained an
  optional `watchAction` slot. `notifications_service.dart` now also registers/refreshes this
  device's own FCM token (`registerDeviceToken`, called from `main.dart` after permission and
  from `HomeShell.initState` on token refresh) — the piece US-6 deliberately left unbuilt since
  nothing needed it yet. 4 new app tests. `flutter analyze` clean; 87 of 98 app tests pass —
  same 11 pre-existing fixture-date failures as every prior sprint since Sprint 8, untouched.
  **Debugging note, not a code decision:** `adb logcat` piped to a file proved unreliable for
  this debugging session in this Windows/Git-Bash setup — intermittent missed lines produced at
  least one false-negative diagnosis along the way. Screenshot- and database-state verification
  ended up the trustworthy signal throughout; worth defaulting to that over logcat capture for
  any future on-device debugging in this environment.
  **Verified live, start to finish, on a clean reinstall (to rule out a stale FCM token from
  earlier debugging cycles):** opened a real Alkaram Studio product page, the bell icon appeared
  once the API confirmed the product, tapping it created real `price_drop`/`restock` watch_item
  rows. Inflated the product's real price in the database, backgrounded the app, ran
  `run_watch_alerts()` directly in the API container: it re-fetched the live page, restored the
  true price, detected the drop, and a genuine Android system notification — "Price drop — RTS |
  SHIRT, TROUSER & DUPATTA — now Rs 3,353" — appeared in the notification shade.
  **Left alone, not silently pushed through:** the manual watch_item rows created during this
  live verification were deleted afterward (unlike some earlier sprints' real-usage evidence,
  these are iterated wholesale by `run_watch_alerts` and were found to directly break three
  count-based backend test assertions when left in the shared database — deleting them, not the
  tests, was the fix). The device_token rows from the same testing were left in place; they don't
  affect any test's outcome.
  **Next session:** US-11 (cross-brand search) or US-12 (price graph + Asli Sale badge) are the
  other two natural Phase 2 picks alongside US-13 — no session-specific reason yet to prefer one
  over the other.



- **2026-08-23 (Sprint 12)** — US-8, built the Salesforce Commerce Cloud adapter ARCHITECTURE.md
  named but never scoped, and activated Sapphire on it — the 9th brand.
  **Scope decided first:** SFCC has no product-feed API, so this was always going to be real HTML
  scraping (fragile) rather than another clean JSON adapter, and page-level research turned up no
  variant matrix — checked before writing code, not after, since it changes what the adapter can
  ever promise. Landed on: single variant per product, sourced from the page's own GA4 tracking
  blob (steadier than incidental markup, since the site's own analytics breaking is their problem
  too), and a redirect-away-from-its-own-URL as the "delisted" signal — verified against a real
  dead product URL before trusting it, not assumed.
  **Backend:** `crawlers/sitemap_html.py` — pure `_parse_product_page(html, url)` separated from
  the fetch, so the parsing logic has 8 real tests (99 backend total) without mocking HTTP. Caught
  a real bug immediately: comparing `str(1490)` against `str("1490.00")` for the "is this actually
  a discount" check — string comparison said yes, the numbers say no; fixed by comparing as
  `Decimal`. `crawlers/base.py`'s `PoliteFetcher.get_json` split into a shared `_fetch` plus
  `get_text`/`get_html`, so the new adapter gets the exact same robots.txt/rate-limit/retry
  behavior as Shopify's, not a parallel implementation of it. `services/crawl.py` now dispatches
  by `brand.platform` instead of hardcoding Shopify.
  **Verified live, not just against fixtures:** 5 real Sapphire products parsed correctly (prices,
  titles, categories); a known-dead product URL correctly redirected and read as unavailable; 20
  products actually ingested into the database end-to-end (`ingest_products`, real `price_history`
  rows) before deciding the pipeline was trustworthy enough to flip `is_active`.
  **Left alone, not silently pushed through:** did not run Sapphire's full 4,130-product crawl
  this session — SFCC's one-request-per-product cost makes that ≈3.4h at the standard politeness
  delay, and forcing it (or shortening the delay to make it faster) would have meant either tying
  up the session for hours or cutting a corner CRAWLER_PLAYBOOK §6 treats as a hard rule. The
  nightly cron picks it up and backfills over several nights instead, the same way the original 5
  pilots' first full crawl worked in Sprint 1.
  **Left for the founder:** Khaadi stays inactive — its sitemap lists no products, so it needs
  category-page crawling, a different and larger adapter than today's. Build incremental crawling
  (the sitemap's own `<lastmod>` would support skipping unchanged products) before a second SFCC
  brand joins Sapphire, or two of them together risk blowing the nightly window entirely.
- **2026-08-23 (Sprint 11)** — US-8, activated the three already-seeded next-wave brands
  (Beechtree, Edenrobe, Zellbury), taking active brands from 5 to 8. Their `brand_config` rows
  (`products_json_ok`, checkout domains, frequency tier) were seeded back in Sprint 1 but never
  turned on — before trusting a month-old seed, re-checked each site live: `robots.txt` and
  `/products.json` both still open on all three (`edenrobe.com`'s `www` now 301s to the bare
  domain — `PoliteFetcher` already follows redirects, so nothing to change). Flipped `is_active`,
  then ran a targeted crawl (`--brands beechtree,edenrobe,zellbury`) rather than the full nightly
  set, so the run stayed fast and its output stayed readable.
  **Real result, no blocks:** Beechtree 1,941 products / 7,029 history rows, Edenrobe 18,252 /
  73,680, Zellbury 14,204 / 47,910 — all first-seen, no 429/403 from any of the three. Re-crawled
  Beechtree alone straight after: `products_new: 0, history_rows: 0`, confirming idempotency the
  same way Sprint 1 did for the original five. `GET /brands` confirmed 8 active, and the app
  showed Beechtree and Edenrobe on a pull-to-refresh with no other change needed — both fall back
  to a monogram tile, since neither has ever had a logo curated (2026-07-26's `LOGOS` dict decision
  applies here unchanged; someone still needs to hand-pick their CDN logo URLs).
  **Left for the founder:** 17 more brands before the 25 target — sourcing them is a
  business/partnership call, not something to decide unilaterally. Khaadi and Sapphire are already
  seeded but need the Salesforce Commerce Cloud `SitemapHtmlAdapter` ARCHITECTURE.md scoped but
  never built; that's real new engineering, not another activation like this one.
- **2026-08-23 (Sprint 10)** — US-10, points for daily streaks and rewarded ads, the last
  Phase-1 wedge story besides finishing US-8's brand count. **Scope decided first:** no AdMob
  account exists, but Google publishes public test app/ad-unit IDs that serve real ad creative —
  built the whole flow against those rather than stubbing it, to swap in real IDs before the beta.
  **Backend:** `services/points.py` — `award_points` inserts via `ON CONFLICT DO NOTHING` on
  `idempotency_key`, mirroring `auth.get_or_create_user`'s shape; `.returning()` rather than
  `.rowcount` is what actually tells the caller whether it inserted (rowcount came back 0 even on
  a clean insert — unreliable for this statement shape, first three tests caught it immediately).
  `current_streak` counts consecutive check-in days backward from today if checked in, yesterday
  otherwise, so the streak doesn't drop to 0 the moment the clock rolls into an unchecked day.
  `api/points.py`: `GET /me/points`, `POST /me/points/checkin` (+10, once/day), `POST
  /me/points/rewarded-ad` (+20, capped at 5/day, keyed by an app-generated `client_ref` so a retry
  can't double-pay). Moved `test_me.py`'s `as_signed_in` fixture into `conftest.py` since
  `test_points.py` needed the identical no-Firebase auth override. 12 new tests, 83 backend total.
  **App:** `google_mobile_ads` added; the main manifest carries Google's public test AdMob
  application ID. `core/rewarded_ad_service.dart` loads and shows a rewarded ad against the public
  test ad-unit ID. `data/points_repository.dart` (`PointsStatus`/`PointsActionResult`, mirroring
  the backend's `PointsOut`/`PointsActionOut` split) reused the `IdTokenProvider` seam US-9 built —
  moved it from `offer_directory_repository.dart` to `auth_service.dart` since two repositories
  now want it. `features/points/points_sheet.dart` shows balance, streak, and the two earn
  actions; a trophy icon on the Brands tab opens it. 5 new tests (94 app total, 83 passing — the
  same 11 pre-existing fixture-date failures from Sprint 8/9, untouched). `flutter analyze` clean.
  **Emulator evidence, start to finish:** opened at 0 points; "Check in for +10" → real `POST
  /me/points/checkin` → 10 points, "🔥 1-day streak," button correctly disabled after. "Watch an
  ad for +20" loaded and played a genuine Google test ad (the IKEA house-tour creative) — SDK
  showed "Reward granted," `onUserEarnedReward` fired, a real `POST /me/points/rewarded-ad`
  landed, and the sheet updated to 30 points with "4 left today." Confirmed in the database: two
  real `points_ledger` rows, not fixtures — left in place, since unlike the MCB test offer from
  Sprint 9 this is genuine usage data with no false trust claim attached.
  **Left for the founder:** swap the test AdMob app ID (`app/android/app/src/main/AndroidManifest.xml`)
  and ad-unit ID (`core/rewarded_ad_service.dart`) for real ones before the closed beta.
  **Next session:** the wedge (US-1…10) is now feature-complete except finishing US-8's brand
  expansion toward 25 — the last open item before Phase 1 is fully shipped.
- **2026-08-22 (Sprint 9)** — US-6, sale/offer push notifications, built and verified for real
  in the same session as US-9 (Sprint 8) so it could reuse the Firebase project that unblocked.
  **Scope decided first:** the AC's "a followed brand's sale" implies a follow feature that does
  not exist; rather than build one, every device subscribes to every active brand's sale topic and
  every bank behind a saved card's offer topic, with two on-device switches as the only opt-out —
  see Decision Log.
  **Backend:** `app/firebase.py` holds the one shared `firebase_admin` app (auth verification and
  push both need it, and initialising twice raises). `services/notifications.py` sends topic
  messages, catching and logging any failure so a push outage never blocks the worker's own job.
  `services/deals.py._notify_live` hooks the existing `VERIFIED → LIVE` transition — the only path
  to `live` — building `sale-{brand_slug}` / `offer-{bank_slug}` topics and human-readable titles
  from the brand/bank rows. 4 new tests (71 backend total): a sale push, a brand-scoped offer push,
  a multi-brand offer push ("at all brands"), and confirmation that a deal still out of its window
  pushes nothing. The two pre-existing transition tests got an autouse fixture stubbing the sender
  so they no longer make a real network call.
  **App:** `firebase_messaging` added; `POST_NOTIFICATIONS` declared in the main manifest.
  `core/notifications_service.dart` diffs desired-vs-subscribed topic sets in memory (Firebase
  subscribe/unsubscribe is idempotent, so nothing needs to survive a restart) and exposes the pure
  `homeTabIndexForNotification` that maps a push's `data.type` to a tab index — unit tested.
  Drift `schemaVersion` 4 → 5 added `NotificationPrefs`, a one-row on/off pair for the two
  categories. `HomeShell`'s tab index moved from local `State` to a `StateProvider` (needed the
  `flutter_riverpod/legacy.dart` import — `StateProvider` moved there in Riverpod 3) so a tapped
  notification can switch tabs from outside the widget tree; `HomeShell.initState` wires
  `onMessage` (foreground → SnackBar with a View action), `onMessageOpenedApp`, and
  `getInitialMessage` (background/terminated tap → switches tab directly), and re-syncs topic
  subscriptions whenever brands, saved cards, or the toggles change. A bell icon on the Brands tab
  opens `NotificationSettingsSheet`. `flutter analyze` clean; 78 of 89 app tests pass — the 11
  failures are the pre-existing fixture-date-rot from Sprint 8, untouched here.
  **Emulator evidence, start to finish:** launch showed the real Android 13+ permission prompt;
  the bell icon opened the settings sheet with both switches on by default; turning "Sale alerts"
  off and reopening the sheet confirmed the write survived (Drift, not just widget state). Then a
  real end-to-end push: inserted a fresh `verified` MCB bank offer via SQL, backgrounded the app,
  ran `run_deal_transitions` in the container, and a genuine Android system notification arrived
  ("MCB Bank offer is live — 25.00% off at all brands") within about a minute — tapping it opened
  the app straight to the Discounts tab, proving `getInitialMessage`/deep-link routing works, not
  just the code compiling. The test offer was deleted immediately after (raw SQL, fake proof URL —
  leaving it would have been exactly the fabricated-verification problem RUNBOOK §5 warns about).
  **Noticed, not fixed:** the push body reads "25.00% off" rather than "25% off" — `Decimal`'s `g`
  format preserves the column's stored precision instead of normalising it the way `float` would.
  Cosmetic; worth trimming with `.normalize()` whenever `_offer_saving_text` is next touched.
  **Left for the founder:** nothing blocking — device tokens for *direct* sends (US-13 price-watch,
  US-18 order points) are still unbuilt, since `device_token` has no functional role in this story.
- **2026-08-22 (Sprint 8)** — US-9 unblocked and finished on the app side. The founder's two
  blockers from Sprint 7 are cleared: `google-services.json` and
  `backend/secrets/firebase-service-account.json` both now exist, sourced from a real Firebase
  project (`allbrand-1`, provisioned this session — see Decision Log) rather than a placeholder.
  **App:** `core/auth_service.dart` wraps `FirebaseAuth` — anonymous sign-in at launch
  (`main.dart`, before `runApp`), an ID-token getter, and `linkGoogleAccount()`, which upgrades
  the same UID via `linkWithCredential` and falls back to `signInWithCredential` when the Google
  account is already tied to a different UID (a reinstall or a second device). Drift
  `schemaVersion` 3 → 4 added `SyncState`, a one-row dirty flag `MyCards` mutations set;
  `OfferDirectoryRepository.reconcileMyCards()` pushes local when dirty, otherwise pulls the
  account's set — called once after sign-in and again after a successful link. A "Link Google
  account" banner sits at the top of the Discounts tab, visible only while anonymous, explaining
  what linking buys rather than gating anything (saving cards already works as a guest).
  Android: `com.google.gms.google-services` 4.5.0 wired into `settings.gradle.kts` +
  `app/build.gradle.kts`; `firebase_core`, `firebase_auth`, `google_sign_in` added via
  `flutter pub add` (resolved to 4.13.0 / 6.5.7 / 7.2.0). `flutter analyze` clean,
  `flutter build apk --debug` succeeds.
  **Emulator evidence (real project, not stubs):** minted a real anonymous Firebase ID token via
  the Identity Toolkit REST API and round-tripped it through the live API — `GET`/`PUT /me/banks`
  both verified and persisted with firebase-admin reading the actual service-account key, not an
  overridden test verifier. On the emulator itself: app launched with no Firebase error, the Link
  Google banner appeared on the Discounts tab exactly as written, ticking a card in "My cards"
  fired a real `PUT /me/banks` (confirmed in the API's own logs, 200 OK) and the directory
  correctly filtered to the one matching offer. Tapping "Link Google account" launched Android's
  real Credential Manager flow (confirmed in logcat — `GetGoogleIdOperation`, `GoogleIdService`)
  and failed gracefully (no Google account on this emulator, no crash), proving the Gradle/native
  wiring is correct up to the point where a real account is needed.
  **Left for the founder:** completing an actual Google link needs a device or emulator signed
  into a real Google account — the code path is wired and exercised up to Android's account
  picker, but nobody has tapped through it end-to-end. Do that once, on the emulator or a phone,
  and confirm the guest's saved cards survive the switch.
  **Noticed, not fixed (unrelated to US-9):** 11 of 86 app tests now fail — all trace to one
  fixture, `test/fixtures.dart`'s Bank Alfalah offer (`valid_to: '2026-08-16'`), which is real-world
  expired now that today is 2026-08-22. `isOfferCurrent` is correctly filtering it out; the tests
  just have a stale date baked in. Left alone since it's pre-existing and outside this session's
  scope — bump the fixture's dates forward next time someone touches that suite.
- **2026-08-01 (Sprint 7)** — US-9 started; the API half is done, the app half is blocked on
  founder setup. Backend: `app/auth.py` verifies Firebase ID tokens and provisions a `user` row
  per UID (`ON CONFLICT DO NOTHING` — the app fires several requests at launch and two can race
  for a brand-new UID), plus `GET`/`PUT /me/banks` storing the shopper's cards in
  `user.my_banks`. `firebase-admin` added to requirements and the image rebuilt.
  15 new tests, 67 backend total. They override the verifier, so **the suite needs no Firebase
  project** — only the token check belongs to Firebase; provisioning, storage and validation run
  against the real database. Verified live with no service-account key on disk: `/health` and
  `/brands`, `/sales`, `/offers` all 200, `/me/banks` 401 rather than 500.
  **Blocked — the founder must create the Firebase project.** Two artifacts are needed and only
  someone signed into the console can produce them:
  1. `app/android/app/google-services.json` — Android app registered with package
     `pk.brandnest.brandnest` and the debug keystore SHA-1
     `43:B3:5D:D8:74:C9:1B:F1:B3:91:8D:E4:4F:A6:A6:23:99:FA:6F:08`
     (from `keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore`,
     storepass `android`). **The SHA-1 is not optional** — without it Google Sign-In builds fine
     and fails at runtime. A release build will need its own fingerprint added later.
  2. `backend/secrets/firebase-service-account.json` — Project settings → Service accounts →
     Generate new private key. The directory exists and is `.dockerignore`d so the key is never
     baked into the image.
  Also required in the console: Authentication → Sign-in method → enable **Anonymous** *and*
  **Google**. No app code was written, because the `google-services` Gradle plugin hard-fails
  when the config is absent — it could not have been compiled, let alone verified on the
  emulator.
  **Settled for the app half, so it does not get re-litigated:** anonymous sign-in means a guest
  already holds a token at first launch, so `/me/banks` works before any Google account exists —
  the link is what makes the saved set survive a reinstall or a new phone, and that is what the
  prompt should say. On launch the account wins when it has anything saved; an empty account plus
  cards on the device means this phone ticked them before it ever signed in, so those go up. A
  tick made offline sets a dirty flag and pushes on next launch rather than being silently
  overwritten by the server's older set.
  **Next session:** once both files are in place — wire the `google-services` Gradle plugin, add
  `firebase_core`/`firebase_auth`/`google_sign_in`, sign in anonymously at launch, attach the ID
  token to `/me` requests, build Google link-on-demand keeping the same UID, and sync `my_cards`
  with Drift staying the offline cache. Verify on the emulator, including a link that preserves
  the guest's saved cards.
- **2026-08-01 (Sprint 6)** — US-5, the bank-discount directory. Backend: `GET /offers`
  serving every currently-usable offer across all brands, with the bank's slug and the brand
  it belongs to attached (both brand fields null = works everywhere). The visibility rule that
  used to live inside the brand-scoped route is now `_visible_today()`, shared by both, so the
  directory and the chips cannot drift apart. 8 new tests, 52 backend total.
  App: Drift `schemaVersion` 2 → 3 adding `directory_offers` (the cache) and `my_cards` (the
  shopper's own banks + card types, device-local). `OfferDirectoryRepository` follows the
  brand/sale shape — reads from Drift, `refresh()` is the only thing that needs the network —
  but maps rows back to `BankOffer` so the directory and US-3's chips share one model and one
  set of formatters. Those formatters and `OfferDetailSheet` moved to `features/offers/`;
  `offer_chips.dart` keeps just the chip strip. New `features/offers/`: `directory_screen.dart`
  (grouped by bank, best saving first, "All brands" for multi-brand offers), `my_cards_sheet.dart`
  (ticks save as you tap — no Save button to lose), `my_cards.dart` (the matcher and the picker
  options, both pure). `HomeShell` gained a third destination, Discounts. 33 new app tests
  (86 total), `flutter analyze` clean.
  **Emulator evidence:** installed *over* the existing v2 install, not a clean one — schema went
  to 3, `directory_offers` and `my_cards` appeared, and the brand grid (5) and calendar (2) kept
  their caches. Six offers rendered grouped under Bank Alfalah / MCB (10% then 8%, best first)
  / Meezan ("All brands") / Standard Chartered / UBL; the two deliberately-invisible fixtures —
  the out-of-window UBL 25% and the unverified Bank Alfalah 30% — correctly never appeared.
  Ticking *Meezan → Islamic* wrote one `my_cards` row, swapped the prompt card for an already-on
  "My cards only" chip, and cut the list to the single Meezan offer; turning the chip off brought
  all six back. Cold start in airplane mode still rendered the directory and the saved filter.
  **Left for the founder — unchanged from US-3 and now more urgent:** the six offers on screen
  are fixtures with terms nobody confirmed with any bank. US-5 gives them a whole browsable
  screen under a "Verified offer" heading, which is a bigger trust claim than a chip was. Enter
  real desk-verified offers at `/admin`, or run `DELETE FROM bank_offer WHERE source = 'fixture';`
  before the closed beta.
  **Noticed, not fixed (predates US-5):** `IndexedStack` builds all three destinations at once,
  so every screen fires its refresh at launch and they all queue snackbars into the one root
  `ScaffoldMessenger` — offline, "showing the saved calendar" appears over whichever tab you are
  on. Brands and Sales already did this; US-5 adds a third to the queue. Fixing it properly means
  refreshing only the visible destination, which touches all three features.
  **Next session:** US-6 (push) or US-9 (guest auth) — US-9 is what gives `my_cards` somewhere
  server-side to live and would let the local rows migrate before the beta rather than after.
- **2026-07-27 (Sprint 5)** — US-7 and US-4, in that order and for that reason: the desk had
  to exist before the calendar, or the calendar would have shipped on invented sales.
  **US-7.** `services/deals.py` holds the state machine for both `sale_event` and `bank_offer`
  (identical status columns, one module). Verifying requires a proof link and an actor and
  stamps `verified_by`/`verified_at`; `live`/`expired` are refused to humans and belong to
  `run_deal_transitions`, now an hourly worker job that also runs once at worker start so a
  restart catches up. `app/admin/` is a Jinja2 + HTMX desk at `/admin` behind basic auth:
  review queue, filtered lists, manual entry forms, row actions that swap in place.
  Evidence: the very first run of the transition job moved the deliberately out-of-window UBL
  fixture from `live` to `expired` on its own. 21 new backend tests.
  **US-4.** `GET /sales` serves desk-approved events in a date window (default −30d…+90d),
  including ended ones so a month view is honest. App: Drift `schemaVersion` 1 → 2 (first real
  migration, verified by upgrading over the existing install), `SaleRepository`, and
  `features/calendar/` — List and Month tabs, `SaleCard`, a hand-rolled Monday-first month grid
  with dots, and pure phase/countdown functions. `main.dart` now opens a `HomeShell` with a
  Brands/Sales `NavigationBar`. 23 new app tests (53 total), `flutter analyze` clean.
  **Real data at last:** scanning the five pilots' homepages the way the crawler will
  (CRAWLER_PLAYBOOK §3) found two announced sales — Outfitters "Summer Sale, up to 50% off"
  and Bonanza Satrangi "Mid Summer Sale, up to 50% off". Both were entered as drafts through
  the desk, verified against the brands' own pages, and published by the worker. Alkaram's
  "10% off" was a newsletter prompt, not a sale — exactly the kind of false positive the desk
  exists to reject, so it was left out. J. and Limelight have permanent `/collections/sale`
  sections but no announced campaign; a standing clearance aisle is not a sale event.
  Emulator: both sales render under "On now" with the Verified badge, and a cold start in
  airplane mode shows the full calendar from cache.
  **Not verified on device:** the month-grid dots and the "Starts in N days" countdown, because
  no pilot brand had an announced *dated* sale today. Both paths are covered by unit tests
  (`sale_phase_test.dart`). They will exercise themselves the first time the desk enters a sale
  with dates — Azadi (14 Aug) is the obvious next one.
  **Also unverified:** the desk's own pages were checked over HTTP, not in a browser. Another
  project on this machine has a service worker registered on `localhost:8000` that answers for
  every path, and basic auth opens a modal the automation cannot dismiss. Use `127.0.0.1:8000`
  when opening the desk by hand.
  **Next session (agreed 2026-07-27): US-5** — bank-discount directory, browsable and filtered
  by the user's own banks and card types, which is what finally makes US-3's chips personal.
  Two things to settle before writing code: where "my cards" lives while US-9 (auth) is still
  unbuilt — device-local in Drift, or a `user` row keyed to a Firebase anonymous UID — and
  whether the directory reuses `GET /brands/{slug}/offers` or needs its own unfiltered feed.
  And the fixture offers above are the data US-5 will display, so replacing them at the desk
  is part of the story, not a follow-up.
- **2026-07-26 (Sprint 4)** — US-3 built and verified on the emulator. Backend:
  `app/api/offers.py` serving `GET /brands/{slug}/offers` — the brand's own offers plus
  multi-brand ones (`brand_id IS NULL`), filtered to desk-approved statuses *and* a current
  validity window, ordered best-saving-first, 404 on an unknown slug. Money and percentages
  are plain JSON numbers (display values the app never computes with).
  `scripts/seed_bank_offers.py` seeds five real banks and eight fixture offers, idempotently
  (second run: 0 created, 8 refreshed). First backend test suite: 10 tests, all passing.
  App: `data/bank_offer.dart` (+ `fetchBrandOffers`), `features/brand_webview/offer_chips.dart`
  (chip strip, detail sheet, and the pure formatters behind them). The offers request is fired
  from `BrandWebViewScreen.build` alongside the config one, so it is in flight before the
  WebView starts loading. 30 app tests pass (15 new), `flutter analyze` clean.
  Emulator evidence: Outfitters shows *Standard Chartered 15% off* and *Meezan Bank 10% off*
  while its page is still at ~10% loaded; the out-of-window UBL 25% and the unverified Bank
  Alfalah 30% fixtures correctly never appear. Limelight shows *Bank Alfalah 20% off* +
  the multi-brand Meezan chip. The sheet lists card types, minimum spend, the cap, "Valid till
  24 Sep 2026", the channel, and the proof link; tapping the proof link opened
  `sc.com/pk/promotions/` in Chrome and the Outfitters session was untouched on return.
  API latency measured at ~10 ms locally, so the chips are limited by the route transition,
  not the fetch.
  **Left for the founder:** the fixture offers are placeholders. Before the closed beta, either
  enter real desk-verified offers (US-7 gives the screens for it) or run
  `DELETE FROM bank_offer WHERE source = 'fixture';` — shipping fixtures as "Verified ✓" is
  exactly the trust failure RUNBOOK §5 is written about.
  **Next session:** US-4 verified sale calendar, which also brings the "Sale Now" tab the brand
  grid is already written to accept, or US-7 (admin deals desk) if real offer data is wanted
  first — US-7 is what turns US-3 and US-5 from fixtures into a product.
- **2026-07-26 (Sprint 3)** — US-2 built and verified on the emulator, and the `=`-path
  blocker is gone: the repo now lives at `C:\Users\arsla\dev\brandnest` and
  `flutter build apk --debug` runs from it in ~90s. Backend: `GET /brands/{slug}/config`
  serving only the webview slice of `brand_config` (UA override + checkout domains; crawl
  settings stay server-side), 404 on an unknown slug; `seed_brands.py` backfills
  `checkout_domains` for the Shopify brands and stays idempotent (second run: 0 updates).
  App: `features/brand_webview/` — `BrandWebViewScreen` (config → browser, defaults on API
  failure), `AddressBar` (+ pure `AddressBarState`), `PopupWebView` for `window.open`
  targets sharing the parent cookie session, `external_links.dart` for non-web schemes.
  Grid tiles now open the brand instead of a placeholder snackbar. 15 tests pass,
  `flutter analyze` clean. Also fixed the release-build gap flagged last session: `INTERNET`
  moved into the **main** manifest, plus the `<queries>` entries Android 11+ needs before
  `url_launcher` can see the dialer/WhatsApp/mail apps.
  Emulator evidence: Outfitters browsed home → MEN → t-shirt listing → PDP → size modal →
  basket → **Shopify checkout with Cash on Delivery preselected**, entirely in-app, address
  strip holding `🔒 outfitters.com.pk` throughout. All five pilots open with the correct host
  and padlock (Outfitters, J., Limelight, Alkaram Studio, Bonanza Satrangi) — none needed a UA
  override, so `webview_user_agent` stays NULL everywhere until a brand misbehaves. Limelight's
  header `tel:` link handed focus to `com.google.android.dialer`; system back walks the brand's
  own history before leaving; X returns to the grid.
  **Left undone deliberately — the founder's call:** the AC's "COD flow works end-to-end on
  5 test brands" stops one tap short. Tapping *Complete order* places a real order with a
  real delivery obligation at a real store, so it was not done. To finish the AC, place one
  low-value COD order per pilot yourself and cancel it with the brand, or ask the brands for
  test SKUs. The 3DS/OTP popup path (`onCreateWindow`) is likewise wired but unexercised — it
  only triggers on a card payment, which has the same problem.
  **Next session:** US-3 bank-offer chips, which is where the injected reader JS from
  ARCHITECTURE §6 finally earns its place.
- **2026-07-26 (Sprint 2)** — US-1 built and verified end-to-end. Backend: `app/api/brands.py`
  (`GET /brands`, active brands only, ordered by tier then name) + a `db_session` FastAPI
  dependency; returns the 5 active pilots and excludes the 5 inactive ones. App: replaced the
  counter scaffold with the ARCHITECTURE §4 layout — `core/` (api_client, theme), `data/`
  (Drift `AppDatabase`, `BrandRepository`), `features/home/` (grid + tile). Reads always come
  from Drift; the API only feeds `refresh()`. 3 tests pass (`flutter analyze` clean); emulator
  run confirms the grid, Men-tab filtering, and cold-start offline rendering.
  **Blocker for the founder to decide:** the project path contains `=` (`proj=-kk`), and
  `cmd.exe` treats `=` as a delimiter, so `gradlew.bat` receives a truncated path and every
  Android build fails ("`C:\Users\arsla\OneDrive\Pictures\proj` is not recognized"). A
  directory junction does **not** help — Flutter resolves it back to the real path. Verified by
  copying the app to a clean path, where the APK builds. The app must live at a path with no
  `=` before any further Android work: rename `proj=-kk` → `proj-kk`, or move the repo out of
  OneDrive (e.g. `C:\Users\arsla\dev\brandnest`, which also stops OneDrive syncing build output).
  Also noted, not fixed: `INTERNET` permission exists only in the debug/profile manifests, so a
  release build cannot reach the API until it is added to `android/app/src/main`.
  Emulator now available: AVD `brandnest` (Android 36, google_apis, x86_64).
- **2026-07-26 (Sprint 2, later)** — Brand logos now render. They were missing because
  `brand.logo_url` was NULL for all 10 brands: nothing ever populated it (the seed script did
  not set it, and the crawler ingests products, not brand identity). Fixed as data, not code —
  `seed_brands.py` gained a `LOGOS` dict and now backfills logos onto existing rows, so
  re-running it is idempotent. The app needed no change to display them. Tile rendering was
  then polished (white plate + padding) because Bonanza's wide wordmark clipped edge-to-edge
  and Outfitters' JPEG carried a baked-in white background. Verified on the emulator with
  logos on, and offline where all five correctly fall back to monograms.
  Rebuild recipe while the path still contains `=`: `robocopy <repo>\app
  C:\Users\arsla\dev\bn-verify /E /XD build .dart_tool .gradle`, then `flutter pub get &&
  flutter build apk --debug` there, then `adb install -r`. ~40s once Gradle's cache is warm.
  **Next session:** US-2 — brand shopping in `flutter_inappwebview` (ARCHITECTURE §6). Needs
  `GET /brands/{slug}/config` to serve `brand_config` (UA override, product URL regex, checkout
  domains) to the app, and replaces the grid's placeholder tap handler. Decide first whether the
  project folder gets renamed off `=`, since US-2 means frequent rebuilds.
- **2026-07-25** — Created project docs scaffolding (`IMPLEMENTATION_PLAN.md`, `PROGRESS.md`).
- **2026-07-25 (evening)** — Dev environment completed: Flutter 3.44.8 SDK installed at
  `C:\Users\arsla\dev\flutter` (on user PATH), Android SDK 36 + platform-tools via
  cmdline-tools at `C:\Users\arsla\dev\android-sdk` (ANDROID_HOME set, licenses accepted;
  Java 21 was already present). `flutter doctor`: all green except Visual Studio (not needed).
  Flutter app scaffolded at `app/` (project `brandnest`, org `pk.brandnest`, Android-only).
  **Next session:** US-1 brand grid — `GET /brands` endpoint + app skeleton per
  ARCHITECTURE.md §4 (core/, features/), first run on a device/emulator (first Gradle build
  downloads dependencies, allow ~15 min).
- **2026-07-25 (Sprint 1, later)** — Diagnosed the 429s: strict stores (Outfitters, J.,
  Limelight) enforce ~1-page/min quotas with `Retry-After: 60`. Crawler now honors
  Retry-After with a 30-wait/brand budget. All five pilots ingesting: 16,884 products /
  66,973 variants / 66,983 history rows (10 genuine changes already recorded).
- **2026-07-25 (Sprint 1)** — Backend foundations built and verified end-to-end:
  monorepo scaffolded (`docker-compose.yml`, `backend/` FastAPI + worker), Phase-1 schema
  migrated via Alembic (14 tables), 10 brands seeded, Shopify adapter + price-history ingest
  live. First crawls: 12,674 products / 46,746 variants / 46,746 baseline history rows
  (Bonanza Satrangi + Alkaram complete; Outfitters, J., Limelight partial — 429 penalty
  windows, nightly cron will fill). Idempotent re-crawl verified (0 spurious history rows).
  API `/health` ok; scheduled worker running (01:00 PKT). **Blocked:** Flutter SDK not
  installed on dev machine — needed for US-1/US-2 app work. **Next:** install Flutter SDK,
  scaffold app, US-1 brand grid (needs `GET /brands` endpoint), activate next-wave brands.
- **2026-07-25** — Business plan added (`brand-nest-general-plan.docx`). Phase 0 planning
  completed: wrote `ARCHITECTURE.md`, `CRAWLER_PLAYBOOK.md`, `RUNBOOK.md`; filled
  `IMPLEMENTATION_PLAN.md` with 24 user stories across 3 phases, stack decisions, open
  decisions (D-1…D-5), and top risks. Next step: resolve D-4 (first 25 brands shortlist),
  then start Phase 1 with US-8 (crawler + price history) and repo scaffolding.
