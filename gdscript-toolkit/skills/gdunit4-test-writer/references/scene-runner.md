# Scene Runner

Use Scene Runner for integration tests that require a full scene context.

## Basic Usage

### Load and Run Scene

```gdscript
func test_scene() -> void:
    var runner := scene_runner("res://scenes/my_scene.tscn")

    # Simulate 60 frames
    await runner.simulate_frames(60)

    # Access scene root
    var scene: Node = runner.scene()
    assert_object(scene).is_not_null()
```

### Simulate with Delta Time

```gdscript
func test_scene_timing() -> void:
    var runner := scene_runner("res://scenes/game.tscn")

    # Simulate 60 frames with 100ms between each frame
    await runner.simulate_frames(60, 100)
```

## Accessing Scene Nodes

```gdscript
func test_scene_children() -> void:
    var runner := scene_runner("res://scenes/player.tscn")

    # Get scene root
    var scene: Node = runner.scene()

    # Find child nodes
    var sprite: Sprite2D = scene.get_node("Sprite2D")
    assert_object(sprite).is_not_null()
```

## Waiting for Conditions

### Wait for Function Result

```gdscript
func test_wait_for_state() -> void:
    var runner := scene_runner("res://scenes/game.tscn")

    # Trigger some action
    runner.scene().start_game()

    # Wait until function returns expected value
    await runner.await_func("get_state").is_equal("playing")
```

### Wait for Signal

```gdscript
func test_wait_for_signal() -> void:
    var runner := scene_runner("res://scenes/game.tscn")

    runner.scene().start_loading()

    # Wait for signal from scene
    await assert_signal(runner.scene()).is_emitted("loading_complete")
```

## Input Simulation

### Mouse Input

```gdscript
func test_mouse_click() -> void:
    var runner := scene_runner("res://scenes/ui.tscn")

    # Simulate mouse click at position
    runner.simulate_mouse_button_pressed(MOUSE_BUTTON_LEFT)
    await runner.simulate_frames(1)
    runner.simulate_mouse_button_released(MOUSE_BUTTON_LEFT)
```

### Keyboard Input

```gdscript
func test_keyboard_input() -> void:
    var runner := scene_runner("res://scenes/game.tscn")

    # Press and release key
    runner.simulate_key_pressed(KEY_SPACE)
    await runner.simulate_frames(1)
    runner.simulate_key_released(KEY_SPACE)
```

### Action Input

```gdscript
func test_action_input() -> void:
    var runner := scene_runner("res://scenes/player.tscn")

    # Simulate action press
    runner.simulate_action_pressed("jump")
    await runner.simulate_frames(10)
    runner.simulate_action_released("jump")
```

## Debugging

### Show Scene Window

```gdscript
func test_with_visible_window() -> void:
    var runner := scene_runner("res://scenes/game.tscn")

    # Show window for debugging
    runner.move_window_to_foreground()

    await runner.simulate_frames(120)
```

## Complete Example

```gdscript
extends GdUnitTestSuite

func test_player_movement() -> void:
    var runner := scene_runner("res://scenes/player.tscn")
    var player: CharacterBody2D = runner.scene()

    var initial_pos := player.position

    # Simulate right movement
    runner.simulate_action_pressed("move_right")
    await runner.simulate_frames(30)
    runner.simulate_action_released("move_right")

    # Verify player moved
    assert_vector(player.position).is_greater(initial_pos)


func test_game_initialization() -> void:
    var runner := scene_runner("res://scenes/main.tscn")

    await runner.simulate_frames(1)

    var game: Node = runner.scene()
    await runner.await_func("is_ready").is_true()

    assert_object(game.get_node("Player")).is_not_null()
    assert_object(game.get_node("UI")).is_not_null()
```

## Tips

- Scene Runner automatically manages scene lifecycle (freed after test)
- Use `move_window_to_foreground()` to visually debug tests
- Combine with signal assertions for async operations
- Input simulation requires `simulate_frames()` to process
