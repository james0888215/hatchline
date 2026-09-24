class_name CombatSim
extends RefCounted

var allies: Array = []
var enemies: Array = []
var log_lines: Array = []
var round_i: int = 0
var over: bool = false
var player_won: bool = false
var timed_out: bool = false
var banner: String = ""
var banner_ttl: int = 0
var adds_summoned: int = 0
# Presentation only. Each step replaces these with hit/heal numbers and motion cues.
var floats: Array = []
var cues: Array = []
var economy: Dictionary = {}
var enemy_defs: Dictionary = {}
var script_steps: Array = []
var fired: Dictionary = {}
var stats: Dictionary = {}
var next_uid: int = 1000


static func buddy_counts(units: Array) -> Dictionary:
	var counts := {}
	for u in units:
		counts[int(u.uid)] = 0
	for i in units.size():
		var a: Dictionary = units[i]
		if not bool(a.get("alive", true)):
			continue
		for j in range(i + 1, units.size()):
			var b: Dictionary = units[j]
			if not bool(b.get("alive", true)):
				continue
			if str(a.family) != str(b.family):
				continue
			var d := absi(int(a.pos.x) - int(b.pos.x)) + absi(int(a.pos.y) - int(b.pos.y))
			if d == 1:
				counts[int(a.uid)] = int(counts[int(a.uid)]) + 1
				counts[int(b.uid)] = int(counts[int(b.uid)]) + 1
	return counts


static func apply_buddy_bonuses(units: Array, econ: Dictionary) -> void:
	var counts := buddy_counts(units)
	var leaf := int(econ["LEAF_BUDDY_ARMOR"])
	var ember := int(econ["EMBER_BUDDY_DAMAGE"])
	var puff := int(econ["PUFF_BUDDY_REGEN"])
	for u in units:
		var n := int(counts.get(int(u.uid), 0))
		u.buddy_n = n
		u.bonus_armor = 0
		u.bonus_atk = 0
		u.bonus_regen = 0
		if n <= 0:
			continue
		match str(u.family):
			"leaf":
				u.bonus_armor = n * leaf
			"ember":
				u.bonus_atk = n * ember
			"puff":
				u.bonus_regen = n * puff


func setup(player_units: Array, encounter: Dictionary, defs: Dictionary, econ: Dictionary) -> void:
	allies = []
	enemies = []
	log_lines = []
	round_i = 0
	over = false
	player_won = false
	timed_out = false
	banner = ""
	banner_ttl = 0
	adds_summoned = 0
	floats = []
	cues = []
	fired = {}
	economy = econ
	enemy_defs = defs
	script_steps = encounter.get("script", [])
	stats = {
		"fielded": 0,
		"buddy_links": 0,
		"had_leaf": false,
		"had_ember": false,
		"had_puff": false,
		"had_splash": false,
		"damage_dealt": 0,
		"damage_taken": 0,
		"burn_taken": 0,
		"boss": false,
		"adds_summoned": 0,
		"ranged_front_fell": false,
		"melee_back_fell": false,
	}
	var offset := int(econ["ENEMY_X_OFFSET"])
	for src in player_units:
		var u := _fill_unit(src)
		u.side = "ally"
		u.boss = false
		allies.append(u)
		next_uid = maxi(next_uid, int(u.uid) + 1)
	for spec in encounter.get("units", []):
		var u := _make_enemy(str(spec.def), int(spec.x), int(spec.y), offset)
		enemies.append(u)
		if bool(u.boss):
			stats.boss = true
	if script_steps.size() > 0:
		stats.boss = true
	_apply_side(allies)
	_apply_side(enemies)
	_log_buddies(allies)
	_log_buddies(enemies)
	var links := 0
	for u in allies:
		stats.fielded = int(stats.fielded) + 1
		links += int(u.buddy_n)
		match str(u.family):
			"leaf":
				stats.had_leaf = true
			"ember":
				stats.had_ember = true
			"puff":
				stats.had_puff = true
		if int(u.splash) > 0:
			stats.had_splash = true
	stats.buddy_links = int(links / 2)
	if allies.is_empty():
		over = true
		player_won = false


