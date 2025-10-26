extends GdUnitTestSuite

@warning_ignore_start("untyped_declaration")

func test_standard() -> void:
	var result := []
	Observable.of(10, 20, 30) \
	.take(2) \
	.subscribe(result.push_back)

	assert_array(result, true).contains_exactly(10, 20)


func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var result3 := []

	var subject := Subject.new()
	var take1 := subject.take(1)
	var take2 := take1.take(1)

	take1.subscribe(result1.push_back)
	take1.subscribe(result2.push_back)

	subject.on_next(1)
	subject.on_next(2)
	assert_array(result1, true).contains_exactly(1)
	assert_array(result2, true).contains_exactly(1)

	take2.subscribe(result3.push_back)

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)

	assert_array(result1, true).contains_exactly(1)
	assert_array(result2, true).contains_exactly(1)
	assert_array(result3, true).contains_exactly(1)


func test_take_zero_returns_empty() -> void:
	var result := []
	Observable.of(1, 2, 3).take(0).subscribe(result.push_back)
	assert_array(result).is_empty()


func test_take_zero_is_singleton() -> void:
	var take1 := Observable.of(1, 2, 3).take(0)
	var take2 := Observable.range(1, 5).take(0)
	var empty := Observable.empty()
	# All should return the same singleton instance
	assert_object(take1).is_same(empty)
	assert_object(take2).is_same(empty)


func test_take_zero_wait_returns_null() -> void:
	var take_zero := Observable.of(1, 2, 3).take(0)
	var result: Variant = await take_zero.wait()
	assert_object(result).is_null()
