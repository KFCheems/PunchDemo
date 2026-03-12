extends Node

const BOOT_SCENE := "res://scenes/boot/boot.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle_scene.tscn"
const RESULT_SCENE := "res://scenes/ui/result_screen.tscn"
const SANDBOX_SCENE := "res://scenes/debug/battle_sandbox.tscn"

func go_to_boot() -> void:
	_change_scene(BOOT_SCENE)

func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)

func start_battle() -> void:
	_change_scene(BATTLE_SCENE)

func go_to_result_screen() -> void:
	_change_scene(RESULT_SCENE)

func go_to_sandbox() -> void:
	_change_scene(SANDBOX_SCENE)

func _change_scene(scene_path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", scene_path)
