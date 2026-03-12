class_name DemoMoveLibrary
extends RefCounted

const MoveDataResource = preload("res://scripts/data/schema/move_data.gd")
const FrameDataResource = preload("res://scripts/data/schema/frame_data.gd")
const HitboxDataResource = preload("res://scripts/data/schema/hitbox_data.gd")
const HurtboxDataResource = preload("res://scripts/data/schema/hurtbox_data.gd")
const HitEffectDataResource = preload("res://scripts/data/schema/hit_effect_data.gd")
const DemoTuningScript = preload("res://scripts/data/demo_tuning.gd")
const BREATH_FRAME_TICKS := 12

static func create_library() -> Dictionary:
	return {
		&"idle": build_idle_move(),
		&"walk": build_walk_move(),
		&"run": build_run_move(),
		&"jump": build_jump_move(),
		&"punch": build_punch_move(),
		&"kick": build_kick_move(),
		&"run_punch": build_run_punch_move(),
		&"run_kick": build_run_kick_move(),
		&"launch": build_launch_move(),
		&"grapple": build_grapple_move(),
		&"grapple_throw": build_grapple_throw_move(),
		&"front_grapple_punch": build_front_grapple_punch_move(),
		&"knockdown": build_knockdown_move(),
		&"breath": build_breath_move(),
		&"breath_invulnerable": build_breath_invulnerable_move(),
		&"attack_single": build_attack_move(&"attack_single", HitEffectDataResource.HitMode.SINGLE, 0),
		&"attack_multi": build_attack_move(&"attack_multi", HitEffectDataResource.HitMode.MULTI, 30),
	}

static func build_idle_move():
	var hurtbox = _make_default_hurtbox()
	var frame = FrameDataResource.new()
	frame.display_id = &"idle"
	frame.duration_ticks = 1
	frame.interruptible = true
	frame.cancelable = true
	frame.interrupt_window_start_tick = 0
	frame.interrupt_window_end_tick = 0
	frame.cancel_window_start_tick = 0
	frame.cancel_window_end_tick = 0
	frame.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"idle"
	move.state_tag = MoveDataResource.StateTag.IDLE
	move.loop = true
	move.return_to = &"idle"
	move.frames = [frame]
	return move

static func build_walk_move():
	var hurtbox = _make_default_hurtbox()
	var frame_a = FrameDataResource.new()
	frame_a.display_id = &"walk_0"
	frame_a.duration_ticks = 6
	frame_a.interruptible = true
	frame_a.cancelable = true
	frame_a.hurtboxes = [hurtbox]

	var frame_b = FrameDataResource.new()
	frame_b.display_id = &"walk_1"
	frame_b.duration_ticks = 6
	frame_b.interruptible = true
	frame_b.cancelable = true
	frame_b.hurtboxes = [hurtbox]

	var frame_c = FrameDataResource.new()
	frame_c.display_id = &"walk_2"
	frame_c.duration_ticks = 6
	frame_c.interruptible = true
	frame_c.cancelable = true
	frame_c.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"walk"
	move.state_tag = MoveDataResource.StateTag.IDLE
	move.loop = true
	move.return_to = &"idle"
	move.frames = [frame_a, frame_b, frame_c]
	return move

static func build_hurt_move(hitstun_ticks: int):
	var hurtbox = _make_default_hurtbox()
	var frame = FrameDataResource.new()
	frame.display_id = &"hurt"
	frame.duration_ticks = max(hitstun_ticks, 1)
	frame.interruptible = false
	frame.cancelable = false
	frame.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"hurt"
	move.state_tag = MoveDataResource.StateTag.HURT
	move.loop = false
	move.return_to = &"idle"
	move.frames = [frame]
	return move

static func build_breath_move():
	var move = MoveDataResource.new()
	move.move_name = &"breath"
	move.state_tag = MoveDataResource.StateTag.IDLE
	move.loop = false
	move.return_to = &"breath_invulnerable"
	move.frames = _build_repeated_display_frames([&"breath_0", &"breath_1"], DemoTuningScript.POST_HURT_BREATH_OPEN_TICKS, true, true)
	return move

