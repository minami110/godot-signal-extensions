extends GdUnitTestSuite


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
	assert_array(result).contains_exactly([1])
	rp.value = 2
	assert_array(result).contains_exactly([1, 2])


func test_rp_equality_disabled() -> void:
	var result: Array[int] = []
	var rp := ReactiveProperty.new(1, false)
	rp.subscribe(result.append)
	rp.value = 1
	assert_array(result).contains_exactly([1, 1])
	rp.value = 2
	assert_array(result).contains_exactly([1, 1, 2])


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
