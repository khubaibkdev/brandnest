# Design Review Checklist

Run this before calling any screen or component "done." It synthesizes the other files into a
pass/fail pass — if any answer is "no" or "not sure," go fix it before shipping, don't note it
for later.

## 0. Read First
- [ ] Have I re-read [02-avoid-ai-generated-look.md](02-avoid-ai-generated-look.md) for this
      specific screen type (not from memory)?

## 1. Brand & Intent
- [ ] If I removed the brand color, would this screen still look like it belongs to BrandNest
      specifically — not a generic fashion/deals app?
- [ ] Does the copy on this screen say something only BrandNest could say, or would it survive
      unchanged on a competitor's screen?
- [ ] Is there a purple/indigo gradient, glassmorphic card, or sparkle icon I didn't deliberately
      choose? If yes, cut it.

## 2. Typography
- [ ] Every text style on screen maps to a `TextTheme` role — no inline one-off `TextStyle`.
- [ ] No more than 3–4 distinct hierarchy levels are visible on this screen.
- [ ] Prices/countdowns/deltas use tabular figures so digits don't jitter.
- [ ] Body text line length is constrained (not spanning full width on a tablet/large screen).

## 3. Color
- [ ] Every color used is a role from the seed-derived scheme or a defined `ThemeExtension`
      token — no raw hex literals scattered in widget code.
- [ ] Text contrast is ≥4.5:1 (normal) or ≥3:1 (large text) against its background.
- [ ] Non-text UI (borders, icon glyphs, focus rings) clears ≥3:1 against its background.
- [ ] No more than 2–3 saturated accent hues compete on this screen.
- [ ] State (verified, sale, price-drop) is never conveyed by color alone — check with a
      grayscale filter or color-blindness simulator.
- [ ] Dark mode was tested on this exact screen, not assumed to inherit correctly — especially
      if the screen shows product photography.

## 4. Spacing & Layout
- [ ] Every margin/padding/gap is a named token from the spacing scale (4/8/12/16/24/32/48/64) —
      no unexplained one-off numbers.
- [ ] Card padding, list-item gaps, and section gaps each use one consistent value across the
      whole app, not per-screen values that are "close enough."
- [ ] Corner radius is consistent per component role (all cards same radius, all buttons/chips
      same radius, all sheets same top-corner radius).
- [ ] This screen's grid/layout wasn't forced into a triptych or bento pattern the content
      doesn't actually justify.
- [ ] Empty, loading, error, and offline states are all designed — not just the happy path.

## 5. Motion (if this screen/component has any)
- [ ] Every animation answers "where did this come from / what caused this / what changed / did
      my action register" — cut anything that doesn't.
- [ ] Duration matches its role (50–200ms micro-feedback, 250–400ms component transition,
      450–600ms page/shared-element transition) — nothing user-blocking exceeds ~600ms.
- [ ] No `Curves.linear` on anything user-facing.
- [ ] This isn't a generic "fade-and-slide-up on scroll, identically, for every item" pattern.
- [ ] `reduceMotion` accessibility users get little to no motion.

## 6. Flutter/Material Implementation
- [ ] No default-Roboto, default-ripple-color, default-Scaffold-background, or default-Dialog/
      SnackBar left unstyled.
- [ ] Custom tappable regions (`InkWell`/`InkResponse`) clip their ripple to the actual shape.
- [ ] Icon sizes come from one fixed set, not ad hoc per-widget sizes.
- [ ] `NavigationBar` (Material 3), not legacy `BottomNavigationBar`, is used for bottom nav.
- [ ] `SafeArea`/display cutouts are respected — verified on a real device, not just an emulator.

## 7. Accessibility & Responsiveness
- [ ] Touch targets meet the minimum size for the platform.
- [ ] Every icon-only button and custom tappable region has a semantic/accessible label.
- [ ] Text scaling (larger system font size) doesn't clip content in a fixed-height container.
- [ ] Layout adapts sensibly across the phone screen-size range this app actually targets — not
      just the one device it was designed on.

## 8. Domain-Specific (BrandNest)
- [ ] Any countdown timer renders only from a real, server-verified expiry — never a
      client-side arbitrary timer.
- [ ] No more than one trust/verification badge stacked on a single card.
- [ ] Bank-offer chips in the WebView never auto-expand or block the brand's page content.
- [ ] A shareable card (savings/price-graph) is designed natively at WhatsApp's 1.91:1 ratio with
      essential numbers inside the center-safe crop zone.
- [ ] Large PKR figures use South Asian digit grouping where relevant.

## Final Gate
- [ ] I can name, out loud, the one specific design decision on this screen that makes it
      recognizably BrandNest and not a generic template. If I can't name one, the screen isn't
      done.