func step() -> void:
	if over:
		return
	floats = []
	cues = []
	if banner_ttl > 0:
		banner_ttl -= 1
		if banner_ttl == 0:
			banner = ""
	round_i += 1
	_apply_side(allies)
	_apply_side(enemies)
	_regen_all()
	_burn_all()
	_purge_check()
	if over:
		return
	for actor in _actors():
		if not bool(actor.alive):
			continue
		var foes: Array = enemies if str(actor.side) == "ally" else allies
		if _living(foes).is_empty():
			break
		_attack(actor)
		_purge_check()
		if over:
			return
	_mend_all()
	_purge_check()
	if over:
		return
	_boss_script()
	_purge_check()
	if over:
		return
	if round_i >= int(economy["COMBAT_MAX_ROUNDS"]):
		_timeout()


func defeat_reason() -> String:
	if int(stats.get("fielded", 0)) <= 0:
		return "Nothing fielded — place critters on the board"
	if timed_out:
		return "Outlasted — their side still stood when the clock ended"
	if bool(stats.get("boss", false)) and int(stats.get("adds_summoned", 0)) > 0 and not bool(stats.get("had_splash", false)):
		return "Adds swarmed the board — an Ember evolve splashes them"
	if bool(stats.get("ranged_front_fell", false)):
		return "Ranged in front melted"
	if bool(stats.get("melee_back_fell", false)):
		return "Melee in the back barely reached"
	if not bool(stats.get("had_leaf", false)) and int(stats.get("damage_taken", 0)) > int(stats.get("damage_dealt", 0)):
		return "Frontline melted — no Leaf buddies"
	if int(stats.get("buddy_links", 0)) <= 0 and int(stats.get("fielded", 0)) >= 2:
		return "No buddies linked — same-family neighbours share a bonus"
	if not bool(stats.get("had_puff", false)) and int(stats.get("burn_taken", 0)) > 0:
		return "Chip damage stuck — no Puff regen"
	return "Your line broke first"


func _fill_unit(src: Dictionary) -> Dictionary:
	var u := src.duplicate()
	u.alive = true
	u.hp = int(u.get("hp", u.get("max_hp", 1)))
	u.max_hp = int(u.get("max_hp", u.hp))
	u.atk = int(u.get("atk", 1))
	u.armor = int(u.get("armor", 0))
	u.regen = int(u.get("regen", 0))
	u.thorns = int(u.get("thorns", 0))
	u.splash = int(u.get("splash", 0))
	u.burn_applied = int(u.get("burn_applied", 0))
	u.mend = str(u.get("mend", ""))
	u.family = str(u.get("family", "beast"))
	u.role = _role_name(u)
	u.name = str(u.get("name", "Critter"))
	u.uid = int(u.get("uid", 0))
	u.boss = bool(u.get("boss", false))
	u.burn_dmg = 0
	u.burn_left = 0
	u.bonus_armor = 0
	u.bonus_atk = 0
	u.bonus_regen = 0
	u.buddy_n = 0
	return u


func _make_enemy(def_id: String, local_x: int, local_y: int, offset: int = -1) -> Dictionary:
	if offset < 0:
		offset = int(economy["ENEMY_X_OFFSET"])
	var d: Dictionary = enemy_defs[def_id]
	next_uid += 1
	return {
		"uid": next_uid,
		"def_id": def_id,
		"name": str(d.name),
		"family": str(d.family),
		"hp": int(d.hp),
		"max_hp": int(d.hp),
		"atk": int(d.atk),
		"armor": int(d.get("armor", 0)),
		"regen": int(d.get("regen", 0)),
		"thorns": int(d.get("thorns", 0)),
		"splash": int(d.get("splash", 0)),
		"burn_applied": int(d.get("burn", 0)),
		"mend": str(d.get("mend", "")),
		"role": _role_name(d),
		"boss": bool(d.get("boss", false)),
		"side": "enemy",
		"alive": true,
		"local_x": local_x,
		"local_y": local_y,
		"pos": Vector2i(offset + local_x, local_y),
		"burn_dmg": 0,
		"burn_left": 0,
		"bonus_armor": 0,
		"bonus_atk": 0,
		"bonus_regen": 0,
		"buddy_n": 0,
	}


