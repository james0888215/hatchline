extends Node

const ECONOMY_PATH := "res://data/economy.json"
const CRITTER_PATH := "res://data/critters.json"
const CIRCUIT_PATH := "res://data/circuit.json"
const ENCOUNTER_PATH := "res://data/encounters.json"
const PROFILE_PATH := "user://profile.json"

signal changed

var phase: String = "start"
var speed: int = 1
var economy: Dictionary = {}
var critters: Dictionary = {}
var critter_order: Array = []
var circuit: Dictionary = {}
var nodes: Dictionary = {}
var encounters: Dictionary = {}
var enemy_defs: Dictionary = {}
var profile: Dictionary = {}
var run: Variant = null
var combat: CombatSim = null
var _combat_done: bool = false


func _ready() -> void:
	_load_data()
	_load_profile()
	phase = "start"


func econ(key: String) -> int:
	return int(economy[key])


func interest_for(coins: int) -> int:
	var per := econ("INTEREST_PER")
	if per <= 0:
		return 0
	return mini(econ("INTEREST_CAP"), int(coins / per))


func reroll_cost() -> int:
	var every := econ("REROLL_SCALE_EVERY")
	var bumps := 0
	if every > 0 and run != null:
		bumps = int(int(run.rerolls) / every)
	return econ("REROLL_COST") + bumps * econ("REROLL_SCALE_STEP")


func buy_cost_for_tier(tier: int) -> int:
	return econ("BUY_T%d" % tier)


func sell_value(tier: int) -> int:
	return econ("SELL_T%d" % tier)


func starter_ids() -> Array:
	var ids: Array = []
	for id in critter_order:
		var c: Dictionary = critters[id]
		if not bool(c.get("starter", false)):
			continue
		if str(c.line) not in profile.unlocked_lines:
			continue
		ids.append(id)
	return ids


func pool_for_tier(tier: int) -> Array:
	var out: Array = []
	for id in critter_order:
		var c: Dictionary = critters[id]
		if int(c.tier) != tier:
			continue
		if str(c.line) not in profile.unlocked_lines:
			continue
		out.append(id)
	return out


func current_node() -> Dictionary:
	return nodes[str(run.node_id)]


func board_count() -> int:
	var n := 0
	if run == null:
		return 0
	for u in run.board:
		if u != null:
			n += 1
	return n


func copy_count(def_id: String) -> int:
	var n := 0
	for u in all_units():
		if str(u.def_id) == def_id:
			n += 1
	return n


func all_units() -> Array:
	var out: Array = []
	if run == null:
		return out
	for u in run.board:
		if u != null:
			out.append(u)
	for u in run.bench:
		if u != null:
			out.append(u)
	return out


func pair_badge(def_id: String) -> String:
	if str(critters[def_id].get("evolves_to", "")) == "":
		return ""
	if copy_count(def_id) == 2:
		return "2/3"
	return ""


func buddy_text(family: String, n: int) -> String:
	if n <= 0:
		return ""
	match family:
		"leaf":
			return "+%d ARM" % (n * econ("LEAF_BUDDY_ARMOR"))
		"ember":
			return "+%d ATK" % (n * econ("EMBER_BUDDY_DAMAGE"))
		"puff":
			return "+%d REG" % (n * econ("PUFF_BUDDY_REGEN"))
		_:
			return ""


func board_buddy_labels() -> Dictionary:
	var labels := {}
	if run == null:
		return labels
	var w := econ("BOARD_W")
	var units: Array = []
	for i in run.board.size():
		var u = run.board[i]
		if u == null:
			continue
		var c: Dictionary = u.duplicate()
		c.pos = Vector2i(i % w, int(i / w))
		c.alive = true
		units.append(c)
	var counts := CombatSim.buddy_counts(units)
	for i in run.board.size():
		var u = run.board[i]
		if u == null:
			continue
		var n := int(counts.get(int(u.uid), 0))
		labels[i] = buddy_text(str(u.family), n)
	return labels


func board_buddy_pairs() -> Array:
	var pairs: Array = []
	if run == null:
		return pairs
	var w := econ("BOARD_W")
	var h := econ("BOARD_H")
	for i in run.board.size():
		var a = run.board[i]
		if a == null:
			continue
		var x: int = int(i) % w
		var y: int = int(i) / w
		if x + 1 < w:
			var right = run.board[i + 1]
			if right != null and str(right.family) == str(a.family):
				pairs.append({"a": i, "b": i + 1, "family": str(a.family)})
		if y + 1 < h and i + w < run.board.size():
			var below = run.board[i + w]
			if below != null and str(below.family) == str(a.family):
				pairs.append({"a": i, "b": i + w, "family": str(a.family)})
	return pairs


