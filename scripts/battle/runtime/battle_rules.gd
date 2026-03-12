class_name BattleRules
extends RefCounted

const ATTACKER_START := Vector2(260.0, 300.0)
const DUMMY_START := Vector2(360.0, 300.0)
const ROUND_TIME_TICKS := 60 * 99

func get_attacker_start() -> Vector2:
	return ATTACKER_START

func get_dummy_start() -> Vector2:
	return DUMMY_START

func is_match_over(attacker, dummy, tick: int) -> bool:
	if attacker == null or dummy == null:
		return false
	if attacker.health <= 0 or dummy.health <= 0:
		return true
	return tick >= ROUND_TIME_TICKS

func build_result(attacker, dummy, tick: int) -> Dictionary:
	var winner_text := "Draw"
	if attacker.health > dummy.health:
		winner_text = "%s Wins" % attacker.fighter_name
	elif dummy.health > attacker.health:
		winner_text = "%s Wins" % dummy.fighter_name
	var elapsed_seconds: int = int(tick / 60.0)
	return {
		"winner_text": winner_text,
		"detail_text": "Time=%d  %s HP=%d  %s HP=%d" % [elapsed_seconds, attacker.fighter_name, attacker.health, dummy.fighter_name, dummy.health],
		"tick": tick,
	}
