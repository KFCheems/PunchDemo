class_name FighterStats
extends RefCounted

func reset(controller) -> void:
	controller.health = controller.max_health

func apply_hit_state_reset(controller) -> void:
	controller._is_jumping = false
	controller._is_jump_landing = false
	controller._jump_visual_offset_y = 0.0
	controller._jump_vertical_velocity = 0.0
	controller._jump_horizontal_velocity = 0.0
	controller._run_direction = 0
