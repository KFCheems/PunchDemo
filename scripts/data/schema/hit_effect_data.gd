class_name HitEffectData
extends Resource

enum HitMode {
	SINGLE,
	MULTI,
}

@export var damage: int = 1
@export var hitstun_ticks: int = 12
@export var knockback_per_tick: Vector2 = Vector2(1.0, 0.0)
@export var knockback_ticks: int = 6
@export_enum("single", "multi") var hit_mode: int = HitMode.SINGLE
@export var rehit_interval_ticks: int = 0
@export var post_hurt_move_name: StringName = &""

func get_mode_name() -> StringName:
	return &"single" if hit_mode == HitMode.SINGLE else &"multi"

func get_return_move_name(default_move_name: StringName) -> StringName:
	if post_hurt_move_name != &"":
		return post_hurt_move_name
	return default_move_name
