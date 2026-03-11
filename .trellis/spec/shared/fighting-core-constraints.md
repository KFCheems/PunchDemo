# Fighting Core Constraints (Godot 4)

## Goal

Recreate the combat kernel of "Nekketsu Kakuto Densetsu" (Kunio-kun) with 1:1 timing-first behavior.  
Outer systems (story mode, UI, menu/meta flow) are deferred.

## Non-Negotiables

- Use fixed-step combat logic at `60 Hz`.
- Treat `MoveData/FrameData` as the single source of truth for combat behavior.
- Do not put core combat logic on `AnimationPlayer` timelines.
- Every frame must be configurable for:
  - display sprite/frame id
  - duration in ticks
  - interrupt/cancel windows
  - hitbox/hurtbox on/off and shape payload
- System must support:
  - single-hit mode
  - multi-hit mode with per-target re-hit interval
  - hurt/hitstun and knockback
  - return to idle after move end
- Demo must include one attack whose active frame is held for `180 ticks` (3 seconds) while hitbox remains continuously valid.

## Architecture Baseline

- Keep modules separated:
  - `input_buffer`
  - `state_machine`
  - `move_runner`
  - `hit_resolver`
- Presentation and logic are decoupled:
  - visual playback reflects frame data
  - combat logic never depends on animation timeline callbacks
- Prefer data-driven rules over hardcoded branching.
- Battle test harness utilities may reuse existing input history and scripted scheduling, but must not rewrite combat core architecture.

## Validation Rules

- Replaying the same input sequence yields consistent results.
- Hit/hurt timing is verifiable at tick granularity.
- All acceptance criteria must be reproducible in a minimal scene.
- If requirements are ambiguous, pause and ask before implementation.
- Live input replay is a validation feature; prefer in-memory snapshots first and do not introduce persistent recording by default.

## Explicitly Out of Scope (P0)

- Story mode, complete UI flow, and cheats/menu systems.
- Full roster and full move list.
- Networking.
