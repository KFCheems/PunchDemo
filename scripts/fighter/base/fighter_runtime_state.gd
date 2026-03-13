class_name FighterRuntimeState
extends RefCounted

const DEFAULT_LAST_PRESS_TICK := -9999

var knockback_step: Vector2 = Vector2.ZERO
var knockback_ticks_remaining: int = 0
var manual_single_attack_pressed_last_tick: bool = false
var manual_multi_attack_pressed_last_tick: bool = false
var manual_jump_pressed_last_tick: bool = false
var buffered_left_pressed_last_tick: bool = false
var buffered_right_pressed_last_tick: bool = false
var last_left_press_tick: int = DEFAULT_LAST_PRESS_TICK
var last_right_press_tick: int = DEFAULT_LAST_PRESS_TICK
var run_direction: int = 0
var jump_visual_offset_y: float = 0.0
var jump_vertical_velocity: float = 0.0
var jump_horizontal_velocity: float = 0.0
var is_jumping: bool = false
var grabbed_by = null

func reset() -> void:
	clear_knockback()
	clear_jump_state()
	clear_run_state()
	clear_input_edges()
	grabbed_by = null

func clear_knockback() -> void:
	knockback_step = Vector2.ZERO
	knockback_ticks_remaining = 0

func clear_jump_state() -> void:
	jump_visual_offset_y = 0.0
	jump_vertical_velocity = 0.0
	jump_horizontal_velocity = 0.0
	is_jumping = false

func clear_run_state() -> void:
	run_direction = 0

func clear_input_edges() -> void:
	manual_single_attack_pressed_last_tick = false
	manual_multi_attack_pressed_last_tick = false
	manual_jump_pressed_last_tick = false
	buffered_left_pressed_last_tick = false
	buffered_right_pressed_last_tick = false
	last_left_press_tick = DEFAULT_LAST_PRESS_TICK
	last_right_press_tick = DEFAULT_LAST_PRESS_TICK
