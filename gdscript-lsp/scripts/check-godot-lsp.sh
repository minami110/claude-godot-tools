#!/bin/bash
set -euo pipefail
PORT="${GODOT_LSP_PORT:-6005}"

if nc -z localhost "$PORT" 2>/dev/null; then
    echo "✓ Godot LSP server is running on port $PORT"
    echo "  LSP features are available for .gd files"
else
    echo "⚠ Godot LSP server not detected on port $PORT"
    echo ""
    echo "To enable LSP features:"
    echo "  1. Start Godot Editor with your project"
    echo "  2. Check: Editor > Editor Settings > Network > Language Server"
    echo "  3. Verify port is set to $PORT"
    echo "  4. Restart Claude Code session"
fi
exit 0
