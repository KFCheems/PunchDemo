extends Node2D

const DemoMoveLibraryScript = preload("res://scripts/data/demo_move_library.gd")
const HitResolverScript = preload("res://scripts/core/hit_resolver.gd")

const ATTACKER_START := Vector2(260.0, 300.0)
const DUMMY_START := Vector2(360.0, 300.0)
const PHASE_LENGTH_TICKS := 240

@onready var attacker: FighterController = $Attacker
@onready var dummy: FighterController = $Dummy
@onready var status_label: Label = $CanvasLayer/StatusLabel

var move_library: Dictionary = {}
var hit_resolver := HitResolverScript.new()
var phases: Array[Dictionary] = []
var results: Dictionary = {}
var report_lines: Array[String] = []
var phase_index: int = 0
var phase_tick: int = 0
var phase_events: Array[String] = []
var phase_timeline: Array[String] = []
var completed: bool = false
var replay_has_run: bool = false
var live_input_replay_active: bool = false
var last_live_input_script: Array = []
var last_live_input_length_ticks: int = 0
var last_live_input_baseline: Dictionary = {}
var last_live_input_summary: String = ""
var _live_input_replay_baseline: Dictionary = {}
var _last_live_input_history_size: int = 0
var _status_panel_visible: bool = true
var _status_panel_toggle_pressed_last_tick: bool = false
var _replay_trigger_pressed_last_tick: bool = false
var _live_input_replay_trigger_pressed_last_tick: bool = false

func _ready() -> void:
	move_library = DemoMoveLibraryScript.create_library()
	attacker.setup("Attacker", 1, move_library)
	dummy.setup("Dummy", -1, move_library)
	attacker.interaction_target = dummy
	dummy.interaction_target = attacker
	dummy.post_hurt_move_name = &"breath"
	phases = [
		{
			"name": "single_run_a",
			"script": [{"tick": 10, "action": "attack_single"}],
		},
		{
			"name": "single_run_b",
			"script": [{"tick": 10, "action": "attack_single"}],
			"compare_to": "single_run_a",
		},
		{
			"name": "multi_run_a",
			"script": [{"tick": 10, "action": "attack_multi"}],
		},
		{
			"name": "multi_run_b",
			"script": [{"tick": 10, "action": "attack_multi"}],
			"compare_to": "multi_run_a",
		},
	]
	report_lines = [
		"P0 combat demo",
		"- single-hit phase",
		"- deterministic replay phase",
		"- multi-hit phase with 30 tick re-hit interval",
		"- attack recovery is cancelable into a new attack",
		"- double-tap left/right enters Run",
		"- Run + J/K triggers run punch / run kick",
	]
	_enter_free_demo_mode()

func _physics_process(_delta: float) -> void:
	_process_status_panel_toggle()
	if completed:
		_process_free_demo_tick()
		return

	attacker.start_combat_tick(phase_tick)
	dummy.start_combat_tick(phase_tick)

	var attacker_events: Array = hit_resolver.resolve_attacker(attacker, [dummy], phase_tick)
	for event in attacker_events:
		phase_events.append(_format_event(event))

	var dummy_events: Array = hit_resolver.resolve_attacker(dummy, [attacker], phase_tick)
	for event in dummy_events:
		phase_events.append(_format_event(event))

	attacker.end_combat_tick()
	dummy.end_combat_tick()

	phase_timeline.append(_snapshot_line(phase_tick))
	_update_status_label(false)
	phase_tick += 1

	if phase_tick >= _get_active_phase_length():
		_finish_phase()

func _process_status_panel_toggle() -> void:
	var toggle_pressed: bool = Input.is_physical_key_pressed(KEY_F1)
	if toggle_pressed and not _status_panel_toggle_pressed_last_tick:
		_status_panel_visible = not _status_panel_visible
		if status_label != null:
			status_label.visible = _status_panel_visible
	_status_panel_toggle_pressed_last_tick = toggle_pressed

