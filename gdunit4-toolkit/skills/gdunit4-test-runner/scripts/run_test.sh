#!/bin/bash

# gdUnit4 Test Wrapper Script
# Suppresses Godot logs and displays only failed tests

set -e

# Use current working directory as project root
# This allows the script to work when called from user's project directory
PROJECT_ROOT="$(pwd)"

# Godot executable path (can be overridden by environment variable)
GODOT_CMD="${GODOT_PATH:-godot}"

# Check if gdUnit4 plugin exists
GDUNIT4_PATH="$PROJECT_ROOT/addons/gdUnit4"
if [ ! -d "$GDUNIT4_PATH" ]; then
  echo "Error: gdUnit4 not found at $GDUNIT4_PATH"
  echo ""
  echo "Please ensure gdUnit4 is installed in your project's addons directory."
  echo "See: https://github.com/MikeSchulze/gdUnit4"
  exit 2
fi

# Function to display help message
show_help() {
  cat << 'EOF'
Usage: ./run_test.sh [OPTIONS] [TARGET...]

OPTIONS:
  -v, --verbose    Show all Godot logs (default: suppress Godot logs)
  -h, --help       Show this help message

ARGUMENTS:
  TARGET...        Test file(s) or directory(ies) to run (default: tests/)
                   Multiple targets can be specified
                   Examples: tests/test_foo.gd, tests/application/

ENVIRONMENT VARIABLES:
  GODOT_PATH       Path to Godot executable (default: godot)
                   Example: GODOT_PATH=/usr/local/bin/godot ./run_test.sh

EXAMPLES:
  ./run_test.sh                              # Run all tests (quiet)
  ./run_test.sh tests/test_foo.gd            # Run specific test file
  ./run_test.sh tests/foo.gd tests/bar.gd    # Run multiple test files
  ./run_test.sh -v                           # Run all tests with verbose output
  ./run_test.sh -v tests/application/        # Run directory tests (verbose)
  ./run_test.sh tests/domain/ tests/app.gd   # Run directory and file
  GODOT_PATH=/custom/godot ./run_test.sh     # Use custom Godot path

EXIT CODES:
  0    All tests passed
  1    Some tests failed
  2    Error (e.g., report file not found)
EOF
}

# Parse arguments
VERBOSE=false
TARGETS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      exit 0
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done

# Default target if none specified
if [ ${#TARGETS[@]} -eq 0 ]; then
  TARGETS=("tests/")
fi

# Run tests
echo "Running tests..."
echo ""

# Add multiple targets as -a options
TARGET_ARGS=()
for target in "${TARGETS[@]}"; do
  TARGET_ARGS+=("-a" "$target")
done

# Execute Godot to run tests
set +e
if [ "$VERBOSE" = true ]; then
  # Verbose mode: show all logs
  $GODOT_CMD --headless -s -d "$GDUNIT4_PATH/bin/GdUnitCmdTool.gd" \
    "${TARGET_ARGS[@]}" --ignoreHeadlessMode -c
  GODOT_EXIT_CODE=$?
else
  # Normal mode: suppress Godot logs
  $GODOT_CMD --headless -s -d "$GDUNIT4_PATH/bin/GdUnitCmdTool.gd" \
    "${TARGET_ARGS[@]}" --ignoreHeadlessMode -c > /dev/null 2>&1
  GODOT_EXIT_CODE=$?
fi
set -e

# Get the latest report file
LATEST_REPORT=$(ls -t "$PROJECT_ROOT/reports/"*/results.xml 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
  echo "Error: Test report not found"
  exit 2
fi

# Extract information from XML
TOTAL_TESTS=$(grep -oP '<testsuites[^>]*tests="\K[0-9]+' "$LATEST_REPORT" || echo "0")
TOTAL_FAILURES=$(grep -oP '<testsuites[^>]*failures="\K[0-9]+' "$LATEST_REPORT" || echo "0")

# Display results
echo "================================================="
if [ "$TOTAL_FAILURES" -eq 0 ]; then
  echo "ALL TESTS PASSED ($TOTAL_TESTS tests)"
  echo "================================================="
  echo ""
  exit 0
else
  echo "TEST FAILURES ($TOTAL_FAILURES of $TOTAL_TESTS tests failed)"
  echo "================================================="
  echo ""

  # Extract and display failed test details
  FAILURE_COUNT=0

  # Process XML line by line
  IN_FAILURE=false
  CURRENT_TESTCASE=""
  CURRENT_CLASSNAME=""
  CURRENT_MESSAGE=""
  CURRENT_CONTENT=""

  while IFS= read -r line; do
    # Detect start of testcase tag
    if echo "$line" | grep -q '<testcase.*name='; then
      CURRENT_TESTCASE=$(echo "$line" | grep -oP 'name="\K[^"]+' || echo "")
      CURRENT_CLASSNAME=$(echo "$line" | grep -oP 'classname="\K[^"]+' || echo "")
    fi

    # Detect start of failure tag
    if echo "$line" | grep -q '<failure'; then
      IN_FAILURE=true
      CURRENT_MESSAGE=$(echo "$line" | grep -oP 'message="\K[^"]+' || echo "")
    fi

    # Collect failure content
    if [ "$IN_FAILURE" = true ]; then
      CURRENT_CONTENT+="$line"

      # Detect end of failure tag
      if echo "$line" | grep -q '</failure>'; then
        IN_FAILURE=false
        FAILURE_COUNT=$((FAILURE_COUNT + 1))

        # Extract file path and line number
        FILE_INFO=$(echo "$CURRENT_MESSAGE" | sed 's/FAILED: //' || echo "")

        # Extract expected and actual values from CDATA
        EXPECTED=$(echo "$CURRENT_CONTENT" | grep -oP "Expecting:\s*'\K[^']*" || echo "")
        ACTUAL=$(echo "$CURRENT_CONTENT" | grep -oP "but was\s*'\K[^']*" || echo "")

        # Display results
        echo "[$FAILURE_COUNT] $CURRENT_CLASSNAME :: $CURRENT_TESTCASE"
        if [ -n "$FILE_INFO" ]; then
          echo "    File: $FILE_INFO"
        fi
        if [ -n "$EXPECTED" ]; then
          echo "    Expected: '$EXPECTED'"
        fi
        if [ -n "$ACTUAL" ]; then
          echo "    Actual:   '$ACTUAL'"
        fi
        echo ""

        # Reset
        CURRENT_CONTENT=""
      fi
    fi
  done < "$LATEST_REPORT"

  echo "================================================="
  echo ""
  exit 1
fi