static func build_breath_invulnerable_move():
	var move = MoveDataResource.new()
	move.move_name = &"breath_invulnerable"
	move.state_tag = MoveDataResource.StateTag.IDLE
	move.loop = false
	move.return_to = &"idle"
	move.invulnerable = true
	move.frames = _build_repeated_display_frames([&"breath_invulnerable_0", &"breath_invulnerable_1"], DemoTuningScript.POST_HURT_BREATH_INVULNERABLE_TICKS, false, false)
	return move

static func build_launch_move():
	var hurtbox = _make_default_hurtbox()

	var startup = FrameDataResource.new()
	startup.display_id = &"launch_0"
	startup.duration_ticks = DemoTuningScript.ATTACK_LAUNCH_STARTUP_TICKS
	startup.interruptible = false
	startup.cancelable = false
	startup.hurtboxes = [hurtbox]

	var active = FrameDataResource.new()
	active.display_id = &"launch_1"
	active.duration_ticks = DemoTuningScript.ATTACK_LAUNCH_ACTIVE_TICKS
	active.interruptible = false
	active.cancelable = false
	active.hurtboxes = [hurtbox]
	active.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_LAUNCH_HITBOX_POSITION, DemoTuningScript.ATTACK_LAUNCH_HITBOX_SIZE, DemoTuningScript.ATTACK_LAUNCH_DAMAGE, DemoTuningScript.ATTACK_LAUNCH_HITSTUN_TICKS, DemoTuningScript.ATTACK_LAUNCH_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_LAUNCH_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.SINGLE, 0, &"idle")]

	var recovery = FrameDataResource.new()
	recovery.display_id = &"launch_2"
	recovery.duration_ticks = DemoTuningScript.ATTACK_LAUNCH_RECOVERY_TICKS
	recovery.interruptible = false
	recovery.cancelable = false
	recovery.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"launch"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup, active, recovery]
	return move

static func build_grapple_move():
	var hurtbox = _make_default_hurtbox()

	var startup = FrameDataResource.new()
	startup.display_id = &"grapple_0"
	startup.duration_ticks = 4
	startup.interruptible = false
	startup.cancelable = false
	startup.hurtboxes = [hurtbox]

	var hold = FrameDataResource.new()
	hold.display_id = &"grapple_0"
	hold.duration_ticks = DemoTuningScript.GRAPPLE_HOLD_TIMEOUT_TICKS
	hold.interruptible = true
	hold.cancelable = true
	hold.cancel_window_start_tick = 0
	hold.cancel_window_end_tick = hold.duration_ticks - 1
	hold.interrupt_window_start_tick = 0
	hold.interrupt_window_end_tick = hold.duration_ticks - 1
	hold.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"grapple"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup, hold]
	return move

static func build_grapple_throw_move():
	var hurtbox = _make_default_hurtbox()

	var startup_a = FrameDataResource.new()
	startup_a.display_id = &"grapple_throw_0"
	startup_a.duration_ticks = 4
	startup_a.interruptible = false
	startup_a.cancelable = false
	startup_a.hurtboxes = [hurtbox]

	var startup_b = FrameDataResource.new()
	startup_b.display_id = &"grapple_throw_1"
	startup_b.duration_ticks = 4
	startup_b.interruptible = false
	startup_b.cancelable = false
	startup_b.hurtboxes = [hurtbox]

	var active = FrameDataResource.new()
	active.display_id = &"grapple_throw_2"
	active.duration_ticks = 4
	active.interruptible = false
	active.cancelable = false
	active.hurtboxes = [hurtbox]
	active.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_GRAPPLE_THROW_HITBOX_POSITION, DemoTuningScript.ATTACK_GRAPPLE_THROW_HITBOX_SIZE, DemoTuningScript.ATTACK_GRAPPLE_THROW_DAMAGE, DemoTuningScript.ATTACK_GRAPPLE_THROW_HITSTUN_TICKS, DemoTuningScript.ATTACK_GRAPPLE_THROW_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_GRAPPLE_THROW_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.SINGLE, 0, &"idle")]

	var recovery_frames: Array = []
	for frame_index in range(3, 6):
		var frame = FrameDataResource.new()
		frame.display_id = StringName("grapple_throw_%d" % frame_index)
		frame.duration_ticks = 4
		frame.interruptible = false
		frame.cancelable = false
		frame.hurtboxes = [hurtbox]
		recovery_frames.append(frame)

	var move = MoveDataResource.new()
	move.move_name = &"grapple_throw"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup_a, startup_b, active] + recovery_frames
	return move

