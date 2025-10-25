extends GdUnitTestSuite

# Helper class for testing: Always updates even if values are equal
class AlwaysUpdateRP extends CustomReactiveProperty:
	func _should_update(_old_value: Variant, _new_value: Variant) -> bool:
		return true # Always update, similar to old check_equality=false


# Helper class for testing: Transforms values by clamping to range
class ClampedRP extends CustomReactiveProperty:
	var min_value: float
	var max_value: float


	func _init(initial: float, min_val: float, max_val: float) -> void:
		min_value = min_val
		max_value = max_val
		super._init(initial)


	func _transform_value(input_value: Variant) -> Variant:
		@warning_ignore("unsafe_call_argument")
		return clampf(input_value, min_value, max_value)


# Helper class for testing: Transforms strings by trimming
class TrimmedStringRP extends CustomReactiveProperty:
	func _transform_value(input_value: Variant) -> Variant:
		if input_value is String:
			return input_value.strip_edges()
		return input_value


# Helper class for testing: Both clamps values AND always updates
class AlwaysUpdateClampedRP extends ClampedRP:
	func _should_update(_old_value: Variant, _new_value: Variant) -> bool:
		return true # Always update, even if same


func test_rp_equality_disabled() -> void:
	var result: Array[int] = []
	var rp := AlwaysUpdateRP.new(1)
	rp.subscribe(result.append)
	rp.value = 1
	rp.value = 2
	assert_array(result).contains_exactly(1, 1, 2)


func test_transform_value_clamping() -> void:
	var result: Array = []
	var rp := ClampedRP.new(50.0, 0.0, 100.0)
	rp.subscribe(result.push_back)

	# Initial value should be 50.0
	assert_array(result).contains_exactly([50.0])

	# Setting value within range
	rp.value = 75.0
	assert_array(result).contains_exactly([50.0, 75.0])
	assert_float(rp.value).is_equal(75.0)

	# Setting value above max should clamp to max
	rp.value = 150.0
	assert_array(result).contains_exactly([50.0, 75.0, 100.0])
	assert_float(rp.value).is_equal(100.0)

	# Setting value below min should clamp to min
	rp.value = -10.0
	assert_array(result).contains_exactly([50.0, 75.0, 100.0, 0.0])
	assert_float(rp.value).is_equal(0.0)

	# Setting same value (after clamping) should not emit
	rp.value = -5.0 # Clamped to 0.0, same as current
	assert_array(result).contains_exactly([50.0, 75.0, 100.0, 0.0])
	assert_float(rp.value).is_equal(0.0)

	rp.dispose()


func test_transform_value_string_trim() -> void:
	var result: Array = []
	var rp := TrimmedStringRP.new("  hello  ")
	rp.subscribe(result.push_back)

	# Initial value should be trimmed
	assert_array(result).contains_exactly(["hello"])
	assert_str(rp.value).is_equal("hello")

	# Setting value with spaces should be trimmed
	rp.value = "  world  "
	assert_array(result).contains_exactly(["hello", "world"])
	assert_str(rp.value).is_equal("world")

	# Setting same value after trimming should not emit
	rp.value = "  world  "
	assert_array(result).contains_exactly(["hello", "world"])

	# Non-string values should pass through unchanged
	rp.value = 123
	assert_array(result).contains_exactly(["hello", "world", 123])
	assert_int(rp.value).is_equal(123)

	rp.dispose()


func test_transform_and_should_update_combination() -> void:
	# Test case where both _transform_value and _should_update are overridden
	var result: Array = []

	var rp := AlwaysUpdateClampedRP.new(50.0, 0.0, 100.0)
	rp.subscribe(result.push_back)

	# Initial value
	assert_array(result).contains_exactly([50.0])

	# Setting same value should emit (because always update)
	rp.value = 50.0
	assert_array(result).contains_exactly([50.0, 50.0])

	# Setting value that clamps to same should still emit
	rp.value = -10.0 # Clamped to 0.0
	rp.value = -20.0 # Also clamped to 0.0, but still emits
	assert_array(result).contains_exactly([50.0, 50.0, 0.0, 0.0])

	rp.dispose()
