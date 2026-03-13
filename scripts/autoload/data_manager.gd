extends Node

const DemoMoveLibraryScript = preload("res://scripts/data/demo_move_library.gd")
const FighterDefinitionScript = preload("res://scripts/data/fighter_definition.gd")
const FighterVisualProfileScript = preload("res://scripts/data/fighter_visual_profile.gd")

const ALI_DEFINITION_RESOURCE_PATH := "res://resources/fighters/ali/ali_definition.tres"
const COMMON_MOVE_RESOURCE_PATHS := {
	"idle": "res://resources/moves/common/idle.tres",
	"hurt": "res://resources/moves/common/hurt.tres",
	"jump": "res://resources/moves/common/jump.tres",
	"punch": "res://resources/moves/common/punch.tres",
	"kick": "res://resources/moves/common/kick.tres",
	"jump_punch": "res://resources/moves/common/jump_punch.tres",
	"jump_kick": "res://resources/moves/common/jump_kick.tres",
	"knockdown_fall": "res://resources/moves/common/knockdown_fall.tres",
	"knockdown_downed": "res://resources/moves/common/knockdown_downed.tres",
	"knockdown_getup": "res://resources/moves/common/knockdown_getup.tres",
}

var _fighter_definitions: Dictionary = {}
var _stage_data: Dictionary = {}

func _ready() -> void:
	initialize()

func initialize() -> void:
	if not _fighter_definitions.is_empty() and not _stage_data.is_empty():
		return
	if not _fighter_definitions.has(&"ali"):
		_fighter_definitions[&"ali"] = _load_fighter_definition_resource(ALI_DEFINITION_RESOURCE_PATH)
		if _fighter_definitions[&"ali"] == null:
			_fighter_definitions[&"ali"] = _build_ali_definition()
	if not _stage_data.has(&"stage_01"):
		_stage_data[&"stage_01"] = {
			"stage_id": &"stage_01",
			"display_name": "Stage 01",
			"background_path": "res://assets/sprites/stages/stage_01.png",
			"bgm_path": "res://assets/audio/bgm/stage_01.wav",
		}

func get_move_library(fighter_id: StringName = &"ali") -> Dictionary:
	initialize()
	var library := DemoMoveLibraryScript.create_library()
	var definition = get_fighter_definition(fighter_id)
	if definition == null:
		return library
	for move_key in definition.move_resource_map.keys():
		var move_name: StringName = StringName(move_key)
		var resource_path := String(definition.move_resource_map.get(move_key, ""))
		var move_resource = _load_move_resource(resource_path)
		if move_resource != null:
			library[move_name] = move_resource
	return library

func build_hurt_move(fighter_id: StringName = &"ali", hitstun_ticks: int = 1):
	initialize()
	var definition = get_fighter_definition(fighter_id)
	var hurt_move = _load_move_resource(_get_move_resource_path(definition, &"hurt"))
	if hurt_move == null:
		return DemoMoveLibraryScript.build_hurt_move(hitstun_ticks)
	if hurt_move.frames.is_empty():
		return DemoMoveLibraryScript.build_hurt_move(hitstun_ticks)
	var hurt_frame = hurt_move.frames[0]
	if hurt_frame == null:
		return DemoMoveLibraryScript.build_hurt_move(hitstun_ticks)
	hurt_frame.duration_ticks = max(hitstun_ticks, 1)
	return hurt_move

func get_fighter_definition(fighter_id: StringName = &"ali"):
	initialize()
	return _fighter_definitions.get(fighter_id, _fighter_definitions.get(&"ali", null))

func get_stage_data(stage_id: StringName = &"stage_01") -> Dictionary:
	initialize()
	return _stage_data.get(stage_id, _stage_data.get(&"stage_01", {})).duplicate(true)

func _load_fighter_definition_resource(resource_path: String):
	if resource_path == "":
		return null
	var definition = load(resource_path)
	if definition == null:
		return null
	return definition

func _load_move_resource(resource_path: String):
	if resource_path == "":
		return null
	var move_resource = load(resource_path)
	if move_resource == null:
		return null
	return move_resource.duplicate(true)

func _get_move_resource_path(definition, move_name: StringName) -> String:
	if definition == null or definition.move_resource_map.is_empty():
		return ""
	if definition.move_resource_map.has(move_name):
		return String(definition.move_resource_map[move_name])
	var move_key := String(move_name)
	if definition.move_resource_map.has(move_key):
		return String(definition.move_resource_map[move_key])
	return ""

