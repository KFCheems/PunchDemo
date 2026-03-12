class_name FighterController
extends Node2D

const InputBufferScript = preload("res://scripts/core/input_buffer.gd")
const FighterStateMachineScript = preload("res://scripts/core/fighter_state_machine.gd")
const MoveRunnerScript = preload("res://scripts/core/move_runner.gd")
const DemoMoveLibraryScript = preload("res://scripts/data/demo_move_library.gd")
const DemoTuningScript = preload("res://scripts/data/demo_tuning.gd")

var fighter_name: String = "Fighter"
var facing: int = 1
var default_facing: int = 1
var max_health: int = 100
var health: int = 100
var move_library: Dictionary = {}
var post_hurt_move_name: StringName = &"idle"
var interaction_target: FighterController = null
var grab_target: FighterController = null
var _grab_is_front: bool = false
var _grabbed_by: FighterController = null

var input_buffer := InputBufferScript.new()
var state_machine := FighterStateMachineScript.new()
var move_runner := MoveRunnerScript.new()

var knockback_step: Vector2 = Vector2.ZERO
var knockback_ticks_remaining: int = 0
var manual_movement_enabled: bool = false
var buffered_movement_enabled: bool = false
var manual_move_speed_per_tick: float = DemoTuningScript.MOVEMENT_GROUND_HORIZONTAL_PER_TICK
var manual_depth_move_speed_per_tick: float = DemoTuningScript.MOVEMENT_GROUND_VERTICAL_PER_TICK
var air_move_speed_per_tick: float = DemoTuningScript.MOVEMENT_AIR_HORIZONTAL_PER_TICK
var air_depth_move_speed_per_tick: float = DemoTuningScript.MOVEMENT_AIR_VERTICAL_PER_TICK
var run_move_speed_per_tick: float = DemoTuningScript.MOVEMENT_RUN_HORIZONTAL_PER_TICK
var run_jump_move_speed_per_tick: float = DemoTuningScript.MOVEMENT_RUN_JUMP_HORIZONTAL_PER_TICK
var run_attack_move_speed_per_tick: float = DemoTuningScript.MOVEMENT_RUN_ATTACK_HORIZONTAL_PER_TICK
var double_tap_window_ticks: int = DemoTuningScript.MOVEMENT_DOUBLE_TAP_WINDOW_TICKS
var jump_velocity_per_tick: float = DemoTuningScript.JUMP_TAKEOFF_VELOCITY_PER_TICK
var jump_gravity_per_tick: float = DemoTuningScript.JUMP_GRAVITY_PER_TICK
var _manual_single_attack_pressed_last_tick: bool = false
var _manual_multi_attack_pressed_last_tick: bool = false
var _manual_jump_pressed_last_tick: bool = false
var _buffered_left_pressed_last_tick: bool = false
var _buffered_right_pressed_last_tick: bool = false
var _last_left_press_tick: int = -9999
var _last_right_press_tick: int = -9999
var _run_direction: int = 0
var _jump_visual_offset_y: float = 0.0
var _jump_vertical_velocity: float = 0.0
var _jump_horizontal_velocity: float = 0.0
var _is_jumping: bool = false
var _is_jump_landing: bool = false

@onready var visual = $Visual

func _ready() -> void:
	if visual != null:
		visual.bind_controller(self)
	if move_runner.current_move == null:
		move_library = DemoMoveLibraryScript.create_library()
		_start_named_move(&"idle")

func setup(new_name: String, facing_dir: int, library: Dictionary) -> void:
	fighter_name = new_name
	facing = 1 if facing_dir >= 0 else -1
	default_facing = facing
	move_library = library
	reset_for_replay(global_position)

func reset_for_replay(start_position: Vector2) -> void:
	global_position = start_position
	facing = default_facing
	health = max_health
	grab_target = null
	_grab_is_front = false
	_grabbed_by = null
	knockback_step = Vector2.ZERO
	knockback_ticks_remaining = 0
	_jump_visual_offset_y = 0.0
	_jump_vertical_velocity = 0.0
	_jump_horizontal_velocity = 0.0
	_is_jumping = false
	_is_jump_landing = false
	manual_movement_enabled = false
	buffered_movement_enabled = false
	_manual_single_attack_pressed_last_tick = false
	_manual_multi_attack_pressed_last_tick = false
	_manual_jump_pressed_last_tick = false
	_buffered_left_pressed_last_tick = false
	_buffered_right_pressed_last_tick = false
	_last_left_press_tick = -9999
	_last_right_press_tick = -9999
	_run_direction = 0
	input_buffer.clear()
	state_machine.reset()
	move_runner.reset()
	_start_named_move(&"idle")
	_refresh_visual()

