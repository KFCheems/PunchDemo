class_name FighterMotor
extends RefCounted

func apply_knockback(controller) -> void:
	if controller.runtime_state.knockback_ticks_remaining <= 0:
		return
	controller.global_position += controller.runtime_state.knockback_step
	controller.runtime_state.knockback_ticks_remaining -= 1

func process_run_attack_movement(controller) -> void:
	if controller.runtime_state.is_jumping:
		return
	var move_name: StringName = controller.get_current_move_name()
	if move_name != &"run_punch" and move_name != &"run_kick":
		return
	controller.global_position.x += float(controller.facing) * controller.run_attack_move_speed_per_tick

func process_jump_motion(controller) -> void:
	if not controller.runtime_state.is_jumping:
		return
	process_airborne_control(controller)
	controller.global_position.x += controller.runtime_state.jump_horizontal_velocity
	controller.runtime_state.jump_visual_offset_y += controller.runtime_state.jump_vertical_velocity
	controller.runtime_state.jump_vertical_velocity += controller.jump_gravity_per_tick
	if controller.runtime_state.jump_visual_offset_y >= 0.0:
		controller.runtime_state.jump_visual_offset_y = 0.0
		controller.runtime_state.jump_vertical_velocity = 0.0
		controller.runtime_state.jump_horizontal_velocity = 0.0
		controller.runtime_state.is_jumping = false
		enter_jump_landing_frame(controller)

func process_airborne_control(controller) -> void:
	if not controller.manual_movement_enabled and not controller.buffered_movement_enabled:
		return
	var horizontal_input: int = controller.input_logic.get_horizontal_input(controller)
	var vertical_input: int = controller.input_logic.get_vertical_input(controller)
	if horizontal_input != 0:
		var target_speed: float = controller.air_move_speed_per_tick
		if sign(controller.runtime_state.jump_horizontal_velocity) == horizontal_input:
			target_speed = max(target_speed, absf(controller.runtime_state.jump_horizontal_velocity))
		controller.runtime_state.jump_horizontal_velocity = float(horizontal_input) * target_speed
		controller.facing = horizontal_input
	if vertical_input != 0:
		controller.global_position.y += float(vertical_input) * controller.air_depth_move_speed_per_tick

func process_manual_movement(controller) -> void:
	if not controller.manual_movement_enabled and not controller.buffered_movement_enabled:
		return
	if controller.runtime_state.is_jumping:
		return
	var current_move_name: StringName = controller.get_current_move_name()
	if current_move_name == &"run_punch" or current_move_name == &"run_kick":
		return
	if controller.get_state_name() != &"idle":
		return
	var horizontal_input: int = controller.input_logic.get_horizontal_input(controller)
	var vertical_input: int = controller.input_logic.get_vertical_input(controller)
	if horizontal_input == 0 and vertical_input == 0:
		controller.runtime_state.run_direction = 0
		if current_move_name == &"walk" or current_move_name == &"run":
			controller.combat_logic.start_named_move(controller, &"idle")
		return
	controller.global_position.y += float(vertical_input) * controller.manual_depth_move_speed_per_tick
	if horizontal_input == 0:
		controller.runtime_state.run_direction = 0
		if current_move_name == &"walk" or current_move_name == &"run":
			controller.combat_logic.start_named_move(controller, &"idle")
		return
	var run_direction: int = controller.runtime_state.run_direction
	if run_direction != 0 and horizontal_input != run_direction:
		run_direction = 0
		controller.runtime_state.run_direction = 0
	var move_speed: float = controller.manual_move_speed_per_tick
	var move_name: StringName = &"walk"
	if run_direction != 0 and horizontal_input == run_direction:
		move_speed = controller.run_move_speed_per_tick
		move_name = &"run"
	controller.global_position.x += float(horizontal_input) * move_speed
	controller.facing = horizontal_input
	if current_move_name != move_name:
		controller.combat_logic.start_named_move(controller, move_name)

func resolve_jump_horizontal_velocity(controller, horizontal_input: int) -> float:
	if horizontal_input == 0:
		return 0.0
	if controller.runtime_state.run_direction != 0 and horizontal_input == controller.runtime_state.run_direction and controller.get_current_move_name() == &"run":
		return float(horizontal_input) * controller.run_jump_move_speed_per_tick
	return float(horizontal_input) * controller.manual_move_speed_per_tick

func enter_jump_landing_frame(controller) -> void:
	if controller.get_current_move_name() != &"jump":
		return
	if controller.move_runner.current_move == null:
		return
	if controller.move_runner.current_move.frames.size() < 3:
		return
	controller.move_runner.current_frame_index = 2
	controller.move_runner.ticks_into_frame = 0
