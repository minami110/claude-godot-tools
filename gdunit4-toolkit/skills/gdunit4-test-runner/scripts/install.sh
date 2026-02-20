#!/bin/bash

# gdunit4-test-runner Install Script
# Downloads and installs gdunit4-test-runner binary for your platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"
VERSION="0.1.0"
BASE_URL="https://github.com/minami110/gdunit4-test-runner/releases/download/${VERSION}"

# Function to display help message
show_help() {
  cat << 'EOF'
Usage: ./install.sh [OPTIONS]

OPTIONS:
  -h, --help       Show this help message

DESCRIPTION:
  Downloads and installs gdunit4-test-runner binary for your platform.
  Supported platforms: Linux x86_64, Windows x86_64 (via Git Bash/MSYS2)

  Binary is installed to: <skill>/bin/gdunit4-test-runner

EXAMPLES:
  ./install.sh              # Install binary

EXIT CODES:
  0    Success
  1    Error (unsupported platform, download failed, etc.)
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information."
      exit 1
      ;;
  esac
done

# Platform detection
case "$(uname -s)" in
  Linux*)
    BINARY_NAME="gdunit4-test-runner-linux-amd64"
    OUTPUT_NAME="gdunit4-test-runner"
    EXT=""
    ;;
  MINGW*|MSYS*|CYGWIN*)
    BINARY_NAME="gdunit4-test-runner-windows-amd64.exe"
    OUTPUT_NAME="gdunit4-test-runner.exe"
    EXT=".exe"
    ;;
  *)
    echo "Error: Unsupported platform: $(uname -s)"
    echo ""
    echo "Supported platforms: Linux, Windows (via Git Bash/MSYS2)"
    exit 1
    ;;
esac

URL="${BASE_URL}/${BINARY_NAME}"

echo "Installing gdunit4-test-runner v${VERSION} for $(uname -s)..."
echo ""

# Create bin directory
mkdir -p "$BIN_DIR"

# Download directly to bin directory
echo "Downloading from: $URL"
if ! curl -sL "$URL" -o "$BIN_DIR/$OUTPUT_NAME"; then
  echo "Error: Failed to download gdunit4-test-runner"
  exit 1
fi

# Make executable (Linux)
if [ -z "$EXT" ]; then
  chmod +x "$BIN_DIR/$OUTPUT_NAME"
fi

echo ""
echo "================================================="
echo "gdunit4-test-runner v${VERSION} installed successfully!"
echo "================================================="
echo ""
echo "Binary location: $BIN_DIR/$OUTPUT_NAME"

exit 0
