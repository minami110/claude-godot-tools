#!/bin/bash
# Godot Engine の存在確認

GODOT_CMD="${GODOT_PATH:-godot}"

if ! command -v "$GODOT_CMD" &> /dev/null; then
  cat << 'EOF' >&2
Error: Godot Engine is not installed or not in PATH.

To fix this:
1. Install Godot Engine from https://godotengine.org/download
2. Add Godot to your PATH, or set GODOT_PATH environment variable

Example:
  export GODOT_PATH=/path/to/godot
EOF
  exit 2
fi

echo "Godot found: $($GODOT_CMD --version 2>/dev/null || echo 'version unknown')" >&2
exit 0
