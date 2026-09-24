extends Panel

const TOKENS := preload("res://scripts/token.gd")

var zone: String = "board"
var slot_index: int = -1
var unit_uid: int = -1
var preview_family: String = "leaf"
var preview_tier: int = 1
var preview_mark: String = ""


func _get_drag_data(_at: Vector2) -> Variant:
	if unit_uid < 0:
		return null
	var preview := TOKENS.make(preview_family, preview_tier, 72.0, false, preview_mark)
	set_drag_preview(preview)
	return {"uid": unit_uid}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and int(data.get("uid", -1)) >= 0


func _drop_data(_at: Vector2, data: Variant) -> void:
	Game.handle_drop(zone, slot_index, data)
