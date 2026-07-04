# gdscript-lsp

GDScript language server integration for Claude Code.

## Overview

This plugin enables Claude Code to connect to Godot Engine's built-in GDScript LSP (Language Server Protocol) server, providing code intelligence features such as:

- Go to definition
- Find references
- Hover documentation
- Symbol search
- Code completion support

## Prerequisites

### 1. Godot Editor Running

The Godot Editor must be running with your project open. The LSP server runs inside Godot Editor on port **6005** by default.

### 2. Enable LSP in Godot

Ensure the Language Server is enabled in Godot:
- Open Godot Editor
- Go to **Editor > Editor Settings > Network > Language Server**
- Verify that LSP is enabled and listening on port 6005

### 3. Enable LSP Tools in Claude Code

Claude Code requires the `ENABLE_LSP_TOOL=true` environment variable to use LSP features.

#### Set environment variable before launching Claude

```bash
ENABLE_LSP_TOOL=true claude
```

## How It Works

When you start a Claude session, this plugin:

1. Checks if Godot LSP server is running on port 6005
2. Displays a status message indicating whether the server is available
3. Configures Claude Code to route `.gd` file requests to the Godot LSP server

## LSP Configuration

The plugin uses the following configuration (defined in `.claude-plugin/plugin.json` under `lspServers`):

- **Transport**: stdio-to-TCP bridge (`scripts/godot-lsp-bridge.sh`, netcat-based)
- **Host**: localhost — override with `GODOT_LSP_HOST`
- **Port**: 6005 — override with `GODOT_LSP_PORT`
- **File extension**: `.gd` → `gdscript` language

## Troubleshooting

### "Godot LSP server not detected on port 6005"

If you see this warning:

1. Ensure Godot Editor is running
2. Open a Godot project (LSP only runs when a project is open)
3. Check LSP settings in Godot Editor: **Editor > Editor Settings > Network > Language Server**
4. Verify the port is set to 6005

### Manual connection test

You can test the Godot LSP connection manually:

```bash
# Check if nc is available
which nc

# Test connection to Godot LSP
nc -z localhost 6005 && echo "Connected" || echo "Failed"
```

### LSP features not working

1. Verify `ENABLE_LSP_TOOL=true` is set (check with `echo $ENABLE_LSP_TOOL`)
2. Restart Claude Code after setting the environment variable
3. Check that the `.gd` file you're working with is part of an open Godot project
4. Try manually testing the connection with the commands above

### Custom host/port configuration

If Godot LSP is running on a different port (or host), you can set:

```bash
GODOT_LSP_PORT=6006 ENABLE_LSP_TOOL=true claude
```

`GODOT_LSP_HOST` is also available (default: `localhost`).

## License

MIT
