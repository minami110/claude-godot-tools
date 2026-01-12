#!/bin/bash
# gdscript-formatter の存在確認と自動インストール

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FORMATTER_PATH="$SCRIPT_DIR/../bin/gdscript-formatter"

if [ ! -x "$FORMATTER_PATH" ]; then
  echo "gdscript-formatter not found. Installing..." >&2

  # install.sh を実行
  if [ -x "$SCRIPT_DIR/install.sh" ]; then
    "$SCRIPT_DIR/install.sh" >&2

    # インストール後の確認
    if [ ! -x "$FORMATTER_PATH" ]; then
      echo "Error: Installation failed." >&2
      exit 2
    fi
    echo "gdscript-formatter installed successfully." >&2
  else
    echo "Error: install.sh not found at $SCRIPT_DIR/install.sh" >&2
    exit 2
  fi
fi

exit 0
