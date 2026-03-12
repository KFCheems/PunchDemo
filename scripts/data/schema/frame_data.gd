class_name FrameData
extends Resource

@export var display_id: StringName = &"idle"
@export var duration_ticks: int = 1
@export var interruptible: bool = true
@export var cancelable: bool = false
@export var interrupt_window_start_tick: int = -1
@export var interrupt_window_end_tick: int = -1
@export var cancel_window_start_tick: int = -1
@export var cancel_window_end_tick: int = -1
@export var hitboxes: Array = []
@export var hurtboxes: Array = []

func get_safe_duration() -> int:
	return max(duration_ticks, 1)

func is_interrupt_open(tick_in_frame: int) -> bool:
	return _is_window_open(tick_in_frame, interruptible, interrupt_window_start_tick, interrupt_window_end_tick)

func is_cancel_open(tick_in_frame: int) -> bool:
	return _is_window_open(tick_in_frame, cancelable, cancel_window_start_tick, cancel_window_end_tick)

func _is_window_open(tick_in_frame: int, enabled: bool, start_tick: int, end_tick: int) -> bool:
	if not enabled:
		return false
	if start_tick < 0 or end_tick < 0:
		return true
	return tick_in_frame >= start_tick and tick_in_frame <= end_tick
