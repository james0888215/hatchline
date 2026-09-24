# starters-v1.1-subtle — Proto drop (motion-only vs v1)

Commercial-ok Proto animation + static tokens. **Motion-only** re-export under Art `MOTION_BRIEF_v1` (subtle breathe).  
**Do not overwrite** `starters-v1` — Proto may still reference it.

Style lock unchanged: flat pastel capsules, thick charcoal outline, two black dots, family marks (Cottonwisp = cloud-body silhouette). Soft-patch look from v1 retained (Sparkpup flame mass, Cotton outline weight).

## Soft patch / motion note

This drop is **motion-only vs `starters-v1`**:

- **Static** tokens are copied from soft-patched `starters-v1` (Sparkpup flame mass + Cottonwisp outline weight already applied).
- **Idle / merge** are re-exported with subtler squash–stretch per `/workspace/hatchline/art/style-lock/motion/MOTION_BRIEF_v1.md`.
- Colours, outline, Art marks, Cottonwisp cloud-body, two-dot faces, and no-double-halo join are unchanged from the v1 look lock + soft patch.
- See `MOTION.md` for frame scale tables and FPS. See v1 `SOFT_PATCH.md` for the original soft-patch changelog (look only).

## File map

```
starters-v1.1-subtle/
  static/
    {sproutling,sparkpup,cottonwisp}_{64,32}.png
  idle/
    {name}_idle_{00..05}_{64,32}.png     # 6 frames subtle breathe
  merge/
    {name}_merge_{00..05}_{64,32}.png    # 6 frames soft merge-pop + settle
  sheets/
    {name}_idle_sheet_64.png
    {name}_merge_sheet_64.png
  qc/
    qc_3x3_contact.png                   # ~28px cell readability
    preview_static_64.png
  MOTION.md
  LICENCE.md
  ATTRIBUTION.md
  README.md
```

## Frame counts + suggested timing

| Anim | Frames | Suggested FPS | Notes |
|------|--------|---------------|-------|
| **Idle** | 6 (`00–05`) | **4–5 FPS** (or 8 FPS + 2-frame holds on `02`/`05`) | neutral → micro-up → peak-up → neutral → micro-down → peak-down. Shared clock. |
| **Merge pop** | 6 (`00–05`) | **8–10 FPS** (one-shot) | squash → expand (+1px mark lift) → soft settle → micro bounce → rest → rest-hold. |

### Idle pose scales (body)

| Frame | bh | bw |
|-------|----|----|
| idle_00 | 1.00 | 1.00 |
| idle_01 | 1.02 | 0.985 |
| idle_02 | 1.04 | 0.97 |
| idle_03 | 1.00 | 1.00 |
| idle_04 | 0.98 | 1.02 |
| idle_05 | 0.96 | 1.04 |

### Merge pose scales

| Frame | bh | bw |
|-------|----|----|
| merge_00 | 0.92 | 1.10 |
| merge_01 | 1.08 | 0.94 |
| merge_02 | 0.97 | 1.03 |
| merge_03 | 1.02 | 0.985 |
| merge_04 | 1.00 | 1.00 |
| merge_05 | 1.00 | 1.00 |

## Colours (recipe lock)

| Starter | Body fill | Mark |
|---------|-----------|------|
| Sproutling | `#B8E0C8` | leaf `#8FCB9B` + vein `#5A9A6A` |
| Sparkpup | `#F7C4A8` | flame outer `#F4A88A` / inner `#FFE8C8` (soft-patch mass) |
| Cottonwisp | `#C5D9F0` | **cloud-body silhouette** |
| Outline (all) | `#2C2A28` ~7% body height (min 2px @32; Cotton soft-patch weight) | |

## Proto ingest notes

- Prefer **64px** for board; **32px** for tight UI / lists.
- Anchor on **bottom-center** of canvas.
- Transparent RGBA; no cream paper baked in (except QC sheets).
- Do not composite a second outline pass — charcoal already applied.
- Do not add scale tweens on top of these frames (double motion = jank).

## Source trail

1. Look: soft-patched `/workspace/hatchline/assets/drops/starters-v1/`
2. Marks / outline: `/workspace/hatchline/art/style-lock/starter-marks/` + `outline-pass-recipe.md`
3. Motion brief: `/workspace/hatchline/art/style-lock/motion/MOTION_BRIEF_v1.md`
4. Export work: `/workspace/hatchline/assets/work/starters-v1.1-subtle/export_subtle.py`
