#!/bin/bash

# GDScript Formatter Install Script
# Downloads and installs gdscript-formatter binary for your platform

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"
VERSION="0.18.1"
BASE_URL="https://github.com/GDQuest/GDScript-formatter/releases/download/${VERSION}"

# Function to display help message
show_help() {
  cat << 'EOF'
Usage: ./install.sh [OPTIONS]

OPTIONS:
  -h, --help       Show this help message

DESCRIPTION:
  Downloads and installs gdscript-formatter binary for your platform.
  Supported platforms: Linux x86_64, Windows x86_64 (via Git Bash/MSYS2)

  Binary is installed to: <skill>/bin/gdscript-formatter

EXAMPLES:
  ./install.sh              # Install formatter

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
    PLATFORM="linux-x86_64"
    EXT=""
    ;;
  MINGW*|MSYS*|CYGWIN*)
    PLATFORM="windows-x86_64"
    EXT=".exe"
    ;;
  *)
    echo "Error: Unsupported platform: $(uname -s)"
    echo ""
    echo "Supported platforms: Linux, Windows (via Git Bash/MSYS2)"
    exit 1
    ;;
esac

FILENAME="gdscript-formatter-${VERSION}-${PLATFORM}${EXT}.zip"
URL="${BASE_URL}/${FILENAME}"

echo "Installing gdscript-formatter v${VERSION} for ${PLATFORM}..."
echo ""

# Create bin directory
mkdir -p "$BIN_DIR"
cd "$BIN_DIR"

# Download
echo "Downloading from: $URL"
if ! curl -sL "$URL" -o formatter.zip; then
  echo "Error: Failed to download formatter"
  exit 1
fi

# Extract
echo "Extracting..."
unzip -o formatter.zip
rm formatter.zip

# Rename extracted binary to standard name
EXTRACTED_NAME="gdscript-formatter-${VERSION}-${PLATFORM}${EXT}"
if [ -f "$EXTRACTED_NAME" ]; then
  mv "$EXTRACTED_NAME" "gdscript-formatter${EXT}"
fi

# Make executable (Linux)
if [ -z "$EXT" ]; then
  chmod +x "gdscript-formatter"
fi

echo ""
echo "================================================="
echo "gdscript-formatter v${VERSION} installed successfully!"
echo "================================================="
echo ""
echo "Binary location: $BIN_DIR/gdscript-formatter${EXT}"

exit 0