func schedule_scripted_actions(entries: Array) -> void:
	input_buffer.schedule_actions(entries)

func start_combat_tick(combat_tick: int) -> void:
	if _grabbed_by != null:
		input_buffer.begin_tick(combat_tick)
		_process_grapple_hold()
		_refresh_visual()
		return
	_process_manual_attack(combat_tick)
	_process_manual_jump(combat_tick)
	_queue_manual_movement_actions(combat_tick)
	_process_auto_grapple(combat_tick)
	input_buffer.begin_tick(combat_tick)
	_sync_buffered_movement_state(combat_tick)
	_apply_knockback()
	_process_jump_motion()
	_process_grapple_hold()
	_process_action_requests()
	_process_run_attack_movement()
	_process_manual_movement()
	_refresh_visual()

func end_combat_tick() -> void:
	if _grabbed_by != null:
		_refresh_visual()
		return
	if move_runner.advance():
		_start_named_move(move_runner.get_return_move_name())
	_refresh_visual()

func get_active_hitboxes() -> Array:
	return move_runner.get_world_hitboxes(get_combat_origin(), facing)

func get_active_hurtboxes() -> Array:
	if move_runner.current_move != null and move_runner.current_move.invulnerable:
		return []
	return move_runner.get_world_hurtboxes(get_combat_origin(), facing)

func get_debug_local_hitboxes() -> Array:
	return move_runner.get_local_hitboxes(facing)

func get_debug_local_hurtboxes() -> Array:
	return move_runner.get_local_hurtboxes(facing)

func get_state_name() -> StringName:
	return state_machine.current_state

func get_current_move_name() -> StringName:
	if move_runner.current_move == null:
		return &"none"
	return move_runner.current_move.move_name

func get_display_id() -> StringName:
	return move_runner.get_display_id()

func get_move_instance_id() -> int:
	return move_runner.current_move_instance_id

func get_frame_index() -> int:
	return move_runner.current_frame_index

func get_combat_origin() -> Vector2:
	return global_position + get_visual_offset()

func get_visual_offset() -> Vector2:
	return Vector2(0.0, _jump_visual_offset_y)

func receive_hit(effect, attacker: FighterController) -> void:
	if move_runner.current_move != null and move_runner.current_move.invulnerable:
		return
	health = max(health - effect.damage, 0)
	interaction_target = attacker
	var direction: int = int(sign(global_position.x - attacker.global_position.x))
	if direction == 0:
		direction = attacker.facing
	knockback_step = Vector2(effect.knockback_per_tick.x * direction, effect.knockback_per_tick.y)
	knockback_ticks_remaining = effect.knockback_ticks
	_is_jumping = false
	_is_jump_landing = false
	_jump_visual_offset_y = 0.0
	_jump_vertical_velocity = 0.0
	_jump_horizontal_velocity = 0.0
	_run_direction = 0
	var hurt_move = DemoMoveLibraryScript.build_hurt_move(effect.hitstun_ticks)
	hurt_move.return_to = effect.get_return_move_name(post_hurt_move_name)
	_start_move(hurt_move)
	_refresh_visual()

func build_snapshot_line(prefix: String) -> String:
	var combat_origin := get_combat_origin()
	return "%s[state=%s move=%s frame=%d display=%s hp=%d pos=(%.1f,%.1f)]" % [
		prefix,
		String(get_state_name()),
		String(get_current_move_name()),
		get_frame_index(),
		String(get_display_id()),
		health,
		combat_origin.x,
		combat_origin.y,
	]

func _apply_knockback() -> void:
	if knockback_ticks_remaining <= 0:
		return
	global_position += knockback_step
	knockback_ticks_remaining -= 1

func _process_manual_attack(combat_tick: int) -> void:
	if not manual_movement_enabled:
		_manual_single_attack_pressed_last_tick = false
		_manual_multi_attack_pressed_last_tick = false
		return
	var single_attack_pressed: bool = Input.is_physical_key_pressed(KEY_J)
	var multi_attack_pressed: bool = Input.is_physical_key_pressed(KEY_K) or Input.is_physical_key_pressed(KEY_ENTER)
	if single_attack_pressed and not _manual_single_attack_pressed_last_tick:
		input_buffer.schedule_action(combat_tick, &"punch")
	elif multi_attack_pressed and not _manual_multi_attack_pressed_last_tick:
		input_buffer.schedule_action(combat_tick, &"kick")
	_manual_single_attack_pressed_last_tick = single_attack_pressed
	_manual_multi_attack_pressed_last_tick = multi_attack_pressed

