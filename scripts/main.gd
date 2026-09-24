extends Control

const SLOT := preload("res://scripts/slot.gd")
const TOKENS := preload("res://scripts/token.gd")
const LINKS := preload("res://scripts/buddy_overlay.gd")
const MARK := preload("res://scripts/mark.gd")

const CREAM := Color("f6f1e7")
const INK := Color("243042")
const MUTED := Color("8a847a")
const GOLD := Color("c8922a")
const GOOD := Color("2f7d4a")
const BAD := Color("a33b32")
const SLOT_EMPTY := Color("efeae0")
const HIT := Color("c4453a")
const HEAL := Color("2a8a4a")
const BEAT_HOLD := 0.48
const BEAT_FADE := 0.2
const LUNGE_PX := 22.0
const LUNGE_OUT := 0.11
const LUNGE_BACK := 0.12
const SPIT_TIME := 0.18
const POP_IN := 0.07
const POP_OUT := 0.10

var host: Control
var tick: Timer
var flash_timer: Timer
var _rebuild_queued := false
var dex_open := false
var _ending := false
var log_open := false
var punch_uid := -1
var focus_uid := -1
var _seen_phase := ""
var _beat: Control = null

var ally_grid: GridContainer
var enemy_grid: GridContainer
var ally_links
var enemy_links
var ally_floats: Control
var enemy_floats: Control
var log_label: Label
var log_button: Button
var banner_panel: Panel
var banner_label: Label
var round_label: Label
var speed_button: Button
var punch_box: Panel
var punch_label: Label
var strike_layer: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_apply_theme()
	var bg := ColorRect.new()
	bg.color = CREAM
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	host = Control.new()
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	tick = Timer.new()
	tick.timeout.connect(_on_tick)
	add_child(tick)
	flash_timer = Timer.new()
	flash_timer.one_shot = true
	flash_timer.timeout.connect(_clear_flash)
	add_child(flash_timer)
	if not Game.changed.is_connected(_queue_rebuild):
		Game.changed.connect(_queue_rebuild)
	_rebuild()


func _apply_theme() -> void:
	var theme := Theme.new()
	var normal := _style(Color("fffdf8"), INK, 2)
	var hover := _style(Color("fff6e4"), INK, 2)
	var pressed := _style(Color("f3e6cc"), INK, 2)
	var disabled := _style(Color("e7e2d8"), Color("b7b1a6"), 2)
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", normal)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", Color("8d887f"))
	theme.set_color("font_color", "Label", INK)
	theme.set_font_size("font_size", "Button", 16)
	theme.set_font_size("font_size", "Label", 16)
	self.theme = theme


func _queue_rebuild() -> void:
	if _rebuild_queued:
		return
	_rebuild_queued = true
	call_deferred("_rebuild")


func _rebuild() -> void:
	_rebuild_queued = false
	if Game.phase == "combat" and Game.combat != null and Game.combat.over:
		Game.finish_combat()
		return
	if tick and Game.phase != "combat":
		tick.stop()
		_ending = false
	_clear_host()
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 16)
	root.add_theme_constant_override("margin_right", 16)
	root.add_theme_constant_override("margin_top", 8)
	root.add_theme_constant_override("margin_bottom", 8)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(root)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(page)
	match Game.phase:
		"start":
			_build_start(page)
		"prep":
			_build_prep(page)
		"choice":
			_build_choice(page)
		"combat":
			_build_combat(page)
		"result":
			_build_result(page)
		_:
			_build_start(page)
	if Game.run != null and not Game.run.merge_flash.is_empty():
		flash_timer.start(1.8)
		_hold_attention()
	else:
		flash_timer.stop()
	var prev := _seen_phase
	_seen_phase = Game.phase
	var beat := _beat_for(prev, Game.phase)
	if beat != "":
		_show_beat(beat)
	elif _beat == null:
		_maybe_start_tick()


func _beat_for(prev: String, now: String) -> String:
	if prev == "" or prev == now or Game.run == null:
		return ""
	if prev == "start" and now == "prep":
		return str(Game.current_node().title)
	if prev == "prep" and now == "combat":
		return "Fight"
	if prev == "combat":
		var arrival := str(Game.run.get("arrival", ""))
		Game.run.arrival = ""
		if arrival != "":
			return arrival
		if now == "result":
			return "Meadow clear" if bool(Game.run.result.get("won", false)) else "Run over"
		return str(Game.current_node().title)
	return ""


func _show_beat(text: String) -> void:
	if tick:
		tick.stop()
	if _beat != null and is_instance_valid(_beat):
		_beat.queue_free()
	var veil := Control.new()
	veil.name = "ArrivalBeat"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.z_index = 90
	var dim := ColorRect.new()
	dim.color = Color(CREAM.r, CREAM.g, CREAM.b, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := _style(Color("fffdf8"), INK, 3)
	style.set_content_margin_all(22)
	card.add_theme_stylebox_override("panel", style)
	var lab := _lbl(text, 28, INK)
	lab.name = "ArrivalText"
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(lab)
	center.add_child(card)
	veil.add_child(center)
	add_child(veil)
	_beat = veil
	var tw := veil.create_tween()
	tw.tween_interval(BEAT_HOLD)
	tw.tween_property(veil, "modulate:a", 0.0, BEAT_FADE)
	tw.finished.connect(func() -> void:
		var current := _beat == veil
		if current:
			_beat = null
		if is_instance_valid(veil):
			veil.queue_free()
		if current:
			_maybe_start_tick()
	)


func _maybe_start_tick() -> void:
	if _beat != null and is_instance_valid(_beat):
		return
	if tick == null:
		return
	if Game.phase == "combat" and Game.combat != null and not Game.combat.over:
		tick.wait_time = 0.72 / float(maxi(1, Game.speed))
		if tick.is_stopped():
			tick.start()


func _clear_host() -> void:
	if host == null:
		return
	for c in host.get_children():
		host.remove_child(c)
		c.free()
	ally_grid = null
	enemy_grid = null
	ally_links = null
	enemy_links = null
	ally_floats = null
	enemy_floats = null
	log_label = null
	log_button = null
	banner_panel = null
	banner_label = null
	round_label = null
	speed_button = null
	punch_box = null
	punch_label = null
	if strike_layer != null and is_instance_valid(strike_layer):
		strike_layer.free()
	strike_layer = null


func _clear_flash() -> void:
	if Game.run == null:
		return
	if Game.run.merge_flash.is_empty():
		return
	Game.run.merge_flash = {}
	Game.run.flash_uid = -1
	_queue_rebuild()


func _build_start(page: VBoxContainer) -> void:
	page.add_child(_lbl("HATCHLINE", 40, INK))
	page.add_child(_lbl("Meadow Circuit", 18, MUTED))
	page.add_child(_lbl("Three of a kind evolve. Same-family neighbours share a bonus.", 16, INK))
	var dex_n: int = Game.profile.discovered.size()
	var dex_line := "Hatch-dex %d/%d    ·    runs %d" % [dex_n, Game.critter_order.size(), int(Game.profile.runs)]
	page.add_child(_lbl(dex_line, 14, MUTED))
	if dex_open:
		page.add_child(_dex_grid())
		var back := _btn("Back", Vector2(160, 40))
		back.name = "BackButton"
		back.pressed.connect(func() -> void:
			dex_open = false
			_queue_rebuild()
		)
		page.add_child(back)
	else:
		var row := HBoxContainer.new()
		row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 12)
		page.add_child(row)
		for id in Game.starter_ids():
			row.add_child(_starter_card(str(id)))
		var dex_btn := _btn("Hatch-dex", Vector2(160, 36))
		dex_btn.name = "DexButton"
		dex_btn.pressed.connect(func() -> void:
			dex_open = true
			_queue_rebuild()
		)
		page.add_child(dex_btn)
	page.add_child(_tease_row())


