#!/usr/bin/env python3
"""Hatchline starter-select v1 — pick screen lock (Sproutling / Sparkpup / Cottonwisp).

Reuses title pack-stack scenic layers + style-lock draw helpers.
Canvas 1280×800. James locking selection menu 2026-09-24.
No new creatures. No muddy washes. No CraftPix flowers.
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageEnhance

ROOT = Path("/workspace/hatchline")
STYLE = ROOT / "art/style-lock"
TITLE_LAYERS = STYLE / "title-menu-v1/composite/layers"
TITLE_GEN = STYLE / "title-menu-v1/_gen_title_menu_v1_2.py"
OUT = STYLE / "starter-select-v1"
SHEET20 = STYLE / "20-starter-select-lock.png"

W, H = 1280, 800

CHARCOAL = (0x2C, 0x2A, 0x28, 255)
CREAM_BTN = (0xFA, 0xF6, 0xEE, 255)
CREAM_CARD = (0xFA, 0xF6, 0xEE, 255)
CREAM_PAPER = (0xF7, 0xF0, 0xE4, 255)
CREAM = (0xF7, 0xF2, 0xE8, 255)
SAGE_FILL = (0x5A, 0x8F, 0x6A, 255)
MUTED = (0x5C, 0x58, 0x54, 255)
MUTED_SOFT = (0x7A, 0x74, 0x6C, 255)
GLOW = (0xFA, 0xF6, 0xEE, 255)

FONT_BOLD = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
FONT_REG = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"

# Layout lock (fractions of canvas height / absolute px)
HEADER_Y_FRAC = 0.10          # ~8–12% — header baseline center
CARD_BAND_TOP = 0.32          # cards mid band ~32–55%
CARD_BAND_BOT = 0.55
CARD_CENTER_Y_FRAC = 0.445    # portrait/card vertical center
BTN_Y_FRAC = 0.74             # mid-lower ~70–78%
BTN_W, BTN_H = 260, 48
CARD_W, CARD_H = 300, 390
CARD_GAP = 36
BODY_H = 122                  # starter portrait body height
SELECTED_SCALE = 1.045
SELECTED_OUTLINE = 7          # thicker than idle 4
IDLE_OUTLINE = 4
CARD_RADIUS = 28


def fnt(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def load_title_helpers():
    """Import draw helpers from locked title gen (do not invent look)."""
    spec = importlib.util.spec_from_file_location("title_gen_v12", TITLE_GEN)
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def soft_light_composite(base: Image.Image, overlay: Image.Image) -> Image.Image:
    """Approximate soft-light blend for paper overlay."""
    base = base.convert("RGBA")
    overlay = overlay.convert("RGBA").resize(base.size, Image.Resampling.LANCZOS)
    bp = base.load()
    op = overlay.load()
    w, h = base.size
    out = Image.new("RGBA", (w, h))
    opx = out.load()
    for y in range(h):
        for x in range(w):
            br, bg, bb, ba = bp[x, y]
            or_, og, ob, oa = op[x, y]
            if oa < 2:
                opx[x, y] = (br, bg, bb, ba)
                continue
            a = oa / 255.0

            def ch(b, o):
                b_n, o_n = b / 255.0, o / 255.0
                if o_n < 0.5:
                    r = 2 * b_n * o_n + b_n * b_n * (1 - 2 * o_n)
                else:
                    r = 2 * b_n * (1 - o_n) + (b_n ** 0.5) * (2 * o_n - 1)
                return int(max(0, min(255, b + (r * 255 - b) * a)))

            opx[x, y] = (ch(br, or_), ch(bg, og), ch(bb, ob), ba)
    return out


def build_scenic(darken_card_band: bool = True) -> Image.Image:
    """Reuse title pack-stack layers; optional softer/darker grade under cards."""
    sky = Image.open(TITLE_LAYERS / "sky.png").convert("RGBA")
    clouds = Image.open(TITLE_LAYERS / "clouds.png").convert("RGBA")
    far = Image.open(TITLE_LAYERS / "far.png").convert("RGBA")
    mid = Image.open(TITLE_LAYERS / "mid.png").convert("RGBA")
    near = Image.open(TITLE_LAYERS / "near.png").convert("RGBA")
    paper = Image.open(TITLE_LAYERS / "paper-softlight.png").convert("RGBA")

    base = Image.new("RGBA", (W, H), CREAM_PAPER)
    base.alpha_composite(sky)
    base.alpha_composite(clouds)
    base.alpha_composite(far)
    base.alpha_composite(mid)
    base.alpha_composite(near)
    base = soft_light_composite(base, paper)

    if darken_card_band:
        # Soft darker grade under card band so cream cards pop; keep center readable
        grade = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gd = ImageDraw.Draw(grade)
        # vertical band ~28–60% with soft edges
        y0 = int(H * 0.26)
        y1 = int(H * 0.62)
        for i in range(y1 - y0):
            t = i / max(1, y1 - y0 - 1)
            # peak darkness mid-band (~0.14 alpha charcoal wash)
            edge = min(t, 1 - t) * 2  # 0→1→0
            edge = max(0.0, min(1.0, edge))
            a = int(36 * (edge ** 0.85))
            gd.line([(0, y0 + i), (W, y0 + i)], fill=(0x2C, 0x2A, 0x28, a))
        grade = grade.filter(ImageFilter.GaussianBlur(radius=18))
        base.alpha_composite(grade)

    return base


def outlined_text(
    d: ImageDraw.ImageDraw,
    xy: tuple[float, float],
    text: str,
    font: ImageFont.FreeTypeFont,
    fill,
    outline,
    ow: int,
) -> None:
    x, y = xy
    for dx in range(-ow, ow + 1):
        for dy in range(-ow, ow + 1):
            if dx * dx + dy * dy <= ow * ow + ow:
                d.text((x + dx, y + dy), text, font=font, fill=outline)
    d.text((x, y), text, font=font, fill=fill)


def draw_header(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    text = "Pick your starter"
    font = fnt(FONT_BOLD, 42)
    bb = d.textbbox((0, 0), text, font=font)
    tw, th = bb[2] - bb[0], bb[3] - bb[1]
    x = (W - tw) // 2
    y = int(H * HEADER_Y_FRAC) - th // 2
    # Match title wordmark language: sage fill + charcoal outline
    outlined_text(d, (x, y), text, font, SAGE_FILL, CHARCOAL, ow=3)


def make_card(
    helpers,
    kind: str,
    name: str,
    cue: str,
    selected: bool = False,
) -> Image.Image:
    """Cream pick card with portrait + name + optional family cue."""
    scale = SELECTED_SCALE if selected else 1.0
    cw = int(CARD_W * scale)
    ch = int(CARD_H * scale)
    outline = SELECTED_OUTLINE if selected else IDLE_OUTLINE

    card = Image.new("RGBA", (cw + 40, ch + 40), (0, 0, 0, 0))
    ox, oy = 20, 20
    d = ImageDraw.Draw(card)

    # Soft cream glow ring for selected
    if selected:
        glow = Image.new("RGBA", card.size, (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        for i, a in enumerate((55, 40, 28, 16, 8)):
            pad = 10 + i * 3
            gd.rounded_rectangle(
                [ox - pad, oy - pad, ox + cw + pad, oy + ch + pad],
                radius=CARD_RADIUS + pad,
                outline=(*GLOW[:3], a),
                width=5,
            )
        glow = glow.filter(ImageFilter.GaussianBlur(radius=6))
        card.alpha_composite(glow)

    # Thick charcoal outline + cream fill
    d.rounded_rectangle(
        [ox - outline, oy - outline, ox + cw + outline, oy + ch + outline],
        radius=CARD_RADIUS + outline,
        fill=CHARCOAL,
    )
    d.rounded_rectangle(
        [ox, oy, ox + cw, oy + ch],
        radius=CARD_RADIUS,
        fill=CREAM_CARD,
    )

    # Portrait — sized so name+cue fit cleanly under token bbox
    body = int(BODY_H * scale)
    token = helpers.make_starter_token(kind, body)
    name_f = fnt(FONT_BOLD, int(22 * scale))
    cue_f = fnt(FONT_REG, int(14 * scale))
    # Measure text block for bottom reserve
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    nbb = tmp.textbbox((0, 0), name, font=name_f)
    cbb = tmp.textbbox((0, 0), cue, font=cue_f)
    nth = nbb[3] - nbb[1]
    cth = cbb[3] - cbb[1]
    text_block = nth + int(6 * scale) + cth
    bottom_pad = int(22 * scale)
    top_pad = int(18 * scale)
    # Place token above the text reserve
    avail_h = ch - top_pad - text_block - bottom_pad - int(10 * scale)
    if token.height > avail_h:
        sc = avail_h / token.height
        token = token.resize(
            (max(1, int(token.width * sc)), max(1, int(token.height * sc))),
            Image.Resampling.LANCZOS,
        )
    tx = ox + (cw - token.width) // 2
    ty = oy + top_pad + max(0, (avail_h - token.height) // 2)
    card.alpha_composite(token, (tx, ty))

    # Name + family cue UNDER portrait (never over body)
    dd = ImageDraw.Draw(card)
    ntw = nbb[2] - nbb[0]
    name_y = ty + token.height + int(4 * scale)
    # Clamp into card bottom reserve if needed
    max_name_y = oy + ch - bottom_pad - text_block
    name_y = min(name_y, max_name_y)
    dd.text(
        (ox + (cw - ntw) // 2, name_y),
        name,
        font=name_f,
        fill=CHARCOAL,
    )
    ctw = cbb[2] - cbb[0]
    dd.text(
        (ox + (cw - ctw) // 2, name_y + nth + int(6 * scale)),
        cue,
        font=cue_f,
        fill=MUTED_SOFT,
    )
    return card


def draw_buttons(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    by = int(H * BTN_Y_FRAC)
    gap = 28
    total = BTN_W * 2 + gap
    x0 = (W - total) // 2
    btn_f = fnt(FONT_BOLD, 22)

    for i, lab in enumerate(("Back", "Confirm")):
        bx = x0 + i * (BTN_W + gap)
        # charcoal outline
        d.rounded_rectangle(
            [bx - 4, by - 4, bx + BTN_W + 4, by + BTN_H + 4],
            radius=BTN_H // 2 + 4,
            fill=CHARCOAL,
        )
        d.rounded_rectangle(
            [bx, by, bx + BTN_W, by + BTN_H],
            radius=BTN_H // 2,
            fill=CREAM_BTN,
        )
        bb = d.textbbox((0, 0), lab, font=btn_f)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
        d.text(
            (bx + (BTN_W - tw) // 2, by + (BTN_H - th) // 2 - 2),
            lab,
            font=btn_f,
            fill=CHARCOAL,
        )


def draw_version(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    ver_f = fnt(FONT_REG, 13)
    tag = "v0.playtest-1"
    bb = d.textbbox((0, 0), tag, font=ver_f)
    tw = bb[2] - bb[0]
    d.text((W - tw - 18, H - 28), tag, font=ver_f, fill=MUTED)


def compose_mock(helpers) -> Image.Image:
    scenic = build_scenic(darken_card_band=True)
    draw_header(scenic)

    starters = [
        ("sproutling", "Sproutling", "Leaf", False),
        ("sparkpup", "Sparkpup", "Ember", True),   # selected (middle)
        ("cottonwisp", "Cottonwisp", "Puff", False),
    ]
    cards = [make_card(helpers, k, n, c, sel) for k, n, c, sel in starters]

    # Equal spacing, centered horizontal row; vertical center in card band
    total_w = sum(c.width for c in cards) + CARD_GAP * (len(cards) - 1)
    # Use logical card widths for spacing (glow pads included in image)
    # Recompute with nominal CARD_W for equal gaps between cream faces
    # Place by centers
    centers_x = []
    row_w = CARD_W * 3 + CARD_GAP * 2
    # Account for selected scale — keep equal visual gaps between card faces
    # Simpler: place three slots at equal centers using avg card face width
    face_ws = [
        int(CARD_W * (SELECTED_SCALE if sel else 1.0))
        for *_, sel in starters
    ]
    row_w = sum(face_ws) + CARD_GAP * 2
    x = (W - row_w) // 2
    xs = []
    for fw in face_ws:
        xs.append(x)
        x += fw + CARD_GAP

    cy = int(H * CARD_CENTER_Y_FRAC)
    for card, x_face, fw in zip(cards, xs, face_ws):
        # card image includes glow pad; center the cream face on the slot
        # cream face starts at offset 20 inside card image
        face_ox = 20
        paste_x = x_face - face_ox + (fw - (card.width - 40)) // 2
        # vertical: center cream face
        face_h = int(CARD_H * (SELECTED_SCALE if card is cards[1] else 1.0))
        paste_y = cy - face_h // 2 - 20
        scenic.alpha_composite(card, (paste_x, paste_y))

    draw_buttons(scenic)
    draw_version(scenic)
    return scenic


def export_isolated_cards(helpers) -> list[Path]:
    paths = []
    specs = [
        ("sproutling", "Sproutling", "Leaf", False, "card-sproutling.png"),
        ("sparkpup", "Sparkpup", "Ember", True, "card-sparkpup.png"),
        ("cottonwisp", "Cottonwisp", "Puff", False, "card-cottonwisp.png"),
    ]
    for kind, name, cue, sel, fname in specs:
        card = make_card(helpers, kind, name, cue, selected=sel)
        # Crop tight to content (trim transparent)
        bbox = card.getbbox()
        if bbox:
            card = card.crop(bbox)
        path = OUT / fname
        card.save(path)
        paths.append(path)
        print(f"  card → {path}")
    return paths


def export_review_sheet(mock: Image.Image, cards: list[Image.Image]) -> Path:
    """20-starter-select-lock.png — A full mock | B three cards close-up."""
    margin, gap, header = 28, 22, 96
    thumb_w = 640
    thumb_h = int(thumb_w * H / W)
    # Panel B: three cards side by side
    card_thumbs = []
    target_h = thumb_h - 20
    for c in cards:
        sc = target_h / c.height
        tw = max(1, int(c.width * sc))
        th = max(1, int(c.height * sc))
        card_thumbs.append(c.resize((tw, th), Image.Resampling.LANCZOS))
    b_w = sum(t.width for t in card_thumbs) + 16 * (len(card_thumbs) - 1) + 40
    panel_b_w = max(b_w, 520)
    sheet_w = margin * 2 + thumb_w + gap + panel_b_w
    sheet_h = header + thumb_h + 78
    sheet = Image.new("RGBA", (sheet_w, sheet_h), CREAM)
    d = ImageDraw.Draw(sheet)
    title_f = fnt(FONT_BOLD, 22)
    panel_f = fnt(FONT_BOLD, 14)
    small_f = fnt(FONT_REG, 12)
    d.text(
        (margin, 16),
        "20 — Starter select lock (pick screen · pack-stack continuity)",
        font=title_f,
        fill=CHARCOAL,
    )
    d.text(
        (margin, 48),
        "Header ~10% · cards mid band ~32–55% · Back/Confirm ~74% · cream cards + charcoal · selected = middle (scale+glow) · scenic = title layers",
        font=small_f,
        fill=MUTED,
    )
    d.text(
        (margin, 68),
        "James locking selection menu 2026-09-24. Style lock closed. No new creatures.",
        font=small_f,
        fill=MUTED,
    )

    # Panel A
    ax, ay = margin, header
    thumb = mock.resize((thumb_w, thumb_h), Image.Resampling.LANCZOS)
    d.rounded_rectangle(
        [ax - 4, ay - 4, ax + thumb_w + 4, ay + thumb_h + 4],
        radius=10,
        outline=CHARCOAL,
        width=3,
        fill=CREAM_BTN,
    )
    sheet.alpha_composite(thumb.convert("RGBA"), (ax, ay))
    d.text(
        (ax, ay + thumb_h + 12),
        "A  Full mock — Pick your starter (Sparkpup selected)",
        font=panel_f,
        fill=CHARCOAL,
    )

    # Panel B
    bx = margin + thumb_w + gap
    by = header
    d.rounded_rectangle(
        [bx - 4, by - 4, bx + panel_b_w + 4, by + thumb_h + 4],
        radius=10,
        outline=CHARCOAL,
        width=3,
        fill=CREAM_BTN,
    )
    # cream panel fill already; place cards centered
    row_w = sum(t.width for t in card_thumbs) + 16 * (len(card_thumbs) - 1)
    cx = bx + (panel_b_w - row_w) // 2
    cy = by + (thumb_h - card_thumbs[0].height) // 2
    for t in card_thumbs:
        sheet.alpha_composite(t.convert("RGBA"), (cx, cy))
        cx += t.width + 16
    d.text(
        (bx, by + thumb_h + 12),
        "B  Cards close-up — Sproutling · Sparkpup (sel) · Cottonwisp",
        font=panel_f,
        fill=CHARCOAL,
    )

    sheet.save(SHEET20)
    print(f"  sheet → {SHEET20}")
    return SHEET20


def write_recipe() -> Path:
    path = OUT / "PROTO_STARTER_SELECT.md"
    path.write_text(
        """# Starter select — Proto recipe (lock)