func _apply_side(units: Array) -> void:
	var living: Array = []
	for u in units:
		if bool(u.alive):
			living.append(u)
		else:
			u.buddy_n = 0
			u.bonus_armor = 0
			u.bonus_atk = 0
			u.bonus_regen = 0
	apply_buddy_bonuses(living, economy)


func _log_buddies(units: Array) -> void:
	for u in units:
		if int(u.buddy_n) <= 0:
			continue
		var kind := ""
		match str(u.family):
			"leaf":
				kind = "+%d armour" % int(u.bonus_armor)
			"ember":
				kind = "+%d damage" % int(u.bonus_atk)
			"puff":
				kind = "+%d regen" % int(u.bonus_regen)
			_:
				continue
		_log("Buddy: %s %s (%s ×%d)" % [u.name, kind, str(u.family).capitalize(), int(u.buddy_n)])


func _log(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > 200:
		log_lines.pop_front()


func _living(units: Array) -> Array:
	var out: Array = []
	for u in units:
		if bool(u.alive):
			out.append(u)
	return out


func _actors() -> Array:
	var list: Array = []
	for u in allies:
		if bool(u.alive):
			list.append(u)
	for u in enemies:
		if bool(u.alive):
			list.append(u)
	list.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var asid := 0 if str(a.side) == "ally" else 1
		var bsid := 0 if str(b.side) == "ally" else 1
		if asid != bsid:
			return asid < bsid
		if int(a.pos.y) != int(b.pos.y):
			return int(a.pos.y) < int(b.pos.y)
		return int(a.pos.x) < int(b.pos.x)
	)
	return list


func _attack(actor: Dictionary) -> void:
	var foes: Array = enemies if str(actor.side) == "ally" else allies
	var target: Variant = _pick_target(actor, foes)
	if target == null:
		return
	cues.append({"uid": int(actor.uid), "kind": "windup"})
	var dmg := maxi(1, _scaled_atk(actor) - _total_arm(target))
	_hurt(target, dmg)
	_count_damage(actor, dmg)
	_log("%s → %s  %d" % [actor.name, target.name, dmg])
	if int(target.thorns) > 0 and bool(actor.alive):
		var th := int(target.thorns)
		_hurt(actor, th)
		_count_damage(target, th)
		_log("%s takes %d thorns" % [actor.name, th])
	if bool(actor.alive) and int(actor.splash) > 0:
		var raw := int(float(_total_atk(actor)) * float(actor.splash) / 100.0)
		for other in foes:
			if not bool(other.alive) or int(other.uid) == int(target.uid):
				continue
			if not _ortho(other, target):
				continue
			var sd := raw - _total_arm(other)
			if sd > 0:
				_hurt(other, sd)
				_count_damage(actor, sd)
				_log("%s splash → %s  %d" % [actor.name, other.name, sd])
	if int(actor.burn_applied) > 0 and bool(target.alive):
		target.burn_dmg = int(actor.burn_applied)
		target.burn_left = 3
		_log("%s burns" % target.name)


func _count_damage(src: Dictionary, amount: int) -> void:
	if str(src.side) == "ally":
		stats.damage_dealt = int(stats.damage_dealt) + amount
	else:
		stats.damage_taken = int(stats.damage_taken) + amount


static func _role_name(src: Dictionary) -> String:
	return "ranged" if str(src.get("role", "")) == "ranged" else "melee"


static func rank_label(u: Dictionary) -> String:
	var depth := 0
	if str(u.get("side", "ally")) == "ally":
		var pos := Vector2i(u.get("pos", Vector2i.ZERO))
		depth = clampi(pos.x, 0, 2)
	else:
		depth = clampi(2 - int(u.get("local_x", 0)), 0, 2)
	return ["Back", "Mid", "Front"][depth]


func _role(u: Dictionary) -> String:
	return _role_name(u)