func _start_phase(index: int) -> void:
	live_input_replay_active = false
	completed = false
	phase_index = index
	phase_tick = 0
	phase_events.clear()
	phase_timeline.clear()
	hit_resolver.clear()
	attacker.reset_for_replay(ATTACKER_START)
	dummy.reset_for_replay(DUMMY_START)
	attacker.interaction_target = dummy
	dummy.interaction_target = attacker
	attacker.schedule_scripted_actions(phases[phase_index]["script"])
	_update_status_label(false)

func _start_live_input_replay() -> void:
	if last_live_input_script.is_empty():
		return
	_live_input_replay_baseline = _build_result(phase_events, phase_timeline, last_live_input_length_ticks, dummy.health)
	live_input_replay_active = true
	completed = false
	phase_tick = 0
	phase_events.clear()
	phase_timeline.clear()
	hit_resolver.clear()
	attacker.reset_for_replay(ATTACKER_START)
	dummy.reset_for_replay(DUMMY_START)
	attacker.interaction_target = dummy
	dummy.interaction_target = attacker
	attacker.buffered_movement_enabled = true
	attacker.schedule_scripted_actions(last_live_input_script)
	_update_status_label(false)

func _enter_free_demo_mode() -> void:
	completed = true
	hit_resolver.clear()
	phase_events.clear()
	phase_timeline.clear()
	phase_tick = 0
	last_live_input_script.clear()
	last_live_input_length_ticks = 0
	last_live_input_baseline.clear()
	_last_live_input_history_size = 0
	_replay_trigger_pressed_last_tick = false
	_live_input_replay_trigger_pressed_last_tick = false
	attacker.reset_for_replay(ATTACKER_START)
	dummy.reset_for_replay(DUMMY_START)
	attacker.interaction_target = dummy
	dummy.interaction_target = attacker
	attacker.manual_movement_enabled = true
	attacker.buffered_movement_enabled = true
	_update_live_input_recording_snapshot()
	_update_status_label(true)

func _process_free_demo_tick() -> void:
	var replay_trigger_pressed: bool = Input.is_physical_key_pressed(KEY_R)
	if replay_trigger_pressed and not _replay_trigger_pressed_last_tick:
		_start_phase(0)
		_replay_trigger_pressed_last_tick = replay_trigger_pressed
		return
	_replay_trigger_pressed_last_tick = replay_trigger_pressed
	var live_input_replay_trigger_pressed: bool = Input.is_physical_key_pressed(KEY_T)
	if live_input_replay_trigger_pressed and not _live_input_replay_trigger_pressed_last_tick:
		_start_live_input_replay()
		_live_input_replay_trigger_pressed_last_tick = live_input_replay_trigger_pressed
		return
	_live_input_replay_trigger_pressed_last_tick = live_input_replay_trigger_pressed
	attacker.start_combat_tick(phase_tick)
	dummy.start_combat_tick(phase_tick)
	var free_demo_attacker_events: Array = hit_resolver.resolve_attacker(attacker, [dummy], phase_tick)
	for event in free_demo_attacker_events:
		phase_events.append(_format_event(event))
	var free_demo_dummy_events: Array = hit_resolver.resolve_attacker(dummy, [attacker], phase_tick)
	for event in free_demo_dummy_events:
		phase_events.append(_format_event(event))
	attacker.end_combat_tick()
	dummy.end_combat_tick()
	phase_timeline.append(_snapshot_line(phase_tick))
	phase_tick += 1
	_update_live_input_recording_snapshot()
	_update_status_label(true)

