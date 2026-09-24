extends TextureRect

# Sproutling / Sparkpup / Cottonwisp only.
# Idle loops while the token is sitting still. A combat squash or lunge
# holds the current frame. A merge one-shot returns to idle, unless the
# triple evolved into another species — that settles on the capsule.

const IDLE_FPS := 7.0
const MERGE_FPS := 11.0

var sheet_px: int = 64
var mode: String = "idle"
var frame_i: int = 0
var idle_count: int = 0
var merge_count: int = 0

var _idle: Array = []
var _merge: Array = []
var _settle: Texture2D = null
var _accum: float = 0.0
var _primed: bool = false


func setup(px: int, static_tex: Texture2D, idle_frames: Array, merge_frames: Array) -> void:
	sheet_px = px
	_idle = idle_frames
	_merge = merge_frames
	idle_count = idle_frames.size()
	merge_count = merge_frames.size()
	mode = "idle"
	frame_i = 0
	_accum = 0.0
	_primed = false
	_settle = null
	texture = static_tex


func has_merge() -> bool:
	return _merge.size() >= 5


func arm_settle(tex: Texture2D) -> void:
	_settle = tex


func play_merge() -> void:
	if _merge.is_empty():
		_finish_merge()
		return
	mode = "merge"
	frame_i = 0
	_accum = 0.0
	texture = _merge[0]


func _process(delta: float) -> void:
	if mode == "still":
		return
	if mode == "idle" and _mid_tween():
		return
	var frames: Array = _merge if mode == "merge" else _idle
	if frames.is_empty():
		return
	var fps := MERGE_FPS if mode == "merge" else IDLE_FPS
	if fps <= 0.0:
		return
	_accum += delta
	var step := 1.0 / fps
	while _accum >= step:
		_accum -= step
		if mode == "idle" and not _primed:
			_primed = true
			frame_i = 0
			texture = frames[0]
			continue
		if mode == "merge":
			frame_i += 1
			if frame_i >= frames.size():
				_finish_merge()
				return
			texture = frames[frame_i]
		else:
			frame_i = (frame_i + 1) % frames.size()
			texture = frames[frame_i]


func _finish_merge() -> void:
	_accum = 0.0
	frame_i = 0
	if _settle != null:
		texture = _settle
		mode = "still"
		return
	mode = "idle"
	_primed = true
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
