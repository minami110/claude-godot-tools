#!/bin/bash
# TCP→stdio ブリッジ for Godot LSP
# Godot エディタの Language Server Protocol (ポート 6005) に接続します
set -euo pipefail

PORT="${GODOT_LSP_PORT:-6005}"
HOST="${GODOT_LSP_HOST:-localhost}"

# 接続確認
if ! nc -z "$HOST" "$PORT" 2>/dev/null; then
    echo "Error: Godot LSP not running on $HOST:$PORT" >&2
    echo "Please start Godot Editor with your project." >&2
    exit 1
fi

# stdio と TCP をブリッジ
exec nc "$HOST" "$PORT"
