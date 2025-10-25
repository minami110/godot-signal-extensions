extends GdUnitTestSuite

# Helper class for testing: Always updates even if values are equal
class AlwaysUpdateRP extends ReactiveProperty:
	func _should_update(_old_value: Variant, _new_value: Variant) -> bool:
		return true # Always update, similar to old check_equality=false


# Helper class for testing: Transforms values by clamping to range
class ClampedRP extends ReactiveProperty:
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
class TrimmedStringRP extends ReactiveProperty:
	func _transform_value(input_value: Variant) -> Variant:
		if input_value is String:
			return input_value.strip_edges()
		return input_value


# Helper class for testing: Both clamps values AND always updates
class AlwaysUpdateClampedRP extends ClampedRP:
	func _should_update(_old_value: Variant, _new_value: Variant) -> bool:
		return true  # Always update, even if same


func test_standard1() -> void:
	var result: Array[int] = []
	var rp := ReactiveProperty.new(1)
	rp.subscribe(result.append)
	assert_array(result).contains_exactly([1])
	assert_int(rp.value).is_equal(1)

	rp.value = 2
	assert_array(result).contains_exactly([1, 2])
	assert_int(rp.value).is_equal(2)

	rp.dispose()
	rp.value = 3
	assert_array(result).contains_exactly([1, 2])
	assert_int(rp.value).is_equal(3)


func test_standard2() -> void:
	var result: Array = []
	var rp := ReactiveProperty.new(null)
	rp.subscribe(result.push_back)

	rp.value = 1
	rp.value = "Foo"
	rp.value = null
	rp.value = null
	var n1 := Node2D.new()
	var n2 := Node2D.new()
	rp.value = n1
	rp.value = n2
	assert_array(result).contains_exactly([null, 1, "Foo", null, n1, n2])
	n1.queue_free()
	n2.queue_free()


func test_rp_equality() -> void:
	var result: Array[int] = []
	var rp := ReactiveProperty.new(1)
	rp.subscribe(result.append)
	rp.value = 1
	rp.value = 2
	rp.value = 2
	assert_array(result).contains_exactly(1, 2)


func test_rp_equality_disabled() -> void:
	var result: Array[int] = []
	var rp := AlwaysUpdateRP.new(1)
	rp.subscribe(result.append)
	rp.value = 1
	rp.value = 2
	assert_array(result).contains_exactly(1, 1, 2)


func test_rp_await() -> void:
	var result: Array[int] = []
	var rp := ReactiveProperty.new(1)
	rp.subscribe(result.append)

	var callable := func() -> void:
		rp.value = 2
	callable.call_deferred()
	var await_result: int = await rp.wait()
	assert_int(await_result).is_equal(2)

	await get_tree().process_frame


func test_dispose() -> void:
	var result: Array[int] = []

	var rp := ReactiveProperty.new(1)
	var d := rp.subscribe(result.append)
	rp.dispose()
	rp = ReactiveProperty.new(2)

	rp.value = 3
	assert_array(result).contains_exactly([1])

	d.dispose()
	d = rp.subscribe(result.append)
	d.dispose()
	d = null
	assert_array(result).contains_exactly([1, 3])

	rp.dispose()
	rp.value = 4
	assert_array(result).contains_exactly([1, 3])


func test_read_only_reactive_property() -> void:
	var result: Array = []
	var rp_source: ReactiveProperty = ReactiveProperty.new(1)

	# cast
	var rp := rp_source as ReadOnlyReactiveProperty
	rp.subscribe(result.push_back)

	assert_int(rp.current_value).is_equal(1)

	rp_source.value = 10

	assert_int(rp.current_value).is_equal(10)
	assert_array(result).contains_exactly([1, 10])


func test_config_file_serialization() -> void:
	var result: Array = []
	var original_rp := ReactiveProperty.new(100)

	# テストのためConfigFileに保存
	var config := ConfigFile.new()
	config.set_value("player", "health", original_rp)

	# メモリ内でシリアライゼーション/デシリアライゼーションをテスト
	var config_text: String = config.encode_to_text()

	var loaded_config := ConfigFile.new()
	loaded_config.parse(config_text)
	var loaded_rp: ReactiveProperty = loaded_config.get_value("player", "health")

	# 値が保持されていることを確認
	assert_int(loaded_rp.value).is_equal(100)

	# 読み込んだオブジェクトが正常に動作することを確認
	loaded_rp.subscribe(result.push_back)

	# 初期値がすぐに通知されることを確認
	assert_array(result).contains_exactly([100])

	# 値を変更して正常に動作することを確認
	loaded_rp.value = 75
	assert_array(result).contains_exactly([100, 75])
	assert_int(loaded_rp.value).is_equal(75)

	loaded_rp.dispose()


func test_config_file_various_types() -> void:
	# 様々な型でシリアライゼーションをテスト
	var test_cases := [
		42,
		3.14,
		"Hello World",
		Vector2(10, 20),
		null,
	]

	for test_value: Variant in test_cases:
		var original_rp := ReactiveProperty.new(test_value)

		# シリアライゼーション/デシリアライゼーション
		var config := ConfigFile.new()
		config.set_value("test", "property", original_rp)
		var config_text: String = config.encode_to_text()

		var loaded_config := ConfigFile.new()
		loaded_config.parse(config_text)
		var loaded_rp: ReactiveProperty = loaded_config.get_value("test", "property")

		# 値が保持されていることを確認
		assert_that(loaded_rp.value).is_equal(test_value)

		# 新しい値を設定して動作確認
		var result: Array = []
		loaded_rp.subscribe(result.push_back)

		# 初期値が通知される
		assert_that(result[0]).is_equal(test_value)

		loaded_rp.dispose()


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
	rp.value = -5.0  # Clamped to 0.0, same as current
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
	rp.value = -10.0  # Clamped to 0.0
	rp.value = -20.0  # Also clamped to 0.0, but still emits
	assert_array(result).contains_exactly([50.0, 50.0, 0.0, 0.0])

	rp.dispose()
