extends Control

const SLOT := preload("res://scripts/slot.gd")
const TOKENS := preload("res://scripts/token.gd")

const CREAM := Color("f6f1e7")
const INK := Color("243042")
const MUTED := Color("8a847a")
const GOLD := Color("c8922a")
const GOOD := Color("2f7d4a")
const BAD := Color("a33b32")
const SLOT_EMPTY := Color("efeae0")

var host: Control
var tick: Timer
var flash_timer: Timer
var _rebuild_queued := false
var dex_open := false
var _ending := false

var ally_grid: GridContainer
var enemy_grid: GridContainer
var log_label: Label
var banner_panel: Panel
var banner_label: Label
var round_label: Label
var speed_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
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
	else:
		flash_timer.stop()
	if Game.phase == "combat" and Game.combat != null and not Game.combat.over:
		tick.wait_time = 0.72 / float(maxi(1, Game.speed))
		tick.start()


func _clear_host() -> void:
	if host == null:
		return
	for c in host.get_children():
		host.remove_child(c)
		c.free()
	ally_grid = null
	enemy_grid = null
	log_label = null
	banner_panel = null
	banner_label = null
	round_label = null
	speed_button = null


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
	page.add_child(_lbl("Meadow Circuit  ·  greybox", 18, MUTED))
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
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
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
	b.custom_minimum_size = Vector2(280, 168)
	var tag := ""
	if str(c.line) in Game.profile.new_lines:
		tag = "NEW\n"
	b.text = "%s%s\n%s · T%d\n%s\n%s" % [tag, c.name, str(c.family).capitalize(), int(c.tier), Game.stat_line(c), c.blurb]
	b.add_theme_font_size_override("font_size", 15)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var tex := TOKENS.texture(str(c.family), int(c.tier))
	if tex != null:
		b.icon = tex
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 84)
	b.add_theme_stylebox_override("normal", _style(Color("fffdf8"), INK, 3))
	b.add_theme_stylebox_override("hover", _style(Color("fff6e4"), INK, 3))
	b.add_theme_stylebox_override("pressed", _style(Color("f3e6cc"), INK, 3))
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
			row.add_child(TOKENS.make(str(c.family), int(c.tier), 40.0))
		var lab := _lbl("✓ %s  T%d" % [c.name, int(c.tier)] if known else "???", 13, INK if known else MUTED)
		lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(lab)
		panel.add_child(row)
		grid.add_child(panel)
	return grid


func _build_prep(page: VBoxContainer) -> void:
	page.add_child(_run_header())
	var flash := _flash_bar()
	if flash:
		page.add_child(flash)
	if str(Game.run.toast) != "":
		page.add_child(_lbl(str(Game.run.toast), 15, GOOD))
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
	page.add_child(_run_header())
	var enc_id := str(Game.current_node().encounter)
	var enc: Dictionary = Game.encounters[enc_id]
	var combat_trait := _lbl(str(enc.trait), 16, INK)
	combat_trait.name = "TraitLabel"
	page.add_child(combat_trait)
	banner_panel = Panel.new()
	banner_panel.custom_minimum_size = Vector2(0, 42)
	banner_panel.add_theme_stylebox_override("panel", _style(Color("f6d56b"), INK, 2))
	banner_label = _lbl("", 20, INK)
	banner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_panel.add_child(banner_label)
	page.add_child(banner_panel)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	page.add_child(body)
	ally_grid = _combat_grid()
	enemy_grid = _combat_grid()
	body.add_child(ally_grid)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.custom_minimum_size = Vector2(280, 0)
	body.add_child(mid)
	round_label = _lbl("Round 0", 16, INK)
	round_label.name = "RoundLabel"
	mid.add_child(round_label)
	speed_button = _btn("Speed ×%d" % Game.speed, Vector2(140, 40))
	speed_button.name = "SpeedButton"
	speed_button.pressed.connect(_toggle_speed)
	mid.add_child(speed_button)
	log_label = _lbl("", 14, INK)
	log_label.name = "CombatLog"
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_child(log_label)
	body.add_child(enemy_grid)
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
		var card := Panel.new()
		card.name = "UnlockCard"
		card.custom_minimum_size = Vector2(0, 72)
		card.add_theme_stylebox_override("panel", _style(Color("fffdf8"), INK, 3))
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 10)
		row.add_child(TOKENS.make("leaf", 1, 48.0))
		var inner := _lbl(str(result.unlock), 18, INK)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(inner)
		card.add_child(row)
		page.add_child(card)
	var again := _btn("Again" if won else "Retry", Vector2(280, 64))
	again.name = "RetryButton"
	again.add_theme_font_size_override("font_size", 22)
	again.pressed.connect(Game.retry)
	page.add_child(again)
	page.add_child(_tease_row())


