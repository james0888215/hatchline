extends Panel

var zone: String = "board"
var slot_index: int = -1
var unit_uid: int = -1
var preview_color: Color = Color("f0a15a")


func _get_drag_data(_at: Vector2) -> Variant:
	if unit_uid < 0:
		return null
	var preview := ColorRect.new()
	preview.custom_minimum_size = Vector2(72, 72)
	preview.color = preview_color
	set_drag_preview(preview)
	return {"uid": unit_uid}


func _can_drop_data(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and int(data.get("uid", -1)) >= 0


func _drop_data(_at: Vector2, data: Variant) -> void:
	Game.handle_drop(zone, slot_index, data)
