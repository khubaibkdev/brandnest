# Fashion E-commerce & Deal-Discovery UX Patterns

Domain-specific patterns for BrandNest: a brand-aggregator/deal-discovery app, not a generic
storefront. General visual/motion rules live in the other files; this file is about the shape of
BrandNest's specific screens (brand grid, WebView toolbar, sale calendar, price history, points,
sharing).

## 1. Brand/Product Grid UX

- **Info hierarchy per card**: logo/wordmark first (largest visual weight), then at most one
  status badge as a top-corner overlay (e.g. "Sale Now"), a category tag as small subtext below
  the name. Never more than two pieces of metadata per card — grids with more than two competing
  badges per tile measurably reduce scan speed. Treat badge slots as scarce and arbitrate which
  signal wins: a live sale always outranks a generic category tag.
- **Skeleton loading**: for the offline-first Drift-cached grid, skeletons should appear only on
  a true first-load/cold-cache. Once Drift has any cached rows, render them immediately — even if
  stale — with a subtle top banner ("Updated 2h ago") rather than blocking with skeletons. Users
  tolerate staleness far better than a blank/loading state, especially on repeat visits.
- **Offline state**: distinguish "no network, showing cached data" (a non-blocking, dismissible
  strip) from "no network, no cache" (the only case that should show a full empty-state
  illustration + retry). Never silently show nothing with no explanation — that's the top
  offline complaint in low-connectivity market UX research.
- **Empty filtered states**: e.g. "Sale Now" filter with zero live sales should redirect to the
  calendar's upcoming count ("No live sales — 3 starting this week") rather than a dead end.

## 2. Trust & Urgency Signals — Real vs. Manipulative

- Pages with 1–3 trust-signal types convert meaningfully better; pages with 7+ signal types
  convert *worse* than pages with none — badge fatigue is real. Pick one primary trust marker per
  context: verified sale = one checkmark badge; genuine price drop = one "Asli Sale" badge. Never
  stack multiple trust badges on the same card.
- **Countdown timers are the highest-risk pattern.** A large share of countdown timers on
  e-commerce sites are fake (reset on refresh, tied to no real expiry) — this is a
  legally-scrutinized dark pattern (FTC enforcement precedent exists). Rule for BrandNest: a
  countdown may render **only** from a real `verified_by/at` + `expires_at` timestamp already
  enforced by the admin verify-state-machine — never a client-side arbitrary timer — and it must
  show the same value on every reload for every user, or don't ship it.
- The "Asli Sale" fake-discount badge is a trust-*building* mechanism precisely because it works
  against the merchant's own inflated-then-discounted price — lean into that framing explicitly
  in copy ("we checked 90 days of price history") with a first-run tooltip/coach-mark, not
  permanent chrome, since it needs a one-line explainer the first few times a user sees it.
- Ethics test for any badge or timer before shipping it: **would the claim survive a user pausing
  to verify it?** If not, cut it.

## 3. Price History & Comparison UI

- Convention (Honey/CamelCamelCamel/Keepa) is a simple line/area chart over a fixed lookback
  window — 90 days matches BrandNest's own AC — with the current price as a distinct marker and
  past sale-event dates annotated as small ticks/dots on the line rather than a separate legend.
- Make every point on the graph tap-to-reveal exact price + date — incumbents like
  CamelCamelCamel notably lack this, and Flutter chart libraries (`fl_chart`, Syncfusion) support
  it cheaply. This is a direct, low-cost win over the tools users already compare BrandNest to.
