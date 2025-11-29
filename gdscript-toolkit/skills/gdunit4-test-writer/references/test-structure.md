# Test Structure

## Basic Template

```gdscript
extends GdUnitTestSuite

func test_example() -> void:
    assert_int(1).is_equal(1)
```

## Full Template with Lifecycle Hooks

```gdscript
class_name TestMyClass
extends GdUnitTestSuite

var _test_data: Node

# Called once before test suite starts
func before():
    pass

# Called before each test
func before_test():
    _test_data = auto_free(Node.new())

# Test methods must start with test_
func test_example() -> void:
    assert_object(_test_data).is_not_null()

func test_another_example() -> void:
    assert_int(1 + 1).is_equal(2)

# Called after each test
func after_test():
    pass

# Called once after test suite ends
func after():
    pass
```

## Lifecycle Order

```
before()           # Once at start
├── before_test()  # Before test 1
│   └── test_a()
│   └── after_test()
├── before_test()  # Before test 2
│   └── test_b()
│   └── after_test()
after()            # Once at end
```

## Memory Management

### auto_free

Use `auto_free()` to automatically free objects after test completes:

```gdscript
func test_with_node() -> void:
    var node := auto_free(Node.new())
    assert_object(node).is_not_null()
    # node is automatically freed after this test
```

### Scope of auto_free

```gdscript
var _suite_obj: Node
var _test_obj: Node

func before():
    # Freed after entire suite completes
    _suite_obj = auto_free(Node.new())

func before_test():
    # Freed after each test completes
    _test_obj = auto_free(Node.new())

func test_example() -> void:
    # Freed after this specific test
    var local_obj := auto_free(Node.new())
```

## Test File Placement

- **Directory**: `res://tests/`
- **File naming**: `test_*.gd` or `*_test.gd`
- **Class naming**: `Test*` (e.g., `TestPlayer`, `TestInventory`)

### Directory Structure Example

```
res://tests/
├── test_player.gd
├── test_inventory.gd
├── core/
│   └── test_game_time.gd
└── controllers/
    └── test_input_handler.gd
```

## Async Tests

For tests that need to wait:

```gdscript
func test_async_operation() -> void:
    var result := await some_async_function()
    assert_int(result).is_equal(42)
```

## Skipping Tests

### Skip a Single Test

```gdscript
@warning_ignore('unused_parameter')
func test_skip_this(do_skip=true) -> void:
    # This test will be skipped
    pass
```

### Skip Entire Suite

```gdscript
@warning_ignore('unused_parameter')
func before(do_skip=true):
    # All tests in this suite will be skipped
    pass
```
