# How to Add a New Move

## Purpose

Add a move without breaking:

- fixed-tick combat behavior
- replay determinism
- fighter/base layer boundaries
- data-driven move ownership

## High-Level Rule

New move content should usually be added as resource data first, not as controller branching.

The preferred pattern is:

1. define or update move data
2. wire the move into a fighter definition or move library
3. ensure presentation can render the new display ids
4. validate the move in both formal runtime and debug sandbox

## First Decision: Common or Fighter-Specific

Before creating a move, decide where it belongs.

### Put the move in `resources/moves/common/` when:

- the move is shared by multiple fighters
- timing and box data are identical
- the display ids are shared or already abstracted

### Put the move in `resources/moves/<fighter_id>/` when:

- the move belongs to only one fighter
- frame timing differs
- hitboxes or hurtboxes differ
- the move is a fighter-specific signature move

## Second Decision: Resource or Fallback Code

Default choice:

- use `.tres` resource data

Temporary fallback:

- use `scripts/data/demo_move_library.gd` only when parity is not yet available in resources

Do not add large amounts of new content directly into `demo_move_library.gd` unless the move is clearly temporary and you document the migration intent.

## Required Checklist

### 1. Choose a Stable Move Id

Examples:

- `punch`
- `kick`
- `run_punch`
- `front_grapple_punch`
- `mach_punch`

Use lowercase snake_case.

### 2. Create the Move Resource

Create:

- `resources/moves/common/<move_id>.tres`
  or
- `resources/moves/<fighter_id>/<move_id>.tres`

The move resource should define:

- `move_name`
- `state_tag`
- `loop`
- `return_to`
- frame list

Each frame should define:

- `display_id`
- `duration_ticks`
- cancel and interrupt settings
- hitboxes and hurtboxes

## 3. Reuse Existing Sub-Patterns

Before inventing a new layout:

- compare against `idle.tres`
- compare against `punch.tres`
- compare against `kick.tres`
- compare against `jump.tres`
- compare against `hurt.tres`

Prefer cloning an existing resource shape and then editing values.

## 4. Add or Update Hit Effect Data

If the move has hitboxes, define:

- damage
- hitstun
- knockback
- hit mode
- rehit interval if needed
- optional `post_hurt_move_name`

Do not hardcode a new hit behavior in controller code if the existing `HitEffectData` already models it.

## 5. Register the Move

If the move is resource-backed, add it to the fighter's move map:

- fighter definition resource
- or temporary DataManager registration path if the project is still in transition

Do not rely on UI code or battle scene code to manually inject a move into combat flow.

## 6. Ensure Display Id Coverage

If the move introduces new `display_id` values:

- update the fighter visual profile mapping
- ensure the atlas json contains the frame names

Combat data may declare a frame correctly while presentation still fails if display ids are missing from the visual profile.

## 7. Update Action Resolution If Needed

Only touch fighter combat/action resolution when the move introduces a genuinely new action path.

Examples:

- new command input
- new run-state branch
- new grapple follow-up

Do not modify action resolution if the new move only replaces data for an existing action like `punch`.

## 8. Validate in Both Runtime Contexts

At minimum test in:

- `scenes/battle/battle_scene.tscn`
- `scenes/debug/battle_sandbox.tscn`

Check:

- move starts correctly
- move ends correctly
- return state is correct
- hitboxes behave at the expected frame/tick
- display ids render correctly
- replay or sandbox still runs

## 9. Preserve Determinism

If the move changes:

- active frame timing
- rehit interval
- cancel window
- return behavior

verify that replay outcomes remain stable for the same input sequence.

## Common Mistakes

- adding move-specific frame logic into `fighter_controller`
- using source atlas frame names as combat move ids
- forgetting to update fighter definition move maps
- forgetting to update visual profile display mappings
- adding debug-only move behavior that formal runtime cannot reproduce
- placing all new moves in `common/` even when they are fighter-specific

## Definition of Done

A move is "added" only when:

- it is addressable by stable move id
- the owning fighter can start it through normal action flow
- it renders correctly
- it behaves correctly in formal battle
- it behaves correctly in debug sandbox
- its behavior does not require new hardcoded controller branching unless the input/action model truly changed
