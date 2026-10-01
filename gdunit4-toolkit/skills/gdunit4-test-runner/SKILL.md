---
name: gdunit4-test-runner
description: |
  Run gdUnit4 tests for Godot projects and report results (read-only).
  Use to verify test status after code changes.
  USE PROACTIVELY to check test results.
allowed-tools:
  - Bash
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/scripts/ensure-binary.sh"
          once: true
---

# GDScript Test

Run GDUnit4 tests using the gdunit4-test-runner binary.

## CRITICAL: Read-Only Operation

- This is a read-only operation.
- Run the binary and report results. DO NOT edit files or attempt to fix failing tests.
- If tests fail, report file path, line number, assertion details — then STOP.
- NEVER use `addons/gdUnit4/runtest.sh` or direct `godot` commands.

## When to Use

- After implementing new features
- After modifying GDScript files
- When you need to verify test coverage
- When running CI/CD validation locally

## Setup

The binary is installed automatically on first use (via a skill hook). To install manually:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/scripts/install.sh
```

## Test Execution

Run tests using the binary directly.

### Run All Tests

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/bin/gdunit4-test-runner
```

Scans entire project for tests.

### Run Specific Test File

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/bin/gdunit4-test-runner tests/test_foo.gd
```

### Run Multiple Tests

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/bin/gdunit4-test-runner tests/test_foo.gd tests/test_bar.gd
```

### Run Tests in Directory

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/bin/gdunit4-test-runner tests/application/
```

### Verbose Mode

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/bin/gdunit4-test-runner --verbose
```

Shows all Godot logs (useful for debugging test issues).

### Custom Godot Path

```bash
${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/bin/gdunit4-test-runner --godot-path /path/to/godot
```

## Understanding Results

The binary outputs test results in JSON format for easy parsing.

### Success
```json
{
  "summary": {
    "total": 186,
    "passed": 186,
    "failed": 0,
    "crashed": false,
    "status": "passed"
  },
  "failures": []
}
```

### Failure
```json
{
  "summary": {
    "total": 10,
    "passed": 8,
    "failed": 2,
    "crashed": false,
    "status": "failed"
  },
  "failures": [
    {
      "class": "TestClassName",
      "method": "test_method_name",
      "file": "res://tests/test_file.gd",
      "line": 42,
      "expected": "expected_value",
      "actual": "actual_value",
      "message": "FAILED: res://tests/test_file.gd:42"
    }
  ]
}
```

### Crash
```json
{
  "summary": {
    "total": 5,
    "passed": 3,
    "failed": 0,
    "crashed": true,
    "status": "crashed"
  },
  "crash_details": {
    "crash_info": "...",
    "script_errors": "..."
  },
  "failures": []
}
```

`crashed` means Godot crashed (`handle_crash:`) or no test report was produced (e.g. a test script failed to compile). Only tests completed before the crash are reported.

### Script Errors

`SCRIPT ERROR:` lines alone do NOT mark a run as crashed. When a complete report exists, they appear in `crash_details.script_errors` as diagnostics while `status` stays `passed` or `failed`. Mention them in the report if present.

## Exit Codes

- **0**: All tests passed
- **1**: Some tests failed
- **2**: Crash or error (e.g., Godot crashed, report file not found)

## Notes

- Binary automatically changes to project root before running tests
- Test reports are saved in `reports/` directory
- Uses gdUnit4 framework (configured in project.godot)
- Compatible with CI/CD environments
- Binary handles Godot existence check and error handling internally
