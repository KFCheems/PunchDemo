class_name HitResolver
extends RefCounted

var _hit_history: Dictionary = {}

func clear() -> void:
	_hit_history.clear()

func resolve_attacker(attacker, targets: Array, combat_tick: int) -> Array:
	var events: Array = []
	if attacker == null:
		return events

	var hitboxes: Array = attacker.get_active_hitboxes()
	if hitboxes.is_empty():
		return events

	for target in targets:
		if target == null or target == attacker:
			continue
		var event := _resolve_target(attacker, target, hitboxes, combat_tick)
		if not event.is_empty():
			events.append(event)
	return events

func _resolve_target(attacker, target, hitboxes: Array, combat_tick: int) -> Dictionary:
	var hurtboxes: Array = target.get_active_hurtboxes()
	if hurtboxes.is_empty():
		return {}

	for hitbox_info in hitboxes:
		var hit_rect: Rect2 = hitbox_info["rect"]
		var effect: HitEffectData = hitbox_info["effect"]
		for hurt_rect in hurtboxes:
			if not hit_rect.intersects(hurt_rect):
				continue
			if not _can_apply_hit(attacker, target, effect, combat_tick):
				return {}
			_record_hit(attacker, target, combat_tick)
			target.receive_hit(effect, attacker)
			return {
				"tick": combat_tick,
				"attacker": attacker.fighter_name,
				"target": target.fighter_name,
				"mode": String(effect.get_mode_name()),
				"damage": effect.damage,
			}
	return {}

func _can_apply_hit(attacker, target, effect: HitEffectData, combat_tick: int) -> bool:
	var key := _make_key(attacker, target)
	if not _hit_history.has(key):
		return true

	var last_hit_tick: int = _hit_history[key]
	if effect.hit_mode == HitEffectData.HitMode.SINGLE:
		return false

	return combat_tick - last_hit_tick >= max(effect.rehit_interval_ticks, 1)

func _record_hit(attacker, target, combat_tick: int) -> void:
	_hit_history[_make_key(attacker, target)] = combat_tick

func _make_key(attacker, target) -> String:
	return "%s|%s|%s" % [
		str(attacker.get_instance_id()),
		str(attacker.get_move_instance_id()),
		str(target.get_instance_id()),
	]
