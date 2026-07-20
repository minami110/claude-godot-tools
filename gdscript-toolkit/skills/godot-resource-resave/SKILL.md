---
name: godot-resource-resave
description: Re-save Godot text resources (.tscn/.tres) through the editor pipeline to inject UIDs and validate that they load. Use after creating or editing .tscn/.tres files by hand.
allowed-tools:
  - Bash
---

# Godot Resource Resave

Re-serialize `.tscn` / `.tres` files through Godot's editor resource pipeline (`ResourceLoader.load` → `ResourceSaver.save`). Never hand-write `uid://...` values into resource files — run this skill instead and let Godot assign them.

**This skill REWRITES the target files in place.** It is not read-only.

## What It Does

- **UID injection**: adds the `uid="uid://..."` attribute to the resource header, exactly as the editor would
- **Load validation**: any file that fails to load (corrupt syntax, unknown type) is reported as a failure instead of being rewritten
- **Canonical formatting**: output is byte-identical to what the Godot editor saves, so re-running on healthy files produces zero diff

## When to Use

- After creating new `.tscn` / `.tres` files (they have no `uid=` yet)
- After hand-editing resource files, to normalize them and confirm they still load
- To validate a set of resource files without trusting them to a full editor session

## Command

```bash
<godot> --headless --editor --path <project_root> --script <script> -- <paths...>
```

- `<godot>` — path to the Godot binary (use whatever is available: `godot`, `godot4`, `/usr/bin/godot`, etc.)
- `<project_root>` — directory containing `project.godot`
- `<script>` — **absolute** path to this skill's `scripts/resave.gd`. Relative `--script` paths are resolved against `res://`, so a path outside the project only works in absolute form.
- `<paths...>` — files and/or directories (recursed), as `res://`, absolute, or project-root-relative paths. Only `.tscn` / `.tres` are processed; hidden directories (`.godot`, `.git`, ...) are skipped. Glob expansion is left to the shell.

`--editor` is **required**: without it the text saver never writes `uid=` lines and even strips existing ones.

### Whole-Project Recipe

```bash
cd <project_root>
git ls-files -z '*.tscn' '*.tres' | xargs -0 <godot> --headless --editor --path . --script <script> --
```

Using `git ls-files` naturally excludes `.godot/` and gitignored addons.

## Output Contract

Read only the `[RESAVE]` marker lines and the exit code:

- `[RESAVE] FAIL <res://path> (load|save)` — one line per failed file
- `[RESAVE] ok=<N> failed=<M>` — final summary

Exit code: `0` all files saved / `1` one or more failures / `2` bad arguments (no paths, or a path that does not exist).

Godot prints WARNING/ERROR noise (ObjectDB leaks, RID leaks, `first_scan_filesystem` progress) during headless runs — ignore it, same policy as godot-cache-refresh.

## Ordering: New Scripts Need a Cache Refresh First

UIDs for referenced resources (e.g. the `uid=` on an `ext_resource` line pointing to a `.gd` script) are looked up from the project's UID cache, which is populated by the editor's filesystem scan — and that scan completes only *after* this script has already run. Verified consequence: for a brand-new `.gd` referenced by a brand-new `.tscn`, a single resave writes the scene's own header `uid=` but not the `ext_resource` `uid=`.

So when new `.gd` files are involved, run **godot-cache-refresh first, then this skill** (a second resave run also works, but the explicit order is cheaper and clearer).

## After Running

Review the result with `git diff --stat`. The operation is idempotent: a second run over the same files must produce zero diff, which doubles as a health check. Note the first pass may include benign normalization beyond UIDs (e.g. recalculated `load_steps`, canonical value formatting) — that is expected.

## Caveats

- Do **not** run this while the same project is open in the GUI editor (import / `.godot` cache contention).
- The first run on a fresh checkout triggers asset import and is slow; later runs are fast.

## Role Separation vs godot-cache-refresh

|  | godot-cache-refresh | godot-resource-resave |
|---|---|---|
| Target | whole project | given `.tscn` / `.tres` files |
| Mechanism | passive scan (`--editor --quit`) | active load→save (`--editor --script`) |
| Produces | class_name cache + missing `.gd.uid` sidecars | `uid=` inside `.tscn`/`.tres` + load validation |
| Rewrites project files | no | **yes** |

Note: gdunit4-toolkit's gdunit4-test-runner performs the same passive scan before running tests by default, so `.gd.uid` sidecar generation can also happen as a side effect of running tests. That runner is read-only by contract and does not resave resources.
