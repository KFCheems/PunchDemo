class_name MoveRunner
extends RefCounted

var current_move: MoveData
var current_frame_index: int = 0
var ticks_into_frame: int = 0
var move_tick: int = 0
var current_move_instance_id: int = 0
var _next_instance_id: int = 1

func reset() -> void:
	current_move = null
	current_frame_index = 0
	ticks_into_frame = 0
	move_tick = 0
	current_move_instance_id = 0
	_next_instance_id = 1

func start_move(move: MoveData) -> void:
	current_move = move
	current_frame_index = 0
	ticks_into_frame = 0
	move_tick = 0
	current_move_instance_id = _next_instance_id
	_next_instance_id += 1

func get_current_frame() -> FrameData:
	if current_move == null:
		return null
	if current_move.frames.is_empty():
		return null
	return current_move.frames[current_frame_index]

func get_return_move_name() -> StringName:
	if current_move == null:
		return &"idle"
	return current_move.return_to

func get_display_id() -> StringName:
	var frame := get_current_frame()
	if frame == null:
		return &"none"
	return frame.display_id

func advance() -> bool:
	var frame := get_current_frame()
	if frame == null:
		return true

	ticks_into_frame += 1
	move_tick += 1
	if ticks_into_frame < frame.get_safe_duration():
		return false

	ticks_into_frame = 0
	current_frame_index += 1
	if current_move != null and current_frame_index < current_move.frames.size():
		return false

	if current_move != null and current_move.loop and not current_move.frames.is_empty():
		current_frame_index = 0
		return false

	if current_move != null and not current_move.frames.is_empty():
		current_frame_index = current_move.frames.size() - 1
	return true

func get_world_hitboxes(origin: Vector2, facing: int) -> Array:
	return _build_hitbox_array(origin, facing)

func get_world_hurtboxes(origin: Vector2, facing: int) -> Array:
	return _build_hurtbox_array(origin, facing)

func get_local_hitboxes(facing: int) -> Array:
	return _build_hitbox_array(Vector2.ZERO, facing)

func get_local_hurtboxes(facing: int) -> Array:
	return _build_hurtbox_array(Vector2.ZERO, facing)

func _build_hitbox_array(origin: Vector2, facing: int) -> Array:
	var results: Array = []
	var frame := get_current_frame()
	if frame == null:
		return results
	for hitbox in frame.hitboxes:
		if hitbox == null or hitbox.effect == null:
			continue
		results.append({
			"rect": _transform_rect(hitbox.local_rect, origin, facing),
			"effect": hitbox.effect,
		})
	return results

func _build_hurtbox_array(origin: Vector2, facing: int) -> Array:
	var results: Array = []
	var frame := get_current_frame()
	if frame == null:
		return results
	for hurtbox in frame.hurtboxes:
		if hurtbox == null:
			continue
		results.append(_transform_rect(hurtbox.local_rect, origin, facing))
	return results

func _transform_rect(local_rect: Rect2, origin: Vector2, facing: int) -> Rect2:
	if facing >= 0:
		return Rect2(origin + local_rect.position, local_rect.size)
	var mirrored_position := Vector2(-local_rect.position.x - local_rect.size.x, local_rect.position.y)
	return Rect2(origin + mirrored_position, local_rect.size)
