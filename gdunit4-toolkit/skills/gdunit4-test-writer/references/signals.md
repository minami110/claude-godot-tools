# Signal Testing

## Basic Signal Assertions

### Wait for Signal Emission

```gdscript
func test_signal_emitted() -> void:
    var emitter := auto_free(MyEmitter.new())

    # Trigger something that emits signal
    emitter.do_action()

    # Wait until signal is emitted (default timeout: 2 seconds)
    await assert_signal(emitter).is_emitted("action_completed")
```

### Signal with Arguments

```gdscript
func test_signal_with_args() -> void:
    var emitter := auto_free(MyEmitter.new())

    emitter.set_value(42)

    # Verify signal emitted with specific arguments
    await assert_signal(emitter).is_emitted("value_changed", [42])
```

### Verify Signal NOT Emitted

```gdscript
func test_signal_not_emitted() -> void:
    var emitter := auto_free(MyEmitter.new())

    # Wait 50ms to verify signal is not emitted
    await assert_signal(emitter).wait_until(50).is_not_emitted("error_occurred")
```

### Custom Timeout

```gdscript
func test_signal_with_timeout() -> void:
    var emitter := auto_free(MyEmitter.new())

    emitter.start_long_operation()

    # Wait up to 5 seconds for signal
    await assert_signal(emitter).wait_until(5000).is_emitted("operation_done")
```

## Signal Existence Check

```gdscript
func test_signal_exists() -> void:
    var node := auto_free(Node2D.new())

    assert_signal(node)\
        .is_signal_exists("visibility_changed")\
        .is_signal_exists("draw")\
        .is_signal_exists("tree_entered")
```

## Complete Example

```gdscript
extends GdUnitTestSuite

class TestEmitter extends Node:
    signal value_changed(new_value)
    signal completed

    func set_value(v: int) -> void:
        value_changed.emit(v)

    func finish() -> void:
        completed.emit()


func test_value_signal() -> void:
    var emitter := auto_free(TestEmitter.new())
    add_child(emitter)

    emitter.set_value(100)

    await assert_signal(emitter).is_emitted("value_changed", [100])


func test_completion_signal() -> void:
    var emitter := auto_free(TestEmitter.new())
    add_child(emitter)

    emitter.finish()

    await assert_signal(emitter).is_emitted("completed")


func test_no_error_signal() -> void:
    var emitter := auto_free(TestEmitter.new())

    # Verify no unexpected signals
    await assert_signal(emitter).wait_until(100).is_not_emitted("error")
```

## Tips

- Always use `await` with signal assertions
- Use `wait_until()` to set custom timeouts (in milliseconds)
- Add emitter to scene tree with `add_child()` if signal depends on `_process` or `_physics_process`
- Use `auto_free()` to ensure cleanup
