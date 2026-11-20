# Design System Document: The Luminescent Herbarium

## 1. Overview & Creative North Star

**Creative North Star: The Luminescent Herbarium**
This design system moves away from the utility-first aesthetic of standard apps and moves toward a high-end, editorial "Digital Field Guide." The experience should feel like peering through a high-tech lens into a dark, lush forest. We achieve this through "The Luminescent Herbarium" concept: deep, ink-like tonal bases contrasted against hyper-vibrant, "living" neon accents.

Instead of rigid grids and boxed-in layouts, we utilize **intentional asymmetry** and **tonal layering**. Elements should feel organic yet precise—as if the AI is illuminating hidden details within a dark environment. We prioritize breathing room and "depth through light" over structural lines.

---

## 2. Colors & Atmospheric Depth

The color palette is designed to create a sense of infinite depth. The base is not a flat black, but a "living dark" (`#0d0f0d`) that allows the brilliant green accent to vibrate with energy.

### The "No-Line" Rule
**Lines are prohibited for sectioning.** To separate content, use background color shifts. For example, a card (`surface-container-low`) sits on a global background (`surface`), creating a boundary through value change rather than a 1px stroke. This creates a more sophisticated, seamless interface.

### Surface Hierarchy & Nesting
Depth is achieved by "stacking" the surface-container tiers. Use this hierarchy to guide the eye:
*   **Deepest (Background):** `surface` (#0d0f0d) – The base canvas.
*   **Secondary (Sections):** `surface-container-low` (#121412) – For grouping related content.
*   **Interactive (Cards):** `surface-container-highest` (#242624) – For elements the user must engage with.

### The "Glass & Gradient" Rule
To elevate the "AI Scanner" feel, floating overlays (like scan results) must use **Glassmorphism**. 
*   **Token:** `surface_variant` at 40% opacity.
*   **Effect:** 20px–40px backdrop-blur.
*   **Signature Gradient:** For primary CTAs and scan indicators, use a linear gradient from `primary` (#5dff3c) to `primary_container` (#3af114) at a 135° angle to provide a "pulsing" life-force effect.

---

## 3. Typography: Editorial Precision

The typography system balances the tech-forward nature of AI with the classic beauty of botanical studies.

*   **Display & Headlines (Manrope):** Chosen for its geometric, modern personality. `headline-lg` (2.0rem/32px) should be used with tight tracking (-2%) to feel authoritative and "branded."
*   **Body & Labels (Inter/System):** Chosen for maximum legibility in dark mode. `body-md` (0.875rem/14pt) is the workhorse.
*   **The Hierarchy Identity:** Create a "Magazine" feel by using extreme scale. A large `display-sm` flower name should sit adjacent to a very small, muted `label-sm` botanical classification. This high contrast mimics premium editorial layouts.

---

## 4. Elevation & Depth: Tonal Layering

Traditional drop shadows are too "software-standard" for this system. We use light and opacity to define space.

*   **The Layering Principle:** Place a `surface-container-lowest` card on a `surface-container-low` section to create a soft, "recessed" look. Use `surface-bright` for elements that need to "pop" forward.
*   **Ambient Shadows:** If a floating element (like a FAB) requires a shadow, use a "Tinted Glow." Instead of black, use `primary` at 10% opacity with a 32px blur and 8px Y-offset. This makes the object appear as if it is emitting light onto the surface below.
*   **The "Ghost Border" Fallback:** If a container lacks enough contrast against its background, use a **Ghost Border**: `outline-variant` at 15% opacity. It should be barely perceptible, serving as a suggestion of a boundary rather than a hard wall.

---

## 5. Key Components

### Buttons (The "Lichen" Pill)
*   **Primary:** Pill-shaped (radius: `full`), Background: `primary` (#5dff3c), Text: `on_primary` (#0d5d00). No border.
*   **Secondary/Ghost:** Pill-shaped, `outline-variant` at 20% opacity. Text: `on_surface`.
*   **States:** On hover/active, the `primary` button should gain a subtle outer glow using the Ambient Shadow rule.

### Cards (Botanical Plates)
*   **Structure:** 12px (`md`) border radius. No visible 1px border.
*   **Separation:** Use `surface-container-high`. 
*   **Content:** Card titles use `title-sm` (16pt medium). Avoid dividers between card header and body; use a `spacing-4` (1rem) gap instead.

### The Scanner Overlay (The Precision Lens)
*   **Scanning Line:** A 2px horizontal rule using the `primary` token with a "bloom" effect (a 10px glow).
*   **Corner Brackets:** Instead of a full box, use L-shaped corner brackets in `primary` to frame the flower, emphasizing the "AI lens" perspective.

### Navigation (The Living Dock)
*   **Inactive:** `outline` icons, `on_surface_variant` color.
*   **Active:** Filled icons in `primary` (#5dff3c). The active state should include a subtle `primary` glow behind the icon (15% opacity) to simulate the button "lighting up."

---

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical margins (e.g., 24px left, 32px right) for headline placements to create an editorial feel.
*   **Do** use `surface-container` shifts to group content instead of lines.
*   **Do** ensure all text on `primary` backgrounds uses the `on_primary` dark green for accessibility.
*   **Do** allow flower imagery to bleed off the edge of cards to emphasize the "organic" nature of the subject.

### Don’t
*   **Don't** use 100% white text. Always use `on_surface` (#faf9f5) or `on_surface_variant` (#ababa8) to prevent eye strain in dark mode.
*   **Don't** use standard 1px borders or dividers. They "trap" the organic content.
*   **Don't** use sharp 90-degree corners. Everything must feel softened, using at least the `sm` (4px) radius for small elements and `md` (12px) for cards.
*   **Don't** over-saturate the UI. The brilliance of the `#3ff51b` green is only effective when surrounded by the muted, deep tones of the base palette.