**Cut:** selection menu / starter pick screen (playtest-1).  
**Canvas:** 1280×800  
**Quality bar:** same professional bar as title (Stardew / Terraria / Great Hatch readability).  
**James locking selection menu 2026-09-24.** Title pack-stack A stays locked — do not reopen title layout.

Style lock closed — flat pastel capsules, two-dot faces, thick charcoal `#2C2A28`, one family mark.  
Drawn from `title-menu-v1/_gen_title_menu_v1_2.py` helpers (`draw_sproutling` / `draw_sparkpup` / `draw_cottonwisp` / `make_starter_token`). No new creatures. No Hatch-dex list. No shop/prep/fight art.

---

## 1) Z-order (back → front)

```
sky
  → clouds              (drift — same as title)
  → far                 (parallax slow)
  → mid
  → near
  → paper soft-light    (optional ~10%, static)
  → card-band grade     (optional soft darker wash under cards; Art mock only / Proto modulate OK)
  → header (“Pick your starter”)
  → pick cards ×3       (selected on top of idle if overlap)
  → buttons (Back / Confirm)
  → version
```

Never draw scenery above cream cards or pills. Skip CraftPix flowers under card band.

---

## 2) Files to load

Base folder: `art/style-lock/starter-select-v1/`

| Layer / asset | File | Notes |
|---------------|------|-------|
| Sky | `../title-menu-v1/composite/layers/sky.png` | **Reuse title** — edermunizz warm cream grade |
| Clouds | `../title-menu-v1/composite/layers/clouds.png` | **Reuse** — drift this |
| Far / Mid / Near | `../title-menu-v1/composite/layers/{far,mid,near}.png` | **Reuse** VISTA mint/sage |
| Paper (opt) | `../title-menu-v1/composite/layers/paper-softlight.png` | **Reuse** |
| Full mock | `mock-starter-select.png` | lock reference |
| Isolated cards | `card-sproutling.png`, `card-sparkpup.png`, `card-cottonwisp.png` | Proto / UI |
| Compose script | `_compose_select.py` | reusable Art rebuild |
| Review sheet | `../20-starter-select-lock.png` | A full mock | B cards close-up |

