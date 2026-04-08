---
name: godot-cache-refresh
description: Regenerate Godot caches (class_name registry and .uid files). Use after creating or renaming GDScript files with class_name.
allowed-tools:
  - Bash
---

# Godot Cache Refresh

Regenerate Godot Engine's project caches by running the editor in headless mode.

## What It Refreshes

- **Class name cache**: `.godot/global_script_class_cache.cfg` — registry of all `class_name` declarations
- **UID files**: `.uid` files for resources that are missing them

## When to Use

- After creating new GDScript files with `class_name`
- After moving or renaming GDScript files
- When class references are not resolving correctly ("class not found" errors)

## Command

```bash
<godot> --headless --editor --path <project_root> --quit
```

- `<godot>` — path to the Godot binary (use whatever is available: `godot`, `godot4`, `/usr/bin/godot`, etc.)
- `<project_root>` — directory containing `project.godot`

### Finding the Project Root

```bash
find . -maxdepth 4 -name "project.godot" -type f 2>/dev/null
```

## Success Criteria

Exit code 0 means the cache was regenerated successfully.

## Important: Ignore Godot Log Noise

Godot prints WARNING and ERROR messages to stderr during headless runs. These are **normal and expected** — do not treat them as failures:

- `WARNING: ObjectDB instances leaked at exit`
- `ERROR: Condition "..." is true`

Only the exit code matters.