func _starter_card(id: String) -> Button:
	var c: Dictionary = Game.critters[id]
	var b := Button.new()
	b.name = "Starter_%s" % id
	b.custom_minimum_size = Vector2(220, 292)
	var is_new: bool = str(c.line) in Game.profile.new_lines
	b.text = ("NEW\n" if is_new else "") + str(c.name)
	b.add_theme_font_size_override("font_size", 1)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, Color(0, 0, 0, 0))
	b.add_theme_stylebox_override("normal", _style(Color("fffdf8"), INK, 3))
	b.add_theme_stylebox_override("hover", _style(Color("fff6e4"), INK, 3))
	b.add_theme_stylebox_override("pressed", _style(Color("f3e6cc"), INK, 3))
	b.add_theme_stylebox_override("focus", _style(Color("fffdf8"), INK, 3))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	var hold := CenterContainer.new()
	hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var token := TOKENS.present(str(c.family), int(c.tier), 128.0, false, TOKENS.species_mark(str(c.family), str(c.line), int(c.tier)), str(c.get("role", "")))
	hold.add_child(token)
	col.add_child(hold)
	if is_new:
		var chip_row := CenterContainer.new()
		chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip_row.add_child(_chip("NEW", Color("f6d56b")))
		col.add_child(chip_row)
	var name := _lbl(str(c.name), 20, INK)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name)
	var sub := _lbl("%s  ·  T%d" % [str(c.family).capitalize(), int(c.tier)], 13, MUTED)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	var stats := _lbl("%d HP    %d ATK" % [int(c.hp), int(c.atk)], 12, MUTED)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(stats)
	b.add_child(col)
	b.pressed.connect(Game.choose_starter.bind(id))
	return b


func _dex_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 6
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	for id in Game.critter_order:
		var known: bool = id in Game.profile.discovered
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(168, 58)
		var c: Dictionary = Game.critters[id]
		panel.add_theme_stylebox_override("panel", _style(Color("fffdf8") if known else Color("e4dfd4"), INK if known else Color("c8c2b6"), 2))
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		if known:
			row.add_child(TOKENS.present(str(c.family), int(c.tier), 40.0, false, TOKENS.species_mark(str(c.family), str(c.line), int(c.tier)), str(c.get("role", ""))))
		var lab := _lbl("✓ %s  T%d" % [c.name, int(c.tier)] if known else "???", 13, INK if known else MUTED)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lab)
		panel.add_child(row)
		grid.add_child(panel)
	return grid


func _build_prep(page: VBoxContainer) -> void:
	Game.note_sell_once()
	page.add_child(_run_header())
	var flash := _flash_bar()
	if flash:
		page.add_child(flash)
	if str(Game.run.toast) != "":
		page.add_child(_lbl(str(Game.run.toast), 15, GOOD))
	var teach := _teach_line()
	if teach != "":
		var teach_lbl := _lbl(teach, 14, MUTED)
		teach_lbl.name = "TeachLine"
		page.add_child(teach_lbl)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	page.add_child(body)
	body.add_child(_bench_column())
	body.add_child(_board_column())
	body.add_child(_right_column())
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	page.add_child(bottom)
	bottom.add_child(_sell_zone())
	var node := Game.current_node()
	var kind := str(node.type)
	if kind == "fight" or kind == "boss":
		var fight := _btn("Fight", Vector2(220, 64))
		fight.name = "FightButton"
		fight.add_theme_font_size_override("font_size", 22)
		fight.pressed.connect(Game.start_combat)
		bottom.add_child(fight)
	elif kind == "shop":
		var onward := _btn(Game.leave_label(), Vector2(220, 64))
		onward.name = "OnwardButton"
		onward.add_theme_font_size_override("font_size", 20)
		onward.pressed.connect(Game.leave_node)
		bottom.add_child(onward)


func _build_choice(page: VBoxContainer) -> void:
	page.add_child(_run_header())
	var flash := _flash_bar()
	if flash:
		page.add_child(flash)
	var node := Game.current_node()
	page.add_child(_lbl(str(node.title), 32, INK))
	page.add_child(_lbl(str(node.get("prompt", "")), 18, INK))
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	page.add_child(row)
	var choices: Array = node.get("choices", [])
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var b := _btn("%s\n%s" % [choice.label, choice.detail], Vector2(340, 180))
		b.name = "Choice%d" % i
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(Game.choose.bind(i))
		row.add_child(b)


func _build_combat(page: VBoxContainer) -> void:
	log_open = false
	punch_uid = -1
	page.add_child(_run_header())
	banner_panel = Panel.new()
	banner_panel.custom_minimum_size = Vector2(0, 36)
	banner_panel.add_theme_stylebox_override("panel", _style(Color("f6d56b"), INK, 2))
	banner_label = _lbl("", 18, INK)
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.add_child(banner_label)
	page.add_child(banner_panel)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	page.add_child(body)
	var ally_stage := _grid_stage(Game.econ("BOARD_W"), [], true)
	var enemy_stage := _grid_stage(Game.econ("BOARD_W"), [], true)
	ally_grid = ally_stage.grid
	enemy_grid = enemy_stage.grid
	ally_links = ally_stage.links
	enemy_links = enemy_stage.links
	ally_floats = ally_stage.floats
	enemy_floats = enemy_stage.floats
	body.add_child(_combat_frame("YOUR MEADOW", ally_stage.stage, PackedStringArray(["Back", "Mid", "Front"])))
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(196, 0)
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", 10)
	body.add_child(mid)
	mid.add_child(_round_badge())
	speed_button = _btn("SPEED  ▶  ×%d" % Game.speed, Vector2(188, 46))
	speed_button.name = "SpeedButton"
	speed_button.add_theme_font_size_override("font_size", 18)
	speed_button.clip_text = false
	speed_button.pressed.connect(_toggle_speed)
	mid.add_child(speed_button)
	punch_box = Panel.new()
	punch_box.name = "PunchIn"
	punch_box.visible = false
	punch_box.custom_minimum_size = Vector2(148, 0)
	punch_box.add_theme_stylebox_override("panel", _style(Color("fffdf8"), INK, 2))
	punch_label = _lbl("", 13, INK)
	punch_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	punch_box.add_child(punch_label)
	mid.add_child(punch_box)
	body.add_child(_combat_frame("ENEMY CRITTERS", enemy_stage.stage, PackedStringArray(["Front", "Mid", "Back"])))
	page.add_child(_log_bar())
	strike_layer = Control.new()
	strike_layer.name = "StrikeLayer"
	strike_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	strike_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strike_layer.z_index = 40
	add_child(strike_layer)
	_sync_combat()


func _build_result(page: VBoxContainer) -> void:
	var result: Dictionary = Game.run.result
	var won: bool = bool(result.get("won", false))
	page.add_child(_lbl("Meadow clear" if won else "Run over", 22, GOOD if won else MUTED))
	var line := _lbl(str(result.get("line", "")), 26, INK if won else BAD)
	line.name = "ResultLine"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(line)
	page.add_child(_lbl("Unlocks and the hatch-dex are kept.", 15, MUTED))
	var dex: Array = result.get("new_dex", [])
	if dex.is_empty():
		page.add_child(_lbl("Dex: no new ticks.", 15, INK))
	else:
		var names: PackedStringArray = []
		var extra := 0
		for i in dex.size():
			if i < 6:
				names.append(str(Game.critters[str(dex[i])].name))
			else:
				extra += 1
		var text := "Dex ticked: " + ", ".join(names)
		if extra > 0:
			text += " +%d more" % extra
		var dex_lbl := _lbl(text, 16, GOOD)
		dex_lbl.name = "DexTick"
		page.add_child(dex_lbl)
	if str(result.get("unlock", "")) != "":
		page.add_child(_unlock_card(str(result.unlock)))
	var again := _btn("Again" if won else "Retry", Vector2(280, 64))
	again.name = "RetryButton"
	again.add_theme_font_size_override("font_size", 22)
	again.pressed.connect(Game.retry)
	page.add_child(again)
	page.add_child(_tease_row())


