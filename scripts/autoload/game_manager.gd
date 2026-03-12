extends Node

var selected_fighter_ids: Array[StringName] = [&"ali", &"ali"]
var selected_stage_id: StringName = &"stage_01"
var selected_mode: StringName = &"versus"
var last_result: Dictionary = {}

func configure_default_match() -> void:
	selected_fighter_ids = [&"ali", &"ali"]
	selected_stage_id = &"stage_01"
	selected_mode = &"versus"

func get_selected_fighter_id(slot: int) -> StringName:
	if slot < 0 or slot >= selected_fighter_ids.size():
		return &"ali"
	return selected_fighter_ids[slot]

func set_last_result(result: Dictionary) -> void:
	last_result = result.duplicate(true)

func get_last_result() -> Dictionary:
	return last_result.duplicate(true)
