extends Node2D

const HitResolverScript = preload("res://scripts/battle/core/hit_resolver.gd")
const BattleRulesScript = preload("res://scripts/battle/runtime/battle_rules.gd")

@onready var background: Sprite2D = $Background
@onready var attacker = $Attacker
@onready var dummy = $Dummy
@onready var battle_camera = $BattleCamera
@onready var battle_hud = $CanvasLayer/BattleHUD

var hit_resolver := HitResolverScript.new()
var rules := BattleRulesScript.new()
var combat_tick: int = 0
var _last_event_text: String = ""

func _ready() -> void:
	_setup_match()
	_update_runtime_views()

func _physics_process(_delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		_finish_match()
		return

	attacker.start_combat_tick(combat_tick)
	dummy.start_combat_tick(combat_tick)

	var attacker_events: Array = hit_resolver.resolve_attacker(attacker, [dummy], combat_tick)
	var dummy_events: Array = hit_resolver.resolve_attacker(dummy, [attacker], combat_tick)
	if not attacker_events.is_empty():
		_last_event_text = _format_event(attacker_events[attacker_events.size() - 1])
	elif not dummy_events.is_empty():
		_last_event_text = _format_event(dummy_events[dummy_events.size() - 1])

	attacker.end_combat_tick()
	dummy.end_combat_tick()
	combat_tick += 1
	_update_runtime_views()

	if rules.is_match_over(attacker, dummy, combat_tick):
		_finish_match()

func _setup_match() -> void:
	var data_manager = get_node_or_null("/root/DataManager")
	var game_manager = get_node_or_null("/root/GameManager")
	var attacker_fighter_id: StringName = &"ali"
	var dummy_fighter_id: StringName = &"ali"
	var stage_id: StringName = &"stage_01"
	if game_manager != null:
		attacker_fighter_id = game_manager.get_selected_fighter_id(0)
		dummy_fighter_id = game_manager.get_selected_fighter_id(1)
		stage_id = game_manager.selected_stage_id

	var attacker_library: Dictionary = {}
	var dummy_library: Dictionary = {}
	if data_manager != null:
		attacker_library = data_manager.get_move_library(attacker_fighter_id)
		dummy_library = data_manager.get_move_library(dummy_fighter_id)
		attacker.apply_fighter_definition(data_manager.get_fighter_definition(attacker_fighter_id))
		dummy.apply_fighter_definition(data_manager.get_fighter_definition(dummy_fighter_id))
		var stage_data: Dictionary = data_manager.get_stage_data(stage_id)
		var background_path := String(stage_data.get("background_path", ""))
		if background_path != "":
			background.texture = load(background_path)
		var audio_manager = get_node_or_null("/root/AudioManager")
		if audio_manager != null:
			audio_manager.play_bgm(String(stage_data.get("bgm_path", "")))

	attacker.setup("Player 1", 1, attacker_library)
	dummy.setup("Player 2", -1, dummy_library)
	attacker.global_position = rules.get_attacker_start()
	dummy.global_position = rules.get_dummy_start()
	attacker.interaction_target = dummy
	dummy.interaction_target = attacker
	dummy.post_hurt_move_name = &"breath"
	attacker.manual_movement_enabled = true
	attacker.buffered_movement_enabled = true
	dummy.manual_movement_enabled = false
	dummy.buffered_movement_enabled = false
	combat_tick = 0
	hit_resolver.clear()
	_last_event_text = ""

func _update_runtime_views() -> void:
	if battle_camera != null:
		battle_camera.sync_to_fighters(attacker, dummy)
	if battle_hud != null:
		battle_hud.update_hud(attacker, dummy, combat_tick)
		battle_hud.set_last_event(_last_event_text)

func _finish_match() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager != null:
		game_manager.set_last_result(rules.build_result(attacker, dummy, combat_tick))
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.go_to_result_screen()

func _format_event(event: Dictionary) -> String:
	return "tick=%03d %s->%s mode=%s damage=%d" % [
		int(event.get("tick", 0)),
		String(event.get("attacker", "?")),
		String(event.get("target", "?")),
		String(event.get("mode", "?")),
		int(event.get("damage", 0)),
	]
