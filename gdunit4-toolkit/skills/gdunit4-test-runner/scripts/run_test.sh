#!/bin/bash

# gdUnit4 Test Wrapper Script
# Outputs test results in JSON format for AI analysis

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
  2    Crash or error (e.g., Godot crashed, report file not found)
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
  TARGETS=("")
fi

# Add multiple targets as -a options
TARGET_ARGS=()
for target in "${TARGETS[@]}"; do
  TARGET_ARGS+=("-a" "$target")
done

# Create temporary file for capturing Godot output
GODOT_LOG=$(mktemp)
trap "rm -f $GODOT_LOG" EXIT

# Execute Godot to run tests
set +e
if [ "$VERBOSE" = true ]; then
  # Verbose mode: show all logs and save to file
  $GODOT_CMD --headless -s -d "$GDUNIT4_PATH/bin/GdUnitCmdTool.gd" \
    "${TARGET_ARGS[@]}" --ignoreHeadlessMode -c 2>&1 | tee "$GODOT_LOG"
  GODOT_EXIT_CODE=$?
else
  # Normal mode: save logs to file but don't display
  $GODOT_CMD --headless -s -d "$GDUNIT4_PATH/bin/GdUnitCmdTool.gd" \
    "${TARGET_ARGS[@]}" --ignoreHeadlessMode -c > "$GODOT_LOG" 2>&1
  GODOT_EXIT_CODE=$?
fi
set -e

# Check if Godot crashed and extract crash information
CRASHED=false
CRASH_INFO=""
SCRIPT_ERRORS=""
ENGINE_ERRORS=""

