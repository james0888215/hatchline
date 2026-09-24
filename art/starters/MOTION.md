# MOTION.md — starters-v1.2-face

**Brief (follow exactly):** `/workspace/hatchline/art/style-lock/motion/MOTION_BRIEF_v1.md` §1  
**Look lock:** Art P1 sit-in-world (thicker charcoal + soft contact shadow) matching  
`title-menu-v1/wordmark-hatchline-trio-*` + `starter-select-v1/card-*` + `20-starter-select-lock.png`  
**Face idle:** blink 1 frame + ±1px shared eye drift on the body clock. **No pixel-punch.**

Bar: cosy breathe + quiet face life. Shared clock for all three starters.

---

## Idle (menu + board) — 6 frames, shared timing

**Suggested FPS:** **5 FPS** loop (within 4–5).  
**Alt:** **8 FPS** with 2-frame holds on extremes (`02` peak-up, `05` peak-down).

**Curve:** `00 neutral → 01 micro-up → 02 peak-up → 03 neutral → 04 micro-down → 05 peak-down → loop`

| Frame | Pose | bh | bw | Face cue |
|-------|------|----|----|----------|
| idle_00 | neutral | 1.00 | 1.00 | **open** (bit-identical to static) |
| idle_01 | micro-up | 1.02 | 0.985 | **drift** both dots **−1 py** |
| idle_02 | peak-up | **1.04** | **0.97** | open |
| idle_03 | neutral | 1.00 | 1.00 | **blink** — lids/squint (~⅓ height, 1 frame) |
| idle_04 | micro-down | 0.98 | 1.02 | **drift** both dots **+1 py** |
| idle_05 | peak-down | **0.96** | **1.04** | open |

Lock check: peak stretch ≤ +4% H / −3% W; peak squash ≤ −4% H / +4% W.

**Pivot:** bottom-center (feet plant; contact shadow scales with plant).  
**Secondary:** leaf / flame move ≤ half body crown delta; Cottonwisp = whole cloud-body silhouette.  
**Face:** two solid black dots only — no brow / mouth / cheek. Drift moves both dots together. Blink = vertical shorten only.

**Proto optional:** alternate blink onto `00` on odd loops (`00` blink / `03` open) so neutrals don’t metronome. Assets keep `00` open + bit-identical to static for merge interrupt-safe return.

---

## Merge pop (one-shot) — 6 frames

**Suggested FPS:** **9 FPS** one-shot (within 8–10).  
**End:** frames `04` + `05` settle on rest. Face stays at rest (no blink/drift in merge).

| Frame | Pose | bh | bw | Mark note |
|-------|------|----|----|-----------|
| merge_00 | squash | **0.92** | **1.10** | — |
| merge_01 | expand | **1.08** | **0.94** | optional **+1px** mark lift (leaf/flame) |
| merge_02 | soft-settle | 0.97 | 1.03 | — |
| merge_03 | micro-bounce | 1.02 | 0.985 | — |
| merge_04 | rest | 1.00 | 1.00 | — |
| merge_05 | rest-hold | 1.00 | 1.00 | — |

---

## Proto playback (from brief §4)

1. Prefer **linear** filter on 64px soft capsules if nearest shimmers.
2. Idle: **loop** with ease; do **not** tween scale on top of these frames.
3. One global idle phase for all visible starters (or ≤2-frame offset).
4. Merge: one-shot, interrupt-safe back to `idle_00`.
5. Files: `{name}_idle_{00..05}_{64,32}.png`, `{name}_merge_{00..05}_{64,32}.png`.