func _run_header() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _lbl("HATCHLINE", 20, INK)
	top.add_child(title)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(gap)
	var node := Game.current_node()
	top.add_child(_lbl(str(node.title), 18, INK))
	top.add_child(_lbl("   coins %d" % int(Game.run.coins), 18, GOLD))
	top.add_child(_lbl("   interest +%d" % Game.interest_for(int(Game.run.coins)), 14, MUTED))
	top.add_child(_lbl("   seed %s" % str(Game.run.seed), 12, MUTED))
	box.add_child(top)
	box.add_child(_ribbon())
	return box


func _ribbon() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cur := str(Game.run.node_id)
	var visited: Array = Game.run.visited
	var steps: Array = Game.circuit.ribbon
	for s in steps.size():
		var step: Dictionary = steps[s]
		var ids: Array = step.ids
		var active: bool = cur in ids
		var past := false
		if not active:
			for id in ids:
				if id in visited:
					past = true
		var lab := _lbl(str(step.label), 15 if active else 13, INK if active else (GOOD if past else MUTED))
		row.add_child(lab)
		if s < steps.size() - 1:
			row.add_child(_lbl("·", 13, MUTED))
	return row


func _flash_bar() -> Control:
	if Game.run == null or Game.run.merge_flash.is_empty():
		return null
	var f: Dictionary = Game.run.merge_flash
	var panel := Panel.new()
	panel.name = "MergeFlash"
	panel.custom_minimum_size = Vector2(0, 72)
	panel.add_theme_stylebox_override("panel", _style(Color("fff6e4"), GOLD, 3))
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	row.add_child(TOKENS.make(str(f.family), int(f.tier), 52.0))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := "TRIPLE    %s    →    %s" % [f.from, f.to]
	if int(f.count) > 1:
		title = "TRIPLE ×%d    %s    →    %s" % [int(f.count), f.from, f.to]
	var a := _lbl(title, 22, INK)
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := _lbl("Tier %d power spike     %s" % [int(f.tier), f.stats], 14, INK)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(a)
	box.add_child(b)
	row.add_child(box)
	panel.add_child(row)
	return panel


func _bench_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(236, 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_lbl("Bench", 16, INK))
	for i in Game.run.bench.size():
		var slot := _make_slot("bench", i, Game.run.bench[i], 236, 78, true)
		slot.name = "Bench%d" % i
		col.add_child(slot)
	return col


func _board_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_lbl("Board  %d/%d" % [Game.board_count(), Game.econ("BOARD_SOFT_CAP")], 16, INK))
	var grid := GridContainer.new()
	grid.columns = Game.econ("BOARD_W")
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var buddies := Game.board_buddy_labels()
	for i in Game.run.board.size():
		var slot := _make_slot("board", i, Game.run.board[i], 168, 132, true)
		slot.name = "Board%d" % i
		if Game.run.board[i] != null and str(buddies.get(i, "")) != "":
			var tag := _lbl(str(buddies[i]), 13, INK)
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			slot.get_node("Margin/SlotBody").add_child(tag)
		grid.add_child(slot)
	col.add_child(grid)
	var legend := "Orthogonal buddies — Leaf +%d armour, Ember +%d damage, Puff +%d regen, per neighbour." % [
		Game.econ("LEAF_BUDDY_ARMOR"), Game.econ("EMBER_BUDDY_DAMAGE"), Game.econ("PUFF_BUDDY_REGEN")
	]
	var leg := _lbl(legend, 13, MUTED)
	leg.name = "BuddyLegend"
	leg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(leg)
	return col


