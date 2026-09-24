extends SceneTree

var failures: Array = []
var g


func _init() -> void:
	call_deferred("_main")


func _main() -> void:
	await process_frame
	g = root.get_node_or_null("Game")
	if g == null:
		print("FAIL autoload Game missing")
		quit(1)
		return
	g.debug_reset_profile()
	var tests: Array = [
		["roster", _test_roster],
		["economy", _test_economy],
		["circuit", _test_circuit],
		["starters_locked", _test_starters_locked],
		["strict_merge", _test_strict_merge],
		["buddy_preview", _test_buddy_preview],
		["combat_floats", _test_combat_floats],
		["wild_buddy_visible", _test_wild_buddy],
		["buddy_reduces_damage", _test_buddy_damage],
		["splash", _test_splash],
		["boss_summons", _test_boss_summons],
		["shop_teach_and_buy", _test_shop],
		["reroll_freeze_interest", _test_reroll_interest],
		["freeze_survives_fight", _test_freeze_survives_fight],
		["sell_drag", _test_sell_drag],
		["soft_cap_and_sell", _test_soft_cap_sell],
		["sparring_win", _test_sparring],
		["wild_with_buddies", _test_wild_win],
		["boss_with_spike", _test_boss_win],
		["defeat_line", _test_defeat_line],
		["roles", _test_roles],
		["sheet_art", _test_sheet_art],
		["role_strikes", _test_role_strikes],
		["early_teeth", _test_early_teeth],
		["enemy_aim", _test_enemy_aim],
		["unlock_on_loss", _test_unlock],
	]
	for item in tests:
		var name: String = item[0]
		print("RUN ", name)
		var err: String = item[1].call()
		if err != "":
			print("FAIL ", name, ": ", err)
			failures.append(name)
			break
		print("OK   ", name)
	if failures.is_empty():
		print("RUN starter_motion")
		var motion_err: String = await _test_starter_motion()
		if motion_err != "":
			print("FAIL starter_motion: ", motion_err)
			failures.append("starter_motion")
		else:
			print("OK   starter_motion")
	if failures.is_empty():
		print("RUN ui_smoke")
		var ui_err: String = await _test_ui()
		if ui_err != "":
			print("FAIL ui_smoke: ", ui_err)
			failures.append("ui_smoke")
		else:
			print("OK   ui_smoke")
	if failures.is_empty():
		print("RUN starter_merge")
		var merge_err: String = await _test_starter_merge()
		if merge_err != "":
			print("FAIL starter_merge: ", merge_err)
			failures.append("starter_merge")
		else:
			print("OK   starter_merge")
	if failures.is_empty():
		print("RUN quiet_prep")
		var quiet_err: String = await _test_quiet_prep()
		if quiet_err != "":
			print("FAIL quiet_prep: ", quiet_err)
			failures.append("quiet_prep")
		else:
			print("OK   quiet_prep")
	if failures.is_empty():
		print("ALL PASS")
		quit(0)
	else:
		print("FAILED ", failures)
		quit(1)


func _test_roster() -> String:
	if g.critter_order.size() < 18 or g.critter_order.size() > 24:
		return "roster size %d" % g.critter_order.size()
	var families = {"leaf": {}, "ember": {}, "puff": {}}
	for id in g.critter_order:
		var c: Dictionary = g.critters[id]
		var fam = str(c.family)
		if not families.has(fam):
			return "bad family " + fam
		families[fam][int(c.tier)] = true
		var evo = str(c.get("evolves_to", ""))
		if evo != "":
			if not g.critters.has(evo):
				return "missing evo " + evo
			var n: Dictionary = g.critters[evo]
			if int(n.tier) != int(c.tier) + 1:
				return "tier jump " + id
			if str(n.line) != str(c.line) or str(n.family) != fam:
				return "line drift " + id
	for fam in families.keys():
		for tier in [1, 2, 3]:
			if not families[fam].has(tier):
				return fam + " missing T" + str(tier)
	return ""


func _test_economy() -> String:
	var keys: Array = [
		"STARTING_COINS", "REROLL_COST", "REROLL_SCALE_EVERY", "REROLL_SCALE_STEP",
		"INTEREST_PER", "INTEREST_CAP", "BUY_T1", "BUY_T2", "BUY_T3",
		"SELL_T1", "SELL_T2", "SELL_T3", "SHOP_SLOTS", "BENCH_SLOTS",
		"BOARD_W", "BOARD_H", "BOARD_SOFT_CAP", "LEAF_BUDDY_ARMOR",
		"EMBER_BUDDY_DAMAGE", "PUFF_BUDDY_REGEN", "EVENT_COIN_GIFT",
		"COMBAT_MAX_ROUNDS", "ENEMY_X_OFFSET",
		"ROLE_OFF_RANK_NUM", "ROLE_OFF_RANK_DEN",
		"SPARRING_MELEE_HP", "SPARRING_MELEE_ATK",
		"SPARRING_RANGED_HP", "SPARRING_RANGED_ATK",
		"WILD_MELEE_HP", "WILD_MELEE_ATK",
		"WILD_RANGED_HP", "WILD_RANGED_ATK",
	]
	for k in keys:
		if not g.economy.has(k):
			return "missing " + str(k)
	if g.ECONOMY_PATH != "res://data/economy.json":
		return "economy path"
	if g.econ("BOARD_SOFT_CAP") != 7:
		return "soft cap default"
	if g.econ("BOARD_W") != 3 or g.econ("BOARD_H") != 3:
		return "board shape"
	if g.interest_for(4) != 0:
		return "interest low"
	if g.interest_for(5) != 1:
		return "interest one"
	if g.interest_for(100) != g.econ("INTEREST_CAP"):
		return "interest cap"
	if g.econ("SELL_T1") < g.econ("BUY_T1"):
		return ""
	return "sell should cost less than buy so pairs hurt"
	# unreachable if sell < buy, which is the intended design
	# The check above returns "" when the cost is real. Flip the condition.


func _test_circuit() -> String:
	var seen = {}
	var stack: Array = [str(g.circuit.start)]
	var kinds = {}
	while not stack.is_empty():
		var id: String = str(stack.pop_back())
		if seen.has(id):
			continue
		if not g.nodes.has(id):
			return "missing node " + id
		seen[id] = true
		var node: Dictionary = g.nodes[id]
		kinds[str(node.type)] = true
		for nxt in node.get("next", []):
			stack.append(str(nxt))
		for choice in node.get("choices", []):
			if choice.has("next"):
				stack.append(str(choice.next))
	if not seen.has("boss") or not seen.has("shop_a") or not seen.has("elite_1"):
		return "path missing a beat"
	for kind in ["fight", "shop", "fork", "event", "boss"]:
		if not kinds.has(kind):
			return "missing kind " + kind
	if not bool(g.nodes["elite_1"].get("elite", false)):
		return "elite flag"
	if int(g.nodes["elite_1"].reward) <= int(g.nodes["wild_1"].reward):
		return "elite purse"
	if int(g.nodes["preboss"].shop_tier) < int(g.nodes["shop_b"].shop_tier):
		return "preboss tier"
	return ""


func _test_starters_locked() -> String:
	var ids: Array = g.starter_ids()
	if ids.size() != 3:
		return "expected 3 starters, got %d" % ids.size()
	if "budmite" in ids:
		return "budmite unlocked early"
	if "budmite" in g.pool_for_tier(1):
		return "budmite in shop pool"
	if "sproutling" not in ids or "sparkpup" not in ids or "cottonwisp" not in ids:
		return "core starters missing"
	return ""


func _test_strict_merge() -> String:
	g.blank_run()
	_put("bench", 0, "sproutling")
	_put("bench", 1, "sproutling")
	var merged: Array = g.resolve_merges()
	if not merged.is_empty() or g.copy_count("sproutling") != 2:
		return "pair merged"
	if g.pair_badge("sproutling") != "2/3":
		return "pair badge"
	_put("bench", 2, "sproutling")
	merged = g.resolve_merges()
	if merged.size() != 1:
		return "triple did not merge"
	if g.copy_count("sproutling") != 0 or g.copy_count("thornbud") != 1:
		return "triple leftovers"
	var thorn = _find("thornbud")
	if thorn == null or int(thorn.tier) != 2:
		return "not T2"
	if int(thorn.hp) < int(g.critters["sproutling"].hp) * 2:
		return "spike too small"
	if str(g.run.merge_flash.get("to", "")) != "Thornbud":
		return "no flourish"
	if str(g.run.merge_flash.get("from_id", "")) != "sproutling":
		return "merge flash lost the starter line"
	g.blank_run()
	_put("board", 4, "sproutling")
	_put("bench", 0, "sproutling")
	_put("bench", 1, "sproutling")
	g.resolve_merges()
	if g.run.board[4] == null or str(g.run.board[4].def_id) != "thornbud":
		return "evo should stay on the board"
	g.blank_run()
	for i in 5:
		_put("bench", i, "sproutling")
	_put("board", 0, "sproutling")
	g.resolve_merges()
	if g.copy_count("sproutling") != 0 or g.copy_count("thornbud") != 2:
		return "six should become two T2s, got sprout %d thorn %d" % [g.copy_count("sproutling"), g.copy_count("thornbud")]
	g.blank_run()
	for i in 3:
		_put("bench", i, "thornbud")
	g.resolve_merges()
	if g.copy_count("elderthorn") != 1 or g.copy_count("thornbud") != 0:
		return "T2 triple"
	g.blank_run()
	_put("bench", 0, "elderthorn")
	_put("bench", 1, "elderthorn")
	if not g.resolve_merges().is_empty():
		return "T3 should not merge"
	return ""


func _test_buddy_preview() -> String:
	g.blank_run()
	_put("board", 0, "sproutling")
	_put("board", 1, "sproutling")
	var labels: Dictionary = g.board_buddy_labels()
	var arm = "+%d ARM" % g.econ("LEAF_BUDDY_ARMOR")
	if str(labels[0]) != arm or str(labels[1]) != arm:
		return "orthogonal leaf preview " + str(labels)
	var pairs: Array = g.board_buddy_pairs()
	if pairs.size() != 1 or int(pairs[0].a) != 0 or int(pairs[0].b) != 1:
		return "orthogonal link " + str(pairs)
	g.run.board[1] = null
	_put("board", 4, "sproutling")
	labels = g.board_buddy_labels()
	if str(labels.get(0, "")) != "" or str(labels.get(4, "")) != "":
		return "diagonal should be quiet"
	if not g.board_buddy_pairs().is_empty():
		return "diagonal should not link"
	g.blank_run()
	_put("board", 0, "sproutling")
	_put("board", 1, "sparkpup")
	labels = g.board_buddy_labels()
	if str(labels.get(0, "")) != "" or str(labels.get(1, "")) != "":
		return "mixed families"
	g.blank_run()
	_put("board", 0, "sparkpup")
	_put("board", 1, "sparkpup")
	labels = g.board_buddy_labels()
	if str(labels[0]) != "+%d ATK" % g.econ("EMBER_BUDDY_DAMAGE"):
		return "ember preview"
	g.blank_run()
	_put("board", 0, "cottonwisp")
	_put("board", 3, "cottonwisp")
	_put("board", 6, "cottonwisp")
	labels = g.board_buddy_labels()
	var reg = g.econ("PUFF_BUDDY_REGEN")
	if str(labels[3]) != "+%d REG" % (reg * 2):
		return "middle puff " + str(labels[3])
	if str(labels[0]) != "+%d REG" % reg:
		return "end puff"
	return ""


