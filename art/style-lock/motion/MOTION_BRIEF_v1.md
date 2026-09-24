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
| Distant clouds | slow drift X | 8–16 px over **12–20 s**, seamless loop |
| Far hills | optional parallax X | **≤ 4 px** over 20 s |
| Near grass / flowers | tiny sway or 2-frame shimmer | only if pack supports; else static |
| Trio starters | shared **idle** from §1 | same clock; smaller on title |
| Wordmark | **static** (no bob) | — |
| Buttons | hover only | scale **1.00 → 1.03** in 100–120ms ease; no idle bounce |

**Layout cue (from James refs):** logo high, big calm sky, buttons low — motion stays in sky/world; UI stays steady.

---

## 4) Proto playback rules (kills most “jank”)

1. Use **AnimatedSprite2D** / AnimationPlayer with **nearest** filter only if pixel; for our soft capsules prefer **linear** on 64px boards if shimmer appears — match art drop.
2. Idle: **loop** with ease; never `tween` scale on top of sprite frames (double motion = jank).
3. One global idle phase for all visible starters on a screen (or offset by ≤2 frames max for variety).
4. Merge: play one-shot, **interrupt-safe** back to idle_00; don’t blend merge into idle mid-squash.
5. Cap board idle if >6 units visible: every other unit static OK for perf — prefer all subtle if cheap.

---

## 5) Done-when (James playtest)

- Starters on title + starter-pick feel **alive but calm** for 10+ seconds without noticing the loop pop (body ≤±4% **plus** quiet blink / ±1px eye drift).
- Board 3×3: idle still reads family mark; no “jelly” fight with role badges.
- Merge pop reads once as delight, then quiet.
- Menu: sky/clouds move; buttons don’t dance.

---

## 6) Next owners

- **Assets:** starters-v1.2-face is the live set in `art/starters/` (idle `00–05`, blink on `03`, ±1px drift on `01`/`04`, merge `00–05`). The drop stays at `assets/drops/starters-v1.2-face/`. `assets/drops/starters-v1.1-subtle/` is the archive.
- **Proto:** idle plays at 5 FPS and merge at 9 FPS, on one shared clock, pivot bottom-center, with no scale tween on the frames. Title cloud drift is already wired on the pack stack.
- **Art:** cream-grade scenic layers, trio wordmarks, and starter-select cards shipped with this drop. Title layout stays the locked pack stack.

**Changelog:** 2026-09-24 — §1 face idle added after James #22 playtest (Review P0). Style lock stays flat capsules. Proto wired v1.2-face the same day.

*End MOTION_BRIEF_v1.*
