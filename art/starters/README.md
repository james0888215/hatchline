# starters-v1 — Proto drop (Sproutling / Sparkpup / Cottonwisp)

Commercial-ok first Proto animation + static tokens. Style lock: flat pastel capsules, thick charcoal outline, two black dots, family mark (Cottonwisp = cloud-body silhouette).

## File map

```
starters-v1/
  static/
    {sproutling,sparkpup,cottonwisp}_{64,32}.png
  idle/
    {name}_idle_{00..03}_{64,32}.png     # 4 frames soft squash-stretch
  merge/
    {name}_merge_{00..04}_{64,32}.png    # 5 frames soft merge-pop
  sheets/
    {name}_idle_sheet_64.png
    {name}_merge_sheet_64.png
  qc/
    qc_3x3_contact.png                   # ~28px cell readability
    preview_static_64.png
  LICENCE.md
  ATTRIBUTION.md
  README.md
```

Work / extract trail (not for Proto ingest):
`/workspace/hatchline/assets/work/starters/` — `raw-frames/`, `recolor/`, `ANIM_NOTES.md`

## Frame counts + suggested timing

| Anim | Frames | Suggested FPS | Notes |
|------|--------|---------------|-------|
| **Idle** | 4 (`00–03`) | **6–8 FPS** (hold-friendly) | `00` neutral → `01` stretch → `02` soft squash → `03` settle (= neutral). Soft breathe; loop. |
| **Merge pop** | 5 (`00–04`) | **10–12 FPS** (one-shot) | `00` heavy squash → `01` expand pop → `02` soft settle → `03` tiny bounce → `04` rest. Play once on merge. |

Timing cue: idle should feel cosy (slightly slow); merge pop is a short soft punch then settle — not elastic cartoon violence.

### Idle pose scales (body)
| Frame | bh | bw |
|-------|----|----|
| idle_00 | 1.00 | 1.00 |
| idle_01 | 1.10 | 0.94 |
| idle_02 | 0.90 | 1.12 |
| idle_03 | 1.00 | 1.00 |

### Merge pose scales
| Frame | bh | bw |
|-------|----|----|
| merge_00 | 0.80 | 1.22 |
| merge_01 | 1.14 | 0.90 |
| merge_02 | 0.96 | 1.04 |
| merge_03 | 1.06 | 0.97 |
| merge_04 | 1.00 | 1.00 |

## Colours (recipe lock)
| Starter | Body fill | Mark |
|---------|-----------|------|
| Sproutling | `#B8E0C8` | leaf `#8FCB9B` + vein `#5A9A6A` |
| Sparkpup | `#F7C4A8` | flame outer `#F4A88A` / inner `#FFE8C8` |
| Cottonwisp | `#C5D9F0` | **cloud-body silhouette** (not pill + bump mark) |
| Outline (all) | `#2C2A28` ~7% body height (min 2px @32) | |

## Proto ingest notes
- Prefer **64px** for board presentation; **32px** for tight UI / lists.
- Anchor tokens on **bottom-center** of canvas (mark hangs above body).
- Transparent RGBA; no cream paper baked in (except QC sheets).
- Do not composite a second outline pass — charcoal already applied.

## Source trail
1. Extract Anêmonônima pack poses → `work/starters/raw-frames/`
2. Flat pastel recolor (marks off) → `work/starters/recolor/`
3. Lock-true redraw + Art marks/outline per `outline-pass-recipe.md` → this drop

Pack alone is shaded 13×11 pixel art; Proto frames are lock-true redraws with pack-keyed squash/stretch (not nearest-neighbor upscales).
