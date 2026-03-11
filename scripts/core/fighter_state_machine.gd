class_name FighterStateMachine
extends RefCounted

var current_state: StringName = &"idle"

func reset() -> void:
	current_state = &"idle"

func sync_from_move(move: MoveData) -> void:
	if move == null:
		current_state = &"idle"
		return
	current_state = _state_name_from_tag(move.state_tag)

func can_start_move(current_move: MoveData, current_frame: FrameData, ticks_into_frame: int, requested_move: MoveData) -> bool:
	if requested_move == null:
		return false
	if current_move == null:
		return true
	if requested_move.state_tag == MoveData.StateTag.HURT:
		return true
	if current_move.state_tag == MoveData.StateTag.AIR:
		return false
	if current_move.state_tag == MoveData.StateTag.IDLE:
		return true
	if current_frame == null:
		return true
	if requested_move.state_tag == MoveData.StateTag.ATTACK:
		return current_frame.is_cancel_open(ticks_into_frame) or current_frame.is_interrupt_open(ticks_into_frame)
	return current_frame.is_interrupt_open(ticks_into_frame)

func _state_name_from_tag(tag: int) -> StringName:
	match tag:
		MoveData.StateTag.ATTACK:
			return &"attack"
		MoveData.StateTag.HURT:
			return &"hurt"
		MoveData.StateTag.AIR:
			return &"air"
		_:
			return &"idle"
