#!/bin/bash
# gdunit4-test-runner の存在確認と自動インストール
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNNER_PATH="$SCRIPT_DIR/../bin/gdunit4-test-runner"

# Windows (Git Bash/MSYS2) では .exe 付きでインストールされる
if [ ! -x "$RUNNER_PATH" ] && [ ! -x "${RUNNER_PATH}.exe" ]; then
  echo "gdunit4-test-runner not found. Installing..." >&2

  # install.sh を実行
  if [ -x "$SCRIPT_DIR/install.sh" ]; then
    "$SCRIPT_DIR/install.sh" >&2

    # インストール後の確認
    if [ ! -x "$RUNNER_PATH" ] && [ ! -x "${RUNNER_PATH}.exe" ]; then
      echo "Error: Installation failed." >&2
      exit 2
    fi
    echo "gdunit4-test-runner installed successfully." >&2
  else
    echo "Error: install.sh not found at $SCRIPT_DIR/install.sh" >&2
    exit 2
  fi
fi

exit 0
