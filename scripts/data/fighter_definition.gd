class_name FighterDefinition
extends Resource

const FighterVisualProfileScript = preload("res://scripts/data/fighter_visual_profile.gd")

@export var fighter_id: StringName = &"fighter"
@export var display_name: String = "Fighter"
@export var move_resource_map: Dictionary = {}
@export var visual_profile: FighterVisualProfileScript
