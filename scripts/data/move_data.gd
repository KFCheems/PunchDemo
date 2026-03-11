class_name MoveData
extends Resource

enum StateTag {
	IDLE,
	ATTACK,
	HURT,
	AIR,
}

@export var move_name: StringName = &"idle"
@export_enum("idle", "attack", "hurt", "air") var state_tag: int = StateTag.IDLE
@export var loop: bool = false
@export var return_to: StringName = &"idle"
@export var invulnerable: bool = false
@export var frames: Array = []

func get_total_duration_ticks() -> int:
	var total := 0
	for frame in frames:
		total += frame.get_safe_duration()
	return total

func get_frame_count() -> int:
	return frames.size()
