# wild-cast-v1-anemononima

Production drop — MVP meadow wild cast + Budmite unlock in **Anêmonônima Blob/Slime** language (CC0).

Same pipeline as `starters-v1.3-anemononima`: pack-native frames → pastel regrade → charcoal outline → identity marks → NN upscale → bottom-center pivot → contact shadow α ~16%.

**Not** a STYLE_LOCK reopen. Enemy path = dusty mauve / wild-rose cooler undertone. Budmite = player mint/sage vertical egg + closed bud.

## Units

| Unit | id | Role | Pack row | Body | Mark | Silhouette |
|------|----|------|----------|------|------|------------|
| Meadow Mite | `meadow_mite` | enemy | row2 | `#C8A4B0` | grass | full |
| Tired Mite | `tired_mite` | enemy | row2 | `#9C7888` | z_badge | flat |
| Barkling | `barkling` | enemy | row6 | `#B4949E` | branch_thorn | squat |
| Pollen Wisp | `pollen_wisp` | enemy | row3 | `#D4B6C2` | pollen_halo | taper |
| Budmite | `budmite` | player | row0 | `#B8E0C8` | closed_bud | egg |

### Soft gaps (Art QC)
- **Barkling** `branch_thorn` mark — provisional earth/branch/short-thorn cue (brief); confirm at 3×3 vs sheets 06/07/12.
- **Pollen Wisp** `pollen_halo` mark — provisional sparse pollen-mote/halo cue; must not read as player cloud bumps/wings.
- No combat telegraph stubs in this drop (optional cheap pass omitted to keep cast shipping).

## Sizes

| Class | Canvas | NN scale | Use |
|-------|--------|----------|-----|
| **64** | 96×88 | ×5 | board token |
| **140** | 220×220 | ×14 | unlock / portrait (Budmite required; all five shipped) |

Pivot: **bottom-center**. Contact shadow α **~16%**.

## Animation

| Anim | Frames | Pack cols (shared clock) | FPS |
|------|--------|--------------------------|-----|
| **Idle** | **8** (`00–07`) | `[0, 1, 0, 3, 0, 6, 0, 7]` → ['neutral', 'stretch', 'neutral_hold', 'soft_squash', 'neutral_hold2', 'look_l', 'neutral_hold3', 'blink'] | **4–5** |

Shared idle clock with starters-v1.3. Quiet pack motion only.

## File map

```
wild-cast-v1-anemononima/
  static/   {meadow_mite,tired_mite,barkling,pollen_wisp,budmite}_{64,140}.png
  idle/     {unit}_idle_{00..07}_{64,140}.png
  sheets/   {unit}_idle_sheet_{64,140}.png
  marks/    mark-{grass,z_badge,branch_thorn,pollen_halo,closed_bud}-{16,32,64}.png
  qc/       qc_3x3_contact_sheet.png
            qc_enemy_vs_budmite_colour.png
            qc_budmite_vs_meadow_mark.png
            qc_five_meadow.png
            qc_idle_cues.png
            qc_marks_kit.png
  README.md  LICENCE.md  ATTRIBUTION.md
```

## Proto ingest

- Prefer **64** for board; **140** for Budmite shop/unlock (others available).
- Transparent RGBA; cream meadow not baked into tokens (QC only).
- Do not add scale tweens on top of idle frames.
- Contact shadow already applied.

## Reproducible build

```
python3 assets/work/wild-cast-v1-anemononima/build_drop.py
```

Source sheet: `assets/candidates/02-anemononima-blob-slime/blobs.png`  
Brief: `art/style-lock/creature-anim-hunt/ASSETS_BRIEF_wild_cast_anemononima.md`  
Clarity refs: sheets `06`, `07`, `12`