static func build_front_grapple_punch_move():
	var hurtbox = _make_default_hurtbox()

	var startup_a = FrameDataResource.new()
	startup_a.display_id = &"front_grapple_punch_0"
	startup_a.duration_ticks = 4
	startup_a.interruptible = false
	startup_a.cancelable = false
	startup_a.hurtboxes = [hurtbox]

	var startup_b = FrameDataResource.new()
	startup_b.display_id = &"front_grapple_punch_1"
	startup_b.duration_ticks = 4
	startup_b.interruptible = false
	startup_b.cancelable = false
	startup_b.hurtboxes = [hurtbox]

	var first_hit = FrameDataResource.new()
	first_hit.display_id = &"front_grapple_punch_2"
	first_hit.duration_ticks = 3
	first_hit.interruptible = false
	first_hit.cancelable = false
	first_hit.hurtboxes = [hurtbox]
	first_hit.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_HITBOX_POSITION, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_HITBOX_SIZE, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_FIRST_DAMAGE, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_FIRST_HITSTUN_TICKS, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_FIRST_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_FIRST_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.MULTI, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_REHIT_INTERVAL_TICKS)]

	var second_hit = FrameDataResource.new()
	second_hit.display_id = &"front_grapple_punch_3"
	second_hit.duration_ticks = 4
	second_hit.interruptible = false
	second_hit.cancelable = false
	second_hit.hurtboxes = [hurtbox]
	second_hit.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_HITBOX_POSITION, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_HITBOX_SIZE, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_SECOND_DAMAGE, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_SECOND_HITSTUN_TICKS, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_SECOND_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_SECOND_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.MULTI, DemoTuningScript.ATTACK_FRONT_GRAPPLE_PUNCH_REHIT_INTERVAL_TICKS, &"knockdown")]

	var recovery = FrameDataResource.new()
	recovery.display_id = &"front_grapple_punch_3"
	recovery.duration_ticks = 6
	recovery.interruptible = false
	recovery.cancelable = false
	recovery.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"front_grapple_punch"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup_a, startup_b, first_hit, second_hit, recovery]
	return move

static func build_knockdown_move():
	var hurtbox = _make_default_hurtbox()
	var frames: Array = []
	var displays: Array[StringName] = [&"knockdown_0", &"knockdown_1", &"knockdown_2", &"knockdown_3", &"knockdown_3", &"knockdown_4"]
	var durations: Array[int] = [DemoTuningScript.KNOCKDOWN_EDGE_FALL_TICKS, DemoTuningScript.KNOCKDOWN_TWISTED_DOWN_A_TICKS, DemoTuningScript.KNOCKDOWN_TWISTED_DOWN_B_TICKS, DemoTuningScript.KNOCKDOWN_TWISTED_DOWN_C_TICKS, DemoTuningScript.KNOCKDOWN_GROUNDED_HOLD_TICKS, DemoTuningScript.KNOCKDOWN_GETUP_CROUCH_TICKS]
	for index in range(displays.size()):
		var frame = FrameDataResource.new()
		frame.display_id = displays[index]
		frame.duration_ticks = durations[index]
		frame.interruptible = false
		frame.cancelable = false
		frame.hurtboxes = [hurtbox]
		frames.append(frame)

	var move = MoveDataResource.new()
	move.move_name = &"knockdown"
	move.state_tag = MoveDataResource.StateTag.HURT
	move.loop = false
	move.return_to = &"idle"
	move.frames = frames
	return move