func _finish_phase() -> void:
	if live_input_replay_active:
		var replay_result := _build_result(phase_events, phase_timeline, phase_tick, dummy.health)
		var comparison := _compare_results(_live_input_replay_baseline, replay_result)
		last_live_input_summary = "live_input_replay -> verdict=%s %s" % [
			"PASS" if comparison["passed"] else "FAIL",
			_build_result_summary(replay_result),
		]
		if not comparison["passed"] and comparison["detail"] != "":
			last_live_input_summary += " detail=%s" % [String(comparison["detail"])]
		live_input_replay_active = false
		_live_input_replay_baseline.clear()
		_enter_free_demo_mode()
		return

	var phase: Dictionary = phases[phase_index]
	var phase_result := _build_result(phase_events, phase_timeline, phase_tick, dummy.health)
	var signature := String(phase_result["signature"])
	results[phase["name"]] = phase_result

	var hit_count := phase_events.size()
	var line := "%s -> hits=%d dummy_hp=%d attacker_move=%s dummy_state=%s" % [
		String(phase["name"]),
		hit_count,
		dummy.health,
		String(attacker.get_current_move_name()),
		String(dummy.get_state_name()),
	]

	if phase.has("compare_to"):
		var compare_name: String = phase["compare_to"]
		var matches := false
		if results.has(compare_name):
			matches = results[compare_name]["signature"] == signature
		line += " replay_match=%s" % ["PASS" if matches else "FAIL"]
	report_lines.append(line)

	if phase_index + 1 >= phases.size():
		replay_has_run = true
		_enter_free_demo_mode()
		return

	_start_phase(phase_index + 1)

func _snapshot_line(tick: int) -> String:
	return "%03d %s %s" % [
		tick,
		attacker.build_snapshot_line("A"),
		dummy.build_snapshot_line("B"),
	]

func _format_event(event: Dictionary) -> String:
	return "tick=%03d %s->%s mode=%s damage=%d" % [
		int(event["tick"]),
		String(event["attacker"]),
		String(event["target"]),
		String(event["mode"]),
		int(event["damage"]),
	]

func _build_signature(events: Array[String], timeline: Array[String]) -> String:
	var all_lines: Array[String] = []
	all_lines.append_array(events)
	all_lines.append("--")
	all_lines.append_array(timeline)
	return _join_lines(all_lines)

func _build_result(events: Array[String], timeline: Array[String], tick_count: int, dummy_hp: int) -> Dictionary:
	return {
		"signature": _build_signature(events, timeline),
		"events": events.duplicate(),
		"timeline": timeline.duplicate(),
		"ticks": tick_count,
		"hits": events.size(),
		"dummy_hp": dummy_hp,
	}

func _build_result_summary(result: Dictionary) -> String:
	return "ticks=%d hits=%d dummy_hp=%d" % [
		int(result.get("ticks", 0)),
		int(result.get("hits", 0)),
		int(result.get("dummy_hp", 0)),
	]

func _compare_results(expected: Dictionary, actual: Dictionary) -> Dictionary:
	if String(expected.get("signature", "")) == String(actual.get("signature", "")):
		return {
			"passed": true,
			"detail": "",
		}
	var detail := _describe_sequence_difference(expected.get("events", []), actual.get("events", []), "event")
	if detail == "":
		detail = _describe_sequence_difference(expected.get("timeline", []), actual.get("timeline", []), "timeline")
	if detail == "":
		detail = "signature_mismatch"
	return {
		"passed": false,
		"detail": detail,
	}

func _describe_sequence_difference(expected_variant, actual_variant, label: String) -> String:
	var expected: Array = expected_variant if expected_variant is Array else []
	var actual: Array = actual_variant if actual_variant is Array else []
	if expected.size() != actual.size():
		return "%s_count expected=%d actual=%d" % [label, expected.size(), actual.size()]
	for index in range(expected.size()):
		var expected_line := String(expected[index])
		var actual_line := String(actual[index])
		if expected_line != actual_line:
			return "%s_mismatch[%d] expected=%s actual=%s" % [label, index, expected_line, actual_line]
	return ""

