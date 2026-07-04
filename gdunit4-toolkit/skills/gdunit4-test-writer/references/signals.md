# Signal Testing

Since gdUnit4 v6, `is_emitted()` accepts a **Signal reference** (preferred, refactoring-safe) or a string name, and expected signal arguments are passed **variadically** (not as an array).

```gdscript
await assert_signal(emitter).is_emitted(emitter.value_changed, 42)   # preferred
await assert_signal(emitter).is_emitted("value_changed", 42)         # also accepted
await assert_signal(emitter).is_emitted("value_changed", [42])       # pre-v6 style, still works
```

## Basic Signal Assertions

### Wait for Signal Emission

```gdscript
func test_signal_emitted() -> void:
    var emitter := auto_free(MyEmitter.new())

    # Trigger something that emits signal
    emitter.do_action()

    # Wait until signal is emitted (default timeout: 2 seconds)
    await assert_signal(emitter).is_emitted(emitter.action_completed)
```

### Signal with Arguments

```gdscript
func test_signal_with_args() -> void:
    var emitter := auto_free(MyEmitter.new())

    emitter.set_value(42)

    # Verify signal emitted with specific arguments (variadic)
    await assert_signal(emitter).is_emitted(emitter.value_changed, 42)
```

### Verify Signal NOT Emitted

```gdscript
func test_signal_not_emitted() -> void:
    var emitter := auto_free(MyEmitter.new())

    # Wait 50ms to verify signal is not emitted
    await assert_signal(emitter).wait_until(50).is_not_emitted(emitter.error_occurred)
```

### Custom Timeout

```gdscript
func test_signal_with_timeout() -> void:
    var emitter := auto_free(MyEmitter.new())

    emitter.start_long_operation()

    # Wait up to 5 seconds for signal
    await assert_signal(emitter).wait_until(5000).is_emitted(emitter.operation_done)
```

## Monitoring Signals Emitted Before the Assertion

`assert_signal(emitter)` starts watching at call time. If the action that emits the signal runs *before* the assertion (the common Arrange-Act-Assert order), start monitoring first with `monitor_signals()`:

```gdscript
func test_with_monitor() -> void:
    var emitter := monitor_signals(MyEmitter.new())  # auto-freed by default

    # Act: signal fires here, before the assertion
    emitter.do_action()

    # The collected emission is still detected
    await assert_signal(emitter).is_emitted(emitter.action_completed)
```

`monitor_signals(source)` returns the source itself and applies `auto_free()` unless called with `monitor_signals(source, false)`.

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
    var emitter := monitor_signals(TestEmitter.new())
    add_child(emitter)

    emitter.set_value(100)

    await assert_signal(emitter).is_emitted(emitter.value_changed, 100)


func test_completion_signal() -> void:
    var emitter := monitor_signals(TestEmitter.new())
    add_child(emitter)

    emitter.finish()

    await assert_signal(emitter).is_emitted(emitter.completed)


func test_no_error_signal() -> void:
    var emitter := auto_free(TestEmitter.new())

    # Verify no unexpected signals
    await assert_signal(emitter).wait_until(100).is_not_emitted("error")
```

## Tips

- **Always `await` signal assertions** — a missing `await` silently voids the assertion (it never fails)
- Prefer Signal references (`emitter.my_signal`) over string names — typos become compile errors instead of silent timeouts
- Use `monitor_signals()` when the emission happens before the assertion line
- Use `wait_until()` to set custom timeouts (in milliseconds); `is_not_emitted` without it blocks for the default 2000ms
- Add emitter to scene tree with `add_child()` if signal depends on `_process` or `_physics_process`
- Use `auto_free()` to ensure cleanup (`monitor_signals()` applies it by default)
