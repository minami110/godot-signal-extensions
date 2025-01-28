extends GdUnitTestSuite

func _wait_time(time_sec: float) -> Signal:
	return get_tree().create_timer(time_sec).timeout

func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
		.throttle_last(0.1) \
		.subscribe(func(x): result.push_back(x))

	# 1
	subject.on_next(1)
	await _wait_time(0.11)


	# 5 (制限時間が更新される)
	subject.on_next(2)
	await _wait_time(0.05)

	subject.on_next(3)
	await _wait_time(0.05)

	subject.on_next(4)
	await _wait_time(0.05)

	subject.on_next(5)
	await _wait_time(0.11)

	assert_array(result, true).is_equal([1, 5])
