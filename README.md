# claude-godot-tools

A collection of Claude Code plugins for Godot Engine development.

## Installation

1. Add the marketplace:

```bash
claude plugin marketplace add minami110/claude-godot-tools
```

2. Install plugins:

```bash
claude plugin install gdscript-toolkit@claude-godot-tools
claude plugin install gdscript-lsp@claude-godot-tools
claude plugin install vscode-gdscript-tools@claude-godot-tools
claude plugin install gdunit4-toolkit@claude-godot-tools
```

## Plugins

### gdscript-toolkit (v1.4.0)

GDScript utilities for file management, validation, formatting, and API research.

**Skills:** `gdscript-file-manager`, `gdscript-format`, `godot-doc-search`
**Agents:** `godot-doc-search`

### gdscript-lsp (dev)

GDScript language server for Godot Engine.

### vscode-gdscript-tools (v1.0.0)

VSCode-dependent GDScript development tools requiring IDE MCP integration.

**Skills:** `gdscript-diagnostics`

### gdunit4-toolkit (v1.5.1)

[gdUnit4](https://github.com/godot-gdunit-labs/gdUnit4) testing framework integration for Godot.

**Skills:** `gdunit4-test-runner`, `gdunit4-test-writer`
**Agents:** `gdunit4-test-runner`