func _right_column() -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(300, 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var node := Game.current_node()
	if str(node.type) == "shop":
		col.add_child(_lbl(str(node.title), 16, INK))
		col.add_child(_lbl("Freeze keeps a card. Pairs sit at 2/3 until the third evolves.", 12, MUTED))
		for i in Game.run.shop.size():
			col.add_child(_shop_card(i))
		var cost := Game.reroll_cost()
		var reroll := _btn("Reroll  %d" % cost, Vector2(200, 36))
		reroll.name = "RerollButton"
		reroll.pressed.connect(Game.reroll)
		col.add_child(reroll)
		col.add_child(_lbl("1 coin per %d saved · cap %d" % [Game.econ("INTEREST_PER"), Game.econ("INTEREST_CAP")], 12, MUTED))
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
	row.add_child(TOKENS.make(str(c.family), int(c.tier), 64.0))
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 1)
	var name := str(c.name)
	if frozen:
		name = "FROZEN  " + name
	var title := _lbl("%s   %s T%d" % [name, str(c.family).capitalize(), int(c.tier)], 14, INK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)
	var stats := _lbl(Game.stat_line(c), 12, INK)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stats)
	var actions := HBoxContainer.new()
	actions.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_theme_constant_override("separation", 6)
	var buy := _btn("Buy %d" % Game.buy_cost_for_tier(int(c.tier)), Vector2(96, 28))
	buy.name = "BuyButton%d" % i
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
			panel.add_theme_stylebox_override("panel", _style(SLOT_EMPTY, INK, 2))
			var box := VBoxContainer.new()
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_theme_constant_override("separation", 0)
			var holder := CenterContainer.new()
			holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			holder.add_child(TOKENS.make(str(d.family), 1, 46.0, boss))
			box.add_child(holder)
			var lab := _lbl(str(d.name), 11, INK)
			lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(lab)
			panel.add_child(box)
		else:
			panel.add_theme_stylebox_override("panel", _style(SLOT_EMPTY, Color("ddd6c8"), 1))
		grid.add_child(panel)
	return grid


func _sell_zone() -> Control:
	var slot := _make_slot("sell", -1, null, 420, 64, false)
	slot.name = "SellZone"
	slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lab := _lbl("Drag a critter here to sell    ·    T1 returns %d    T2 returns %d    T3 returns %d" % [
		Game.econ("SELL_T1"), Game.econ("SELL_T2"), Game.econ("SELL_T3")
	], 14, BAD)
	lab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.get_node("Margin/SlotBody").add_child(lab)
	return slot


func _make_slot(zone: String, index: int, unit, w: float, h: float, show_sell: bool) -> Panel:
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
		border = GOLD if flash else INK
		width = 4 if flash else 2
		slot.set("preview_family", str(unit.family))
		slot.set("preview_tier", int(unit.tier))
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
	var wide := w > h + 40.0
	var token := TOKENS.make(str(unit.family), int(unit.tier), 52.0 if wide else 46.0)
	var name := _lbl("%s  T%d" % [unit.name, int(unit.tier)], 14, INK)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var meta := _lbl("%d HP   %d ATK   %d ARM" % [int(unit.max_hp), int(unit.atk), int(unit.armor)], 13, INK)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texts := VBoxContainer.new()
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.add_theme_constant_override("separation", 0)
	texts.add_child(name)
	texts.add_child(meta)
	var badge := Game.pair_badge(str(unit.def_id))
	if badge != "":
		var b := _lbl(badge + "  waiting", 13, BAD)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(b)
	if show_sell:
		var sell := _btn("Sell %d" % Game.sell_value(int(unit.tier)), Vector2(78, 24))
		sell.add_theme_font_size_override("font_size", 13)
		sell.pressed.connect(Game.sell_uid.bind(int(unit.uid)))
		texts.add_child(sell)
	if wide:
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		row.add_child(token)
		row.add_child(texts)
		body.add_child(row)
	else:
		var holder := CenterContainer.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		holder.add_child(token)
		body.add_child(holder)
		body.add_child(texts)
	return slot


