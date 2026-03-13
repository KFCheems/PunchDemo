# Godot Task Templates

## Purpose

These are **task-folder templates** for this project.

They are intentionally **not** placed inside `.trellis/tasks/`, because the Trellis `task.py list` command treats every directory under `.trellis/tasks/` as a task candidate.

Use these templates as copy/reference material when creating a new real task directory with:

```bash
python3 ./.trellis/scripts/task.py create "<title>" --slug <slug>
```

Then copy the relevant template content into the generated task folder.

## Available Templates

- `system-refactor/`
  - For engineering refactors, architecture cleanup, controller slimming, scene/runtime separation, and migration work.
- `move-resource-migration/`
  - For moving a move from fallback code into `.tres` resources while preserving deterministic behavior.
- `fighter-addition/`
  - For adding a new fighter with assets, move map, visual profile, and runtime integration.
- `stage-addition/`
  - For adding a new stage to assets, data flow, and formal runtime.

## Standard Task Folder Shape

Each real task folder should typically contain:

```text
.trellis/tasks/<mm-dd-slug>/
  task.json
  prd.md
  implement.jsonl
  check.jsonl
  debug.jsonl
```

## How to Use

1. Create a real task directory with `task.py create`.
2. Choose the closest template folder from this directory.
3. Copy the template file contents into the real task.
4. Replace placeholder tokens like:
   - `<task-id>`
   - `<task-title>`
   - `<fighter-id>`
   - `<move-id>`
   - `<stage-id>`
5. Trim any sections that do not apply.

## Project-Specific Rule

These templates assume the current project architecture:

- deterministic combat core in `scripts/battle/core/`
- formal battle runtime in `scripts/battle/runtime/`
- debug harnesses in `scripts/battle/debug/`
- fighter shared logic in `scripts/fighter/base/`
- move and fighter content primarily in `resources/`

If that architecture changes, update these templates together with the shared specs.