- Highlight the historical low as a distinct horizontal reference line or shaded band ("lowest in
  90 days") — the single highest-value annotation for a "should I buy now" decision, and the
  visual anchor competitors are missing.
- For "similar for less" comparisons, show the two products side-by-side with the *shared
  attribute* (fabric, category, occasion) as the connecting element, not just price. A bare price
  comparison with no visible reason for the match reads as untrustworthy AI-matching — surface a
  short rationale ("similar lawn print, ₨1,200 less"), not just the number.

## 4. In-Context Bank Offer Chips (WebView Toolbar)

- Treat this as a contextual-help affordance, not a promotional overlay: a persistent but
  collapsed chip (icon + count, e.g. "3 offers") rather than an auto-expanded card; expansion
  only on tap, never auto-popup over the brand's page content; appears in response to a context
  change (new brand loaded), not a time-based interruption; trivially dismissible with state
  remembered per session so it doesn't reappear every scroll.
- Position at a fixed edge (the existing toolbar/`address_bar.dart` chrome), not a floating card
  over content — a floating overlay inside a WebView reads as an ad or malware to users
  conditioned by mobile browsing, which actively hurts trust in the exact feature meant to build
  it.
- Never block interaction with the brand's page (no scrim/backdrop) — the moment it prevents
  tapping "Add to Cart" underneath, it stops feeling like assistance.

## 5. Gamification & Loyalty UI

- Non-purchase earning mechanics (streaks, daily check-in, watch-a-price) drive daily-open habits
  more than purchase-linked points alone — market data from comparable apps shows this nearly
  doubles session frequency versus non-gamified competitors. Make the streak visible on the home
  screen at all times (a small persistent counter), not buried in a points sheet — visibility of
  progress drives the habit loop, not reward size.
- Redemption clarity matters more than reward size for perceived fairness: always show the exact
  point cost and running balance at the point of redemption, and confirm with an explicit success
  state — not just a balance number quietly changing. Ambiguous point systems are the top
  complaint in loyalty-gamification research.
- Avoid manipulative framing: skip loss-framed streak language ("Don't lose your streak!") paired
  with pressure; use gain-framed, culturally warm copy instead. Time seasonal campaigns (Eid,
  lawn-season launch, shaadi season, Blessed Friday) as bonus-multiplier events, not fear-based
  countdowns — same "real, verifiable" standard as Section 2.

## 6. Sharing & Virality UI (WhatsApp-Optimized)

- WhatsApp link-preview/carousel images are effectively fixed at **1.91:1** (1200×630) —
  WhatsApp center-crops anything else. Design the shareable savings/price-graph card natively at
  that ratio; don't repurpose a square or portrait screenshot.
- WhatsApp center-crops to roughly the middle 80%, so keep essential text/numbers (the savings
  amount, the "Asli Sale" badge) within the center-safe zone, with the brand logo small and
  corner-anchored rather than centered.
- Keep file size under ~300KB before JPEG quality loss becomes visible, so previews render fast
  on cellular — directly consistent with BrandNest's own Data Saver requirement.
- At WhatsApp chat-thumbnail size, only large bold numerals (the ₨ savings figure or discount %)
  plus one short label survive legibility — treat the chart/graph as decorative background, not
  the primary information carrier, in the shareable-card version. The full interactive graph
  stays in-app.

## 7. Localization & Device Constraints

- Roman Urdu search implies typo-tolerant, phonetic-aware matching (Meilisearch handles this).
  Show "Did you mean" / auto-corrected query chips rather than silently correcting — transliteration
  ambiguity ("kameez" vs "qameez") means users need visible confirmation of what was matched.
- No live RTL requirement while UI text stays English/Roman Urdu; only reconsider if native Urdu
  script is ever rendered (e.g. brand names in Urdu) — isolate that text in its own directional
  span rather than flipping the full-screen layout.
- Design for intermittent connectivity as the default state, not an edge case — variable screen
  sizes/older OS versions, low battery. Favor dark-theme-friendly, low-repaint UI and defer
  non-critical network calls (images, VTO, stylist chat), exactly as the existing Data Saver
  requirement (US-17) already scopes.
- PKR formatting: use South Asian digit grouping (lakh style, e.g. 1,20,000) once numbers
  regularly exceed 99,999 — Pakistani users read this grouping natively; plain Western
  thousand-grouping on large PKR figures reads as slightly foreign/mistranslated.