**No select-specific scenic grades exported** — mock darkens the card band in-compose only. Proto may modulate a soft ColorRect (~α 0.10–0.14 charcoal) under the card row if cream needs more pop; keep center readable.

---

## 3) Layout lock

| Element | Placement |
|---------|-----------|
| Header | Centered, **~10%** from top (band **8–12%**). Soft rounded bold; sage fill `#5A8F6A` + charcoal outline `#2C2A28` (title wordmark language). Text: **Pick your starter** |
| Cards | Three cream pick cards, centered horizontal row; vertical mid band **~32–55%** (centers ≈ **43.5%**). Equal spacing (~36 px gap). |
| Card chrome | Rounded rect, thick charcoal outline (~4 px idle / ~7 px selected), fill `#FAF6EE`, generous padding. Portrait body height **~140 px** (~120–160). Name under portrait; optional family cue (Leaf / Ember / Puff) muted charcoal, small. |
| Selected | **Middle** card (Sparkpup) in mock — thicker outline + soft cream glow ring + slight scale **~1.045**. Label “selected” in recipe only (no noisy on-card badge). |
| Buttons | Cream pills **Back** (left/secondary) + **Confirm** (right/primary), **~260×48** (240–280×48 OK), mid-lower **~74%** from top (band **70–78%**). Same pill language as title. |
| Version | Tiny BR: `v0.playtest-1` |