# Check if Godot actually crashed (not just test failure)
# gdUnit4 returns exit code 100 for test failures, which is not a crash
if grep -q "handle_crash:" "$GODOT_LOG"; then
  CRASHED=true

  # Extract crash information
  CRASH_INFO=$(grep -A 50 "handle_crash:" "$GODOT_LOG" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

  # Extract SCRIPT ERROR messages
  if grep -q "SCRIPT ERROR:" "$GODOT_LOG"; then
    SCRIPT_ERRORS=$(grep -A 15 "SCRIPT ERROR:" "$GODOT_LOG" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  fi

  # Extract ENGINE ERROR messages
  if grep -q "^ERROR:" "$GODOT_LOG"; then
    ENGINE_ERRORS=$(grep -A 5 "^ERROR:" "$GODOT_LOG" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  fi
fi

# Get the latest report file
LATEST_REPORT=$(ls -t "$PROJECT_ROOT/reports/"*/results.xml 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
  echo "Error: Test report not found"
  exit 2
fi

# Extract information from XML
TOTAL_TESTS=$(grep -oP '<testsuites[^>]*tests="\K[0-9]+' "$LATEST_REPORT" || echo "0")
TOTAL_FAILURES=$(grep -oP '<testsuites[^>]*failures="\K[0-9]+' "$LATEST_REPORT" || echo "0")
TOTAL_PASSED=$((TOTAL_TESTS - TOTAL_FAILURES))

# Build JSON output
JSON_OUTPUT="{"
JSON_OUTPUT+="\"summary\":{"
JSON_OUTPUT+="\"total\":$TOTAL_TESTS,"
JSON_OUTPUT+="\"passed\":$TOTAL_PASSED,"
JSON_OUTPUT+="\"failed\":$TOTAL_FAILURES,"
JSON_OUTPUT+="\"crashed\":$CRASHED,"

if [ "$CRASHED" = true ]; then
  JSON_OUTPUT+="\"status\":\"crashed\""
elif [ "$TOTAL_FAILURES" -eq 0 ]; then
  JSON_OUTPUT+="\"status\":\"passed\""
else
  JSON_OUTPUT+="\"status\":\"failed\""
fi

JSON_OUTPUT+="},"

# Add crash information if crashed
if [ "$CRASHED" = true ]; then
  JSON_OUTPUT+="\"crash_details\":{"

  if [ -n "$CRASH_INFO" ]; then
    JSON_OUTPUT+="\"crash_info\":\"$CRASH_INFO\","
  fi

  if [ -n "$SCRIPT_ERRORS" ]; then
    JSON_OUTPUT+="\"script_errors\":\"$SCRIPT_ERRORS\","
  fi

  if [ -n "$ENGINE_ERRORS" ]; then
    JSON_OUTPUT+="\"engine_errors\":\"$ENGINE_ERRORS\","
  fi

  # Remove trailing comma if present
  JSON_OUTPUT="${JSON_OUTPUT%,}"
  JSON_OUTPUT+="},"
fi

JSON_OUTPUT+="\"failures\":["

# Extract failed test details if any
if [ "$TOTAL_FAILURES" -gt 0 ]; then
  FAILURE_COUNT=0
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

        # Add comma if not first failure
        if [ "$FAILURE_COUNT" -gt 0 ]; then
          JSON_OUTPUT+=","
        fi
        FAILURE_COUNT=$((FAILURE_COUNT + 1))

        # Extract file path and line number
        FILE_INFO=$(echo "$CURRENT_MESSAGE" | sed 's/FAILED: //' || echo "")
        # Handle Godot paths like res://path/to/file.gd:123
        if [[ "$FILE_INFO" =~ ^(res://[^:]+):([0-9]+)$ ]]; then
          FILE_PATH="${BASH_REMATCH[1]}"
          LINE_NUM="${BASH_REMATCH[2]}"
        else
          FILE_PATH="$FILE_INFO"
          LINE_NUM="0"
        fi

        # Extract expected and actual values from CDATA
        EXPECTED=$(echo "$CURRENT_CONTENT" | grep -oP "Expecting:\s*'\K[^']*" || echo "")
        # Support both "but is" and "but was" patterns
        ACTUAL=$(echo "$CURRENT_CONTENT" | grep -oP "but (?:is|was)\s*'\K[^']*" || echo "")

        # Escape quotes, backslashes, and control characters for JSON
        CURRENT_CLASSNAME_ESC=$(echo "$CURRENT_CLASSNAME" | tr -d '\n\r' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
        CURRENT_TESTCASE_ESC=$(echo "$CURRENT_TESTCASE" | tr -d '\n\r' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
        FILE_PATH_ESC=$(echo "$FILE_PATH" | tr -d '\n\r' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
        EXPECTED_ESC=$(echo "$EXPECTED" | tr -d '\n\r' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
        ACTUAL_ESC=$(echo "$ACTUAL" | tr -d '\n\r' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')
        CURRENT_MESSAGE_ESC=$(echo "$CURRENT_MESSAGE" | tr -d '\n\r' | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g')

        # Add failure object
        JSON_OUTPUT+="{"
        JSON_OUTPUT+="\"class\":\"$CURRENT_CLASSNAME_ESC\","
        JSON_OUTPUT+="\"method\":\"$CURRENT_TESTCASE_ESC\","
        JSON_OUTPUT+="\"file\":\"$FILE_PATH_ESC\","
        JSON_OUTPUT+="\"line\":$LINE_NUM,"
        JSON_OUTPUT+="\"expected\":\"$EXPECTED_ESC\","
        JSON_OUTPUT+="\"actual\":\"$ACTUAL_ESC\","
        JSON_OUTPUT+="\"message\":\"$CURRENT_MESSAGE_ESC\""
        JSON_OUTPUT+="}"

        # Reset
        CURRENT_CONTENT=""
      fi
    fi
  done < "$LATEST_REPORT"
fi

JSON_OUTPUT+="]"
JSON_OUTPUT+="}"

# Output JSON
echo "$JSON_OUTPUT"

# Exit with appropriate code
if [ "$CRASHED" = true ]; then
  exit 2
elif [ "$TOTAL_FAILURES" -eq 0 ]; then
  exit 0
else
  exit 1
fi
