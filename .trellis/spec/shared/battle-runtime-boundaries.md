# Battle Runtime Boundaries

## Purpose

Prevent combat logic from leaking into scene flow, and prevent scene flow from rewriting combat rules.

This project now has both:

- a formal battle flow
- a debug sandbox and replay harness

Those must share the same combat kernel without competing ownership.

## Layer Definitions

### Combat Core

Location:

- `scripts/battle/core/`

Responsibilities:

- deterministic move progression
- hit resolution
- state machine transitions
- input buffer semantics
- per-frame combat interpretation

Core must not know:

- menus
- result screens
- stage selection flow
- HUD text formatting
- scene switching

### Fighter Base

Location:

- `scripts/fighter/base/`

Responsibilities:

- fighter-level orchestration
- movement behavior
- combat action requests
- grab behavior
- runtime state storage
- fighter stats

Fighter base may depend on combat core.
Fighter base must not own menu or scene flow.

### Battle Runtime

Location:

- `scripts/battle/runtime/`

Responsibilities:

- setting up a match
- choosing fighters and stage data
- ticking the active match
- evaluating round end conditions
- updating HUD and camera
- producing result data

Runtime may call fighter methods and core systems.
Runtime must not redefine frame data semantics or hit rules.

### Debug Runtime

Location:

- `scripts/battle/debug/`
- `scenes/debug/`

Responsibilities:

- replay validation
- sandbox controls
- deterministic diagnostics
- debug-only text panels and harness behavior

Debug code may be more verbose and specialized.
Debug code must not become required for formal gameplay.

## Formal Flow Rule

Formal flow scenes:

- must start from boot or menu
- must use runtime battle scenes
- must not rely on sandbox-specific labels, report strings, or replay test phases

## Sandbox Rule

Sandbox scenes:

- may expose replay buttons, direct debug text, and validation controls
- may instantiate the same fighter base scene as formal battle
- must remain independent of the formal match result flow

## Data Flow Rule

Preferred flow:

`autoload managers -> battle runtime -> fighter modules -> combat core -> resource data`

Not preferred:

`UI -> directly mutate core`

or

`debug harness -> bypass fighter pipeline`

## AI Rule

Future AI should inject actions through the same fighter input/action path used by players and replay scripts.

Do not create an AI-only shortcut that bypasses:

- `input_buffer`
- action resolution
- move start validation

## When in Doubt

Ask:

1. Is this deterministic combat truth? Put it in core.
2. Is this fighter behavior shared across runtime contexts? Put it in fighter base.
3. Is this only about running a match scene? Put it in battle runtime.
4. Is this only for replay, sandbox, or diagnostics? Put it in battle debug.