Order L→R: **Sproutling** (mint + tall leaf) · **Sparkpup** (peach/coral + soft top flame) · **Cottonwisp** (powder blue cloud bumps / cloud-body).

If hills fight readability, lift cards into calm sky / upper mid — cream cards must win contrast. Mock uses soft card-band grade + title layers.

---

## 4) Motion

| What | Amount | Timing |
|------|--------|--------|
| Cloud drift | **8–16 px** horizontal | **12–20 s** loop (same as title if scenic shared) |
| Far / mid hills | optional parallax | slower than clouds (title recipe) |
| **Selected starter idle** | subtle breathe **≤ ±4%** squash/stretch | from Assets `starters-v1.1-subtle` once Proto wires; shared clock; pivot bottom-center (`motion/MOTION_BRIEF_v1.md`) |
| Unselected starters | static OK, or same idle quieter | keep one clock if both idle |
| Hover card | scale **1.00 → 1.03** | soft ease ~100–120 ms |
| Confirm hover | scale **1.03** | soft ease ~100–120 ms (title button language) |
| Back hover | scale **1.03** | same |
| Header / version | static | — |

Mock is **static**. Menu drift = same slow clouds as title. No bob on buttons. No idle bounce on chrome.

---

## 5) Attribution **required** if scenic stack ships

