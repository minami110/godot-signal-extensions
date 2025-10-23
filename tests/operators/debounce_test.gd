extends GdUnitTestSuite

func _wait_time(time_sec: float) -> Signal:
	return get_tree().create_timer(time_sec).timeout


func test_standard() -> void:
	var result := []
	var pub := Subject.new()
	# Note: Subscription を変数で受けておいて Callable が死なないようにする
	var _d1 := pub \
	.debounce(0.1) \
	.subscribe(func(x: Variant) -> void: result.push_back(x))

	# t: 0.0
	pub.on_next(1)
	pub.on_next(2)
	pub.on_next(3)
	assert_array(result, true).is_empty()

	# t: 0.05
	await _wait_time(0.05)
	pub.on_next(4) # Timer: 0.05 => 0.0
	assert_array(result, true).is_empty()

	# t: 0.1
	await _wait_time(0.05) # Timer: 0.0 => 0.05
	assert_array(result, true).is_empty()

	# t: 0.15
	await _wait_time(0.05) # Timer: 0.05 => 0.1
	assert_array(result, true).contains_exactly([4])

	# -----

	pub.on_next(5)
	await _wait_time(0.1)
	assert_array(result, true).contains_exactly([4, 5])

	# -----

	# TODO: publisher.dispose() によるキャンセル挙動
	# R3 では source が dispose されると即時に値が書き込まれる
	pub.on_next(6)
	pub.dispose()

	# assert_array(result, true).contains_exactly([4, 5, 6])
	assert_array(result, true).contains_exactly([4, 5])

	await _wait_time(0.12)
	assert_array(result, true).contains_exactly([4, 5, 6])