func _unlock_card(copy: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "UnlockCard"
	card.custom_minimum_size = Vector2(560, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := _style(Color("fffdf8"), INK, 3)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	var found := _unlock_critter()
	var family := str(found.get("family", "leaf"))
	var tier := int(found.get("tier", 1))
	var hold := CenterContainer.new()
	hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var token := TOKENS.present(family, tier, 132.0, false, TOKENS.species_mark(family, str(found.get("line", "")), tier), str(found.get("role", "")))
	hold.add_child(token)
	col.add_child(hold)
	var chip_row := CenterContainer.new()
	chip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip_row.add_child(_chip("NEW", Color("f6d56b")))
	col.add_child(chip_row)
	var name := _lbl(str(found.get("name", "New egg")), 26, INK)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name)
	var line := _lbl(copy, 16, MUTED)
	line.name = "UnlockCopy"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.clip_text = false
	line.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	line.custom_minimum_size = Vector2(520, 0)
	line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(line)
	card.add_child(col)
	return card


func _unlock_critter() -> Dictionary:
	var want := str(Game.circuit.meta.get("unlock_name", ""))
	for id in Game.critter_order:
		var c: Dictionary = Game.critters[id]
		if str(c.name) == want:
			return c
	return {}


func _run_header() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 10)
	var title := _lbl("HATCHLINE", 26, INK)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(title)
	top.add_child(_path_pill())
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(gap)
	top.add_child(_coin_pill(str(int(Game.run.coins)), "coin"))
	top.add_child(_lbl("+", 20, INK))
	top.add_child(_coin_pill("+%d" % Game.interest_for(int(Game.run.coins)), "interest"))
	box.add_child(top)
	box.add_child(_ribbon())
	return box


func _path_pill() -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(260, 52)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", _style(Color("f3ecdf"), INK, 2))
	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 0)
	var circuit := _lbl("MEADOW CIRCUIT", 11, MUTED)
	circuit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var node := _lbl(str(Game.current_node().title).to_upper(), 16, INK)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(circuit)
	inner.add_child(node)
	p.add_child(inner)
	return p


func _coin_pill(amount: String, kind: String) -> Panel:
	var p := Panel.new()
	var wide := kind == "interest"
	p.custom_minimum_size = Vector2(138 if wide else 108, 44)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := _style(Color("fffdf8"), INK, 2)
	s.set_content_margin_all(4)
	p.add_theme_stylebox_override("panel", s)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	var mark := Control.new()
	mark.set_script(MARK)
	mark.set("kind", kind)
	mark.custom_minimum_size = Vector2(22, 22)
	row.add_child(mark)
	if wide:
		var tag := _lbl("INT", 12, MUTED)
		tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(tag)
	var lab := _lbl(amount, 20, INK)
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lab)
	p.add_child(row)
	return p


func _ribbon() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "PathRibbon"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 0)
	var cur := str(Game.run.node_id)
	var visited: Array = Game.run.visited
	var steps: Array = Game.circuit.ribbon
	var states: Array = []
	for s in steps.size():
		var step: Dictionary = steps[s]
		var ids: Array = step.ids
		var active: bool = cur in ids
		var past := false
		if not active:
			for id in ids:
				if id in visited:
					past = true
		states.append("now" if active else ("past" if past else "next"))
	for s in steps.size():
		if s > 0:
			var walked: bool = str(states[s - 1]) == "past" or str(states[s]) != "next"
			row.add_child(_path_link(walked))
		row.add_child(_path_node(_ribbon_label(str(steps[s].label)), str(states[s])))
	return row


func _path_link(walked: bool) -> CenterContainer:
	var hold := CenterContainer.new()
	hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hold.custom_minimum_size = Vector2(14, 16)
	var line := ColorRect.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.custom_minimum_size = Vector2(14, 3)
	line.color = GOOD if walked else Color("d5cfc3")
	hold.add_child(line)
	return hold


func _ribbon_label(label: String) -> String:
	# Long stops collide with their neighbours. Keep the data labels; show the short form.
	match label:
		"Cart / Nest":
			return "Cart"
		"Last stall":
			return "Stall 2"
		_:
			return label


func _path_node(label: String, state: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 1)
	var hold := CenterContainer.new()
	hold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hold.custom_minimum_size = Vector2(0, 16)
	var dot := Panel.new()
	var d := 16 if state == "now" else 11
	dot.custom_minimum_size = Vector2(d, d)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if state == "now":
		dot.name = "PathNow"
	var bg := GOLD if state == "now" else (GOOD if state == "past" else Color("f7f3ea"))
	var border := INK if state == "now" else (GOOD if state == "past" else MUTED)
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(d)
	s.set_content_margin_all(0)
	dot.add_theme_stylebox_override("panel", s)
	hold.add_child(dot)
	box.add_child(hold)
	var lab := _lbl(label, 13 if state == "now" else 11, INK if state == "now" else (GOOD if state == "past" else MUTED))
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(lab)
	return box


func _flash_bar() -> Control:
	if Game.run == null or Game.run.merge_flash.is_empty():
		return null
	var f: Dictionary = Game.run.merge_flash
	var panel := Panel.new()
	panel.name = "MergeFlash"
	panel.custom_minimum_size = Vector2(0, 40)
	panel.add_theme_stylebox_override("panel", _style(Color("fff6e4"), GOLD, 3))
	var title := "TRIPLE   %s   →   %s   ·   T%d" % [f.from, f.to, int(f.tier)]
	if int(f.count) > 1:
		title = "TRIPLE ×%d   %s   →   %s   ·   T%d" % [int(f.count), f.from, f.to, int(f.tier)]
	var a := _lbl(title, 20, INK)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	a.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	a.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(a)
	return panel


func _bench_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(236, 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_lbl("Bench", 16, INK))
	for i in Game.run.bench.size():
		var slot := _make_slot("bench", i, Game.run.bench[i], 236, 78)
		slot.name = "Bench%d" % i
		col.add_child(slot)
	return col


func _board_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_lbl("Board  %d/%d" % [Game.board_count(), Game.econ("BOARD_SOFT_CAP")], 16, INK))
	var buddies := Game.board_buddy_labels()
	var adj := _adjacency(Game.run.board)
	var built := _grid_stage(Game.econ("BOARD_W"), adj.pairs, false)
	var grid: GridContainer = built.grid
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	var glow: Dictionary = adj.glow
	for i in Game.run.board.size():
		var slot := _make_slot("board", i, Game.run.board[i], 168, 136, glow.get(i, Color(0, 0, 0, 0)))
		slot.name = "Board%d" % i
		if Game.run.board[i] != null and str(buddies.get(i, "")) != "":
			var tag := _lbl(str(buddies[i]), 13, _family_color(str(Game.run.board[i].family)))
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.get_node("Margin/SlotBody").add_child(tag)
		grid.add_child(slot)
	built.stage.custom_minimum_size = grid.get_combined_minimum_size()
	col.add_child(_rank_heads(PackedStringArray(["Back", "Mid", "Front"])))
	col.add_child(built.stage)
	return col