func _update_live_input_recording_snapshot() -> void:
	last_live_input_length_ticks = max(phase_tick, 0)
	last_live_input_baseline = {
		"ticks": last_live_input_length_ticks,
		"hits": phase_events.size(),
		"dummy_hp": dummy.health,
	}
	if attacker == null:
		return
	if attacker.input_buffer.action_history.size() < _last_live_input_history_size:
		last_live_input_script.clear()
		_last_live_input_history_size = 0
	for history_index in range(_last_live_input_history_size, attacker.input_buffer.action_history.size()):
		var entry = attacker.input_buffer.action_history[history_index]
		if not (entry is Dictionary):
			continue
		var tick: int = int(entry.get("tick", -1))
		if tick < 0:
			continue
		var actions: Array = entry.get("actions", [])
		for action in actions:
			var action_name := StringName(action)
			if action_name == &"move_left" or action_name == &"move_right" or action_name == &"move_up" or action_name == &"move_down" or action_name == &"jump" or action_name == &"punch" or action_name == &"kick" or action_name == &"grapple" or action_name == &"attack_single" or action_name == &"attack_multi":
				last_live_input_script.append({
					"tick": tick,
					"action": String(action_name),
				})
	_last_live_input_history_size = attacker.input_buffer.action_history.size()

func _update_status_label(show_complete: bool) -> void:
	var lines: Array[String] = []
	lines.append_array(report_lines)
	if not show_complete and phase_index < phases.size():
		lines.append("")
		if live_input_replay_active:
			lines.append("Live input replay running.")
			lines.append("Tick: %d / %d" % [phase_tick, max(_get_active_phase_length(), 1)])
		else:
			var phase: Dictionary = phases[phase_index]
			lines.append("Replay validation running: %s" % [String(phase["name"])])
			lines.append("Tick: %d / %d" % [phase_tick, _get_active_phase_length()])
		lines.append("Attacker: %s" % [attacker.build_snapshot_line("A")])
		lines.append("Dummy: %s" % [dummy.build_snapshot_line("B")])
		if not phase_events.is_empty():
			lines.append("Last hit: %s" % [phase_events[phase_events.size() - 1]])
	else:
		lines.append("")
		if replay_has_run:
			lines.append("Manual demo active. Last replay validation completed.")
			lines.append("Expected replay results: single-hit=1 hit, multi-hit=6 hits, replay_match=PASS.")
		else:
			lines.append("Manual demo active. Press R to run replay validation.")
			lines.append("Replay validation checks single-hit, deterministic replay, and multi-hit.")
		lines.append("Controls: WASD or arrows move, Space jump, J punch, K/Enter kick, L grapple, R replay, T live replay.")
		lines.append("Movement: double-tap left/right to enter Run.")
		lines.append("Depth: W/S or Up/Down moves along the vertical lane.")
		lines.append("Debug panel: press F1 to show/hide this text panel.")
		lines.append("Sprint attacks: while running, J for run punch and K for run kick.")
		lines.append("Recovery cancel: press attack again during recovery to chain into a new attack.")
		lines.append("Breath follow-up: hit a breathing dummy with J/K to launch, or press L nearby to grapple.")
		if last_live_input_script.is_empty():
			lines.append("Live input replay: no recorded manual input yet.")
		else:
			lines.append("Live input replay: %d actions over %d ticks. Press T to replay." % [last_live_input_script.size(), last_live_input_length_ticks])
			if last_live_input_summary != "":
				lines.append("Last live replay: %s" % [last_live_input_summary])
		lines.append("Attacker: %s" % [attacker.build_snapshot_line("A")])
		lines.append("Dummy: %s" % [dummy.build_snapshot_line("B")])
		if not phase_events.is_empty():
			lines.append("Last hit: %s" % [phase_events[phase_events.size() - 1]])
	status_label.text = _join_lines(lines)
	status_label.visible = _status_panel_visible

func _join_lines(lines: Array[String]) -> String:
	var text := ""
	for i in range(lines.size()):
		if i > 0:
			text += "\n"
		text += lines[i]
	return text

func _get_active_phase_length() -> int:
	if live_input_replay_active:
		return max(last_live_input_length_ticks, 0)
	return PHASE_LENGTH_TICKS