static func build_jump_move():
	var hurtbox = _make_default_hurtbox()

	var takeoff = FrameDataResource.new()
	takeoff.display_id = &"jump_0"
	takeoff.duration_ticks = DemoTuningScript.JUMP_FRAME_TAKEOFF_TICKS
	takeoff.interruptible = false
	takeoff.cancelable = false
	takeoff.hurtboxes = [hurtbox]

	var airborne = FrameDataResource.new()
	airborne.display_id = &"jump_1"
	airborne.duration_ticks = DemoTuningScript.JUMP_FRAME_AIR_HOLD_TICKS
	airborne.interruptible = false
	airborne.cancelable = false
	airborne.hurtboxes = [hurtbox]

	var landing = FrameDataResource.new()
	landing.display_id = &"jump_2"
	landing.duration_ticks = DemoTuningScript.JUMP_FRAME_LANDING_TICKS
	landing.interruptible = false
	landing.cancelable = false
	landing.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"jump"
	move.state_tag = MoveDataResource.StateTag.AIR
	move.loop = false
	move.return_to = &"idle"
	move.frames = [takeoff, airborne, landing]
	return move

static func build_run_move():
	var hurtbox = _make_default_hurtbox()
	var frames: Array = []
	for index in range(6):
		var frame = FrameDataResource.new()
		frame.display_id = StringName("run_%d" % index)
		frame.duration_ticks = 4
		frame.interruptible = true
		frame.cancelable = true
		frame.hurtboxes = [hurtbox]
		frames.append(frame)

	var move = MoveDataResource.new()
	move.move_name = &"run"
	move.state_tag = MoveDataResource.StateTag.IDLE
	move.loop = true
	move.return_to = &"idle"
	move.frames = frames
	return move

static func build_punch_move():
	var hurtbox = _make_default_hurtbox()

	var startup = FrameDataResource.new()
	startup.display_id = &"punch_0"
	startup.duration_ticks = DemoTuningScript.ATTACK_PUNCH_STARTUP_TICKS
	startup.interruptible = false
	startup.cancelable = false
	startup.hurtboxes = [hurtbox]

	var active = FrameDataResource.new()
	active.display_id = &"punch_1"
	active.duration_ticks = DemoTuningScript.ATTACK_PUNCH_ACTIVE_TICKS
	active.interruptible = false
	active.cancelable = false
	active.hurtboxes = [hurtbox]
	active.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_PUNCH_HITBOX_POSITION, DemoTuningScript.ATTACK_PUNCH_HITBOX_SIZE, DemoTuningScript.ATTACK_PUNCH_DAMAGE, DemoTuningScript.ATTACK_PUNCH_HITSTUN_TICKS, DemoTuningScript.ATTACK_PUNCH_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_PUNCH_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.SINGLE, 0)]

	var recovery = FrameDataResource.new()
	recovery.display_id = &"punch_2"
	recovery.duration_ticks = DemoTuningScript.ATTACK_PUNCH_RECOVERY_TICKS
	recovery.interruptible = false
	recovery.cancelable = true
	recovery.cancel_window_start_tick = 0
	recovery.cancel_window_end_tick = recovery.duration_ticks - 1
	recovery.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"punch"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup, active, recovery]
	return move

static func build_kick_move():
	var hurtbox = _make_default_hurtbox()

	var startup = FrameDataResource.new()
	startup.display_id = &"kick_0"
	startup.duration_ticks = DemoTuningScript.ATTACK_KICK_STARTUP_TICKS
	startup.interruptible = false
	startup.cancelable = false
	startup.hurtboxes = [hurtbox]

	var active = FrameDataResource.new()
	active.display_id = &"kick_1"
	active.duration_ticks = DemoTuningScript.ATTACK_KICK_ACTIVE_TICKS
	active.interruptible = false
	active.cancelable = false
	active.hurtboxes = [hurtbox]
	active.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_KICK_HITBOX_POSITION, DemoTuningScript.ATTACK_KICK_HITBOX_SIZE, DemoTuningScript.ATTACK_KICK_DAMAGE, DemoTuningScript.ATTACK_KICK_HITSTUN_TICKS, DemoTuningScript.ATTACK_KICK_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_KICK_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.SINGLE, 0)]

	var recovery = FrameDataResource.new()
	recovery.display_id = &"kick_1"
	recovery.duration_ticks = DemoTuningScript.ATTACK_KICK_RECOVERY_TICKS
	recovery.interruptible = false
	recovery.cancelable = true
	recovery.cancel_window_start_tick = 0
	recovery.cancel_window_end_tick = recovery.duration_ticks - 1
	recovery.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"kick"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup, active, recovery]
	return move

