# Godot Directory Structure

## Purpose

Define the default directory layout for this Godot project so that new work lands in predictable locations.

This project has already moved beyond a single combat demo. Treat the structure below as the source of truth for future work.

## Root Layout

```text
res://
  assets/
    audio/
      bgm/
      sfx/
    sprites/
      fighters/
      stages/
      ui/
    fonts/
    vfx/
  docs/
    design/
    thesis/
    test/
  resources/
    fighters/
    moves/
    effects/
    stages/
    ui/
  scenes/
    boot/
    ui/
    battle/
    fighters/
      base/
      <fighter_id>/
    stages/
    debug/
  scripts/
    autoload/
    battle/
      core/
      runtime/
      debug/
    fighter/
      base/
      ai/
      presentation/
    data/
      schema/
    ui/
    tools/
  tests/
```

## Placement Rules

### `assets/`

- Store imported source media only.
- Put backgrounds, atlases, audio, fonts, and VFX source files here.
- Do not place gameplay logic or `.tres` gameplay configuration here.

### `resources/`

- Store editable gameplay configuration and reusable Godot resources here.
- Move definitions, fighter definitions, visual profiles, stage data, and effect data belong here.
- If a designer or balancing pass should be able to modify it without touching logic code, prefer `resources/`.

### `scenes/`

- Store instantiable runtime scenes only.
- `scenes/boot/`: startup and initialization scenes.
- `scenes/ui/`: menu, result, settings, and non-debug UI.
- `scenes/battle/`: formal runtime battle flow scenes.
- `scenes/fighters/base/`: generic fighter scene skeletons.
- `scenes/fighters/<fighter_id>/`: fighter-specific wrapper scenes, if needed.
- `scenes/stages/`: stage scenes used by formal battle flow.
- `scenes/debug/`: sandbox, replay validation, harnesses, and one-off verification scenes.

### `scripts/autoload/`

- Global singleton managers only.
- Typical examples: `game_manager`, `scene_manager`, `audio_manager`, `save_manager`, `data_manager`.
- Avoid putting fighter-specific or battle tick-specific rules here.

### `scripts/battle/core/`

- Deterministic combat kernel modules only.
- Code here should remain valid whether the caller is a formal match, sandbox, replay harness, or future AI simulation.
- This is the most protected layer in the project.

### `scripts/battle/runtime/`

- Battle flow orchestration only.
- Match setup, timer logic, result creation, camera coordination, HUD updates, and scene-level runtime behavior live here.
- Runtime code may use core modules but must not redefine core rules.

### `scripts/battle/debug/`

- Replay harnesses, validation tools, debug visualizers, and test-only runtime glue.
- Code here may be noisy or purpose-built, but must not become a dependency of the formal game flow.

### `scripts/fighter/base/`

- Generic fighter modules shared by all fighters.
- Controller coordination, movement, combat, grab handling, input interpretation, stats, and runtime state belong here.

### `scripts/fighter/ai/`

- AI input generation and decision modules only.
- AI should emit actions into the same fighter pipeline as players instead of bypassing combat rules.

### `scripts/fighter/presentation/`

- Rendering, atlas lookup, debug draw, and presentation helpers only.
- Presentation code must not contain authoritative combat timing.

### `scripts/data/schema/`

- Resource classes and schema definitions only.
- `MoveData`, `FrameData`, `HitboxData`, `HurtboxData`, and related resource classes belong here.

### `scripts/ui/`

- Menu and non-battle UI logic only.

### `scripts/tools/`

- Editor scripts, migration scripts, content generation helpers, and other development tooling.

## Legacy Compatibility

- Compatibility wrappers may temporarily remain in old locations when needed to avoid breaking scenes or references.
- Compatibility wrappers must be thin pass-through files only.
- New features must target the new directory structure, not the legacy wrapper paths.

## When Adding New Files

Use these questions:

1. Is this deterministic combat logic? Place it in `scripts/battle/core/`.
2. Is this only for a formal battle scene or flow? Place it in `scripts/battle/runtime/`.
3. Is this a sandbox or verification helper? Place it in `scripts/battle/debug/`.
4. Is this fighter-agnostic runtime behavior? Place it in `scripts/fighter/base/`.
5. Is this editable data? Place it in `resources/`.
6. Is this raw imported media? Place it in `assets/`.

If a file seems to fit multiple places, stop and choose the highest-value abstraction before adding it.