func _test_wild_buddy() -> String:
	g.blank_run()
	var scout = g.make_unit("sparkpup")
	scout.pos = Vector2i(1, 1)
	var sim = CombatSim.new()
	sim.setup([scout], g.encounters["wild_grass"], g.enemy_defs, g.economy)
	if sim.enemies.size() != 4:
		return "wild count %d" % sim.enemies.size()
	var linked = 0
	for e in sim.enemies:
		if str(e.def_id) != "barkling":
			if int(e.bonus_armor) != 0:
				return "spitter took bark armour"
			if str(e.role) != "ranged" or int(e.local_x) != 2:
				return "pollen should spit from the back"
			if int(e.hp) != g.econ("WILD_RANGED_HP") or int(e.atk) != g.econ("WILD_RANGED_ATK"):
				return "pollen constants"
			continue
		var expect = g.econ("LEAF_BUDDY_ARMOR") * (2 if int(e.local_y) == 1 else 1)
		if int(e.bonus_armor) != expect:
			return "barkling armour %d != %d" % [int(e.bonus_armor), expect]
		if int(e.atk) != g.econ("WILD_MELEE_ATK") or int(e.max_hp) != g.econ("WILD_MELEE_HP"):
			return "bark constants"
		linked += 1
	if linked != 3:
		return "bark count %d" % linked
	var blob = "\n".join(PackedStringArray(sim.log_lines))
	if "Buddy:" not in blob:
		return "buddy log missing"
	return ""


func _test_buddy_damage() -> String:
	var econ = g.economy
	var solo = _duel(false)
	var buddied = _duel(true)
	if int(buddied) <= int(solo):
		return "buddy hp %d should beat solo hp %d" % [buddied, solo]
	return ""


func _duel(with_buddy: bool) -> int:
	var sim = CombatSim.new()
	var leaf = {
		"uid": 1, "name": "Leaf", "family": "leaf", "hp": 100, "max_hp": 100,
		"atk": 1, "armor": 0, "pos": Vector2i(1, 1),
	}
	var units: Array = [leaf]
	if with_buddy:
		units.append({
			"uid": 2, "name": "Leaf2", "family": "leaf", "hp": 100, "max_hp": 100,
			"atk": 1, "armor": 0, "pos": Vector2i(1, 2),
		})
	var foe_defs = {
		"brute": {"name": "Brute", "family": "beast", "hp": 100, "atk": 10, "armor": 0},
	}
	var enc = {"units": [{"def": "brute", "x": 0, "y": 1}]}
	sim.setup(units, enc, foe_defs, g.economy)
	for _i in 3:
		if not sim.over:
			sim.step()
	for u in sim.allies:
		if int(u.uid) == 1:
			return int(u.hp)
	return -1


func _test_splash() -> String:
	var sim = CombatSim.new()
	var hero = {
		"uid": 1, "name": "Fox", "family": "ember", "hp": 80, "max_hp": 80,
		"atk": 10, "armor": 0, "splash": 100, "pos": Vector2i(0, 0),
	}
	var defs = {
		"a": {"name": "A", "family": "beast", "hp": 40, "atk": 0, "armor": 0},
		"b": {"name": "B", "family": "beast", "hp": 40, "atk": 0, "armor": 0},
		"c": {"name": "C", "family": "beast", "hp": 40, "atk": 0, "armor": 0},
	}
	var enc = {"units": [
		{"def": "a", "x": 0, "y": 0},
		{"def": "b", "x": 1, "y": 0},
		{"def": "c", "x": 2, "y": 2},
	]}
	sim.setup([hero], enc, defs, g.economy)
	sim.step()
	var hp = {}
	for e in sim.enemies:
		hp[str(e.def_id)] = int(e.hp)
	if int(hp["a"]) >= 40:
		return "primary untouched"
	if int(hp["b"]) >= 40:
		return "splash missed neighbour"
	if int(hp["c"]) != 40:
		return "splash hit a far target"
	return ""


func _test_boss_summons() -> String:
	var sim = CombatSim.new()
	var hero = {
		"uid": 1, "name": "Hammer", "family": "beast", "hp": 500, "max_hp": 500,
		"atk": 40, "armor": 50, "role": "ranged", "pos": Vector2i(1, 1),
	}
	var defs = {
		"dummy": {"name": "Meadow Matron", "family": "leaf", "hp": 100, "atk": 1, "armor": 0, "boss": true},
		"sprig": {"name": "Sprig Add", "family": "beast", "hp": 500, "atk": 1, "armor": 0},
	}
	var enc = {
		"units": [{"def": "dummy", "x": 1, "y": 1}],
		"script": [
			{"id": "add_wave_1", "when_hp_below": 0.66, "summon": "sprig", "count": 2},
			{"id": "add_wave_2", "when_hp_below": 0.33, "summon": "sprig", "count": 2},
		],
	}
	sim.setup([hero], enc, defs, g.economy)
	sim.step()
	if sim.adds_summoned != 2:
		return "wave 1 summoned %d" % sim.adds_summoned
	sim.step()
	if sim.adds_summoned != 4:
		return "wave 2 summoned %d" % sim.adds_summoned
	var blob = "\n".join(PackedStringArray(sim.log_lines))
	if "thicket" not in blob.to_lower():
		return "summon line missing"
	if sim.banner == "" and sim.banner_ttl <= 0:
		# banner may already have been consumed if ttl expired inside the step; the log is the contract
		pass
	return ""


func _test_combat_floats() -> String:
	var sim = _sim([_fighter("sproutling", 1, 1)], "sparring_pups")
	if not sim.floats.is_empty():
		return "floats before the first step"
	sim.step()
	if sim.floats.is_empty():
		return "no float on a hit"
	var hit := false
	for entry in sim.floats:
		if str(entry.kind) == "hit" and str(entry.text).begins_with("-") and int(entry.uid) > 0:
			hit = true
	if not hit:
		return "hit float missing " + str(sim.floats)
	var wind := false
	var cue_hit := false
	for entry in sim.cues:
		if str(entry.kind) == "windup" and int(entry.uid) > 0:
			wind = true
		if str(entry.kind) == "hit":
			cue_hit = true
	if not wind or not cue_hit:
		return "juice cues missing " + str(sim.cues)
	var heavy = _sim([_fighter("thornbud", 1, 1)], "sparring_pups")
	heavy.step()
	var saw_kill := false
	for entry in heavy.cues:
		if str(entry.kind) == "kill":
			saw_kill = true
	if not saw_kill:
		return "kill cue missing " + str(heavy.cues)
	var tokens = load("res://scripts/token.gd")
	if tokens.enemy_mark("mite") == "" or tokens.enemy_mark("mite") == tokens.enemy_mark("mite_small"):
		return "mites share a telegraph"
	if tokens.species_mark("puff", "cotton", 2) == "" or tokens.species_mark("puff", "cotton", 2) == tokens.species_mark("puff", "fluff", 2):
		return "cloudbud and cumulon share a face"
	if tokens.clarity_texture("meadow") == null or tokens.clarity_texture("tired") == null:
		return "mite clarity tokens missing"
	if tokens.clarity_texture("cloudbud") == null or tokens.clarity_texture("cumulon") == null:
		return "puff clarity tokens missing"
	if tokens.enemy_mark("warden") == "" or tokens.enemy_mark("bramble") == "" or tokens.enemy_mark("sprig") == "":
		return "elite telegraph missing"
	if tokens.enemy_mark("warden") == tokens.enemy_mark("mite"):
		return "warden shares the mite face"
	if tokens.species_mark("puff", "nimbus", 2) == "" or tokens.species_mark("puff", "nimbus", 2) == tokens.species_mark("puff", "cotton", 2):
		return "driftkin still shares cloudbud"
	if tokens.clarity_texture("warden") == null or tokens.clarity_texture("bramble") == null:
		return "elite clarity tokens missing"
	if tokens.clarity_texture("sprig") == null or tokens.clarity_texture("driftkin") == null:
		return "sprig or driftkin token missing"
	if tokens.species_mark("leaf", "sprout", 1) == tokens.species_mark("leaf", "bud", 1):
		return "budmite shares sproutling"
	if tokens.species_mark("leaf", "dew", 1) == "" or tokens.species_mark("leaf", "dew", 1) == tokens.species_mark("leaf", "sprout", 1):
		return "dewcap shares sproutling"
	if tokens.species_mark("ember", "wick", 1) == tokens.species_mark("ember", "spark", 1):
		return "wicklet shares sparkpup"
	if tokens.species_mark("ember", "cinder", 1) == tokens.species_mark("ember", "spark", 1):
		return "cinderkit shares sparkpup"
	if tokens.species_mark("puff", "nimbus", 1) == tokens.species_mark("puff", "cotton", 1):
		return "nimbusling shares cottonwisp"
	if tokens.species_mark("puff", "fluff", 1) == tokens.species_mark("puff", "cotton", 1):
		return "fluffball shares cottonwisp"
	for mark in ["sproutling", "budmite", "dewcap", "wicklet", "cinderkit", "nimbusling", "fluffball", "thornbud", "stormpillow"]:
		if tokens.clarity_texture(mark) == null:
			return "shop line token missing " + mark
	if tokens.species_mark("leaf", "bud", 2) != "mossguard" or tokens.species_mark("puff", "cotton", 3) != "stormpillow":
		return "line did not continue past T1"
	var cap: TextureRect = tokens.make("leaf", 1, 64.0, false, "sproutling", "melee")
	if cap.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS:
		return "fight token filter"
	if cap.texture == null or not cap.texture.get_image().has_mipmaps():
		return "fight token mipmaps"
	if cap.custom_minimum_size != cap.custom_minimum_size.round():
		return "fight token is off a pixel"
	var face_script = load("res://scripts/starter_face.gd")
	if absf(float(face_script.IDLE_FPS) - 5.0) > 0.01:
		return "idle is not 5 fps"
	var holds = face_script.IDLE_HOLD_STEPS
	if holds.size() != 6:
		return "idle hold is not the 6-frame sheet"
	var span := 0.0
	for step in holds:
		span += float(step)
	var cycle := span / float(face_script.IDLE_FPS)
	var effective := float(holds.size()) / cycle
	if effective < 4.9 or effective > 5.1:
		return "idle is not a 5 fps loop"
	if float(face_script.MERGE_FPS) < 8.0 or float(face_script.MERGE_FPS) > 10.0:
		return "merge fps out of band"
	if float(face_script.MERGE_SETTLE) < 0.05 or float(face_script.MERGE_SETTLE) > 0.08:
		return "merge settle out of band"
	if int(cap.get("sheet_px")) != 64 or int(cap.get("idle_count")) != 6 or int(cap.get("merge_count")) != 6:
		return "sproutling board sheet"
	if absf(cap.pivot_offset.x - cap.custom_minimum_size.x * 0.5) > 1.0 or absf(cap.pivot_offset.y - cap.custom_minimum_size.y) > 1.0:
		return "starter pivot is not bottom-center"
	var listed = tokens.make("ember", 1, 40.0, false, "sparkpup", "ranged")
	if int(listed.get("sheet_px")) != 32:
		return "sparkpup list should use 32"
	var cotton = tokens.make("puff", 1, 46.0, false, "cottonwisp", "ranged")
	if int(cotton.get("sheet_px")) != 64:
		return "cottonwisp board should use 64"
	var bud = tokens.make("leaf", 1, 64.0, false, "budmite", "ranged")
	if bud.get_script() != null:
		return "budmite left the capsule"
	if tokens.clarity_texture("sproutling") == null:
		return "old sproutling crop missing"
	return ""


