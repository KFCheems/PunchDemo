class_name FighterVisualProfile
extends Resource

@export var fighter_id: StringName = &"fighter"
@export var texture: Texture2D
@export_file("*.json") var atlas_data_path: String = ""
@export var display_to_frame_name: Dictionary = {}
@export var fallback_frame_name: String = ""
@export var sprite_scale: Vector2 = Vector2(2.0, 2.0)
@export var sprite_offset: Vector2 = Vector2(0.0, -16.0)
