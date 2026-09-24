extends Control

# Sheet 11. Soft sage hills and a ground plane. No illustrated scenery.

const CREAM := Color("f6f1e7")
const WASH := Color("e4eedc")
const HILL_FAR := Color("d5e6cc")
const HILL_MID := Color("c9dcb8")
const HILL_NEAR := Color("b7d0a4")
const GROUND := Color("87a873")
const GRASS := Color("6e945c")
const CELL := Color("e7f0de")

# Pixels from the bottom edge to the ground stripe. Negative draws no stripe.
var ground_from_bottom: float = 18.0
# "fill" covers this control. "lower" is only the bottom band of a page.
var wash_mode: String = "fill"
# Hills stay behind Bench, Board, shop, path chrome, and labels.
const Z_BEHIND := -8


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	z_index = Z_BEHIND


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 4.0 or h < 4.0:
		return
	if wash_mode == "lower":
		_hills(Rect2(0.0, h * 0.46, w, h * 0.54))
		return
	draw_rect(Rect2(Vector2.ZERO, size), WASH)
	_hills(Rect2(Vector2.ZERO, size))
	if ground_from_bottom < 0.0:
		return
	var gy := h - ground_from_bottom - 6.0
	if gy < 6.0:
		gy = h * 0.62
	var x := 8.0
	while x < w - 4.0:
		draw_line(Vector2(x, gy - 7.0), Vector2(x + 6.0, gy - 1.0), GRASS, 1.5, true)
		x += 15.0
	draw_rect(Rect2(0.0, gy, w, 6.0), GROUND)


func _hills(area: Rect2) -> void:
	var w := size.x
	var top := area.position.y
	var depth := area.size.y
	_hill(w * 0.16, top + depth * 0.58, w * 0.34, depth * 0.70, HILL_FAR)
	_hill(w * 0.50, top + depth * 0.66, w * 0.42, depth * 0.76, HILL_MID)
	_hill(w * 0.84, top + depth * 0.60, w * 0.36, depth * 0.68, HILL_FAR)
	_hill(w * 0.32, top + depth * 0.90, w * 0.40, depth * 0.46, HILL_NEAR)
	_hill(w * 0.72, top + depth * 0.94, w * 0.46, depth * 0.40, HILL_MID)


func _hill(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	if rx < 2.0 or ry < 2.0:
		return
	var pts := PackedVector2Array()
	var steps := 28
	for i in steps:
		var a := TAU * float(i) / float(steps)
		pts.append(Vector2(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(pts, color)
