# Accessibility & Responsive Design

Covers both BrandNest surfaces: the Flutter mobile app and the Jinja2+HTMX admin panel.

## 1. Accessibility Fundamentals (Both Surfaces)

- **Contrast (WCAG 2.2 AA)**: normal text 4.5:1, large text (≥18.66px/14pt bold or ≥24px/18pt
  regular) 3:1, non-text UI components (borders, icon glyphs, focus rings) 3:1 against their
  adjacent color.
- **Target size (WCAG 2.2, SC 2.5.8, AA)**: interactive targets must be at least 24×24 CSS px,
  with narrow exceptions (inline text links, adequately spaced targets, an equivalent control
  elsewhere). Treat 24×24 as the legal floor, not the design target — use Flutter's Material
  default of **48dp** as the real minimum, since this app is Android-first and Material's own
  guidance already exceeds WCAG's floor.
- **Focus indicators (WCAG 2.2, SC 2.4.11, AA)**: focus rings need 3:1 contrast against adjacent
  colors and a minimum visible perimeter — relevant mainly to the keyboard-navigated HTMX admin
  panel; not a concern for Flutter mobile unless external-keyboard/TV support is ever added.
- **Text scaling (WCAG 1.4.4)**: text must be resizable to 200% without loss of content or
  function. In Flutter, read sizes via `MediaQuery.textScalerOf(context)` rather than hardcoding
  font sizes, and never wrap text in a fixed-height `Container`/`SizedBox` that clips at large
  scale factors — use `Flexible`/`FittedBox` or let containers grow. On the admin side, define
  type in `rem`/`clamp()`, never raw `px`, so browser zoom and OS text-size settings work.
- **Motion sensitivity**: Flutter exposes `MediaQuery.disableAnimationsOf(context)` (reflects the
  OS "remove animations" setting) — gate non-essential animation (decorative parallax,
  auto-playing carousels) behind a check on this flag. On the web side, respect
  `prefers-reduced-motion` in CSS to disable HTMX transition/swap animations.
- **Color-blindness safety**: never encode state in hue alone. Pair every color-coded state with
  a shape/icon/text difference — a checkmark glyph *and* green tint for "verified," not green
  alone; an up/down arrow glyph *and* color for a price change.

## 2. Flutter-Specific Implementation

- **Wrap custom widgets in `Semantics`**: the custom `Pill`/badge/card components from
  [03-flutter-material-implementation.md](03-flutter-material-implementation.md) need
  `Semantics(label: ..., button: true, onTap: ...)`, or `MergeSemantics` to collapse a compound
  card (image + title + price + badge) into one coherent screen-reader stop instead of four
  confusing separate ones.
- **Common mistake**: icon-only `IconButton`s or custom `InkWell` regions with no `tooltip`/
  `semanticLabel` — TalkBack announces these as just "button" with no purpose. Every icon-only
  tap target needs an explicit label (`IconButton(icon: Icon(Icons.favorite), tooltip: 'Save to
  favorites', ...)`).
- **Label writing**: concise and action-oriented ("Add to cart," "Save deal"), not a description
  of the visual ("Heart icon button").
- **Testing**: run the app with TalkBack (Android) enabled every sprint, not only at the end —
  screen-reader regressions are cheap to catch immediately and expensive to catch late. Flutter
  DevTools' accessibility guideline checker flags missing labels, insufficient contrast, and
  undersized targets automatically — run it as a routine check, not a one-off audit.

## 3. Responsive/Adaptive Strategy — Flutter App

- Use Flutter's window size classes, not device-type checks: **Compact** (<600dp width) →
  `NavigationBar` at the bottom (the default phone layout); **Medium** (600–840dp) →
  `NavigationRail` on the left, icon-only; **Expanded** (>840dp) → a permanent
  `NavigationDrawer`. Read the size via `MediaQuery.sizeOf(context).width` or `LayoutBuilder`,
  never `Theme.of(context).platform` or a device-model check.
- For the brand/product grid: adapt column count directly off available width via `LayoutBuilder`
  + a computed `crossAxisCount` (e.g. 2 columns under 600dp, 3–4 columns 600–840dp) rather than a
  fixed number per screen — this covers small phones through foldables/tablets with one rule
  instead of a hardcoded breakpoint table per screen.
- Foldables/tablets are a real target given "Android-first" — test at least one folded (compact)
  and one unfolded (medium) width; don't assume phone-only.

## 4. Responsive Strategy — Jinja2+HTMX Admin Panel

Server-rendered HTML with no JS framework — lean entirely on modern CSS:

- **Fluid typography via `clamp()`**: `font-size: clamp(min, preferred, max)` so text scales
  smoothly between breakpoints. Use relative units (`rem`) inside the calc, not raw `vw` alone,
  so 200% browser zoom still works per WCAG 1.4.4.
- **Container queries** for the data-dense review-queue UI: a deal-review card can switch its own
  internal layout (stacked vs. side-by-side) based on the width of its containing panel,
  independent of overall page width. Set `container-type: inline-size` on the review-queue's card
  wrapper and use `@container` rules for its internal grid.
- **Layout primitives**: CSS Grid for the overall admin shell (sidebar + content), Flexbox for
  toolbar/action rows. Avoid fixed pixel widths on the review-queue table — let columns size
  intrinsically (`minmax()` in `grid-template-columns`) so it degrades gracefully from laptop to
  wide monitor.
- **HTMX loading indicators**: scope `hx-indicator` to the swapped element, not a global spinner,
  so unrelated parts of the admin UI don't appear to freeze during a partial update. Keep
  `hx-indicator`'s default `visibility:hidden` behavior (preserves layout space) rather than
  switching to `display:none`, which causes layout shift. Add a short (~200ms) delay before
  showing the indicator so near-instant actions (approve/reject a deal) don't flash a spinner
  uselessly.
- **Avoid layout shift on swap**: give swap targets (the review-queue row/card being replaced) an
  explicit `min-height` matching typical content so the surrounding page doesn't jump when HTMX
  replaces inner HTML.
- **Accessibility for partial swaps**: mark the swap target with `aria-live="polite"` (or
  `role="status"` for the indicator itself) so screen readers announce the outcome of an
  approve/reject action — a silent DOM swap with no `aria-live` region is invisible to
  screen-reader users.

## 5. Pre-Ship Accessibility Checklist (Both Surfaces)

1. Every icon-only button/tap target has a semantic label or tooltip.
2. Text/UI-component contrast checked against 4.5:1 (text) / 3:1 (large text, borders, icons) —
   verified with a contrast checker, not eyeballed.
3. All tap/click targets ≥48dp (Flutter) / effectively ≥24×24 CSS px with adequate spacing
   (HTMX admin).
4. Screen tested at 200% text scale (Flutter `textScaler` / browser zoom) with no clipped or
   overlapping text.
5. No state conveyed by color alone — every color-coded status has a paired icon/shape/text cue.
6. Reduced-motion preference respected (`disableAnimations` in Flutter, `prefers-reduced-motion`
   in CSS) for any non-essential animation.
7. Screen tested once with TalkBack (Flutter) or keyboard-only navigation + focus-visible check
   (HTMX admin).
8. HTMX partial swaps have a scoped loading indicator and an `aria-live` region so the outcome is
   announced non-visually.