static func build_run_punch_move():
	var hurtbox = _make_default_hurtbox()

	var startup_a = FrameDataResource.new()
	startup_a.display_id = &"run_0"
	startup_a.duration_ticks = DemoTuningScript.ATTACK_RUN_PUNCH_STARTUP_A_TICKS
	startup_a.interruptible = false
	startup_a.cancelable = false
	startup_a.hurtboxes = [hurtbox]

	var startup_b = FrameDataResource.new()
	startup_b.display_id = &"run_1"
	startup_b.duration_ticks = DemoTuningScript.ATTACK_RUN_PUNCH_STARTUP_B_TICKS
	startup_b.interruptible = false
	startup_b.cancelable = false
	startup_b.hurtboxes = [hurtbox]

	var active = FrameDataResource.new()
	active.display_id = &"run_punch_0"
	active.duration_ticks = DemoTuningScript.ATTACK_RUN_PUNCH_ACTIVE_TICKS
	active.interruptible = false
	active.cancelable = false
	active.hurtboxes = [hurtbox]
	active.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_RUN_PUNCH_HITBOX_POSITION, DemoTuningScript.ATTACK_RUN_PUNCH_HITBOX_SIZE, DemoTuningScript.ATTACK_RUN_PUNCH_DAMAGE, DemoTuningScript.ATTACK_RUN_PUNCH_HITSTUN_TICKS, DemoTuningScript.ATTACK_RUN_PUNCH_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_RUN_PUNCH_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.SINGLE, 0)]

	var recovery = FrameDataResource.new()
	recovery.display_id = &"run_punch_1"
	recovery.duration_ticks = DemoTuningScript.ATTACK_RUN_PUNCH_RECOVERY_TICKS
	recovery.interruptible = false
	recovery.cancelable = false
	recovery.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"run_punch"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup_a, startup_b, active, recovery]
	return move

static func build_run_kick_move():
	var hurtbox = _make_default_hurtbox()

	var startup_a = FrameDataResource.new()
	startup_a.display_id = &"run_2"
	startup_a.duration_ticks = DemoTuningScript.ATTACK_RUN_KICK_STARTUP_A_TICKS
	startup_a.interruptible = false
	startup_a.cancelable = false
	startup_a.hurtboxes = [hurtbox]

	var startup_b = FrameDataResource.new()
	startup_b.display_id = &"run_3"
	startup_b.duration_ticks = DemoTuningScript.ATTACK_RUN_KICK_STARTUP_B_TICKS
	startup_b.interruptible = false
	startup_b.cancelable = false
	startup_b.hurtboxes = [hurtbox]

	var active = FrameDataResource.new()
	active.display_id = &"run_kick_0"
	active.duration_ticks = DemoTuningScript.ATTACK_RUN_KICK_ACTIVE_TICKS
	active.interruptible = false
	active.cancelable = false
	active.hurtboxes = [hurtbox]
	active.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_RUN_KICK_HITBOX_POSITION, DemoTuningScript.ATTACK_RUN_KICK_HITBOX_SIZE, DemoTuningScript.ATTACK_RUN_KICK_DAMAGE, DemoTuningScript.ATTACK_RUN_KICK_HITSTUN_TICKS, DemoTuningScript.ATTACK_RUN_KICK_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_RUN_KICK_KNOCKBACK_TICKS, HitEffectDataResource.HitMode.SINGLE, 0)]

	var recovery = FrameDataResource.new()
	recovery.display_id = &"run_4"
	recovery.duration_ticks = DemoTuningScript.ATTACK_RUN_KICK_RECOVERY_TICKS
	recovery.interruptible = false
	recovery.cancelable = false
	recovery.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = &"run_kick"
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup_a, startup_b, active, recovery]
	return move