func _build_ali_definition():
	var profile = FighterVisualProfileScript.new()
	profile.fighter_id = &"ali"
	profile.texture = preload("res://assets/sprites/fighters/ali/ali.png")
	profile.atlas_data_path = "res://assets/sprites/fighters/ali/ali_atlas.json"
	profile.display_to_frame_name = {
		"idle": "ALI (walk) 0.aseprite",
		"walk_0": "ALI (walk) 0.aseprite",
		"walk_1": "ALI (walk) 1.aseprite",
		"walk_2": "ALI (walk) 2.aseprite",
		"run_0": "ALI (Run) 0.aseprite",
		"run_1": "ALI (Run) 1.aseprite",
		"run_2": "ALI (Run) 2.aseprite",
		"run_3": "ALI (Run) 3.aseprite",
		"run_4": "ALI (Run) 4.aseprite",
		"run_5": "ALI (Run) 5.aseprite",
		"jump_0": "ALI (jump) 0.aseprite",
		"jump_1": "ALI (jump) 1.aseprite",
		"jump_2": "ALI (jump) 0.aseprite",
		"jump_punch_0": "ALI (Punch) 0.aseprite",
		"jump_punch_1": "ALI (Punch) 1.aseprite",
		"jump_punch_2": "ALI (Punch) 2.aseprite",
		"jump_kick_0": "ALI (kick) 0.aseprite",
		"jump_kick_1": "ALI (kick) 1.aseprite",
		"jump_kick_2": "ALI (kick) 1.aseprite",
		"punch_0": "ALI (Punch) 0.aseprite",
		"punch_1": "ALI (Punch) 1.aseprite",
		"punch_2": "ALI (Punch) 2.aseprite",
		"kick_0": "ALI (kick) 0.aseprite",
		"kick_1": "ALI (kick) 1.aseprite",
		"attack_start": "ALI (Punch) 0.aseprite",
		"attack_hold": "ALI (Punch) 1.aseprite",
		"attack_recover": "ALI (Punch) 2.aseprite",
		"run_punch_0": "ALI (RunPunch) 0.aseprite",
		"run_punch_1": "ALI (RunPunch) 1.aseprite",
		"run_kick_0": "ALI (Runkick) 0.aseprite",
		"launch_0": "ALI (Launch) 0.aseprite",
		"launch_1": "ALI (Launch) 1.aseprite",
		"launch_2": "ALI (Launch) 2.aseprite",
		"grapple_0": "ALI (Grapple) 0.aseprite",
		"grapple_throw_0": "ALI (FrontGrappleThrow) 0.aseprite",
		"grapple_throw_1": "ALI (FrontGrappleThrow) 1.aseprite",
		"grapple_throw_2": "ALI (FrontGrappleThrow) 2.aseprite",
		"grapple_throw_3": "ALI (FrontGrappleThrow) 3.aseprite",
		"grapple_throw_4": "ALI (FrontGrappleThrow) 4.aseprite",
		"grapple_throw_5": "ALI (FrontGrappleThrow) 5.aseprite",
		"front_grapple_punch_0": "ALI (FrontGrappleThrow) 0.aseprite",
		"front_grapple_punch_1": "ALI (FrontGrappleThrow) 1.aseprite",
		"front_grapple_punch_2": "ALI (FrontGrappleThrow) 2.aseprite",
		"front_grapple_punch_3": "ALI (FrontGrappleThrow) 3.aseprite",
		"front_grapple_punch_4": "ALI (FrontGrappleThrow) 4.aseprite",
		"knockdown_0": "ALI (EdgeFall) 0.aseprite",
		"knockdown_1": "ALI (TwistedDown) 0.aseprite",
		"knockdown_2": "ALI (TwistedDown) 1.aseprite",
		"knockdown_3": "ALI (TwistedDown) 2.aseprite",
		"knockdown_4": "ALI (jump) 0.aseprite",
		"hurt": "ALI (Hurt) 0.aseprite",
		"breath_0": "ALI (Breath) 0.aseprite",
		"breath_1": "ALI (Breath) 1.aseprite",
		"breath_invulnerable_0": "ALI (Breath) 0.aseprite",
		"breath_invulnerable_1": "ALI (Breath) 1.aseprite",
	}
	profile.fallback_frame_name = "ALI (walk) 0.aseprite"
	profile.sprite_scale = Vector2(2.0, 2.0)
	profile.sprite_offset = Vector2(0.0, -16.0)

	var definition = FighterDefinitionScript.new()
	definition.fighter_id = &"ali"
	definition.display_name = "ALI"
	definition.move_resource_map = COMMON_MOVE_RESOURCE_PATHS.duplicate(true)
	definition.visual_profile = profile
	return definition