func _process_manual_jump(combat_tick: int) -> void:
	if not manual_movement_enabled:
		_manual_jump_pressed_last_tick = false
		return
	var jump_pressed: bool = Input.is_physical_key_pressed(KEY_SPACE)
	if jump_pressed and not _manual_jump_pressed_last_tick and not _is_jumping and get_state_name() == &"idle":
		input_buffer.schedule_action(combat_tick, &"jump")
	_manual_jump_pressed_last_tick = jump_pressed

func _queue_manual_movement_actions(combat_tick: int) -> void:
	if not manual_movement_enabled:
		if not buffered_movement_enabled:
			_buffered_left_pressed_last_tick = false
			_buffered_right_pressed_last_tick = false
			_run_direction = 0
		return
	var left_pressed: bool = Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right_pressed: bool = Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var up_pressed: bool = Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var down_pressed: bool = Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	_queue_buffered_movement_actions(combat_tick, left_pressed, right_pressed, up_pressed, down_pressed)

func _queue_buffered_movement_actions(combat_tick: int, left_pressed: bool, right_pressed: bool, up_pressed: bool, down_pressed: bool) -> void:
	if not buffered_movement_enabled:
		_buffered_left_pressed_last_tick = false
		_buffered_right_pressed_last_tick = false
		_run_direction = 0
		return
	if left_pressed:
		input_buffer.schedule_action(combat_tick, &"move_left")
	if right_pressed:
		input_buffer.schedule_action(combat_tick, &"move_right")
	if up_pressed:
		input_buffer.schedule_action(combat_tick, &"move_up")
	if down_pressed:
		input_buffer.schedule_action(combat_tick, &"move_down")
	if left_pressed and not _buffered_left_pressed_last_tick:
		if combat_tick - _last_left_press_tick <= double_tap_window_ticks:
			_run_direction = -1
		_last_left_press_tick = combat_tick
	if right_pressed and not _buffered_right_pressed_last_tick:
		if combat_tick - _last_right_press_tick <= double_tap_window_ticks:
			_run_direction = 1
		_last_right_press_tick = combat_tick
	_buffered_left_pressed_last_tick = left_pressed
	_buffered_right_pressed_last_tick = right_pressed

func _sync_buffered_movement_state(combat_tick: int) -> void:
	if manual_movement_enabled or not buffered_movement_enabled:
		return
	var left_pressed := input_buffer.has_action(&"move_left")
	var right_pressed := input_buffer.has_action(&"move_right")
	if left_pressed and not _buffered_left_pressed_last_tick:
		if combat_tick - _last_left_press_tick <= double_tap_window_ticks:
			_run_direction = -1
		_last_left_press_tick = combat_tick
	if right_pressed and not _buffered_right_pressed_last_tick:
		if combat_tick - _last_right_press_tick <= double_tap_window_ticks:
			_run_direction = 1
		_last_right_press_tick = combat_tick
	_buffered_left_pressed_last_tick = left_pressed
	_buffered_right_pressed_last_tick = right_pressed

func _process_manual_movement() -> void:
	if not manual_movement_enabled and not buffered_movement_enabled:
		return
	if _is_jumping:
		return
	if get_current_move_name() == &"run_punch" or get_current_move_name() == &"run_kick":
		return
	if get_state_name() != &"idle":
		return
	var horizontal_input := _get_horizontal_input()
	var vertical_input := _get_vertical_input()
	if horizontal_input == 0 and vertical_input == 0:
		_run_direction = 0
		if get_current_move_name() == &"walk" or get_current_move_name() == &"run":
			_start_named_move(&"idle")
		return
	global_position.y += float(vertical_input) * manual_depth_move_speed_per_tick
	if horizontal_input == 0:
		_run_direction = 0
		if get_current_move_name() == &"walk" or get_current_move_name() == &"run":
			_start_named_move(&"idle")
		return
	if _run_direction != 0 and horizontal_input != _run_direction:
		_run_direction = 0
	var move_speed := manual_move_speed_per_tick
	var move_name: StringName = &"walk"
	if _run_direction != 0 and horizontal_input == _run_direction:
		move_speed = run_move_speed_per_tick
		move_name = &"run"
	global_position.x += float(horizontal_input) * move_speed
	facing = horizontal_input
	if get_current_move_name() != move_name:
		_start_named_move(move_name)

func _process_run_attack_movement() -> void:
	if _is_jumping:
		return
	var move_name := get_current_move_name()
	if move_name != &"run_punch" and move_name != &"run_kick":
		return
	global_position.x += float(facing) * run_attack_move_speed_per_tick

func _process_jump_motion() -> void:
	if not _is_jumping:
		return
	_process_airborne_control()
	global_position.x += _jump_horizontal_velocity
	_jump_visual_offset_y += _jump_vertical_velocity
	_jump_vertical_velocity += jump_gravity_per_tick
	if _jump_visual_offset_y >= 0.0:
		_jump_visual_offset_y = 0.0
		_jump_vertical_velocity = 0.0
		_jump_horizontal_velocity = 0.0
		_is_jumping = false
		_is_jump_landing = true
		_enter_jump_landing_frame()

func _process_airborne_control() -> void:
	if not manual_movement_enabled and not buffered_movement_enabled:
		return
	var horizontal_input := _get_horizontal_input()
	var vertical_input := _get_vertical_input()
	if horizontal_input != 0:
		var target_speed := air_move_speed_per_tick
		if sign(_jump_horizontal_velocity) == horizontal_input:
			target_speed = max(target_speed, absf(_jump_horizontal_velocity))
		_jump_horizontal_velocity = float(horizontal_input) * target_speed
		facing = horizontal_input
	if vertical_input != 0:
		global_position.y += float(vertical_input) * air_depth_move_speed_per_tick

func _process_action_requests() -> void:
	for action in input_buffer.get_current_actions():
		var requested_move = _resolve_requested_move(action)
		if requested_move == null:
			continue
		if not state_machine.can_start_move(move_runner.current_move, move_runner.get_current_frame(), move_runner.ticks_into_frame, requested_move):
			continue
		if input_buffer.consume_action(action):
			_start_move(requested_move)
			return

func _resolve_requested_move(action: StringName):
	if action == &"jump":
		return move_library.get(&"jump", null)
	if action == &"punch" and _can_front_grapple_punch():
		return move_library.get(&"front_grapple_punch", null)
	if _can_release_grapple_throw() and (action == &"punch" or action == &"kick"):
		return move_library.get(&"grapple_throw", null)
	if _can_launch_breath_target() and (action == &"punch" or action == &"kick"):
		return move_library.get(&"launch", move_library.get(action, null))
	if action == &"grapple" and _can_grapple_breath_target():
		grab_target = interaction_target
		_grab_is_front = _is_front_grab_target(grab_target)
		return move_library.get(&"grapple", null)
	if action == &"punch" and _is_run_forward_active():
		return move_library.get(&"run_punch", move_library.get(action, null))
	if action == &"kick" and _is_run_forward_active():
		return move_library.get(&"run_kick", move_library.get(action, null))
	return move_library.get(action, null)

func _can_launch_breath_target() -> bool:
	if interaction_target == null:
		return false
	if interaction_target.get_current_move_name() != &"breath":
		return false
	return true

func _can_grapple_breath_target() -> bool:
	if not _can_launch_breath_target():
		return false
	return global_position.distance_to(interaction_target.global_position) <= DemoTuningScript.POST_HURT_GRAB_TRIGGER_DISTANCE

func _can_front_grapple_punch() -> bool:
	if not _can_release_grapple_throw():
		return false
	return _grab_is_front

func _can_auto_grapple_breath_target() -> bool:
	if not _can_grapple_breath_target():
		return false
	if grab_target != null:
		return false
	return get_current_move_name() == &"idle" or get_current_move_name() == &"walk" or get_current_move_name() == &"run"

func _can_release_grapple_throw() -> bool:
	return grab_target != null and get_current_move_name() == &"grapple"

func _is_front_grab_target(target: FighterController) -> bool:
	if target == null:
		return false
	var to_target_x: float = target.global_position.x - global_position.x
	if is_zero_approx(to_target_x):
		return facing == target.facing
	var target_side: int = 1 if to_target_x > 0.0 else -1
	return target_side == facing