| Asset | Licence | Credit |
|-------|---------|--------|
| **edermunizz** sky | Commercial free; **MUST credit** | edermunizz — Simple Pastel Backgrounds |
| VISTA downs (najjar320) | **CC0** | Optional: najjar320 |
| Garzett pixel clouds | Commercial free | Optional / appreciated: GarzettDev |
| Paper albedo | **CC0** | — |

Same stack as title — credit **edermunizz** if sky reused. CraftPix flowers **not** used under card band.

---

## 6) Checklist

- [ ] Load title `composite/layers/` sky → clouds → far → mid → near (+ optional paper)
- [ ] Header “Pick your starter” ~8–12% from top (sage + charcoal)
- [ ] Three cream cards mid band ~32–55%; portraits from style-lock helpers
- [ ] One selected state (thicker outline / glow / slight scale) — no noisy badge
- [ ] Back + Confirm cream pills ~70–78% from top; `v0.playtest-1` BR
- [ ] Selected idle ≤±4% from `starters-v1.1-subtle`; hover card 1.03; Confirm hover 1.03
- [ ] Cloud drift same as title; credit **edermunizz**
- [ ] No new creatures; no Hatch-dex; title layout stays locked

*End PROTO_STARTER_SELECT.*
""",
        encoding="utf-8",
    )
    print(f"  recipe → {path}")
    return path


def update_style_lock() -> None:
    path = STYLE / "STYLE_LOCK.md"
    text = path.read_text(encoding="utf-8")
    note = (
        "20. `20-starter-select-lock.png` — starter pick screen lock "
        "(selection menu; James 2026-09-24)\n"
    )
    # Add to deliverables list if missing
    if "20-starter-select-lock" not in text:
        needle = "19. `19-title-pack-composite.png` — Assets pack-stack title composite (+ painted alt)  \n"
        if needle in text:
            text = text.replace(
                needle,
                needle + note,
            )
        else:
            # fallback append near deliverables end
            text = text.replace(
                "## Archive\n",
                note + "\n## Archive\n",
            )

    section = """

