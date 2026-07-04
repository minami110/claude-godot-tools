---
name: open-godot-editor
description: |
  Launch the Godot editor GUI in the background so its stdout (print / push_warning / push_error) is directly readable.
  Use when the user explicitly asks to open the Godot editor, or when a change needs hands-on verification in the running editor/game.
allowed-tools:
  - Bash
---

# Open Godot Editor

Launch `godot --editor` for the current project as a **background task**. Because the editor runs in the background, everything the project prints (`print`, `push_warning`, `push_error`) lands in the task output where it can be read directly — no copy-pasting from the user's console.

## When to Use

- The user explicitly asks to open/launch the Godot editor ("open the editor", "launch godot", "エディタ開いて")
- The user wants to try the game/scene hands-on in the GUI
- After injecting debug prints, to capture their output while the user plays

**Not for**: headless imports / cache refresh (use `godot-cache-refresh`), running tests, LSP status checks, or environments without a display (SSH / CI — `godot --editor` cannot open a window there).

## Steps

### 1. Pre-flight checks (foreground, as separate commands)

Resolve the project root — the directory containing `project.godot`. In a git repository, try the repo/worktree root first; otherwise search:

```bash
git rev-parse --show-toplevel
```

```bash
find . -maxdepth 4 -name "project.godot" -type f 2>/dev/null
```

If no `project.godot` is found, report that and stop — launching the editor without a project is pointless.

Verify the Godot binary is available:

```bash
command -v godot
```

If not found, ask the user to add Godot to `PATH` or set `GODOT_PATH` to the absolute binary path. When `GODOT_PATH` is set, use it instead of `godot` in the commands below.

### 2. Launch (background)

```bash
godot --editor --path <project_root>
```

Run this as its **own Bash call with `run_in_background: true`**. Do not chain it with `&&` onto the pre-flight commands — backgrounding a compound command breaks per-step exit-code error detection.

### 3. After launch

- Report the launched project root in one line (e.g. `Godot editor launched at /path/to/project`).
- If Godot is already running for the same project, Godot itself rejects the second instance — an "already running" error appears in the background log. Report that instead; no extra pre-check is needed.

## Reading Logs

The Bash tool result of the background call includes the output file path. Use `grep` / `tail` / `Read` on it:

- `print()` output appears as-is; `push_error` / `push_warning` appear as `SCRIPT ERROR:` / `WARNING:` lines:

  ```bash
  grep -nE "SCRIPT ERROR|WARNING" <output_path>
  ```

- Editor startup is noisy (import logs, warnings — often hundreds of lines). When debugging, give injected prints a distinct marker like `[PROBE]` and extract with:

  ```bash
  grep -n "\[PROBE\]" <output_path>
  ```

- The user runs the game (F5) themselves; its stdout joins the same log file. Read it after the user reports having interacted.
