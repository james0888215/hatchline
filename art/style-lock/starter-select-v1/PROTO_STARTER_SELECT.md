# Starter select — Proto recipe (lock)

**Cut:** selection menu / starter pick screen (playtest-1).  
**Canvas:** 1280×800  
**Quality bar:** same professional bar as title (Stardew / Terraria / Great Hatch readability).  
**James locking selection menu 2026-09-24.** Title pack-stack A stays locked — do not reopen title layout.

Style lock closed — flat pastel capsules, two-dot faces, thick charcoal `#2C2A28`, one family mark.  
Drawn from `title-menu-v1/_gen_title_menu_v1_2.py` helpers (`draw_sproutling` / `draw_sparkpup` / `draw_cottonwisp` / `make_starter_token`). No new creatures. No Hatch-dex list. No shop/prep/fight art.

---

## 1) Z-order (back → front)

```
sky
  → clouds              (drift — same as title)
  → far                 (parallax slow)
  → mid
  → near
  → paper soft-light    (optional ~10%, static)
  → header (“Pick your starter”)
  → pick cards ×3       (selected on top of idle if overlap)
  → buttons (Back / Confirm)
  → version
```

Never draw scenery above cream cards or pills. No charcoal/grey band wash and no ColorRect grade under cards; cream cards alone win contrast. Skip CraftPix flowers under the card row.

---

## 2) Files to load

Base folder: `art/style-lock/starter-select-v1/`

| Layer / asset | File | Notes |
|---------------|------|-------|
| Sky | `../title-menu-v1/composite/layers/sky.png` | **Reuse title** — edermunizz warm cream grade |
| Clouds | `../title-menu-v1/composite/layers/clouds.png` | **Reuse** — drift this |
| Far / Mid / Near | `../title-menu-v1/composite/layers/{far,mid,near}.png` | **Reuse** VISTA mint/sage |
| Paper (opt) | `../title-menu-v1/composite/layers/paper-softlight.png` | **Reuse** |
| Full mock | `mock-starter-select.png` | lock reference |
| Isolated cards | `card-sproutling.png`, `card-sparkpup.png`, `card-cottonwisp.png` | Proto / UI |
| Compose script | `_compose_select.py` | reusable Art rebuild |
| Review sheet | `../20-starter-select-lock.png` | A full mock | B cards close-up |

**Starter-select contrast rule:** No charcoal/grey band wash and no ColorRect grade under cards. Cream cards alone win contrast on the reused cream-graded title layers. Do not add a select-specific scenic grade.

---

## 3) Layout lock

| Element | Placement |
|---------|-----------|
| Header | Centered, **~10%** from top (band **8–12%**). Soft rounded bold; sage fill `#5A8F6A` + charcoal outline `#2C2A28` (title wordmark language). Text: **Pick your starter** |
| Cards | Three cream pick cards, centered horizontal row; vertical mid band **~32–55%** (centers ≈ **43.5%**). Equal spacing (~36 px gap). |
| Card chrome | Rounded rect, thick charcoal outline (~4 px idle / ~7 px selected), fill `#FAF6EE`, generous padding. Portrait body height **~140 px** (~120–160). Name under portrait; optional family cue (Leaf / Ember / Puff) muted charcoal, small. |
| Selected | **Middle** card (Sparkpup) in mock — thicker outline + soft cream glow ring + slight scale **~1.045**. Label “selected” in recipe only (no noisy on-card badge). |
| Buttons | Cream pills **Back** (left/secondary) + **Confirm** (right/primary), **~260×48** (240–280×48 OK), mid-lower **~74%** from top (band **70–78%**). Same pill language as title. |
| Version | Tiny BR: `v0.playtest-1` |

Order L→R: **Sproutling** (mint + tall leaf) · **Sparkpup** (peach/coral + soft top flame) · **Cottonwisp** (powder blue cloud bumps / cloud-body).

If hills fight readability, lift cards into calm sky / upper mid — cream cards must win contrast. Cream cards win on cream-graded title layers alone.

---

## 4) Motion

| What | Amount | Timing |
|------|--------|--------|
| Cloud drift | **8–16 px** horizontal | **12–20 s** loop (same as title if scenic shared) |
| Far hills | optional parallax | **≤ 4 px** over **20 s** |
| **Selected starter idle** | subtle breathe **≤ ±4%** squash/stretch | from `starters-v1.2-face`; shared clock; pivot bottom-center (`motion/MOTION_BRIEF_v1.md`) |
| Unselected starters | static OK, or same idle quieter | keep one clock if both idle |
| Hover card | scale **1.00 → 1.03** | soft ease ~100–120 ms |
| Confirm hover | scale **1.03** | soft ease ~100–120 ms (title button language) |
| Back hover | scale **1.03** | same |
| Header / version | static | — |

Mock is **static**. Menu drift = same slow clouds as title. No bob on buttons. No idle bounce on chrome.

---

## 5) Attribution **required** if scenic stack ships

| Asset | Licence | Credit |
|-------|---------|--------|
| **edermunizz** sky | Commercial free; **MUST credit** | edermunizz — Simple Pastel Backgrounds |
| VISTA downs (najjar320) | **CC0** | Optional: najjar320 |
| Garzett pixel clouds | Commercial free | Optional / appreciated: GarzettDev |
| Paper albedo | **CC0** | — |

Same stack as title — credit **edermunizz** if sky reused. CraftPix flowers **not** used under card band.

---

## 6) Checklist

- [ ] Load title `composite/layers/` sky → clouds → far → mid → near (+ optional paper)
- [ ] Header “Pick your starter” ~8–12% from top (sage + charcoal)
- [ ] Three cream cards mid band ~32–55%; portraits from style-lock helpers
- [ ] One selected state (thicker outline / glow / slight scale) — no noisy badge
- [ ] Back + Confirm cream pills ~70–78% from top; `v0.playtest-1` BR
- [ ] Selected idle ≤±4% from `starters-v1.2-face`; hover card 1.03; Confirm hover 1.03
- [ ] No card-band charcoal wash; no grey/charcoal ColorRect grade under cards
- [ ] Cloud drift same as title; credit **edermunizz**
- [ ] No new creatures; no Hatch-dex; title layout stays locked

## 7) Changelog

- **2026-09-24 — Playtest 2 P0:** card-band charcoal/grey wash removed per James; cream cards win on cream-graded title layers alone.

*End PROTO_STARTER_SELECT.*