### Starter select lock (`starter-select-v1/`, sheet 20)

James locking **selection menu** 2026-09-24 (title pack-stack A already locked — do not reopen title layout).

- Folder: `starter-select-v1/` — `_compose_select.py`, `mock-starter-select.png`, `card-{sproutling,sparkpup,cottonwisp}.png`, `PROTO_STARTER_SELECT.md`
- Sheet: `20-starter-select-lock.png` — A full mock | B three cards close-up
- Scenic: **reuse** title `title-menu-v1/composite/layers/` (sky/clouds/far/mid/near/paper); optional soft darker grade under cards in mock only — no muddy washes; no CraftPix flowers
- Layout 1280×800: header “Pick your starter” ~**10%** (8–12%); three cream pick cards mid band ~**32–55%**; Back + Confirm cream pills ~**74%** (70–78%); `v0.playtest-1` BR
- Starters from locked helpers: Sproutling mint+leaf · Sparkpup peach+flame · Cottonwisp powder cloud bumps — flat, two-dot, charcoal `#2C2A28`
- Selected (mock = middle Sparkpup): thicker outline + soft cream glow + slight scale; no noisy badge
- Motion: selected idle ≤±4% (`starters-v1.1-subtle`); hover card 1.03; Confirm hover 1.03; cloud drift same as title
- Caption: “Selection menu locked. Title A untouched. Style lock closed. In-run deferred.”

