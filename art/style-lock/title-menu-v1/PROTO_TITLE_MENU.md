# Title / start menu polish v1.2 — Proto recipe

**Cut:** title / start menu polish (playtest-1) — **v1.2 trio refine + Stardew meadow**.  
**Style lock:** closed — flat pastel cream-paper. No creature production redraw. In-run deferred.

James feedback on v1.1: trio oversized/floating; muddy watercolor B rejected.  
**LOCKED wordmark** = three starters centered ABOVE “Hatchline” (now smaller + tighter).  
**Default bg** = Stardew-leaning painted meadow (warm cream/peach sky, sage/olive hill bands, patterned grass). Muddy B archived.

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
| Texture A (paper grain) | `bg-title-texture-A-paper-1280x800.png` — quiet alt |
| **Texture B (recommend / default)** | `bg-title-texture-B-meadow-1280x800.png` — **Stardew-leaning** |
| Texture C (alias) | `bg-title-texture-C-stardew-meadow-1280x800.png` — same intent |
| Grass tile | `texture-meadow-grass-tile-256.png` |
| Paper tile | `texture-paper-grain-512.png` |
| Muddy B archive | `archive/bg-title-texture-B-meadow-muddy-archive.png` |
| Title flourish (hills) | `flourish-title-underlay-1280x800.png` |
| Safe-zone guide | `flourish-title-underlay-safe-mask.png` |
| Starter-pick stage | `flourish-starter-pick-1280x800.png` |
| Full mock | `mock-title-menu-trio-texture.png` |
| Review sheet | `../18-title-trio-stardew-bg.png` (sheet 17 = prior trio lock) |

Composite on cream paper `#F7F0E4` / `#F7F2E8`. Wordmark fill sage `#5A8F6A` + charcoal outline `#2C2A28`.  
Meadow palette: cream `#F7F0E4`, sky peach `#F3E6D4`, sage `#A8C49A`, olive `#7E9B6E`.

---

## 3) Button safe zone (unchanged)

| Zone | Fraction | Rule |
|------|----------|------|
| Button safe | middle **50%** width × middle **40%** height | Wash / texture green δ ≤ **5–8%** or clear; **cream-ish** |
| Wash OK | lower third + far left/right edges | Soft sage/olive hills; scenic interest |
| Ground | bottom ~12% | Soft ground stripe OK |
| Logo zone | center-upper | Calm open cream/peach sky |

Play / Hatch-dex / Options must stay fully readable on cream pills.

---

## 4) Wordmark — LOCKED (v1.2 sizing)

**Wire `wordmark-hatchline-trio-*` as default.** Lock card: `wordmark-hatchline-trio-lock.png`.

- Three starters in a centered row **ABOVE** “Hatchline” (flat baseline, no floating arc)
- Order L→R: Sproutling (mint + leaf) · Sparkpup (peach + soft flame) · Cottonwisp (powder blue cloud bumps)
- Flat capsule lock, two-dot faces, thick charcoal `#2C2A28`
- **Sizing (v1.2):** starters ≈ **35–45%** of v1.1 visual weight (clearly smaller)
- Gap from capsule bottoms to type top ≈ **8–12%** of wordmark height (tight)
- Equal spacing; total trio width ≈ **70–85%** of wordmark / type width (not wider than type)
- Soft cosy rounded sans — **not** fancy serif, **not** 3D

Side-icon B is **retired as default** (keep files as archive). Type-only A stays archive.

---

## 5) Background texture — Stardew-leaning meadow

Wire **texture B** (`bg-title-texture-B-meadow-1280x800.png`) as **default**.

- **B / C** — warm cream/peach sky, gentle distant sage/olive hill bands, soft grass midground with subtle repeating blade/dot pattern, sparse tiny flower dots. Flat/painterly cream-paper Hatchline cousin of Stardew — **not** muddy watercolor speckles, **not** noisy grain soup, **not** dark, **not** photoreal. Center vertical band stays cream-ish for buttons.
- **A** — soft paper grain (quiet alternate)
- **Archived:** `archive/bg-title-texture-B-meadow-muddy-archive.png` (v1.1 muddy B)

Flourish hills / silhouette life sit **on top of** texture, still **under** chrome. Scenery interest is mostly in B now; flourish stays light.

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
- Copying Stardew assets

---

## 8) Quick checklist

- [ ] Texture underlay z lowest; flourish above texture; logo above flourish; buttons top
- [ ] Wire `wordmark-hatchline-trio-*` (v1.2 smaller sizing)
- [ ] Wire texture **B Stardew-leaning meadow** as default (A quiet alt; muddy archived)
- [ ] Button safe zone cream-ish (α / green δ ≤ 5–8%)
- [ ] Scenic interest at sides + lower third + horizon; calm center-upper for logo
- [ ] Sparse silhouette life decorative only
- [ ] Creatures / in-run untouched
