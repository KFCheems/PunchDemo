extends Camera2D

func sync_to_fighters(attacker, dummy) -> void:
	if attacker == null or dummy == null:
		return
	global_position = (attacker.global_position + dummy.global_position) * 0.5 + Vector2(0.0, -40.0)
