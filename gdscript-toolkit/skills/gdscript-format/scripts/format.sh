#!/bin/bash

# GDScript Format Script
# Formats GDScript files using gdscript-formatter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Function to display help message
show_help() {
  cat << 'EOF'
Usage: ./format.sh [OPTIONS] FILE...

OPTIONS:
  --safe           Verify formatting doesn't change code semantics
  --check          Return exit code 1 if changes needed (CI mode)
  --reorder-code   Reorder code according to GDScript style guide
  -h, --help       Show this help message

ARGUMENTS:
  FILE...          GDScript file(s) to format

EXAMPLES:
  ./format.sh player.gd                    # Format single file
  ./format.sh src/*.gd                     # Format multiple files
  ./format.sh --safe player.gd             # Format with safety check
  ./format.sh --check player.gd            # Check if formatting needed

EXIT CODES:
  0    Success (formatted or no changes needed)
  1    Changes needed (--check mode) or formatting issues
  2    Error (binary not found, invalid file, etc.)
EOF
}

# Platform detection for binary path
if [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || "$(uname -s)" == CYGWIN* ]]; then
  FORMATTER="$BIN_DIR/gdscript-formatter.exe"
else
  FORMATTER="$BIN_DIR/gdscript-formatter"
fi

# Check for help flag first
for arg in "$@"; do
  case $arg in
    -h|--help)
      show_help
      exit 0
      ;;
  esac
done

# Check if binary exists
if [ ! -f "$FORMATTER" ]; then
  echo "Error: gdscript-formatter not found"
  echo ""
  echo "Please run scripts/install.sh first to install the formatter."
  exit 2
fi

# Execute formatter
exec "$FORMATTER" "$@"
