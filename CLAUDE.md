# Claude Godot Tools - Development Guidelines

## Project Overview

This repository contains Claude plugins for Godot Engine development, including:

- **gdscript-toolkit** - GDScript utilities for file management, validation, and formatting
- **gdunit4-toolkit** - gdUnit4 testing framework integration with test runners, writers, and analyzers

## Plugin Validation

**IMPORTANT**: After modifying any plugin-related files, always validate the marketplace and plugin configurations.

### Required Validation Steps

**Validate the marketplace manifest**:
```bash
claude plugin validate .claude-plugin/marketplace.json
```

This validates the entire marketplace configuration including all plugins, skills, and agents.

### When to Validate

Run validation after:
- Modifying `.claude-plugin/marketplace.json`
- Adding/removing skills or agents
- Updating skill manifests (SKILL.md files)
- Changing plugin metadata or structure
- Modifying agent configurations

This ensures all plugin configurations are properly formatted and compatible with Claude Code before committing changes.

## Version Bumping

**IMPORTANT**: Whenever you modify anything under a plugin (skills, scripts, agents, SKILL.md, bundled binaries, etc.), you MUST bump the version numbers in `.claude-plugin/marketplace.json` in the same PR — both the affected plugin's `version` and the top-level `metadata.version` for the marketplace itself.

### How to pick the bump level

Follow semver. Match the plugin bump to the biggest change in that plugin:

- **patch** — bug fix, dependency `patch` version update, doc-only tweak that doesn't change how the skill is used
- **minor** — new skill / new agent / new feature, dependency `minor` version update, SKILL.md usage surface change (e.g. renamed commands, dropped wrapper scripts, added flags in the recommended examples)
- **major** — removed skill/agent, breaking change to how existing users must invoke things, migration to a different backing tool

Then bump the top-level `metadata.version` one level *below* the plugin bump (patch when a sub-plugin got a minor, patch when a sub-plugin got a patch, minor when a sub-plugin got a major or multiple plugins changed at once).

### Historical patterns for reference

- Formatter `0.19.x → 0.20.0` (upstream minor) → `gdscript-toolkit 1.5.x → 1.6.0` + `marketplace 1.0.0 → 1.0.1` (#23)
- Formatter `0.20.0 → 0.20.1` (upstream patch) → `gdscript-toolkit 1.6.0 → 1.6.1` (#24)
- New skill added to gdscript-toolkit + gdUnit4 v6 API update → `gdscript-toolkit 1.6.1 → 1.7.0`, `gdunit4-toolkit 2.2.0 → 2.3.0` + `marketplace 1.0.1 → 1.1.0` (#25)

### What to also check

- `README.md` intentionally does NOT list per-plugin versions (marketplace.json is the single source since #25) — do not add version numbers back to README.
- If a plugin has its own `.claude-plugin/plugin.json` (currently only `gdscript-lsp/`), keep its `version` in sync with the marketplace entry.
