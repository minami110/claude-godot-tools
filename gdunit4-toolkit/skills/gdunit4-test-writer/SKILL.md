---
name: gdunit4-test-writer
description: Write gdUnit4 test code with type-specific assertions, signal testing, and scene runner support. Use when creating or updating tests for GDScript files.
allowed-tools:
  - mcp__context7__resolve-library-id
  - mcp__context7__query-docs
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# gdUnit4 Test Writer

Write gdUnit4 test code for GDScript files with proper assertions and test structure.

## Workflow

1. **Analyze target file** - Read the GDScript file to understand what needs testing
2. **Check gdUnit4 docs** - Use Context7 (`/websites/godot-gdunit-labs_github_io_gdunit4`) if needed
3. **Select assertions** - Use type-specific assertions (see [references/assertions.md])
4. **Create test file** - Place in `res://tests/` directory with `test_*.gd` naming (e.g., `test_player.gd`)

## Quick Reference

### Test File Template

```gdscript
extends GdUnitTestSuite

func test_example() -> void:
    assert_int(1).is_equal(1)
```

### Common Assertions

- **int**: `assert_int(value).is_equal(10)`
- **float**: `assert_float(value).is_equal_approx(3.14, 0.01)`
- **String**: `assert_str(text).contains("hello")`
- **Array**: `assert_array(items).has_size(5)`
- **Object**: `assert_object(node).is_not_null()`
- **Signal**: `await assert_signal(emitter).is_emitted(emitter.my_signal)` (Signal reference preferred; string name also accepted)

### Memory Management

```gdscript
func test_with_node() -> void:
    var node: Node = auto_free(Node.new())  # Auto-freed after test
    assert_object(node).is_not_null()
```

## Version Compatibility

| gdUnit4 | Godot |
|---------|-------|
| v6.x | 4.5+ |
| v5.x | 4.3 – 4.4.1 |
| v4.4.0+ | 4.2+ |

These references target gdUnit4 v6. Pre-v6 array-style arguments (e.g. `contains([1, 2])`, `is_emitted("sig", [args])`) are still accepted for backward compatibility, but prefer the v6 variadic style shown here.

## References

- [references/assertions.md](references/assertions.md) - Complete assertion reference
- [references/test-structure.md](references/test-structure.md) - Test lifecycle and structure
- [references/signals.md](references/signals.md) - Signal testing guide
- [references/scene-runner.md](references/scene-runner.md) - Scene runner for integration tests
- [references/parameterized-tests.md](references/parameterized-tests.md) - Parameterized tests and fuzzing

## Context7 Library ID

For detailed gdUnit4 documentation:
- Library ID: `/websites/godot-gdunit-labs_github_io_gdunit4`
