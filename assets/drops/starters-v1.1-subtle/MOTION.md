# MOTION.md — starters-v1.1-subtle

**Brief (follow exactly):** `/workspace/hatchline/art/style-lock/motion/MOTION_BRIEF_v1.md`  
**Look lock:** soft-patched `starters-v1` static + Art kit `art/style-lock/starter-marks/` + `outline-pass-recipe.md`  
**Drop:** motion-only re-export vs `starters-v1` (colours / outline / marks unchanged).

Bar: cosy breathe, not cartoon bounce. Shared clock for all three starters.

---

## Idle (menu + board) — 6 frames, shared timing

**Suggested FPS:** **5 FPS** loop (within 4–5).  
**Alt:** **8 FPS** with 2-frame holds on extremes (`02` peak-up, `05` peak-down).

**Curve:** `00 neutral → 01 micro-up → 02 peak-up → 03 neutral → 04 micro-down → 05 peak-down → loop`

| Frame | Pose | bh | bw |
|-------|------|----|----|
| idle_00 | neutral | 1.00 | 1.00 |
| idle_01 | micro-up | 1.02 | 0.985 |
| idle_02 | peak-up | **1.04** | **0.97** |
| idle_03 | neutral | 1.00 | 1.00 |
| idle_04 | micro-down | 0.98 | 1.02 |
| idle_05 | peak-down | **0.96** | **1.04** |

Lock check: peak stretch ≤ +4% H / −3% W; peak squash ≤ −4% H / +4% W.

**Pivot:** bottom-center (feet plant).  
**Secondary:** leaf / flame move ≤ half body crown delta; Cottonwisp = whole cloud-body silhouette (no separate bump mark).

---

## Merge pop (one-shot) — 6 frames

**Suggested FPS:** **9 FPS** one-shot (within 8–10).  
**End:** frames `04` + `05` settle on rest (2-frame settle). Proto may add 50–80ms ease.

| Frame | Pose | bh | bw | Mark note |
|-------|------|----|----|-----------|
| merge_00 | squash | **0.92** | **1.10** | — |
| merge_01 | expand | **1.08** | **0.94** | optional **+1px** mark lift (leaf/flame) |
| merge_02 | soft-settle | 0.97 | 1.03 | — |
| merge_03 | micro-bounce | 1.02 | 0.985 | — |
| merge_04 | rest | 1.00 | 1.00 | — |
| merge_05 | rest-hold | 1.00 | 1.00 | — |

Lock check: max squash ≤ −8% H / +10% W; max stretch ≤ +8% H / −6% W.

---

## Proto playback (from brief §4)

1. Prefer **linear** filter on 64px soft capsules if nearest shimmers.
2. Idle: **loop** with ease; do **not** tween scale on top of these frames.
3. One global idle phase for all visible starters (or ≤2-frame offset).
4. Merge: one-shot, interrupt-safe back to `idle_00`; don’t blend into idle mid-squash.
5. Files: `{name}_idle_{00..05}_{64,32}.png`, `{name}_merge_{00..05}_{64,32}.png`.

---

## Was (starters-v1) → now

| | starters-v1 | starters-v1.1-subtle |
|-|-------------|----------------------|
| Idle frames | 4 @ 6–8 FPS | **6 @ 4–5 FPS** |
| Idle peak | +10%/−6% · −10%/+12% | **+4%/−3% · −4%/+4%** |
| Merge peak | −20%/+22% · +14%/−10% | **−8%/+10% · +8%/−6%** |
| Merge FPS | 10–12 | **8–10** |
