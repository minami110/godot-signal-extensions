extends GdUnitTestSuite


func test_standard() -> void:
	var result := []
	var subject := Subject.new()
	subject \
		.skip_while(func(x): return x <= 2) \
		.subscribe(func(x): result.push_back(x))

	subject.on_next(1)
	subject.on_next(2)
	subject.on_next(3)
	subject.on_next(1)
	subject.on_next(2)
	assert_array(result, true).is_equal([3, 1, 2])

func test_two_subscribers() -> void:
	var result1 := []
	var result2 := []
	var subject := Subject.new()
	var skip_while := subject.skip_while(func(x): return x <= 2)

	skip_while.subscribe(func(x): result1.push_back(x))

	subject.on_next(1)
	subject.on_next(3)
	subject.on_next(1)

	assert_array(result1, true).is_equal([3, 1])
	assert_array(result2, true).is_equal([])

	skip_while.subscribe(func(x): result2.push_back(x))

	subject.on_next(1)
	subject.on_next(3)
	subject.on_next(1)

	assert_array(result1, true).is_equal([3, 1, 1, 3, 1])
	assert_array(result2, true).is_equal([3, 1])
