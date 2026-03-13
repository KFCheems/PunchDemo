class_name FighterStats
extends RefCounted

func reset(controller) -> void:
	controller.health = controller.max_health

func apply_hit_state_reset(controller) -> void:
	controller.runtime_state.clear_jump_state()
	controller.runtime_state.clear_run_state()
