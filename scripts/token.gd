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


const MARK_FILES := {
	"meadow": "mite_meadow",
	"tired": "mite_tired",
	"cloudbud": "puff_cloudbud",
	"cumulon": "puff_cumulon",
	"warden": "beast_warden",
	"bramble": "beast_bramble",
	"sprig": "beast_sprig",
	"driftkin": "puff_driftkin",
	"sproutling": "leaf_sproutling",
	"dewcap": "leaf_dewcap",
	"budmite": "leaf_budmite",
	"thornbud": "leaf_thornbud",
	"elderthorn": "leaf_elderthorn",
	"canopykin": "leaf_canopykin",
	"mossguard": "leaf_mossguard",
	"grovewarden": "leaf_grovewarden",
	"sparkpup": "ember_sparkpup",
	"wicklet": "ember_wicklet",
	"cinderkit": "ember_cinderkit",
	"foxfire": "ember_foxfire",
	"infernox": "ember_infernox",
	"emberfox": "ember_emberfox",
	"pyrelord": "ember_pyrelord",
	"blazetail": "ember_blazetail",
	"cottonwisp": "puff_cottonwisp",
	"nimbusling": "puff_nimbusling",
	"fluffball": "puff_fluffball",
	"stormpillow": "puff_stormpillow",
	"skyloom": "puff_skyloom",
}


static func species_mark(family: String, line: String, tier: int) -> String:
	# Sheet 08 is the T1 face. Sheet 09 continues that line at T2/T3.
	# Cloudbud, Driftkin, and Cumulon keep their earlier clarity crops.
	var mark := ""
	if tier == 1:
		match line:
			"sprout":
				mark = "sproutling"
			"dew":
				mark = "dewcap"
			"bud":
				mark = "budmite"
			"spark":
				mark = "sparkpup"
			"wick":
				mark = "wicklet"
			"cinder":
				mark = "cinderkit"
			"cotton":
				mark = "cottonwisp"
			"nimbus":
				mark = "nimbusling"
			"fluff":
				mark = "fluffball"
	elif tier == 2:
		match line:
			"sprout":
				mark = "thornbud"
			"dew":
				mark = "canopykin"
			"bud":
				mark = "mossguard"
			"spark":
				mark = "foxfire"
			"wick":
				mark = "emberfox"
			"cinder":
				mark = "blazetail"
			"cotton":
				mark = "cloudbud"
			"nimbus":
				mark = "driftkin"
			"fluff":
				mark = "cumulon"
	elif tier == 3:
		match line:
			"sprout":
				mark = "elderthorn"
			"bud":
				mark = "grovewarden"
			"spark":
				mark = "infernox"
			"wick":
				mark = "pyrelord"
			"cotton":
				mark = "stormpillow"
			"nimbus":
				mark = "skyloom"
	if mark == "" or not MARK_FILES.has(mark):
		return ""
	return mark


static func clarity_texture(mark: String) -> Texture2D:
	if not MARK_FILES.has(mark):
		return null
	var path := "res://art/tokens/%s.png" % str(MARK_FILES[mark])
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
	box.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
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


static var _mips: Dictionary = {}


static func _filtered(tex: Texture2D, w: int, h: int) -> Texture2D:
	if tex == null:
		return null
	var path := tex.resource_path
	if path == "":
		path = str(tex.get_rid())
	var key := "%s@%dx%d" % [path, w, h]
	if _mips.has(key):
		return _mips[key]
	var img := tex.get_image()
	if img == null:
		return tex
	img = img.duplicate()
	if img.get_width() != w or img.get_height() != h:
		img.resize(maxi(1, w), maxi(1, h), Image.INTERPOLATE_LANCZOS)
	if not img.has_mipmaps():
		img.generate_mipmaps()
	var out := ImageTexture.create_from_image(img)
	_mips[key] = out
	return out


static func make(family: String, tier: int, max_h: float, boss: bool = false, mark: String = "", role: String = "") -> Control:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Resample to the drawn size, then keep mips for the fight squash and window scale.
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var tex := clarity_texture(mark)
	if tex == null:
		tex = texture(family, tier)
	var aspect := 1.35
	if tex != null:
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
	w = maxf(1.0, roundf(w))
	h = maxf(1.0, roundf(h))
	if tex != null:
		rect.texture = _filtered(tex, int(w), int(h))
	rect.custom_minimum_size = Vector2(w, h)
	rect.size = Vector2(w, h)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect
