# Visual Design Fundamentals

Concrete rules for typography, color, spacing, hierarchy, iconography, and component
consistency. These are numeric/structural rules, not taste — apply them before any screen is
considered done. Flutter-specific implementation lives in
[03-flutter-material-implementation.md](03-flutter-material-implementation.md); this file is
platform-agnostic theory.

## 1. Typography

- **Build the type scale from a base × ratio.** Base = 16px body text. Ratio choice depends on
  density: 1.125–1.2 (Minor Second/Third) for dense UI (catalog grids, admin tables), 1.25–1.333
  (Major Third/Perfect Fourth) for marketing/editorial screens (onboarding, promo). Wider ratios
  read as more "designed" but need more room to breathe.
- **Cap the scale at 6–9 steps** (e.g. 12/14/16/20/24/32/40). More steps than that creates
  ambiguity about which size to use where — every text style in the app must map to exactly one
  step, never a one-off size.
- **Line-height**: body 1.4–1.6× font size; headings tighten to 1.1–1.25× as size increases
  (large type needs proportionally less leading).
- **Line length**: 45–75 characters per line, 66 ideal. Never let body text span a full tablet or
  desktop width — constrain it.
- **One font family covers 90% of products.** Add a second family only for a deliberate
  voice split (e.g. a display face for editorial sale banners vs. a grotesk for UI chrome), never
  two geometric sans faces competing with each other.
- **Weight discipline**: bold (600–700) is for true emphasis — ideally one element per screen.
  Most hierarchy should come from size + color + spacing, not bolding everything; bolding
  everything flattens hierarchy back to zero.
- **Tabular figures for numbers that change**: prices, countdowns, and price-history deltas
  should use tabular (monospaced) digit figures so they don't jitter horizontally as digits
  update.

## 2. Color

- **Derive the whole palette from one seed, never hand-pick hexes.** A seed color, converted to
  HCT (Hue/Chroma/Tone) space, generates tonal palettes (Primary, Secondary, Tertiary, Neutral,
  Neutral Variant) at fixed tone stops: 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100. Roles
  are assigned by tone, not vibes — light mode: `primary`=tone 40, `onPrimary`=tone 100,
  `primaryContainer`=tone 90, `onPrimaryContainer`=tone 10; dark mode flips: `primary`=tone 80,
  `onPrimary`=tone 20, `primaryContainer`=tone 30.
- **Never use the raw seed/brand hex as text or a fill next to other saturated color** — always
  use the tone-40 (light) / tone-80 (dark) role for text, and reserve the raw seed for singular
  brand moments (logo, splash).
- **Assign secondary/tertiary hues deliberately**, don't accept whatever an algorithm defaults
  to. A commerce/deals product needs a distinct "urgency" hue (sale/discount) that is clearly
  differentiated from the primary brand hue and used consistently for exactly that meaning
  everywhere in the app.
- **Contrast minimums (WCAG 2.1/2.2), non-negotiable**: normal text 4.5:1, large text (≥18.66px
  bold or ≥24px regular) 3:1, and **non-text UI components** (borders, icon glyphs, focus rings)
  3:1 against their adjacent color — this last one is the rule most often missed (a light-gray
  input border on white background usually fails it). Treat AAA (7:1) as aspirational for body
  copy only, not a requirement.
- **Common amateur mistakes**: more than 2–3 saturated accent hues fighting on one screen (sale
  badge + price + CTA all shouting); gray-on-gray text that clears nothing near 4.5:1 but "looks
  fine" on a calibrated monitor; building dark mode by inverting/dimming light-mode colors
  instead of regenerating tones (crushes shadows, makes colored text vibrate) — dark surfaces
  should use desaturated, tonally-elevated surfaces, not near-black.

## 3. Spacing & Layout

- **One base unit, no exceptions.** 8dp is the standard (Material's origin; Stripe, Linear,
  Airbnb, Figma all build on multiples of 8), with 4dp as a permitted half-step for
  icon-adjacent micro-spacing only.
- **Token scale**: `4, 8, 12, 16, 24, 32, 48, 64` → name them (`xs=8, s=16, m=24, l=32, xl=48`)
  and never use a raw, un-named number in layout code. If a spacing value doesn't match a token,
  that's a signal something is misaligned, not a reason to add a new token.
- **Pick one value per role and hold it everywhere**: card internal padding is always the same
  number across every card in the app; list-item gaps are always the same number; section gaps
  are always the same number. Inconsistent spacing that's "close enough" is the single most
  common tell of an unpolished screen.
- **Density changes by surface, not globally**: mobile defaults to higher density with a 44–48dp
  minimum tap target (Apple HIG 44dp / Material 48dp) and tighter spacing; a desktop/admin
  surface can use looser spacing (32–48dp section gaps) since pointer precision and
  content-to-screen ratio differ. Don't reuse phone-screen spacing tokens on the admin panel.

## 4. Visual Hierarchy

- Hierarchy comes from **combining levers, never one alone**: size, weight, color/contrast,
  position, whitespace-isolation. Making text bigger alone reads as unstyled; bigger + higher
  contrast + more surrounding space reads as designed.
- **Match the scan pattern to the screen's job.** Dense, browsing screens (catalog grids, search
  results, sale calendar) get scanned in an **F-pattern** — read the first row fully, then scan
  down the left edge for anchors — so the identifying info (brand name, price) goes left-aligned
  and first. Sparse, single-decision screens (a promo banner, onboarding, a paywall sheet) get
  scanned in a **Z-pattern** — top-left → top-right → diagonal → bottom-right primary CTA.
- **Cap hierarchy at 3–4 levels per screen** (e.g. screen title → section header → card title →
  metadata). Needing a 5th or 6th level of size/weight distinction means the content needs
  restructuring, not a smaller, grayer font.

## 5. Iconography & Imagery

- **One icon grid, one stroke weight, per screen — no exceptions.** Mixing filled and outlined
  icons, or two different icon sets, on the same screen is one of the fastest ways a UI reads as
  assembled rather than designed. Icon color always comes from the same tonal role as body text
  (e.g. `onSurfaceVariant`), never a hardcoded gray.
- **Use the platform-default icon for universal actions** (back, search, close, share) —
  reinventing these costs recognition speed for no benefit. **Commission a custom glyph only for
  domain-specific concepts with no standard icon** — for BrandNest that means "verified sale,"
  "bank-card offer," "price-drop alert": a generic bell or tag icon undersells what the product
  actually does.
- **Fix the aspect ratio per image context and never mix ratios in one grid.** Fashion product
  photography reads best at 3:4 (matches how fashion is shot); banners at 16:9 or 1:1. A catalog
  grid with mixed aspect ratios is the #1 giveaway of an unpolished commerce UI.
- **Always composite a gradient scrim behind text-on-photo**, never trust the photo's natural
  contrast — a transparent-to-~60%-black gradient behind the text zone, because brand photography
  contrast is unpredictable and will fail legibility on some fraction of images otherwise.

## 6. Component Consistency

- **Prefer tonal elevation over drop shadows.** Material 3 mixes a tint of the primary color into
  a surface as it rises (roughly 5% at elevation 1, 11% at elevation 3) rather than relying on a
  shadow. Reserve real shadows for surfaces that must visually separate from busy content below
  them (FAB, bottom sheet) — shadowing every card is the "2016 Material app" tell.
- **Fix corner radius per component role, as tokens**: `none=0, xs=4, s=8, m=12, l=16, xl=28`.
  All cards use the same radius everywhere; all buttons/chips use the same radius everywhere;
  bottom sheets use the same top-corner radius everywhere. A 6dp card next to a 16dp card in the
  same screen signals there's no real system underneath.
- **Borders are a last resort, and must clear contrast.** Prefer elevation/surface-tint
  separation. When a border is used (inputs, outlined chips), it must clear 3:1 non-text contrast
  against its background, and weight is a single fixed value (1dp default, 2dp only for
  focus/error) — never mix border weights on one screen.
