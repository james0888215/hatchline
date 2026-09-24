extends RefCounted

# Flat capsule tokens cut from the locked silhouette sheets.
# One texture per family + tier. Named clarity crops override a shared face.

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
		"warden":
			return "warden"
		"bramble":
			return "bramble"
		"sprig":
			return "sprig"
		_:
			return ""


static func species_mark(family: String, line: String, tier: int) -> String:
	if family == "puff" and tier == 2:
		match line:
			"cotton":
				return "cloudbud"
			"fluff":
				return "cumulon"
			"nimbus":
				return "driftkin"
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
		"warden":
			file = "beast_warden"
		"bramble":
			file = "beast_bramble"
		"sprig":
			file = "beast_sprig"
		"driftkin":
			file = "puff_driftkin"
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


static func present(family: String, tier: int, max_h: float, boss: bool = false, mark: String = "", role: String = "") -> Control:
	var token := make(family, tier, max_h, boss, mark, role)
	token.name = "Capsule"
	var box := Control.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sz := token.custom_minimum_size
	box.custom_minimum_size = sz
	box.size = sz
	token.position = Vector2.ZERO
	box.add_child(token)
	if role == "melee" or role == "ranged":
		var badge := Control.new()
		badge.name = "RoleBadge"
		badge.set_script(preload("res://scripts/mark.gd"))
		badge.set("kind", role)
		var s := clampf(sz.y * 0.36, 14.0, 28.0)
		badge.custom_minimum_size = Vector2(s, s)
		badge.size = Vector2(s, s)
		badge.position = Vector2(sz.x - s * 0.78, -s * 0.12)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(badge)
	return box


static func make(family: String, tier: int, max_h: float, boss: bool = false, mark: String = "", role: String = "") -> Control:
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
	# Sheet 07: the crown reads taller, and the sprig's size is the telegraph.
	if mark == "warden":
		h *= 1.16
	elif mark == "sprig":
		h *= 0.68
	var w := h * aspect
	if role == "melee":
		w *= 1.16
		h *= 0.9
	elif role == "ranged":
		w *= 0.84
		h *= 1.14
	var max_w := max_h * 1.9
	if w > max_w:
		w = max_w
		h = w / aspect
	rect.custom_minimum_size = Vector2(w, h)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect
