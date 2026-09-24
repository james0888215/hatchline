# Title / start menu polish v1.3 — Proto recipe

**Cut:** title / start menu polish (playtest-1) — **v1.3 Assets pack-stack composite**.  
**Style lock:** closed — flat pastel cream-paper. No creature production redraw. In-run deferred.

James feedback trail: trio oversized/floating (fixed v1.2); muddy watercolor B rejected; Art-drawn meadow retired as default.  
**LOCKED wordmark** = three starters centered ABOVE “Hatchline” (smaller + tighter).  
**Default bg** = **Assets shortlist pack stack** → `composite/` (edermunizz sky + VISTA hills + Garzett clouds).  
Art-drawn Stardew meadow B = **fallback only**. Painted heartpunch alt = fallback/alt only, not James pick. **James locked A pack stack + raised menu 2026-09-24.**

Sheet 11 / meadow-wash-v2 still define place intent for in-run. This pack owns title chrome only.

**Proto composite recipe (z-order, motion, attribution):** `composite/PROTO_TITLE_COMPOSITE.md`

---

## 1) Z-order (locked)

**Default (pack stack):**
```
sky → clouds → far → mid → near → (optional paper) → logo (trio + wordmark) → buttons / version
```

**Fallback (Art-drawn B only):**
```
texture underlay  →  flourish hills / silhouette life  →  logo (trio + wordmark)  →  buttons / version
```

Never draw scenery / texture / flourish above the three stacked cream buttons.  
Full layer paths + motion: `composite/PROTO_TITLE_COMPOSITE.md`.

---

## 2) Assets

| Use | File |
|-----|------|
| **LOCKED wordmark** | `wordmark-hatchline-trio-{512,256}.png` |
| Lock card (Proto) | `wordmark-hatchline-trio-lock.png` |
| **DEFAULT bg stack** | `composite/layers/{sky,clouds,far,mid,near}.png` (+ opt `paper-softlight.png`) |
| Pack-stack mock | `composite/title-composite-pack-stack.png` |
| Painted alt (fallback/alt only) | `composite/title-composite-painted-alt.png` |
| Composite Proto recipe | `composite/PROTO_TITLE_COMPOSITE.md` |
| Review sheet | `../19-title-pack-composite.png` |
| Archive A (type only) | `wordmark-hatchline-only-{512,256}.png` — archive only |
| Archive B (side-icon) | `wordmark-hatchline-icon-{512,256}.png` — **retired as default** |
| Texture A (paper grain) | `bg-title-texture-A-paper-1280x800.png` — quiet alt |
| **Texture B (fallback only)** | `bg-title-texture-B-meadow-1280x800.png` — Art-drawn Stardew-leaning; **not default** |
| Texture C (alias) | `bg-title-texture-C-stardew-meadow-1280x800.png` — same as B fallback |
| Grass tile | `texture-meadow-grass-tile-256.png` |
| Paper tile | `texture-paper-grain-512.png` |
| Muddy B archive | `archive/bg-title-texture-B-meadow-muddy-archive.png` |
| Title flourish (hills) | `flourish-title-underlay-1280x800.png` — fallback stack only |
| Safe-zone guide | `flourish-title-underlay-safe-mask.png` |
| Starter-pick stage | `flourish-starter-pick-1280x800.png` |
| Prior mock | `mock-title-menu-trio-texture.png` — pre-composite reference |
| Prior review | `../18-title-trio-stardew-bg.png` (sheet 17 = trio lock) |

Wordmark fill sage `#5A8F6A` + charcoal outline `#2C2A28`.  
Pack-stack palette: warm cream-blue sky, mint/sage VISTA hills (`#A8C49A` / `#7E9B6E` grade), cream pills `#FAF6EE`.

---

## 3) Button safe zone + layout

| Zone | Fraction | Rule |
|------|----------|------|
| Logo | upper sky third | Trio+wordmark high (Stardew); calm open sky |
| Calm gap | mid band | Negative space between logo and buttons |
| Buttons | **mid-lower** (~**58%** from top), raised from prior 70% per James 2026-09-24 | Cream pills stacked here; keep calm sky gap under logo; not full mid-screen over hills |
| Button readable | mid **50%** width over near grass | Cream pills + thick charcoal; hills may sit behind |
| Wash OK (fallback B) | lower third + far L/R | Soft sage/olive; green δ ≤ **5–8%** in readable band |

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

## 5) Background — pack stack default (Assets shortlist)

Wire **`composite/layers/`** as **default** (see `composite/PROTO_TITLE_COMPOSITE.md`).

- **Pack stack (#1)** — edermunizz pastel sky (warm cream grade) + Garzett sparse clouds + VISTA downs far/mid/near (NN scale, mint/sage grade) + optional paper soft-light ~10%. Logo high (~7–12% from top) / buttons mid-lower (~58%, raised per James 2026-09-24). Parallax-ready. **James locked A.**
- **Painted alt** — heartpunch `flowermeadow_day` full-bleed (`composite/title-composite-painted-alt.png`) as fallback/alt only, not James pick (flat, no parallax).
- **Fallback only** — Art-drawn texture B/C Stardew-leaning meadow (+ flourish). Quiet alt A paper grain.
- **Archived:** `archive/bg-title-texture-B-meadow-muddy-archive.png` (v1.1 muddy B)

Attribution: **credit edermunizz** if sky ships; VISTA/paper/heartpunch = CC0; CraftPix only if flowers added later (OGA-BY).

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

- [ ] Pack stack z: sky→clouds→far→mid→near→(paper)→logo→buttons (fallback: texture→flourish→logo→buttons)
- [ ] Wire `wordmark-hatchline-trio-*` (v1.2 smaller sizing)
- [ ] Wire **composite/layers pack stack** as default (James-locked A; painted alt = fallback/alt only; Art B = fallback only; muddy archived)
- [ ] Button safe zone cream-ish (α / green δ ≤ 5–8%)
- [ ] Scenic interest at sides + lower third + horizon; calm center-upper for logo
- [ ] Sparse silhouette life decorative only
- [ ] Creatures / in-run untouched
