extends GdUnitTestSuite

# warning-ignore-all:unused_parameter
# warning-ignore-all:unused_variable
# warning-ignore-all:return_value_discarded

const __source := 'res://addons/signal_extensions/reactive_property.gd'

var _result_int: int

func test_standard1() -> void:
	_result_int = 0
	var rp := ReactiveProperty.new(1)
	rp.subscribe(func(new_value: int) -> void:
		_result_int = new_value
	)
	assert_int(_result_int).is_equal(1)
	assert_int(rp.value).is_equal(1)

	rp.value = 2
	assert_int(_result_int).is_equal(2)
	assert_int(rp.value).is_equal(2)

	rp.dispose()
	rp.value = 3
	assert_int(_result_int).is_equal(2)
	assert_int(rp.value).is_equal(3)

func test_standard2() -> void:
	var result: Array = []
	var rp := ReactiveProperty.new(null)
	rp.subscribe(func(new_value: Variant) -> void:
		result.push_back(new_value)
	)

	rp.value = 1
	rp.value = "Foo"
	rp.value = null
	rp.value = null
	var n1 := Node2D.new()
	var n2 := Node2D.new()
	rp.value = n1
	rp.value = n2
	assert_array(result).is_equal([null, 1, "Foo", null, n1, n2])
	n1.queue_free()
	n2.queue_free()

func test_rp_equality() -> void:
	_result_int = 0
	var rp := ReactiveProperty.new(1)
	rp.subscribe(func(new_value: int) -> void:
		_result_int += new_value
	)
	rp.value = 1
	assert_int(_result_int).is_equal(1)
	rp.value = 2
	assert_int(_result_int).is_equal(3)

func test_rp_equality_disabled() -> void:
	_result_int = 0
	var rp := ReactiveProperty.new(1, false)
	rp.subscribe(func(new_value: int) -> void:
		_result_int += new_value
	)
	rp.value = 1
	assert_int(_result_int).is_equal(2)
	rp.value = 2
	assert_int(_result_int).is_equal(4)

func test_rp_await() -> void:
	_result_int = 0
	var rp := ReactiveProperty.new(1)
	rp.subscribe(func(i: int) -> void:
		_result_int = i
	)

	var callable := func() -> void:
		rp.value = 2
	callable.call_deferred()
	var result: int = await rp.wait()
	assert_int(result).is_equal(2)

	await get_tree().process_frame

func test_dispose() -> void:
	_result_int = 0

	var rp := ReactiveProperty.new(1)
	var d := rp.subscribe(func(i: int) -> void:
		_result_int = i
	)
	rp.dispose()
	rp = ReactiveProperty.new(2)

	rp.value = 3
	assert_int(_result_int).is_equal(1)

	d.dispose()
	d = rp.subscribe(func(i: int) -> void:
		_result_int = i
	)
	d.dispose()
	d = null
	assert_int(_result_int).is_equal(3)

	rp.dispose()
	rp.value = 4
	assert_int(_result_int).is_equal(3)

func test_read_only_reactive_property() -> void:
	var result: Array = []
	var rp_source: ReactiveProperty = ReactiveProperty.new(1)

	# cast
	var rp := rp_source as ReadOnlyReactiveProperty
	rp.subscribe(func(new_value: int) -> void:
		result.push_back(new_value)
	)

	assert_int(rp.current_value).is_equal(1)

	rp_source.value = 10

	assert_int(rp.current_value).is_equal(10)
	assert_array(result).is_equal([1, 10])

func test_config_file_serialization() -> void:
	var result: Array = []
	var original_rp := ReactiveProperty.new(100)

	# テストのためConfigFileに保存
	var config := ConfigFile.new()
	config.set_value("player", "health", original_rp)
	
	# メモリ内でシリアライゼーション/デシリアライゼーションをテスト
	var config_string := config.encode_var(original_rp)
	var loaded_rp: ReactiveProperty = config.decode_var(config_string)
	
	# 値が保持されていることを確認
	assert_int(loaded_rp.value).is_equal(100)
	
	# 読み込んだオブジェクトが正常に動作することを確認
	loaded_rp.subscribe(func(new_value: int) -> void:
		result.push_back(new_value)
	)
	
	# 初期値がすぐに通知されることを確認
	assert_array(result).is_equal([100])
	
	# 値を変更して正常に動作することを確認
	loaded_rp.value = 75
	assert_array(result).is_equal([100, 75])
	assert_int(loaded_rp.value).is_equal(75)
	
	loaded_rp.dispose()

func test_config_file_various_types() -> void:
	# 様々な型でシリアライゼーションをテスト
	var test_cases := [
		42,
		3.14,
		"Hello World",
		Vector2(10, 20),
		null
	]
	
	for test_value in test_cases:
		var original_rp := ReactiveProperty.new(test_value)
		
		# シリアライゼーション/デシリアライゼーション
		var config := ConfigFile.new()
		var config_string := config.encode_var(original_rp)
		var loaded_rp: ReactiveProperty = config.decode_var(config_string)
		
		# 値が保持されていることを確認
		assert_that(loaded_rp.value).is_equal(test_value)
		
		# 新しい値を設定して動作確認
		var result: Array = []
		loaded_rp.subscribe(func(new_value: Variant) -> void:
			result.push_back(new_value)
		)
		
		# 初期値が通知される
		assert_that(result[0]).is_equal(test_value)
		
		loaded_rp.dispose()