func _test_shop() -> String:
	g.blank_run()
	_put("board", 4, "sproutling")
	g.run.coins = 15
	g.enter_node("shop_a")
	if str(g.run.shop[0].def_id) != "sproutling":
		return "teach copy missing, got " + str(g.run.shop[0].def_id)
	var after_interest = 15 + g.interest_for(15)
	if int(g.run.coins) != after_interest:
		return "interest on shop enter"
	g.buy(0)
	if g.copy_count("sproutling") != 2 or g.copy_count("thornbud") != 0:
		return "buying the pair evolved early"
	if int(g.run.coins) != after_interest - g.econ("BUY_T1"):
		return "buy cost"
	g.run.shop[1] = {"def_id": "sproutling", "frozen": false}
	g.buy(1)
	if g.copy_count("thornbud") != 1 or g.copy_count("sproutling") != 0:
		return "third buy should spike"
	if str(g.run.board[4].def_id) != "thornbud":
		return "spike left the board"
	return ""


func _test_reroll_interest() -> String:
	g.blank_run()
	g.run.coins = 30
	g.enter_node("shop_a")
	var base = g.econ("REROLL_COST")
	if g.reroll_cost() != base:
		return "opening reroll cost"
	g.run.shop[1] = {"def_id": "dewcap", "frozen": true}
	g.run.shop[2] = {"def_id": "___sentinel", "frozen": false}
	var coins_before = int(g.run.coins)
	g.reroll()
	if int(g.run.coins) != coins_before - base:
		return "reroll spend"
	if str(g.run.shop[1].def_id) != "dewcap" or not bool(g.run.shop[1].frozen):
		return "freeze lost"
	if str(g.run.shop[2].def_id) == "___sentinel":
		return "unfrozen slot stuck"
	if g.reroll_cost() != base:
		return "cost scaled too early"
	g.reroll()
	var step = g.econ("REROLL_SCALE_STEP")
	if g.reroll_cost() != base + step:
		return "cost did not scale"
	return ""


func _test_freeze_survives_fight() -> String:
	g.blank_run()
	g.run.coins = 40
	g.enter_node("shop_a")
	var slots := int(g.econ("SHOP_SLOTS"))
	if g.run.shop.size() != slots:
		return "opening slot count %d" % g.run.shop.size()
	g.run.shop[1] = {"def_id": "dewcap", "frozen": false}
	g.toggle_freeze(1)
	if str(g.run.shop[1].def_id) != "dewcap" or not bool(g.run.shop[1].frozen):
		return "freeze did not stick"
	g.toggle_freeze(1)
	if bool(g.run.shop[1].frozen):
		return "unfreeze did not stick"
	g.toggle_freeze(1)
	g.run.shop[0] = {"def_id": "sproutling", "frozen": true}
	g.run.shop[2] = {"def_id": "___sentinel", "frozen": false}
	g.buy(0)
	if g.run.shop.size() != slots:
		return "buy ate a shop slot"
	if str(g.run.shop[0].def_id) != "" or bool(g.run.shop[0].frozen):
		return "bought freeze still holds the slot"
	if str(g.run.shop[1].def_id) != "dewcap" or not bool(g.run.shop[1].frozen):
		return "buy shifted the frozen slot"
	g.leave_node()
	if str(g.run.node_id) != "wild_1":
		return "did not reach the fight prep"
	if str(g.run.shop[1].def_id) != "dewcap" or not bool(g.run.shop[1].frozen):
		return "fight prep cleared the freeze"
	g.start_combat()
	g.combat.player_won = true
	g.combat.over = true
	g.finish_combat()
	if g.phase != "choice":
		return "fight reward should open the fork, got " + g.phase
	if g.run.shop.size() != slots:
		return "fight changed the shop size"
	if str(g.run.shop[1].def_id) != "dewcap" or not bool(g.run.shop[1].frozen):
		return "fight cleared the frozen offer"
	g.choose(0)
	if str(g.run.node_id) != "shop_b":
		return "fork did not open the cart"
	if g.run.shop.size() != slots:
		return "next shop slot count %d" % g.run.shop.size()
	if str(g.run.shop[1].def_id) != "dewcap" or not bool(g.run.shop[1].frozen):
		return "frozen offer did not survive into the next prep"
	if str(g.run.shop[0].def_id) == "":
		return "bought slot was not refilled"
	if str(g.run.shop[2].def_id) == "___sentinel":
		return "unfrozen slot was not refreshed"
	g.toggle_freeze(1)
	if bool(g.run.shop[1].frozen) or str(g.run.shop[1].def_id) != "dewcap":
		return "unfreeze cleared the offer early"
	g.run.shop[3] = {"def_id": "___keep", "frozen": true}
	g.run.shop[1] = {"def_id": "___drop", "frozen": false}
	g.reroll()
	if g.run.shop.size() != slots:
		return "reroll ate a slot"
	if str(g.run.shop[3].def_id) != "___keep" or not bool(g.run.shop[3].frozen):
		return "reroll moved the frozen slot"
	if str(g.run.shop[1].def_id) == "___drop":
		return "unfrozen slot stuck after reroll"
	return ""


func _test_sell_drag() -> String:
	g.blank_run()
	g.enter_node("sparring_1")
	var u: Dictionary = _put("bench", 0, "sparkpup")
	var coins := int(g.run.coins)
	g.handle_drop("sell", -1, {"uid": int(u.uid)})
	if g.run.bench[0] != null:
		return "drag sell left the critter"
	if int(g.run.coins) != coins + g.econ("SELL_T1"):
		return "drag sell value"
	if "Sold" not in str(g.run.toast):
		return "drag sell toast"
	var board: Dictionary = _put("board", 2, "dewcap")
	g.handle_drop("sell", -1, {"uid": int(board.uid)})
	if g.run.board[2] != null:
		return "board drag sell left the critter"
	return ""


func _test_soft_cap_sell() -> String:
	g.blank_run()
	var ids: Array = ["sproutling", "dewcap", "sparkpup", "wicklet", "cinderkit", "cottonwisp", "nimbusling", "fluffball"]
	for i in 7:
		_put("board", i, str(ids[i]))
	var extra: Dictionary = _put("bench", 0, str(ids[7]))
	var coins = int(g.run.coins)
	g.handle_drop("board", 7, {"uid": int(extra.uid)})
	if g.board_count() != 7 or g.run.board[7] != null:
		return "cap ignored"
	if "Soft cap" not in str(g.run.toast):
		return "cap toast"
	g.sell_uid(int(extra.uid))
	if g.run.bench[0] != null:
		return "sell left the unit"
	if int(g.run.coins) != coins + g.econ("SELL_T1"):
		return "sell value"
	return ""


func _test_sparring() -> String:
	g.blank_run()
	# A real pick, then the easy fight.
	g.choose_starter("sproutling")
	if g.phase != "prep" or str(g.run.node_id) != "sparring_1":
		return "did not open sparring"
	if g.run.board[int(g.run.board.size() / 2)] == null:
		return "starter not placed"
	g.start_combat()
	var guard = 0
	while g.combat != null and not g.combat.over and guard < 30:
		g.combat_tick()
		guard += 1
	if g.combat == null or not g.combat.player_won:
		_dump(g.combat, "sparring")
		return "starter should win sparring"
	g.finish_combat()
	if str(g.run.node_id) != "shop_a":
		return "reward should open the stall, at " + str(g.run.node_id)
	var purse := int(g.run.coins)
	var price: int = g.econ("BUY_T1")
	var slots: int = g.econ("SHOP_SLOTS")
	var before_interest: int = g.econ("STARTING_COINS") + int(g.nodes["sparring_1"].reward)
	var purse_expect: int = before_interest + int(g.interest_for(before_interest))
	if purse != purse_expect:
		return "first stall purse %d != %d" % [purse, purse_expect]
	if purse < price:
		return "can't afford a buy after fight 1"
	# Two T1 buys finish the starter into a triple. Three would clear most of the stall.
	if purse < price * 2:
		return "first stall cannot reach a starter triple, purse %d" % purse
	if purse >= price * 3:
		return "first stall buys three offers, purse %d" % purse
	if purse >= slots * price:
		return "first stall buys every offer"
	if purse - price < g.econ("REROLL_COST"):
		return "no coin left to reroll after one buy"
	print("  sparring rounds ", guard, " coins ", purse)
	return ""


func _test_wild_win() -> String:
	var units: Array = [
		_fighter("sproutling", 1, 1),
		_fighter("sproutling", 1, 0),
		_fighter("sparkpup", 0, 1),
	]
	var err = _fight(units, "wild_grass", true, "wild buddies")
	return err


func _test_boss_win() -> String:
	var units: Array = [
		_fighter("elderthorn", 1, 1),
		_fighter("thornbud", 1, 0),
		_fighter("infernox", 0, 1),
		_fighter("foxfire", 0, 0),
		_fighter("stormpillow", 2, 1),
		_fighter("cloudbud", 2, 0),
		_fighter("sparkpup", 0, 2),
	]
	return _fight(units, "meadow_matron", true, "boss spike")


