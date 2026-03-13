# How to Add a New Stage

## Purpose

Add a stage without leaking stage concerns into combat core.

Stages belong to runtime flow, assets, and data definitions—not to the deterministic combat kernel.

## High-Level Rule

A stage should be assembled from:

- stage assets
- optional stage scene
- stage data entry
- runtime loading through `DataManager` and battle runtime

Do not hardcode stage selection directly into combat core or fighter modules.

## Required Checklist

### 1. Choose a Stable Stage Id

Use lowercase snake_case, for example:

- `stage_01`
- `stage_schoolyard`
- `stage_rooftop`

Use the same id across asset paths, scene paths, and stage data.

### 2. Add Visual Assets

Create or update:

- `assets/sprites/stages/<stage_id>.png`

If the stage has additional decorative assets, keep them grouped under the same stage family.

### 3. Add Audio Assets

If the stage has its own BGM, add:

- `assets/audio/bgm/<stage_id>.wav`

If no unique BGM exists yet, reuse a safe default via stage data instead of hardcoding it in the scene.

### 4. Create a Stage Scene If Needed

If the stage needs scene-level structure, create:

- `scenes/stages/<stage_id>.tscn`

Use this when the stage needs:

- decorative parallax layers
- anchors or markers
- future hazards or region nodes

If the stage is currently just a background, you may defer a full scene and use data-only loading first.

## 5. Add Stage Data

Register the stage in data flow.

At the current project stage, that usually means adding a stage data entry accessible from `DataManager`.

A stage data payload should at minimum include:

- `stage_id`
- `display_name`
- `background_path`
- `bgm_path`

Future stage data may also include:

- scene path
- spawn positions
- camera limits
- lane/depth settings
- hazard configuration

## 6. Keep Stage Logic Out of Combat Core

Do not place stage-specific behavior in:

- `scripts/battle/core/`
- fighter base modules

Stage-dependent runtime behavior belongs in:

- `scripts/battle/runtime/`
- stage scene scripts
- stage data

## 7. Wire It Into Formal Runtime

Ensure formal battle flow can load the stage through:

- `GameManager` selection
- `DataManager` lookup
- `battle_match.gd` runtime setup

Do not make the battle scene depend on a single fixed texture path forever.

## 8. Validate Sandbox Expectations

Debug sandbox may continue using a known default stage.

If you want the sandbox to exercise the new stage too, add the stage in a way that does not break:

- replay validation
- sandbox boot stability
- existing debug labels and harness assumptions

## 9. Validate Runtime Behavior

At minimum confirm:

- background loads
- BGM loads or gracefully falls back
- battle scene still starts
- fighters spawn at usable positions
- camera still frames the match acceptably
- result flow still works

## Common Mistakes

- putting stage selection logic into combat core
- hardcoding stage asset paths in multiple runtime files
- adding new assets into legacy folders like `assets/backgrounds/`
- forgetting to add a data entry after creating the asset
- using display names with spaces as technical ids
- breaking sandbox assumptions while trying to improve formal flow

## Definition of Done

A stage is "added" only when:

- it has a stable stage id
- its assets live in the correct stage folders
- runtime can load it through data
- formal battle can start with it
- it does not require combat core modifications just to exist