func _process_grapple_hold() -> void:
	if grab_target == null:
		return
	var move_name: StringName = get_current_move_name()
	if move_name == &"grapple":
		grab_target.apply_grabbed_pose(self)
		return
	if move_name == &"grapple_throw" and get_frame_index() < 2:
		grab_target.apply_grabbed_pose(self)
		return
	if move_name == &"front_grapple_punch":
		if get_frame_index() < 2:
			grab_target.apply_grabbed_pose(self)
		elif get_frame_index() == 2:
			grab_target.global_position = global_position + Vector2(float(facing) * DemoTuningScript.GRAPPLE_HOLD_OFFSET_X, 0.0)
			grab_target.facing = facing
			grab_target._refresh_visual()
		else:
			_release_grab_target(false)
		return
	_release_grab_target(move_name != &"grapple_throw")
	return

func _process_auto_grapple(combat_tick: int) -> void:
	if not _can_auto_grapple_breath_target():
		return
	input_buffer.schedule_action(combat_tick, &"grapple")

func _release_grab_target(_return_to_idle: bool) -> void:
	if grab_target == null:
		return
	var released_target: FighterController = grab_target
	grab_target = null
	_grab_is_front = false
	released_target.release_from_grab(_return_to_idle)
	if _return_to_idle and get_current_move_name() != &"idle":
		_start_named_move(&"idle")

func apply_grabbed_pose(holder: FighterController) -> void:
	if holder == null:
		return
	_grabbed_by = holder
	knockback_step = Vector2.ZERO
	knockback_ticks_remaining = 0
	_is_jumping = false
	_is_jump_landing = false
	_jump_visual_offset_y = 0.0
	_jump_vertical_velocity = 0.0
	_jump_horizontal_velocity = 0.0
	global_position = holder.global_position + Vector2(float(holder.facing) * DemoTuningScript.GRAPPLE_HOLD_OFFSET_X, 0.0)
	_refresh_visual()

func release_from_grab(return_to_idle: bool = true) -> void:
	_grabbed_by = null
	knockback_step = Vector2.ZERO
	knockback_ticks_remaining = 0
	_is_jumping = false
	_is_jump_landing = false
	_jump_visual_offset_y = 0.0
	_jump_vertical_velocity = 0.0
	_jump_horizontal_velocity = 0.0
	if return_to_idle:
		if get_current_move_name() == &"breath":
			_start_named_move(&"breath_invulnerable")
		elif get_current_move_name() != &"idle":
			_start_named_move(&"idle")
	_refresh_visual()

func _is_run_forward_active() -> bool:
	if not manual_movement_enabled and not buffered_movement_enabled:
		return false
	if _is_jumping:
		return false
	if get_current_move_name() != &"run":
		return false
	if facing >= 0:
		return input_buffer.has_action(&"move_right")
	return input_buffer.has_action(&"move_left")

func _get_horizontal_input() -> int:
	var horizontal_input: int = 0
	if input_buffer.has_action(&"move_left"):
		horizontal_input -= 1
	if input_buffer.has_action(&"move_right"):
		horizontal_input += 1
	return horizontal_input

func _get_vertical_input() -> int:
	var vertical_input: int = 0
	if input_buffer.has_action(&"move_up"):
		vertical_input -= 1
	if input_buffer.has_action(&"move_down"):
		vertical_input += 1
	return vertical_input

func _resolve_jump_horizontal_velocity() -> float:
	var horizontal_input := _get_horizontal_input()
	if horizontal_input == 0:
		return 0.0
	if _run_direction != 0 and horizontal_input == _run_direction and get_current_move_name() == &"run":
		return float(horizontal_input) * run_jump_move_speed_per_tick
	return float(horizontal_input) * manual_move_speed_per_tick

func _enter_jump_landing_frame() -> void:
	if get_current_move_name() != &"jump":
		return
	if move_runner.current_move == null:
		return
	if move_runner.current_move.frames.size() < 3:
		return
	move_runner.current_frame_index = 2
	move_runner.ticks_into_frame = 0

func _start_named_move(move_name: StringName) -> void:
	var next_move = move_library.get(move_name, null)
	if next_move == null and move_library.has(&"idle"):
		next_move = move_library[&"idle"]
	if next_move == null:
		return
	_start_move(next_move)

func _start_move(move) -> void:
	if move != null and move.move_name == &"jump":
		var horizontal_input := _get_horizontal_input()
		_is_jumping = true
		_is_jump_landing = false
		_jump_vertical_velocity = jump_velocity_per_tick
		_jump_horizontal_velocity = _resolve_jump_horizontal_velocity()
		if horizontal_input != 0:
			facing = horizontal_input
		_run_direction = 0
	elif move != null:
		_is_jump_landing = false
	move_runner.start_move(move)
	state_machine.sync_from_move(move)

func _refresh_visual() -> void:
	if visual != null:
		visual.refresh_visual()
