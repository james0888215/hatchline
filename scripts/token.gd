extends RefCounted

# Flat capsule tokens cut from the locked silhouette sheets.
# One texture per family + tier. Named clarity crops override a shared face.
# TODO(Art): later wild traits (bramble, warden, sprig) still use the plain
# rose pill until a clarity sheet gives each a silhouette or large badge.

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


static func enemy_mark(def_id: String) -> String:
	match def_id:
		"mite":
			return "meadow"
		"mite_small":
			return "tired"
		_:
			return ""


static func species_mark(family: String, line: String, tier: int) -> String:
	if family == "puff" and tier == 2:
		match line:
			"cotton":
				return "cloudbud"
			"fluff":
				return "cumulon"
	return ""


static func clarity_texture(mark: String) -> Texture2D:
	var file := ""
	match mark:
		"meadow":
			file = "mite_meadow"
		"tired":
			file = "mite_tired"
		"cloudbud":
			file = "puff_cloudbud"
		"cumulon":
			file = "puff_cumulon"
		_:
			return null
	var path := "res://art/tokens/%s.png" % file
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D


static func unit_mark(unit) -> String:
	var from_def := enemy_mark(str(unit.get("def_id", "")))
	if from_def != "":
		return from_def
	return species_mark(str(unit.get("family", "")), str(unit.get("line", "")), int(unit.get("tier", 1)))


static func make(family: String, tier: int, max_h: float, boss: bool = false, mark: String = "") -> Control:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tex := clarity_texture(mark)
	if tex == null:
		tex = texture(family, tier)
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
