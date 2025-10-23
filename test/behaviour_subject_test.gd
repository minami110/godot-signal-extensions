extends GdUnitTestSuite

@warning_ignore("unused_parameter")
@warning_ignore("unused_variable")
@warning_ignore("return_value_discarded")

func test_standard() -> void:
	var result: Array[int] = []

	var subject := BehaviourSubject.new(5)
	subject.subscribe(
		func(i: int) -> void:
			result.append(i)
	)

	subject.on_next(10)
	subject.on_next(10)
	subject.dispose()
	subject.on_next(20)
	assert_array(result).is_equal([5, 10, 10])


func test_behaviour_subject_wait() -> void:
	var subject := BehaviourSubject.new(1)

	subject.on_next.call_deferred(2)
	var result: int = await subject.wait()
	assert_int(result).is_equal(2)


func test_config_file_serialization() -> void:
	var result: Array = []
	var original_subject := BehaviourSubject.new("idle")

	# 値を変更
	original_subject.on_next("loading")
	original_subject.on_next("complete")

	# シリアライゼーション/デシリアライゼーション
	var config := ConfigFile.new()
	var config_string := config.encode_var(original_subject)
	var loaded_subject: BehaviourSubject = config.decode_var(config_string)

	# 最新値が保持されていることを確認
	assert_str(loaded_subject.value).is_equal("complete")

	# 新しいsubscriberがすぐに最新値を受け取ることを確認
	loaded_subject.subscribe(
		func(new_value: String) -> void:
			result.push_back(new_value)
	)

	# 初期値（最新値）がすぐに通知されることを確認
	assert_array(result).is_equal(["complete"])

	# 新しい値を設定して正常に動作することを確認
	loaded_subject.on_next("updated")
	assert_array(result).is_equal(["complete", "updated"])
	assert_str(loaded_subject.value).is_equal("updated")

	loaded_subject.dispose()


func test_config_file_various_types() -> void:
	# 様々な型でシリアライゼーションをテスト
	var test_cases := [
		100,
		2.5,
		"test_string",
		Vector3(1, 2, 3),
		null,
	]

	for test_value in test_cases:
		var original_subject := BehaviourSubject.new(test_value)

		# シリアライゼーション/デシリアライゼーション
		var config := ConfigFile.new()
		var config_string := config.encode_var(original_subject)
		var loaded_subject: BehaviourSubject = config.decode_var(config_string)

		# 値が保持されていることを確認
		assert_that(loaded_subject.value).is_equal(test_value)

		# 新しいsubscriberの動作確認
		var result: Array = []
		loaded_subject.subscribe(
			func(new_value: Variant) -> void:
				result.push_back(new_value)
		)

		# 初期値（最新値）がすぐに通知される
		assert_that(result[0]).is_equal(test_value)

		# 新しい値を設定して動作確認
		loaded_subject.on_next("new_value")
		assert_str(result[1]).is_equal("new_value")
		assert_str(loaded_subject.value).is_equal("new_value")

		loaded_subject.dispose()
