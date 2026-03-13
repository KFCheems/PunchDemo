# Data-Driven Combat

## Purpose

Keep combat deterministic while allowing move content to scale without ballooning controller code.

This project uses a hybrid model:

- combat rules live in code
- move content lives in resources

That boundary should become stronger over time, not weaker.

## Source of Truth

### Code Owns Rules

The following belong in code:

- fixed tick progression
- frame advancement rules
- hit resolution rules
- cancel and interrupt evaluation
- single-hit and multi-hit behavior
- re-hit interval checks
- facing and mirroring logic
- state transition rules
- sandbox replay logic

These should remain inside modules like:

- `scripts/battle/core/move_runner.gd`
- `scripts/battle/core/hit_resolver.gd`
- `scripts/battle/core/fighter_state_machine.gd`

### Resources Own Move Content

The following belong in resources:

- move names
- frame lists
- frame durations
- display ids
- hitboxes and hurtboxes
- hit effect parameter values
- cancel and interrupt windows
- fighter-to-move mappings

These should live in:

- `resources/moves/`
- `resources/fighters/`
- `resources/effects/`

## Current Project Strategy

The project currently supports a compatibility layer:

- `.tres` resources are the preferred home for stable move content
- `scripts/data/demo_move_library.gd` remains a fallback and migration bridge

This is acceptable during transition.

It is not acceptable to expand `demo_move_library.gd` indefinitely for all future content.

## Move Migration Policy

When moving a move from code to resources:

1. Keep runtime behavior identical.
2. Migrate only one logical group at a time.
3. Preserve a fallback path until the new resource path is proven stable.
4. Update fighter definitions to reference the resource path.
5. Leave validation harnesses intact.

Recommended migration order:

1. `idle`
2. `hurt`
3. `jump`
4. `punch`
5. `kick`
6. `run`
7. `run_punch`
8. `run_kick`
9. `knockdown`
10. grapples and post-hurt follow-ups

## Frame Semantics Rule

Every frame should have explicit meaning.

That does not mean every frame should be hardcoded in controller logic.

Preferred pattern:

- `FrameData` declares the frame's meaning
- runtime code interprets the frame consistently
- visual code renders the declared display id

Avoid patterns like:

- `if current_frame == 3 then enable hitbox`
- `if current_move == "punch" and frame == 2 then play real combat logic`

Use resource data instead.

## Presentation Rule

Display mapping is not combat truth.

- `display_id` is combat-facing data
- atlas frame mapping is presentation-facing data

Do not let sprite frame names become combat identifiers.

## Validation Rule

Every new move data path should still be testable from:

- formal battle flow
- debug sandbox
- deterministic replay

If a resource migration breaks replay parity, fix parity before adding more content.
