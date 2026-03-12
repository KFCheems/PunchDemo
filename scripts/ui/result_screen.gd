extends Control

@onready var result_label: Label = $MarginContainer/VBoxContainer/ResultLabel
@onready var detail_label: Label = $MarginContainer/VBoxContainer/DetailLabel
@onready var rematch_button: Button = $MarginContainer/VBoxContainer/Buttons/RematchButton
@onready var menu_button: Button = $MarginContainer/VBoxContainer/Buttons/MenuButton

func _ready() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	var result: Dictionary = {}
	if game_manager != null:
		result = game_manager.get_last_result()
	result_label.text = String(result.get("winner_text", "Match Complete"))
	detail_label.text = String(result.get("detail_text", "Press Rematch to return to battle or Main Menu to leave."))
	rematch_button.pressed.connect(_on_rematch_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

func _on_rematch_pressed() -> void:
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.start_battle()

func _on_menu_pressed() -> void:
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.go_to_main_menu()
