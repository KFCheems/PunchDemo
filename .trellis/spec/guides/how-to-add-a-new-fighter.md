# How to Add a New Fighter

## Purpose

Add a fighter in a way that respects the current project architecture:

- combat kernel stays shared
- fighter-specific content stays data-driven
- presentation remains configurable

## High-Level Rule

Do not clone and fork the entire fighter controller stack for each new fighter.

New fighters should usually add:

- fighter resources
- move resources
- visual mapping
- optional wrapper scene

They should usually not add:

- a brand new combat core
- a second copy of fighter base logic

## Required Checklist

### 1. Create Fighter Id

Choose a stable fighter id such as:

- `ali`
- `riki`
- `kunio`

Use the same id across folders, definitions, and wrapper scene names.

### 2. Add Visual Assets

Create:

- `assets/sprites/fighters/<fighter_id>/`

Add at minimum:

- atlas texture
- atlas metadata json

### 3. Add Move Resources

Create:

- `resources/moves/<fighter_id>/`

Reuse shared moves from `resources/moves/common/` when behavior is identical.

Only create fighter-specific move resources when timing, boxes, or other frame content differs.

### 4. Add Fighter Definition

Create:

- `resources/fighters/<fighter_id>/<fighter_id>_definition.tres`

The definition should include:

- fighter id
- display name
- move resource map
- visual profile

### 5. Add Visual Profile

The visual profile must define:

- texture
- atlas json path
- display id to atlas frame mapping
- fallback frame name
- sprite scale
- sprite offset

Do not hardcode fighter atlas data into the shared visual script.

### 6. Register in DataManager

Update `DataManager` so the fighter can be loaded by id.

During the current project stage, this may mean:

- loading the fighter definition resource
- falling back to a built-in default only if the resource is missing

Prefer resource-backed registration over embedding large fighter data directly into `DataManager`.

### 7. Reuse Fighter Base Scene

Default choice:

- instantiate `scenes/fighters/base/fighter_base.tscn`

Only add a fighter-specific wrapper scene if you truly need scene-level overrides.

### 8. Validate in Both Contexts

Test the fighter in:

- formal battle scene
- debug sandbox

At minimum verify:

- idle render works
- punch and kick start correctly
- hurt works
- jump works
- replay or sandbox does not break

## Migration Advice

When migrating an old hardcoded fighter:

1. move visual data first
2. move common moves next
3. move fighter-specific moves after that
4. keep a fallback path until parity is confirmed

## Common Mistakes

- adding new fighter atlas mappings directly into shared visual defaults
- duplicating `fighter_controller` for each fighter
- creating fighter-specific move code in runtime scripts
- bypassing `move_library` and manually starting hardcoded moves from UI
- putting raw assets in the wrong folder family

## Definition of Done

A fighter is "added" only when:

- it can be selected or loaded by fighter id
- it renders using its own visual profile
- it can run at least the shared baseline move set
- it works in both formal and debug battle contexts
