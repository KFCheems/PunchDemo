class_name FighterVisual
extends Node2D

const SPRITE_TEXTURE = preload("res://assets/Sprite/ALI-b/ALI.png")
const ATLAS_DATA_PATH := "res://assets/Sprite/ALI-b/ALI-B.json"
const DISPLAY_TO_FRAME_NAME := {
	"idle": "ALI (walk) 0.aseprite",
	"walk_0": "ALI (walk) 0.aseprite",
	"walk_1": "ALI (walk) 1.aseprite",
	"walk_2": "ALI (walk) 2.aseprite",
	"run_0": "ALI (Run) 0.aseprite",
	"run_1": "ALI (Run) 1.aseprite",
	"run_2": "ALI (Run) 2.aseprite",
	"run_3": "ALI (Run) 3.aseprite",
	"run_4": "ALI (Run) 4.aseprite",
	"run_5": "ALI (Run) 5.aseprite",
	"jump_0": "ALI (jump) 0.aseprite",
	"jump_1": "ALI (jump) 1.aseprite",
	"jump_2": "ALI (jump) 0.aseprite",
	"punch_0": "ALI (Punch) 0.aseprite",
	"punch_1": "ALI (Punch) 1.aseprite",
	"punch_2": "ALI (Punch) 2.aseprite",
	"kick_0": "ALI (kick) 0.aseprite",
	"kick_1": "ALI (kick) 1.aseprite",
	"attack_start": "ALI (Punch) 0.aseprite",
	"attack_hold": "ALI (Punch) 1.aseprite",
	"attack_recover": "ALI (Punch) 2.aseprite",
	"run_punch_0": "ALI (RunPunch) 0.aseprite",
	"run_punch_1": "ALI (RunPunch) 1.aseprite",
	"run_kick_0": "ALI (Runkick) 0.aseprite",
	"launch_0": "ALI (Launch) 0.aseprite",
	"launch_1": "ALI (Launch) 1.aseprite",
	"launch_2": "ALI (Launch) 2.aseprite",
	"grapple_0": "ALI (Grapple) 0.aseprite",
	"grapple_throw_0": "ALI (FrontGrappleThrow) 0.aseprite",
	"grapple_throw_1": "ALI (FrontGrappleThrow) 1.aseprite",
	"grapple_throw_2": "ALI (FrontGrappleThrow) 2.aseprite",
	"grapple_throw_3": "ALI (FrontGrappleThrow) 3.aseprite",
	"grapple_throw_4": "ALI (FrontGrappleThrow) 4.aseprite",
	"grapple_throw_5": "ALI (FrontGrappleThrow) 5.aseprite",
	"hurt": "ALI (Hurt) 0.aseprite",
	"breath_0": "ALI (Breath) 0.aseprite",
	"breath_1": "ALI (Breath) 1.aseprite",
	"breath_invulnerable_0": "ALI (Breath) 0.aseprite",
	"breath_invulnerable_1": "ALI (Breath) 1.aseprite",
}
const FALLBACK_FRAME_NAME := "ALI (walk) 0.aseprite"
const FALLBACK_RECT := Rect2(0, 0, 32, 32)
const SHADOW_BASE_RADIUS := 11.0
const SHADOW_SQUASH_SCALE := Vector2(1.9, 0.55)
const SHADOW_BASE_OFFSET := Vector2(0.0, 4.0)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.28)
const SHADOW_MIN_SCALE := 0.45
const SHADOW_FADE_HEIGHT := 52.0

static var _atlas_frame_rects: Dictionary = {}
static var _atlas_loaded: bool = false

var controller = null

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	if controller == null:
		controller = get_parent()
	_ensure_atlas_loaded()
	refresh_visual()

func bind_controller(value) -> void:
	controller = value
	_ensure_atlas_loaded()
	refresh_visual()

func refresh_visual() -> void:
	if controller == null:
		return
	position = controller.get_visual_offset()
	if sprite != null:
		sprite.texture = SPRITE_TEXTURE
		sprite.hframes = 1
		sprite.vframes = 1
		sprite.region_enabled = true
		sprite.region_rect = _get_region_rect()
		sprite.centered = true
		sprite.scale = Vector2(2.0, 2.0)
		sprite.offset = Vector2(0.0, -16.0)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.flip_h = controller.facing < 0
	queue_redraw()

func _draw() -> void:
	if controller == null:
		return

	_draw_ground_shadow()

	for hurtbox in controller.get_debug_local_hurtboxes():
		draw_rect(hurtbox, Color(0.2, 0.9, 1.0, 0.9), false, 2.0)

	for hitbox_info in controller.get_debug_local_hitboxes():
		var hit_rect: Rect2 = hitbox_info["rect"]
		draw_rect(hit_rect, Color(1.0, 0.3, 0.2, 0.25), true)
		draw_rect(hit_rect, Color(1.0, 0.4, 0.2, 0.95), false, 2.0)

	_draw_facing_marker()

func _draw_ground_shadow() -> void:
	var visual_offset: Vector2 = controller.get_visual_offset()
	var height: float = maxf(-visual_offset.y, 0.0)
	var scale_ratio: float = clampf(1.0 - (height / SHADOW_FADE_HEIGHT) * 0.55, SHADOW_MIN_SCALE, 1.0)
	var shadow_center: Vector2 = Vector2(SHADOW_BASE_OFFSET.x - visual_offset.x, SHADOW_BASE_OFFSET.y - visual_offset.y)
	var shadow_scale: Vector2 = Vector2(SHADOW_SQUASH_SCALE.x * scale_ratio, SHADOW_SQUASH_SCALE.y * scale_ratio)
	draw_set_transform(shadow_center, 0.0, shadow_scale)
	draw_circle(Vector2.ZERO, SHADOW_BASE_RADIUS, SHADOW_COLOR)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _get_region_rect() -> Rect2:
	if controller == null:
		return FALLBACK_RECT
	_ensure_atlas_loaded()
	var display_id := String(controller.get_display_id())
	var frame_name: String = DISPLAY_TO_FRAME_NAME.get(display_id, FALLBACK_FRAME_NAME)
	return _atlas_frame_rects.get(frame_name, FALLBACK_RECT)

func _draw_facing_marker() -> void:
	draw_line(Vector2.ZERO, Vector2(32.0 * controller.facing, -16.0), Color(1.0, 1.0, 1.0, 0.9), 2.0)
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 1.0, 0.9))

func _ensure_atlas_loaded() -> void:
	if _atlas_loaded:
		return
	_atlas_loaded = true
	var file := FileAccess.open(ATLAS_DATA_PATH, FileAccess.READ)
	if file == null:
		return
	var json_text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(json_text) != OK:
		return
	var data = json.data
	if not (data is Dictionary):
		return
	var frames = data.get("frames", {})
	if not (frames is Dictionary):
		return
	for frame_name in frames.keys():
		var frame_entry = frames[frame_name]
		if not (frame_entry is Dictionary):
			continue
		var frame_rect_data = frame_entry.get("frame", {})
		if not (frame_rect_data is Dictionary):
			continue
		_atlas_frame_rects[frame_name] = Rect2(
			float(frame_rect_data.get("x", 0)),
			float(frame_rect_data.get("y", 0)),
			float(frame_rect_data.get("w", 32)),
			float(frame_rect_data.get("h", 32))
		)
