# Type-Specific Assertions

Always prefer type-specific assertions over `assert_that()` for better error messages.

## Assertion Reference

| Assertion | Type | Key Methods |
|-----------|------|-------------|
| `assert_int()` | int | `is_equal`, `is_less`, `is_greater`, `is_between`, `is_zero`, `is_negative`, `is_odd`, `is_even` |
| `assert_float()` | float | `is_equal`, `is_equal_approx`, `is_less`, `is_greater`, `is_zero`, `is_in` |
| `assert_str()` | String | `is_equal`, `contains`, `starts_with`, `ends_with`, `is_empty` |
| `assert_bool()` | bool | `is_true`, `is_false` |
| `assert_array()` | Array | `has_size`, `contains`, `contains_exactly`, `is_empty`, `not_contains` |
| `assert_dict()` | Dictionary | `is_empty`, `has_size`, `contains_keys`, `contains_key_value` |
| `assert_object()` | Object | `is_null`, `is_not_null`, `is_same`, `is_instanceof` |
| `assert_vector()` | Vector2/3 | `is_equal`, `is_equal_approx`, `is_less`, `is_greater` |
| `assert_signal()` | Signal | `is_emitted`, `is_not_emitted`, `is_signal_exists` |
| `assert_file()` | File | `exists`, `does_not_exist`, `is_script` |
| `assert_that()` | Generic | Use when type is unknown |

## Examples

### Integer Assertions

```gdscript
assert_int(value).is_equal(10)
assert_int(value).is_not_equal(5)
assert_int(value).is_less(20)
assert_int(value).is_greater(0)
assert_int(value).is_between(1, 100)
assert_int(value).is_zero()
assert_int(value).is_negative()
assert_int(value).is_odd()
assert_int(value).is_even()
assert_int(value).is_in([1, 2, 3])
```

### Float Assertions

```gdscript
assert_float(value).is_equal(3.14)
assert_float(value).is_equal_approx(3.14, 0.01)  # With tolerance
assert_float(value).is_less(10.0)
assert_float(value).is_greater(0.0)
assert_float(value).is_zero()
assert_float(value).is_not_zero()
assert_float(value).is_in([1.0, 2.0, 3.0])
```

### String Assertions

```gdscript
assert_str(text).is_equal("Hello")
assert_str(text).is_not_equal("Goodbye")
assert_str(text).contains("ell")
assert_str(text).not_contains("xyz")
assert_str(text).starts_with("He")
assert_str(text).ends_with("lo")
assert_str(text).is_empty()
assert_str(text).is_not_empty()
assert_str(text).contains_ignoring_case("HELLO")
```

### Boolean Assertions

```gdscript
assert_bool(flag).is_true()
assert_bool(flag).is_false()
```

### Array Assertions

```gdscript
assert_array(items).has_size(5)
assert_array(items).is_empty()
assert_array(items).is_not_empty()
assert_array(items).contains([1, 2])           # Contains these elements (any order)
assert_array(items).contains_exactly([1, 2, 3]) # Exact match (same order)
assert_array(items).contains_exactly_in_any_order([3, 1, 2])
assert_array(items).not_contains([4, 5])
assert_array(items).contains_same([obj1, obj2]) # Reference comparison
```

### Dictionary Assertions

```gdscript
assert_dict(data).is_empty()
assert_dict(data).is_not_empty()
assert_dict(data).has_size(3)
assert_dict(data).contains_keys(["name", "age"])
assert_dict(data).contains_key_value("name", "Player")
```

### Object Assertions

```gdscript
assert_object(node).is_null()
assert_object(node).is_not_null()
assert_object(node).is_equal(other_node)
assert_object(node).is_not_equal(other_node)
assert_object(node).is_same(same_ref)          # Same reference
assert_object(node).is_not_same(different_ref)
assert_object(node).is_instanceof(Node2D)
assert_object(node).is_not_instanceof(Sprite2D)
```

### Vector Assertions

```gdscript
assert_vector(pos).is_equal(Vector2(10, 20))
assert_vector(pos).is_not_equal(Vector2.ZERO)
assert_vector(pos).is_equal_approx(Vector2.ONE, Vector2(0.01, 0.01))
assert_vector(pos).is_less(Vector2(100, 100))
assert_vector(pos).is_greater(Vector2.ZERO)
```

### File Assertions

```gdscript
assert_file("res://data.json").exists()
assert_file("res://missing.txt").does_not_exist()
assert_file("res://script.gd").is_script()
```
