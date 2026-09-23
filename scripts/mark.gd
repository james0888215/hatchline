extends Control

# HUD glyphs only. Critter faces come from the cut tokens, not drawn marks.
# TODO(Art): bramble, warden, and sprig still share the plain rose pill until
# a clarity sheet gives each a silhouette or a large badge.

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

