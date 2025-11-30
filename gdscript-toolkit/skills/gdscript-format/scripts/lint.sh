#!/bin/bash

# GDScript Lint Script
# Checks GDScript files for style issues using gdscript-formatter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$SCRIPT_DIR/../bin"

# Function to display help message
show_help() {
  cat << 'EOF'
Usage: ./lint.sh [OPTIONS] FILE...

OPTIONS:
  --max-line-length N     Set maximum line length (default: 100)
  --disable RULES         Disable specific rules (comma-separated)
  --list-rules            Show all available lint rules
  --pretty                Human-readable output format
  -h, --help              Show this help message

ARGUMENTS:
  FILE...                 GDScript file(s) to lint

AVAILABLE RULES:
  Naming:  function-name, class-name, variable-name, signal-name,
           constant-name, enum-name, enum-member-name
  Quality: unused-argument, max-line-length, no-else-return,
           private-access, duplicated-load, unnecessary-pass

EXAMPLES:
  ./lint.sh player.gd                              # Lint single file
  ./lint.sh --max-line-length 120 player.gd        # Custom line length
  ./lint.sh --disable unused-argument player.gd    # Disable rule
  ./lint.sh --list-rules                           # Show all rules

EXIT CODES:
  0    No issues found
  1    Issues found
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

# Execute lint command
exec "$FORMATTER" lint "$@"
