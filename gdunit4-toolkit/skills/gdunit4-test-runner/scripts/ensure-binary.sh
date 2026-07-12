#!/bin/bash
# gdunit4-test-runner の存在確認と自動インストール
# install.sh に pin された VERSION と bin/.installed-version を突き合わせ、
# 一致しなければ再インストールする (marketplace 更新後のバージョンドリフト対策)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"
RUNNER_PATH="$BIN_DIR/gdunit4-test-runner"
VERSION_MARKER="$BIN_DIR/.installed-version"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"

if [ ! -x "$INSTALL_SCRIPT" ]; then
  echo "Error: install.sh not found at $INSTALL_SCRIPT" >&2
  exit 2
fi

# install.sh の VERSION="…" 行から期待バージョンを抽出
PINNED_VERSION="$(grep -m1 '^VERSION=' "$INSTALL_SCRIPT" | sed -E 's/^VERSION="?([^"]+)"?$/\1/')"
if [ -z "$PINNED_VERSION" ]; then
  echo "Error: could not read VERSION from $INSTALL_SCRIPT" >&2
  exit 2
fi

INSTALLED_VERSION=""
if [ -f "$VERSION_MARKER" ]; then
  INSTALLED_VERSION="$(head -n1 "$VERSION_MARKER" | tr -d '[:space:]')"
fi

# Windows (Git Bash/MSYS2) では .exe 付きでインストールされる
binary_present() {
  [ -x "$RUNNER_PATH" ] || [ -x "${RUNNER_PATH}.exe" ]
}

needs_install=0
if ! binary_present; then
  echo "gdunit4-test-runner not found. Installing v${PINNED_VERSION}..." >&2
  needs_install=1
elif [ "$INSTALLED_VERSION" != "$PINNED_VERSION" ]; then
  echo "gdunit4-test-runner version drift: installed=${INSTALLED_VERSION:-unknown}, pinned=${PINNED_VERSION}. Reinstalling..." >&2
  needs_install=1
fi

if [ "$needs_install" -eq 1 ]; then
  "$INSTALL_SCRIPT" >&2

  if ! binary_present; then
    echo "Error: Installation failed." >&2
    exit 2
  fi
  echo "gdunit4-test-runner v${PINNED_VERSION} ready." >&2
fi

exit 0
