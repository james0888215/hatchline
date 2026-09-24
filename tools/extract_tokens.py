#!/usr/bin/env python3
"""Cut family+tier capsule tokens out of the locked silhouette sheets.

Source sheets live in art/style-lock/. Outputs land in art/tokens/.
Beast (meadow enemies with no Leaf / Ember / Puff mark) is the plain
rose pill from the combat mock — two dots, no family mark.
"""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
LOCK = ROOT / "art" / "style-lock"
OUT = ROOT / "art" / "tokens"

# Tight boxes around each critter on the 1280×720 sheets, labels excluded.
SHEET_BOXES = {
    "02-silhouettes-leaf.png": [
        ("leaf_t1", (114, 331, 397, 501)),
        ("leaf_t2", (496, 300, 779, 501)),
        ("leaf_t3", (891, 251, 1158, 501)),
    ],
    "03-silhouettes-ember.png": [
        ("ember_t1", (91, 299, 356, 546)),
        ("ember_t2", (433, 229, 746, 548)),
        ("ember_t3", (814, 170, 1189, 550)),
    ],
    "04-silhouettes-puff.png": [
        ("puff_t1", (106, 363, 379, 543)),
        ("puff_t2", (473, 367, 793, 545)),
        ("puff_t3", (895, 348, 1157, 549)),
    ],
}

# Enemy pills on the combat mock. Same silhouette; either crop is fine.
BEAST_BOX = ("05-combat-mock.png", "beast_t1", (1068, 168, 1210, 270))

# Clarity sheet heroes. Boxes exclude captions. Interior white (the Z badge,
# cream horns) is kept; only paper connected to the crop edge is dropped.
CLARITY_BOXES = [
    ("mite_meadow", (222, 154, 480, 263)),
    ("mite_tired", (772, 182, 1020, 263)),
    ("puff_cloudbud", (206, 493, 502, 566)),
    ("puff_cumulon", (768, 458, 1012, 569)),
]

# Elite / add / Driftkin heroes on sheet 07. Captions and the tiny grids stay out.
ELITE_BOXES = [
    ("beast_warden", (124, 134, 322, 248)),
    ("beast_bramble", (530, 150, 730, 248)),
    ("beast_sprig", (940, 148, 1100, 248)),
    ("puff_driftkin", (748, 458, 1010, 556)),
]

# Sheet 08 heroes. Captions and the 3-copy grids stay out.
SHOP_T1_BOXES = [
    ("leaf_sproutling", (270, 74, 402, 184)),
    ("leaf_dewcap", (590, 96, 710, 184)),
    ("leaf_budmite", (926, 80, 1030, 188)),
    ("ember_sparkpup", (270, 298, 402, 398)),
    ("ember_wicklet", (618, 286, 684, 402)),
    ("ember_cinderkit", (908, 318, 1028, 400)),
    ("puff_cottonwisp", (266, 508, 408, 590)),
    ("puff_nimbusling", (578, 526, 726, 590)),
    ("puff_fluffball", (912, 502, 1036, 622)),
]

# One center mark from each sheet 09 panel. Cloudbud, Driftkin, and Cumulon
# already have locked crops from sheets 06 and 07.
SHOP_LINE_BOXES = [
    ("leaf_thornbud", (116, 218, 172, 263)),
    ("leaf_elderthorn", (363, 216, 416, 263)),
    ("leaf_canopykin", (606, 220, 663, 262)),
    ("leaf_mossguard", (851, 222, 908, 263)),
    ("leaf_grovewarden", (1099, 222, 1153, 264)),
    ("ember_foxfire", (117, 413, 172, 449)),
    ("ember_infernox", (363, 407, 416, 453)),
    ("ember_emberfox", (606, 411, 667, 452)),
    ("ember_pyrelord", (851, 412, 908, 452)),
    ("ember_blazetail", (1096, 412, 1155, 453)),
    ("puff_stormpillow", (363, 594, 413, 635)),
    ("puff_skyloom", (852, 595, 904, 637)),
]


