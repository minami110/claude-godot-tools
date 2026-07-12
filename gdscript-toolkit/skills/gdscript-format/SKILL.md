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
| `-s`, `--safe` | Abort if formatting would change code meaning. Diagnostics currently report only `formatted output is structurally different from input` — the specific cause (whitespace, dict-literal, semicolon, etc.) is not surfaced. If one file fails `--safe` while others in the same batch pass, treat that file as an outlier and inspect its diff manually. |
| `-c`, `--check` | Exit 1 if files are not formatted (CI mode, no writes) |
| `--stdout` | Write to stdout instead of overwriting files |
| `--reorder-code` | Reorder code to match the official style guide. **Includes formatting** — a single call runs format + reorder, no need to invoke the formatter twice. |
| `--max-line-length <N>` | Line length limit (default: 100) |
| `--use-spaces` / `--indent-size <N>` | Use spaces for indentation |
| `--blank-lines-around-definitions <N>` | Blank lines between top-level definitions (default: 2) |

## Best Practices

**Scope your batch to changed files.** When applying `--reorder-code` after editing, prefer targeting only files you actually changed:

```bash
git diff HEAD --name-only -- '*.gd' | \
  xargs ${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter --reorder-code
```

Batching the whole tree from a single-file edit can produce hundreds of lines of unwanted formatting changes in legacy unmodified files (see "Known Caveats").

**Preview before writing** (unfamiliar or legacy files):

```bash
# stdout mode — shows formatted output without touching disk
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter --stdout path/to/file.gd | diff path/to/file.gd -

# check mode — exit 1 if not formatted (no writes)
${CLAUDE_PLUGIN_ROOT}/skills/gdscript-format/bin/gdscript-formatter --check path/to/file.gd
```

**Repo-wide reformat = its own PR.** If you need to normalize the whole tree to the current formatter output, do it in a dedicated PR (nothing else in it). After the reformat PR merges, append its squash-merge SHA to `.git-blame-ignore-revs` so `git blame` skips the mechanical commit:

```bash
# Create or append to the ignore file
echo "<merge-commit-sha>" >> .git-blame-ignore-revs

# One-time per clone: teach local git to use the file
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

GitHub's blame view honors `.git-blame-ignore-revs` automatically once the file is committed.

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
- **First-time `--reorder-code` on legacy files can produce large diffs.** If a file predates the current formatter version, applying `--reorder-code` may shift continuation-line indents, normalize blank lines around definitions, and rearrange members — even when your logical change is small. When editing one function of a legacy file: (a) apply reformat to that file first as a separate commit/PR, or (b) run a repo-wide reformat once as a baseline before feature work. Prefer (a) for a single legacy file; (b) only pays off when many legacy files will be edited across the project. Preview with `--stdout` if churn size matters for review.
- **Formatter panic on multibyte-heavy files.** On `.gd` files with dense multibyte content (long Japanese comments, non-ASCII string literals), the formatter can crash with `index out of bounds: the len is 256 but the index is 65535`. When this happens, exclude the file from the batch and treat it as already-formatted, then report the snippet upstream to [GDQuest/GDScript-formatter](https://github.com/GDQuest/GDScript-formatter/issues).
- The formatter is under active development. If output looks wrong, re-run with `--safe` (refuses semantic changes) and report the snippet upstream to [GDQuest/GDScript-formatter](https://github.com/GDQuest/GDScript-formatter/issues).

## Exit Codes

- **0**: Success (no issues, or formatting applied)
- **1**: Issues found or changes needed (`--check` mode)
- **2**: Binary not found or other setup error
