class_name FighterCombat
extends RefCounted

func process_action_requests(controller) -> void:
	for action in controller.input_buffer.get_current_actions():
		var requested_move = resolve_requested_move(controller, action)
		if requested_move == null:
			continue
		if not controller.state_machine.can_start_move(controller.move_runner.current_move, controller.move_runner.get_current_frame(), controller.move_runner.ticks_into_frame, requested_move):
			continue
		if controller.input_buffer.consume_action(action):
			controller._start_move(requested_move)
			return

func resolve_requested_move(controller, action: StringName):
	if action == &"jump":
		return controller.move_library.get(&"jump", null)
	if action == &"punch" and controller.grab_logic.can_front_grapple_punch(controller):
		return controller.move_library.get(&"front_grapple_punch", null)
	if controller.grab_logic.can_release_grapple_throw(controller) and (action == &"punch" or action == &"kick"):
		return controller.move_library.get(&"grapple_throw", null)
	if controller.grab_logic.can_launch_breath_target(controller) and (action == &"punch" or action == &"kick"):
		return controller.move_library.get(&"launch", controller.move_library.get(action, null))
	if action == &"grapple" and controller.grab_logic.can_grapple_breath_target(controller):
		controller.grab_target = controller.interaction_target
		controller._grab_is_front = controller.grab_logic.is_front_grab_target(controller, controller.grab_target)
		return controller.move_library.get(&"grapple", null)
	if action == &"punch" and controller._is_run_forward_active():
		return controller.move_library.get(&"run_punch", controller.move_library.get(action, null))
	if action == &"kick" and controller._is_run_forward_active():
		return controller.move_library.get(&"run_kick", controller.move_library.get(action, null))
	return controller.move_library.get(action, null)

func receive_hit(controller, effect, attacker) -> void:
	if controller.move_runner.current_move != null and controller.move_runner.current_move.invulnerable:
		return
	controller.health = max(controller.health - effect.damage, 0)
	controller.interaction_target = attacker
	var direction: int = int(sign(controller.global_position.x - attacker.global_position.x))
	if direction == 0:
		direction = attacker.facing
	controller.knockback_step = Vector2(effect.knockback_per_tick.x * direction, effect.knockback_per_tick.y)
	controller.knockback_ticks_remaining = effect.knockback_ticks
	controller.stats_logic.apply_hit_state_reset(controller)
	var hurt_move = _build_hurt_move(controller, effect.hitstun_ticks)
	hurt_move.return_to = effect.get_return_move_name(controller.post_hurt_move_name)
	controller._start_move(hurt_move)
	controller._refresh_visual()

func _build_hurt_move(controller, hitstun_ticks: int):
	var data_manager = controller.get_node_or_null("/root/DataManager")
	if data_manager != null and data_manager.has_method("build_hurt_move"):
		var fighter_id: StringName = &"ali"
		if controller.fighter_definition != null and controller.fighter_definition.fighter_id != &"":
			fighter_id = controller.fighter_definition.fighter_id
		var hurt_move = data_manager.build_hurt_move(fighter_id, hitstun_ticks)
		if hurt_move != null:
			return hurt_move
	return controller.DemoMoveLibraryScript.build_hurt_move(hitstun_ticks)