func encounter_blurb(enc_id: String) -> String:
	var enc: Dictionary = encounters[enc_id]
	var counts := {}
	var order: Array = []
	for spec in enc.units:
		var n := str(enemy_defs[str(spec.def)].name)
		if not counts.has(n):
			order.append(n)
			counts[n] = 0
		counts[n] = int(counts[n]) + 1
	var bits := PackedStringArray()
	for n in order:
		bits.append("%d× %s" % [int(counts[n]), n])
	return " · ".join(bits)


func leave_label() -> String:
	var node := current_node()
	if str(node.get("leave_label", "")) != "":
		return str(node.leave_label)
	return "Onward"


func debug_reset_profile() -> void:
	if FileAccess.file_exists(PROFILE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	profile = _default_profile()
	_save_profile()
	combat = null
	run = null
	phase = "start"
	speed = 1
	_combat_done = false


func blank_run() -> void:
	_make_run()
	phase = "prep"
	run.node_id = str(circuit.start)
	run.visited = [run.node_id]
	combat = null


func choose_starter(def_id: String) -> void:
	if def_id not in starter_ids():
		return
	_make_run()
	var u := make_unit(def_id)
	run.board[int(run.board.size() / 2)] = u
	discover(def_id)
	var line := str(critters[def_id].line)
	if line in profile.new_lines:
		profile.new_lines.erase(line)
		_save_profile()
	enter_node(str(circuit.start))


func enter_node(id: String) -> void:
	run.node_id = id
	if id not in run.visited:
		run.visited.append(id)
	run.toast = ""
	var node := current_node()
	var kind := str(node.type)
	if kind == "shop":
		run.rerolls = 0
		run.shop = []
		var paid := interest_for(int(run.coins))
		if paid > 0:
			run.coins += paid
			run.toast = "Interest +%d" % paid
		roll_shop(true)
		phase = "prep"
	elif kind == "fight" or kind == "boss":
		phase = "prep"
	elif kind == "fork" or kind == "event":
		phase = "choice"
	else:
		phase = "prep"
	changed.emit()


func leave_node() -> void:
	if phase != "prep" or run == null:
		return
	var node := current_node()
	if str(node.type) != "shop":
		return
	var nxt: Array = node.get("next", [])
	if nxt.is_empty():
		return
	enter_node(str(nxt[0]))


func choose(i: int) -> void:
	if phase != "choice" or run == null:
		return
	var node := current_node()
	var choices: Array = node.get("choices", [])
	if i < 0 or i >= choices.size():
		return
	var choice: Dictionary = choices[i]
	if str(node.type) == "event":
		var note := _apply_event(choice)
		var nxt: Array = node.get("next", [])
		if nxt.is_empty():
			changed.emit()
			return
		enter_node(str(nxt[0]))
		if note != "":
			if str(run.toast) == "":
				run.toast = note
			else:
				run.toast = note + "   ·   " + str(run.toast)
			changed.emit()
		return
	if str(node.type) == "fork":
		enter_node(str(choice.next))


func buy(i: int) -> void:
	if phase != "prep" or run == null:
		return
	if i < 0 or i >= run.shop.size():
		return
	var card: Dictionary = run.shop[i]
	if str(card.def_id) == "":
		return
	var def: Dictionary = critters[str(card.def_id)]
	var cost := buy_cost_for_tier(int(def.tier))
	if int(run.coins) < cost:
		run.toast = "Not enough coins"
		changed.emit()
		return
	var idx := _first_empty(run.bench)
	if idx < 0:
		run.toast = "Bench is full"
		changed.emit()
		return
	run.coins = int(run.coins) - cost
	var u := make_unit(str(card.def_id))
	run.bench[idx] = u
	run.last_uid = int(u.uid)
	discover(str(card.def_id))
	run.shop[i] = {"def_id": "", "frozen": false}
	run.toast = "Bought %s" % u.name
	var line := str(def.line)
	if line in profile.new_lines:
		profile.new_lines.erase(line)
		_save_profile()
	_after_units_changed()


func reroll() -> void:
	if phase != "prep" or run == null:
		return
	if str(current_node().type) != "shop":
		return
	var cost := reroll_cost()
	if int(run.coins) < cost:
		run.toast = "Not enough coins"
		changed.emit()
		return
	run.coins = int(run.coins) - cost
	run.rerolls = int(run.rerolls) + 1
	run.toast = "Reroll -%d" % cost
	roll_shop(false)
	changed.emit()


func toggle_freeze(i: int) -> void:
	if phase != "prep" or run == null:
		return
	if i < 0 or i >= run.shop.size():
		return
	if str(run.shop[i].def_id) == "":
		return
	run.shop[i].frozen = not bool(run.shop[i].frozen)
	if bool(run.shop[i].frozen):
		_advance_stall("freeze")
	changed.emit()


func sell_uid(uid: int) -> void:
	if phase != "prep" or run == null:
		return
	var loc := _loc_of_uid(uid)
	if loc.is_empty():
		return
	_sell_loc(loc)


func handle_drop(zone: String, index: int, data: Dictionary) -> void:
	if phase != "prep" or run == null:
		return
	var uid := int(data.get("uid", -1))
	var from := _loc_of_uid(uid)
	if from.is_empty():
		return
	if zone == "sell":
		_sell_loc(from)
		return
	if str(from.zone) == zone and int(from.index) == index:
		return
	var moving = _peek(from)
	var dest = _peek_at(zone, index)
	if zone == "board" and dest == null and str(from.zone) != "board":
		if board_count() >= econ("BOARD_SOFT_CAP"):
			run.toast = "Soft cap %d — merge or sell first" % econ("BOARD_SOFT_CAP")
			changed.emit()
			return
	_set_at(str(from.zone), int(from.index), dest)
	_set_at(zone, index, moving)
	run.toast = ""
	_after_units_changed()


func resolve_merges() -> Array:
	var done: Array = []
	if run == null:
		return done
	var guard := 0
	while guard < 12:
		guard += 1
		var counts := {}
		for u in all_units():
			var id := str(u.def_id)
			counts[id] = int(counts.get(id, 0)) + 1
		var merged := false
		for def_id in counts.keys():
			if int(counts[def_id]) < 3:
				continue
			var evo := str(critters[def_id].get("evolves_to", ""))
			if evo == "" or not critters.has(evo):
				continue
			var anchor := _pick_anchor(str(def_id))
			if _remove_copies(str(def_id), 3, anchor) < 3:
				continue
			var baby := make_unit(evo)
			_place_at(anchor, baby)
			discover(evo)
			run.flash_uid = int(baby.uid)
			done.append({"from": def_id, "to": evo, "uid": baby.uid})
			merged = true
			break
		if not merged:
			break
	if done.size() > 0:
		var last: Dictionary = done[done.size() - 1]
		var to_c: Dictionary = critters[str(last.to)]
		var from_c: Dictionary = critters[str(last.from)]
		run.merge_flash = {
			"from": str(from_c.name),
			"to": str(to_c.name),
			"tier": int(to_c.tier),
			"family": str(to_c.family),
			"stats": stat_line(to_c),
			"count": done.size(),
		}
	return done


func start_combat() -> void:
	if phase != "prep" or run == null:
		return
	var node := current_node()
	if str(node.type) != "fight" and str(node.type) != "boss":
		return
	run.merge_flash = {}
	run.toast = ""
	var enc: Dictionary = encounters[str(node.encounter)]
	combat = CombatSim.new()
	combat.setup(_combat_player_units(), enc, enemy_defs, economy)
	_combat_done = false
	phase = "combat"
	changed.emit()


func combat_tick() -> void:
	if combat == null or combat.over:
		return
	combat.step()


func finish_combat() -> void:
	if _combat_done or combat == null or run == null:
		return
	_combat_done = true
	if not combat.player_won:
		_end_run(false, combat.defeat_reason())
		return
	var node := current_node()
	var reward := int(node.get("reward", 0))
	run.coins = int(run.coins) + reward
	var title := str(node.title)
	if str(node.type) == "boss":
		run.toast = "%s clear" % title
		_end_run(true, "The Matron curtseys. Your menagerie holds.")
		return
	var saved := "%s clear  +%d coins" % [title, reward]
	var nxt: Array = node.get("next", [])
	if nxt.is_empty():
		run.toast = saved
		_end_run(true, "The path ends.")
		return
	enter_node(str(nxt[0]))
	if str(run.toast) == "":
		run.toast = saved
	else:
		run.toast = saved + "   ·   " + str(run.toast)
	changed.emit()


func retry() -> void:
	combat = null
	run = null
	phase = "start"
	changed.emit()


func make_unit(def_id: String) -> Dictionary:
	var c: Dictionary = critters[def_id]
	run.next_uid = int(run.next_uid) + 1
	return {
		"uid": int(run.next_uid),
		"def_id": def_id,
		"name": str(c.name),
		"family": str(c.family),
		"line": str(c.line),
		"tier": int(c.tier),
		"hp": int(c.hp),
		"max_hp": int(c.hp),
		"atk": int(c.atk),
		"armor": int(c.armor),
		"regen": int(c.get("regen", 0)),
		"thorns": int(c.get("thorns", 0)),
		"splash": int(c.get("splash", 0)),
		"burn_applied": int(c.get("burn", 0)),
		"mend": str(c.get("mend", "")),
		"evolves_to": str(c.get("evolves_to", "")),
		"blurb": str(c.get("blurb", "")),
	}


func stat_line(c: Dictionary) -> String:
	var bits: Array = []
	bits.append("%d HP" % int(c.hp))
	bits.append("%d ATK" % int(c.atk))
	bits.append("%d ARM" % int(c.armor))
	if int(c.get("regen", 0)) > 0:
		bits.append("%d REG" % int(c.regen))
	if int(c.get("thorns", 0)) > 0:
		bits.append("Thorns %d" % int(c.thorns))
	if int(c.get("splash", 0)) > 0:
		bits.append("Splash %d%%" % int(c.splash))
	if int(c.get("burn", 0)) > 0:
		bits.append("Burn %d" % int(c.burn))
	var mend := str(c.get("mend", ""))
	if mend == "one":
		bits.append("Mend")
	elif mend == "all":
		bits.append("Mend all")
	return "  ·  ".join(PackedStringArray(bits))


func discover(def_id: String) -> void:
	if def_id in profile.discovered:
		return
	profile.discovered.append(def_id)
	if run != null and def_id not in run.new_dex:
		run.new_dex.append(def_id)
	_save_profile()


func roll_shop(teach: bool) -> void:
	if run.shop.is_empty():
		run.shop = _empty_shop()
	var node := current_node()
	var tier := str(int(node.get("shop_tier", 1)))
	var odds: Dictionary = economy["SHOP_ODDS"][tier]
	var teach_id := ""
	if teach and bool(node.get("teach_copy", false)):
		teach_id = _teach_copy_id()
	for i in run.shop.size():
		var slot: Dictionary = run.shop[i]
		if bool(slot.get("frozen", false)) and str(slot.get("def_id", "")) != "":
			continue
		var picked := ""
		if i == 0 and teach_id != "":
			picked = teach_id
			teach_id = ""
		else:
			picked = _roll_def(odds)
		run.shop[i] = {"def_id": picked, "frozen": false}


func _end_run(won: bool, line: String) -> void:
	var unlock := _finish_profile(won)
	var dex: Array = run.new_dex.duplicate()
	phase = "result"
	run.result = {
		"won": won,
		"line": line,
		"unlock": unlock,
		"new_dex": dex,
	}
	combat = null
	changed.emit()


func _finish_profile(won: bool) -> String:
	profile.runs = int(profile.runs) + 1
	if won:
		profile.wins = int(profile.wins) + 1
	var msg := ""
	var line := str(circuit.meta.unlock_line)
	if line not in profile.unlocked_lines:
		profile.unlocked_lines.append(line)
		if line not in profile.new_lines:
			profile.new_lines.append(line)
		msg = "New egg-line: %s.\nIt shows up in the shop." % str(circuit.meta.unlock_name)
	_save_profile()
	return msg


func _apply_event(choice: Dictionary) -> String:
	var effect := str(choice.get("effect", ""))
	if effect == "coins":
		var n := econ("EVENT_COIN_GIFT")
		run.coins = int(run.coins) + n
		return "Tip jar +%d" % n
	if effect == "egg":
		var pool := pool_for_tier(1)
		if pool.is_empty():
			return "The basket was empty"
		var id := str(pool[randi() % pool.size()])
		var u := make_unit(id)
		var idx := _first_empty(run.bench)
		if idx >= 0:
			run.bench[idx] = u
		elif board_count() < econ("BOARD_SOFT_CAP"):
			var bidx := _first_empty(run.board)
			run.board[bidx] = u
		else:
			run.coins = int(run.coins) + 2
			return "Bench full — the egg became 2 coins"
		discover(id)
		resolve_merges()
		return "Free egg: %s" % str(critters[id].name)
	return ""


func _after_units_changed() -> void:
	resolve_merges()
	_advance_stall("pair")
	changed.emit()


func _advance_stall(kind: String) -> void:
	if run == null or str(run.node_id) != "shop_a":
		return
	var step := int(run.get("stall_step", 0))
	if kind == "freeze" and step < 1:
		run.stall_step = 1
	elif kind == "pair" and _has_pair() and step < 2:
		run.stall_step = 1 if step < 1 else 2


func _has_pair() -> bool:
	var seen := {}
	for u in all_units():
		var id := str(u.def_id)
		if seen.has(id):
			continue
		seen[id] = true
		if copy_count(id) == 2:
			return true
	return false


func _combat_player_units() -> Array:
	var out: Array = []
	var w := econ("BOARD_W")
	for i in run.board.size():
		var u = run.board[i]
		if u == null:
			continue
		var c: Dictionary = u.duplicate()
		c.side = "ally"
		c.alive = true
		c.pos = Vector2i(i % w, int(i / w))
		c.hp = int(c.max_hp)
		c.burn_dmg = 0
		c.burn_left = 0
		c.boss = false
		out.append(c)
	return out


func _teach_copy_id() -> String:
	var options: Array = []
	var seen := {}
	for u in all_units():
		var id := str(u.def_id)
		if seen.has(id):
			continue
		seen[id] = true
		var c: Dictionary = critters[id]
		if int(c.tier) != 1:
			continue
		if str(c.get("evolves_to", "")) == "":
			continue
		if copy_count(id) >= 3:
			continue
		options.append(id)
	if options.is_empty():
		return ""
	return str(options[randi() % options.size()])


func _roll_def(odds: Dictionary) -> String:
	var tiers: Array = []
	var weights: Array = []
	var total := 0
	for key in odds.keys():
		var w := int(odds[key])
		if w <= 0:
			continue
		var pool := pool_for_tier(int(key))
		if pool.is_empty():
			continue
		tiers.append(int(key))
		weights.append(w)
		total += w
	if total <= 0:
		return ""
	var r := randi() % total
	var acc := 0
	var chosen := int(tiers[0])
	for i in tiers.size():
		acc += int(weights[i])
		if r < acc:
			chosen = int(tiers[i])
			break
	var pool := pool_for_tier(chosen)
	return str(pool[randi() % pool.size()])


func _empty_shop() -> Array:
	var slots: Array = []
	for _i in econ("SHOP_SLOTS"):
		slots.append({"def_id": "", "frozen": false})
	return slots


func _make_run() -> void:
	var cells := econ("BOARD_W") * econ("BOARD_H")
	var board: Array = []
	board.resize(cells)
	for i in board.size():
		board[i] = null
	var bench: Array = []
	bench.resize(econ("BENCH_SLOTS"))
	for i in bench.size():
		bench[i] = null
	run = {
		"coins": econ("STARTING_COINS"),
		"node_id": "",
		"board": board,
		"bench": bench,
		"shop": [],
		"rerolls": 0,
		"next_uid": 0,
		"last_uid": -1,
		"visited": [],
		"toast": "",
		"merge_flash": {},
		"flash_uid": -1,
		"seed": randi() % 1000000,
		"new_dex": [],
		"result": {},
	}
	seed(int(run.seed))


func _pick_anchor(def_id: String) -> Dictionary:
	var locs := _locs(def_id)
	for loc in locs:
		if str(loc.zone) == "board":
			return loc
	return locs[0]


func _remove_copies(def_id: String, n: int, anchor: Dictionary) -> int:
	var locs := _locs(def_id)
	var remove: Array = [anchor]
	var bench_locs: Array = []
	var other: Array = []
	for loc in locs:
		if str(loc.zone) == str(anchor.zone) and int(loc.index) == int(anchor.index):
			continue
		if str(loc.zone) == "bench":
			bench_locs.append(loc)
		else:
			other.append(loc)
	for loc in bench_locs:
		if remove.size() >= n:
			break
		remove.append(loc)
	for loc in other:
		if remove.size() >= n:
			break
		remove.append(loc)
	if remove.size() < n:
		return 0
	var board_idx: Array = []
	var bench_idx: Array = []
	for loc in remove:
		if str(loc.zone) == "board":
			board_idx.append(int(loc.index))
		else:
			bench_idx.append(int(loc.index))
	board_idx.sort()
	bench_idx.sort()
	board_idx.reverse()
	bench_idx.reverse()
	for i in board_idx:
		run.board[i] = null
	for i in bench_idx:
		run.bench[i] = null
	return n


func _place_at(anchor: Dictionary, unit: Dictionary) -> void:
	if str(anchor.zone) == "board":
		run.board[int(anchor.index)] = unit
	else:
		run.bench[int(anchor.index)] = unit


func _locs(def_id: String) -> Array:
	var out: Array = []
	for i in run.board.size():
		var u = run.board[i]
		if u != null and str(u.def_id) == def_id:
			out.append({"zone": "board", "index": i})
	for i in run.bench.size():
		var u = run.bench[i]
		if u != null and str(u.def_id) == def_id:
			out.append({"zone": "bench", "index": i})
	return out


func _loc_of_uid(uid: int) -> Dictionary:
	for i in run.board.size():
		var u = run.board[i]
		if u != null and int(u.uid) == uid:
			return {"zone": "board", "index": i}
	for i in run.bench.size():
		var u = run.bench[i]
		if u != null and int(u.uid) == uid:
			return {"zone": "bench", "index": i}
	return {}


func _peek(loc: Dictionary):
	return _peek_at(str(loc.zone), int(loc.index))


func _peek_at(zone: String, index: int):
	if zone == "board":
		return run.board[index]
	if zone == "bench":
		return run.bench[index]
	return null


func _set_at(zone: String, index: int, unit) -> void:
	if zone == "board":
		run.board[index] = unit
	elif zone == "bench":
		run.bench[index] = unit


func _sell_loc(loc: Dictionary) -> void:
	var u = _peek(loc)
	if u == null:
		return
	var gain := sell_value(int(u.tier))
	run.coins = int(run.coins) + gain
	_set_at(str(loc.zone), int(loc.index), null)
	run.toast = "Sold %s +%d" % [u.name, gain]
	_after_units_changed()


func _first_empty(arr: Array) -> int:
	for i in arr.size():
		if arr[i] == null:
			return i
	return -1


func _load_data() -> void:
	economy = _read_json(ECONOMY_PATH)
	var cdef := _read_json(CRITTER_PATH)
	critters = {}
	critter_order = []
	for c in cdef.critters:
		critters[str(c.id)] = c
		critter_order.append(str(c.id))
	circuit = _read_json(CIRCUIT_PATH)
	nodes = {}
	for n in circuit.nodes:
		nodes[str(n.id)] = n
	var edef := _read_json(ENCOUNTER_PATH)
	enemy_defs = {}
	encounters = {}
	for key in edef.defs.keys():
		enemy_defs[str(key)] = edef.defs[key]
	for key in edef.encounters.keys():
		encounters[str(key)] = edef.encounters[key]


func _read_json(path: String) -> Dictionary:
	var txt := FileAccess.get_file_as_string(path)
	if txt == "":
		push_error("Missing " + path)
		return {}
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Bad JSON " + path)
		return {}
	return parsed


func _default_profile() -> Dictionary:
	var lines: Array = []
	for id in circuit.meta.starting_lines:
		lines.append(str(id))
	return {
		"runs": 0,
		"wins": 0,
		"discovered": [],
		"unlocked_lines": lines,
		"new_lines": [],
		"seen_sell": false,
	}


func _load_profile() -> void:
	profile = _default_profile()
	if not FileAccess.file_exists(PROFILE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROFILE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	profile.runs = int(parsed.get("runs", 0))
	profile.wins = int(parsed.get("wins", 0))
	profile.discovered = parsed.get("discovered", [])
	var unlocked: Array = parsed.get("unlocked_lines", profile.unlocked_lines)
	profile.unlocked_lines = []
	for id in unlocked:
		profile.unlocked_lines.append(str(id))
	for id in circuit.meta.starting_lines:
		if str(id) not in profile.unlocked_lines:
			profile.unlocked_lines.append(str(id))
	profile.new_lines = []
	for id in parsed.get("new_lines", []):
		profile.new_lines.append(str(id))
	profile.seen_sell = bool(parsed.get("seen_sell", false))
	var discovered: Array = []
	for id in profile.discovered:
		discovered.append(str(id))
	profile.discovered = discovered


func note_sell_once() -> void:
	if bool(profile.get("seen_sell", false)):
		return
	profile.seen_sell = true
	_save_profile()
	if run == null:
		return
	var hint := "Drag a critter onto Sell."
	if str(run.toast) == "":
		run.toast = hint
	elif hint not in str(run.toast):
		run.toast = str(run.toast) + "   ·   " + hint


func _save_profile() -> void:
	var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Could not save profile")
		return
	f.store_string(JSON.stringify(profile, "\t"))
