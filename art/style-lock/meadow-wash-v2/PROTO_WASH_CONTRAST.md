# Meadow wash v2 — Proto recipe (contrast + underlay)

**Art owns:** wash shape / opacity + contrast tokens  
**Proto owns:** z-order (wash behind ALL chrome)  
**Do not:** redraw creatures · reopen flat-capsule lock

Sheet 11 (`11-meadow-presentation-spine.png`) still defines **place intent** (soft meadow wash + ground plane behind boards).  
v2 softens **opacity** and clears **chrome gutters** so live PathBar / Bench / Board stay readable.

---

## 1) Z-order

Place wash as a `TextureRect` (or `ColorRect` + modulate) **behind ALL chrome**:

- PathBar (top)
- Bench (left)
- Board / place grid
- Shop / Coming-up / Sunny Cart
- Menu buttons / Sell bar / Onward / Fight
- HUD gold / INT pills

Creatures and cell chrome stay above the wash. Never draw wash into a layer above PathBar labels or Bench slots.

---

## 2) Which texture

| Screen | Asset |
|--------|-------|
| Battle / prep / spar / cart | `wash-underlay-battle-1280x800.png` |
| Main menu | `wash-underlay-menu-1280x800.png` (softer, bottom-weighted) |
| Tiled / procedural underlay | `wash-blob-soft-256.png` or `wash-blob-soft-128.png` |

All are RGBA pale sage. Soft ellipse blobs — not solid slabs.

**Modulate alpha:** `~0.20–0.28` on the TextureRect (asset peak already ≈18–25%; do not stack a second opaque ColorRect on top).

Guide: `chrome-safe-mask-guide.png`

---

## 3) Gutters (do not stretch wash into these)

| Zone | Fraction | Rule |
|------|----------|------|
| Top path bar | ~18% of frame height | Wash α ≤ 8% or fully clear |
| Left Bench | ~14% of frame width | Fully clear |
| Bottom | ~12% | Ground stripe OK but keep soft |
| Center board | mid-field | Wash may sit **under** cream cells — keep pale so slots still read |

Never stretch / scale the underlay so mass climbs into the PathBar or bleeds under Bench.

---

## 4) Path labels — contrast

Path type must read on cream, not on sage wash.

**Preferred:** cream rounded pill behind label text  
- Active ink: `#2C2A28` (e.g. “Grass”)  
- Inactive ink: `#5C5854` (e.g. “Stall”)  
Token: `token-path-label-pill.png`

**Alt:** darker ink `#2C2A28` on an already-cream PathBar strip (no pill needed if bar fill is solid cream).

---

## 5) Path nodes — solid marks, no glow

| State | Token | Rule |
|-------|-------|------|
| Active | `token-active-node-solid.png` | Filled disc `#6B9B6E` (sage) **or** `#E8956A` (coral) + **thick charcoal ring** `#2C2A28` |
| Inactive | `token-inactive-node-ring.png` | Empty charcoal ring only |

**Kill:** soft glow, yellow bloom, clash halos behind the active node.

---

## 6) Creatures

Unchanged. Flat-capsule lock stands. Do not retouch Sproutling / Sparkpup / Cottonwisp / mites for this pass.

---

## 7) Quick checklist

- [ ] Wash TextureRect z < PathBar, Bench, Board, Shop, Menu
- [ ] Underlay or soft blobs; modulate ≈ 0.2–0.28
- [ ] Top ~18% and left ~14% gutters clear
- [ ] Path labels on cream pills (or cream bar + `#2C2A28`)
- [ ] Active node = solid disc + ring; no glow
- [ ] Creatures untouched
