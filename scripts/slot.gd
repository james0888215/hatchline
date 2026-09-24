extends Panel

const TOKENS := preload("res://scripts/token.gd")

var zone: String = "board"
var slot_index: int = -1
var unit_uid: int = -1
var preview_family: String = "leaf"
var preview_tier: int = 1
var preview_mark: String = ""
var preview_role: String = ""
var _sell_mode := 0


func _ready() -> void:
	if zone == "sell":
		set_process(true)


func _process(_delta: float) -> void:
	if zone != "sell":
		return
	var dragging := get_viewport().gui_is_dragging()
	var over := dragging and get_global_rect().has_point(get_global_mouse_position())
	var mode := 2 if over else (1 if dragging else 0)
	if mode == _sell_mode:
		return
	_sell_mode = mode
	var hint := find_child("SellHint", true, false)
	if hint is Label:
		hint.text = "Drop to sell" if mode > 0 else "Drag a critter here to sell"
	if mode == 2:
		modulate = Color(1, 0.78, 0.74)
	elif mode == 1:
		modulate = Color(1, 0.92, 0.88)
	else:
		modulate = Color.WHITE


func _get_drag_data(_at: Vector2) -> Variant:
	if unit_uid < 0:
		return null
	var preview := TOKENS.present(preview_family, preview_tier, 72.0, false, preview_mark, preview_role)
	set_drag_preview(preview)
	return {"uid": unit_uid}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and int(data.get("uid", -1)) >= 0


func _drop_data(_at: Vector2, data: Variant) -> void:
	Game.handle_drop(zone, slot_index, data)
