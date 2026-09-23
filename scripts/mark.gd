extends Control

# TODO(Art): swap beast marks for style-lock enemy tokens when those sheets land.
# The rose pill stays the base; these are glance marks only.

var kind: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	match kind:
		"coin":
			_coin()
		"interest":
			_interest()
		"sell":
			_sell()
		"tired":
			_tired()
		"bramble":
			_bramble()
		"warden":
			_warden()
		"sprig":
			_sprig()
		"bud":
			_bud()
		"pile":
			_pile()
		"drift":
			_drift()


func _coin() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.46
	draw_circle(c, r, Color("e2b14a"))
	draw_arc(c, r * 0.96, 0, TAU, 28, Color("243042"), 1.7, true)
	draw_line(c + Vector2(0, -r * 0.46), c + Vector2(0, r * 0.46), Color("8a5a12"), 2.1, true)


func _interest() -> void:
	var ink := Color("243042")
	var u := minf(size.x, size.y)
	var w := maxf(2.2, u * 0.14)
	draw_line(Vector2(size.x * 0.74, size.y * 0.16), Vector2(size.x * 0.26, size.y * 0.84), ink, w, true)
	var dot := u * 0.14
	draw_circle(Vector2(size.x * 0.30, size.y * 0.26), dot, ink)
	draw_circle(Vector2(size.x * 0.70, size.y * 0.74), dot, ink)


func _sell() -> void:
	var w := size.x
	var h := size.y
	var pts := PackedVector2Array([
		Vector2(w * 0.06, h * 0.22),
		Vector2(w * 0.56, h * 0.22),
		Vector2(w * 0.94, h * 0.50),
		Vector2(w * 0.56, h * 0.78),
		Vector2(w * 0.06, h * 0.78),
	])
	draw_colored_polygon(pts, Color("a33b32"))
	draw_circle(Vector2(w * 0.26, h * 0.50), h * 0.10, Color("f6f1e7"))


func _tired() -> void:
	var ink := Color("243042")
	var x := size.x * 0.58
	var y := size.y * 0.10
	var w := size.x * 0.30
	var h := size.y * 0.20
	draw_line(Vector2(x, y), Vector2(x + w, y), ink, 3.2, true)
	draw_line(Vector2(x + w, y), Vector2(x, y + h), ink, 3.2, true)
	draw_line(Vector2(x, y + h), Vector2(x + w, y + h), ink, 3.2, true)
	draw_arc(Vector2(size.x * 0.48, size.y * 0.46), size.y * 0.18, PI * 1.05, TAU * 0.95, 14, ink, 2.6, true)


func _bramble() -> void:
	_thorn(Vector2(size.x * 0.22, size.y * 0.62), minf(size.x, size.y) * 0.16)
	_thorn(Vector2(size.x * 0.30, size.y * 0.78), minf(size.x, size.y) * 0.13)
	_thorn(Vector2(size.x * 0.16, size.y * 0.80), minf(size.x, size.y) * 0.11)


func _thorn(at: Vector2, s: float) -> void:
	var pts := PackedVector2Array([
		at + Vector2(-s, s * 0.42),
		at + Vector2(s, 0),
		at + Vector2(-s * 0.2, -s * 0.55),
	])
	draw_colored_polygon(pts, Color("243042"))


func _warden() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.30
	draw_arc(c, r, 0, TAU, 32, Color("243042"), 3.6, true)
	draw_circle(c, r * 0.28, Color("f6d56b"))


func _sprig() -> void:
	var stem := Vector2(size.x * 0.50, size.y * 0.30)
	draw_line(stem + Vector2(0, size.y * 0.18), stem, Color("2f7d4a"), 3.0, true)
	draw_circle(stem + Vector2(-size.x * 0.06, 0), minf(size.x, size.y) * 0.07, Color("6fae7c"))
	draw_circle(stem + Vector2(size.x * 0.06, -size.y * 0.02), minf(size.x, size.y) * 0.07, Color("6fae7c"))


func _bud() -> void:
	var c := Vector2(size.x * 0.50, size.y * 0.16)
	var r := minf(size.x, size.y) * 0.13
	draw_circle(c, r, Color("6fae7c"))
	draw_arc(c, r, 0, TAU, 18, Color("243042"), 2.0, true)
	var leaf := c + Vector2(r * 0.85, -r * 0.7)
	draw_circle(leaf, r * 0.48, Color("2f7d4a"))


func _pile() -> void:
	var r := minf(size.x, size.y) * 0.15
	var y := size.y * 0.80
	var spots := [
		Vector2(size.x * 0.36, y),
		Vector2(size.x * 0.64, y),
		Vector2(size.x * 0.50, y - r * 0.85),
	]
	for spot in spots:
		draw_circle(spot, r, Color("fffdf8"))
	for spot in spots:
		draw_arc(spot, r, 0, TAU, 16, Color("243042"), 2.0, true)


func _drift() -> void:
	var ink := Color("243042")
	var gust := Color("5d7eae")
	for i in 3:
		var y := size.y * (0.30 + float(i) * 0.16)
		var x := size.x * 0.66
		var reach := size.x * 0.22
		draw_line(Vector2(x, y), Vector2(x + reach, y), gust, 3.4, true)
		draw_line(Vector2(x + reach * 0.62, y - 5.0), Vector2(x + reach, y), ink, 2.2, true)
		draw_line(Vector2(x + reach * 0.62, y + 5.0), Vector2(x + reach, y), ink, 2.2, true)
