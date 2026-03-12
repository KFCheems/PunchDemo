extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var hint_label: Label = $MarginContainer/VBoxContainer/HintLabel
@onready var event_label: Label = $MarginContainer/VBoxContainer/EventLabel

func _ready() -> void:
	title_label.text = "Formal Battle"
	hint_label.text = "WASD / arrows move, Space jump, J punch, K kick, Esc result screen."
	set_last_event("")

func update_hud(attacker, dummy, tick: int) -> void:
	if attacker == null or dummy == null:
		status_label.text = "Waiting for fighters..."
		return
	status_label.text = "%s HP %d  |  %s HP %d  |  Tick %d" % [attacker.fighter_name, attacker.health, dummy.fighter_name, dummy.health, tick]

func set_last_event(event_text: String) -> void:
	if event_text == "":
		event_label.text = "Last event: none"
		return
	event_label.text = "Last event: %s" % event_text
