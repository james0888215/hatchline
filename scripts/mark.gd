extends Control

# HUD glyphs only. Critter faces come from the cut tokens, not drawn marks.

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
		"melee":
			_plate()
			_melee()
		"ranged":
			_plate()
			_ranged()


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


func _plate() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.48
	draw_circle(c, r, Color("fffdf8"))
	draw_arc(c, r * 0.92, 0, TAU, 20, Color("243042"), 1.5, true)


func _melee() -> void:
	var fur := Color("e7b56a")
	var ink := Color("243042")
	var toe := minf(size.x, size.y) * 0.13
	draw_circle(Vector2(size.x * 0.30, size.y * 0.34), toe, fur)
	draw_circle(Vector2(size.x * 0.50, size.y * 0.24), toe, fur)
	draw_circle(Vector2(size.x * 0.70, size.y * 0.34), toe, fur)
	var palm := Vector2(size.x * 0.50, size.y * 0.60)
	var r := minf(size.x, size.y) * 0.22
	draw_circle(palm, r, fur)
	draw_arc(palm, r, 0, TAU, 16, ink, 1.3, true)


func _ranged() -> void:
	var ink := Color("243042")
	var seed := Vector2(size.x * 0.40, size.y * 0.62)
	var r := minf(size.x, size.y) * 0.16
	draw_circle(seed, r, Color("d5e29a"))
	draw_arc(seed, r, 0, TAU, 14, ink, 1.3, true)
	var spark := Vector2(size.x * 0.70, size.y * 0.32)
	draw_line(seed + Vector2(r * 0.4, -r * 0.5), spark, ink, 1.4, true)
	draw_circle(spark, r * 0.7, Color("f6d56b"))


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

