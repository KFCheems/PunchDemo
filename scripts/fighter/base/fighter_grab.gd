class_name FighterGrab
extends RefCounted

func can_launch_breath_target(controller) -> bool:
	if controller.interaction_target == null:
		return false
	if controller.interaction_target.get_current_move_name() != &"breath":
		return false
	return true

func can_grapple_breath_target(controller) -> bool:
	if not can_launch_breath_target(controller):
		return false
	return controller.global_position.distance_to(controller.interaction_target.global_position) <= controller.DemoTuningScript.POST_HURT_GRAB_TRIGGER_DISTANCE

func can_front_grapple_punch(controller) -> bool:
	if not can_release_grapple_throw(controller):
		return false
	return controller._grab_is_front

func can_auto_grapple_breath_target(controller) -> bool:
	if not can_grapple_breath_target(controller):
		return false
	if controller.grab_target != null:
		return false
	var move_name: StringName = controller.get_current_move_name()
	return move_name == &"idle" or move_name == &"walk" or move_name == &"run"

func can_release_grapple_throw(controller) -> bool:
	return controller.grab_target != null and controller.get_current_move_name() == &"grapple"

func is_front_grab_target(controller, target) -> bool:
	if target == null:
		return false
	var to_target_x: float = target.global_position.x - controller.global_position.x
	if is_zero_approx(to_target_x):
		return controller.facing == target.facing
	var target_side: int = 1 if to_target_x > 0.0 else -1
	return target_side == controller.facing

func has_auto_grapple_movement_intent(controller, combat_tick: int) -> bool:
	return controller.input_buffer.has_scheduled_action(combat_tick, &"move_left") or controller.input_buffer.has_scheduled_action(combat_tick, &"move_right")

func process_auto_grapple(controller, combat_tick: int) -> void:
	if not can_auto_grapple_breath_target(controller):
		return
	if not has_auto_grapple_movement_intent(controller, combat_tick):
		return
	controller.input_buffer.schedule_action(combat_tick, &"grapple")

func process_grapple_hold(controller) -> void:
	var target = controller.grab_target
	if target == null:
		return
	var move_name: StringName = controller.get_current_move_name()
	if move_name == &"grapple":
		target.apply_grabbed_pose(controller)
		return
	var frame_index: int = controller.get_frame_index()
	if move_name == &"grapple_throw" and frame_index < 2:
		target.apply_grabbed_pose(controller)
		return
	if move_name == &"front_grapple_punch":
		if frame_index < 2:
			target.apply_grabbed_pose(controller)
		elif frame_index == 2:
			target.global_position = controller.global_position + Vector2(float(controller.facing) * controller.DemoTuningScript.GRAPPLE_HOLD_OFFSET_X, 0.0)
			target.facing = controller.facing
			target._refresh_visual()
		else:
			release_grab_target(controller, false)
		return
	release_grab_target(controller, move_name != &"grapple_throw")

func release_grab_target(controller, return_to_idle: bool) -> void:
	if controller.grab_target == null:
		return
	var released_target = controller.grab_target
	controller.grab_target = null
	controller._grab_is_front = false
	released_target.release_from_grab(return_to_idle)
	if return_to_idle and controller.get_current_move_name() != &"idle":
		controller.combat_logic.start_named_move(controller,&"idle")

func apply_grabbed_pose(controller, holder) -> void:
	if holder == null:
		return
	if controller.runtime_state.grabbed_by != holder:
		controller.runtime_state.grabbed_by = holder
		controller.runtime_state.clear_knockback()
		controller.runtime_state.clear_jump_state()
	controller.global_position = holder.global_position + Vector2(float(holder.facing) * controller.DemoTuningScript.GRAPPLE_HOLD_OFFSET_X, 0.0)
	controller._refresh_visual()

func release_from_grab(controller, return_to_idle: bool = true) -> void:
	controller.runtime_state.grabbed_by = null
	controller.runtime_state.clear_knockback()
	controller.runtime_state.clear_jump_state()
	if return_to_idle:
		if controller.get_current_move_name() == &"breath":
			controller.combat_logic.start_named_move(controller,&"breath_invulnerable")
		elif controller.get_current_move_name() != &"idle":
			controller.combat_logic.start_named_move(controller,&"idle")
	controller._refresh_visual()
