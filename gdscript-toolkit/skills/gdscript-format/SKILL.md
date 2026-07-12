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
| `-s`, `--safe` | Abort if formatting would change code meaning |
| `-c`, `--check` | Exit 1 if files are not formatted (CI mode, no writes) |
| `--stdout` | Write to stdout instead of overwriting files |
| `--reorder-code` | Reorder code to match the official style guide |
| `--max-line-length <N>` | Line length limit (default: 100) |
| `--use-spaces` / `--indent-size <N>` | Use spaces for indentation |
| `--blank-lines-around-definitions <N>` | Blank lines between top-level definitions (default: 2) |

## Lint

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter lint path/to/file.gd
```

Common flags:

| Flag | Purpose |
|---|---|
| `--disable <rules>` | Comma-separated rule names to skip |
| `--max-line-length <N>` | Line length limit (default: 100) |
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

- The formatter may expand single-line lambdas onto multiple lines. gdUnit4 `test_parameters` requires single-line lambdas — after formatting test suites, verify parameterized tests still parse (see the gdunit4-test-writer skill).
- The formatter is under active development. If output looks wrong, re-run with `--safe` (refuses semantic changes) and report the snippet upstream to [GDQuest/GDScript-formatter](https://github.com/GDQuest/GDScript-formatter/issues).

## Exit Codes

- **0**: Success (no issues, or formatting applied)
- **1**: Issues found or changes needed (`--check` mode)
- **2**: Binary not found or other setup error
