extends Control

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $MarginContainer/VBoxContainer/SubtitleLabel
@onready var start_button: Button = $MarginContainer/VBoxContainer/Buttons/StartBattleButton
@onready var sandbox_button: Button = $MarginContainer/VBoxContainer/Buttons/OpenSandboxButton
@onready var quit_button: Button = $MarginContainer/VBoxContainer/Buttons/QuitButton

func _ready() -> void:
	title_label.text = "PunchDemo"
	subtitle_label.text = "Formal shell flow over the existing combat sandbox kernel."
	start_button.pressed.connect(_on_start_battle_pressed)
	sandbox_button.pressed.connect(_on_open_sandbox_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_battle_pressed() -> void:
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.start_battle()

func _on_open_sandbox_pressed() -> void:
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.go_to_sandbox()

func _on_quit_pressed() -> void:
	get_tree().quit()