func _rank_depth(u: Dictionary) -> int:
	# 2 is the column nearest the other board. Boards sit side by side,
	# so the player's right column and the enemy's left column are Front.
	if str(u.get("side", "ally")) == "ally":
		return clampi(int(u.pos.x), 0, 2)
	return clampi(2 - int(u.get("local_x", 0)), 0, 2)


func _full_rank(u: Dictionary) -> bool:
	var depth := _rank_depth(u)
	if _role(u) == "ranged":
		return depth <= 1
	return depth >= 1


func _scaled_atk(u: Dictionary) -> int:
	var raw := _total_atk(u)
	if _full_rank(u):
		return raw
	var num := int(economy.get("ROLE_OFF_RANK_NUM", 1))
	var den := maxi(1, int(economy.get("ROLE_OFF_RANK_DEN", 2)))
	return maxi(1, raw * num / den)


func _pick_target(actor: Dictionary, foes: Array) -> Variant:
	if _role(actor) == "ranged":
		return _lowest_hp(actor, foes)
	if str(actor.side) == "enemy":
		var marked := _front_ranged(foes)
		var prefer: Variant = _nearest(actor, marked)
		if prefer != null:
			return prefer
	var front := _in_front(foes)
	var line: Variant = _nearest(actor, front)
	if line != null:
		return line
	return _nearest(actor, foes)


func _front_ranged(foes: Array) -> Array:
	var out: Array = []
	for f in foes:
		if bool(f.alive) and _role(f) == "ranged" and _rank_depth(f) == 2:
			out.append(f)
	return out


func _in_front(foes: Array) -> Array:
	var out: Array = []
	for f in foes:
		if bool(f.alive) and _rank_depth(f) == 2:
			out.append(f)
	return out


func _lowest_hp(actor: Dictionary, foes: Array) -> Variant:
	var best: Variant = null
	var best_hp := 999999
	var best_d := 9999
	for f in foes:
		if not bool(f.alive):
			continue
		var hp := int(f.hp)
		var d := absi(int(f.pos.x) - int(actor.pos.x)) + absi(int(f.pos.y) - int(actor.pos.y))
		if best == null or hp < best_hp or (hp == best_hp and d < best_d):
			best = f
			best_hp = hp
			best_d = d
	return best


func _nearest(actor: Dictionary, foes: Array) -> Variant:
	var best: Variant = null
	var best_d := 9999
	for f in foes:
		if not bool(f.alive):
			continue
		var d := absi(int(f.pos.x) - int(actor.pos.x)) + absi(int(f.pos.y) - int(actor.pos.y))
		if best == null or d < best_d or (d == best_d and int(f.hp) < int(best.hp)):
			best = f
			best_d = d
	return best


func _ortho(a: Dictionary, b: Dictionary) -> bool:
	var d := absi(int(a.pos.x) - int(b.pos.x)) + absi(int(a.pos.y) - int(b.pos.y))
	return d == 1


func _hurt(u: Dictionary, amount: int) -> void:
	if not bool(u.alive):
		return
	u.hp = int(u.hp) - amount
	if amount != 0:
		floats.append({"uid": int(u.uid), "text": "-%d" % amount, "kind": "hit"})
		cues.append({"uid": int(u.uid), "kind": "hit"})
	if int(u.hp) <= 0:
		u.hp = 0
		u.alive = false
		cues.append({"uid": int(u.uid), "kind": "kill"})
		_log("%s faints" % u.name)
		if str(u.side) == "ally" and _role(u) == "ranged" and _rank_depth(u) == 2:
			stats.ranged_front_fell = true
		if str(u.side) == "ally" and _role(u) == "melee" and _rank_depth(u) == 0:
			stats.melee_back_fell = true


func _heal(u: Dictionary, amount: int) -> void:
	if not bool(u.alive) or amount <= 0:
		return
	u.hp = mini(int(u.max_hp), int(u.hp) + amount)
	floats.append({"uid": int(u.uid), "text": "+%d" % amount, "kind": "heal"})


func _total_atk(u: Dictionary) -> int:
	return int(u.atk) + int(u.bonus_atk)


func _total_arm(u: Dictionary) -> int:
	return int(u.armor) + int(u.bonus_armor)


