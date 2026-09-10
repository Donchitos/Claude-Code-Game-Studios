# Implementing a New Assert Type

Every assert type follows a strict two-layer pattern. Five touch points must be updated — do them in this order.

## 1. Abstract interface — `src/GdUnit<Type>Assert.gd`

Read `src/GdUnitAssert.gd` to get the exact base interface — re-declare every `@abstract` method
from it with the return type changed to `GdUnit<Type>Assert`, then append type-specific methods below.
Do **not** hardcode the method list; derive it from the current file.

## 2. Implementation — `src/asserts/GdUnit<Type>AssertImpl.gd`

All logic delegates to a `GdUnitAssertImpl` instance. The mandatory skeleton:

```gdscript
extends GdUnit<Type>Assert

var _base: GdUnitAssertImpl

func _init(current: Variant) -> void:
    _base = GdUnitAssertImpl.new(current)
    GdUnitThreadManager.get_current_context().set_assert(self)
    if not _validate_value_type(current):
        @warning_ignore("return_value_discarded")
        report_error("GdUnit<Type>Assert error, the type <%s> is not supported." % GdObjects.typeof_as_string(current))

func _notification(event: int) -> void:       # required — cleans up _base
    if event == NOTIFICATION_PREDELETE:
        if _base != null:
            _base.notification(event)
            _base = null

func _validate_value_type(value: Variant) -> bool:
    return value == null or value is MyGodotType

func current_value() -> Variant:
    return _base.current_value()

func report_success() -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.report_success()
    return self

func report_error(error: String) -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.report_error(error)
    return self

func failure_message() -> String:
    return _base.failure_message()

func override_failure_message(message: String) -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.override_failure_message(message)
    return self

func append_failure_message(message: String) -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.append_failure_message(message)
    return self

func is_null() -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.is_null()
    return self

func is_not_null() -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.is_not_null()
    return self

func is_equal(expected: Variant) -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.is_equal(expected)   # or custom comparison + report_error/report_success
    return self

func is_not_equal(expected: Variant) -> GdUnit<Type>Assert:
    @warning_ignore("return_value_discarded")
    _base.is_not_equal(expected)
    return self
```

Key rules:

- Every method returns `self` for chaining.
- Call `report_error(message)` on failure, `report_success()` on pass — never raise directly.
- `GdObjects.equals()` handles deep comparison for most types. For objects whose `==` is
  reference-only (e.g. `Image`), implement comparison manually via their API.
- Custom error message helpers belong in `GdAssertMessages.gd` as `static func` methods.
  Use `_error()` / `_colored_value()` for consistent colouring.

## 3. Preload — `src/asserts/GdUnitAssertions.gd`

Add one line inside `_init()` alongside the other preloads:

```gdscript
GdUnitAssertions.__lazy_load("res://addons/gdUnit4/src/asserts/GdUnit<Type>AssertImpl.gd")
```

## 4. Registration — `src/GdUnitTestSuite.gd`

Add the public factory method near the other `assert_*` functions:

```gdscript
func assert_mytype(current: Variant) -> GdUnit<Type>Assert:
    return __lazy_load("res://addons/gdUnit4/src/asserts/GdUnit<Type>AssertImpl.gd").new(current)
```

Update `assert_that()` to dispatch the new type (add a `match` branch or an `if` inside `TYPE_OBJECT`):

```gdscript
TYPE_OBJECT:
    if current is MyGodotType:
        return assert_mytype(current)
    return assert_object(current)
```

## 5. Test suite — `test/asserts/GdUnit<Type>AssertImplTest.gd`

```gdscript
class_name GdUnit<Type>AssertImplTest
extends GdUnitTestSuite


const __source = 'res://addons/gdUnit4/src/asserts/GdUnit<Type>AssertImpl.gd'
```

Minimum test coverage: supported types, unsupported types (type-check error message),
`is_null`, `is_not_null`, `is_equal` (pass + each failure variant), `is_not_equal`,
every type-specific method, `assert_that` dispatch, method chaining.

**Lint scope:** `test/asserts/` is **not** checked by CI gdlint. Only `src/asserts/` is.
Always lint `src/asserts/` after changes:

```bash
gdlint addons/gdUnit4/src/asserts/
```
