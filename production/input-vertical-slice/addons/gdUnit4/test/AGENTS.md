# Testing Requirements

Every code change must be accompanied by new or updated tests. Tests live under `addons/gdUnit4/test/` and mirror
the `src/` structure (e.g. `src/core/Foo.gd` → `test/core/FooTest.gd`).

## GdUnit4 Fluent Syntax

All GDScript tests must use the GdUnit4 fluent assertion API. Do **not** use plain `assert()`.

**Test suite skeleton:**

```gdscript
class_name MyFeatureTest
extends GdUnitTestSuite


const __source = "res://addons/gdUnit4/src/path/to/MyFeature.gd"


# optional lifecycle hooks
func before_test() -> void:
    pass

func after_test() -> void:
    pass
```

**Test section grouping — use `#region` / `#endregion`:**

Group related test functions into named regions instead of comment dividers.
Every region must have a matching `#endregion`:

```gdscript
#region is_equal
func test_is_equal_same_value() -> void:
    assert_int(1).is_equal(1)

func test_is_equal_different_value_fails() -> void:
    assert_failure(func() -> void: assert_int(1).is_equal(2)) \
        .is_failed()
#endregion

#region has_size
func test_has_size() -> void:
    assert_array([1, 2, 3]).has_size(3)
#endregion
```

**Always use the type-specific assert function:**

Match the assert to the type of the value under test. Type-specific asserts unlock
richer failure messages and type-appropriate matchers. Fall back to `assert_that` only
for custom objects and variants that have no dedicated assert.

| Value type | Use |
| ---------- | --- |
| `bool` | `assert_bool(value)` |
| `int` | `assert_int(value)` |
| `float` | `assert_float(value)` |
| `String` | `assert_str(value)` |
| `Array` | `assert_array(value)` |
| `Dictionary` | `assert_dict(value)` |
| Custom object / variant | `assert_that(value)` |

Pick the assert based on the type of the value — whether that comes from an explicit
annotation, `:=` inference, or the return type of the called function.

```gdscript
# Preferred — assert matches the inferred type of the value
var is_alive := player.is_alive()       # bool  → assert_bool
assert_bool(is_alive).is_true()

var item_count := inventory.size()      # int   → assert_int
assert_int(item_count).is_equal(5)

var label := button.get_label()         # String → assert_str
assert_str(label).is_equal("Start Game")

var config := settings.to_dict()        # Dictionary → assert_dict
assert_dict(config).contains_key_value("difficulty", "hard")

var node := scene.find_child("Player")  # Node → assert_that
assert_that(node).is_equal(expected_node)

# Avoid — assert_that used where a type-specific assert exists
assert_that(player.is_alive()).is_equal(true)
assert_that(inventory.size()).is_equal(5)
assert_that(button.get_label()).is_equal("Start Game")
```

**Fluent chain — break only when necessary:**

Keep the chain on one line when it fits within the 140-character limit and uses a single
validation call. Break with `\` continuation when the line would be too long, or when
chaining more than one validation method.

```gdscript
# Preferred — fits on one line, single validation
assert_bool(player.is_alive()).is_true()
assert_str(player.name()).is_equal("Hero")

# Preferred — break because the line would exceed 140 characters
assert_str(player.get_full_description()) \
    .is_equal("Hero the Brave, level 42, wielder of the Sword of Destiny")

# Preferred — break because multiple validations are chained
assert_str(player.name()) \
    .is_not_empty() \
    .starts_with("H") \
    .is_equal("Hero")

# Avoid — unnecessary break for a short single-validation chain
assert_bool(player.is_alive()) \
    .is_true()
```

**Core assert functions and chaining:**

```gdscript
# Primitives
assert_bool(value).is_true()
assert_bool(value).is_false()

assert_int(value).is_equal(42)
assert_int(value).is_not_equal(0)
assert_int(value).is_greater(10).is_less(100)

assert_float(value).is_equal_approx(3.14, 0.001)

assert_str(value).is_equal("expected")
assert_str(value).is_not_null().has_length(5).starts_with("ab").ends_with("cd").contains("bc")
assert_str(value).is_empty()

# Objects / variants
assert_object(value).is_not_null()
assert_object(value).is_instanceof(MyClass)
assert_that(value).is_null()
assert_that(value).is_equal(expected)
assert_that(value).is_instanceof(Node)
```

**Object equality — prefer whole-object comparison:**

`assert_that(obj).is_equal(expected)` uses deep property comparison (`GdObjects.equals`), so
always prefer it over asserting fields one by one. Field-by-field assertions are harder to
read, require more maintenance, and produce worse failure messages.

```gdscript
# Preferred — compare the full result to an expected object in one assertion
var result := Player.new("Hero", 100, Vector3(1, 2, 3))
assert_that(result).is_equal(Player.new("Hero", 100, Vector3(1, 2, 3)))

# Avoid — noisy, fragile, easy to miss a property
assert_str(result.name).is_equal("Hero")
assert_int(result.health).is_equal(100)
assert_that(result.position).is_equal(Vector3(1, 2, 3))
```

Only fall back to field-by-field when you intentionally want to verify a single property
in isolation, or when the expected object cannot be constructed easily.

**Inline expected values — avoid unnecessary variables:**

Put the expected value directly in the assertion unless the line would exceed the 140-character
limit. An extra `var expected` adds noise without adding clarity.

```gdscript
# Preferred — expected value inline
assert_str(player.name()).is_equal("Hero")
assert_that(result).is_equal(Player.new("Hero", 100, Vector3(1, 2, 3)))

# Accepted — variable needed to stay within the 140-character line limit
var expected := Player.new(
    "Hero", 100, Vector3(1, 2, 3), ["sword", "shield"], {"speed": 5.0}
)
assert_that(result).is_equal(expected)

# Avoid — variable adds no value when the expression fits on one line
var expected_name := "Hero"
assert_str(player.name()).is_equal(expected_name)
```

```gdscript
# Arrays
assert_array(value).is_not_empty()
assert_array(value).has_size(3).contains(1, 2)
assert_array(value).contains_exactly(1, 2, 3)

# Dictionaries
assert_dict(value).is_not_empty()
assert_dict(value).contains_key("foo")
assert_dict(value).contains_key_value("foo", "bar")
assert_dict(value).has_size(3).contains_key_value("foo", "bar")
```

**Testing expected failures:**

```gdscript
assert_failure(func() -> void: assert_str("abc").is_equal("xyz")) \
    .is_failed() \
    .has_message("Expecting:\n 'xyz'\n but was\n 'abc'")

assert_failure(func() -> void: assert_str("abc").is_null()) \
    .is_failed() \
    .starts_with_message("Expecting: '<null>'")
```

**Mocking and spying:**

```gdscript
var mock :Variant = mock(MyClass)
when(mock.my_method(any_int())).thenReturn(42)
verify(mock).my_method(42)
verify(mock, times(2)).my_method(any_int())
```

**Scene runner:**

```gdscript
var runner := scene_runner("res://my_scene.tscn")
await runner.simulate_frames(10)
assert_signal(runner).is_emitted("my_signal")
runner.simulate_key_pressed(KEY_ENTER)
```

**Auto-free resources:**

```gdscript
var node := auto_free(MyNode.new())   # freed after test automatically
```
