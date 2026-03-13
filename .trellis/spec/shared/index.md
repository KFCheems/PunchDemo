# Shared Project Specs

> Hard constraints and project-level rules that apply across all task types.

---

## Specs Index

| Spec | Description | Status |
|------|-------------|--------|
| [Fighting Core Constraints](./fighting-core-constraints.md) | Non-negotiable rules for 1:1 combat-kernel recreation | Filled |
| [Godot Directory Structure](./godot-directory-structure.md) | Source-of-truth directory layout and placement rules for scenes, scripts, assets, and resources | Filled |
| [Data-Driven Combat](./data-driven-combat.md) | Rules for what belongs in combat code versus move/frame resource data | Filled |
| [Resource Naming](./resource-naming.md) | Naming and path conventions for assets, resources, scenes, and scripts | Filled |
| [Battle Runtime Boundaries](./battle-runtime-boundaries.md) | Separation rules between combat core, fighter modules, runtime flow, and debug harnesses | Filled |

---

## Usage

1. Read this directory before implementing any combat-related task.
2. Treat listed constraints as hard requirements, not suggestions.
3. If a requirement conflicts with implementation reality, stop and ask for confirmation before changing behavior.