func _total_reg(u: Dictionary) -> int:
	return int(u.regen) + int(u.bonus_regen)


func _regen_all() -> void:
	for u in _chain():
		if not bool(u.alive):
			continue
		var amt := _total_reg(u)
		if amt <= 0 or int(u.hp) >= int(u.max_hp):
			continue
		_heal(u, amt)
		if str(u.side) == "ally":
			_log("%s +%d regen" % [u.name, amt])


func _burn_all() -> void:
	for u in _chain():
		if not bool(u.alive) or int(u.burn_left) <= 0:
			continue
		var d := int(u.burn_dmg)
		u.burn_left = int(u.burn_left) - 1
		_hurt(u, d)
		if str(u.side) == "ally":
			stats.burn_taken = int(stats.burn_taken) + d
			stats.damage_taken = int(stats.damage_taken) + d
		_log("%s burn %d" % [u.name, d])


func _mend_all() -> void:
	for u in allies:
		if not bool(u.alive):
			continue
		var kind := str(u.mend)
		if kind == "":
			continue
		var amt := _total_reg(u)
		if amt <= 0:
			continue
		if kind == "one":
			var t: Variant = _lowest(allies)
			if t == null:
				continue
			_heal(t, amt)
			_log("%s mends %s +%d" % [u.name, t.name, amt])
		elif kind == "all":
			for a in allies:
				if bool(a.alive):
					_heal(a, amt)
			_log("%s mends the line +%d" % [u.name, amt])


func _lowest(units: Array) -> Variant:
	var best: Variant = null
	var best_r := 999.0
	for u in units:
		if not bool(u.alive):
			continue
		var r := float(u.hp) / float(maxi(1, int(u.max_hp)))
		if best == null or r < best_r:
			best = u
			best_r = r
	return best


func _boss_script() -> void:
	var boss: Variant = null
	for e in enemies:
		if bool(e.get("boss", false)) and bool(e.alive):
			boss = e
			break
	if boss == null:
		return
	var ratio := float(boss.hp) / float(maxi(1, int(boss.max_hp)))
	for step_def in script_steps:
		var id := str(step_def.id)
		if bool(fired.get(id, false)):
			continue
		if ratio <= float(step_def.when_hp_below):
			fired[id] = true
			_summon_wave(step_def)


func _summon_wave(step_def: Dictionary) -> void:
	var count := int(step_def.get("count", 1))
	var def_id := str(step_def.summon)
	var spots := _empty_enemy_slots()
	banner = "The Matron calls the thicket!"
	banner_ttl = 2
	_log(banner)
	for i in count:
		if i >= spots.size():
			_log("The thicket is full")
			break
		var spot: Vector2i = spots[i]
		var u := _make_enemy(def_id, spot.x, spot.y)
		enemies.append(u)
		adds_summoned += 1
		stats.adds_summoned = adds_summoned
		_log("%s hops in" % u.name)
	_apply_side(enemies)


func _empty_enemy_slots() -> Array:
	var used := {}
	for e in enemies:
		if bool(e.alive):
			used["%d,%d" % [int(e.local_x), int(e.local_y)]] = true
	var spots := [
		Vector2i(0, 0), Vector2i(0, 2), Vector2i(2, 0), Vector2i(2, 2),
		Vector2i(1, 0), Vector2i(1, 2), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 1),
	]
	var out: Array = []
	for s in spots:
		if not used.has("%d,%d" % [s.x, s.y]):
			out.append(s)
	return out


func _purge_check() -> void:
	var allies_up := not _living(allies).is_empty()
	var enemies_up := not _living(enemies).is_empty()
	if not allies_up or not enemies_up:
		over = true
		player_won = not enemies_up and allies_up


func _timeout() -> void:
	timed_out = true
	over = true
	var ah := 0
	var eh := 0
	for u in allies:
		if bool(u.alive):
			ah += int(u.hp)
	for u in enemies:
		if bool(u.alive):
			eh += int(u.hp)
	player_won = ah > eh


func _chain() -> Array:
	var out: Array = []
	out.append_array(allies)
	out.append_array(enemies)
	return out