def key_paper(rgba: np.ndarray) -> np.ndarray:
    """Drop the paper background. Body fills stay (mint, peach, cream, rose)."""
    rgb = rgba[:, :, :3].astype(np.float32)
    lum = rgb.mean(axis=2)
    sat = rgb.max(axis=2) - rgb.min(axis=2)
    # Sheet white and the mock's cream paper are bright and nearly neutral.
    paper = (lum > 214.0) & (sat < 26.0) & (rgb[:, :, 2] > 185.0)
    out = rgba.copy()
    out[:, :, 3] = np.where(paper, 0, 255).astype(np.uint8)
    return out


def trim(rgba: np.ndarray, pad: int = 4) -> np.ndarray:
    alpha = rgba[:, :, 3]
    ys, xs = np.where(alpha > 0)
    if len(xs) == 0:
        raise SystemExit("empty crop")
    y0 = max(0, int(ys.min()) - pad)
    y1 = min(rgba.shape[0], int(ys.max()) + 1 + pad)
    x0 = max(0, int(xs.min()) - pad)
    x1 = min(rgba.shape[1], int(xs.max()) + 1 + pad)
    return rgba[y0:y1, x0:x1]


def cut(path: Path, box: tuple) -> Image.Image:
	im = Image.open(path).convert("RGBA")
	x0, y0, x1, y1 = box
	crop = np.array(im.crop((x0, y0, x1 + 1, y1 + 1)))
	return Image.fromarray(trim(key_paper(crop)))


def _paper_like(rgb: np.ndarray) -> np.ndarray:
	lum = rgb.mean(axis=2)
	sat = rgb.max(axis=2) - rgb.min(axis=2)
	return (lum > 200.0) & (sat < 22.0)


def flood_key(rgba: np.ndarray) -> np.ndarray:
	"""Remove sheet paper that touches the crop edge. Closed interiors stay."""
	paper = _paper_like(rgba[:, :, :3].astype(np.float32))
	h, w = paper.shape
	seen = np.zeros((h, w), dtype=bool)
	stack = []
	for x in range(w):
		stack.append((0, x))
		stack.append((h - 1, x))
	for y in range(h):
		stack.append((y, 0))
		stack.append((y, w - 1))
	while stack:
		y, x = stack.pop()
		if y < 0 or x < 0 or y >= h or x >= w or seen[y, x] or not paper[y, x]:
			continue
		seen[y, x] = True
		stack.append((y - 1, x))
		stack.append((y + 1, x))
		stack.append((y, x - 1))
		stack.append((y, x + 1))
	out = rgba.copy()
	out[:, :, 3] = np.where(seen, 0, 255).astype(np.uint8)
	return out


def cut_clarity(path: Path, box: tuple) -> Image.Image:
	im = Image.open(path).convert("RGBA")
	x0, y0, x1, y1 = box
	crop = np.array(im.crop((x0, y0, x1 + 1, y1 + 1)))
	return Image.fromarray(trim(flood_key(crop)))


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for sheet, items in SHEET_BOXES.items():
        for name, box in items:
            img = cut(LOCK / sheet, box)
            dest = OUT / f"{name}.png"
            img.save(dest)
            print(f"{dest.name} {img.size}")
    sheet, name, box = BEAST_BOX
    img = cut(LOCK / sheet, box)
    dest = OUT / f"{name}.png"
    img.save(dest)
    print(f"{dest.name} {img.size}")
    clarity = LOCK / "06-token-clarity.png"
    for name, box in CLARITY_BOXES:
        img = cut_clarity(clarity, box)
        dest = OUT / f"{name}.png"
        img.save(dest)
        print(f"{dest.name} {img.size}")
    elites = LOCK / "07-token-clarity-elites.png"
    for name, box in ELITE_BOXES:
        img = cut_clarity(elites, box)
        dest = OUT / f"{name}.png"
        img.save(dest)
        print(f"{dest.name} {img.size}")
    shop_t1 = LOCK / "08-shop-line-clarity-t1.png"
    for name, box in SHOP_T1_BOXES:
        img = cut_clarity(shop_t1, box)
        dest = OUT / f"{name}.png"
        img.save(dest)
        print(f"{dest.name} {img.size}")
    shop_lines = LOCK / "09-shop-line-clarity-t2t3.png"
    for name, box in SHOP_LINE_BOXES:
        img = cut_clarity(shop_lines, box)
        dest = OUT / f"{name}.png"
        img.save(dest)
        print(f"{dest.name} {img.size}")


if __name__ == "__main__":
    main()
