# Title composite — Proto recipe (pack stack default)

**Cut:** title / start menu polish — **Assets shortlist composite** (no gen, no Art muddy wash).  
**Canvas:** 1280×800  
**Quality bar:** Stardew / Terraria / Great Hatch refs — logo HIGH (~7–12% from top), cream pills raised (~58% from top), big calm sky, layered world. Pack stack A is the default. James locked this layout.

**Default background** = **pack stack** (`title-composite-pack-stack.png` + `layers/`).  
Art-drawn Stardew meadow B (`../bg-title-texture-B-meadow-1280x800.png`) is **fallback only**.  
**Alternate A** = heartpunch painted (`title-composite-painted-alt.png`) — fallback/alt only (not James pick). **James locked A pack stack.**

---

## 1) Z-order (back → front)

```
sky
  → clouds          (drift)
  → far             (parallax slow)
  → mid             (parallax mid)
  → near            (parallax near / static OK)
  → paper soft-light (optional, static ~8–12%)
  → logo (trio + wordmark)
  → buttons / version
```

Never draw scenery above the three cream pills. No new creature art.

---

## 2) Files to load

Base folder: `art/style-lock/title-menu-v1/composite/`

| Layer | File | Notes |
|-------|------|-------|
| Sky | `layers/sky.png` | edermunizz `skyDay01` NN×5, warm cream grade, 1280×800 |
| Clouds | `layers/clouds.png` | Garzett sprites, cream-tinted, sparse; **drift this** |
| Far | `layers/far.png` | VISTA `downs_1_far@3x` NN→1280, mint/sage grade, bottom-aligned |
| Mid | `layers/mid.png` | VISTA `downs_2_mid@3x` |
| Near | `layers/near.png` | VISTA `downs_3_near@3x` |
| Paper (opt) | `layers/paper-softlight.png` | CC0 PaperAlbedo @ ~10% soft-light |
| Logo | `../wordmark-hatchline-trio-{512,256}.png` | LOCKED — do not invent creatures |
| Full mock | `title-composite-pack-stack.png` | reference composite |
| Painted alt | `title-composite-painted-alt.png` | heartpunch full-bleed alt |
| Review sheet | `../../19-title-pack-composite.png` | A pack stack \| B painted alt |

Source candidates (do not redistribute raw packs beyond project):  
`assets/candidates/title-menu/` — see that folder’s `ATTRIBUTION.md`.

**Skipped:** CraftPix flowers (would clutter button zone). Revisit only if sparse side accents are wanted later.

---

## 3) Layout lock

| Element | Placement |
|---------|-----------|
| Logo | Centered, upper sky third (~7–12% from top). Calm sky behind. |
| Negative space | Open sky between logo and buttons (mid band clear). |
| Buttons | Raised (~**58%** from top). Cream pills, thick charcoal outline, dark charcoal labels: Play / Hatch-dex / Options. Calm sky stays between the logo and the pills. |
| Version | Tiny bottom-right: `v0.playtest-1` |

Button chrome (match mock): fill `#FAF6EE`, outline `#2C2A28` (~4px), label `#2C2A28`, ~300×54 pills, ~18px gap.

---

## 4) Motion

| What | Amount | Timing |
|------|--------|--------|
| Cloud drift | **8–16 px** horizontal | **12–20 s** loop (ease linear / gentle) |
| Far hills | optional ~4–8 px | slower than clouds (~25–40 s) |
| Mid hills | optional ~6–12 px | mid |
| Near | static or tiny (~2–4 px) | slowest |
| Buttons hover | scale **1.03** | soft ease ~120–180 ms |
| Logo | static | — |

Idle only. No bob on buttons. Match `motion/MOTION_BRIEF_v1.md` menu = slow sky drift + static UI.

---

## 5) Attribution **required** if this stack ships

| Asset | Licence | Credit |
|-------|---------|--------|
| **edermunizz** sky (`skyDay01`) | Commercial free; **MUST credit** | edermunizz — [Simple Pastel Backgrounds](https://edermunizz.itch.io/free-simple-pastel-backgrounds) |
| VISTA downs (najjar320) | **CC0** | Optional: najjar320 |
| Garzett pixel clouds | Commercial free | Optional / appreciated: GarzettDev |
| Kenney cloud elements (if used later) | **CC0** | Optional: Kenney.nl |
| Paper albedo (plaggy / OGA) | **CC0** | — |
| heartpunch painted alt | **CC0** | Optional: heartpunch! |
| CraftPix flowers | **OGA-BY 3.0** | **Credit CraftPix** if flowers added later |

Do not redistribute source packs as stand-alone asset products.

---

## 6) Painted alt (fallback/alt only — not James pick)

`title-composite-painted-alt.png` — heartpunch `flowermeadow_day` full-bleed + same logo/buttons/version; fallback/alt only, not James pick.  
**Pros:** Strong Great Hatch / cream-paper cousin; warm sky; scenic meadow.  
**Cons:** Flat (no parallax layers); denser flowers near button band.  
If chosen: wire as single TextureRect under chrome; skip `layers/` parallax. Still CC0.

**Recommendation:** Ship pack stack A as the default (parallax + cloud drift). Painted alt stays the flip option, not the default.

---

## 7) Checklist

- [ ] Load `layers/sky → clouds → far → mid → near` (+ optional paper)
- [ ] Wire `wordmark-hatchline-trio-*` high (~7–12% from top); cream pills raised (~58% from top)
- [ ] Cloud drift 8–16px / 12–20s; button hover 1.03
- [ ] Credit **edermunizz** (sky); list CC0 (VISTA, paper, heartpunch if used)
- [ ] Art-drawn B meadow = fallback only
- [ ] No new creature art; style lock closed; in-run deferred