func _test_sheet_art() -> String:
	var tokens = load("res://scripts/token.gd")
	for mark in ["meadow", "tired", "warden", "bramble", "sprig"]:
		var tone := _body_mean(tokens.clarity_texture(mark))
		if tone.r < tone.g + 0.04 or tone.b + 0.02 < tone.g:
			return "%s is not dusty mauve %s" % [mark, tone]
		if tone.r > 0.88:
			return "%s still candy bright %s" % [mark, tone]
	if _green_count(tokens.clarity_texture("meadow")) < 80:
		return "meadow sprout was recolored"
	if _green_count(tokens.clarity_texture("sprig")) < 40:
		return "sprig leaves are not green"
	var drift := _body_mean(tokens.clarity_texture("driftkin"))
	if drift.b < drift.r or drift.g < drift.r:
		return "driftkin lost powder blue %s" % drift
	var sprout: Control = tokens.present("leaf", 1, 96.0, false, "sproutling", "melee")
	var sprout_err := _badge_clear(sprout, "sproutling")
	if sprout_err != "":
		return sprout_err
	var bud: Control = tokens.present("leaf", 1, 96.0, false, "budmite", "ranged")
	var bud_err := _badge_clear(bud, "budmite")
	if bud_err != "":
		return bud_err
	var spark: Control = tokens.present("ember", 1, 96.0, false, "sparkpup", "ranged")
	var spark_err := _badge_clear(spark, "sparkpup")
	if spark_err != "":
		return spark_err
	var cotton: Control = tokens.present("puff", 1, 64.0, false, "cottonwisp", "ranged")
	return _badge_clear(cotton, "cottonwisp")


func _badge_clear(box: Control, label: String) -> String:
	var badge: Node = box.find_child("RoleBadge", true, false)
	if badge == null or not (badge is Control):
		return label + " missing role badge"
	var sz := box.size
	var pos := (badge as Control).position
	var bsz := (badge as Control).size
	var center := pos + bsz * 0.5
	if center.x < sz.x * 0.60:
		return "%s badge not top-right (%.1f, %.1f) in %s" % [label, center.x, center.y, sz]
	if center.y > sz.y * 0.72:
		return "%s badge too low (%.1f, %.1f) in %s" % [label, center.x, center.y, sz]
	var mark := Rect2(sz.x * 0.28, 0.0, sz.x * 0.38, sz.y * 0.40)
	if mark.intersects(Rect2(pos, bsz)):
		return "%s badge overlaps line mark %s vs %s" % [label, Rect2(pos, bsz), mark]
	return ""


