extends Control

# Draws the glow that joins orthogonal same-family neighbours.
# `pairs` entries are {a: cell index, b: cell index, color: Color}.

var grid: GridContainer
var pairs: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func arm(next: Array) -> void:
	pairs = next
	set_process(true)
	queue_redraw()


func _process(_delta: float) -> void:
	if grid == null or grid.get_child_count() == 0:
		return
	var first := grid.get_child(0) as Control
	if first == null or first.size.x < 2.0:
		return
	set_process(false)
	queue_redraw()


func _draw() -> void:
	if grid == null:
		return
	for p in pairs:
		var ia := int(p.a)
		var ib := int(p.b)
		if ia < 0 or ib < 0 or ia >= grid.get_child_count() or ib >= grid.get_child_count():
			continue
		var ca := grid.get_child(ia) as Control
		var cb := grid.get_child(ib) as Control
		if ca == null or cb == null or ca.size.x < 2.0 or cb.size.x < 2.0:
			continue
		var color: Color = p.color
		var a := _center(ca)
		var b := _center(cb)
		var dir := b - a
		if dir.length_squared() < 1.0:
			continue
		dir = dir.normalized()
		var along := ca.size.x * 0.5 - 1.0 if absf(dir.x) > absf(dir.y) else ca.size.y * 0.5 - 1.0
		var start := a + dir * along
		var end := b - dir * along
		var soft := Color(color.r, color.g, color.b, 0.42)
		var hard := Color(color.r, color.g, color.b, 0.96)
		draw_line(start, end, soft, 20.0, true)
		draw_line(start, end, hard, 8.0, true)
		draw_circle(start, 7.0, hard)
		draw_circle(end, 7.0, hard)
		_glow_cell(ca, color)
		_glow_cell(cb, color)


func _center(c: Control) -> Vector2:
	return c.global_position + c.size * 0.5 - global_position


func _glow_cell(c: Control, color: Color) -> void:
	var rect := Rect2(c.global_position - global_position, c.size).grow(-2.0)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.9), false, 4.0)
