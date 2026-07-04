# Parameterized Tests & Fuzzing

## Parameterized Tests (test_parameters)

Run one test function against multiple input sets using the special `test_parameters` argument. It must be the **last** parameter, and its default value is a 2D array where each row is one invocation's arguments:

```gdscript
func test_add(a: int, b: int, expected: int, test_parameters := [
    [1, 2, 3],
    [4, 5, 9],
    [-1, 1, 0],
]) -> void:
    assert_int(a + b).is_equal(expected)
```

Each row runs as its own test case; `before_test()` / `after_test()` run around every row.

### Pitfalls

1. **Lambdas inside `test_parameters` must be single-line.** A block-form (multi-line) lambda causes `Parse Error: Expected indented block after lambda declaration` — and a parse error makes gdUnit4 silently fall back to a stale discovery cache, so failures vanish or shift to wrong locations. Code formatters (including gdscript-format) tend to expand single-line lambdas; re-check parameterized tests after formatting.
2. **Annotate the return type of Callable factories.** When a parameter row passes a factory lambda, an omitted return type is inferred as `Variant` at parse level and can break test discovery — write `func() -> Variant: return ...` explicitly.
3. **Don't name lambda arguments the same as outer local variables** — the capture silently binds the wrong value.
4. **Debugging discovery problems**: run the test runner in verbose mode to surface the underlying parse error; the default output hides it.

## Fuzzing

Declare a `fuzzer` parameter to run a test repeatedly with generated inputs (default: 1000 iterations):

```gdscript
func test_with_random_values(fuzzer := Fuzzers.rangei(-10, 10)) -> void:
    var value: int = fuzzer.next_value()
    assert_int(clampi(value, -10, 10)).is_equal(value)
```

### Built-in Fuzzers

| Factory | Generates |
|---------|-----------|
| `Fuzzers.rangei(from, to)` | int in range |
| `Fuzzers.rangef(from, to)` | float in range |
| `Fuzzers.rangev2(from, to)` | Vector2 in range |
| `Fuzzers.rangev3(from, to)` | Vector3 in range |
| `Fuzzers.rand_str(min_length, max_length)` | random String |
| `Fuzzers.boolean()` | bool |
| `Fuzzers.eveni(from, to)` / `Fuzzers.oddi(from, to)` | even/odd int |

### Controlling Iterations and Seed

Use the special parameters `fuzzer_iterations` and `fuzzer_seed` (underscore prefix allowed):

```gdscript
func test_fuzzed(fuzzer := Fuzzers.rangei(0, 100),
        _fuzzer_iterations := 100, _fuzzer_seed := 12345) -> void:
    assert_int(fuzzer.next_value()).is_between(0, 100)
```

Custom fuzzers: extend `Fuzzer` and implement `next_value()`.
