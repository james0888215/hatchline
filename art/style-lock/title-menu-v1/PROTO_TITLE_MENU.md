# Title / start menu polish v1.1 — Proto recipe

**Cut:** title / start menu polish (playtest-1) — **v1.1 trio lock**.  
**Style lock:** closed — flat pastel cream-paper. No creature production redraw. In-run deferred.

James **rejected** side-icon wordmark B. Locked direction = **three starters centered ABOVE** the Hatchline wordmark + thematic cream texture underlay.

Sheet 11 / meadow-wash-v2 still define place intent for in-run. This pack owns title chrome only.

---

## 1) Z-order (locked)

```
texture underlay  →  flourish hills / silhouette life  →  logo (trio + wordmark)  →  buttons / version
```

Never draw texture or flourish above the three stacked cream buttons.

---

## 2) Assets

| Use | File |
|-----|------|
| **LOCKED wordmark** | `wordmark-hatchline-trio-{512,256}.png` |
| Lock card (Proto) | `wordmark-hatchline-trio-lock.png` |
| Archive A (type only) | `wordmark-hatchline-only-{512,256}.png` — archive only |
| Archive B (side-icon) | `wordmark-hatchline-icon-{512,256}.png` — **retired as default** |
| Texture A (paper grain) | `bg-title-texture-A-paper-1280x800.png` |
| **Texture B (recommend)** | `bg-title-texture-B-meadow-1280x800.png` |
| Tile swatches | `texture-paper-grain-512.png`, `texture-meadow-fiber-512.png` |
| Title flourish (hills) | `flourish-title-underlay-1280x800.png` |
| Safe-zone guide | `flourish-title-underlay-safe-mask.png` |
| Starter-pick stage | `flourish-starter-pick-1280x800.png` |
| Full mock | `mock-title-menu-trio-texture.png` |
| Review sheet | `../17-title-trio-texture.png` (sheet 16 archive) |

Composite on cream paper `#F6F1E7` / `#F7F2E8`. Wordmark fill sage `#5A8F6A` + charcoal outline `#2C2A28`.

---

## 3) Button safe zone (unchanged)

| Zone | Fraction | Rule |
|------|----------|------|
| Button safe | middle **50%** width × middle **40%** height | Wash / texture green δ ≤ **5–8%** or clear |
| Wash OK | lower third + far left/right edges | Soft sage hills; peak α ≤ **22%** |
| Ground | bottom ~12% | Soft ground stripe OK |

Play / Hatch-dex / Options must stay fully readable.

---

## 4) Wordmark — LOCKED

**Wire `wordmark-hatchline-trio-*` as default.** Lock card: `wordmark-hatchline-trio-lock.png` labeled **LOCKED — trio above wordmark**.

- Three starters in a gentle arc/row **centered ABOVE** “Hatchline”
- Order L→R: Sproutling (mint + leaf) · Sparkpup (peach + soft flame) · Cottonwisp (powder blue cloud bumps)
- Flat capsule lock, two-dot faces, thick charcoal `#2C2A28`
- Even spacing; equal visual weight; small gap above type
- Soft cosy rounded sans — **not** fancy serif, **not** 3D

Side-icon B is **retired as default** (keep files as archive). Type-only A stays archive.

---

## 5) Background texture

Wire **texture B** (`bg-title-texture-B-meadow-1280x800.png`) first.

- **A** — soft paper grain + faint fiber (cream + subtle sage flecks); quieter
- **B** — meadow watercolor wash streaks (pale sage/peach) + paper grain — cooler cosy Hatchline feel

James can swap A/B. Flourish hills sit **on top of** texture, still **under** chrome.

---

## 6) Modulate habits

- TextureRect for texture + flourish; modulate flourish ≈ **0.20–0.28** if stacking
- Do not stack a second opaque ColorRect that kills cream
- Ownership: Art = shape/opacity; Proto = z-order

---

## 7) Out of this cut

- Creatures / production redraw
- In-run UI (PathBar / Bench / Board / Fight) — still meadow-wash-v2
- Fancy logo serifs, gradients, noisy/photoreal/dark textures

---

## 8) Quick checklist

- [ ] Texture underlay z lowest; flourish above texture; logo above flourish; buttons top
- [ ] Wire `wordmark-hatchline-trio-*` (not side-icon B)
- [ ] Wire texture B first (James may swap A)
- [ ] Button safe zone clear (α / green δ ≤ 5–8%)
- [ ] Peak hill wash α ≤ 22%
- [ ] Sparse silhouette life decorative only
- [ ] Creatures / in-run untouched
