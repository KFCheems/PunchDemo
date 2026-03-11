class_name InputBuffer
extends RefCounted

var _scheduled_actions: Dictionary = {}
var _current_actions: Array[StringName] = []
var _consumed_actions: Dictionary = {}
var action_history: Array = []

func clear() -> void:
	_scheduled_actions.clear()
	_current_actions.clear()
	_consumed_actions.clear()
	action_history.clear()

func schedule_action(tick: int, action: StringName) -> void:
	var actions: Array = _scheduled_actions.get(tick, [])
	actions.append(action)
	_scheduled_actions[tick] = actions

func schedule_actions(entries: Array) -> void:
	for entry in entries:
		if not (entry is Dictionary):
			continue
		if not entry.has("tick") or not entry.has("action"):
			continue
		schedule_action(int(entry["tick"]), StringName(entry["action"]))

func begin_tick(tick: int) -> void:
	_current_actions.clear()
	_consumed_actions.clear()
	var actions: Array = _scheduled_actions.get(tick, [])
	if _scheduled_actions.has(tick):
		_scheduled_actions.erase(tick)
	for action in actions:
		_current_actions.append(StringName(action))
	if not _current_actions.is_empty():
		action_history.append({
			"tick": tick,
			"actions": _current_actions.duplicate(),
		})

func has_action(action: StringName) -> bool:
	return _current_actions.has(action) and not _consumed_actions.has(action)

func consume_action(action: StringName) -> bool:
	if not has_action(action):
		return false
	_consumed_actions[action] = true
	return true

func get_current_actions() -> Array[StringName]:
	return _current_actions.duplicate()