func _right_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(300, 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var node := Game.current_node()
	if str(node.type) == "shop":
		col.add_child(_lbl(str(node.title), 16, INK))
		for i in Game.run.shop.size():
			col.add_child(_shop_card(i))
		var cost := Game.reroll_cost()
		var reroll := _btn("Reroll  %d" % cost, Vector2(200, 36))
		reroll.name = "RerollButton"
		reroll.pressed.connect(Game.reroll)
		col.add_child(reroll)
	else:
		var enc_id := str(node.get("encounter", ""))
		col.add_child(_lbl("Coming up", 14, MUTED))
		if enc_id != "" and Game.encounters.has(enc_id):
			var enc: Dictionary = Game.encounters[enc_id]
			var trait_label := _lbl(str(enc.trait), 16, INK)
			trait_label.name = "TraitLabel"
			trait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			col.add_child(trait_label)
			col.add_child(_lbl(Game.encounter_blurb(enc_id), 15, INK))
			col.add_child(_enemy_preview(enc))
	return col


func _shop_card(i: int) -> Panel:
	var card: Dictionary = Game.run.shop[i]
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(286, 96)
	var def_id := str(card.def_id)
	var frozen: bool = bool(card.frozen)
	var border := Color("7aa2d6") if frozen else Color("cfc6b8")
	panel.add_theme_stylebox_override("panel", _style(Color("fffdf8"), border, 3 if frozen else 2))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)
	if def_id == "":
		row.add_child(_lbl("Empty", 14, MUTED))
		return panel
	var c: Dictionary = Game.critters[def_id]
	row.add_child(TOKENS.present(str(c.family), int(c.tier), 64.0, false, TOKENS.species_mark(str(c.family), str(c.line), int(c.tier)), str(c.get("role", ""))))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 1)
	var name := str(c.name)
	if frozen:
		name = "FROZEN  " + name
	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_theme_constant_override("separation", 6)
	if str(c.line) in Game.profile.new_lines:
		var chip := _chip("NEW", Color("f6d56b"))
		chip.name = "ShopNew"
		title_row.add_child(chip)
	var title := _lbl("%s   %s T%d" % [name, str(c.family).capitalize(), int(c.tier)], 14, INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.add_child(title)
	box.add_child(title_row)
	var stats := _lbl(Game.stat_line(c), 12, INK)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stats)
	var actions := HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_theme_constant_override("separation", 6)
	var cost := Game.buy_cost_for_tier(int(c.tier))
	var buy := _btn("Buy %d" % cost, Vector2(96, 28))
	buy.name = "BuyButton%d" % i
	buy.disabled = cost > int(Game.run.coins)
	buy.pressed.connect(Game.buy.bind(i))
	actions.add_child(buy)
	var fr := _btn("Unfreeze" if frozen else "Freeze", Vector2(96, 28))
	fr.name = "FreezeButton%d" % i
	fr.pressed.connect(Game.toggle_freeze.bind(i))
	actions.add_child(fr)
	box.add_child(actions)
	row.add_child(box)
	return panel


func _enemy_preview(enc: Dictionary) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := Game.econ("BOARD_W")
	var cells := w * Game.econ("BOARD_H")
	var placed := {}
	for spec in enc.units:
		placed[int(spec.y) * w + int(spec.x)] = spec
	for i in cells:
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(92, 78)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if placed.has(i):
			var spec: Dictionary = placed[i]
			var d: Dictionary = Game.enemy_defs[str(spec.def)]
			var boss: bool = bool(d.get("boss", false))
			panel.clip_contents = true
			panel.tooltip_text = str(d.name)
			panel.add_theme_stylebox_override("panel", _style(SLOT_EMPTY, INK, 2))
			var holder := CenterContainer.new()
			holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.clip_contents = true
			holder.set_anchors_preset(Control.PRESET_FULL_RECT)
			holder.offset_left = 2
			holder.offset_right = -2
			holder.offset_top = 2
			holder.offset_bottom = -18
			holder.add_child(TOKENS.present(str(d.family), 1, 44.0, boss, TOKENS.enemy_mark(str(spec.def)), str(d.get("role", "melee"))))
			panel.add_child(holder)
			var band := _name_band(_short_name(str(d.name), 14), 10, INK)
			band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			band.offset_left = 2
			band.offset_right = -2
			band.offset_top = -16
			band.offset_bottom = -1
			panel.add_child(band)
		else:
			panel.add_theme_stylebox_override("panel", _style(SLOT_EMPTY, Color("ddd6c8"), 1))
		grid.add_child(panel)
	return grid


func _sell_zone() -> Control:
	var slot := _make_slot("sell", -1, null, 460, 76)
	slot.name = "SellZone"
	slot.tooltip_text = "Drag a critter here to sell"
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	var tag := Control.new()
	tag.set_script(MARK)
	tag.set("kind", "sell")
	tag.custom_minimum_size = Vector2(36, 28)
	row.add_child(tag)
	var lab := _lbl("Drag a critter here to sell", 18, BAD)
	lab.name = "SellHint"
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lab)
	slot.get_node("Margin/SlotBody").add_child(row)
	return slot


func _make_slot(zone: String, index: int, unit, w: float, h: float, glow: Color = Color(0, 0, 0, 0)) -> Panel:
	var slot := Panel.new()
	slot.set_script(SLOT)
	slot.set("zone", zone)
	slot.set("slot_index", index)
	slot.set("unit_uid", -1 if unit == null else int(unit.uid))
	slot.custom_minimum_size = Vector2(w, h)
	slot.mouse_filter = Control.MOUSE_FILTER_STOP
	var border := Color("cfc6b8")
	var bg := SLOT_EMPTY
	var width := 1
	if zone == "sell":
		bg = Color("f7e1dc")
		border = BAD
		width = 2
	elif unit != null:
		var flash := Game.run != null and int(unit.uid) == int(Game.run.get("flash_uid", -1))
		if flash:
			border = GOLD
			width = 4
		elif glow.a > 0.0:
			border = glow
			width = 4
			bg = Color(glow.r, glow.g, glow.b).lerp(SLOT_EMPTY, 0.78)
		else:
			border = INK
			width = 2
		slot.set("preview_family", str(unit.family))
		slot.set("preview_tier", int(unit.tier))
		slot.set("preview_mark", TOKENS.species_mark(str(unit.family), str(unit.get("line", "")), int(unit.tier)))
	slot.add_theme_stylebox_override("panel", _style(bg, border, width))
	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	slot.add_child(margin)
	var body := VBoxContainer.new()
	body.name = "SlotBody"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_theme_constant_override("separation", 1)
	margin.add_child(body)
	if unit == null:
		return slot
	var wide: bool = w > h + 40.0
	var flashing: bool = Game.run != null and int(unit.uid) == int(Game.run.get("flash_uid", -1))
	var species := TOKENS.species_mark(str(unit.family), str(unit.get("line", "")), int(unit.tier))
	var role := str(unit.get("role", "melee"))
	slot.set("preview_role", role)
	var token := TOKENS.present(str(unit.family), int(unit.tier), 52.0 if wide else 46.0, false, species, role)
	var pop := _pop_wrap(token)
	if flashing:
		_play_merge_pop(pop)
		_pulse_slot(slot)
	var hp := int(unit.max_hp)
	var atk := int(unit.atk)
	var arm := int(unit.armor)
	var reg := int(unit.get("regen", 0))
	var full := "%d HP   %d ATK   %d ARM" % [hp, atk, arm]
	if reg > 0:
		full += "   %d REG" % reg
	var quiet := zone == "board" and Game.board_count() >= 5
	var role_word := "Ranged" if role == "ranged" else "Melee"
	var tip := "%s\n%s" % [unit.name, role_word]
	if zone == "board":
		var rx := int(index) % Game.econ("BOARD_W")
		var rank := "Back" if rx == 0 else ("Mid" if rx == 1 else "Front")
		tip += " · %s" % rank
	slot.tooltip_text = "%s\n%d HP\n%d ATK\n%d ARM\n%d REG" % [tip, hp, atk, arm, reg]
	var name := _lbl("%s  T%d" % [unit.name, int(unit.tier)], 14, INK)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var meta := _lbl(("%d HP" % hp) if quiet else full, 13, INK)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(name)
	texts.add_child(meta)
	if quiet:
		var extra_bits := "%d ATK   %d ARM" % [atk, arm]
		if reg > 0:
			extra_bits += "   %d REG" % reg
		var extra := _lbl(extra_bits, 12, INK)
		extra.name = "QuietDetail"
		extra.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var uid := int(unit.uid)
		extra.visible = focus_uid == uid
		texts.add_child(extra)
		slot.mouse_entered.connect(func() -> void:
			if is_instance_valid(extra):
				extra.visible = true
		)
		slot.mouse_exited.connect(func() -> void:
			if is_instance_valid(extra):
				extra.visible = focus_uid == uid
		)
		slot.gui_input.connect(func(ev: InputEvent) -> void:
			if not (ev is InputEventMouseButton):
				return
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(extra):
				if focus_uid == uid:
					focus_uid = -1
				else:
					focus_uid = uid
				extra.visible = focus_uid == uid
		)
	var badge := Game.pair_badge(str(unit.def_id))
	if badge != "":
		var pip_row := HBoxContainer.new()
		pip_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pip_row.add_child(_chip(badge, Color("f6d56b")))
		texts.add_child(pip_row)
	if wide:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		row.add_child(pop)
		row.add_child(texts)
		body.add_child(row)
	else:
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.add_child(pop)
		body.add_child(holder)
		body.add_child(texts)
	return slot


