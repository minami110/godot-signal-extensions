extends GdUnitTestSuite

func _wait_time(time_sec: float) -> Signal:
	return get_tree().create_timer(time_sec).timeout

## throttle_last (sample) standard test
func test_standard() -> void:
	var result := []
	var pub := Subject.new()
	# Note: Subscription を変数で受けておいて Callable が死なないようにする
	var _d1 := pub \
		.throttle_last(0.1) \
		.subscribe(func(x): result.push_back(x))

	pub.on_next(1)
	pub.on_next(2)
	pub.on_next(3)
	assert_array(result, true).is_equal([])

	await _wait_time(0.05)
	pub.on_next(4)
	pub.on_next(5)

	await _wait_time(0.05)
	assert_array(result, true).is_equal([5])
	pub.on_next(6)
	pub.on_next(7)

	await _wait_time(0.1)
	assert_array(result, true).is_equal([5, 7])

	# TODO: Observable.dispose() によるキャンセル挙動
	# R3 では source が dispose されると値が書きこまれなくなる
	pub.on_next(8)
	pub.dispose()
	assert_array(result, true).is_equal([5, 7])

	await _wait_time(0.12)
	# assert_array(result, true).is_equal([5, 7])
	assert_array(result, true).is_equal([5, 7, 8])