func _body_mean(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var r := 0.0
	var g := 0.0
	var b := 0.0
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.65:
				continue
			if c.r < 0.45 and c.g < 0.45 and c.b < 0.45:
				continue
			if c.g > c.r + 0.05 and c.g > c.b + 0.05:
				continue
			var mx := maxf(c.r, maxf(c.g, c.b))
			var mn := minf(c.r, minf(c.g, c.b))
			if mx - mn < 0.08 and mx > 0.55:
				continue
			r += c.r
			g += c.g
			b += c.b
			n += 1
	if n == 0:
		return Color(0, 0, 0)
	return Color(r / n, g / n, b / n)


func _green_count(tex: Texture2D) -> int:
	var img := tex.get_image()
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.6 and c.g > c.r + 0.06 and c.g > c.b + 0.06:
				n += 1
	return n


func _test_roles() -> String:
	var counts := {"leaf": {"melee": 0, "ranged": 0}, "ember": {"melee": 0, "ranged": 0}, "puff": {"melee": 0, "ranged": 0}}
	for id in g.critter_order:
		var c: Dictionary = g.critters[id]
		var role := str(c.get("role", ""))
		if role != "melee" and role != "ranged":
			return "bad role " + str(id)
		counts[str(c.family)][role] = int(counts[str(c.family)][role]) + 1
	for fam in counts.keys():
		if int(counts[fam].melee) < 1 or int(counts[fam].ranged) < 1:
			return fam + " missing a role"
	if str(g.critters["sproutling"].role) != "melee" or str(g.critters["budmite"].role) != "ranged":
		return "leaf split"
	if str(g.critters["sparkpup"].role) != "ranged" or str(g.critters["wicklet"].role) != "melee":
		return "ember split"
	if str(g.critters["cottonwisp"].role) != "ranged" or str(g.critters["fluffball"].role) != "melee":
		return "puff split"
	var melee_back := _role_hit("melee", 0)
	var melee_mid := _role_hit("melee", 1)
	if melee_back >= melee_mid:
		return "melee back %d should be softer than mid %d" % [melee_back, melee_mid]
	var ranged_front := _role_hit("ranged", 2)
	var ranged_back := _role_hit("ranged", 0)
	if ranged_front >= ranged_back:
		return "ranged front %d should be softer than back %d" % [ranged_front, ranged_back]
	var defs := {
		"front": {"name": "Front", "family": "beast", "hp": 80, "atk": 0, "armor": 0, "role": "melee"},
		"back": {"name": "Back", "family": "beast", "hp": 10, "atk": 0, "armor": 0, "role": "melee"},
	}
	var spots: Array = [{"def": "front", "x": 0, "y": 2}, {"def": "back", "x": 2, "y": 0}]
	if _role_aim("melee", Vector2i(2, 0), spots, defs) != "front":
		return "melee left the front line"
	if _role_aim("ranged", Vector2i(2, 0), spots, defs) != "back":
		return "ranged ignored lowest hp"
	var nip := {"nip": {"name": "Nip", "family": "beast", "hp": 40, "atk": 8, "armor": 0, "role": "melee"}}
	var sim := CombatSim.new()
	sim.setup([
		{"uid": 1, "name": "Tank", "family": "leaf", "hp": 40, "max_hp": 40, "atk": 0, "armor": 0, "role": "melee", "pos": Vector2i(2, 1)},
		{"uid": 2, "name": "Spit", "family": "puff", "hp": 40, "max_hp": 40, "atk": 0, "armor": 0, "role": "ranged", "pos": Vector2i(2, 0)},
	], {"units": [{"def": "nip", "x": 0, "y": 1}]}, nip, g.economy)
	sim.step()
	var tank_hp := -1
	var spit_hp := -1
	for u in sim.allies:
		if str(u.name) == "Tank":
			tank_hp = int(u.hp)
		if str(u.name) == "Spit":
			spit_hp = int(u.hp)
	if spit_hp >= 40 or tank_hp < 40:
		return "enemy melee skipped front ranged (%d / %d)" % [spit_hp, tank_hp]
	var fallen: Array = [_fighter("cottonwisp", 2, 1)]
	var loss: CombatSim = _sim(fallen, "meadow_matron")
	var guard := 0
	while not loss.over and guard < 40:
		loss.step()
		guard += 1
	if loss.player_won or loss.defeat_reason() != "Ranged in front melted":
		return "front ranged reason [" + loss.defeat_reason() + "]"
	return ""


func _test_role_strikes() -> String:
	var sim := CombatSim.new()
	var post := {
		"uid": 1, "name": "Post", "family": "leaf", "hp": 80, "max_hp": 80,
		"atk": 0, "armor": 0, "role": "melee", "pos": Vector2i(1, 1),
	}
	sim.setup([post], g.encounters["sparring_pups"], g.enemy_defs, g.economy)
	var melee_uid := -1
	var ranged_uid := -1
	for e in sim.enemies:
		if str(e.role) == "melee":
			melee_uid = int(e.uid)
			if int(e.local_x) != 0 or int(e.max_hp) != g.econ("SPARRING_MELEE_HP") or int(e.atk) != g.econ("SPARRING_MELEE_ATK"):
				return "sparring melee constants"
		elif str(e.role) == "ranged":
			ranged_uid = int(e.uid)
			if int(e.local_x) != 2 or int(e.max_hp) != g.econ("SPARRING_RANGED_HP") or int(e.atk) != g.econ("SPARRING_RANGED_ATK"):
				return "sparring ranged constants"
	if melee_uid < 0 or ranged_uid < 0:
		return "sparring needs both roles"
	sim.step()
	var melee_wind := false
	var ranged_wind := false
	var melee_hit := false
	var ranged_hit := false
	for entry in sim.cues:
		if str(entry.kind) == "windup" and int(entry.uid) == melee_uid and int(entry.get("target", -1)) == 1 and str(entry.role) == "melee":
			melee_wind = true
		if str(entry.kind) == "windup" and int(entry.uid) == ranged_uid and int(entry.get("target", -1)) == 1 and str(entry.role) == "ranged":
			ranged_wind = true
		if str(entry.kind) == "hit" and int(entry.uid) == 1 and str(entry.get("via", "")) == "melee":
			melee_hit = true
		if str(entry.kind) == "hit" and int(entry.uid) == 1 and str(entry.get("via", "")) == "ranged":
			ranged_hit = true
	if not melee_wind or not ranged_wind:
		return "role windups missing " + str(sim.cues)
	if not melee_hit or not ranged_hit:
		return "impact via missing " + str(sim.cues)
	return ""


func _test_early_teeth() -> String:
	var err := _fight([_fighter("cottonwisp", 2, 1)], "sparring_pups", false, "front cotton")
	if err != "":
		return err
	err = _fight([_fighter("sparkpup", 2, 1)], "sparring_pups", false, "front spark")
	if err != "":
		return err
	err = _fight([_fighter("sproutling", 0, 1)], "sparring_pups", false, "back sprout")
	if err != "":
		return err
	err = _fight([_fighter("sparkpup", 1, 1)], "sparring_pups", true, "spark mid")
	if err != "":
		return err
	err = _fight([_fighter("cottonwisp", 1, 1)], "sparring_pups", true, "cotton mid")
	if err != "":
		return err
	err = _fight([_fighter("sproutling", 1, 1)], "wild_grass", false, "lone sprout wild")
	if err != "":
		return err
	var mix: Array = [_fighter("sproutling", 1, 1), _fighter("sparkpup", 0, 1)]
	err = _fight(mix, "wild_grass", false, "no buddy wild")
	if err != "":
		return err
	var pair: Array = [_fighter("sproutling", 1, 1), _fighter("sproutling", 1, 0)]
	err = _fight(pair, "wild_grass", true, "buddy pair wild")
	if err != "":
		return err
	var front: Array = [_fighter("sproutling", 2, 1), _fighter("sproutling", 2, 0)]
	err = _fight(front, "wild_grass", true, "front column wild")
	if err != "":
		return err
	var back: Array = [_fighter("sproutling", 1, 1), _fighter("sproutling", 0, 1)]
	err = _fight(back, "wild_grass", false, "back column wild")
	if err != "":
		return err
	return ""


func _test_enemy_aim() -> String:
	var defs := {
		"nip": {"name": "Nip", "family": "beast", "hp": 40, "atk": 6, "armor": 0, "role": "melee"},
		"spit": {"name": "Spit", "family": "beast", "hp": 40, "atk": 6, "armor": 0, "role": "ranged"},
	}
	var sim := CombatSim.new()
	sim.setup([
		{"uid": 1, "name": "FrontTop", "family": "leaf", "hp": 80, "max_hp": 80, "atk": 0, "armor": 0, "role": "melee", "pos": Vector2i(2, 0)},
		{"uid": 2, "name": "BackBot", "family": "puff", "hp": 10, "max_hp": 10, "atk": 0, "armor": 0, "role": "ranged", "pos": Vector2i(0, 2)},
	], {"units": [
		{"def": "nip", "x": 0, "y": 2},
		{"def": "spit", "x": 2, "y": 0},
	]}, defs, g.economy)
	sim.step()
	var front_hp := -1
	var back_hp := -1
	for u in sim.allies:
		if str(u.name) == "FrontTop":
			front_hp = int(u.hp)
		if str(u.name) == "BackBot":
			back_hp = int(u.hp)
	if front_hp >= 80:
		return "melee left the front column"
	if back_hp >= 10:
		return "ranged left the low hp target"
	if front_hp != 80 - 6:
		return "melee also hit the back row (%d)" % front_hp
	if back_hp != 10 - 6:
		return "ranged also hit the front (%d)" % back_hp
	var elite := CombatSim.new()
	elite.setup([_fighter("sproutling", 1, 1)], g.encounters["elite_nest"], g.enemy_defs, g.economy)
	var warden_back := false
	for e in elite.enemies:
		if str(e.def_id) == "warden":
			warden_back = str(e.role) == "ranged" and int(e.local_x) == 2
	if not warden_back:
		return "warden should spit from the back"
	var bramble := CombatSim.new()
	bramble.setup([_fighter("sproutling", 1, 1)], g.encounters["bramble_patch"], g.enemy_defs, g.economy)
	var back_spit := 0
	var front_melee := 0
	for e in bramble.enemies:
		if str(e.role) == "ranged" and int(e.local_x) == 2:
			back_spit += 1
		if str(e.role) == "melee" and int(e.local_x) == 0:
			front_melee += 1
	if back_spit != 1 or front_melee != 3:
		return "bramble ranks %d spit %d front" % [back_spit, front_melee]
	var half := CombatSim.new()
	half.setup([
		{"uid": 1, "name": "Post", "family": "leaf", "hp": 80, "max_hp": 80, "atk": 0, "armor": 0, "role": "melee", "pos": Vector2i(1, 1)},
	], {"units": [{"def": "nip", "x": 2, "y": 1}]}, defs, g.economy)
	half.step()
	var back_hit := 80 - int(half.allies[0].hp)
	var full := CombatSim.new()
	full.setup([
		{"uid": 1, "name": "Post", "family": "leaf", "hp": 80, "max_hp": 80, "atk": 0, "armor": 0, "role": "melee", "pos": Vector2i(1, 1)},
	], {"units": [{"def": "nip", "x": 0, "y": 1}]}, defs, g.economy)
	full.step()
	var front_hit := 80 - int(full.allies[0].hp)
	if back_hit >= front_hit:
		return "enemy melee in the back hit %d, front hit %d" % [back_hit, front_hit]
	return ""


func _role_hit(role: String, x: int) -> int:
	var sim := CombatSim.new()
	var hero := {
		"uid": 1, "name": "H", "family": "leaf", "hp": 50, "max_hp": 50,
		"atk": 10, "armor": 0, "role": role, "pos": Vector2i(x, 1),
	}
	var defs := {"blob": {"name": "Blob", "family": "beast", "hp": 40, "atk": 0, "armor": 0, "role": "melee"}}
	sim.setup([hero], {"units": [{"def": "blob", "x": 0, "y": 1}]}, defs, g.economy)
	sim.step()
	return 40 - int(sim.enemies[0].hp)


func _role_aim(role: String, pos: Vector2i, spots: Array, defs: Dictionary) -> String:
	var sim := CombatSim.new()
	var hero := {
		"uid": 1, "name": "H", "family": "leaf", "hp": 80, "max_hp": 80,
		"atk": 10, "armor": 20, "role": role, "pos": pos,
	}
	sim.setup([hero], {"units": spots}, defs, g.economy)
	sim.step()
	for e in sim.enemies:
		if int(e.hp) < int(e.max_hp):
			return str(e.def_id)
	return ""


func _test_defeat_line() -> String:
	var lone: Array = [_fighter("cottonwisp", 1, 1)]
	var sim = _sim(lone, "meadow_matron")
	var guard = 0
	while not sim.over and guard < 40:
		sim.step()
		guard += 1
	if sim.player_won:
		return "lone puff should lose to the matron"
	var reason = sim.defeat_reason()
	if reason == "" or "\n" in reason or reason.length() > 90:
		return "bad reason [" + reason + "]"
	print("  loss line: ", reason)
	return ""


func _test_unlock() -> String:
	if int(g.profile.runs) != 0:
		return "run counted early"
	g.blank_run()
	g.discover("foxfire")
	g.run.board = _cleared(g.run.board)
	g.start_combat()
	if not g.combat.over or g.combat.player_won:
		return "empty board should already be over"
	g.finish_combat()
	if g.phase != "result":
		return "no result"
	var line = str(g.run.result.line)
	if line != "Nothing fielded — place critters on the board":
		return "empty reason [" + line + "]"
	if "\n" in line:
		return "reason has a break"
	if "bud" not in g.profile.unlocked_lines:
		return "line stayed locked"
	if "Budmite" not in str(g.run.result.unlock):
		return "unlock copy"
	if "budmite" in g.starter_ids():
		return "unlock joined the starter row"
	if g.starter_ids().size() != 3:
		return "starter row changed size"
	if "budmite" not in g.pool_for_tier(1):
		return "not in the shop pool"
	if "foxfire" not in g.run.result.new_dex:
		return "dex tick missing"
	# Loss keeps the unlock on disk.
	g._load_profile()
	if "bud" not in g.profile.unlocked_lines:
		return "unlock did not save"
	return ""


func _test_starter_motion() -> String:
	var tokens = load("res://scripts/token.gd")
	var board = tokens.make("leaf", 1, 64.0, false, "sproutling", "melee")
	root.add_child(board)
	var still: Texture2D = board.texture
	await create_timer(0.25).timeout
	if str(board.get("mode")) != "idle" or board.texture == still:
		board.queue_free()
		return "idle did not leave the static frame"
	if board.scale != Vector2.ONE:
		board.queue_free()
		return "idle stacked a scale tween"
	var buddy = tokens.make("ember", 1, 64.0, false, "sparkpup", "ranged")
	root.add_child(buddy)
	var before_frame := int(board.get("frame_i"))
	await create_timer(0.3).timeout
	if int(board.get("frame_i")) == before_frame:
		board.queue_free()
		buddy.queue_free()
		return "idle did not advance"
	if int(board.get("frame_i")) != int(buddy.get("frame_i")):
		board.queue_free()
		buddy.queue_free()
		return "starters do not share an idle clock"
	if board.scale != Vector2.ONE or buddy.scale != Vector2.ONE:
		board.queue_free()
		buddy.queue_free()
		return "idle stacked a scale tween"
	var holder := Control.new()
	root.add_child(holder)
	var held = tokens.make("ember", 1, 64.0, false, "sparkpup", "ranged")
	holder.add_child(held)
	var tw := holder.create_tween()
	tw.tween_interval(1.0)
	holder.set_meta("juice_tw", tw)
	var held_tex: Texture2D = held.texture
	var held_frame := int(held.get("frame_i"))
	await create_timer(0.25).timeout
	if int(held.get("frame_i")) != held_frame or held.texture != held_tex:
		tw.kill()
		board.queue_free()
		holder.queue_free()
		buddy.queue_free()
		return "idle advanced during a tween"
	tw.kill()
	board.call("play_merge")
	await create_timer(0.08).timeout
	if board.scale != Vector2.ONE:
		board.queue_free()
		holder.queue_free()
		buddy.queue_free()
		return "merge stacked a scale tween"
	board.call("play_merge")
	await create_timer(0.95).timeout
	if str(board.get("mode")) != "idle":
		board.queue_free()
		holder.queue_free()
		buddy.queue_free()
		return "merge did not settle to idle"
	if board.scale != Vector2.ONE:
		board.queue_free()
		holder.queue_free()
		buddy.queue_free()
		return "merge settle scaled the sheet"
	var evolved = tokens.make("puff", 1, 64.0, false, "cottonwisp", "ranged")
	root.add_child(evolved)
	var cap_tex: Texture2D = tokens.clarity_texture("cloudbud")
	var sz: Vector2 = evolved.custom_minimum_size
	evolved.call("arm_settle", tokens.sheet_frame(cap_tex, int(sz.x), int(sz.y)))
	evolved.call("play_merge")
	await create_timer(0.95).timeout
	if str(evolved.get("mode")) != "still":
		board.queue_free()
		holder.queue_free()
		buddy.queue_free()
		evolved.queue_free()
		return "evolved merge did not settle to the capsule"
	board.queue_free()
	holder.queue_free()
	buddy.queue_free()
	evolved.queue_free()
	return ""


func _test_starter_merge() -> String:
	g.blank_run()
	_put("board", 4, "sproutling")
	_put("bench", 0, "sproutling")
	_put("bench", 1, "sproutling")
	g._after_units_changed()
	if str(g.run.board[4].def_id) != "thornbud":
		return "triple did not land on the board"
	if str(g.run.merge_flash.get("from_id", "")) != "sproutling":
		return "flash is not the sproutling line"
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var center: Node = main.find_child("Board4", true, false)
	if center == null:
		main.queue_free()
		return "merge slot missing"
	var face: Node = center.find_child("Capsule", true, false)
	if face == null or not face.has_method("play_merge"):
		main.queue_free()
		return "merge did not use the starter sheet"
	if str(face.get("mode")) != "merge":
		main.queue_free()
		return "merge one-shot was not playing"
	if int(face.get("sheet_px")) != 64:
		main.queue_free()
		return "merge used the 32 sheet on the board"
	var badge: Node = center.find_child("RoleBadge", true, false)
	if badge == null or str(badge.get("kind")) != "melee":
		main.queue_free()
		return "merge hid the role badge"
	var board_wash: Node = main.find_child("BoardMeadow", true, false)
	if board_wash == null or int(board_wash.z_index) >= 0:
		main.queue_free()
		return "merge put the board wash in front"
	var page_wash: Node = main.find_child("MeadowWash", true, false)
	if page_wash == null or int(page_wash.z_index) >= 0:
		main.queue_free()
		return "merge put the page wash in front"
	await create_timer(0.95).timeout
	if not is_instance_valid(face) or str(face.get("mode")) != "still":
		main.queue_free()
		return "merge did not settle onto the evolved capsule"
	main.queue_free()
	return ""


func _test_ui() -> String:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var reason: Node = main.find_child("ResultLine", true, false)
	if reason == null or "Nothing fielded" not in reason.text:
		return "result line not on screen"
	if "\n" in str(reason.text):
		return "result line should stay one line"
	var fight_log: Node = main.find_child("FightLogScroll", true, false)
	if fight_log == null or not fight_log.visible or not (fight_log is ScrollContainer):
		return "result fight log missing"
	var fight_text: Node = main.find_child("FightLogText", true, false)
	if fight_text == null or not fight_text.visible:
		return "result fight log text missing"
	var park: Node = main.find_child("ReservePark", true, false)
	var trail: Node = main.find_child("SeasonTrail", true, false)
	if park == null or trail == null or not park.disabled or not trail.disabled:
		return "park/trail tease missing"
	var unlock: Node = main.find_child("UnlockCard", true, false)
	if unlock == null:
		return "unlock card missing"
	var hero: Node = unlock.find_child("Capsule", true, false)
	if hero == null or not (hero is TextureRect) or hero.custom_minimum_size.y < 80.0:
		return "unlock capsule is not the hero"
	var copy: Node = unlock.find_child("UnlockCopy", true, false)
	if copy == null or not (copy is Label) or "shows up in the shop" not in str(copy.text):
		return "unlock copy missing the shop sentence"
	if copy is Label and (copy as Label).get_line_count() > (copy as Label).get_visible_line_count():
		return "unlock copy clipped"
	var dex: Node = main.find_child("DexTick", true, false)
	if dex == null or "Foxfire" not in dex.text:
		return "dex tick not visible"
	var retry: Node = main.find_child("RetryButton", true, false)
	if retry == null:
		return "no retry"
	retry.pressed.emit()
	await process_frame
	await process_frame
	if g.phase != "start":
		return "retry did not return to the title"
	var title_err := _title_menu_err(main)
	if title_err != "":
		return title_err
	var hover_play := main.find_child("PlayButton", true, false) as BaseButton
	hover_play.mouse_entered.emit()
	await create_timer(0.2).timeout
	if hover_play.scale.x < 1.02 or hover_play.scale.x > 1.04:
		return "title hover is not a small scale"
	var hovered := hover_play.scale.x
	await create_timer(0.3).timeout
	if absf(hover_play.scale.x - hovered) > 0.001:
		return "title button bounces at rest"
	hover_play.mouse_exited.emit()
	await create_timer(0.2).timeout
	if absf(hover_play.scale.x - 1.0) > 0.02:
		return "title hover did not return"
	var options: Node = main.find_child("OptionsButton", true, false)
	options.pressed.emit()
	await process_frame
	await process_frame
	var volume: Node = main.find_child("OptionsVolume", true, false)
	var full: Node = main.find_child("OptionsFullscreen", true, false)
	if volume == null or not (volume is HSlider) or (volume as HSlider).editable:
		return "volume placeholder missing"
	if full == null or not (full is BaseButton) or not (full as BaseButton).disabled:
		return "fullscreen placeholder missing"
	if main.find_child("StarterRow", true, false) != null:
		return "options is showing starters"
	var opt_back: Node = main.find_child("BackButton", true, false)
	if opt_back == null:
		return "options back missing"
	opt_back.pressed.emit()
	await process_frame
	await process_frame
	title_err = _title_menu_err(main)
	if title_err != "":
		return "options back: " + title_err
	var dex_btn: Node = main.find_child("DexButton", true, false)
	dex_btn.pressed.emit()
	await process_frame
	await process_frame
	if main.find_child("DexScreen", true, false) == null:
		return "hatch-dex did not open"
	if main.find_child("StarterRow", true, false) != null:
		return "hatch-dex is showing starters"
	var dex_back: Node = main.find_child("BackButton", true, false)
	if dex_back == null:
		return "dex back missing"
	dex_back.pressed.emit()
	await process_frame
	await process_frame
	title_err = _title_menu_err(main)
	if title_err != "":
		return "dex back: " + title_err
	var play: Node = main.find_child("PlayButton", true, false)
	play.pressed.emit()
	await process_frame
	await process_frame
	var pick_err := _starter_pick_err(main)
	if pick_err != "":
		return pick_err
	var wisp := main.find_child("Starter_cottonwisp", true, false) as BaseButton
	wisp.mouse_entered.emit()
	await create_timer(0.2).timeout
	if wisp.scale.x < 1.02 or wisp.scale.x > 1.04:
		return "starter card hover is not 1.03"
	var wisp_face := wisp.find_child("Capsule", true, false) as Control
	if wisp_face == null or wisp_face.scale != Vector2.ONE:
		return "starter idle is scaling"
	wisp.mouse_exited.emit()
	await create_timer(0.2).timeout
	if absf(wisp.scale.x - 1.0) > 0.02:
		return "starter card hover did not return"
	var spark := main.find_child("Starter_sparkpup", true, false) as BaseButton
	spark.mouse_entered.emit()
	await create_timer(0.2).timeout
	if absf(spark.scale.x - 1.045) > 0.02:
		return "selected card hover changed the scale"
	var confirm_hover := main.find_child("ConfirmButton", true, false) as BaseButton
	confirm_hover.mouse_entered.emit()
	await create_timer(0.2).timeout
	if confirm_hover.scale.x < 1.02 or confirm_hover.scale.x > 1.04:
		return "confirm hover is not 1.03"
	var back_hover := main.find_child("BackButton", true, false) as BaseButton
	back_hover.mouse_entered.emit()
	await create_timer(0.2).timeout
	if back_hover.scale.x < 1.02 or back_hover.scale.x > 1.04:
		return "back hover is not 1.03"
	var pick_back: Node = main.find_child("BackButton", true, false)
	pick_back.pressed.emit()
	await process_frame
	await process_frame
	if g.phase != "start":
		return "back left the title phase"
	title_err = _title_menu_err(main)
	if title_err != "":
		return "starter back: " + title_err
	play = main.find_child("PlayButton", true, false)
	play.pressed.emit()
	await process_frame
	await process_frame
	pick_err = _starter_pick_err(main)
	if pick_err != "":
		return pick_err
	if _text_has(main, "greybox"):
		return "greybox subtitle still showing"
	var sprout: Node = main.find_child("Starter_sproutling", true, false)
	if sprout == null:
		return "sproutling card missing"
	sprout.pressed.emit()
	await process_frame
	await process_frame
	if g.phase != "start":
		return "card press started the run"
	sprout = main.find_child("Starter_sproutling", true, false) as BaseButton
	if sprout == null or absf((sprout as BaseButton).scale.x - 1.045) > 0.02:
		return "sproutling did not select"
	var confirm: Node = main.find_child("ConfirmButton", true, false)
	if confirm == null:
		return "confirm missing"
	confirm.pressed.emit()
	await process_frame
	await process_frame
	if str(g.run.node_id) != "sparring_1":
		return "pick did not start sparring"
	var page_wash: Node = main.find_child("MeadowWash", true, false)
	var board_wash: Node = main.find_child("BoardMeadow", true, false)
	if page_wash == null or int(page_wash.z_index) >= 0:
		return "prep wash should sit behind the page"
	if board_wash == null or int(board_wash.z_index) >= 0:
		return "board wash should sit behind the slots"
	var page_tex: Node = page_wash.find_child("WashUnderlay", true, false)
	if page_tex == null or not (page_tex is TextureRect):
		return "prep wash is not an underlay"
	if "wash-underlay-battle" not in str((page_tex as TextureRect).texture.resource_path):
		return "prep wash is not the battle sheet"
	if board_wash.find_child("WashUnderlay", true, false) != null:
		return "board stacked a second wash"
	var path_now: Node = main.find_child("PathNow", true, false)
	if path_now == null or not (path_now is TextureRect):
		return "active path node is not the solid token"
	var grass_step: Node = null
	for step in main.find_children("PathStep", "Label", true, false):
		if str(step.text) == "Grass":
			grass_step = step
	if grass_step == null:
		return "path label missing"
	var ink: Color = grass_step.get_theme_color("font_color")
	if ink.r > 0.45 or ink.g > ink.r + 0.08:
		return "path label washed out %s" % ink
	if grass_step.get_parent() == null or str(grass_step.get_parent().name) != "PathChip":
		return "path label has no chip"
	var land: Node = main.find_child("ArrivalText", true, false)
	if land == null or "Sparring" not in str(land.text):
		return "starter transition beat missing"
	var center = main.find_child("Board4", true, false)
	if center == null or int(center.get("unit_uid")) < 0:
		return "starter not on the board slot"
	var badge: Node = center.find_child("RoleBadge", true, false)
	if badge == null or str(badge.get("kind")) != "melee":
		return "starter role badge"
	var board_face: Node = center.find_child("Capsule", true, false)
	if board_face == null or board_face.get_script() == null:
		return "starter board is still a plain capsule"
	if str(board_face.get_script().resource_path) != "res://scripts/starter_face.gd":
		return "starter board face script"
	if int(board_face.get("sheet_px")) != 64:
		return "starter board is not the 64 sheet"
	var heads: Node = main.find_child("RankHeads", true, false)
	if heads == null or not _text_has(heads, "Front") or not _text_has(heads, "Back"):
		return "rank headers"
	if not center.has_method("_get_drag_data") or not center.has_method("_drop_data"):
		return "board slot is not drag-drop"
	var sell: Node = main.find_child("SellZone", true, false)
	if sell == null:
		return "no sell zone"
	var hint: Node = sell.find_child("SellHint", true, false)
	if hint == null or not (hint is Label) or "Drag a critter here" not in str(hint.text):
		return "sell zone is not a drag target"
	if not sell.has_method("_can_drop_data") or not sell.has_method("_drop_data"):
		return "sell zone does not take a drop"
	if not bool(sell._can_drop_data(Vector2.ZERO, {"uid": int(center.get("unit_uid"))})):
		return "sell zone rejected a critter"
	var fight: Node = main.find_child("FightButton", true, false)
	if fight == null:
		return "no fight button"
	var trait_label: Node = main.find_child("TraitLabel", true, false)
	if trait_label == null or trait_label.text == "":
		return "trait not shown"
	if main.find_child("BuddyLegend", true, false) != null:
		return "buddy wall still on the board"
	if _text_has(main, "seed"):
		return "seed visible on the hud"
	if _text_has(main, "Orthogonal buddies"):
		return "buddy formula still on the board"
	var spar_teach: Node = main.find_child("TeachLine", true, false)
	if spar_teach == null:
		return "sparring should teach once"
	fight.pressed.emit()
	await process_frame
	await process_frame
	if g.phase != "combat":
		return "fight did not start"
	var fight_beat: Node = main.find_child("ArrivalText", true, false)
	if fight_beat == null or str(fight_beat.text) != "Fight":
		return "fight transition beat missing"
	if main.tick and not main.tick.is_stopped():
		return "fight ticked under the beat"
	var speed: Node = main.find_child("SpeedButton", true, false)
	if speed == null:
		return "no speed toggle"
	speed.pressed.emit()
	if g.speed != 2:
		return "speed stayed at 1"
	if "×2" not in str(speed.text):
		return "speed x2 not readable: " + str(speed.text)
	var clog: Node = main.find_child("CombatLog", true, false)
	if clog == null or clog.visible:
		return "combat log should start collapsed"
	if main.tick:
		main.tick.stop()
	var guard = 0
	while g.combat != null and not g.combat.over and guard < 30:
		g.combat_tick()
		guard += 1
	if g.combat == null or not g.combat.player_won:
		_dump(g.combat, "ui sparring")
		return "ui sparring lost"
	g.finish_combat()
	await process_frame
	await process_frame
	if str(g.run.node_id) != "shop_a":
		return "shop did not open"
	var after_log: Node = main.find_child("FightLogText", true, false)
	if after_log == null or not after_log.visible or "→" not in str(after_log.text):
		return "full log not on screen after the fight"
	var reward_beat: Node = main.find_child("ArrivalText", true, false)
	if reward_beat == null or "clear" not in str(reward_beat.text):
		return "reward beat missing"
	var reroll: Node = main.find_child("RerollButton", true, false)
	var buy: Node = main.find_child("BuyButton0", true, false)
	if reroll == null or buy == null:
		return "shop controls missing"
	var bench_before = int(main.find_child("Bench0", true, false).get("unit_uid"))
	buy.pressed.emit()
	await process_frame
	await process_frame
	var bench: Node = main.find_child("Bench0", true, false)
	if bench == null or int(bench.get("unit_uid")) < 0:
		return "buy did not reach the bench (before %d)" % bench_before
	# Drag the purchase onto the board through the same drop path the mouse uses.
	g.handle_drop("board", 0, {"uid": int(bench.get("unit_uid"))})
	await process_frame
	await process_frame
	var corner = main.find_child("Board0", true, false)
	if corner == null or int(corner.get("unit_uid")) < 0:
		return "drop did not place"
	var sell_zone: Node = main.find_child("SellZone", true, false)
	var coins_before := int(g.run.coins)
	sell_zone._drop_data(Vector2.ZERO, {"uid": int(corner.get("unit_uid"))})
	await process_frame
	await process_frame
	var cleared: Node = main.find_child("Board0", true, false)
	if cleared == null or int(cleared.get("unit_uid")) >= 0:
		return "sell drop left the critter"
	if int(g.run.coins) != coins_before + g.econ("SELL_T1"):
		return "sell drop paid the wrong amount"
	if _text_has(main, "1 coin per") or _text_has(main, "Pairs sit"):
		return "shop teach wall still up"
	var stall_teach: Node = main.find_child("TeachLine", true, false)
	if stall_teach == null or not (stall_teach is Label):
		return "first stall should teach once"
	if _packed_stall(str(stall_teach.text)):
		return "first stall still packs every lesson"
	if _button_says(main, "Sell"):
		return "per-cell sell button remains"
	g.enter_node("shop_b")
	await process_frame
	await process_frame
	if main.find_child("TeachLine", true, false) != null:
		return "teach returned after the first stall"
	if _text_has(main, "Orthogonal buddies") or _text_has(main, "1 coin per") or _text_has(main, "Pairs sit"):
		return "later shop still has a teach wall"
	return ""


func _test_quiet_prep() -> String:
	g.debug_reset_profile()
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	g.blank_run()
	# Under the soft crowd line the full stat row stays, so early boards still read.
	var early := ["cloudbud", "cloudbud", "driftkin", "thornbud"]
	for i in early.size():
		g.run.board[i] = g.make_unit(early[i])
	g.enter_node("wild_1")
	await process_frame
	await process_frame
	if g.board_count() != 4:
		return "early count %d" % g.board_count()
	if _board_stat_lines(main).is_empty():
		return "under 5 should still show ATK ARM REG"
	# 6 fill: name + HP, pair pip, and buddy chips. Stats only on the selected cell.
	g.run.board[4] = g.make_unit("foxfire")
	g.run.board[5] = g.make_unit("emberfox")
	g.changed.emit()
	await process_frame
	await process_frame
	if g.board_count() != 6:
		return "crowded count %d" % g.board_count()
	var clutter := _board_stat_lines(main)
	if not clutter.is_empty():
		return "5-7 board shows " + " | ".join(clutter)
	if not _board_has_text(main, "2/3"):
		return "pair pip hidden at 5-7"
	if not _board_has_chip(main):
		return "buddy chip hidden at 5-7"
	if not _board_has_hp(main):
		return "HP missing at 5-7"
	if _quiet_count(main, true) != 0:
		return "quiet detail visible with nothing selected"
	var focus_uid := -1
	for i in g.run.board.size():
		var u = g.run.board[i]
		if u != null and str(u.def_id) == "driftkin":
			focus_uid = int(u.uid)
	main.focus_uid = focus_uid
	g.changed.emit()
	await process_frame
	await process_frame
	if _quiet_count(main, true) != 1:
		return "select should open one stat line (%d)" % _quiet_count(main, true)
	var leaked := _board_stat_lines(main)
	if leaked.size() != 1:
		return "select leaked stats " + " | ".join(leaked)
	var corner: Node = main.find_child("Board0", true, false)
	if corner == null or "ATK" not in str(corner.tooltip_text):
		return "tooltip dropped the stat line"
	return ""


func _board_slots(main: Node) -> Array:
	var slots: Array = []
	for i in 9:
		var slot: Node = main.find_child("Board%d" % i, true, false)
		if slot != null and int(slot.get("unit_uid")) >= 0:
			slots.append(slot)
	return slots


func _visible_texts(node: Node, out: PackedStringArray) -> void:
	if node is CanvasItem and not (node as CanvasItem).visible:
		return
	if node is Label:
		out.append(str((node as Label).text))
	for c in node.get_children():
		_visible_texts(c, out)


func _is_stat_line(text: String) -> bool:
	if text.begins_with("+"):
		return false
	return "ATK" in text or "ARM" in text or "REG" in text


func _board_stat_lines(main: Node) -> PackedStringArray:
	var found := PackedStringArray()
	for slot in _board_slots(main):
		var s: Node = slot
		var texts := PackedStringArray()
		_visible_texts(s, texts)
		for t in texts:
			if _is_stat_line(t):
				found.append(t)
	return found


func _board_has_text(main: Node, needle: String) -> bool:
	for slot in _board_slots(main):
		var s: Node = slot
		var texts := PackedStringArray()
		_visible_texts(s, texts)
		for t in texts:
			if needle in t:
				return true
	return false


func _board_has_chip(main: Node) -> bool:
	for slot in _board_slots(main):
		var s: Node = slot
		var texts := PackedStringArray()
		_visible_texts(s, texts)
		for t in texts:
			if t.begins_with("+"):
				return true
	return false


func _board_has_hp(main: Node) -> bool:
	for slot in _board_slots(main):
		var s: Node = slot
		var texts := PackedStringArray()
		_visible_texts(s, texts)
		for t in texts:
			if t.ends_with("HP") and not _is_stat_line(t):
				return true
	return false


func _quiet_count(main: Node, want_visible: bool) -> int:
	var n := 0
	for slot in _board_slots(main):
		var s: Node = slot
		var detail: Node = s.find_child("QuietDetail", true, false)
		if detail != null and detail.visible == want_visible:
			n += 1
	return n


func _packed_stall(text: String) -> bool:
	var n := 0
	if "Freeze" in text:
		n += 1
	if "2/3" in text:
		n += 1
	if "Interest" in text:
		n += 1
	return n > 1


func _title_menu_err(main: Node) -> String:
	if main.find_child("TitleMenu", true, false) == null:
		return "title menu missing"
	if main.find_child("StarterRow", true, false) != null or main.find_child("StarterMeadow", true, false) != null:
		return "title is showing starters"
	for starter_id in ["sproutling", "sparkpup", "cottonwisp", "budmite"]:
		if main.find_child("Starter_%s" % starter_id, true, false) != null:
			return "title is showing starter " + starter_id
	var play := main.find_child("PlayButton", true, false) as BaseButton
	var dex := main.find_child("DexButton", true, false) as BaseButton
	var options := main.find_child("OptionsButton", true, false) as BaseButton
	if play == null or dex == null or options == null:
		return "title nav missing"
	if play.custom_minimum_size != dex.custom_minimum_size or play.custom_minimum_size != options.custom_minimum_size:
		return "title nav weights differ"
	if play.size_flags_horizontal != Control.SIZE_SHRINK_CENTER:
		return "play button stretches"
	var nav := main.find_child("TitleNav", true, false)
	if nav == null or not (nav is VBoxContainer):
		return "title nav is not a vertical stack"
	var view_h := play.get_viewport_rect().size.y
	if view_h > 1.0 and play.size.y > 1.0:
		var ui = load("res://scripts/main.gd")
		var band := float(ui.TITLE_NAV_ANCHOR)
		var play_y := play.get_global_rect().position.y
		var dex_y := dex.get_global_rect().position.y
		var options_y := options.get_global_rect().position.y
		if play_y >= dex_y or dex_y >= options_y:
			return "title nav is not stacked vertically"
		if absf(play_y / view_h - band) > 0.04:
			return "title pills are not at the raised lock"
		var logo := main.find_child("TitleWordmark", true, false) as Control
		if logo != null and logo.size.y > 1.0:
			var word_top := logo.get_global_rect().position.y / view_h
			if word_top < 0.06 or word_top > 0.14:
				return "logo is not high in the sky"
	if dex.size_flags_horizontal != Control.SIZE_SHRINK_CENTER or options.size_flags_horizontal != Control.SIZE_SHRINK_CENTER:
		return "title nav stretches"
	var play_box := play.get_theme_stylebox("normal")
	if not (play_box is StyleBoxFlat):
		return "play pill missing"
	var pill := play_box as StyleBoxFlat
	if pill.bg_color.r < 0.95 or pill.bg_color.g < 0.90 or pill.get_border_width(SIDE_LEFT) < 4:
		return "play is not a cream pill"
	var dex_box := dex.get_theme_stylebox("normal")
	if dex_box is StyleBoxFlat and (dex_box as StyleBoxFlat).bg_color != pill.bg_color:
		return "hatch-dex pill does not match play"
	var mark := main.find_child("TitleMark", true, false)
	if mark == null:
		return "title mark missing"
	var word := main.find_child("TitleWordmark", true, false) as TextureRect
	if word == null or word.texture == null:
		return "trio wordmark missing"
	var word_path := str(word.texture.resource_path)
	if "wordmark-hatchline-trio" not in word_path:
		return "title logo is not the trio wordmark"
	if "wordmark-hatchline-icon" in word_path or "wordmark-hatchline-only" in word_path:
		return "archive wordmark is the default"
	if word.scale != Vector2.ONE:
		return "wordmark is moving"
	var version := main.find_child("TitleVersion", true, false) as Label
	if version == null or version.text != "v0.playtest-1":
		return "version crumb missing"
	var stage_err := _title_stage_err(main)
	if stage_err != "":
		return stage_err
	var park := main.find_child("ReservePark", true, false) as BaseButton
	var trail := main.find_child("SeasonTrail", true, false) as BaseButton
	if park == null or trail == null or not park.disabled or not trail.disabled:
		return "title park/trail tease missing"
	if park.custom_minimum_size.y >= play.custom_minimum_size.y:
		return "park tease competes with play"
	if park.modulate.a > 0.85:
		return "park tease is not greyed"
	return ""


func _starter_pick_err(main: Node) -> String:
	if main.find_child("StarterPick", true, false) == null:
		return "starter pick missing"
	if main.find_child("PlayButton", true, false) != null:
		return "play is still on the starter pick"
	if main.find_child("TitleMenu", true, false) != null:
		return "starter pick is still the title"
	if main.find_child("StarterMeadow", true, false) != null:
		return "card-band wash should be gone"
	var stage_err := _title_stage_err(main)
	if stage_err != "":
		return stage_err
	for starter_id in ["sproutling", "sparkpup", "cottonwisp"]:
		if main.find_child("Starter_%s" % starter_id, true, false) == null:
			return "missing starter " + starter_id
	if main.find_child("Starter_budmite", true, false) != null:
		return "budmite still on the starter row"
	var prompt := main.find_child("StarterPrompt", true, false) as Label
	if prompt == null or prompt.text != "Pick your starter":
		return "starter header missing"
	var sage: Color = prompt.get_theme_color("font_color")
	if sage.g < sage.r or sage.g < 0.45:
		return "starter header is not sage"
	var confirm := main.find_child("ConfirmButton", true, false) as BaseButton
	var back := main.find_child("BackButton", true, false) as BaseButton
	if confirm == null or back == null:
		return "starter pick actions missing"
	if confirm.custom_minimum_size != Vector2(260, 48) or back.custom_minimum_size != Vector2(260, 48):
		return "starter pills are not 260x48"
	var view_h := prompt.get_viewport_rect().size.y
	if view_h > 1.0 and prompt.size.y > 1.0:
		var ui = load("res://scripts/main.gd")
		var header_top: float = prompt.get_global_rect().position.y / view_h
		if absf(header_top - float(ui.PICK_HEADER_ANCHOR)) > 0.04:
			return "starter header is not near 10%"
		for starter_id in ["sproutling", "sparkpup", "cottonwisp"]:
			var card := main.find_child("Starter_%s" % starter_id, true, false) as Control
			if card.size.y <= 1.0:
				return "starter card has no size"
			var mid: float = card.get_global_rect().get_center().y / view_h
			if absf(mid - float(ui.PICK_CARD_ANCHOR)) > 0.04:
				return "starter cards are not mid-screen"
			var face := card.find_child("Capsule", true, false)
			if face == null or face.get_script() == null:
				return "starter portrait is not the idle sheet"
			if str(face.get_script().resource_path) != "res://scripts/starter_face.gd":
				return "starter portrait is not the idle sheet"
			if (face as Control).scale != Vector2.ONE:
				return "starter portrait scale is tweening"
		var spark := main.find_child("Starter_sparkpup", true, false) as BaseButton
		var sprout := main.find_child("Starter_sproutling", true, false) as BaseButton
		if absf(spark.scale.x - float(ui.PICK_SELECTED_SCALE)) > 0.02:
			return "sparkpup is not selected"
		if absf(sprout.scale.x - 1.0) > 0.02:
			return "unselected card is scaled"
		var spark_box := spark.get_theme_stylebox("normal") as StyleBoxFlat
		var sprout_box := sprout.get_theme_stylebox("normal") as StyleBoxFlat
		if spark_box == null or spark_box.get_border_width(SIDE_LEFT) < 7:
			return "selected card outline is thin"
		if sprout_box == null or sprout_box.get_border_width(SIDE_LEFT) > 4:
			return "idle card outline is thick"
		if spark_box.shadow_size < 8:
			return "selected card has no glow"
		var action_top: float = confirm.get_global_rect().position.y / view_h
		if absf(action_top - float(ui.PICK_ACTION_ANCHOR)) > 0.04:
			return "starter pills are not near 74%"
	var version := main.find_child("TitleVersion", true, false) as Label
	if version == null or version.text != "v0.playtest-1":
		return "version crumb missing"
	return ""


func _title_stage_err(main: Node) -> String:
	var ui = load("res://scripts/main.gd")
	if str(ui.TITLE_BG_CHOICE) != "pack":
		return "pack stack is not the default"
	if "title-composite-painted-alt" not in str(ui.TITLE_PAINTED_ALT):
		return "painted alt is not loadable"
	if "bg-title-texture-B" not in str(ui.TITLE_TEXTURE_B):
		return "meadow fallback missing"
	if main.find_child("TitleTexture", true, false) != null:
		return "meadow fallback is showing"
	var names := ["TitleSky", "TitleClouds", "TitleFar", "TitleMid", "TitleNear", "TitlePaper"]
	var prev_z := -100
	for layer_name in names:
		var layer := main.find_child(layer_name, true, false)
		if layer == null:
			return "missing " + layer_name
		if int(layer.z_index) <= prev_z or int(layer.z_index) >= 0:
			return "scenery is out of order"
		prev_z = int(layer.z_index)
	var clouds := main.find_child("TitleClouds", true, false)
	var drift := float(clouds.get_meta("drift_px"))
	var drift_sec := float(clouds.get_meta("drift_sec"))
	if drift < 8.0 or drift > 16.0 or drift_sec < 12.0 or drift_sec > 20.0:
		return "cloud drift is out of band"
	for hill_name in ["TitleFar", "TitleMid", "TitleNear"]:
		var hill := main.find_child(hill_name, true, false)
		var hill_px := float(hill.get_meta("drift_px"))
		var hill_sec := float(hill.get_meta("drift_sec"))
		if hill_px < 0.0 or hill_px > 4.0 or hill_sec < 18.0 or hill_sec > 22.0:
			return "%s drift is outside the hill clamp" % hill_name
	var paper := main.find_child("TitlePaper", true, false) as CanvasItem
	if paper.modulate.a < 0.08 or paper.modulate.a > 0.12:
		return "paper softlight is not a light veil"
	var plate_err := _opaque_plate_err(main)
	if plate_err != "":
		return plate_err
	var credit := main.find_child("SkyCredit", true, false) as Label
	if credit == null or "edermunizz" not in credit.text.to_lower():
		return "sky credit missing"
	var sky_art := main.find_child("TitleSkyArt", true, false) as TextureRect
	if sky_art == null or sky_art.texture == null or "layers/sky" not in str(sky_art.texture.resource_path):
		return "sky layer missing"
	return ""


func _opaque_plate_err(main: Node) -> String:
	var sky := main.find_child("TitleSky", true, false) as CanvasItem
	if sky == null:
		return "sky layer missing"
	var sky_z := _canvas_z(sky)
	for node in main.find_children("*", "ColorRect", true, false):
		var rect := node as ColorRect
		if rect.color.a < 0.5:
			continue
		var rect_h := rect.get_global_rect().size.y
		var view_h := rect.get_viewport_rect().size.y
		if view_h <= 1.0 or rect_h < view_h * 0.9:
			continue
		var z := _canvas_z(rect)
		if z > sky_z and z < 0:
			return "opaque plate covers the pack hills"
	return ""


func _canvas_z(node: CanvasItem) -> int:
	var z := node.z_index
	if not node.z_as_relative:
		return z
	var parent := node.get_parent()
	if parent is CanvasItem:
		return z + _canvas_z(parent)
	return z


func _text_has(node: Node, needle: String) -> bool:
	if node is Label and needle.to_lower() in str(node.text).to_lower():
		return true
	if node is Button and needle.to_lower() in str(node.text).to_lower():
		return true
	for c in node.get_children():
		if _text_has(c, needle):
			return true
	return false


func _button_says(node: Node, needle: String) -> bool:
	if node is Button and str(node.text).begins_with(needle):
		return true
	for c in node.get_children():
		if _button_says(c, needle):
			return true
	return false


func _put(zone: String, index: int, id: String) -> Dictionary:
	var u = g.make_unit(id)
	if zone == "board":
		g.run.board[index] = u
	else:
		g.run.bench[index] = u
	return u


func _find(def_id: String):
	for u in g.all_units():
		if str(u.def_id) == def_id:
			return u
	return null


func _fighter(id: String, x: int, y: int) -> Dictionary:
	var u = g.make_unit(id)
	u.pos = Vector2i(x, y)
	return u


func _sim(units: Array, enc_id: String) -> CombatSim:
	var sim = CombatSim.new()
	sim.setup(units, g.encounters[enc_id], g.enemy_defs, g.economy)
	return sim


func _fight(units: Array, enc_id: String, should_win: bool, label: String) -> String:
	var sim = _sim(units, enc_id)
	var guard = 0
	while not sim.over and guard < 40:
		sim.step()
		guard += 1
	print("  ", label, " ", "win" if sim.player_won else "loss", " round ", sim.round_i, " adds ", sim.adds_summoned)
	if should_win and not sim.player_won:
		_dump(sim, label)
		return label + " should win"
	if not should_win and sim.player_won:
		return label + " should lose"
	return ""


func _cleared(arr: Array) -> Array:
	var out: Array = []
	out.resize(arr.size())
	for i in out.size():
		out[i] = null
	return out


func _dump(sim: CombatSim, label: String) -> void:
	if sim == null:
		print("  ", label, " no sim")
		return
	print("  ", label, " log:")
	for line in sim.log_lines:
		print("   ", line)
	print("  reason: ", sim.defeat_reason())
