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


# Sheet 12 wild line. Driftkin is a puff sail, not one of these.
const WILD_MARKS := {
	"meadow": true,
	"tired": true,
	"warden": true,
	"bramble": true,
	"sprig": true,
}

static var _corners: Dictionary = {}


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
		var tex: Texture2D = (token as TextureRect).texture
		var drawn := _drawn_rect(tex, sz, WILD_MARKS.has(mark))
		var corner := _body_corner(tex)
		# Sheet 13: small badge on the top-right outline corner, clear of the line mark.
		var s := clampf(drawn.size.y * 0.28, 12.0, 22.0)
		badge.custom_minimum_size = Vector2(s, s)
		badge.size = Vector2(s, s)
		var cx := drawn.position.x + corner.x * drawn.size.x + s * 0.16
		var cy := drawn.position.y + corner.y * drawn.size.y - s * 0.06
		var left := drawn.position.x + drawn.size.x * 0.66
		badge.position = Vector2(maxf(cx - s * 0.5, left), cy - s * 0.5)
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


static func _drawn_rect(tex: Texture2D, sz: Vector2, stretched: bool) -> Rect2:
	if tex == null or stretched:
		return Rect2(Vector2.ZERO, sz)
	var aspect := float(tex.get_width()) / float(maxi(1, tex.get_height()))
	var box_aspect := sz.x / maxf(1.0, sz.y)
	var dw: float
	var dh: float
	if aspect > box_aspect:
		dw = sz.x
		dh = dw / aspect
	else:
		dh = sz.y
		dw = dh * aspect
	return Rect2((sz.x - dw) * 0.5, (sz.y - dh) * 0.5, dw, dh)


static func _body_corner(tex: Texture2D) -> Vector2:
	# First wide row is the capsule body. A leaf, flame, or bud is the narrow top.
	if tex == null:
		return Vector2(0.84, 0.28)
	var key := tex.resource_path
	if key == "":
		key = "id:%d" % tex.get_instance_id()
	if _corners.has(key):
		return _corners[key]
	var img := tex.get_image()
	if img == null or img.get_width() < 2:
		return Vector2(0.84, 0.28)
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var tw := img.get_width()
	var th := img.get_height()
	var max_span := 0
	var spans := PackedInt32Array()
	var rights := PackedInt32Array()
	spans.resize(th)
	rights.resize(th)
	for y in th:
		var left := tw
		var right := -1
		for x in tw:
			if img.get_pixel(x, y).a > 0.35:
				if x < left:
					left = x
				if x > right:
					right = x
		var span := 0 if right < 0 else right - left + 1
		spans[y] = span
		rights[y] = right
		if span > max_span:
			max_span = span
	var thresh := int(float(max_span) * 0.62)
	var body_y := 0
	for y in th:
		if spans[y] >= thresh:
			body_y = y
			break
	var ratio := Vector2(0.84, 0.28)
	if rights[body_y] >= 0:
		ratio = Vector2(float(rights[body_y]) / float(tw), float(body_y) / float(th))
	_corners[key] = ratio
	return ratio


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
	# Sheet 12: wild silhouettes read a little chunkier than the player family.
	if WILD_MARKS.has(mark):
		w *= 1.12
	w = maxf(1.0, roundf(w))
	h = maxf(1.0, roundf(h))
	if tex != null:
		rect.texture = _filtered(tex, int(w), int(h))
	rect.custom_minimum_size = Vector2(w, h)
	rect.size = Vector2(w, h)
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return rect
