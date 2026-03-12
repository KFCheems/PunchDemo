class_name FighterController
extends Node2D

const InputBufferScript = preload("res://scripts/battle/core/input_buffer.gd")
const FighterStateMachineScript = preload("res://scripts/battle/core/fighter_state_machine.gd")
const MoveRunnerScript = preload("res://scripts/battle/core/move_runner.gd")
const DemoMoveLibraryScript = preload("res://scripts/data/demo_move_library.gd")
const DemoTuningScript = preload("res://scripts/data/demo_tuning.gd")
const FighterStatsScript = preload("res://scripts/fighter/base/fighter_stats.gd")
const FighterMotorScript = preload("res://scripts/fighter/base/fighter_motor.gd")
const FighterGrabScript = preload("res://scripts/fighter/base/fighter_grab.gd")
const FighterCombatScript = preload("res://scripts/fighter/base/fighter_combat.gd")

var fighter_name: String = "Fighter"
var facing: int = 1
var default_facing: int = 1
var max_health: int = 100
var health: int = 100
var move_library: Dictionary = {}
var fighter_definition = null
var visual_profile = null
var post_hurt_move_name: StringName = &"idle"
var interaction_target: FighterController = null
var grab_target: FighterController = null
var _grab_is_front: bool = false
var _grabbed_by: FighterController = null

var input_buffer := InputBufferScript.new()
var state_machine := FighterStateMachineScript.new()
var move_runner := MoveRunnerScript.new()
var stats_logic := FighterStatsScript.new()
var motor_logic := FighterMotorScript.new()
var grab_logic := FighterGrabScript.new()
var combat_logic := FighterCombatScript.new()

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

func apply_fighter_definition(definition) -> void:
	fighter_definition = definition
	visual_profile = null
	if definition != null and definition.visual_profile != null:
		visual_profile = definition.visual_profile
	_refresh_visual()

func get_visual_profile():
	return visual_profile

func reset_for_replay(start_position: Vector2) -> void:
	global_position = start_position
	facing = default_facing
	stats_logic.reset(self)
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
	combat_logic.receive_hit(self, effect, attacker)

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
	motor_logic.apply_knockback(self)

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
	motor_logic.process_manual_movement(self)

func _process_run_attack_movement() -> void:
	motor_logic.process_run_attack_movement(self)

func _process_jump_motion() -> void:
	motor_logic.process_jump_motion(self)

func _process_airborne_control() -> void:
	motor_logic.process_airborne_control(self)

func _process_action_requests() -> void:
	combat_logic.process_action_requests(self)

func _resolve_requested_move(action: StringName):
	return combat_logic.resolve_requested_move(self, action)

func _can_launch_breath_target() -> bool:
	return grab_logic.can_launch_breath_target(self)

func _can_grapple_breath_target() -> bool:
	return grab_logic.can_grapple_breath_target(self)

func _can_front_grapple_punch() -> bool:
	return grab_logic.can_front_grapple_punch(self)

func _can_auto_grapple_breath_target() -> bool:
	return grab_logic.can_auto_grapple_breath_target(self)

func _can_release_grapple_throw() -> bool:
	return grab_logic.can_release_grapple_throw(self)

func _is_front_grab_target(target: FighterController) -> bool:
	return grab_logic.is_front_grab_target(self, target)

func _process_grapple_hold() -> void:
	grab_logic.process_grapple_hold(self)

func _has_auto_grapple_movement_intent(combat_tick: int) -> bool:
	return grab_logic.has_auto_grapple_movement_intent(self, combat_tick)

func _process_auto_grapple(combat_tick: int) -> void:
	grab_logic.process_auto_grapple(self, combat_tick)

func _release_grab_target(_return_to_idle: bool) -> void:
	grab_logic.release_grab_target(self, _return_to_idle)

func apply_grabbed_pose(holder: FighterController) -> void:
	grab_logic.apply_grabbed_pose(self, holder)

func release_from_grab(return_to_idle: bool = true) -> void:
	grab_logic.release_from_grab(self, return_to_idle)

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
	var horizontal_input: int = _get_horizontal_input()
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
		var horizontal_input: int = _get_horizontal_input()
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
