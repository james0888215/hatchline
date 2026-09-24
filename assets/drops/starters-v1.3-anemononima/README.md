# starters-v1.3-anemononima

Production drop from **Anêmonônima Blob/Slime** (CC0) — pack-native frames with pastel regrade + Hatchline Art marks.

**Not** the archived flat-capsule redraw (`starters-v1.2-face`). Keep pack thick outline + two-dot face; marks on TOP; cream-meadow pastel bodies.

## Sizes

| Class | Canvas | NN scale from 16×16 cell | Body height (approx) | Use |
|-------|--------|--------------------------|----------------------|-----|
| **140** | 220×200 | ×14 | ~140px (~140 class) | pick / title |
| **64** | 96×80 | ×5 | ~50px | board token |
| **32** | 48×40 | ×3 | ~30px | tight UI (static only) |

Pivot: **bottom-center** on every frame (consistent padding + soft contact shadow α ~16%).

## Animation

| Anim | Frames | Pack cols (shared clock) | FPS | Notes |
|------|--------|--------------------------|-----|-------|
| **Idle** | **8** (`00–07`) | `[0, 1, 0, 3, 0, 6, 0, 7]` → ['neutral', 'stretch', 'neutral_hold', 'soft_squash', 'neutral_hold2', 'look_l', 'neutral_hold3', 'blink'] | **4–5** | holds on neutrals; blink on 07 |
| **Merge pop** | **6** (`00–05`) | `[3, 1, 0, 1, 0, 0]` → ['squash', 'stretch', 'settle', 'micro_bounce', 'rest', 'rest_hold'] | **8–10** one-shot | soft pack extremes |

Shared idle clock across Sproutling / Sparkpup / Cottonwisp.

Soft peaks: pack pose size variance is only ~±1 native px (~±5–10% after scale) — no Godot scale tweens on top.

## Family mapping

| Starter | Pack row | Body pastel | Mark |
|---------|----------|-------------|------|
| Sproutling | row0 green | `#B8E0C8` mint | leaf tip TOP |
| Sparkpup | row4 red | `#F7C4A8` peach | soft flame TOP |
| Cottonwisp | row1 cyan | `#C5D9F0` powder | cloud bumps TOP |

Outline / eyes: charcoal `#2C2A28`. Mark outline merges with body (no double-halo).

## File map

```
starters-v1.3-anemononima/
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

## Reproducible build

```
python3 assets/work/starters-v1.3-anemononima/build_drop.py
```

Source sheet: `assets/candidates/02-anemononima-blob-slime/blobs.png`  
Marks: `art/style-lock/starter-marks/`  
Brief: `art/style-lock/creature-anim-hunt/ASSETS_PRODUCTION_BRIEF_anemononima.md`
