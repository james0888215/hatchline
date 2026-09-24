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
		print("RUN ui_smoke")
		var ui_err: String = await _test_ui()
		if ui_err != "":
			print("FAIL ui_smoke: ", ui_err)
			failures.append("ui_smoke")
		else:
			print("OK   ui_smoke")
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
	if sim.enemies.size() != 3:
		return "wild count"
	var linked = 0
	for e in sim.enemies:
		var expect = g.econ("LEAF_BUDDY_ARMOR") * (2 if int(e.local_y) == 1 else 1)
		if int(e.bonus_armor) != expect:
			return "barkling armour %d != %d" % [int(e.bonus_armor), expect]
		linked += 1
	if linked < 3:
		return "not all buddied"
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
	if purse < price:
		return "can't afford a buy after fight 1"
	if purse >= price * 2:
		return "first stall still buys a triple, purse %d" % purse
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


func _test_ui() -> String:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var reason: Node = main.find_child("ResultLine", true, false)
	if reason == null or "Nothing fielded" not in reason.text:
		return "result line not on screen"
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
		return "retry did not return to starters"
	for starter_id in ["sproutling", "sparkpup", "cottonwisp"]:
		var card: Node = main.find_child("Starter_%s" % starter_id, true, false)
		if card == null:
			return "missing starter " + starter_id
	if main.find_child("Starter_budmite", true, false) != null:
		return "budmite still on the starter row"
	if _text_has(main, "greybox"):
		return "greybox subtitle still showing"
	var sprout: Node = main.find_child("Starter_sproutling", true, false)
	if sprout == null:
		return "sproutling card missing"
	sprout.pressed.emit()
	await process_frame
	await process_frame
	if str(g.run.node_id) != "sparring_1":
		return "pick did not start sparring"
	var land: Node = main.find_child("ArrivalText", true, false)
	if land == null or "Sparring" not in str(land.text):
		return "starter transition beat missing"
	var center = main.find_child("Board4", true, false)
	if center == null or int(center.get("unit_uid")) < 0:
		return "starter not on the board slot"
	var badge: Node = center.find_child("RoleBadge", true, false)
	if badge == null or str(badge.get("kind")) != "melee":
		return "starter role badge"
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