func _rank_heads(words: PackedStringArray) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "RankHeads"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	for word in words:
		var lab := _lbl(word, 12, MUTED)
		lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lab)
	return row


func _combat_frame(title: String, stage: Control, ranks: PackedStringArray) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", 0)
	var tab_row := CenterContainer.new()
	tab_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tab := Panel.new()
	tab.custom_minimum_size = Vector2(220, 32)
	tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tab.add_theme_stylebox_override("panel", _style(Color("f7f1e6"), INK, 2))
	var tab_label := _lbl(title, 14, INK)
	tab_label.name = "BoardTitle"
	tab_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tab_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	tab.add_child(tab_label)
	tab_row.add_child(tab)
	col.add_child(tab_row)
	col.add_child(_rank_heads(ranks))
	var frame := Panel.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := _style(Color("f6f1e7"), INK, 3)
	frame_style.set_content_margin_all(8)
	frame.add_theme_stylebox_override("panel", frame_style)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(stage)
	frame.add_child(margin)
	col.add_child(frame)
	return col


func _round_badge() -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(104, 104)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s := _style(Color("efe6d4"), INK, 2)
	s.set_corner_radius_all(52)
	s.set_content_margin_all(6)
	p.add_theme_stylebox_override("panel", s)
	round_label = _lbl("ROUND\n0", 16, INK)
	round_label.name = "RoundLabel"
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	round_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	round_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(round_label)
	return p


func _log_bar() -> PanelContainer:
	var p := PanelContainer.new()
	p.name = "CombatLogPanel"
	p.size_flags_vertical = Control.SIZE_SHRINK_END
	p.custom_minimum_size = Vector2(0, 52)
	var s := _style(Color("f3ecdf"), INK, 2)
	s.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", s)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	var head := HBoxContainer.new()
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _lbl("COMBAT LOG", 14, INK)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	head.add_child(title)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(gap)
	log_button = _btn("VIEW FULL LOG", Vector2(168, 34))
	log_button.name = "ViewLogButton"
	log_button.pressed.connect(_toggle_log)
	head.add_child(log_button)
	box.add_child(head)
	log_label = _lbl("", 14, INK)
	log_label.name = "CombatLog"
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.visible = false
	box.add_child(log_label)
	p.add_child(box)
	return p


func _toggle_log() -> void:
	log_open = not log_open
	_apply_log_mode()


func _apply_log_mode() -> void:
	if log_label:
		log_label.visible = log_open
	if log_button:
		log_button.text = "HIDE LOG" if log_open else "VIEW FULL LOG"


func _grid_stage(columns: int, pairs: Array, with_floats: bool) -> Dictionary:
	var stage := Control.new()
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grid := GridContainer.new()
	grid.columns = columns
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	stage.add_child(grid)
	var links = LINKS.new()
	links.set_anchors_preset(Control.PRESET_FULL_RECT)
	links.grid = grid
	links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	links.arm(pairs)
	stage.add_child(links)
	var floats: Control = null
	if with_floats:
		floats = Control.new()
		floats.set_anchors_preset(Control.PRESET_FULL_RECT)
		floats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage.add_child(floats)
	return {"stage": stage, "grid": grid, "links": links, "floats": floats}


func _sync_combat() -> void:
	if Game.combat == null or ally_grid == null:
		return
	var sim: CombatSim = Game.combat
	if round_label:
		round_label.text = "ROUND\n%d" % sim.round_i
	if banner_panel and banner_label:
		banner_panel.visible = sim.banner != ""
		banner_label.text = sim.banner
	if log_label:
		var start := maxi(0, sim.log_lines.size() - 8)
		var lines := PackedStringArray()
		for i in range(start, sim.log_lines.size()):
			lines.append("•  " + str(sim.log_lines[i]))
		log_label.text = "\n".join(lines)
		_apply_log_mode()
	_retitle_ally_board()
	var ally_cells := _combat_entries(sim.allies, false)
	var enemy_cells := _combat_entries(sim.enemies, true)
	var ally_adj := _adjacency(ally_cells)
	var enemy_adj := _adjacency(enemy_cells)
	var popping := {}
	for entry in sim.cues:
		if str(entry.kind) == "kill":
			popping[int(entry.uid)] = true
	_fill_combat_grid(ally_grid, ally_cells, ally_adj.glow, popping)
	_fill_combat_grid(enemy_grid, enemy_cells, enemy_adj.glow, popping)
	if ally_links:
		ally_links.arm(ally_adj.pairs)
	if enemy_links:
		enemy_links.arm(enemy_adj.pairs)
	_refresh_punch(sim)
	var pending: Array = sim.floats.duplicate()
	var pending_cues: Array = sim.cues.duplicate()
	sim.floats.clear()
	sim.cues.clear()
	_spawn_floats(ally_floats, ally_grid, ally_cells, pending)
	_spawn_floats(enemy_floats, enemy_grid, enemy_cells, pending)
	_play_cues(pending_cues)


func _retitle_ally_board() -> void:
	if ally_grid == null:
		return
	var frame := ally_grid.get_parent()
	while frame != null and not (frame is VBoxContainer):
		frame = frame.get_parent()
	if frame == null:
		return
	var title := frame.find_child("BoardTitle", true, false)
	if title is Label:
		title.text = _your_board_title()


func _your_board_title() -> String:
	if Game.combat == null or Game.combat.allies.size() != 1:
		return "YOUR MEADOW"
	return "YOUR " + str(Game.combat.allies[0].name).to_upper()


func _fill_combat_grid(grid: GridContainer, cells: Array, glow: Dictionary, popping: Dictionary) -> void:
	if grid.get_child_count() != cells.size():
		for c in grid.get_children():
			grid.remove_child(c)
			c.free()
		for i in cells.size():
			grid.add_child(_combat_cell(cells[i], glow.get(i, Color(0, 0, 0, 0)), popping))
		return
	for i in cells.size():
		var cell: Node = grid.get_child(i)
		var unit = cells[i]
		var uid := -1
		if unit != null:
			uid = int(unit.uid)
		var have := -2
		if cell.has_meta("uid"):
			have = int(cell.get_meta("uid"))
		if have != uid:
			var neu := _combat_cell(unit, glow.get(i, Color(0, 0, 0, 0)), popping)
			grid.remove_child(cell)
			cell.free()
			grid.add_child(neu)
			grid.move_child(neu, i)
		elif unit != null and cell is Panel:
			_touch_combat_cell(cell as Panel, unit, glow.get(i, Color(0, 0, 0, 0)), popping.has(uid))


