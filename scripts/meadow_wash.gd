extends Control

# Sheet 11 place intent, skinned from Hatch Art meadow-wash-v2.
# Proto owns z-order only. Opacity, hill shape, gutters, and path tokens
# come from ART_WASH_DIR. Do not redraw the wash or recolor creatures.

const ART_WASH_DIR := "res://art/style-lock/meadow-wash-v2"
const BATTLE_UNDERLAY := preload("res://art/style-lock/meadow-wash-v2/wash-underlay-battle-1280x800.png")
const MENU_UNDERLAY := preload("res://art/style-lock/meadow-wash-v2/wash-underlay-menu-1280x800.png")
const PILL_TEX := preload("res://art/style-lock/meadow-wash-v2/token-path-label-pill.png")
const ACTIVE_TEX := preload("res://art/style-lock/meadow-wash-v2/token-active-node-solid.png")
const RING_TEX := preload("res://art/style-lock/meadow-wash-v2/token-inactive-node-ring.png")

# Cream pill only. The sheet caption sits above this region.
const PILL_REGION := Rect2(24, 28, 278, 45)
# Sage disc + charcoal ring. The coral twin on the same sheet stays unused.
const ACTIVE_REGION := Rect2(36, 32, 73, 73)

const INK_ACTIVE := Color("2C2A28")
const INK_QUIET := Color("5C5854")

# Slot paper. Not part of the wash.
const CELL := Color("e7f0de")

# Behind Bench, Board, shop, path chrome, menu chrome, and labels.
# The cream paper sits one step further back so this underlay can show.
const Z_BEHIND := -8

# Baked PNG peak is 63/255 (~0.25), already inside the recipe band
# 0.20–0.28. A second multiply would drop the wash under the gutters,
# and a ColorRect on top would stack a second wash.
const UNDERLAY_MODULATE := Color(1, 1, 1, 1)

# "menu", "battle", or "" (nest keeps z-order and paints nothing).
var sheet: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	z_index = Z_BEHIND
	var tex: Texture2D = _sheet_texture()
	if tex == null:
		return
	var rect := TextureRect.new()
	rect.name = "WashUnderlay"
	rect.texture = tex
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.modulate = UNDERLAY_MODULATE
	add_child(rect)


func _sheet_texture() -> Texture2D:
	if sheet == "menu":
		return MENU_UNDERLAY
	if sheet == "battle":
		return BATTLE_UNDERLAY
	return null
