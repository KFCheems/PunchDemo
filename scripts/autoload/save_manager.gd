extends Node

const SAVE_PATH := "user://settings.cfg"

var settings: Dictionary = {}

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		settings = {}
		return
	settings = config.get_value("settings", "values", {})

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "values", settings)
	config.save(SAVE_PATH)

func get_setting(key: StringName, default_value = null):
	return settings.get(key, default_value)

func set_setting(key: StringName, value) -> void:
	settings[key] = value
	save_settings()
