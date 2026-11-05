# Motion & Interaction Design

Motion must be semantic, not decorative. Every animation answers one of: where did this come
from, what caused this, what changed, or did my action register. If an animation doesn't answer
one of those, cut it.

## 1. Motion Principles

- **Four legitimate jobs for motion**: spatial (show relationships — shared-element/container
  transforms), reveal (expand/collapse to disclose hierarchy), transform (one element morphs
  into another — FAB → sheet), feedback (confirm an action landed — ripple, toggle).
- **Duration by role, in ms**: micro-feedback (ripple, toggle, icon state) 50–200ms; component
  transitions (card expand, sheet peek) 250–400ms; full-screen/page or shared-element
  transitions 450–600ms. Never exceed ~600ms for anything the user is blocked on waiting for.
- **Easing, never linear**: `Curves.linear` on anything user-facing is the single biggest
  "robotic" tell. Use standard (`(0.2,0,0,1)`) for routine on-screen motion, decelerate
  (`(0,0,0,1)`) for entering elements, accelerate (`(0.3,0,1,1)`) for exiting elements, and an
  emphasized variant (steeper curve, e.g. `(0.05,0.7,0.1,1)` decelerate) for hero/attention
  moments like a grid→detail container transform.
- **Spring physics for anything meant to feel alive** — a favorited icon, a drag-released bottom
  sheet, a price-graph scrubber. Critically-damped springs for everyday UI (no bounce), lower
  damping (visible overshoot) reserved for delight moments only.
- **Restraint checklist before adding an animation**: don't animate list items on every rebuild;
  don't animate things the user didn't touch; skip motion for `reduceMotion` accessibility users;
  never animate purely for "arrival on scroll" — identical fade-up-on-scroll for every item is
  the #1 template/AI-slop motion signature.

## 2. Micro-interactions

- **Button press**: state-layer/ripple is usually enough. For custom buttons: scale to 0.96–0.97
  over ~100ms accelerate on press, spring back on release. Never a full 1.0→0.9 "squish" — reads
  cheap.
- **Favorite/save/like**: the one place a bounce is earned. Icon scale 1→1.3→1 over ~300–400ms
  with a damped spring; commit the state instantly (color fill) rather than waiting for the
  animation to finish.
- **Pull-to-refresh**: resist linearly with the drag, snap at a fixed trigger threshold with
  decelerate easing, spinner/brand mark appears only past threshold.
- **Form validation**: inline, on blur (not every keystroke). Error text fades/slides in over
  ~150ms; border color transitions over the same curve. Never a jarring flash.
- **Loading states**: 0–300ms show nothing; 300ms–1s show a subtle spinner only if the layout is
  unknown; 1s+ show skeletons shaped like the real content. Skeletons are perceived as
  meaningfully faster than spinners at identical real latency because they signal "content is
  already here" rather than "wait." Reserve spinners for short atomic actions (submitting a
  report, verifying login); use skeletons for the product/brand grid.
- **Empty states get a voice**: an illustration + one line of brand-appropriate copy + a clear
  next action — never a bare "No results found." This is cheap and is one of the highest-leverage
  places to inject personality that generic/templated apps skip entirely.

## 3. Navigation Transitions

- **Shared-element continuity (grid → detail/webview)**: use `Hero` on the product image so it
  visually flies from grid card to detail header. This one transition does more for "premium
  feel" than anything else in a catalog app. If the crop/aspect ratio changes between grid and
  detail, supply a `flightShuttleBuilder` so it doesn't distort mid-flight.
- **Page transitions**: prefer Material's shared-axis family over a generic slide-up-for-
  everything (the most common generic-template signature). Horizontal shared-axis for lateral
  navigation (tab-to-tab, category drill-down), scaled shared-axis for modal-like drill-in (grid
  item → detail), fade-through for bottom-nav tab switches where content is spatially unrelated.
- **Bottom sheets** (bank offers, my-cards, settings): rise with decelerate easing over
  ~250–300ms; the dim scrim fades in concurrently, not after. Drag-to-dismiss tracks the finger
  1:1 with velocity-based fling-to-dismiss — never a binary open/close.

## 4. Flutter Implementation

- **Implicit widgets first** (`AnimatedContainer`, `AnimatedOpacity`, `AnimatedSwitcher`,
  `TweenAnimationBuilder`) — cover most needs with zero controller boilerplate for one-shot
  property changes driven by state. Move to **explicit** (`AnimationController` + `Tween` +
  `AnimatedBuilder`) only when you need looping, staggering, gesture-driven scrubbing, or the
  ability to interrupt/reverse mid-flight (e.g. a swipe-to-dismiss deal card that can be
  cancelled).
- **`Hero`** for grid↔detail continuity; use `HeroMode` to disable inherited heroes inside nested
  navigators (e.g. inside the brand WebView's own nav stack) so they don't collide.
- **Spring simulations** (`SpringSimulation`/`SpringDescription` via `AnimationController.
  animateWith`) for drag-release snapping (bottom sheet, price-graph scrubber) instead of a
  fixed-duration `Tween` with a bounce curve — a real spring responds correctly to interrupted or
  variable-velocity gestures where a fixed curve can't.
- **Performance**: wrap animating subtrees in `RepaintBoundary` so the whole grid doesn't repaint
  on every frame of one card's animation; push static content into `AnimatedBuilder`'s `child`
  parameter so it isn't rebuilt every frame; avoid animating `Opacity` on large subtrees (use
  `AnimatedOpacity`/`FadeTransition`, which are optimized, or apply `Opacity` only to leaf
  widgets). Profile the product grid specifically with DevTools' performance overlay — it's the
  highest-traffic scroll surface in the app.
- **Packages worth using**: `animations` (official Material motion transitions) and
  `flutter_animate` (declarative chaining for one-off polish). Flutter's own toolkit plus
  `animations` covers this app's needs — no need for anything heavier.

## 5. What Separates Premium Motion From Generic/AI-Generated Motion

The tell isn't the presence of animation — it's **uniformity**. Every card fading up on scroll
identically, every button using the same 300ms ease-in-out regardless of what it's doing, motion
with zero relationship to hierarchy (an error state animating as gently as a decorative badge).
Premium apps instead show:

1. **Differentiated timing by importance** — hero/brand moments (onboarding, a big sale reveal,
   favoriting) get more expressive motion; routine chrome (tab switches, list scroll) stays fast
   and restrained.
2. **Directional consistency** — things animate from where the trigger was (a sheet rises from
   the tapped element, not generically from the bottom edge).
3. **Motion tied to gesture, not just state** — drag distance/velocity feeds the animation curve
   directly rather than a canned `Tween` firing on tap.
4. **Near-zero motion where it doesn't help** — no scroll-triggered fade-in on every list item
   (a huge template signature), no decorative parallax with no informational purpose.
5. **One signature moment unique to the brand** — for BrandNest, the obvious candidates are the
   price-drop/"Asli Sale" badge reveal and the Bachat Meter savings counter animating up — rather
   than spreading generic effort evenly across every interaction.

The gap between "an app that animates" and "an app that feels crafted" is almost entirely about
**where restraint is applied**, not how much motion exists.
