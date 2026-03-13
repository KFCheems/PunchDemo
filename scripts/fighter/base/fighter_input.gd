class_name FighterInput
extends RefCounted

func process_manual_attack(controller, combat_tick: int) -> void:
	if not controller.manual_movement_enabled:
		controller.runtime_state.manual_single_attack_pressed_last_tick = false
		controller.runtime_state.manual_multi_attack_pressed_last_tick = false
		return
	var single_attack_pressed: bool = Input.is_physical_key_pressed(KEY_J)
	var multi_attack_pressed: bool = Input.is_physical_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_ENTER)
	if single_attack_pressed and not controller.runtime_state.manual_single_attack_pressed_last_tick:
		controller.input_buffer.schedule_action(combat_tick, &"punch")
	elif multi_attack_pressed and not controller.runtime_state.manual_multi_attack_pressed_last_tick:
		controller.input_buffer.schedule_action(combat_tick, &"kick")
	controller.runtime_state.manual_single_attack_pressed_last_tick = single_attack_pressed
	controller.runtime_state.manual_multi_attack_pressed_last_tick = multi_attack_pressed

func process_manual_jump(controller, combat_tick: int) -> void:
	if not controller.manual_movement_enabled:
		controller.runtime_state.manual_jump_pressed_last_tick = false
		return
	var jump_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
	if jump_pressed and not controller.runtime_state.manual_jump_pressed_last_tick and not controller.runtime_state.is_jumping and controller.get_state_name() == &"idle":
		controller.input_buffer.schedule_action(combat_tick, &"jump")
	controller.runtime_state.manual_jump_pressed_last_tick = jump_pressed

func queue_manual_movement_actions(controller, combat_tick: int) -> void:
	if not controller.manual_movement_enabled:
		if not controller.buffered_movement_enabled:
			_clear_buffered_movement_state(controller)
		return
	var left_pressed: bool = Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right_pressed: bool = Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var up_pressed: bool = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var down_pressed: bool = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	queue_buffered_movement_actions(controller, combat_tick, left_pressed, right_pressed, up_pressed, down_pressed)

func queue_buffered_movement_actions(controller, combat_tick: int, left_pressed: bool, right_pressed: bool, up_pressed: bool, down_pressed: bool) -> void:
	if not controller.buffered_movement_enabled:
		_clear_buffered_movement_state(controller)
		return
	if left_pressed:
		controller.input_buffer.schedule_action(combat_tick, &"move_left")
	if right_pressed:
		controller.input_buffer.schedule_action(combat_tick, &"move_right")
	if up_pressed:
		controller.input_buffer.schedule_action(combat_tick, &"move_up")
	if down_pressed:
		controller.input_buffer.schedule_action(combat_tick, &"move_down")
	_update_run_direction_from_pressed_state(controller, combat_tick, left_pressed, right_pressed)

func sync_buffered_movement_state(controller, combat_tick: int) -> void:
	if controller.manual_movement_enabled or not controller.buffered_movement_enabled:
		return
	var left_pressed: bool = controller.input_buffer.has_action(&"move_left")
	var right_pressed: bool = controller.input_buffer.has_action(&"move_right")
	_update_run_direction_from_pressed_state(controller, combat_tick, left_pressed, right_pressed)

func _clear_buffered_movement_state(controller) -> void:
	controller.runtime_state.buffered_left_pressed_last_tick = false
	controller.runtime_state.buffered_right_pressed_last_tick = false
	controller.runtime_state.run_direction = 0

func _update_run_direction_from_pressed_state(controller, combat_tick: int, left_pressed: bool, right_pressed: bool) -> void:
	if left_pressed and not controller.runtime_state.buffered_left_pressed_last_tick:
		if combat_tick - controller.runtime_state.last_left_press_tick <= controller.double_tap_window_ticks:
			controller.runtime_state.run_direction = -1
		controller.runtime_state.last_left_press_tick = combat_tick
	if right_pressed and not controller.runtime_state.buffered_right_pressed_last_tick:
		if combat_tick - controller.runtime_state.last_right_press_tick <= controller.double_tap_window_ticks:
			controller.runtime_state.run_direction = 1
		controller.runtime_state.last_right_press_tick = combat_tick
	controller.runtime_state.buffered_left_pressed_last_tick = left_pressed
	controller.runtime_state.buffered_right_pressed_last_tick = right_pressed

func is_run_forward_active(controller) -> bool:
	if not controller.manual_movement_enabled and not controller.buffered_movement_enabled:
		return false
	if controller.runtime_state.is_jumping:
		return false
	if controller.get_current_move_name() != &"run":
		return false
	if controller.facing >= 0:
		return controller.input_buffer.has_action(&"move_right")
	return controller.input_buffer.has_action(&"move_left")

func get_horizontal_input(controller) -> int:
	var horizontal_input: int = 0
	if controller.input_buffer.has_action(&"move_left"):
		horizontal_input -= 1
	if controller.input_buffer.has_action(&"move_right"):
		horizontal_input += 1
	return horizontal_input

func get_vertical_input(controller) -> int:
	var vertical_input: int = 0
	if controller.input_buffer.has_action(&"move_up"):
		vertical_input -= 1
	if controller.input_buffer.has_action(&"move_down"):
		vertical_input += 1
	return vertical_input
