---
name: godot-resource-owners
description: List which scenes, scripts, and resources reference a given Godot resource (reverse dependencies — the script-side equivalent of the editor's "View Owners..."). Use before deleting, moving, or renaming any .gd / .tscn / .tres / shader / image / audio file, or to check whether an asset is unused.
allowed-tools:
  - Bash
---

# Godot Resource Owners

Find the **owners** of a resource: every project file that references it. This is a read-only, grep-based lookup — no Godot binary is needed and nothing is rewritten.

## Why Not the Editor / a Godot Script

- The editor's "View Owners..." is not scriptable: its backing API (`EditorFileSystemDirectory::get_file_deps`) is not exposed to GDScript, and the editor's file system tree is still empty when a `--headless --editor --script` run reaches `_initialize()`.
- The editor's data source, `ResourceLoader.get_dependencies()`, **does not see `preload()` / `load()` in `.gd` files** at all (as of Godot 4.7). Grepping for both the `res://` path and the `uid://` id catches those too, so this skill is a superset of the editor feature for text-based projects.

## Command

```bash
${CLAUDE_PLUGIN_ROOT}/skills/godot-resource-owners/scripts/owners.sh <project_root> <path>...
```

- `<project_root>` — directory containing `project.godot`
- `<path>` — the target, as `res://...`, an absolute path, or a path relative to `<project_root>`. Several targets may be given in one call.

## What It Does

1. Resolves the target's UID from wherever Godot stores it: `<file>.uid` sidecar (scripts, shaders), `<file>.import` (imported assets such as images / audio), or the header line of a `.tscn` / `.tres`.
2. Greps `*.gd`, `*.cs`, `*.tscn`, `*.tres`, `*.gdshader`, `*.gdshaderinc`, `*.gdextension`, and `project.godot` for the full `res://` path **and** the `uid://` id (both with a boundary check, so `res://a.gd` never matches `res://a.gdshader`).
3. Skips exactly what the editor skips: directories starting with `.` (`.godot`, `.git`, ...) and directories containing a `.gdignore` file. `*.import` / `*.uid` files are never candidates.

## Output Contract

```
[OWNERS] res://scenes/main.tscn   (uid://d1main000000)
[OWNERS]   res://project.godot      (path)
[OWNERS]   res://scenes/root.tscn   (path+uid)
[OWNERS]   res://scripts/legacy.gd  (path)
[OWNERS] res://scripts/orphan.gd   (uid://b7orphan0000)
[OWNERS]   (none)
```

One block per target. The tag says how the owner refers to the target:

| Tag | Meaning | On move / rename |
|---|---|---|
| `uid` | `uid://` only (e.g. `preload("uid://...")`) | survives — Godot re-resolves it |
| `path+uid` | `ext_resource` in a `.tscn` / `.tres` | survives — the editor rewrites `path=` on next save |
| `path` | `res://` literal only (`.gd` `preload("res://...")`, `project.godot`, `.gdextension`, ...) | **breaks** — the literal must be updated by hand |

Exit code: `0` done (even when a target has no owners) / `2` bad arguments (missing `project.godot`, target does not exist, no target given).

## When to Use

- Before **deleting** a file: if owners are listed, do not delete — fix the owners first (`gdscript-file-manager` calls this skill for that gate).
- Before **moving / renaming**: collect the `(path)` owners; those literals need to be rewritten after the move.
- To answer "is this asset still used?" (unused images, scenes, scripts) — `(none)` means no text reference anywhere in the project.

## Limitations

- Text resources only. Binary formats (`.res`, `.scn`, binary `.material`, etc.) cannot be grepped; a project relying on them needs a Godot-side fallback that this skill does not provide.
- Dynamic references built at runtime (`load(dir + name)`) are invisible to any static tool, including the editor.
- References that Godot does not use but that still contain the string (a comment, a doc string) count as owners. Read the owner file when the tag is `path` and the result looks surprising.