"""
    if "### Starter select lock" not in text:
        # Insert before Subtle motion section if present
        if "## Subtle motion" in text:
            text = text.replace("## Subtle motion", section + "## Subtle motion")
        else:
            text = text.rstrip() + "\n" + section
    path.write_text(text, encoding="utf-8")
    print(f"  STYLE_LOCK updated → {path}")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    print("Loading title style-lock helpers…")
    helpers = load_title_helpers()

    print("Composing starter-select mock…")
    mock = compose_mock(helpers)
    mock_path = OUT / "mock-starter-select.png"
    mock.save(mock_path)
    print(f"  mock → {mock_path}")

    print("Exporting isolated cards…")
    card_paths = export_isolated_cards(helpers)
    cards = [Image.open(p).convert("RGBA") for p in card_paths]

    print("Review sheet 20…")
    export_review_sheet(mock, cards)

    print("Writing Proto recipe…")
    write_recipe()

    print("Updating STYLE_LOCK.md…")
    update_style_lock()

    print("done")
    print(
        f"layout: header_y≈{int(H*HEADER_Y_FRAC)} ({HEADER_Y_FRAC:.0%}) | "
        f"card_band={CARD_BAND_TOP:.0%}–{CARD_BAND_BOT:.0%} (cy≈{int(H*CARD_CENTER_Y_FRAC)}) | "
        f"btn_y≈{int(H*BTN_Y_FRAC)} ({BTN_Y_FRAC:.0%})"
    )


if __name__ == "__main__":
    main()
