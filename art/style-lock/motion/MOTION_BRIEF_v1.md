# Hatchline — Subtle motion brief (v1)

**Owner:** Hatch Art (feel / lock) · **Build:** Hatch Assets (frames) · **Wire:** Hatch Proto (playback)  
**Bar:** cosy breathe, not cartoon bounce. Jank usually = too much squash, too few holds, or linear frame stepping.

**Style lock:** Anêmonônima Blob/Slime pack frames + pastel regrade + family marks (James 2026-09-24). Not flat Art capsules. Motion prefers **native pack idle frames**; soft ≤±4% spirit only if synthesizing. No Godot scale tween on top of pack frames.

---

## 1) Starters — idle (menu + board)

**Goal:** alive at a glance; readable at 3×3; never steals focus from shop/path.

| Param | Lock | Notes |
|-------|------|-------|
| Frames | Prefer pack’s **~8 squash/bounce** frames (or ≥4 clean) | Shared row language across Leaf/Ember/Puff |
| Loop FPS | **4–5 FPS** with holds on neutrals/extremes | Or 8 FPS with 2-frame holds |
| Peak spirit | Soft peaks — keep **≤±4%** spirit if synthesizing | If using **native pack frames**, do **not** add Godot scale tween on top |
| Ease / holds | Hold 1–2 ticks on quiet frames | Avoid hard snap loop |
| Pivot | **bottom-center** | Feet plant; mark floats with crown |
| Secondary | leaf/flame/cloud marks move **≤ half** body delta | From `starter-marks/` overlays |
| **Face idle** | **Pack-native eyes preferred** | Optional blink/drift only if frames support — do not force old capsule face rules |

**Face idle:** Prefer Anêmonônima pack-native eye frames. Optional quiet blink / ±1 px drift **only if** the sheet supports it without redrawing. Do not invent capsule two-dot face cycles when pack eyes already read.

**Idle curve (when synthesizing 6-frame):**  
`00 neutral → 01 micro-up → 02 peak-up → 03 neutral → 04 micro-down → 05 peak-down → loop`  
When shipping **native pack frames**, follow the pack order with holds; shared clock across all three starters on one screen.

**Do not:** ping-pong only two extreme poses; scale from center (looks floaty); different timing per starter on the same screen; stack Godot scale tween on pack frame playback; soft-paint / Fluffyblob-volume redraw.

---

## 2) Starters — merge pop (one-shot)

**Goal:** soft reward punch, then settle. Snackable, not elastic violence.

| Param | Lock | Was |
|-------|------|-----|
| Frames | 5–6 (pack extremes OK if clean) | 5 |
| FPS | **8–10** one-shot | 10–12 |
| Max squash | **≤ −8% H / +10% W** if synthesizing | −20% / +22% |
| Max stretch | **≤ +8% H / −6% W** if synthesizing | +14% / −10% |
| End | 2-frame settle on rest; Proto may add 50–80ms ease | hard rest |

Optional: tiny **+1px** mark lift on the expand frame only (leaf/flame), then return. If pack lacks merge, soft Assets settle from idle peaks per Assets brief.

---

## 3) Title / menu motion (scenic amounts unchanged)

Layer order: texture/sky → clouds → hills → grass → **trio wordmark** → buttons.

| Layer | Motion | Amount |
|-------|--------|--------|
| Distant clouds | slow drift X | **8–16 px** over **12–20 s** (live OK: **12 px / 16 s**) |
| Far / mid / near hills | optional parallax X | **≤ 4 px** over **20 s** (live OK: far 2 / mid 3 / near 2) |
| Near grass / flowers | tiny sway or 2-frame shimmer | only if pack supports; else static |
| Trio starters | shared **idle** from §1 (Anêmonônima frames) | same clock; smaller on title |
| Wordmark | **static** (no bob) | — |
| Buttons | hover only | scale **1.00 → 1.03** in 100–120ms ease; no idle bounce |

**Playtest 2 confirmation (2026-09-24):** The §3 amounts are locked; Proto should clamp to them and never exceed. If layer seams hitch at these soft amounts, report to Art as a tile/wrap seam issue — do **not** speed up motion to hide the hitch.

**Playback on current plates (Art wrap pass 2026-09-24):**  
`clouds.png` is a **1280×800 wrap-OK plate** with a matched L/R seam. Proto may wrap-scroll clouds within the locked **8–16 px / 12–20 s** amount (live target: 12 px / 16 s); do not speed motion. **Far/mid/near hill plates remain non-tileable** and should stay ease ping-pong (or soft reverse) within their locked travel unless separately tiled. Ping-pong remains an acceptable fallback for clouds too.

**Layout cue (from James refs):** logo high, big calm sky, buttons low — motion stays in sky/world; UI stays steady.

---

## 4) Proto playback rules (kills most “jank”)

1. Prefer **nearest** filter for this **pixel pack** (Anêmonônima). Match art drop; do not soften with linear unless shimmer is worse than pixel shimmer on board.
2. Idle: **loop** pack frames with holds; never `tween` scale on top of sprite frames (double motion = jank).
3. One global idle phase for all visible starters on a screen (or offset by ≤2 frames max for variety).
4. Merge: play one-shot, **interrupt-safe** back to idle_00; don’t blend merge into idle mid-squash.
5. Cap board idle if >6 units visible: every other unit static OK for perf — prefer all subtle if cheap.
6. Title/pick scenic: wrap-scroll the tileable `clouds.png` within the locked amount, or use ease ping-pong as fallback. **Never wrap** the non-tileable 1280 hill plates; keep far/mid/near ease ping-pong unless separately tiled.

---

## 5) Done-when (James playtest)

- Starters on title + starter-pick feel **alive but calm** for 10+ seconds without noticing the loop pop (pack squash/bounce + quiet face if supported).
- Board 3×3: idle still reads family mark; no “jelly” fight with role badges.
- Merge pop reads once as delight, then quiet.
- Menu: sky/clouds move; buttons don’t dance.

---

## 6) Next owners

- **Assets:** production drop per `art/style-lock/creature-anim-hunt/ASSETS_PRODUCTION_BRIEF_anemononima.md` → `starters-v1.3-anemononima/` (pastel regrade, marks, idle ≥4–8 frames, pick ~140 px, board ~64 px, bottom-center pivot, LICENCE/ATTRIBUTION).
- **Proto:** wires **after Review soft PASS** — nearest filter; retarget FPS/holds; **no** extra scale tweens on pack frames; title parallax per §3.
- **Art:** QC against shortlist boards + production drop; sit-in-world outline/contact shadow on title/pick; update this brief only if James asks louder/softer.

**Changelog:** 2026-09-24 — James locked Anêmonônima Blob/Slime as creature winner for starters / title / board. Style lock = pack frames + pastel + marks (not flat capsules). Prefer nearest; pack-native idle ~8 frames @ 4–5 FPS.
**Changelog:** 2026-09-24 — §1 face idle (capsule rules) superseded by pack-native eyes; prior flat-capsule “do not redraw as pixel” guidance removed (we use the pixel pack).
**Changelog:** 2026-09-24 Playtest 2 — §3 amounts confirmed; seam hitch = Art/Assets seam issue, not faster drift.
**Changelog:** 2026-09-24 Art wrap pass — `clouds.png` is now wrap-OK; hills remain ping-pong unless separately tiled.

*End MOTION_BRIEF_v1.*