func _combat_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = Game.econ("BOARD_W")
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return grid


func _sync_combat() -> void:
	if Game.combat == null or ally_grid == null:
		return
	var sim: CombatSim = Game.combat
	if round_label:
		round_label.text = "Round %d" % sim.round_i
	if banner_panel and banner_label:
		banner_panel.visible = sim.banner != ""
		banner_label.text = sim.banner
	if log_label:
		var start := maxi(0, sim.log_lines.size() - 8)
		var lines := PackedStringArray()
		for i in range(start, sim.log_lines.size()):
			lines.append(str(sim.log_lines[i]))
		log_label.text = "\n".join(lines)
	_fill_combat_grid(ally_grid, sim.allies, false)
	_fill_combat_grid(enemy_grid, sim.enemies, true)


func _fill_combat_grid(grid: GridContainer, units: Array, enemy: bool) -> void:
	for c in grid.get_children():
		grid.remove_child(c)
		c.free()
	var w := Game.econ("BOARD_W")
	var cells := w * Game.econ("BOARD_H")
	var by_pos := {}
	for u in units:
		var x: int
		var y: int
		if enemy:
			x = int(u.local_x)
			y = int(u.local_y)
		else:
			x = int(u.pos.x)
			y = int(u.pos.y)
		by_pos[y * w + x] = u
	for i in cells:
		grid.add_child(_combat_cell(by_pos.get(i, null)))


func _combat_cell(unit) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(148, 152)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unit == null:
		panel.add_theme_stylebox_override("panel", _style(SLOT_EMPTY, Color("ddd6c8"), 1))
		return panel
	var alive: bool = bool(unit.alive)
	panel.add_theme_stylebox_override("panel", _style(SLOT_EMPTY, INK if alive else Color("b7b1a6"), 2))
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)
	var name := _lbl(str(unit.name), 14, INK if alive else MUTED)
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name)
	var token := TOKENS.make(str(unit.family), int(unit.get("tier", 1)), 52.0, bool(unit.get("boss", false)))
	if not alive:
		token.modulate = Color(0.62, 0.62, 0.64)
	var holder := CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_child(token)
	box.add_child(holder)
	var hp := int(unit.hp)
	var mx := int(unit.max_hp)
	var hp_l := _lbl("%d/%d%s" % [hp, mx, "" if alive else "  fainted"], 14, INK)
	hp_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hp_l)
	box.add_child(_hp_bar(hp, mx))
	var atk := int(unit.atk) + int(unit.bonus_atk)
	var arm := int(unit.armor) + int(unit.bonus_armor)
	var stats := _lbl("%d ATK   %d ARM" % [atk, arm], 13, INK)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stats)
	var bonus := ""
	if int(unit.bonus_armor) > 0:
		bonus = "+%d ARM" % int(unit.bonus_armor)
	elif int(unit.bonus_atk) > 0:
		bonus = "+%d ATK" % int(unit.bonus_atk)
	elif int(unit.bonus_regen) > 0:
		bonus = "+%d REG" % int(unit.bonus_regen)
	if bonus != "":
		var b := _lbl(bonus, 13, INK)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(b)
	return panel


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


func _toggle_speed() -> void:
	Game.speed = 2 if Game.speed == 1 else 1
	if speed_button:
		speed_button.text = "Speed ×%d" % Game.speed
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
