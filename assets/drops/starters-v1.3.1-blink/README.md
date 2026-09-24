# starters-v1.3.1-blink

P0 re-export of **starters-v1.3-anemononima** with a stronger shared-clock blink for title/pick.

Production drop from **Anêmonônima Blob/Slime** (CC0) — pack-native frames with pastel regrade + Hatchline Art marks.

**Not** the archived flat-capsule redraw (`starters-v1.2-face`). Keep pack thick outline + pack-native eyes (strengthened closed lids); marks on TOP; cream-meadow pastel bodies.

## P0 blink lock (2026-09-24)

| Rule | This drop |
|------|-----------|
| Glance read | Clear blink every **~1.6–2.0 s** (8f @ 4–5 FPS) |
| Closed hold | **2 ticks** — frames **06 + 07** are identical CLOSED |
| Lid weight | **Thick charcoal horizontal bars** `#2C2A28` (2 native px tall × ≥3–4 wide; NN ×5/×14) — not 1px hairline |
| Half-lid | Frame **05** brief half-lid intermediate (1 native px tall) |
| Shared clock | Sproutling / Sparkpup / Cottonwisp identical frame indices |
| Soft body | Pack quiet peaks only; no Godot scale tween |

## Sizes

| Class | Canvas | NN scale from 16×16 cell | Body height (approx) | Use |
|-------|--------|--------------------------|----------------------|-----|
| **140** | 220×200 | ×14 | ~140px (~140 class) | pick / title |
| **64** | 96×80 | ×5 | ~50px | board token |
| **32** | 48×40 | ×3 | ~30px | tight UI (static only) |

Pivot: **bottom-center** on every frame (consistent padding + soft contact shadow α ~16%).

## Animation

| Anim | Frames | Shared clock | FPS | Notes |
|------|--------|--------------|-----|-------|
| **Idle** | **8** (`00–07`) | `[0, 1, 0, 3, 0, 'half', 'closed', 'closed']` → ['open', 'micro', 'open', 'squash', 'open', 'half_lid', 'CLOSED', 'CLOSED'] | **4–5** | **CLOSED hold on 06+07**; half-lid on 05 |
| **Merge pop** | **6** (`00–05`) | `[3, 1, 0, 1, 0, 0]` → ['squash', 'stretch', 'settle', 'micro_bounce', 'rest', 'rest_hold'] | **8–10** one-shot | unchanged from v1.3 |

### Idle frame map

| Index | Source | Label |
|-------|--------|-------|
| 00 | pack col0 | open / neutral |
| 01 | pack col1 | micro / stretch |
| 02 | pack col0 | open |
| 03 | pack col3 | squash |
| 04 | pack col0 | open |
| 05 | synthesized on col0 | half-lid (1px tall bars) |
| 06 | pack col7 + thick lids | **CLOSED** |
| 07 | pack col7 + thick lids | **CLOSED** (duplicate hold) |

Frame labels: `0:open, 1:micro, 2:open, 3:squash, 4:open, 5:half_lid, 6:CLOSED, 7:CLOSED`

Shared idle clock across Sproutling / Sparkpup / Cottonwisp.

Soft peaks: pack pose size variance is only ~±1 native px — no Godot scale tweens on top.

## Family mapping

| Starter | Pack row | Body pastel | Mark |
|---------|----------|-------------|------|
| Sproutling | row0 green | `#B8E0C8` mint | leaf tip TOP |
| Sparkpup | row4 red | `#F7C4A8` peach | soft flame TOP |
| Cottonwisp | row1 cyan | `#C5D9F0` powder | cloud bumps TOP |

Outline / eyes / closed lids: charcoal `#2C2A28`. Mark outline merges with body (no double-halo).

## File map

```
starters-v1.3.1-blink/
  static/   {sproutling,sparkpup,cottonwisp}_{140,64,32}.png
  idle/     {name}_idle_{00..07}_{140,64}.png
  merge/    {name}_merge_{00..05}_{140,64}.png
  sheets/   {name}_{idle,merge}_sheet_{140,64}.png
  qc/       qc_trio_meadow.png  qc_64_readability.png
            qc_face_idle_cues.png  qc_pick_140.png
            preview_idle_sheet_140.png
  README.md  LICENCE.md  ATTRIBUTION.md
```

## Proto ingest

- Prefer **64** for board; **140** for pick / title sit.
- Transparent RGBA; cream meadow **not** baked into tokens (only QC).
- Do **not** add scale tweens on top of these frames.
- Contact shadow already applied (~15–18% α).
- Blink: play frames 06+07 as consecutive holds (already duplicated in the drop).

## vs v1.3

`starters-v1.3-anemononima` idle was `[0,1,0,3,0,6,0,7]` with blink only on **07** (1-tick flicker) — **FAIL P0**. This drop keeps pastel/marks/merge/sizes and re-exports idle only for the 2-tick thick-lid blink.

## Reproducible build

```
python3 assets/work/starters-v1.3.1-blink/build_drop.py
```

Source sheet: `assets/candidates/02-anemononima-blob-slime/blobs.png`  
Marks: `art/style-lock/starter-marks/`  
Brief: `art/style-lock/motion/MOTION_BRIEF_v1.md` §1 P0 title/pick blink
