# Flutter / Material 3 Implementation Craft

How to make BrandNest's Flutter UI look premium and custom rather than an unstyled Material
demo. This is implementation craft only — design theory lives in
[01-visual-design-fundamentals.md](01-visual-design-fundamentals.md); anti-patterns to avoid
live in [02-avoid-ai-generated-look.md](02-avoid-ai-generated-look.md).

Current state: `app/lib/core/theme.dart` is only `ColorScheme.fromSeed(seedColor: _brandSeed)` —
every section below is currently unaddressed in the codebase.

## 1. Theming Architecture

Never leave `ThemeData` at a bare `ColorScheme.fromSeed()`. Build one `AppTheme` module:

- **ColorScheme**: `ColorScheme.fromSeed(seedColor: brandSeed, brightness: ...)` generates tonal
  roles (`primary`, `onPrimary`, `primaryContainer`, `secondary`, `tertiary`, `surface`,
  `surfaceContainerLow/High`, `outline`, `outlineVariant`). Don't just consume the defaults —
  override specific roles (`colorScheme.copyWith(tertiary: ..., error: ...)`) so brand-critical
  colors (a "sale/discount" hue distinct from Material's own `error` red) are deliberate, not
  accidental.
- **Custom semantic colors via `ThemeExtension<T>`**: `ColorScheme` has no slot for "success,"
  "discount," "verified badge." Define `class AppColors extends ThemeExtension<AppColors> {
  final Color discount; final Color verifiedBadge; ... }`, register it via
  `ThemeData(extensions: [AppColors(...)])`, and read via
  `Theme.of(context).extension<AppColors>()!`. This keeps brand-specific tokens type-safe instead
  of scattering `Color(0xFF...)` literals through widgets.
- **TextTheme**: build the full scale (`displayLarge` → `labelSmall`) once. Every widget
  references `Theme.of(context).textTheme.titleMedium`, never an inline
  `TextStyle(fontSize: 15, fontWeight: ...)` — inline styles are exactly what makes an app drift
  into "different screen, different feel."
- **Shape tokens**: a small set of `BorderRadius` constants (`AppRadius.sm=8, md=12, lg=16,
  pill=999`), applied via each component theme's `shape:` — not ad hoc per-widget radii.
- **Component themes**: explicitly set `CardThemeData`, `ChipThemeData`,
  `ElevatedButtonThemeData`/`FilledButtonThemeData`, `AppBarTheme`, `NavigationBarThemeData`
  (Material 3's successor to `BottomNavigationBarTheme`), `BottomSheetThemeData`, `DialogTheme`,
  `SnackBarThemeData`, `InputDecorationTheme`. Every one of these has a Flutter default that
  reads as "unstyled Material demo" if left untouched — theming them once, globally, is what
  makes the whole app look designed rather than assembled screen-by-screen.
- Keep it all in `lib/core/theme/` (`theme.dart`, `text_theme.dart`, `color_extension.dart`,
  `component_themes.dart`) — one place to evolve, never duplicated per feature.

## 2. Typography

- Use `google_fonts` (`GoogleFonts.<family>TextTheme(base)`) or bundle a licensed font via
  `pubspec.yaml`'s `fonts:` section. Do not ship default Roboto for a lifestyle/fashion brand —
  it reads as an unbranded Android app.
- Common mistake: registering every weight as a separate font family (`Poppins-Bold`,
  `Poppins-Medium`). Register one family with multiple `FontWeight` variants instead, so
  `TextStyle(fontWeight: FontWeight.w600)` resolves correctly within a single `fontFamily`.
- Font pairing for a fashion app: a distinctive, slightly editorial display/serif or geometric
  sans for headings (product names, section titles) paired with a highly legible, neutral
  workhorse for body/UI text. Two families max — more reads as noisy.
- Build the scale with `GoogleFonts.<family>TextTheme(Theme.of(context).textTheme)` merged into
  the base `TextTheme`, then apply brand color/weight overrides per role.
- Use tabular figures (`FontFeature.tabularFigures()`) for prices, countdowns, and price-history
  deltas so digits don't jitter horizontally as they update.

## 3. Elevation, Shadow, Surface

- Material 3 shows elevation two ways: **surface tint** (`Material.surfaceTintColor` washes a
  primary-color tint over the surface as elevation increases) and **shadow**
  (`Material.shadowColor`, still black by default). With `useMaterial3: true` both are active by
  default — a subtle tinted lift, not the old sharp Material 2 dropshadow.
- **The muddy-look problem**: `ColorScheme.fromSeed` plus default surface-tint intensity on
  nested elevated surfaces (cards over cards) gives everything a faint maroon/purple haze,
  especially in dark mode. Fix: set `surfaceTintColor: Colors.transparent` on `CardThemeData`/
  `Material` for content-dense surfaces (product cards over photography) and use explicit
  `BoxShadow` instead — real shadow is more predictable over photographic imagery than a
  color-tint overlay.
- Recommended premium product-card shadow: two soft, low-opacity layered shadows —
  `BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: Offset(0,4))` plus
  `BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2, offset: Offset(0,1))`. A
  single harsh `blurRadius: 4, opacity: 0.3` shadow reads as default/generic.
- Don't stack more than 2–3 visually distinguishable elevation levels on one screen — more
  becomes noise.

## 4. Custom Component Patterns

- **Product/deal cards**: never a bare `Card()`. Compose `ClipRRect` (for the image) + a custom
  `Container` decoration + `Stack` for badge overlays (e.g. an "Asli Sale" pill positioned via
  `Positioned` in a corner) + `InkWell` wrapping the whole tappable region with a custom
  `splashColor`/`highlightColor` matched to the brand tint — the default Material ripple is a
  generic gray/primary wash that clashes with photography (`splashColor:
  brandColor.withOpacity(0.08)`).
- **Badges/pills** (sale %, verified, bank-offer chips): build a small reusable `Pill` widget
  (rounded-full `Container` + `Text`) rather than repurposing `Chip` — default `ChipThemeData`
  carries padding/height assumptions that rarely match a compact badge's needs.
- **Bottom sheets** (price graph, my-cards, settings — already used via `price_graph_sheet.dart`,
  `my_cards_sheet.dart`): always set a custom `shape: RoundedRectangleBorder(borderRadius:
  BorderRadius.vertical(top: Radius.circular(20)))` via `BottomSheetThemeData`, add a drag-handle
  affordance widget at the top (a small centered `Container` bar), and set `backgroundColor`
  explicitly — default sheets inherit `canvasColor`, which can look washed out.
- **Ripple/InkWell discipline**: always wrap custom tappable containers in `InkWell`/
  `InkResponse` with a matching `borderRadius` so the ripple is clipped to the shape — an
  unclipped ripple bleeding into square corners on a rounded card is one of the most common
  "unpolished Flutter app" tells.

## 5. Dark Mode

- Generate the dark scheme with `ColorScheme.fromSeed(seedColor: brandSeed, brightness:
  Brightness.dark)` — don't hand-roll it — then audit it: a deep maroon seed (`0xFF7B1E3A`) can
  generate a dark `primary` that's too desaturated/muddy against a near-black surface. Manually
  bump `primary`/`primaryContainer` saturation-lightness in the dark scheme if the auto-generated
  tone reads gray-brown instead of "brand."
- Test photography-heavy screens (product grids) specifically in dark mode — photos on pure black
  (`0xFF000000`) create harsh contrast. Material 3's recommended dark surface is a very dark
  near-black with slight tint (which `fromSeed` already produces) — don't override to true black
  unless doing OLED-specific optimization.
- Elevated surfaces in dark mode should get *lighter*, not shadowed (shadow is invisible on dark
  backgrounds) — this is what Material 3's surface-tint elevation model automates. Don't fight it
  by forcing `shadowColor` only in dark mode.

## 6. Common "Looks Unfinished" Mistakes

- Default ripple color mismatching brand (gray Material ripple on a maroon button).
- Inconsistent icon sizing — mixing default `Icon(size: 24)` with ad hoc 20/28 sizes; fix with an
  `AppIconSize` constant set.
- Unstyled `Scaffold(backgroundColor: default)` — always set explicitly via the theme's
  `scaffoldBackgroundColor`, distinct from `surface`, so screens don't look like raw white/gray
  canvases.
- Default `SnackBar`/`Dialog`/`AlertDialog` — square corners, default elevation, default text
  style. Theme `SnackBarThemeData` (rounded shape, `behavior: SnackBarBehavior.floating`) and
  `DialogTheme` globally.
- Using legacy `BottomNavigationBar` instead of Material 3's `NavigationBar` — the legacy widget
  has an older visual language (no pill-shaped active indicator); `NavigationBar` gives the
  modern floating-indicator look for free.
- Ignoring `SafeArea`/display cutouts — content butting against the status bar or gesture-nav
  area is an instant "amateur" signal on a real device, distinct from an emulator screenshot.
- Default `CircularProgressIndicator()` spinners everywhere instead of branded skeleton/shimmer
  loaders for content that loads in (product grids, price graphs) — skeleton loaders matching the
  final layout's shape read as significantly more polished for a catalog/discovery app.
