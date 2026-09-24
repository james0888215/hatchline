# starters-v1.2-face — Proto drop (face idle + P1 sit-in-world)

Commercial-ok Proto animation + static tokens.  
**Face idle** under Art `MOTION_BRIEF_v1` §1 (blink + ±1px drift) on **P1** thicker charcoal + soft contact shadow (match title wordmark trio + starter-select cards).

**Do not overwrite** `starters-v1` or `starters-v1.1-subtle` — Proto may still reference them.

Style lock: flat pastel capsules, thick charcoal outline, two black dots, family marks (Cottonwisp = cloud-body). Soft-patch flame mass retained via Art draw path. **No pixel-punch.**

## What’s new vs v1.1-subtle

| | v1.1-subtle | **v1.2-face** |
|-|-------------|----------------|
| Outline | soft-patch weight | **touch thicker** (P1 / playtest #22) |
| Contact shadow | none / AA fringe | **soft puddle α ~15–18%** after blur |
| Face idle | open dots only | **blink on 03** + **±1px drift on 01/04** |
| Body motion | ≤±4% 6f @ 4–5 FPS | same |
| Merge | subtle 6f | same scales, **re-outlined** to match P1 |

See `MOTION.md`, `SOFT_PATCH.md`.

## File map

```
starters-v1.2-face/
  static/   {sproutling,sparkpup,cottonwisp}_{64,32}.png
  idle/     {name}_idle_{00..05}_{64,32}.png
  merge/    {name}_merge_{00..05}_{64,32}.png
  sheets/   {name}_{idle,merge}_sheet_64.png
  qc/
    qc_vs_wordmark_trio.png
    qc_vs_select_cards.png
    qc_face_cues.png
    qc_3x3_contact.png
    preview_static_64.png
    preview_face_cues_64.png
  MOTION.md
  SOFT_PATCH.md
  LICENCE.md
  ATTRIBUTION.md
  README.md
```

## Frame counts + suggested timing

| Anim | Frames | Suggested FPS | Notes |
|------|--------|---------------|-------|
| **Idle** | 6 (`00–05`) | **4–5 FPS** | face cues on shared clock; see MOTION.md |
| **Merge pop** | 6 (`00–05`) | **8–10 FPS** one-shot | face at rest; 2-frame settle |

## Colours (recipe lock)

| Starter | Body fill | Mark |
|---------|-----------|------|
| Sproutling | `#B8E0C8` | leaf `#8FCB9B` + vein `#5A9A6A` |
| Sparkpup | `#F7C4A8` | flame outer `#F4A88A` / inner `#FFE8C8` |
| Cottonwisp | `#C5D9F0` | **cloud-body silhouette** |
| Outline (all) | `#2C2A28` P1 thicker | |
| Contact shadow | charcoal ~15–18% α after blur | under capsule |

## Proto ingest notes

- Prefer **64px** for board; **32px** for tight UI / lists.
- Anchor on **bottom-center** of canvas (shadow sits under feet).
- Transparent RGBA; no cream paper baked in (except QC sheets).
- Do not composite a second outline / shadow pass — already applied.
- Do not add scale tweens on top of these frames.
- P2 scenic layers live under `art/style-lock/title-menu-v1/composite/layers/` — Proto loads them; not part of this drop.

## Source trail

1. Look / P1: `art/style-lock/title-menu-v1/_gen_title_menu_v1_2.py` (`make_starter_token`, `#22` outline + contact shadow)
2. Match targets: `wordmark-hatchline-trio-{512,256,lock}.png`, `starter-select-v1/card-*.png`, `20-starter-select-lock.png`
3. Motion brief: `art/style-lock/motion/MOTION_BRIEF_v1.md` §1
4. Face draft / export: `assets/work/starters-v1.2-face-draft/` (`export_face_idle.py`, `finalize_v12_face.py`)
5. Prior motion tables: `assets/drops/starters-v1.1-subtle/`
