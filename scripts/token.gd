extends RefCounted

# Flat capsule tokens cut from the locked silhouette sheets.
# One texture per family + tier. Meadow beasts use the plain rose pill.


static func texture(family: String, tier: int) -> Texture2D:
	var fam := family
	var t := tier
	if fam != "leaf" and fam != "ember" and fam != "puff":
		fam = "beast"
		t = 1
	t = clampi(t, 1, 3)
	var path := "res://art/tokens/%s_t%d.png" % [fam, t]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func make(family: String, tier: int, max_h: float, boss: bool = false) -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tex := texture(family, tier)
	var aspect := 1.35
	if tex != null:
		rect.texture = tex
		aspect = float(tex.get_width()) / float(maxi(1, tex.get_height()))
	var known := family == "leaf" or family == "ember" or family == "puff"
	var h := max_h
	if boss:
		h = max_h
	elif not known:
		h = max_h * 0.82
	elif tier <= 1:
		h = max_h * 0.74
	elif tier == 2:
		h = max_h * 0.88
	var w := h * aspect
	var max_w := max_h * 1.9
	if w > max_w:
		w = max_w
		h = w / aspect
	rect.custom_minimum_size = Vector2(w, h)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect
