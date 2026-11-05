# Avoiding the AI-Generated Look

**Read this file before every design/dev task, no exceptions.** It is the most important file
in this folder.

## Why this happens

An unconstrained model (or an unconstrained decision by anyone) converges on the statistical
mean of its training data — Tailwind's `indigo-500` default, the "modern SaaS landing page"
boilerplate, the same shadcn scaffold thousands of other projects ship unmodified. Distinctive
design lives in the tails of the distribution; averaging kills it. Every fix below works the same
way: **replace an unstated default with an explicit, product-specific decision.** If a color,
font, radius, spacing value, or layout wasn't chosen on purpose for BrandNest, assume it's the
mean, and it will read as generic.

## Blacklist: Tell → Fix

### Color
- **Tell**: purple-to-blue/cyan gradient behind hero sections, buttons, or CTAs, used as pure
  decoration. This traces directly to `indigo-500`-family defaults being the median color of
  most training/design corpora. **Fix**: derive every color from BrandNest's actual seed
  (`0xFF7B1E3A`, deep maroon) — never let a screen quietly drift to indigo/purple because that's
  what a framework or library defaulted to.
- **Tell**: glassmorphism cards with a faint neon glow, "AI blue" indigo everywhere, neon glows
  on dark backgrounds. **Fix**: one accent hue used sparingly, with a real tonal ramp built from
  the brand seed (see [01](01-visual-design-fundamentals.md)), not sampled blur/opacity
  combinations.
- **Tell**: dark mode built by inverting or dimming light-mode colors. **Fix**: dark surfaces get
  their own regenerated tonal system, not a flipped lightness value.

### Layout
- **Tell**: centered hero + exactly three feature cards in a row (icon + heading + two lines
  each) + a gradient blob in the background. This "triptych" is the single most recognized
  AI-generated layout signature. **Fix**: break the symmetry deliberately. If content doesn't
  naturally have three equal things, don't manufacture three equal cards to fill the pattern.
- **Tell**: identical corner-radius and identical padding applied uniformly to every card/button/
  sheet regardless of size or importance — visually monotonous. **Fix**: radius and spacing come
  from a fixed scale (see [01](01-visual-design-fundamentals.md)), but *usage* of that scale
  should reflect importance — not be copy-pasted onto everything.
- **Tell**: bento grids used decoratively with no content logic behind cell sizing. **Fix**: only
  use a bento layout when cell size genuinely maps to content importance/density (a live sale
  event card is bigger because it carries more information, not because bento is trendy).
- **Tell**: happy-path-only screens — no empty, loading, error, or offline states designed. This
  is especially costly for BrandNest given its explicit offline-first/Drift-cache and
  slow-network requirements. **Fix**: design the unhappy paths as deliberately as the happy path
  — every screen ships with empty, loading, error, and offline variants before it's "done."

### Typography
- **Tell**: Inter/system-ui used everywhere with zero intentionality — the single most cited "AI
  tell" across design critique sources. **Fix**: pick a typeface that carries a specific feeling
  for BrandNest (fashion energy, Pakistani market context), or deliberately pair Inter with a
  display face that does. The rule isn't "never use Inter" — it's "choose it on purpose."
- **Tell**: generic, weightless headline/microcopy — "Unlock the power of X," "Your all-in-one
  platform," "Scale without limits." Generic copy reads as templated before anyone even reads the
  words. **Fix**: copy should say something only this product could say — name the actual
  behavior ("Verified sale, not a fake markdown" beats "Unlock better deals").
- **Tell**: gradient text, oversized bold display headlines with no restraint, all-caps without
  real letter-spacing tuning. **Fix**: reserve gradient/heavy treatments for one clear focal
  point per screen, never the default heading style.
- **Tell**: emoji used as icons or bullets in professional UI — reads as unserious and is a
  well-known giveaway of unpolished/AI-assisted work. **Fix**: real iconography for anything
  functional. Emoji, if used at all, belongs only inside user-generated content, never as a
  system icon or bullet marker.

### Icons & Illustration
- **Tell**: thin-line generic icon sets (Heroicons/Lucide-style) dropped in undifferentiated
  everywhere, or generic 3D gradient blobs/abstract shapes as hero illustration — instantly
  recognizable as an unmodified default. **Fix**: icons reflect the product's actual domain
  (fashion, deals, price tracking) with one consistent stroke-weight/corner treatment. BrandNest
  already has a stronger asset than generic illustration — real brand/product photography —
  which should carry the visual weight instead.
- **Tell**: "✨ sparkle" iconography used by default to signal "AI/magic" — now itself a recognized
  cliché, marketing-over-UX. **Fix**: don't badge AI features with sparkles by default. Label
  what the feature actually does ("Similar for less" rather than a sparkle icon).

### Motion
- **Tell**: every element fades-and-slides-up on scroll, identically, everywhere; hover states
  that are a generic `scale(1.05)` or opacity fade with no variation; or animation entirely
  absent from an otherwise "perfect" screen. **Fix**: reserve motion for primary actions and vary
  the motion language across contexts — see [04-motion-and-interaction.md](04-motion-and-interaction.md).
  One universal easing/duration slapped onto every element is a template tell.

### Structural / Craft
- **Tell**: no opinionated point of view — safe, symmetric, "defensible in a meeting" layouts
  everywhere, because every screen independently landed on the same untouched defaults instead
  of following one deliberate system. **Fix**: make brand decisions (palette, type, spacing
  rhythm, tone of voice, icon treatment) once, explicitly, then apply *that specific system*
  consistently. Consistency should come from a chosen system, not from everyone defaulting to
  the same thing independently.
- **Tell**: inconsistent spacing that "looks close enough" instead of snapping to a real scale;
  shadows/elevation applied with no consistent light-source logic. **Fix**: audit against the
  actual scale in [01](01-visual-design-fundamentals.md) — don't eyeball values.
- **Tell**: generic stock feel with no cultural specificity. Especially risky for BrandNest,
  which targets a specific Pakistani cultural context (Eid, lawn season, shaadi season) that
  generic "global SaaS" defaults will actively erase. **Fix**: let culturally specific content
  (event calendar, Roman-Urdu search, local bank offers) shape the visual system — don't just
  drop local text into a generic template.

## Fast Self-Check Before Shipping a Screen

1. If I removed the brand color, could this screen belong to any other product? (If yes, color/
   type/icon choices aren't doing brand work.)
2. Did I choose this font, radius, spacing, and shadow value on purpose, or is it whatever the
   framework/library defaulted to?
3. Is there a purple/indigo gradient, a glassmorphic card, or a sparkle icon anywhere I didn't
   deliberately choose? Cut it.
4. Does every card/section actually need to be the same size and shape, or did I force content
   into a triptych/bento grid out of habit?
5. Have I designed the empty, loading, error, and offline states — not just the happy path with
   data?
6. Does the copy say something only this product could say, or would it survive verbatim on a
   competitor's screen?
7. Is motion applied selectively to what matters (primary actions), or copy-pasted onto
   everything identically?
8. Would a fashion-savvy Pakistani shopper recognize this as *for them*, or does it read as
   generic global-template UI with local text dropped in?
