---
name: gdscript-format
description: Format and lint GDScript files using gdscript-formatter. Use after editing GDScript files to ensure code style consistency.
allowed-tools:
  - Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/scripts/ensure-binary.sh"
          once: true
---

# GDScript Format

Format and lint GDScript files using the [gdscript-formatter](https://github.com/GDQuest/GDScript-formatter) binary from GDQuest.

The binary is auto-installed by the PreToolUse hook on first use and lives at:

```
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter
```

Call it directly — no wrapper script. Run `--help` / `lint --help` to see all options.

The hook always installs the version pinned in `scripts/install.sh`, so the behavior described here is exact rather than approximate: it is verified against **formatter 0.24.0**.

## When to Use

- After creating or editing GDScript files
- Before committing code to ensure style consistency
- When running code quality checks

## Format

```bash
# Single file
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter path/to/file.gd

# Multiple files
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter path/to/file1.gd path/to/file2.gd

# Directory (recursive)
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter path/to/dir
```

Common flags:

| Flag | Purpose |
|---|---|
| `--verify-structure` | Keep the original file if the formatted output's structure differs from the input |
| `-c`, `--check` | Exit 1 if files are not formatted (CI mode, no writes) |
| `-x`, `--exclude <PATH>` | Skip one file or directory; repeat the flag to skip several |
| `--stdout` | Write to stdout instead of overwriting files |
| `--reorder-code` | Reorder code to match the official style guide. Includes formatting — a single call runs format and reorder. |
| `--max-line-length <N>` | Line length limit (default: 100; `.editorconfig` can override — see below) |
| `--use-spaces` / `--indent-size <N>` | Use spaces for indentation |
| `--blank-lines-around-definitions <N>` | Blank lines between top-level definitions (default: 2) |

`--verify-structure` replaced `-s`/`--safe`; the old spellings still work but are gone from `--help`. Its diagnostic is generic — `Verify structure: formatted output is structurally different from input` — so it says nothing about which construct differed.

Both `format` and `lint` honor `.editorconfig`, resolved upward from each file's directory: settings such as `max_line_length` override the built-in defaults, and explicit CLI flags override `.editorconfig`.

### Excluding Files

Pass `-x`/`--exclude` per call, or check the exclusion into `.editorconfig`. There the value is a boolean and the section glob picks what to skip:

```ini
[**/tests/**]
gdscript_formatter_exclude = true
```

Start the glob with `**/` (`[**/tests/**]`, `[**/*_test.gd]`). A section beginning with a plain relative path (`[tests/**]`) matches only when the formatter is invoked from the directory holding that `.editorconfig`.

## Lint

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter lint path/to/file.gd
```

Common flags:

| Flag | Purpose |
|---|---|
| `--disable <rules>` | Comma-separated rule names to skip |
| `-x`, `--exclude <PATH>` | Skip one file or directory; repeat the flag to skip several |
| `--max-line-length <N>` | Line length limit (default: 100; overrides `.editorconfig`'s `max_line_length`) |
| `--pretty` | Human-readable output |
| `--list-rules` | Print every available rule and exit |

### Lint Rules

- **Naming**: `function-name`, `class-name`, `signal-name`, `variable-name`, `function-argument-name`, `loop-variable-name`, `enum-name`, `enum-member-name`, `constant-name`
- **Quality**: `duplicated-load`, `standalone-expression`, `unnecessary-pass`, `unused-argument`, `comparison-with-itself`, `private-access`, `max-line-length`, `no-else-return`

Run `... lint --list-rules` for the authoritative list.

### Suppressing Lint Warnings in Code

Use `gdlint-ignore` comments (rule names comma-separated; omit them to ignore all rules):

```gdscript
# gdlint-ignore-next-line private-access
obj._private_method()

obj._private_method() # gdlint-ignore private-access
```

## Known Caveats

- **Every** single-line lambda is expanded into block form. A line break always follows the lambda declaration regardless of line length, so keeping the lambda short does not avoid it. The output is valid GDScript, so `--verify-structure` does not object (`--check` does exit 1, but only as an ordinary "not formatted" diff — nothing marks the change as risky). A block-form lambda inside gdUnit4 `test_parameters` breaks test discovery: extract a named static helper instead of an inline lambda there (see the gdunit4-test-writer skill), or exclude the file.
- Hand-wrapping is not preserved. A trailing comma does not keep an array or argument list expanded — anything that fits within the line length is re-joined onto one line, including a `test_parameters` table written one case per row. Exclude the file if that layout matters.
- `--reorder-code` moves a mid-file `@warning_ignore_start` together with the declaration that follows it, changing which declarations it covers. For file-wide suppression, put it at the very top of the file, above `class_name` — that position survives reordering.
- Two Godot-side rules constrain where those annotations can go: `@warning_ignore_start` between `class_name` and `extends` is a parse error (`Unexpected "extends" in class body`), and `@warning_ignore` on a `func` declaration does not cover the function body — annotate the statement inside the body instead.
- If output looks wrong, re-run with `--verify-structure` (keeps the original file when the structure differs) and report the snippet upstream to [GDQuest/GDScript-formatter](https://github.com/GDQuest/GDScript-formatter/issues).

## Exit Codes

- **0**: Success (no issues, or formatting applied)
- **1**: Issues found — a `--check` diff, lint findings, or an unreadable input file
- **2**: Setup or usage error (binary not installed, unknown flag)
