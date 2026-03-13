# Resource Naming

## Purpose

Provide consistent naming and paths so content remains searchable, batch-editable, and easy to reason about.

## Core Rules

- Use lowercase for folders.
- Use lowercase with underscores for filenames.
- Do not use spaces in file or folder names.
- Do not use mixed naming styles in the same resource family.
- Use stable ids in filenames when the resource is referenced by code or data.

## Examples

Good:

- `assets/audio/bgm/stage_01.wav`
- `assets/sprites/fighters/ali/ali.png`
- `assets/sprites/fighters/ali/ali_atlas.json`
- `resources/moves/common/punch.tres`
- `resources/fighters/ali/ali_definition.tres`
- `scenes/debug/battle_sandbox.tscn`
- `scripts/battle/runtime/battle_match.gd`

Bad:

- `assets/BGM/Stage1BGM.wav`
- `assets/backgrounds/Stage 1.png`
- `assets/Sprite/ALI-b/ALI.png`
- `fighterController.gd`

## Naming by Category

### Fighters

- Fighter folder: `<fighter_id>`
- Fighter definition: `<fighter_id>_definition.tres`
- Fighter visual profile, if split later: `<fighter_id>_visual_profile.tres`
- Fighter wrapper scene: `<fighter_id>_fighter.tscn`

### Moves

- Shared/common move: `resources/moves/common/<move_id>.tres`
- Fighter-specific move: `resources/moves/<fighter_id>/<move_id>.tres`

Use stable move ids like:

- `idle`
- `hurt`
- `jump`
- `punch`
- `run_punch`
- `front_grapple_punch`

### Stages

- Stage id format: `stage_01`, `stage_schoolyard`, `stage_rooftop`
- Stage scene: `<stage_id>.tscn`
- Stage background image: `<stage_id>.png`
- Stage config resource, if added later: `<stage_id>.tres`

### Scripts

- Use noun or noun_phrase names
- Prefer role-based names:
  - `battle_match.gd`
  - `fighter_input.gd`
  - `fighter_runtime_state.gd`

Avoid vague names like:

- `utils.gd`
- `helper.gd`
- `manager2.gd`

## Legacy Paths

Old directories such as:

- `assets/BGM/`
- `assets/backgrounds/`
- `assets/Sprite/`

may remain temporarily for compatibility, but new content must not be added there.

## Display Ids and Data Keys

- Keep display ids stable and machine-friendly.
- Prefer `run_punch_0` over display strings with spaces or source-tool suffixes.
- Source asset frame names can stay verbose if required by atlas exports, but combat-facing ids should stay normalized.
