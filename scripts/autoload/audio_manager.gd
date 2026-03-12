extends Node

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BGMPlayer"
	add_child(_bgm_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.name = "SFXPlayer"
	add_child(_sfx_player)

func play_bgm(stream_path: String) -> void:
	if stream_path == "":
		stop_bgm()
		return
	var stream := load(stream_path)
	if stream == null:
		return
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
	_bgm_player.stream = stream
	_bgm_player.volume_db = -10.0
	_bgm_player.play()

func stop_bgm() -> void:
	if _bgm_player == null:
		return
	_bgm_player.stop()
	_bgm_player.stream = null

func play_sfx(stream_path: String) -> void:
	if stream_path == "":
		return
	var stream := load(stream_path)
	if stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.play()
