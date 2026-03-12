extends Control

func _ready() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager != null:
		game_manager.configure_default_match()
	var save_manager = get_node_or_null("/root/SaveManager")
	if save_manager != null:
		save_manager.load_settings()
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager != null:
		data_manager.initialize()
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager != null:
		scene_manager.go_to_main_menu()