func _combat_cell(unit, glow: Color, popping: Dictionary) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(150, 128)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unit == null:
		panel.set_meta("uid", -1)
		panel.add_theme_stylebox_override("panel", _style(SLOT_EMPTY, Color("ddd6c8"), 1))
		return panel
	var alive: bool = bool(unit.alive)
	var border := INK if alive else Color("b7b1a6")
	var width := 2
	var bg := SLOT_EMPTY
	if glow.a > 0.0 and alive:
		border = glow
		width = 4
		bg = Color(glow.r, glow.g, glow.b).lerp(SLOT_EMPTY, 0.78)
	panel.add_theme_stylebox_override("panel", _style(bg, border, width))
	panel.clip_contents = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.tooltip_text = _combat_detail(unit).replace("\n", "   ")
	panel.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton:
			var mb := ev as InputEventMouseButton
			if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				_toggle_punch(unit)
	)
	panel.set_meta("uid", int(unit.uid))
	var band := _name_band(_short_name(str(unit.name), 12), 12, INK if alive else MUTED)
	if band.get_child_count() > 0:
		band.get_child(0).name = "NameText"
	band.set_anchors_preset(Control.PRESET_TOP_WIDE)
	band.offset_left = 4
	band.offset_right = -4
	band.offset_top = 1
	band.offset_bottom = 16
	panel.add_child(band)
	var fresh_kill: bool = popping.has(int(unit.uid))
	var token := TOKENS.present(str(unit.family), int(unit.get("tier", 1)), 64.0, bool(unit.get("boss", false)), TOKENS.unit_mark(unit), str(unit.get("role", "melee")))
	if not alive and not fresh_kill:
		token.modulate = Color(0.62, 0.62, 0.64)
	var juice := _juice_wrap(token)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.clip_contents = false
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	holder.offset_left = 4
	holder.offset_right = -4
	holder.offset_top = 18
	holder.offset_bottom = -20
	holder.add_child(juice)
	panel.add_child(holder)
	var bar_band := Control.new()
	bar_band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_band.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_band.offset_left = 6
	bar_band.offset_right = -6
	bar_band.offset_top = -18
	bar_band.offset_bottom = -2
	var bar := _hp_bar(int(unit.hp), int(unit.max_hp))
	bar.name = "HpBar"
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_band.add_child(bar)
	panel.add_child(bar_band)
	return panel


func _touch_combat_cell(panel: Panel, unit, glow: Color, popping: bool) -> void:
	var alive: bool = bool(unit.alive)
	var border := INK if alive else Color("b7b1a6")
	var width := 2
	var bg := SLOT_EMPTY
	if glow.a > 0.0 and alive:
		border = glow
		width = 4
		bg = Color(glow.r, glow.g, glow.b).lerp(SLOT_EMPTY, 0.78)
	panel.add_theme_stylebox_override("panel", _style(bg, border, width))
	panel.tooltip_text = _combat_detail(unit).replace("\n", "   ")
	var name_lab: Node = panel.find_child("NameText", true, false)
	if name_lab is Label:
		(name_lab as Label).add_theme_color_override("font_color", INK if alive else MUTED)
	var bar: Node = panel.find_child("HpBar", true, false)
	if bar is ProgressBar:
		var pb := bar as ProgressBar
		var mx := maxi(1, int(unit.max_hp))
		pb.max_value = mx
		pb.value = int(unit.hp)
		var ratio := clampf(float(unit.hp) / float(mx), 0.0, 1.0)
		var fill := StyleBoxFlat.new()
		fill.bg_color = GOOD if ratio > 0.35 else BAD
		fill.set_corner_radius_all(3)
		fill.set_content_margin_all(0)
		pb.add_theme_stylebox_override("fill", fill)
	var juice: Node = panel.find_child("Juice", true, false)
	if juice is Control and not alive and not popping and not _juice_busy(juice as Control):
		var j := juice as Control
		j.scale = Vector2(0.72, 0.72)
		j.modulate = Color(0.62, 0.62, 0.64, 0.55)


func _combat_detail(unit) -> String:
	var atk := int(unit.atk) + int(unit.get("bonus_atk", 0))
	var arm := int(unit.armor) + int(unit.get("bonus_armor", 0))
	var reg := int(unit.get("regen", 0)) + int(unit.get("bonus_regen", 0))
	var hp := "%d/%d HP" % [int(unit.hp), int(unit.max_hp)]
	if not bool(unit.alive):
		hp = "fainted"
	var role_word := "Ranged" if str(unit.get("role", "")) == "ranged" else "Melee"
	return "%s\n%s · %s\n%s\n%d ATK\n%d ARM\n%d REG" % [unit.name, role_word, CombatSim.rank_label(unit), hp, atk, arm, reg]


func _toggle_punch(unit) -> void:
	if unit == null:
		return
	if punch_uid == int(unit.uid):
		punch_uid = -1
	else:
		punch_uid = int(unit.uid)
	if Game.combat != null:
		_refresh_punch(Game.combat)


func _refresh_punch(sim: CombatSim) -> void:
	if punch_box == null or punch_label == null:
		return
	if punch_uid < 0:
		punch_box.visible = false
		return
	var found = null
	for u in sim.allies:
		if int(u.uid) == punch_uid:
			found = u
	if found == null:
		for u in sim.enemies:
			if int(u.uid) == punch_uid:
				found = u
	if found == null:
		punch_box.visible = false
		punch_uid = -1
		return
	punch_label.text = _combat_detail(found)
	punch_box.visible = true


func _spawn_floats(layer: Control, grid: GridContainer, cells: Array, pending: Array) -> void:
	if layer == null:
		return
	var shown := pending
	var life := 0.62
	if Game.speed >= 2:
		shown = _loud_floats(pending)
		life = 0.30
	var stacks := {}
	var pace := 0.72 if Game.speed >= 2 else 1.0
	for entry in shown:
		var uid := int(entry.uid)
		var index := -1
		for i in cells.size():
			var u = cells[i]
			if u != null and int(u.uid) == uid:
				index = i
				break
		if index < 0 or index >= grid.get_child_count():
			continue
		var n := int(stacks.get(uid, 0))
		stacks[uid] = n + 1
		var color := HIT if str(entry.kind) == "hit" else HEAL
		var delay := _impact_delay(str(entry.get("via", "")), pace)
		call_deferred("_place_float", layer, grid.get_child(index), str(entry.text), color, n, 0, life, delay)


func _loud_floats(pending: Array) -> Array:
	var best_hit := {}
	var best_heal := {}
	var hit_mag := {}
	var heal_mag := {}
	for entry in pending:
		var uid := int(entry.uid)
		var mag := _float_mag(str(entry.text))
		if str(entry.kind) == "heal":
			if not heal_mag.has(uid) or mag > int(heal_mag[uid]):
				heal_mag[uid] = mag
				best_heal[uid] = entry
		else:
			if not hit_mag.has(uid) or mag > int(hit_mag[uid]):
				hit_mag[uid] = mag
				best_hit[uid] = entry
	var out: Array = []
	for uid in best_hit.keys():
		out.append(best_hit[uid])
	for uid in best_heal.keys():
		out.append(best_heal[uid])
	return out


func _float_mag(text: String) -> int:
	var t := text.strip_edges()
	if t.begins_with("+") or t.begins_with("-"):
		t = t.substr(1)
	if t.is_valid_int():
		return int(t)
	return 0


