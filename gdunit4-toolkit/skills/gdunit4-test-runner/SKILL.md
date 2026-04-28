---
name: gdunit4-test-runner
description: |
  Run gdUnit4 tests for Godot projects and report results (read-only).
  Use to verify test status after code changes.
  USE PROACTIVELY to check test results.
context: fork
agent: gdunit4-test-runner
allowed-tools:
  - Bash
---

# GDScript Test

Run GDUnit4 tests using the gdunit4-test-runner binary.

## When to Use

- After implementing new features
- After modifying GDScript files
- When you need to verify test coverage
- When running CI/CD validation locally

## Setup

Before running tests, ensure the binary is installed:

1. Check if `bin/gdunit4-test-runner` exists in the skill directory
2. If not, run the install script:
   ```bash
   ${CLAUDE_PLUGIN_ROOT}/skills/gdunit4-test-runner/scripts/install.sh
   ```

## Test Execution

Run tests using the binary directly.

**NEVER use `addons/gdUnit4/runtest.sh` or direct `godot` commands.**

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
  "crash_details": null,
  "failures": []
}
```

Godot crashed during test execution. Only tests completed before crash are reported.

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
