#!/bin/bash
# Bash コマンドをインターセプトし、テスト実行時は run_test.sh を使用

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# addons/gdUnit4/runtest.sh を使おうとしている場合はブロック
if echo "$COMMAND" | grep -E 'addons/gdUnit4/runtest\.sh' > /dev/null; then
  echo "BLOCKED: Do not use addons/gdUnit4/runtest.sh" >&2
  echo "Use this instead: ${SCRIPT_DIR}/run_test.sh" >&2
  exit 2
fi

# 許可（他のコマンドはそのまま実行）
exit 0