func _hp_bar(hp: int, mx: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = maxi(1, mx)
	bar.value = hp
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(120, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ratio := 0.0 if mx <= 0 else clampf(float(hp) / float(mx), 0.0, 1.0)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("2a2622")
	bg.set_corner_radius_all(3)
	bg.set_content_margin_all(0)
	var fill := StyleBoxFlat.new()
	fill.bg_color = GOOD if ratio > 0.35 else BAD
	fill.set_corner_radius_all(3)
	fill.set_content_margin_all(0)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _place_float(layer: Control, cell: Control, text: String, color: Color, slot_i: int, tries: int, duration: float = 0.62, delay: float = 0.0) -> void:
	if not is_instance_valid(layer) or not is_instance_valid(cell):
		return
	if cell.size.x < 2.0 and tries < 6:
		call_deferred("_place_float", layer, cell, text, color, slot_i, tries + 1, duration, delay)
		return
	var wrap := Control.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.custom_minimum_size = Vector2(72, 36)
	wrap.z_index = 12
	var shadow := _lbl(text, 28, Color(0.12, 0.08, 0.06, 0.9))
	shadow.position = Vector2(2, 2)
	var face := _lbl(text, 28, color)
	wrap.add_child(shadow)
	wrap.add_child(face)
	layer.add_child(wrap)
	var origin := layer.get_global_transform().affine_inverse() * (cell.global_position + Vector2(cell.size.x * 0.52 + slot_i * 26.0, cell.size.y * 0.28))
	wrap.position = origin
	var rise := 28.0 if duration < 0.5 else 40.0
	var tw := wrap.create_tween()
	if delay > 0.0:
		wrap.modulate.a = 0.0
		tw.tween_interval(delay)
		tw.tween_property(wrap, "modulate:a", 1.0, 0.02)
	tw.tween_property(wrap, "position:y", origin.y - rise, duration)
	tw.parallel().tween_property(wrap, "modulate:a", 0.0, duration * 0.75).set_delay(duration * 0.28)
	tw.finished.connect(wrap.queue_free)


func _combat_entries(units: Array, enemy: bool) -> Array:
	var w := Game.econ("BOARD_W")
	var h := Game.econ("BOARD_H")
	var cells: Array = []
	cells.resize(w * h)
	for i in cells.size():
		cells[i] = null
	for u in units:
		var x: int = int(u.local_x) if enemy else int(u.pos.x)
		var y: int = int(u.local_y) if enemy else int(u.pos.y)
		if x < 0 or y < 0 or x >= w or y >= h:
			continue
		cells[y * w + x] = u
	return cells


func _adjacency(cells: Array) -> Dictionary:
	var pairs: Array = []
	var glow := {}
	var w := Game.econ("BOARD_W")
	var h := Game.econ("BOARD_H")
	for i in cells.size():
		var a = cells[i]
		if a == null or not bool(a.get("alive", true)):
			continue
		var x: int = int(i) % w
		var y: int = int(i) / w
		if x + 1 < w:
			_link_if(cells, i, i + 1, pairs, glow)
		if y + 1 < h and i + w < cells.size():
			_link_if(cells, i, i + w, pairs, glow)
	return {"pairs": pairs, "glow": glow}


func _link_if(cells: Array, ia: int, ib: int, pairs: Array, glow: Dictionary) -> void:
	var b = cells[ib]
	var a = cells[ia]
	if b == null or not bool(b.get("alive", true)):
		return
	if str(a.get("family", "")) == "" or str(a.family) != str(b.get("family", "")):
		return
	var color := _family_color(str(a.family))
	pairs.append({"a": ia, "b": ib, "color": color})
	glow[ia] = color
	glow[ib] = color


func _family_color(family: String) -> Color:
	match family:
		"leaf":
			return Color("6fae7c")
		"ember":
			return Color("e08b78")
		"puff":
			return Color("8eadd8")
		_:
			return Color("e09aa4")


func _teach_line() -> String:
	if Game.run == null:
		return ""
	match str(Game.run.node_id):
		"sparring_1":
			if Game.board_buddy_pairs().is_empty():
				return "Same-family neighbours glow. Watch the boards."
			return ""
		"shop_a":
			var lessons := [
				"Freeze keeps a card.",
				"A pair shows 2/3.",
				"Interest is +1 per 5 saved.",
			]
			var step := clampi(int(Game.run.get("stall_step", 0)), 0, lessons.size() - 1)
			return str(lessons[step])
		_:
			return ""


func _short_name(name: String, limit: int = 12) -> String:
	if name.length() <= limit:
		return name
	var head := str(name.split(" ")[0])
	if head.length() <= limit and head != name:
		return head
	return name.substr(0, maxi(1, limit - 1)) + "…"


func _name_band(text: String, size: int, color: Color) -> Control:
	var band := Control.new()
	band.name = "NameBand"
	band.clip_contents = true
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lab := _lbl(text, size, color)
	lab.clip_text = true
	lab.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.set_anchors_preset(Control.PRESET_FULL_RECT)
	band.add_child(lab)
	return band


func _chip(text: String, bg: Color) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = Vector2(52, 24)
	var s := _style(bg, INK, 2)
	s.set_content_margin_all(1)
	p.add_theme_stylebox_override("panel", s)
	var l := _lbl(text, 13, INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	p.add_child(l)
	return p


func _juice_wrap(token: Control) -> Control:
	var juice := Control.new()
	juice.name = "Juice"
	var sz := token.custom_minimum_size
	juice.custom_minimum_size = sz
	juice.size = sz
	juice.pivot_offset = sz * 0.5
	juice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	juice.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var motion := Control.new()
	motion.name = "Motion"
	motion.custom_minimum_size = sz
	motion.size = sz
	motion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.position = Vector2.ZERO
	motion.add_child(token)
	var flash := ColorRect.new()
	flash.name = "Flash"
	flash.color = Color("f6d56b")
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	motion.add_child(flash)
	juice.add_child(motion)
	juice.resized.connect(func() -> void:
		juice.pivot_offset = juice.size * 0.5
	)
	return juice


func _play_cues(cues: Array) -> void:
	var by_uid := {}
	for entry in cues:
		var uid := int(entry.uid)
		if not by_uid.has(uid):
			by_uid[uid] = []
		by_uid[uid].append(entry)
	var k := 0.72 if Game.speed >= 2 else 1.0
	for uid in by_uid.keys():
		var node := _find_juice(int(uid))
		if node == null:
			continue
		_tween_juice(node, by_uid[uid], k)


func _find_juice(uid: int) -> Control:
	for grid in [ally_grid, enemy_grid]:
		if grid == null:
			continue
		for cell in grid.get_children():
			if cell.has_meta("uid") and int(cell.get_meta("uid")) == uid:
				var found: Node = cell.find_child("Juice", true, false)
				if found is Control:
					return found
	return null


func _juice_busy(node: Control) -> bool:
	if not node.has_meta("juice_tw"):
		return false
	var tw = node.get_meta("juice_tw")
	return tw is Tween and (tw as Tween).is_valid() and (tw as Tween).is_running()


func _tween_juice(node: Control, entries: Array, k: float) -> void:
	var has_kill := false
	var via := ""
	var needs_body := false
	for entry in entries:
		var step := str(entry.kind)
		if step == "kill":
			has_kill = true
		if step == "hit" or step == "kill":
			needs_body = true
		if step == "windup" and str(entry.get("role", "")) == "ranged":
			_spit(node, int(entry.get("target", -1)), k)
		elif step == "windup":
			needs_body = true
		if str(entry.get("via", "")) != "":
			via = str(entry.via)
	if not needs_body:
		return
	if node.has_meta("juice_tw"):
		var old = node.get_meta("juice_tw")
		if old is Tween and (old as Tween).is_valid():
			(old as Tween).kill()
	node.scale = Vector2.ONE
	node.modulate = Color.WHITE
	var motion := node.find_child("Motion", true, false)
	if motion is Control:
		(motion as Control).position = Vector2.ZERO
	var flash: Node = node.find_child("Flash", true, false)
	if flash is CanvasItem:
		(flash as CanvasItem).modulate.a = 0.0
	var tw := node.create_tween()
	node.set_meta("juice_tw", tw)
	var waited := false
	var delay := _impact_delay(via, k)
	for entry in entries:
		var step := str(entry.kind)
		if step == "windup":
			if str(entry.get("role", "")) != "ranged":
				_lunge(node, int(entry.get("target", -1)), tw, k)
		elif step == "hit":
			if has_kill:
				continue
			if delay > 0.0 and not waited:
				tw.tween_interval(delay)
				waited = true
			_pop_hit(node, flash, tw, k)
		elif step == "kill":
			if delay > 0.0 and not waited:
				tw.tween_interval(delay)
				waited = true
			if flash is ColorRect:
				(flash as ColorRect).color = Color("ff5c4a")
			tw.tween_property(node, "scale", Vector2(1.20, 0.66), 0.06 * k)
			tw.parallel().tween_property(node, "modulate", Color(1.0, 0.40, 0.34), 0.06 * k)
			if flash is CanvasItem:
				tw.parallel().tween_property(flash, "modulate:a", 0.7, 0.06 * k)
			tw.tween_property(node, "scale", Vector2(1.58, 1.58), 0.12 * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_interval(0.07 * k)
			tw.tween_property(node, "scale", Vector2(0.40, 0.40), 0.20 * k)
			tw.parallel().tween_property(node, "modulate", Color(0.55, 0.55, 0.58, 0.3), 0.20 * k)
			if flash is CanvasItem:
				tw.parallel().tween_property(flash, "modulate:a", 0.0, 0.20 * k)


func _impact_delay(via: String, k: float) -> float:
	if via == "ranged":
		return SPIT_TIME * k
	if via == "melee":
		return LUNGE_OUT * k
	return 0.0


func _pop_hit(node: Control, flash: Node, tw: Tween, k: float) -> void:
	if flash is ColorRect:
		(flash as ColorRect).color = Color("f6d56b")
	tw.tween_property(node, "scale", Vector2(1.14, 1.14), POP_IN * k).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(node, "modulate", Color(1.0, 0.94, 0.78), POP_IN * k)
	if flash is CanvasItem:
		tw.parallel().tween_property(flash, "modulate:a", 0.34, POP_IN * k)
	tw.tween_property(node, "scale", Vector2.ONE, POP_OUT * k)
	tw.parallel().tween_property(node, "modulate", Color.WHITE, POP_OUT * k)
	if flash is CanvasItem:
		tw.parallel().tween_property(flash, "modulate:a", 0.0, POP_OUT * k)


func _lunge(node: Control, target_uid: int, tw: Tween, k: float) -> void:
	var motion := node.find_child("Motion", true, false) as Control
	if motion == null:
		return
	var dest := _toward(node, target_uid, LUNGE_PX)
	motion.position = Vector2.ZERO
	tw.tween_property(motion, "position", dest, LUNGE_OUT * k).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(motion, "position", Vector2.ZERO, LUNGE_BACK * k).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _spit(from_node: Control, target_uid: int, k: float) -> void:
	if strike_layer == null or not is_instance_valid(strike_layer):
		return
	var target := _find_juice(target_uid)
	if target == null:
		return
	var seed := Panel.new()
	seed.name = "Spit"
	seed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seed.custom_minimum_size = Vector2(14, 14)
	seed.size = Vector2(14, 14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("d7e7a4")
	style.border_color = INK
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(0)
	seed.add_theme_stylebox_override("panel", style)
	var spark := ColorRect.new()
	spark.color = Color("f6d56b")
	spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spark.custom_minimum_size = Vector2(5, 5)
	spark.size = Vector2(5, 5)
	spark.position = Vector2(9, -1)
	seed.add_child(spark)
	strike_layer.add_child(seed)
	var start := _layer_point(from_node)
	var end := _layer_point(target)
	seed.position = start - seed.size * 0.5
	var tw := seed.create_tween()
	tw.tween_property(seed, "position", end - seed.size * 0.5, SPIT_TIME * k).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(seed.queue_free)


func _toward(from_node: Control, target_uid: int, dist: float) -> Vector2:
	var fallback := Vector2(dist, 0)
	if enemy_grid != null and enemy_grid.is_ancestor_of(from_node):
		fallback = Vector2(-dist, 0)
	var target := _find_juice(target_uid)
	if target == null or from_node.size.x < 2.0 or target.size.x < 2.0:
		return fallback
	var from_c := from_node.global_position + from_node.size * 0.5
	var to_c := target.global_position + target.size * 0.5
	var delta := to_c - from_c
	if delta.length() < 4.0:
		return fallback
	return from_node.get_global_transform().affine_inverse().basis_xform(delta).normalized() * dist


func _layer_point(node: Control) -> Vector2:
	var center := node.global_position + node.size * 0.5
	if strike_layer == null:
		return center
	return strike_layer.get_global_transform().affine_inverse() * center


func _pop_wrap(token: Control) -> Control:
	var pop := Control.new()
	pop.name = "MergePop"
	pop.custom_minimum_size = token.custom_minimum_size
	pop.size = token.custom_minimum_size
	pop.pivot_offset = pop.size * 0.5
	pop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	token.position = Vector2.ZERO
	pop.add_child(token)
	return pop


func _play_merge_pop(node: Control) -> void:
	node.scale = Vector2(0.62, 0.62)
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(1.28, 1.28), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _pulse_slot(slot: Control) -> void:
	var pulse := ColorRect.new()
	pulse.color = Color("f6d56b")
	pulse.modulate.a = 0.0
	pulse.set_anchors_preset(Control.PRESET_FULL_RECT)
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pulse.z_index = 4
	slot.add_child(pulse)
	var tw := pulse.create_tween()
	tw.tween_property(pulse, "modulate:a", 0.55, 0.1)
	tw.tween_property(pulse, "modulate:a", 0.0, 0.4)
	tw.finished.connect(pulse.queue_free)


func _hold_attention() -> void:
	var veil := Control.new()
	veil.name = "AttentionHold"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_STOP
	veil.z_index = 80
	add_child(veil)
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.finished.connect(func() -> void:
		if is_instance_valid(veil):
			veil.queue_free()
	)


func _toggle_speed() -> void:
	Game.speed = 2 if Game.speed == 1 else 1
	if speed_button:
		speed_button.text = "SPEED  ▶  ×%d" % Game.speed
	if tick and Game.phase == "combat":
		tick.wait_time = 0.72 / float(maxi(1, Game.speed))


func _on_tick() -> void:
	if _ending or Game.phase != "combat" or Game.combat == null:
		return
	Game.combat_tick()
	_sync_combat()
	if Game.combat != null and Game.combat.over:
		_ending = true
		tick.stop()
		await get_tree().create_timer(0.45).timeout
		_ending = false
		if Game.phase == "combat":
			Game.finish_combat()


func _tease_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.add_child(_tease("Reserve Park — soon", "ReservePark"))
	row.add_child(_tease("Season Trail — soon", "SeasonTrail"))
	return row


func _tease(text: String, node_name: String) -> Button:
	var b := _btn(text, Vector2(280, 42))
	b.name = node_name
	b.disabled = true
	b.tooltip_text = "Tease only — not on the Meadow Circuit."
	b.modulate = Color(1, 1, 1, 0.55)
	return b


func _lbl(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _btn(text: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	return b


func _style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(8)
	s.set_content_margin_all(8)
	return s
