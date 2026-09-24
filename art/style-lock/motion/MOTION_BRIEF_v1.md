# Hatchline — Subtle motion brief (v1)

**Owner:** Hatch Art (feel / lock) · **Build:** Hatch Assets (frames) · **Wire:** Hatch Proto (playback)  
**Bar:** cosy breathe, not cartoon bounce. Jank usually = too much squash, too few holds, or linear frame stepping.

Style lock stays: flat capsules, thick charcoal, two-dot faces. Motion is silhouette scale + tiny mark secondary only — no new limbs, no smear frames required for MVP.

---

## 1) Starters — idle (menu + board)

**Goal:** alive at a glance; readable at 3×3; never steals focus from shop/path.

| Param | Lock | Was (starters-v1) |
|-------|------|-------------------|
| Frames | **6** preferred (or 4 with holds) | 4 |
| Loop FPS | **4–5 FPS** (or 8 FPS with 2-frame holds on extremes) | 6–8 |
| Peak stretch | **≤ +4% H / −3% W** | +10% / −6% |
| Peak squash | **≤ −4% H / +4% W** | −10% / +12% |
| Ease | ease-in-out; **hold 1–2 ticks** on neutral | hard step |
| Pivot | **bottom-center** (feet plant; mark floats with crown) | — |
| Secondary | leaf/flame/cloud bumps move **≤ half** body delta | lock to body |
| **Face idle** | **allowed** on two-dot faces — see below | none (felt lifeless on #22) |

**Face idle (James playtest #22 — more life without pixel-punch):**  
Keep the **flat pastel capsule** lock. Do **not** redraw critters as pixel art to match pack scenery.

| Face cue | Lock | Notes |
|----------|------|-------|
| Blink | **1–2 frames** lids/squint (dots briefly shorten or close) | Cosy; not anime multi-blink flurry |
| Eye drift | optional **±1 px** on both dots together | Shared with body clock; never opposite-eye wander |
| Timing | same **shared idle clock** as body §1 | Face peaks on quiet frames (neutral / micro), not only on squash extremes |
| Intensity | face reads as life; body still owns ≤±4% silhouette | No brow, mouth, or cheek squash |

**Idle curve (6-frame example):**  
`00 neutral → 01 micro-up → 02 peak-up → 03 neutral → 04 micro-down → 05 peak-down → loop`  
Peaks use the ≤4% table. No frame should snap back to identical `00` without a settle.  
Example face placement: blink on `03` (or `00`/`03` alternating loops); ±1px drift on `01`/`04` only.

**Do not:** ping-pong only two extreme poses; scale from center (looks floaty); different timing per starter on the same screen (keep one shared clock); pixel-punch / dither / outline-noise the capsule to “match” NN pack art; cartoon eye pops larger than ±1px.

---

## 2) Starters — merge pop (one-shot)

**Goal:** soft reward punch, then settle. Snackable, not elastic violence.

| Param | Lock | Was |
|-------|------|-----|
| Frames | 5–6 | 5 |
| FPS | **8–10** one-shot | 10–12 |
| Max squash | **≤ −8% H / +10% W** | −20% / +22% |
| Max stretch | **≤ +8% H / −6% W** | +14% / −10% |
| End | 2-frame settle on rest; Proto may add 50–80ms ease | hard rest |

Optional: tiny **+1px** mark lift on the expand frame only (leaf/flame), then return.

---

## 3) Title / menu motion (while Assets scenic packs land)

Layer order: texture/sky → clouds → hills → grass → **trio wordmark** → buttons.

| Layer | Motion | Amount |
|-------|--------|--------|
| Distant clouds | slow drift X | **8–16 px** over **12–20 s** (live OK: **12 px / 16 s**) |
| Far / mid / near hills | optional parallax X | **≤ 4 px** over **20 s** (live OK: far 2 / mid 3 / near 2) |
| Near grass / flowers | tiny sway or 2-frame shimmer | only if pack supports; else static |
| Trio starters | shared **idle** from §1 | same clock; smaller on title |
| Wordmark | **static** (no bob) | — |
| Buttons | hover only | scale **1.00 → 1.03** in 100–120ms ease; no idle bounce |

**Playtest 2 confirmation (2026-09-24):** The §3 amounts are locked; Proto should clamp to them and never exceed. If layer seams hitch at these soft amounts, report to Art as a tile/wrap seam issue — do **not** speed up motion to hide the hitch.

**Playback on current plates (updated after Art wrap pass 2026-09-24):**  
`clouds.png` is now a **1280×800 wrap-OK plate** with a matched L/R seam. Proto may wrap-scroll clouds within the locked **8–16 px / 12–20 s** amount (live target: 12 px / 16 s); do not speed motion. **Far/mid/near hill plates remain non-tileable** and should stay ease ping-pong (or soft reverse) within their locked travel unless separately tiled. Ping-pong remains an acceptable fallback for clouds too.

**Layout cue (from James refs):** logo high, big calm sky, buttons low — motion stays in sky/world; UI stays steady.

---

## 4) Proto playback rules (kills most “jank”)

1. Use **AnimatedSprite2D** / AnimationPlayer with **nearest** filter only if pixel; for our soft capsules prefer **linear** on 64px boards if shimmer appears — match art drop.
2. Idle: **loop** with ease; never `tween` scale on top of sprite frames (double motion = jank).
3. One global idle phase for all visible starters on a screen (or offset by ≤2 frames max for variety).
4. Merge: play one-shot, **interrupt-safe** back to idle_00; don’t blend merge into idle mid-squash.
5. Cap board idle if >6 units visible: every other unit static OK for perf — prefer all subtle if cheap.
6. Title/pick scenic: wrap-scroll the new tileable `clouds.png` within the locked amount, or use ease ping-pong as fallback. **Never wrap** the non-tileable 1280 hill plates; keep far/mid/near ease ping-pong unless separately tiled.

---

## 5) Done-when (James playtest)

- Starters on title + starter-pick feel **alive but calm** for 10+ seconds without noticing the loop pop (body ≤±4% **plus** quiet blink / ±1px eye drift).
- Board 3×3: idle still reads family mark; no “jelly” fight with role badges.
- Merge pop reads once as delight, then quiet.
- Menu: sky/clouds move; buttons don’t dance.

---

## 6) Next owners

- **Assets:** re-export starters idle/merge under these % **with face idle** (blink 1–2f, optional ±1px drift); keep flat capsule colours/outline from style-lock; new drop `starters-v1.2-face/` (or patch) + README note. Do **not** pixel-punch.
- **Proto:** retarget FPS/holds; remove any extra scale tweens; title parallax per §3 when scenic layers exist.
- **Art:** re-pass QC; sit-in-world outline/contact shadow on title/pick (P1); optional cream-paper scenic grade (P2). Update this brief only if James asks louder/softer.

**Changelog:** 2026-09-24 — §1 face idle added after James #22 playtest (Review P0). Style lock stays flat capsules.
**Changelog:** 2026-09-24 Playtest 2 — §3 amounts confirmed; seam hitch = Art/Assets seam issue, not faster drift.
**Changelog:** 2026-09-24 Art wrap pass — `clouds.png` is now wrap-OK; hills remain ping-pong unless separately tiled.

*End MOTION_BRIEF_v1.*