static func build_attack_move(move_name: StringName, hit_mode: int, rehit_interval_ticks: int):
	var hurtbox = _make_default_hurtbox()

	var startup = FrameDataResource.new()
	startup.display_id = &"attack_start"
	startup.duration_ticks = 12
	startup.interruptible = false
	startup.cancelable = false
	startup.hurtboxes = [hurtbox]

	var active = FrameDataResource.new()
	active.display_id = &"attack_hold"
	active.duration_ticks = 180
	active.interruptible = false
	active.cancelable = false
	active.hurtboxes = [hurtbox]
	active.hitboxes = [_make_configured_attack_hitbox(DemoTuningScript.ATTACK_HARNESS_HITBOX_POSITION, DemoTuningScript.ATTACK_HARNESS_HITBOX_SIZE, DemoTuningScript.ATTACK_HARNESS_DAMAGE, DemoTuningScript.ATTACK_HARNESS_HITSTUN_TICKS, DemoTuningScript.ATTACK_HARNESS_KNOCKBACK_PER_TICK, DemoTuningScript.ATTACK_HARNESS_KNOCKBACK_TICKS, hit_mode, rehit_interval_ticks)]

	var recovery = FrameDataResource.new()
	recovery.display_id = &"attack_recover"
	recovery.duration_ticks = 12
	recovery.interruptible = false
	recovery.cancelable = true
	recovery.cancel_window_start_tick = 0
	recovery.cancel_window_end_tick = recovery.duration_ticks - 1
	recovery.hurtboxes = [hurtbox]

	var move = MoveDataResource.new()
	move.move_name = move_name
	move.state_tag = MoveDataResource.StateTag.ATTACK
	move.loop = false
	move.return_to = &"idle"
	move.frames = [startup, active, recovery]
	return move

static func _make_configured_attack_hitbox(hitbox_position: Vector2, hitbox_size: Vector2, damage: int, hitstun_ticks: int, knockback_per_tick: Vector2, knockback_ticks: int, hit_mode: int, rehit_interval_ticks: int, post_hurt_move_name: StringName = &""):
	var effect = HitEffectDataResource.new()
	effect.damage = damage
	effect.hitstun_ticks = hitstun_ticks
	effect.knockback_per_tick = knockback_per_tick
	effect.knockback_ticks = knockback_ticks
	effect.hit_mode = hit_mode
	effect.rehit_interval_ticks = rehit_interval_ticks
	effect.post_hurt_move_name = post_hurt_move_name

	var hitbox = HitboxDataResource.new()
	hitbox.local_rect = Rect2(hitbox_position, hitbox_size)
	hitbox.effect = effect
	return hitbox

static func _build_repeated_display_frames(display_ids: Array, total_ticks: int, interruptible: bool, cancelable: bool) -> Array:
	var hurtbox = _make_default_hurtbox()
	var frames: Array = []
	var remaining_ticks: int = max(total_ticks, 1)
	var display_count: int = max(display_ids.size(), 1)
	var display_index: int = 0
	while remaining_ticks > 0:
		var frame = FrameDataResource.new()
		frame.display_id = display_ids[display_index % display_count]
		frame.duration_ticks = min(BREATH_FRAME_TICKS, remaining_ticks)
		frame.interruptible = interruptible
		frame.cancelable = cancelable
		frame.hurtboxes = [hurtbox]
		frames.append(frame)
		display_index += 1
		remaining_ticks -= frame.duration_ticks
	return frames

static func _make_default_hurtbox():
	var hurtbox = HurtboxDataResource.new()
	hurtbox.local_rect = Rect2(DemoTuningScript.HURTBOX_DEFAULT_POSITION, DemoTuningScript.HURTBOX_DEFAULT_SIZE)
	return hurtbox
