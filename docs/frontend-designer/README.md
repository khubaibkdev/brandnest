# Frontend Designer Skill Set

A reference library to consult **before** any UI design or frontend/Flutter development work on
BrandNest — new screens, redesigns, or component work on either the Flutter app or the
Jinja2+HTMX admin panel. Built from current (2025/2026) professional design-system documentation,
UX research, and design-critique sources — not generic advice.

## How to use this folder

1. Before starting any design/dev task, skim
   [02-avoid-ai-generated-look.md](02-avoid-ai-generated-look.md) — it's the one file that
   applies to every task, every time, since its whole purpose is catching the default failure
   mode of AI-assisted design.
2. Read whichever of the other files apply to the task at hand (a Flutter screen needs
   [01](01-visual-design-fundamentals.md), [03](03-flutter-material-implementation.md), and
   likely [04](04-motion-and-interaction.md); an admin-panel page needs
   [01](01-visual-design-fundamentals.md) and [06](06-accessibility-and-responsive.md); anything
   product/commerce-facing needs [05](05-ecommerce-fashion-ux-patterns.md)).
3. Before shipping, run [07-design-review-checklist.md](07-design-review-checklist.md) against
   the actual screen.

## Files

| File | Covers |
|---|---|
| [01-visual-design-fundamentals.md](01-visual-design-fundamentals.md) | Typography scales, color/contrast rules, spacing/grid systems, visual hierarchy, iconography/imagery, component consistency (elevation, radius, borders). Platform-agnostic theory. |
| [02-avoid-ai-generated-look.md](02-avoid-ai-generated-look.md) | The specific, named tells of AI-generated/templated UI (purple gradients, triptych layouts, Inter-by-default, generic icon sets, uniform scroll animation, etc.) and the concrete fix for each. Read this one every time. |
| [03-flutter-material-implementation.md](03-flutter-material-implementation.md) | How to implement 01's theory in Flutter/Material 3 specifically — theme architecture, `ThemeExtension` for brand tokens, elevation/shadow craft, custom component patterns, dark mode, common "unfinished Flutter app" mistakes. |
| [04-motion-and-interaction.md](04-motion-and-interaction.md) | Motion principles, duration/easing tokens, micro-interactions, navigation transitions, Flutter animation APIs, what separates premium motion from generic template motion. |
| [05-ecommerce-fashion-ux-patterns.md](05-ecommerce-fashion-ux-patterns.md) | Domain-specific UX for BrandNest's actual screens: brand/product grid, trust and urgency signals (and where they become dark patterns), price-history UI, in-WebView bank-offer chips, gamification/loyalty, WhatsApp-optimized sharing, localization for the Pakistani market. |
| [06-accessibility-and-responsive.md](06-accessibility-and-responsive.md) | WCAG 2.2 AA specifics, Flutter accessibility implementation (`Semantics`, TalkBack testing), adaptive layout across phone/foldable/tablet, and CSS-only responsive patterns for the HTMX admin panel. |
| [07-design-review-checklist.md](07-design-review-checklist.md) | A pass/fail checklist synthesizing all of the above — run before calling any screen done. |

## Ground truth for this project

- Brand seed color: `0xFF7B1E3A` (deep maroon), set in `app/lib/core/theme.dart` — currently the
  *only* thing themed; everything in [03](03-flutter-material-implementation.md) is unaddressed
  in the codebase as of this writing.
- Stack: Flutter 3.x + Material 3 + Riverpod (mobile, Android-first), Jinja2 + HTMX (admin panel).
- Product identity: BrandNest aggregates 100+ Pakistani fashion brands — discovery, verified
  sales, bank-card discounts, price-history/fake-discount detection, gamified savings, WhatsApp
  sharing. See `docs/IMPLEMENTATION_PLAN.md` for the full product spec.

## Keeping this current

These files are a snapshot of current (2025/2026) best practice, not a permanent standard —
design conventions and what reads as "generic AI look" will keep shifting. Revisit and update a
file when its guidance stops matching what actually ships as premium, or when BrandNest's own
product decisions (e.g. an actual chosen typeface, a finalized color system) supersede a
placeholder recommendation here.
