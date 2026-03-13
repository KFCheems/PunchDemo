class_name FighterController
extends Node2D

const InputBufferScript = preload("res://scripts/battle/core/input_buffer.gd")
const FighterStateMachineScript = preload("res://scripts/battle/core/fighter_state_machine.gd")
const MoveRunnerScript = preload("res://scripts/battle/core/move_runner.gd")
const DemoMoveLibraryScript = preload("res://scripts/data/demo_move_library.gd")
const DemoTuningScript = preload("res://scripts/data/demo_tuning.gd")
const FighterStatsScript = preload("res://scripts/fighter/base/fighter_stats.gd")
const FighterInputScript = preload("res://scripts/fighter/base/fighter_input.gd")
const FighterMotorScript = preload("res://scripts/fighter/base/fighter_motor.gd")
const FighterGrabScript = preload("res://scripts/fighter/base/fighter_grab.gd")
const FighterCombatScript = preload("res://scripts/fighter/base/fighter_combat.gd")
const FighterRuntimeStateScript = preload("res://scripts/fighter/base/fighter_runtime_state.gd")

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

var input_buffer = InputBufferScript.new()
var state_machine = FighterStateMachineScript.new()
var move_runner = MoveRunnerScript.new()
var runtime_state = FighterRuntimeStateScript.new()
var stats_logic = FighterStatsScript.new()
var input_logic = FighterInputScript.new()
var motor_logic = FighterMotorScript.new()
var grab_logic = FighterGrabScript.new()
var combat_logic = FighterCombatScript.new()

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

@onready var visual = $Visual

func _ready() -> void:
	if visual != null:
		visual.bind_controller(self)
	if move_runner.current_move == null:
		move_library = DemoMoveLibraryScript.create_library()
		combat_logic.start_named_move(self,&"idle")

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
	runtime_state.reset()
	manual_movement_enabled = false
	buffered_movement_enabled = false
	input_buffer.clear()
	state_machine.reset()
	move_runner.reset()
	combat_logic.start_named_move(self,&"idle")
	_refresh_visual()

func schedule_scripted_actions(entries: Array) -> void:
	input_buffer.schedule_actions(entries)

func start_combat_tick(combat_tick: int) -> void:
	if runtime_state.grabbed_by != null:
		input_buffer.begin_tick(combat_tick)
		grab_logic.process_grapple_hold(self)
		_refresh_visual()
		return
	input_logic.process_manual_attack(self, combat_tick)
	input_logic.process_manual_jump(self, combat_tick)
	input_logic.queue_manual_movement_actions(self, combat_tick)
	grab_logic.process_auto_grapple(self, combat_tick)
	input_buffer.begin_tick(combat_tick)
	input_logic.sync_buffered_movement_state(self, combat_tick)
	motor_logic.apply_knockback(self)
	motor_logic.process_jump_motion(self)
	grab_logic.process_grapple_hold(self)
	combat_logic.process_action_requests(self)
	motor_logic.process_run_attack_movement(self)
	motor_logic.process_manual_movement(self)
	_refresh_visual()

func end_combat_tick() -> void:
	if runtime_state.grabbed_by != null:
		_refresh_visual()
		return
	if move_runner.advance():
		combat_logic.start_named_move(self,move_runner.get_return_move_name())
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
	return Vector2(0.0, runtime_state.jump_visual_offset_y)

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

func apply_grabbed_pose(holder: FighterController) -> void:
	grab_logic.apply_grabbed_pose(self, holder)

func release_from_grab(return_to_idle: bool = true) -> void:
	grab_logic.release_from_grab(self, return_to_idle)

func _refresh_visual() -> void:
	if visual != null:
		visual.refresh_visual()
