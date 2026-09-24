extends TextureRect

# Sproutling / Sparkpup / Cottonwisp only.
# Idle loops on one shared clock. A combat squash or lunge holds the
# current frame. A merge one-shot returns to idle, unless the triple
# evolved into another species — that settles on the capsule.
# The 4-frame sheet is still the punchy starters-v1 export. Playback
# slows it until Assets re-exports the ≤4% stretch. No scale tween
# rides on top of those frames.

const IDLE_FPS := 8.0
const MERGE_FPS := 9.0
const MERGE_SETTLE := 0.065
# Steps of IDLE_FPS. Order is rest, stretch, squash, settle.
# Extremes (stretch, squash) hold two ticks. Neutrals hold two as well,
# so the loop eases instead of snapping. Eight FPS with those holds
# shows the sheet at 4 FPS.
const IDLE_HOLD_STEPS: Array = [2.0, 2.0, 2.0, 2.0]

static var _clock: float = 0.0
static var _clock_frame: int = -1

var sheet_px: int = 64
var mode: String = "idle"
var frame_i: int = 0
var idle_count: int = 0
var merge_count: int = 0

var _idle: Array = []
var _merge: Array = []
var _settle: Texture2D = null
var _accum: float = 0.0


func setup(px: int, static_tex: Texture2D, idle_frames: Array, merge_frames: Array) -> void:
	sheet_px = px
	_idle = idle_frames
	_merge = merge_frames
	idle_count = idle_frames.size()
	merge_count = merge_frames.size()
	mode = "idle"
	frame_i = 0
	_accum = 0.0
	_settle = null
	scale = Vector2.ONE
	texture = static_tex


func has_merge() -> bool:
	return _merge.size() >= 5


func arm_settle(tex: Texture2D) -> void:
	_settle = tex


func play_merge() -> void:
	scale = Vector2.ONE
	if _merge.is_empty():
		_finish_merge()
		return
	mode = "merge"
	frame_i = 0
	_accum = 0.0
	texture = _merge[0]


func _process(delta: float) -> void:
	_advance_clock(delta)
	if mode == "still":
		return
	if mode == "idle" and _mid_tween():
		return
	if mode == "settle":
		_accum += delta
		if _accum < MERGE_SETTLE:
			return
		mode = "idle"
		_show_shared_idle()
		return
	var frames: Array = _merge if mode == "merge" else _idle
	if frames.is_empty():
		return
	if mode == "idle":
		_show_shared_idle()
		return
	if MERGE_FPS <= 0.0:
		return
	_accum += delta
	var step := 1.0 / MERGE_FPS
	while _accum >= step:
		_accum -= step
		frame_i += 1
		if frame_i >= frames.size():
			_finish_merge()
			return
		texture = frames[frame_i]


func _advance_clock(delta: float) -> void:
	var tick := Engine.get_process_frames()
	if tick == _clock_frame:
		return
	_clock_frame = tick
	_clock += delta


func _show_shared_idle() -> void:
	if _idle.is_empty():
		return
	var count := _idle.size()
	var total := 0.0
	for i in count:
		total += _idle_hold(i)
	if total <= 0.0:
		return
	var t := fposmod(_clock, total)
	var walked := 0.0
	var index := 0
	for i in count:
		walked += _idle_hold(i)
		if t < walked:
			index = i
			break
		index = i
	frame_i = index
	texture = _idle[index]
	scale = Vector2.ONE


func _idle_hold(index: int) -> float:
	var step := 1.0 / IDLE_FPS
	if index < 0 or index >= IDLE_HOLD_STEPS.size():
		return step
	return step * float(IDLE_HOLD_STEPS[index])


func _finish_merge() -> void:
	_accum = 0.0
	frame_i = 0
	scale = Vector2.ONE
	if _settle != null:
		texture = _settle
		mode = "still"
		return
	# 65ms on the rest frame, then the shared idle clock. Interruptible.
	mode = "settle"
	if not _idle.is_empty():
		texture = _idle[0]


func _mid_tween() -> bool:
	var n: Node = self
	while n != null:
		if n.has_meta("juice_tw"):
			var tw = n.get_meta("juice_tw")
			if tw is Tween and (tw as Tween).is_valid() and (tw as Tween).is_running():
				return true
		n = n.get_parent()
	return false
