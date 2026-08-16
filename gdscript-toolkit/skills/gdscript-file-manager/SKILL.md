---
name: gdscript-file-manager
description: Move, rename, or delete GDScript files with their .uid files for Godot projects. Use when reorganizing code, renaming scripts, or removing unused GDScript files.
allowed-tools:
  - Bash
---

# GDScript File Manager

Manage GDScript files (.gd) along with their corresponding .uid files.

## Core Principle

Godot Engine auto-generates a `.uid` file for each resource. **Always handle .gd and .uid files together.**

## Before Any Operation: Check Owners

Run **godot-resource-owners** on the target first:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/godot-resource-owners/scripts/owners.sh <project_root> <file>.gd
```

- **Delete**: if any owner is listed, stop — remove or redirect those references first, then delete.
- **Move / Rename**: owners tagged `(uid)` or `(path+uid)` survive the move (Godot re-resolves them by UID). Owners tagged `(path)` — `preload("res://old/path.gd")` literals, `project.godot` autoloads, etc. — will break; update those literals to the new path right after the move.

## Operations

### Move Files

```bash
# 1. Verify destination
ls <destination-dir>

# 2. Move both files
mv <source>.gd <destination>.gd && mv <source>.gd.uid <destination>.gd.uid

# 3. Verify
ls <destination-dir> && ls <source-dir>

# 4. Update every owner tagged (path) to the new res:// path
```

### Rename Files

```bash
# 1. Rename both files
mv <old-name>.gd <new-name>.gd && mv <old-name>.gd.uid <new-name>.gd.uid

# 2. Verify
ls -la <directory>

# 3. Update every owner tagged (path) to the new res:// path
```

### Delete Files

```bash
# 1. Verify target and confirm it has no owners (see above)
ls -la <directory>

# 2. Delete both files
rm <filename>.gd && rm <filename>.gd.uid

# 3. Verify
ls -la <directory>
```

## Important Notes

- Never manually create or edit .uid files - Godot manages them automatically
- Always process both files together to avoid breaking project references
- Verify files before operations using `ls` commands
- `.uid` references survive a move; `res://` path literals in other scripts and in `project.godot` do not — always run the owners check first

See @examples.md for detailed examples and troubleshooting.
