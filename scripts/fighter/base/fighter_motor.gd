class_name FighterMotor
extends RefCounted

func apply_knockback(controller) -> void:
	if controller.knockback_ticks_remaining <= 0:
		return
	controller.global_position += controller.knockback_step
	controller.knockback_ticks_remaining -= 1

func process_run_attack_movement(controller) -> void:
	if controller._is_jumping:
		return
	var move_name: StringName = controller.get_current_move_name()
	if move_name != &"run_punch" and move_name != &"run_kick":
		return
	controller.global_position.x += float(controller.facing) * controller.run_attack_move_speed_per_tick

func process_jump_motion(controller) -> void:
	if not controller._is_jumping:
		return
	process_airborne_control(controller)
	controller.global_position.x += controller._jump_horizontal_velocity
	controller._jump_visual_offset_y += controller._jump_vertical_velocity
	controller._jump_vertical_velocity += controller.jump_gravity_per_tick
	if controller._jump_visual_offset_y >= 0.0:
		controller._jump_visual_offset_y = 0.0
		controller._jump_vertical_velocity = 0.0
		controller._jump_horizontal_velocity = 0.0
		controller._is_jumping = false
		controller._is_jump_landing = true
		controller._enter_jump_landing_frame()

func process_airborne_control(controller) -> void:
	if not controller.manual_movement_enabled and not controller.buffered_movement_enabled:
		return
	var horizontal_input: int = controller._get_horizontal_input()
	var vertical_input: int = controller._get_vertical_input()
	if horizontal_input != 0:
		var target_speed: float = controller.air_move_speed_per_tick
		if sign(controller._jump_horizontal_velocity) == horizontal_input:
			target_speed = max(target_speed, absf(controller._jump_horizontal_velocity))
		controller._jump_horizontal_velocity = float(horizontal_input) * target_speed
		controller.facing = horizontal_input
	if vertical_input != 0:
		controller.global_position.y += float(vertical_input) * controller.air_depth_move_speed_per_tick

func process_manual_movement(controller) -> void:
	if not controller.manual_movement_enabled and not controller.buffered_movement_enabled:
		return
	if controller._is_jumping:
		return
	if controller.get_current_move_name() == &"run_punch" or controller.get_current_move_name() == &"run_kick":
		return
	if controller.get_state_name() != &"idle":
		return
	var horizontal_input: int = controller._get_horizontal_input()
	var vertical_input: int = controller._get_vertical_input()
	if horizontal_input == 0 and vertical_input == 0:
		controller._run_direction = 0
		if controller.get_current_move_name() == &"walk" or controller.get_current_move_name() == &"run":
			controller._start_named_move(&"idle")
		return
	controller.global_position.y += float(vertical_input) * controller.manual_depth_move_speed_per_tick
	if horizontal_input == 0:
		controller._run_direction = 0
		if controller.get_current_move_name() == &"walk" or controller.get_current_move_name() == &"run":
			controller._start_named_move(&"idle")
		return
	if controller._run_direction != 0 and horizontal_input != controller._run_direction:
		controller._run_direction = 0
	var move_speed: float = controller.manual_move_speed_per_tick
	var move_name: StringName = &"walk"
	if controller._run_direction != 0 and horizontal_input == controller._run_direction:
		move_speed = controller.run_move_speed_per_tick
		move_name = &"run"
	controller.global_position.x += float(horizontal_input) * move_speed
	controller.facing = horizontal_input
	if controller.get_current_move_name() != move_name:
		controller._start_named_move(move_name)
