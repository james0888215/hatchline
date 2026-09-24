# SOFT_PATCH / P1 note — starters-v1.2-face

## What changed vs `starters-v1.1-subtle`

1. **P1 sit-in-world look** (match Art title-menu wordmark trio + starter-select cards):
   - Charcoal outline `#2C2A28` reads **a touch thicker** than v1.1-subtle (Art `#22` recipe: `bh*0.07` + ~2 display-px).
   - Soft **contact shadow** under capsules — charcoal peak α **~20%**, readable puddle **~15–18%** after Gaussian blur (not a hard drop shadow).
2. **Face idle** per `MOTION_BRIEF_v1` §1: blink on `idle_03` (1 frame squint); ±1px shared eye drift on `idle_01` / `idle_04`.
3. **Merge** re-exported from the new statics (same subtle scales as v1.1) so outline/shadow match — face at rest.

## Unchanged lock

- Flat pastel fills (Sproutling `#B8E0C8`, Sparkpup `#F7C4A8`, Cottonwisp `#C5D9F0`)
- Art marks: leaf / soft-patch flame mass / Cotton **cloud-body** silhouette
- Two-dot faces only
- Body idle ≤±4%; pivot bottom-center; shared 4–5 FPS clock
- **No pixel-punch** / dither / outline-noise

## Soft patch lineage

v1 soft-patch (Sparkpup flame mass + Cotton outline weight) is absorbed into the Art P1 draw path used here (`title-menu-v1/_gen_title_menu_v1_2.py` helpers). See prior `starters-v1.1-subtle/SOFT_PATCH.md` for history.

## P2 scenic

Cream-paper scenic grade (`title-menu-v1/composite/layers/*`, `21-scenic-cream-grade.png`) is **Proto context only** — not shipped in this drop.
